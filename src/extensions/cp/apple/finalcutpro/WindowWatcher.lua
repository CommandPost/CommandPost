--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.WindowWatcher ===
---
--- Window Watcher Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("windowWatcher")

local windowfilter					= require("cp.apple.finalcutpro.windowfilter")
local axuielement					= require("hs._asm.axuielement")
local watcher						= require("cp.watcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local WindowWatcher = {}

--- cp.apple.finalcutpro.WindowWatcher:new(windowFn) -> WindowWatcher
--- Method
--- Creates a new WindowWatcher
---
--- Parameters:
---  * `window` 	- the window object (eg. CommandEditor)
---
--- Returns:
---  * `WindowWatcher`	- the new WindowWatcher instance.
function WindowWatcher:new(window)
	local o = {_window = window}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- cp.apple.finalcutpro.WindowWatcher:watch() -> bool
--- Method
--- Watch for events that happen in the window
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(window)` - Triggered when the window is shown.
---    * `hide(window)` - Triggered when the window is hidden.
---    * `open(window)` - Triggered when the window is opened.
---    * `close(window)` - Triggered when the window is closed.
---    * `move(window)` - Triggered when the window is moved.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
function WindowWatcher:watch(events)

	if not self._watchers then
		self._watchers = watcher.new("show", "hide", "move", "open", "close")
	end

	local id = self._watchers:watch(events)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Made Visible:
	--------------------------------------------------------------------------------
	windowfilter:subscribe("windowVisible", function(window)
		local windowUI = axuielement.windowElement(window)
		if self._window:UI() == windowUI then
			self._watchers:notify("show", self._window)
		end
	end,
	true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Not Visisble:
	--------------------------------------------------------------------------------
	windowfilter:subscribe("windowNotVisible", function(window)
		local windowUI = axuielement.windowElement(window)
		if self._window:UI() == windowUI then
			self._watchers:notify("hide", self._window)
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Created:
	--------------------------------------------------------------------------------
	windowfilter:subscribe("windowCreated", function(window)
		local windowUI = axuielement.windowElement(window)
		if self._window:UI() == windowUI then
			self._watchers:notify("open", self._window)
		end
	end, true)
	
	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Destroyed:
	--------------------------------------------------------------------------------
	windowfilter:subscribe("windowDestroyed", function(window)
		local windowUI = axuielement.windowElement(window)
		if self._window:UI() == windowUI then
			self._watchers:notify("close", self._window)
		end
	end,
	true)
	
	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Destroyed:
	--------------------------------------------------------------------------------
	windowfilter:subscribe("windowMoved", function(window)
		local windowUI = axuielement.windowElement(window)
		if self._window:UI() == windowUI then
			self._watchers:notify("move", self._window)
		end
	end, true)

	return id
end

--- cp.apple.finalcutpro.WindowWatcher:unwatch() -> bool
--- Method
--- Removes the watch with the specified ID
---
--- Parameters:
---  * `id` - The ID returned from `watch` that wants to be removed.
---
--- Returns:
---  * None
function WindowWatcher:unwatch(id)
	local watchers = self._watchers
	if id and id.id and watchers and watchers[id.id] then
		table.remove(watchers, id.id)
	end
end

return WindowWatcher