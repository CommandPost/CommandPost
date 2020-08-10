--- === plugins.finalcutpro.export.batch ===
---
--- Timeline Batch Export Plugin.

local require               = require

local log                   = require "hs.logger".new("batch")

local eventtap              = require "hs.eventtap"
local fnutils               = require "hs.fnutils"
local fs                    = require "hs.fs"
local geometry              = require "hs.geometry"
local image                 = require "hs.image"
local mouse                 = require "hs.mouse"

local compressor            = require "cp.apple.compressor"
local config                = require "cp.config"
local destinations          = require "cp.apple.finalcutpro.export.destinations"
local dialog                = require "cp.dialog"
local Do                    = require "cp.rx.go.Do"
local fcp                   = require "cp.apple.finalcutpro"
local html                  = require "cp.web.html"
local i18n                  = require "cp.i18n"
local just                  = require "cp.just"
local tools                 = require "cp.tools"

local displayChooseFolder   = dialog.displayChooseFolder
local displayChooseFromList = dialog.displayChooseFromList
local displayErrorMessage   = dialog.displayErrorMessage
local displayMessage        = dialog.displayMessage
local displayTextBoxMessage = dialog.displayTextBoxMessage

local doesDirectoryExist    = tools.doesDirectoryExist
local iconFallback          = tools.iconFallback
local incrementFilename     = tools.incrementFilename
local ninjaMouseClick       = tools.ninjaMouseClick
local safeFilename          = tools.safeFilename
local spairs                = tools.spairs
local stringMaxLength       = tools.stringMaxLength
local trim                  = tools.trim

local doUntil               = just.doUntil
local wait                  = just.wait

local imageFromPath         = image.imageFromPath
local insert                = table.insert

local pathToAbsolute        = fs.pathToAbsolute

local mod = {}

--- plugins.finalcutpro.export.batch.DEFAULT_CUSTOM_FILENAME -> string
--- Constant
--- Default Custom Filename
mod.DEFAULT_CUSTOM_FILENAME = i18n("batchExport")

-- plugins.finalcutpro.export.batch._existingClipNames -> table
-- Variable
-- Table of existing clip names.
mod._existingClipNames = {}

-- plugins.finalcutpro.export.batch._clips -> table
-- Variable
-- Table of clips to batch export.
mod._clips = {}

-- plugins.finalcutpro.export.batch._nextID -> number
-- Variable
-- Next available ID for building the UI.
mod._nextID = 0

--- plugins.finalcutpro.export.batch.destinationPreset <cp.prop: boolean>
--- Field
--- Destination Preset.
mod.destinationPreset = config.prop("batchExportDestinationPreset")

--- plugins.finalcutpro.export.batch.replaceExistingFiles <cp.prop: boolean>
--- Field
--- Defines whether or not a Batch Export should Replace Existing Files.
mod.replaceExistingFiles = config.prop("batchExportReplaceExistingFiles", false)

--- plugins.finalcutpro.export.batch.useCustomFilename <cp.prop: boolean>
--- Field
--- Defines whether or not the Batch Export tool should override the clipname with a custom filename.
mod.useCustomFilename = config.prop("batchExportOverrideClipnameWithCustomFilename", false)

--- plugins.finalcutpro.export.batch.customFilename <cp.prop: string>
--- Field
--- Custom Filename for Batch Export.
mod.customFilename = config.prop("batchExportCustomFilename", mod.DEFAULT_CUSTOM_FILENAME)

--- plugins.finalcutpro.export.batch.ignoreMissingEffects <cp.prop: boolean>
--- Field
--- Defines whether or not a Batch Export should Ignore Missing Effects.
mod.ignoreMissingEffects = config.prop("batchExportIgnoreMissingEffects", false)

--- plugins.finalcutpro.export.batch.ignoreInvalidCaptions <cp.prop: boolean>
--- Field
--- Defines whether or not a Batch Export should Ignore Invalid Captions.
mod.ignoreInvalidCaptions = config.prop("batchExportIgnoreInvalidCaptions", false)

--- plugins.finalcutpro.export.batch.ignoreProxies <cp.prop: boolean>
--- Field
--- Defines whether or not a Batch Export should Ignore Proxies.
mod.ignoreProxies = config.prop("batchExportIgnoreProxies", false)

