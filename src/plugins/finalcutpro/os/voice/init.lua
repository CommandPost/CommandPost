--- === plugins.finalcutpro.os.voice ===
---
--- Voice Command Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                   = require("hs.logger").new("voice")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local osascript                             = require("hs.osascript")
local speech                                = require("hs.speech")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                = require("cp.config")
local dialog                                = require("cp.dialog")
local fcp                                   = require("cp.apple.finalcutpro")
local prop                                  = require("cp.prop")
local i18n                                  = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY      = 6000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.os.voice.commandTitles -> table
--- Variable
--- Command Titles
mod.commandTitles = {}

--- plugins.finalcutpro.os.voice.commandsByTitle -> table
--- Variable
--- Command By Title
mod.commandsByTitle = {}

--- plugins.finalcutpro.os.voice.openDictationSystemPreferences() -> none
--- Function
--- Open Dictation System Preferences
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.openDictationSystemPreferences()
    osascript.applescript([[
        tell application "System Preferences"
            activate
            reveal anchor "Dictation" of pane "com.apple.preference.speech"
        end tell
    ]])
end

-- listenerCallback(listenerObj, text) -> none
-- Function
-- Listener Callback
--
-- Parameters:
--  * listenerObj - The listener object
--  * text - The text as string
--
-- Returns:
--  * None
local function listenerCallback(_, text)

    local visualAlerts = mod.visualAlertsEnabled()
    local announcements = mod.announcementsEnabled()

    if announcements then
        mod.talker:speak(text)
    end

    if visualAlerts then
        dialog.displayNotification(text)
    end

    mod.activateCommand(text)
end

--- plugins.finalcutpro.os.voice.activateCommand(title) -> none
--- Function
--- Activate Command
---
--- Parameters:
---  * title - The title as a string
---
--- Returns:
---  * None
function mod.activateCommand(title)
    local cmd = mod.commandsByTitle[title]
    if cmd then
        cmd:activated()
    else
        local announcements = mod.announcementsEnabled()
        if announcements then
            mod.talker:speak(i18n("unsupportedVoiceCommand"))
        end
        local visualAlerts = mod.visualAlertsEnabled()
        if visualAlerts then
            dialog.displayNotification(i18n("unsupportedVoiceCommand"))
        end

    end
end

--- plugins.finalcutpro.os.voice.new() -> none
--- Function
--- Creates a new listener.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false` if an errors occurs.
function mod.new()
    if mod.listener == nil then
        mod.listener = speech.listener.new("CommandPost")
        if mod.listener ~= nil then
            mod.listener:foregroundOnly(false)
                           :blocksOtherRecognizers(true)
                           :commands(mod.getCommandTitles())
                           :setCallback(listenerCallback)
        else
            --------------------------------------------------------------------------------
            -- Something went wrong:
            --------------------------------------------------------------------------------
            return false
        end

        mod.talker = speech.new()
    end
    return true
end

--- plugins.finalcutpro.os.voice.start() -> none
--- Function
--- Starts the listener.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false` if an errors occurs.
function mod.start()
    if mod.listener == nil then
        if not mod.new() then
            return false
        end
    end
    if mod.listener ~= nil then
        mod.listener:start()
        return true
    end
    return false
end

--- plugins.finalcutpro.os.voice.stop() -> none
--- Function
--- Stops the listener.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    if mod.listener ~= nil then
        mod.listener:delete()
        mod.listener = nil
        mod.talker = nil
    end
end

--- plugins.finalcutpro.os.voice.listening <cp.prop: boolean>
--- Variable
--- Is the listener listening?
mod.listening = prop.new(function()
    return mod.listener ~= nil and mod.listener:isListening()
end)

--- plugins.finalcutpro.os.voice.update() -> none
--- Function
--- Starts or stops the listener.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        if not mod.listening() then
            local result = mod.new()
            if result == false then
                dialog.displayErrorMessage(i18n("voiceCommandsError"))
                mod.enabled(false)
                return
            end

            if fcp:isFrontmost() then
                mod.start()
            else
                mod.stop()
            end
        end
    else
        if mod.listening() then
            mod.stop()
        end
    end
