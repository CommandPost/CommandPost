--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro ===
---
--- Represents the Final Cut Pro application, providing functions that allow different tasks to be accomplished.
---
--- This module provides an API to work with the FCPX application. There are a couple of types of files:
---
--- * `init.lua` - the main module that gets imported.
--- * `axutils.lua` - some utility functions for working with `axuielement` objects.
--- * `test.lua` - some support functions for testing. TODO: Make this better.
---
--- Generally, you will `require` the `cp.finalcutpro` module to import it, like so:
---
--- ```lua
--- local fcp = require("cp.apple.finalcutpro")
--- ```
---
--- Then, there are the `UpperCase` files, which represent the application itself:
---
--- * `MenuBar` 	- The main menu bar.
--- * `prefs/PreferencesWindow` - The preferences window.
--- * etc...
---
--- The `fcp` variable is the root application. It has functions which allow you to perform tasks or access parts of the UI. For example, to open the `Preferences` window, you can do this:
---
--- ```lua
--- fcp:preferencesWindow():show()
--- ```
---
--- In general, as long as FCPX is running, actions can be performed directly, and the API will perform the required operations to achieve it. For example, to toggle the 'Create Optimized Media' checkbox in the 'Import' section of the 'Preferences' window, you can simply do this:
---
--- ```lua
--- fcp:preferencesWindow():importPanel():toggleCreateOptimizedMedia()
--- ```
---
--- The API will automatically open the `Preferences` window, navigate to the 'Import' panel and toggle the checkbox.
---
--- The `UpperCase` classes also have a variety of `UI` methods. These will return the `axuielement` for the relevant GUI element, if it is accessible. If not, it will return `nil`. These allow direct interaction with the GUI if necessary. It's most useful when adding new functions to `UpperCase` files for a particular element.
---
--- This can also be used to 'wait' for an element to be visible before performing a task. For example, if you need to wait for the `Preferences` window to finish loading before doing something else, you can do this with the `cp.just` library:
---
--- ```lua
--- local just = require("cp.just")
---
--- local prefsWindow = fcp:preferencesWindow()
---
--- local prefsUI = just.doUntil(function() return prefsWindow:UI() end)
---
--- if prefsUI then
--- 	-- it's open!
--- else
--- 	-- it's closed!
--- end
--- ```
---
--- By using the `just` library, we can do a loop waiting until the function returns a result that will give up after a certain time period (10 seconds by default).
---
--- Of course, we have a specific support function for that already, so you could do this instead:
---
--- ```lua
--- if fcp:preferencesWindow():isShowing() then
--- 	-- it's open!
--- else
--- 	-- it's closed!
--- end
--- ```

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
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
local timer										= require("hs.timer")
local windowfilter								= require("hs.window.filter")

local v											= require("semver")

local plist										= require("cp.plist")
local just										= require("cp.just")
local tools										= require("cp.tools")

local axutils									= require("cp.apple.finalcutpro.axutils")

local MenuBar									= require("cp.apple.finalcutpro.MenuBar")
local PreferencesWindow							= require("cp.apple.finalcutpro.prefs.PreferencesWindow")
local PrimaryWindow								= require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow							= require("cp.apple.finalcutpro.main.SecondaryWindow")
local FullScreenWindow							= require("cp.apple.finalcutpro.main.FullScreenWindow")
local Timeline									= require("cp.apple.finalcutpro.main.Timeline")
local Browser									= require("cp.apple.finalcutpro.main.Browser")
local Viewer									= require("cp.apple.finalcutpro.main.Viewer")
local CommandEditor								= require("cp.apple.finalcutpro.cmd.CommandEditor")
local ExportDialog								= require("cp.apple.finalcutpro.export.ExportDialog")
local MediaImport								= require("cp.apple.finalcutpro.import.MediaImport")

local kc										= require("cp.apple.finalcutpro.keycodes")
local shortcut									= require("cp.commands.shortcut")

local is										= require("cp.is")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local App = {}

