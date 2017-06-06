--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               S H O W   T I M E L I N E   I N   P L A Y E R                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.viewer.showtimecode ===
---
--- Show Timeline In Player.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("showtimecode")

local application		= require("hs.application")

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local config			= require("cp.config")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 20
local DEFAULT_VALUE		= 0
local PREFERENCES_KEY 	= "FFPlayerDisplayedTimecode"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.enabled = prop.new(
	function()
		return fcp:getPreference(PREFERENCES_KEY, DEFAULT_VALUE)
	end,

	function(value)

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local running = fcp:isRunning()
		if running and not dialog.displayYesNoQuestion(i18n("togglingTimecodeOverlayRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
			return
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		if fcp:setPreference(PREFERENCES_KEY, value) == nil then
			dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
			return
		end

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

local function toggle(value)

	if mod.enabled() == value then
		mod.enabled:set(0)
	else
		mod.enabled:set(value)
	end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.viewer.showtimecode",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.menu.viewer.showtimecode"]		= "menu",
		["finalcutpro.commands"] 						= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("showProjectTimecodeTop"),	fn = function() toggle(3) end, checked=mod.enabled() == 3 }
	end)

	deps.menu:addItem(PRIORITY + 1, function()
		return { title = i18n("showProjectTimecodeBottom"),	fn = function() toggle(4) end, checked=mod.enabled() == 4 }
	end)

	deps.menu:addItem(PRIORITY + 2, function()
		return { title = "-" }
	end)

	deps.menu:addItem(PRIORITY + 3, function()
		return { title = i18n("showSourceTimecodeTop"),	fn = function() toggle(1) end, checked=mod.enabled() == 1 }
	end)

	deps.menu:addItem(PRIORITY + 4, function()
		return { title = i18n("showSourceTimecodeBottom"),	fn = function() toggle(2) end, checked=mod.enabled() == 2 }
	end)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpShowProjectTimecodeTop")
		:groupedBy("hacks")
		:whenActivated(function() toggle(3) end)

	deps.fcpxCmds:add("cpShowProjectTimecodeBottom")
		:groupedBy("hacks")
		:whenActivated(function() toggle(4) end)

	deps.fcpxCmds:add("cpShowSourceTimecodeTop")
		:groupedBy("hacks")
		:whenActivated(function() toggle(1) end)

	deps.fcpxCmds:add("cpShowSourceTimecodeBottom")
		:groupedBy("hacks")
		:whenActivated(function() toggle(2) end)

	return mod

end

return plugin