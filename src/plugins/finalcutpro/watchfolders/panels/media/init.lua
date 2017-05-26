--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           F I N A L    C U T    P R O   W A T C H   F O L D E R S          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.watchfolders.panels.media ===
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

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local just				= require("cp.just")
local config			= require("cp.config")
local tools				= require("cp.tools")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.watchfolders.panels.media.filesInTransit
--- Variable
--- Files currently being copied
mod.filesInTransit = {}

--- plugins.finalcutpro.watchfolders.panels.media.watchFolderTableID
--- Variable
--- Watch Folder Table ID
mod.watchFolderTableID = "fcpMediaWatchFoldersTable"

--- plugins.finalcutpro.watchfolders.panels.media.notifications
--- Variable
--- Table of Path Watchers
mod.pathwatchers = {}

--- plugins.finalcutpro.watchfolders.panels.media.notifications
--- Variable
--- Table of Notifications
mod.notifications = {}

--- plugins.finalcutpro.watchfolders.panels.media.disableImport
--- Variable
--- When `true` Notifications will no longer be triggered.
mod.disableImport = false

--- plugins.finalcutpro.watchfolders.panels.media.automaticallyImport
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.automaticallyImport = config.prop("fcpMediaWatchFoldersAutomaticallyImport", false)

--- plugins.finalcutpro.watchfolders.panels.media.savedNotifications
--- Variable
--- Table of Notifications that are saved between restarts
mod.savedNotifications = config.prop("fcpMediaWatchFoldersSavedNotifications", {})

--- plugins.finalcutpro.watchfolders.panels.media.insertIntoTimeline
--- Variable
--- Boolean that sets whether or not the files are automatically added to the timeline or not.
mod.insertIntoTimeline = config.prop("fcpMediaWatchFoldersInsertIntoTimeline", true)

--- plugins.finalcutpro.watchfolders.panels.media.deleteAfterImport
--- Variable
--- Boolean that sets whether or not you want to delete file after they've been imported.
mod.deleteAfterImport = config.prop("fcpMediaWatchFoldersDeleteAfterImport", false)

--- plugins.finalcutpro.watchfolders.panels.media.videoTag
--- Variable
--- String which contains the video tag.
mod.videoTag = config.prop("fcpMediaWatchFoldersVideoTag", "")

--- plugins.finalcutpro.watchfolders.panels.media.audioTag
--- Variable
--- String which contains the audio tag.
mod.audioTag = config.prop("fcpMediaWatchFoldersAudioTag", "")

--- plugins.finalcutpro.watchfolders.panels.media.imageTag
--- Variable
--- String which contains the stills tag.
mod.imageTag = config.prop("fcpMediaWatchFoldersImageTag", "")

--- plugins.finalcutpro.watchfolders.panels.media.watchFolders
--- Variable
--- Table of the users watch folders.
mod.watchFolders = config.prop("fcpMediaWatchFolders", {})

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
function mod.controllerCallback(id, params)
	if params and params.action and params.action == "remove" then
		mod.watchFolders(tools.removeFromTable(fnutils.copy(mod.watchFolders()), params.path))
		mod.removeWatcher(params.path)
		mod.refreshTable()
	elseif params and params.action and params.action == "refresh" then
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
	local watchFolders =  fnutils.copy(mod.watchFolders())

	for i, v in ipairs(watchFolders) do
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
					<td class="rowPath">Empty</td>
					<td class="rowRemove"></td>
				</tr>
		]]
	end

	local result = [[
		<table class="watchfolders">
			<thead>
				<tr>
					<th class="rowPath">Folder</th>
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

			var videoFiles = document.getElementById("videoFiles");
			if (typeof(]] .. mod.watchFolderTableID .. [[) != 'undefined' && ]] .. mod.watchFolderTableID .. [[ != null)
			{
				document.getElementById("videoFiles").value = `]] .. mod.videoTag() .. [[`;
			}

			var audioFiles = document.getElementById("audioFiles");
			if (typeof(]] .. mod.watchFolderTableID .. [[) != 'undefined' && ]] .. mod.watchFolderTableID .. [[ != null)
			{
				document.getElementById("audioFiles").value = `]] .. mod.audioTag() .. [[`;
			}

			var imageFiles = document.getElementById("imageFiles");
			if (typeof(]] .. mod.watchFolderTableID .. [[) != 'undefined' && ]] .. mod.watchFolderTableID .. [[ != null)
			{
				document.getElementById("imageFiles").value = `]] .. mod.imageTag() .. [[`;
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
			}

			.deleteNote {
				font-size: 10px;
				margin-left: 20px;
			}

		</style>
	]]
	return result
end

