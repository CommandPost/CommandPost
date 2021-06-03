--- === cp.rx.Subject ===
---
--- `Subjects` function both as an [Observer](cp.rs.Observer.md) and as an [Observable](cp.rx.Observable.md). Subjects inherit all
--- `Observable` functions, including [subscribe](#subscribe). Values can also be pushed to the `Subject`, which will
--- be broadcasted to any subscribed [Observers](cp.rx.Observers.md).

local require           = require

local insert            = table.insert
local remove            = table.remove

local Observable        = require "cp.rx.Observable"
local Observer          = require "cp.rx.Observer"
local Reference         = require "cp.rx.Reference"
local util              = require "cp.rx.util"

local Subject = setmetatable({}, Observable)
Subject.__index = Subject
Subject.__tostring = util.constant('Subject')

--- cp.rx.Subject.create() -> cp.rx.Subject
--- Constructor
--- Creates a new Subject.
--- Returns:
---  * The `Subject`.
function Subject.create()
  local self = {
    observers = {},
    stopped = false
  }

  return setmetatable(self, Subject)
end

--- cp.rx.Subject:subscribe(onNext[, onError[, onCompleted]]) -> cp.rx.Reference
--- Method
--- Creates a new [Observer](cp.rx.Observer.md) and attaches it to the Subject.
---
--- Parameters:
---  * observer | onNext     - Either an [Observer](cp.rx.Observer.md), or a `function` called
---                           when the `Subject` produces a value.
---  * onError               - A `function` called when the `Subject` terminates due to an error.
---  * onCompleted           - A `function` called when the `Subject` completes normally.
---
--- Returns:
---  * The [Reference](cp.rx.Reference.md)
function Subject:subscribe(onNext, onError, onCompleted)
  local observer

  if util.isa(onNext, Observer) then
    observer = onNext
  else
    observer = Observer.create(onNext, onError, onCompleted)
  end

  if self.stopped then
    observer:onError("Subject has already stopped.")
    return Reference.create(util.noop)
  end

  insert(self.observers, observer)

  return Reference.create(function()
    if not self.stopping then
      for i = 1, #self.observers do
        if self.observers[i] == observer then
          remove(self.observers, i)
          return
        end
      end
    end
  end)
end

-- cp.rx.Subject:_stop() -> nil
-- Method
-- Stops future signals from being sent, and unsubscribes any observers.
function Subject:_stop()
  self.stopped = true
  self.observers = {}
end

--- cp.rx.Subject:onNext(...) -> nil
--- Method
--- Pushes zero or more values to the `Subject`. They will be broadcasted to all [Observers](cp.rx.Observer.md).
---
--- Parameters:
---  * ...       - The values to send.
function Subject:onNext(...)
  if not self.stopped then
    local observer
    for i = 1, #self.observers do
      observer = self.observers[i]
      if observer then observer:onNext(...) end
    end
  end
end

--- cp.rx.Subject:onError(message) -> nil
--- Method
--- Signal to all `Observers` that an error has occurred.
---
--- Parameters:
---  * message     - A string describing what went wrong.
function Subject:onError(message)
  if not self.stopped then
    self.stopping = true
    local observer
    for i = 1, #self.observers do
      observer = self.observers[i]
      if observer then observer:onError(message) end
    end
    self.stopping = true
    self:_stop()
  end
end

--- cp.rx.Subject:onCompleted() -> nil
--- Method
--- Signal to all [Observers](cp.rx.Observer.md) that the `Subject` will not produce any more values.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function Subject:onCompleted()
  if not self.stopped then
    self.stopping = true
    local observer
    for i = 1, #self.observers do
      observer = self.observers[i]
      if observer then observer:onCompleted() end
    end
    self.stopping = true
    self:_stop()
  end
end

Subject.__call = Subject.onNext

return Subject