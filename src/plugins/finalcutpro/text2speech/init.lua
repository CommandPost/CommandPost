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
local log                               = require("hs.logger").new("text2speech")

local application                       = require("hs.application")
local chooser                           = require("hs.chooser")
local drawing                           = require("hs.drawing")
local fs                                = require("hs.fs")
local http                              = require("hs.http")
local menubar                           = require("hs.menubar")
local mouse                             = require("hs.mouse")
local pasteboard                        = require("hs.pasteboard")
local screen                            = require("hs.screen")
local speech                            = require("hs.speech")
local timer                             = require("hs.timer")

local config                            = require("cp.config")
local dialog                            = require("cp.dialog")
local fcp                               = require("cp.apple.finalcutpro")
local just                              = require("cp.just")
local tools                             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.text2speech.DELETE_DELAY
--- Constant
--- How long before a file is deleted in seconds.
mod.DELETE_DELAY = 30

--- plugins.finalcutpro.text2speech.COPY_TO_MEDIA_FOLDER
--- Constant
--- Copy to Media Folder Preferences Key.
mod.COPY_TO_MEDIA_FOLDER = "FFImportCopyToMediaFolder"

--- plugins.finalcutpro.text2speech.recentText
--- Variable
--- Table of recent items in Text to Speech Search.
mod.history = config.prop("textToSpeechHistory", {})

--- plugins.finalcutpro.text2speech.currentIncrementalNumber
--- Variable
--- Current Incremental Number as number
mod.currentIncrementalNumber = config.prop("textToSpeechCurrentIncrementalNumber", 1)

--- plugins.finalcutpro.text2speech.includeTextInFilename
--- Variable
--- Includes the entered text in the filename
mod.includeTextInFilename = config.prop("includeTextInFilename", true)

--- plugins.finalcutpro.text2speech.replaceSpaceWithUnderscore
--- Variable
--- Replace Space with Underscore
mod.replaceSpaceWithUnderscore = config.prop("replaceSpaceWithUnderscore", false)

--- plugins.finalcutpro.text2speech.addTextToNotesFieldAfterImport
--- Variable
--- Option to Add Text to Notes Field After Importing
mod.addTextToNotesFieldAfterImport = config.prop("addTextToNotesFieldAfterImport", false)

--- plugins.finalcutpro.text2speech.deleteFileAfterImport
--- Variable
--- Delete File After Import
mod.deleteFileAfterImport = config.prop("deleteFileAfterImport", false)

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
mod.tag = config.prop("text2speechTag", i18n("generatedVoiceOver"))

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

-- plugins.finalcutpro.text2speech._speechCallback() -> none
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
function mod._speechCallback(_, result, a, b, c)
    if result == "didEncounterError" then
        log.df("Speech Callback Received: didEncounterError")
        log.df("Index: %s", a)
        log.df("Text: %s", b)
        log.df("Error: %s", c)
    elseif result == "didFinish" then
        if a then
            mod._completeProcess()
        else
            mod._speechError()
        end
    end
end

-- plugins.finalcutpro.text2speech._speechError() -> none
-- Function
-- Error message when something goes wrong.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._speechError()
    dialog.displayErrorMessage("Something went wrong whilst trying to generate the generated voice over.")
end

