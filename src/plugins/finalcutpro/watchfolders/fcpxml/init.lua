--- === plugins.finalcutpro.watchfolders.fcpxml ===
---
--- Final Cut Pro FCPXML Watch Folder Plugin.

local require = require

local eventtap          = require("hs.eventtap")
local fnutils           = require("hs.fnutils")
local host              = require("hs.host")
local image             = require("hs.image")
local notify            = require("hs.notify")
local pathwatcher       = require("hs.pathwatcher")
local timer             = require("hs.timer")

local config            = require("cp.config")
local dialog            = require("cp.dialog")
local Do                = require("cp.rx.go.Do")
local fcp               = require("cp.apple.finalcutpro")
local html              = require("cp.web.html")
local i18n              = require("cp.i18n")
local tools             = require("cp.tools")
local ui                = require("cp.web.ui")

local doAfter           = timer.doAfter
local uuid              = host.uuid


local mod = {}

--- plugins.finalcutpro.watchfolders.fcpxml.SECONDS_UNTIL_DELETE -> number
--- Constant
--- Seconds until a file is deleted.
mod.SECONDS_UNTIL_DELETE = 30

--- plugins.finalcutpro.watchfolders.fcpxml.watchFolderTableID -> string
--- Variable
--- Watch Folder Table ID
mod.watchFolderTableID = "fcpxmlWatchFoldersTable"

--- plugins.finalcutpro.watchfolders.fcpxml.filesInTransit -> table
--- Variable
--- Files currently being copied
mod.filesInTransit = {}

--- plugins.finalcutpro.watchfolders.fcpxml.notifications -> table
--- Variable
--- Table of Path Watchers
mod.pathwatchers = {}

--- plugins.finalcutpro.watchfolders.fcpxml.notifications -> table
--- Variable
--- Table of Notifications
mod.notifications = {}

--- plugins.finalcutpro.watchfolders.fcpxml.disableImport -> boolean
--- Variable
--- When `true` Notifications will no longer be triggered.
mod.disableImport = false

--- plugins.finalcutpro.watchfolders.fcpxml.automaticallyImport <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.automaticallyImport = config.prop("fcp.fcpxml.watchFolders.automaticallyImport", false)

--- plugins.finalcutpro.watchfolders.fcpxml.savedNotifications <cp.prop: table>
--- Variable
--- Table of Notifications that are saved between restarts
mod.savedNotifications = config.prop("fcp.fcpxml.watchFolders.savedNotifications", {})

--- plugins.finalcutpro.watchfolders.fcpxml.deleteAfterImport <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not you want to delete file after they've been imported.
mod.deleteAfterImport = config.prop("fcp.fcpxml.watchFolders.deleteAfterImport", false)

--- plugins.finalcutpro.watchfolders.fcpxml.watchFolders <cp.prop: table>
--- Variable
--- Table of the users watch folders.
mod.watchFolders = config.prop("fcp.fcpxml.watchFolders", {})

--- plugins.finalcutpro.watchfolders.fcpxml.generateTable() -> string
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

    for _, v in ipairs(watchFolders) do
        local uniqueUUID = string.gsub(uuid(), "-", "")
        watchFoldersHTML = watchFoldersHTML .. [[
                <tr>
                    <td class="rowPath">]] .. v .. [[</td>
                    <td class="rowRemove"><a onclick="remove]] .. uniqueUUID .. [[()" href="#">Remove</a></td>
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
                    <td class="rowPath">]] .. i18n("empty") .. [[</td>
                    <td class="rowRemove"></td>
                </tr>
        ]]
    end

    local result = [[
        <table class="watchfolders">
            <thead>
                <tr>
                    <th class="rowPath">]] .. i18n("folder") .. [[</th>
                </tr>
            </thead>
            <tbody>
                ]] .. watchFoldersHTML .. [[
            </tbody>
        </table>
    ]]

    return result

end

--- plugins.finalcutpro.watchfolders.fcpxml.refreshTable() -> string
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

--- plugins.finalcutpro.watchfolders.fcpxml.controllerCallback(id, params) -> none
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
        mod.watchFolders(tools.removeFromTable(mod.watchFolders(), params.path))
        mod.removeWatcher(params.path)
        mod.refreshTable()
    elseif params and params.action and params.action == "refresh" then
        mod.refreshTable()
    end
end

