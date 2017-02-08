local application		= require("hs.application")
local log				= require("hs.logger").new("timecodeoverlay")

local metadata			= require("cp.metadata")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")

-- Constants

local PRIORITY = 1

local mod = {}

-- Local Functions



-- The Module

function mod.isEnabled()
	local preferences = fcp:getPreferences()
	local FFEnableGuards = false
	if preferences["FFEnableGuards"] then
		FFEnableGuards = preferences["FFEnableGuards"]
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
	local result = fcp:setPreference("FFEnableGuards", not FFEnableGuards)
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
	["cp.plugins.menu.tools"] = "tools",
}

function plugin.init(deps)

	deps.tools:addItem(PRIORITY, function()
		return { title = i18n("enableTimecodeOverlay"),	fn = mod.toggleTimecodeOverlay, checked=mod.isEnabled() }
	end)

	return mod

end

return plugin

--[[
{ title = i18n("enableHacksShortcuts"), 													fn = toggleEnableHacksShortcutsInFinalCutPro, 						checked = enableHacksShortcutsInFinalCutPro},
{ title = "-" },
{ title = i18n("enableTimecodeOverlay"), 													fn = toggleTimecodeOverlay, 										checked = mod.FFEnableGuards },
{ title = i18n("enableMovingMarkers"), 														fn = toggleMovingMarkers, 											checked = mod.allowMovingMarkers },
{ title = i18n("enableRenderingDuringPlayback"),											fn = togglePerformTasksDuringPlayback, 								checked = not mod.FFSuspendBGOpsDuringPlay },
{ title = "-" },
{ title = i18n("changeBackupInterval") .. " (" .. tostring(mod.FFPeriodicBackupInterval) .. " " .. i18n("mins") .. ")", fn = changeBackupInterval },
{ title = i18n("changeSmartCollectionLabel"),												fn = changeSmartCollectionsLabel },
--]]