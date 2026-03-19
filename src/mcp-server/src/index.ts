#!/usr/bin/env node

/**
 * CommandPost MCP Server
 *
 * A comprehensive Model Context Protocol server that exposes CommandPost's
 * full automation capabilities — Final Cut Pro control, macOS workflow
 * automation, Lua scripting, action handlers, and operation chaining.
 *
 * Communicates with CommandPost via its built-in WebSocket server.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { CommandPostClient } from "./commandpost.js";

// ═══════════════════════════════════════════════════════════════════════════
// Logging (stderr to avoid polluting MCP JSON-RPC on stdout)
// ═══════════════════════════════════════════════════════════════════════════

function log(level: "info" | "warn" | "error" | "debug", message: string, data?: unknown): void {
  const timestamp = new Date().toISOString();
  const prefix = `[${timestamp}] [commandpost-mcp] [${level.toUpperCase()}]`;
  if (data !== undefined) {
    console.error(`${prefix} ${message}`, typeof data === "string" ? data : JSON.stringify(data));
  } else {
    console.error(`${prefix} ${message}`);
  }
}

const client = new CommandPostClient();

// ═══════════════════════════════════════════════════════════════════════════
// Lua Preamble & Helpers
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Standard Lua preamble injected before tool scripts.
 * Provides commonly-used requires and safe helper functions so individual
 * tool handlers don't need to repeat them.
 */
const LUA_PREAMBLE = `
local fcp = require("cp.apple.finalcutpro")

--- Safely read a value; returns nil on error instead of throwing.
local function safeGet(fn)
  local ok, val = pcall(fn)
  if ok then return val end
  return nil
end

--- Detect and handle FCP modal dialogs (sheets/alerts).
--- Returns a table describing what was found and handled, or nil if no dialog.
--- By default clicks the primary (default) button to proceed.
--- @param preferCancel boolean  If true, click Cancel instead of the default button.
local function handleFCPDialog(preferCancel)
  local result = nil
  pcall(function()
    local app = fcp:application()
    if not app then return end
    local axApp = hs.axuielement.applicationElement(app)
    local windows = axApp:attributeValue("AXWindows") or {}
    for _, w in ipairs(windows) do
      -- Check sheets attached to each window
      local sheets = w:attributeValue("AXSheets") or {}
      for _, sheet in ipairs(sheets) do
        local children = sheet:attributeValue("AXChildren") or {}
        local texts, buttons = {}, {}
        for _, c in ipairs(children) do
          local role = c:attributeValue("AXRole") or ""
          if role == "AXStaticText" then
            table.insert(texts, c:attributeValue("AXValue") or c:attributeValue("AXTitle") or "")
          elseif role == "AXButton" then
            table.insert(buttons, {title = c:attributeValue("AXTitle") or "", element = c})
          end
        end
        if #buttons > 0 then
          result = {dialogType = "sheet", texts = texts, buttonTitles = {}}
          for _, b in ipairs(buttons) do table.insert(result.buttonTitles, b.title) end
          -- Click the appropriate button
          local clicked = false
          if preferCancel then
            for _, b in ipairs(buttons) do
              if b.title == "Cancel" then
                b.element:performAction("AXPress")
                result.clicked = "Cancel"
                clicked = true
                break
              end
            end
          end
          if not clicked then
            -- Click first non-Cancel button (the primary action)
            for _, b in ipairs(buttons) do
              if b.title ~= "Cancel" then
                b.element:performAction("AXPress")
                result.clicked = b.title
                clicked = true
                break
              end
            end
            -- Fallback: click first button
            if not clicked and buttons[1] then
              buttons[1].element:performAction("AXPress")
              result.clicked = buttons[1].title
            end
          end
          return
        end
      end
      -- Also check for modal windows (not sheets)
      local modal = w:attributeValue("AXModal")
      local subrole = w:attributeValue("AXSubrole") or ""
      if modal or subrole == "AXDialog" or subrole == "AXSystemDialog" then
        local children = w:attributeValue("AXChildren") or {}
        local texts, buttons = {}, {}
        for _, c in ipairs(children) do
          local role = c:attributeValue("AXRole") or ""
          if role == "AXStaticText" then
            table.insert(texts, c:attributeValue("AXValue") or c:attributeValue("AXTitle") or "")
          elseif role == "AXButton" then
            table.insert(buttons, {title = c:attributeValue("AXTitle") or "", element = c})
          elseif role == "AXGroup" then
            for _, gc in ipairs(c:attributeValue("AXChildren") or {}) do
              if gc:attributeValue("AXRole") == "AXButton" then
                table.insert(buttons, {title = gc:attributeValue("AXTitle") or "", element = gc})
              end
            end
          end
        end
        if #buttons > 0 then
          result = {dialogType = "modal", title = w:attributeValue("AXTitle"), buttonTitles = {}}
          for _, b in ipairs(buttons) do table.insert(result.buttonTitles, b.title) end
          local clicked = false
          if preferCancel then
            for _, b in ipairs(buttons) do
              if b.title == "Cancel" then
                b.element:performAction("AXPress")
                result.clicked = "Cancel"
                clicked = true
                break
              end
            end
          end
          if not clicked then
            for _, b in ipairs(buttons) do
              if b.title ~= "Cancel" then
                b.element:performAction("AXPress")
                result.clicked = b.title
                clicked = true
                break
              end
            end
            if not clicked and buttons[1] then
              buttons[1].element:performAction("AXPress")
              result.clicked = buttons[1].title
            end
          end
          return
        end
      end
    end
  end)
  return result
end
`;

/**
 * Wrap a Lua script with the standard preamble and pcall error handling.
 * Returns JSON with { success = true/false, ... } shape.
 */
function safeLua(code: string): string {
  return `${LUA_PREAMBLE}
local __ok, __result = pcall(function()
  ${code}
end)
if not __ok then
  return {success = false, error = tostring(__result)}
end
if type(__result) == "table" then
  __result.success = true
  return __result
end
return {success = true, value = __result}
`;
}

const FCP_STATUS_LUA = safeLua(`
  local result = {
    running = fcp:isRunning(),
    frontmost = safeGet(function() return fcp:isFrontmost() end),
    installed = safeGet(function() return fcp:isInstalled() end),
    version = safeGet(function() return fcp:version() and tostring(fcp:version()) end),
    path = safeGet(function() return fcp:getPath() end),
  }
  result.activeLibraries = safeGet(function() return fcp:activeLibraryNames() end)
  result.activeLibraryPaths = safeGet(function() return fcp:activeLibraryPaths() end)
  result.currentTimecode = safeGet(function() return fcp.viewer:timecode() end)
  result.playing = safeGet(function() return fcp.viewer:isPlaying() end)
  return result
`);

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Tool Definitions
// ═══════════════════════════════════════════════════════════════════════════

