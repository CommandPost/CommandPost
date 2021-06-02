
--- === cp.rx.Reference ===
---
--- A handle representing the link between an [Observer](cp.rx.Observer.md) and an [Observable](cp.rx.Observable.md), as well as any
--- work required to clean up after the Observable completes or the Observer cancels.

local require           = require

local util              = require "cp.rx.util"

local Reference = {}
Reference.__index = Reference
Reference.__tostring = util.constant('Reference')

--- cp.rx.Reference.create(action) -> cp.rx.Reference
--- Constructor
--- Creates a new Reference.
---
--- Parameters:
---  * action - The action to run when the reference is canceld. It will only be run once.
---
--- Returns:
---  * the [Reference](cp.rx.Reference.md).
function Reference.create(action)
  local self = {
    action = action or util.noop,
    cancelled = false
  }

  return setmetatable(self, Reference)
end

--- cp.rx.Reference:cancel() -> nil
--- Method
--- Unsubscribes the reference, performing any necessary cleanup work.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
function Reference:cancel()
  if self.cancelled then return end
  self.action(self)
  self.cancelled = true
end

return Reference