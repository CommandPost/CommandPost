-- Imports
local settings									= require("hs.settings")
local host										= require("hs.host")
local json										= require("hs.json")
local base64									= require("hs.base64")
local fs										= require("hs.fs")

local fcp										= require("cp.finalcutpro")
local dialog									= require("cp.dialog")
local plist										= require("cp.plist")
local metadata									= require("cp.metadata")
local tools										= require("cp.tools")

local log										= require("hs.logger").new("sharedClipboard")

-- Constants
local TOOLS_PRIORITY		= 2000
local OPTIONS_PRIORITY		= 2000

local HISTORY_EXTENSION		= ".sharedClipboard"
local LEGACY_EXTENSION		= ".fcpxhacks"

-- The Module
local mod = {}

mod._hostname				= host.localizedName()					-- Hostname
mod.maxHistory				= 5
mod.log						= log

function mod.isEnabled()
	return settings.get(metadata.settingsPrefix .. ".enableSharedClipboard") or false
end

function mod.setEnabled(value)
	settings.set(metadata.settingsPrefix .. ".enableSharedClipboard", value)
	mod.update()
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

function mod.getRootPath()
	return settings.get(metadata.settingsPrefix .. ".sharedClipboardPath")
end

function mod.setRootPath(path)
	settings.set(metadata.settingsPrefix .. ".sharedClipboardPath", path)
end

