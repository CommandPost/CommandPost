--- hs.finalcutpro.App
---
--- Represents the Final Cut Pro X application, providing functions that allow different tasks to be accomplished.
---
--- Author: David Peterson (david@randombits.org)
---

--- Standard Modules
local application								= require("hs.application")
local ax 										= require("hs._asm.axuielement")
local log										= require("hs.logger").new("fcpxapp")

--- Local Modules
local UI										= require("hs.finalcutpro.ui")
local MenuBar									= require("hs.finalcutpro.MenuBar")
local PreferencesDialog							= require("hs.finalcutpro.PreferencesDialog")

--- The App module
local App = {}

--- Constants
App.BUNDLE_ID 							= "com.apple.FinalCut"
App.PASTEBOARD_UTI 						= "com.apple.flexo.proFFPasteboardUTI"

--- CONSTANTS

--- hs.finalcutpro.App:new(hs.application, axuielement) -> App
--- Function
--- Creates a new App instance representing Final Cut Pro
---
--- Parameters:
---  * ui			- The hs.finalcutpro.ui for the application
---
--- Returns:
---  * True is successful otherwise Nil
---
function App:new(ui)
	o = {
	  ui = ui,
	}
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
	return application(self.BUNDLE_ID) or nil
end

function App:ui()
	local fcp = self:application()
	if fcp then
		return UI:new(ax.applicationElement(fcp))
	else
		return nil
	end
end

function App:menuBar()
	if not self._menuBar then
		self._menuBar = MenuBar:new(self)
	end
	return self._menuBar
end

function App:preferencesDialog()
	if not self._preferencesDialog then
		self._preferencesDialog = PreferencesDialog:new(self)
	end
	return self._preferencesDialog
end

--- hs.finalcutpro.App:windowsUI() -> hs.finalcutpro.UI
--- Function
--- Returns the UI containing the list of windows in the app.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * The hs.finalcutpro.UI, or nil if the application is not running.
---
function App:windowsUI()
	return self:ui():attribute("AXWindows")
end

function App:_listWindows()
	log.d("Listing FCPX windows:")
	local windows = self:windowsUI()
	for i=1,windows:childCount() do
		local w = windows:childAt(i)
		log.d(i, ": title: ", w:attribute("AXTitle"), "; role: ", w:attribute("AXRole"), "; subrole: ", w:attribute("AXSubrole"),
			 "; modal: ", w:attribute("AXModal"))
	end
end

return App