-- plugins.finalcutpro.text2speech._completionFn() -> none
-- Function
-- Completion Function for the Chooser
--
-- Parameters:
--  * result - the result of the chooser.
--
-- Returns:
--  * None
function mod._completionFn(result)

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
    -- Text to Speak:
    --------------------------------------------------------------------------------
    local textToSpeak = result["text"]

    --------------------------------------------------------------------------------
    -- Determine Filename from Result:
    --------------------------------------------------------------------------------
    local filename, savePath
    local prefix = mod.customPrefix()
    if mod.enableCustomPrefix() == true and prefix and tools.trim(prefix) ~= "" then
        --------------------------------------------------------------------------------
        -- Enable Custom Prefix:
        --------------------------------------------------------------------------------
        local seperator = " - "
        if mod.useUnderscore() then
            seperator = "_"
        end

        local customTextToSpeak = textToSpeak
        if customTextToSpeak and mod.replaceSpaceWithUnderscore() then
            customTextToSpeak = string.gsub(customTextToSpeak, " ", "_")
        end
        if mod.includeTextInFilename() then
            filename = seperator .. customTextToSpeak or i18n("generatedVoiceOver")
        else
            filename = ""
        end
        savePath = mod.path() .. tools.safeFilename(prefix .. seperator .. string.format("%04d", mod.currentIncrementalNumber())  .. filename) .. ".aif"
        if tools.doesFileExist(savePath) then
            local newPathCount = 1
            repeat
                local currentIncrementalNumber = mod.currentIncrementalNumber()
                mod.currentIncrementalNumber(currentIncrementalNumber + 1)
                newPathCount = newPathCount + 1
                savePath = mod.path() .. tools.safeFilename(prefix .. seperator .. string.format("%04d", mod.currentIncrementalNumber()) .. seperator .. filename .. seperator .. string.format("%04d", newPathCount)) .. ".aif"
            until not tools.doesFileExist(savePath)
        end
        local currentIncrementalNumber = mod.currentIncrementalNumber()
        mod.currentIncrementalNumber(currentIncrementalNumber + 1)
    else
        --------------------------------------------------------------------------------
        -- No Custom Prefix:
        --------------------------------------------------------------------------------
        local noCustomTextToSpeak = textToSpeak
        if noCustomTextToSpeak and mod.replaceSpaceWithUnderscore() then
            noCustomTextToSpeak = string.gsub(noCustomTextToSpeak, " ", "_")
        end
        filename = noCustomTextToSpeak or i18n("generatedVoiceOver")
        savePath = mod.path() .. tools.safeFilename(filename) .. ".aif"
        if tools.doesFileExist(savePath) then
            local newPathCount = 0
            repeat
                newPathCount = newPathCount + 1
                savePath = mod.path() .. tools.safeFilename(filename .. " " .. string.format("%04d", newPathCount)) .. ".aif"
            until not tools.doesFileExist(savePath)
        end
    end

    --------------------------------------------------------------------------------
    -- Save Synthesised Voice to File:
    --------------------------------------------------------------------------------
    local talker = speech.new()
    local defaultVoice = speech.defaultVoice()
    if mod.voice() ~= "" then
        local talkerResult = talker:voice(mod.voice())
        if not talkerResult then
            talker:voice(defaultVoice)
            mod.voice(defaultVoice)
        end
    end

    --------------------------------------------------------------------------------
    -- Save last Save Path:
    --------------------------------------------------------------------------------
    mod._lastSavePath = savePath

    --------------------------------------------------------------------------------
    -- Trigger the Talker:
    --------------------------------------------------------------------------------
    talker:setCallback(mod._speechCallback)
        :speakToFile(textToSpeak, savePath)

end

