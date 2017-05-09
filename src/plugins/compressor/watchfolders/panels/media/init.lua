--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           F I N A L    C U T    P R O   W A T C H   F O L D E R S          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.compressor.watchfolders.panels.media ===
---
--- Final Cut Pro Media Watch Folder Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("fcpwatch")

local application		= require("hs.application")
local axuielement 		= require("hs._asm.axuielement")
local eventtap			= require("hs.eventtap")
local fnutils			= require("hs.fnutils")
local fs				= require("hs.fs")
local http				= require("hs.http")
local image				= require("hs.image")
local notify			= require("hs.notify")
local pasteboard		= require("hs.pasteboard")
local pathwatcher		= require("hs.pathwatcher")
local task				= require("hs.task")
local timer				= require("hs.timer")
local uuid				= require("hs.host").uuid

local compressor		= require("cp.apple.compressor")
local config			= require("cp.config")
local dialog			= require("cp.dialog")
local just				= require("cp.just")
local prop				= require("cp.prop")
local tools				= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.compressor.watchfolders.panels.media.watchFolderTableID
--- Variable
--- Watch Folder Table ID
mod.watchFolderTableID = "compressorWatchFoldersTable"

--- plugins.compressor.watchfolders.panels.media.filesInTransit
--- Variable
--- Files currently being copied
mod.filesInTransit = {}

--- plugins.compressor.watchfolders.panels.media.notifications
--- Variable
--- Table of Path Watchers
mod.pathwatchers = {}

--- plugins.compressor.watchfolders.panels.media.notifications
--- Variable
--- Table of Notifications
mod.notifications = {}

--- plugins.compressor.watchfolders.panels.media.disableImport
--- Variable
--- When `true` Notifications will no longer be triggered.
mod.disableImport = false

--- plugins.compressor.watchfolders.panels.media.automaticallyImport
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.automaticallyImport = config.prop("compressorWatchFoldersAutomaticallyImport", false)

--- plugins.compressor.watchfolders.panels.media.savedNotifications
--- Variable
--- Table of Notifications that are saved between restarts
mod.savedNotifications = config.prop("compressorWatchFoldersSavedNotifications", {})

--- plugins.compressor.watchfolders.panels.media.deleteAfterImport
--- Variable
--- Boolean that sets whether or not you want to delete file after they've been imported.
mod.deleteAfterImport = config.prop("compressorWatchFoldersDeleteAfterImport", false)

--- plugins.compressor.watchfolders.panels.media.watchFolders
--- Variable
--- Table of the users watch folders.
mod.watchFolders = config.prop("compressorWatchFolders", {})

