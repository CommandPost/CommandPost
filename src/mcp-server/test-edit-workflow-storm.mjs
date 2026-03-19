/**
 * High-volume timeline edit stress demo.
 *
 * Usage:
 *   node test-edit-workflow-storm.mjs
 *
 * This runs a larger sequence of MCP timeline actions (markers + effects +
 * generators + transitions) to prove the connection can execute repeated edits.
 */

import { spawn } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SERVER_PATH = join(__dirname, "dist", "index.js");

const EDIT_CYCLES = 24;
const TRANSITION_INTERVAL = 4;
const EFFECT_INTERVAL = 2;
const GENERATOR_INTERVAL = 3;

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
        clientInfo: { name: "edit-workflow-storm", version: "1.0.0" },
      }, 12000)
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

  callTool(name, args = {}, timeoutMs = 45000) {
    return this.#send("tools/call", { name, arguments: args }, timeoutMs);
  }

  #send(method, params, timeoutMs = 45000) {
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

function ensureSuccess(payload, label) {
  if (payload?.success === false) {
    throw new Error(`${label} failed: ${payload.error || "unknown error"}`);
  }
}

async function safeCall(client, name, args, timeoutMs = 45000) {
  try {
    const resp = await client.callTool(name, args, timeoutMs);
    const payload = parsePayload(resp);
    if (payload?.error) {
      throw new Error(payload.error);
    }
    ensureSuccess(payload, name);
    return payload;
  } catch (error) {
    return { __error: error.message || String(error), _failed: true };
  }
}

async function runLua(client, code, timeoutMs = 45000) {
  const payload = await callTool(client, "commandpost_execute_lua", { code }, timeoutMs);
  if (payload.error) {
    throw new Error(payload.error);
  }
  return payload;
}

async function callTool(client, name, args = {}, timeoutMs = 45000) {
  const resp = await client.callTool(name, args, timeoutMs);
  const payload = parsePayload(resp);
  ensureSuccess(payload, name);
  if (payload?.error) {
    throw new Error(`${name} failed: ${payload.error}`);
  }
  return payload;
}

async function resolveHandlerChoice(client, handler, preferredCategory, preferredName, fallbackNameContains) {
  const payload = await callTool(
    client,
    "commandpost_get_handler_info",
    { handler, includeChoices: true, includeParams: true, limit: 500 },
    30000,
  );
  const handlerInfo = payload?.handler || payload;
  const choices = handlerInfo?.choices || [];

  const exact = choices.find((choice) =>
    choice?.params?.category === preferredCategory
    && choice?.params?.name === preferredName
  );
  if (exact?.params?.category && exact?.params?.name) {
    return `${exact.params.category}/${exact.params.name}`;
  }

  if (fallbackNameContains) {
    const byName = choices.find((choice) =>
      String(choice?.params?.name || "").toLowerCase().includes(fallbackNameContains.toLowerCase())
    );
    if (byName?.params?.category && byName?.params?.name) {
      return `${byName.params.category}/${byName.params.name}`;
    }
  }

  const first = choices.find((choice) => choice?.params?.category && choice?.params?.name);
  if (!first) {
    return null;
  }
  return `${first.params.category}/${first.params.name}`;
}

async function selectFirstClip(client) {
  const payload = await runLua(client, `
    local fcp = require("cp.apple.finalcutpro")
    local contents = fcp.timeline.contents
    local ui = contents:UI()
    if not ui then
      return { selected = false, reason = "No timeline UI" }
    end

    local children = ui:attributeValue("AXChildren") or {}
    local avClip
    for _, child in ipairs(children) do
      local desc = child:attributeValue("AXDescription") or ""
      if string.sub(desc, 1, 8) == "AV-Clip:" then
        avClip = child
        break
      end
    end
    if not avClip then
      return { selected = false, reason = "No AV clips visible" }
    end

    contents:selectClips({avClip})
    hs.timer.usleep(120000)

    local selected = ui:attributeValue("AXSelectedChildren") or {}
    return {
      selected = #selected >= 1,
      count = #selected,
      description = avClip:attributeValue("AXDescription"),
    }
  `);
  return payload;
}

async function selectTwoClipsForTransition(client) {
  const payload = await runLua(client, `
    local fcp = require("cp.apple.finalcutpro")
    local contents = fcp.timeline.contents
    local ui = contents:UI()
    if not ui then
      return { selected = false, reason = "No timeline UI" }
    end

    local candidates = {}
    local children = ui:attributeValue("AXChildren") or {}

    for _, child in ipairs(children) do
      local desc = child:attributeValue("AXDescription") or ""
      local frame = child:attributeValue("AXFrame")
      if string.sub(desc, 1, 8) == "AV-Clip:" and frame then
        table.insert(candidates, {
          ui = child,
          x = frame.x or 0,
          y = frame.y or 0,
        })
      end
    end

    table.sort(candidates, function(a, b)
      if math.abs(a.y - b.y) <= 4 then
        return a.x < b.x
      end
      return a.y < b.y
    end)

    if #candidates < 2 then
      return {
        selected = false,
        count = #candidates,
        reason = "Need two AV clips to apply transition",
      }
    end

    local first = candidates[1].ui
    local second = candidates[2].ui
    contents:selectClips({first, second})
    hs.timer.usleep(150000)

    local selected = ui:attributeValue("AXSelectedChildren") or {}
    return {
      selected = #selected >= 2,
      count = #selected,
      first = first:attributeValue("AXDescription"),
      second = second:attributeValue("AXDescription"),
    }
  `);
  return payload;
}

