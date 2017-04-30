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

local base64							= require("hs.base64")
local chooser							= require("hs.chooser")
local drawing							= require("hs.drawing")
local eventtap							= require("hs.eventtap")
local host								= require("hs.host")
local menubar							= require("hs.menubar")
local mouse								= require("hs.mouse")
local screen							= require("hs.screen")
local speech							= require("hs.speech")
local timer								= require("hs.timer")

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

mod.defaultFilename 	= "Synthesised Voice Over"
mod.recentText 			= config.prop("textToSpeechRecentText", {})
mod.path 				= config.prop("text2speechPath", "")

function mod.chooseFolder()
	local result = dialog.displayChooseFolder("Please select where you want to save your audio files:")
	if result then
		mod.path(result)
	end
	return result
end

local function fileToString(path)
	local result = nil
	file = io.open(path, "r")
	if file then
		io.input(file)
		result = io.read("*a")
		io.close(file)
	end
	return result
end

local charset = {}
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end

function string.random(length)
  math.randomseed(os.time())

  if length > 0 then
    return string.random(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
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

	--log.df("mod.recentText: %s", hs.inspect(mod.recentText()))

	local textToSpeak = result["text"]

	local label = mod.defaultFilename
	local savePath = mod.path() .. mod.defaultFilename .. ".aif"

	if tools.doesFileExist(savePath) then
		local newPathCount = 0
		repeat
			newPathCount = newPathCount + 1
			savePath = mod.path() .. mod.defaultFilename .. " " .. tostring(newPathCount) .. ".aif"
			label = mod.defaultFilename .. " " .. tostring(newPathCount)
		until not tools.doesFileExist(savePath)
	end

	--log.df("Saving to file (%s): %s", savePath, textToSpeak)

	speech.new():speakToFile(textToSpeak, savePath)

	hs.execute("open -R '" ..  savePath .. "'")

	do return end

	--------------------------------------------------------------------------------
	--
	-- TODO: Below is a failed attempt of trying to import the audio clip into the
	--       Final Cut Pro timeline using the Pasteboard. Need to do a lot more
	--       testing and experimentation to hopefully get it to actually work.
	--
	--------------------------------------------------------------------------------

	local templateXML = fileToString(mod.assetsPath .. "/inside.plist")
	templateXML = string.gsub(templateXML, "{{ clipname }}", textToSpeak)
	templateXML = string.gsub(templateXML, "{{ label }}", label)
	templateXML = string.gsub(templateXML, "{{ fullPath }}", savePath)
	templateXML = string.gsub(templateXML, "{{ uuidA }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidB }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidC}}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidD }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidE }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidF }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidG }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidH }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidI }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ uuidJ }}", host.uuid())
	templateXML = string.gsub(templateXML, "{{ randomA }}", string.random(32))

	local base64Encoded = base64.encode(templateXML, 68)

	local finalClipboardData = fileToString(mod.assetsPath .. "/outside.plist")
	finalClipboardData = string.gsub(finalClipboardData, "{{ base64data }}", base64Encoded)

	--------------------------------------------------------------------------------
	-- Put item back in the clipboard quietly:
	--------------------------------------------------------------------------------
	mod.clipboardManager.writeFCPXData(finalClipboardData, true)

	--------------------------------------------------------------------------------
	-- Paste in FCPX:
	--------------------------------------------------------------------------------
	fcp:launch()
	if fcp:performShortcut("Paste") then
		return true
	else
		log.w("Failed to trigger the 'Paste' Shortcut.")
	end

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
			--log.df("Choose Folder Cancelled.")
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
		["finalcutpro.commands"]			= "fcpxCmds",
		["finalcutpro.clipboard.manager"]	= "clipboardManager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	mod.clipboardManager = deps.clipboardManager

	mod.assetsPath = env:pathToAbsolute("assets")

	deps.fcpxCmds:add("cpText2Speech")
		:whenActivated(function() mod.show() end)
		:activatedBy():cmd():option():ctrl("u")

	return mod
end

return plugin