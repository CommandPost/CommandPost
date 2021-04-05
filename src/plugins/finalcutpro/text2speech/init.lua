--- === plugins.finalcutpro.text2speech ===
---
--- Text to Speech Plugin.

local require = require

local log                               = require "hs.logger".new "text2speech"

local application                       = require "hs.application"
local chooser                           = require "hs.chooser"
local drawing                           = require "hs.drawing"
local eventtap                          = require "hs.eventtap"
local fs                                = require "hs.fs"
local http                              = require "hs.http"
local menubar                           = require "hs.menubar"
local mouse                             = require "hs.mouse"
local pasteboard                        = require "hs.pasteboard"
local screen                            = require "hs.screen"
local speech                            = require "hs.speech"
local timer                             = require "hs.timer"

local axutils                           = require "cp.ui.axutils"
local config                            = require "cp.config"
local dialog                            = require "cp.dialog"
local fcp                               = require "cp.apple.finalcutpro"
local just                              = require "cp.just"
local tools                             = require "cp.tools"
local i18n                              = require "cp.i18n"

local doAfter                           = timer.doAfter

local displayChooseFolder               = dialog.displayChooseFolder
local displayErrorMessage               = dialog.displayErrorMessage
local displaySmallNumberTextBoxMessage  = dialog.displaySmallNumberTextBoxMessage
local displayTextBoxMessage             = dialog.displayTextBoxMessage

local doesDirectoryExist                = tools.doesDirectoryExist
local doesFileExist                     = tools.doesFileExist
local firstToUpper                      = tools.firstToUpper
local playErrorSound                    = tools.playErrorSound
local replace                           = tools.replace

local urlFromPath                       = fs.urlFromPath

local mod = {}

-- DELETE_DELAY
-- Constant
-- How long before a file is deleted in seconds.
local DELETE_DELAY = 30

--- plugins.finalcutpro.text2speech.copyToMediaFolder <cp.prop: boolean; live>
--- Constant
--- Copy to Media Folder Preferences Key.
mod.copyToMediaFolder = fcp.preferences:prop("FFImportCopyToMediaFolder")

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

--- plugins.finalcutpro.text2speech.addCaption
--- Variable
--- Option to Add Text to Notes Field After Importing
mod.addCaption = config.prop("addCaption", false)

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

--- plugins.finalcutpro.text2speech.assignClipAudioRoleToVoiceName
--- Variable
--- Assign Clip Audio Role to Voice Name
mod.assignClipAudioRoleToVoiceName = config.prop("text2speechCreateRoleForVoice", true)

--- plugins.finalcutpro.text2speech.addKeywordForVoiceName
--- Variable
--- Boolean that sets whether or not a tag should be added for the voice.
mod.addKeywordForVoiceName = config.prop("text2speech_addKeywordForVoiceName", true)