--- plugins.finalcutpro.export.batch.ignoreBackgroundTasks <cp.prop: boolean>
--- Field
--- Defines whether or not a Batch Export should Ignore Background Tasks.
mod.ignoreBackgroundTasks = config.prop("batchExportIgnoreBackgroundTasks", false)

--- plugins.finalcutpro.export.batch.batchExportTimelineClips(clips) -> boolean
--- Function
--- Batch Export Timeline Clips
---
--- Parameters:
---  * clips - table of selected Clips
---  * sendToCompressor - `true` if sending to Compressor, otherwise `false`
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.batchExportTimelineClips(clips, sendToCompressor)

    --------------------------------------------------------------------------------
    -- Launch Compressor if needed:
    --------------------------------------------------------------------------------
    if sendToCompressor then
        if not compressor:isRunning() then
            if not doUntil(function()
                compressor:launch()
                return compressor:isFrontmost()
            end, 5, 0.1) then
                displayErrorMessage("Failed to Launch Compressor.")
                return false
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    local isOnPrimaryStoryline  = true
    local firstTime             = true
    local exportPath            = mod.getDestinationFolder()
    local destinationPreset     = mod.getDestinationPreset()
    local errorFunction         = "\n\nError occurred in batchExportTimelineClips()."
    local originalMousePosition = mouse.getAbsolutePosition()

    --------------------------------------------------------------------------------
    -- Process each clip individually:
    --------------------------------------------------------------------------------
    if not clips then
        displayErrorMessage("No selected clips detected. This shouldn't happen." .. errorFunction)
        return false
    end
    local sortFn = function(t,a,b)
        if t and t[a] and t[b] and t[a].attributeValue and t[b].attributeValue then
            return (t[a]:attributeValue("AXValueDescription") or "") < (t[b]:attributeValue("AXValueDescription") or "")
        end
    end
    local playhead = fcp:timeline():playhead()
    local timelineContents = fcp:timeline():contents()
    for _,clip in spairs(clips, sortFn) do
        --------------------------------------------------------------------------------
        -- Make sure Final Cut Pro is Active:
        --------------------------------------------------------------------------------
        if not doUntil(function()
            fcp:launch()
            return fcp:isFrontmost()
        end, 5, 0.1) then
            displayErrorMessage("Failed to switch back to Final Cut Pro.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Make sure the Timeline is focussed:
        --------------------------------------------------------------------------------
        if not doUntil(function()
            fcp:selectMenu({"Window", "Go To", "Timeline"})
            return fcp:timeline():contents():isFocused()
        end, 5, 0.1) then
            displayErrorMessage("Failed to focus on timeline.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Select clip:
        --------------------------------------------------------------------------------
        if not doUntil(function()
            timelineContents:selectClip(clip)
            local selectedClips = timelineContents:selectedClipsUI(true)
            return selectedClips and #selectedClips == 1 and selectedClips[1] == clip
        end, 5, 0.1) then
            displayErrorMessage("Failed to select clip." .. errorFunction)
            return false
        end

        --------------------------------------------------------------------------------
        -- Get Clip Name whilst we're at it:
        --------------------------------------------------------------------------------
        local clipName = clip:attributeValue("AXDescription")
        if not clipName then
            displayErrorMessage("Could not get clip name." .. errorFunction)
            return false
        end
        local columnPostion = string.find(clipName, ":")
        if columnPostion then
            clipName = string.sub(clipName, columnPostion + 1)
        end

        --------------------------------------------------------------------------------
        -- Check to see if there's any clips above or below the selected clip:
        --------------------------------------------------------------------------------
        local originalFrame = clip:frame()
        local verticalClips = timelineContents:clipsUI(false, function(c)
            local newFrame = c:frame()
            return newFrame.x > originalFrame.x and newFrame.x < (originalFrame.x + originalFrame.w)
            or originalFrame.x > newFrame.x and originalFrame.x < (newFrame.x + newFrame.w)

        end)
        if #verticalClips > 0 then
            isOnPrimaryStoryline = false
        else
            isOnPrimaryStoryline = true
        end

        --------------------------------------------------------------------------------
        -- Mark > Go to > Range Start:
        --------------------------------------------------------------------------------
        if not fcp:selectMenu({"Mark", "Go to", "Range Start"}) then
            displayErrorMessage("Failed to trigger Range Start.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Mark Clip Range:
        --------------------------------------------------------------------------------
        if not isOnPrimaryStoryline then
            local point = { x = originalFrame.x + originalFrame.w/2, y = originalFrame.y + originalFrame.h/2}
            mouse.setAbsolutePosition(point)
            eventtap.leftClick(point)
        end
        if not fcp:selectMenu({"Mark", "Set Clip Range"}) then
            displayErrorMessage("Failed Set Clip Range.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Click on the Playhead (if we haven't already done above), as this
        -- seems to be the only way to ensure that the timeline has focus:
        --------------------------------------------------------------------------------
        if isOnPrimaryStoryline then
            local playheadUI = playhead and playhead:UI()
            local playheadFrame = playheadUI and playheadUI:frame()
            local center = playheadFrame and geometry(playheadFrame).center
            if center then
                ninjaMouseClick(center)
                wait(1)
            end
        end

        --------------------------------------------------------------------------------
        -- Make sure the Timeline is focused:
        --------------------------------------------------------------------------------
        if not doUntil(function()
            fcp:selectMenu({"Window", "Go To", "Timeline"})
            return fcp:timeline():contents():isFocused()
        end, 5, 0.1) then
            displayErrorMessage("Failed to focus on timeline.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Send to Compressor:
        --------------------------------------------------------------------------------
        if sendToCompressor then
            --------------------------------------------------------------------------------
            -- Trigger Export:
            --------------------------------------------------------------------------------
            if not fcp:selectMenu({"File", "Send to Compressor"}) then
                displayErrorMessage("Could not trigger 'Send to Compressor'.")
                return false
            end
        else
            --------------------------------------------------------------------------------
            -- Trigger Export:
            --------------------------------------------------------------------------------
            local exportDialog = fcp.exportDialog
            local errorMessage
            _, errorMessage = exportDialog:show(destinationPreset, mod.ignoreProxies(), mod.ignoreMissingEffects(), mod.ignoreInvalidCaptions())
            if errorMessage then
                return false
            end

            --------------------------------------------------------------------------------
            -- Get the file extension for later:
            --------------------------------------------------------------------------------
            local fileExtension = exportDialog:fileExtension()

            --------------------------------------------------------------------------------
            -- Press 'Next':
            --------------------------------------------------------------------------------
            exportDialog:pressNext()

            --------------------------------------------------------------------------------
            -- If 'Next' has been clicked (as opposed to 'Share'):
            --------------------------------------------------------------------------------
            local saveSheet = exportDialog.saveSheet
            if exportDialog:isShowing() then

                --------------------------------------------------------------------------------
                -- Click 'Save' on the save sheet:
                --------------------------------------------------------------------------------
                if not doUntil(function() return saveSheet:isShowing() end) then
                    displayErrorMessage("Failed to open the 'Save' window." .. errorFunction)
                    return false
                end

                --------------------------------------------------------------------------------
                -- Set Custom Export Path (or Default to Desktop) on the first clip if
                -- necessary by checking the Preferences file first:
                --------------------------------------------------------------------------------
                if firstTime then
                    local NSNavLastRootDirectory = fcp.preferences.NSNavLastRootDirectory
                    if not NSNavLastRootDirectory or (pathToAbsolute(NSNavLastRootDirectory) ~= pathToAbsolute(exportPath)) then
                        saveSheet:setPath(exportPath)
                    end
                    firstTime = false
                end

                --------------------------------------------------------------------------------
                -- Make sure we don't already have a clip with the same name in the batch:
                --------------------------------------------------------------------------------
                local filename = saveSheet:filename():getValue()
                if filename then
                    local newFilename = clipName

                    --------------------------------------------------------------------------------
                    -- Inject Custom Filenames:
                    --------------------------------------------------------------------------------
                    local customFilename = mod.customFilename()
                    local useCustomFilename = mod.useCustomFilename()
                    if useCustomFilename and customFilename then
                        newFilename = customFilename
                        --------------------------------------------------------------------------------
                        -- Process variables:
                        --------------------------------------------------------------------------------
                        newFilename = string.gsub(newFilename, "{original}", clipName)
                        newFilename = string.gsub(newFilename, "{yyyy}", os.date("%Y"))
                        newFilename = string.gsub(newFilename, "{yy}", os.date("%y"))
                        newFilename = string.gsub(newFilename, "{mm}", os.date("%m"))
                        newFilename = string.gsub(newFilename, "{dd}", os.date("%d"))
                        newFilename = string.gsub(newFilename, "{hh}", os.date("%H"))
                        newFilename = string.gsub(newFilename, "{mm}", os.date("%M"))
                        newFilename = string.gsub(newFilename, "{ss}", os.date("%S"))
                    end

                    --------------------------------------------------------------------------------
                    -- Increment filename is filename already exists in this batch:
                    --------------------------------------------------------------------------------
                    while fnutils.contains(mod._existingClipNames, newFilename) do
                        newFilename = incrementFilename(newFilename)
                    end

                    --------------------------------------------------------------------------------
                    -- Increment filename is filename already exists in the output directory:
                    --------------------------------------------------------------------------------
                    while tools.doesFileExist(exportPath .. "/" .. newFilename .. fileExtension) do
                        newFilename = incrementFilename(newFilename)
                    end

                    --------------------------------------------------------------------------------
                    -- Update the filename and save it for comparison of next clip:
                    --------------------------------------------------------------------------------
                    if filename ~= newFilename then
                        saveSheet:filename():setValue(newFilename)
                    end
                    table.insert(mod._existingClipNames, newFilename)
                end

                --------------------------------------------------------------------------------
                -- Click 'Save' on the save sheet:
                --------------------------------------------------------------------------------
                saveSheet:pressSave()

            end

            --------------------------------------------------------------------------------
            -- Make sure Save Window is closed:
            --------------------------------------------------------------------------------
            while saveSheet:isShowing() do
                local replaceAlert = saveSheet:replaceAlert()
                if mod.replaceExistingFiles() and replaceAlert:isShowing() then
                    replaceAlert:pressReplace()
                else
                    replaceAlert:pressCancel()

                    local originalFilename = saveSheet:filename():getValue()
                    if originalFilename == nil then
                        displayErrorMessage("Failed to get the original Filename." .. errorFunction)
                        return false
                    end

                    local newFilename = incrementFilename(originalFilename)

                    saveSheet:filename():setValue(newFilename)
                    saveSheet:pressSave()
                end
            end

            --------------------------------------------------------------------------------
            -- Give Final Cut Pro a chance to show the "Preparing" modal dialog:
            --
            -- NOTE: I tried to avoid doing this, but it seems to be the only way to
            --       ensure the "Preparing" modal dialog actually appears. If I try and
            --       use a just.doUntil(), it seems to block Final Cut Pro from actually
            --       opening the "Preparing" modal dialog.
            --------------------------------------------------------------------------------
            wait(4)

            --------------------------------------------------------------------------------
            -- Wait until the "Preparing" modal dialog closes or the
            -- Background Tasks Dialog opens:
            --------------------------------------------------------------------------------
            local backgroundTasksDialog = fcp:backgroundTasksDialog()
            if fcp:isModalDialogOpen() then
                doUntil(function()
                    return backgroundTasksDialog:isShowing() or fcp:isModalDialogOpen() == false
                end, 15)
            end

            --------------------------------------------------------------------------------
            -- Check for Background Tasks warning:
            --------------------------------------------------------------------------------
            local ignoreBackgroundTasks = mod.ignoreBackgroundTasks()
            if backgroundTasksDialog:isShowing() then
                if ignoreBackgroundTasks then
                    backgroundTasksDialog:continue():press()
                else
                    backgroundTasksDialog:cancel():press()
                    displayMessage(i18n("batchExportBackgroundTasksDetected"))
                    return false
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Restore Mouse position:
    --------------------------------------------------------------------------------
    if not isOnPrimaryStoryline then
        mouse.setAbsolutePosition(originalMousePosition)
    end

    --------------------------------------------------------------------------------
    -- Reselect the original list of clips:
    --------------------------------------------------------------------------------
    timelineContents:selectClips(clips)
    return true
end

--- plugins.finalcutpro.export.batch.changeExportDestinationPreset() -> none
--- Function
--- Change Export Destination Preset.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.changeExportDestinationPreset()
    Do(function()
        local destinationList, destinationListError = destinations.names()
        local currentPreset = mod.destinationPreset()

        if not destinationList then
            log.ef("Destination List Error: %s", destinationListError)
            destinationList = {}
        end

        if compressor.isInstalled() then
            insert(destinationList, 1, i18n("sendToCompressor"))
        end

        local result = displayChooseFromList(i18n("selectDestinationPreset"), destinationList, {currentPreset})

        if result and #result > 0 then
            mod.destinationPreset(result[1])
        end

        --------------------------------------------------------------------------------
        -- Refresh the Preferences:
        --------------------------------------------------------------------------------
        mod._bmMan.refresh()
    end):After(0)
end

--- plugins.finalcutpro.export.batch.changeExportDestinationFolder() -> none
--- Function
--- Change Export Destination Folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.changeExportDestinationFolder()
    Do(function()
        local result = displayChooseFolder(i18n("selectDestinationFolder"))
        if result ~= false then
            config.set("batchExportDestinationFolder", result)

            --------------------------------------------------------------------------------
            -- Refresh the Preferences:
            --------------------------------------------------------------------------------
            mod._bmMan.refresh()
        end
    end):After(0)
end

--- plugins.finalcutpro.export.batch.changeCustomFilename() -> none
--- Function
--- Change Custom Filename String.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.changeCustomFilename()
    Do(function()
        local result = mod.customFilename(displayTextBoxMessage(i18n("enterCustomFilename"), i18n("enterCustomFilenameError"), mod.customFilename(), function(value)
            if value and type("value") == "string" and value ~= trim("") and safeFilename(value, value) == value then
                return true
            else
                return false
            end
        end))
        if type(result) == "string" then
            mod.customFilename(result)
        end

        --------------------------------------------------------------------------------
        -- Refresh the Preferences:
        --------------------------------------------------------------------------------
        mod._bmMan.refresh()
    end):After(0)
end

--- plugins.finalcutpro.export.batch.getDestinationFolder() -> string
--- Function
--- Gets the destination folder path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The destination folder path as a string.
function mod.getDestinationFolder()
    local batchExportDestinationFolder = config.get("batchExportDestinationFolder")
    local NSNavLastRootDirectory = fcp.preferences.NSNavLastRootDirectory
    local exportPath = os.getenv("HOME") .. "/Desktop"
    if batchExportDestinationFolder ~= nil then
         if doesDirectoryExist(batchExportDestinationFolder) then
            exportPath = batchExportDestinationFolder
         end
    else
        if doesDirectoryExist(NSNavLastRootDirectory) then
            exportPath = NSNavLastRootDirectory
        end
    end
    return exportPath and pathToAbsolute(exportPath)
end

--- plugins.finalcutpro.export.batch.getDestinationFolder() -> string | nil
--- Function
--- Gets the destination preset.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The destination preset as a string, or `nil` if no preset is set.
function mod.getDestinationPreset()

    --------------------------------------------------------------------------------
    -- Get Destination Preset from Preferences:
    --------------------------------------------------------------------------------
    local destinationPreset = config.get("batchExportDestinationPreset")

    --------------------------------------------------------------------------------
    -- If it's "Send to Compressor" - make sure Compressor is installed:
    --------------------------------------------------------------------------------
    if destinationPreset == i18n("sendToCompressor") then
        if not compressor:isInstalled() then
            --log.df("Apple Compressor could not be detected.")
            destinationPreset = nil
            config.set("batchExportDestinationPreset", nil)
        end
    end

    --------------------------------------------------------------------------------
    -- If there's no existing destination, then try use the Default Destination:
    --------------------------------------------------------------------------------
    if destinationPreset == nil then
        local defaultItem = fcp:menu():findMenuUI({"File", "Share", function(menuItem)
            return menuItem:attributeValue("AXMenuItemCmdChar") ~= nil
        end})
        if defaultItem ~= nil then
            local title = defaultItem:attributeValue("AXTitle")
            if title then
                --log.df("Using Default Destination: '%s'", title)
                --------------------------------------------------------------------------------
                -- Remove the " (default)…" if it exists:
                --------------------------------------------------------------------------------
                if title:sub(-13) == " (default)…" then
                    title = title:sub(1, -14)
                end
                destinationPreset = title
            end
        end
    end

    --------------------------------------------------------------------------------
    -- If that fails, try the first item on the list:
    --------------------------------------------------------------------------------
    if destinationPreset == nil then
        local firstItem = fcp:menu():findMenuUI({"File", "Share", 1})
        if firstItem ~= nil then
            local title = firstItem:attributeValue("AXTitle")
            if title then
                --------------------------------------------------------------------------------
                -- Remove the "…" if it exists:
                --------------------------------------------------------------------------------
                if title:sub(-3) == "…" then
                    title = title:sub(1, -4)
                end
                destinationPreset = title
            end
        end
    end

    --------------------------------------------------------------------------------
    -- If that fails, try using Compressor if installed:
    --------------------------------------------------------------------------------
    if destinationPreset == nil then
        if compressor:isInstalled() then
            destinationPreset = i18n("sendToCompressor")
        end
    end

    return destinationPreset
end

--- plugins.finalcutpro.export.batch.batchExport() -> boolean
--- Function
--- Opens the Batch Export popup.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.batchExport()
    --------------------------------------------------------------------------------
    -- Make sure Final Cut Pro is Active:
    --------------------------------------------------------------------------------
    if not doUntil(function()
        fcp:launch()
        return fcp:isFrontmost()
    end, 5, 0.1) then
        displayErrorMessage("Failed to activate Final Cut Pro. Batch Export aborted.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Reset Everything:
    --------------------------------------------------------------------------------
    mod._clips = nil
    mod._existingClipNames = nil
    mod._existingClipNames = {}

    --------------------------------------------------------------------------------
    -- Check if we have any currently-selected clips:
    --------------------------------------------------------------------------------
    local timelineContents = fcp:timeline():contents()
    local selectedClips = timelineContents:selectedClipsUI(true)

    if not selectedClips or #selectedClips == 0 then
        displayMessage(i18n("noSelectedClipsInTimeline"))
        return
    end

    mod._clips = selectedClips

    --------------------------------------------------------------------------------
    -- Show the Batch Export window:
    --------------------------------------------------------------------------------
    mod._bmMan.show()
end

-- clipsToCountString(clips) -> string
-- Function
-- Calculates the numbers of clips supplied and returns the number as a formatted string.
--
-- Parameters:
--  * clips - A table of clips
--
-- Returns:
--  * A string.
local function clipsToCountString(clips)
    local countText = " "
    if clips and #clips > 1 then countText = " " .. tostring(#clips) .. " " end
    return countText
end

--- plugins.finalcutpro.export.batch.performBatchExport() -> none
--- Function
--- Performs the Browser Batch Export function.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.performBatchExport()
    --------------------------------------------------------------------------------
    -- Hide the Window:
    --------------------------------------------------------------------------------
    mod._bmMan.hide()

    --------------------------------------------------------------------------------
    -- Make sure Final Cut Pro is Active:
    --------------------------------------------------------------------------------
    if not doUntil(function()
        fcp:launch()
        return fcp:isFrontmost()
    end, 5, 0.1) then
        displayErrorMessage("Failed to activate Final Cut Pro. Batch Export aborted.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Check to see if we're sending to Compressor:
    --------------------------------------------------------------------------------
    local destinationPreset = mod.getDestinationPreset()
    local sendToCompressor = false
    if destinationPreset == i18n("sendToCompressor") then
        sendToCompressor = true
    end

    --------------------------------------------------------------------------------
    -- Display message:
    --------------------------------------------------------------------------------
    if sendToCompressor then
        displayMessage(i18n("timelineBatchExportCompressorBeginMessage"))
    else
        displayMessage(i18n("timelineBatchExportBeginMessage"))
    end

    --------------------------------------------------------------------------------
    -- Export the clips:
    --------------------------------------------------------------------------------
    if mod.batchExportTimelineClips(mod._clips, sendToCompressor) then
        --------------------------------------------------------------------------------
        -- Batch Export Complete:
        --------------------------------------------------------------------------------
        if sendToCompressor then
            displayMessage(i18n("batchExportCompressorComplete"), {i18n("done")})
        else
            displayMessage(i18n("batchExportComplete"), {i18n("done")})
        end
    end
end

-- nextID() -> number
-- Function
-- Returns the next free ID.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The next ID as a number.
local function nextID()
    mod._nextID = mod._nextID + 1
    return mod._nextID
end

local plugin = {
    id              = "finalcutpro.export.batch",
    group           = "finalcutpro",
    dependencies    = {
        ["core.menu.manager"]                   = "manager",
        ["finalcutpro.menu.manager"]            = "menuManager",
        ["finalcutpro.commands"]                = "fcpxCmds",
        ["finalcutpro.export.batch.manager"]    = "batchExportManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Create the Batch Export window:
    --------------------------------------------------------------------------------
    mod._bmMan = deps.batchExportManager
    local fcpPath = fcp:getPath() or ""

    --------------------------------------------------------------------------------
    -- Timeline Panel:
    --------------------------------------------------------------------------------
    mod._timelinePanel = mod._bmMan.addPanel({
        priority    = 1,
        id          = "timeline",
        label       = i18n("timeline"),
        image       = imageFromPath(iconFallback(fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/FFMediaManagerCompoundClipIcon.png")),
        tooltip     = i18n("timeline"),
        height      = 720,
    })
        :addContent(nextID(), [[
            <script>
                document.addEventListener("keyup", function(event) {
                    // NOTE: 13 is the "return" key on the keyboard
                    if (event.keyCode === 13) {
                        event.preventDefault();
                        document.getElementById("performBatchExportButton").click();
                    }
                });
            </script>
        ]], false)
        :addHeading(nextID(), i18n("batchExportFromTimeline"))
        :addParagraph(nextID(), function()
                local clipCount = mod._clips and #mod._clips or 0
                local clipCountString = clipsToCountString(mod._clips)
                local itemString = i18n("item", {count=clipCount})
                return i18n("finalCutProTimelineBatchExportMessage", {clipCountString=clipCountString, itemString=itemString})
            end)
        :addParagraph(nextID(), html.br())
        :addContent(nextID(), function()
                local destinationPreset = mod.getDestinationPreset()
                if destinationPreset == i18n("sendToCompressor") then
                    return html.p {class="uiItem", style="color:#3f9253; font-weight:bold;"} (i18n("changeDestinationFolderInCompressor"))
                else
                    local destinationFolder = mod.getDestinationFolder()
                    if destinationFolder then
                        local shortDestinationFolder = trim(stringMaxLength(destinationFolder, 48))
                        if shortDestinationFolder ~= destinationFolder then shortDestinationFolder = shortDestinationFolder .. "…" end
                        return html.div {style="white-space: nowrap; overflow: hidden;"} (
                            html.p {class="uiItem", style="color:#5760e7; font-weight:bold;"} (shortDestinationFolder)
                        )
                    else
                        return html.p {class="uiItem", style="color:#d1393e; font-weight:bold;"} (i18n("noDestinationFolderSelected"))
                    end
                end
            end)
        :addParagraph(nextID(), html.br())
        :addButton(nextID(),
            {
                width = 200,
                label = i18n("changeDestinationFolder"),
                onclick = function()
                    local destinationPreset = mod.getDestinationPreset()
                    if destinationPreset == i18n("sendToCompressor") then
                        compressor:launch()
                    else
                        mod.changeExportDestinationFolder()
                    end
                end
            })
        :addParagraph(nextID(), html.br())
        :addParagraph(nextID(), i18n("usingTheFollowingDestinationPreset") .. ":")
        :addParagraph(nextID(), html.br())
        :addContent(nextID(), function()
                local destinationPreset = mod.getDestinationPreset()
                if destinationPreset then
                    --------------------------------------------------------------------------------
                    -- Trim the "(default)…":
                    --------------------------------------------------------------------------------
                    local trimmedDestinationPreset = destinationPreset:match("(.*) %([^()]+%)…$")
                    if trimmedDestinationPreset then
                        destinationPreset = trimmedDestinationPreset
                    end
                    return html.div {style="white-space: nowrap; overflow: hidden;"} (
                        html.p {class="uiItem", style="color:#5760e7; font-weight:bold;"} (destinationPreset)
                    )
                else
                    return html.p {class="uiItem", style="color:#d1393e; font-weight:bold;"} (i18n("noDestinationPresetSelected"))
                end
            end)
        :addParagraph(nextID(), html.br())
        :addButton(nextID(),
            {
                width = 200,
                label = i18n("changeDestinationPreset"),
                onclick = mod.changeExportDestinationPreset
            })
        :addParagraph(nextID(), html.br())
        :addParagraph(nextID(), i18n("usingTheFollowingNamingConvention") .. ":")
        :addParagraph(nextID(), html.br())
        :addContent(nextID(), function()
                local destinationPreset = mod.getDestinationPreset()
                local useCustomFilename = mod.useCustomFilename()
                if destinationPreset == i18n("sendToCompressor") then
                    return html.p {class="uiItem", style="color:#3f9253; font-weight:bold;"} (i18n("changeFilenamesInCompressor"))
                else
                    if useCustomFilename then
                        local customFilename = mod.customFilename() or mod.DEFAULT_CUSTOM_FILENAME
                        return [[<div style="white-space: nowrap; overflow: hidden;"><p class="uiItem" style="color:#5760e7; font-weight:bold;">]] .. customFilename .."</p></div>"
                    else
                        return [[<p class="uiItem" style="color:#3f9253; font-weight:bold;">]] .. i18n("originalClipName") .. [[</p>]]
                    end
                end
            end, false)
        :addParagraph(nextID(), html.br())
        :addButton(nextID(),
            {
                width = 200,
                label = i18n("changeCustomFilename"),
                onclick = function()
                    if mod.getDestinationPreset() == i18n("sendToCompressor") then
                        compressor:launch()
                    else
                        mod.changeCustomFilename()
                    end
                end
            })
        :addHeading(nextID(), "Preferences")
        :addCheckbox(nextID(),
            {
                label = i18n("useCustomFilename"),
                onchange = function(_, params)
                    mod.useCustomFilename(params.checked)

                    --------------------------------------------------------------------------------
                    -- Refresh the Preferences:
                    --------------------------------------------------------------------------------
                    mod._bmMan.refresh()
                end,
                checked = mod.useCustomFilename,
            })
        :addCheckbox(nextID(),
            {
                label = i18n("replaceExistingFiles"),
                onchange = function(_, params) mod.replaceExistingFiles(params.checked) end,
                checked = mod.replaceExistingFiles,
            })
        :addParagraph(nextID(), html.br())
        :addCheckbox(nextID(),
            {
                label = i18n("ignoreMissingEffects"),
                onchange = function(_, params) mod.ignoreMissingEffects(params.checked) end,
                checked = mod.ignoreMissingEffects,
            })
        :addCheckbox(nextID(),
            {
                label = i18n("ignoreProxies"),
                onchange = function(_, params) mod.ignoreProxies(params.checked) end,
                checked = mod.ignoreProxies,
            })
        :addCheckbox(nextID(),
            {
                label = i18n("ignoreInvalidCaptions"),
                onchange = function(_, params) mod.ignoreInvalidCaptions(params.checked) end,
                checked = mod.ignoreInvalidCaptions,
            })
        :addCheckbox(nextID(),
            {
                label = i18n("ignoreBackgroundTasks"),
                onchange = function(_, params) mod.ignoreBackgroundTasks(params.checked) end,
                checked = mod.ignoreBackgroundTasks,
            })
        :addParagraph(nextID(), html.br())
        :addButton(nextID(),
            {
                width = 200,
                label = i18n("performBatchExport"),
                id = "performBatchExportButton",
                onclick = function() mod.performBatchExport() end,
            })

    --------------------------------------------------------------------------------
    -- Add items to Menubar:
    --------------------------------------------------------------------------------
    local menuManager = deps.menuManager
    menuManager.timeline:addItems(1001, function()
        return {
            {
                title       = i18n("batchExportActiveTimeline"),
                fn          = function() mod.batchExport() end,
                disabled    = not fcp:isRunning()
            },
        }
    end)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpBatchExportFromTimeline")
        :activatedBy():ctrl():option():cmd("e")
        :whenActivated(function() mod.batchExport() end)

    --------------------------------------------------------------------------------
    -- Return the module:
    --------------------------------------------------------------------------------
    return mod
end

return plugin
