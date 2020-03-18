--- === plugins.compressor.watchfolders.panels.media ===
---
--- Compressor Watch Folder Plugin.

local require = require

local log                       = require "hs.logger".new "compressorWatchFolder"

local fnutils                   = require "hs.fnutils"
local host                      = require "hs.host"
local image                     = require "hs.image"
local notify                    = require "hs.notify"
local pathwatcher               = require "hs.pathwatcher"
local task                      = require "hs.task"
local timer                     = require "hs.timer"

local compressor                = require "cp.apple.compressor"
local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local Do                        = require "cp.rx.go.Do"
local html                      = require "cp.web.html"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"
local ui                        = require "cp.web.ui"

local xml                       = require "hs._asm.xml"

local doesFileExist             = tools.doesFileExist
local doEvery                   = timer.doEvery

local getFilenameFromPath       = tools.getFilenameFromPath
local incrementFilenameInPath   = tools.incrementFilenameInPath
local tableContains             = tools.tableContains
local unescape                  = tools.unescape
local uuid                      = host.uuid

local mod = {}

-- WATCH_FOLDER_TABLE_ID -> string
-- Variable
-- Watch Folder Table ID
local WATCH_FOLDER_TABLE_ID  = "compressorWatchFoldersTable"

--- plugins.compressor.watchfolders.panels.media.filesInTransit -> table
--- Variable
--- Files currently being copied
mod.filesInTransit = {}

--- plugins.compressor.watchfolders.panels.media.notifications -> table
--- Variable
--- Table of Path Watchers
mod.pathwatchers = {}

--- plugins.compressor.watchfolders.panels.media.notifications -> table
--- Variable
--- Table of Notifications
mod.notifications = {}

--- plugins.compressor.watchfolders.panels.media.tasks -> table
--- Variable
--- Table of Tasks
mod.tasks = {}

--- plugins.compressor.watchfolders.panels.media.disableImport -> boolean
--- Variable
--- When `true` Notifications will no longer be triggered.
mod.disableImport = false

--- plugins.compressor.watchfolders.panels.media.savedNotifications <cp.prop: table>
--- Variable
--- Table of Notifications that are saved between restarts
mod.savedNotifications = config.prop("compressor.watchFolders.savedNotifications", {})

--- plugins.compressor.watchfolders.panels.media.watchFolders <cp.prop: table>
--- Variable
--- Table of the users watch folders.
mod.watchFolders = config.prop("compressor.watchFolders.v2", {}) -- Added v2 when added support to have multiple Compressor presets for same folder.

-- nameCache -> table
-- Variable
-- Table of cached Compressor Settings names.
local nameCache = {}

-- getNameFromSettingsFile -> string
-- Function
-- Gets the name from a Compressor Settings file.
--
-- Parameters:
--  * path - The path to the settings file.
--
-- Returns:
--  * A string containing the name of the settings file.
local function getNameFromSettingsFile(path)
    if nameCache[path] then
        return nameCache[path]
    end
    local data = xml.open(path)
    if data then
        local children = data:children()
        if children and children[1] then
            local name = children[1]:attribute("name")
            if name then
                nameCache[path] = unescape(name)
                return unescape(name)
            end
        end
    end
end

--- plugins.compressor.watchfolders.panels.media.generateTable() -> string
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

    for path, presets in pairs(watchFolders) do
        for _, v in pairs(presets) do
            local uniqueUUID = string.gsub(uuid(), "-", "")
            watchFoldersHTML = watchFoldersHTML .. [[
                    <tr>
                        <td class="compressorRowPath">]] .. path .. [[</td>
                        <td class="compressorRowDestination">]] .. v.destinationPath .. [[ </td>
                        <td class="compressorRowSetting">]] .. getNameFromSettingsFile(v.settingFile) .. [[</td>
                        <td class="compressorRowRemove"><a onclick="remove]] .. uniqueUUID .. [[()" href="#">Remove</a></td>
                    </tr>
            ]]
            mod.manager.injectScript([[
                function remove]] .. uniqueUUID .. [[() {
                    try {
                        var p = {};
                        p["action"] = "remove";
                        p["path"] = "]] .. path .. [[";
                        p["settingFile"] = "]] .. v.settingFile .. [[";
                        var result = { id: "]] .. uniqueUUID .. [[", params: p };
                        webkit.messageHandlers.watchfolders.postMessage(result);
                    } catch(err) {
                        alert('An error has occurred. Does the controller exist yet?');
                    }
                }
            ]])
            mod.manager.addHandler(uniqueUUID, mod.controllerCallback)
        end
    end

    if watchFoldersHTML == "" then
        watchFoldersHTML = [[
                <tr>
                    <td class="compressorRowPath">Empty</td>
                    <td class="compressorRowDestination"></td>
                    <td class="compressorRowSetting"></td>
                    <td class="compressorRowRemove"></td>
                </tr>
        ]]
    end

    local result = [[
        <table class="compressorWatchfolders">
            <thead>
                <tr>
                    <th class="compressorRowPath">Folder</th>
                    <th class="compressorRowDestination">Destination</th>
                    <th class="compressorRowSetting">Setting</th>
                    <th class="compressorRowRemove"></th>
                </tr>
            </thead>
            <tbody>
                ]] .. watchFoldersHTML .. [[
            </tbody>
        </table>
    ]]

    return result

