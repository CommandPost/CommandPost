--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.PrimaryWindow ===
---
--- Primary Window Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("primaryWindow")
local inspect						= require("hs.inspect")

local axutils						= require("cp.ui.axutils")
local just							= require("cp.just")
local prop							= require("cp.prop")

local Button						= require("cp.ui.Button")
local Window						= require("cp.ui.Window")
local WindowWatcher					= require("cp.apple.finalcutpro.WindowWatcher")

local Inspector						= require("cp.apple.finalcutpro.main.Inspector")
local ColorBoard					= require("cp.apple.finalcutpro.main.ColorBoard")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PrimaryWindow = {}

-- TODO: Add documentation
function PrimaryWindow.matches(w)
	local subrole = w:attributeValue("AXSubrole")
	return w and w:attributeValue("AXTitle") == "Final Cut Pro" and (subrole == "AXStandardWindow" or subrole == "AXDialog")
end

-- TODO: Add documentation
function PrimaryWindow:new(app)
	local o = {
		_app = app
	}
	prop.extend(o, PrimaryWindow)
	
	local window = Window:new(function()
		return axutils.cache(self, "_ui", function()
			return axutils.childMatching(app:windowsUI(), PrimaryWindow.matches)
		end,
		PrimaryWindow.matches)
	end)
	o._window = window
	
--- cp.apple.finalcutpro.main.PrimaryWindow.UI <cp.prop: axuielement; read-only>
--- Field
--- The `axuielement` for the window.
	o.UI = window.UI:wrap(o)
	
--- cp.apple.finalcutpro.main.PrimaryWindow.isShowing <cp.prop: boolean>
--- Field
--- Is `true` if the window is visible.
	o.isShowing = window.visible:wrap(o)
	
--- cp.apple.finalcutpro.main.PrimaryWindow.isFullScreen <cp.prop: boolean>
--- Field
--- Is `true` if the window is full-screen.
	o.isFullScreen = window.fullScreen:wrap(o)
	
--- cp.apple.finalcutpro.main.PrimaryWindow.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
	o.frame = window.frame:wrap(o)
	
	return o
end

--- cp.apple.finalcutpro.main.PrimaryWindow:app() -> hs.application
--- Method
--- Returns the application the display belongs to.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The app instance.
function PrimaryWindow:app()
	return self._app
end

--- cp.apple.finalcutpro.main.PrimaryWindow:window() -> cp.ui.Window
--- Method
--- Returns the `Window` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Window` instance.
function PrimaryWindow:window()
	return self._window
end

--- cp.apple.finalcutpro.main.PrimaryWindow:show() -> PrimaryWindow
--- Method
--- Attempts to focus the specified window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the window exists and 
function PrimaryWindow:show()
	if self:isShowing() then
		return true
	else
		return self:window():focus()
	end
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

--- cp.apple.finalcutpro.main.PrimaryWindow:watch() -> string
--- Method
--- Watch for events that happen in the command editor
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(window)` - Triggered when the window is shown.
---    * `hide(window)` - Triggered when the window is hidden.
---    * `move(window)` - Triggered when the window is moved.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
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