--- cp.apple.finalcutpro.EARLIEST_SUPPORTED_VERSION
--- Constant
--- The earliest version of Final Cut Pro supported by this module.
App.EARLIEST_SUPPORTED_VERSION					= "10.3"

--------------------------------------------------------------------------------
-- TODO: The below five constants should probably just be determined from the
--       Final Cut Pro plist file?
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.BUNDLE_ID
--- Constant
--- Final Cut Pro's Bundle ID
App.BUNDLE_ID 									= "com.apple.FinalCut"

--- cp.apple.finalcutpro.PASTEBOARD_UTI
--- Constant
--- Final Cut Pro's Pasteboard UTI
App.PASTEBOARD_UTI 								= "com.apple.flexo.proFFPasteboardUTI"

--- cp.apple.finalcutpro.PREFS_PLIST_PATH
--- Constant
--- Final Cut Pro's Preferences Path
App.PREFS_PLIST_PATH 							= "~/Library/Preferences/com.apple.FinalCut.plist"

--- cp.apple.finalcutpro.SUPPORTED_LANGUAGES
--- Constant
--- Table of Final Cut Pro's supported Languages
App.SUPPORTED_LANGUAGES 						= {"de", "en", "es", "fr", "ja", "zh_CN"}

--- cp.apple.finalcutpro.FLEXO_LANGUAGES
--- Constant
--- Table of Final Cut Pro's supported Languages for the Flexo Framework
App.FLEXO_LANGUAGES								= {"de", "en", "es_419", "es", "fr", "id", "ja", "ms", "vi", "zh_CN"}

--- cp.apple.finalcutpro:application() -> hs.application
--- Function
--- Returns the hs.application for Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The hs.application, or nil if the application is not running.
function App:application()
	local result = application.applicationsForBundleID(App.BUNDLE_ID)
	if result and #result > 0 then
		return result[1] -- If there is at least one copy running, return the first one
	end
	return nil
end

--- cp.apple.finalcutpro:getBundleID() -> string
--- Function
--- Returns the Final Cut Pro Bundle ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the Final Cut Pro Bundle ID
function App:getBundleID()
	return App.BUNDLE_ID
end

--- cp.apple.finalcutpro:getPasteboardUTI() -> string
--- Function
--- Returns the Final Cut Pro Pasteboard UTI
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the Final Cut Pro Pasteboard UTI
function App:getPasteboardUTI()
	return App.PASTEBOARD_UTI
end

--- cp.apple.finalcutpro:getPasteboardUTI() -> axuielementObject
--- Function
--- Returns the Final Cut Pro axuielementObject
---
--- Parameters:
---  * None
---
--- Returns:
---  * A axuielementObject of Final Cut Pro
function App:UI()
	return axutils.cache(self, "_ui", function()
		local fcp = self:application()
		return fcp and ax.applicationElement(fcp)
	end)
end

--- cp.apple.finalcutpro:isRunning() -> boolean
--- Function
--- Is Final Cut Pro Running?
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro is running otherwise False
App.isRunning = is.new(function(self)
	local fcpx = self:application()
	return fcpx and fcpx:isRunning()
end):bind(App)

