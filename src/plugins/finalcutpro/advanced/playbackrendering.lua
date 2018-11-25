--- === plugins.finalcutpro.advanced.playbackrendering ===
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

--- plugins.finalcutpro.advanced.playbackrendering.enabled <cp.prop: boolean>
--- Variable
--- Gets whether or not Playback Rendering is enabled.
mod.enabled = fcp.preferences:prop(PREFERENCES_KEY, DEFAULT_VALUE)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.advanced.playbackrendering",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel
            --------------------------------------------------------------------------------
            -- Add Preferences Checkbox:
            --------------------------------------------------------------------------------
            :addCheckbox(2204.1,
            {
                label = i18n("enableRenderingDuringPlayback"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = function() return not mod.enabled() end,
            })
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpAllowTasksDuringPlayback")
        :whenActivated(function() mod.enabled:toggle() end)

    return mod

end

return plugin
