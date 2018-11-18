--- === plugins.finalcutpro.hacks.playbackrendering ===
---
--- Playback Rendering Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")

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
mod.enabled = fcp.preferences:prop(PREFERENCES_KEY, DEFAULT_VALUE)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hacks.playbackrendering",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.menu.manager"]    = "menu",
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
    deps.menu.timeline
        :addItem(PRIORITY, function()
            return { title = i18n("enableRenderingDuringPlayback"), fn = function() mod.enabled:toggle() end, checked=not mod.enabled() }
        end)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpAllowTasksDuringPlayback")
        :groupedBy("hacks")
        :whenActivated(function() mod.enabled:toggle() end)

    return mod

end

return plugin
