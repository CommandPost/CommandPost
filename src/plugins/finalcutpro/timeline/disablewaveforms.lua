--- === plugins.finalcutpro.timeline.disablewaveforms ===
---
--- Disable Waveforms Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 10001

-- DEFAULT_VALUE -> boolean
-- Constant
-- Whether or not the feature is enabled by default.
local DEFAULT_VALUE = false

-- PREFERENCES_KEY -> number
-- Constant
-- Preferences key
local PREFERENCES_KEY = "FFAudioDisableWaveformDrawing"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.disablewaveforms.enabled <cp.prop: boolean>
--- Variable
--- Whether or not Waveforms are enabled.
mod.enabled = fcp.preferences:prop(PREFERENCES_KEY, DEFAULT_VALUE):mutate(
    function(original) return original() end,
    function(newValue, original)
        if newValue == original() then
            -- No change
            return
        end
        --------------------------------------------------------------------------------
        -- If Final Cut Pro is running...
        --------------------------------------------------------------------------------
        local running = fcp:isRunning()
        if running and not dialog.displayYesNoQuestion(i18n("togglingWaveformsRestart"), i18n("doYouWantToContinue")) then
            return
        end

        --------------------------------------------------------------------------------
        -- Set Preference:
        --------------------------------------------------------------------------------
        original(newValue)

        --------------------------------------------------------------------------------
        -- Restart Final Cut Pro:
        --------------------------------------------------------------------------------
        if running and not fcp:restart() then
            --------------------------------------------------------------------------------
            -- Failed to restart Final Cut Pro:
            --------------------------------------------------------------------------------
            dialog.displayErrorMessage(i18n("failedToRestart"))
            return
        end

    end
)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.timeline.disablewaveforms",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.menu.timeline"]   = "menu",
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Menu:
    --------------------------------------------------------------------------------
    if deps.menu then
        deps.menu
            :addItem(PRIORITY, function()
                return { title = i18n("enableWaveformDrawing"), fn = function() mod.enabled:toggle() end, checked=not mod.enabled() }
            end)
    end

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpDisableWaveforms")
            :groupedBy("hacks")
            :whenActivated(function() mod.enabled:toggle() end)
    end

    return mod

end

return plugin
