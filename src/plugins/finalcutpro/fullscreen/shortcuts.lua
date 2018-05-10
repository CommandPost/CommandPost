--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 F U L L S C R E E N     S H O R T C U T S                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.fullscreen.shortcuts ===
---
--- Fullscreen Shortcuts

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("fullscreenShortcuts")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap                          = require("hs.eventtap")
local timer                             = require("hs.timer")
local timer                             = require("hs.timer")
local window                            = require("hs.window")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                               = require("cp.apple.finalcutpro")
local config                            = require("cp.config")
local shortcut                          = require("cp.commands.shortcut")
local tools                             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- DEFAULT_VALUE
-- Constant
-- Whether or not this plugin is enabled by default.
local DEFAULT_VALUE = false

-- FULLSCREEN_KEYS
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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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
    if mod.enabled() and fcp:fullScreenWindow():isShowing() then
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
mod.enabled = config.prop("enableShortcutsDuringFullscreenPlayback", DEFAULT_VALUE):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Watch for the full screen window:
        --------------------------------------------------------------------------------
        if not mod._fcpFullScreenWindowWatcher then
            mod._fcpFullScreenWindowWatcher = fcp:fullScreenWindow():watch({
                show    = mod.update,
                hide    = mod.update,
            })
        end

        mod.watcherWorking = false

        if not mod.keyUpWatcher then
            mod.keyUpWatcher = eventtap.new({ eventtap.event.types.keyUp }, function()
                timer.doAfter(0.0000001, function()
                    mod.watcherWorking = false
                end)
            end)
        end

        if not mod.keyDownWatcher then
            mod.keyDownWatcher = eventtap.new({ eventtap.event.types.keyDown }, function(event)
                timer.doAfter(0.0000001, function() mod.checkCommand(event:getFlags(), event:getKeyCode()) end)
            end)
        end

        mod.update()
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        if mod._fcpFullScreenWindowWatcher and mod._fcpFullScreenWindowWatcher.id then
            fcp:fullScreenWindow():unwatch(mod._fcpFullScreenWindowWatcher.id)
            mod._fcpFullScreenWindowWatcher = nil
        end
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
    eventtap.keyStroke({""}, "escape")

    --------------------------------------------------------------------------------
    -- Perform Keystroke:
    --------------------------------------------------------------------------------
    eventtap.keyStroke(whichModifier, whichKey)

    --------------------------------------------------------------------------------
    -- Go back to Full Screen Playback:
    --------------------------------------------------------------------------------
    fcp:performShortcut("PlayFullscreen")
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
    if chars and chars ~= "" and whichKey == shortcut.textToKeyCode(chars) and tools.modifierMatch(whichModifier, cmd['modifiers']) then
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
    if fcp:fullScreenWindow():isShowing() then

        --------------------------------------------------------------------------------
        -- Get Active Command Set:
        --------------------------------------------------------------------------------
        local activeCommandSet = fcp:getActiveCommandSet()
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

--- plugins.finalcutpro.fullscreen.shortcuts.updateDockIcon() -> none
--- Function
--- Update Dock Icon Visibility. Dock Icon will be disabled when FCPX is in fullscreen mode.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateDockIcon()
    if mod._ignoreWatchers then
        return
    end
    if fcp:isFrontmost() then
        local ui = fcp:primaryWindow():UI()
        local primaryWindow = ui and ui:asHSWindow()
        if primaryWindow and primaryWindow:isFullScreen() then
            if hs.dockIcon() then
                --log.df("Fullscreen detected")
                mod._ignoreWatchers = true
                hs.dockIcon(false)
                timer.doAfter(0.3, function()
                    fcp:launch()
                    mod._ignoreWatchers = false
                end)
            end
            return
        elseif primaryWindow and not primaryWindow:isFullScreen() then
            if not hs.dockIcon() then
                --log.df("Fullscreen NOT detected")
                mod._ignoreWatchers = true
                local originalFocusedWindow = window.focusedWindow()
                hs.dockIcon(true)
                timer.doAfter(0.3, function()
                    if originalFocusedWindow then
                        originalFocusedWindow:focus()
                    end
                    mod._ignoreWatchers = false
                end)
            end
        end
    else
        if not hs.dockIcon() then
            --log.df("Fullscreen NOT detected")
            mod._ignoreWatchers = true
            local originalFocusedWindow = window.focusedWindow()
            hs.dockIcon(true)
            timer.doAfter(0.3, function()
                if originalFocusedWindow then
                    originalFocusedWindow:focus()
                end
                mod._ignoreWatchers = false
            end)
        end
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.fullscreen.shortcuts",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.app"] = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Watchers:
    --------------------------------------------------------------------------------
    mod._fcpWatcher = fcp:watch({
        fullscreen  = mod.updateDockIcon,
        inactive    = mod.updateDockIcon,
        hide        = mod.updateDockIcon,
        active      = mod.updateDockIcon,
        show        = mod.updateDockIcon,
    })

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel
            --------------------------------------------------------------------------------
            -- Add Preferences Checkbox:
            --------------------------------------------------------------------------------
            :addCheckbox(1.2,
            {
                label = i18n("enableShortcutsDuringFullscreen"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = mod.enabled,
            }
        )
    end

    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Check to see if we started in fullscreen mode:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    --------------------------------------------------------------------------------
    -- Update Dock Icon:
    --------------------------------------------------------------------------------
    mod.updateDockIcon()
end

return plugin