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
local drawing							= require("hs.drawing")
local fnutils							= require("hs.fnutils")
local fs								= require("hs.fs")
local menubar							= require("hs.menubar")
local mouse								= require("hs.mouse")
local pasteboard						= require("hs.pasteboard")
local screen							= require("hs.screen")
local speech							= require("hs.speech")
local timer								= require("hs.timer")

local config							= require("cp.config")
local dialog							= require("cp.dialog")
local fcp								= require("cp.apple.finalcutpro")
local just								= require("cp.just")
local tools								= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.text2speech.recentText
--- Variable
--- Table of recent items in Text to Speech Search.
mod.history = config.prop("textToSpeechHistory", {})

--- plugins.finalcutpro.text2speech.path
--- Variable
--- Text to Speech Path for generated files.
mod.path = config.prop("text2speechPath", "")

--- plugins.finalcutpro.text2speech.voice
--- Variable
--- Text to Speech Voice.
mod.voice = config.prop("text2speechVoice", "")

--- plugins.finalcutpro.text2speech.tag
--- Variable
--- Tag that will be added to generated voice overs.
mod.tag = config.prop("text2speechTag", "Generated Voice Over")

--- plugins.finalcutpro.text2speech.insertIntoTimeline
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.insertIntoTimeline = config.prop("text2speechInsertIntoTimeline", true)

--- plugins.finalcutpro.text2speech.chooseFolder() -> string or false
--- Function
--- Prompts the user to choose a folder for the Text to Speech Tool.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the selected path or `false` if cancelled.
function mod.chooseFolder()
	local result = dialog.displayChooseFolder(i18n("textToSpeechDestination"))
	if result then
		mod.path(result)
	end
	return result
end