end

--- plugins.compressor.watchfolders.panels.media.refreshTable() -> string
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
            var ]] .. WATCH_FOLDER_TABLE_ID .. [[ = document.getElementById("]] .. WATCH_FOLDER_TABLE_ID .. [[");
            if (typeof(]] .. WATCH_FOLDER_TABLE_ID .. [[) != 'undefined' && ]] .. WATCH_FOLDER_TABLE_ID .. [[ != null)
            {
                document.getElementById("]] .. WATCH_FOLDER_TABLE_ID .. [[").innerHTML = `]] .. mod.generateTable() .. [[`;
            }
        }
        catch(err) {
            alert("Refresh Table Error");
        }
        ]]
    mod.manager.injectScript(result)
end

--- plugins.compressor.watchfolders.panels.media.controllerCallback(id, params) -> none
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
        local watchFolders = mod.watchFolders()
        if watchFolders[params.path] then
            for i, item in pairs(watchFolders[params.path]) do
                if item.settingFile == params.settingFile then
                    table.remove(watchFolders[params.path], i)
                end
            end
            if not next(watchFolders[params.path]) then
                watchFolders[params.path] = nil
                mod.removeWatcher(params.path)
            end
        end
        mod.watchFolders(watchFolders)
        mod.refreshTable()
    elseif params and params.action and params.action == "refresh" then
        mod.refreshTable()
    end
end

