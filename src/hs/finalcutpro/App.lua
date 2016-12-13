--- hs.finalcutpro.App
---
--- Represents the Final Cut Pro X application, providing functions that allow different tasks to be accomplished.
---
--- Author: David Peterson (david@randombits.org)
---

--- Standard Modules
local application								= require("hs.application")
local ax 										= require("hs._asm.axuielement")
local inspect									= require("hs.inspect")
local log										= require("hs.logger").new("fcpxapp")

--- Local Modules
local MenuBar									= require("hs.finalcutpro.MenuBar")
local PreferencesWindow							= require("hs.finalcutpro.prefs.PreferencesWindow")

--- The App module
local App = {}

--- Constants
App.BUNDLE_ID 							= "com.apple.FinalCut"
App.PASTEBOARD_UTI 						= "com.apple.flexo.proFFPasteboardUTI"

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
	return application(App.BUNDLE_ID) or nil
end

function App:AX()
	local fcp = self:application()
	return fcp and ax.applicationElement(fcp)
end

--- hs.finalcutpro.running() -> boolean
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

function App:menuBar()
	if not self._menuBar then
		self._menuBar = MenuBar:new(self)
	end
	return self._menuBar
end

function App:preferencesWindow()
	if not self._preferencesWindow then
		self._preferencesWindow = PreferencesWindow:new(self)
	end
	return self._preferencesWindow
end

--- hs.finalcutpro.App:windowsAX() -> axuielement
--- Function
--- Returns the AX containing the list of windows in the app.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * The axuieleme, or nil if the application is not running.
---
function App:windowsAX()
	local ax = self:AX()
	return ax and ax:windows()
end

function App:_listWindows()
	log.d("Listing FCPX windows:")
	local windows = self:windowsAX()
	for i,w in ipairs(windows) do
		log.d(i..": title: "..inspect(w:title()).."; role: "..inspect(w:role()).."; subrole: "..inspect(w:subrole()).."; modal: "..inspect(w:modal()))
	end
end

return App