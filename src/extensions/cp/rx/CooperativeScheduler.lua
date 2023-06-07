--- === cp.rx.CooperativeScheduler ===
---
--- Manages [Observables](cp.rx.Observer.md) using `coroutines` and a virtual clock that must be updated
--- manually.

local require           = require

local Reference         = require "cp.rx.Reference"
local util              = require "cp.rx.util"

local insert              = table.insert
local remove              = table.remove

local CooperativeScheduler = {}
CooperativeScheduler.__index = CooperativeScheduler
CooperativeScheduler.__tostring = util.constant('CooperativeScheduler')

--- cp.rx.CooperativeScheduler.create([currentTime]) -> cp.rx.CooperativeScheduler
--- Constructor
--- Creates a new `CooperativeScheduler`.
---
--- Parameters:
---  * currentTime     - A time to start the scheduler at. Defaults to `0`.
---
--- Returns:
---  * The new `CooperativeScheduler`.
function CooperativeScheduler.create(currentTime)
  local self = {
    tasks = {},
    currentTime = currentTime or 0
  }

  return setmetatable(self, CooperativeScheduler)
end

--- cp.rx.CooperativeScheduler:schedule(action[, delay]) -> cp.rx.Reference
--- Method
--- Schedules a `function` to be run after an optional delay.  Returns a [Reference](cp.rx.Reference.md) that will stop the action from running.
---
--- Parameters:
---  * action - The `function` to execute. Will be converted into a coroutine. The coroutine may yield execution back to the scheduler with an optional number, which will put it to sleep for a time period.
---  * delay - Delay execution of the action by a virtual time period. Defaults to `0`.
---
--- Returns:
---  * The [Reference](cp.rx.Reference.md).
function CooperativeScheduler:schedule(action, delay)
  local task = {
    thread = coroutine.create(action),
    due = self.currentTime + (delay or 0)
  }

  insert(self.tasks, task)

  return Reference.create(function()
    return self:unschedule(task)
  end)
end

function CooperativeScheduler:unschedule(task)
  for i = 1, #self.tasks do
    if self.tasks[i] == task then
      remove(self.tasks, i)
    end
  end
end

--- cp.rx.CooperativeScheduler:update(delta) -> nil
--- Method
--- Triggers an update of the `CooperativeScheduler`. The clock will be advanced and the scheduler will run any coroutines that are due to be run.
---
--- Parameters:
---  * delta - An amount of time to advance the clock by. It is common to pass in the time in seconds or milliseconds elapsed since this function was last called. Defaults to `0`.
---
--- Returns:
---  * None
function CooperativeScheduler:update(delta)
  self.currentTime = self.currentTime + (delta or 0)

  local i = 1
  while i <= #self.tasks do
    local task = self.tasks[i]

    if self.currentTime >= task.due then
      local success, delay = coroutine.resume(task.thread)

      if coroutine.status(task.thread) == 'dead' then
        remove(self.tasks, i)
      else
        task.due = math.max(task.due + (delay or 0), self.currentTime)
        i = i + 1
      end

      if not success then
        error(delay)
      end
    else
      i = i + 1
    end
  end
end

--- cp.rx.CooperativeScheduler:isEmpth() -> cp.rx.CooperativeScheduler
--- Method
--- Returns whether or not the `CooperativeScheduler`'s queue is empty.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the scheduler is empty, otherwise `false`.
function CooperativeScheduler:isEmpty()
  return not next(self.tasks)
end

return CooperativeScheduler