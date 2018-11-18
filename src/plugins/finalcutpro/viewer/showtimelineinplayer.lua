--- === plugins.finalcutpro.viewer.showtimelineinplayer ===
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

--- plugins.finalcutpro.viewer.showtimelineinplayer.enabled <cp.prop: boolean; live>
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
    id				= "finalcutpro.viewer.showtimelineinplayer",
    group			= "finalcutpro",
    dependencies	= {
        ["finalcutpro.menu.manager"]	= "menu",
        ["finalcutpro.commands"] 		= "fcpxCmds",
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
        deps.menu.viewer:addItem(PRIORITY, function()
            return { title = i18n("showTimelineInPlayer"),	fn = function() mod.enabled:toggle() end, checked=mod.enabled() }
        end)
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpShowTimelineInPlayer")
            :groupedBy("hacks")
            :whenActivated(function() mod.enabled:toggle() end)
    end

    return mod
end

return plugin
