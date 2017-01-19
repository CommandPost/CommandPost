-- Imports

local fcp 			= require("hs.finalcutpro")
local dialog		= require("hs.fcpxhacks.modules.dialog")
local settings		= require("hs.settings")

-- Constants

local PRIORITY = 2000

-- The Module

local mod = {}

--------------------------------------------------------------------------------
-- CHANGE BATCH EXPORT DESTINATION PRESET:
--------------------------------------------------------------------------------
function mod.changeExportDestinationPreset()
	local shareMenuItems = fcp:menuBar():findMenuItemsUI("File", "Share")
	if not shareMenuItems then
		dialog.displayErrorMessage(i18n("batchExportDestinationsNotFound"))
		return
	end

	local destinations = {}

	for i = 1, #shareMenuItems-2 do
		local item = shareMenuItems[i]
		local title = item:attributeValue("AXTitle")
		if title ~= nil then
			local value = string.sub(title, 1, -4)
			if item:attributeValue("AXMenuItemCmdChar") then -- it's the default
				-- Remove (default) text:
				local firstBracket = string.find(value, " %(", 1)
				if firstBracket == nil then
					firstBracket = string.find(value, "（", 1)
				end
				value = string.sub(value, 1, firstBracket - 1)
			end
			destinations[#destinations + 1] = value
		end
	end

	local batchExportDestinationPreset = settings.get("fcpxHacks.batchExportDestinationPreset")
	local defaultItems = {}
	if batchExportDestinationPreset ~= nil then defaultItems[1] = batchExportDestinationPreset end

	local result = dialog.displayChooseFromList(i18n("selectDestinationPreset"), destinations, defaultItems)
	if result and #result > 0 then
		settings.set("fcpxHacks.batchExportDestinationPreset", result[1])
	end
end

--------------------------------------------------------------------------------
-- CHANGE BATCH EXPORT DESTINATION FOLDER:
--------------------------------------------------------------------------------
function mod.changeExportDestinationFolder()
	local result = dialog.displayChooseFolder(i18n("selectDestinationFolder"))
	if result == false then return end

	settings.set("fcpxHacks.batchExportDestinationFolder", result)
end

--------------------------------------------------------------------------------
-- TOGGLE BATCH EXPORT REPLACE EXISTING FILES:
--------------------------------------------------------------------------------
function mod.toggleReplaceExistingFiles()
	local batchExportReplaceExistingFiles = settings.get("fcpxHacks.batchExportReplaceExistingFiles")
	settings.set("fcpxHacks.batchExportReplaceExistingFiles", not batchExportReplaceExistingFiles)
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.manager"]		= "manager",
	["hs.fcpxhacks.plugins.menu.preferences"]	= "prefs",
}

function plugin.init(deps)
	local fcpxRunning = fcp:isRunning()
	
	-- Add a secton to the 'Preferences' menu
	local section = deps.prefs:addSection(PRIORITY)
	mod.manager = deps.manager
	
	section:addSeparator(0)
	
	local menu = section:addMenu(1000, function() return i18n("batchExportOptions") end)
	
	menu:addItems(1, function()
		return {
			{ title = i18n("setDestinationPreset"),	fn = mod.changeExportDestinationPreset,	disabled = not fcpxRunning },
			{ title = i18n("setDestinationFolder"),	fn = mod.changeExportDestinationFolder },
			{ title = "-" },
			{ title = i18n("replaceExistingFiles"),	fn = mod.toggleReplaceExistingFiles, checked = settings.get("fcpxHacks.batchExportReplaceExistingFiles") },
		}
	end)
	
	section:addSeparator(9000)
	
	-- Return the module
	return mod
end

return plugin