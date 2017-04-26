--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.cmd.CommandEditor ===
---
--- Command Editor Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("cp.apple.finalcutpro.axutils")
local just							= require("cp.just")

local Button						= require("cp.apple.finalcutpro.ui.Button")
local WindowWatcher					= require("cp.apple.finalcutpro.ui.WindowWatcher")

local id							= require("cp.apple.finalcutpro.ids").current("CommandEditor")
local is							= require("cp.is")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local CommandEditor = {}

-- TODO: Add documentation
function CommandEditor.matches(element)
	if element then
		return element:attributeValue("AXSubrole") == "AXDialog"
		   and element:attributeValue("AXModal")
		   and axutils.childWith(element, "AXIdentifier", id "KeyDetailPanel") ~= nil
	end
	return false
end

-- TODO: Add documentation
function CommandEditor:new(app)
	o = {_app = app}
	
	-- TODO: Add documentation
	o.isShowing = is.new(function(self)
		return self:UI() ~= nil
	end):methodOf(o)
	
	return setmetatable(o, { __index = CommandEditor })
end

-- TODO: Add documentation
function CommandEditor:app()
	return self._app
end

-- TODO: Add documentation
function CommandEditor:UI()
	return axutils.cache(self, "_ui", function()
		local windowsUI = self:app():windowsUI()
		return windowsUI and self:_findWindowUI(windowsUI)
	end,
	CommandEditor.matches)
end

-- TODO: Add documentation
function CommandEditor:_findWindowUI(windows)
	for i,window in ipairs(windows) do
		if CommandEditor.matches(window) then return window end
	end
	return nil
end

-- TODO: Add documentation
-- Ensures the CommandEditor is showing
function CommandEditor:show()
	if not self:isShowing() then
		-- open the window
		if self:app():menuBar():isEnabled("Final Cut Pro", "Commands", "Customize…") then
			self:app():menuBar():selectMenu("Final Cut Pro", "Commands", "Customize…")
			local ui = just.doUntil(function() return self:UI() end)
		end
	end
	return self
end

-- TODO: Add documentation
function CommandEditor:hide()
	local ui = self:UI()
	if ui then
		local closeBtn = axutils.childWith(ui, "AXSubrole", "AXCloseButton")
		if closeBtn then
			closeBtn:doPress()
		end
	end
	return self
end

function CommandEditor:saveButton()
	if not self._saveButton then
		self._saveButton = Button:new(self, function()
			return axutils.childWithID(self:UI(), id "SaveButton")
		end)
	end
	return self._saveButton
end

-- TODO: Add documentation
function CommandEditor:save()
	local ui = self:UI()
	if ui then
		local saveBtn = axutils.childWith(ui, "AXIdentifier", id "SaveButton")
		if saveBtn and saveBtn:enabled() then
			saveBtn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function CommandEditor:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

--- cp.apple.finalcutpro.cmd.CommandEditor:watch() -> bool
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
function CommandEditor:watch(events)
	if not self._watcher then
		self._watcher = WindowWatcher:new(self)
	end

	self._watcher:watch(events)
end

-- TODO: Add documentation
function CommandEditor:unwatch(id)
	if self._watcher then
		self._watcher:unwatch(id)
	end
end

return CommandEditor