const TOOLS = [
  // ── System & Connection ─────────────────────────────────────────────
  {
    name: "commandpost_ping",
    description:
      "Check if CommandPost is running and the WebSocket connection is active. Use this to verify connectivity before performing operations.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "commandpost_list_handlers",
    description:
      "List all available action handlers registered in CommandPost. Returns handler IDs, groups, and labels. Use this to discover what actions can be executed via commandpost_execute_action.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "commandpost_get_handler_info",
    description:
      "Get detailed information about a specific action handler. Choices are paginated and params are omitted unless explicitly requested.",
    inputSchema: {
      type: "object" as const,
      properties: {
        handler: {
          type: "string",
          description:
            'The handler ID (e.g., "fcpx_videoEffect", "global_shortcuts")',
        },
        includeChoices: {
          type: "boolean",
          description:
            "Include action choices in the response (default: true).",
        },
        includeParams: {
          type: "boolean",
          description:
            "Include serialized choice params for each returned choice (default: false).",
        },
        limit: {
          type: "number",
          description:
            "Maximum number of choices to return (default: 200, max: 1000).",
        },
        offset: {
          type: "number",
          description:
            "Zero-based choice offset for pagination (default: 0).",
        },
      },
      required: ["handler"],
    },
  },

  // ── Lua Execution ───────────────────────────────────────────────────
  {
    name: "commandpost_execute_lua",
    description:
      "Execute arbitrary Lua code in CommandPost's Hammerspoon environment. This is the most powerful tool — it can do ANYTHING CommandPost can do. The code runs with full access to the `hs` (Hammerspoon) API, `cp` (CommandPost) modules, and all loaded plugins. For expressions, the result is returned automatically. For statements, use explicit `return`. Examples: 'hs.alert.show(\"Hello\")' or 'local fcp = require(\"cp.apple.finalcutpro\") return fcp:isRunning()'.",
    inputSchema: {
      type: "object" as const,
      properties: {
        code: {
          type: "string",
          description:
            'Lua code to execute. Expressions auto-return (e.g., "1+1" returns 2). For statements, use explicit return.',
        },
      },
      required: ["code"],
    },
  },

  // ── Action System ───────────────────────────────────────────────────
  {
    name: "commandpost_execute_action",
    description:
      "Execute a registered CommandPost action by handler ID and optional action ID. Handlers include: global_shortcuts, global_menuactions, fcpx_videoEffect, fcpx_audioEffect, fcpx_generator, fcpx_title, fcpx_transition, and more. Use commandpost_list_handlers to discover available handlers.",
    inputSchema: {
      type: "object" as const,
      properties: {
        handler: {
          type: "string",
          description:
            'The action handler ID (e.g., "fcpx_videoEffect", "global_shortcuts")',
        },
        actionId: {
          type: "string",
          description:
            'Optional action ID within the handler. For FCPX plugins, can be a simplified path like "Blur/Prism" or full path.',
        },
        parameters: {
          type: "object",
          description: "Optional parameters to pass to the action",
        },
      },
      required: ["handler"],
    },
  },

  // ── Chaining / Batch ───────────────────────────────────────────────
  {
    name: "commandpost_chain",
    description:
      'Execute multiple operations sequentially with optional result passing between steps. Each operation can be: {"type":"execute","code":"..."} for Lua, {"type":"command","handler":"...","actionId":"..."} for actions, {"type":"delay","seconds":N} for pauses. The result of each step is available as `_prev` in subsequent Lua execute steps. Great for complex workflows like: apply effect → adjust parameters → add marker.',
    inputSchema: {
      type: "object" as const,
      properties: {
        operations: {
          type: "array",
          items: {
            type: "object",
            properties: {
              type: {
                type: "string",
                enum: ["execute", "command", "query", "delay"],
              },
              code: { type: "string" },
              handler: { type: "string" },
              actionId: { type: "string" },
              seconds: { type: "number" },
            },
            required: ["type"],
          },
          description: "Array of operations to execute in sequence",
        },
        stopOnError: {
          type: "boolean",
          description:
            "Stop executing if any operation fails (default: true)",
        },
      },
      required: ["operations"],
    },
  },

  // ── Preferences ─────────────────────────────────────────────────────
  {
    name: "commandpost_get_preference",
    description:
      "Get a CommandPost preference/setting value by key. CommandPost stores preferences using cp.config.",
    inputSchema: {
      type: "object" as const,
      properties: {
        key: {
          type: "string",
          description: 'The preference key (e.g., "websocket.enabled")',
        },
      },
      required: ["key"],
    },
  },
  {
    name: "commandpost_set_preference",
    description: "Set a CommandPost preference/setting value.",
    inputSchema: {
      type: "object" as const,
      properties: {
        key: {
          type: "string",
          description: "The preference key",
        },
        value: {
          description:
            "The value to set (string, number, boolean, or null to clear)",
        },
      },
      required: ["key", "value"],
    },
  },

  // ── Final Cut Pro — Application ─────────────────────────────────────
  {
    name: "fcp_launch",
    description:
      "Launch Final Cut Pro. If already running, brings it to the front.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_quit",
    description: "Quit Final Cut Pro.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_restart",
    description:
      "Restart Final Cut Pro by quitting and relaunching it.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_status",
    description:
      "Get the current status of Final Cut Pro — whether it's running, frontmost, installed, version info, and active library/project details.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_select_menu",
    description:
      'Select a Final Cut Pro menu item by its path. The path is an array of menu item names from top-level menu to the specific item. Example: ["Edit", "Select All"] or ["File", "Share", "Master File..."].',
    inputSchema: {
      type: "object" as const,
      properties: {
        path: {
          type: "array",
          items: { type: "string" },
          description:
            'Menu path as array of strings, e.g., ["Clip", "Solo Animation"]',
        },
      },
      required: ["path"],
    },
  },
  {
    name: "fcp_do_shortcut",
    description:
      'Execute a Final Cut Pro keyboard shortcut by its command ID. Examples: "SelectAll", "Paste", "PlayPause", "Blade", etc.',
    inputSchema: {
      type: "object" as const,
      properties: {
        command: {
          type: "string",
          description:
            'The FCP command ID (e.g., "SelectAll", "Blade", "PlayPause")',
        },
      },
      required: ["command"],
    },
  },

  // ── Final Cut Pro — Timeline ────────────────────────────────────────
  {
    name: "fcp_timeline_show",
    description:
      "Show or focus the Final Cut Pro timeline. Can show on primary or secondary display.",
    inputSchema: {
      type: "object" as const,
      properties: {
        display: {
          type: "string",
          enum: ["primary", "secondary"],
          description: "Which display to show the timeline on (default: primary)",
        },
      },
    },
  },
  {
    name: "fcp_timeline_playback",
    description:
      "Control timeline playback — play, pause, or toggle play/pause.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: ["play", "pause", "toggle"],
          description: "Playback action (default: toggle)",
        },
      },
    },
  },
  {
    name: "fcp_timeline_navigate",
    description:
      "Navigate the timeline — go to beginning, end, next/previous frame, next/previous edit point, or a specific timecode.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: [
            "beginning",
            "end",
            "next_frame",
            "previous_frame",
            "next_edit",
            "previous_edit",
            "timecode",
          ],
          description: "Navigation action",
        },
        timecode: {
          type: "string",
          description:
            'Timecode to navigate to (only used with "timecode" action), e.g., "00:01:30:00"',
        },
      },
      required: ["action"],
    },
  },
  {
    name: "fcp_timeline_select",
    description:
      "Select or deselect clips in the timeline. Use 'at_playhead' to select the clip under the playhead, 'by_index' to select by clip index (1-based), 'all' to select all, or 'none' to deselect.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: ["all", "none", "at_playhead", "by_index"],
          description:
            "Selection action: 'all' to select all, 'none' to deselect, 'at_playhead' to select clip under playhead, 'by_index' to select by clip index",
        },
        index: {
          type: "number",
          description:
            "1-based clip index (only used with 'by_index' action). Counts only actual clips, not transitions.",
        },
      },
      required: ["action"],
    },
  },
  {
    name: "fcp_timeline_blade",
    description:
      "Blade (cut) the clip at the current playhead position in the timeline.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_timeline_delete",
    description:
      "Delete the currently selected clips or range in the timeline.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_timeline_clipboard",
    description: "Copy, cut, or paste timeline content.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: ["copy", "cut", "paste"],
          description: "Clipboard action",
        },
      },
      required: ["action"],
    },
  },
  {
    name: "fcp_timeline_zoom",
    description: "Zoom the timeline in, out, or to fit the entire project.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: ["in", "out", "fit"],
          description: "Zoom action",
        },
      },
      required: ["action"],
    },
  },
  {
    name: "fcp_timeline_get_info",
    description:
      "Get information about the current timeline state — playhead position, whether it's playing, showing, focused, etc.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },

  // ── Final Cut Pro — Effects & Plugins ──────────────────────────────
  {
    name: "fcp_apply_effect",
    description:
      'Apply a video or audio effect to the selected clip(s). Use a simplified path like "Blur/Gaussian" or "Color/Color Wheels" or the full plugin path.',
    inputSchema: {
      type: "object" as const,
      properties: {
        name: {
          type: "string",
          description:
            'Effect name or path (e.g., "Blur/Gaussian", "Stylize/Comic Book")',
        },
        type: {
          type: "string",
          enum: ["video", "audio"],
          description: "Effect type (default: video)",
        },
      },
      required: ["name"],
    },
  },
  {
    name: "fcp_apply_transition",
    description:
      'Apply a transition between clips. Use a simplified path like "Dissolves/Cross Dissolve".',
    inputSchema: {
      type: "object" as const,
      properties: {
        name: {
          type: "string",
          description:
            'Transition name or path (e.g., "Dissolves/Cross Dissolve")',
        },
      },
      required: ["name"],
    },
  },
  {
    name: "fcp_apply_generator",
    description:
      'Apply a generator to the timeline. Use a simplified path like "Backgrounds/Gradient".',
    inputSchema: {
      type: "object" as const,
      properties: {
        name: {
          type: "string",
          description:
            'Generator name or path (e.g., "Solids/Custom", "Backgrounds/Gradient")',
        },
      },
      required: ["name"],
    },
  },
  {
    name: "fcp_apply_title",
    description:
      'Apply a title to the timeline. Use a simplified path like "Build In/Build Out/Typewriter".',
    inputSchema: {
      type: "object" as const,
      properties: {
        name: {
          type: "string",
          description:
            'Title name or path (e.g., "Bumper/Opener/Basic Title")',
        },
      },
      required: ["name"],
    },
  },

  // ── Final Cut Pro — Browser ────────────────────────────────────────
  {
    name: "fcp_browser_show",
    description: "Show or hide the Final Cut Pro browser panel.",
    inputSchema: {
      type: "object" as const,
      properties: {
        panel: {
          type: "string",
          enum: ["libraries", "media", "generators"],
          description: "Which browser panel to show (default: libraries)",
        },
      },
    },
  },
  {
    name: "fcp_browser_list_libraries",
    description:
      "List all open Final Cut Pro libraries and their paths.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_browser_select_library",
    description: "Select an open library by its title/name.",
    inputSchema: {
      type: "object" as const,
      properties: {
        title: {
          type: "string",
          description: "The library title/name to select",
        },
      },
      required: ["title"],
    },
  },

  // ── Final Cut Pro — Inspector ─────────────────────────────────────
  {
    name: "fcp_inspector_show",
    description:
      "Show the inspector panel and optionally select a specific tab.",
    inputSchema: {
      type: "object" as const,
      properties: {
        tab: {
          type: "string",
          enum: [
            "audio",
            "video",
            "info",
            "color",
            "effect",
            "generator",
            "share",
            "text",
            "title",
            "transition",
          ],
          description: "Inspector tab to select (optional)",
        },
      },
    },
  },

  // ── Final Cut Pro — Viewer ─────────────────────────────────────────
  {
    name: "fcp_viewer_show",
    description: "Show the viewer on the primary or secondary display.",
    inputSchema: {
      type: "object" as const,
      properties: {
        display: {
          type: "string",
          enum: ["primary", "secondary"],
          description: "Which display (default: primary)",
        },
      },
    },
  },

  // ── Final Cut Pro — Color ──────────────────────────────────────────
  {
    name: "fcp_color_board",
    description:
      "Adjust the Color Board in Final Cut Pro. Controls color, saturation, and exposure with master, shadows, midtones, and highlights pucks.",
    inputSchema: {
      type: "object" as const,
      properties: {
        aspect: {
          type: "string",
          enum: ["color", "saturation", "exposure"],
          description: "Which color board aspect to adjust",
        },
        puck: {
          type: "string",
          enum: ["master", "shadows", "midtones", "highlights"],
          description: "Which puck to adjust",
        },
        value: {
          type: "number",
          description: "Value to set (range depends on aspect: typically -100 to 100)",
        },
        property: {
          type: "string",
          enum: ["percentage", "angle"],
          description:
            "Which property to set. 'percentage' for saturation/exposure, 'angle' for color hue (default: percentage)",
        },
      },
      required: ["aspect", "puck", "value"],
    },
  },

  // ── Final Cut Pro — Export/Import ──────────────────────────────────
  {
    name: "fcp_export",
    description:
      "Export/share the current Final Cut Pro project. Opens the export dialog with an optional destination preset.",
    inputSchema: {
      type: "object" as const,
      properties: {
        destination: {
          type: "string",
          description:
            'Optional share destination name (e.g., "Master File", "Apple Devices 1080p")',
        },
      },
    },
  },
  {
    name: "fcp_import_media",
    description:
      "Import a media file or folder into Final Cut Pro from a file path using the Media Import window.",
    inputSchema: {
      type: "object" as const,
      properties: {
        path: {
          type: "string",
          description: "File or folder path to import",
        },
      },
      required: ["path"],
    },
  },
  {
    name: "fcp_import_xml",
    description: "Import an FCPXML file into Final Cut Pro.",
    inputSchema: {
      type: "object" as const,
      properties: {
        path: {
          type: "string",
          description: "Path to the FCPXML file",
        },
      },
      required: ["path"],
    },
  },
  {
    name: "fcp_export_xml",
    description:
      "Export the current project/event as FCPXML via the File > Export XML menu.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },

  // ── Final Cut Pro — Projects & Libraries ──────────────────────────
  {
    name: "fcp_open_project",
    description: "Open a project by name in the timeline.",
    inputSchema: {
      type: "object" as const,
      properties: {
        name: {
          type: "string",
          description: "Project name (or pattern) to open",
        },
      },
      required: ["name"],
    },
  },
  {
    name: "fcp_project_properties",
    description:
      "Get properties of the current project — resolution, frame rate, codec, etc.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },

  // ── Final Cut Pro — Markers & Keywords ────────────────────────────
  {
    name: "fcp_add_marker",
    description:
      "Add a marker at the current playhead position in the timeline, optionally naming it or setting a To Do marker as completed.",
    inputSchema: {
      type: "object" as const,
      properties: {
        type: {
          type: "string",
          enum: ["standard", "todo", "chapter"],
          description: "Marker type (default: standard)",
        },
        name: {
          type: "string",
          description: "Optional marker name",
        },
        completed: {
          type: "boolean",
          description:
            "For todo markers, whether the marker should be marked completed",
        },
      },
    },
  },
  {
    name: "fcp_add_keyword",
    description: "Add a keyword to the currently selected clip(s).",
    inputSchema: {
      type: "object" as const,
      properties: {
        keyword: {
          type: "string",
          description: "The keyword to add",
        },
      },
      required: ["keyword"],
    },
  },
  {
    name: "fcp_list_markers",
    description:
      "List all markers in the current timeline/project. Returns marker names, types, positions, and notes.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },

  // ── Final Cut Pro — Clip Operations ───────────────────────────────
  {
    name: "fcp_rename_clip",
    description: "Rename the currently selected clip.",
    inputSchema: {
      type: "object" as const,
      properties: {
        name: {
          type: "string",
          description: "New name for the clip",
        },
      },
      required: ["name"],
    },
  },
  {
    name: "fcp_rate_clip",
    description:
      "Rate the currently selected clip as favorite, rejected, or unrated.",
    inputSchema: {
      type: "object" as const,
      properties: {
        rating: {
          type: "string",
          enum: ["favorite", "reject", "unrate"],
          description: "Rating to apply",
        },
      },
      required: ["rating"],
    },
  },

  // ── Final Cut Pro — Window Management ─────────────────────────────
  {
    name: "fcp_window_layout",
    description:
      "Control Final Cut Pro window layout — toggle fullscreen, show/hide panels.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: [
            "show_timeline",
            "show_browser",
            "show_inspector",
            "show_viewer",
            "hide_browser",
            "hide_inspector",
            "fullscreen_toggle",
          ],
          description: "Window layout action",
        },
      },
      required: ["action"],
    },
  },

  // ── Final Cut Pro — Undo/Redo ─────────────────────────────────────
  {
    name: "fcp_undo_redo",
    description: "Undo or redo the last action in Final Cut Pro.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: ["undo", "redo"],
          description: "Undo or redo",
        },
        count: {
          type: "number",
          description: "Number of times to undo/redo (default: 1)",
        },
      },
      required: ["action"],
    },
  },

  // ── Final Cut Pro — Speed/Retime ──────────────────────────────────
  {
    name: "fcp_retime",
    description: "Change the speed/retime of the selected clip.",
    inputSchema: {
      type: "object" as const,
      properties: {
        speed: {
          type: "string",
          enum: [
            "slow_50",
            "slow_25",
            "slow_10",
            "fast_2x",
            "fast_4x",
            "fast_8x",
            "fast_20x",
            "normal",
            "reverse",
            "hold",
          ],
          description: "Speed preset to apply",
        },
      },
      required: ["speed"],
    },
  },

  // ── Final Cut Pro — Captions ──────────────────────────────────────
  {
    name: "fcp_captions",
    description: "Manage captions — add, extract, or import captions.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: ["add", "extract", "import"],
          description: "Caption action",
        },
        path: {
          type: "string",
          description: "File path for import/export operations",
        },
      },
      required: ["action"],
    },
  },

  // ── Final Cut Pro — Multicam ──────────────────────────────────────
  {
    name: "fcp_multicam_switch_angle",
    description: "Switch the multicam angle for the selected clip.",
    inputSchema: {
      type: "object" as const,
      properties: {
        angle: {
          type: "number",
          description: "Angle number to switch to (1-based)",
        },
        type: {
          type: "string",
          enum: ["video", "audio", "both"],
          description: "Switch video, audio, or both (default: both)",
        },
      },
      required: ["angle"],
    },
  },

  // ── Final Cut Pro — Pasteboard History ────────────────────────────
  {
    name: "fcp_pasteboard",
    description:
      "Access Final Cut Pro timeline pasteboard content. `copy` and `paste` use the normal clipboard by default; when `slot` is provided they use CommandPost's pasteboard buffer. `history` returns populated buffer slots.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: {
          type: "string",
          enum: ["copy", "paste", "history"],
          description:
            "Action: 'copy' to copy the current selection, 'paste' to paste, or 'history' to list populated pasteboard buffer slots",
        },
        slot: {
          type: "number",
          description:
            "Optional buffer slot number (1-50). When provided, copy/paste use CommandPost's pasteboard buffer instead of the system clipboard.",
        },
      },
      required: ["action"],
    },
  },

  // ── Color Wheels / Video Inspector / Audio Inspector ────────────
  {
    name: "fcp_color_wheels",
    description:
      "Adjust color using Final Cut Pro's Color Wheels — temperature, tint, hue, mix, saturation, brightness, contrast. Much more capable than the basic Color Board.",
    inputSchema: {
      type: "object" as const,
      properties: {
        control: { type: "string", enum: ["temperature", "tint", "hue", "mix", "saturation", "brightness", "contrast"], description: "Which control to adjust" },
        value: { type: "number", description: "Value to set" },
        reset: { type: "boolean", description: "If true, reset the control to default" },
      },
      required: ["control"],
    },
  },
  {
    name: "fcp_video_inspector",
    description:
      "Read or adjust video properties in the Inspector — transform (position, scale, rotation), crop, compositing (blend mode, opacity). Uses the native VideoInspector API.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: { type: "string", enum: ["get", "set"], description: "Read or write" },
        section: { type: "string", enum: ["transform", "crop", "compositing", "stabilization", "spatial"], description: "Inspector section" },
        property: { type: "string", description: 'Property name (e.g., "positionX", "scale", "rotation", "opacity")' },
        value: { description: "Value to set (for action=set)" },
      },
      required: ["action", "section"],
    },
  },
  {
    name: "fcp_audio_inspector",
    description: "Read or adjust audio properties in the Inspector — volume, pan.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: { type: "string", enum: ["get", "set"], description: "Read or write" },
        property: { type: "string", enum: ["volume", "pan"], description: "Audio property" },
        value: { type: "number", description: "Value to set (for action=set)" },
      },
      required: ["action"],
    },
  },

  // ── Timeline Toolbar / Appearance / Viewer Config ───────────────
  {
    name: "fcp_toolbar_state",
    description: "Read or set timeline toolbar toggles (snapping, skimming, solo) and the active editing tool.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: { type: "string", enum: ["get", "set"], description: "Read or write" },
        toggle: { type: "string", enum: ["snapping", "skimming", "audioSkimming", "solo"], description: "Toggle to get/set" },
        enabled: { type: "boolean", description: "Enable or disable (for set)" },
        tool: { type: "string", enum: ["select", "trim", "position", "range", "blade", "zoom", "hand"], description: "Set active editing tool" },
      },
      required: ["action"],
    },
  },
  {
    name: "fcp_timeline_appearance",
    description: "Read or configure timeline appearance — clip height, names, roles, lane headers.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: { type: "string", enum: ["get", "set"], description: "Read or write" },
        clipHeight: { type: "number", description: "Clip height (0-100)" },
        clipNames: { type: "boolean", description: "Show clip names" },
        clipRoles: { type: "boolean", description: "Show clip roles" },
        laneHeaders: { type: "boolean", description: "Show lane headers" },
      },
      required: ["action"],
    },
  },
  {
    name: "fcp_viewer_config",
    description: "Read or configure the Viewer — playback quality, background color, proxy mode.",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: { type: "string", enum: ["get", "set"], description: "Read or write" },
        background: { type: "string", enum: ["black", "white", "checkerboard"], description: "Viewer background" },
        quality: { type: "string", enum: ["better_quality", "better_performance", "proxy_preferred", "proxy_only", "original_better_quality", "original_better_performance"], description: "Playback quality" },
      },
      required: ["action"],
    },
  },

  // ── CSV Export / Match Frame / Transcode ────────────────────────
  {
    name: "fcp_export_csv",
    description: "Export browser contents or timeline index to CSV for external analysis.",
    inputSchema: {
      type: "object" as const,
      properties: {
        source: { type: "string", enum: ["browser", "timeline"], description: "What to export" },
        path: { type: "string", description: "Output file path (optional — returns data if omitted)" },
      },
      required: ["source"],
    },
  },
  {
    name: "fcp_match_frame",
    description: "Match frame — locate the source clip in the browser for the current playhead position.",
    inputSchema: {
      type: "object" as const,
      properties: {
        multicam: { type: "boolean", description: "If true, perform multicam match frame" },
      },
    },
  },
  {
    name: "fcp_transcode",
    description: "Transcode selected clips — create optimized or proxy media.",
    inputSchema: {
      type: "object" as const,
      properties: {
        mode: { type: "string", enum: ["optimize", "proxy", "both"], description: "Transcoding mode" },
      },
      required: ["mode"],
    },
  },

  // ── Find/Replace Titles / Keywords / Text-to-Markers ───────────
  {
    name: "fcp_find_replace_titles",
    description: "Find and replace text in titles across the timeline via FCP's Edit > Find and Replace Title Text.",
    inputSchema: {
      type: "object" as const,
      properties: {
        find: { type: "string", description: "Text to search for" },
        replace: { type: "string", description: "Replacement text" },
      },
      required: ["find", "replace"],
    },
  },
  {
    name: "fcp_keyword_presets",
    description: "Save or restore keyword preset configurations (9 slots).",
    inputSchema: {
      type: "object" as const,
      properties: {
        action: { type: "string", enum: ["save", "restore", "list"], description: "Action" },
        preset: { type: "number", description: "Preset slot (1-9)" },
      },
      required: ["action"],
    },
  },
  {
    name: "fcp_text_to_markers",
    description: "Convert formatted text with timecodes into timeline markers. Each line: 'HH:MM:SS:FF marker text'.",
    inputSchema: {
      type: "object" as const,
      properties: {
        text: { type: "string", description: "Timecoded text (one marker per line)" },
        type: { type: "string", enum: ["marker", "todo"], description: "Marker type (default: marker)" },
      },
      required: ["text"],
    },
  },

  // ── Notifications ─────────────────────────────────────────────────
  {
    name: "commandpost_alert",
    description:
      "Show an on-screen alert/notification via Hammerspoon's alert system.",
    inputSchema: {
      type: "object" as const,
      properties: {
        message: {
          type: "string",
          description: "The message to display",
        },
        duration: {
          type: "number",
          description: "How long to show the alert in seconds (default: 2)",
        },
      },
      required: ["message"],
    },
  },

  // ── Discovery / Introspection ─────────────────────────────────────
  {
    name: "fcp_list_effects",
    description:
      "List all available video effects installed in Final Cut Pro. Returns effect names and categories.",
    inputSchema: {
      type: "object" as const,
      properties: {
        category: {
          type: "string",
          description:
            'Optional category filter (e.g., "Blur", "Color", "Stylize"). If omitted, lists all.',
        },
      },
    },
  },
  {
    name: "fcp_list_audio_effects",
    description:
      "List all available audio effects installed in Final Cut Pro.",
    inputSchema: {
      type: "object" as const,
      properties: {
        category: {
          type: "string",
          description: "Optional category filter. If omitted, lists all.",
        },
      },
    },
  },
  {
    name: "fcp_list_transitions",
    description:
      "List all available transitions installed in Final Cut Pro.",
    inputSchema: {
      type: "object" as const,
      properties: {
        category: {
          type: "string",
          description: "Optional category filter. If omitted, lists all.",
        },
      },
    },
  },
  {
    name: "fcp_list_generators",
    description:
      "List all available generators installed in Final Cut Pro.",
    inputSchema: {
      type: "object" as const,
      properties: {
        category: {
          type: "string",
          description: "Optional category filter. If omitted, lists all.",
        },
      },
    },
  },
  {
    name: "fcp_list_titles",
    description: "List all available titles installed in Final Cut Pro.",
    inputSchema: {
      type: "object" as const,
      properties: {
        category: {
          type: "string",
          description: "Optional category filter. If omitted, lists all.",
        },
      },
    },
  },
  {
    name: "fcp_get_selected_clips",
    description:
      "Get information about the currently selected clips in the timeline, including their names, positions, and durations.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_get_playhead_position",
    description:
      "Get the current playhead (CTI) position in the timeline as timecode.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_set_playhead_position",
    description:
      "Set the playhead to a specific timecode position in the timeline.",
    inputSchema: {
      type: "object" as const,
      properties: {
        timecode: {
          type: "string",
          description:
            'Timecode to navigate to (e.g., "00:01:30:00" or "01:00:00:00")',
        },
      },
      required: ["timecode"],
    },
  },
  {
    name: "fcp_get_project_settings",
    description:
      "Get the current project settings — resolution, frame rate, color space, audio settings, etc.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },

  // ── Clip Properties ───────────────────────────────────────────────
  {
    name: "fcp_get_clip_properties",
    description:
      "Get the transform and compositing properties (position, scale, rotation, opacity, etc.) of the currently selected clip via the Video Inspector.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_set_clip_properties",
    description:
      "Set transform or compositing properties on the selected clip. Adjusts values via the Video Inspector.",
    inputSchema: {
      type: "object" as const,
      properties: {
        positionX: {
          type: "number",
          description: "X position in pixels",
        },
        positionY: {
          type: "number",
          description: "Y position in pixels",
        },
        scaleAll: {
          type: "number",
          description: "Uniform scale percentage (100 = normal)",
        },
        rotation: {
          type: "number",
          description: "Rotation in degrees",
        },
        opacity: {
          type: "number",
          description: "Opacity percentage (0-100)",
        },
      },
    },
  },

  // ── Additional Clip Operations ────────────────────────────────────
  {
    name: "fcp_duplicate_clip",
    description:
      "Duplicate the currently selected clip(s) in the timeline (Option-drag equivalent).",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_enable_disable_clip",
    description: "Enable or disable the currently selected clip(s).",
    inputSchema: {
      type: "object" as const,
      properties: {
        enabled: {
          type: "boolean",
          description: "true to enable, false to disable (toggles if omitted)",
        },
      },
    },
  },
  {
    name: "fcp_split_at_timecode",
    description:
      "Split/blade the clip at a specific timecode position. Moves the playhead to the timecode first, then blades.",
    inputSchema: {
      type: "object" as const,
      properties: {
        timecode: {
          type: "string",
          description: 'Timecode position to split at (e.g., "00:01:30:00")',
        },
      },
      required: ["timecode"],
    },
  },
  {
    name: "fcp_speed_custom",
    description:
      "Set a custom speed percentage for the selected clip using the retime editor.",
    inputSchema: {
      type: "object" as const,
      properties: {
        percentage: {
          type: "number",
          description:
            "Speed percentage (e.g., 50 for half speed, 200 for double speed)",
        },
      },
      required: ["percentage"],
    },
  },

  // ── Range Selection / Work Area ───────────────────────────────────
  {
    name: "fcp_set_range",
    description:
      "Set the timeline range selection (in/out points) using timecodes.",
    inputSchema: {
      type: "object" as const,
      properties: {
        start: {
          type: "string",
          description: 'Start timecode (e.g., "00:00:10:00")',
        },
        end: {
          type: "string",
          description: 'End timecode (e.g., "00:00:20:00")',
        },
      },
      required: ["start", "end"],
    },
  },
  {
    name: "fcp_clear_range",
    description: "Clear the current range selection in the timeline.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },

  // ── Compound Clips & Auditions ────────────────────────────────────
  {
    name: "fcp_create_compound_clip",
    description:
      "Create a compound clip from the currently selected clips in the timeline.",
    inputSchema: {
      type: "object" as const,
      properties: {
        name: {
          type: "string",
          description: "Optional name for the compound clip",
        },
      },
    },
  },
  {
    name: "fcp_break_apart_compound",
    description:
      "Break apart a selected compound clip into its individual components.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },
  {
    name: "fcp_create_audition",
    description:
      "Create an audition from the currently selected clips. Auditions let you group alternative clips and switch between them.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },

  // ── Roles ─────────────────────────────────────────────────────────
  {
    name: "fcp_assign_role",
    description:
      "Assign a role (video, audio, or custom) to the selected clip(s) via the Modify > Assign Roles menu.",
    inputSchema: {
      type: "object" as const,
      properties: {
        role: {
          type: "string",
          description:
            'Role name to assign (e.g., "Dialogue", "Music", "Effects", "Video", or a custom role name)',
        },
      },
      required: ["role"],
    },
  },

  // ── Stabilization ─────────────────────────────────────────────────
  {
    name: "fcp_stabilization",
    description:
      "Toggle stabilization on the selected clip via the Video Inspector.",
    inputSchema: {
      type: "object" as const,
      properties: {
        enabled: {
          type: "boolean",
          description:
            "true to enable stabilization, false to disable (default: true)",
        },
        method: {
          type: "string",
          enum: ["automatic", "inertiaCam", "smoothCam"],
          description: "Stabilization method (default: automatic)",
        },
      },
    },
  },

  // ── Proxy Management ──────────────────────────────────────────────
  {
    name: "fcp_proxy_toggle",
    description:
      "Toggle between proxy and optimized/original media for playback.",
    inputSchema: {
      type: "object" as const,
      properties: {
        mode: {
          type: "string",
          enum: ["proxy", "optimized", "original"],
          description:
            "Media mode to switch to (default: toggles between proxy and optimized/original)",
        },
      },
    },
  },

  // ── Batch Operations ──────────────────────────────────────────────
  {
    name: "fcp_batch_apply_transition",
    description:
      "Apply Final Cut Pro's current default transition across the active timeline by selecting all clips first.",
    inputSchema: {
      type: "object" as const,
      properties: {},
    },
  },

  // ── Composite Workflow ────────────────────────────────────────────
  {
    name: "fcp_assemble_rough_cut",
    description:
      'Batch-import media files for rough-cut preparation. Accepts a "clipPlan" array of media paths and can optionally open an existing project first. This tool currently imports media only; it does not trim clips or place them on the timeline.',
    inputSchema: {
      type: "object" as const,
      properties: {
        projectName: {
          type: "string",
          description: "Optional existing project to open before importing",
        },
        clipPlan: {
          type: "array",
          items: {
            type: "object",
            properties: {
              mediaPath: {
                type: "string",
                description: "Path to the media file to import",
              },
            },
            required: ["mediaPath"],
          },
          description: "Array of media files to import in order",
        },
      },
      required: ["clipPlan"],
    },
  },
];

// ═══════════════════════════════════════════════════════════════════════════
// Tool Handlers
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Format a tool response as JSON string.
 * Ensures the result always contains a `success` field for consistency.
 * Creates a shallow copy to avoid mutating the original object.
 */
function formatResult(response: unknown): string {
  if (typeof response === "string") {
    try {
      const parsed = JSON.parse(response);
      if (typeof parsed === "object" && parsed !== null && !("success" in parsed)) {
        parsed.success = !("error" in parsed) ? true : false;
      }
      return JSON.stringify(parsed, null, 2);
    } catch {
      return response;
    }
  }
  if (typeof response === "object" && response !== null) {
    const copy = { ...(response as Record<string, unknown>) };
    if (!("success" in copy)) {
      copy.success = !("error" in copy) ? true : false;
    }
    return JSON.stringify(copy, null, 2);
  }
  return JSON.stringify(response, null, 2);
}

function extractResult(response: { result?: unknown }): unknown {
  return response?.result ?? response;
}

function unwrapNestedResult(response: unknown): unknown {
  let value = extractResult(response as { result?: unknown });

  while (
    value
    && typeof value === "object"
    && !Array.isArray(value)
    && hasOwn(value as Record<string, unknown>, "result")
  ) {
    const obj = value as Record<string, unknown>;
    const keys = Object.keys(obj);
    if (keys.length > 2 || (keys.length === 2 && !hasOwn(obj, "success"))) {
      break;
    }
    value = obj.result;
  }

  return value;
}

async function activateFinalCutPro(timeoutMs = 30000): Promise<void> {
  const resp = await client.executeLua(
    `
      local fcp = require("cp.apple.finalcutpro")

      -- Guard: FCP must be running
      if not fcp:isRunning() then
        return {error = "Final Cut Pro is not running. Launch it first.", fcpNotRunning = true}
      end

      fcp:launch()
      hs.timer.usleep(200000)

      -- Check for modal dialogs blocking interaction
      local app = fcp:application()
      if app then
        local windows = app:allWindows()
        if windows then
          for _, w in ipairs(windows) do
            local role = w:role()
            local subrole = w:subrole()
            if role == "AXWindow" and (subrole == "AXDialog" or subrole == "AXSheet" or subrole == "AXSystemDialog") then
              return {error = "A modal dialog is open in FCP. Dismiss it before proceeding.", modalDialog = true, dialogTitle = w:title() or "unknown"}
            end
          end
        end
      end

      -- Dismiss any open speed popover that might block subsequent operations
      pcall(function()
        local sp = fcp.timeline.speedPopover
        if sp:isShowing() then
          sp:hide()
          local just = require("cp.just")
          just.doUntil(function() return not sp:isShowing() end, 2)
          hs.timer.usleep(200000)
        end
      end)

      return true
    `,
    timeoutMs
  );
  // If FCP returned an error (not running, modal dialog), throw so callers can handle
  const result = unwrapNestedResult(resp) as Record<string, unknown> | undefined;
  if (result && typeof result === "object" && result.error) {
    throw new Error(String(result.error));
  }
}

const INSPECTOR_TAB_MAP: Record<string, string> = {
  audio: "Audio",
  color: "Color",
  effect: "Effect",
  generator: "Generator",
  info: "Info",
  share: "Share",
  text: "Text",
  title: "Title",
  transition: "Transition",
  video: "Video",
};

const KNOWN_TOOLS = new Set(TOOLS.map((t) => t.name));
const TIMELINE_NAVIGATION_ACTIONS = new Set([
  "beginning",
  "end",
  "next_frame",
  "previous_frame",
  "next_edit",
  "previous_edit",
  "timecode",
]);
const PASTEBOARD_ACTIONS = new Set(["copy", "paste", "history"]);

// ── Verification Helpers ──────────────────────────────────────────────
// These use a TWO-PHASE approach:
//   1. Capture lightweight "before" state (clip count + timecode — NO menu reads)
//   2. Run the operation
//   3. Capture "after" state INCLUDING undo text (menu read is safe AFTER the op)
//
// IMPORTANT: getMenuItems() steals focus from FCP, which breaks keyboard
// shortcuts in the same Lua chunk. That's why we only read menus AFTER
// the operation, never before.

/**
 * Wrap a Lua operation with before/after timeline state capture.
 * Returns: .before, .after, .verified with undoText, clipDelta, tcChanged
 */
function withVerification(operationCode: string): string {
  return `${LUA_PREAMBLE}
-- Guard: FCP must be running
do
  local __fcp = require("cp.apple.finalcutpro")
  if not __fcp:isRunning() then
    return {error = "Final Cut Pro is not running. Launch it first.", fcpNotRunning = true}
  end
  __fcp:launch()
  hs.timer.usleep(300000)

  -- Check for modal dialogs blocking interaction
  local __app = __fcp:application()
  if __app then
    local __windows = __app:allWindows()
    if __windows then
      for _, w in ipairs(__windows) do
        local __role = w:role()
        local __subrole = w:subrole()
        if __role == "AXWindow" and (__subrole == "AXDialog" or __subrole == "AXSheet" or __subrole == "AXSystemDialog") then
          return {error = "A modal dialog is open in FCP. Dismiss it before proceeding.", modalDialog = true, dialogTitle = w:title() or "unknown"}
        end
      end
    end
  end
end

-- Dismiss any open speed popover that might block operations
pcall(function()
  local __fcp = require("cp.apple.finalcutpro")
  local __sp = __fcp.timeline.speedPopover
  if __sp:isShowing() then
    __sp:hide()
    local __just = require("cp.just")
    __just.doUntil(function() return not __sp:isShowing() end, 2)
    hs.timer.usleep(200000)
  end
end)

-- Phase 1: lightweight before-state (NO menu read — preserves FCP focus)
local __before = {}
pcall(function() __before.timecode = tostring(require("cp.apple.finalcutpro").viewer:timecode()) end)
pcall(function()
  local contents = require("cp.apple.finalcutpro").timeline.contents:UI()
  if contents then
    local children = contents:attributeValue("AXChildren")
    if children then
      __before.clipCount = 0
      for _, c in ipairs(children) do
        local desc = c:attributeValue("AXDescription")
        if desc and desc ~= "Playhead" then __before.clipCount = __before.clipCount + 1 end
      end
    end
  end
end)

-- Phase 2: execute the operation
local __opResult = (function()
  ${operationCode}
end)()

-- Phase 2.5: check for and handle any FCP dialogs that appeared
local __dialogResult = handleFCPDialog(false)
if __dialogResult then
  hs.timer.usleep(500000)
end

-- Phase 3: after-state WITH menu read (safe now that operation is done)
hs.timer.usleep(500000)
local __after = {}
pcall(function() __after.timecode = tostring(require("cp.apple.finalcutpro").viewer:timecode()) end)
pcall(function()
  local contents = require("cp.apple.finalcutpro").timeline.contents:UI()
  if contents then
    local children = contents:attributeValue("AXChildren")
    if children then
      __after.clipCount = 0
      __after.clips = {}
      for _, c in ipairs(children) do
        local desc = c:attributeValue("AXDescription")
        if desc and desc ~= "Playhead" then
          __after.clipCount = __after.clipCount + 1
          if __after.clipCount <= 30 then
            table.insert(__after.clips, {description = desc, duration = c:attributeValue("AXValue")})
          end
        end
      end
    end
  end
end)
pcall(function()
  local app = require("cp.apple.finalcutpro"):application()
  if app then
    local menus = app:getMenuItems()
    if menus then
      for _, m in ipairs(menus) do
        if m.AXTitle == "Edit" then
          __after.undoText = m.AXChildren[1][1].AXTitle
          break
        end
      end
    end
  end
end)

if type(__opResult) ~= "table" then __opResult = {value = __opResult} end
__opResult.before = {clipCount = __before.clipCount, timecode = __before.timecode}
__opResult.after  = {clipCount = __after.clipCount, timecode = __after.timecode, undoText = __after.undoText, clips = __after.clips}
__opResult.verified = {
  undoText = __after.undoText,
  clipDelta = (__after.clipCount or 0) - (__before.clipCount or 0),
  tcChanged = __after.timecode ~= __before.timecode,
}
if __dialogResult then
  __opResult.dialogHandled = __dialogResult
end
return __opResult
`;
}

/**
 * Lighter wrapper for navigation — captures timecode before/after.
 * No menu reads needed — timecode change IS the verification.
 */
function withTimecodeCheck(operationCode: string): string {
  return `
do
  local __fcp = require("cp.apple.finalcutpro")
  if __fcp:isRunning() then __fcp:launch() end
  hs.timer.usleep(300000)
end
local __tcBefore
pcall(function() __tcBefore = tostring(require("cp.apple.finalcutpro").viewer:timecode()) end)
local __opResult = (function()
  ${operationCode}
end)()
local __tcAfter
pcall(function() __tcAfter = tostring(require("cp.apple.finalcutpro").viewer:timecode()) end)
if type(__opResult) ~= "table" then __opResult = {value = __opResult} end
__opResult.beforeTimecode = __tcBefore
__opResult.afterTimecode = __tcAfter
__opResult.timecodeChanged = __tcBefore ~= __tcAfter
return __opResult
`;
}

// ── Reusable Lua Snippets for Pre/Post Checks ──────────────────────
// These are Lua code fragments that can be interpolated into tool Lua strings.

/**
 * Lua snippet that returns a table with FCP readiness info.
 * Call this at the start of operations to check preconditions.
 * Returns: { timelineShowing, selectedClipCount, speedPopoverOpen, playheadTimecode }
 */
const LUA_PRECHECK = `
(function()
  local fcp = require("cp.apple.finalcutpro")
  local just = require("cp.just")
  local pre = {}

  -- Dismiss any open speed popover
  pcall(function()
    local sp = fcp.timeline.speedPopover
    if sp:isShowing() then
      pre.speedPopoverWasOpen = true
      sp:hide()
      just.doUntil(function() return not sp:isShowing() end, 2)
      hs.timer.usleep(200000)
    end
  end)

  -- Check timeline is showing
  pcall(function()
    pre.timelineShowing = fcp.timeline:isShowing()
  end)

  -- Check selection state
  pcall(function()
    local contents = fcp.timeline.contents
    if contents and contents:isShowing() then
      local selected = contents:selectedClipsUI() or {}
      pre.selectedClipCount = #selected
      if #selected > 0 then
        pre.selectedClipDesc = selected[1]:attributeValue("AXDescription") or "unknown"
      end
    end
  end)

  -- Read playhead timecode
  pcall(function()
    pre.playheadTimecode = tostring(fcp.viewer:timecode())
  end)

  return pre
end)()
`;

/**
 * Lua snippet that reads the current undo/redo text from the Edit menu.
 * Returns: { undoText, redoText }
 * NOTE: This reads menus which steals FCP focus — only use AFTER operations.
 */
const LUA_READ_UNDO_STATE = `
(function()
  local fcp = require("cp.apple.finalcutpro")
  local state = {}
  pcall(function()
    local app = fcp:application()
    local menus = app and app:getMenuItems()
    if menus then
      for _, menu in ipairs(menus) do
        if menu.AXTitle == "Edit" then
          local group = menu.AXChildren and menu.AXChildren[1]
          if group then
            state.undoText = group[1] and group[1].AXTitle or nil
            state.redoText = group[2] and group[2].AXTitle or nil
          end
          break
        end
      end
    end
  end)
  return state
end)()
`;

/**
 * Wrap a Lua operation with undo-text verification.
 * Captures undo text AFTER the operation (not before, to preserve FCP focus),
 * and compares against a pre-captured undo text passed as a parameter.
 * Returns: { result, afterUndoText }
 */
function withUndoCheck(operationCode: string): string {
  return `
-- Guard: FCP must be running
do
  local fcp = require("cp.apple.finalcutpro")
  if not fcp:isRunning() then
    return {error = "Final Cut Pro is not running. Launch it first.", fcpNotRunning = true}
  end
  fcp:launch()
  hs.timer.usleep(300000)

  -- Check for modal dialogs blocking interaction
  local __app = fcp:application()
  if __app then
    local __windows = __app:allWindows()
    if __windows then
      for _, w in ipairs(__windows) do
        local __role = w:role()
        local __subrole = w:subrole()
        if __role == "AXWindow" and (__subrole == "AXDialog" or __subrole == "AXSheet" or __subrole == "AXSystemDialog") then
          return {error = "A modal dialog is open in FCP. Dismiss it before proceeding.", modalDialog = true, dialogTitle = w:title() or "unknown"}
        end
      end
    end
  end
end

-- Dismiss any open speed popover
pcall(function()
  local fcp = require("cp.apple.finalcutpro")
  local sp = fcp.timeline.speedPopover
  if sp:isShowing() then
    sp:hide()
    local just = require("cp.just")
    just.doUntil(function() return not sp:isShowing() end, 2)
    hs.timer.usleep(200000)
  end
end)

-- Capture before undo text (safe here since we haven't done the operation yet
-- and we already ensured FCP focus above)
local __beforeUndo
pcall(function()
  local app = require("cp.apple.finalcutpro"):application()
  local menus = app and app:getMenuItems()
  if menus then
    for _, m in ipairs(menus) do
      if m.AXTitle == "Edit" then
        __beforeUndo = m.AXChildren[1][1].AXTitle
        break
      end
    end
  end
end)

-- Re-activate FCP since getMenuItems may have stolen focus
do
  local fcp = require("cp.apple.finalcutpro")
  fcp:launch()
  hs.timer.usleep(300000)
end

-- Execute the operation
local __opResult = (function()
  ${operationCode}
end)()

-- Capture after undo text
hs.timer.usleep(300000)
local __afterUndo
pcall(function()
  local app = require("cp.apple.finalcutpro"):application()
  local menus = app and app:getMenuItems()
  if menus then
    for _, m in ipairs(menus) do
      if m.AXTitle == "Edit" then
        __afterUndo = m.AXChildren[1][1].AXTitle
        break
      end
    end
  end
end)

if type(__opResult) ~= "table" then __opResult = {value = __opResult} end
__opResult.beforeUndoText = __beforeUndo
__opResult.afterUndoText = __afterUndo
__opResult.undoChanged = __beforeUndo ~= __afterUndo
return __opResult
`;
}

// ── Per-Tool Rate Limiting ──────────────────────────────────────────
// Prevents rapid-fire commands that can race against FCP's UI state.

/** Minimum interval (ms) between calls to the same tool */
const TOOL_COOLDOWNS: Record<string, number> = {
  // Destructive timeline operations
  fcp_timeline_blade: 200,
  fcp_timeline_delete: 300,
  fcp_split_at_timecode: 200,
  // Speed/retime (popover interactions need settling time)
  fcp_speed_custom: 500,
  fcp_retime: 300,
  // Effects and transitions (FCP needs UI time to apply)
  fcp_apply_effect: 400,
  fcp_apply_transition: 500,
  fcp_batch_apply_transition: 1000,
  // Clipboard operations
  fcp_timeline_clipboard: 200,
  fcp_duplicate_clip: 300,
  // Clip modifications
  fcp_set_clip_properties: 300,
  fcp_rename_clip: 300,
  fcp_enable_disable_clip: 200,
  fcp_rate_clip: 200,
  // Navigation (fast but still shouldn't be spammed)
  fcp_set_playhead_position: 100,
  // Inspector operations (UI needs settling)
  fcp_color_wheels: 300,
  fcp_video_inspector: 300,
  fcp_audio_inspector: 300,
  // Toolbar/appearance (popover interactions)
  fcp_timeline_appearance: 500,
  // Transcode (heavy operation)
  fcp_transcode: 1000,
  // Find/replace (dialog interaction)
  fcp_find_replace_titles: 1000,
  // Text to markers (sequential operations)
  fcp_text_to_markers: 500,
};

/** Default cooldown for tools not in the map (0 = no limit) */
const DEFAULT_COOLDOWN_MS = 0;

/** Tracks the last execution time for each tool */
const lastToolExecution: Map<string, number> = new Map();

/**
 * Check if a tool call is within its cooldown period.
 * Returns null if OK, or an error message string if rate-limited.
 */
function checkRateLimit(toolName: string): string | null {
  const cooldown = TOOL_COOLDOWNS[toolName] ?? DEFAULT_COOLDOWN_MS;
  if (cooldown <= 0) return null;

  const now = Date.now();
  const lastExec = lastToolExecution.get(toolName);
  if (lastExec && now - lastExec < cooldown) {
    const waitMs = cooldown - (now - lastExec);
    return `Rate limited: ${toolName} was called ${now - lastExec}ms ago (minimum interval: ${cooldown}ms). Wait ${waitMs}ms before retrying.`;
  }
  lastToolExecution.set(toolName, now);
  return null;
}

async function handleTool(
  name: string,
  args: Record<string, unknown>
): Promise<string> {
  // Check for unknown tool before attempting connection
  if (!KNOWN_TOOLS.has(name)) {
    log("warn", `Unknown tool requested: ${name}`);
    return JSON.stringify({ success: false, error: `Unknown tool: ${name}` });
  }

  log("debug", `Executing tool: ${name}`, args);

  // Rate limit check
  const rateLimitError = checkRateLimit(name);
  if (rateLimitError) {
    log("warn", `Rate limited: ${name}`);
    return JSON.stringify({ success: false, error: rateLimitError, rateLimited: true });
  }

  const validationError = validateToolArgs(name, args);
  if (validationError) {
    log("warn", `Validation failed for tool ${name}: ${validationError}`);
    return JSON.stringify({ success: false, error: validationError });
  }

  try {
    await client.ensureConnected();
  } catch (err) {
    log("error", `Connection failed for tool ${name}`, err instanceof Error ? err.message : String(err));
    return JSON.stringify({
      success: false,
      error: `Cannot connect to CommandPost: ${err instanceof Error ? err.message : String(err)}`,
      help: "Make sure CommandPost is running and the WebSocket server is enabled (CommandPost > Preferences > WebSocket).",
    });
  }

  switch (name) {
    // ── System & Connection ─────────────────────────────────────────
    case "commandpost_ping": {
      const resp = await client.ping();
      return formatResult({ status: "connected", ...resp });
    }

    case "commandpost_list_handlers": {
      const resp = await client.query("handlers");
      return formatResult(extractResult(resp));
    }

    case "commandpost_get_handler_info": {
      const resp = await client.query("handlerInfo", {
        handler: args.handler as string,
        includeChoices: (args.includeChoices as boolean | undefined) ?? true,
        includeParams: (args.includeParams as boolean | undefined) ?? false,
        limit: (args.limit as number | undefined) ?? 200,
        offset: (args.offset as number | undefined) ?? 0,
      });
      return formatResult(extractResult(resp));
    }

    // ── Lua Execution ───────────────────────────────────────────────
    case "commandpost_execute_lua": {
      // Validation already handled by validateToolArgs above
      const resp = await client.executeLua(args.code as string);
      return formatResult(extractResult(resp));
    }

    // ── Action System ───────────────────────────────────────────────
    case "commandpost_execute_action": {
      const resp = await client.executeAction(
        args.handler as string,
        args.actionId as string | undefined,
        args.parameters as Record<string, unknown> | undefined
      );
      return formatResult(extractResult(resp));
    }

    // ── Chaining / Batch ────────────────────────────────────────────
    case "commandpost_chain": {
      const resp = await client.executeBatch(
        args.operations as Array<Record<string, unknown>>,
        (args.stopOnError as boolean) ?? true
      );
      return formatResult(extractResult(resp));
    }

    // ── Preferences ─────────────────────────────────────────────────
    case "commandpost_get_preference": {
      const key = args.key as string;
      const resp = await client.executeLua(
        `return require("cp.config").get("${escapeLua(key)}")`
      );
      return formatResult(extractResult(resp));
    }

    case "commandpost_set_preference": {
      const key = args.key as string;
      const value = args.value;
      const luaValue = toLuaLiteral(value);
      const resp = await client.executeLua(
        `require("cp.config").set("${escapeLua(key)}", ${luaValue}) return true`
      );
      return formatResult(extractResult(resp));
    }

    // ── FCP Application ─────────────────────────────────────────────
    case "fcp_launch": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:launch()
        return {launched = true}
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_quit": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:quit()
        return {quit = true}
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_restart": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:quit()
        hs.timer.doAfter(3, function() fcp:launch() end)
        return {restarting = true}
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_status": {
      const resp = await client.executeLua(FCP_STATUS_LUA);
      return formatResult(extractResult(resp));
    }

    case "fcp_select_menu": {
      const path = args.path as string[];
      const luaPath = path.map((s) => `"${escapeLua(s)}"`).join(", ");
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")
        local result = fcp:selectMenu({${luaPath}}, {plain = true})
        return {menuPath = {${luaPath}}, menuResult = result ~= nil}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      return formatResult({
        ...result,
        success: result?.menuResult === true || result?.undoChanged === true,
        ...(!result?.menuResult ? {
          warning: "selectMenu returned nil. The menu item may be disabled or the path may be incorrect.",
        } : {}),
      });
    }

    case "fcp_do_shortcut": {
      const command = args.command as string;
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:doShortcut("${escapeLua(command)}"):Now()
        return {command = "${escapeLua(command)}"}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      return formatResult({
        ...result,
        executed: true,
        ...(!result?.undoChanged ? {
          warning: "Shortcut executed but undo state did not change. The command may have had no effect in the current context.",
        } : {}),
      });
    }

    // ── FCP Timeline ────────────────────────────────────────────────
    case "fcp_timeline_show": {
      const display = (args.display as string) || "primary";
      const method =
        display === "secondary" ? "showOnSecondary" : "showOnPrimary";
      const resp = await client.executeLua(safeLua(`
        local just = require("cp.just")
        local fcp = require("cp.apple.finalcutpro")
        local timeline = fcp.timeline

        fcp:launch()
        local app = fcp:application()
        if app then
          pcall(function() app:activate() end)
          hs.timer.usleep(300000)
        end

        timeline:${method}()
        hs.timer.usleep(300000)

        if not timeline:isShowing() then
          timeline:show()
          hs.timer.usleep(300000)
        end

        local shown = just.doUntil(function()
          return timeline:isShowing()
        end, 5)
        local isShown = shown and true or false

        local result = {
          shown = isShown,
          display = "${escapeLua(display)}",
          loaded = safeGet(function() return timeline:isLoaded() end),
        }
        if not isShown then
          result.error = "Timeline did not become visible"
        end
        return result
      `), 45000);
      return formatResult(extractResult(resp));
    }

    case "fcp_timeline_playback": {
      const action = (args.action as string) || "toggle";
      let code: string;
      if (action === "play") {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          local wasPlaying = fcp.viewer:isPlaying()
          -- Use the native viewer API instead of doShortcut("PlayPause")
          fcp.viewer:doPlay():Now()
          return {action = "play", changed = not wasPlaying, playing = true}
        `;
      } else if (action === "pause") {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          local wasPlaying = fcp.viewer:isPlaying()
          -- Use the native viewer API instead of doShortcut("PlayPause")
          fcp.viewer:doPause():Now()
          return {action = "pause", changed = wasPlaying, playing = false}
        `;
      } else {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          local wasPlaying = fcp.viewer:isPlaying()
          -- Use the native viewer isPlaying property toggle
          fcp.viewer.isPlaying:toggle()
          return {action = "toggle", previouslyPlaying = wasPlaying}
        `;
      }
      const resp = await client.executeLua(code);
      return formatResult(extractResult(resp));
    }

    case "fcp_timeline_navigate": {
      const action = args.action as string;
      const timecode = args.timecode as string | undefined;
      let code: string;
      switch (action) {
        case "beginning":
          code = `require("cp.apple.finalcutpro"):doShortcut("JumpToStart"):Now() return {navigated = "beginning"}`;
          break;
        case "end":
          code = `require("cp.apple.finalcutpro"):doShortcut("JumpToEnd"):Now() return {navigated = "end"}`;
          break;
        case "next_frame":
          code = `require("cp.apple.finalcutpro"):doShortcut("JumpToNextFrame"):Now() return {navigated = "next_frame"}`;
          break;
        case "previous_frame":
          code = `require("cp.apple.finalcutpro"):doShortcut("JumpToPreviousFrame"):Now() return {navigated = "previous_frame"}`;
          break;
        case "next_edit":
          code = `require("cp.apple.finalcutpro"):doShortcut("NextEdit"):Now() return {navigated = "next_edit"}`;
          break;
        case "previous_edit":
          code = `require("cp.apple.finalcutpro"):doShortcut("PreviousEdit"):Now() return {navigated = "previous_edit"}`;
          break;
        case "timecode":
          code = `
            local fcp = require("cp.apple.finalcutpro")
            local result = fcp.viewer:timecode("${escapeLua(timecode || "00:00:00:00")}")
            return {navigated = "timecode", timecode = result}
          `;
          break;
        default:
          return JSON.stringify({ error: `Unknown navigation action: ${action}` });
      }
      const resp = await client.executeLua(withTimecodeCheck(code));
      return formatResult(extractResult(resp));
    }

    case "fcp_timeline_select": {
      const action = args.action as string;
      const clipIndex = args.index as number | undefined;
      const resp = await client.executeLua(safeLua(`
        local contents = fcp.timeline.contents
        if not contents:isShowing() then
          return {selected = "${escapeLua(action)}", changed = false, count = 0, error = "Timeline is not showing"}
        end

        pcall(function() contents:doFocus(true):Now() end)
        hs.timer.usleep(200000)

        -- Helper: get only real clips (not transitions, playhead, accessories)
        local function getActualClips()
          local all = contents:clipsUI(true) or {}
          local actual = {}
          for _, c in ipairs(all) do
            local desc = c:attributeValue("AXDescription") or ""
            if not desc:find("Transition") and not desc:find("Playhead") and not desc:find("accessory") then
              table.insert(actual, c)
            end
          end
          return actual
        end

        local beforeSelection = contents:selectedClipsUI(true) or {}

        if "${escapeLua(action)}" == "all" then
          local clips = contents:clipsUI(true)
          if not clips or #clips == 0 then
            return {selected = "all", changed = false, count = 0, totalClips = 0, error = "No timeline clips available to select"}
          end

          contents:selectClips(clips)
          hs.timer.usleep(250000)

          local afterSelection = contents:selectedClipsUI(true) or {}
          if #afterSelection == 0 then
            return {selected = "all", changed = false, count = 0, totalClips = #clips, error = "Timeline selection did not change"}
          end

          return {
            selected = "all",
            changed = #afterSelection ~= #beforeSelection,
            count = #afterSelection,
            totalClips = #clips,
          }

        elseif "${escapeLua(action)}" == "at_playhead" then
          local playheadClips = contents:playheadClipsUI(true) or {}
          if #playheadClips == 0 then
            return {selected = "at_playhead", changed = false, count = 0, error = "No clip under playhead"}
          end
          -- Select the first (primary storyline) clip at playhead
          contents:selectClip(playheadClips[1])
          hs.timer.usleep(250000)
          local afterSelection = contents:selectedClipsUI(true) or {}
          local desc = playheadClips[1]:attributeValue("AXDescription") or "unknown"
          return {
            selected = "at_playhead",
            changed = true,
            count = #afterSelection,
            clipDescription = desc,
          }

        elseif "${escapeLua(action)}" == "by_index" then
          local idx = ${clipIndex ?? 1}
          local actualClips = getActualClips()
          if idx < 1 or idx > #actualClips then
            return {selected = "by_index", changed = false, count = 0, error = "Index " .. idx .. " out of range (1-" .. #actualClips .. ")", totalClips = #actualClips}
          end
          contents:selectClip(actualClips[idx])
          hs.timer.usleep(250000)
          local afterSelection = contents:selectedClipsUI(true) or {}
          local desc = actualClips[idx]:attributeValue("AXDescription") or "unknown"
          return {
            selected = "by_index",
            index = idx,
            changed = true,
            count = #afterSelection,
            clipDescription = desc,
            totalClips = #actualClips,
          }

        else
          -- "none"
          contents:selectNone()
          hs.timer.usleep(250000)

          local afterSelection = contents:selectedClipsUI(true) or {}
          if #afterSelection ~= 0 then
            return {
              selected = "none",
              changed = #beforeSelection > 0 and #afterSelection < #beforeSelection,
              count = #afterSelection,
              error = "Timeline selection did not clear",
            }
          end

          return {
            selected = "none",
            changed = #beforeSelection > 0,
            count = 0,
          }
        end
      `));
      return formatResult(extractResult(resp));
    }

    case "fcp_timeline_blade": {
      const resp = await client.executeLua(safeLua(`
        local contents = fcp.timeline.contents
        if not contents:isShowing() then
          return {action = "blade", cut = false, error = "Timeline is not showing"}
        end

        pcall(function() contents:doFocus(true):Now() end)
        hs.timer.usleep(200000)

        local playheadPosition = contents.playhead and contents.playhead:position()
        local clipsAtPlayhead = contents:playheadClipsUI(true) or {}
        if #clipsAtPlayhead == 0 then
          return {action = "blade", cut = false, error = "No clip under playhead"}
        end

        local function isUndoBlade(title)
          return type(title) == "string" and string.match(title, "^Undo Blade") ~= nil
        end

        local function clipSignature(clips)
          local parts = {}
          for i, clip in ipairs(clips or {}) do
            if i > 60 then break end
            local desc = clip:attributeValue("AXDescription") or ""
            local value = clip:attributeValue("AXValue") or ""
            local pos = clip:attributeValue("AXPosition") or {}
            local size = clip:attributeValue("AXSize") or {}
            parts[#parts + 1] = table.concat({
              desc,
              value,
              tostring(pos.x or ""),
              tostring(pos.y or ""),
              tostring(size.w or ""),
              tostring(size.h or ""),
            }, "|")
          end
          return table.concat(parts, "||")
        end

        local function editMenuUndoTitle()
          local undoTitle = nil
          local app = require("cp.apple.finalcutpro"):application()
          local menus = app and app:getMenuItems()
          if menus then
            for _, menu in ipairs(menus) do
              if menu.AXTitle == "Edit" then
                undoTitle = menu.AXChildren and menu.AXChildren[1] and menu.AXChildren[1][1] and menu.AXChildren[1][1].AXTitle
                break
              end
            end
          end
          return undoTitle
        end

        local function captureState()
          local function readState()
            local clips = contents:clipsUI(true) or {}
            return {
              clips = clips,
              count = #clips,
              signature = clipSignature(clips),
              undoTitle = editMenuUndoTitle(),
            }
          end

          local state = readState()
          if state.count == 0 then
            hs.timer.usleep(300000)
            state = readState()
          end
          return state
        end

        local function stateChanged(beforeState, afterState)
          local clipDelta = (afterState.count or 0) - (beforeState.count or 0)
          local undoChanged = beforeState.undoTitle ~= afterState.undoTitle
          local undoIndicatesBlade = isUndoBlade(afterState.undoTitle)
          local changed = clipDelta > 0
            or afterState.signature ~= beforeState.signature
            or (undoChanged and undoIndicatesBlade)
          return changed, clipDelta
        end

        local function attemptBlade(mode, menuPath, shortcut, beforeState)
          local okMenu, menuResult = pcall(function()
            return fcp:doSelectMenu(menuPath):Now()
          end)
          hs.timer.usleep(300000)

          local afterMenu = captureState()
          local changedAfterMenu = stateChanged(beforeState, afterMenu)
          if changedAfterMenu then
            return true, "menu", afterMenu, okMenu and menuResult or nil
          end

          local okShortcut, shortcutErr = pcall(function()
            fcp:doShortcut(shortcut):Now()
            return true
          end)
          hs.timer.usleep(300000)

          local afterShortcut = captureState()
          local changedAfterShortcut = stateChanged(beforeState, afterShortcut)
          if changedAfterShortcut then
            return true, "shortcut", afterShortcut, okShortcut and true or shortcutErr
          end

          local detail = nil
          if not okMenu then
            detail = tostring(menuResult)
          elseif not okShortcut then
            detail = tostring(shortcutErr)
          end

          return false, detail or mode, afterShortcut, okShortcut and true or shortcutErr
        end

        local beforeState = captureState()
        local beforeCount = beforeState.count
        local selectedAtPlayhead = {}
        if type(playheadPosition) == "number" then
          for _, clip in ipairs(contents:selectedClipsUI(true) or {}) do
            local frame = clip:attributeValue("AXFrame")
            if frame and playheadPosition >= frame.x and playheadPosition <= (frame.x + frame.w) then
              selectedAtPlayhead[#selectedAtPlayhead + 1] = clip
            end
          end
        end

        local mode = (#selectedAtPlayhead == 1 or #clipsAtPlayhead == 1) and "single" or "all"
        local trigger = nil
        local afterState = beforeState
        local commandDetail = nil

        local success, sourceOrDetail, attemptState, detail = attemptBlade(
          mode,
          mode == "all" and {"Trim", "Blade All"} or {"Trim", "Blade"},
          mode == "all" and "BladeAll" or "BladeAtPlayhead",
          beforeState
        )
        trigger = success and sourceOrDetail or nil
        commandDetail = detail
        afterState = attemptState

        local changed, clipDelta = stateChanged(beforeState, afterState)
        if not success and mode ~= "all" then
          local fallbackSuccess, fallbackSourceOrDetail, fallbackState, fallbackDetail = attemptBlade(
            "all",
            {"Trim", "Blade All"},
            "BladeAll",
            beforeState
          )
          if fallbackSuccess then
            mode = "all"
            trigger = fallbackSourceOrDetail
            commandDetail = fallbackDetail
            afterState = fallbackState
            changed, clipDelta = stateChanged(beforeState, afterState)
          else
            commandDetail = fallbackDetail or sourceOrDetail
            afterState = fallbackState
            changed, clipDelta = stateChanged(beforeState, afterState)
          end
        end

        if not changed then
          return {
            action = "blade",
            cut = false,
            mode = mode,
            beforeCount = beforeCount,
            afterCount = afterState.count,
            clipDelta = clipDelta,
            trigger = trigger,
            undoText = afterState.undoTitle,
            detail = commandDetail,
            error = "Blade command did not change the timeline",
          }
        end

        return {
          action = "blade",
          cut = true,
          mode = mode,
          beforeCount = beforeCount,
          afterCount = afterState.count,
          clipDelta = clipDelta,
          trigger = trigger,
          undoText = afterState.undoTitle,
        }
      `));
      return formatResult(extractResult(resp));
    }

    case "fcp_timeline_delete": {
      const resp = await client.executeLua(withVerification(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          -- Try selecting clip at playhead
          local playheadClips = contents:playheadClipsUI(true) or {}
          if #playheadClips == 0 then
            return {action = "delete", error = "No clip selected and no clip under playhead."}
          end
          contents:selectClip(playheadClips[1])
          hs.timer.usleep(200000)
        end

        -- Use menu Delete which is more reliable than doShortcut
        fcp:selectMenu({"Edit", "Delete"}, {plain = true})
        hs.timer.usleep(300000)
        return {action = "delete"}
      `));
      return formatResult(extractResult(resp));
    }

    case "fcp_timeline_clipboard": {
      const action = args.action as string;
      const shortcutMap: Record<string, string> = {
        copy: "Copy",
        cut: "Cut",
        paste: "Paste",
      };
      const resp = await client.executeLua(withVerification(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:doShortcut("${shortcutMap[action]}"):Now()
        return {action = "${action}"}
      `));
      return formatResult(extractResult(resp));
    }

    case "fcp_timeline_zoom": {
      const action = args.action as string;
      let code: string;
      if (action === "in") {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          local appearance = fcp.timeline.toolbar.appearance
          appearance:show()
          local zoom = appearance.zoomAmount
          if zoom then
            zoom:shiftValue(1)
          end
          appearance:hide()
          return {zoomed = "in"}
        `;
      } else if (action === "out") {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          local appearance = fcp.timeline.toolbar.appearance
          appearance:show()
          local zoom = appearance.zoomAmount
          if zoom then
            zoom:shiftValue(-1)
          end
          appearance:hide()
          return {zoomed = "out"}
        `;
      } else {
        code = `require("cp.apple.finalcutpro"):doShortcut("ZoomToFit"):Now() return {zoomed = "fit"}`;
      }
      const resp = await client.executeLua(code);
      return formatResult(extractResult(resp));
    }

    case "fcp_timeline_get_info": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local timeline = fcp.timeline
        local result = {
          showing = timeline:isShowing(),
          onPrimary = timeline:isOnPrimary(),
          onSecondary = timeline:isOnSecondary(),
          playing = timeline:isPlaying(),
          focused = timeline:isFocused(),
        }
        -- Read playhead timecode
        pcall(function()
          result.timecode = tostring(fcp.viewer:timecode())
        end)
        -- Read clip list from AX tree
        pcall(function()
          local contents = timeline.contents:UI()
          if contents then
            local children = contents:attributeValue("AXChildren")
            if children then
              result.clips = {}
              result.clipCount = 0
              for _, c in ipairs(children) do
                local desc = c:attributeValue("AXDescription")
                if desc and desc ~= "Playhead" then
                  result.clipCount = result.clipCount + 1
                  table.insert(result.clips, {
                    description = desc,
                    duration = c:attributeValue("AXValue"),
                  })
                end
              end
            end
          end
        end)
        -- Read undo state via CommandPost's app reference
        pcall(function()
          local app = fcp:application()
          if app then
            local menus = app:getMenuItems()
            if menus then
              for _, m in ipairs(menus) do
                if m.AXTitle == "Edit" then
                  result.undoText = m.AXChildren[1][1].AXTitle
                  break
                end
              end
            end
          end
        end)
        return result
      `);
      return formatResult(extractResult(resp));
    }

    // ── FCP Effects & Plugins ───────────────────────────────────────
    case "fcp_apply_effect": {
      const effectName = args.name as string;
      const effectType = (args.type as string) || "video";
      const handler =
        effectType === "audio" ? "fcpx_audioEffect" : "fcpx_videoEffect";

      // Pre-check: verify clip is selected and capture before-state
      const beforeState = (unwrapNestedResult(await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local result = {}
        pcall(function()
          local contents = fcp.timeline.contents
          if contents and contents:isShowing() then
            local selected = contents:selectedClipsUI() or {}
            result.selectedClipCount = #selected
          end
        end)
        pcall(function()
          local app = fcp:application()
          local menus = app and app:getMenuItems()
          if menus then
            for _, m in ipairs(menus) do
              if m.AXTitle == "Edit" then
                result.undoText = m.AXChildren[1][1].AXTitle
                break
              end
            end
          end
        end)
        return result
      `)) ?? {}) as Record<string, unknown>;

      if (Number(beforeState?.selectedClipCount ?? 0) === 0) {
        return formatResult({
          action: "apply_effect",
          name: effectName,
          type: effectType,
          success: false,
          error: "No clip selected. Select a clip in the timeline before applying an effect.",
        });
      }

      await activateFinalCutPro();
      const resp = await client.executeAction(handler, effectName);
      await delay(800);

      // Post-check: verify undo text changed
      const afterState = (unwrapNestedResult(await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local result = {}
        pcall(function()
          local app = fcp:application()
          local menus = app and app:getMenuItems()
          if menus then
            for _, m in ipairs(menus) do
              if m.AXTitle == "Edit" then
                result.undoText = m.AXChildren[1][1].AXTitle
                break
              end
            end
          end
        end)
        return result
      `)) ?? {}) as Record<string, unknown>;

      const undoChanged = beforeState?.undoText !== afterState?.undoText;
      return formatResult({
        action: "apply_effect",
        name: effectName,
        type: effectType,
        applied: undoChanged,
        result: extractResult(resp),
        ...(!undoChanged ? {
          error: `Effect "${effectName}" may not have been applied. The undo state did not change. Check that the effect name is correct and a clip is selected.`,
        } : {}),
      });
    }

    case "fcp_apply_transition": {
      const transName = args.name as string;

      // Pre-check: ensure a clip is selected (auto-select at playhead if not)
      const preCheckResp = await client.executeLua(safeLua(`
        local contents = fcp.timeline.contents
        if not contents:isShowing() then
          return {error = "Timeline is not showing"}
        end

        local selected = contents:selectedClipsUI() or {}
        if #selected == 0 then
          -- Auto-select clip at playhead
          local playheadClips = contents:playheadClipsUI(true) or {}
          if #playheadClips > 0 then
            contents:selectClip(playheadClips[1])
            hs.timer.usleep(200000)
            selected = contents:selectedClipsUI() or {}
          end
        end

        -- Count transitions before
        local transitionCount = 0
        local clipCount = 0
        local allClips = contents:clipsUI(true) or {}
        for _, clip in ipairs(allClips) do
          local desc = clip:attributeValue("AXDescription") or ""
          if string.sub(desc, 1, 11) == "Transition:" then
            transitionCount = transitionCount + 1
          end
          clipCount = clipCount + 1
        end

        -- Read undo text via AX (more reliable than getMenuItems)
        local undoText = nil
        pcall(function()
          local editMenu = fcp:menu():findMenuUI({"Edit"})
          if editMenu then
            local items = editMenu:attributeValue("AXChildren")
            if items and items[1] then
              local undoItems = items[1]:attributeValue("AXChildren")
              if undoItems and undoItems[1] then
                undoText = undoItems[1]:attributeValue("AXTitle")
              end
            end
          end
        end)

        return {
          selectedCount = #selected,
          transitionCount = transitionCount,
          clipCount = clipCount,
          undoText = undoText,
        }
      `));
      const beforeState = (unwrapNestedResult(preCheckResp) ?? {}) as Record<string, unknown>;

      if (beforeState?.error) {
        return formatResult({ action: "apply_transition", name: transName, applied: false, ...beforeState });
      }

      await activateFinalCutPro();
      const actionResult = extractResult(await client.executeAction("fcpx_transition", transName));
      await delay(1200);

      // Check for and handle FCP dialogs (e.g., "not enough media handles" prompt)
      const dialogResp = await client.executeLua(safeLua(`
        -- Check for media handles dialog and auto-accept "Create Transition"
        local dialogResult = handleFCPDialog(false)
        if dialogResult then
          hs.timer.usleep(800000)
        end
        return {dialog = dialogResult}
      `));
      const dialogState = (unwrapNestedResult(dialogResp) ?? {}) as Record<string, unknown>;
      const dialogHandled = dialogState?.dialog as Record<string, unknown> | undefined;
      if (dialogHandled) {
        // Dialog was present — wait extra time for transition to finalize
        await delay(800);
      }

      // Read after-state
      const afterResp = await client.executeLua(safeLua(`
        local contents = fcp.timeline.contents
        local transitionCount = 0
        local clipCount = 0
        local allClips = contents:clipsUI(true) or {}
        for _, clip in ipairs(allClips) do
          local desc = clip:attributeValue("AXDescription") or ""
          if string.sub(desc, 1, 11) == "Transition:" then
            transitionCount = transitionCount + 1
          end
          clipCount = clipCount + 1
        end

        local undoText = nil
        pcall(function()
          local editMenu = fcp:menu():findMenuUI({"Edit"})
          if editMenu then
            local items = editMenu:attributeValue("AXChildren")
            if items and items[1] then
              local undoItems = items[1]:attributeValue("AXChildren")
              if undoItems and undoItems[1] then
                undoText = undoItems[1]:attributeValue("AXTitle")
              end
            end
          end
        end)

        return {
          transitionCount = transitionCount,
          clipCount = clipCount,
          undoText = undoText,
        }
      `));
      const afterState = (unwrapNestedResult(afterResp) ?? {}) as Record<string, unknown>;

      const beforeUndoText = beforeState?.undoText as string | undefined;
      const afterUndoText = afterState?.undoText as string | undefined;
      const beforeTransitionCount = Number(beforeState?.transitionCount ?? 0);
      const afterTransitionCount = Number(afterState?.transitionCount ?? 0);
      const undoChanged = beforeUndoText !== afterUndoText;
      const transitionCountChanged = afterTransitionCount > beforeTransitionCount;
      const undoSaysTransition = typeof afterUndoText === "string" && afterUndoText.includes("Transition");
      const applied = undoChanged || transitionCountChanged || undoSaysTransition;

      if (!applied) {
        return formatResult({
          action: "apply_transition",
          name: transName,
          applied: false,
          beforeUndoText,
          afterUndoText,
          beforeTransitionCount,
          afterTransitionCount,
          error: Number(beforeState?.selectedCount ?? 0) === 0
            ? "No clips are selected. Select a clip or position the playhead on a clip first."
            : "Transition may not have applied. Ensure the clip has sufficient media handles at the edit point.",
        });
      }

      return formatResult({
        action: "apply_transition",
        name: transName,
        applied: true,
        ...(dialogHandled ? { mediaHandlesDialog: true, dialogAction: dialogHandled.clicked } : {}),
        verifiedBy: transitionCountChanged ? "transition_count" : (undoSaysTransition ? "undo_text" : "undo_changed"),
        beforeTransitionCount,
        afterTransitionCount,
      });
    }

    case "fcp_apply_generator": {
      const genName = args.name as string;
      await activateFinalCutPro();
      const resp = await client.executeAction("fcpx_generator", genName);
      return formatResult({
        action: "apply_generator",
        name: genName,
        result: extractResult(resp),
      });
    }

    case "fcp_apply_title": {
      const titleName = args.name as string;
      await activateFinalCutPro();
      const resp = await client.executeAction("fcpx_title", titleName);
      return formatResult({
        action: "apply_title",
        name: titleName,
        result: extractResult(resp),
      });
    }

    // ── FCP Browser ─────────────────────────────────────────────────
    case "fcp_browser_show": {
      const panel = (args.panel as string) || "libraries";
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local browser = fcp.browser
        browser:showOnPrimary()
        if "${escapeLua(panel)}" == "media" then
          browser.showMedia:checked(true)
        elseif "${escapeLua(panel)}" == "generators" then
          browser.showGenerators:checked(true)
        else
          browser.showLibraries:checked(true)
        end
        return {shown = true, panel = "${escapeLua(panel)}"}
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_browser_list_libraries": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local names = fcp:activeLibraryNames() or {}
        local paths = fcp:activeLibraryPaths() or {}
        local libs = {}
        for i, name in ipairs(names) do
          table.insert(libs, {name = name, path = paths[i] or "unknown"})
        end
        return libs
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_browser_select_library": {
      const title = args.title as string;
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local result = fcp:selectLibrary("${escapeLua(title)}")
        return {selected = result ~= nil, library = "${escapeLua(title)}"}
      `);
      return formatResult(extractResult(resp));
    }

    // ── FCP Inspector ───────────────────────────────────────────────
    case "fcp_inspector_show": {
      const tabArg = args.tab as string | undefined;
      const tab = tabArg ? INSPECTOR_TAB_MAP[tabArg] : undefined;
      if (tabArg && !tab) {
        return JSON.stringify({ error: `Unknown inspector tab: ${tabArg}` });
      }
      let code: string;
      if (tab) {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          fcp.inspector:show("${escapeLua(tab)}")
          return {shown = true, tab = "${escapeLua(tab)}"}
        `;
      } else {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          fcp.inspector:show()
          return {shown = true}
        `;
      }
      const resp = await client.executeLua(code);
      return formatResult(extractResult(resp));
    }

    // ── FCP Viewer ──────────────────────────────────────────────────
    case "fcp_viewer_show": {
      const display = (args.display as string) || "primary";
      const method =
        display === "secondary" ? "showOnSecondary" : "showOnPrimary";
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp.viewer:${method}()
        return {shown = true, display = "${escapeLua(display)}"}
      `);
      return formatResult(extractResult(resp));
    }

    // ── FCP Color ───────────────────────────────────────────────────
    case "fcp_color_board": {
      const aspect = args.aspect as string;
      const puck = args.puck as string;
      const value = args.value as number;
      const property = ((args.property as string) || "percentage") === "angle"
        ? "angle"
        : "percent";

      // Allowlist to prevent Lua injection via property access
      const validAspects = new Set(["color", "saturation", "exposure"]);
      const validPucks = new Set(["master", "shadows", "midtones", "highlights"]);
      if (!validAspects.has(aspect)) {
        return JSON.stringify({ success: false, error: `Invalid aspect: ${aspect}` });
      }
      if (!validPucks.has(puck)) {
        return JSON.stringify({ success: false, error: `Invalid puck: ${puck}` });
      }

      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local colorBoard = fcp.colorBoard
        colorBoard:show()
        local aspectPanel = colorBoard.${aspect}
        local puckControl = aspectPanel.${puck}
        puckControl:show()
        puckControl:${property}(${value})
        return {adjusted = true, aspect = "${escapeLua(aspect)}", puck = "${escapeLua(puck)}", value = ${value}}
      `);
      return formatResult(extractResult(resp));
    }

    // ── FCP Export/Import ───────────────────────────────────────────
    case "fcp_export": {
      const destination = args.destination as string | undefined;
      let code: string;
      if (destination) {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          fcp:selectMenu({"File", "Share", "${escapeLua(destination)}"}, {plain = true})
          return {exporting = true, destination = "${escapeLua(destination)}"}
        `;
      } else {
        code = `
          local fcp = require("cp.apple.finalcutpro")
          fcp:selectMenu({"File", "Share", "Master File..."}, {plain = true})
          return {exporting = true, destination = "Master File"}
        `;
      }
      const resp = await client.executeLua(code);
      return formatResult(extractResult(resp));
    }

    case "fcp_import_media": {
      const path = args.path as string;
      const pathErr = validateFilePath(path);
      if (pathErr) return JSON.stringify({ error: pathErr });
      const resp = await client.executeLua(`
        local fs = require("hs.fs")
        local fcp = require("cp.apple.finalcutpro")
        local mediaImport = fcp.mediaImport
        local path = fs.pathToAbsolute("${escapeLua(path)}") or "${escapeLua(path)}"
        local attributes = fs.attributes(path)

        if not attributes then
          return {imported = false, path = path, error = "Path does not exist"}
        end

        local imported, message = mediaImport:importPath(path)
        if not imported then
          return {
            imported = false,
            path = path,
            kind = attributes.mode,
            error = message,
          }
        end

        return {imported = true, path = path, kind = attributes.mode}
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_import_xml": {
      const path = args.path as string;
      const pathErr = validateFilePath(path);
      if (pathErr) return JSON.stringify({ error: pathErr });
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:importXML("${escapeLua(path)}")
        return {imported = true, path = "${escapeLua(path)}"}
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_export_xml": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:selectMenu({"File", "Export XML..."}, {plain = true})
        return {exporting = true}
      `);
      return formatResult(extractResult(resp));
    }

    // ── FCP Projects & Libraries ────────────────────────────────────
    case "fcp_open_project": {
      const projectName = args.name as string;
      const resp = await client.executeLua(safeLua(`
        local just = require("cp.just")
        local fcp = require("cp.apple.finalcutpro")
        local projectName = "${escapeLua(projectName)}"

        fcp:launch()
        local app = fcp:application()
        if app then
          pcall(function() app:activate() end)
          hs.timer.usleep(300000)
        end

        local function currentProjectTitle()
          return safeGet(function() return fcp.timeline.toolbar.title:title() end)
            or safeGet(function() return fcp.timeline.toolbar.title:value() end)
        end

        local function waitUntilReady(seconds)
          return just.doUntil(function()
            return fcp.timeline:isLoaded() and fcp.timeline:isShowing()
          end, seconds)
        end

        local showing = safeGet(function() return fcp.timeline:isShowing() end)
        local loaded = safeGet(function() return fcp.timeline:isLoaded() end)
        local currentProject = currentProjectTitle()

        if currentProject == projectName then
          pcall(function() fcp.timeline:show() end)
          local ready = waitUntilReady(20)
          local isReady = ready and true or false
          local result = {
            opened = projectName,
            ready = isReady,
            alreadyOpen = true,
            showing = safeGet(function() return fcp.timeline:isShowing() end),
            loaded = safeGet(function() return fcp.timeline:isLoaded() end),
            currentProject = currentProject,
            currentTimecode = safeGet(function() return fcp.viewer:timecode() end),
          }
          if not isReady then
            result.error = "Project is already selected but the timeline did not become visible"
          end
          return result
        end

        fcp.timeline:doOpenProject(projectName):Now()
        pcall(function() fcp.timeline:show() end)

        local ready = waitUntilReady(20)
        local isReady = ready and true or false

        local finalProject = currentProjectTitle()
        local finalShowing = safeGet(function() return fcp.timeline:isShowing() end)
        local finalLoaded = safeGet(function() return fcp.timeline:isLoaded() end)

        if not isReady then
          return {
            opened = projectName,
            ready = false,
            showing = finalShowing,
            loaded = finalLoaded,
            currentProject = finalProject,
            currentTimecode = safeGet(function() return fcp.viewer:timecode() end),
            error = "Project did not become ready with a visible timeline",
          }
        end

        return {
          opened = projectName,
          ready = isReady,
          alreadyOpen = finalProject == projectName,
          showing = finalShowing,
          loaded = finalLoaded,
          currentProject = finalProject,
          currentTimecode = safeGet(function() return fcp.viewer:timecode() end),
        }
      `), 90000);
      return formatResult(extractResult(resp));
    }

    case "fcp_project_properties": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:selectMenu({"Window", "Project Properties"}, {plain = true})
        return {showing = true}
      `);
      return formatResult(extractResult(resp));
    }

    // ── FCP Markers & Keywords ──────────────────────────────────────
    case "fcp_add_marker": {
      const markerType = (args.type as string) || "standard";
      const markerName = typeof args.name === "string" ? args.name.trim() : "";
      const hasMarkerName = markerName.length > 0;
      const completed =
        typeof args.completed === "boolean" ? args.completed : undefined;

      if (completed !== undefined && markerType !== "todo") {
        return JSON.stringify({
          error: "'completed' is only supported for todo markers",
        });
      }

      let code: string;
      if (!hasMarkerName && completed === undefined) {
        const shortcutMap: Record<string, string> = {
          standard: "AddMarker",
          todo: "AddToDoMarker",
          chapter: "AddChapterMarker",
        };
        code = `
          local just = require("cp.just")
          local fcp = require("cp.apple.finalcutpro")
          fcp.timeline:show()
          if not just.doUntil(function() return fcp.timeline:isLoaded() end, 2) then
            return {marker = "${escapeLua(markerType)}", added = false, error = "No open timeline"}
          end

          if not fcp.timeline:isFocused() then
            fcp.timeline.contents:focus()
            just.doUntil(function() return fcp.timeline:isFocused() end, 1)
          end

          fcp:doShortcut("${shortcutMap[markerType]}"):Now()
          return {marker = "${escapeLua(markerType)}", added = true}
        `;
      } else if (markerType === "standard" && completed === undefined) {
        code = `
          local just = require("cp.just")
          local axutils = require("cp.ui.axutils")
          local childrenWithRole = axutils.childrenWithRole
          local fcp = require("cp.apple.finalcutpro")

          local function focusedElement()
            return hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
          end

          local function focusedTextField()
            local focused = focusedElement()
            if focused and focused:attributeValue("AXRole") == "AXTextField" then
              return focused
            end
            return nil
          end

          local function ancestorWithRole(element, role)
            local current = element
            local depth = 0
            while current and depth < 12 do
              if current:attributeValue("AXRole") == role then
                return current
              end
              current = current:attributeValue("AXParent")
              depth = depth + 1
            end
            return nil
          end

          local function doneButtonFor(popover)
            if not popover then return nil end
            for _, button in ipairs(childrenWithRole(popover, "AXButton") or {}) do
              if button:attributeValue("AXTitle") == "Done" then
                return button
              end
            end
            return nil
          end

          fcp.timeline:show()
          if not just.doUntil(function() return fcp.timeline:isLoaded() end, 2) then
            return {marker = "standard", added = false, error = "No open timeline"}
          end

          if not fcp.timeline:isFocused() then
            pcall(function() fcp.timeline.contents:doFocus(true):Now() end)
            just.doUntil(function() return fcp.timeline:isFocused() end, 1)
          end

          local triggered = false
          pcall(function()
            triggered = fcp:doSelectMenu({"Mark", "Markers", "Add Marker and Modify"}):Now() == true
          end)
          if not triggered then
            fcp:doShortcut("AddAndEditMarker"):Now()
          end

          local nameField = nil
          if not just.doUntil(function()
            nameField = focusedTextField()
            return nameField ~= nil
          end, 2) then
            local focused = focusedElement()
            return {
              marker = "standard",
              added = false,
              error = "Marker name field did not appear",
              focusedRole = focused and focused:attributeValue("AXRole") or nil,
            }
          end

          nameField:setAttributeValue("AXValue", "${escapeLua(markerName)}")
          hs.timer.usleep(100000)

          local actualName = nameField:attributeValue("AXValue")
          if actualName ~= "${escapeLua(markerName)}" then
            return {
              marker = "standard",
              added = false,
              error = "Unable to set marker name",
              requestedName = "${escapeLua(markerName)}",
              actualName = actualName,
            }
          end

          local popover = ancestorWithRole(nameField, "AXPopover")
          local doneButton = doneButtonFor(popover)
          local pressed = doneButton and doneButton:performAction("AXPress") == true
          if not pressed then
            pcall(function() nameField:performAction("AXConfirm") end)
          end

          local closed = just.doUntil(function()
            local focused = focusedElement()
            return ancestorWithRole(focused, "AXPopover") == nil
          end, 2)

          if not closed then
            return {
              marker = "standard",
              added = false,
              error = "Marker editor did not close",
              name = actualName,
            }
          end

          return {
            marker = "standard",
            added = true,
            name = actualName,
          }
        `;
      } else {
        code = `
          local just = require("cp.just")
          local axutils = require("cp.ui.axutils")
          local childrenWithRole = axutils.childrenWithRole
          local fcp = require("cp.apple.finalcutpro")

          local function focusedElement()
            return hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
          end

          local function focusedTextField()
            local focused = focusedElement()
            if focused and focused:attributeValue("AXRole") == "AXTextField" then
              return focused
            end
            return nil
          end

          local function ancestorWithRole(element, role)
            local current = element
            local depth = 0
            while current and depth < 12 do
              if current:attributeValue("AXRole") == role then
                return current
              end
              current = current:attributeValue("AXParent")
              depth = depth + 1
            end
            return nil
          end

          local function firstChildWithRole(element, role)
            local matches = childrenWithRole(element, role)
            return matches and matches[1] or nil
          end

          local function radioButtonsFor(popover)
            local group = firstChildWithRole(popover, "AXRadioGroup")
            return group and group:attributeValue("AXChildren") or {}
          end

          local function completedCheckboxFor(popover)
            for _, checkbox in ipairs(childrenWithRole(popover, "AXCheckBox") or {}) do
              if checkbox:attributeValue("AXTitle") == "Completed" then
                return checkbox
              end
            end
            return nil
          end

          local function doneButtonFor(popover)
            for _, button in ipairs(childrenWithRole(popover, "AXButton") or {}) do
              if button:attributeValue("AXTitle") == "Done" then
                return button
              end
            end
            return nil
          end

          fcp.timeline:show()
          if not just.doUntil(function() return fcp.timeline:isLoaded() end, 2) then
            return {marker = "${escapeLua(markerType)}", added = false, error = "No open timeline"}
          end

          if not fcp.timeline:isFocused() then
            pcall(function() fcp.timeline.contents:doFocus(true):Now() end)
            just.doUntil(function() return fcp.timeline:isFocused() end, 1)
          end

          local triggered = false
          pcall(function()
            triggered = fcp:doSelectMenu({"Mark", "Markers", "Add Marker and Modify"}):Now() == true
          end)
          if not triggered then
            fcp:doShortcut("AddAndEditMarker"):Now()
          end

          local nameField = nil
          if not just.doUntil(function()
            nameField = focusedTextField()
            return nameField ~= nil
          end, 2) then
            return {marker = "${escapeLua(markerType)}", added = false, error = "Marker editor did not appear"}
          end

          local popover = ancestorWithRole(nameField, "AXPopover")
          if not popover then
            return {marker = "${escapeLua(markerType)}", added = false, error = "Marker editor popover not found"}
          end

          local radioButtons = radioButtonsFor(popover)
          local markerIndex = 1
          if "${escapeLua(markerType)}" == "todo" then
            markerIndex = 2
          elseif "${escapeLua(markerType)}" == "chapter" then
            markerIndex = 3
          end

          local targetRadio = radioButtons[markerIndex]
          if not targetRadio then
            return {marker = "${escapeLua(markerType)}", added = false, error = "Marker type control not found"}
          end

          if targetRadio:attributeValue("AXValue") ~= 1 then
            targetRadio:performAction("AXPress")
            hs.timer.usleep(200000)
          end

          if "${escapeLua(markerName)}" ~= "" then
            nameField = firstChildWithRole(popover, "AXTextField") or focusedTextField()
            if not nameField then
              return {marker = "${escapeLua(markerType)}", added = false, error = "Marker name field did not appear"}
            end
            nameField:setAttributeValue("AXValue", "${escapeLua(markerName)}")
            hs.timer.usleep(100000)

            local appliedName = nameField:attributeValue("AXValue")
            if appliedName ~= "${escapeLua(markerName)}" then
              return {
                marker = "${escapeLua(markerType)}",
                added = false,
                error = "Unable to set marker name",
                requestedName = "${escapeLua(markerName)}",
                actualName = appliedName,
              }
            end
          end

          local completed = ${toLuaLiteral(completed)}
          if completed ~= nil and "${escapeLua(markerType)}" == "todo" then
            local completedCheckbox = completedCheckboxFor(popover)
            if not completedCheckbox then
              return {marker = "${escapeLua(markerType)}", added = false, error = "Completed checkbox did not appear"}
            end
            local currentValue = completedCheckbox:attributeValue("AXValue")
            local desiredValue = completed and 1 or 0
            if currentValue ~= desiredValue then
              completedCheckbox:performAction("AXPress")
              hs.timer.usleep(150000)
            end
          end

          local doneButton = doneButtonFor(popover)
          local pressed = doneButton and doneButton:performAction("AXPress") == true
          if not pressed then
            pcall(function() nameField:performAction("AXConfirm") end)
          end

          local closed = just.doUntil(function()
            local focused = focusedElement()
            return ancestorWithRole(focused, "AXPopover") == nil
          end, 2)
          if not closed then
            return {marker = "${escapeLua(markerType)}", added = false, error = "Marker editor did not close"}
          end

          return {
            marker = "${escapeLua(markerType)}",
            added = true,
            name = ${toLuaLiteral(hasMarkerName ? markerName : undefined)},
            completed = completed,
          }
        `;
      }
      const resp = await client.executeLua(code);
      return formatResult(extractResult(resp));
    }

    case "fcp_add_keyword": {
      const keyword = args.keyword as string;
      await activateFinalCutPro();
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")

        -- Ensure a clip is selected; auto-select at playhead if needed
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          local playheadClips = contents:playheadClipsUI(true) or {}
          if #playheadClips == 0 then
            return {keyword = "${escapeLua(keyword)}", added = false, error = "No clip selected and no clip under playhead."}
          end
          contents:selectClip(playheadClips[1])
          hs.timer.usleep(300000)
        end

        -- Use CommandPost's KeywordEditor API
        local keywordEditor = fcp.keywordEditor
        local wasShowing = keywordEditor:isShowing()
        if not wasShowing then
          keywordEditor:show()
          hs.timer.usleep(1000000)
        end

        if not keywordEditor:isShowing() then
          return {keyword = "${escapeLua(keyword)}", added = false, error = "Could not open Keyword Editor."}
        end

        local ok, err = pcall(function()
          keywordEditor.keywords:addKeyword("${escapeLua(keyword)}")
        end)

        -- Close the keyword editor if we opened it
        if not wasShowing then
          keywordEditor:hide()
          hs.timer.usleep(300000)
        end

        if not ok then
          return {keyword = "${escapeLua(keyword)}", added = false, error = "Failed to add keyword: " .. tostring(err)}
        end

        return {keyword = "${escapeLua(keyword)}", added = true}
      `, 30000);
      return formatResult(extractResult(resp));
    }

    case "fcp_list_markers": {
      const resp = await client.executeLua(safeLua(`
        local timeline = fcp.timeline
        if not timeline:isShowing() then
          return {error = "Timeline is not showing"}
        end

        -- Access the timeline contents to find marker elements
        local contents = timeline.contents
        local contentsUI = contents:UI()
        if not contentsUI then
          return {markers = {}, count = 0, note = "Could not access timeline contents"}
        end

        local markers = {}
        local children = contentsUI:attributeValue("AXChildren")
        if children then
          for _, child in ipairs(children) do
            local role = child:attributeValue("AXRole")
            local desc = child:attributeValue("AXDescription") or ""
            -- Markers typically appear as specific AX elements
            if role and (string.find(desc, "Marker") or string.find(desc, "marker") or role == "AXMarker") then
              local marker = {
                description = desc,
                position = child:attributeValue("AXPosition") or {},
                value = child:attributeValue("AXValue") or "",
              }
              table.insert(markers, marker)
            end
          end
        end

        -- Also try to get markers via FCPXML export if available
        -- For now, return what we can from the AX tree
        return {markers = markers, count = #markers}
      `), 60000);
      return formatResult(extractResult(resp));
    }

    // ── FCP Clip Operations ─────────────────────────────────────────
    case "fcp_rename_clip": {
      const newName = args.name as string;
      await activateFinalCutPro();
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local just = require("cp.just")

        -- Dismiss any blocking popovers first
        pcall(function()
          local sp = fcp.timeline.speedPopover
          if sp:isShowing() then
            sp:hide()
            just.doUntil(function() return not sp:isShowing() end, 2)
            hs.timer.usleep(200000)
          end
        end)

        -- Ensure FCP is frontmost (required for menu and text field interaction)
        fcp:launch()
        hs.timer.usleep(300000)

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          return {renamed = false, error = "No clip selected. Select a clip before renaming."}
        end

        -- FCP v12 moved "Rename Clip" from Modify to Clip menu; try both
        local result = fcp:selectMenu({"Clip", "Rename Clip"}, {plain = true})
        if not result then
          result = fcp:selectMenu({"Modify", "Rename Clip"}, {plain = true})
        end
        if not result then
          return {renamed = false, error = "Could not open Rename Clip dialog. The menu item may be disabled or no clip is selected in the browser/timeline."}
        end
        hs.timer.usleep(500000)

        -- Wait for the inline text field to become focused
        local textField = just.doUntil(function()
          local focused = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
          if focused then
            local role = focused:attributeValue("AXRole")
            if role == "AXTextField" or role == "AXTextArea" then
              return focused
            end
          end
          return false
        end, 3)
        if not textField then
          -- Try pressing Escape to dismiss any partial state
          hs.eventtap.keyStroke({}, "escape")
          return {renamed = false, error = "Rename text field did not appear. FCP may not be focused or the clip type does not support renaming."}
        end
        -- Set the value directly via accessibility instead of simulating keystrokes
        textField:setAttributeValue("AXValue", "${escapeLua(newName)}")
        hs.timer.usleep(100000)
        textField:performAction("AXConfirm")
        hs.timer.usleep(300000)

        -- Read back the clip name to verify
        local verifiedName
        pcall(function()
          local sel = fcp.timeline.contents:selectedClipsUI() or {}
          if #sel > 0 then
            verifiedName = sel[1]:attributeValue("AXDescription") or nil
          end
        end)

        local nameInDesc = verifiedName and string.find(verifiedName, "${escapeLua(newName)}", 1, true)
        return {
          renamed = true,
          name = "${escapeLua(newName)}",
          verifiedDescription = verifiedName,
          verified = nameInDesc ~= nil
        }
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_rate_clip": {
      const rating = args.rating as string;
      const ratingMap: Record<string, string> = {
        favorite: "Favorite",
        reject: "Reject",
        unrate: "Unfavorite",
      };
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          return {error = "No clip selected. Select a clip before rating."}
        end

        fcp:doShortcut("${ratingMap[rating]}"):Now()
        return {rating = "${rating}"}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      if (result?.error) {
        return formatResult({ ...result, rated: false, success: false });
      }
      return formatResult({
        ...result,
        rated: result?.undoChanged === true ? "${rating}" : false,
        ...(!result?.undoChanged ? {
          warning: "Rating shortcut executed but undo state did not change. The clip may already have this rating.",
        } : {}),
      });
    }

    // ── FCP Window Management ───────────────────────────────────────
    case "fcp_window_layout": {
      const action = args.action as string;
      const actionMap: Record<string, string> = {
        show_timeline: `require("cp.apple.finalcutpro").timeline:show()`,
        show_browser: `require("cp.apple.finalcutpro").browser:showOnPrimary()`,
        show_inspector: `require("cp.apple.finalcutpro").inspector:show()`,
        show_viewer: `require("cp.apple.finalcutpro").viewer:showOnPrimary()`,
        hide_browser: `require("cp.apple.finalcutpro").browser:hide()`,
        hide_inspector: `require("cp.apple.finalcutpro").inspector:hide()`,
        fullscreen_toggle: `require("cp.apple.finalcutpro").primaryWindow.isFullScreen:toggle()`,
      };
      const luaCode = actionMap[action];
      if (!luaCode) {
        return JSON.stringify({ error: `Unknown layout action: ${action}` });
      }
      const resp = await client.executeLua(
        `${luaCode} return {action = "${escapeLua(action)}"}`
      );
      return formatResult(extractResult(resp));
    }

    // ── FCP Undo/Redo ───────────────────────────────────────────────
    case "fcp_undo_redo": {
      const action = args.action as string;
      const count = (args.count as number) ?? 1;
      const menuPattern = action === "undo" ? "Undo" : "Redo";
      const titleKey = action === "undo" ? "undoTitle" : "redoTitle";
      const shortcutCommand = action === "undo" ? "UndoChanges" : "RedoChanges";
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")

        local function editMenuState()
          local state = {}
          local app = fcp:application()
          local menus = app and app:getMenuItems()
          if not menus then return state end

          for _, menu in ipairs(menus) do
            if menu.AXTitle == "Edit" then
              local group = menu.AXChildren and menu.AXChildren[1]
              if group then
                local undoItem = group[1]
                local redoItem = group[2]
                state.undoTitle = undoItem and undoItem.AXTitle or nil
                state.redoTitle = redoItem and redoItem.AXTitle or nil
              end
              break
            end
          end

          return state
        end

        local function startsWith(value, prefix)
          return type(value) == "string" and string.sub(value, 1, string.len(prefix)) == prefix
        end

        fcp:launch()
        hs.timer.usleep(300000)
        local app = fcp:application()
        if app then
          pcall(function() app:activate() end)
          hs.timer.usleep(150000)
        end

        local before = editMenuState()
        local initialTitle = before.${titleKey}
        if not startsWith(initialTitle, "${menuPattern}") then
          return {
            action = "${action}",
            countRequested = ${count},
            countApplied = 0,
            before = before,
            error = "No ${action} item is currently available in the Edit menu",
          }
        end

        local countApplied = 0
        for i = 1, ${count} do
          local state = editMenuState()
          local currentTitle = state.${titleKey}
          if not startsWith(currentTitle, "${menuPattern}") then
            break
          end

          local ok, result = pcall(function()
            fcp:doShortcut("${shortcutCommand}"):Now()
            return editMenuState()
          end)
          if not ok or type(result) ~= "table" then
            return {
              action = "${action}",
              countRequested = ${count},
              countApplied = countApplied,
              before = before,
              error = "Failed to invoke ${shortcutCommand}",
            }
          end

          countApplied = countApplied + 1
          hs.timer.usleep(300000)
        end

        local after = editMenuState()
        local changed = before.undoTitle ~= after.undoTitle or before.redoTitle ~= after.redoTitle

        if countApplied ~= ${count} then
          return {
            action = "${action}",
            countRequested = ${count},
            countApplied = countApplied,
            before = before,
            after = after,
            changed = changed,
            error = "Only applied " .. tostring(countApplied) .. " of " .. tostring(${count}) .. " requested ${action} operations",
          }
        end

        if not changed then
          return {
            action = "${action}",
            countRequested = ${count},
            countApplied = countApplied,
            before = before,
            after = after,
            changed = false,
            error = "${menuPattern} did not change the Edit menu state",
          }
        end

        return {
          action = "${action}",
          countRequested = ${count},
          countApplied = countApplied,
          before = before,
          after = after,
          changed = true,
        }
      `));
      return formatResult(extractResult(resp));
    }

    // ── FCP Speed/Retime ────────────────────────────────────────────
    case "fcp_retime": {
      const speed = args.speed as string;
      // Use plain text matching (no Lua patterns) to avoid issues with '%' in menu items
      const speedMenuMap: Record<string, string[]> = {
        slow_50: ["Modify", "Retime", "Slow", "50%"],
        slow_25: ["Modify", "Retime", "Slow", "25%"],
        slow_10: ["Modify", "Retime", "Slow", "10%"],
        fast_2x: ["Modify", "Retime", "Fast", "2x"],
        fast_4x: ["Modify", "Retime", "Fast", "4x"],
        fast_8x: ["Modify", "Retime", "Fast", "8x"],
        fast_20x: ["Modify", "Retime", "Fast", "20x"],
        normal: ["Modify", "Retime", "Normal (100%)"],
        reverse: ["Modify", "Retime", "Reverse Clip"],
        hold: ["Modify", "Retime", "Hold"],
      };
      const menuPath = speedMenuMap[speed];
      if (!menuPath) {
        return JSON.stringify({ error: `Unknown speed preset: ${speed}` });
      }
      const luaPath = menuPath.map((s) => `"${escapeLua(s)}"`).join(", ");
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check if a clip is selected
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          return {error = "No clip selected. Select a clip before changing speed.", speed = "${escapeLua(speed)}"}
        end

        local result = fcp:selectMenu({${luaPath}}, {plain = true})
        return {speed = "${escapeLua(speed)}", menuResult = result ~= nil}
      `));
      const result = extractResult(resp) as Record<string, unknown>;
      if (result?.error) {
        return formatResult({ ...result, success: false });
      }
      if (result?.undoChanged === false) {
        return formatResult({
          ...result,
          success: false,
          error: "Speed change did not take effect. The menu item may be disabled or unavailable for the selected clip.",
        });
      }
      return formatResult(result);
    }

    // ── FCP Captions ────────────────────────────────────────────────
    case "fcp_captions": {
      const action = args.action as string;
      let code: string;
      switch (action) {
        case "add":
          code = `
            local fcp = require("cp.apple.finalcutpro")
            fcp:selectMenu({"Edit", "Captions", "Add Caption"}, {plain = true})
            return {action = "add"}
          `;
          break;
        case "extract":
          code = `
            local fcp = require("cp.apple.finalcutpro")
            fcp:selectMenu({"Edit", "Captions", "Extract Captions"}, {plain = true})
            return {action = "extract"}
          `;
          break;
        case "import":
          code = `
            local fcp = require("cp.apple.finalcutpro")
            fcp:selectMenu({"File", "Import", "Captions..."}, {plain = true})
            return {action = "import"}
          `;
          break;
        default:
          return JSON.stringify({ error: `Unknown caption action: ${action}` });
      }
      const resp = await client.executeLua(code);
      return formatResult(extractResult(resp));
    }

    // ── FCP Multicam ────────────────────────────────────────────────
    case "fcp_multicam_switch_angle": {
      const angle = args.angle as number;
      const switchType = (args.type as string) || "both";
      if (angle < 1 || angle > 16) {
        return JSON.stringify({ error: `Angle must be between 1 and 16: ${angle}` });
      }
      let modeShortcut: string;
      if (switchType === "video") {
        modeShortcut = "MultiAngleEditStyleVideo";
      } else if (switchType === "audio") {
        modeShortcut = "MultiAngleEditStyleAudio";
      } else {
        modeShortcut = "MultiAngleEditStyleAudioVideo";
      }
      const angleShortcut = `CutSwitchAngle${String(angle).padStart(2, "0")}`;
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp:doShortcut("${modeShortcut}"):Now()
        fcp:doShortcut("${angleShortcut}"):Now()
        return {angle = ${angle}, type = "${switchType}"}
      `);
      return formatResult(extractResult(resp));
    }

    // ── FCP Pasteboard ──────────────────────────────────────────────
    case "fcp_pasteboard": {
      const action = args.action as string;
      const slot = typeof args.slot === "number" ? args.slot : undefined;
      const slotLiteral = slot !== undefined ? `"${slot}"` : "nil";
      if (action === "copy") {
        const resp = await client.executeLua(safeLua(`
          local slot = ${slotLiteral}
          if slot then
            local pasteboardManager = require("cp.plugins")("finalcutpro.pasteboard.manager")
            if not pasteboardManager then
              return {action = "copied", buffered = false, slot = tonumber(slot), error = "Pasteboard manager not available"}
            end
            local ok, err = pcall(function()
              pasteboardManager.doSaveToBuffer(slot):Now()
            end)
            if not ok then
              return {action = "copied", buffered = false, slot = tonumber(slot), error = tostring(err)}
            end
            return {action = "copied", buffered = true, slot = tonumber(slot)}
          end

          fcp:doShortcut("Copy"):Now()
          return {action = "copied", buffered = false}
        `));
        return formatResult(extractResult(resp));
      } else if (action === "paste") {
        const resp = await client.executeLua(safeLua(`
          local slot = ${slotLiteral}
          if slot then
            local pasteboardManager = require("cp.plugins")("finalcutpro.pasteboard.manager")
            if not pasteboardManager then
              return {action = "pasted", buffered = false, slot = tonumber(slot), error = "Pasteboard manager not available"}
            end
            local ok, err = pcall(function()
              pasteboardManager.doRestoreFromBuffer(slot):Now()
            end)
            if not ok then
              return {action = "pasted", buffered = false, slot = tonumber(slot), error = tostring(err)}
            end
            return {action = "pasted", buffered = true, slot = tonumber(slot)}
          end

          fcp:doShortcut("Paste"):Now()
          return {action = "pasted", buffered = false}
        `));
        return formatResult(extractResult(resp));
      } else {
        const resp = await client.executeLua(safeLua(`
          local base64 = require("hs.base64")
          local pasteboardManager = require("cp.plugins")("finalcutpro.pasteboard.manager")
          if not pasteboardManager or not pasteboardManager.buffer then
            return {action = "history", items = {}, count = 0, error = "Pasteboard manager not available"}
          end

          local buffer = pasteboardManager.buffer() or {}
          local items = {}
          for key, encodedData in pairs(buffer) do
            if encodedData and encodedData ~= "" then
              local decoded = base64.decode(encodedData)
              local label = nil
              local clipCount = 0
              if decoded then
                local ok, foundLabel, foundCount = pcall(function()
                  return pasteboardManager.findClipName(decoded, "Unknown")
                end)
                if ok then
                  label = foundLabel
                  clipCount = foundCount or 0
                end
              end

              table.insert(items, {
                slot = tonumber(key) or key,
                label = label,
                clipCount = clipCount,
                populated = decoded ~= nil,
              })
            end
          end

          table.sort(items, function(a, b)
            return (tonumber(a.slot) or 999999) < (tonumber(b.slot) or 999999)
          end)

          return {action = "history", items = items, count = #items}
        `));
        return formatResult(extractResult(resp));
      }
    }

    // ── Notifications/Alerts ────────────────────────────────────────
    case "commandpost_alert": {
      const message = args.message as string;
      const duration = (args.duration as number) || 2;
      const resp = await client.executeLua(
        `hs.alert.show("${escapeLua(message)}", ${duration}) return {alerted = true}`
      );
      return formatResult(extractResult(resp));
    }

    // ── Discovery / Introspection ──────────────────────────────────
    case "fcp_list_effects":
    case "fcp_list_audio_effects":
    case "fcp_list_transitions":
    case "fcp_list_generators":
    case "fcp_list_titles": {
      const handlerMap: Record<string, string> = {
        fcp_list_effects: "fcpx_videoEffect",
        fcp_list_audio_effects: "fcpx_audioEffect",
        fcp_list_transitions: "fcpx_transition",
        fcp_list_generators: "fcpx_generator",
        fcp_list_titles: "fcpx_title",
      };
      const labelMap: Record<string, string> = {
        fcp_list_effects: "video effects",
        fcp_list_audio_effects: "audio effects",
        fcp_list_transitions: "transitions",
        fcp_list_generators: "generators",
        fcp_list_titles: "titles",
      };
      const handlerId = handlerMap[name];
      const label = labelMap[name];
      const category = args.category as string | undefined;
      const filterCode = category
        ? `
        local filtered = {}
        for _, item in ipairs(items) do
          if item.category and string.find(string.lower(item.category), string.lower("${escapeLua(category)}")) then
            table.insert(filtered, item)
          end
        end
        return filtered`
        : "return items";
      const resp = await client.executeLua(`
        local actionManager = require("cp.plugins")("core.action.manager")
        if not actionManager then
          return {error = "Action manager not available"}
        end
        local handler = actionManager.getHandler("${handlerId}")
        if not handler then
          return {error = "${label} handler not available"}
        end
        local choices = handler:choices()
        if not choices then
          return {error = "Could not retrieve ${label} choices"}
        end
        local items = {}
        for _, choice in ipairs(choices:getChoices()) do
          table.insert(items, {
            name = choice.text or "",
            category = choice.subText or "",
          })
        end
        ${filterCode}
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_get_selected_clips": {
      const resp = await client.executeLua(safeLua(`
        local timeline = fcp.timeline
        local contents = timeline.contents

        if not timeline:isShowing() then
          return {error = "Timeline is not showing"}
        end

        local clips = contents:selectedClipsUI()
        if not clips or #clips == 0 then
          return {clips = {}, count = 0, note = "No clips selected"}
        end

        local result = {}
        for i, clip in ipairs(clips) do
          local info = {
            index = i,
            role = safeGet(function() return clip:attributeValue("AXRole") end) or "unknown",
            description = safeGet(function() return clip:attributeValue("AXDescription") end) or "",
            position = safeGet(function() return clip:attributeValue("AXPosition") end) or {},
            size = safeGet(function() return clip:attributeValue("AXSize") end) or {},
            value = safeGet(function() return clip:attributeValue("AXValue") end),
          }
          table.insert(result, info)
        end
        return {clips = result, count = #result}
      `));
      return formatResult(extractResult(resp));
    }

    case "fcp_get_playhead_position": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local viewer = fcp.viewer
        local tc = viewer:timecode()
        return {
          timecode = tc or "unknown",
          playing = viewer:isPlaying(),
        }
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_set_playhead_position": {
      const timecode = args.timecode as string;
      const validErr = validateStringInput(timecode, "timecode");
      if (validErr) return JSON.stringify({ error: validErr });
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")

        -- Read before timecode
        local beforeTC
        pcall(function() beforeTC = tostring(fcp.viewer:timecode()) end)

        -- Set playhead
        fcp.viewer:timecode("${escapeLua(timecode)}")
        hs.timer.usleep(200000)

        -- Read back actual timecode to verify
        local afterTC
        pcall(function() afterTC = tostring(fcp.viewer:timecode()) end)

        local moved = beforeTC ~= afterTC
        return {
          navigated = moved,
          timecode = afterTC or "${escapeLua(timecode)}",
          requestedTimecode = "${escapeLua(timecode)}",
          previousTimecode = beforeTC,
          error = not moved and "Playhead did not move. The timecode may be out of range or the timeline may not be focused." or nil
        }
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_get_project_settings": {
      const resp = await client.executeLua(safeLua(`
        local result = {
          running = fcp:isRunning(),
          version = safeGet(function() return fcp:version() and tostring(fcp:version()) end),
        }

        result.currentTimecode = safeGet(function() return fcp.viewer:timecode() end)
        result.playing = safeGet(function() return fcp.viewer:isPlaying() end)

        local timeline = fcp.timeline
        result.timelineShowing = safeGet(function() return timeline:isShowing() end)
        result.timelineFocused = safeGet(function() return timeline:isFocused() end)

        result.project = safeGet(function()
          local proj = fcp.timeline:contents()
          return {
            description = proj and tostring(proj) or "unavailable",
          }
        end)

        result.activeLibraries = safeGet(function() return fcp:activeLibraryNames() end)

        return result
      `));
      return formatResult(extractResult(resp));
    }

    // ── Clip Properties ──────────────────────────────────────────────
    case "fcp_get_clip_properties": {
      const resp = await client.executeLua(safeLua(`
        local inspector = fcp.inspector
        inspector:show()

        local videoInspector = inspector.video
        if not videoInspector then
          return {error = "Video inspector not available"}
        end
        videoInspector:show()

        local result = {
          available = safeGet(function() return videoInspector:isShowing() end),
        }

        -- Transform properties (graceful degradation per field)
        result.transform = {
          position = safeGet(function()
            local t = videoInspector:transform()
            return t and t:position() or nil
          end),
          rotation = safeGet(function()
            local t = videoInspector:transform()
            return t and t:rotation() or nil
          end),
          scale = safeGet(function()
            local t = videoInspector:transform()
            return t and t:scaleAll() or nil
          end),
          anchor = safeGet(function()
            local t = videoInspector:transform()
            return t and t:anchor() or nil
          end),
        }

        -- Compositing properties
        result.compositing = {
          opacity = safeGet(function()
            local c = videoInspector:compositing()
            return c and c:opacity() or nil
          end),
          blendMode = safeGet(function()
            local c = videoInspector:compositing()
            return c and c:blendMode() or nil
          end),
        }

        -- Crop properties
        result.crop = safeGet(function()
          local crop = videoInspector:crop()
          if not crop then return nil end
          return {
            type = crop:type() or nil,
          }
        end)

        return result
      `), 60000);
      return formatResult(extractResult(resp));
    }

    case "fcp_set_clip_properties": {
      const posX = args.positionX as number | undefined;
      const posY = args.positionY as number | undefined;
      const scaleAll = args.scaleAll as number | undefined;
      const rotation = args.rotation as number | undefined;
      const opacity = args.opacity as number | undefined;

      if (opacity !== undefined) {
        const rangeErr = validateRange(opacity, 0, 100, "opacity");
        if (rangeErr) return JSON.stringify({ error: rangeErr });
      }

      const setStatements: string[] = [];
      if (posX !== undefined || posY !== undefined) {
        setStatements.push(`
          local pos = transform:position()
          ${posX !== undefined ? `if pos then pos:x(${posX}) end` : ""}
          ${posY !== undefined ? `if pos then pos:y(${posY}) end` : ""}
        `);
      }
      if (scaleAll !== undefined) {
        setStatements.push(`transform:scaleAll(${scaleAll})`);
      }
      if (rotation !== undefined) {
        setStatements.push(`transform:rotation(${rotation})`);
      }
      if (opacity !== undefined) {
        setStatements.push(`
          local compositing = videoInspector:compositing()
          if compositing then compositing:opacity(${opacity}) end
        `);
      }

      if (setStatements.length === 0) {
        return JSON.stringify({
          error:
            "No properties specified. Provide at least one of: positionX, positionY, scaleAll, rotation, opacity",
        });
      }

      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local inspector = fcp.inspector
        inspector:show()
        local videoInspector = inspector.video
        if not videoInspector then
          return {error = "Video inspector not available"}
        end
        videoInspector:show()
        local transform = videoInspector:transform()
        if not transform then
          return {error = "Transform controls not available — is a clip selected?"}
        end
        ${setStatements.join("\n")}
        return {
          set = true,
          positionX = ${posX !== undefined ? posX : "nil"},
          positionY = ${posY !== undefined ? posY : "nil"},
          scaleAll = ${scaleAll !== undefined ? scaleAll : "nil"},
          rotation = ${rotation !== undefined ? rotation : "nil"},
          opacity = ${opacity !== undefined ? opacity : "nil"},
        }
      `);
      return formatResult(extractResult(resp));
    }

    // ── Additional Clip Operations ───────────────────────────────────
    case "fcp_duplicate_clip": {
      const resp = await client.executeLua(withVerification(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          return {error = "No clip selected. Select a clip before duplicating."}
        end

        fcp:doShortcut("Copy"):Now()
        hs.timer.usleep(100000)
        fcp:doShortcut("PasteAsConnected"):Now()
        return {action = "duplicate"}
      `));
      const raw = unwrapNestedResult(resp) as Record<string, unknown> | null;
      const result = raw ?? {};
      if (result?.error && !result?.verified) {
        return formatResult({ ...result, duplicated: false, success: false });
      }
      // Check verification at multiple possible nesting levels
      const verified = (result?.verified ?? (result as Record<string, unknown>)?.after) as Record<string, unknown> | undefined;
      const clipDelta = Number(verified?.clipDelta ?? 0);
      const undoText = String(verified?.undoText ?? (result?.after as Record<string, unknown>)?.undoText ?? "");
      const afterClipCount = Number((result?.after as Record<string, unknown>)?.clipCount ?? 0);
      const beforeClipCount = Number((result?.before as Record<string, unknown>)?.clipCount ?? 0);
      const duplicated = clipDelta > 0 || undoText.includes("Paste") || (afterClipCount > beforeClipCount);
      return formatResult({
        ...result,
        duplicated,
        ...(!duplicated ? { error: "Duplicate may not have succeeded. No new clip detected in timeline." } : {}),
      });
    }

    case "fcp_enable_disable_clip": {
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          return {error = "No clip selected. Select a clip before toggling enabled state."}
        end

        fcp:selectMenu({"Clip", "Enable"}, {plain = true})
        return {action = "toggle_enable"}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      if (result?.error) {
        return formatResult({ ...result, toggled: false, success: false });
      }
      return formatResult({
        ...result,
        toggled: result?.undoChanged === true,
        ...(!result?.undoChanged ? { error: "Enable/disable toggle did not take effect." } : {}),
      });
    }

    case "fcp_split_at_timecode": {
      const timecode = args.timecode as string;
      const validErr = validateStringInput(timecode, "timecode");
      if (validErr) return JSON.stringify({ error: validErr });
      const resp = await client.executeLua(withVerification(`
        local fcp = require("cp.apple.finalcutpro")
        fcp.viewer:timecode("${escapeLua(timecode)}")
        hs.timer.usleep(200000)
        fcp:doShortcut("BladeAtPlayhead"):Now()
        return {action = "split", timecode = "${escapeLua(timecode)}"}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      const clipDelta = Number((result?.verified as Record<string, unknown>)?.clipDelta ?? 0);
      if (clipDelta <= 0) {
        return formatResult({
          ...result,
          split: false,
          error: "Blade did not split the clip. There may be no clip at the specified timecode, or the timeline was not focused.",
        });
      }
      return formatResult({ ...result, split: true });
    }

    case "fcp_speed_custom": {
      const percentage = args.percentage as number;
      const rangeErr = validateRange(percentage, 1, 10000, "percentage");
      if (rangeErr) return JSON.stringify({ error: rangeErr });
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local just = require("cp.just")
        local speedPopover = fcp.timeline.speedPopover

        -- Open the speed popover using the native CommandPost API
        speedPopover:doShow():Now()
        if not just.doUntil(function() return speedPopover:isShowing() end, 3) then
          return {error = "Speed popover did not appear"}
        end

        -- Ensure "Rate" mode is selected (not Duration)
        if not speedPopover.byRate:checked() then
          speedPopover.byRate:doPress():Now()
          just.doUntil(function() return speedPopover.byRate:checked() end, 1)
        end

        -- Set the rate value via the TextField API instead of eventtap keystrokes
        local rateField = speedPopover.rate
        if rateField then
          rateField:value("${percentage}")
          -- Confirm with AXConfirm on the text field
          local rateUI = rateField:UI()
          if rateUI then
            rateUI:performAction("AXConfirm")
          end
        else
          -- Close the popover before returning error
          speedPopover:hide()
          return {error = "Rate field not available in speed popover"}
        end

        -- Dismiss the speed popover so it doesn't block subsequent operations
        hs.timer.usleep(200000)
        speedPopover:hide()
        just.doUntil(function() return not speedPopover:isShowing() end, 2)

        return {speed = ${percentage}, note = "Custom speed set via SpeedPopover API"}
      `);
      return formatResult(extractResult(resp));
    }

    // ── Range Selection / Work Area ──────────────────────────────────
    case "fcp_set_range": {
      const rangeStart = args.start as string;
      const rangeEnd = args.end as string;
      const startErr = validateStringInput(rangeStart, "start");
      if (startErr) return JSON.stringify({ error: startErr });
      const endErr = validateStringInput(rangeEnd, "end");
      if (endErr) return JSON.stringify({ error: endErr });
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        fcp.viewer:timecode("${escapeLua(rangeStart)}")
        hs.timer.usleep(200000)
        fcp:doShortcut("SetSelectionStart"):Now()
        hs.timer.usleep(100000)
        fcp.viewer:timecode("${escapeLua(rangeEnd)}")
        hs.timer.usleep(200000)
        fcp:doShortcut("SetSelectionEnd"):Now()
        return {rangeSet = true, start = "${escapeLua(rangeStart)}", ["end"] = "${escapeLua(rangeEnd)}"}
      `);
      return formatResult(extractResult(resp));
    }

    case "fcp_clear_range": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        -- Use the native timeline contents API instead of selectMenu
        fcp.timeline.contents:selectNone()
        return {rangeCleared = true}
      `);
      return formatResult(extractResult(resp));
    }

    // ── Compound Clips & Auditions ───────────────────────────────────
    case "fcp_create_compound_clip": {
      const compName = args.name as string | undefined;
      const nameCode = compName
        ? `
        -- Wait for the compound clip name dialog to appear and find the text field
        local just = require("cp.just")
        local nameField = just.doUntil(function()
          local focused = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
          if focused and focused:attributeValue("AXRole") == "AXTextField" then
            return focused
          end
          return false
        end, 3)
        if nameField then
          -- Set value directly via accessibility instead of simulating keystrokes
          nameField:setAttributeValue("AXValue", "${escapeLua(compName)}")
          nameField:performAction("AXConfirm")
        else
          return {created = false, error = "Compound clip name dialog did not appear"}
        end`
        : "";
      const resp = await client.executeLua(withVerification(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          return {created = false, error = "No clips selected. Select one or more clips before creating a compound clip."}
        end

        fcp:selectMenu({"File", "New", "Compound Clip..."}, {plain = true})
        ${nameCode}
        return {action = "create_compound"${compName ? `, name = "${escapeLua(compName)}"` : ""}}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      if (result?.error) {
        return formatResult({ ...result, created: false, success: false });
      }
      const undoText = String((result?.verified as Record<string, unknown>)?.undoText ?? "");
      const created = undoText.toLowerCase().includes("compound");
      return formatResult({
        ...result,
        created,
        ...(!created ? { warning: "Compound clip creation could not be verified via undo state." } : {}),
      });
    }

    case "fcp_break_apart_compound": {
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          return {error = "No clip selected. Select a compound clip before breaking apart."}
        end

        fcp:selectMenu({"Clip", "Break Apart Clip Items"}, {plain = true})
        return {action = "break_apart"}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      if (result?.error) {
        return formatResult({ ...result, brokenApart: false, success: false });
      }
      return formatResult({
        ...result,
        brokenApart: result?.undoChanged === true,
        ...(!result?.undoChanged ? {
          error: "Break apart did not take effect. The selected clip may not be a compound clip.",
        } : {}),
      });
    }

    case "fcp_create_audition": {
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected < 2 then
          return {error = "Select at least 2 clips to create an audition."}
        end

        fcp:selectMenu({"Clip", "Audition", "Create Audition"}, {plain = true})
        return {action = "create_audition"}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      if (result?.error) {
        return formatResult({ ...result, created: false, success: false });
      }
      return formatResult({
        ...result,
        created: result?.undoChanged === true,
        ...(!result?.undoChanged ? {
          error: "Audition creation did not take effect. Ensure multiple clips are selected.",
        } : {}),
      });
    }

    // ── Roles ────────────────────────────────────────────────────────
    case "fcp_assign_role": {
      const role = args.role as string;
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")

        -- Check selection first
        local contents = fcp.timeline.contents
        local selected = contents and contents:selectedClipsUI() or {}
        if #selected == 0 then
          return {error = "No clip selected. Select a clip before assigning a role."}
        end

        local result = fcp:selectMenu({"Modify", "Assign Roles", "${escapeLua(role)}"}, {plain = true})
        return {role = "${escapeLua(role)}", menuResult = result ~= nil}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      if (result?.error) {
        return formatResult({ ...result, assigned: false, success: false });
      }
      return formatResult({
        ...result,
        assigned: result?.undoChanged === true || result?.menuResult === true,
        ...(!result?.menuResult ? {
          error: `Role "${role}" could not be assigned. The menu item may not exist or be disabled.`,
        } : {}),
      });
    }

    // ── Stabilization ────────────────────────────────────────────────
    case "fcp_stabilization": {
      const stabEnabled = (args.enabled as boolean) !== false;
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local inspector = fcp.inspector
        inspector:show()
        local videoInspector = inspector.video
        if not videoInspector then
          return {error = "Video inspector not available"}
        end
        videoInspector:show()
        local ok, err = pcall(function()
          local stabilization = videoInspector:stabilization()
          if stabilization then
            stabilization:enabled(${stabEnabled})
          end
        end)
        if not ok then
          return {error = "Could not access stabilization controls: " .. tostring(err)}
        end
        return {stabilization = ${stabEnabled}}
      `);
      return formatResult(extractResult(resp));
    }

    // ── Proxy Management ─────────────────────────────────────────────
    case "fcp_proxy_toggle": {
      const resp = await client.executeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local Viewer = require("cp.apple.finalcutpro.viewer.Viewer")
        local viewer = fcp.viewer
        local wasUsingProxies = viewer:usingProxies()
        if wasUsingProxies then
          -- Switch back to original quality
          viewer:playbackMode(Viewer.PLAYBACK_MODE.ORIGINAL_BETTER_PERFORMANCE)
        else
          -- Switch to proxy preferred
          viewer:playbackMode(Viewer.PLAYBACK_MODE.PROXY_PREFERRED)
        end
        return {
          toggled = true,
          wasUsingProxies = wasUsingProxies,
          nowUsingProxies = not wasUsingProxies,
        }
      `);
      return formatResult(extractResult(resp));
    }

    // ── Batch Operations ─────────────────────────────────────────────
    case "fcp_batch_apply_transition": {
      const resp = await client.executeLua(withVerification(`
        local fcp = require("cp.apple.finalcutpro")
        -- Use native timeline contents API to select all clips
        local contents = fcp.timeline.contents
        local clips = contents:clipsUI(true)
        if not clips or #clips < 2 then
          return {error = "Need at least 2 clips in the timeline to apply transitions between them."}
        end
        contents:selectClips(clips)
        hs.timer.usleep(200000)
        fcp:doShortcut("AddTransition"):Now()
        return {action = "batch_transition", clipCount = #clips}
      `));
      const result = (extractResult(resp) ?? {}) as Record<string, unknown>;
      if (result?.error) {
        return formatResult({ ...result, applied: false, success: false });
      }
      const clipDelta = Number((result?.verified as Record<string, unknown>)?.clipDelta ?? 0);
      const undoText = String((result?.verified as Record<string, unknown>)?.undoText ?? "");
      const applied = clipDelta > 0 || undoText.toLowerCase().includes("transition");
      return formatResult({
        ...result,
        applied,
        transition: "default",
        ...(!applied ? {
          error: "Batch transition application could not be verified. No timeline changes detected.",
        } : {}),
      });
    }

    // ── Composite Workflow: Assemble Rough Cut ────────────────────────
    case "fcp_assemble_rough_cut": {
      const projectName = args.projectName as string | undefined;
      const clipPlan = args.clipPlan as Array<{
        mediaPath: string;
      }>;

      const clipStatements = clipPlan
        .map((clip, i) => {
          const lines: string[] = [];
          lines.push(`  -- Clip ${i + 1}`);
          lines.push(
            `  local imported${i}, msg${i} = mediaImport:importPath("${escapeLua(clip.mediaPath)}")`
          );
          lines.push(
            `  table.insert(results, {index=${i + 1}, path="${escapeLua(clip.mediaPath)}", imported=imported${i}~=false, error=imported${i} and nil or msg${i}})`
          );
          lines.push(`  if imported${i} then importedCount = importedCount + 1 end`);
          lines.push("  hs.timer.usleep(500000)");
          return lines.join("\n");
        })
        .join("\n");

      const resp = await client.executeLua(
        safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local mediaImport = fcp.mediaImport
        if not fcp:isRunning() then
          return {error = "Final Cut Pro is not running"}
        end
        local openedProject = nil
        ${
          projectName
            ? `
        local projectOpened = fcp.timeline:doOpenProject("${escapeLua(projectName)}"):Now()
        if not projectOpened then
          return {error = "Unable to open project: ${escapeLua(projectName)}"}
        end
        openedProject = "${escapeLua(projectName)}"
        hs.timer.usleep(500000)
        `
            : ""
        }
        local results = {}
        local importedCount = 0
${clipStatements}
        return {
          assembled = false,
          prepared = true,
          clipCount = ${clipPlan.length},
          importedCount = importedCount,
          clips = results,
          projectName = openedProject,
          note = "Imported media for rough-cut preparation. Timeline assembly, trimming, effects, and transitions must be performed separately.",
        }
      `),
        120000
      );
      return formatResult(extractResult(resp));
    }

    // ── Color Wheels ──────────────────────────────────────────────
    case "fcp_color_wheels": {
      const control = args.control as string;
      const value = args.value as number | undefined;
      const reset = args.reset as boolean | undefined;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        local inspector = fcp.inspector
        inspector:show()
        local colorInspector = inspector.color
        if not colorInspector then return {error = "Color inspector not available"} end
        colorInspector:show()
        local wheels = colorInspector:colorWheels()
        if not wheels then return {error = "Color Wheels not available — make sure a clip is selected and the color inspector is open"} end
        wheels:show()
        hs.timer.usleep(300000)
        local control = "${escapeLua(control)}"
        local prop = wheels[control]
        if not prop then return {error = "Unknown color wheel control: " .. control} end
        ${reset ? `
        if type(prop.doReset) == "function" then prop:doReset():Now()
        else return {error = "Reset not supported for " .. control} end
        return {reset = true, control = control}
        ` : value !== undefined ? `
        prop(${value})
        return {control = control, value = ${value}, set = true}
        ` : `
        local val = prop()
        return {control = control, value = val}
        `}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Video Inspector ───────────────────────────────────────────
    case "fcp_video_inspector": {
      const viAction = args.action as string;
      const section = args.section as string;
      const property = args.property as string | undefined;
      const viValue = args.value;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        local inspector = fcp.inspector
        inspector:show()
        local video = inspector.video
        if not video then return {error = "Video inspector not available"} end
        video:show()
        hs.timer.usleep(300000)
        local section = video:${escapeLua(section)}()
        if not section then return {error = "Section '${escapeLua(section)}' not available"} end
        ${viAction === "get" ? `
        -- Read all properties from this section
        local result = {section = "${escapeLua(section)}"}
        local ok, val = pcall(function()
          local ui = section:UI()
          if ui then
            local children = ui:attributeValue("AXChildren") or {}
            result.propertyCount = #children
          end
        end)
        ${property ? `
        local prop = section["${escapeLua(property)}"]
        if prop then
          local pok, pval = pcall(function() return prop() end)
          if pok then result["${escapeLua(property)}"] = pval end
        end
        ` : ""}
        return result
        ` : `
        ${property && viValue !== undefined ? `
        local prop = section["${escapeLua(property)}"]
        if not prop then return {error = "Property '${escapeLua(property ?? "")}' not found in section '${escapeLua(section)}'"} end
        prop(${toLuaLiteral(viValue)})
        return {section = "${escapeLua(section)}", property = "${escapeLua(property ?? "")}", value = ${toLuaLiteral(viValue)}, set = true}
        ` : `return {error = "property and value are required for action=set"}`}
        `}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Audio Inspector ───────────────────────────────────────────
    case "fcp_audio_inspector": {
      const aiAction = args.action as string;
      const aiProp = args.property as string | undefined;
      const aiValue = args.value as number | undefined;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        local inspector = fcp.inspector
        inspector:show()
        local audio = inspector.audio
        if not audio then return {error = "Audio inspector not available"} end
        audio:show()
        hs.timer.usleep(300000)
        ${aiAction === "get" ? `
        local result = {}
        ${aiProp ? `
        local prop = audio["${escapeLua(aiProp)}"]
        if prop then
          local ok, val = pcall(function() return prop() end)
          if ok then result["${escapeLua(aiProp)}"] = val end
        end
        ` : `result.showing = audio:isShowing()`}
        return result
        ` : `
        ${aiProp && aiValue !== undefined ? `
        local prop = audio["${escapeLua(aiProp)}"]
        if not prop then return {error = "Property '${escapeLua(aiProp ?? "")}' not found"} end
        prop(${aiValue})
        return {property = "${escapeLua(aiProp ?? "")}", value = ${aiValue}, set = true}
        ` : `return {error = "property and value are required for action=set"}`}
        `}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Toolbar State ─────────────────────────────────────────────
    case "fcp_toolbar_state": {
      const tbAction = args.action as string;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        local toolbar = fcp.timeline.toolbar
        if not toolbar then return {error = "Timeline toolbar not available"} end
        ${tbAction === "get" ? `
        return {
          snapping = safeGet(function() return toolbar:snapping() end),
          skimming = safeGet(function() return toolbar:skimming() end),
          audioSkimming = safeGet(function() return toolbar:audioSkimming() end),
          solo = safeGet(function() return toolbar:solo() end),
        }
        ` : `
        ${args.toggle ? `
        local toggle = toolbar["${escapeLua(args.toggle as string)}"]
        if toggle then
          toggle(${args.enabled === true})
          return {toggle = "${escapeLua(args.toggle as string)}", enabled = ${args.enabled === true}, set = true}
        else
          return {error = "Unknown toggle: ${escapeLua(args.toggle as string)}"}
        end
        ` : ""}
        ${args.tool ? `
        local toolMap = {
          select = "SelectTool", trim = "TrimTool", position = "PositionTool",
          range = "RangeSelectionTool", blade = "BladeTool", zoom = "ZoomTool", hand = "HandTool",
        }
        local shortcutName = toolMap["${escapeLua(args.tool as string)}"]
        if shortcutName then
          fcp:doShortcut(shortcutName):Now()
          return {tool = "${escapeLua(args.tool as string)}", set = true}
        else
          return {error = "Unknown tool: ${escapeLua(args.tool as string)}"}
        end
        ` : ""}
        ${!args.toggle && !args.tool ? `return {error = "Specify toggle and/or tool for set action"}` : ""}
        `}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Timeline Appearance ───────────────────────────────────────
    case "fcp_timeline_appearance": {
      const taAction = args.action as string;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        local appearance = fcp.timeline.toolbar:appearance()
        if not appearance then return {error = "Timeline appearance popover not available"} end
        ${taAction === "get" ? `
        appearance:show()
        hs.timer.usleep(300000)
        local result = {
          clipHeight = safeGet(function() return appearance:clipHeight() end),
          clipNames = safeGet(function() return appearance:clipNames() end),
          clipRoles = safeGet(function() return appearance:clipRoles() end),
          laneHeaders = safeGet(function() return appearance:laneHeaders() end),
        }
        appearance:hide()
        return result
        ` : `
        appearance:show()
        hs.timer.usleep(300000)
        local changed = {}
        ${args.clipHeight !== undefined ? `appearance:clipHeight(${Number(args.clipHeight)}); changed.clipHeight = ${Number(args.clipHeight)}` : ""}
        ${args.clipNames !== undefined ? `appearance:clipNames(${args.clipNames === true}); changed.clipNames = ${args.clipNames === true}` : ""}
        ${args.clipRoles !== undefined ? `appearance:clipRoles(${args.clipRoles === true}); changed.clipRoles = ${args.clipRoles === true}` : ""}
        ${args.laneHeaders !== undefined ? `appearance:laneHeaders(${args.laneHeaders === true}); changed.laneHeaders = ${args.laneHeaders === true}` : ""}
        appearance:hide()
        return {set = true, changed = changed}
        `}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Viewer Config ─────────────────────────────────────────────
    case "fcp_viewer_config": {
      const vcAction = args.action as string;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        local Viewer = require("cp.apple.finalcutpro.viewer.Viewer")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        local viewer = fcp.viewer
        ${vcAction === "get" ? `
        return {
          usingProxies = safeGet(function() return viewer:usingProxies() end),
          betterQuality = safeGet(function() return viewer:betterQuality() end),
          isPlaying = safeGet(function() return viewer:isPlaying() end),
          timecode = safeGet(function() return viewer:timecode() end),
        }
        ` : `
        local changed = {}
        ${args.quality ? `
        local modeMap = {
          better_quality = Viewer.PLAYBACK_MODE.ORIGINAL_BETTER_QUALITY,
          better_performance = Viewer.PLAYBACK_MODE.ORIGINAL_BETTER_PERFORMANCE,
          proxy_preferred = Viewer.PLAYBACK_MODE.PROXY_PREFERRED,
          proxy_only = Viewer.PLAYBACK_MODE.PROXY_ONLY,
          original_better_quality = Viewer.PLAYBACK_MODE.ORIGINAL_BETTER_QUALITY,
          original_better_performance = Viewer.PLAYBACK_MODE.ORIGINAL_BETTER_PERFORMANCE,
        }
        local mode = modeMap["${escapeLua(args.quality as string)}"]
        if mode then
          viewer:playbackMode(mode)
          changed.quality = "${escapeLua(args.quality as string)}"
        end
        ` : ""}
        return {set = true, changed = changed}
        `}
      `));
      return formatResult(extractResult(resp));
    }

    // ── CSV Export ─────────────────────────────────────────────────
    case "fcp_export_csv": {
      const csvSource = args.source as string;
      const csvPath = args.path as string | undefined;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        ${csvSource === "browser" ? `
        fcp:selectMenu({"File", "Export", "Browser Contents as CSV..."})
        ` : `
        fcp:selectMenu({"File", "Export", "Timeline Index as CSV..."})
        `}
        return {exported = true, source = "${escapeLua(csvSource)}"}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Match Frame ───────────────────────────────────────────────
    case "fcp_match_frame": {
      const multicam = args.multicam as boolean | undefined;
      const resp = await client.executeLua(withUndoCheck(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        ${multicam ? `
        fcp:selectMenu({"File", "Reveal in Browser", "Multicam Match Frame"})
        return {action = "multicam_match_frame"}
        ` : `
        fcp:doShortcut("RevealInBrowserMatchFrame"):Now()
        return {action = "match_frame"}
        `}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Transcode ─────────────────────────────────────────────────
    case "fcp_transcode": {
      const mode = args.mode as string;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        ${mode === "optimize" || mode === "both" ? `
        fcp:selectMenu({"File", "Transcode Media", "Create Optimized Media"})
        ` : ""}
        ${mode === "proxy" || mode === "both" ? `
        ${mode === "both" ? "hs.timer.usleep(500000)" : ""}
        fcp:selectMenu({"File", "Transcode Media", "Create Proxy Media"})
        ` : ""}
        return {transcoding = true, mode = "${escapeLua(mode)}"}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Find & Replace Titles ─────────────────────────────────────
    case "fcp_find_replace_titles": {
      const findText = args.find as string;
      const replaceText = args.replace as string;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        -- Open Find and Replace Title Text dialog
        fcp:selectMenu({"Edit", "Find and Replace Title Text…"})
        hs.timer.usleep(500000)
        -- Use AX to find the dialog and fill in fields
        local app = fcp:application()
        if not app then return {error = "FCP application not found"} end
        local just = require("cp.just")
        local dialog = just.doUntil(function()
          local wins = app:allWindows()
          for _, w in ipairs(wins) do
            local axWin = hs.axuielement.windowElement(w)
            if axWin and axWin:attributeValue("AXSubrole") == "AXDialog" then
              return axWin
            end
          end
          return false
        end, 3)
        if not dialog then return {error = "Find and Replace dialog did not open"} end
        local textFields = dialog:attributeValue("AXChildren") or {}
        local fields = {}
        for _, child in ipairs(textFields) do
          if child:attributeValue("AXRole") == "AXTextField" then
            table.insert(fields, child)
          end
        end
        if #fields < 2 then return {error = "Could not find text fields in dialog"} end
        fields[1]:setAttributeValue("AXValue", "${escapeLua(findText)}")
        fields[2]:setAttributeValue("AXValue", "${escapeLua(replaceText)}")
        -- Click Replace All button
        for _, child in ipairs(textFields) do
          if child:attributeValue("AXRole") == "AXButton" and (child:attributeValue("AXTitle") or ""):find("Replace All") then
            child:performAction("AXPress")
            hs.timer.usleep(300000)
            return {replaced = true, find = "${escapeLua(findText)}", replace = "${escapeLua(replaceText)}"}
          end
        end
        return {error = "Replace All button not found"}
      `), 30000);
      return formatResult(extractResult(resp));
    }

    // ── Keyword Presets ───────────────────────────────────────────
    case "fcp_keyword_presets": {
      const kpAction = args.action as string;
      const kpPreset = args.preset as number | undefined;
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        ${kpAction === "list" ? `
        local config = require("cp.config")
        local presets = {}
        for i = 1, 9 do
          local key = "fcpxBrowserKeywordPreset" .. i
          local val = config.get(key)
          if val then presets[i] = val end
        end
        return {presets = presets}
        ` : kpAction === "save" && kpPreset ? `
        local keywordEditor = fcp.keywordEditor
        local keywords = keywordEditor and keywordEditor:keywords() or nil
        if not keywords then return {error = "Could not read keywords from Keyword Editor"} end
        local config = require("cp.config")
        config.set("fcpxBrowserKeywordPreset${kpPreset}", keywords)
        return {saved = true, preset = ${kpPreset}, keywords = keywords}
        ` : kpAction === "restore" && kpPreset ? `
        local config = require("cp.config")
        local keywords = config.get("fcpxBrowserKeywordPreset${kpPreset}")
        if not keywords then return {error = "No keywords saved in preset ${kpPreset}"} end
        local keywordEditor = fcp.keywordEditor
        if keywordEditor then
          keywordEditor:keywords(keywords)
          return {restored = true, preset = ${kpPreset}, keywords = keywords}
        end
        return {error = "Could not access Keyword Editor"}
        ` : `return {error = "Invalid action or missing preset number"}`}
      `));
      return formatResult(extractResult(resp));
    }

    // ── Text to Markers ───────────────────────────────────────────
    case "fcp_text_to_markers": {
      const markerText = args.text as string;
      const markerType = (args.type as string) || "marker";
      const resp = await client.executeLua(safeLua(`
        local fcp = require("cp.apple.finalcutpro")
        if not fcp:isRunning() then return {error = "FCP not running"} end
        local lines = {}
        for line in ("${escapeLua(markerText)}"):gmatch("[^\\n]+") do
          table.insert(lines, line)
        end
        local created = 0
        local errors = {}
        for i, line in ipairs(lines) do
          -- Parse "HH:MM:SS:FF description" or "HH:MM:SS;FF description" format
          local tc, desc = line:match("^(%d%d[:%%;]%d%d[:%%;]%d%d[:%%;]%d%d)%s+(.+)$")
          if tc and desc then
            -- Navigate to timecode
            fcp.viewer:timecode(tc)
            hs.timer.usleep(200000)
            -- Add marker
            ${markerType === "todo" ? `
            fcp:doShortcut("AddTodoMarker"):Now()
            ` : `
            fcp:doShortcut("AddMarker"):Now()
            `}
            hs.timer.usleep(200000)
            created = created + 1
          else
            table.insert(errors, {line = i, text = line, error = "Could not parse timecode"})
          end
        end
        return {created = created, totalLines = #lines, errors = #errors > 0 and errors or nil}
      `), 120000);
      return formatResult(extractResult(resp));
    }

    default:
      return JSON.stringify({ success: false, error: `Unknown tool: ${name}` });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Input Validation & Security
// ═══════════════════════════════════════════════════════════════════════════

const MAX_STRING_LENGTH = 10000;
const MAX_CODE_LENGTH = 500000;

/** Validate a file path to prevent directory traversal attacks */
function validateFilePath(path: string): string | null {
  if (!path || typeof path !== "string") return "Path is required";
  if (path.length > MAX_STRING_LENGTH) return "Path exceeds maximum length";
  // Reject relative path traversal
  if (path.includes("..")) return "Path traversal (..) is not allowed";
  // Reject null bytes
  if (path.includes("\0")) return "Path contains null bytes";
  return null;
}

/** Validate string input length */
function validateStringInput(
  value: unknown,
  fieldName: string,
  maxLength = MAX_STRING_LENGTH
): string | null {
  if (typeof value !== "string") return null;
  if (value.length > maxLength)
    return `${fieldName} exceeds maximum length of ${maxLength} characters`;
  return null;
}

function validateStringList(
  values: unknown,
  fieldName: string
): string | null {
  if (!Array.isArray(values) || values.length === 0) {
    return `${fieldName} must be a non-empty array`;
  }

  for (const [index, value] of values.entries()) {
    if (typeof value !== "string" || value.length === 0) {
      return `${fieldName}[${index}] must be a non-empty string`;
    }
    const err = validateStringInput(value, `${fieldName}[${index}]`);
    if (err) return err;
  }

  return null;
}

/** Validate Lua code input */
function validateCode(code: unknown): string | null {
  if (typeof code !== "string") return "Code must be a string";
  if (code.length === 0) return "Code cannot be empty";
  if (code.length > MAX_CODE_LENGTH)
    return `Code exceeds maximum length of ${MAX_CODE_LENGTH} characters`;
  return null;
}

/** Validate numeric range */
function validateRange(
  value: number,
  min: number,
  max: number,
  fieldName: string
): string | null {
  if (typeof value !== "number" || isNaN(value))
    return `${fieldName} must be a number`;
  if (value < min || value > max)
    return `${fieldName} must be between ${min} and ${max}`;
  return null;
}

function hasOwn(obj: Record<string, unknown>, key: string): boolean {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

function validateClipPlan(clipPlan: unknown): string | null {
  if (!Array.isArray(clipPlan) || clipPlan.length === 0) {
    return "clipPlan is required and must have at least one entry";
  }

  for (const [index, clip] of clipPlan.entries()) {
    if (!clip || typeof clip !== "object" || Array.isArray(clip)) {
      return `clipPlan[${index}] must be an object`;
    }

    const clipObj = clip as Record<string, unknown>;
    const unsupportedKeys = Object.keys(clipObj).filter(
      (key) => key !== "mediaPath"
    );
    if (unsupportedKeys.length > 0) {
      return `clipPlan[${index}] includes unsupported fields: ${unsupportedKeys.join(", ")}. fcp_assemble_rough_cut currently supports only mediaPath for each clip.`;
    }

    if (typeof clipObj.mediaPath !== "string" || clipObj.mediaPath.length === 0) {
      return `clipPlan[${index}].mediaPath is required`;
    }

    const pathErr = validateFilePath(clipObj.mediaPath);
    if (pathErr) {
      return `Invalid mediaPath "${clipObj.mediaPath}": ${pathErr}`;
    }
  }

  return null;
}

function validateToolArgs(
  name: string,
  args: Record<string, unknown>
): string | null {
  switch (name) {
    case "commandpost_get_handler_info": {
      if (typeof args.handler !== "string" || args.handler.length === 0) {
        return "handler is required";
      }
      const handlerErr = validateStringInput(args.handler, "handler");
      if (handlerErr) return handlerErr;

      if (args.includeChoices !== undefined && typeof args.includeChoices !== "boolean") {
        return "includeChoices must be a boolean";
      }

      if (args.includeParams !== undefined && typeof args.includeParams !== "boolean") {
        return "includeParams must be a boolean";
      }

      if (args.limit !== undefined) {
        const limitErr = validateRange(args.limit as number, 0, 1000, "limit");
        if (limitErr) return limitErr;
      }

      if (args.offset !== undefined) {
        const offsetErr = validateRange(args.offset as number, 0, 100000, "offset");
        if (offsetErr) return offsetErr;
      }

      return null;
    }

    case "commandpost_execute_lua":
      return validateCode(args.code);

    case "commandpost_chain":
      if (!Array.isArray(args.operations) || args.operations.length === 0) {
        return "operations must be a non-empty array";
      }
      return null;

    case "commandpost_get_preference":
    case "commandpost_set_preference":
      if (typeof args.key !== "string" || args.key.length === 0) {
        return "key is required";
      }
      return validateStringInput(args.key, "key");

    case "fcp_import_media":
    case "fcp_import_xml": {
      const path = args.path;
      if (typeof path !== "string" || path.length === 0) {
        return "path is required";
      }
      return validateFilePath(path);
    }

    case "fcp_open_project":
      if (typeof args.name !== "string" || args.name.length === 0) {
        return "name is required";
      }
      return validateStringInput(args.name, "name");

    case "fcp_select_menu":
      return validateStringList(args.path, "path");

    case "fcp_timeline_navigate": {
      const action = args.action;
      if (typeof action !== "string" || !TIMELINE_NAVIGATION_ACTIONS.has(action)) {
        return `Unknown navigation action: ${String(action)}`;
      }
      if (
        action === "timecode" &&
        (typeof args.timecode !== "string" || args.timecode.length === 0)
      ) {
        return "timecode is required when action is \"timecode\"";
      }
      return null;
    }

    case "fcp_color_board": {
      const VALID_ASPECTS = new Set(["color", "saturation", "exposure"]);
      const VALID_PUCKS = new Set(["master", "shadows", "midtones", "highlights"]);
      if (typeof args.aspect !== "string" || !VALID_ASPECTS.has(args.aspect)) {
        return `Invalid aspect: ${String(args.aspect)}. Must be one of: color, saturation, exposure`;
      }
      if (typeof args.puck !== "string" || !VALID_PUCKS.has(args.puck)) {
        return `Invalid puck: ${String(args.puck)}. Must be one of: master, shadows, midtones, highlights`;
      }
      if (typeof args.value !== "number" || Number.isNaN(args.value)) {
        return "value must be a number";
      }
      return null;
    }

    case "fcp_multicam_switch_angle": {
      const rangeErr = validateRange(args.angle as number, 1, 16, "angle");
      if (rangeErr) return rangeErr;
      const typeValue = args.type;
      if (
        typeValue !== undefined &&
        typeValue !== "video" &&
        typeValue !== "audio" &&
        typeValue !== "both"
      ) {
        return `Unknown multicam switch type: ${String(typeValue)}`;
      }
      return null;
    }

    case "fcp_pasteboard": {
      const action = args.action;
      if (typeof action !== "string" || !PASTEBOARD_ACTIONS.has(action)) {
        return `Unknown pasteboard action: ${String(action)}`;
      }
      if (args.slot !== undefined) {
        return validateRange(args.slot as number, 1, 50, "slot");
      }
      return null;
    }

    case "fcp_undo_redo":
      if (args.count !== undefined) {
        const countErr = validateRange(args.count as number, 1, 100, "count");
        if (countErr) return countErr;
      }
      return null;

    case "fcp_batch_apply_transition":
      if (Object.keys(args).length > 0) {
        return "fcp_batch_apply_transition does not support custom transition or duration parameters. It applies Final Cut Pro's current default transition across the active timeline.";
      }
      return null;

    case "fcp_assemble_rough_cut": {
      const unsupportedKeys = Object.keys(args).filter(
        (key) => key !== "projectName" && key !== "clipPlan"
      );
      if (unsupportedKeys.length > 0) {
        return `Unsupported fields for fcp_assemble_rough_cut: ${unsupportedKeys.join(", ")}. Supported fields are projectName and clipPlan.`;
      }

      if (hasOwn(args, "projectName")) {
        if (typeof args.projectName !== "string" || args.projectName.length === 0) {
          return "projectName must be a non-empty string";
        }
        const err = validateStringInput(args.projectName, "projectName");
        if (err) return err;
      }

      return validateClipPlan(args.clipPlan);
    }

    case "fcp_color_wheels": {
      const VALID_CONTROLS = new Set(["temperature", "tint", "hue", "mix", "saturation", "brightness", "contrast"]);
      if (typeof args.control !== "string" || !VALID_CONTROLS.has(args.control)) {
        return `Invalid control. Must be one of: ${[...VALID_CONTROLS].join(", ")}`;
      }
      if (args.value !== undefined && typeof args.value !== "number") return "value must be a number";
      return null;
    }

    case "fcp_video_inspector": {
      if (args.action !== "get" && args.action !== "set") return "action must be 'get' or 'set'";
      const VALID_SECTIONS = new Set(["transform", "crop", "compositing", "stabilization", "spatial"]);
      if (typeof args.section !== "string" || !VALID_SECTIONS.has(args.section)) {
        return `Invalid section. Must be one of: ${[...VALID_SECTIONS].join(", ")}`;
      }
      if (args.action === "set" && !args.property) return "property is required for action=set";
      return null;
    }

    case "fcp_audio_inspector":
      if (args.action !== "get" && args.action !== "set") return "action must be 'get' or 'set'";
      if (args.action === "set" && !args.property) return "property is required for action=set";
      if (args.action === "set" && typeof args.value !== "number") return "value must be a number for action=set";
      return null;

    case "fcp_toolbar_state":
      if (args.action !== "get" && args.action !== "set") return "action must be 'get' or 'set'";
      return null;

    case "fcp_timeline_appearance":
      if (args.action !== "get" && args.action !== "set") return "action must be 'get' or 'set'";
      if (args.clipHeight !== undefined) {
        const err = validateRange(args.clipHeight as number, 0, 100, "clipHeight");
        if (err) return err;
      }
      return null;

    case "fcp_viewer_config":
      if (args.action !== "get" && args.action !== "set") return "action must be 'get' or 'set'";
      return null;

    case "fcp_export_csv": {
      const VALID_SOURCES = new Set(["browser", "timeline"]);
      if (typeof args.source !== "string" || !VALID_SOURCES.has(args.source)) {
        return "source must be 'browser' or 'timeline'";
      }
      if (args.path !== undefined) {
        const pathErr = validateFilePath(args.path as string);
        if (pathErr) return pathErr;
      }
      return null;
    }

    case "fcp_transcode": {
      const VALID_MODES = new Set(["optimize", "proxy", "both"]);
      if (typeof args.mode !== "string" || !VALID_MODES.has(args.mode)) {
        return "mode must be 'optimize', 'proxy', or 'both'";
      }
      return null;
    }

    case "fcp_find_replace_titles":
      if (typeof args.find !== "string" || args.find.length === 0) return "find is required";
      if (typeof args.replace !== "string") return "replace is required";
      return validateStringInput(args.find, "find") || validateStringInput(args.replace, "replace");

    case "fcp_keyword_presets": {
      const VALID_ACTIONS = new Set(["save", "restore", "list"]);
      if (typeof args.action !== "string" || !VALID_ACTIONS.has(args.action)) {
        return "action must be 'save', 'restore', or 'list'";
      }
      if ((args.action === "save" || args.action === "restore") && args.preset !== undefined) {
        const presetErr = validateRange(args.preset as number, 1, 9, "preset");
        if (presetErr) return presetErr;
      }
      return null;
    }

    case "fcp_text_to_markers":
      if (typeof args.text !== "string" || args.text.length === 0) return "text is required";
      return validateStringInput(args.text, "text");

    default:
      return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Utility Functions
// ═══════════════════════════════════════════════════════════════════════════

/** Escape a string for safe inclusion in Lua string literals */
function escapeLua(str: string): string {
  return str
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r")
    .replace(/\0/g, "\\0");
}

/** Convert a JavaScript value to a Lua literal */
function toLuaLiteral(value: unknown): string {
  if (value === null || value === undefined) return "nil";
  if (typeof value === "boolean") return value.toString();
  if (typeof value === "number") {
    if (Number.isNaN(value)) return "0/0";
    if (value === Infinity) return "math.huge";
    if (value === -Infinity) return "-math.huge";
    return value.toString();
  }
  if (typeof value === "string") return `"${escapeLua(value)}"`;
  if (Array.isArray(value)) {
    const items = value.map((v) => toLuaLiteral(v)).join(", ");
    return `{${items}}`;
  }
  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>)
      .map(([k, v]) => `["${escapeLua(k)}"] = ${toLuaLiteral(v)}`)
      .join(", ");
    return `{${entries}}`;
  }
  return `"${escapeLua(String(value))}"`;
}

// ═══════════════════════════════════════════════════════════════════════════
// MCP Server Setup
// ═══════════════════════════════════════════════════════════════════════════

const server = new Server(
  {
    name: "commandpost",
    version: "2.0.0",
  },
  {
    capabilities: {
      tools: {},
      resources: {},
      prompts: {},
    },
  }
);

// ── Resources ─────────────────────────────────────────────────────────────

const RESOURCES = [
  {
    uri: "commandpost://instructions",
    name: "CommandPost FCPX Editing Instructions",
    description:
      "Best practices and guidelines for editing in Final Cut Pro via CommandPost MCP. Attach this before performing complex edits.",
    mimeType: "text/plain",
  },
  {
    uri: "commandpost://fcp-status",
    name: "Final Cut Pro Current Status",
    description:
      "Live status of Final Cut Pro — whether it's running, which libraries are open, and current playhead position.",
    mimeType: "application/json",
  },
  {
    uri: "commandpost://tool-reference",
    name: "Available Tools Quick Reference",
    description:
      "Quick reference of all available MCP tools organized by category.",
    mimeType: "text/plain",
  },
  {
    uri: "commandpost://timeline/clips",
    name: "Timeline Clips",
    description:
      "Live list of clips currently in the active timeline — names, positions, durations.",
    mimeType: "application/json",
  },
];

server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return { resources: RESOURCES };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;

  switch (uri) {
    case "commandpost://instructions":
      return {
        contents: [
          {
            uri,
            mimeType: "text/plain",
            text: [
              "# CommandPost FCPX Editing Best Practices",
              "",
              "## Before Editing",
              "1. Always check FCP status first (fcp_status) to confirm it's running",
              "2. Verify the correct project is open (fcp_browser_list_libraries)",
              "3. Check current playhead position (fcp_get_playhead_position) for context",
              "",
              "## Editing Workflow",
              "- Use fcp_get_selected_clips to understand what's currently selected before applying effects",
              "- Use fcp_list_effects / fcp_list_transitions to discover available plugins before applying them",
              "- Navigate to specific timecodes with fcp_set_playhead_position before blading or adding markers",
              "- For batch operations, select all first (fcp_timeline_select action=all) then apply",
              "",
              "## Safety",
              "- Use fcp_undo_redo to revert mistakes — always safer than trying to manually reverse changes",
              "- Check clip properties before and after modifications to verify changes applied correctly",
              "- For destructive operations (delete, blade), confirm the selection/position first",
              "- Validate file paths before import operations",
              "",
              "## Performance Tips",
              "- Use the commandpost_chain tool for multi-step workflows to reduce round-trips",
              "- Use fcp_assemble_rough_cut for batch-importing multiple media paths instead of repeated individual import calls",
              "- Batch transition application (fcp_batch_apply_transition) applies Final Cut Pro's current default transition across the active timeline",
              "- Avoid querying the full effects list repeatedly — cache the results within your workflow",
              "",
              "## FCP-Specific Notes",
              "- Final Cut Pro uses a magnetic timeline — clips snap to each other",
              "- Connected clips (B-roll) attach to the primary storyline and move with it",
              "- Compound clips group multiple clips into a single container",
              "- Auditions let you group alternative clips and switch between them",
              "- Roles (Dialogue, Music, Effects, Video) help organize clips for output",
              "- Proxy media can speed up editing on slower hardware — toggle with fcp_proxy_toggle",
            ].join("\n"),
          },
        ],
      };

    case "commandpost://fcp-status": {
      try {
        await client.ensureConnected();
        const resp = await client.executeLua(FCP_STATUS_LUA, 60000);
        const envelope = extractResult(resp) as Record<string, unknown>;
        const payload =
          envelope &&
          typeof envelope === "object" &&
          envelope.result &&
          typeof envelope.result === "object"
            ? {
                ...(envelope.result as Record<string, unknown>),
                ...(envelope.success !== undefined ? { success: envelope.success } : {}),
              }
            : envelope;
        return {
          contents: [
            {
              uri,
              mimeType: "application/json",
              text: formatResult(payload),
            },
          ],
        };
      } catch {
        return {
          contents: [
            {
              uri,
              mimeType: "application/json",
              text: JSON.stringify({
                error:
                  "Cannot read Final Cut Pro status. Ensure CommandPost is running with WebSocket enabled and that Final Cut Pro is available.",
              }),
            },
          ],
        };
      }
    }

    case "commandpost://tool-reference":
      return {
        contents: [
          {
            uri,
            mimeType: "text/plain",
            text: [
              "# CommandPost MCP Tool Reference",
              "",
              "## System: commandpost_ping, commandpost_list_handlers, commandpost_get_handler_info, commandpost_execute_lua, commandpost_execute_action, commandpost_chain, commandpost_get/set_preference, commandpost_alert",
              "",
              "## FCP App: fcp_launch, fcp_quit, fcp_restart, fcp_status, fcp_select_menu, fcp_do_shortcut",
              "",
              "## Timeline: fcp_timeline_show, fcp_timeline_playback, fcp_timeline_navigate, fcp_timeline_select, fcp_timeline_blade, fcp_timeline_delete, fcp_timeline_clipboard, fcp_timeline_zoom, fcp_timeline_get_info",
              "",
              "## Discovery: fcp_list_effects, fcp_list_audio_effects, fcp_list_transitions, fcp_list_generators, fcp_list_titles, fcp_get_selected_clips, fcp_get_playhead_position, fcp_set_playhead_position, fcp_get_project_settings",
              "",
              "## Clip Properties: fcp_get_clip_properties, fcp_set_clip_properties",
              "",
              "## Effects: fcp_apply_effect, fcp_apply_transition, fcp_apply_generator, fcp_apply_title",
              "",
              "## Clip Ops: fcp_rename_clip, fcp_rate_clip, fcp_duplicate_clip, fcp_enable_disable_clip, fcp_split_at_timecode, fcp_speed_custom, fcp_retime",
              "",
              "## Range: fcp_set_range, fcp_clear_range",
              "",
              "## Compound/Auditions: fcp_create_compound_clip, fcp_break_apart_compound, fcp_create_audition",
              "",
              "## Organization: fcp_assign_role, fcp_add_keyword, fcp_add_marker, fcp_list_markers",
              "",
              "## Color/Stabilization: fcp_color_board, fcp_color_wheels, fcp_stabilization",
              "",
              "## Inspector: fcp_video_inspector, fcp_audio_inspector, fcp_inspector_show",
              "",
              "## Export/Import: fcp_export, fcp_export_csv, fcp_import_media, fcp_import_xml, fcp_export_xml",
              "",
              "## Batch/Workflow: fcp_batch_apply_transition, fcp_assemble_rough_cut, fcp_text_to_markers",
              "",
              "## Media: fcp_proxy_toggle, fcp_transcode, fcp_match_frame",
              "",
              "## Toolbar/Appearance: fcp_toolbar_state, fcp_timeline_appearance, fcp_viewer_config",
              "",
              "## Titles/Keywords: fcp_find_replace_titles, fcp_keyword_presets",
              "",
              "## Window/Browser: fcp_window_layout, fcp_browser_show, fcp_browser_list_libraries, fcp_browser_select_library, fcp_viewer_show",
            ].join("\n"),
          },
        ],
      };

    case "commandpost://timeline/clips": {
      try {
        await client.ensureConnected();
        const resp = await client.executeLua(safeLua(`
          local timeline = fcp.timeline
          if not timeline:isShowing() then
            return {error = "Timeline is not showing", clips = {}, count = 0}
          end

          local contentsUI = timeline.contents:UI()
          if not contentsUI then
            return {clips = {}, count = 0, note = "Could not access timeline contents"}
          end

          local clips = {}
          local children = contentsUI:attributeValue("AXChildren")
          if children then
            for _, child in ipairs(children) do
              local desc = safeGet(function() return child:attributeValue("AXDescription") end) or ""
              if desc ~= "Playhead" and desc ~= "" then
                table.insert(clips, {
                  description = desc,
                  role = safeGet(function() return child:attributeValue("AXRole") end) or "unknown",
                  value = safeGet(function() return child:attributeValue("AXValue") end),
                  position = safeGet(function() return child:attributeValue("AXPosition") end),
                  size = safeGet(function() return child:attributeValue("AXSize") end),
                  selected = safeGet(function() return child:attributeValue("AXSelected") end),
                })
              end
            end
          end
          return {clips = clips, count = #clips}
        `), 60000);
        const envelope = extractResult(resp) as Record<string, unknown>;
        const payload =
          envelope &&
          typeof envelope === "object" &&
          envelope.result &&
          typeof envelope.result === "object"
            ? {
                ...(envelope.result as Record<string, unknown>),
                ...(envelope.success !== undefined ? { success: envelope.success } : {}),
              }
            : envelope;
        return {
          contents: [
            {
              uri,
              mimeType: "application/json",
              text: formatResult(payload),
            },
          ],
        };
      } catch {
        return {
          contents: [
            {
              uri,
              mimeType: "application/json",
              text: JSON.stringify({
                success: false,
                error: "Cannot connect to CommandPost.",
                clips: [],
                count: 0,
              }),
            },
          ],
        };
      }
    }

    default:
      throw new Error(`Unknown resource: ${uri}`);
  }
});

// ── Prompts ───────────────────────────────────────────────────────────────

const PROMPTS = [
  {
    name: "edit_video",
    description:
      "Guided workflow for editing a video project in Final Cut Pro — from organizing media to rough cut to export.",
    arguments: [
      {
        name: "project_type",
        description:
          'Type of project (e.g., "short film", "social media", "documentary", "commercial")',
        required: false,
      },
    ],
  },
  {
    name: "color_grade",
    description:
      "Step-by-step color grading workflow using Final Cut Pro's Color Board and color tools.",
    arguments: [
      {
        name: "look",
        description:
          'Desired look (e.g., "cinematic warm", "cool desaturated", "high contrast")',
        required: false,
      },
    ],
  },
  {
    name: "organize_media",
    description:
      "Workflow for organizing media with keywords, ratings, roles, and smart collections in FCP.",
    arguments: [],
  },
  {
    name: "audio_edit",
    description:
      "Audio editing and mixing workflow — levels, effects, roles, and export considerations.",
    arguments: [],
  },
  {
    name: "multicam_edit",
    description:
      "Multicam editing workflow — syncing angles, switching, and audio selection.",
    arguments: [
      {
        name: "angle_count",
        description: "Number of camera angles",
        required: false,
      },
    ],
  },
  {
    name: "rough_cut_assembly",
    description:
      "Assemble a rough cut from raw footage — import, arrange, trim, and add basic transitions.",
    arguments: [
      {
        name: "media_folder",
        description: "Path to folder containing media files to import",
        required: false,
      },
    ],
  },
];

server.setRequestHandler(ListPromptsRequestSchema, async () => {
  return { prompts: PROMPTS };
});

server.setRequestHandler(GetPromptRequestSchema, async (request) => {
  const { name, arguments: promptArgs } = request.params;

  switch (name) {
    case "edit_video": {
      const projectType = promptArgs?.project_type || "general";
      return {
        messages: [
          {
            role: "user" as const,
            content: {
              type: "text" as const,
              text: `I want to edit a ${projectType} video project in Final Cut Pro using CommandPost. Please guide me through the full workflow:\n\n1. First check that FCP is running (fcp_status)\n2. List available libraries (fcp_browser_list_libraries)\n3. Help me organize my media — suggest keywords and ratings\n4. Create a rough cut assembly\n5. Apply transitions between clips\n6. Do basic color correction\n7. Add titles if needed\n8. Review and export\n\nStart by checking the current state of Final Cut Pro.`,
            },
          },
        ],
      };
    }

    case "color_grade": {
      const look = promptArgs?.look || "balanced";
      return {
        messages: [
          {
            role: "user" as const,
            content: {
              type: "text" as const,
              text: `I want to color grade my Final Cut Pro project with a "${look}" look. Please guide me through:\n\n1. Check FCP status and current project\n2. Get the current clip properties to see the starting point\n3. Walk me through Color Board adjustments (exposure, saturation, color)\n4. Apply corrections clip-by-clip or suggest batch approaches\n5. Preview and adjust\n\nUse the fcp_color_board tool to make adjustments. Start by checking what's in the timeline.`,
            },
          },
        ],
      };
    }

    case "organize_media":
      return {
        messages: [
          {
            role: "user" as const,
            content: {
              type: "text" as const,
              text: "Help me organize my media in Final Cut Pro. I need to:\n\n1. Check the current libraries and what's imported (fcp_browser_list_libraries, fcp_status)\n2. Review clips in the timeline and browser\n3. Add keywords to categorize clips (fcp_add_keyword)\n4. Rate clips as favorites or rejects (fcp_rate_clip)\n5. Assign roles for audio and video tracks (fcp_assign_role)\n6. Create compound clips for grouped elements (fcp_create_compound_clip)\n\nStart by showing me what's currently in the project.",
            },
          },
        ],
      };

    case "audio_edit":
      return {
        messages: [
          {
            role: "user" as const,
            content: {
              type: "text" as const,
              text: "I need to edit and mix the audio in my Final Cut Pro project. Please help me:\n\n1. Check the current project state\n2. List available audio effects (fcp_list_audio_effects)\n3. Review the timeline clips and their audio\n4. Apply audio effects as needed\n5. Adjust audio levels and balance\n6. Assign audio roles (Dialogue, Music, Effects)\n7. Help with any audio-specific export settings\n\nStart by checking what's in the timeline.",
            },
          },
        ],
      };

    case "multicam_edit": {
      const angleCount = promptArgs?.angle_count || "multiple";
      return {
        messages: [
          {
            role: "user" as const,
            content: {
              type: "text" as const,
              text: `I want to do a multicam edit with ${angleCount} camera angles in Final Cut Pro. Guide me through:\n\n1. Check FCP is running and the multicam clip is in the timeline\n2. Show me how to switch between angles (fcp_multicam_switch_angle)\n3. Help me cut between video angles while keeping one audio source\n4. Review the edit and make adjustments\n5. Break apart the multicam if needed for fine-tuning\n\nStart by checking the project state.`,
            },
          },
        ],
      };
    }

    case "rough_cut_assembly": {
      const mediaFolder = promptArgs?.media_folder;
      return {
        messages: [
          {
            role: "user" as const,
            content: {
              type: "text" as const,
              text: `I want to assemble a rough cut in Final Cut Pro.${mediaFolder ? ` My media is in: ${mediaFolder}` : ""}\n\nPlease help me:\n1. Check FCP is running (fcp_status)\n2. ${mediaFolder ? "Import media from the folder (fcp_import_media)" : "Identify what media to work with in the current library"}\n3. Arrange clips in the timeline in a logical order\n4. Add basic transitions between clips\n5. Do a quick review of the assembly\n\n${mediaFolder ? "You can use fcp_assemble_rough_cut with a clipPlan for batch import, or import clips individually." : "Start by checking what's available in the current project."}`,
            },
          },
        ],
      };
    }

    default:
      throw new Error(`Unknown prompt: ${name}`);
  }
});

// ── Tool Handlers ─────────────────────────────────────────────────────────

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  const startTime = Date.now();
  try {
    const result = await handleTool(name, (args as Record<string, unknown>) || {});
    log("debug", `Tool ${name} completed in ${Date.now() - startTime}ms`);
    return {
      content: [{ type: "text" as const, text: result }],
    };
  } catch (err) {
    const errorMessage =
      err instanceof Error ? err.message : String(err);
    log("error", `Tool ${name} failed after ${Date.now() - startTime}ms: ${errorMessage}`);
    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify({ success: false, error: errorMessage }),
        },
      ],
      isError: true,
    };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// Entry Point
// ═══════════════════════════════════════════════════════════════════════════

async function shutdown(): Promise<void> {
  log("info", "Shutting down...");
  try {
    await client.disconnect();
  } catch {
    // Ignore disconnect errors during shutdown
  }
  try {
    await server.close();
  } catch {
    // Ignore close errors during shutdown
  }
  process.exit(0);
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

async function main(): Promise<void> {
  log("info", `CommandPost MCP Server v2.0.0 starting (${TOOLS.length} tools, ${RESOURCES.length} resources, ${PROMPTS.length} prompts)`);

  // Try to pre-connect to CommandPost (non-blocking)
  client.connect().then(() => {
    log("info", "Connected to CommandPost WebSocket");
  }).catch(() => {
    log("warn", "Could not pre-connect to CommandPost — will retry on first tool call");
  });

  const transport = new StdioServerTransport();
  await server.connect(transport);
  log("info", "MCP server ready on stdio transport");
}

main().catch((err) => {
  log("error", "Fatal error", err);
  process.exit(1);
});
