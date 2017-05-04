--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           F I N A L    C U T    P R O   W A T C H   F O L D E R S          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.watchfolders.panels.finalcutpro ===
---
--- Final Cut Pro Watch Folder Panel.

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

mod.pathwatchers = {}
mod.notifications = {}

mod.allowedExtensions = fcp.ALLOWED_IMPORT_EXTENSIONS

--- plugins.finalcutpro.watchfolders.panels.finalcutpro.insertIntoTimeline
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.insertIntoTimeline = config.prop("fcpWatchFoldersInsertIntoTimeline", true)

--- plugins.finalcutpro.watchfolders.panels.finalcutpro.watchFolders
--- Variable
--- Table of the users watch folders.
mod.watchFolders = config.prop("fcpWatchFolders", {})

-- controllerCallback(id, params) -> none
-- Function
-- Callback Controller
--
-- Parameters:
--  * id - ID as string
--  * params - table of Parameters
--
-- Returns:
--  * None
local function controllerCallback(id, params)
	if params and params.action and params.action == "remove" then
		--log.df("Remove: %s", params.path)
		mod.watchFolders(removeFromTable(fnutils.copy(mod.watchFolders()), params.path))
		removeWatcher(params.path)
		refreshTable()
		--log.df("mod.watchFolders(): %s", hs.inspect(mod.watchFolders()))
	else
		--log.df("id, params: %s, %s", id, params)
	end
end

--------------------------------------------------------------------------------
-- GENERATE TABLE
--------------------------------------------------------------------------------
function generateTable()

	local watchFoldersHTML = ""
	local watchFolders =  fnutils.copy(mod.watchFolders())

	for i, v in ipairs(watchFolders) do
		local uniqueUUID = string.gsub(uuid(), "-", "")
		watchFoldersHTML = watchFoldersHTML .. [[
				<tr>
					<td class="rowPath">]] .. v .. [[</td>
					<td class="rowRemove"><a onclick="remove]] .. uniqueUUID .. [[()" href="#">Remove</a></td>
				</tr>
				<script>
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
				</script>
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
		mod.manager.addHandler(uniqueUUID, controllerCallback)
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
		</style>
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

function refreshTable()
	mod.manager.injectScript([[document.getElementById("watchFolderTable").innerHTML = `]] .. generateTable() .. [[`]])
end

function tableContains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
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
	for _, value in pairs(table) do
		if value ~= element then
			result[#result + 1] = value
		end
	end
	return result
end

-- addWatchFolder() -> none
-- Function
-- Opens the "Add Watch Folder" Dialog.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function addWatchFolder()
	local path = dialog.displayChooseFolder(i18n("selectFolderToWatch"))
	if path then

		local watchFolders = fnutils.copy(mod.watchFolders())

		if tableContains(watchFolders, path) then
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
		refreshTable()

		--------------------------------------------------------------------------------
		-- Setup New Watcher:
		--------------------------------------------------------------------------------
		newWatcher(path)

	end
	--log.df("mod.watchFolders(): %s", hs.inspect(mod.watchFolders()))
end

function importFile(file, obj)

	--------------------------------------------------------------------------------
	-- Check to see if Final Cut Pro is running:
	--------------------------------------------------------------------------------
	if not fcp:isRunning() then
		dialog.displayMessage(i18n("finalCutProNotRunning"))
		obj:send()
		return
	end

	local importAll = false
	local files = {}

	local modifiers = eventtap.checkKeyboardModifiers()
	if modifiers["shift"] then
		--log.df("Import All")
		importAll = true
		for i, v in pairs(mod.notifications) do
			files[#files + 1] = i
		end
	else
		files = {file}
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
	local objects = {}
	for i, v in pairs(files) do
		objects[#objects + 1] = { url = "file://" .. http.encodeForQuery(v) }
	end
	local result = pasteboard.writeObjects(objects)
	if not result then
		dialog.displayErrorMessage("The URL could not be written to the Pasteboard.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Check if Timeline can be enabled:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled("Window", "Go To", "Timeline")
	if result then
		local result = fcp:selectMenu("Window", "Go To", "Timeline")
	else
		dialog.displayErrorMessage("Failed to activate timeline in Text to Speech Plugin.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Perform Paste:
	--------------------------------------------------------------------------------
	local result = fcp:menuBar():isEnabled("Edit", "Paste as Connected Clip")
	if result then
		local result = fcp:selectMenu("Edit", "Paste as Connected Clip")
	else
		dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut in the Text to Speech Plugin.")
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
	-- Release the notification:
	--------------------------------------------------------------------------------
	if importAll then
		for i, v in pairs(mod.notifications) do
			mod.notifications[i]:withdraw()
			mod.notifications[i] = nil
		end
	else
		mod.notifications[file] = nil
	end

end

function createNotification(file)
	mod.notifications[file] = notify.new(function(obj) importFile(file, obj) end)
		:title(i18n("newFileForFinalCutPro"))
		:subTitle(tools.getFilenameFromPath(file))
		:hasActionButton(true)
		:actionButtonTitle(i18n("import"))
		:otherButtonTitle(i18n("ignore"))
		:send()
end

function watchFolderTriggered(files)
    for _,file in pairs(files) do
    	if (fnutils.contains(mod.allowedExtensions, file:sub(-3)) or fnutils.contains(mod.allowedExtensions, file:sub(-4))) and tools.doesFileExist(file) then
            createNotification(file)
        end
    end
end

function newWatcher(path)
	--log.df("New Watcher: %s", path)
	mod.pathwatchers[path] = pathwatcher.new(path, watchFolderTriggered):start()
end

function removeWatcher(path)
	--log.df("Removing Watcher: %s", path)
	mod.pathwatchers[path]:stop()
	mod.pathwatchers[path] = nil
end

function setupWatchers()
	local watchFolders = fnutils.copy(mod.watchFolders())
	for i, v in ipairs(watchFolders) do
		newWatcher(v)
	end
end

--- plugins.finalcutpro.watchfolders.panels.finalcutpro.init(deps, env) -> table
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

	if not fcp:isInstalled() then
		return nil
	end

	--------------------------------------------------------------------------------
	-- Define Plugins:
	--------------------------------------------------------------------------------
	mod.clipboardManager = deps.clipboardManager
	mod.manager = deps.manager

	mod.panel = deps.manager.addPanel({
			priority 	= 2040,
			id			= "finalcutpro",
			label		= i18n("finalCutProPanelLabel"),
			image		= image.imageFromPath(fcp:getPath() .. "/Contents/Resources/Final Cut.icns"),
			tooltip		= i18n("finalCutProPanelTooltip"),
			height		= 465,
		})

	mod.panel
		:addHeading(10, i18n("description"))
		:addParagraph(11, i18n("watchFolderHelp"), true)
		:addParagraph(12, "")
		:addHeading(13, i18n("watchFolders"), 3)
		:addContent(14, [[<div id="watchFolderTable">]] .. generateTable() .. [[</div>]], true)
		:addButton(15,
			{
				label		= i18n("addWatchFolder"),
				onclick		= addWatchFolder,
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
	setupWatchers()

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.watchfolders.panels.finalcutpro",
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