--- plugins.finalcutpro.watchfolders.fcpxml.styleSheet() -> cp.web.html
--- Function
--- Generates Style Sheet
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns Style Sheet as a string
function mod.styleSheet()
    return ui.style ([[
        .btnAddWatchFolder {
            margin-top: 10px;
        }
        .watchfolders {
            float: left;
            margin-left: 20px;
            table-layout: fixed;
            width: 95%;
            white-space: nowrap;
            border: 1px solid #cccccc;
            padding: 8px;
            background-color: #161616 !important;
            text-align: left;
        }

        .watchfolders td {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .rowPath {
            width:80%;
        }

        .rowRemove {
            width:20%;
            text-align:right;
        }

        .watchfolders thead, .watchfolders tbody tr {
            display:table;
            table-layout:fixed;
            width: calc( 100% - 1.5em );
        }

        .watchfolders tbody {
            display:block;
            height: 80px;
            font-weight: normal;
            font-size: 10px;

            overflow-x: hidden;
            overflow-y: auto;
        }

        .watchfolders tbody tr {
            display:table;
            width:100%;
            table-layout:fixed;
        }

        .watchfolders thead {
            font-weight: bold;
            font-size: 12px;
        }

        .watchfolders tbody {
            font-weight: normal;
            font-size: 10px;
        }

        .watchfolders tbody tr:nth-child(even) {
            background-color: #f5f5f5
        }

        .watchfolders tbody tr:hover {
            background-color: #006dd4;
            color: white;
        }

        .watchFolderTextBox {
            vertical-align: middle;
        }

        .watchFolderTextBox label {
            display: inline-block;
            width: 100px;
            height: 25px;
        }

        .watchFolderTextBox input {
            display: inline-block;
            background-color: #161616 !important;
            color: #999999 !important;
        }

        .deleteNote {
            font-size: 10px;
            margin-left: 20px;
        }
    ]])
end

--- plugins.finalcutpro.watchfolders.fcpxml.insertFilesIntoFinalCutPro(files) -> none
--- Function
--- Imports a file into Final Cut Pro
---
--- Parameters:
---  * files - File names in table
---
--- Returns:
---  * None
function mod.insertFilesIntoFinalCutPro(files)

    --------------------------------------------------------------------------------
    -- Disable Import:
    --------------------------------------------------------------------------------
    mod.disableImport = true

    --------------------------------------------------------------------------------
    -- Import XML:
    --------------------------------------------------------------------------------
    for _, file in pairs(files) do
        fcp:importXML(file)
    end

    --------------------------------------------------------------------------------
    -- Delete After Import:
    --------------------------------------------------------------------------------
    if mod.deleteAfterImport() then
        for _, file in pairs(files) do
            doAfter(mod.SECONDS_UNTIL_DELETE, function()
                os.remove(file)
            end)
        end
    end

    --------------------------------------------------------------------------------
    -- Re-enable Import:
    --------------------------------------------------------------------------------
    mod.disableImport = false

    return true
end

--- plugins.finalcutpro.watchfolders.fcpxml.importFile(file, obj) -> none
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

end

--- plugins.finalcutpro.watchfolders.fcpxml.createNotification(file) -> none
--- Function
--- Creates a new notification
---
--- Parameters:
---  * file - File name
---
--- Returns:
---  * None
function mod.createNotification(file)
    mod.notifications[file] = notify.new(function(obj) mod.importFile(file, obj:getFunctionTag()) end)
        :title(i18n("newFCPXMLForFinalCutPro"))
        :subTitle(tools.getFilenameFromPath(file))
        :hasActionButton(true)
        :actionButtonTitle(i18n("import"))
        :otherButtonTitle(i18n("skip"))
        :withdrawAfter(0)
        :send()

    --------------------------------------------------------------------------------
    -- Save Notifications to Settings:
    --------------------------------------------------------------------------------
    local notificationTag = mod.notifications[file]:getFunctionTag()
    local savedNotifications = mod.savedNotifications()
    savedNotifications[file] = notificationTag
    mod.savedNotifications(savedNotifications)
end

--- plugins.finalcutpro.watchfolders.fcpxml.watchFolderTriggered(files) -> none
--- Function
--- Watch Folder Triggered
---
--- Parameters:
---  * files - A table of files
---
--- Returns:
---  * None
function mod.watchFolderTriggered(files, eventFlags)

    local autoFiles = {}
    if not mod.disableImport then
        for i,file in pairs(files) do
            --------------------------------------------------------------------------------
            -- Ignore some events:
            --------------------------------------------------------------------------------
            local skipEvent = false
            if eventFlags[i]["itemIsFile"] and
            not eventFlags[i]["itemModified"] and
            not eventFlags[i]["itemRenamed"] and
            not eventFlags[i]["itemChangeOwner"] then
                skipEvent = true
            end

            if not skipEvent then
                --------------------------------------------------------------------------------
                -- File deleted or removed from Watch Folder:
                --------------------------------------------------------------------------------
                if eventFlags[i] and eventFlags[i]["itemRenamed"] and eventFlags[i]["itemIsFile"] and not tools.doesFileExist(file) then
                    if mod.notifications[file] then
                        mod.notifications[file]:withdraw()
                        mod.notifications[file] = nil
                        local savedNotifications = mod.savedNotifications()
                        savedNotifications[file] = nil
                        mod.savedNotifications(savedNotifications)
                    end
                else
                    --------------------------------------------------------------------------------
                    -- New File Added to Watch Folder, but still in transit:
                    --------------------------------------------------------------------------------
                    if string.lower(file:sub(-7)) == ".fcpxml" and eventFlags[i]["itemCreated"] and eventFlags[i]["itemIsFile"] and not eventFlags[i]["itemModified"] then

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
                            :withdrawAfter(0)
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
                        end
                    end
                    if eventFlags[i]["itemCreated"] and eventFlags[i]["itemIsFile"] and eventFlags[i]["itemChangeOwner"] and fnutils.contains(mod.filesInTransit, file) then
                        tools.removeFromTable(mod.filesInTransit, file)
                        if mod.notifications[file] then
                            mod.notifications[file]:withdraw()
                            mod.notifications[file] = nil
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Check Extensions:
                    --------------------------------------------------------------------------------
                    if string.lower(file:sub(-7)) == ".fcpxml" and tools.doesFileExist(file) then
                        if mod.automaticallyImport() then
                            autoFiles[#autoFiles + 1] = file
                        else
                            mod.createNotification(file)
                        end
                    end
                end
            end
        end
    end
    if mod.automaticallyImport() and next(autoFiles) ~= nil then
        mod.insertFilesIntoFinalCutPro(autoFiles)
    end
end

--- plugins.finalcutpro.watchfolders.fcpxml.newWatcher(path) -> none
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

--- plugins.finalcutpro.watchfolders.fcpxml.removeWatcher(path) -> none
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

--- plugins.finalcutpro.watchfolders.fcpxml.addWatchFolder() -> none
--- Function
--- Opens the "Add Watch Folder" Dialog.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.addWatchFolder()
    Do(function()
        local path = dialog.displayChooseFolder(i18n("selectFolderToWatch"))
        if path then

            local watchFolders = mod.watchFolders()

            if tools.tableContains(watchFolders, path) then
                dialog.displayMessage(i18n("alreadyWatched"))
            else
                watchFolders[#watchFolders + 1] = path
            end

            --------------------------------------------------------------------------------
            -- Update Settings:
            --------------------------------------------------------------------------------
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
    end):After(0)
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

--- plugins.finalcutpro.watchfolders.fcpxml.setupWatchers(path) -> none
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
    if deliveredNotifications then
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
    end
    mod.savedNotifications(newSavedNotifications)
end

--- plugins.finalcutpro.watchfolders.fcpxml.init(deps, env) -> table
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
    if mod.manager then
        mod.panel = mod.manager.addPanel({
                priority        = 2020,
                id              = "fcpxml",
                label           = "FCPXML",
                image           = image.imageFromPath(tools.iconFallback(fcp:getPath() .. "/Contents/Resources/Final Cut.icns")),
                tooltip         = i18n("watchFolderFCPXMLTooltip"),
                height          = 475,
                loadFn          = mod.refreshTable,
            })
    end

    --------------------------------------------------------------------------------
    -- Setup Panel Contents:
    --------------------------------------------------------------------------------
    if mod.panel then
        mod.panel
            :addContent(1, mod.styleSheet())
            :addHeading(10, i18n("description"))
            :addParagraph(11, i18n("watchFolderXMLHelp"), false)
            :addParagraph(12, "")
            :addHeading(13, i18n("watchFolders"), 3)
            :addContent(14, html.div { id=mod.watchFolderTableID } ( mod.generateTable() ) )
            :addButton(15,
                {
                    label       = i18n("addWatchFolder"),
                    onclick     = mod.addWatchFolder,
                    class       = "btnAddWatchFolder",
                })
            :addParagraph(16, "")
            :addHeading(17, i18n("options"), 3)
            :addCheckbox(19,
                {
                    label       = i18n("automaticallyImport"),
                    checked     = mod.automaticallyImport,
                    onchange    = function(_, params) mod.automaticallyImport(params.checked) end,
                }
            )
            :addCheckbox(20,
                {
                    label		= i18n("deleteAfterImport", {
                        numberOfSeconds = mod.SECONDS_UNTIL_DELETE,
                        seconds = i18n("second", {count = mod.SECONDS_UNTIL_DELETE})
                    }),
                    checked     = mod.deleteAfterImport,
                    onchange    = function(_, params) mod.deleteAfterImport(params.checked) end,
                }
            )
            local uniqueUUID = string.gsub(uuid(), "-", "")
            mod.manager.addHandler(uniqueUUID, mod.controllerCallback)
            mod.panel:addContent(27, ui.javascript ([[
                window.onload = function() {
                    try {
                        var p = {};
                        p["action"] = "refresh";
                        var result = { id: "{{ id }}", params: p };
                        webkit.messageHandlers.watchfolders.postMessage(result);
                    } catch(err) {
                        alert('An error has occurred. Does the controller exist yet?');
                    }
                }
            ]], { id = uniqueUUID }))
    end

    --------------------------------------------------------------------------------
    -- Setup Watchers:
    --------------------------------------------------------------------------------
    mod.setupWatchers()

    return mod

end


local plugin = {
    id = "finalcutpro.watchfolders.fcpxml",
    group = "finalcutpro",
    dependencies = {
        ["core.watchfolders.manager"]       = "manager",
        ["finalcutpro.pasteboard.manager"]   = "pasteboardManager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then
        return mod.init(deps, env)
    end
end

return plugin