--- plugins.compressor.watchfolders.panels.media.styleSheet() -> cp.web.html
--- Function
--- Generates Style Sheet
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns Style Sheet as a `cp.web.html` block.
function mod.styleSheet()
    return ui.style [[
        .compressorBtnAddWatchFolder {
            margin-top: 10px;
        }
        .compressorWatchfolders {
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

        .compressorWatchfolders td {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .compressorRowPath {
            width:35%;
            text-align:left;
        }

        .compressorRowDestination {
            width:35%;
            text-align:left;
        }

        .compressorRowSetting {
            width:15%;
            text-align:left;
        }

        .compressorRowRemove {
            width:15%;
            text-align:right;
        }

        .compressorWatchfolders thead, .compressorWatchfolders tbody tr {
            display:table;
            table-layout:fixed;
            width: 100%;
        }

        .compressorWatchfolders tbody {
            display:block;
            height: 80px;
            font-weight: normal;
            font-size: 10px;

            overflow-x: hidden;
            overflow-y: auto;
        }

        .compressorWatchfolders tbody tr {
            display:table;
            width:100%;
            table-layout:fixed;
        }

        .compressorWatchfolders thead {
            font-weight: bold;
            font-size: 12px;
        }

        .compressorWatchfolders tbody {
            font-weight: normal;
            font-size: 10px;
        }

        .compressorWatchfolders tbody tr:hover {
            background-color: #006dd4;
            color: white;
        }

        .compressorWatchFolderTextBox {
            vertical-align: middle;
        }

        .compressorWatchFolderTextBox label {
            display: inline-block;
            width: 100px;
            height: 25px;
        }

        .compressorWatchFolderTextBox input {
            display: inline-block;
        }
    ]]
end

--- plugins.compressor.watchfolders.panels.media.watchCompressorStatus(jobID) -> none
--- Function
--- Checks the Status of a Job in Compressor
---
--- Parameters:
---  * jobID - Job ID as string
---  * file - File Path as string
---  * destinationPath - Destination Path as string
---
--- Returns:
---  * None
mod.statusTimer = {}
mod.statusTasks = {}
function mod.watchCompressorStatus(jobID, file, destinationPath)
    local compressorPath = compressor:getPath() .. "/Contents/MacOS/Compressor"
    --log.df("Lets track the status of: %s", jobID)
    mod.statusTimer[jobID] = doEvery(5, function()
        if mod.statusTasks[jobID] and mod.statusTasks[jobID]:isRunning() == true then
            --log.df("status task already running")
            return
        end
        mod.statusTasks[jobID] = task.new(compressorPath, nil, function(_, stdOut)
            if stdOut and string.match(stdOut, [[status="([^%s]+)"]]) then
                local status = string.match(stdOut, [[status="([^%s]+)"]])
                --log.df("Status: %s", status)
                if status and status == "Cancelled" then
                    -------------------------------------------------------------------------------
                    -- Cancelled:
                    --------------------------------------------------------------------------------
                    --log.df("Render Cancelled: %s", jobID)
                    mod.statusTimer[jobID]:stop()
                    mod.statusTimer[jobID] = nil
                elseif status and status == "Successful" then
                    -------------------------------------------------------------------------------
                    -- Show Notification:
                    --------------------------------------------------------------------------------
                    --log.df("SUCCESSFUL: %s", file)
                    if mod.notifications[file] then
                        mod.notifications[file]:withdraw()
                        mod.notifications[file] = nil
                    end
                    mod.notifications[file] = notify.new(function()
                        os.execute([[open "]] .. destinationPath .. [["]])
                    end)
                        :title(i18n("renderComplete"))
                        :subTitle(getFilenameFromPath(file))
                        :hasActionButton(true)
                        :actionButtonTitle(i18n("show"))
                        :withdrawAfter(0)
                        :send()
                    mod.statusTimer[jobID]:stop()
                    mod.statusTimer[jobID] = nil
                elseif status and status == "Processing" then -- luacheck:ignore
                    --log.df("Compressor is processing the following file: %s", file)
                else
                    log.ef("Unknown Status from Compressor: %s", status)
                    if mod.statusTimer[jobID] then
                        mod.statusTimer[jobID]:stop()
                        mod.statusTimer[jobID] = nil
                    end
                end
                mod.statusTasks[jobID] = nil
            end
            return true
        end, { "-monitor", "-jobid", jobID }):start()
    end)
end

--- plugins.compressor.watchfolders.panels.media.addFilesToCompressor(files) -> none
--- Function
--- Imports a file into Final Cut Pro
---
--- Parameters:
---  * files - File names in table
---
--- Returns:
---  * None
function mod.addFilesToCompressor(files)

    --------------------------------------------------------------------------------
    -- Disable Import:
    --------------------------------------------------------------------------------
    mod.disableImport = true

    --------------------------------------------------------------------------------
    -- Add files to Compressor:
    --------------------------------------------------------------------------------
    for _, file in pairs(files) do

        --         Usage:  Compressor [Cluster Info] [Batch Specific Info] [Optional Info] [Other Options]
        --
        --          -computergroup <name> -- name of the Computer Group to use.
        --         --Batch Specific Info:--
        --          -batchname <name> -- name to be given to the batch.
        --          -priority <value> -- priority to be given to the batch. Possible values are: low, medium or high
        --         Job Info: Used when submitting individual source files. Following parameters are repeated to enter multiple job targets in a batch
        --          -jobpath <url> -- url to source file.
        --                         -- In case of Image Sequence, URL should be a file URL pointing to directory with image sequence.
        --                         -- Additional parameters may be specified to set frameRate (e.g. frameRate=29.97) and audio file (e.g. audio=/usr/me/myaudiofile.mov).
        --          -settingpath <url> -- url to settings file.
        --          -locationpath <url> -- url to location file.
        --          -info <xml> -- xml for job info.
        --          -scc <url> -- url to scc file for source
        --          -startoffset <hh:mm:ss;ff> -- time offset from beginning
        --          -in <hh:mm:ss;ff> -- in time
        --          -out <hh:mm:ss;ff> -- out time
        --          -annotations <path> -- path to file to import annotations from; a plist file or a Quicktime movie
        --          -chapters <path> -- path to file to import chapters from
        --         --Optional Info:--
        --          -help -- Displays, on stdout, this help information.
        --          -checkstream <url> -- url to source file to analyze
        --          -findletterbox <url> -- url to source file to analyze
        --
        --         --Batch Monitoring Info:--
        --         Actions on Job:
        --          -monitor -- monitor the job or batch specified by jobid or batchid.
        --          -kill -- kill the job or batch specified by jobid or batchid.
        --          -pause -- pause the job or batch specified by jobid or batchid.
        --          -resume -- resume previously paused job or batch specified by jobid or batchid.
        --         Optional Info:
        --          -jobid <id> -- unique id of the job usually obtained when job was submitted.
        --          -batchid <id> -- unique id of the batch usually obtained when job was submitted.
        --          -query <seconds> -- The value in seconds, specifies how often to query the cluster for job status.
        --          -timeout <seconds> -- the timeOut value, in seconds, specifies when to quit the process.
        --          -once -- show job status only once and quit the process.
        --
        --         --Sharing Related Options:--
        --          -resetBackgroundProcessing [cancelJobs] -- Restart all processes used in background processing, and optionally cancel all queued jobs.
        --
        --          -repairCompressor -- Repair Compressor config files and restart all processes used in background processing.
        --
        --          -sharing <on/off>  -- Turn sharing of this computer on or off.
        --
        --          -requiresPassword [password] -- Sharing of this computer requires specified password. Computer must not be busy processing jobs when you set the password.
        --
        --          -noPassword  -- Turn off the password requirement for sharing this computer.
        --
        --          -instances <number>  -- Enables additional Compressor instances.
        --
        --          -networkInterface <bsdname>  -- Specify which network interface to use. If "all" is specified for <bsdname>, all available network interfaces are used.
        --
        --          -portRange <startNumber> <count>  -- Defines what port range use, using start number specifying how many ports to use.
        --
        -- EXAMPLE:
        --
        -- /Applications/Compressor.app/Contents/MacOS/Compressor
        -- -batchname "My First Batch" -jobpath ~/Movies/
        -- MySource.mov -settingpath ~/Library/Application\
        -- Support/Compressor/Settings/Apple\ Devices\ HD\ \
        -- (Custom\).cmprstng -locationpath ~/Movies/MyOutput.m4v

        local presets = nil
        local watchFolders = mod.watchFolders()
        for i, v in pairs(watchFolders) do
            if i == string.sub(file, 1, string.len(i)) then
                presets = v
            end
        end

        local compressorPath = compressor:getPath() .. "/Contents/MacOS/Compressor"

        local filename = getFilenameFromPath(file, true)

        local usedFiles = {}
        for _, item in pairs(presets) do

            local exportFile = item.destinationPath .. filename

            repeat
                if doesFileExist(exportFile) or tableContains(usedFiles, exportFile) then
                    exportFile = incrementFilenameInPath(exportFile)
                end
            until(doesFileExist(exportFile) == false and tableContains(usedFiles, exportFile) == false)
            table.insert(usedFiles, exportFile)

            local id = exportFile

            -------------------------------------------------------------------------------
            -- Show Notification:
            --------------------------------------------------------------------------------
            if mod.notifications[id] then
                mod.notifications[id]:withdraw()
                mod.notifications[id] = nil
            end
            mod.notifications[id] = notify.new(function()
                compressor:launch()
            end)
                :title(i18n("addedToCompressor"))
                :subTitle(getFilenameFromPath(file))
                :informativeText(getNameFromSettingsFile(item.settingFile))
                :hasActionButton(true)
                :actionButtonTitle(i18n("monitor"))
                :withdrawAfter(0)
                :send()

            mod.tasks[exportFile] = task.new(compressorPath, function(exitCode)
                if exitCode ~= 0 then
                    --------------------------------------------------------------------------------
                    -- Compressor Failed:
                    --------------------------------------------------------------------------------
                    if mod.notifications[id] then
                        mod.notifications[id]:withdraw()
                        mod.notifications[id] = nil
                    end

                    --------------------------------------------------------------------------------
                    -- Show Failed Notification:
                    --------------------------------------------------------------------------------
                    notify.new(function() compressor:launch() end)
                        :title("Compressor Failed:")
                        :subTitle(getFilenameFromPath(file))
                        :informativeText(getNameFromSettingsFile(item.settingFile))
                        :hasActionButton(true)
                        :actionButtonTitle(i18n("monitor"))
                        :withdrawAfter(0)
                        :send()
                end
                --------------------------------------------------------------------------------
                -- Remove the task:
                --------------------------------------------------------------------------------
                if mod.tasks[exportFile] then
                    --log.df("Removing task: %s", id)
                    mod.tasks[id] = nil
                end
            end,
            function(_, _, stdErr)
                local jobID = nil
                local jobIDPattern = "jobID ([^%s]+)"
                if stdErr and string.find(stdErr, jobIDPattern) then
                    jobID = string.match(stdErr, jobIDPattern)
                end
                if jobID then
                    --------------------------------------------------------------------------------
                    -- Watch the Compressor Status:
                    --------------------------------------------------------------------------------
                    mod.watchCompressorStatus(jobID, exportFile, item.destinationPath)

                    --------------------------------------------------------------------------------
                    -- We only want to trigger the streamCallbackFn for the jobID:
                    --------------------------------------------------------------------------------
                    return false
                end
                return true
            end, { "-batchname", "CommandPost Watch Folder", "-jobpath", file, "-settingpath", item.settingFile, "-locationpath", exportFile } ):start()

            if not mod.tasks[exportFile] then
                if mod.notifications[id] then
                    mod.notifications[id]:withdraw()
                    mod.notifications[id] = nil
                end
                dialog.displayErrorMessage(i18n("compressorError"))
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Re-enable Import:
    --------------------------------------------------------------------------------
    mod.disableImport = false

    return true
end

--- plugins.compressor.watchfolders.panels.media.watchFolderTriggered(files) -> none
--- Function
--- Watch Folder Triggered
---
--- Parameters:
---  * files - A table of files
---
--- Returns:
---  * None
function mod.watchFolderTriggered(files, eventFlags)

    if not mod.disableImport then
        local autoFiles = {}
        local allowedExtensions = compressor.ALLOWED_IMPORT_ALL_EXTENSIONS
        for i,file in pairs(files) do

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
                --if eventFlags[i]["itemCreated"] and eventFlags[i]["itemIsFile"] and eventFlags[i]["itemModified"] then
                    --log.df("New File Added: %s", file)
                --end

                --------------------------------------------------------------------------------
                -- New File Added to Watch Folder, but still in transit:
                --------------------------------------------------------------------------------
                if eventFlags[i]["itemCreated"] and eventFlags[i]["itemIsFile"] and not eventFlags[i]["itemModified"] then
                    -------------------------------------------------------------------------------
                    -- Only show temporary notification for allowed files:
                    -------------------------------------------------------------------------------
                    if ((fnutils.contains(allowedExtensions, string.lower(file:sub(-3))) or fnutils.contains(allowedExtensions, string.lower(file:sub(-4))))) then
                        -------------------------------------------------------------------------------
                        -- Add filename to table:
                        -------------------------------------------------------------------------------
                        mod.filesInTransit[#mod.filesInTransit + 1] = file

                        -------------------------------------------------------------------------------
                        -- Show Temporary Notification:
                        --------------------------------------------------------------------------------
                        mod.notifications[file] = notify.new()
                            :title(i18n("incomingFile"))
                            :subTitle(getFilenameFromPath(file))
                            :hasActionButton(false)
                            :withdrawAfter(0)
                            :send()
                    end
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

                --------------------------------------------------------------------------------
                -- New File Moved into Watch Folder:
                --------------------------------------------------------------------------------
                --if eventFlags[i]["itemRenamed"] and eventFlags[i]["itemIsFile"] then
                    --log.df("File Moved or Renamed: %s", file)
                --end

                --------------------------------------------------------------------------------
                -- Check Extensions:
                --------------------------------------------------------------------------------
                if ((fnutils.contains(allowedExtensions, string.lower(file:sub(-3))) or fnutils.contains(allowedExtensions, string.lower(file:sub(-4))))) and tools.doesFileExist(file) then
                    autoFiles[#autoFiles + 1] = file
                end
            end
        end
        if next(autoFiles) ~= nil then
            mod.addFilesToCompressor(autoFiles)
        end
    end
end

--- plugins.compressor.watchfolders.panels.media.newWatcher(path) -> none
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

--- plugins.compressor.watchfolders.panels.media.removeWatcher(path) -> none
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

--- plugins.compressor.watchfolders.panels.media.addWatchFolder() -> none
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
        --------------------------------------------------------------------------------
        -- Select Watch Folder Folder:
        --------------------------------------------------------------------------------
        local path = dialog.displayChooseFolder(i18n("selectFolderToWatch"))
        if not path then
            return
        end

        --------------------------------------------------------------------------------
        -- Select Setting File:
        --------------------------------------------------------------------------------
        local settingsPath = os.getenv("HOME") .. "/Library/Application Support/Compressor/Settings"
        local defaultPath = nil
        if tools.doesDirectoryExist(settingsPath) then
            defaultPath = settingsPath
        end
        local settingFile = dialog.displayChooseFile(i18n("selectCompressorSettingsFile"), {"cmprstng", "compressorsetting"}, defaultPath)
        if not settingFile then
            return
        end

        --------------------------------------------------------------------------------
        -- Select Destination Folder:
        --------------------------------------------------------------------------------
        local destinationPath = dialog.displayChooseFolder(i18n("selectCompressorDestination"))
        if not destinationPath then
            return
        end

        --------------------------------------------------------------------------------
        -- Update Settings:
        --------------------------------------------------------------------------------
        local watchFolders = mod.watchFolders()
        if not watchFolders[path] then
            watchFolders[path] = {}
        end
        table.insert(watchFolders[path], {settingFile=settingFile, destinationPath=destinationPath })
        mod.watchFolders(watchFolders)

        --------------------------------------------------------------------------------
        -- Refresh HTML Table:
        --------------------------------------------------------------------------------
        mod.refreshTable()

        --------------------------------------------------------------------------------
        -- Setup New Watcher:
        --------------------------------------------------------------------------------
        mod.newWatcher(path)
    end):After(0)
end

--- plugins.compressor.watchfolders.panels.media.setupWatchers(path) -> none
--- Function
--- Setup Folder Watchers
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setupWatchers()
    local watchFolders = mod.watchFolders()
    for i, _ in pairs(watchFolders) do
        mod.newWatcher(i)
    end
end

--- plugins.compressor.watchfolders.panels.media.init(deps, env) -> table
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
    -- Ignore Panel if Compressor isn't supported.
    --------------------------------------------------------------------------------
    if not compressor:isSupported() then
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
            priority        = 2030,
            id              = "compressor",
            label           = i18n("compressor"),
            image           = image.imageFromPath(tools.iconFallback(compressor:getPath() .. "/Contents/Resources/compressor.icns")),
            tooltip         = i18n("watchFolderCompressorTooltip"),
            height          = 360,
            loadFn          = mod.refreshTable,
        })

    --------------------------------------------------------------------------------
    -- Setup Panel Contents:
    --------------------------------------------------------------------------------
    mod.panel
        :addContent(1, mod.styleSheet())
        :addHeading(10, i18n("description"))
        :addParagraph(11, i18n("watchFolderCompressorHelp"), false)
        :addParagraph(12, "")
        :addHeading(13, i18n("watchFolders"), 3)
        :addContent(14, html.div { id = WATCH_FOLDER_TABLE_ID } ( mod.generateTable() ) )
        :addButton(15,
            {
                label       = i18n("addWatchFolder"),
                onclick     = mod.addWatchFolder,
                class       = "compressorBtnAddWatchFolder",
            })

    local uniqueUUID = string.gsub(uuid(), "-", "")
    mod.manager.addHandler(uniqueUUID, mod.controllerCallback)
    mod.panel:addContent(27, ui.javascript
    ([[
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
    ]], {id = uniqueUUID}))

    --------------------------------------------------------------------------------
    -- Setup Watchers:
    --------------------------------------------------------------------------------
    mod.setupWatchers()

    return mod

end

local plugin = {
    id = "compressor.watchfolders.panels.media",
    group = "compressor",
    dependencies = {
        ["core.watchfolders.manager"]       = "manager",
        ["finalcutpro.pasteboard.manager"]   = "pasteboardManager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
