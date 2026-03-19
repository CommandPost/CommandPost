/**
 * Dedicated live edit-workflow smoke test for Final Cut Pro via CommandPost MCP.
 *
 * This script is intentionally separate from test.mjs because it performs
 * destructive timeline edits against a user-provided project.
 *
 * Usage:
 *   node test-edit-workflow.mjs
 *   node test-edit-workflow.mjs --project "MCP Edit Tests"
 *
 * Notes:
 *   - This workflow expects the target timeline/project to already be open in
 *     Final Cut Pro. Project switching is exercised separately because FCP can
 *     become non-deterministic while reopening the same project repeatedly.
 */

import { spawn } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SERVER_PATH = join(__dirname, "dist", "index.js");
const argv = process.argv.slice(2);
const PROJECT_NAME = getFlagValue("--project") || "MCP Edit Tests";

function getFlagValue(flag) {
  const index = argv.indexOf(flag);
  if (index === -1 || index === argv.length - 1) return null;
  return argv[index + 1];
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function log(step, message) {
  console.log(`[${step}] ${message}`);
}

function parseTimecodeToFrames(timecode, fps = 30) {
  if (typeof timecode !== "string") return null;
  const match = timecode.match(/^(\d{2}):(\d{2}):(\d{2}):(\d{2})$/);
  if (!match) return null;
  const [, hh, mm, ss, ff] = match;
  return (((Number(hh) * 60 + Number(mm)) * 60 + Number(ss)) * fps) + Number(ff);
}

function framesToTimecode(frames, fps = 30) {
  const totalFrames = Math.max(0, Math.floor(frames));
  const ff = totalFrames % fps;
  const totalSeconds = Math.floor(totalFrames / fps);
  const ss = totalSeconds % 60;
  const totalMinutes = Math.floor(totalSeconds / 60);
  const mm = totalMinutes % 60;
  const hh = Math.floor(totalMinutes / 60);
  return [hh, mm, ss, ff].map((value) => String(value).padStart(2, "0")).join(":");
}

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
        clientInfo: { name: "edit-workflow-test", version: "1.0.0" },
      }, 10000).then((resp) => {
        this.proc.stdin.write(JSON.stringify({
          jsonrpc: "2.0",
          method: "notifications/initialized",
          params: {},
        }) + "\n");
        resolve(resp);
      }).catch(reject);
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

  async callTool(name, args = {}, timeoutMs = 30000) {
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
        // Ignore non-JSON lines.
      }
    }
  }
}

function parseToolResponse(resp) {
  const text = resp?.result?.content?.[0]?.text;
  if (!text) return resp;
  try {
    return JSON.parse(text);
  } catch {
    return { success: false, error: `Non-JSON tool response: ${text}` };
  }
}

function extractPayload(parsed) {
  return parsed?.result ?? parsed;
}

