--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro ===
---
--- Represents the Final Cut Pro X application, providing functions that allow different tasks to be accomplished.

--------------------------------------------------------------------------------
--- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("finalcutpro")

local application								= require("hs.application")
local ax 										= require("hs._asm.axuielement")
local eventtap									= require("hs.eventtap")
local fs 										= require("hs.fs")
local inspect									= require("hs.inspect")
local osascript 								= require("hs.osascript")
local pathwatcher								= require("hs.pathwatcher")
local task										= require("hs.task")
local windowfilter								= require("hs.window.filter")

local plist										= require("cp.plist")
local just										= require("cp.just")
local tools										= require("cp.tools")

local axutils									= require("cp.finalcutpro.axutils")

local MenuBar									= require("cp.finalcutpro.MenuBar")
local PreferencesWindow							= require("cp.finalcutpro.prefs.PreferencesWindow")
local PrimaryWindow								= require("cp.finalcutpro.main.PrimaryWindow")
local SecondaryWindow							= require("cp.finalcutpro.main.SecondaryWindow")
local FullScreenWindow							= require("cp.finalcutpro.main.FullScreenWindow")
local Timeline									= require("cp.finalcutpro.main.Timeline")
local Browser									= require("cp.finalcutpro.main.Browser")
local Viewer									= require("cp.finalcutpro.main.Viewer")
local CommandEditor								= require("cp.finalcutpro.cmd.CommandEditor")
local ExportDialog								= require("cp.finalcutpro.export.ExportDialog")
local MediaImport								= require("cp.finalcutpro.import.MediaImport")

local kc										= require("cp.finalcutpro.keycodes")
local shortcut									= require("cp.commands.shortcut")

--------------------------------------------------------------------------------
-- APP MODULE:
--------------------------------------------------------------------------------
local App = {}

--- cp.finalcutpro.BUNDLE_ID
--- Constant
--- Final Cut Pro's Bundle ID
App.BUNDLE_ID 									= "com.apple.FinalCut"

--- cp.finalcutpro.PASTEBOARD_UTI
--- Constant
--- Final Cut Pro's Pasteboard UTI
App.PASTEBOARD_UTI 								= "com.apple.flexo.proFFPasteboardUTI"

--- cp.finalcutpro.PREFS_PLIST_PATH
--- Constant
--- Final Cut Pro's Preferences Path
App.PREFS_PLIST_PATH 							= "~/Library/Preferences/com.apple.FinalCut.plist"

--- cp.finalcutpro.SUPPORTED_LANGUAGES
--- Constant
--- Table of Final Cut Pro's supported Languages
App.SUPPORTED_LANGUAGES 						= {"de", "en", "es", "fr", "ja", "zh_CN"}

--- cp.finalcutpro.FLEXO_LANGUAGES
--- Constant
--- Table of Final Cut Pro's supported Languages for the Flexo Framework
App.FLEXO_LANGUAGES								= {"de", "en", "es_419", "es", "fr", "id", "ja", "ms", "vi", "zh_CN"}

--- doesDirectoryExist() -> boolean
--- Function
--- Returns true if Directory Exists else False
---
--- Parameters:
---  * None
---
--- Returns:
---  * True is Directory Exists otherwise False
---
local function doesDirectoryExist(path)
    local attr = fs.attributes(path)
    return attr and attr.mode == 'directory'
end

--- cp.finalcutpro:new() -> App
--- Function
--- Creates a new App instance representing Final Cut Pro
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * True is successful otherwise Nil
---
function App:new()
	o = {}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- cp.finalcutpro:application() -> hs.application
--- Function
--- Returns the hs.application for Final Cut Pro X.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * The hs.application, or nil if the application is not installed.
---
function App:application()
	local result = application.applicationsForBundleID(App.BUNDLE_ID) or nil
	-- If there is at least one copy installed, return the first one
	if result and #result > 0 then
		return result[1]
	end
	return nil
end