-- plugins.finalcutpro.text2speech.completeProcess() -> none
-- Function
-- Completes the Text to Speech Process.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._completeProcess()

    --------------------------------------------------------------------------------
    -- Cache Preferences:
    --------------------------------------------------------------------------------
    local copyToMediaFolder = fcp:getPreference(mod.COPY_TO_MEDIA_FOLDER, true)

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
    result = fcp:menuBar():isEnabled({"Window", "Go To", "Timeline"})
    if result then
        fcp:selectMenu({"Window", "Go To", "Timeline"})
    else
        dialog.displayErrorMessage("Failed to activate timeline in Text to Speech Plugin.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Perform Paste:
    --------------------------------------------------------------------------------
    result = fcp:menuBar():isEnabled({"Edit", "Paste as Connected Clip"})
    if result then
        fcp:selectMenu({"Edit", "Paste as Connected Clip"})
    else
        --------------------------------------------------------------------------------
        -- Try one more time...
        --------------------------------------------------------------------------------
        local takeTwo = fcp:menuBar():isEnabled({"Edit", "Paste as Connected Clip"})
        if takeTwo then
            fcp:selectMenu({"Edit", "Paste as Connected Clip"})
        else
            dialog.displayErrorMessage("Failed to trigger the 'Paste as Connected Clip' Shortcut in the Text to Speech Plugin.")
            return nil
        end
    end

    --------------------------------------------------------------------------------
    -- Add Text to Notes Field After Import:
    --------------------------------------------------------------------------------
    if mod.addTextToNotesFieldAfterImport() then

        --------------------------------------------------------------------------------
        -- Go back a frame:
        --------------------------------------------------------------------------------
        fcp:selectMenu({"Mark", "Previous", "Frame"})

        --------------------------------------------------------------------------------
        -- Get timeline contents:
        --------------------------------------------------------------------------------
        local content = fcp:timeline():contents()
        local playheadX = content:playhead():getPosition()

        local clips = content:clipsUI(false, function(clip)
            local frame = clip:frame()
            return playheadX >= frame.x and playheadX < (frame.x + frame.w)
        end)

        if clips == nil then
            log.d("No clips detected in selectClipAtLane().")
            return false
        end

        --------------------------------------------------------------------------------
        -- Sort the table:
        --------------------------------------------------------------------------------
        table.sort(clips, function(a, b) return a:position().y > b:position().y end)

        log.df("clips: %s", hs.inspect(clips))

        if #clips > 0 then
            for i, v in ipairs(clips) do
                log.df("Value: %s", v:attributeValue("AXDescription"))
            end
        end

--Audio-Clip:THis_is_a_test 0002

        --content:selectClip(clips[whichLane])



        --[[

        --------------------------------------------------------------------------------
        -- Make sure the Browser is visible:
        --------------------------------------------------------------------------------
        local libraries = fcp:browser():libraries()
        if not libraries:isShowing() then
            log.ef("Library Panel is closed.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Get number of Selected Browser Clips:
        --------------------------------------------------------------------------------
        local clips = libraries:selectedClipsUI()
        if #clips ~= 1 then
            log.ef("Wrong number of clips selected.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Check to see if we're in Filmstrip or List View:
        --------------------------------------------------------------------------------
        local filmstripView = false
        if libraries:isFilmstripView() then
            filmstripView = true
            libraries:toggleViewMode():press()
        end

        --------------------------------------------------------------------------------
        -- Get Selected Clip & Selected Clip's Parent:
        --------------------------------------------------------------------------------
        local selectedClip = libraries:selectedClipsUI()[1]
        local selectedClipParent = selectedClip:attributeValue("AXParent")

        --]]

    end

    --------------------------------------------------------------------------------
    -- Remove from Timeline if appropriate:
    --------------------------------------------------------------------------------
    if not mod.insertIntoTimeline() then
        result = just.doUntil(function()
            return fcp:menuBar():isEnabled({"Edit", "Undo Paste"})
        end, 3)
        if result then
            result = fcp:menuBar():isEnabled({"Edit", "Undo Paste"})
            if result then
                fcp:selectMenu({"Edit", "Undo Paste"})
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

    --------------------------------------------------------------------------------
    -- Delete File After Import:
    --------------------------------------------------------------------------------
    if copyToMediaFolder and mod.deleteFileAfterImport() then
        timer.doAfter(mod.DELETE_DELAY, function()
            os.remove(savePath)
        end)
    end

end

-- plugins.finalcutpro.text2speech._queryChangedCallback() -> none
-- Function
-- Callback for when the Chooser Query is Changed.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._queryChangedCallback()
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

-- plugins.finalcutpro.text2speech._tagValidation() -> string
-- Function
-- Checks to see if a tag is valid.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if valid otherwise `false`
function mod._tagValidation(value)
    if string.find(value, ":") then
        return false
    end
    return true
end

-- plugins.finalcutpro.text2speech._rightClickCallback() -> none
-- Function
-- Callback for when you right click on the Chooser.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._rightClickCallback()
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
        checked = (speech.defaultVoice() == mod.voice()),
    }
    voicesMenu[2] = { title = "-" }
    for _, v in ipairs(availableVoices) do
        voicesMenu[#voicesMenu + 1] = {
            title = tools.firstToUpper(v),
            fn = function()
                mod.voice(v)
            end,
            checked = (v == mod.voice() and v ~= speech.defaultVoice()),
        }
    end
    local rightClickMenu = {
        { title = i18n("selectVoice"), menu = voicesMenu },
        { title = "-" },
        { title = i18n("insertIntoTimeline"),
            checked = mod.insertIntoTimeline(),
            fn = function()
                mod.insertIntoTimeline:toggle()
            end,
        },
        { title = i18n("addTextToNotesFieldAfterImport"),
            checked = mod.addTextToNotesFieldAfterImport(),
            fn = function()
                mod.addTextToNotesFieldAfterImport:toggle()
            end,
        },
        { title = i18n("createRoleForVoice"), checked = mod.createRoleForVoice(),
            fn = function()
                mod.createRoleForVoice:toggle()
            end,
        },
        { title = "-" },
        { title = i18n("customiseFinderTag"), fn = function()
                local result = dialog.displayTextBoxMessage(i18n("enterFinderTag"), i18n("enterFinderTagError"), mod.tag(), mod._tagValidation)
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
        { title = i18n("deleteFileAfterImport"),
            disabled = not fcp:getPreference(mod.COPY_TO_MEDIA_FOLDER, true),
            checked = fcp:getPreference(mod.COPY_TO_MEDIA_FOLDER, true) and mod.deleteFileAfterImport(),
            fn = function()
                mod.deleteFileAfterImport:toggle()
            end,
        },
        { title = "-" },
        { title = string.format(string.upper(i18n("currentIncrementalNumber")) .. ": %s", string.format("%04d",mod.currentIncrementalNumber())),
            disabled = true,
        },
        { title = string.format(string.upper(i18n("prefix")) .. ": %s", mod.customPrefix()),
            disabled = true,
        },
        { title = "-" },
        { title = i18n("enableFilenamePrefix"),
            checked = mod.enableCustomPrefix(),
            fn = function()
                mod.enableCustomPrefix:toggle()
            end,
        },
        { title = i18n("includeTextInFilename"),
            disabled = not mod.enableCustomPrefix(),
            checked = not mod.enableCustomPrefix() or mod.includeTextInFilename(),
            fn = function()
                mod.includeTextInFilename:toggle()
            end,
        },
        { title = i18n("useUnderscore"),
            checked = mod.useUnderscore(),
            fn = function()
                mod.useUnderscore:toggle()
            end,
        },
        { title = i18n("replaceSpaceWithUnderscore"),
            checked = mod.replaceSpaceWithUnderscore(),
            fn = function()
                mod.replaceSpaceWithUnderscore:toggle()
            end,
        },
        { title = "-" },
        { title = i18n("resetIncrementalNumber"),
            fn = function()
                mod.currentIncrementalNumber(1)
            end,
        },
        { title = i18n("setIncrementalNumber"),
            fn = function()
                local result = dialog.displaySmallNumberTextBoxMessage(i18n("setIncrementalNumberMessage"), i18n("setIncrementalNumberError"), mod.currentIncrementalNumber())
                if type(result) == "number" then
                    mod.currentIncrementalNumber(result)
                end
            end,
        },
        { title = i18n("setFilenamePrefix"),
            fn = function()
                local result = mod.customPrefix(dialog.displayTextBoxMessage(i18n("pleaseEnterAPrefix") .. ":", i18n("customPrefixError"), mod.customPrefix(), function(value)
                    if value and type("value") == "string" and value ~= tools.trim("") and tools.safeFilename(value, value) == value then
                        return true
                    else
                        return false
                    end
                end))
                if type(result) == "string" then
                    mod.customPrefix(result)
                end
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
        local folderResult = mod.chooseFolder()
        if not folderResult then
            return nil
        else
            mod.path(result)
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Chooser:
    --------------------------------------------------------------------------------
    mod.chooser = chooser.new(mod._completionFn)
        :bgDark(true)
        :queryChangedCallback(mod._queryChangedCallback)
        :rightClickCallback(mod._rightClickCallback)
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
    id              = "finalcutpro.text2speech",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.clipboard.manager"]   = "clipboardManager",
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