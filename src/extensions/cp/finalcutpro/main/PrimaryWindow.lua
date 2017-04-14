--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Primary Window

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("primaryWindow")
local inspect						= require("hs.inspect")

local axutils						= require("cp.finalcutpro.axutils")
local just							= require("cp.just")

local Button						= require("cp.finalcutpro.ui.Button")
local WindowWatcher					= require("cp.finalcutpro.ui.WindowWatcher")

local Inspector						= require("cp.finalcutpro.main.Inspector")
local ColorBoard					= require("cp.finalcutpro.main.ColorBoard")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PrimaryWindow = {}

-- TODO: Add documentation
function PrimaryWindow.matches(w)
	return w and w:attributeValue("AXSubrole") == "AXStandardWindow"
end

-- TODO: Add documentation
function PrimaryWindow:new(app)
	o = {
		_app = app
	}
	setmetatable(o, self)
	self.__index = self

	return o
end

-- TODO: Add documentation
function PrimaryWindow:app()
	return self._app
end

-- TODO: Add documentation
function PrimaryWindow:isShowing()
	return self:UI() ~= nil
end

-- TODO: Add documentation
function PrimaryWindow:show()
	-- Currently a null-op. Determin if there are any scenarios where we need to force this.
	return true
end

-- TODO: Add documentation
function PrimaryWindow:UI()
	return axutils.cache(self, "_ui", function()
		local ui = self:app():UI()
		if ui then
			if PrimaryWindow.matches(ui:mainWindow()) then
				return ui:mainWindow()
			else
				local windowsUI = self:app():windowsUI()
				return windowsUI and self:_findWindowUI(windowsUI)
			end
		end
		return nil
	end,
	PrimaryWindow.matches)
end

-- TODO: Add documentation
function PrimaryWindow:_findWindowUI(windows)
	for i,w in ipairs(windows) do
		if PrimaryWindow.matches(w) then return w end
	end
	return nil
end

-- TODO: Add documentation
function PrimaryWindow:isFullScreen()
	local ui = self:UI()
	return ui and ui:fullScreen()
end

-- TODO: Add documentation
function PrimaryWindow:setFullScreen(isFullScreen)
	local ui = self:UI()
	if ui then ui:setFullScreen(isFullScreen) end
	return self
end

-- TODO: Add documentation
function PrimaryWindow:toggleFullScreen()
	local ui = self:UI()
	if ui then ui:setFullScreen(not self:isFullScreen()) end
	return self
end

-----------------------------------------------------------------------
--
-- UI STRUCTURE:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
-- The top AXSplitGroup contains the
function PrimaryWindow:rootGroupUI()
	return axutils.cache(self, "_rootGroup", function()
		local ui = self:UI()
		return ui and axutils.childWith(ui, "AXRole", "AXSplitGroup")
	end)
end

-- TODO: Add documentation
function PrimaryWindow:leftGroupUI()
	local root = self:rootGroupUI()
	if root then
		for i,child in ipairs(root) do
			-- the left group has only one child
			if #child == 1 then
				return child[1]
			end
		end
	end
	return nil
end

-- TODO: Add documentation
function PrimaryWindow:rightGroupUI()
	local root = self:rootGroupUI()
	if root and #root == 2 then
		if #(root[1]) >= 3 then
			return root[1]
		else
			return root[2]
		end
	end
	return nil
end

-- TODO: Add documentation
function PrimaryWindow:topGroupUI()
	local left = self:leftGroupUI()
	if left then
		if #left < 3 then
			-- Either top or bottom is visible.
			-- It's impossible to determine which it at this level, so just return the non-empty one
			for _,child in ipairs(left) do
				if #child > 0 then
					return child[1]
				end
			end
		elseif #left >= 3 then
			-- Both top and bottom are visible. Grab the highest AXGroup
			local top = nil
			for _,child in ipairs(left) do
				if child:attributeValue("AXRole") == "AXGroup" then
					if top == nil or top:frame().y > child:frame().y then
						top = child
					end
				end
			end
			if top then return top[1] end
		end
	end
	return nil
end

-- TODO: Add documentation
function PrimaryWindow:bottomGroupUI()
	local left = self:leftGroupUI()
	if left then
		if #left < 3 then
			-- Either top or bottom is visible.
			-- It's impossible to determine which it at this level, so just return the non-empty one
			for _,child in ipairs(left) do
				if #child > 0 then
					return child[1]
				end
			end
		elseif #left >= 3 then
			-- Both top and bottom are visible. Grab the lowest AXGroup
			local top = nil
			for _,child in ipairs(left) do
				if child:attributeValue("AXRole") == "AXGroup" then
					if top == nil or top:frame().y < child:frame().y then
						top = child
					end
				end
			end
			if top then return top[1] end
		end
	end
	return nil
end

-----------------------------------------------------------------------
--
-- INSPECTOR:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function PrimaryWindow:inspector()
	if not self._inspector then
		self._inspector = Inspector:new(self)
	end
	return self._inspector
end

-----------------------------------------------------------------------
--
-- COLOR BOARD:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function PrimaryWindow:colorBoard()
	if not self._colorBoard then
		self._colorBoard = ColorBoard:new(self)
	end
	return self._colorBoard
end

-----------------------------------------------------------------------
--
-- VIEWER:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function PrimaryWindow:viewerGroupUI()
	return self:topGroupUI()
end

-----------------------------------------------------------------------
--
-- TIMELINE GROUP UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function PrimaryWindow:timelineGroupUI()
	return self:bottomGroupUI()
end

-----------------------------------------------------------------------
--
-- BROWSER:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function PrimaryWindow:browserGroupUI()
	return self:topGroupUI()
end

-----------------------------------------------------------------------
--
-- WATCHERS:
--
-----------------------------------------------------------------------

--- cp.finalcutpro:main:PrimaryWindow:watch() -> string
--- Method
--- Watch for events that happen in the command editor
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
--- * `events` - A table of functions with to watch. These may be:
--- 	* `show(CommandEditor)` - Triggered when the window is shown.
--- 	* `hide(CommandEditor)` - Triggered when the window is hidden.
---
--- Returns:
--- * An ID which can be passed to `unwatch` to stop watching.
function PrimaryWindow:watch(events)
	if not self._watcher then
		self._watcher = WindowWatcher:new(self)
	end

	self._watcher:watch(events)
end

-- TODO: Add documentation
function PrimaryWindow:unwatch(id)
	if self._watcher then
		self._watcher:unwatch(id)
	end
end

return PrimaryWindow