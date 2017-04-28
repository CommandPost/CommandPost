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

local fcp						= require("cp.apple.finalcutpro")
local dialog					= require("cp.dialog")
local plist						= require("cp.plist")
local tools						= require("cp.tools")
local prop						= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 					= 5
local DEFAULT_VALUE 			= false
local EVENT_DESCRIPTION_PATH 	= "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist"
local PLIST_BUDDY				= "/usr/libexec/PlistBuddy"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local function getValue(source, property, ...)
	if source == nil or property == nil then
		return source
	else
		local value = source[property]
		return value ~= nil and getValue(value, ...) or nil
	end
end

local function saveMovingMarkers(enabled)
	local cmd = string.format([[%s -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' %s\" '%s']], PLIST_BUDDY, enabled, fcp:getPath() .. EVENT_DESCRIPTION_PATH)
	local result = tools.executeWithAdministratorPrivileges(cmd)
	if type(result) == "string" then
		dialog.displayErrorMessage(result)
		return false
	end
	return true
end

--------------------------------------------------------------------------------
-- ARE MOVING MARKERS ENABLED:
--------------------------------------------------------------------------------
mod.enabled = prop.new(
	function()
		if fcp:isInstalled() then
			local eventDescriptionsPath = fcp:getPath() .. EVENT_DESCRIPTION_PATH
			local modified = fs.attributes(eventDescriptionsPath, "modification")
			if modified ~= mod._modified then
				local eventDescriptions = plist.binaryFileToTable(eventDescriptionsPath)
				local allow = getValue(eventDescriptions, "TLKMarkerHandler", "Configuration", "Allow Moving Markers") or DEFAULT_VALUE

				mod._enabled = allow
				mod._modified = modified
			end

			return mod._enabled
		end
		return false
	end,
	
	function(allowMovingMarkers)
		if not fcp:isInstalled() then
			return
		end
		
		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local running = fcp:isRunning()
		if running and not dialog.displayYesNoQuestion(i18n("togglingMovingMarkersRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
			return
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		saveMovingMarkers(allowMovingMarkers)

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if running and not fcp:restart() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			dialog.displayErrorMessage(i18n("failedToRestart"))
		end
	end
)

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
	mod.enabled()

	--------------------------------------------------------------------------------
	-- Setup Menu:
	--------------------------------------------------------------------------------
	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("enableMovingMarkers"),	fn = function() mod.enabled:toggle() end, checked=mod.enabled() }
	end)

	:addSeparator(PRIORITY + 1)

	--------------------------------------------------------------------------------
	-- Setup Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpToggleMovingMarkers")
		:groupedBy("hacks")
		:activatedBy():ctrl():option():cmd("y")
		:whenActivated(function() mod.enabled:toggle() end)

	return mod

end

return plugin