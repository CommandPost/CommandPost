--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.ui.WindowWatcher ===
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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local WindowWatcher = {}

--- cp.apple.finalcutpro.ui.WindowWatcher:new(windowFn) -> WindowWatcher
--- Method
--- Creates a new WindowWatcher
---
--- Parameters:
---  * `window` 	- the window object (eg. CommandEditor)
---
--- Returns:
---  * `WindowWatcher`	- the new WindowWatcher instance.
function WindowWatcher:new(window)
	o = {_window = window}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- cp.apple.finalcutpro.ui.WindowWatcher:watch() -> bool
--- Method
--- Watch for events that happen in the window
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(CommandEditor)` - Triggered when the window is shown.
---    * `hide(window)` - Triggered when the window is hidden.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
function WindowWatcher:watch(events)

	if not self._watchers then
		self._watchers = {}
	end

	self._watchers[#(self._watchers)+1] = {show = events.show, hide = events.hide}
	local id = {id=#(self._watchers)}

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Created:
	--------------------------------------------------------------------------------
	windowfilter:subscribe("windowVisible", function(window)
			local windowUI = axuielement.windowElement(window)
			if self._window:UI() == windowUI and self._window:isShowing() then
				self._windowID = window:id()
				for i,watcher in ipairs(self._watchers) do
					if watcher.show then
						watcher.show(self)
					end
				end
			end
		end,
		true
	)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Destroyed:
	--------------------------------------------------------------------------------
	windowfilter:subscribe("windowNotVisible", function(window)
			if window:id() == self._windowID then
				self._windowID = nil
				for i,watcher in ipairs(self._watchers) do
					if watcher.hide then
						watcher.hide(self)
					end
				end
			end
		end,
		true
	)

	return id
end

--- cp.apple.finalcutpro.ui.WindowWatcher:unwatch() -> bool
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