async function main() {
  const client = new MCPTestClient();
  const counters = {
    marker: 0,
    effect: 0,
    generator: 0,
    transition: 0,
  };

  try {
    await client.start();
    console.log("[step] connected to MCP");

    await safeCall(client, "fcp_timeline_show");
    await safeCall(client, "fcp_timeline_zoom", { action: "fit" });
    await callTool(client, "fcp_timeline_navigate", { action: "beginning" }, 30000);

    const before = await safeCall(client, "fcp_list_markers") || {};
    const beforeCount = Number(before.count || before.markers?.length || 0);
    console.log(`[before] markers ${beforeCount}`);

    const effectChoice = await resolveHandlerChoice(client, "fcpx_videoEffect", "Basics", "Noise Reduction", "Noise");
    const transitionChoice = await resolveHandlerChoice(
      client,
      "fcpx_transition",
      "Dissolves",
      "Cross Dissolve",
      "Cross",
    );
    const generatorChoice = await resolveHandlerChoice(client, "fcpx_generator", "Solids", "Custom", "Custom");

    if (!effectChoice || !transitionChoice || !generatorChoice) {
      throw new Error("Could not resolve required handler choices (effect/transition/generator)");
    }

    console.log(`[resolve] effect=${effectChoice}`);
    console.log(`[resolve] transition=${transitionChoice}`);
    console.log(`[resolve] generator=${generatorChoice}`);

    for (let i = 1; i <= EDIT_CYCLES; i += 1) {
      console.log(`[cycle ${i}]`);

      const nav = i === 1
        ? { action: "beginning" }
        : (i % 2 === 0 ? { action: "next_frame" } : { action: "next_edit" });
      const navResult = await safeCall(client, "fcp_timeline_navigate", nav, 25000);
      if (navResult?.error) {
        await safeCall(client, "fcp_timeline_navigate", { action: "next_frame" }, 25000);
      }

      const markerResult = await safeCall(
        client,
        "fcp_add_marker",
        { name: `MCP Storm Marker ${i}` },
        25000,
      );
      if (!markerResult._failed && !markerResult.__error) {
        counters.marker += 1;
      }

      if (i % EFFECT_INTERVAL === 0) {
        const clipSel = await selectFirstClip(client);
        if (clipSel && clipSel.selected) {
          const effectResult = await safeCall(
            client,
            "fcp_apply_effect",
            { name: effectChoice, type: "video" },
            45000,
          );
          if (!effectResult._failed && !effectResult.__error) {
            counters.effect += 1;
            console.log(`  [effect] applied`);
          }
        }
      }

      if (i % GENERATOR_INTERVAL === 0) {
        const genResult = await safeCall(
          client,
          "fcp_apply_generator",
          { name: generatorChoice },
          45000,
        );
        if (!genResult._failed && !genResult.__error) {
          counters.generator += 1;
          console.log(`  [generator] inserted`);
        }
      }

      if (i % TRANSITION_INTERVAL === 0) {
        const transitionSel = await selectTwoClipsForTransition(client);
        if (transitionSel && transitionSel.selected) {
          const transResult = await safeCall(
            client,
            "fcp_apply_transition",
            { name: transitionChoice },
            45000,
          );
          if (transResult && transResult.applied && !transResult._failed && !transResult.__error) {
            counters.transition += 1;
          }
        }
      }
    }

    const after = await safeCall(client, "fcp_list_markers") || {};
    const afterCount = Number(after.count || after.markers?.length || 0);
    console.log(`[after] markers ${afterCount}`);
    console.log(`[result] marker=${counters.marker}, effect=${counters.effect}, generator=${counters.generator}, transition=${counters.transition}`);
    console.log("[result] stress cycle complete");
  } catch (error) {
    console.error("[error]", error.stack || String(error));
    process.exitCode = 1;
  } finally {
    const undoTotal = counters.marker + counters.effect + counters.generator + counters.transition;
    if (client.proc && undoTotal > 0) {
      try {
        const undoResult = await callTool(client, "fcp_undo_redo", {
          action: "undo",
          count: undoTotal,
        }, 60000);
        console.log(`[cleanup] requested undo ${undoTotal}`);
        console.log(`[cleanup]`, undoResult);
      } catch (undoErr) {
        console.error("[warn] cleanup undo failed:", undoErr.message || undoErr);
      }
    }
    client.stop();
  }
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
