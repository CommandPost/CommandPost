--- === plugins.finalcutpro.fullscreen.shortcuts ===
---
--- Fullscreen Shortcuts

local require               = require

local eventtap              = require "hs.eventtap"
local timer                 = require "hs.timer"

local commandeditor         = require "cp.apple.commandeditor"
local config                = require "cp.config"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local shortcut              = require "cp.commands.shortcut"

local doAfter               = timer.doAfter

local mod = {}

-- FULLSCREEN_KEYS -> table
-- Constant
-- Supported Full Screen Keys
local FULLSCREEN_KEYS = {
    "Unfavorite",
    "Favorite",
    "SetSelectionStart",
    "SetSelectionEnd",
    "AnchorWithSelectedMedia",
    "AnchorWithSelectedMediaAudioBacktimed",
    "InsertMedia",
    "AppendWithSelectedMedia"
}

--- plugins.finalcutpro.fullscreen.shortcuts.update() -> none
--- Function
--- Toggles the watches for monitoring fullscreen playback.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() and fcp.fullScreenPlayer:isShowing() then
        if mod.keyUpWatcher then
            mod.keyUpWatcher:start()
        end
        if mod.keyDownWatcher then
            mod.keyDownWatcher:start()
        end
    else
        if mod.keyUpWatcher then
            mod.keyUpWatcher:stop()
        end
        if mod.keyDownWatcher then
            mod.keyDownWatcher:stop()
        end
    end
end

--- plugins.finalcutpro.fullscreen.shortcuts.enabled <cp.prop: boolean>
--- Variable
--- Is the module enabled?
mod.enabled = config.prop("enableShortcutsDuringFullscreenPlayback", false):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Watch for the full screen window:
        --------------------------------------------------------------------------------
        fcp.fullScreenPlayer.isFullScreen:watch(mod.update)

        mod.watcherWorking = false

        if not mod.keyUpWatcher then
            mod.keyUpWatcher = eventtap.new({ eventtap.event.types.keyUp }, function()
                doAfter(0.0000001, function()
                    mod.watcherWorking = false
                end)
            end)
        end

        if not mod.keyDownWatcher then
            mod.keyDownWatcher = eventtap.new({ eventtap.event.types.keyDown }, function(event)
                doAfter(0.0000001, function() mod.checkCommand(event:getFlags(), event:getKeyCode()) end)
            end)
        end

        mod.update()
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.fullScreenPlayer.isFullScreen:unwatch(mod.update)
        if mod.keyUpWatcher then
            mod.keyUpWatcher:stop()
            mod.keyUpWatcher = nil
        end
        if mod.keyDownWatcher then
            mod.keyDownWatcher:stop()
            mod.keyDownWatcher = nil
        end
        mod.watcherWorking = nil
    end
end)

--- plugins.finalcutpro.fullscreen.shortcuts.ninjaKeyStroke(whichModifier, whichKey) -> none
--- Function
--- Performs a Ninja Key Stoke.
---
--- Parameters:
---  * whichModifier - Modifier Key
---  * whichKey - Key
---
--- Returns:
---  * None
function mod.ninjaKeyStroke(whichModifier, whichKey)
    --------------------------------------------------------------------------------
    -- Press 'Escape':
    --------------------------------------------------------------------------------
    fcp:keyStroke({}, "escape")

    --------------------------------------------------------------------------------
    -- Perform Keystroke:
    --------------------------------------------------------------------------------
    fcp:keyStroke(whichModifier, whichKey)

    --------------------------------------------------------------------------------
    -- Go back to Full Screen Playback:
    --------------------------------------------------------------------------------
    fcp:doShortcut("PlayFullscreen"):Now()
end

--- plugins.finalcutpro.fullscreen.shortcuts.performCommand(cmd, whichModifier, whichKey) -> boolean
--- Function
--- Performs a command.
---
--- Parameters:
---  * cmd - The Command.
---  * whichModifier - Which modifier key to check.
---  * whichKey - Which key to check.
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.performCommand(cmd, whichModifier, whichKey)
    local chars = cmd['characterString']
    if chars and chars ~= "" and whichKey == shortcut.textToKeyCode(chars) and commandeditor.modifierMatch(whichModifier, cmd['modifiers']) then
        --------------------------------------------------------------------------------
        -- Perform the keystroke:
        --------------------------------------------------------------------------------
        --log.df("performing command: %s", hs.inspect(cmd))
        mod.ninjaKeyStroke(whichModifier, whichKey)
        return true
    end
    return false
end

--- plugins.finalcutpro.fullscreen.shortcuts.checkCommand(whichModifier, whichKey) -> none
--- Function
--- Checks to see if a shortcut has been pressed, then processes.
---
--- Parameters:
---  * whichModifier - Which modifier key to check.
---  * whichKey - Which key to check.
---
--- Returns:
---  * None
function mod.checkCommand(whichModifier, whichKey)
    --------------------------------------------------------------------------------
    -- Don't repeat if key is held down:
    --------------------------------------------------------------------------------
    if mod.watcherWorking then
        --log.df("plugins.fullscreen.shortcuts.checkCommand() already in progress.")
        return false
    end
    mod.watcherWorking = true

    --------------------------------------------------------------------------------
    -- Only Continue if in Full Screen Playback Mode:
    --------------------------------------------------------------------------------
    if fcp.fullScreenPlayer:isShowing() then

        --------------------------------------------------------------------------------
        -- Get Active Command Set:
        --------------------------------------------------------------------------------
        local activeCommandSet = fcp:activeCommandSet()
        if type(activeCommandSet) ~= "table" then
            --log.df("Failed to get Active Command Set. Error occurred in plugins.fullscreen.shortcuts.checkCommand().")
            return
        end

        --------------------------------------------------------------------------------
        -- Key Detection:
        --------------------------------------------------------------------------------
        for _, whichShortcutKey in pairs(FULLSCREEN_KEYS) do
            local selectedCommandSet = activeCommandSet[whichShortcutKey]

            if selectedCommandSet then
                if selectedCommandSet[1] and type(selectedCommandSet[1]) == "table" then
                    --------------------------------------------------------------------------------
                    -- There are multiple shortcut possibilities for this command:
                    --------------------------------------------------------------------------------
                    for _,cmd in ipairs(selectedCommandSet) do
                        if mod.performCommand(cmd, whichModifier, whichKey) then
                            -- All done
                            return
                        end
                    end
                else
                    --------------------------------------------------------------------------------
                    -- There is only a single shortcut possibility for this command:
                    --------------------------------------------------------------------------------
                    if mod.performCommand(selectedCommandSet, whichModifier, whichKey) then
                        -- All done
                        return
                    end
                end
            end
        end

    end
end

local plugin = {
    id              = "finalcutpro.fullscreen.shortcuts",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel
            --------------------------------------------------------------------------------
            -- Add Preferences Checkbox:
            --------------------------------------------------------------------------------
            :addCheckbox(1.01,
            {
                label = i18n("enableShortcutsDuringFullscreen"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = mod.enabled,
            }
        )
    end

    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Check to see if we started in fullscreen mode:
    --------------------------------------------------------------------------------
    if mod.enabled then
        mod.enabled:update()
    end
end

return plugin
