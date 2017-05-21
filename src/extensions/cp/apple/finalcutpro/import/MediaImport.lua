--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.import.MediaImport ===
---
--- Media Import

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("PrefsDlg")

local just							= require("cp.just")
local prop							= require("cp.prop")

local axutils						= require("cp.apple.finalcutpro.axutils")
local id							= require("cp.apple.finalcutpro.ids") "MediaImporter"
local WindowWatcher					= require("cp.apple.finalcutpro.ui.WindowWatcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MediaImport = {}

-- TODO: Add documentation
function MediaImport.matches(element)
	if element then
		return element:attributeValue("AXSubrole") == "AXDialog"
		   and element:attributeValue("AXMain")
		   and element:attributeValue("AXModal")
		   and axutils.childWith(element, "AXIdentifier", id "MainPanel") ~= nil
	end
	return false
end

-- TODO: Add documentation
function MediaImport:new(app)
	local o = {_app = app}
	return prop.extend(o, MediaImport)
end

-- TODO: Add documentation
function MediaImport:app()
	return self._app
end

-- TODO: Add documentation
function MediaImport:UI()
	return axutils.cache(self, "_ui", function()
		local windowsUI = self:app():windowsUI()
		return windowsUI and self:_findWindowUI(windowsUI)
	end,
	MediaImport.matches)
end

-- TODO: Add documentation
function MediaImport:_findWindowUI(windows)
	for i,window in ipairs(windows) do
		if MediaImport.matches(window) then return window end
	end
	return nil
end

--- cp.apple.finalcutpro.import.MediaImport.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the Media Import window showing?
MediaImport.isShowing = prop.new(function(self)
	return self:UI() ~= nil
end):bind(MediaImport)

-- TODO: Add documentation
-- Ensures the MediaImport is showing
function MediaImport:show()
	if not self:isShowing() then
		-- open the window
		if self:app():menuBar():isEnabled({"File", "Import", "Media…"}) then
			self:app():menuBar():selectMenu({"File", "Import", "Media…"})
			local ui = just.doUntil(function() return self:isShowing() end)
		end
	end
	return self
end

-- TODO: Add documentation
function MediaImport:hide()
	local ui = self:UI()
	if ui then
		local closeBtn = ui:closeButton()
		if closeBtn then
			closeBtn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function MediaImport:importAll()
	local ui = self:UI()
	if ui then
		local btn = ui:defaultButton()
		if btn and btn:enabled() then
			btn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function MediaImport:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

-----------------------------------------------------------------------
--
-- WATCHERS
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.import.MediaImport:watch() -> bool
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
function MediaImport:watch(events)
	if not self._watcher then
		self._watcher = WindowWatcher:new(self)
	end

	self._watcher:watch(events)
end

function MediaImport:unwatch(id)
	if self._watcher then
		self._watcher:unwatch(id)
	end
end

return MediaImport