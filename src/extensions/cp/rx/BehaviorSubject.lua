--- === cp.rx.BehaviorSubject ===
---
--- A [Subject](cp.rx.Subject.md) that tracks its current value. Provides an accessor to retrieve the most
--- recent pushed value, and all subscribers immediately receive the latest value.
local require           = require

local Observer          = require "cp.rx.Observer"
local Subject           = require "cp.rx.Subject"
local util              = require "cp.rx.util"

local BehaviorSubject = setmetatable({}, Subject)
BehaviorSubject.__index = BehaviorSubject
BehaviorSubject.__tostring = util.constant('BehaviorSubject')

--- cp.rx.BehaviorSubject.create(...) -> cp.rx.BehaviorSubject
--- Method
--- Creates a new `BehaviorSubject`.
---
--- Parameters:
---  * ...     - The initial values.
---
--- Returns:
---  * The new `BehaviorSubject`.
function BehaviorSubject.create(...)
  local self = {
    observers = {},
    stopped = false
  }

  if select('#', ...) > 0 then
    self.value = util.pack(...)
  end

  return setmetatable(self, BehaviorSubject)
end

--- cp.rx.BehaviorSubject:subscribe(observer | onNext, onError, onCompleted) -> cp.rx.Reference
--- Method
--- Creates a new [Observer](cp.rx.Observer.md) and attaches it to the `BehaviorSubject`. Immediately broadcasts the most
--- recent value to the [Observer](cp.rx.Observer.md).
---
--- Parameters:
---  * observer | onNext       - The [Observer](cp.rx.Observer.md) subscribing, or the `function` called when the
---                             `BehaviorSubject` produces a value.
---  * onError                 - A `function` called when the `BehaviorSubject` terminates due to an error.
---  * onCompleted             - A `function` called when the `BehaviorSubject` completes normally.
---
--- Returns:
---  * The [Reference](cp.rx.Reference.md)
function BehaviorSubject:subscribe(onNext, onError, onCompleted)
  local observer

  if util.isa(onNext, Observer) then
    observer = onNext
  else
    observer = Observer.create(onNext, onError, onCompleted)
  end

  local reference = Subject.subscribe(self, observer)

  if self.value then
    observer:onNext(util.unpack(self.value))
  end

  return reference
end

--- cp.rx.BehaviorSubject:onNext(...) -> nil
--- Method
--- Pushes zero or more values to the `BehaviorSubject`. They will be broadcasted to all [Observers](cp.rx.Observer.md).
---
--- Parameters:
---  * ...     - The values to send.
function BehaviorSubject:onNext(...)
  self.value = util.pack(...)
  return Subject.onNext(self, ...)
end

--- cp.rx.BehaviorSubject:getValue() -> anything
--- Method
--- Returns the last value emitted by the `BehaviorSubject`, or the initial value passed to the
--- constructor if nothing has been emitted yet.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The last value.
---
--- Note:
---  * You can also call the `BehaviorSubject` as a function to retrieve the value. E.g. `mySubject()`.
function BehaviorSubject:getValue()
  if self.value ~= nil then
    return util.unpack(self.value)
  end
end

BehaviorSubject.__call = BehaviorSubject.onNext

return BehaviorSubject