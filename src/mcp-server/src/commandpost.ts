/**
 * CommandPost WebSocket Client
 *
 * Manages the WebSocket connection to CommandPost's built-in server.
 * Handles message correlation via IDs, automatic reconnection,
 * and serialization.
 */

import WebSocket from "ws";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

interface PendingRequest {
  resolve: (value: unknown) => void;
  reject: (reason: Error) => void;
  timeout: ReturnType<typeof setTimeout>;
}

export interface CommandPostResponse {
  type: string;
  id?: string;
  timestamp?: number;
  status?: "success" | "error";
  result?: unknown;
  error?: string;
}

export interface ExecuteResult {
  result: unknown;
}

export interface BatchResult {
  results: Array<{
    index: number;
    status: "success" | "error";
    result?: unknown;
    error?: string;
  }>;
  totalOperations: number;
  completedOperations: number;
}

export interface HandlerInfo {
  id: string;
  group: string;
  label: string;
}

export class CommandPostClient {
  private ws: WebSocket | null = null;
  private connectPromise: Promise<void> | null = null;
  private pendingRequests: Map<string, PendingRequest> = new Map();
  private messageCounter = 0;
  private url: string;
  private reconnecting = false;
  private authToken: string | null = null;
  private authTokenLoadedAt = 0;
  /** How long (ms) to cache the auth token before re-reading from disk */
  private static readonly AUTH_TOKEN_TTL_MS = 60000;
  /** Ring buffer for deduplication: stores recent message IDs with O(1) add and bounded memory. */
  private seenIds: Map<string, number> = new Map();
  private static readonly SEEN_IDS_MAX = 5000;

  /** Well-known paths where CommandPost writes the auth token */
  private static readonly AUTH_TOKEN_PATHS = [
    path.join(os.homedir(), "Library", "Application Support", "CommandPost", "mcp-auth-token"),
    path.join(os.homedir(), ".CommandPost", "mcp-auth-token"),
  ];

  constructor(url?: string) {
    this.url = url || process.env.COMMANDPOST_WS_URL || "ws://localhost:27480";
    this.loadAuthToken();
  }

  /** Load auth token from env var or well-known file path (cached with TTL) */
  private loadAuthToken(force = false): void {
    // Use cached token if within TTL unless forced
    if (!force && this.authToken && (Date.now() - this.authTokenLoadedAt) < CommandPostClient.AUTH_TOKEN_TTL_MS) {
      return;
    }

    // Check env var first
    if (process.env.COMMANDPOST_AUTH_TOKEN) {
      this.authToken = process.env.COMMANDPOST_AUTH_TOKEN;
      this.authTokenLoadedAt = Date.now();
      return;
    }

    // Try well-known file paths
    for (const tokenPath of CommandPostClient.AUTH_TOKEN_PATHS) {
      try {
        const token = fs.readFileSync(tokenPath, "utf-8").trim();
        if (token) {
          this.authToken = token;
          this.authTokenLoadedAt = Date.now();
          return;
        }
      } catch {
        // File doesn't exist, try next path
      }
    }
  }

  isConnected(): boolean {
    return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
  }

