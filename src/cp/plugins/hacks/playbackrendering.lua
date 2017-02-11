local application		= require("hs.application")
local log				= require("hs.logger").new("playbackrendering")

local metadata			= require("cp.metadata")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")
local plist				= require("cp.plist")
local tools				= require("cp.tools")

-- Constants

local PRIORITY 			= 5500
local DEFAULT_VALUE		= false
local PREFERENCES_KEY 	= "FFSuspendBGOpsDuringPlay"

local mod = {}

-- The Module

function mod.isEnabled()

	local FFSuspendBGOpsDuringPlay = DEFAULT_VALUE
	local preferences = fcp:getPreferences()
	if preferences and preferences[PREFERENCES_KEY] then
		FFSuspendBGOpsDuringPlay = preferences[PREFERENCES_KEY]
	end
	return FFSuspendBGOpsDuringPlay

end

function mod.togglePerformTasksDuringPlayback()

	--------------------------------------------------------------------------------
	-- Get existing value:
	--------------------------------------------------------------------------------
	local FFSuspendBGOpsDuringPlay = mod.isEnabled()

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartStatus = false
	if fcp:isRunning() then
		if dialog.displayYesNoQuestion(i18n("togglingBackgroundTasksRestart") .. "\n\n" ..i18n("doYouWantToContinue")) then
			restartStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Update plist:
	--------------------------------------------------------------------------------
	local result = fcp:setPreference(PREFERENCES_KEY, not FFSuspendBGOpsDuringPlay)
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
		return { title = i18n("enableRenderingDuringPlayback"),	fn = mod.togglePerformTasksDuringPlayback, checked=mod.isEnabled() }
	end)

	-- Commands
	deps.fcpxCmds:add("cpAllowTasksDuringPlayback")
		:activatedBy():ctrl():option():cmd("p")
		:whenActivated(mod.togglePerformTasksDuringPlayback)

	return mod

end

return plugin