--- plugins.finalcutpro.text2speech.addCustomKeyword
--- Variable
--- Boolean that sets whether or not to add a custom keyword.
mod.addCustomKeyword = config.prop("text2speech_addCustomKeyword", true)

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
    local result = displayChooseFolder(i18n("textToSpeechDestination"))
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
    displayErrorMessage("Something went wrong whilst trying to generate the generated voice over.")
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
    if mod.chooser then
        mod.chooser:hide()
    end

    --------------------------------------------------------------------------------
    -- Return to Final Cut Pro:
    --------------------------------------------------------------------------------
    fcp:launch()

    --------------------------------------------------------------------------------
    -- Save last result to history:
    --------------------------------------------------------------------------------
    if mod.chooser then
        local selectedRow = mod.chooser:selectedRow()
        local history = mod.history()
        if selectedRow == 1 then
            table.insert(history, 1, result)
        end
        mod.history(history)
    end

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
        mod._lastFilename = tools.safeFilename(prefix .. seperator .. string.format("%04d", mod.currentIncrementalNumber())  .. filename)
        if doesFileExist(savePath) then
            local newPathCount = 1
            repeat
                local currentIncrementalNumber = mod.currentIncrementalNumber()
                mod.currentIncrementalNumber(currentIncrementalNumber + 1)
                newPathCount = newPathCount + 1
                savePath = mod.path() .. tools.safeFilename(prefix .. seperator .. string.format("%04d", mod.currentIncrementalNumber()) .. seperator .. filename .. seperator .. string.format("%04d", newPathCount)) .. ".aif"
                mod._lastFilename = tools.safeFilename(prefix .. seperator .. string.format("%04d", mod.currentIncrementalNumber()) .. seperator .. filename .. seperator .. string.format("%04d", newPathCount))
            until not doesFileExist(savePath)
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
        mod._lastFilename = tools.safeFilename(filename)
        if doesFileExist(savePath) then
            local newPathCount = 0
            repeat
                newPathCount = newPathCount + 1
                savePath = mod.path() .. tools.safeFilename(filename .. " " .. string.format("%04d", newPathCount)) .. ".aif"
                mod._lastFilename = tools.safeFilename(filename .. " " .. string.format("%04d", newPathCount))
            until not doesFileExist(savePath)
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
    -- Save values for later:
    --------------------------------------------------------------------------------
    mod._lastSavePath = savePath
    mod._lastTextToSpeak = textToSpeak

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
    local copyToMediaFolder = mod.copyToMediaFolder()

    --------------------------------------------------------------------------------
    -- Get the last Save Path:
    --------------------------------------------------------------------------------
    local savePath = mod._lastSavePath
    if not doesFileExist(savePath) then
        displayErrorMessage("The generated Text to Speech file could not be found.")
        return
    end

    --------------------------------------------------------------------------------
    -- Add Finder Tag(s):
    --------------------------------------------------------------------------------
    local originalImportTags = fcp.preferences.FFImportTagsAsKeywordCollectionsKey
    fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", true)
    local tags = {}
    if mod.addCustomKeyword() then
        table.insert(tags, mod.tag())
    end
    if mod.addKeywordForVoiceName() then
        table.insert(tags, firstToUpper(mod.voice()))
    end
    if next(tags) then
        if not fs.tagsAdd(savePath, tags) then
            log.ef("Failed to add Finder Tags to: %s\n%s", savePath, hs.inspect(tags))
            displayErrorMessage("The generated Text to Speech file could not be found.")
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Assign Audio Role:
    --------------------------------------------------------------------------------
    local originalRole = fcp.preferences.FFImportAudioRoleGroupOverrideRoleDef
    if mod.assignClipAudioRoleToVoiceName() then
        local voice = mod.voice()

        -- Roles cannot include a dot or a question mark:
        voice = replace(voice, ".", "-")
        voice = replace(voice, "?", "-")

        local role = "a." .. voice .. "._"
        fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", role)
    end

    --------------------------------------------------------------------------------
    -- Temporarily stop the Pasteboard Watcher:
    --------------------------------------------------------------------------------
    if mod.pasteboardManager then
        mod.pasteboardManager.stopWatching()
    end

    --------------------------------------------------------------------------------
    -- Save current Pasteboard Content:
    --------------------------------------------------------------------------------
    local originalPasteboard = pasteboard.readAllData()

    --------------------------------------------------------------------------------
    -- Write URL to Pasteboard:
    --------------------------------------------------------------------------------
    local safeSavePath = urlFromPath(savePath)
    local result = pasteboard.writeObjects({url=safeSavePath})
    if not result then
        --------------------------------------------------------------------------------
        -- Restore audio role & Finder Tags Setting:
        --------------------------------------------------------------------------------
        fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
        fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

        -------------------------------------------------------------------------------
        -- Display Error Message:
        --------------------------------------------------------------------------------
        displayErrorMessage("The Text to Speech tool could not write a URL to the Pasteboard, and therefore has aborted.")
        return
    end

    --------------------------------------------------------------------------------
    -- Delay things until the data is actually successfully on the Pasteboard:
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
        --------------------------------------------------------------------------------
        -- Restore audio role & Finder Tags Setting:
        --------------------------------------------------------------------------------
        fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
        fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

        -------------------------------------------------------------------------------
        -- Display Error Message:
        --------------------------------------------------------------------------------
        displayErrorMessage("The Text to Speech tool failed to detect the URL that was just inserted on the Pasteboard, and therefore has aborted.")
        return
    end

    --------------------------------------------------------------------------------
    -- Check if Timeline can be enabled:
    --------------------------------------------------------------------------------
    result = fcp.menu:isEnabled({"Window", "Go To", "Timeline"})
    if result then
        fcp:selectMenu({"Window", "Go To", "Timeline"})
    else
        --------------------------------------------------------------------------------
        -- Restore audio role & Finder Tags Setting:
        --------------------------------------------------------------------------------
        fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
        fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

        -------------------------------------------------------------------------------
        -- Display Error Message:
        --------------------------------------------------------------------------------
        displayErrorMessage("The Text to Speech tool failed to trigger the 'Window > Go To > Timeline' menu item, and therefore has aborted.")
        return
    end

    --------------------------------------------------------------------------------
    -- Perform Paste:
    --------------------------------------------------------------------------------
    result = fcp.menu:isEnabled({"Edit", "Paste as Connected Clip"})
    if result then
        fcp:selectMenu({"Edit", "Paste as Connected Clip"})
    else
        --------------------------------------------------------------------------------
        -- Try one more time...
        --------------------------------------------------------------------------------
        local takeTwo = fcp.menu:isEnabled({"Edit", "Paste as Connected Clip"})
        if takeTwo then
            fcp:selectMenu({"Edit", "Paste as Connected Clip"})
        else
            --------------------------------------------------------------------------------
            -- Restore audio role & Finder Tags Setting:
            --------------------------------------------------------------------------------
            fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
            fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

            -------------------------------------------------------------------------------
            -- Display Error Message:
            --------------------------------------------------------------------------------
            displayErrorMessage("The Text to Speech tool failed to trigger the 'Paste as Connected Clip' Shortcut, and therefore has aborted.")
            return
        end
    end

    --------------------------------------------------------------------------------
    -- If "Add Text to Notes Field After Import" or "Add Caption" then find the
    -- clip on the timeline:
    --------------------------------------------------------------------------------
    local lastClip
    if mod.addTextToNotesFieldAfterImport() or mod.addCaption() then
        --------------------------------------------------------------------------------
        -- Go back two frames:
        --------------------------------------------------------------------------------
        fcp:selectMenu({"Mark", "Previous", "Frame"})
        fcp:selectMenu({"Mark", "Previous", "Frame"})

        --------------------------------------------------------------------------------
        -- Get timeline contents:
        --------------------------------------------------------------------------------
        local content = fcp.timeline.contents
        local playheadX = content.playhead:position()

        local clips = content:clipsUI(false, function(clip)
            local frame = clip:frame()
            return playheadX >= frame.x and playheadX < (frame.x + frame.w)
        end)

        if clips == nil then
            --------------------------------------------------------------------------------
            -- Restore audio role & Finder Tags Setting:
            --------------------------------------------------------------------------------
            fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
            fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

            -------------------------------------------------------------------------------
            -- Display Error Message:
            --------------------------------------------------------------------------------
            displayErrorMessage("The Text to Speech tool could not detect any clips it just inserted into the timeline, and therefore has aborted.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Sort the table:
        --------------------------------------------------------------------------------
        table.sort(clips, function(a, b) return a:position().y > b:position().y end)

        --------------------------------------------------------------------------------
        -- Find our clip:
        --------------------------------------------------------------------------------
        local clip
        if #clips > 0 then
            for _, v in ipairs(clips) do
                local wantedValue = "Audio-Clip:" .. mod._lastFilename
                wantedValue = wantedValue:sub(1, 193)
                local currentValue = v:attributeValue("AXDescription"):sub(1, 193)
                if currentValue == wantedValue then
                    clip = v
                    break
                end
            end
        end
        if not clip then
            --------------------------------------------------------------------------------
            -- Restore audio role & Finder Tags Setting:
            --------------------------------------------------------------------------------
            fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
            fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

            -------------------------------------------------------------------------------
            -- Display Error Message:
            --------------------------------------------------------------------------------
            displayErrorMessage("The Text to Speech tool could not detect the clip it just inserted into the timeline, and therefore has aborted.")
            return
        end
        lastClip = clip
    end

    --------------------------------------------------------------------------------
    -- Add Text to Notes Field After Import:
    --------------------------------------------------------------------------------
    if mod.addTextToNotesFieldAfterImport() then
        --------------------------------------------------------------------------------
        -- Select clip:
        --------------------------------------------------------------------------------
        local content = fcp.timeline.contents
        content:selectClip(lastClip)

        --------------------------------------------------------------------------------
        -- Reveal in Browser:
        --------------------------------------------------------------------------------
        fcp:selectMenu({"File", "Reveal in Browser"})

        --------------------------------------------------------------------------------
        -- Make sure the Browser is visible:
        --------------------------------------------------------------------------------
        local libraries = fcp.browser.libraries
        libraries:show()
        if not libraries:isShowing() then
            --------------------------------------------------------------------------------
            -- Restore audio role & Finder Tags Setting:
            --------------------------------------------------------------------------------
            fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
            fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

            -------------------------------------------------------------------------------
            -- Display Error Message:
            --------------------------------------------------------------------------------
            displayErrorMessage("The Text to Speech tool could not open the Libraries Browser, and therefore has aborted.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Get number of Selected Browser Clips:
        --------------------------------------------------------------------------------
        clips = libraries:selectedClipsUI()
        if #clips ~= 1 then
            --------------------------------------------------------------------------------
            -- Maybe Reveal in Browser failed, so let's try again.
            --------------------------------------------------------------------------------
            log.df("Reveal in Browser might have failed, so let's try again.")
            fcp:selectMenu({"Window", "Go To", "Timeline"})
            fcp:selectMenu({"File", "Reveal in Browser"})
            clips = libraries:selectedClipsUI()
            if #clips ~= 1 then
                --------------------------------------------------------------------------------
                -- Restore audio role & Finder Tags Setting:
                --------------------------------------------------------------------------------
                fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
                fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

                -------------------------------------------------------------------------------
                -- Display Error Message:
                --------------------------------------------------------------------------------
                displayErrorMessage("The Text to Speech tool could not find the newly created clip in the Browser, and therefore has aborted.")
                return false
            end
        end

        --------------------------------------------------------------------------------
        -- Check to see if we're in Filmstrip or List View:
        --------------------------------------------------------------------------------
        local filmstripView = false
        if libraries:isFilmstripView() then
            filmstripView = true
            libraries:toggleViewMode()
        end

        --------------------------------------------------------------------------------
        -- Get Selected Clip & Selected Clip's Parent:
        --------------------------------------------------------------------------------
        local selectedClip = libraries:selectedClipsUI()[1]
        local selectedClipParent = selectedClip:attributeValue("AXParent")

        --------------------------------------------------------------------------------
        -- Get the AXGroup:
        --------------------------------------------------------------------------------
        local listHeadingGroup = axutils.childWithRole(selectedClipParent, "AXGroup")

        --------------------------------------------------------------------------------
        -- Find the 'Notes' column:
        --------------------------------------------------------------------------------
        local notesFieldID = nil
        for i=1, listHeadingGroup:attributeValueCount("AXChildren") do
            local title = listHeadingGroup[i]:attributeValue("AXTitle")
            if title == fcp:string("FFInspectorModuleProjectPropertiesNotes") then
                notesFieldID = i
            end
        end

        --------------------------------------------------------------------------------
        -- If the 'Notes' column is missing:
        --------------------------------------------------------------------------------
        local notesPressed = false
        if notesFieldID == nil then
            listHeadingGroup:performAction("AXShowMenu")
            local menu = axutils.childWithRole(listHeadingGroup, "AXMenu")
            for i=1, menu:attributeValueCount("AXChildren") do
                if not notesPressed then
                    local title = menu[i]:attributeValue("AXTitle")
                    if title == fcp:string("FFInspectorModuleProjectPropertiesNotes") then
                        menu[i]:performAction("AXPress")
                        notesPressed = true
                        for a=1, listHeadingGroup:attributeValueCount("AXChildren") do
                            local titleA = listHeadingGroup[i]:attributeValue("AXTitle")
                            if titleA == fcp:string("FFInspectorModuleProjectPropertiesNotes") then
                                notesFieldID = a
                            end
                        end
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- If the 'Notes' column is missing then error:
        --------------------------------------------------------------------------------
        if notesFieldID == nil then
            --------------------------------------------------------------------------------
            -- Restore audio role & Finder Tags Setting:
            --------------------------------------------------------------------------------
            fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
            fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

            -------------------------------------------------------------------------------
            -- Display Error Message:
            --------------------------------------------------------------------------------
            displayErrorMessage("The Text to Speech tool could not find the Notes column in the browser, and therefore has aborted.")
            return
        end

        local selectedNotesField = selectedClip[notesFieldID][1]
        selectedNotesField:setAttributeValue("AXFocused", true)
        selectedNotesField:setAttributeValue("AXValue", mod._lastTextToSpeak)
        selectedNotesField:performAction("AXConfirm")
        selectedNotesField:setAttributeValue("AXFocused", false)

        --------------------------------------------------------------------------------
        -- Restore Filmstrip View:
        --------------------------------------------------------------------------------
        if filmstripView then
            libraries:toggleViewMode()
        end

        --------------------------------------------------------------------------------
        -- Remove from Timeline if appropriate:
        --------------------------------------------------------------------------------
        if not mod.insertIntoTimeline() then
            --------------------------------------------------------------------------------
            -- Check if Timeline can be enabled:
            --------------------------------------------------------------------------------
            if fcp.menu:isEnabled({"Window", "Go To", "Timeline"}) then
                fcp:selectMenu({"Window", "Go To", "Timeline"})
            else
                --------------------------------------------------------------------------------
                -- Restore audio role & Finder Tags Setting:
                --------------------------------------------------------------------------------
                fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
                fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

                -------------------------------------------------------------------------------
                -- Display Error Message:
                --------------------------------------------------------------------------------
                displayErrorMessage("The Text to Speech tool failed to trigger the 'Window > Go To Timeline' menu item, and therefore has aborted.")
                return
            end

            --------------------------------------------------------------------------------
            -- Delete the clip:
            --------------------------------------------------------------------------------
            fcp:selectMenu({"Edit", "Delete"})
        end
    else
        --------------------------------------------------------------------------------
        -- Remove from Timeline if appropriate:
        --------------------------------------------------------------------------------
        if not mod.insertIntoTimeline() then
            if not fcp:selectMenu({"Edit", "Undo Paste"}, {pressAll = true}) then
                --------------------------------------------------------------------------------
                -- Restore audio role & Finder Tags Setting:
                --------------------------------------------------------------------------------
                fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
                fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

                -------------------------------------------------------------------------------
                -- Display Error Message:
                --------------------------------------------------------------------------------
                displayErrorMessage("The Text to Speech tool failed to trigger the 'Undo Paste' Shortcut, and therefore has aborted.")
                return
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Add Caption:
    --------------------------------------------------------------------------------
    if mod.addCaption() then
        fcp:selectMenu({"View", "Zoom to Fit"})
        local originalMousePoint = mouse.absolutePosition()
        local point = { x = lastClip:position().x + lastClip:frame().w/2, y = lastClip:position().y + lastClip:frame().h/2}
        mouse.absolutePosition(point)
        eventtap.leftClick(point)
        fcp:selectMenu({"Mark", "Set Clip Range"})
        fcp:selectMenu({"Edit", "Captions", "Add Caption"})
        pasteboard.setContents(mod._lastTextToSpeak)
        fcp:selectMenu({"Edit", "Paste"})
        eventtap.leftClick(point)
        mouse.absolutePosition(originalMousePoint)
    end

    --------------------------------------------------------------------------------
    -- We previous went back two frames, so lets go forward to frames to correct:
    --------------------------------------------------------------------------------
    if mod.addTextToNotesFieldAfterImport() or mod.addCaption() then
        --------------------------------------------------------------------------------
        -- Go back two frames:
        --------------------------------------------------------------------------------
        fcp:selectMenu({"Mark", "Next", "Frame"})
        fcp:selectMenu({"Mark", "Next", "Frame"})
    end

    --------------------------------------------------------------------------------
    -- After a two second delay...
    --------------------------------------------------------------------------------
    doAfter(2, function()
        --------------------------------------------------------------------------------
        -- Restore audio role & Finder Tags Setting:
        --------------------------------------------------------------------------------
        fcp.preferences:set("FFImportAudioRoleGroupOverrideRoleDef", originalRole)
        fcp.preferences:set("FFImportTagsAsKeywordCollectionsKey", originalImportTags)

        --------------------------------------------------------------------------------
        -- Restore original Pasteboard Content:
        --------------------------------------------------------------------------------
        pasteboard.writeAllData(originalPasteboard)
        if mod.pasteboardManager then
            mod.pasteboardManager.startWatching()
        end
    end)

    --------------------------------------------------------------------------------
    -- Delete File After Import:
    --------------------------------------------------------------------------------
    if copyToMediaFolder and mod.deleteFileAfterImport() then
        doAfter(DELETE_DELAY, function()
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
            title = firstToUpper(v),
            fn = function()
                mod.voice(v)
            end,
            checked = (v == mod.voice() and v ~= speech.defaultVoice()),
        }
    end
    local rightClickMenu = {
        { title = i18n("selectVoice"), menu = voicesMenu },
        { title = "-" },
        { title = i18n("importOptions"),
            menu = {
                { title = i18n("insertIntoTimeline"),
                    checked = mod.insertIntoTimeline(),
                    fn = function()
                        mod.insertIntoTimeline:toggle()
                    end,
                },
                { title = "-" },
                { title = i18n("addCaption"),
                    checked = mod.addCaption(),
                    fn = function()
                        mod.addCaption:toggle()
                    end,
                },
                { title = i18n("addTextToNotesFieldAfterImport"),
                    checked = mod.addTextToNotesFieldAfterImport(),
                    fn = function()
                        mod.addTextToNotesFieldAfterImport:toggle()
                    end,
                },
                { title = i18n("assignClipAudioRoleToVoiceName"), checked = mod.assignClipAudioRoleToVoiceName(),
                    fn = function()
                        mod.assignClipAudioRoleToVoiceName:toggle()
                    end,
                },
                { title = "-" },
                { title = i18n("deleteFileAfterImport"),
                    disabled = not mod.copyToMediaFolder(),
                    checked = mod.copyToMediaFolder() and mod.deleteFileAfterImport(),
                    fn = function()
                        mod.deleteFileAfterImport:toggle()
                    end,
                },
                { title = "-" },
                { title = i18n("changeDestinationFolder"),
                    fn = function()
                        mod.chooser:hide()
                        mod.chooseFolder()
                        mod.chooser:show()
                    end,
                },
            }
        },
        { title = i18n("keywordOptions"),
            menu = {
                { title = i18n("addKeywordForVoiceName"), checked = mod.addKeywordForVoiceName(),
                    fn = function()
                        mod.addKeywordForVoiceName:toggle()
                    end,
                },
                { title = i18n("addCustomKeyword"), checked = mod.addCustomKeyword(),
                    fn = function()
                        mod.addCustomKeyword:toggle()
                    end,
                },
                { title = "-" },
                { title = i18n("setCustomKeyword"), fn = function()
                        mod.chooser:hide()
                        local result = displayTextBoxMessage(i18n("enterCustomKeyword"), i18n("enterCustomKeywordError"), mod.tag(), mod._tagValidation)
                        if result then
                            mod.tag(result)
                        end
                        mod.chooser:show()
                    end,
                },
            },
        },
        { title = i18n("clipNamingOptions"),
            menu = {
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
                { title = i18n("setFilenamePrefix"),
                    fn = function()
                        mod.chooser:hide()
                        local result = mod.customPrefix(displayTextBoxMessage(i18n("pleaseEnterAPrefix") .. ":", i18n("customPrefixError"), mod.customPrefix(), function(value)
                            if value and type("value") == "string" and value ~= tools.trim("") and tools.safeFilename(value, value) == value then
                                return true
                            else
                                return false
                            end
                        end))
                        if type(result) == "string" then
                            mod.customPrefix(result)
                        end
                        mod.chooser:show()
                    end,
                },
                { title = i18n("setIncrementalNumber"),
                    fn = function()
                        mod.chooser:hide()
                        local result = displaySmallNumberTextBoxMessage(i18n("setIncrementalNumberMessage"), i18n("setIncrementalNumberError"), mod.currentIncrementalNumber())
                        if type(result) == "number" then
                            mod.currentIncrementalNumber(result)
                        end
                        mod.chooser:show()
                    end,
                },
                { title = "-" },
                { title = i18n("resetIncrementalNumber"),
                    fn = function()
                        mod.currentIncrementalNumber(1)
                    end,
                },
            },
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
        :popupMenu(mouse.absolutePosition(), true)
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
    local result = fcp.menu:isEnabled({"Window", "Go To", "Timeline"})
    if not result then
        log.wf("Failed to activate timeline in Text to Speech Plugin.")
    end

    --------------------------------------------------------------------------------
    -- If directory doesn't exist then prompt user to select a new folder:
    --------------------------------------------------------------------------------
    if not doesDirectoryExist(mod.path()) then
        local folderResult = mod.chooseFolder()
        if not folderResult then
            return
        else
            mod.path(folderResult)
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

--- plugins.finalcutpro.text2speech.insertFromPasteboard() -> none
--- Function
--- Inserts Text to Speech by reading the Pasteboard.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.insertFromPasteboard()
    local pasteboardString = pasteboard.readString()
    if pasteboardString then
        --------------------------------------------------------------------------------
        -- If directory doesn't exist then prompt user to select a new folder:
        --------------------------------------------------------------------------------
        if not doesDirectoryExist(mod.path()) then
            local folderResult = mod.chooseFolder()
            if not folderResult then
                return
            else
                mod.path(folderResult)
            end
        end

        --------------------------------------------------------------------------------
        -- Build table:
        --------------------------------------------------------------------------------
        local result = {}
        result.text = pasteboardString

        --------------------------------------------------------------------------------
        -- Add to history:
        --------------------------------------------------------------------------------
        local history = mod.history()
        table.insert(history, 1, result)
        mod.history(history)

        --------------------------------------------------------------------------------
        -- Trigger Completion Function:
        --------------------------------------------------------------------------------
        mod._completionFn(result)
    else
        playErrorSound()
    end
end

local plugin = {
    id              = "finalcutpro.text2speech",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.pasteboard.manager"]   = "pasteboardManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Define Plugins:
    --------------------------------------------------------------------------------
    mod.pasteboardManager = deps.pasteboardManager

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpText2Speech")
        :whenActivated(mod.show)

    deps.fcpxCmds:add("cpText2SpeechFromPasteboard")
        :whenActivated(mod.insertFromPasteboard)

    return mod
end

return plugin