end

--- plugins.finalcutpro.os.voice.pause() -> none
--- Function
--- Stops the listener.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.pause()
    if mod.listening() then
        mod.stop()
    end
end

--- plugins.finalcutpro.os.voice.getCommandTitles() -> table
--- Function
--- Gets the Command Titles
---
--- Parameters:
---  * None
---
--- Returns:
---  * The command titles as a table.
function mod.getCommandTitles()
    return mod.commandTitles
end

--- plugins.finalcutpro.os.voice.registerCommands(commands) -> none
--- Function
--- Register Commands.
---
--- Parameters:
---  * commands - A table of commands.
---
--- Returns:
---  * The command titles as a table.
function mod.registerCommands(commands)
    local allCmds = commands:getAll()
    for _,cmd in pairs(allCmds) do
        local title = cmd:getTitle()
        if title then
            if mod.commandsByTitle[title] then
                log.w("Multiple commands with the title of '%' registered. Ignoring additional commands.", title)
            else
                mod.commandsByTitle[title] = cmd
                mod.commandTitles[#mod.commandTitles + 1] = title
            end
        end
    end

    table.sort(mod.commandTitles, function(a, b) return a < b end)
end

--- plugins.finalcutpro.os.voice.enabled <cp.prop: boolean>
--- Variable
--- Are Voice Commands Enabled?
mod.enabled = config.prop("enableVoiceCommands", false):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Register Commands:
        --------------------------------------------------------------------------------
        if not mod._registered then
            mod.registerCommands(mod._fcpxCmds)
            mod.registerCommands(mod._globalCmds)
            mod._registered = true
        end
    end
end)

--- plugins.finalcutpro.os.voice.active <cp.prop: boolean; read-only>
--- Variable
--- Are Voice Commands active? This will be true if they are both [enabled](#enabled) and FCP is frontmost.
mod.active = mod.enabled:AND(fcp.app.frontmost):watch(function(active)
    if not active then
        mod.pause()
    end
    mod.update()
end, true)

--- plugins.finalcutpro.os.voice.announcementsEnabled <cp.prop: boolean>
--- Variable
--- Announcements Enabled?
mod.announcementsEnabled = config.prop("voiceCommandEnableAnnouncements", false)

--- plugins.finalcutpro.os.voice.visualAlertsEnabled <cp.prop: boolean>
--- Variable
--- Visual Alerts Enabled?
mod.visualAlertsEnabled = config.prop("voiceCommandEnableVisualAlerts", false)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.os.voice",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.menu.tools"]          = "prefs",
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["core.commands.global"]            = "globalCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._fcpxCmds = deps.fcpxCmds
    mod._globalCmds = deps.globalCmds

    --------------------------------------------------------------------------------
    -- Menu Items:
    --------------------------------------------------------------------------------
    if deps.prefs then
        deps.prefs:addMenu(PRIORITY, function() return i18n("voiceCommands") end)
            :addItem(500, function()
                return { title = i18n("enableVoiceCommands"), fn = function() mod.enabled:toggle() end, checked = mod.enabled() }
            end)
            :addSeparator(600)
            :addItems(1000, function()
                return {
                    { title = i18n("enableAnnouncements"),  fn = function() mod.announcementsEnabled:toggle() end,  checked = mod.announcementsEnabled(), disabled = not mod.enabled() },
                    { title = i18n("enableVisualAlerts"),   fn = function() mod.visualAlertsEnabled:toggle() end,       checked = mod.visualAlertsEnabled(), disabled = not mod.enabled() },
                    { title = "-" },
                    { title = i18n("openDictationPreferences"), fn = mod.openDictationSystemPreferences },
                }
            end)
    end

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpToggleVoiceCommands")
            :whenActivated(function() mod.enabled:toggle() end)
    end

    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    mod.enabled:update()
end

return plugin