--- cp.finalcutpro:getBundleID() -> string
--- Function
--- Returns the Final Cut Pro Bundle ID
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * A string of the Final Cut Pro Bundle ID
---
function App:getBundleID()
	return App.BUNDLE_ID
end

--- cp.finalcutpro:getPasteboardUTI() -> string
--- Function
--- Returns the Final Cut Pro Pasteboard UTI
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * A string of the Final Cut Pro Pasteboard UTI
---
function App:getPasteboardUTI()
	return App.PASTEBOARD_UTI
end

--- cp.finalcutpro:getPasteboardUTI() -> axuielementObject
--- Function
--- Returns the Final Cut Pro axuielementObject
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * A axuielementObject of Final Cut Pro
---
function App:UI()
	return axutils.cache(self, "_ui", function()
		local fcp = self:application()
		return fcp and ax.applicationElement(fcp)
	end)
end

--- cp.finalcutpro:isRunning() -> boolean
--- Function
--- Is Final Cut Pro Running?
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro is running otherwise False
---
function App:isRunning()
	local fcpx = self:application()
	return fcpx and fcpx:isRunning()
end

--- cp.finalcutpro:launch() -> boolean
--- Function
--- Launches Final Cut Pro, or brings it to the front if it was already running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Final Cut Pro was either launched or focused, otherwise false (e.g. if Final Cut Pro doesn't exist)
---
function App:launch()

	local result = nil

	local fcpx = self:application()
	if fcpx == nil then
		-- Final Cut Pro is Closed:
		result = application.launchOrFocusByBundleID(App.BUNDLE_ID)
	else
		-- Final Cut Pro is Open:
		if not fcpx:isFrontmost() then
			-- Open by not Active:
			result = application.launchOrFocusByBundleID(App.BUNDLE_ID)
		else
			-- Already frontmost:
			return true
		end
	end

	return result
end

--- cp.finalcutpro:restart() -> boolean
--- Function
--- Restart Final Cut Pro X
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Final Cut Pro X was running and restarted successfully.
---
function App:restart()
	local app = self:application()
	if app then
		-- Kill Final Cut Pro:
		self:quit()

		-- Wait until Final Cut Pro is Closed (checking every 0.1 seconds for up to 20 seconds):
		just.doWhile(function() return self:isRunning() end, 20, 0.1)

		-- Launch Final Cut Pro:
		return self:launch()
	end
	return false
end

--- cp.finalcutpro:show() -> cp.finalcutpro object
--- Function
--- Activate Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * An cp.finalcutpro object otherwise nil
---
function App:show()
	local app = self:application()
	if app then
		if app:isHidden() then
			app:unhide()
		end
		if app:isRunning() then
			app:activate()
		end
	end
	return self
end

--- cp.finalcutpro:show() -> cp.finalcutpro object
--- Function
--- Activate Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * An cp.finalcutpro object otherwise nil
---
function App:isShowing()
	local app = self:application()
	return app ~= nil and app:isRunning() and not app:isHidden()
end

--- cp.finalcutpro:hide() -> cp.finalcutpro object
--- Function
--- Hides Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * An cp.finalcutpro object otherwise nil
---
function App:hide()
	local app = self:application()
	if app then
		app:hide()
	end
	return self
end

--- cp.finalcutpro:quit() -> cp.finalcutpro object
--- Function
--- Quits Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * An cp.finalcutpro object otherwise nil
---
function App:quit()
	local app = self:application()
	if app then
		app:kill()
	end
	return self
end

--- cp.finalcutpro:path() -> string or nil
--- Function
--- Path to Final Cut Pro Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing Final Cut Pro's filesystem path, or nil if the bundle identifier could not be located
---
function App:getPath()
	return application.pathForBundleID(App.BUNDLE_ID)
end

--- cp.finalcutpro:isInstalled() -> boolean
--- Function
--- Is Final Cut Pro X Installed?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if a version of FCPX is installed.
---
function App:isInstalled()
	local path = self:getPath()
	return doesDirectoryExist(path)
end

--- cp.finalcutpro:isFrontmost() -> boolean
--- Function
--- Is Final Cut Pro X Frontmost?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Final Cut Pro is Frontmost.
---
function App:isFrontmost()
	local fcpx = self:application()
	return fcpx and fcpx:isFrontmost()
end

--- cp.finalcutpro:getVersion() -> string or nil
--- Function
--- Version of Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * Version as string or nil if an error occurred
---
function App:getVersion()
	local version = nil
	if self:isInstalled() then
		ok,version = osascript.applescript('return version of application id "'..App.BUNDLE_ID..'"')
	end
	return version or nil
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- MENU BAR
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.finalcutpro:menuBar() -> menuBar object
--- Function
--- Returns the Final Cut Pro Menu Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * A menuBar object
---
function App:menuBar()
	if not self._menuBar then
		self._menuBar = MenuBar:new(self)
	end
	return self._menuBar
end

--- cp.finalcutpro:selectMenu(...) -> boolean
--- Function
--- Selects a Final Cut Pro Menu Item based on the list of menu titles in English.
---
--- Parameters:
---  * ... - The list of menu items you'd like to activate, for example:
---            select("View", "Browser", "as List")
---
--- Returns:
---  * `true` if the press was successful.
---
function App:selectMenu(...)
	return self:menuBar():selectMenu(...)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- WINDOWS
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.finalcutpro:preferencesWindow() -> preferenceWindow object
--- Function
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Preferences Window
---
function App:preferencesWindow()
	if not self._preferencesWindow then
		self._preferencesWindow = PreferencesWindow:new(self)
	end
	return self._preferencesWindow
end

--- cp.finalcutpro:primaryWindow() -> primaryWindow object
--- Function
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Primary Window
---
function App:primaryWindow()
	if not self._primaryWindow then
		self._primaryWindow = PrimaryWindow:new(self)
	end
	return self._primaryWindow
end

--- cp.finalcutpro:secondaryWindow() -> secondaryWindow object
--- Function
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Secondary Window
---
function App:secondaryWindow()
	if not self._secondaryWindow then
		self._secondaryWindow = SecondaryWindow:new(self)
	end
	return self._secondaryWindow
end

--- cp.finalcutpro:fullScreenWindow() -> fullScreenWindow object
--- Function
--- Returns the Final Cut Pro Full Screen Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Full Screen Playback Window
---
function App:fullScreenWindow()
	if not self._fullScreenWindow then
		self._fullScreenWindow = FullScreenWindow:new(self)
	end
	return self._fullScreenWindow
end

--- cp.finalcutpro:commandEditor() -> commandEditor object
--- Function
--- Returns the Final Cut Pro Command Editor
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Command Editor
---
function App:commandEditor()
	if not self._commandEditor then
		self._commandEditor = CommandEditor:new(self)
	end
	return self._commandEditor
end

--- cp.finalcutpro:mediaImport() -> mediaImport object
--- Function
--- Returns the Final Cut Pro Media Import Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Media Import Window
---
function App:mediaImport()
	if not self._mediaImport then
		self._mediaImport = MediaImport:new(self)
	end
	return self._mediaImport
end

--- cp.finalcutpro:exportDialog() -> exportDialog object
--- Function
--- Returns the Final Cut Pro Export Dialog Box
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Export Dialog Box
---
function App:exportDialog()
	if not self._exportDialog then
		self._exportDialog = ExportDialog:new(self)
	end
	return self._exportDialog
end

--- cp.finalcutpro:windowsUI() -> axuielement
--- Function
--- Returns the UI containing the list of windows in the app.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * The axuielement, or nil if the application is not running.
---
function App:windowsUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXWindows")
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- APP SECTIONS
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.finalcutpro:timeline() -> Timeline
--- Function
--- Returns the Timeline instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Timeline
---
function App:timeline()
	if not self._timeline then
		self._timeline = Timeline:new(self)
	end
	return self._timeline
end

--- cp.finalcutpro:viewer() -> Viewer
--- Function
--- Returns the Viewer instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Viewer
---
function App:viewer()
	if not self._viewer then
		self._viewer = Viewer:new(self, false)
	end
	return self._viewer
end

--- cp.finalcutpro:eventViewer() -> Event Viewer
--- Function
--- Returns the Event Viewer instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Event Viewer
---
function App:eventViewer()
	if not self._eventViewer then
		self._eventViewer = Viewer:new(self, true)
	end
	return self._eventViewer
end

--- cp.finalcutpro:browser() -> Browser
--- Function
--- Returns the Browser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Browser
---
function App:browser()
	if not self._browser then
		self._browser = Browser:new(self)
	end
	return self._browser
end

--- cp.finalcutpro:libraries() -> LibrariesBrowser
--- Function
--- Returns the LibrariesBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the LibrariesBrowser
---
function App:libraries()
	return self:browser():libraries()
end

--- cp.finalcutpro:media() -> MediaBrowser
--- Function
--- Returns the MediaBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the MediaBrowser
---
function App:media()
	return self:browser():media()
end

--- cp.finalcutpro:generators() -> GeneratorsBrowser
--- Function
--- Returns the GeneratorsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the GeneratorsBrowser
---
function App:generators()
	return self:browser():generators()
end

--- cp.finalcutpro:effects() -> EffectsBrowser
--- Function
--- Returns the EffectsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the EffectsBrowser
---
function App:effects()
	return self:timeline():effects()
end

--- cp.finalcutpro:transitions() -> TransitionsBrowser
--- Function
--- Returns the TransitionsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the TransitionsBrowser
---
function App:transitions()
	return self:timeline():transitions()
end

--- cp.finalcutpro:inspector() -> Inspector
--- Function
--- Returns the Inspector instance from the primary window
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Inspector
---
function App:inspector()
	return self:primaryWindow():inspector()
end

--- cp.finalcutpro:colorBoard() -> ColorBoard
--- Function
--- Returns the ColorBoard instance from the primary window
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the ColorBoard
---
function App:colorBoard()
	return self:primaryWindow():colorBoard()
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- PREFERENCES, SETTINGS, XML
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.finalcutpro:getPreferences() -> table or nil
--- Function
--- Gets Final Cut Pro's Preferences as a table. It checks if the preferences
--- file has been modified and reloads when necessary.
---
--- Parameters:
---  * forceReload	- (optional) if true, a reload will be forced even if the file hasn't been modified.
---
--- Returns:
---  * A table with all of Final Cut Pro's preferences, or nil if an error occurred
---
function App:getPreferences(forceReload)
	local modified = fs.attributes(App.PREFS_PLIST_PATH, "modification")
	if forceReload or modified ~= self._preferencesModified then
		log.d("Reloading Final Cut Pro Preferences.")

		-- See: https://macmule.com/2014/02/07/mavericks-preference-caching/
		hs.execute([[/usr/bin/python -c 'import CoreFoundation; CoreFoundation.CFPreferencesAppSynchronize("com.apple.FinalCut")']])

		self._preferences = plist.binaryFileToTable(App.PREFS_PLIST_PATH) or nil
		self._preferencesModified = modified
	 end
	return self._preferences
end

--- cp.finalcutpro.getPreference(value, default, forceReload) -> string or nil
--- Function
--- Get an individual Final Cut Pro preference
---
--- Parameters:
---  * value 			- The preference you want to return
---  * default			- (optional) The default value to return if the preference is not set.
---  * forceReload		= (optional) If true, forces a reload of the app's preferences.
---
--- Returns:
---  * A string with the preference value, or nil if an error occurred
---
function App:getPreference(value, default, forceReload)
	local result = nil
	local preferencesTable = self:getPreferences(forceReload)
	if preferencesTable then
		result = preferencesTable[value]
	end

	if result == nil then
		result = default
	end

	return result
end

--- cp.finalcutpro:setPreference(key, value) -> boolean
--- Function
--- Sets an individual Final Cut Pro preference
---
--- Parameters:
---  * key - The preference you want to change
---  * value - The value you want to set for that preference
---
--- Returns:
---  * True if executed successfully otherwise False
---
function App:setPreference(key, value)
	local executeStatus
	local preferenceType = nil

	if type(value) == "boolean" then
		value = tostring(value)
		preferenceType = "bool"
	elseif type(value) == "table" then
		local arrayString = ""
		for i=1, #value do
			arrayString = arrayString .. value[i]
			if i ~= #value then
				arrayString = arrayString .. ","
			end
		end
		value = "'" .. arrayString .. "'"
		preferenceType = "array"
	elseif type(value) == "string" then
		preferenceType = "string"
		value = "'" .. value .. "'"
	else
		return false
	end

	if preferenceType then
		local executeString = "defaults write " .. App.PREFS_PLIST_PATH .. " '" .. key .. "' -" .. preferenceType .. " " .. value
		local _, executeStatus = hs.execute(executeString)
		return executeStatus ~= nil
	end
	return false
end

--- cp.finalcutpro:importXML() -> boolean
--- Function
--- Imports an XML file into Final Cut Pro
---
--- Parameters:
---  * path = Path to XML File
---
--- Returns:
---  * A boolean value indicating whether the AppleScript succeeded or not
---
function App:importXML(path)
	if self:isRunning() then
		local appleScript = [[
			set whichSharedXMLPath to "]] .. path .. [["
			tell application "Final Cut Pro"
				activate
				open POSIX file whichSharedXMLPath as string
			end tell
		]]
		local bool, _, _ = osascript.applescript(appleScript)
		return bool
	end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- SHORTCUTS
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.finalcutpro:getActiveCommandSetPath() -> string or nil
--- Function
--- Gets the 'Active Command Set' value from the Final Cut Pro preferences
---
--- Parameters:
---  * None
---
--- Returns:
---  * The 'Active Command Set' value, or the 'Default' command set if none is set.
---
function App:getActiveCommandSetPath()
	local result = self:getPreference("Active Command Set") or nil
	if result == nil then
		-- In the unlikely scenario that this is the first time FCPX has been run:
		result = self:getDefaultCommandSetPath()
	end
	return result
end

--- cp.finalcutpro:getDefaultCommandSetPath([langauge]) -> string
--- Function
--- Gets the path to the 'Default' Command Set.
---
--- Parameters:
---  * `language`	- (optional) The language code to use. Defaults to the current FCPX language.
---
--- Returns:
---  * The 'Default' Command Set path, or `nil` if an error occurred
---
function App:getDefaultCommandSetPath(language)
	language = language or self:getCurrentLanguage()
	return self:getPath() .. "/Contents/Resources/" .. language .. ".lproj/Default.commandset"
end

--- cp.finalcutpro:getCommandSet(path) -> string
--- Function
--- Loads the Command Set at the specified path into a table.
---
--- Parameters:
---  * `path`	- The path to the command set.
---
--- Returns:
---  * The Command Set as a table, or `nil` if there was a problem.
---
function App:getCommandSet(path)
	if fs.attributes(path) ~= nil then
		return plist.fileToTable(path)
	end
end

--- cp.finalcutpro:getActiveCommandSet([forceReload]) -> table or nil
--- Function
--- Returns the 'Active Command Set' as a Table. The result is cached, so pass in
--- `true` for `forceReload` if you want to reload it.
---
--- Parameters:
---  * forceReload	- (optional) If `true`, require the Command Set to be reloaded.
---
--- Returns:
---  * A table of the Active Command Set's contents, or `nil` if an error occurred
---
function App:getActiveCommandSet(forceReload)

	if forceReload or not self._activeCommandSet then
		local path = self:getActiveCommandSetPath()
		self._activeCommandSet = self:getCommandSet(path)
		-- reset the command cache since we've loaded a new set.
		if self._activeCommands then
			self._activeCommands = nil
		end
	end

	return self._activeCommandSet
end

--- cp.finalcutpro.getCommandShortcuts(id) -> table of hs.commands.shortcut
--- Function
--- Finds a shortcut from the Active Command Set with the specified ID and returns a table
--- of `hs.commands.shortcut`s for the specified command, or `nil` if it doesn't exist.
---
--- Parameters:
---  * id - The unique ID for the command.
---
--- Returns:
---  * The array of shortcuts, or `nil` if no command exists with the specified `id`.
---
function App:getCommandShortcuts(id)
	local activeCommands = self._activeCommands
	if not activeCommands then
		activeCommands = {}
		self._activeCommands = activeCommands
	end

	local shortcuts = activeCommands[id]
	if not shortcuts then
		local commandSet = self:getActiveCommandSet()

		local fcpxCmds = commandSet[id]

		if fcpxCmds == nil then
			return nil
		end

		if #fcpxCmds == 0 then
			fcpxCmds = { fcpxCmds }
		end

		shortcuts = {}

		for _,fcpxCmd in ipairs(fcpxCmds) do
			local modifiers = nil
			local keyCode = nil
			local keypadModifier = false

			if fcpxCmd["modifiers"] ~= nil then
				if string.find(fcpxCmd["modifiers"], "keypad") then keypadModifier = true end
				modifiers = kc.fcpxModifiersToHsModifiers(fcpxCmd["modifiers"])
			elseif fcpxCmd["modifierMask"] ~= nil then
				modifiers = kc.modifierMaskToModifiers(fcpxCmd["modifierMask"])
			end

			if fcpxCmd["characterString"] ~= nil then
				keyCode = kc.characterStringToKeyCode(fcpxCmd["characterString"])
			elseif fcpxHacks["character"] ~= nil then
				if keypadModifier then
					keyCode = kc.keypadCharacterToKeyCode(fcpxCmd["character"])
				else
					keyCode = kc.characterStringToKeyCode(fcpxCmd["character"])
				end
			end

			if keyCode ~= nil and keyCode ~= "" then
				shortcuts[#shortcuts + 1] = shortcut:new(modifiers, keyCode)
			end
		end

		activeCommands[id] = shortcuts
	end
	return shortcuts
end

--- cp.finalcutpro.performShortcut() -> Boolean
--- Function
--- Performs a Final Cut Pro Shortcut
---
--- Parameters:
---  * whichShortcut - As per the Command Set name
---
--- Returns:
---  * true if successful otherwise false
---
function App:performShortcut(whichShortcut)
	self:launch()
	local activeCommandSet = self:getActiveCommandSet()

	local shortcuts = self:getCommandShortcuts(whichShortcut)

	if shortcuts and #shortcuts > 0 then
		shortcuts[1]:trigger()
	end

	return true
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- LANGUAGE
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

App.fileMenuTitle = {
	["File"]		= "en",
	["Ablage"]		= "de",
	["Archivo"]		= "es",
	["Fichier"]		= "fr",
	["ファイル"]		= "ja",
	["文件"]			= "zh_CN"
}

--- cp.finalcutpro:getCurrentLanguage() -> string
--- Function
--- Returns the language Final Cut Pro is currently using.
---
--- Parameters:
---  * none
---
--- Returns:
---  * Returns the current language as string (or 'en' if unknown).
---
function App:getCurrentLanguage(forceReload, forceLanguage)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Supported Languages:
	--------------------------------------------------------------------------------
	local finalCutProLanguages = App.SUPPORTED_LANGUAGES

	--------------------------------------------------------------------------------
	-- Force a Language:
	--------------------------------------------------------------------------------
	if forceReload and forceLanguage ~= nil then
		self._currentLanguage = forceLanguage
		return self._currentLanguage
	end

	--------------------------------------------------------------------------------
	-- Caching:
	--------------------------------------------------------------------------------
	if self._currentLanguage ~= nil and not forceReload then
		--log.df("Using Final Cut Pro Language from Cache")
		return self._currentLanguage
	end

	--------------------------------------------------------------------------------
	-- If FCPX is already running, we determine the language off the menu:
	--------------------------------------------------------------------------------
	if self:isRunning() then
		local menuBar = self:menuBar()
		local fileMenu = menuBar:findMenuUI("File")
		if fileMenu then
			fileValue = fileMenu:attributeValue("AXTitle") or nil
			self._currentLanguage = fileValue and App.fileMenuTitle[fileValue]
			if self._currentLanguage then
				return self._currentLanguage
			end
		end
	end

	--------------------------------------------------------------------------------
	-- If FCPX is not running, we next try to determine the language using
	-- the Final Cut Pro Plist File:
	--------------------------------------------------------------------------------
	local finalCutProLanguage = self:getPreference("AppleLanguages", nil)
	if finalCutProLanguage ~= nil and next(finalCutProLanguage) ~= nil then
		if finalCutProLanguage[1] ~= nil then
			self._currentLanguage = finalCutProLanguage[1]
			return finalCutProLanguage[1]
		end
	end

	--------------------------------------------------------------------------------
	-- If that fails, we try and use the user locale:
	--------------------------------------------------------------------------------
	local a, userLocale = osascript.applescript("return user locale of (get system info)")
	if userLocale ~= nil then
		--------------------------------------------------------------------------------
		-- Only return languages Final Cut Pro actually supports:
		--------------------------------------------------------------------------------
		for i=1, #finalCutProLanguages do
			if userLocale == finalCutProLanguages[i] then
				self._currentLanguage = userLocale
				return userLocale
			else
				local subLang = string.find(userLocale, "_")
				if subLang ~= nil then
					local lang = string.sub(userLocale, 1, subLang - 1)
					if lang == finalCutProLanguages[i] then
						self._currentLanguage = lang
						return lang
					end
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- If that also fails, we try and use NSGlobalDomain AppleLanguages:
	--------------------------------------------------------------------------------
	local output, status, _, _ = hs.execute("defaults read NSGlobalDomain AppleLanguages")
	if status then
		local appleLanguages = tools.lines(output)
		if next(appleLanguages) ~= nil then
			if appleLanguages[1] == "(" and appleLanguages[#appleLanguages] == ")" then
				for i=2, #appleLanguages - 1 do
					local firstCharacter = string.sub(appleLanguages[i], 1, 1)
					local lastCharacter = string.sub(appleLanguages[i], -1)
					if firstCharacter == '"' and lastCharacter == '"' and string.len(appleLanguages[i]) > 2 then
						--------------------------------------------------------------------------------
						-- Only return languages Final Cut Pro actually supports:
						--------------------------------------------------------------------------------
						local currentLanguage = string.sub(appleLanguages[i], 2, -2)
						for x=1, #finalCutProLanguages do
							if currentLanguage == finalCutProLanguages[x] then
								self._currentLanguage = currentLanguage
								return currentLanguage
							else
								local subLang = string.find(currentLanguage, "-")
								if subLang ~= nil then
									local lang = string.sub(currentLanguage, 1, subLang - 1)
									if lang == finalCutProLanguages[x] then
										self._currentLanguage = lang
										return lang
									end
								end
							end
						end
					end
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- If all else fails, assume it's English:
	--------------------------------------------------------------------------------
	return "en"

end

--- cp.finalcutpro:getSupportedLanguages() -> table
--- Function
--- Returns a table of languages Final Cut Pro supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
---
function App:getSupportedLanguages()
	return App.SUPPORTED_LANGUAGES
end

--- cp.finalcutpro:getFlexoLanguages() -> table
--- Function
--- Returns a table of languages Final Cut Pro's Flexo Framework supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
---
function App:getFlexoLanguages()
	return App.FLEXO_LANGUAGES
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                               W A T C H E R S                              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- Watch for events that happen in the application.
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
--- * `events` - A table of functions with to watch. These may be:
--- 	* `active()`		- Triggered when the application is the active application.
--- 	* `inactive()`		- Triggered when the application is no longer the active application.
---     * `move()` 	 		- Triggered when the application window is moved.
--- 	* `preferences()`	- Triggered when the application preferences are updated.
---
--- Returns:
--- * An ID which can be passed to `unwatch` to stop watching.
function App:watch(events)
	self:_initWatchers()

	if not self._watchers then
		self._watchers = {}
	end

	self._watchers[#self._watchers+1] = {active = events.active, inactive = events.inactive, move = events.move, preferences = events.preferences}
	local id = { id=#self._watchers }

	-- If already active, we trigger an 'active' notification.
	if self:isFrontmost() and events.active then
		events.active()
	end

	return id
end

--- Stop watching for events that happen in the application for the specified ID.
---
--- Parameters:
--- * `id` 	- The ID object which was returned from the `watch(...)` function.
---
--- Returns:
--- * `true` if the ID was watching and has been removed.
function App:unwatch(id)
	local watchers = self._watchers
	if id and id.id and watchers and watchers[id.id] then
		table.remove(watchers, id.id)
		return true
	end
	return false
end

function App:_initWatchers()

	--------------------------------------------------------------------------------
	-- Application Watcher:
	--------------------------------------------------------------------------------
	local watcher = application.watcher

	self._active = false
	self._appWatcher = watcher.new(
		function(appName, eventType, appObject)
			local event = nil

			if (appName == "Final Cut Pro") then
				if self._active == false and (eventType == watcher.activated) and self:isFrontmost() then
					self._active = true
					event = "active"
				elseif self._active == true and (eventType == watcher.deactivated or eventType == watcher.terminated) then
					self._active = false
					event = "inactive"
				end
			end

			if event then
				self:_notifyWatchers(event)
			end
		end
	):start()

	windowfilter.setLogLevel("error") -- The wfilter errors are too annoying.
	self._windowWatcher = windowfilter.new{"Final Cut Pro"}

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Not On Screen:
	--------------------------------------------------------------------------------
	self._windowWatcher:subscribe(windowfilter.windowNotOnScreen, function()
		if self._active == true and not self:isFrontmost() then
			self._active = false
			self:_notifyWatchers("inactive")
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window On Screen:
	--------------------------------------------------------------------------------
	self._windowWatcher:subscribe(windowfilter.windowOnScreen, function()
		if self._active == false and self:isFrontmost() then
			self._active = true
			self:_notifyWatchers("active")
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Moved:
	--------------------------------------------------------------------------------
	self._windowWatcher:subscribe(windowfilter.windowMoved, function()
		self:_notifyWatchers("move")
	end, true)

	--------------------------------------------------------------------------------
	-- Preferences Watcher:
	--------------------------------------------------------------------------------
	self._preferencesWatcher = pathwatcher.new("~/Library/Preferences/", function(files)
		for _,file in pairs(files) do
			if file:sub(-24) == "com.apple.FinalCut.plist" then
				self:_notifyWatchers("preferences")
				return
			end
		end
	end):start()

end

function App:_notifyWatchers(event)
	if self._watchers then
		for i,watcher in ipairs(self._watchers) do
			if type(watcher[event]) == "function" then
				watcher[event]()
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   D E V E L O P M E N T      T O O L S                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- cp.finalcutpro._generateMenuMap() -> Table
--- Function
--- Generates a map of the menu bar and saves it in '/hs/finalcutpro/menumap.json'.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * True is successful otherwise Nil
---
function App:_generateMenuMap()
	return self:menuBar():generateMenuMap()
end

function App:_listWindows()
	log.d("Listing FCPX windows:")
	self:show()
	local windows = self:windowsUI()
	for i,w in ipairs(windows) do
		log.df(string.format("%7d", i)..": "..self:_describeWindow(w))
	end

	log.df("")
	log.df("   Main: "..self:_describeWindow(self:UI():mainWindow()))
	log.df("Focused: "..self:_describeWindow(self:UI():focusedWindow()))
end

function App:_describeWindow(w)
	return "title: "..inspect(w:attributeValue("AXTitle"))..
	       "; role: "..inspect(w:attributeValue("AXRole"))..
		   "; subrole: "..inspect(w:attributeValue("AXSubrole"))..
		   "; modal: "..inspect(w:attributeValue("AXModal"))
end

return App:new()