--- plugins.finalcutpro.watchfolders.panels.media.insertFilesIntoFinalCutPro(files) -> none
--- Function
--- Imports a file into Final Cut Pro
---
--- Parameters:
---  * file - File name
---  * tag - The notification tag
---
--- Returns:
---  * None
function mod.insertFilesIntoFinalCutPro(files)
	--------------------------------------------------------------------------------
	-- Add Tags:
	--------------------------------------------------------------------------------
	mod.disableImport = true
	for i, file in pairs(files) do
		local videoExtensions = fcp.ALLOWED_IMPORT_VIDEO_EXTENSIONS
		local audioExtensions = fcp.ALLOWED_IMPORT_AUDIO_EXTENSIONS
		local imageExtensions = fcp.ALLOWED_IMPORT_IMAGE_EXTENSIONS
		if mod.videoTag() ~= "" then
			if (fnutils.contains(videoExtensions, file:sub(-3)) or fnutils.contains(videoExtensions, file:sub(-4))) and tools.doesFileExist(file) then
				fs.tagsAdd(file, {mod.videoTag()})
			end
		end
		if mod.audioTag() ~= "" then
			if (fnutils.contains(audioExtensions, file:sub(-3)) or fnutils.contains(audioExtensions, file:sub(-4))) and tools.doesFileExist(file) then
				fs.tagsAdd(file, {mod.audioTag()})
			end
		end
		if mod.imageTag() ~= "" then
			if (fnutils.contains(imageExtensions, file:sub(-3)) or fnutils.contains(imageExtensions, file:sub(-4))) and tools.doesFileExist(file) then
				fs.tagsAdd(file, {mod.imageTag()})
			end
		end
	end
	timer.doAfter(1, function()
		mod.disableImport = false
	end)

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
	local objects = {}
	for i, v in pairs(files) do
		objects[#objects + 1] = { url = "file://" .. http.encodeForQuery(v) }
	end
	local result = pasteboard.writeObjects(objects)
	if not result then
		dialog.displayErrorMessage("The URL could not be written to the Pasteboard. Error occured in Final Cut Pro Media Watch Folder.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Check if Timeline can be enabled:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled({"Window", "Go To", "Timeline"})
	if result then
		local result = fcp:selectMenu({"Window", "Go To", "Timeline"})
	else
		dialog.displayErrorMessage("Failed to activate timeline. Error occured in Final Cut Pro Media Watch Folder.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Perform Paste:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled({"Edit", "Paste as Connected Clip"})
	if result then
		local result = fcp:selectMenu({"Edit", "Paste as Connected Clip"})
	else
		dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut. Error occured in Final Cut Pro Media Watch Folder.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Remove from Timeline if appropriate:
	--------------------------------------------------------------------------------
	if not mod.insertIntoTimeline() then
		fcp:performShortcut("UndoChanges")
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
	-- Delete After Import:
	--------------------------------------------------------------------------------
	if mod.deleteAfterImport() then
		for _, file in pairs(files) do
			timer.doAfter(5, function()
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
function mod.importFile(file, tag)

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
		for i, v in pairs(mod.notifications) do
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
	local savedNotifications = fnutils.copy(mod.savedNotifications())
	if importAll then
		for i, v in pairs(mod.notifications) do
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
	mod.notifications[file] = notify.new(function(obj) mod.importFile(file, obj:getFunctionTag()) end)
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
	local savedNotifications = fnutils.copy(mod.savedNotifications())
	savedNotifications[file] = notificationTag
	mod.savedNotifications(savedNotifications)
end

--- plugins.finalcutpro.watchfolders.panels.media.watchFolderTriggered(files) -> none
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
		for i,file in pairs(files) do

			--------------------------------------------------------------------------------
			-- File deleted or removed from Watch Folder:
			--------------------------------------------------------------------------------
			if eventFlags[i] and eventFlags[i]["itemRenamed"] and eventFlags[i]["itemIsFile"] and not tools.doesFileExist(file) then
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
					end
					newFile = true
				end

				--------------------------------------------------------------------------------
				-- New File Moved into Watch Folder:
				--------------------------------------------------------------------------------
				local movedFile = false
				if eventFlags[i]["itemRenamed"] and eventFlags[i]["itemIsFile"] then
					--log.df("File Moved or Renamed: %s", file)
					movedFile = true
				end

				--------------------------------------------------------------------------------
				-- Check Extensions:
				--------------------------------------------------------------------------------
				local allowedExtensions = fcp.ALLOWED_IMPORT_ALL_EXTENSIONS
				if (fnutils.contains(allowedExtensions, file:sub(-3)) or fnutils.contains(allowedExtensions, file:sub(-4))) and tools.doesFileExist(file) then
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

		local watchFolders = fnutils.copy(mod.watchFolders())

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
	local watchFolders = fnutils.copy(mod.watchFolders())
	for i, v in ipairs(watchFolders) do
		mod.newWatcher(v)
	end

	--------------------------------------------------------------------------------
	-- Re-create any Un-clicked Notifications from Previous Session:
	--------------------------------------------------------------------------------
	local savedNotifications = fnutils.copy(mod.savedNotifications())
	for file,tag in pairs(savedNotifications) do
		if tools.doesFileExist(file) then
			mod.createNotification(file)
		else
			savedNotifications[file] = nil
			mod.savedNotifications(savedNotifications)
		end
	end

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
function mod.init(deps, env)

	--------------------------------------------------------------------------------
	-- Ignore Panel if Final Cut Pro isn't installed.
	--------------------------------------------------------------------------------
	if not fcp:isInstalled() then
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
			priority 		= 2010,
			id				= "media",
			label			= i18n("media"),
			image			= image.imageFromPath(fcp:getPath() .. "/Contents/Resources/Final Cut.icns"),
			tooltip			= i18n("watchFolderFCPMediaTooltip"),
			height			= 650,
			loadFn			= mod.refreshTable,
		})

	--------------------------------------------------------------------------------
	-- Setup Panel Contents:
	--------------------------------------------------------------------------------
	mod.panel
		:addContent(1, mod.styleSheet(), true)
		:addHeading(10, i18n("description"))
		:addParagraph(11, i18n("watchFolderFCPMediaHelp"), true)
		:addParagraph(12, "")
		:addHeading(13, i18n("watchFolders"), 3)
		:addContent(14, [[<div id="]] .. mod.watchFolderTableID .. [[">]] .. mod.generateTable() .. [[</div>]], true)
		:addButton(15,
			{
				label		= i18n("addWatchFolder"),
				onclick		= mod.addWatchFolder,
				class		= "btnAddWatchFolder",
			})
		:addParagraph(16, "")
		:addHeading(17, i18n("options"), 3)
		:addCheckbox(18,
			{
				label		= i18n("importToTimeline"),
				checked		= mod.insertIntoTimeline,
				onchange	= function(id, params) mod.insertIntoTimeline(params.checked) end,
			}
		)
		:addCheckbox(19,
			{
				label		= i18n("automaticallyImport"),
				checked		= mod.automaticallyImport,
				onchange	= function(id, params) mod.automaticallyImport(params.checked) end,
			}
		)
		:addCheckbox(20,
			{
				label		= i18n("deleteAfterImport"),
				checked		= mod.deleteAfterImport,
				onchange	= function(id, params) mod.deleteAfterImport(params.checked) end,
			}
		)
		:addParagraph(21, i18n("deleteNote"), true, "deleteNote")
		:addParagraph(22, "")
		:addHeading(23, i18n("addFinderTagsOnImport"), 3)
		:addTextbox(24,
			{
				id			= "videoFiles",
				label		= "Video Files:",
				class		= "watchFolderTextBox",
				value		= mod.videoTag(),
				onchange	= function(id, params) mod.videoTag(params.value) end,
				placeholder = i18n("enterVideoTag"),
			})
		:addTextbox(25,
			{
				id			= "audioFiles",
				label		= "Audio Files:",
				class		= "watchFolderTextBox",
				value		= mod.audioTag(),
				onchange	= function(id, params) mod.audioTag(params.value) end,
				placeholder = i18n("enterAudioTag"),
			})
		:addTextbox(26,
			{
				id			= "imageFiles",
				label		= "Image Files:",
				class		= "watchFolderTextBox",
				value 		= mod.imageTag(),
				onchange	= function(id, params) mod.imageTag(params.value) end,
				placeholder = i18n("enterImageTag"),
			})
		--------------------------------------------------------------------------------
		-- NOTE: Yes (David), this would be better with CSS, but "focus" doesn't seem
		-- to work in a webview for some reason?
		--------------------------------------------------------------------------------
		local uniqueUUID = string.gsub(uuid(), "-", "")
		mod.manager.addHandler(uniqueUUID, mod.controllerCallback)
		mod.panel:addContent(27, [[
			<script>
				try {
					document.getElementById("videoFiles").onfocus = function() { document.getElementById("videoFiles").style.border = "2px solid #97c4f2"; };
					document.getElementById("videoFiles").onblur = function() { document.getElementById("videoFiles").style.border = ""; };

					document.getElementById("audioFiles").onfocus = function() { document.getElementById("audioFiles").style.border = "2px solid #97c4f2"; };
					document.getElementById("audioFiles").onblur = function() { document.getElementById("audioFiles").style.border = ""; };

					document.getElementById("imageFiles").onfocus = function() { document.getElementById("imageFiles").style.border = "2px solid #97c4f2"; };
					document.getElementById("imageFiles").onblur = function() { document.getElementById("imageFiles").style.border = ""; };
				}
				catch(err) {
					alert("Tags Highlighter Error");
				}
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
	id = "finalcutpro.watchfolders.panels.media",
	group = "finalcutpro",
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