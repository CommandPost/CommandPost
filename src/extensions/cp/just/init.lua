--- === cp.just ===
---
--- This module provides functions to help with performing tasks which may be
--- delayed, up to a finite number of loops.

local require = require

local timer                 = require("hs.timer")

local secondsSinceEpoch     = timer.secondsSinceEpoch
local usleep                = timer.usleep

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local just = {}

--- cp.just.doWhile(actionFn[, timeout[, frequency]]) -> value
--- Function
--- Performs an 'action' function, looping while the result of the function evaluates to `true`.
--- It will halt after `timeout` seconds, checking with the specified `frequency`.
---
--- Parameters:
---  * `actionFn`	- a fuction which is called on each loop. It should return a 'truthy' value.
---  * `timeout`	- (optional) the number of seconds after which we will give up. Defaults to 1 second.
---  * `frequency`	- (optional) the time between checks. Defaults to 1 millisecond.
---
--- Returns:
---  * The last return value of the action function.
function just.doWhile(actionFn, timeout, frequency)
    timeout = timeout or 1.0
    frequency = frequency or 0.001

    local period = frequency * 1000000
    local stopTime = secondsSinceEpoch() + timeout

    local result = true
    while result and secondsSinceEpoch() < stopTime do
        result = actionFn()
        usleep(period)
    end
    return result
end

--- cp.just.doUntil(actionFn[, timeout[, frequency]]) -> value
--- Function
--- Performs an `action` function, looping until the result of the function evaluates to `true` (or a non-nil value).
--- It will halt after the `timeout` in seconds after checking every `frequency` seconds.
---
--- Parameters:
---  * `actionFn`	- a fuction which is called on each loop. It should return a 'truthy' value.
---  * `timeout`	- (optional) the number of seconds after which we will give up. Defaults to 1 second.
---  * `frequency`	- (optional) the amount of time between checks. Defaults to 1 millisecond.
---
--- Returns:
---  * The last return value of the action function.
function just.doUntil(actionFn, timeout, frequency)
    timeout = timeout or 1.0
    frequency = frequency or 0.001

    local period = frequency * 1000000
    local stopTime = secondsSinceEpoch() + timeout

    local result = false
    while not result and secondsSinceEpoch() < stopTime do
        result = actionFn()
        usleep(period)
    end
    return result
end

--- cp.just.wait(integer) -> nil
--- Function
--- Pauses the application for the specified number of seconds.
---
--- Parameters:
---  * periodInSeconds - the number of seconds to pause for.
---
--- Returns:
---  * None
function just.wait(periodInSeconds)
    usleep(periodInSeconds * 1000000)
end

return just
