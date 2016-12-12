local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local just							= require("hs.just")

local PreferencesDialog = {}

function PreferencesDialog:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function PreferencesDialog:app()
	return self._app
end

function PreferencesDialog:ui()
	if not self._ui then
		self._ui = self:_findWindow(self:app():windowsUI())
	end
	return self._ui
end

function PreferencesDialog:_findWindow(windows)
	for i = 1,windows:childCount() do
		local w = windows:childAt(i)
		if w:attribute("AXSubrole") == "AXDialog" 
			and not w:attribute("AXModal") 
			and w:attribute("AXTitle") ~= ""
			then
			-- Is a dialog and is not modal (Media Import is modal) and the title is not blank
			return w
		end
	end
	return nil
end

--- Ensures the PreferencesDialog is showing
function PreferencesDialog:show()
	local ui = self:ui()
	if not ui then
		-- open the window
		-- self:app():ensureIsRunning()
		self:app():menuBar():select("Final Cut Pro", "Preferences…")
		ui = just.doUntil(function() return self:ui() end)
	end
	
	return ui ~= nil
end

return PreferencesDialog