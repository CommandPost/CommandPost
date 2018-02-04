--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Window ===
---
--- A Window UI element.

local log							= require("hs.logger").new("button")
local inspect						= require("hs.inspect")

local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")
local hswindow						= require("hs.window")
local hswindowfilter				= require("hs.window.filter")

hswindowfilter.setLogLevel("error") -- The wfilter errors are too annoying.
local filter = hswindowfilter.new()

-- _watch(event, window, ...)
-- Private Function
-- Adds a window.filter that will update the provided property if the window matches.
--
-- Parameter:
--  * `event`		- The event to watch for (eg `hs.window.filter.windowCreated`)
--  * `window`		- The `Window` instance
--  * `property`	- The set of `hs.param` values to update.
local function _watch(event, window, property)
	assert(event ~= nil)
	assert(window ~= nil, event)
	assert(property ~= nil, event)
	filter:subscribe(event, function(hsWindow)
		if window:id() == hsWindow:id() then
			property:update()
		end
	end, true)
end

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Window = {}

--- cp.ui.Window.matches(element) -> boolean
--- Function
--- Checks if the provided element is a valid window.
function Window.matches(element)
	return element and element:attributeValue("AXRole") == "AXWindow"
end

--- cp.ui.Window:new(finderFn) -> Window
--- Constructor
--- Creates a new Window
---
--- Parameters:
---  * `finderFn`	- a function which will provide the `axuielement` for the window to work with.
---
--- Returns:
---  * A new `Window` instance.
function Window:new(finderFn)
	assert(finderFn, "Please provide a finder function.")
	local o = {_finder = finderFn}
	prop.extend(o, Window)

	-- Window Visible:
	_watch(hswindowfilter.windowVisible, o, o.visible)

	-- Window Not Visisble:
	_watch(hswindowfilter.windowNotVisible, o, o.visible)

	-- Window Created:
	_watch(hswindowfilter.windowCreated, o, o.UI)

	-- Window Destroyed:
	_watch(hswindowfilter.windowDestroyed, o, o.UI)

	-- Window Moved:
	_watch(hswindowfilter.windowMoved, o, o.frame)

	-- Window Focused:
	_watch(hswindowfilter.windowFocused, o, o.focused)

	-- Window Full-Screened:
	_watch(hswindowfilter.windowFullscreened, o, o.fullScreen)

	return o
end

--- cp.ui.Window.UI <cp.prop: axuielement; read-only>
--- Field
--- Returns the `axuielement` UI for the window, or `nil` if it can't be found.
Window.UI = prop(
	function(self)
		return axutils.cache(self, "_ui", function()
			return self._finder()
		end,
		Window.matches)
	end
):bind(Window)

--- cp.ui.Window.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
Window.hsWindow = Window.UI:mutate(
	function(original, self)
		local ui = original()
		return ui and ui:asHSWindow()
	end
):bind(Window)

--- cp.ui.Window.id <cp.prop: number; read-only>
--- Field
--- The unique ID for the window.
Window.id = Window.hsWindow:mutate(
	function(original)
		local window = original()
		return window ~= nil and window:id()
	end
):bind(Window)

--- cp.ui.Window.visible <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the window is visible on a screen.
Window.visible = Window.hsWindow:mutate(
	function(original)
		local window = original()
		return window ~= nil and window:isVisible()
	end
):bind(Window)

--- cp.ui.Window.focused <cp.prop: boolean>
--- Field
--- Is `true` if the window has mouse/keyboard focused.
--- Note: Setting to `false` has no effect, since 'defocusing' isn't definable.
Window.focused = Window.hsWindow:mutate(
	function(original)
		return original() == hswindow.focusedWindow()
	end,
	function(focused, original)
		local window = original()
		if window and focused then
			window:focus()
		end
	end
):bind(Window)

--- cp.ui.Window.exists <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the window exists. It may not be visible.
Window.exists = Window.UI:mutate(
	function(ui)
		return ui ~= nil
	end
):bind(Window)

--- cp.ui.Window.minimized <cp.prop: boolean>
--- Field
--- Returns `true` if the window exists and is minimised.
Window.minimized = Window.hsWindow:mutate(
	function(original)
		local window = original()
		return window ~= nil and window:isMinimized()
	end,
	function(minimized, original)
		local window = original()
		if window then
			if minimized then
				window:minimize()
			else
				window:unminimize()
			end
		end
	end
):bind(Window)

--- cp.ui.Window.frame <cp.prop: hs.geometry rect>
--- Field
--- The `hs.geometry` rect value describing the window's position.
Window.frame = Window.hsWindow:mutate(
	function(original)
		local window = original()
		return window and window:frame()
	end,
	function(frame, original)
		local window = original()
		if window then
			window:move(frame)
		end
		return window
	end
):bind(Window)

--- cp.ui.Window.fullScreen <cp.prop: boolean>
--- Field
--- Returns `true` if the window is full-screen.
Window.fullScreen = Window.hsWindow:mutate(
	function(original)
		local window = original()
		return window and window:isFullScreen()
	end,
	function(window, fullScreen)
		if window then
			window:setFullScreen(fullScreen)
		end
		return window
	end
):bind(Window)

--- cp.ui.Window.close() -> boolean
--- Method
--- Attempts to close the window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the window was successfully closed.
function Window:close()
	local hsWindow = self:hsWindow()
	return hsWindow ~= nil and hsWindow:close()
end

--- cp.ui.Window.focus() -> boolean
--- Method
--- Attempts to focus the window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the window was successfully focused.
function Window:focus()
	local hsWindow = self:hsWindow()
	return hsWindow ~= nil and hsWindow:focus()
end

return Window