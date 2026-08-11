# CommandPost MCP Server

A [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server that exposes the full power of [CommandPost](https://commandpost.io) and Final Cut Pro automation to AI assistants like Claude.

**76 tools** covering everything from timeline editing and color correction to arbitrary Lua scripting and multi-step operation chaining.

---

## Architecture

```
Claude / AI Assistant
        |
        | stdio (JSON-RPC)
        v
  MCP Server (Node.js)
        |
        | WebSocket (port 27480)
        v
   CommandPost (Hammerspoon)
        |
        | Accessibility API + Lua scripting
        v
  Final Cut Pro / macOS
```

The MCP server connects to CommandPost's built-in WebSocket server, which provides access to the full Hammerspoon runtime and CommandPost plugin ecosystem. Operations are executed in CommandPost's Lua environment with direct access to Final Cut Pro via the accessibility API.

---

## Prerequisites

- **macOS** (CommandPost is macOS-only)
- **[CommandPost](https://commandpost.io)** installed and running
- **Node.js** >= 18.0.0
- **Final Cut Pro** (for FCP-specific tools)

---

## Setup

### 1. Enable the CommandPost WebSocket Server

Open CommandPost Preferences and enable the WebSocket control surface, or run:

```bash
defaults write org.latenitefilms.CommandPost "cp.websocket.enabled" -int 1
```

Then restart CommandPost. The WebSocket server listens on **port 27480** by default.

### 2. Build the MCP Server

```bash
cd src/mcp-server
npm install
npm run build
```

### 3. Configure Claude Code

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "commandpost": {
      "command": "node",
      "args": ["/path/to/CommandPost/src/mcp-server/dist/index.js"]
    }
  }
}
```

Or set the `COMMANDPOST_WS_URL` environment variable if using a non-default port:

```json
{
  "mcpServers": {
    "commandpost": {
      "command": "node",
      "args": ["/path/to/CommandPost/src/mcp-server/dist/index.js"],
      "env": {
        "COMMANDPOST_WS_URL": "ws://localhost:27480"
      }
    }
  }
}
```

### 4. Restart Claude Code

The MCP server loads at session start. After adding the configuration, restart your Claude Code session.

---

## Authentication

The WebSocket connection is authenticated using a shared token. When CommandPost starts the WebSocket server, it generates a random SHA-256 token and writes it to:

```
~/Library/Application Support/CommandPost/mcp-auth-token
```

The MCP server reads this token automatically. The token is regenerated each time CommandPost's WebSocket server starts and is restricted to owner-only permissions (`chmod 600`).

You can also set the token via the `COMMANDPOST_AUTH_TOKEN` environment variable.

---

## Tools Reference

### System & Connection (9 tools)

| Tool | Description |
|------|-------------|
| `commandpost_ping` | Check if CommandPost is running and the WebSocket connection is active |
| `commandpost_list_handlers` | List all available action handlers registered in CommandPost |
| `commandpost_get_handler_info` | Get detailed info about a specific action handler with paginated choices and optional params |
| `commandpost_execute_lua` | Execute arbitrary Lua code in CommandPost's Hammerspoon environment |
| `commandpost_execute_action` | Execute a registered action by handler ID and action ID |
| `commandpost_chain` | Execute multiple operations sequentially with result passing between steps |
| `commandpost_get_preference` | Get a CommandPost preference value |
| `commandpost_set_preference` | Set a CommandPost preference value |
| `commandpost_alert` | Show an on-screen alert/notification |

### Final Cut Pro — Application (6 tools)

| Tool | Description |
|------|-------------|
| `fcp_launch` | Launch Final Cut Pro (or bring to front) |
| `fcp_quit` | Quit Final Cut Pro |
| `fcp_restart` | Quit and relaunch Final Cut Pro |
| `fcp_status` | Get running state, version, frontmost status, and active libraries |
| `fcp_select_menu` | Select any FCP menu item by path (e.g., `["File", "Share", "Master File..."]`) |
| `fcp_do_shortcut` | Execute a keyboard shortcut by command ID |

### Final Cut Pro — Timeline (9 tools)

| Tool | Description |
|------|-------------|
| `fcp_timeline_show` | Show/focus the timeline on primary or secondary display |
| `fcp_timeline_playback` | Play, pause, or toggle playback |
| `fcp_timeline_navigate` | Jump to beginning/end, next/previous frame or edit, or a specific timecode |
| `fcp_timeline_select` | Select clips: all, none, at playhead, or by 1-based index |
| `fcp_timeline_blade` | Blade (cut) at the current playhead position |
| `fcp_timeline_delete` | Delete the selected clips or range (auto-selects at playhead if needed) |
| `fcp_timeline_clipboard` | Copy, cut, or paste timeline content |
| `fcp_timeline_zoom` | Zoom in, out, or fit to window |
| `fcp_timeline_get_info` | Get timeline state: clip list, playhead timecode, undo text, and more |

### Final Cut Pro — Effects & Plugins (4 tools)

| Tool | Description |
|------|-------------|
| `fcp_apply_effect` | Apply a video or audio effect by name (e.g., `"Blur/Gaussian"`) |
| `fcp_apply_transition` | Apply a transition between clips (e.g., `"Dissolves/Cross Dissolve"`) |
| `fcp_apply_generator` | Apply a generator to the timeline (e.g., `"Solids/Custom"`) |
| `fcp_apply_title` | Apply a title to the timeline (e.g., `"Basic Title"`) |

### Final Cut Pro — Discovery (6 tools)

| Tool | Description |
|------|-------------|
| `fcp_list_effects` | List all installed video effects |
| `fcp_list_audio_effects` | List all installed audio effects |
| `fcp_list_transitions` | List all installed transitions |
| `fcp_list_generators` | List all installed generators |
| `fcp_list_titles` | List all installed titles |
| `fcp_list_markers` | List all markers in the current timeline |

### Final Cut Pro — Browser & Libraries (3 tools)

| Tool | Description |
|------|-------------|
| `fcp_browser_show` | Show the browser panel (libraries, media, or generators) |
| `fcp_browser_list_libraries` | List all open libraries with paths |
| `fcp_browser_select_library` | Select a library by name |

### Final Cut Pro — Inspector & Viewer (2 tools)

| Tool | Description |
|------|-------------|
| `fcp_inspector_show` | Show inspector and optionally select a tab (audio, video, info, color, etc.) |
| `fcp_viewer_show` | Show the viewer on primary or secondary display |

### Final Cut Pro — Color (1 tool)

| Tool | Description |
|------|-------------|
| `fcp_color_board` | Adjust Color Board parameters (color/saturation/exposure for master/shadows/midtones/highlights) |

### Final Cut Pro — Export & Import (4 tools)

| Tool | Description |
|------|-------------|
| `fcp_export` | Export/share the current project with optional destination preset |
| `fcp_export_xml` | Export FCPXML via File > Export XML |
| `fcp_import_media` | Import a media file or folder |
| `fcp_import_xml` | Import an FCPXML file |

### Final Cut Pro — Projects & Playhead (5 tools)

| Tool | Description |
|------|-------------|
| `fcp_open_project` | Open a project by name |
| `fcp_project_properties` | Get project properties (resolution, frame rate, etc.) |
| `fcp_get_playhead_position` | Get current playhead timecode |
| `fcp_set_playhead_position` | Set the playhead to a specific timecode |
| `fcp_get_project_settings` | Get full project settings (resolution, frame rate, color space, audio) |

### Final Cut Pro — Markers & Keywords (2 tools)

| Tool | Description |
|------|-------------|
| `fcp_add_marker` | Add a standard, to-do, or chapter marker (optionally named) |
| `fcp_add_keyword` | Add a keyword to selected clips |

### Final Cut Pro — Clip Operations (10 tools)

| Tool | Description |
|------|-------------|
| `fcp_rename_clip` | Rename the selected clip |
| `fcp_rate_clip` | Rate as favorite, reject, or unrate |
| `fcp_get_selected_clips` | Get info about selected clips (names, positions, durations) |
| `fcp_get_clip_properties` | Get transform/compositing properties (position, scale, rotation, opacity) |
| `fcp_set_clip_properties` | Set transform or compositing properties on the selected clip |
| `fcp_duplicate_clip` | Duplicate the selected clip(s) |
| `fcp_enable_disable_clip` | Enable or disable the selected clip(s) |
| `fcp_create_compound_clip` | Create a compound clip from selected clips |
| `fcp_create_audition` | Create an audition from selected clips |
| `fcp_break_apart_compound` | Break apart a compound clip |

### Final Cut Pro — Speed & Retime (2 tools)

| Tool | Description |
|------|-------------|
| `fcp_retime` | Apply speed presets (slow 50%/25%/10%, fast 2x-20x, normal, reverse, hold) |
| `fcp_speed_custom` | Set a custom speed percentage |

### Final Cut Pro — Advanced (9 tools)

| Tool | Description |
|------|-------------|
| `fcp_split_at_timecode` | Blade at a specific timecode position |
| `fcp_set_range` | Set timeline in/out range selection |
| `fcp_clear_range` | Clear the range selection |
| `fcp_captions` | Add, extract, or import captions |
| `fcp_multicam_switch_angle` | Switch multicam angle (video, audio, or both) |
| `fcp_assign_role` | Assign a role to selected clips |
| `fcp_stabilization` | Toggle stabilization on the selected clip |
| `fcp_proxy_toggle` | Toggle proxy/optimized/original media |
| `fcp_batch_apply_transition` | Apply a transition to all edit points in a selection |

### Final Cut Pro — Window & Undo (3 tools)

| Tool | Description |
|------|-------------|
| `fcp_window_layout` | Show/hide browser, inspector, timeline, viewer, or toggle fullscreen |
| `fcp_undo_redo` | Undo or redo (with optional count for multiple undos) |
| `fcp_pasteboard` | Access CommandPost's clipboard history for timeline content |

### Final Cut Pro — Workflow (1 tool)

| Tool | Description |
|------|-------------|
| `fcp_assemble_rough_cut` | Assemble a rough cut from a sequence of operations in one call |

---

## Verification

Editing tools return **verification data** so you can confirm operations actually succeeded:

```json
{
  "action": "blade",
  "before": { "clipCount": 12, "timecode": "00:00:05:00" },
  "after": {
    "clipCount": 13,
    "timecode": "00:00:05:00",
    "undoText": "Undo Blade",
    "clips": [
      { "description": "Generator:Placeholder", "duration": "00:00:01:20" },
      { "description": "Generator:Placeholder", "duration": "00:00:01:10" }
    ]
  },
  "verified": {
    "undoText": "Undo Blade",
    "clipDelta": 1,
    "tcChanged": false
  }
}
```

**Three verification signals:**

| Signal | What it tells you |
|--------|-------------------|
| `verified.undoText` | FCP's own name for the last action (e.g., `"Undo Blade"`, `"Undo Add Cross Dissolve"`) |
| `verified.clipDelta` | Change in clip count (`+1` = clip added, `-1` = clip removed) |
| `verified.tcChanged` | Whether the playhead moved (key for navigation verification) |

Navigation tools return **timecode verification**:

```json
{
  "navigated": "next_edit",
  "beforeTimecode": "00:00:05:00",
  "afterTimecode": "00:00:10:00",
  "timecodeChanged": true
}
```

### Dialog Handling

When FCP presents a modal dialog (e.g., "not enough extra media beyond clip edges" when applying a transition), the server automatically detects and handles it. The `handleFCPDialog` helper scans for AXSheets and modal windows, reads their text, and clicks the appropriate button. This is integrated into both the `withVerification` wrapper and the `fcp_apply_transition` tool.

---

## Chaining Operations

The `commandpost_chain` tool executes multiple steps sequentially, passing results between them via the `_prev` variable:

```json
{
  "operations": [
    { "type": "execute", "code": "require('cp.apple.finalcutpro'):doShortcut('JumpToStart'):Now() return 'at_start'" },
    { "type": "execute", "code": "require('cp.apple.finalcutpro'):doShortcut('NextEdit'):Now() return 'at_edit_1'" },
    { "type": "command", "handler": "fcpx_transition", "actionId": "Cross Dissolve" },
    { "type": "delay", "seconds": 0.5 },
    { "type": "execute", "code": "require('cp.apple.finalcutpro'):doShortcut('AddMarker'):Now() return 'marker_added'" }
  ]
}
```

**Operation types:**

| Type | Fields | Description |
|------|--------|-------------|
| `execute` | `code` | Run Lua code; result available as `_prev` in next step |
| `command` | `handler`, `actionId` | Execute a registered action handler |
| `query` | `query` | Query handler information |
| `delay` | `seconds` | Pause between operations (max 10s) |

---

## Lua Execution

The `commandpost_execute_lua` tool is the escape hatch — it can do **anything** CommandPost can do:

```lua
-- Get FCP timeline info
local fcp = require("cp.apple.finalcutpro")
return {
  running = fcp:isRunning(),
  version = tostring(fcp:version()),
  timeline_showing = fcp.timeline:isShowing(),
}
```

```lua
-- Show an alert and play a sound
hs.alert.show("Hello from MCP!")
hs.sound.getByName("Funk"):play()
return true
```

The code runs with full access to:
- `hs` — Hammerspoon API (windows, keyboard, mouse, audio, network, etc.)
- `require("cp.*")` — CommandPost modules (FCP automation, plugins, config)
- All standard Lua 5.4 libraries

---

## FCP v12 Compatibility

This fork includes fixes for Final Cut Pro v12 (version 12.0+):

- **Toolbar checkbox detection**: FCP v12 no longer wraps toolbar checkboxes in `AXGroup` elements. The `PrimaryToolbar.lua` module now falls back to description-based matching for the Keyword Editor, Browser, Timeline, and Inspector checkboxes.
- **Menu item relocation**: "Rename Clip" moved from the Modify menu to the Clip menu in v12. The MCP server tries both locations.
- **Lua pattern safety**: All `selectMenu` calls use `{plain = true}` to prevent crashes from special characters (`%`, `.`, `(`, `)`) in menu item names.
- **Plugin name-only matching**: The `findFCPXPluginBySimplifiedPath` function now supports name-only matching as a fallback (e.g., `"Cross Dissolve"` without requiring `"Dissolves/Cross Dissolve"`).

---

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Watch mode (rebuild on changes)
npm run dev

# Run tests (offline — protocol only)
node test.mjs

# Run tests (live — requires running CommandPost with WebSocket enabled)
node test.mjs --live
```

### Project Structure

```
src/mcp-server/
  src/
    index.ts          # MCP server, tool definitions, and handlers
    commandpost.ts    # WebSocket client for CommandPost
  dist/               # Compiled JavaScript (git-ignored)
  test.mjs            # Test suite
  package.json
  tsconfig.json
```

### Adding New Tools

1. Add the tool definition to the `TOOLS` array in `src/index.ts` (name, description, inputSchema)
2. Add the handler in the `handleTool` switch statement
3. Use `withVerification()` for editing operations or `withUndoCheck()` for lighter verification
4. Rebuild with `npm run build`

---

## How It Works

### WebSocket Protocol

The MCP server communicates with CommandPost via a JSON WebSocket protocol:

| Message Type | Description |
|-------------|-------------|
| `ping` | Health check |
| `command` | Execute a registered action handler |
| `query` | Query handler info |
| `execute` | Run arbitrary Lua code |
| `batch` | Run multiple operations sequentially |

Every message includes an `auth` field with the session token. Messages without valid authentication are rejected.

### Lua-Side Changes

This fork adds the following to CommandPost's WebSocket message handler (`src/plugins/core/websocket/manager/message-handler.lua`):

1. **`execute` message type** — Compiles and runs Lua code via `load()`, with safe serialization of results (handles tables, userdata, circular references)
2. **`batch` message type** — Runs multiple operations sequentially, passing results between steps via the `_prev` global
3. **Authentication** — Token-based auth with SHA-256 tokens written to a well-known file path
4. **Audit logging** — All incoming messages are logged with timestamps for debugging
5. **Plugin name-only matching** — Fallback matching for transitions and other plugins that lack filesystem paths

### Focus Management

FCP keyboard shortcuts require the app to be frontmost. The `activateFinalCutPro()` helper ensures FCP is active before operations. Menu reads (`getMenuItems()`) are only performed **after** operations to avoid stealing focus. The `withVerification` wrapper captures before/after state including clip counts and undo text via AX-based reads instead of menu reads where possible.

---

## License

MIT — Same as CommandPost.
