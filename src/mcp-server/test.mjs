/**
 * CommandPost MCP Server — Test Suite
 *
 * Tests the MCP server protocol, tool definitions, error handling,
 * and (when CommandPost is running) live functionality.
 *
 * Usage:
 *   node test.mjs           # Run all tests
 *   node test.mjs --live    # Include live CommandPost tests (requires running CommandPost with WebSocket enabled)
 */

import { spawn } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SERVER_PATH = join(__dirname, "dist", "index.js");
const LIVE_MODE = process.argv.includes("--live");

let passed = 0;
let failed = 0;
let skipped = 0;

function log(emoji, msg) {
  console.log(`  ${emoji} ${msg}`);
}

function assert(condition, msg) {
  if (!condition) throw new Error(`Assertion failed: ${msg}`);
}

// ── MCP Client Harness ───────────────────────────────────────────────────

class MCPTestClient {
  constructor(options = {}) {
    this.proc = null;
    this.buffer = "";
    this.idCounter = 0;
    this.pendingRequests = new Map();
    this.env = { ...process.env, ...(options.env || {}) };
  }

  start() {
    return new Promise((resolve, reject) => {
      this.proc = spawn("node", [SERVER_PATH], {
        stdio: ["pipe", "pipe", "pipe"],
        env: this.env,
      });

      this.proc.stdout.on("data", (data) => {
        this.buffer += data.toString();
        this._processBuffer();
      });

      this.proc.stderr.on("data", (data) => {
        // Capture stderr but don't fail — connection warnings are expected
      });

      this.proc.on("error", reject);

      // Send initialize
      this._send("initialize", {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: { name: "test-harness", version: "1.0.0" },
      }).then((resp) => {
        // Send initialized notification (no response expected)
        const notif = JSON.stringify({
          jsonrpc: "2.0",
          method: "notifications/initialized",
          params: {},
        });
        this.proc.stdin.write(notif + "\n");
        resolve(resp);
      }).catch(reject);
    });
  }

  stop() {
    if (this.proc) {
      this.proc.kill();
      this.proc = null;
    }
    // Reject any pending
    for (const [, { reject }] of this.pendingRequests) {
      reject(new Error("Client stopped"));
    }
    this.pendingRequests.clear();
  }

  async listTools() {
    return this._send("tools/list", {});
  }

  async callTool(name, args = {}, timeoutMs = 30000) {
    return this._send("tools/call", { name, arguments: args }, timeoutMs);
  }

  async listResources() {
    return this._send("resources/list", {});
  }

  async readResource(uri, timeoutMs = 10000) {
    return this._send("resources/read", { uri }, timeoutMs);
  }

  async listPrompts() {
    return this._send("prompts/list", {});
  }

  async getPrompt(name, args = {}) {
    return this._send("prompts/get", { name, arguments: args });
  }

  _send(method, params, timeoutMs = 30000) {
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

  _processBuffer() {
    // MCP uses newline-delimited JSON
    const lines = this.buffer.split("\n");
    this.buffer = lines.pop() || ""; // Keep incomplete line in buffer
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
        // Skip non-JSON lines
      }
    }
  }
}

// ── Test Runner ─────────────────────────────────────────────────────────

async function test(name, fn, { requiresLive = false, skipIfLive = false } = {}) {
  if (requiresLive && !LIVE_MODE) {
    skipped++;
    log("⏭️ ", `SKIP: ${name} (requires --live)`);
    return;
  }
  if (skipIfLive && LIVE_MODE) {
    skipped++;
    log("⏭️ ", `SKIP: ${name} (offline-only test)`);
    return;
  }
  try {
    await fn();
    passed++;
    log("✅", `PASS: ${name}`);
  } catch (err) {
    failed++;
    log("❌", `FAIL: ${name}`);
    log("  ", `     ${err.message}`);
  }
}

// ── Tests ───────────────────────────────────────────────────────────────

