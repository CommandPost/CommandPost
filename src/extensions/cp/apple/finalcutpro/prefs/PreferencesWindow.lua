--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.prefs.PreferencesWindow ===
---
--- Preferences Window Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("cp.ui.axutils")
local just							= require("cp.just")
local prop							= require("cp.prop")

local PlaybackPanel					= require("cp.apple.finalcutpro.prefs.PlaybackPanel")
local ImportPanel					= require("cp.apple.finalcutpro.prefs.ImportPanel")

local id							= require("cp.apple.finalcutpro.ids") "PreferencesWindow"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PreferencesWindow = {}

function PreferencesWindow.matches(element)
	return element:attributeValue("AXSubrole") == "AXDialog"
		and not element:attributeValue("AXModal")
		and element:attributeValue("AXTitle") ~= ""
		and axutils.childWithRole(element, "AXToolbar") ~= nil
		and axutils.childWithRole(element, "AXGroup") ~= nil
end

-- TODO: Add documentation
function PreferencesWindow:new(app)
	local o = {_app = app}
	return prop.extend(o, PreferencesWindow)
end

-- TODO: Add documentation
function PreferencesWindow:app()
	return self._app
end

-- TODO: Add documentation
function PreferencesWindow:UI()
	return axutils.cache(self, "_ui", function()
		local windowsUI = self:app():windowsUI()
		return windowsUI and self:_findWindowUI(windowsUI)
	end)
end

-- TODO: Add documentation
function PreferencesWindow:_findWindowUI(windows)
	return axutils.childMatching(windows, PreferencesWindow.matches)
end

-- TODO: Add documentation
-- Returns the UI for the AXToolbar containing this panel's buttons
function PreferencesWindow:toolbarUI()
	return axutils.cache(self, "_toolbar", function()
		local ax = self:UI()
		return ax and axutils.childWith(ax, "AXRole", "AXToolbar") or nil
	end)
end

-- TODO: Add documentation
-- Returns the UI for the AXGroup containing this panel's elements
function PreferencesWindow:groupUI()
	return axutils.cache(self, "_group", function()
		local ui = self:UI()
		local group = ui and axutils.childWithRole(ui, "AXGroup")
		-- The group conains another single group that contains the actual checkboxes, etc.
		return group and #group == 1 and group[1]
	end)
end

-- TODO: Add documentation
function PreferencesWindow:playbackPanel()
	if not self._playbackPanel then
		self._playbackPanel = PlaybackPanel:new(self)
	end
	return self._playbackPanel
end

-- TODO: Add documentation
function PreferencesWindow:importPanel()
	if not self._importPanel then
		self._importPanel = ImportPanel:new(self)
	end
	return self._importPanel
end

-- TODO: Add documentation
PreferencesWindow.isShowing = prop.new(function(self)
	return self:UI() ~= nil
end):bind(PreferencesWindow)

-- TODO: Add documentation
-- Ensures the PreferencesWindow is showing
function PreferencesWindow:show()
	if not self:isShowing() then
		-- open the window
		if self:app():menuBar():isEnabled({"Final Cut Pro", "Preferences…"}) then
			self:app():menuBar():selectMenu({"Final Cut Pro", "Preferences…"})
			-- wait for it to open.
			local ui = just.doUntil(function() return self:UI() end)
		end
	end
	return self
end

-- TODO: Add documentation
function PreferencesWindow:hide()
	local ui = self:UI()
	if ui then
		local closeBtn = axutils.childWith(ui, "AXSubrole", "AXCloseButton")
		if closeBtn then
			closeBtn:doPress()
			-- wait for it to close
			just.doWhile(function() return self:isShowing() end, 5)
		end
	end
	return self
end

return PreferencesWindow