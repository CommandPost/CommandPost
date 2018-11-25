--- === plugins.finalcutpro.advanced.showtimelineinplayer ===
---
--- Show Timeline In Player.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp		= require("cp.apple.finalcutpro")
local i18n      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 20

-- DEFAULT_VALUE -> number
-- Constant
-- The Default Value.
local DEFAULT_VALUE = 0

-- PREFERENCES_KEY -> number
-- Constant
-- The Preferences Key.
local PREFERENCES_KEY 	= "FFPlayerDisplayedTimeline"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.advanced.showtimelineinplayer.enabled <cp.prop: boolean; live>
--- Constant
--- Show Timeline in Player Enabled?
mod.enabled = fcp.preferences:prop(PREFERENCES_KEY, DEFAULT_VALUE):mutate(
    function(original) return original() == 1 end,
    function(newValue, original) original(newValue and 1 or 0) end
)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "finalcutpro.advanced.showtimelineinplayer",
    group			= "finalcutpro",
    dependencies	= {
        ["finalcutpro.commands"] 		= "fcpxCmds",
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
            :addCheckbox(2204.2,
            {
                label = i18n("showTimelineInPlayer"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = function() return mod.enabled() end,
            })
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpShowTimelineInPlayer")
            :whenActivated(function() mod.enabled:toggle() end)
    end

    return mod
end

return plugin