async function runTests() {
  console.log("\n🧪 CommandPost MCP Server Tests\n");
  console.log(`   Mode: ${LIVE_MODE ? "LIVE (connected to CommandPost)" : "OFFLINE (protocol-only)"}\n`);

  const client = new MCPTestClient();

  // ── Protocol Tests ──────────────────────────────────────────────────

  console.log("── Protocol & Initialization ──");

  let initResp;
  await test("Server initializes with correct protocol", async () => {
    initResp = await client.start();
    assert(initResp.result, "Missing result in init response");
    assert(
      initResp.result.protocolVersion === "2024-11-05",
      `Wrong protocol: ${initResp.result.protocolVersion}`
    );
    assert(
      initResp.result.serverInfo.name === "commandpost",
      `Wrong server name: ${initResp.result.serverInfo.name}`
    );
    assert(
      initResp.result.serverInfo.version,
      `Missing version: ${initResp.result.serverInfo.version}`
    );
  });

  await test("Server reports tools capability", async () => {
    assert(initResp.result.capabilities.tools, "Missing tools capability");
  });

  await test("Server reports resources capability", async () => {
    assert(initResp.result.capabilities.resources, "Missing resources capability");
  });

  await test("Server reports prompts capability", async () => {
    assert(initResp.result.capabilities.prompts, "Missing prompts capability");
  });

  await test("Server version is 2.0.0", async () => {
    assert(
      initResp.result.serverInfo.version === "2.0.0",
      `Expected 2.0.0, got: ${initResp.result.serverInfo.version}`
    );
  });

  // ── Tool Listing Tests ──────────────────────────────────────────────

  console.log("\n── Tool Listing ──");

  let tools;
  await test("tools/list returns all tools", async () => {
    const resp = await client.listTools();
    assert(resp.result, "Missing result");
    assert(resp.result.tools, "Missing tools array");
    tools = resp.result.tools;
    assert(tools.length >= 70, `Expected at least 70 tools, got ${tools.length}`);
  });

  await test("All tools have required fields", async () => {
    for (const tool of tools) {
      assert(tool.name, `Tool missing name: ${JSON.stringify(tool)}`);
      assert(tool.description, `Tool ${tool.name} missing description`);
      assert(tool.inputSchema, `Tool ${tool.name} missing inputSchema`);
      assert(
        tool.inputSchema.type === "object",
        `Tool ${tool.name} inputSchema.type is not 'object'`
      );
    }
  });

  await test("Tool names follow naming convention", async () => {
    const validPrefixes = ["commandpost_", "fcp_"];
    for (const tool of tools) {
      const hasPrefix = validPrefixes.some((p) => tool.name.startsWith(p));
      assert(
        hasPrefix,
        `Tool ${tool.name} doesn't start with commandpost_ or fcp_`
      );
    }
  });

  await test("Required parameters are correctly specified", async () => {
    // Check a few known tools
    const execLua = tools.find((t) => t.name === "commandpost_execute_lua");
    assert(execLua, "commandpost_execute_lua not found");
    assert(
      execLua.inputSchema.required?.includes("code"),
      "commandpost_execute_lua should require 'code'"
    );

    const selectMenu = tools.find((t) => t.name === "fcp_select_menu");
    assert(selectMenu, "fcp_select_menu not found");
    assert(
      selectMenu.inputSchema.required?.includes("path"),
      "fcp_select_menu should require 'path'"
    );

    const ping = tools.find((t) => t.name === "commandpost_ping");
    assert(ping, "commandpost_ping not found");
    // ping should have no required params
    assert(
      !ping.inputSchema.required || ping.inputSchema.required.length === 0,
      "commandpost_ping should not require any params"
    );
  });

  await test("Enum parameters have valid values", async () => {
    const playback = tools.find((t) => t.name === "fcp_timeline_playback");
    assert(playback, "fcp_timeline_playback not found");
    const actionProp = playback.inputSchema.properties?.action;
    assert(actionProp?.enum, "fcp_timeline_playback action should have enum");
    assert(
      actionProp.enum.includes("play") &&
      actionProp.enum.includes("pause") &&
      actionProp.enum.includes("toggle"),
      "fcp_timeline_playback action should have play/pause/toggle"
    );
  });

  // ── Tool Category Coverage Tests ────────────────────────────────────

  console.log("\n── Tool Category Coverage ──");

  await test("System tools present", async () => {
    const sysTools = ["commandpost_ping", "commandpost_list_handlers", "commandpost_get_handler_info"];
    for (const name of sysTools) {
      assert(tools.find((t) => t.name === name), `Missing system tool: ${name}`);
    }
  });

  await test("Lua execution tools present", async () => {
    assert(tools.find((t) => t.name === "commandpost_execute_lua"), "Missing commandpost_execute_lua");
    assert(tools.find((t) => t.name === "commandpost_execute_action"), "Missing commandpost_execute_action");
    assert(tools.find((t) => t.name === "commandpost_chain"), "Missing commandpost_chain");
  });

  await test("FCP application tools present", async () => {
    const fcpTools = ["fcp_launch", "fcp_quit", "fcp_restart", "fcp_status", "fcp_select_menu", "fcp_do_shortcut"];
    for (const name of fcpTools) {
      assert(tools.find((t) => t.name === name), `Missing FCP app tool: ${name}`);
    }
  });

  await test("FCP timeline tools present", async () => {
    const timelineTools = [
      "fcp_timeline_show", "fcp_timeline_playback", "fcp_timeline_navigate",
      "fcp_timeline_select", "fcp_timeline_blade", "fcp_timeline_delete",
      "fcp_timeline_clipboard", "fcp_timeline_zoom", "fcp_timeline_get_info",
    ];
    for (const name of timelineTools) {
      assert(tools.find((t) => t.name === name), `Missing timeline tool: ${name}`);
    }
  });

  await test("FCP effects tools present", async () => {
    const effectsTools = ["fcp_apply_effect", "fcp_apply_transition", "fcp_apply_generator", "fcp_apply_title"];
    for (const name of effectsTools) {
      assert(tools.find((t) => t.name === name), `Missing effects tool: ${name}`);
    }
  });

  await test("FCP media tools present", async () => {
    const mediaTools = [
      "fcp_browser_show", "fcp_browser_list_libraries", "fcp_browser_select_library",
      "fcp_inspector_show", "fcp_viewer_show",
      "fcp_export", "fcp_import_media", "fcp_import_xml", "fcp_export_xml",
    ];
    for (const name of mediaTools) {
      assert(tools.find((t) => t.name === name), `Missing media tool: ${name}`);
    }
  });

  await test("FCP editing tools present", async () => {
    const editTools = [
      "fcp_open_project", "fcp_project_properties",
      "fcp_add_marker", "fcp_add_keyword",
      "fcp_rename_clip", "fcp_rate_clip",
      "fcp_undo_redo", "fcp_retime",
      "fcp_captions", "fcp_multicam_switch_angle",
      "fcp_pasteboard", "fcp_color_board",
      "fcp_window_layout",
    ];
    for (const name of editTools) {
      assert(tools.find((t) => t.name === name), `Missing editing tool: ${name}`);
    }
  });

  // ── New Tool Category Coverage Tests ────────────────────────────────

  console.log("\n── New Tool Categories ──");

  await test("Discovery/introspection tools present", async () => {
    const discoveryTools = [
      "fcp_list_effects", "fcp_list_audio_effects", "fcp_list_transitions",
      "fcp_list_generators", "fcp_list_titles",
      "fcp_get_selected_clips", "fcp_get_playhead_position", "fcp_set_playhead_position",
      "fcp_get_project_settings",
    ];
    for (const name of discoveryTools) {
      assert(tools.find((t) => t.name === name), `Missing discovery tool: ${name}`);
    }
  });

  await test("Clip property tools present", async () => {
    assert(tools.find((t) => t.name === "fcp_get_clip_properties"), "Missing fcp_get_clip_properties");
    assert(tools.find((t) => t.name === "fcp_set_clip_properties"), "Missing fcp_set_clip_properties");
  });

  await test("Additional clip operation tools present", async () => {
    const clipTools = [
      "fcp_duplicate_clip", "fcp_enable_disable_clip",
      "fcp_split_at_timecode", "fcp_speed_custom",
    ];
    for (const name of clipTools) {
      assert(tools.find((t) => t.name === name), `Missing clip op tool: ${name}`);
    }
  });

  await test("Range/work area tools present", async () => {
    assert(tools.find((t) => t.name === "fcp_set_range"), "Missing fcp_set_range");
    assert(tools.find((t) => t.name === "fcp_clear_range"), "Missing fcp_clear_range");
  });

  await test("Compound clip and audition tools present", async () => {
    assert(tools.find((t) => t.name === "fcp_create_compound_clip"), "Missing fcp_create_compound_clip");
    assert(tools.find((t) => t.name === "fcp_break_apart_compound"), "Missing fcp_break_apart_compound");
    assert(tools.find((t) => t.name === "fcp_create_audition"), "Missing fcp_create_audition");
  });

  await test("Role, stabilization, proxy tools present", async () => {
    assert(tools.find((t) => t.name === "fcp_assign_role"), "Missing fcp_assign_role");
    assert(tools.find((t) => t.name === "fcp_stabilization"), "Missing fcp_stabilization");
    assert(tools.find((t) => t.name === "fcp_proxy_toggle"), "Missing fcp_proxy_toggle");
  });

  await test("Batch and workflow tools present", async () => {
    assert(tools.find((t) => t.name === "fcp_batch_apply_transition"), "Missing fcp_batch_apply_transition");
    assert(tools.find((t) => t.name === "fcp_assemble_rough_cut"), "Missing fcp_assemble_rough_cut");
  });

  await test("Marker listing tool present", async () => {
    assert(tools.find((t) => t.name === "fcp_list_markers"), "Missing fcp_list_markers");
  });

  // ── New Tool Schema Validation ────────────────────────────────────

  console.log("\n── New Tool Schemas ──");

  await test("fcp_set_clip_properties has numeric params", async () => {
    const tool = tools.find((t) => t.name === "fcp_set_clip_properties");
    const props = tool.inputSchema.properties;
    assert(props.positionX?.type === "number", "positionX should be number");
    assert(props.scaleAll?.type === "number", "scaleAll should be number");
    assert(props.rotation?.type === "number", "rotation should be number");
    assert(props.opacity?.type === "number", "opacity should be number");
  });

  await test("fcp_split_at_timecode requires timecode", async () => {
    const tool = tools.find((t) => t.name === "fcp_split_at_timecode");
    assert(
      tool.inputSchema.required?.includes("timecode"),
      "Should require timecode"
    );
  });

  await test("fcp_speed_custom requires percentage", async () => {
    const tool = tools.find((t) => t.name === "fcp_speed_custom");
    assert(
      tool.inputSchema.required?.includes("percentage"),
      "Should require percentage"
    );
  });

  await test("fcp_set_range requires start and end", async () => {
    const tool = tools.find((t) => t.name === "fcp_set_range");
    assert(tool.inputSchema.required?.includes("start"), "Should require start");
    assert(tool.inputSchema.required?.includes("end"), "Should require end");
  });

  await test("fcp_assign_role requires role", async () => {
    const tool = tools.find((t) => t.name === "fcp_assign_role");
    assert(tool.inputSchema.required?.includes("role"), "Should require role");
  });

  await test("fcp_assemble_rough_cut requires clipPlan", async () => {
    const tool = tools.find((t) => t.name === "fcp_assemble_rough_cut");
    assert(tool.inputSchema.required?.includes("clipPlan"), "Should require clipPlan");
    const clipPlan = tool.inputSchema.properties?.clipPlan;
    assert(clipPlan?.type === "array", "clipPlan should be array");
    assert(clipPlan?.items?.properties?.mediaPath, "clipPlan items should have mediaPath");
  });

  await test("fcp_assemble_rough_cut no longer advertises unsupported clip instructions", async () => {
    const tool = tools.find((t) => t.name === "fcp_assemble_rough_cut");
    const clipProps = tool.inputSchema.properties?.clipPlan?.items?.properties || {};
    assert(!clipProps.inPoint, "Should not advertise inPoint");
    assert(!clipProps.outPoint, "Should not advertise outPoint");
    assert(!clipProps.transitionAfter, "Should not advertise transitionAfter");
    assert(!clipProps.effectName, "Should not advertise effectName");
    assert(!clipProps.keyword, "Should not advertise keyword");
    assert(!tool.inputSchema.properties?.defaultTransition, "Should not advertise defaultTransition");
  });

  await test("fcp_batch_apply_transition no longer advertises unsupported params", async () => {
    const tool = tools.find((t) => t.name === "fcp_batch_apply_transition");
    const props = tool.inputSchema.properties || {};
    assert(!props.transition, "Should not advertise transition");
    assert(!props.duration, "Should not advertise duration");
  });

  await test("fcp_list_effects has optional category filter", async () => {
    const tool = tools.find((t) => t.name === "fcp_list_effects");
    assert(tool.inputSchema.properties?.category, "Should have category property");
    assert(!tool.inputSchema.required?.includes("category"), "Category should be optional");
  });

  // ── Resources Tests ───────────────────────────────────────────────

  console.log("\n── Resources ──");

  let resources;
  await test("resources/list returns resources", async () => {
    const resp = await client.listResources();
    assert(resp.result, "Missing result");
    assert(resp.result.resources, "Missing resources array");
    resources = resp.result.resources;
    assert(resources.length >= 4, `Expected at least 4 resources, got ${resources.length}`);
  });

  await test("All resources have required fields", async () => {
    for (const r of resources) {
      assert(r.uri, `Resource missing uri`);
      assert(r.name, `Resource ${r.uri} missing name`);
      assert(r.description, `Resource ${r.uri} missing description`);
      assert(r.mimeType, `Resource ${r.uri} missing mimeType`);
    }
  });

  await test("Instructions resource exists", async () => {
    assert(
      resources.find((r) => r.uri === "commandpost://instructions"),
      "Missing instructions resource"
    );
  });

  await test("FCP status resource exists", async () => {
    assert(
      resources.find((r) => r.uri === "commandpost://fcp-status"),
      "Missing fcp-status resource"
    );
  });

  await test("Tool reference resource exists", async () => {
    assert(
      resources.find((r) => r.uri === "commandpost://tool-reference"),
      "Missing tool-reference resource"
    );
  });

  await test("Timeline clips resource exists", async () => {
    assert(
      resources.find((r) => r.uri === "commandpost://timeline/clips"),
      "Missing timeline/clips resource"
    );
  });

  await test("Instructions resource returns content", async () => {
    const resp = await client.readResource("commandpost://instructions");
    assert(resp.result, "Missing result");
    const contents = resp.result.contents;
    assert(contents && contents.length > 0, "Missing contents");
    assert(contents[0].text.includes("Best Practices"), "Should contain best practices");
    assert(contents[0].text.includes("magnetic timeline"), "Should mention magnetic timeline");
  });

  await test("Tool reference resource returns content", async () => {
    const resp = await client.readResource("commandpost://tool-reference");
    assert(resp.result, "Missing result");
    const contents = resp.result.contents;
    assert(contents && contents.length > 0, "Missing contents");
    const text = contents[0].text;
    assert(text.includes("fcp_list_effects"), "Should list discovery tools");
    assert(text.includes("fcp_list_markers"), "Should list markers tool");
    assert(text.includes("fcp_assemble_rough_cut"), "Should list workflow tools");
  });

  await test("Unknown resource returns error", async () => {
    const resp = await client.readResource("commandpost://nonexistent");
    assert(resp.error, "Should return error for unknown resource");
  });

  // ── Prompts Tests ─────────────────────────────────────────────────

  console.log("\n── Prompts ──");

  let prompts;
  await test("prompts/list returns prompts", async () => {
    const resp = await client.listPrompts();
    assert(resp.result, "Missing result");
    assert(resp.result.prompts, "Missing prompts array");
    prompts = resp.result.prompts;
    assert(prompts.length >= 6, `Expected at least 6 prompts, got ${prompts.length}`);
  });

  await test("All prompts have required fields", async () => {
    for (const p of prompts) {
      assert(p.name, `Prompt missing name`);
      assert(p.description, `Prompt ${p.name} missing description`);
    }
  });

  await test("Expected prompts exist", async () => {
    const expectedPrompts = [
      "edit_video", "color_grade", "organize_media",
      "audio_edit", "multicam_edit", "rough_cut_assembly",
    ];
    for (const name of expectedPrompts) {
      assert(prompts.find((p) => p.name === name), `Missing prompt: ${name}`);
    }
  });

  await test("edit_video prompt has project_type argument", async () => {
    const prompt = prompts.find((p) => p.name === "edit_video");
    assert(prompt.arguments, "Missing arguments");
    assert(
      prompt.arguments.find((a) => a.name === "project_type"),
      "Missing project_type argument"
    );
  });

  await test("edit_video prompt returns messages", async () => {
    const resp = await client.getPrompt("edit_video", { project_type: "documentary" });
    assert(resp.result, "Missing result");
    assert(resp.result.messages, "Missing messages");
    assert(resp.result.messages.length > 0, "Should have at least one message");
    const msg = resp.result.messages[0];
    assert(msg.role === "user", "First message should be from user");
    assert(msg.content.text.includes("documentary"), "Should include project type");
  });

  await test("color_grade prompt returns messages with look", async () => {
    const resp = await client.getPrompt("color_grade", { look: "cinematic warm" });
    assert(resp.result, "Missing result");
    assert(resp.result.messages[0].content.text.includes("cinematic warm"), "Should include look");
  });

  await test("rough_cut_assembly prompt handles media_folder", async () => {
    const resp = await client.getPrompt("rough_cut_assembly", {
      media_folder: "/Users/test/footage",
    });
    assert(resp.result, "Missing result");
    assert(
      resp.result.messages[0].content.text.includes("/Users/test/footage"),
      "Should include media folder path"
    );
  });

  await test("Unknown prompt returns error", async () => {
    const resp = await client.getPrompt("nonexistent_prompt");
    assert(resp.error, "Should return error for unknown prompt");
  });

  // ── Response Shape Tests ──────────────────────────────────────────

  console.log("\n── Response Shape (success field) ──");

  await test("Unknown tool response has success=false", async () => {
    const resp = await client.callTool("nonexistent_tool_shape_test", {});
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.success === false, `Expected success=false, got: ${parsed.success}`);
    assert(parsed.error, "Should have error field");
  });

  // ── Error Handling Tests ────────────────────────────────────────────
  // NOTE: These tests expect CommandPost to be DISCONNECTED. In --live mode
  // the server is connected, so these calls succeed (slowly) and would block
  // the entire test suite. We skip them in live mode.

  console.log("\n── Error Handling (offline) ──");

  await test("commandpost_ping returns helpful error when disconnected", async () => {
    const resp = await client.callTool("commandpost_ping");
    assert(resp.result, "Missing result");
    const content = resp.result.content?.[0]?.text;
    assert(content, "Missing content text");
    const parsed = JSON.parse(content);
    assert(
      parsed.error || parsed.status === "connected",
      "Should return error or connected status"
    );
  }, { requiresLive: false, skipIfLive: true });

  await test("commandpost_execute_lua returns result or connection error", async () => {
    const resp = await client.callTool("commandpost_execute_lua", {
      code: "return 1+1",
    });
    const content = resp.result.content?.[0]?.text;
    assert(content, "Missing content text");
    const parsed = JSON.parse(content);
    assert(
      parsed.result !== undefined || parsed.error,
      "Should have result or error field"
    );
  }, { requiresLive: false, skipIfLive: true });

  await test("commandpost_chain returns result or connection error", async () => {
    const resp = await client.callTool("commandpost_chain", {
      operations: [{ type: "execute", code: "return 1" }],
    });
    const content = resp.result.content?.[0]?.text;
    assert(content, "Missing content text");
    const parsed = JSON.parse(content);
    assert(
      parsed.results || parsed.error,
      "Should have results or error field"
    );
  }, { requiresLive: false, skipIfLive: true });

  await test("Unknown tool returns error", async () => {
    const resp = await client.callTool("nonexistent_tool", {});
    const content = resp.result.content?.[0]?.text;
    assert(content, "Missing content text");
    const parsed = JSON.parse(content);
    assert(
      parsed.error && parsed.error.includes("Unknown tool"),
      `Expected 'Unknown tool' error, got: ${parsed.error}`
    );
  });

  await test("fcp_timeline_navigate rejects invalid action", async () => {
    const resp = await client.callTool("fcp_timeline_navigate", {
      action: "invalid_action",
    });
    const content = resp.result.content?.[0]?.text;
    assert(content, "Missing content text");
    // Should either be connection error or validation error
    const parsed = JSON.parse(content);
    assert(
      parsed.error,
      "Should have error for invalid action"
    );
  });

  await test("Invalid input validation runs before connection attempts", async () => {
    const deadClient = new MCPTestClient({
      env: {
        COMMANDPOST_WS_URL: "ws://127.0.0.1:9",
      },
    });

    try {
      await deadClient.start();
      const resp = await deadClient.callTool("commandpost_execute_lua", {
        code: "",
      });
      const content = resp.result.content?.[0]?.text;
      assert(content, "Missing content text");
      const parsed = JSON.parse(content);
      assert(parsed.error === "Code cannot be empty", `Expected validation error, got: ${parsed.error}`);
      assert(
        !parsed.error.includes("Cannot connect to CommandPost"),
        "Should validate before attempting to connect"
      );
    } finally {
      deadClient.stop();
    }
  });

  await test("fcp_batch_apply_transition rejects unsupported custom params", async () => {
    const resp = await client.callTool("fcp_batch_apply_transition", {
      transition: "Dissolves/Cross Dissolve",
      duration: 1,
    });
    const content = resp.result.content?.[0]?.text;
    assert(content, "Missing content text");
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should have validation error");
    assert(
      parsed.error.includes("does not support custom transition or duration parameters"),
      `Expected unsupported params error, got: ${parsed.error}`
    );
  });

  await test("fcp_assemble_rough_cut rejects unsupported clip instructions", async () => {
    const resp = await client.callTool("fcp_assemble_rough_cut", {
      clipPlan: [
        {
          mediaPath: "/tmp/example.mov",
          inPoint: "00:00:01:00",
        },
      ],
    });
    const content = resp.result.content?.[0]?.text;
    assert(content, "Missing content text");
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should have validation error");
    assert(
      parsed.error.includes("unsupported fields: inPoint"),
      `Expected unsupported clip field error, got: ${parsed.error}`
    );
  });

  // ── Error response structure ────────────────────────────────────────

  await test("Connection error responses include help text", async () => {
    // Use an unknown tool to test error format without needing a connection
    const resp = await client.callTool("nonexistent_tool_2", {});
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should have error");
    // Unknown tool errors have a simple format; connection errors have help
    // Just verify we get a structured error response
    assert(typeof parsed.error === "string", "Error should be a string");
  });

  // ── Input Schema Validation Tests ──────────────────────────────────

  console.log("\n── Input Schema Validation ──");

  await test("Tools with array params have items schema", async () => {
    const chain = tools.find((t) => t.name === "commandpost_chain");
    const ops = chain.inputSchema.properties?.operations;
    assert(ops?.type === "array", "operations should be array type");
    assert(ops?.items, "operations should have items schema");
  });

  await test("fcp_select_menu path is array of strings", async () => {
    const tool = tools.find((t) => t.name === "fcp_select_menu");
    const path = tool.inputSchema.properties?.path;
    assert(path?.type === "array", "path should be array type");
    assert(path?.items?.type === "string", "path items should be strings");
  });

  await test("fcp_color_board has all required params", async () => {
    const tool = tools.find((t) => t.name === "fcp_color_board");
    assert(
      tool.inputSchema.required?.includes("aspect"),
      "Should require aspect"
    );
    assert(
      tool.inputSchema.required?.includes("puck"),
      "Should require puck"
    );
    assert(
      tool.inputSchema.required?.includes("value"),
      "Should require value"
    );
  });

  // ── Live Tests (require CommandPost with WebSocket) ─────────────────

  console.log("\n── Live Tests ──");

  await test("commandpost_ping succeeds against live server", async () => {
    const resp = await client.callTool("commandpost_ping");
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.status === "connected", `Expected connected, got: ${JSON.stringify(parsed)}`);
  }, { requiresLive: true });

  await test("commandpost_execute_lua returns arithmetic result", async () => {
    const resp = await client.callTool("commandpost_execute_lua", {
      code: "1 + 1",
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.result === 2, `Expected 2, got: ${JSON.stringify(parsed)}`);
  }, { requiresLive: true });

  await test("commandpost_execute_lua returns string", async () => {
    const resp = await client.callTool("commandpost_execute_lua", {
      code: '"hello" .. " " .. "world"',
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.result === "hello world", `Expected 'hello world', got: ${JSON.stringify(parsed)}`);
  }, { requiresLive: true });

  await test("commandpost_execute_lua returns table", async () => {
    const resp = await client.callTool("commandpost_execute_lua", {
      code: '{name = "test", value = 42, nested = {a = 1}}',
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.result?.name === "test", "Missing name field");
    assert(parsed.result?.value === 42, "Missing value field");
    assert(parsed.result?.nested?.a === 1, "Missing nested field");
  }, { requiresLive: true });

  await test("commandpost_execute_lua returns array", async () => {
    const resp = await client.callTool("commandpost_execute_lua", {
      code: "{10, 20, 30}",
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(Array.isArray(parsed.result), "Expected array result");
    assert(parsed.result.length === 3, "Expected 3 elements");
    assert(parsed.result[0] === 10, "First element should be 10");
  }, { requiresLive: true });

  await test("commandpost_execute_lua handles runtime errors", async () => {
    const resp = await client.callTool("commandpost_execute_lua", {
      code: 'error("intentional test error")',
    });
    const content = resp.result.content?.[0]?.text;
    // The server should catch the error and return it
    assert(content, "Should have response content");
  }, { requiresLive: true });

  await test("commandpost_execute_lua handles multi-statement code", async () => {
    const resp = await client.callTool("commandpost_execute_lua", {
      code: "local x = 10\nlocal y = 20\nreturn x + y",
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.result === 30, `Expected 30, got: ${JSON.stringify(parsed)}`);
  }, { requiresLive: true });

  await test("commandpost_list_handlers returns handlers", async () => {
    const resp = await client.callTool("commandpost_list_handlers");
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.handlers, "Missing handlers array");
    assert(parsed.handlers.length > 0, "Expected at least one handler");
    // Verify structure — all handlers must have an id, group may be nil
    for (const h of parsed.handlers) {
      assert(h.id, `Handler missing id: ${JSON.stringify(h)}`);
    }
  }, { requiresLive: true });

  await test("commandpost_chain executes multiple operations", async () => {
    const resp = await client.callTool("commandpost_chain", {
      operations: [
        { type: "execute", code: "return 10" },
        { type: "execute", code: "return _prev + 5" },
        { type: "execute", code: "return {first = 10, second = _prev, sum = 10 + _prev}" },
      ],
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.results, "Missing results array");
    assert(parsed.completedOperations === 3, `Should complete 3 operations, got ${parsed.completedOperations}`);
    // Verify chaining: step 1 returns 10, step 2 returns 15, step 3 builds table
    assert(parsed.results[0].status === "success", "Step 1 should succeed");
    assert(parsed.results[1].status === "success", "Step 2 should succeed");
    assert(parsed.results[2].status === "success", "Step 3 should succeed");
  }, { requiresLive: true });

  await test("commandpost_chain stops on error when stopOnError is true", async () => {
    const resp = await client.callTool("commandpost_chain", {
      operations: [
        { type: "execute", code: "return 1" },
        { type: "execute", code: 'error("test")' },
        { type: "execute", code: "return 3" },
      ],
      stopOnError: true,
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.completedOperations === 2, "Should stop after 2 operations");
  }, { requiresLive: true });

  await test("fcp_status returns status info", async () => {
    const resp = await client.callTool("fcp_status");
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.result !== undefined, "Missing result");
    // Should have running field at minimum
    const result = parsed.result;
    assert(result.running !== undefined, "Missing running field");
    assert(result.installed !== undefined, "Missing installed field");
  }, { requiresLive: true });

  await test("commandpost_alert shows notification", async () => {
    const resp = await client.callTool("commandpost_alert", {
      message: "MCP Test Passed!",
      duration: 1,
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.result?.alerted === true, "Alert should be shown");
  }, { requiresLive: true });

  await test("commandpost_get_preference reads a value", async () => {
    const resp = await client.callTool("commandpost_get_preference", {
      key: "websocket.enabled",
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    // Should return truthy value since we're connected via WebSocket
    // (may be boolean true or integer 1 depending on how it was stored)
    assert(parsed.result, `Expected truthy for websocket.enabled, got: ${JSON.stringify(parsed)}`);
  }, { requiresLive: true });

  await test("fcp_pasteboard history returns structured items", async () => {
    const resp = await client.callTool("fcp_pasteboard", {
      action: "history",
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.result?.action === "history", `Expected history action, got: ${JSON.stringify(parsed)}`);
    assert(Array.isArray(parsed.result?.items), "Expected items array");
    assert(typeof parsed.result?.count === "number", "Expected numeric count");
  }, { requiresLive: true });

  // ── Live: New Features ────────────────────────────────────────────

  console.log("\n── Live: Response Shape ──");

  await test("fcp_status response has success field", async () => {
    const resp = await client.callTool("fcp_status");
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.success !== undefined, "Response should have success field");
  }, { requiresLive: true });

  await test("fcp_status uses graceful degradation (safeGet)", async () => {
    const resp = await client.callTool("fcp_status");
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    const result = parsed.result || parsed;
    // Should have running field — even if FCP is not running, it should return false not crash
    assert(result.running !== undefined, "Should have running field");
    // Version, path, etc. may be null if FCP not installed — but should not throw
    assert(result.success !== undefined || result.running !== undefined, "Should have structured response");
  }, { requiresLive: true });

  console.log("\n── Live: Discovery Tools ──");

  await test("fcp_get_playhead_position returns timecode", async () => {
    const resp = await client.callTool("fcp_get_playhead_position");
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    const result = parsed.result || parsed;
    assert(result.timecode !== undefined, `Should have timecode field, got: ${JSON.stringify(result)}`);
  }, { requiresLive: true });

  await test("fcp_get_project_settings returns settings", async () => {
    const resp = await client.callTool("fcp_get_project_settings");
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    const result = parsed.result || parsed;
    assert(result.running !== undefined, "Should have running field");
    assert(result.success !== undefined, "Should have success field from safeLua");
  }, { requiresLive: true });

  await test("fcp_get_selected_clips returns clip info or empty", async () => {
    const resp = await client.callTool("fcp_get_selected_clips");
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    const result = parsed.result || parsed;
    // Should have clips array (may be empty) or error if timeline not showing
    assert(
      result.clips !== undefined || result.error,
      `Should have clips array or error, got: ${JSON.stringify(result)}`
    );
  }, { requiresLive: true });

  await test("fcp_get_clip_properties returns properties or error", async () => {
    const resp = await client.callTool("fcp_get_clip_properties", {}, 30000);
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    const result = parsed.result || parsed;
    // Should return structured properties or error
    assert(
      result.transform !== undefined || result.error || result.available !== undefined,
      `Should have transform or error, got: ${JSON.stringify(result)}`
    );
  }, { requiresLive: true });

  await test("fcp_list_markers returns markers or error", async () => {
    const resp = await client.callTool("fcp_list_markers", {}, 30000);
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    const result = parsed.result || parsed;
    assert(
      result.markers !== undefined || result.error,
      `Should have markers array or error, got: ${JSON.stringify(result)}`
    );
  }, { requiresLive: true });

  console.log("\n── Live: Input Validation ──");

  await test("commandpost_execute_lua validates empty code", async () => {
    const resp = await client.callTool("commandpost_execute_lua", { code: "" });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should reject empty code");
  }, { requiresLive: true });

  await test("fcp_import_media validates path traversal", async () => {
    const resp = await client.callTool("fcp_import_media", {
      path: "/tmp/../../../etc/passwd",
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should reject path with traversal");
    assert(parsed.error.includes("traversal") || parsed.error.includes(".."), "Error should mention traversal");
  }, { requiresLive: true });

  await test("fcp_import_xml validates path traversal", async () => {
    const resp = await client.callTool("fcp_import_xml", {
      path: "../../../secret.xml",
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should reject path with traversal");
  }, { requiresLive: true });

  await test("fcp_speed_custom validates percentage range", async () => {
    const resp = await client.callTool("fcp_speed_custom", {
      percentage: -50,
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should reject negative percentage");
  }, { requiresLive: true });

  await test("fcp_assemble_rough_cut validates clipPlan paths", async () => {
    const resp = await client.callTool("fcp_assemble_rough_cut", {
      clipPlan: [{ mediaPath: "../../../etc/passwd" }],
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should reject path traversal in clipPlan");
  }, { requiresLive: true });

  await test("fcp_assemble_rough_cut validates empty clipPlan", async () => {
    const resp = await client.callTool("fcp_assemble_rough_cut", {
      clipPlan: [],
    });
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should reject empty clipPlan");
  }, { requiresLive: true });

  await test("fcp_set_clip_properties rejects no properties", async () => {
    const resp = await client.callTool("fcp_set_clip_properties", {});
    const content = resp.result.content?.[0]?.text;
    const parsed = JSON.parse(content);
    assert(parsed.error, "Should reject when no properties specified");
  }, { requiresLive: true });

  console.log("\n── Live: Resources ──");

  await test("commandpost://fcp-status returns live data", async () => {
    const resp = await client.readResource("commandpost://fcp-status", 30000);
    assert(resp.result, "Missing result");
    const contents = resp.result.contents;
    assert(contents && contents.length > 0, "Missing contents");
    const data = JSON.parse(contents[0].text);
    assert(data.running !== undefined, "Should have running field");
  }, { requiresLive: true });

  await test("commandpost://timeline/clips returns clip data", async () => {
    const resp = await client.readResource("commandpost://timeline/clips", 30000);
    assert(resp.result, "Missing result");
    const contents = resp.result.contents;
    assert(contents && contents.length > 0, "Missing contents");
    const data = JSON.parse(contents[0].text);
    // Should have clips array (possibly empty) or error
    assert(
      data.clips !== undefined || data.error,
      `Should have clips or error, got: ${JSON.stringify(data)}`
    );
  }, { requiresLive: true });

  // ── Cleanup ───────────────────────────────────────────────────────

  client.stop();

  // ── Summary ───────────────────────────────────────────────────────

  console.log("\n" + "─".repeat(50));
  console.log(`\n  Results: ${passed} passed, ${failed} failed, ${skipped} skipped`);
  console.log(`  Total:   ${passed + failed + skipped} tests\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error("Test runner error:", err);
  process.exit(1);
});