--- cp.apple.finalcutpro:launch() -> boolean
--- Function
--- Launches Final Cut Pro, or brings it to the front if it was already running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Final Cut Pro was either launched or focused, otherwise false (e.g. if Final Cut Pro doesn't exist)
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

--- cp.apple.finalcutpro:restart() -> boolean
--- Function
--- Restart Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Final Cut Pro was running and restarted successfully.
function App:restart()
	local app = self:application()
	if app then
		local appPath = app:path()
		-- Kill Final Cut Pro:
		self:quit()

		-- Wait until Final Cut Pro is Closed (checking every 0.1 seconds for up to 20 seconds):
		just.doWhile(function() return self:isRunning() end, 20, 0.1)

		-- Launch Final Cut Pro:
		if appPath then
			local _, result = hs.execute([[open "]] .. tostring(appPath) .. [["]])
			return result
		end

	end
	return false
end

--- cp.apple.finalcutpro:show() -> cp.finalcutpro object
--- Function
--- Activate Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * An cp.finalcutpro object otherwise nil
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

--- cp.apple.finalcutpro:show() -> cp.finalcutpro object
--- Function
--- Activate Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * An cp.finalcutpro object otherwise nil
App.isShowing = is.new(function(self)
	local app = self:application()
	return app ~= nil and app:isRunning() and not app:isHidden()
end):bind(App)

--- cp.apple.finalcutpro:hide() -> cp.finalcutpro object
--- Function
--- Hides Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * An cp.finalcutpro object otherwise nil
function App:hide()
	local app = self:application()
	if app then
		app:hide()
	end
	return self
end

--- cp.apple.finalcutpro:quit() -> cp.finalcutpro object
--- Function
--- Quits Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * An cp.finalcutpro object otherwise nil
function App:quit()
	local app = self:application()
	if app then
		app:kill()
	end
	return self
end

--- cp.apple.finalcutpro:path() -> string or nil
--- Function
--- Path to Final Cut Pro Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing Final Cut Pro's filesystem path, or nil if Final Cut Pro's path could not be determined.
function App:getPath()
	local app = self:application()
	if app then
		----------------------------------------------------------------------------------------
		-- FINAL CUT PRO IS CURRENTLY RUNNING:
		----------------------------------------------------------------------------------------
		local appPath = app:path()
		if appPath then
			return appPath
		else
			log.df("GET PATH: Failed to get running application path.")
		end
	else
		----------------------------------------------------------------------------------------
		-- FINAL CUT PRO IS CURRENTLY CLOSED:
		----------------------------------------------------------------------------------------
		local result = application.pathForBundleID(App.BUNDLE_ID)
		if result then
			return result
		end
	end
	return nil
end

--- cp.apple.finalcutpro:isInstalled() -> boolean
--- Function
--- Is a supported version of Final Cut Pro Installed?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if a supported version of Final Cut Pro is installed otherwise `false`
---  * Supported version refers to any version of Final Cut Pro equal or higher to cp.apple.finalcutpro.EARLIEST_SUPPORTED_VERSION
App.isInstalled = is.new(function(self)
	local version = self:getVersion()
	if version then
		if v(tostring(version)) >= v(tostring(App.EARLIEST_SUPPORTED_VERSION)) then
			return true
		end
	end
	return false
end):bind(App)

--- cp.apple.finalcutpro:isFrontmost() -> boolean
--- Function
--- Is Final Cut Pro Frontmost?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Final Cut Pro is Frontmost.
App.isFrontmost = is.new(function(self)
	local fcpx = self:application()
	return fcpx and fcpx:isFrontmost()
end):bind(App)

--- cp.apple.finalcutpro:getVersion() -> string or nil
--- Function
--- Version of Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * Version as string or nil if Final Cut Pro cannot be found.
---
--- Notes:
---  * If Final Cut Pro is running it will get the version of the active Final Cut Pro application, otherwise, it will use hs.application.infoForBundleID() to find the version.
function App:getVersion()

	----------------------------------------------------------------------------------------
	-- GET RUNNING COPY OF FINAL CUT PRO:
	----------------------------------------------------------------------------------------
	local app = self:application()

	----------------------------------------------------------------------------------------
	-- FINAL CUT PRO IS CURRENTLY RUNNING:
	----------------------------------------------------------------------------------------
	if app then
		local appPath = app:path()
		if appPath then
			local info = application.infoForBundlePath(appPath)
			if info then
				return info["CFBundleShortVersionString"]
			else
				log.df("VERSION CHECK: Could not determine Final Cut Pro's version.")
			end
		else
			log.df("VERSION CHECK: Could not determine Final Cut Pro's path.")
		end
	end

	----------------------------------------------------------------------------------------
	-- NO VERSION OF FINAL CUT PRO CURRENTLY RUNNING:
	----------------------------------------------------------------------------------------
	local app = application.infoForBundleID(App.BUNDLE_ID)
	if app then
		return app["CFBundleShortVersionString"]
	else
		log.df("VERSION CHECK: Could not determine Final Cut Pro's info from Bundle ID.")
	end

	----------------------------------------------------------------------------------------
	-- FINAL CUT PRO COULD NOT BE DETECTED:
	----------------------------------------------------------------------------------------
	return nil

end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- MENU BAR
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:menuBar() -> menuBar object
--- Function
--- Returns the Final Cut Pro Menu Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * A menuBar object
function App:menuBar()
	if not self._menuBar then
		self._menuBar = MenuBar:new(self)
	end
	return self._menuBar
end

--- cp.apple.finalcutpro:selectMenu(...) -> boolean
--- Function
--- Selects a Final Cut Pro Menu Item based on the list of menu titles in English.
---
--- Parameters:
---  * ... - The list of menu items you'd like to activate, for example:
---            select("View", "Browser", "as List")
---
--- Returns:
---  * `true` if the press was successful.
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

--- cp.apple.finalcutpro:preferencesWindow() -> preferenceWindow object
--- Function
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Preferences Window
function App:preferencesWindow()
	if not self._preferencesWindow then
		self._preferencesWindow = PreferencesWindow:new(self)
	end
	return self._preferencesWindow
end

--- cp.apple.finalcutpro:primaryWindow() -> primaryWindow object
--- Function
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Primary Window
function App:primaryWindow()
	if not self._primaryWindow then
		self._primaryWindow = PrimaryWindow:new(self)
	end
	return self._primaryWindow
end

--- cp.apple.finalcutpro:secondaryWindow() -> secondaryWindow object
--- Function
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Secondary Window
function App:secondaryWindow()
	if not self._secondaryWindow then
		self._secondaryWindow = SecondaryWindow:new(self)
	end
	return self._secondaryWindow
end

--- cp.apple.finalcutpro:fullScreenWindow() -> fullScreenWindow object
--- Function
--- Returns the Final Cut Pro Full Screen Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Full Screen Playback Window
function App:fullScreenWindow()
	if not self._fullScreenWindow then
		self._fullScreenWindow = FullScreenWindow:new(self)
	end
	return self._fullScreenWindow
end

--- cp.apple.finalcutpro:commandEditor() -> commandEditor object
--- Function
--- Returns the Final Cut Pro Command Editor
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Command Editor
function App:commandEditor()
	if not self._commandEditor then
		self._commandEditor = CommandEditor:new(self)
	end
	return self._commandEditor
end

--- cp.apple.finalcutpro:mediaImport() -> mediaImport object
--- Function
--- Returns the Final Cut Pro Media Import Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Media Import Window
function App:mediaImport()
	if not self._mediaImport then
		self._mediaImport = MediaImport:new(self)
	end
	return self._mediaImport
end

--- cp.apple.finalcutpro:exportDialog() -> exportDialog object
--- Function
--- Returns the Final Cut Pro Export Dialog Box
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Export Dialog Box
function App:exportDialog()
	if not self._exportDialog then
		self._exportDialog = ExportDialog:new(self)
	end
	return self._exportDialog
end

--- cp.apple.finalcutpro:windowsUI() -> axuielement
--- Function
--- Returns the UI containing the list of windows in the app.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The axuielement, or nil if the application is not running.
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

--- cp.apple.finalcutpro:timeline() -> Timeline
--- Function
--- Returns the Timeline instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Timeline
function App:timeline()
	if not self._timeline then
		self._timeline = Timeline:new(self)
	end
	return self._timeline
end

--- cp.apple.finalcutpro:viewer() -> Viewer
--- Function
--- Returns the Viewer instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Viewer
function App:viewer()
	if not self._viewer then
		self._viewer = Viewer:new(self, false)
	end
	return self._viewer
end

--- cp.apple.finalcutpro:eventViewer() -> Event Viewer
--- Function
--- Returns the Event Viewer instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Event Viewer
function App:eventViewer()
	if not self._eventViewer then
		self._eventViewer = Viewer:new(self, true)
	end
	return self._eventViewer
end

--- cp.apple.finalcutpro:browser() -> Browser
--- Function
--- Returns the Browser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Browser
function App:browser()
	if not self._browser then
		self._browser = Browser:new(self)
	end
	return self._browser
end

--- cp.apple.finalcutpro:libraries() -> LibrariesBrowser
--- Function
--- Returns the LibrariesBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the LibrariesBrowser
function App:libraries()
	return self:browser():libraries()
end

--- cp.apple.finalcutpro:media() -> MediaBrowser
--- Function
--- Returns the MediaBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the MediaBrowser
function App:media()
	return self:browser():media()
end

--- cp.apple.finalcutpro:generators() -> GeneratorsBrowser
--- Function
--- Returns the GeneratorsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the GeneratorsBrowser
function App:generators()
	return self:browser():generators()
end

--- cp.apple.finalcutpro:effects() -> EffectsBrowser
--- Function
--- Returns the EffectsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the EffectsBrowser
function App:effects()
	return self:timeline():effects()
end

--- cp.apple.finalcutpro:transitions() -> TransitionsBrowser
--- Function
--- Returns the TransitionsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the TransitionsBrowser
function App:transitions()
	return self:timeline():transitions()
end

--- cp.apple.finalcutpro:inspector() -> Inspector
--- Function
--- Returns the Inspector instance from the primary window
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Inspector
function App:inspector()
	return self:primaryWindow():inspector()
end

--- cp.apple.finalcutpro:colorBoard() -> ColorBoard
--- Function
--- Returns the ColorBoard instance from the primary window
---
--- Parameters:
---  * None
---
--- Returns:
---  * the ColorBoard
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

--- cp.apple.finalcutpro:getPreferences() -> table or nil
--- Function
--- Gets Final Cut Pro's Preferences as a table. It checks if the preferences
--- file has been modified and reloads when necessary.
---
--- Parameters:
---  * forceReload	- (optional) if true, a reload will be forced even if the file hasn't been modified.
---  * preventMultipleReloads - (optional) if true, adds a 0.01 delay before reloading preferences (for use with the watcher)
---
--- Returns:
---  * A table with all of Final Cut Pro's preferences, or nil if an error occurred
App._preferencesAlreadyUpdating = false
function App:getPreferences(forceReload)
	local modified = fs.attributes(App.PREFS_PLIST_PATH, "modification")
	if forceReload or modified ~= self._preferencesModified then
		log.df("Reloading Final Cut Pro Preferences: %s; %s", self._preferencesModified, modified)
		-- NOTE: https://macmule.com/2014/02/07/mavericks-preference-caching/
		hs.execute([[/usr/bin/python -c 'import CoreFoundation; CoreFoundation.CFPreferencesAppSynchronize("com.apple.FinalCut")']])

		self._preferences = plist.binaryFileToTable(App.PREFS_PLIST_PATH) or nil
		self._preferencesModified = fs.attributes(App.PREFS_PLIST_PATH, "modification")
	 end
	return self._preferences
end

--- cp.apple.finalcutpro.getPreference(value, default, forceReload) -> string or nil
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

--- cp.apple.finalcutpro:setPreference(key, value) -> boolean
--- Function
--- Sets an individual Final Cut Pro preference
---
--- Parameters:
---  * key - The preference you want to change
---  * value - The value you want to set for that preference
---
--- Returns:
---  * True if executed successfully otherwise False
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

--- cp.apple.finalcutpro:importXML() -> boolean
--- Function
--- Imports an XML file into Final Cut Pro
---
--- Parameters:
---  * path = Path to XML File
---
--- Returns:
---  * A boolean value indicating whether the AppleScript succeeded or not
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

--- cp.apple.finalcutpro:getActiveCommandSetPath() -> string or nil
--- Function
--- Gets the 'Active Command Set' value from the Final Cut Pro preferences
---
--- Parameters:
---  * None
---
--- Returns:
---  * The 'Active Command Set' value, or the 'Default' command set if none is set.
function App:getActiveCommandSetPath()
	local result = self:getPreference("Active Command Set") or nil
	if result == nil then
		-- In the unlikely scenario that this is the first time FCPX has been run:
		result = self:getDefaultCommandSetPath()
	end
	return result
end

--- cp.apple.finalcutpro:getDefaultCommandSetPath([langauge]) -> string
--- Function
--- Gets the path to the 'Default' Command Set.
---
--- Parameters:
---  * `language`	- (optional) The language code to use. Defaults to the current FCPX language.
---
--- Returns:
---  * The 'Default' Command Set path, or `nil` if an error occurred
function App:getDefaultCommandSetPath(language)
	language = language or self:getCurrentLanguage()
	return self:getPath() .. "/Contents/Resources/" .. language .. ".lproj/Default.commandset"
end

--- cp.apple.finalcutpro:getCommandSet(path) -> string
--- Function
--- Loads the Command Set at the specified path into a table.
---
--- Parameters:
---  * `path`	- The path to the command set.
---
--- Returns:
---  * The Command Set as a table, or `nil` if there was a problem.
function App:getCommandSet(path)
	if fs.attributes(path) ~= nil then
		return plist.fileToTable(path)
	end
end

--- cp.apple.finalcutpro:getActiveCommandSet([forceReload]) -> table or nil
--- Function
--- Returns the 'Active Command Set' as a Table. The result is cached, so pass in
--- `true` for `forceReload` if you want to reload it.
---
--- Parameters:
---  * forceReload	- (optional) If `true`, require the Command Set to be reloaded.
---
--- Returns:
---  * A table of the Active Command Set's contents, or `nil` if an error occurred
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

--- cp.apple.finalcutpro.getCommandShortcuts(id) -> table of hs.commands.shortcut
--- Function
--- Finds a shortcut from the Active Command Set with the specified ID and returns a table
--- of `hs.commands.shortcut`s for the specified command, or `nil` if it doesn't exist.
---
--- Parameters:
---  * id - The unique ID for the command.
---
--- Returns:
---  * The array of shortcuts, or `nil` if no command exists with the specified `id`.
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

--- cp.apple.finalcutpro.performShortcut() -> Boolean
--- Function
--- Performs a Final Cut Pro Shortcut
---
--- Parameters:
---  * whichShortcut - As per the Command Set name
---
--- Returns:
---  * true if successful otherwise false
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

--- cp.apple.finalcutpro:getCurrentLanguage() -> string
--- Function
--- Returns the language Final Cut Pro is currently using.
---
--- Parameters:
---  * none
---
--- Returns:
---  * Returns the current language as string (or 'en' if unknown).
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
		local menuMap = menuBar:getMainMenu()
		local menuUI = menuBar:UI()
		if menuMap and menuUI and #menuMap >= 2 and #menuUI >=2 then
			local fileMap = menuMap[2]
			local fileUI = menuUI[2]
			local title = fileUI:attributeValue("AXTitle") or nil
			for _,lang in ipairs(self:getSupportedLanguages()) do
				if fileMap[lang] == title then
					self._currentLanguage = lang
					return lang
				end
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

--- cp.apple.finalcutpro:getSupportedLanguages() -> table
--- Function
--- Returns a table of languages Final Cut Pro supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
function App:getSupportedLanguages()
	return App.SUPPORTED_LANGUAGES
end

--- cp.apple.finalcutpro:getFlexoLanguages() -> table
--- Function
--- Returns a table of languages Final Cut Pro's Flexo Framework supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
function App:getFlexoLanguages()
	return App.FLEXO_LANGUAGES
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                               W A T C H E R S                              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro:watch() -> string
--- Method
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

--- cp.apple.finalcutpro:unwatch() -> boolean
--- Method
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
	self._windowWatcher = windowfilter.new({"Final Cut Pro"}, "finalcutpro")

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

-- cp.apple.finalcutpro._generateMenuMap() -> Table
-- Function
-- Generates a map of the menu bar and saves it in '/hs/finalcutpro/menumap.json'.
--
-- Parameters:
--  * N/A
--
-- Returns:
--  * `true` if successful otherwise `nil`
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

return App
