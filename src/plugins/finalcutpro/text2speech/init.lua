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

local application						= require("hs.application")
local chooser							= require("hs.chooser")
local drawing							= require("hs.drawing")
local fnutils							= require("hs.fnutils")
local fs								= require("hs.fs")
local http								= require("hs.http")
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
mod.voice = config.prop("text2speechVoice", speech.defaultVoice())

--- plugins.finalcutpro.text2speech.tag
--- Variable
--- Tag that will be added to generated voice overs.
mod.tag = config.prop("text2speechTag", "Generated Voice Over")

--- plugins.finalcutpro.text2speech.insertIntoTimeline
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.insertIntoTimeline = config.prop("text2speechInsertIntoTimeline", true)

--- plugins.finalcutpro.text2speech.enableCustomPrefix
--- Variable
--- Boolean that sets whether or not a custom prefix for the generated filename is enabled.
mod.enableCustomPrefix = config.prop("text2speechEnableCustomPrefix", false)

--- plugins.finalcutpro.text2speech.customPrefix
--- Variable
--- String which contains the custom prefix.
mod.customPrefix = config.prop("text2speechCustomPrefix", "Custom Prefix")

--- plugins.finalcutpro.text2speech.useUnderscore
--- Variable
--- If `true` then an underscore will be used in the Custom Prefix filename otherwise a dash will be used.
mod.useUnderscore = config.prop("text2speechUseUnderscore", false)

--- plugins.finalcutpro.text2speech.createRoleForVoice
--- Variable
--- Boolean that sets whether or not a tag should be added for the voice.
mod.createRoleForVoice = config.prop("text2speechCreateRoleForVoice", true)

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

-- speechCallback() -> none
-- Function
-- Callback function for the speech tool.
--
-- Parameters:
--  * object - the synthesizer object
--  * result - string indicating the activity which has caused the callback
--  * a - optional argument
--  * b - optional argument
--  * c - optional argument
--
-- Returns:
--  * None
local function speechCallback(object, result, a, b, c)
	if result == "willSpeakWord" then
	elseif result == "willSpeakPhoneme" then
	elseif result == "didEncounterError" then
		log.df("Speech Callback Received: didEncounterError")
		log.df("Index: %s", a)
		log.df("Text: %s", b)
		log.df("Error: %s", c)
	elseif result == "didEncounterSync" then
	elseif result == "didFinish" then
		if a then
			completeProcess()
		else
			speechError()
		end
	end
end

-- speechError() -> none
-- Function
-- Error message when something goes wrong.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function speechError()
	dialog.displayErrorMessage("Something went wrong whilst trying to generate the generated voice over.")
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
	local history = mod.history()
	if selectedRow == 1 then
		table.insert(history, 1, result)
	end
	mod.history(history)

	--------------------------------------------------------------------------------
	-- Determine Filename from Result:
	--------------------------------------------------------------------------------
	local textToSpeak, filename, savePath
	local prefix = mod.customPrefix()
    if mod.enableCustomPrefix() == true and prefix and tools.trim(prefix) ~= "" then
        --------------------------------------------------------------------------------
        -- Enable Custom Prefix:
        --------------------------------------------------------------------------------
        local seperator = " - "
        if mod.useUnderscore() then
            seperator = "_"
        end
        textToSpeak = result["text"]
        filename = tools.safeFilename(textToSpeak, "Generated Voice Over")
        savePath = mod.path() .. prefix .. seperator .. "0001" .. seperator .. filename .. ".aif"
        if tools.doesFileExist(savePath) then
            local newPathCount = 1
            repeat
                newPathCount = newPathCount + 1
                savePath = mod.path() .. prefix .. seperator .. string.format("%04d", newPathCount) .. seperator .. filename .. ".aif"
            until not tools.doesFileExist(savePath)
        end
    else
        --------------------------------------------------------------------------------
        -- No Custom Prefix:
        --------------------------------------------------------------------------------
        textToSpeak = result["text"]
        filename = tools.safeFilename(textToSpeak, "Generated Voice Over")
        savePath = mod.path() .. filename .. ".aif"
        if tools.doesFileExist(savePath) then
            local newPathCount = 0
            repeat
                newPathCount = newPathCount + 1
                savePath = mod.path() .. filename .. " " .. string.format("%04d", newPathCount) .. ".aif"
            until not tools.doesFileExist(savePath)
        end
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

	mod._lastSavePath = savePath

	talker:setCallback(speechCallback)
		:speakToFile(textToSpeak, savePath)

end

