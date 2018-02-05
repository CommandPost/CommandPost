--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               S H O W   T I M E L I N E   I N   P L A Y E R                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.viewer.showtimelineinplayer ===
---
--- Show Timeline In Player.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local prop				= require("cp.prop")

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

--- plugins.finalcutpro.viewer.showtimelineinplayer.enabled <cp.prop: boolean>
--- Variable
--- Show Timeline in Player Enabled?
mod.enabled = prop.new(
	function()
		local value = fcp:getPreference(PREFERENCES_KEY, DEFAULT_VALUE)
		if value == 1 then
			value = true
		else
			value = false
		end
		return value
	end,

	function(value)

		if value then
			value = 1
		else
			value = 0
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		if fcp:setPreference(PREFERENCES_KEY, value) == nil then
			dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
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
	id				= "finalcutpro.viewer.showtimelineinplayer",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.menu.viewer"]		= "menu",
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
        deps.menu:addItem(PRIORITY, function()
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