local function watchUpdate(data, name)
	log.df("Clipboard updated. Adding '%s' to shared history.", name)

	local sharedClipboardPath = mod.getRootPath()
	if sharedClipboardPath ~= nil then

		local folderName = nil
		if mod._overrideFolder ~= nil then
			folderName = mod._overrideFolder
			mod._overrideFolder = nil
		else
			folderName = mod.getLocalFolderName()
		end

		-- First, read the existing history
		local history = mod.getHistory(folderName) or {}

		-- Drop old history items
		while (#history >= mod.maxHistory) do
			table.remove(history, 1)
		end

		-- Add the new item
		local item = {
			name = name,
			data = base64.encode(data),
		}
		table.insert(history, item)

		-- Save the updated history
		mod.setHistory(folderName, history)
	end
end

function mod.update()
	if mod.isEnabled() then
		if mod.getRootPath() == nil then
			-- Assign a new root path
			local result = dialog.displayChooseFolder(i18n("sharedClipboardRootFolder"))
			if result then
				mod.setRootPath(result)
			end
		end

		if mod.getRootPath() ~= nil and not mod._watcherId then
			mod._watcherId = mod._manager.watch({
				update	= watchUpdate,
			})
		end
	else
		if mod._watcherId then
			mod._manager.unwatch(mod._watcherId)
			mod._watcherId = nil
		end
		mod.setRootPath(nil)
	end
end

-- Returns the list of folder names as an array of strings.
function mod.getFolderNames()
	local folders = {}

	local rootPath = mod.getRootPath()
	if rootPath then
		local path = fs.pathToAbsolute(rootPath)
		local contents, data = fs.dir(path)

		for file in function() return contents(data) end do
			local name = file:match("(.+)%"..HISTORY_EXTENSION.."$")
			if not name then
				name = file:match("(.+)%"..LEGACY_EXTENSION.."$")
			end
			if name then
				folders[#folders+1] = name
			end
		end
		table.sort(folders, function(a, b) return a < b end)
	end
	return folders
end

function mod.getLocalFolderName()
	return mod._hostname
end

--------------------------------------------------------------------------------
-- OVERRIDE FOLDER NAME:
--------------------------------------------------------------------------------
-- Overrides the folder name for the next clip which is copied from FCPX to the
-- specified value. Once the override has been used, the standard folder name via
-- `mod.getLocalFolderName()` will be used for subsequent copy operations.
--------------------------------------------------------------------------------
function mod.overrideNextFolderName(overrideFolder)
	mod._overrideFolder = overrideFolder
end

--------------------------------------------------------------------------------
-- COPY WITH CUSTOM LABEL:
--------------------------------------------------------------------------------
function mod.copyWithCustomClipName()
	local menuBar = fcp:menuBar()
	if menuBar:isEnabled("Edit", "Copy") then
		local result = dialog.displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
		if result == false then return end
		mod.overrideNextClipName(result)
		menuBar:selectMenu("Edit", "Copy")
	end
end

local function migrateLegacyHistory(folderName)
	local filePath = mod.getHistoryPath(folderName, LEGACY_EXTENSION)
	if not fs.attributes(filePath) then
		-- The legacy file doesn't exist.
		return {}
	end

	local plistData = plist.xmlFileToTable(filePath)

	local history = {}

	if plistData then
		-- convert it to the new history format
		for i = 1,5 do
			local item = {
				name = plistData["SharedClipboardLabel"..i],
				data = plistData["SharedClipboardData"..i],
			}
			if item.name ~= "" and item.data ~= "" then
				history[#history + 1] = item
			end
		end

		-- save it to the new format
		if mod.setHistory(folderName, history) then
			-- and erase the old file
			os.remove(filePath)
		end
	end

	return history
end

function mod.getHistoryPath(folderName, fileExtension)
	fileExtension = fileExtension or HISTORY_EXTENSION
	return mod.getRootPath() .. folderName .. fileExtension
end

function mod.getHistory(folderName)
	local history = {}

	local filePath = mod.getHistoryPath(folderName)
	local file = io.open(filePath, "r")
	if file then
		local content = file:read("*all")
		file:close()
		history = json.decode(content)
	else
		-- Try migrating a legacy history file, if present
		history = migrateLegacyHistory(folderName)
	end
	return history
end

function mod.setHistory(folderName, history)
	local filePath = mod.getHistoryPath(folderName)
	if history and #history > 0 then
		file = io.open(filePath, "w")
		if file then
			file:write(json.encode(history))
			file:close()
			return true
		end
	else
		-- Remove it
		os.remove(filePath)
	end
	return false
end

function mod.clearHistory(folderName)
	mod.setHistory(folderName, nil)
end

--------------------------------------------------------------------------------
-- COPY WITH CUSTOM LABEL & FOLDER:
--------------------------------------------------------------------------------
function mod.copyWithCustomClipNameAndFolder()
	local menuBar = fcp:menuBar()
	if menuBar:isEnabled("Edit", "Copy") then
		local result = dialog.displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
		if result == false then return end
		mod._manager.overrideNextClipName(result)

		local result = dialog.displayTextBoxMessage(i18n("overrideFolderNamePrompt"), i18n("overrideValueInvalid"), "")
		if result == false then return end
		mod.overrideNextFolderName(result)

		menuBar:selectMenu("Edit", "Copy")
	end
end

function mod.pasteHistoryItem(folderName, index)
	local item = mod.getHistory(folderName)[index]
	if item then
		--------------------------------------------------------------------------------
		-- Decode the data.
		--------------------------------------------------------------------------------
		local data = base64.decode(item.data)
		if not data then
			log.w("Unable to decode the item data for '%s' at %d.", folderName, index)
		end
		--------------------------------------------------------------------------------
		-- Put item back in the clipboard quietly.
		--------------------------------------------------------------------------------
		mod._manager.writeFCPXData(data, true)

		--------------------------------------------------------------------------------
		-- Paste in FCPX:
		--------------------------------------------------------------------------------
		fcp:launch()
		if fcp:performShortcut("Paste") then
			return true
		else
			log.w("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in clipboard.history.pasteHistoryItem().")
		end
	end
	return false
end

function mod.init(manager)
	mod._manager = manager
	mod.update()
	return self
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.clipboard.manager"]	= "manager",
	["cp.plugins.commands.fcpx"]		= "fcpxCmds",
	["cp.plugins.menu.tools"]			= "tools",
	["cp.plugins.menu.tools.options"]	= "options",
}

function plugin.init(deps)
	mod.init(deps.manager)

	-- Add menu items
	local menu = deps.tools:addMenu(TOOLS_PRIORITY, function() return i18n("pasteFromSharedClipboard") end)

	menu:addItems(1000, function()
		local folderItems = {}
		if mod.isEnabled() then
		local fcpxRunning = fcp:isRunning()
			local folderNames = mod.getFolderNames()
			if #folderNames > 0 then
				for _,folder in ipairs(folderNames) do
					local historyItems = {}
					local history = mod.getHistory(folder)
					if #history > 0 then
						for i=#history, 1, -1 do
							local item = history[i]
							table.insert(historyItems, {title = item.name, fn = function() mod.pasteHistoryItem(folder, i) end, disabled = not fcpxRunning})
						end
						table.insert(historyItems, { title = "-" })
						table.insert(historyItems, { title = i18n("clearSharedClipboard"), fn = function() mod.clearHistory(folder) end })
					else
						table.insert(historyItems, { title = i18n("emptySharedClipboard"), disabled = true })
					end
					table.insert(folderItems, { title = folder, menu = historyItems })
				end
			else
				table.insert(folderItems, { title = i18n("emptySharedClipboard"), disabled = true })
			end
		else
			table.insert(folderItems, { title = i18n("disabled"), disabled = true })
		end
		return folderItems
	end)

	deps.options:addItem(OPTIONS_PRIORITY, function()
		return { title = i18n("enableSharedClipboard"),	fn = mod.toggleEnabled, checked = mod.isEnabled()}
	end)

	-- Commands
	deps.fcpxCmds:add("FCPXCopyWithCustomLabelAndFolder")
		:whenActivated(mod.copyWithCustomClipNameAndFolder)

	return mod
end

return plugin