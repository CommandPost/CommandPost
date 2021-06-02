--- === cp.rx.AsyncSubject ===
---
--- `AsyncSubjects` are subjects that produce either no values or a single value.  If
--- multiple values are produced via `onNext`, only the last one is used.  If `onError` is called, then
--- no value is produced and `onError` is called on any subscribed [Observers](cp.rx.Observers.md).
--- If an [Observer](cp.rx.Observer.md) subscribes and the `AsyncSubject` has already terminated,
--- the `Observer` will immediately receive the value or the error.

local require           = require

local insert            = table.insert
local remove            = table.remove

local Observable        = require "cp.rx.Observable"
local Observer          = require "cp.rx.Observer"
local Reference         = require "cp.rx.Reference"
local util              = require "cp.rx.util"

local AsyncSubject = setmetatable({}, Observable)
AsyncSubject.__index = AsyncSubject
AsyncSubject.__tostring = util.constant('AsyncSubject')

--- cp.rx.AsyncSubject.create() -> cp.rx.AsyncSubject
--- Constructor
--- Creates a new `AsyncSubject`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new `AsyncSubject`.
function AsyncSubject.create()
  local self = {
    observers = {},
    stopped = false,
    value = nil,
    errorMessage = nil
  }

  return setmetatable(self, AsyncSubject)
end

--- cp.rx.AsyncSubject:subscribe(onNext, onError, onCompleted) -> cp.rx.Reference
--- Method
--- Creates a new [Observer](cp.rx.Observer.md) and attaches it to the `AsyncSubject`.
---
--- Parameters:
---  * onNext | observer - A `function` called when the `AsyncSubject` produces a value
---                       or an existing [Observer](cp.rx.Observer.md) to attach to the `AsyncSubject`.
---  * onError           - A `function` called when the `AsyncSubject` terminates due to an error.
---  * onCompleted       - A `funtion` called when the `AsyncSubject` completes normally.
---
--- Returns:
---  * The [Reference](cp.rx.Reference.md).
function AsyncSubject:subscribe(onNext, onError, onCompleted)
  local observer

  if util.isa(onNext, Observer) then
    observer = onNext
  else
    observer = Observer.create(onNext, onError, onCompleted)
  end

  if self.value then
    observer:onNext(util.unpack(self.value))
    observer:onCompleted()
    return Reference.create(util.noop)
  elseif self.errorMessage then
    observer:onError(self.errorMessage)
    return Reference.create(util.noop)
  else
    insert(self.observers, observer)

    return Reference.create(function()
      for i = 1, #self.observers do
        if self.observers[i] == observer then
          remove(self.observers, i)
          return
        end
      end
    end)
  end
end

--- cp.rx.AsyncSubject:onNext(...) -> nil
--- Method
--- Pushes zero or more values to the `AsyncSubject`.
---
--- Parameters:
---  * ...       - The values to send.
function AsyncSubject:onNext(...)
  if not self.stopped then
    self.value = util.pack(...)
  end
end

--- cp.rx.AsyncSubject:onError(message) -> nil
--- Method
--- Signal to all [Observers](cp.rx.Observer.md) that an error has occurred.
---
--- Parameters:
---  * message     - A string describing what went wrong.
function AsyncSubject:onError(message)
  if not self.stopped then
    self.errorMessage = message

    for i = 1, #self.observers do
      self.observers[i]:onError(self.errorMessage)
    end

    self.stopped = true
    self.observers = {}
  end
end

--- cp.rx.AsyncSubject:onCompleted() -> nil
--- Method
--- Signal to all [Observers](cp.rx.Observers.md) that the `AsyncSubject` will not produce any more values.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function AsyncSubject:onCompleted()
  if not self.stopped then
    for i = 1, #self.observers do
      if self.value then
        self.observers[i]:onNext(util.unpack(self.value))
      end

      self.observers[i]:onCompleted()
    end

    self.stopped = true
    self.observers = {}
  end
end

AsyncSubject.__call = AsyncSubject.onNext

return AsyncSubject