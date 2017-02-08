local application		= require("hs.application")
local log				= require("hs.logger").new("movingmarkers")

local metadata			= require("cp.metadata")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")
local plist				= require("cp.plist")
local tools				= require("cp.tools")

-- Constants

local PRIORITY = 5
local DEFAULT_VALUE = false
local EVENT_DESCRIPTION_PATH = "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist"

local mod = {}

-- The Module

function mod.isEnabled()

	local allowMovingMarkers = DEFAULT_VALUE

	local eventDescriptionsPath = fcp:getPath() .. EVENT_DESCRIPTION_PATH
	local eventDescriptions = plist.binaryFileToTable(eventDescriptionsPath)

	if eventDescriptions and eventDescriptions["TLKMarkerHandler"] and eventDescriptions["TLKMarkerHandler"]["Configuration"] and eventDescriptions["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"] and type(eventDescriptions["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"]) == "boolean" then
		allowMovingMarkers = eventDescriptions["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"]
	end

	return allowMovingMarkers

end

function mod.toggleMovingMarkers()

	--------------------------------------------------------------------------------
	-- Get existing value:
	--------------------------------------------------------------------------------
	local allowMovingMarkers = mod.isEnabled()

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartStatus = false
	if fcp:isRunning() then
		if dialog.displayYesNoQuestion(i18n("togglingMovingMarkersRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
			restartStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Update plist:
	--------------------------------------------------------------------------------
	if allowMovingMarkers then
		local result = tools.executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' false\" ']] .. fcp:getPath() .. EVENT_DESCRIPTION_PATH .. "'")
		if type(result) == "string" then
			dialog.displayErrorMessage(result)
		end
	else
		local result = tools.executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' true\" ']] .. fcp:getPath() .. EVENT_DESCRIPTION_PATH .. "'")
		if type(result) == "string" then
			dialog.displayErrorMessage(result)
		end
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
	["cp.plugins.menu.administrator.advancedfeatures"] = "advancedfeatures",
	["cp.plugins.commands.fcpx"] = "fcpxCmds",
}

function plugin.init(deps)

	deps.advancedfeatures:addItem(PRIORITY, function()
		return { title = i18n("enableMovingMarkers"),	fn = mod.toggleMovingMarkers, checked=mod.isEnabled() }
	end)

	:addSeparator(PRIORITY + 1)

	-- Commands
	deps.fcpxCmds:add("cpToggleMovingMarkers")
		:activatedBy():ctrl():option():cmd("y")
		:whenActivated(mod.toggleMovingMarkers)

	return mod

end

return plugin