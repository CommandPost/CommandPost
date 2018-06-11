--- === plugins.finalcutpro.watchfolders.panels.media ===
---
--- Final Cut Pro Media Watch Folder Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("fcpwatch")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap			= require("hs.eventtap")
local fnutils			= require("hs.fnutils")
local fs				= require("hs.fs")
local host				= require("hs.host")
local http				= require("hs.http")
local image				= require("hs.image")
local notify			= require("hs.notify")
local pasteboard		= require("hs.pasteboard")
local pathwatcher		= require("hs.pathwatcher")
local timer				= require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config			= require("cp.config")
local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local just              = require("cp.just")
local tools				= require("cp.tools")
local html				= require("cp.web.html")
local ui				= require("cp.web.ui")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.watchfolders.panels.media.SECONDS_UNTIL_DELETE -> number
--- Constant
--- Seconds until a file is deleted.
mod.SECONDS_UNTIL_DELETE = 30

-- uuid -> string
-- Variable
-- A unique ID.
local uuid = host.uuid

--- plugins.finalcutpro.watchfolders.panels.media.filesInTransit -> table
--- Variable
--- Files currently being copied
mod.filesInTransit = {}

--- plugins.finalcutpro.watchfolders.panels.media.watchFolderTableID -> string
--- Variable
--- Watch Folder Table ID
mod.watchFolderTableID = "fcpMediaWatchFoldersTable"

--- plugins.finalcutpro.watchfolders.panels.media.notifications -> table
--- Variable
--- Table of Path Watchers
mod.pathwatchers = {}

--- plugins.finalcutpro.watchfolders.panels.media.notifications -> table
--- Variable
--- Table of Notifications
mod.notifications = {}

--- plugins.finalcutpro.watchfolders.panels.media.disableImport -> boolean
--- Variable
--- When `true` Notifications will no longer be triggered.
mod.disableImport = false

--- plugins.finalcutpro.watchfolders.panels.media.automaticallyImport <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.automaticallyImport = config.prop("fcp.watchFolders.automaticallyImport", false)

--- plugins.finalcutpro.watchfolders.panels.media.savedNotifications <cp.prop: table>
--- Variable
--- Table of Notifications that are saved between restarts
mod.savedNotifications = config.prop("fcp.watchFolders.savedNotifications", {})

--- plugins.finalcutpro.watchfolders.panels.media.insertIntoTimeline <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not the files are automatically added to the timeline or not.
mod.insertIntoTimeline = config.prop("fcp.watchFolders.insertIntoTimeline", true)

--- plugins.finalcutpro.watchfolders.panels.media.deleteAfterImport <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not you want to delete file after they've been imported.
mod.deleteAfterImport = config.prop("fcp.watchFolders.deleteAfterImport", false)

--- plugins.finalcutpro.watchfolders.panels.media.videoTag <cp.prop: string>
--- Variable
--- String which contains the video tag.
mod.videoTag = config.prop("fcp.watchFolders.videoTag", {})

--- plugins.finalcutpro.watchfolders.panels.media.audioTag <cp.prop: string>
--- Variable
--- String which contains the audio tag.
mod.audioTag = config.prop("fcp.watchFolders.audioTag", {})

--- plugins.finalcutpro.watchfolders.panels.media.imageTag <cp.prop: string>
--- Variable
--- String which contains the stills tag.
mod.imageTag = config.prop("fcp.watchFolders.imageTag", {})

--- plugins.finalcutpro.watchfolders.panels.media.watchFolders <cp.prop: table>
--- Variable
--- Table of the users watch folders.
mod.watchFolders = config.prop("fcp.watchFolders.mediaPaths", {})

