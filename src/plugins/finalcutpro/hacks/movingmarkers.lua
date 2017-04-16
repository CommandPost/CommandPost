--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                M O V I N G   M A R K E R S   P L U G I N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.hacks.movingmarkers ===
---
--- Moving Markers Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("movingmarkers")

local application				= require("hs.application")
local fs						= require("hs.fs")

local config					= require("cp.config")
local fcp						= require("cp.finalcutpro")
local dialog					= require("cp.dialog")
local plist						= require("cp.plist")
local tools						= require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 					= 5
local DEFAULT_VALUE 			= false
local EVENT_DESCRIPTION_PATH 	= "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- ARE MOVING MARKERS ENABLED:
--------------------------------------------------------------------------------
function mod.isEnabled(forceReload)

	local eventDescriptionsPath = fcp:getPath() .. EVENT_DESCRIPTION_PATH
	local modified = fs.attributes(eventDescriptionsPath, "modification")
	if forceReload or modified ~= mod._allowMovingMarkersModified then
		local allowMovingMarkers = DEFAULT_VALUE
		local eventDescriptions = plist.binaryFileToTable(eventDescriptionsPath)
		if eventDescriptions and eventDescriptions["TLKMarkerHandler"] and eventDescriptions["TLKMarkerHandler"]["Configuration"] and eventDescriptions["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"] and type(eventDescriptions["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"]) == "boolean" then
			allowMovingMarkers = eventDescriptions["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"]
		end

		mod._allowMovingMarkers = allowMovingMarkers
		mod._allowMovingMarkersModified = modified
	end

	return _allowMovingMarkers
end

--------------------------------------------------------------------------------
-- TOGGLE MOVING MARKERS:
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.hacks.movingmarkers",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.menu.administrator.advancedfeatures"] = "menu",
		["finalcutpro.commands"] 							= "fcpxCmds",
	}
}

function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Cache status on load:
	--------------------------------------------------------------------------------
	mod.isEnabled()

	--------------------------------------------------------------------------------
	-- Setup Menu:
	--------------------------------------------------------------------------------
	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("enableMovingMarkers"),	fn = mod.toggleMovingMarkers, checked=mod.isEnabled() }
	end)

	:addSeparator(PRIORITY + 1)

	--------------------------------------------------------------------------------
	-- Setup Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpToggleMovingMarkers")
		:groupedBy("hacks")
		:activatedBy():ctrl():option():cmd("y")
		:whenActivated(mod.toggleMovingMarkers)

	return mod

end

return plugin