-- shortPath(input) -> string
-- Function
-- Returns a Short Path
--
-- Parameters:
--  * None
--
-- Returns:
--  * String
function shortPath(input)
	local maxLength = 22
	if input:len() <= maxLength then
		return input
	else
		return "..." .. string.sub(input, input:len() - maxLength)
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
	local watchFolders =  fnutils.copy(mod.watchFolders())

	for i, v in pairs(watchFolders) do
		local uniqueUUID = string.gsub(uuid(), "-", "")
		watchFoldersHTML = watchFoldersHTML .. [[
				<tr>
					<td class="rowPath">]] .. shortPath(i) .. [[</td>
					<td class="rowDestination">]] .. shortPath(v.destinationPath) .. [[ </td>
					<td class="rowSetting">]] .. string.sub(tools.getFilenameFromPath(v.settingFile), 1, -10) .. [[</td>
					<td class="rowRemove"><a onclick="remove]] .. uniqueUUID .. [[()" href="#">Remove</a></td>
				</tr>
		]]
		mod.manager.injectScript([[
			function remove]] .. uniqueUUID .. [[() {
				try {
					var p = {};
					p["action"] = "remove";
					p["path"] = "]] .. i .. [[";
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
					<td class="rowPath">Empty</td>
					<td class="rowDestination"></td>
					<td class="rowSetting"></td>
					<td class="rowRemove"></td>
				</tr>
		]]
	end

	local result = [[
		<table class="watchfolders">
			<thead>
				<tr>
					<th class="rowPath">Folder</th>
					<th class="rowDestination">Destination</th>
					<th class="rowSetting">Setting</th>
					<th class="rowRemove"></th>
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


-- removeFromTable(table, element) -> table
-- Function
-- Removes a string from a table of strings
--
-- Parameters:
--  * table - the table you want to check
--  * element - the string you want to remove
--
-- Returns:
--  * A table
function removeFromTable(table, element)
	local result = {}
	for value, contents in pairs(table) do
		if value ~= element then
			result[value] = contents
		end
	end
	return result
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
function mod.controllerCallback(id, params)
	if params and params.action and params.action == "remove" then
		mod.watchFolders(removeFromTable(fnutils.copy(mod.watchFolders()), params.path))
		mod.removeWatcher(params.path)
		mod.refreshTable()
	elseif params and params.action and params.action == "refresh" then
		mod.refreshTable()
	end
end

--- plugins.compressor.watchfolders.panels.media.styleSheet() -> string
--- Function
--- Generates Style Sheet
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns Style Sheet as a string
function mod.styleSheet()
	local result = [[
		<style>
			.btnAddWatchFolder {
				margin-top: 10px;
			}
			.watchfolders {
				float: left;
				margin-left: 20px;
				table-layout: fixed;
				width: 92%;
				white-space: nowrap;
				border: 1px solid #cccccc;
				padding: 8px;
				background-color: #ffffff;
				text-align: left;
			}

			.watchfolders td {
			  white-space: nowrap;
			  overflow: hidden;
			  text-overflow: ellipsis;
			}

			.rowPath {
				width:35%;
				text-align:lef;
			}

			.rowDestination {
				width:35%;
				text-align:lef;
			}

			.rowSetting {
				width:15%;
				text-align:lef;
			}

			.rowRemove {
				width:15%;
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
			}

			.deleteNote {
				font-size: 10px;
				margin-left: 20px;
			}

		</style>
	]]
	return result
end

-- wrapInQuotes(value) -> none
-- Function
-- Wraps a string in quotes
--
-- Parameters:
--  * value - Incoming string
--
-- Returns:
--  * A string in quotes
local function wrapInQuotes(value)
	return [["]] .. value .. [["]]
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
		--         	-computergroup <name> -- name of the Computer Group to use.
		--         --Batch Specific Info:--
		--         	-batchname <name> -- name to be given to the batch.
		--         	-priority <value> -- priority to be given to the batch. Possible values are: low, medium or high
		--         Job Info: Used when submitting individual source files. Following parameters are repeated to enter multiple job targets in a batch
		--         	-jobpath <url> -- url to source file.
		--         				   -- In case of Image Sequence, URL should be a file URL pointing to directory with image sequence.
		--         				   -- Additional parameters may be specified to set frameRate (e.g. frameRate=29.97) and audio file (e.g. audio=/usr/me/myaudiofile.mov).
		--         	-settingpath <url> -- url to settings file.
		--         	-locationpath <url> -- url to location file.
		--         	-info <xml> -- xml for job info.
		--         	-scc <url> -- url to scc file for source
		--         	-startoffset <hh:mm:ss;ff> -- time offset from beginning
		--         	-in <hh:mm:ss;ff> -- in time
		--         	-out <hh:mm:ss;ff> -- out time
		--         	-annotations <path> -- path to file to import annotations from; a plist file or a Quicktime movie
		--         	-chapters <path> -- path to file to import chapters from
		--         --Optional Info:--
		--         	-help -- Displays, on stdout, this help information.
		--         	-checkstream <url> -- url to source file to analyze
		--         	-findletterbox <url> -- url to source file to analyze
		--
		--         --Batch Monitoring Info:--
		--         Actions on Job:
		--         	-monitor -- monitor the job or batch specified by jobid or batchid.
		--         	-kill -- kill the job or batch specified by jobid or batchid.
		--         	-pause -- pause the job or batch specified by jobid or batchid.
		--         	-resume -- resume previously paused job or batch specified by jobid or batchid.
		--         Optional Info:
		--         	-jobid <id> -- unique id of the job usually obtained when job was submitted.
		--         	-batchid <id> -- unique id of the batch usually obtained when job was submitted.
		--         	-query <seconds> -- The value in seconds, specifies how often to query the cluster for job status.
		--         	-timeout <seconds> -- the timeOut value, in seconds, specifies when to quit the process.
		--         	-once -- show job status only once and quit the process.
		--
		--         --Sharing Related Options:--
		--         	-resetBackgroundProcessing [cancelJobs] -- Restart all processes used in background processing, and optionally cancel all queued jobs.
		--
		--         	-repairCompressor -- Repair Compressor config files and restart all processes used in background processing.
		--
		--         	-sharing <on/off>  -- Turn sharing of this computer on or off.
		--
		--         	-requiresPassword [password] -- Sharing of this computer requires specified password. Computer must not be busy processing jobs when you set the password.
		--
		--         	-noPassword  -- Turn off the password requirement for sharing this computer.
		--
		--         	-instances <number>  -- Enables additional Compressor instances.
		--
		--         	-networkInterface <bsdname>  -- Specify which network interface to use. If "all" is specified for <bsdname>, all available network interfaces are used.
		--
		--         	-portRange <startNumber> <count>  -- Defines what port range use, using start number specifying how many ports to use.
		--
		-- EXAMPLE:
		--
		-- /Applications/Compressor.app/Contents/MacOS/Compressor
		-- -batchname "My First Batch" -jobpath ~/Movies/
		-- MySource.mov -settingpath ~/Library/Application\
		-- Support/Compressor/Settings/Apple\ Devices\ HD\ \
		-- (Custom\).cmprstng -locationpath ~/Movies/MyOutput.m4v

		-------------------------------------------------------------------------------
		-- Show Notification:
		--------------------------------------------------------------------------------
		if mod.notifications[file] then
			mod.notifications[file]:withdraw()
			mod.notifications[file] = nil
		end
		mod.notifications[file] = notify.new(function()
			compressor:launch()
		end)
			:title(i18n("addedToCompressor"))
			:subTitle(tools.getFilenameFromPath(file))
			:hasActionButton(true)
			:actionButtonTitle(i18n("monitor"))
			:send()

		local selectedFile = nil
		local watchFolders = fnutils.copy(mod.watchFolders())
		for i, v in pairs(watchFolders) do
			if i == string.sub(file, 1, string.len(i)) then
				selectedFile = v
			end
		end

		local compressorPath = compressor:getPath()

		local filename = tools.getFilenameFromPath(file, true)

		local uniqueUUID = string.gsub(uuid(), "-", "")

		local compressorCommand = compressorPath .. [[/Contents/MacOS/Compressor -batchname "CommandPost Watch Folder" -jobid "]] .. uniqueUUID .. [[" -jobpath "]] .. file .. [[" -settingpath "]] .. selectedFile.settingFile .. [[" -locationpath "]] .. selectedFile.destinationPath .. filename .. [[" &]]
		local output, status, endType = hs.execute(compressorCommand)
		if status then
			--------------------------------------------------------------------------------
			-- Command Triggered Successfully:
			--------------------------------------------------------------------------------
			--[[
			if not mod.compressorTask then
				mod.compressorTask = {}
			end
			mod.compressorTask[uniqueUUID] =  task.new(compressorPath .. "/Contents/MacOS/Compressor", function(exitCode, stdOut, stdErr)
				log.df("exitCode: %s", exitCode)
				log.df("stdOut: %s", stdOut)
				log.df("stdErr: %s", stdErr)
			end, function(task, stdOut, stdErr)
				log.df("task: %s", task)
				log.df("stdOut: %s", stdOut)
				log.df("stdErr: %s", stdErr)
			end, { "-monitor", "-jobid", wrapInQuotes(uniqueUUID) } )
			:start()
			--]]
		else
			log.df("compressorCommand: %s", compressorCommand)
			log.df("RESULT:\nOutput: %s\nStatus: %s\nendType: %s", output, status, endType)
			dialog.displayErrorMessage(i18n("compressorError"))
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

	--------------------------------------------------------------------------------
	-- Add Event Flags to Table:
	--------------------------------------------------------------------------------
	local eventFlagsValues = {}
	for i, flags in pairs(eventFlags) do
		for description,value in pairs(pathwatcher.eventFlags) do
			if not eventFlagsValues[i] then
				eventFlagsValues[i] = {}
			end
			if eventFlags[i] & value == value then
				eventFlagsValues[i][description] = true
			else
				eventFlagsValues[i][description] = false
			end
		end
	end

	if not mod.disableImport then
		local autoFiles = {}
		local allowedExtensions = compressor.ALLOWED_IMPORT_ALL_EXTENSIONS
		for i,file in pairs(files) do

			--------------------------------------------------------------------------------
			-- File deleted or removed from Watch Folder:
			--------------------------------------------------------------------------------
			if eventFlagsValues[i] and eventFlagsValues[i]["itemRenamed"] and eventFlagsValues[i]["itemIsFile"] and not tools.doesFileExist(file) then
				--log.df("File deleted or moved outside of watch folder!")
				if mod.notifications[file] then
					mod.notifications[file]:withdraw()
					mod.notifications[file] = nil
					local savedNotifications = fnutils.copy(mod.savedNotifications())
					savedNotifications[file] = nil
					mod.savedNotifications(savedNotifications)
				end
			else

				--------------------------------------------------------------------------------
				-- New File Added to Watch Folder:
				--------------------------------------------------------------------------------
				local newFile = false
				if eventFlagsValues[i]["itemCreated"] and eventFlagsValues[i]["itemIsFile"] and eventFlagsValues[i]["itemModified"] then
					--log.df("New File Added: %s", file)
					newFile = true
				end

				--------------------------------------------------------------------------------
				-- New File Added to Watch Folder, but still in transit:
				--------------------------------------------------------------------------------
				if eventFlagsValues[i]["itemCreated"] and eventFlagsValues[i]["itemIsFile"] and not eventFlagsValues[i]["itemModified"] then

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
				if eventFlagsValues[i]["itemModified"] and eventFlagsValues[i]["itemIsFile"] and fnutils.contains(mod.filesInTransit, file) then
					tools.removeFromTable(mod.filesInTransit, file)
					if mod.notifications[file] then
						mod.notifications[file]:withdraw()
						mod.notifications[file] = nil
					end
					newFile = true
				end

				--------------------------------------------------------------------------------
				-- New File Moved into Watch Folder:
				--------------------------------------------------------------------------------
				local movedFile = false
				if eventFlagsValues[i]["itemRenamed"] and eventFlagsValues[i]["itemIsFile"] then
					--log.df("File Moved or Renamed: %s", file)
					movedFile = true
				end

				--------------------------------------------------------------------------------
				-- Check Extensions:
				--------------------------------------------------------------------------------
				if ((fnutils.contains(allowedExtensions, file:sub(-3)) or fnutils.contains(allowedExtensions, file:sub(-4)))) and tools.doesFileExist(file) then
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

	--------------------------------------------------------------------------------
	-- Select Watch Folder Folder:
	--------------------------------------------------------------------------------
	local path = dialog.displayChooseFolder(i18n("selectFolderToWatch"))
	if not path then
		return
	end
	if tools.tableContains(watchFolders, path) then
		dialog.displayMessage(i18n("alreadyWatched"))
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
	local settingFile = dialog.displayChooseFile(i18n("selectCompressorSettingsFile"), "cmprstng", defaultPath)
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
	local watchFolders = fnutils.copy(mod.watchFolders())
	watchFolders[path] = {settingFile=settingFile, destinationPath=destinationPath }
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
	local watchFolders = fnutils.copy(mod.watchFolders())
	for i, v in pairs(watchFolders) do
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
function mod.init(deps, env)

	--------------------------------------------------------------------------------
	-- Ignore Panel if Compressor isn't installed.
	--------------------------------------------------------------------------------
	if not compressor:isInstalled() then
		return nil
	end

	--------------------------------------------------------------------------------
	-- Define Plugins:
	--------------------------------------------------------------------------------
	mod.clipboardManager = deps.clipboardManager
	mod.manager = deps.manager

	--------------------------------------------------------------------------------
	-- Setup Panel:
	--------------------------------------------------------------------------------
	mod.panel = deps.manager.addPanel({
			priority 		= 2020,
			id				= "compressor",
			label			= i18n("compressor"),
			image			= image.imageFromPath(compressor:getPath() .. "/Contents/Resources/compressor.icns"),
			tooltip			= i18n("watchFolderCompressorTooltip"),
			height			= 380,
			loadFn			= mod.refreshTable,
		})

	--------------------------------------------------------------------------------
	-- Setup Panel Contents:
	--------------------------------------------------------------------------------
	mod.panel
		:addContent(1, mod.styleSheet(), true)
		:addHeading(10, i18n("description"))
		:addParagraph(11, i18n("watchFolderCompressorHelp"), true)
		:addParagraph(12, "")
		:addHeading(13, i18n("watchFolders"), 3)
		:addContent(14, [[<div id="]] .. mod.watchFolderTableID .. [[">]] .. mod.generateTable() .. [[</div>]], true)
		:addButton(15,
			{
				label		= i18n("addWatchFolder"),
				onclick		= mod.addWatchFolder,
				class		= "btnAddWatchFolder",
			})
		local uniqueUUID = string.gsub(uuid(), "-", "")
		mod.manager.addHandler(uniqueUUID, mod.controllerCallback)
		mod.panel:addContent(27, [[
			<script>
				window.onload = function() {
					try {
						var p = {};
						p["action"] = "refresh";
						var result = { id: "]] .. uniqueUUID .. [[", params: p };
						webkit.messageHandlers.watchfolders.postMessage(result);
					} catch(err) {
						alert('An error has occurred. Does the controller exist yet?');
					}
				}
			</script>
		]],true)

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
	id = "compressor.watchfolders.panels.media",
	group = "compressor",
	dependencies = {
		["core.watchfolders.manager"]		= "manager",
		["finalcutpro.clipboard.manager"]	= "clipboardManager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(deps, env)
end

return plugin