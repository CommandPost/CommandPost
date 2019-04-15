--- === cp.deferred ===
---
--- This extension makes it simple to defer multiple actions after a delay from the initial execution.
---  Unlike `hs.timer.delayed`, the delay will not be extended
--- with subsequent `run()` calls, but the delay will trigger again if `run()` is called again later.
---
--- For example:
---
--- ```lua
--- local update = deferred.new(1) -- defer 1 second
--- :action(function() print("Updated!"") end)
--- -- do something
--- update()
--- -- do something else
--- update()
--- -- one second after the inital call to `update()`, one "Updated!" is printed.
--- ```

local require = require
local delayed           = require("hs.timer").delayed

local is                = require("cp.is")

local isntCallable      = is.nt.callable
local insert            = table.insert


local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.deferred.new(delay) -> cp.deferred
--- Constructor
--- Creates a new `defer` instance, which will trigger any added `action`s by a set delay after
--- the initial call to `run()`.
---
--- Parameters:
--- * delay     - The number of seconds to delay when `run()` is initally called.
---
--- Returns:
--- * The new `cp.deferred` instance.
function mod.new(delay)
    local o ={
        _actions = {},
        _delay = delay,
    }

    o._timer = delayed.new(delay, function()
        for _,action in ipairs(o._actions) do
            action()
        end
    end)

    return setmetatable(o, mod.mt)
end

--- cp.deferred:action(actionFn) -> self
--- Method
--- Adds the `action` the the list that will be called when the timer goes off.
--- It must be a `function` (or callable `table`) with the following signature:
---
--- ```lua
--- function() -> nil
--- ```
---
--- Multiple actions can be added and they will all be called when the delay timer
--- goes off.
---
--- Parameters:
--- * The callable action.
function mod.mt:action(actionFn)
    if isntCallable(actionFn) then
        error("The action must be callable: %s", type(actionFn))
    end
    insert(self._actions, actionFn)
    return self
end

--- cp.deferred:run() -> self
--- Method
--- Ensures that the actions will run after the `delay`.
--- Multiple calls will not increase the delay from the initial call.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `cp.deferred` instance.
function mod.mt:run()
    local timer = self._timer
    if not timer:running() then
        timer:start()
    end
end

--- cp.deferred:waiting() -> boolean
--- Method
--- Checks if the defer is currently waiting to run.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the deferred action is waiting to execute.
function mod.mt:waiting()
    return self._timer:running()
end

--- cp.deferred:secondsRemaining() -> number | nil
--- Method
--- Returns the number of seconds until the next execution, or `nil` if it's not running.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The number of seconds until execution.
function mod.mt:secondsRemaining()
    return self._timer:nextTrigger()
end

--- cp.deferred:stop() -> self
--- Method
--- Stops any execution of any deferred actions, if it is currently running.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The deferred timer.
function mod.mt:stop()
    self._timer:stop()
    return self
end

--- cp.deferred:delay([value]) -> self | number
--- Method
--- Sets/gets the delay period. If no `value` is provided, the current delay is returned.
--- If it is provided, then the new delay will be set. If it is currently waiting, then
--- the wait will be restarted with the new delay.
---
--- Parameters:
--- * value     - the new delay value.
---
--- Returns:
--- * The `cp.deferred` instance if a new value is provided, or the current delay if not.
function mod.mt:delay(value)
    if value ~= nil then
        self._delay = value
        self._timer:setDelay(value)
        return self
    else
        return self._delay
    end
end

function mod.mt:__call()
    self:run()
end

return mod
