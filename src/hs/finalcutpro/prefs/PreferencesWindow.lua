local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local just							= require("hs.just")

local PlaybackPanel					= require("hs.finalcutpro.prefs.PlaybackPanel")
local ImportPanel					= require("hs.finalcutpro.prefs.ImportPanel")

local PreferencesWindow = {}

function PreferencesWindow:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function PreferencesWindow:app()
	return self._app
end

function PreferencesWindow:UI()
	if not self._ui then
		self._ui = self:_findWindowUI(self:app():windowsUI())
	end
	return self._ui
end

function PreferencesWindow:_findWindowUI(windows)
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

function PreferencesWindow:toolbarUI()
	local ui = self:UI()
	return ui and ui:childWithRole("AXToolbar") or nil
end

function PreferencesWindow:playbackPanel()
	if not self._playbackPanel then
		self._playbackPanel = PlaybackPanel:new(self)
	end
	return self._playbackPanel
end

function PreferencesWindow:importPanel()
	if not self._importPanel then
		self._importPanel = ImportPanel:new(self)
	end
	return self._importPanel
end

function PreferencesWindow:isShowing()
	return self:UI() ~= nil
end

--- Ensures the PreferencesWindow is showing
function PreferencesWindow:show()
	if self:app():isRunning() and not self:isShowing() then
		-- open the window
		-- self:app():ensureIsRunning()
		self:app():menuBar():select("Final Cut Pro", "Preferences…")
		ui = just.doUntil(function() return self:UI() end)
		return ui ~= nil
	end
	return true
end

function PreferencesWindow:hide()
	local ui = self:UI()
	if ui then
		local closeBtn = ui:childWithSubrole("AXCloseButton")
		if closeBtn then
			closeBtn:press()
			return true
		end
	end
	return false
end

return PreferencesWindow