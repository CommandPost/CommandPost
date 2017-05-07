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

local watchFolderTableID = "compressorWatchFoldersTable"

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
			var ]] .. watchFolderTableID .. [[ = document.getElementById("]] .. watchFolderTableID .. [[");
			if (typeof(]] .. watchFolderTableID .. [[) != 'undefined' && ]] .. watchFolderTableID .. [[ != null)
			{
				document.getElementById("]] .. watchFolderTableID .. [[").innerHTML = `]] .. mod.generateTable() .. [[`;
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

		-- Compressor [-computergroup <name>] [-batchname <name>]
		--     [-priority <value>] -jobpath <file>[?frameRate=<frame rate>
		--     |?audio=<file>|?frameRate=<frame rate>\&audio=<file>]
		--     -settingpath <setting> -locationpath <file>
		--     [-info <xml>] [-scc <file>] [-startoffset <hh:mm:ss:ff>]
		--     [-in <hh:mm:ss:ff> [-out <hh:mm:ss:ff> [-annotations <file>]
		--     [-chapters <file>]
		-- Compressor -checkstream <file>
		-- Compressor -findletterbox <file>
		-- Compressor -help
		-- Compressor [-resetBackgroundProcessing [cancelJobs]]
		--     [-sharing <on|off>] [[-requiresPassword <password>]
		--     | [-noPassword]] [-instances <value>]
		--     [-networkInterface <bsd name>] [-portRange <starting port>
		--     <count>]
		-- These three arguments are the minimum required to submit a batch:
		--
		-- Compressor ‑jobpath <path> ‑settingpath <path> ‑locationpath <path>
		--
		-- EXAMPLE:
		--
		-- /Applications/Compressor.app/Contents/MacOS/Compressor
		-- -batchname "My First Batch" -jobpath ~/Movies/
		-- MySource.mov -settingpath ~/Library/Application\
		-- Support/Compressor/Settings/Apple\ Devices\ HD\ \
		-- (Custom\).cmprstng -locationpath ~/Movies/MyOutput.m4v

		local selectedFile = nil
		local watchFolders = fnutils.copy(mod.watchFolders())
		for i, v in pairs(watchFolders) do
			if i == string.sub(file, 1, string.len(i)) then
				selectedFile = v
			end
		end

		local compressorPath = compressor:getPath()

		local filename = tools.getFilenameFromPath(file, true)

		local compressorCommand = compressorPath .. [[/Contents/MacOS/Compressor -jobpath "]] .. file .. [[" -settingpath "]] .. selectedFile.settingFile .. [[" -locationpath "]] .. selectedFile.destinationPath .. filename .. [[" ]]

		local output, status, endType = hs.execute(compressorCommand)
		if not status then
			print("compressorCommand: %s", compressorCommand)
			print("RESULT:\nOutput: %s\nStatus: %s\nendType: %s", output, status, endType)
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
function mod.watchFolderTriggered(files)
	if not mod.disableImport then
		local autoFiles = {}
		local allowedExtensions = compressor.ALLOWED_IMPORT_ALL_EXTENSIONS
		for _,file in pairs(files) do
			if ((fnutils.contains(allowedExtensions, file:sub(-3)) or fnutils.contains(allowedExtensions, file:sub(-4)))) and tools.doesFileExist(file) then
				autoFiles[#autoFiles + 1] = file
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
		:addContent(14, [[<div id="]] .. watchFolderTableID .. [[">]] .. mod.generateTable() .. [[</div>]], true)
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