  async connect(): Promise<void> {
    if (this.isConnected()) return;
    if (this.connectPromise) return this.connectPromise;

    this.connectPromise = new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.connectPromise = null;
        if (this.ws && this.ws.readyState === WebSocket.CONNECTING) {
          this.ws.terminate();
        }
        reject(
          new Error(
            `Connection to CommandPost timed out. Ensure CommandPost is running and WebSocket is enabled at ${this.url}.`
          )
        );
      }, 10000);

      let settled = false;

      const resolveConnection = () => {
        if (settled) return;
        settled = true;
        clearTimeout(timeout);
        this.connectPromise = null;
        this.reconnecting = false;
        resolve();
      };

      const rejectConnection = (error: Error) => {
        if (settled) return;
        settled = true;
        clearTimeout(timeout);
        this.connectPromise = null;
        reject(error);
      };

      let socket: WebSocket;
      try {
        socket = new WebSocket(this.url);
        this.ws = socket;
      } catch (err) {
        clearTimeout(timeout);
        this.connectPromise = null;
        reject(
          new Error(
            `Failed to create WebSocket: ${err instanceof Error ? err.message : String(err)}`
          )
        );
        return;
      }

      socket.on("open", () => {
        // Reload auth token on new connection in case CommandPost restarted
        this.loadAuthToken();
        resolveConnection();
      });

      socket.on("message", (data: WebSocket.Data) => {
        this.handleIncomingMessage(data);
      });

      socket.on("error", (err: Error) => {
        if (!this.reconnecting) {
          rejectConnection(
            new Error(
              `WebSocket error: ${err.message}. Is CommandPost running with WebSocket enabled?`
            )
          );
        }
      });

      socket.on("close", () => {
        if (this.ws === socket) {
          this.ws = null;
        }

        rejectConnection(
          new Error("Connection to CommandPost closed before it became ready.")
        );

        // Reject all pending requests
        for (const [id, pending] of this.pendingRequests) {
          clearTimeout(pending.timeout);
          pending.reject(new Error("Connection closed"));
          this.pendingRequests.delete(id);
        }
      });
    });

    return this.connectPromise;
  }

  async disconnect(): Promise<void> {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    this.connectPromise = null;
    for (const [id, pending] of this.pendingRequests) {
      clearTimeout(pending.timeout);
      pending.reject(new Error("Disconnected from CommandPost"));
      this.pendingRequests.delete(id);
    }
    this.pendingRequests.clear();
    this.seenIds.clear();
  }

  async ensureConnected(): Promise<void> {
    if (!this.isConnected()) {
      await this.connect();
    }
  }

  private nextId(): string {
    return `mcp-${++this.messageCounter}-${Date.now()}`;
  }

  private handleIncomingMessage(data: WebSocket.Data): void {
    const text = data.toString();
    if (!text || text === "") return;

    let message: CommandPostResponse;
    try {
      message = JSON.parse(text);
    } catch {
      return; // Ignore non-JSON messages
    }

    // Match response to pending request by ID
    if (message.id) {
      // Deduplicate (response may arrive via both callback return and broadcast)
      if (this.seenIds.has(message.id)) return;
      this.seenIds.set(message.id, this.messageCounter);

      // Evict oldest entries when limit is reached (Map iterates in insertion order)
      if (this.seenIds.size > CommandPostClient.SEEN_IDS_MAX) {
        const deleteCount = this.seenIds.size - CommandPostClient.SEEN_IDS_MAX;
        let deleted = 0;
        for (const key of this.seenIds.keys()) {
          if (deleted >= deleteCount) break;
          this.seenIds.delete(key);
          deleted++;
        }
      }

      const pending = this.pendingRequests.get(message.id);
      if (pending) {
        clearTimeout(pending.timeout);
        this.pendingRequests.delete(message.id);

        if (message.status === "error") {
          // If auth failed, force-reload token for next request
          if (message.error && message.error.includes("Authentication failed")) {
            this.loadAuthToken(true);
          }
          pending.reject(
            new Error(message.error || "Unknown error from CommandPost")
          );
        } else {
          pending.resolve(message);
        }
      }
    }
  }

  private static readonly MAX_PENDING_REQUESTS = 100;

  private async sendRaw(
    messageObj: Record<string, unknown>,
    timeoutMs = 30000
  ): Promise<CommandPostResponse> {
    await this.ensureConnected();

    // Refresh auth token if TTL expired or missing
    this.loadAuthToken();

    if (this.pendingRequests.size >= CommandPostClient.MAX_PENDING_REQUESTS) {
      throw new Error(
        `Too many pending requests (${this.pendingRequests.size}). CommandPost may be unresponsive.`
      );
    }

    // Inject auth token into every message
    const authenticatedMsg = this.authToken
      ? { ...messageObj, auth: this.authToken }
      : messageObj;

    const id = messageObj.id as string;
    const messageStr = JSON.stringify(authenticatedMsg);

    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(id);
        const socket = this.ws;
        this.ws = null;
        this.connectPromise = null;
        if (socket) {
          try {
            socket.terminate();
          } catch {
            // Ignore socket teardown failures on timeout.
          }
        }
        reject(
          new Error(
            `Request timed out after ${timeoutMs}ms. CommandPost may be busy or unresponsive.`
          )
        );
      }, timeoutMs);

      this.pendingRequests.set(id, {
        resolve: resolve as (value: unknown) => void,
        reject,
        timeout,
      });

      this.ws!.send(messageStr, (err) => {
        if (err) {
          clearTimeout(timeout);
          this.pendingRequests.delete(id);
          const socket = this.ws;
          this.ws = null;
          this.connectPromise = null;
          if (socket) {
            try {
              socket.terminate();
            } catch {
              // Ignore socket teardown failures after send errors.
            }
          }
          reject(new Error(`Failed to send message: ${err.message}`));
        }
      });
    });
  }

  // ── High-level API methods ──────────────────────────────────────────

  /** Ping CommandPost to check connectivity */
  async ping(): Promise<CommandPostResponse> {
    const id = this.nextId();
    return this.sendRaw({ type: "ping", id });
  }

  /** Execute arbitrary Lua code in CommandPost's environment */
  async executeLua(
    code: string,
    timeoutMs = 30000
  ): Promise<CommandPostResponse> {
    const id = this.nextId();
    return this.sendRaw(
      { type: "execute", id, payload: { code } },
      timeoutMs
    );
  }

  /** Execute a registered action handler */
  async executeAction(
    handler: string,
    actionId?: string,
    parameters?: Record<string, unknown>
  ): Promise<CommandPostResponse> {
    const id = this.nextId();
    return this.sendRaw({
      type: "command",
      id,
      payload: { handler, actionId, parameters },
    });
  }

  /** Query for available handlers or handler info */
  async query(
    queryType: string,
    payload?: Record<string, unknown>
  ): Promise<CommandPostResponse> {
    const id = this.nextId();
    return this.sendRaw({
      type: "query",
      id,
      payload: { query: queryType, ...payload },
    });
  }

  /** Execute a batch of operations sequentially */
  async executeBatch(
    operations: Array<Record<string, unknown>>,
    stopOnError = true,
    timeoutMs = 60000
  ): Promise<CommandPostResponse> {
    const id = this.nextId();
    return this.sendRaw(
      {
        type: "batch",
        id,
        payload: { operations, stopOnError },
      },
      timeoutMs
    );
  }
}
