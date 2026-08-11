/**
 * Quick MCP timeline demo.
 *
 * Usage:
 *   node test-edit-workflow-mini.mjs
 *
 * This is a non-destructive-first demo:
 * - shows timeline
 * - performs a few navigation and marker operations
 * - logs each step
 * - undoes the marker operations at the end
 */

import { spawn } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SERVER_PATH = join(__dirname, "dist", "index.js");

class MCPTestClient {
  constructor() {
    this.proc = null;
    this.buffer = "";
    this.idCounter = 0;
    this.pendingRequests = new Map();
  }

  start() {
    return new Promise((resolve, reject) => {
      this.proc = spawn("node", [SERVER_PATH], {
        stdio: ["pipe", "pipe", "pipe"],
        env: process.env,
      });

      this.proc.stdout.on("data", (data) => {
        this.buffer += data.toString();
        this.#processBuffer();
      });

      this.proc.stderr.on("data", () => {});
      this.proc.on("error", reject);

      this.#send("initialize", {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: { name: "edit-workflow-mini", version: "1.0.0" },
      }, 10000)
        .then((resp) => {
          this.proc.stdin.write(
            JSON.stringify({
              jsonrpc: "2.0",
              method: "notifications/initialized",
              params: {},
            }) + "\n",
          );
          resolve(resp);
        })
        .catch(reject);
    });
  }

  stop() {
    if (this.proc) {
      this.proc.kill();
      this.proc = null;
    }
    for (const [, { reject, timeout }] of this.pendingRequests) {
      clearTimeout(timeout);
      reject(new Error("Client stopped"));
    }
    this.pendingRequests.clear();
  }

  callTool(name, args = {}, timeoutMs = 30000) {
    return this.#send("tools/call", { name, arguments: args }, timeoutMs);
  }

  #send(method, params, timeoutMs = 30000) {
    const id = ++this.idCounter;
    const msg = JSON.stringify({ jsonrpc: "2.0", id, method, params });
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(id);
        reject(new Error(`Request ${method} (id=${id}) timed out after ${timeoutMs / 1000}s`));
      }, timeoutMs);
      this.pendingRequests.set(id, { resolve, reject, timeout });
      this.proc.stdin.write(msg + "\n");
    });
  }

  #processBuffer() {
    const lines = this.buffer.split("\n");
    this.buffer = lines.pop() || "";
    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        const msg = JSON.parse(line);
        if (msg.id !== undefined && this.pendingRequests.has(msg.id)) {
          const { resolve, timeout } = this.pendingRequests.get(msg.id);
          clearTimeout(timeout);
          this.pendingRequests.delete(msg.id);
          resolve(msg);
        }
      } catch {
        // ignore
      }
    }
  }
}

function parsePayload(response) {
  const text = response?.result?.content?.[0]?.text;
  if (!text) return response;
  try {
    return JSON.parse(text);
  } catch {
    return { success: false, error: `Non-JSON tool response: ${text}` };
  }
}

function expectSuccessful(payload, context) {
  if (payload?.success === false) {
    throw new Error(`${context} failed: ${payload.error || "unknown error"}`);
  }
}

async function callTool(client, name, args = {}, timeoutMs = 30000) {
  const response = await client.callTool(name, args, timeoutMs);
  const payload = parsePayload(response);
  expectSuccessful(payload, name);
  if (payload?.error) {
    throw new Error(`${name} failed: ${payload.error}`);
  }
  return payload;
}

async function main() {
  const client = new MCPTestClient();
  const undoableSteps = [];

  try {
    await client.start();
    console.log("[step] MCP server connected");

    await callTool(client, "fcp_timeline_show");
    await callTool(client, "fcp_timeline_zoom", { action: "fit" });
    const before = await callTool(client, "fcp_list_markers");
    const beforeCount = before?.count ?? before?.markers?.length ?? 0;
    console.log(`[before] markers: ${beforeCount}`);

    await callTool(client, "fcp_set_playhead_position", { timecode: "00:00:00:00" });
    const markerOne = await callTool(client, "fcp_add_marker", { name: "MCP Mini Marker 1" });
    undoableSteps.push("marker");
    console.log("[edit] added:", markerOne.marker, markerOne.name);

    await callTool(client, "fcp_timeline_navigate", { action: "next_edit" }).catch(() => {
      // next_edit is optional depending on timeline content; continue with warning.
      console.log("[warn] next_edit unavailable, continuing");
    });

    const markerTwo = await callTool(client, "fcp_add_marker", { name: "MCP Mini Marker 2" });
    undoableSteps.push("marker");
    console.log("[edit] added:", markerTwo.marker, markerTwo.name);

    const after = await callTool(client, "fcp_list_markers");
    const afterCount = after?.count ?? after?.markers?.length ?? 0;
    console.log(`[after] markers: ${afterCount}`);

    console.log("[done] demo sequence completed");
  } catch (error) {
    console.error("[error]", error.stack || String(error));
    process.exitCode = 1;
  } finally {
    if (client.proc) {
      if (undoableSteps.length > 0) {
        try {
          await callTool(client, "fcp_undo_redo", {
            action: "undo",
            count: undoableSteps.length,
          }, 45000);
          console.log(`[cleanup] undid ${undoableSteps.length} marker action(s)`);
        } catch (undoErr) {
          console.error("[warn] cleanup undo failed:", undoErr.message || undoErr);
        }
      }
    }
    client.stop();
  }
}

main().catch((err) => {
  console.error(err.stack || String(err));
  process.exit(1);
});
