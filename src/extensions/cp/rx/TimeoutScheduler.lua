--- === cp.rx.TimeoutScheduler ===
---
--- A scheduler that uses the `hs.timer` library to schedule events on an event loop.

local require           = require

local timer             = require "hs.timer"
local doAfter           = timer.doAfter

local Reference         = require "cp.rx.Reference"
local util              = require "cp.rx.util"

local TimeoutScheduler = {}
TimeoutScheduler.__index = TimeoutScheduler
TimeoutScheduler.__tostring = util.constant('TimeoutScheduler')

--- cp.rx.TimeoutScheduler.create() -> cp.rx.TimeoutScheduler
--- Method
--- Creates a new `TimeoutScheduler`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new `TimeoutScheduler`.
function TimeoutScheduler.create()
  return setmetatable({_timers = {}}, TimeoutScheduler)
end

--- cp.rx.TimeoutScheduler:schedule(action[, delay]) -> cp.rx.TimeoutScheduler
--- Method
--- Schedules an action to run at a future point in time.
---
--- Parameters:
---  * action  - The action to run.
---  * delay   - The delay, in milliseconds. Defaults to `0`.
---
--- Returns:
---  * The [Reference](cp.rx.Reference.md).
function TimeoutScheduler:schedule(action, delay)
  delay = delay or 0
  local t = doAfter(delay/1000.0, action)
  self._timers[t] = true

  return Reference.create(function()
    t:stop()
    self._timers[t] = nil
  end)
end

--- cp.rx.TimeoutScheduler:stopAll() -> nil
--- Method
--- Stops all future timers from running and clears them.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function TimeoutScheduler:stopAll()
    for t,_ in pairs(self._timers) do
        t:stop()
    end
    self._timers = {}
end

return TimeoutScheduler