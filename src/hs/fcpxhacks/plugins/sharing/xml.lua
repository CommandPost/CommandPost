-- Imports
local settings									= require("hs.settings")
local tools										= require("hs.fcpxhacks.modules.tools")
local pathwatcher								= require("hs.pathwatcher")
local notify									= require("hs.notify")
local image										= require("hs.image")
local metadata									= require("hs.fcpxhacks.metadata")
local fs										= require("hs.fs")
local fcp										= require("hs.finalcutpro")

-- Constants

local PRIORITY = 1000

-- The module
local mod = {}

function mod.isEnabled()
	return settings.get("fcpxHacks.enableXMLSharing") or false
end

function mod.setEnabled(value)
	settings.set("fcpxHacks.enableXMLSharing", value)
end

function mod.getSharingPath()
	return settings.get("fcpxHacks.xmlSharingPath")
end

function mod.setSharingPath(value)
	settings.set("fcpxHacks.xmlSharingPath", value)
end

--------------------------------------------------------------------------------
-- SHARED XML FILE WATCHER:
--------------------------------------------------------------------------------
local function sharedXMLFileWatcher(files)
	debugMessage("Refreshing Shared XML Folder.")

	for _,file in ipairs(files) do
        if file:sub(-7) == ".fcpxml" then
			local testFile = io.open(file, "r")
			if testFile ~= nil then
				testFile:close()

				local editorName = string.reverse(string.sub(string.reverse(file), string.find(string.reverse(file), "/", 1) + 1, string.find(string.reverse(file), "/", string.find(string.reverse(file), "/", 1) + 1) - 1))

				if host.localizedName() ~= editorName then

					local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")
					sharedXMLNotification = notify.new(function() fcp:importXML(file) end)
						:setIdImage(image.imageFromPath(metadata.iconPath))
						:title("New XML Received")
						:subTitle(file:sub(string.len(xmlSharingPath) + 1 + string.len(editorName) + 1, -8))
						:informativeText(metadata.scriptName .. " has received a new XML file.")
						:hasActionButton(true)
						:actionButtonTitle("Import XML")
						:send()

				end
			end
        end
    end
end


--------------------------------------------------------------------------------
-- TOGGLE XML SHARING:
--------------------------------------------------------------------------------
function mod.toggleEnabled()

	local enableXMLSharing = mod.isEnabled()

	if not enableXMLSharing then

		local xmlSharingPath = dialog.displayChooseFolder("Which folder would you like to use for XML Sharing?")

		if xmlSharingPath ~= false then
			mod.setSharingPath(xmlSharingPath)
		else
			mod.setSharingPath(nil)
			return "Cancelled"
		end

		--------------------------------------------------------------------------------
		-- Watch for Shared XML Folder Changes:
		--------------------------------------------------------------------------------
		mod.sharedXMLWatcher = pathwatcher.new(xmlSharingPath, sharedXMLFileWatcher):start()

	else
		--------------------------------------------------------------------------------
		-- Stop Watchers:
		--------------------------------------------------------------------------------
		mod.sharedXMLWatcher:stop()

		--------------------------------------------------------------------------------
		-- Clear Settings:
		--------------------------------------------------------------------------------
		mod.setSharingPath(nil)
	end

	mod.setEnabled(not enableXMLSharing)
end


function mod.init()
	--------------------------------------------------------------------------------
	-- Watch for Shared XML Changes:
	--------------------------------------------------------------------------------
	local enableXMLSharing = mod.isEnabled()
	if enableXMLSharing then
		local xmlSharingPath = mod.getSharingPath()
		if xmlSharingPath ~= nil then
			if tools.doesDirectoryExist(xmlSharingPath) then
				sharedXMLWatcher = pathwatcher.new(xmlSharingPath, sharedXMLFileWatcher):start()
			else
				writeToConsole("The Shared XML Folder(s) could not be found, so disabling.")
				mod.setSharingPath(nil)
				mod.setEnabled(false)
			end
		end
	end
end


--------------------------------------------------------------------------------
-- CLEAR SHARED XML FILES:
--------------------------------------------------------------------------------
function mod.clearSharedFiles()
	local xmlSharingPath = mod.getSharingPath()
	for folder in fs.dir(xmlSharingPath) do
		if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then
			for file in fs.dir(xmlSharingPath .. "/" .. folder) do
				if file:sub(-7) == ".fcpxml" then
					os.remove(xmlSharingPath .. folder .. "/" .. file)
				end
			end
		end
	end
end


function mod.listFilesMenu()
	--------------------------------------------------------------------------------
	-- Shared XML Menu:
	--------------------------------------------------------------------------------
	local settingsSharedXMLTable = {}
	if mod.isEnabled() then

		--------------------------------------------------------------------------------
		-- Get list of files:
		--------------------------------------------------------------------------------
		local sharedXMLFiles = {}

		local emptySharedXMLFiles = true
		local xmlSharingPath = mod.getSharingPath()
		
		local fcpxRunning = fcp:isRunning()

		for folder in fs.dir(xmlSharingPath) do

			if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then

				submenu = {}
				for file in fs.dir(xmlSharingPath .. "/" .. folder) do
					if file:sub(-7) == ".fcpxml" then
						emptySharedXMLFiles = false
						local xmlPath = xmlSharingPath .. folder .. "/" .. file
						table.insert(submenu, {title = file:sub(1, -8), fn = function() fcp:importXML(xmlPath) end, disabled = not fcpxRunning})
					end
				end

				if next(submenu) ~= nil then
					table.insert(settingsSharedXMLTable, {title = folder, menu = submenu})
				end

			end

		end

		if emptySharedXMLFiles then
			--------------------------------------------------------------------------------
			-- Nothing in the Shared Clipboard:
			--------------------------------------------------------------------------------
			table.insert(settingsSharedXMLTable, { title = "Empty", disabled = true })
		else
			--------------------------------------------------------------------------------
			-- Something in the Shared Clipboard:
			--------------------------------------------------------------------------------
			table.insert(settingsSharedXMLTable, { title = "-" })
			table.insert(settingsSharedXMLTable, { title = "Clear Shared XML Files", fn = mod.clearSharedFiles })
		end
	else
		--------------------------------------------------------------------------------
		-- Shared Clipboard Disabled:
		--------------------------------------------------------------------------------
		table.insert(settingsSharedXMLTable, { title = "Disabled in Settings", disabled = true })
	end
	return settingsSharedXMLTable	
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.tools"]			= "tools",
	["hs.fcpxhacks.plugins.menu.tools.options"]	= "options",
}

function plugin.init(deps)
	-- Tools Menus
	deps.tools:addMenu(PRIORITY, function() return i18n("importSharedXMLFile") end)
		:addItems(1, mod.listFilesMenu)
		
	-- Tools Options
	deps.options:addItem(5000, function()
		return { title = i18n("enableXMLSharing"),	fn = mod.toggleEnable,	checked = mod.isEnabled()}
	end)
	
	return mod
end

return plugin