-- completeProcess() -> none
-- Function
-- Completes the Text to Speech Process.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function completeProcess()

	--------------------------------------------------------------------------------
	-- Get the last Save Path:
	--------------------------------------------------------------------------------
	local savePath = mod._lastSavePath
	if not tools.doesFileExist(savePath) then
		dialog.displayErrorMessage("The generated Text to Speech file could not be found.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Add Finder Tag(s):
	--------------------------------------------------------------------------------
	if mod.createRoleForVoice() then
		if not fs.tagsAdd(savePath, {mod.tag(), tools.firstToUpper(mod.voice())}) then
			log.ef("Failed to add Finder Tags (%s & %s) to: %s", mod.tag(), tools.firstToUpper(mod.voice()), savePath)
		end
	else
		if not fs.tagsAdd(savePath, {mod.tag()}) then
			log.ef("Failed to add Finder Tag (%s) to: %s", mod.tag(), savePath)
		end
	end

	--------------------------------------------------------------------------------
	-- Temporarily stop the Clipboard Watcher:
	--------------------------------------------------------------------------------
	if mod.clipboardManager then
		mod.clipboardManager.stopWatching()
	end

	--------------------------------------------------------------------------------
	-- Save current Clipboard Content:
	--------------------------------------------------------------------------------
	local originalClipboard = pasteboard.readAllData()

	--------------------------------------------------------------------------------
	-- Write URL to Pasteboard:
	--------------------------------------------------------------------------------
	local safeSavePath = "file://" .. http.encodeForQuery(savePath)
	local result = pasteboard.writeObjects({url=safeSavePath})
	if not result then
		dialog.displayErrorMessage("The URL could not be written to the Pasteboard.")
		return nil
	end

    --------------------------------------------------------------------------------
    -- Delay things until the data is actually successfully on the Clipboard:
    --------------------------------------------------------------------------------
    local pasteboardCheckResult = just.doUntil(function()
        local pasteboardCheck = pasteboard.readAllData()
        if pasteboardCheck and pasteboardCheck["public.file-url"] and pasteboardCheck["public.file-url"] == safeSavePath then
            return true
        else
            return false
        end
    end, 0.5)
    if not pasteboardCheckResult then
        dialog.displayErrorMessage("The URL on the clipboard was not the same as what we wrote to the Pasteboard.")
        return nil
    end

	--------------------------------------------------------------------------------
	-- Check if Timeline can be enabled:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled({"Window", "Go To", "Timeline"})
	if result then
		local result = fcp:selectMenu({"Window", "Go To", "Timeline"})
	else
		dialog.displayErrorMessage("Failed to activate timeline in Text to Speech Plugin.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Perform Paste:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled({"Edit", "Paste as Connected Clip"})
	if result then
		local result = fcp:selectMenu({"Edit", "Paste as Connected Clip"})
	else
		dialog.displayErrorMessage("Failed to trigger the 'Paste as Connected Clip' Shortcut in the Text to Speech Plugin.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Remove from Timeline if appropriate:
	--------------------------------------------------------------------------------
	if not mod.insertIntoTimeline() then
		local result = just.doUntil(function()
			return fcp:menuBar():isEnabled({"Edit", "Undo Paste"})
		end, 3)
		if result then
			local result = fcp:menuBar():isEnabled({"Edit", "Undo Paste"})
			if result then
				local result = fcp:selectMenu({"Edit", "Undo Paste"})
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
		if mod.clipboardManager then
			mod.clipboardManager.startWatching()
		end
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
	local history = mod.history()
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
	voicesMenu[1] = {
		title = "Default " .. "(" .. speech.defaultVoice() .. ")",
		fn = function()
			mod.voice(hs.speech.defaultVoice())
		end,
		checked = (v == mod.voice()),
	}
	voicesMenu[2] = { title = "-" }
	for i, v in ipairs(availableVoices) do
		voicesMenu[#voicesMenu + 1] = {
			title = tools.firstToUpper(v),
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
		{ title = i18n("createRoleForVoice"), checked = mod.createRoleForVoice(),
			fn = function()
				mod.createRoleForVoice:toggle()
			end,
		},
		{ title = "-" },
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
		{ title = i18n("enableFilenamePrefix"),
		    checked = mod.enableCustomPrefix(),
			fn = function()
				mod.enableCustomPrefix:toggle()
			end,
		},
		{ title = i18n("setFilenamePrefix"),
			fn = function()
                mod.customPrefix(dialog.displayTextBoxMessage(i18n("pleaseEnterAPrefix") .. ":", "", mod.customPrefix(), nil))
			end,
		},
		{ title = i18n("useUnderscore"),
		    checked = mod.useUnderscore(),
			fn = function()
				mod.useUnderscore:toggle()
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
		end
		},
		{ title = "-" },
		{ title = i18n("openVoiceOverUtility"), fn = function()
				application.open("VoiceOver Utility")
			end,
		},
		{ title = i18n("openEmbeddedSpeechCommandsHelp"), fn = function()
			os.execute('open "https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/SpeechSynthesisProgrammingGuide/FineTuning/FineTuning.html#//apple_ref/doc/uid/TP40004365-CH5-SW6"')
		end,
		},
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
	local result = fcp:menuBar():isEnabled({"Window", "Go To", "Timeline"})
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