-- cleanupTags() -> none
-- Function
-- Removes any Video, Audio & Image Tags that are no longer needed.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function cleanupTags()
    local watchFolders = mod.watchFolders()

    local videoTag = mod.videoTag()
    local audioTag = mod.audioTag()
    local imageTag = mod.imageTag()

    local newVideoTag = {}
    local newAudioTag = {}
    local newImageTag = {}

    for _, v in pairs(watchFolders) do
        if videoTag[v] then
            newVideoTag[v] = videoTag[v]
        end
        if audioTag[v] then
            newAudioTag[v] = audioTag[v]
        end
        if imageTag[v] then
            newImageTag[v] = imageTag[v]
        end
    end

    mod.videoTag(newVideoTag)
    mod.audioTag(newAudioTag)
    mod.imageTag(newImageTag)
end

--- plugins.finalcutpro.watchfolders.panels.media.removeWatcher(path) -> none
--- Function
--- Remove Folder Watcher
---
--- Parameters:
---  * path - Path to Watch Folder
---
--- Returns:
---  * None
function mod.removeWatcher(path)
    mod.pathwatchers[path]:stop()
    mod.pathwatchers[path] = nil
end

--- plugins.finalcutpro.watchfolders.panels.media.controllerCallback(id, params) -> none
--- Function
--- Callback Controller
---
--- Parameters:
---  * id - ID as string
---  * params - table of Parameters
---
--- Returns:
---  * None
function mod.controllerCallback(_, params)
    if params and params.action and params.action == "remove" then
        --------------------------------------------------------------------------------
        -- Remove a Watch Folder:
        --------------------------------------------------------------------------------
        mod.watchFolders(tools.removeFromTable(mod.watchFolders(), params.path))
        mod.removeWatcher(params.path)

        --------------------------------------------------------------------------------
        -- Cleanup Tags:
        --------------------------------------------------------------------------------
        cleanupTags()

        --------------------------------------------------------------------------------
        -- Refresh Table:
        --------------------------------------------------------------------------------
        mod.refreshTable()
    elseif params and params.action and params.action == "refresh" then
        --------------------------------------------------------------------------------
        -- Refresh Table:
        --------------------------------------------------------------------------------
        mod.refreshTable()
    end
end

--- plugins.finalcutpro.watchfolders.panels.media.generateTable() -> string
--- Function
--- Generate HTML Table
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns a HTML table as a string
function mod.generateTable()

    local watchFoldersHTML = ""
    local watchFolders =  mod.watchFolders()

    local videoTag = mod.videoTag()
    local audioTag = mod.audioTag()
    local imageTag = mod.imageTag()

    for _, v in ipairs(watchFolders) do
        local uniqueUUID = string.gsub(uuid(), "-", "")
        watchFoldersHTML = watchFoldersHTML .. [[
                <tr>
                    <td class="mediaRowPath">]] .. v .. [[</td>
                    <td class="mediaRowVideoTag">]] .. (videoTag[v] or i18n("none")) .. [[</td>
                    <td class="mediaRowAudioTag">]] .. (audioTag[v] or i18n("none")) .. [[</td>
                    <td class="mediaRowImageTag">]] .. (imageTag[v] or i18n("none")) .. [[</td>
                    <td class="mediaRowRemove"><a onclick="remove]] .. uniqueUUID .. [[()" href="#">Remove</a></td>
                </tr>
        ]]
        mod.manager.injectScript([[
            function remove]] .. uniqueUUID .. [[() {
                try {
                    var p = {};
                    p["action"] = "remove";
                    p["path"] = "]] .. v .. [[";
                    var result = { id: "]] .. uniqueUUID .. [[", params: p };
                    webkit.messageHandlers.watchfolders.postMessage(result);
                } catch(err) {
                    alert('An error has occurred. Does the controller exist yet?');
                }
            }
        ]])
        mod.manager.addHandler(uniqueUUID, mod.controllerCallback)
    end

    if watchFoldersHTML == "" then
            watchFoldersHTML = [[
                <tr>
                    <td class="mediaRowPath">]] .. i18n("empty") .. [[</td>
                    <td class="mediaRowVideoTag"></td>
                    <td class="mediaRowAudioTag"></td>
                    <td class="mediaRowImageTag"></td>
                    <td class="mediaRowRemove"></td>
                </tr>
        ]]
    end

    local result = [[
        <table class="mediaWatchFolders">
            <thead>
                <tr>
                    <th class="mediaRowPath">]] .. i18n("folder") .. [[</th>
                    <th class="mediaRowVideoTag">]] .. i18n("video") .. " " .. i18n("tag") .. [[</th>
                    <th class="mediaRowAudioTag">]] .. i18n("audio") .. " " .. i18n("tag") .. [[</th>
                    <th class="mediaRowImageTag">]] .. i18n("stills") .. " " .. i18n("tag") .. [[</th>
                    <th class="mediaRowRemove"></th>
                </tr>
            </thead>
            <tbody>
                ]] .. watchFoldersHTML .. [[
            </tbody>
        </table>
    ]]

    return result