-- completionFn() -> none
-- Function
-- Completion Function for the Chooser
--
-- Parameters:
--  * result - the result of the chooser.
--
-- Returns:
--  * None
local function completionFn(result)

	--------------------------------------------------------------------------------
	-- If cancelled then stop here:
	--------------------------------------------------------------------------------
	if not result then
		mod.chooser:hide()
		return
	end

	--------------------------------------------------------------------------------
	-- Hide Chooser:
	--------------------------------------------------------------------------------
	mod.chooser:hide()

	--------------------------------------------------------------------------------
	-- Return to Final Cut Pro:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Save last result to history:
	--------------------------------------------------------------------------------
	local selectedRow = mod.chooser:selectedRow()
	local history = fnutils.copy(mod.history())
	if selectedRow == 1 then
		table.insert(history, 1, result)
	end
	mod.history(history)

	--------------------------------------------------------------------------------
	-- Determine Filename from Result:
	--------------------------------------------------------------------------------
	local textToSpeak = result["text"]
	local filename = string.sub(textToSpeak, 1, 255) 	-- macOS doesn't like filenames over 255 characters
	filename = string.gsub(filename, ":", "") 			-- macOS doesn't like : symbols in filenames
	local savePath = mod.path() .. filename .. ".aif"

	if tools.doesFileExist(savePath) then
		local newPathCount = 0
		repeat
			newPathCount = newPathCount + 1
			savePath = mod.path() .. filename .. " " .. tostring(newPathCount) .. ".aif"
		until not tools.doesFileExist(savePath)
	end

	--------------------------------------------------------------------------------
	-- Save Synthesised Voice to File:
	--------------------------------------------------------------------------------
	local talker = speech.new()
	local defaultVoice = speech.defaultVoice()
	if mod.voice() ~= "" then
		local result = talker:voice(mod.voice())
		if not result then
			talker:voice(defaultVoice)
			mod.voice(defaultVoice)
		end
	end
	talker:speakToFile(textToSpeak, savePath)

	--------------------------------------------------------------------------------
	-- Add Finder Tag:
	--------------------------------------------------------------------------------
	local result = just.doUntil(function()
		return tools.doesFileExist(savePath)
	end, 3)
	if result then
		fs.tagsAdd(savePath, {mod.tag()})
	else
		log.ef("The Text to Speech file could not be found.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Temporarily stop the Clipboard Watcher:
	--------------------------------------------------------------------------------
	mod.clipboardManager.stopWatching()

	--------------------------------------------------------------------------------
	-- Save current Clipboard Content:
	--------------------------------------------------------------------------------
	local originalClipboard = pasteboard.readAllData()

	--------------------------------------------------------------------------------
	-- Write URL to Pasteboard:
	--------------------------------------------------------------------------------
	local safeSavePath = "file://" .. string.gsub(savePath, " ", "%%20") -- Replace spaces with %20
	pasteboard.writeObjects({url=safeSavePath})

	--------------------------------------------------------------------------------
	-- Check if Timeline can be enabled:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled("Window", "Go To", "Timeline")
	if result then
		local result = fcp:selectMenu("Window", "Go To", "Timeline")
	else
		log.wf("Failed to activate timeline in Text to Speech Plugin.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Perform Paste:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled("Edit", "Paste as Connected Clip")
	if result then
		local result = fcp:selectMenu("Edit", "Paste as Connected Clip")
	else
		log.wf("Failed to trigger the 'Paste' Shortcut in the Text to Speech Plugin.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Remove from Timeline if appropriate:
	--------------------------------------------------------------------------------
	if not mod.insertIntoTimeline() then
		local result = just.doUntil(function()
			return fcp:menuBar():isEnabled("Edit", "Undo Paste")
		end, 3)
		if result then
			local result = fcp:menuBar():isEnabled("Edit", "Undo Paste")
			if result then
				local result = fcp:selectMenu("Edit", "Undo Paste")
			else
				log.wf("Failed to trigger the 'Undo Paste' Shortcut in the Text to Speech Plugin.")
				return nil
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Restore original Clipboard Content:
	--------------------------------------------------------------------------------
	timer.doAfter(2, function()
		pasteboard.writeAllData(originalClipboard)
		mod.clipboardManager.startWatching()
	end)

end

-- queryChangedCallback() -> none
-- Function
-- Callback for when the Chooser Query is Changed.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function queryChangedCallback()
	--------------------------------------------------------------------------------
	-- Chooser Query Changed by User:
	--------------------------------------------------------------------------------
	local history = fnutils.copy(mod.history())
	local currentQuery = mod.chooser:query()
	local currentQueryTable = {
		{
			["text"] = currentQuery
		},
	}
	for i=1, #history do
		table.insert(currentQueryTable, history[i])
	end
	mod.chooser:choices(currentQueryTable)
end

-- firstToUpper() -> string
-- Function
-- Makes the first letter in a word a capital letter.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A string.
function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

-- tagValidation() -> string
-- Function
-- Checks to see if a tag is valid.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if valid otherwise `false`
local function tagValidation(value)
	if string.find(value, ":") then
		return false
	end
	return true
end

-- rightClickCallback() -> none
-- Function
-- Callback for when you right click on the Chooser.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function rightClickCallback()
	--------------------------------------------------------------------------------
	-- Right Click Menu:
	--------------------------------------------------------------------------------
	local availableVoices = speech.availableVoices()

	local voicesMenu = {}
	for i, v in ipairs(availableVoices) do
		voicesMenu[#voicesMenu + 1] = {
			title = firstToUpper(v),
			fn = function()
				mod.voice(v)
			end,
			checked = (v == mod.voice()),
		}
    end

	local rightClickMenu = {
		{ title = i18n("selectVoice"), menu = voicesMenu },
		{ title = "-" },
		{ title = i18n("insertIntoTimeline"), checked = mod.insertIntoTimeline(),
			fn = function()
				mod.insertIntoTimeline:toggle()
			end,
		},
		{ title = i18n("customiseFinderTag"), fn = function()
				local result = dialog.displayTextBoxMessage(i18n("enterFinderTag"), i18n("enterFinderTagError"), mod.tag(), tagValidation)
				if result then
					mod.tag(result)
				end
				mod.chooser:show()
			end,
		},
		{ title = i18n("changeDestinationFolder"),
			fn = function()
				mod.chooseFolder()
				mod.chooser:show()
			end,
		},
		{ title = "-" },
		{ title = i18n("clearHistory"), fn = function()
			mod.history({})
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
		:setMenu(rightClickMenu)
		:popupMenu(mouse.getAbsolutePosition())
end

--- plugins.finalcutpro.text2speech.show() -> none
--- Function
--- Shows the Text to Speech Chooser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()

	--------------------------------------------------------------------------------
	-- Check if Timeline can be enabled:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled("Window", "Go To", "Timeline")
	if not result then
		log.wf("Failed to activate timeline in Text to Speech Plugin.")
	end

	--------------------------------------------------------------------------------
	-- If directory doesn't exist then prompt user to select a new folder:
	--------------------------------------------------------------------------------
	if not tools.doesDirectoryExist(mod.path()) then
		local result = mod.chooseFolder()
		if not result then
			return nil
		else
			mod.path(result)
		end
	end

	--------------------------------------------------------------------------------
	-- Setup Chooser:
	--------------------------------------------------------------------------------
	mod.chooser = chooser.new(completionFn)
		:bgDark(true)
		:queryChangedCallback(queryChangedCallback)
		:rightClickCallback(rightClickCallback)
		:choices(mod.history())

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

	--------------------------------------------------------------------------------
	-- Define Plugins:
	--------------------------------------------------------------------------------
	mod.clipboardManager = deps.clipboardManager

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpText2Speech")
		:whenActivated(function() mod.show() end)
		:activatedBy():cmd():option():ctrl("u")

	return mod
end

return plugin