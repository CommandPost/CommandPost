--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 T E X T    T O    S P E E C H    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.text2speech ===
---
--- Text to Speech Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("text2speech")

local chooser							= require("hs.chooser")
local screen							= require("hs.screen")
local timer								= require("hs.timer")
local drawing							= require("hs.drawing")
local eventtap							= require("hs.eventtap")
local menubar							= require("hs.menubar")
local mouse								= require("hs.mouse")
local speech							= require("hs.speech")

local axutils 							= require("cp.apple.finalcutpro.axutils")
local config							= require("cp.config")
local dialog							= require("cp.dialog")
local fcp								= require("cp.apple.finalcutpro")
local tools								= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.defaultFilename = "Synthesised Voice Over 1"

mod.recentText = config.prop("text2speechRecentText", {})
mod.path = config.prop("text2speechPath", "")

function mod.chooseFolder()
	local result = dialog.displayChooseFolder("Please select where you want to save your audio files:")
	if result then
		mod.path(result)
	end
	return result
end

local function completionFn(result)
	--------------------------------------------------------------------------------
	-- When Chooser Item is Selected or Closed:
	--------------------------------------------------------------------------------
	mod.chooser:hide()
	fcp:launch()

	if not result then
		--log.df("Chooser Closed")
		return
	end

	local selectedRow = mod.chooser:selectedRow()
	local recentText = mod.recentText()
	if selectedRow == 1 then
		table.insert(recentText, 1, result)
		mod.recentText(recentText)
	else
		table.remove(recentText, selectedRow)
		table.insert(recentText, 1, result)
		mod.recentText(recentText)
	end

	local textToSpeak = result["text"]

	local savePath = mod.path() .. mod.defaultFilename .. ".aif"

	if tools.doesFileExist(savePath) then
		savePath = mod.path() .. tools.incrementFilename(mod.defaultFilename) .. ".aif"
	end

	--log.df("Saving to file (%s): %s", savePath, textToSpeak)

	speech.new():speakToFile(textToSpeak, savePath)

	--------------------------------------------------------------------------------
	--
	-- TODO: Now we need to import this file into Final Cut Pro (probably using the Pasteboard - or XML is too hard)
	--
	--------------------------------------------------------------------------------

end

local function queryChangedCallback()
	--------------------------------------------------------------------------------
	-- Chooser Query Changed by User:
	--------------------------------------------------------------------------------
	local recentText = mod.recentText()

	local currentQuery = mod.chooser:query()

	local currentQueryTable = {
		{
			["text"] = currentQuery
		},
	}

	for i=1, #recentText do
		table.insert(currentQueryTable, recentText[i])
	end

	mod.chooser:choices(currentQueryTable)
	return
end

local function rightClickCallback()
	--------------------------------------------------------------------------------
	-- Right Click Menu:
	--------------------------------------------------------------------------------
	local rightClickMenu = {
		{ title = "Change Location to Save Files",
			fn = function()
				mod.chooseFolder()
				mod.chooser:show()
			end,
		},
		{ title = "-" },
		{ title = i18n("clearList"), fn = function()
			log.df("Clearing List")
			mod.recentText({})
			local currentQuery = mod.chooser:query()
			local currentQueryTable = {
				{
					["text"] = currentQuery
				},
			}
			mod.chooser:choices(currentQueryTable)
		end },
	}
	mod.rightClickMenubar = menubar.new(false)
	mod.rightClickMenubar:setMenu(rightClickMenu)
	mod.rightClickMenubar:popupMenu(mouse.getAbsolutePosition())
end

function mod.show()

	if not tools.doesDirectoryExist(mod.path()) then
		local result = mod.chooseFolder()
		if not result then
			log.df("Choose Folder Cancelled.")
			return nil
		else
			mod.path(result)
		end
	else
		--log.df("Using path: %s", mod.path())
	end

	--------------------------------------------------------------------------------
	-- Setup Chooser:
	--------------------------------------------------------------------------------
	mod.chooser = chooser.new(completionFn)
		:bgDark(true)
		:query(existingValue)
		:queryChangedCallback(queryChangedCallback)
		:rightClickCallback(rightClickCallback)

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	if screen.accessibilitySettings()["ReduceTransparency"] then
		mod.chooser:fgColor(nil)
					   :subTextColor(nil)
	else
		mod.chooser:fgColor(drawing.color.x11.snow)
					   :subTextColor(drawing.color.x11.snow)
	end

	--------------------------------------------------------------------------------
	-- Show Chooser:
	--------------------------------------------------------------------------------
	mod.chooser:show()

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.text2speech",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.commands"]		= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	deps.fcpxCmds:add("cpText2Speech")
		:whenActivated(function() mod.show() end)
		:activatedBy():cmd():option():ctrl("u")

	return mod
end

return plugin