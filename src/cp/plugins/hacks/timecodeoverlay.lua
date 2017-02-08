local application		= require("hs.application")
local log				= require("hs.logger").new("timecodeoverlay")

local metadata			= require("cp.metadata")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")

-- Constants:

local PRIORITY 			= 5000
local DEFAULT_VALUE		= false
local PREFERENCES_KEY 	= "FFEnableGuards"

local mod = {}

-- The Module:

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

--- The Plugin:

local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.timeline"] = "timeline",
	["cp.plugins.commands.fcpx"] = "fcpxCmds",
}

function plugin.init(deps)

	deps.timeline:addItem(PRIORITY, function()
		return { title = i18n("enableTimecodeOverlay"),	fn = mod.toggleTimecodeOverlay, checked=mod.isEnabled() }
	end)

	-- Commands
	deps.fcpxCmds:add("FCPXHackToggleTimecodeOverlays")
		:activatedBy():ctrl():option():cmd("t")
		:whenActivated(mod.toggleTimecodeOverlay)

	return mod

end

return plugin