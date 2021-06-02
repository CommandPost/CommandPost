--- === cp.rx.ImmediateScheduler ===
---
--- Schedules `Observables` by running all operations immediately.

local require           = require

local Reference         = require "cp.rx.Reference"
local util              = require "cp.rx.util"

local ImmediateScheduler = {}
ImmediateScheduler.__index = ImmediateScheduler
ImmediateScheduler.__tostring = util.constant('ImmediateScheduler')

--- cp.rx.ImmediateScheduler.create() -> cp.rx.ImmediageScheduler
--- Constructor
--- Creates a new `ImmediateScheduler`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new `ImmediateScheduler`.
function ImmediateScheduler.create()
  return setmetatable({}, ImmediateScheduler)
end

--- cp.rx.ImmediateScheduler:schedule(action) -> cp.rx.Reference
--- Method
--- Schedules a `function` to be run on the scheduler. It is executed immediately.
---
--- Parameters:
---  * action    - The `function` to execute.
---
--- Returns:
---  * The [Reference](cp.rx.Reference.md).
function ImmediateScheduler:schedule(action) --luacheck: ignore
  action()
  return Reference.create()
end

return  ImmediateScheduler