end

--- plugins.finalcutpro.watchfolders.panels.media.refreshTable() -> string
--- Function
--- Refreshes the Final Cut Pro Watch Folder Panel via JavaScript Injection
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.refreshTable()
    local result = [[
        try {
            var ]] .. mod.watchFolderTableID .. [[ = document.getElementById("]] .. mod.watchFolderTableID .. [[");
            if (typeof(]] .. mod.watchFolderTableID .. [[) != 'undefined' && ]] .. mod.watchFolderTableID .. [[ != null)
            {
                document.getElementById("]] .. mod.watchFolderTableID .. [[").innerHTML = `]] .. mod.generateTable() .. [[`;
            }
        }
        catch(err) {
            alert("Refresh Table Error");
        }
        ]]
    mod.manager.injectScript(result)
end

--- plugins.finalcutpro.watchfolders.panels.media.styleSheet() -> string
--- Function
--- Generates Style Sheet
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns Style Sheet as a string
function mod.styleSheet()
    return ui.style [[
        .mediaAddWatchFolder {
            margin-top: 10px;
        }

        .mediaRowPath {
            width:40%;
        }

        .mediaRowVideoTag {
            width:18.33%;
        }

        .mediaRowAudioTag {
            width:18.33%;
        }

        .mediaRowImageTag {
            width:18.33%;
        }

        .mediaRowRemove {
            width:5%;
            text-align:right;
        }

        .mediaWatchFolders {
            float: left;
            margin-left: 20px;
            table-layout: fixed;
            width: 95%;
            white-space: nowrap;
            border: 1px solid #cccccc;
            padding: 8px;
            text-align: left;
            background-color: #161616 !important;
        }

        .mediaWatchFolders td {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .mediaWatchFolders thead, .mediaWatchFolders tbody tr {
            display:table;
            table-layout:fixed;
            width: 100%;
        }

        .mediaWatchFolders tbody {
            display:block;
            height: 80px;
            font-weight: normal;
            font-size: 10px;

            overflow-x: hidden;
            overflow-y: auto;
        }

        .mediaWatchFolders tbody tr {
            display:table;
            width:100%;
            table-layout:fixed;
        }

        .mediaWatchFolders thead {
            font-weight: bold;
            font-size: 12px;
        }

        .mediaWatchFolders tbody {
            font-weight: normal;
            font-size: 10px;
        }

        .mediaWatchFolders tbody tr:hover {
            background-color: #006dd4;
            color: white;
        }

        .mediaDeleteNote {
            font-size: 10px;
            margin-left: 20px;
        }
    ]]
end

-- getPath(file) -> string | nil
-- Function
-- Checks to see whether a file path matches one of our watch folders.
--
-- Parameters:
--  * file - The path to the file to check.
--
-- Returns:
--  * A path as string, or `nil` if no matching path can be found.
local function getPath(file)
    local watchFolders = mod.watchFolders()
    for _, path in pairs(watchFolders) do
        if file:sub(1, path:len()) == path then
            return path
        end
    end
    return nil
end

--- plugins.finalcutpro.watchfolders.panels.media.insertFilesIntoFinalCutPro(files) -> none
--- Function
--- Imports files into Final Cut Pro
---
--- Parameters:
---  * files - A table of file paths.
---
--- Returns:
---  * None
function mod.insertFilesIntoFinalCutPro(files)
    --------------------------------------------------------------------------------
    -- Add Tags:
    --------------------------------------------------------------------------------
    mod.disableImport = true
    for _, file in pairs(files) do
        local videoExtensions = fcp.ALLOWED_IMPORT_VIDEO_EXTENSIONS
        local audioExtensions = fcp.ALLOWED_IMPORT_AUDIO_EXTENSIONS
        local imageExtensions = fcp.ALLOWED_IMPORT_IMAGE_EXTENSIONS

        local path = getPath(file)

        local videoTags = mod.videoTag()
        local audioTags = mod.audioTag()
        local imageTags = mod.imageTag()

        local videoTag = videoTags[path]
        local audioTag = audioTags[path]
        local imageTag = imageTags[path]

        if videoTag then
            if (fnutils.contains(videoExtensions, string.lower(file:sub(-3))) or fnutils.contains(videoExtensions, string.lower(file:sub(-4)))) and tools.doesFileExist(file) then
                if not fs.tagsAdd(file, {videoTag}) then
                    log.ef("Failed to add Finder Tag (%s) to: %s", videoTag, file)
                end
            end
        end
        if audioTag then
            if (fnutils.contains(audioExtensions, string.lower(file:sub(-3))) or fnutils.contains(audioExtensions, string.lower(file:sub(-4)))) and tools.doesFileExist(file) then
                if not fs.tagsAdd(file, {audioTag}) then
                    log.ef("Failed to add Finder Tag (%s) to: %s", audioTag, file)
                end
            end
        end
        if imageTag then
            if (fnutils.contains(imageExtensions, string.lower(file:sub(-3))) or fnutils.contains(imageExtensions, string.lower(file:sub(-4)))) and tools.doesFileExist(file) then
                if not fs.tagsAdd(file, {imageTag}) then
                    log.ef("Failed to add Finder Tag (%s) to: %s", imageTag, file)
                end
            end
        end
    end
    timer.doAfter(1, function()
        mod.disableImport = false
    end)

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
    local objects = {}
    for _, v in pairs(files) do
        objects[#objects + 1] = { url = "file://" .. http.encodeForQuery(v) }
    end
    local result = pasteboard.writeObjects(objects)
    if not result then
        dialog.displayErrorMessage("The URL could not be written to the Pasteboard. Error occured in Final Cut Pro Media Watch Folder.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Make sure Final Cut Pro is Active:
    --------------------------------------------------------------------------------
    result = just.doUntil(function()
        fcp:launch()
        return fcp:isFrontmost()
    end, 5, 0.1)
    if not result then
        dialog.displayErrorMessage("Failed to launch to Final Cut Pro. Error occured in Final Cut Pro Media Watch Folder.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Check if Timeline can be enabled:
    --------------------------------------------------------------------------------
    fcp:timeline():show()
    if not fcp:timeline():isShowing() then
        dialog.displayErrorMessage("Failed to activate timeline. Error occured in Final Cut Pro Media Watch Folder.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Perform Paste:
    --------------------------------------------------------------------------------
    if not fcp:selectMenu({"Edit", "Paste as Connected Clip"}) then
        dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut. Error occured in Final Cut Pro Media Watch Folder.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Remove from Timeline if appropriate:
    --------------------------------------------------------------------------------
    if not mod.insertIntoTimeline() then
        fcp:selectMenu({"Edit", "Undo Paste"}, true)
        -- fcp:performShortcut("UndoChanges")
    end

    --------------------------------------------------------------------------------
    -- Restore original Pasteboard Content:
    --------------------------------------------------------------------------------
    timer.doAfter(2, function()
        pasteboard.writeAllData(originalPasteboard)
        if mod.pasteboardManager then
            mod.pasteboardManager.startWatching()
        end
    end)

    --------------------------------------------------------------------------------
    -- Delete After Import:
    --------------------------------------------------------------------------------
    if mod.deleteAfterImport() then
        for _, file in pairs(files) do
            timer.doAfter(mod.SECONDS_UNTIL_DELETE, function()
                os.remove(file)
            end)
        end
    end

    return true
end

--- plugins.finalcutpro.watchfolders.panels.media.importFile(file, obj) -> none
--- Function
--- Imports a file into Final Cut Pro
---
--- Parameters:
---  * file - File name
---  * tag - The notification tag
---
--- Returns:
---  * None
function mod.importFile(file)

    --------------------------------------------------------------------------------
    -- Check to see if Final Cut Pro is running:
    --------------------------------------------------------------------------------
    if not fcp:isRunning() then
        dialog.displayMessage(i18n("finalCutProNotRunning"))
        if mod.notifications[file] then
            mod.notifications[file]:send()
        else
            mod.createNotification(file)
        end
        return
    end

    local importAll = false
    local files = {}

    local modifiers = eventtap.checkKeyboardModifiers()
    if modifiers["shift"] then
        --------------------------------------------------------------------------------
        -- Import All:
        --------------------------------------------------------------------------------
        importAll = true
        for i, _ in pairs(mod.notifications) do
            files[#files + 1] = i
        end
    else
        files = {file}
    end

    --------------------------------------------------------------------------------
    -- Insert Files into Final Cut Pro:
    --------------------------------------------------------------------------------
    local result = mod.insertFilesIntoFinalCutPro(files)
    if not result then
        return
    end

    --------------------------------------------------------------------------------
    -- Release the notification:
    --------------------------------------------------------------------------------
    local savedNotifications = mod.savedNotifications()
    if importAll then
        for i, _ in pairs(mod.notifications) do
            mod.notifications[i]:withdraw()
            mod.notifications[i] = nil
            savedNotifications[i] = nil
        end
    else
        mod.notifications[file] = nil
        savedNotifications[file] = nil
    end

    --------------------------------------------------------------------------------
    -- Save Notifications to Settings:
    --------------------------------------------------------------------------------
    mod.savedNotifications(savedNotifications)

    --------------------------------------------------------------------------------
    -- Cleanup Tags:
    --------------------------------------------------------------------------------
    cleanupTags()

end

--- plugins.finalcutpro.watchfolders.panels.media.createNotification(file) -> none
--- Function
--- Creates a new notification
---
--- Parameters:
---  * file - File name
---
--- Returns:
---  * None
function mod.createNotification(file)

    local notificationFn = function(obj)
        mod.importFile(file, obj:getFunctionTag())
    end

    mod.notifications[file] = notify.new(notificationFn)
        :title(i18n("newFileForFinalCutPro"))
        :subTitle(tools.getFilenameFromPath(file))
        :hasActionButton(true)
        :actionButtonTitle(i18n("import"))
        :otherButtonTitle(i18n("skip"))
        :send()

    --------------------------------------------------------------------------------
    -- Save Notifications to Settings:
    --------------------------------------------------------------------------------
    local notificationTag = mod.notifications[file]:getFunctionTag()
    local savedNotifications = mod.savedNotifications()
    savedNotifications[file] = notificationTag
    mod.savedNotifications(savedNotifications)
end

--- plugins.finalcutpro.watchfolders.panels.media.watchFolderTriggered(files, eventFlags, path) -> none
--- Function
--- Watch Folder Triggered
---
--- Parameters:
---  * files - A table containing a list of file paths that have changed.
---  * eventFlags - A table containing a list of tables denoting how each corresponding file in paths has changed, each containing boolean values indicating which types of events occurred.
---
--- Returns:
---  * None
function mod.watchFolderTriggered(files, eventFlags)

    --log.df("files: %s", hs.inspect(files))
    --log.df("eventFlags: %s", hs.inspect(eventFlags))

    if not mod.disableImport then
        local autoFiles = {}
        for i,file in pairs(files) do

            --------------------------------------------------------------------------------
            -- Detect the filesystem:
            --------------------------------------------------------------------------------
            local volumeFormat = tools.volumeFormat(file)

            --------------------------------------------------------------------------------
            -- File deleted or removed from Watch Folder:
            --------------------------------------------------------------------------------
            if eventFlags[i] and eventFlags[i]["itemRenamed"] and eventFlags[i]["itemIsFile"] and not tools.doesFileExist(file) then
                --log.df("File deleted or moved outside of watch folder!")
                if mod.notifications[file] then
                    mod.notifications[file]:withdraw()
                    mod.notifications[file] = nil
                    local savedNotifications = mod.savedNotifications()
                    savedNotifications[file] = nil
                    mod.savedNotifications(savedNotifications)
                end
            else

                --------------------------------------------------------------------------------
                -- New File Added to Watch Folder:
                --------------------------------------------------------------------------------
                local newFile = false
                if eventFlags[i]["itemCreated"] and eventFlags[i]["itemIsFile"] and eventFlags[i]["itemModified"] then
                    --log.df("New File Added: %s", file)
                    newFile = true
                end

                --------------------------------------------------------------------------------
                -- New File Added to Watch Folder, but still in transit:
                --------------------------------------------------------------------------------
                if eventFlags[i]["itemCreated"] and eventFlags[i]["itemIsFile"] and not eventFlags[i]["itemModified"] then

                    -------------------------------------------------------------------------------
                    -- Add filename to table:
                    -------------------------------------------------------------------------------
                    mod.filesInTransit[#mod.filesInTransit + 1] = file

                    -------------------------------------------------------------------------------
                    -- Show Temporary Notification:
                    --------------------------------------------------------------------------------
                    mod.notifications[file] = notify.new()
                        :title(i18n("incomingFile"))
                        :subTitle(tools.getFilenameFromPath(file))
                        :hasActionButton(false)
                        :send()

                end

                --------------------------------------------------------------------------------
                -- New File Added to Watch Folder after copying:
                --------------------------------------------------------------------------------
                if eventFlags[i]["itemModified"] and eventFlags[i]["itemIsFile"] and fnutils.contains(mod.filesInTransit, file) then
                    tools.removeFromTable(mod.filesInTransit, file)
                    if mod.notifications[file] then
                        mod.notifications[file]:withdraw()
                        mod.notifications[file] = nil
                        local savedNotifications = mod.savedNotifications()
                        savedNotifications[file] = nil
                        mod.savedNotifications(savedNotifications)
                    end
                    newFile = true
                end

                --------------------------------------------------------------------------------
                -- New File Moved into Watch Folder:
                --------------------------------------------------------------------------------
                local movedFile = false
                if eventFlags[i]["itemRenamed"] and eventFlags[i]["itemIsFile"] then
                    log.df("File Moved or Renamed: %s", file)
                    movedFile = true
                end

                --------------------------------------------------------------------------------
                -- New File Moved into Watch Folder on High Sierra:
                --------------------------------------------------------------------------------
                if eventFlags[i]["itemChangeOwner"] and eventFlags[i]["itemCreated"] and eventFlags[i]["itemIsFile"] and volumeFormat == "APFS" then
                    tools.removeFromTable(mod.filesInTransit, file)
                    if mod.notifications[file] then
                        mod.notifications[file]:withdraw()
                        mod.notifications[file] = nil
                        local savedNotifications = mod.savedNotifications()
                        savedNotifications[file] = nil
                        mod.savedNotifications(savedNotifications)
                    end
                    movedFile = true
                end

                --------------------------------------------------------------------------------
                -- Check Extensions:
                --------------------------------------------------------------------------------
                local allowedExtensions = fcp.ALLOWED_IMPORT_ALL_EXTENSIONS
                if (fnutils.contains(allowedExtensions, string.lower(file:sub(-3))) or fnutils.contains(allowedExtensions, string.lower(file:sub(-4)))) and tools.doesFileExist(file) then
                    if newFile or movedFile then
                        --log.df("File finished copying: %s", file)
                        if mod.automaticallyImport() then
                            autoFiles[#autoFiles + 1] = file
                        else
                            mod.createNotification(file)
                        end
                    end
                end
            end
        end
        if mod.automaticallyImport() and next(autoFiles) ~= nil then
            mod.insertFilesIntoFinalCutPro(autoFiles)
        end
    end
end

--- plugins.finalcutpro.watchfolders.panels.media.newWatcher(path) -> none
--- Function
--- New Folder Watcher
---
--- Parameters:
---  * path - Path to Watch Folder
---
--- Returns:
---  * None
function mod.newWatcher(path)
    mod.pathwatchers[path] = pathwatcher.new(path, mod.watchFolderTriggered):start()
end

--- plugins.finalcutpro.watchfolders.panels.media.addWatchFolder() -> none
--- Function
--- Opens the "Add Watch Folder" Dialog.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.addWatchFolder()
    local path = dialog.displayChooseFolder(i18n("selectFolderToWatch"))
    if path then

        --------------------------------------------------------------------------------
        -- Make sure the folder isn't already being watched:
        --------------------------------------------------------------------------------
        local watchFolders = mod.watchFolders()
        if tools.tableContains(watchFolders, path) then
            dialog.displayMessage(i18n("alreadyWatched"))
            return
        end

        --------------------------------------------------------------------------------
        -- Finder Tags:
        --------------------------------------------------------------------------------
        local result
        result = dialog.displayTextBoxMessage(i18n("watchFolderAddFinderTag", {type=i18n("video")}), "", "", function() return true end)
        if result == false then
            return
        elseif result and tools.trim(result) ~= "" then
            local videoTag = mod.videoTag()
            videoTag[path] = result
            mod.videoTag(videoTag)
        end

        result = dialog.displayTextBoxMessage(i18n("watchFolderAddFinderTag", {type=i18n("audio")}), "", "", function() return true end)
        if result == false then
            return
        elseif result and tools.trim(result) ~= "" then
            local audioTag = mod.audioTag()
            audioTag[path] = result
            mod.audioTag(audioTag)
        end

        result = dialog.displayTextBoxMessage(i18n("watchFolderAddFinderTag", {type=i18n("stills")}), "", "", function() return true end)
        if result == false then
            return
        elseif result and tools.trim(result) ~= "" then
            local imageTag = mod.imageTag()
            imageTag[path] = result
            mod.imageTag(imageTag)
        end

        --------------------------------------------------------------------------------
        -- Update Settings:
        --------------------------------------------------------------------------------
        watchFolders[#watchFolders + 1] = path
        mod.watchFolders(watchFolders)

        --------------------------------------------------------------------------------
        -- Refresh HTML Table:
        --------------------------------------------------------------------------------
        mod.refreshTable()

        --------------------------------------------------------------------------------
        -- Setup New Watcher:
        --------------------------------------------------------------------------------
        mod.newWatcher(path)

    end
end

-- getFileFromTag(tag) -> string
-- Function
-- Gets the file value from a tag.
--
-- Parameters:
--  * tag - The tag ID to search for as a string.
--
-- Returns:
--  * The file as string.
local function getFileFromTag(tag)
    local savedNotifications = mod.savedNotifications()
    for file,t in pairs(savedNotifications) do
        if t == tag then
            return file
        end
    end
    return nil
end

--- plugins.finalcutpro.watchfolders.panels.media.setupWatchers(path) -> none
--- Function
--- Setup Folder Watchers
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setupWatchers()

    --------------------------------------------------------------------------------
    -- Setup Watchers:
    --------------------------------------------------------------------------------
    local watchFolders = mod.watchFolders()
    for _, v in ipairs(watchFolders) do
        mod.newWatcher(v)
    end

    --------------------------------------------------------------------------------
    -- Register any un-clicked Notifications from Previous Session & Trash
    -- any ones that were clicked when CommandPost was closed:
    --------------------------------------------------------------------------------
    local deliveredNotifications = notify.deliveredNotifications()
    local newSavedNotifications = {}
    for _, v in pairs(deliveredNotifications) do
        local tag = v:getFunctionTag()
        local file = getFileFromTag(tag)
        if file then
            local notificationFn = function(obj)
                mod.importFile(file, obj:getFunctionTag())
            end
            notify.register(tag, notificationFn)
            newSavedNotifications[file] = tag
        end
    end
    mod.savedNotifications(newSavedNotifications)

    --------------------------------------------------------------------------------
    -- Cleanup Tags:
    --------------------------------------------------------------------------------
    cleanupTags()
end

--- plugins.finalcutpro.watchfolders.panels.media.init(deps, env) -> table
--- Function
--- Initialises the module.
---
--- Parameters:
---  * deps - The dependencies environment
---  * env - The plugin environment
---
--- Returns:
---  * Table of the module.
function mod.init(deps)

    --------------------------------------------------------------------------------
    -- Ignore Panel if Final Cut Pro isn't installed.
    --------------------------------------------------------------------------------
    if not fcp:isInstalled() then
        return nil
    end

    --------------------------------------------------------------------------------
    -- Define Plugins:
    --------------------------------------------------------------------------------
    mod.pasteboardManager = deps.pasteboardManager
    mod.manager = deps.manager

    --------------------------------------------------------------------------------
    -- Setup Panel:
    --------------------------------------------------------------------------------
    mod.panel = deps.manager.addPanel({
            priority 		= 2010,
            id				= "media",
            label			= i18n("media"),
            image			= image.imageFromPath(fcp:getPath() .. "/Contents/Resources/Final Cut.icns"),
            tooltip			= i18n("watchFolderFCPMediaTooltip"),
            height			= 500,
            loadFn			= mod.refreshTable,
        })

    --------------------------------------------------------------------------------
    -- Setup Panel Contents:
    --------------------------------------------------------------------------------
    mod.panel
        :addContent(1, mod.styleSheet())
        :addHeading(10, i18n("description"))
        :addParagraph(11, i18n("watchFolderFCPMediaHelp"), false)
        :addParagraph(12, "")
        :addHeading(13, i18n("watchFolders"), 3)
        :addContent(14, html.div { id=mod.watchFolderTableID } ( mod.generateTable(), false ))
        :addButton(15,
            {
                label		= i18n("addWatchFolder"),
                onclick		= mod.addWatchFolder,
                class		= "mediaAddWatchFolder",
            })
        :addParagraph(16, "")
        :addHeading(17, i18n("options"), 3)
        :addCheckbox(18,
            {
                label		= i18n("importToTimeline"),
                checked		= mod.insertIntoTimeline,
                onchange	= function(_, params) mod.insertIntoTimeline(params.checked) end,
            }
        )
        :addCheckbox(19,
            {
                label		= i18n("automaticallyImport"),
                checked		= mod.automaticallyImport,
                onchange	= function(_, params) mod.automaticallyImport(params.checked) end,
            }
        )
        :addCheckbox(20,
            {
                label		= i18n("deleteAfterImport", {
                    numberOfSeconds = mod.SECONDS_UNTIL_DELETE,
                    seconds = i18n("second", {count = mod.SECONDS_UNTIL_DELETE})
                }),
                checked		= mod.deleteAfterImport,
                onchange	= function(_, params) mod.deleteAfterImport(params.checked) end,
            }
        )
        :addParagraph(21, i18n("deleteNote"), false, "mediaDeleteNote")

    --------------------------------------------------------------------------------
    -- Setup Watchers:
    --------------------------------------------------------------------------------
    mod.setupWatchers()

    return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.watchfolders.panels.media",
    group = "finalcutpro",
    dependencies = {
        ["core.watchfolders.manager"]		= "manager",
        ["finalcutpro.pasteboard.manager"]	= "pasteboardManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
