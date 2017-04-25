--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             S H A R E D    C L I P B O A R D    P L U G I N                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.clipboard.shared ===
---
--- Shared Clipboard Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("sharedClipboard")

local host										= require("hs.host")
local json										= require("hs.json")
local base64									= require("hs.base64")
local fs										= require("hs.fs")

local fcp										= require("cp.apple.finalcutpro")
local dialog									= require("cp.dialog")
local plist										= require("cp.plist")
local config									= require("cp.config")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local TOOLS_PRIORITY		= 2000
local OPTIONS_PRIORITY		= 2000

local HISTORY_EXTENSION		= ".sharedClipboard"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod._hostname				= host.localizedName()					-- Hostname
mod.maxHistory				= 5
mod.log						= log

--------------------------------------------------------------------------------
-- IS ENABLED:
--------------------------------------------------------------------------------
mod.isEnabled = config.is("enabledShardClipboard", false)

--------------------------------------------------------------------------------
-- GET ROOT PATH:
--------------------------------------------------------------------------------
function mod.getRootPath()
	return config.get("sharedClipboardPath", nil)
end

--------------------------------------------------------------------------------
-- SET ROOT PATH:
--------------------------------------------------------------------------------
function mod.setRootPath(path)
	config.set("sharedClipboardPath", path)
end

--------------------------------------------------------------------------------
-- VALID ROOT PATH:
--------------------------------------------------------------------------------
function mod.validRootPath()
	return tools.doesDirectoryExist(mod.getRootPath())
end

--------------------------------------------------------------------------------
-- WATCHER ACTION:
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- UPDATE:
--------------------------------------------------------------------------------
function mod.update()
	if mod.isEnabled() then
		if not mod.validRootPath() then
			-- Assign a new root path:
			local result = dialog.displayChooseFolder(i18n("sharedClipboardRootFolder"))
			if result then
				mod.setRootPath(result)
			else
				mod.isEnabled(false)
			end
		end
		if mod.validRootPath() and not mod._watcherId then
			mod._watcherId = mod._manager.watch({
				update	= watchUpdate,
			})
		end
	end
	if not mod.isEnabled() then
		if mod._watcherId then
			mod._manager.unwatch(mod._watcherId)
			mod._watcherId = nil
		end
		mod.setRootPath(nil)
	end
end

--------------------------------------------------------------------------------
-- RETURNS THE LIST OF FOLDER NAMES AS AN ARRAY OF STRINGS:
--------------------------------------------------------------------------------
function mod.getFolderNames()
	local folders = {}
	local rootPath = mod.getRootPath()
	if rootPath then
		local path = fs.pathToAbsolute(rootPath)
		if path then
			local contents, data = fs.dir(path)

			for file in function() return contents(data) end do
				local name = file:match("(.+)%"..HISTORY_EXTENSION.."$")
				if name then
					folders[#folders+1] = name
				end
			end
			table.sort(folders, function(a, b) return a < b end)
		end
	end
	return folders
end

--------------------------------------------------------------------------------
-- GET LOCAL FOLDER NAME:
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- GET HISTORY PATH:
--------------------------------------------------------------------------------
function mod.getHistoryPath(folderName, fileExtension)
	fileExtension = fileExtension or HISTORY_EXTENSION
	return mod.getRootPath() .. folderName .. fileExtension
end

--------------------------------------------------------------------------------
-- GET HISTORY:
--------------------------------------------------------------------------------
function mod.getHistory(folderName)
	local history = {}

	local filePath = mod.getHistoryPath(folderName)
	local file = io.open(filePath, "r")
	if file then
		local content = file:read("*all")
		file:close()
		history = json.decode(content)
	end
	return history
end

--------------------------------------------------------------------------------
-- SET HISTORY:
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- CLEAR HISTORY:
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- PASTE HISTORY ITEM:
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init(manager)
	mod._manager = manager

	local setEnabledValue = false
	if mod.isEnabled() then
		if not mod.validRootPath() then
			local result = dialog.displayMessage(i18n("sharedClipboardPathMissing"), {"Yes", "No"})
			if result == "Yes" then
				setEnabledValue = true
			end
		else
			setEnabledValue = true
		end
	end

	mod.isEnabled(setEnabledValue)
	mod.isEnabled:watch(mod.update)

	return self
end

--------------------------------------------------------------------------------
-- GET SHARED CLIPBOARD MENU:
--------------------------------------------------------------------------------
function mod.generateSharedClipboardMenu()
	local folderItems = {}
	if mod.isEnabled() and mod.validRootPath() then
		local fcpxRunning = fcp:isRunning()

		local sharedClipboardFolderModified = fs.attributes(mod.getRootPath(), "modification")
		local folderNames = nil
		if sharedClipboardFolderModified ~= mod._sharedClipboardFolderModified or mod._folderNames == nil then
			folderNames = mod.getFolderNames()
			mod._folderNames = folderNames
			mod._sharedClipboardFolderModified = sharedClipboardFolderModified
			--log.df("Creating Folder Names Cache")
		else
			folderNames = mod._folderNames
			--log.df("Using Folder Names Cache")
		end

		if #folderNames > 0 then
			for _,folder in ipairs(folderNames) do
				local historyItems = {}

				local history = nil
				local historyFolderModified = fs.attributes(mod.getHistoryPath(folder), "modification")

				if mod._historyFolderModified == nil or mod._historyFolderModified[folder] == nil or historyFolderModified ~= mod._historyFolderModified[folder] or mod._history == nil or mod._history[folder] == nil then
					history = mod.getHistory(folder)
					if mod._history == nil then mod._history = {} end
					mod._history[folder] = history
					if mod._historyFolderModified == nil then mod._historyFolderModified = {} end
					mod._historyFolderModified[folder] = historyFolderModified
					--log.df("Creating History Cache for " .. folder)
				else
					history = mod._history[folder]
					--log.df("Using History Cache for " .. folder)
				end

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
	end
	return folderItems
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.clipboard.shared",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.clipboard.manager"]	= "manager",
		["finalcutpro.commands"]			= "fcpxCmds",
		["finalcutpro.menu.clipboard"]		= "menu",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Initialise Module:
	--------------------------------------------------------------------------------
	mod.init(deps.manager)

	--------------------------------------------------------------------------------
	-- Generate Menu Cache:
	--------------------------------------------------------------------------------
	mod.generateSharedClipboardMenu()

	--------------------------------------------------------------------------------
	-- Add menu items:
	--------------------------------------------------------------------------------
	local menu = deps.menu:addMenu(TOOLS_PRIORITY, function() return i18n("sharedClipboardHistory") end)

	:addItem(1000, function()
		return { title = i18n("enableSharedClipboard"),	fn = function() mod.isEnabled:toggle() end, checked = mod.isEnabled() and mod.validRootPath() }
	end)

	:addSeparator(2000)

	:addItems(3000, mod.generateSharedClipboardMenu)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpCopyWithCustomLabelAndFolder")
		:whenActivated(mod.copyWithCustomClipNameAndFolder)

	return mod
end

return plugin