async function main() {
  const client = new MCPTestClient();
  const summary = [];

  async function call(name, args = {}, timeoutMs = 30000) {
    const resp = await client.callTool(name, args, timeoutMs);
    const parsed = parseToolResponse(resp);
    summary.push({ name, args, parsed });
    return parsed;
  }

  async function expectTool(name, args = {}, options = {}) {
    const { timeoutMs = 30000, verify } = options;
    const parsed = await call(name, args, timeoutMs);
    const payload = extractPayload(parsed);

    if (parsed?.success === false) {
      throw new Error(`${name} failed: ${parsed.error || "unknown error"}`);
    }
    if (payload?.error) {
      throw new Error(`${name} failed: ${payload.error}`);
    }

    if (verify) {
      await verify(payload, parsed);
    }

    await assertNoAlert(name);

    return payload;
  }

  async function resolveHandlerChoice(handler, preferredCategory, preferredName) {
    const parsed = await call("commandpost_get_handler_info", {
      handler,
      includeChoices: true,
      includeParams: true,
      limit: 500,
    }, 30000);
    if (parsed?.success === false) {
      throw new Error(`commandpost_get_handler_info failed for ${handler}: ${parsed.error}`);
    }
    const info = parsed?.handler || extractPayload(parsed)?.handler || extractPayload(parsed);
    const choices = info?.choices || [];
    const match = choices.find((choice) =>
      choice?.params?.category === preferredCategory
      && choice?.params?.name === preferredName
    );
    if (!match) {
      throw new Error(
        `No ${handler} choice matched ${preferredCategory}/${preferredName}`
      );
    }
    return `${preferredCategory}/${preferredName}`;
  }

  async function getTimelineInfo(timeoutMs = 60000) {
    const parsed = await call("fcp_timeline_get_info", {}, timeoutMs);
    if (parsed?.success === false) {
      throw new Error(`fcp_timeline_get_info failed: ${parsed.error}`);
    }
    const payload = extractPayload(parsed);
    if (payload?.error) {
      throw new Error(`fcp_timeline_get_info failed: ${payload.error}`);
    }
    return payload;
  }

  async function getUndoState(timeoutMs = 30000) {
    const result = await runLua(`
      local fcp = require("cp.apple.finalcutpro")
      local state = {
        showing = false,
        loaded = false,
      }

      pcall(function()
        state.showing = fcp.timeline:isShowing()
        state.loaded = fcp.timeline:isLoaded()
      end)

      pcall(function()
        local app = fcp:application()
        local menus = app and app:getMenuItems()
        if menus then
          for _, menu in ipairs(menus) do
            if menu.AXTitle == "Edit" then
              local group = menu.AXChildren and menu.AXChildren[1]
              local undoItem = group and group[1]
              state.undoText = undoItem and undoItem.AXTitle or nil
              break
            end
          end
        end
      end)

      return state
    `, timeoutMs);

    const payload = extractPayload(result);
    if (payload?.error) {
      throw new Error(payload.error);
    }
    return payload;
  }

  async function getCurrentProjectState(timeoutMs = 30000) {
    const result = await runLua(`
      local fcp = require("cp.apple.finalcutpro")
      local state = {
        showing = false,
        loaded = false,
      }

      pcall(function()
        state.showing = fcp.timeline:isShowing()
        state.loaded = fcp.timeline:isLoaded()
      end)

      pcall(function()
        state.projectTitle = fcp.timeline.toolbar.title:title()
      end)

      if not state.projectTitle then
        pcall(function()
          state.projectTitle = fcp.timeline.toolbar.title:value()
        end)
      end

      return state
    `, timeoutMs);

    const payload = extractPayload(result);
    if (payload?.error) {
      throw new Error(payload.error);
    }
    return payload;
  }

  async function waitForTimelineVisible(timeoutMs = 30000) {
    const deadline = Date.now() + timeoutMs;
    let lastInfo = null;
    let attempts = 0;

    while (Date.now() < deadline) {
      attempts += 1;
      if (attempts > 1) {
        await expectTool("fcp_timeline_show");
      }

      lastInfo = await getTimelineInfo();
      if (lastInfo?.showing === true) {
        return lastInfo;
      }

      await new Promise((resolve) => setTimeout(resolve, 1000));
    }

    throw new Error(`Timeline did not become visible: ${JSON.stringify({
      attempts,
      lastInfo: lastInfo ? {
        showing: lastInfo.showing,
        clipCount: lastInfo.clipCount,
        undoText: lastInfo.undoText,
      } : null,
    })}`);
  }

  async function runLua(code, timeoutMs = 30000) {
    const parsed = await call("commandpost_execute_lua", { code }, timeoutMs);
    if (parsed?.success === false) {
      throw new Error(`commandpost_execute_lua failed: ${parsed.error}`);
    }
    const payload = extractPayload(parsed);
    if (payload?.error) {
      throw new Error(`commandpost_execute_lua failed: ${payload.error}`);
    }
    return payload;
  }

  async function assertNoAlert(context) {
    const result = await runLua(`
      local ax = require("hs.axuielement")
      local app = hs.application("Final Cut Pro")
      local appUI = app and ax.applicationElement(app)
      if not appUI then
        return {alert = false}
      end

      local function dismiss(window)
        local children = window:attributeValue("AXChildren") or {}
        for _, child in ipairs(children) do
          local role = child:attributeValue("AXRole")
          local title = child:attributeValue("AXTitle")
          if role == "AXButton" and (title == "OK" or title == "Done") then
            pcall(function() child:performAction("AXPress") end)
            hs.timer.usleep(150000)
            return true
          end
        end
        return false
      end

      local windows = appUI:attributeValue("AXWindows") or {}
      for _, window in ipairs(windows) do
        local role = window:attributeValue("AXRole")
        local subrole = window:attributeValue("AXSubrole")
        local children = window:attributeValue("AXChildren") or {}
        local texts = {}
        if role == "AXWindow" or role == "AXDialog" or subrole == "AXDialog" then
          for _, child in ipairs(children) do
            local childRole = child:attributeValue("AXRole")
            local value = child:attributeValue("AXValue")
            if childRole == "AXStaticText" and value and tostring(value) ~= "" then
              table.insert(texts, tostring(value))
            end
          end
          if #texts > 0 then
            local dismissed = dismiss(window)
            return {
              alert = true,
              message = table.concat(texts, " "),
              dismissed = dismissed,
            }
          end
        end
      end

      return {alert = false}
    `, 15000);

    const payload = extractPayload(result);
    if (payload?.alert) {
      throw new Error(`${context} triggered Final Cut Pro alert: ${payload.message}`);
    }
  }

  async function selectAvClips(count) {
    const result = await runLua(`
      local fcp = require("cp.apple.finalcutpro")
      local contents = fcp.timeline.contents
      local ui = contents:UI()
      if not ui then
        return {selected = false, error = "Timeline UI is unavailable"}
      end

      pcall(function() contents:doFocus(true):Now() end)
      hs.timer.usleep(150000)

      local children = ui:attributeValue("AXChildren") or {}
      local selected = {}
      for _, child in ipairs(children) do
        local desc = child:attributeValue("AXDescription") or ""
        if string.sub(desc, 1, 8) == "AV-Clip:" then
          table.insert(selected, child)
          if #selected >= ${count} then
            break
          end
        end
      end

      if #selected < ${count} then
        return {
          selected = false,
          error = "Need at least ${count} AV clips",
          count = #selected,
        }
      end

      contents:selectClips(selected)
      hs.timer.usleep(200000)

      local selectedChildren = ui:attributeValue("AXSelectedChildren") or {}
      local descriptions = {}
      for _, child in ipairs(selectedChildren) do
        descriptions[#descriptions + 1] = child:attributeValue("AXDescription") or ""
      end

      return {
        selected = #selectedChildren >= ${count},
        count = #selectedChildren,
        descriptions = descriptions,
      }
    `, 30000);

    const payload = extractPayload(result);
    if (!payload?.selected) {
      throw new Error(payload?.error || `Could not select ${count} AV clips`);
    }
    return payload;
  }

  async function selectAdjacentAvClips() {
    const result = await runLua(`
      local fcp = require("cp.apple.finalcutpro")
      local contents = fcp.timeline.contents
      local ui = contents:UI()
      if not ui then
        return {selected = false, error = "Timeline UI is unavailable"}
      end

      pcall(function() contents:doFocus(true):Now() end)
      hs.timer.usleep(150000)

      local playheadX = contents.playhead and contents.playhead:position()
      local laneTolerance = 4
      local boundaryTolerance = 8

      local function clipRecord(child)
        local desc = child:attributeValue("AXDescription") or ""
        local frame = child:attributeValue("AXFrame")
        if string.sub(desc, 1, 8) ~= "AV-Clip:"
          or not frame
          or type(frame.x) ~= "number"
          or type(frame.y) ~= "number"
          or type(frame.w) ~= "number"
        then
          return nil
        end
        return {
          ui = child,
          description = desc,
          x = frame.x,
          y = frame.y,
          w = frame.w,
        }
      end

      local function sortClips(clips)
        table.sort(clips, function(a, b)
          if math.abs(a.y - b.y) <= laneTolerance then
            return a.x < b.x
          end
          return a.y < b.y
        end)
      end

      local function describeClips(clips, limit)
        local description = {}
        for i, clip in ipairs(clips or {}) do
          if i > (limit or 10) then break end
          description[#description + 1] = {
            description = clip.description,
            x = clip.x,
            y = clip.y,
            w = clip.w,
            endX = clip.x + clip.w,
          }
        end
        return description
      end

      local function collectVisibleClips()
        local clips = {}
        local children = ui:attributeValue("AXChildren") or {}
        for _, child in ipairs(children) do
          local record = clipRecord(child)
          if record then
            clips[#clips + 1] = record
          end
        end
        sortClips(clips)
        return clips
      end

      local function collectPlayheadClips()
        local clips = {}
        local playheadClips = contents:playheadClipsUI(true, function(clip)
          local desc = clip:attributeValue("AXDescription") or ""
          return string.sub(desc, 1, 8) == "AV-Clip:"
        end) or {}
        for _, clip in ipairs(playheadClips) do
          local record = clipRecord(clip)
          if record then
            clips[#clips + 1] = record
          end
        end
        sortClips(clips)
        return clips
      end

      local function chooseBoundaryPair(clips)
        if type(playheadX) ~= "number" then
          return nil
        end

        local bestPair = nil
        local bestScore = nil

        for _, left in ipairs(clips or {}) do
          local leftEnd = left.x + left.w
          if leftEnd <= (playheadX + boundaryTolerance) then
            for _, right in ipairs(clips or {}) do
              if right.ui ~= left.ui
                and math.abs(left.y - right.y) <= laneTolerance
                and right.x >= (playheadX - boundaryTolerance)
              then
                local score = math.abs(leftEnd - playheadX) + math.abs(right.x - playheadX)
                if bestScore == nil or score < bestScore then
                  bestPair = {left.ui, right.ui}
                  bestScore = score
                end
              end
            end
          end
        end

        return bestPair, bestScore
      end

      local function chooseNearestSequentialPair(clips)
        local bestPair = nil
        local bestScore = nil

        for i = 1, (#clips - 1) do
          local first = clips[i]
          local second = clips[i + 1]
          if math.abs(first.y - second.y) <= laneTolerance then
            local gap = math.abs((first.x + first.w) - second.x)
            local score = gap
            if type(playheadX) == "number" then
              score = score + math.abs((first.x + first.w) - playheadX) + math.abs(second.x - playheadX)
            end
            if bestScore == nil or score < bestScore then
              bestPair = {first.ui, second.ui}
              bestScore = score
            end
          end
        end

        if bestScore ~= nil and bestScore <= (boundaryTolerance * 3) then
          return bestPair, bestScore
        end
        return nil, bestScore
      end

      local playheadClips = collectPlayheadClips()
      local pair, score = chooseBoundaryPair(playheadClips)

      if not pair and #playheadClips >= 2 then
        pair, score = chooseNearestSequentialPair(playheadClips)
      end

      local visibleClips = nil
      if not pair then
        visibleClips = collectVisibleClips()
        pair, score = chooseBoundaryPair(visibleClips)
      end

      if not pair then
        visibleClips = visibleClips or collectVisibleClips()
        pair, score = chooseNearestSequentialPair(visibleClips)
      end

      if not pair then
        return {
          selected = false,
          error = "Need adjacent AV clips on the same timeline lane",
          playheadX = playheadX,
          playheadClips = describeClips(playheadClips, 8),
          visibleClips = describeClips(visibleClips or collectVisibleClips(), 12),
        }
      end

      contents:selectClips(pair)
      hs.timer.usleep(200000)

      local selectedChildren = ui:attributeValue("AXSelectedChildren") or {}
      local descriptions = {}
      for _, child in ipairs(selectedChildren) do
        descriptions[#descriptions + 1] = child:attributeValue("AXDescription") or ""
      end

      return {
        selected = #selectedChildren >= 2,
        count = #selectedChildren,
        descriptions = descriptions,
        playheadX = playheadX,
        score = score,
      }
    `, 30000);

    const payload = extractPayload(result);
    if (!payload?.selected) {
      const diagnostics = JSON.stringify({
        playheadX: payload?.playheadX,
        playheadClips: payload?.playheadClips,
        visibleClips: payload?.visibleClips,
      });
      throw new Error(`${payload?.error || "Could not select adjacent AV clips"} ${diagnostics}`);
    }
    return payload;
  }

  function countByPrefix(info, prefix) {
    const clips = Array.isArray(info?.clips) ? info.clips : [];
    return clips.filter((clip) => String(clip?.description || "").startsWith(prefix)).length;
  }

  async function findBladeTimecode() {
    const result = await runLua(`
      local fcp = require("cp.apple.finalcutpro")
      local contents = fcp.timeline.contents
      local ui = contents:UI()
      if not ui then
        return {error = "Timeline UI is unavailable"}
      end

      pcall(function() contents:doFocus(true):Now() end)
      hs.timer.usleep(150000)

      local playheadX = contents.playhead and contents.playhead:position()
      local currentTimecode = fcp.viewer:timecode()
      local children = ui:attributeValue("AXChildren") or {}
      local candidate = nil

      for _, child in ipairs(children) do
        local description = child:attributeValue("AXDescription") or ""
        local duration = child:attributeValue("AXValue")
        local frame = child:attributeValue("AXFrame")
        if string.sub(description, 1, 8) == "AV-Clip:"
          and type(duration) == "string"
          and frame
          and type(frame.x) == "number"
          and type(frame.w) == "number"
          and frame.w >= 24
        then
          candidate = {
            description = description,
            duration = duration,
            x = frame.x,
            w = frame.w,
          }
          contents:selectClip(child)
          hs.timer.usleep(150000)
          break
        end
      end

      return {
        playheadX = playheadX,
        currentTimecode = currentTimecode,
        candidate = candidate,
      }
    `, 30000);

    const payload = extractPayload(result);
    if (payload?.error) {
      throw new Error(payload.error);
    }

    const candidate = payload?.candidate;
    const durationFrames = parseTimecodeToFrames(candidate?.duration);
    const currentFrames = parseTimecodeToFrames(payload?.currentTimecode);
    const playheadX = Number(payload?.playheadX);
    const clipX = Number(candidate?.x);
    const clipWidth = Number(candidate?.w);

    if (!candidate || !durationFrames || !Number.isFinite(currentFrames) || !Number.isFinite(playheadX)
      || !Number.isFinite(clipX) || !Number.isFinite(clipWidth) || clipWidth <= 0) {
      throw new Error("Could not derive a bladable AV clip target from the visible timeline geometry");
    }

    const inset = Math.max(6, Math.min(24, Math.floor(clipWidth / 4)));
    const targetX = clipX + Math.max(inset, Math.min(clipWidth - inset, Math.floor(clipWidth / 2)));
    const deltaFrames = Math.round((targetX - playheadX) * (durationFrames / clipWidth));
    return framesToTimecode(currentFrames + deltaFrames);
  }

  try {
    await client.start();

    log("setup", `Preparing current timeline for "${PROJECT_NAME}"`);
    await expectTool("fcp_timeline_show");
    const baseline = await waitForTimelineVisible(45000);
    await expectTool("fcp_timeline_zoom", { action: "fit" });
    assert(baseline.showing === true, "Timeline is not visible");
    assert(countByPrefix(baseline, "AV-Clip:") >= 1, "Need at least one AV clip in the test project");

    await expectTool("fcp_browser_show", { panel: "generators" });
    await expectTool("fcp_browser_show", { panel: "libraries" });
    await expectTool("fcp_inspector_show", { tab: "video" });

    const generatorId = await resolveHandlerChoice("fcpx_generator", "Solids", "Custom");
    const effectId = await resolveHandlerChoice("fcpx_videoEffect", "Basics", "Noise Reduction");
    const transitionId = await resolveHandlerChoice("fcpx_transition", "Dissolves", "Cross Dissolve");

    log("menu", "Insert a spacer/gap via the Edit menu");
    const gapBefore = await getTimelineInfo();
    await expectTool("fcp_set_playhead_position", { timecode: "00:00:01:00" }, { timeoutMs: 20000 });
    await expectTool("fcp_select_menu", { path: ["Edit", "Insert Generator", "Gap"] }, {
      timeoutMs: 20000,
    });
    await new Promise((resolve) => setTimeout(resolve, 600));
    const gapAfter = await getTimelineInfo();
    const gapCountBefore = countByPrefix(gapBefore, "Gap:");
    const gapCountAfter = countByPrefix(gapAfter, "Gap:");
    assert(
      gapAfter.clipCount > gapBefore.clipCount
        || gapCountAfter > gapCountBefore
        || String(gapAfter.undoText || "") !== String(gapBefore.undoText || ""),
      `Gap insert did not change the timeline: ${JSON.stringify({
        gapBefore: {
          clipCount: gapBefore.clipCount,
          gapCount: gapCountBefore,
          undoText: gapBefore.undoText,
        },
        gapAfter: {
          clipCount: gapAfter.clipCount,
          gapCount: gapCountAfter,
          undoText: gapAfter.undoText,
        },
      })}`
    );

    log("generator", "Apply a generator to the timeline");
    const genBefore = await getTimelineInfo();
    await expectTool("fcp_apply_generator", { name: generatorId }, {
      timeoutMs: 30000,
    });
    await new Promise((resolve) => setTimeout(resolve, 1200));
    const genAfter = await getTimelineInfo();
    const generatorCountBefore = countByPrefix(genBefore, "Generator:");
    const generatorCountAfter = countByPrefix(genAfter, "Generator:");
    assert(
      generatorCountAfter > generatorCountBefore
        || String(genAfter.undoText || "") !== String(genBefore.undoText || ""),
      `Generator insert did not create a verifiable change: ${JSON.stringify({
        genBefore: {
          clipCount: genBefore.clipCount,
          generatorCount: generatorCountBefore,
          undoText: genBefore.undoText,
        },
        genAfter: {
          clipCount: genAfter.clipCount,
          generatorCount: generatorCountAfter,
          undoText: genAfter.undoText,
        },
      })}`
    );

    log("effect", "Select one AV clip and apply a video effect");
    const effectBefore = await getUndoState();
    const singleSelection = await selectAvClips(1);
    assert(singleSelection.count >= 1, "Expected one selected AV clip");
    await expectTool("fcp_apply_effect", { name: effectId, type: "video" }, {
      timeoutMs: 30000,
    });
    await new Promise((resolve) => setTimeout(resolve, 1200));
    const effectAfter = await getUndoState();
    assert(
      String(effectAfter.undoText || "") !== String(effectBefore.undoText || ""),
      `Video effect apply did not register a new undo step: ${JSON.stringify({
        effectBefore: effectBefore.undoText,
        effectAfter: effectAfter.undoText,
      })}`
    );

    log("color", "Open the video inspector and apply a small color-board change");
    await expectTool("fcp_inspector_show", { tab: "video" });
    const colorBefore = await getUndoState();
    await expectTool("fcp_color_board", {
      aspect: "exposure",
      puck: "master",
      value: 0.03,
    }, {
      timeoutMs: 30000,
    });
    await new Promise((resolve) => setTimeout(resolve, 1200));
    const colorAfter = await getUndoState();
    assert(
      String(colorAfter.undoText || "") !== String(colorBefore.undoText || ""),
      `Color board apply did not register a new undo step: ${JSON.stringify({
        colorBefore: colorBefore.undoText,
        colorAfter: colorAfter.undoText,
      })}`
    );

    log("blade", "Create a fresh cut point inside a real AV clip");
    const bladeBefore = await getTimelineInfo();
    const bladeTargetTimecode = await findBladeTimecode();
    await expectTool("fcp_set_playhead_position", {
      timecode: bladeTargetTimecode,
    }, { timeoutMs: 20000 });
    const bladeResult = await expectTool("fcp_timeline_blade", {}, {
      timeoutMs: 30000,
    });
    assert(bladeResult.cut === true, "Blade did not report a successful cut");
    assert(
      String(bladeResult.undoText || "").startsWith("Undo Blade"),
      "Blade did not register as the last Final Cut Pro action"
    );
    const bladeAfter = await getTimelineInfo();
    assert(
      bladeAfter.clipCount > bladeBefore.clipCount
        || String(bladeAfter.undoText || "").startsWith("Undo Blade"),
      "Blade did not leave a verifiable change in Final Cut Pro"
    );

    log("transition", "Select the new adjacent AV clips and apply a transition");
    const transitionBefore = await getTimelineInfo();
    const twoSelection = await selectAdjacentAvClips();
    assert(twoSelection.count >= 2, "Expected two selected AV clips");
    const transitionResult = await expectTool("fcp_apply_transition", { name: transitionId }, {
      timeoutMs: 30000,
    });
    await new Promise((resolve) => setTimeout(resolve, 1200));
    const transitionAfter = await getTimelineInfo();
    const transitionCountBefore = countByPrefix(transitionBefore, "Transition:");
    const transitionCountAfter = countByPrefix(transitionAfter, "Transition:");
    assert(
      transitionResult.applied === true
        || transitionCountAfter > transitionCountBefore
        || String(transitionAfter.undoText || "") !== String(transitionBefore.undoText || ""),
      `Transition apply did not produce a verifiable change: ${JSON.stringify({
        transitionResult,
        transitionBefore: {
          undoText: transitionBefore.undoText,
          clipCount: transitionBefore.clipCount,
          transitionCount: transitionCountBefore,
        },
        transitionAfter: {
          undoText: transitionAfter.undoText,
          clipCount: transitionAfter.clipCount,
          transitionCount: transitionCountAfter,
        },
        selection: twoSelection,
      })}`
    );

    log("navigation", "Move through browser and timeline views");
    await expectTool("fcp_browser_show", { panel: "generators" });
    await expectTool("fcp_browser_show", { panel: "media" });
    await expectTool("fcp_timeline_navigate", { action: "next_edit" });
    await expectTool("fcp_timeline_navigate", { action: "previous_edit" });

    const finalInfo = await getTimelineInfo();
    console.log("\nWorkflow smoke test passed.");
    console.log(JSON.stringify({
      project: PROJECT_NAME,
      destructive: true,
      baselineClipCount: baseline.clipCount,
      finalClipCount: finalInfo.clipCount,
      baselineTransitionCount: countByPrefix(baseline, "Transition:"),
      finalTransitionCount: countByPrefix(finalInfo, "Transition:"),
      baselineGeneratorCount: countByPrefix(baseline, "Generator:"),
      finalGeneratorCount: countByPrefix(finalInfo, "Generator:"),
    }, null, 2));
  } catch (error) {
    console.error("\nWorkflow smoke test failed.");
    console.error(error.stack || String(error));
    console.error("\nLast tool calls:");
    console.error(JSON.stringify(summary.slice(-12).map((entry) => ({
      name: entry.name,
      args: entry.args,
      success: entry.parsed?.success,
      error: entry.parsed?.error || entry.parsed?.result?.error || null,
      keys: Object.keys(entry.parsed || {}),
    })), null, 2));
    process.exitCode = 1;
  } finally {
    if (client.proc) {
      const destructiveSteps = summary.reduce((count, entry) => {
        const payload = extractPayload(entry.parsed);
        if (entry.parsed?.success === false || payload?.error) {
          return count;
        }
        if (entry.name === "fcp_select_menu" && entry.args?.path?.join?.("/") === "Edit/Insert Generator/Gap") {
          return count + 1;
        }
        if (entry.name === "fcp_apply_generator" || entry.name === "fcp_apply_effect"
          || entry.name === "fcp_color_board" || entry.name === "fcp_timeline_blade"
          || entry.name === "fcp_apply_transition") {
          return count + 1;
        }
        return count;
      }, 0);

      if (destructiveSteps > 0) {
        try {
          log("cleanup", `Undo ${destructiveSteps} destructive step(s)`);
          await call("fcp_undo_redo", { action: "undo", count: destructiveSteps }, 45000);
        } catch (error) {
          console.error(`Cleanup undo failed: ${error.message || error}`);
        }
      }
    }
    client.stop();
  }
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
