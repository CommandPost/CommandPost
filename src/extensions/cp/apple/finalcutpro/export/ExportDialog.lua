--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.export.ExportDialog ===
---
--- Export Dialog Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("cp.apple.finalcutpro.axutils")
local just							= require("cp.just")

local SaveSheet						= require("cp.apple.finalcutpro.export.SaveSheet")
local WindowWatcher					= require("cp.apple.finalcutpro.ui.WindowWatcher")

local id							= require "cp.apple.finalcutpro.ids" "ExportDialog"

local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ExportDialog = {}

-- TODO: Add documentation
function ExportDialog.matches(element)
	if element then
		return element:attributeValue("AXSubrole") == "AXDialog"
		   and element:attributeValue("AXModal")
		   and axutils.childWithID(element, id "BackgroundImage") ~= nil
	end
	return false
end

-- TODO: Add documentation
function ExportDialog:new(app)
	local o = {_app = app}
	return prop.extend(o, ExportDialog)
end

-- TODO: Add documentation
function ExportDialog:app()
	return self._app
end

-- TODO: Add documentation
function ExportDialog:UI()
	return axutils.cache(self, "_ui", function()
		local windowsUI = self:app():windowsUI()
		return windowsUI and self:_findWindowUI(windowsUI)
	end,
	ExportDialog.matches)
end

-- TODO: Add documentation
function ExportDialog:_findWindowUI(windows)
	for i,window in ipairs(windows) do
		if ExportDialog.matches(window) then return window end
	end
	return nil
end

--- cp.apple.finalcutpro.export.ExportDialog.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the window showing?
ExportDialog.isShowing = prop.new(function(self)
	return self:UI() ~= nil
end):bind(ExportDialog)

-- Ensures the ExportDialog is showing
function ExportDialog:show()
	if not self:isShowing() then
		-- open the window
		if self:app():menuBar():isEnabled({"File", "Share", 1}) then
			self:app():menuBar():selectMenu({"File", "Share", 1})
			local ui = just.doUntil(function() return self:UI() end)
		end
	end
	return self
end

-- TODO: Add documentation
function ExportDialog:hide()
	self:pressCancel()
end

-- TODO: Add documentation
function ExportDialog:pressCancel()
	local ui = self:UI()
	if ui then
		local btn = ui:cancelButton()
		if btn then
			btn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function ExportDialog:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

-- TODO: Add documentation
function ExportDialog:pressNext()
	local ui = self:UI()
	if ui then
		local nextBtn = ui:defaultButton()
		if nextBtn then
			nextBtn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function ExportDialog:saveSheet()
	if not self._saveSheet then
		self._saveSheet = SaveSheet:new(self)
	end
	return self._saveSheet
end

-----------------------------------------------------------------------
--
-- WATCHERS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.export.ExportDialog:watch() -> string
--- Method
--- Watch for events that happen in the command editor. The optional functions will be called when the window is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(CommandEditor)` - Triggered when the window is shown.
---    * `hide(CommandEditor)` - Triggered when the window is hidden.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
function ExportDialog:watch(events)
	if not self._watcher then
		self._watcher = WindowWatcher:new(self)
	end

	self._watcher:watch(events)
end

-- TODO: Add documentation
function ExportDialog:unwatch(id)
	if self._watcher then
		self._watcher:unwatch(id)
	end
end

return ExportDialog