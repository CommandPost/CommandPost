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

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("primaryWindow")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

local Alert							= require("cp.ui.Alert")
local Window						= require("cp.ui.Window")

local WindowWatcher					= require("cp.apple.finalcutpro.WindowWatcher")

local Inspector						= require("cp.apple.finalcutpro.inspector.Inspector")
local PrimaryToolbar				= require("cp.apple.finalcutpro.main.PrimaryToolbar")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PrimaryWindow = {}

--- cp.apple.finalcutpro.main.PrimaryWindow.matches(w) -> boolean
--- Function
--- Checks to see if a window matches the PrimaryWindow requirements
---
--- Parameters:
---  * w - The window to check
---
--- Returns:
---  * `true` if matched otherwise `false`
function PrimaryWindow.matches(w)
	local subrole = w:attributeValue("AXSubrole")
	return w and w:attributeValue("AXTitle") == "Final Cut Pro" and (subrole == "AXStandardWindow" or subrole == "AXDialog")
end

--- cp.apple.finalcutpro.main.PrimaryWindow:new(app) -> PrimaryWindow object
--- Method
--- Creates a new PrimaryWindow.
---
--- Parameters:
---  * None
---
--- Returns:
---  * PrimaryWindow
function PrimaryWindow:new(app)
	local o = prop.extend({
		_app = app
	}, PrimaryWindow)

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

--- cp.apple.finalcutpro.main.PrimaryWindow.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
	o.hsWindow = window.hsWindow:wrap(o)

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
---  * The `PrimaryWindow` instance.
function PrimaryWindow:show()
	self:app():show()
	if not self:isShowing() then
		return self:window():focus()
	end
	return self
end

-----------------------------------------------------------------------
--
-- UI STRUCTURE:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow:rootGroupUI() -> hs._asm.axuielement object
--- Method
--- Returns the top AXSplitGroup as a `hs._asm.axuielement` object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function PrimaryWindow:rootGroupUI()
	return axutils.cache(self, "_rootGroup", function()
		local ui = self:UI()
		return ui and axutils.childWith(ui, "AXRole", "AXSplitGroup")
	end)
end

--- cp.apple.finalcutpro.main.PrimaryWindow:leftGroupUI() -> hs._asm.axuielement object
--- Method
--- Returns the left group UI as a `hs._asm.axuielement` object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function PrimaryWindow:leftGroupUI()
	local root = self:rootGroupUI()
	if root then
		for _,child in ipairs(root) do
			-----------------------------------------------------------------------
			-- The left group has only one child:
			-----------------------------------------------------------------------
			if #child == 1 then
				return child[1]
			end
		end
	end
	return nil
end

--- cp.apple.finalcutpro.main.PrimaryWindow:rightGroupUI() -> hs._asm.axuielement object
--- Method
--- Returns the right group UI as a `hs._asm.axuielement` object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function PrimaryWindow:rightGroupUI()
	local root = self:rootGroupUI()
	if root and #root >= 3 then -- NOTE: Chris changed from "== 3" to ">= 3" because this wasn't working with FCPX 10.4 as there seems to be two AXSplitters.
		if #(root[1]) >= 3 then
			return root[1]
		else
			return root[2]
		end
	end
	return nil
end

--- cp.apple.finalcutpro.main.PrimaryWindow:topGroupUI() -> hs._asm.axuielement object
--- Method
--- Returns the top group UI as a `hs._asm.axuielement` object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function PrimaryWindow:topGroupUI()
	local left = self:leftGroupUI()
	if left then
		if #left < 3 then
			-----------------------------------------------------------------------
			-- Either top or bottom is visible.
			-- It's impossible to determine which it at this level,
			-- so just return the non-empty one:
			-----------------------------------------------------------------------
			for _,child in ipairs(left) do
				if #child > 0 then
					return child[1]
				end
			end
		elseif #left >= 3 then
			-----------------------------------------------------------------------
			-- Both top and bottom are visible. Grab the highest AXGroup:
			-----------------------------------------------------------------------
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

--- cp.apple.finalcutpro.main.PrimaryWindow:bottomGroupUI() -> hs._asm.axuielement object
--- Method
--- Returns the bottom group UI as a `hs._asm.axuielement` object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function PrimaryWindow:bottomGroupUI()
	local left = self:leftGroupUI()
	if left then
		if #left < 3 then
			-----------------------------------------------------------------------
			-- Either top or bottom is visible.
			-- It's impossible to determine which it at this level,
			-- so just return the non-empty one:
			-----------------------------------------------------------------------
			for _,child in ipairs(left) do
				if #child > 0 then
					return child[1]
				end
			end
		elseif #left >= 3 then
			-----------------------------------------------------------------------
			-- Both top and bottom are visible. Grab the lowest AXGroup:
			-----------------------------------------------------------------------
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

--- cp.apple.finalcutpro.main.PrimaryWindow:inspector() -> Inspector
--- Method
--- Gets the Inspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Inspector
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

--- cp.apple.finalcutpro.main.PrimaryWindow:colorBoard() -> ColorBoard
--- Method
--- Gets the ColorBoard object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard
function PrimaryWindow:colorBoard()
	return self:inspector():color():colorBoard()
end

-----------------------------------------------------------------------
--
-- VIEWER:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow:viewerGroupUI() -> hs._asm.axuielement object
--- Method
--- Returns the viewer group UI as a `hs._asm.axuielement` object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function PrimaryWindow:viewerGroupUI()
	return self:topGroupUI()
end

-----------------------------------------------------------------------
--
-- TIMELINE GROUP UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow:timelineGroupUI() -> hs._asm.axuielement object
--- Method
--- Returns the timeline group UI as a `hs._asm.axuielement` object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function PrimaryWindow:timelineGroupUI()
	return self:bottomGroupUI()
end

-----------------------------------------------------------------------
--
-- BROWSER:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow:browserGroupUI() -> hs._asm.axuielement object
--- Method
--- Returns the browser group UI as a `hs._asm.axuielement` object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function PrimaryWindow:browserGroupUI()
	return self:topGroupUI()
end

--- cp.apple.finalcutpro.main.PrimaryWindow:toolbar() -> PrimaryToolbar
--- Method
--- Returns the PrimaryToolbar element.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `PrimaryToolbar`.
function PrimaryWindow:toolbar()
	if not self._toolbar then
		self._toolbar = PrimaryToolbar:new(self)
	end
	return self._toolbar
end

-----------------------------------------------------------------------
--
-- BROWSER:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow:alert() -> cp.ui.Alert
--- Method
--- Provides access to any 'Alert' windows on the PrimaryWindow.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `cp.ui.Alert` object
function PrimaryWindow:alert()
	if not self._alert then
		self._alert = Alert:new(self)
	end
	return self._alert
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
	return self._watcher:watch(events)
end

--- cp.apple.finalcutpro.main.PrimaryWindow:unwatch() -> string
--- Method
--- Un-watches an event based on the specified ID.
---
--- Parameters:
---  * `id` - An ID has returned by `watch`
---
--- Returns:
---  * None
function PrimaryWindow:unwatch(id)
	if self._watcher then
		self._watcher:unwatch(id)
	end
end

return PrimaryWindow