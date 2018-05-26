--- === cp.watcher ===
---
--- This extension provides support for setting up 'event watchers'.
---
--- For example, if you want to allow interested parties to watch for 'update'
--- events, you might have something like this:
---
--- ```lua
--- local thing = {}
---
--- thing.watchers = watcher.new('update')
---
--- thing.watch(events)
--- 	return thing.watchers:watch(events)
--- end
---
--- thing.update(value)
--- 	thing.value = value
--- 	thing.watchers:notify('update', value)
--- end
--- ```
---
--- Then, your other code could get notifications like so:
---
--- ```lua
--- thing.watch({
--- 	update = function(value) print "New value is "..value end
--- })
--- ```
---
--- Then, whenever `thing.update(xxx)` is called, the watcher will output `"New value is xxx"`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("watcher")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local uuid							= require("hs.host").uuid
local fnutils						= require("hs.fnutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}
mod.mt = {}

--- cp.watcher.new(...) -> watcher
--- Function
--- Constructs a new watcher instance.
---
--- Parameters:
---  * `...` - The list of event name strings supported by the watcher.
---
--- Returns:
---  * a new watcher instance
function mod.new(...)
    local o = {
        _events 		= table.pack(...),
        _watchers 		= {},
        _watchersCount 	= 0,
    }
    return setmetatable(o, { __index = mod.mt })
end

--- cp.watcher:events()
--- Method
--- Returns a list of the event names supported by this watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table of event names.
function mod.mt:events()
    return fnutils.copy(self._events)
end

-- cp.watcher:_prepareWatcher(events)
-- Private Method
-- Copies supported watcher functions from the events table.
--
-- Parameters:
--  * `events`	- The events passed by the user
--
-- Returns:
--  * The table of valid events that can be watched.
function mod.mt:_prepareWatcher(events)
    local watcher = {}
    for _,name in ipairs(self._events) do
        local fn = events[name]
        if fn and type(fn) == "function" then
            watcher[name] = fn
        end
    end
    return watcher
end

--- cp.watcher:watch(events) -> id
--- Method
--- Adds a watcher for the specified events.
---
--- Parameters:
---  * `events`		- A table of functions, one for each event to watch.
---
--- Returns:
--- * A unique ID that can be passed to `unwatch` to stop watching.
function mod.mt:watch(events)
    local id = uuid()
    self._watchers[id] = self:_prepareWatcher(events)
    self._watchersCount = self._watchersCount + 1
    return {id=id}
end

--- cp.watcher:unwatch(id) -> boolean
--- Method
--- Removes the watchers which were added with the specified ID.
---
--- Parameters:
---  * `id`		- The unique ID returned from `watch`.
---
--- Returns:
---  * `true` if a watcher with the specified ID exists and was successfully removed.
function mod.mt:unwatch(id)
    if self._watchers and id then
        if self._watchers[id.id] ~= nil then
            self._watchers[id.id] = nil
            self._watchersCount = self._watchersCount - 1
            return true
        end
    end
    return false
end

--- cp.watcher:notify(type, ...) -> nil
--- Method
--- Notifies watchers of the specified event type.
---
--- Parameters:
---  * `type`	- The event type to notify. Must be one of the supported events.
---  * `...`	- These parameters are passed directly to the event watcher functions.
---
--- Returns:
---  * Nothing.
function mod.mt:notify(type, ...)
    if self._watchers then
        for _,watcher in pairs(self._watchers) do
            if watcher[type] then
                watcher[type](...)
            end
        end
    end
end

--- cp.watcher:getCount()
--- Method
--- Returns the number of watchers currently registered.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The number of watchers.
function mod.mt:getCount()
    return self._watchersCount
end

return mod