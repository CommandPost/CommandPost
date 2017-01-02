--- hs.finalcutpro.App
---
--- Represents the Final Cut Pro X application, providing functions that allow different tasks to be accomplished.
---
--- Author: David Peterson (david@randombits.org)
---

--- Standard Modules
local application								= require("hs.application")
local ax 										= require("hs._asm.axuielement")
local osascript 								= require("hs.osascript")
local just										= require("hs.just")
local fs 										= require("hs.fs")

local inspect									= require("hs.inspect")
local log										= require("hs.logger").new("fcpxapp")

local axutils									= require("hs.finalcutpro.axutils")

--- Local Modules
local MenuBar									= require("hs.finalcutpro.MenuBar")
local PreferencesWindow							= require("hs.finalcutpro.prefs.PreferencesWindow")
local PrimaryWindow								= require("hs.finalcutpro.main.PrimaryWindow")
local SecondaryWindow							= require("hs.finalcutpro.main.SecondaryWindow")
local FullScreenWindow							= require("hs.finalcutpro.main.FullScreenWindow")
local Timeline									= require("hs.finalcutpro.main.Timeline")
local Browser									= require("hs.finalcutpro.main.Browser")
local Viewer									= require("hs.finalcutpro.main.Viewer")
local CommandEditor								= require("hs.finalcutpro.cmd.CommandEditor")
local ExportDialog								= require("hs.finalcutpro.export.ExportDialog")

--- The App module
local App = {}

--- Constants
App.BUNDLE_ID 									= "com.apple.FinalCut"
App.PASTEBOARD_UTI 								= "com.apple.flexo.proFFPasteboardUTI"

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


--- hs.finalcutpro.App:new() -> App
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

--- hs.finalcutpro.App:application() -> hs.application
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

function App:UI()
	return axutils.cache(self, "_ui", function()
		local fcp = self:application()
		return fcp and ax.applicationElement(fcp)
	end)
end

--- hs.finalcutpro.App:running() -> boolean
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


--- hs.finalcutpro.App:launch() -> boolean
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


--- hs.finalcutpro.App:restart() -> boolean
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
		app:kill()

		-- Wait until Final Cut Pro is Closed (checking every 0.1 seconds for up to 20 seconds):
		just.doWhile(function() return self:isRunning() end, 20, 0.1)

		-- Launch Final Cut Pro:
		return self:launch()
	end
	return false
end


--- hs.finalcutpro.App:installed() -> boolean
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
	local path = application.pathForBundleID(App.BUNDLE_ID)
	return doesDirectoryExist(path)
end

--- hs.finalcutpro.App:isFrontmost() -> boolean
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


--- hs.finalcutpro.App:version() -> string or nil
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

function App:menuBar()
	if not self._menuBar then
		self._menuBar = MenuBar:new(self)
	end
	return self._menuBar
end

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

function App:preferencesWindow()
	if not self._preferencesWindow then
		self._preferencesWindow = PreferencesWindow:new(self)
	end
	return self._preferencesWindow
end

function App:primaryWindow()
	if not self._primaryWindow then
		self._primaryWindow = PrimaryWindow:new(self)
	end
	return self._primaryWindow
end

function App:secondaryWindow()
	if not self._secondaryWindow then
		self._secondaryWindow = SecondaryWindow:new(self)
	end
	return self._secondaryWindow
end

function App:fullScreenWindow()
	if not self._fullScreenWindow then
		self._fullScreenWindow = FullScreenWindow:new(self)
	end
	return self._fullScreenWindow
end

function App:commandEditor()
	if not self._commandEditor then
		self._commandEditor = CommandEditor:new(self)
	end
	return self._commandEditor
end

function App:exportDialog()
	if not self._exportDialog then
		self._exportDialog = ExportDialog:new(self)
	end
	return self._exportDialog
end

--- hs.finalcutpro.App:windowsUI() -> axuielement
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


--- hs.finalcutpro.App:timeline() -> Timeline
--- Function
--- Returns the Timeline instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Timeline
function App:timeline()
	if not self._timeline then
		self._timeline = Timeline:new(self)
	end
	return self._timeline
end


--- hs.finalcutpro.App:viewer() -> Viewer
--- Function
--- Returns the Viewer instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Viewer
function App:viewer()
	if not self._viewer then
		self._viewer = Viewer:new(self, false)
	end
	return self._viewer
end

--- hs.finalcutpro.App:eventViewer() -> Viewer
--- Function
--- Returns the Event Viewer instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Event Viewer
function App:eventViewer()
	if not self._eventViewer then
		self._eventViewer = Viewer:new(self, true)
	end
	return self._eventViewer
end

--- hs.finalcutpro.App:browser() -> Browser
--- Function
--- Returns the Browser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Browser
function App:browser()
	if not self._browser then
		self._browser = Browser:new(self)
	end
	return self._browser
end

--- hs.finalcutpro.App:libraries() -> LibrariesBrowser
--- Function
--- Returns the LibrariesBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the LibrariesBrowser
function App:libraries()
	return self:browser():libraries()
end

--- hs.finalcutpro.App:media() -> MediaBrowser
--- Function
--- Returns the MediaBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the MediaBrowser
function App:media()
	return self:browser():media()
end

--- hs.finalcutpro.App:generators() -> GeneratorsBrowser
--- Function
--- Returns the GeneratorsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the GeneratorsBrowser
function App:generators()
	return self:browser():generators()
end

--- hs.finalcutpro.App:effects() -> EffectsBrowser
--- Function
--- Returns the EffectsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the EffectsBrowser
function App:effects()
	return self:timeline():effects()
end

--- hs.finalcutpro.App:transitions() -> TransitionsBrowser
--- Function
--- Returns the TransitionsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the TransitionsBrowser
function App:transitions()
	return self:timeline():transitions()
end

--- hs.finalcutpro.App:inspector() -> Inspector
--- Function
--- Returns the Inspector instance from the primary window
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the Inspector
function App:inspector()
	return self:primaryWindow():inspector()
end

--- hs.finalcutpro.App:colorBoard() -> ColorBoard
--- Function
--- Returns the ColorBoard instance from the primary window
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the ColorBoard
function App:colorBoard()
	return self:primaryWindow():colorBoard()
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- DEBUG FUNCTIONS
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

function App:_listWindows()
	log.d("Listing FCPX windows:")
	local windows = self:windowsUI()
	for i,w in ipairs(windows) do
		debugMessage(string.format("%7d", i)..": "..self:_describeWindow(w))
	end

	debugMessage("")
	debugMessage("   Main: "..self:_describeWindow(self:UI():mainWindow()))
	debugMessage("Focused: "..self:_describeWindow(self:UI():focusedWindow()))
end

function App:_describeWindow(w)
	return "title: "..inspect(w:attributeValue("AXTitle"))..
	       "; role: "..inspect(w:attributeValue("AXRole"))..
		   "; subrole: "..inspect(w:attributeValue("AXSubrole"))..
		   "; modal: "..inspect(w:attributeValue("AXModal"))
end

return App