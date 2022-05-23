--- === plugins.core.loupedeckplugin ===
---
--- General/macOS Loupedeck Plugin Actions

local require           = require

local log               = require "hs.logger".new "ldPlugin"

local osascript         = require "hs.osascript"
local shortcuts         = require "hs.shortcuts"
local spaces            = require "hs.spaces"
local plist             = require "hs.plist"

local config            = require "cp.config"
local json              = require "cp.json"
local tools             = require "cp.tools"

local semver            = require "semver"

local applescript       = osascript.applescript
local tableCount        = tools.tableCount

local mod = {}

-- makeFunctionHandler(fn) -> function
-- Function
-- Creates a 'handler' for triggering a function.
--
-- Parameters:
--  * fn - the function you want to trigger.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeFunctionHandler(fn)
    return function()
        fn()
    end
end

-- requestShortcuts() -> function
-- Function
-- Sends the LoupedeckConfig application a list of macOS Shortcuts.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function requestShortcuts()
    --------------------------------------------------------------------------------
    -- Get a list of macOS Shortcuts:
    --------------------------------------------------------------------------------
    local shortcutsForLoupedeck = {}
    local shortcutsList = shortcuts.list()
    for _, item in pairs(shortcutsList) do
        shortcutsForLoupedeck[item.name] = item.name
    end

    --------------------------------------------------------------------------------
    -- Send a WebSocket Message back to Loupedeck if there are shortcuts:
    --------------------------------------------------------------------------------
    if tableCount(shortcutsForLoupedeck) >= 1 then
        local message = {
            ["MessageType"] = "UpdateCommands",
            ["ActionName"] = "macOS.Shortcuts",
            ["ActionValue"] = json.encode(shortcutsForLoupedeck),
        }
        local encodedMessage = json.encode(message, true)
        mod.manager.sendMessage(encodedMessage)
    end
end

-- requestKeyboardMaestro() -> function
-- Function
-- Sends the LoupedeckConfig application a list of Keyboard Maestro macros.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function requestKeyboardMaestro()
    --------------------------------------------------------------------------------
    -- Get a list of Keyboard Maestro Macros:
    --------------------------------------------------------------------------------
    local keyboardMaestroMacros = {}
    local preferencesPath = "~/Library/Application Support/Keyboard Maestro/Keyboard Maestro Macros.plist"
    local prefs = plist.read(preferencesPath)
    local macroGroups = prefs and prefs.MacroGroups
    if macroGroups then
        for _, v in pairs(macroGroups) do
            local groupName = v.Name
            if v.Macros then
                for _, vv in pairs(v.Macros) do
                    local name = vv.Name
                    local uid = vv.UID
                    if name and uid then
                        mod.keyboardMaestroLookup[name] = uid
                        keyboardMaestroMacros[name] = name
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Send a WebSocket Message back to Loupedeck if there are macros:
    --------------------------------------------------------------------------------
    if tableCount(keyboardMaestroMacros) >= 1 then
        local message = {
            ["MessageType"] = "UpdateCommands",
            ["ActionName"] = "KeyboardMaestro",
            ["ActionValue"] = json.encode(keyboardMaestroMacros),
        }
        local encodedMessage = json.encode(message, true)
        mod.manager.sendMessage(encodedMessage)
    end
end

-- triggerShortcut(data) -> function
-- Function
-- Triggers a macOS shortcut.
--
-- Parameters:
--  * data - The data from the Loupedeck Plugin
--
-- Returns:
--  * None
local function triggerShortcut(data)
    local name = data.actionValue
    if name then
        shortcuts.run(name)
    end
end

-- triggerKeyboardMaestroMacro(data) -> function
-- Function
-- Triggers a Keyboard Maestro Macro.
--
-- Parameters:
--  * data - The data from the Loupedeck Plugin
--
-- Returns:
--  * None
local function triggerKeyboardMaestroMacro(data)
    local name = data.actionValue
    local uid = name and mod.keyboardMaestroLookup[name]
    if uid then
        applescript([[tell application "Keyboard Maestro Engine"
        do script "]] .. uid .. [["
        end tell]])
    end
end

-- plugins.core.loupedeckplugin.manager._registerActions(manager) -> none
-- Function
-- A private function to register actions.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._registerActions()
    --------------------------------------------------------------------------------
    -- Only run once:
    --------------------------------------------------------------------------------
    if mod._registerActionsRun then return end
    mod._registerActionsRun = true

    --------------------------------------------------------------------------------
    -- Setup Dependancies:
    --------------------------------------------------------------------------------
    local registerAction = mod.manager.registerAction

    --------------------------------------------------------------------------------
    -- macOS Spaces:
    --------------------------------------------------------------------------------
    registerAction("MoveLeftASpace", makeFunctionHandler(function() tools.keyStroke({"ctrl"}, "left", nil, true) end))
    registerAction("MoveRightASpace", makeFunctionHandler(function() tools.keyStroke({"ctrl"}, "right", nil, true) end))
    registerAction("ToggleMissionControl", makeFunctionHandler(function() spaces.toggleMissionControl() end))
    registerAction("ToggleShowDesktop", makeFunctionHandler(function() spaces.toggleShowDesktop() end))
    registerAction("ToggleAppExpose", makeFunctionHandler(function() spaces.toggleAppExpose() end))
    registerAction("ToggleLaunchPad", makeFunctionHandler(function() spaces.toggleLaunchPad() end))

    --------------------------------------------------------------------------------
    -- macOS Shortcuts:
    --------------------------------------------------------------------------------
    local macOSVersion = semver(tools.macOSVersion())
    local macOSMonterey = semver("12.0.0")
    local shortcutsEnabled = config.prop("macosshortcuts.enabled", false)
    if macOSVersion >= macOSMonterey and shortcutsEnabled then
        registerAction("RequestShortcuts", requestShortcuts)
        registerAction("macOS.Shortcuts", triggerShortcut)
    end

    --------------------------------------------------------------------------------
    -- Keyboard Maestro:
    --------------------------------------------------------------------------------
    mod.keyboardMaestroLookup = {}
    registerAction("RequestKeyboardMaestro", requestKeyboardMaestro)
    registerAction("KeyboardMaestro", triggerKeyboardMaestroMacro)

end

local plugin = {
    id          = "core.loupedeckplugin",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.loupedeckplugin.manager"]                = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Manage Dependencies:
    --------------------------------------------------------------------------------
    mod.manager             = deps.manager

    --------------------------------------------------------------------------------
    -- Add actions:
    --------------------------------------------------------------------------------
    mod.manager.enabled:watch(function(enabled)
        if enabled then
            mod._registerActions()
        end
    end)

    return mod
end

return plugin
