--- === plugins.finalcutpro.hacks.playbackrendering ===
---
--- Playback Rendering Plugin.

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
local prop              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY
-- Constant
-- The menubar position priority.
local PRIORITY = 5500

-- DEFAULT_VALUE
-- Constant
-- Whether or not the plugin is enabled by default.
local DEFAULT_VALUE = false

-- PREFERENCES_KEY
-- Constant
-- Preferences Key
local PREFERENCES_KEY   = "FFSuspendBGOpsDuringPlay"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.hacks.playbackrendering.enabled <cp.prop: boolean>
--- Variable
--- Gets whether or not Playback Rendering is enabled.
mod.enabled = prop.new(
    function()
        --------------------------------------------------------------------------------
        -- Get Preference:
        --------------------------------------------------------------------------------
        return fcp:getPreference(PREFERENCES_KEY, DEFAULT_VALUE)
    end,

    function(value)
        --------------------------------------------------------------------------------
        -- Set Preference:
        --------------------------------------------------------------------------------
        fcp:setPreference(PREFERENCES_KEY, value)
    end
)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hacks.playbackrendering",
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
    deps.menu
        :addItem(PRIORITY, function()
            return { title = i18n("enableRenderingDuringPlayback"), fn = function() mod.enabled:toggle() end, checked=not mod.enabled() }
        end)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpAllowTasksDuringPlayback")
        :groupedBy("hacks")
        :activatedBy():ctrl():option():cmd("p")
        :whenActivated(function() mod.enabled:toggle() end)

    return mod

end

return plugin
