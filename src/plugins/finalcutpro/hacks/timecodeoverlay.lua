--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              T I M E C O D E    O V E R L A Y    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.hacks.timecodeoverlay ===
---
--- Timecode Overlay.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("timecodeoverlay")

local application		= require("hs.application")

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local config			= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 5000
local DEFAULT_VALUE		= false
local PREFERENCES_KEY 	= "FFEnableGuards"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.isEnabled()
	local FFEnableGuards = DEFAULT_VALUE
	local preferences = fcp:getPreferences()
	if preferences and preferences[PREFERENCES_KEY] then
		FFEnableGuards = preferences[PREFERENCES_KEY]
	end
	return FFEnableGuards
end

function mod.toggleTimecodeOverlay()

	--------------------------------------------------------------------------------
	-- Get existing value:
	--------------------------------------------------------------------------------
	local FFEnableGuards = mod.isEnabled()

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartStatus = false
	if fcp:isRunning() then
		if dialog.displayYesNoQuestion(i18n("togglingTimecodeOverlayRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
			restartStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Update plist:
	--------------------------------------------------------------------------------
	local result = fcp:setPreference(PREFERENCES_KEY, not FFEnableGuards)
	if result == nil then
		dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if restartStatus then
		if not fcp:restart() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			dialog.displayErrorMessage(i18n("failedToRestart"))
			return "Failed"
		end
	end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.hacks.timecodeoverlay",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.menu.timeline"]	= "menu",
		["finalcutpro.commands"] 		= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("enableTimecodeOverlay"),	fn = mod.toggleTimecodeOverlay, checked=mod.isEnabled() }
	end)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpToggleTimecodeOverlays")
		:groupedBy("hacks")
		:activatedBy():ctrl():option():cmd("t")
		:whenActivated(mod.toggleTimecodeOverlay)

	return mod

end

return plugin