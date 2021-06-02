--- === cp.rx.RelaySubject ===
---
--- A [Subject](cp.rx.Subject.md) that provides new [Observers](cp.rx.Observer.md) with some or all of the most recently
--- produced values upon reference.
local require           = require

local Queue                 = require "cp.collect.Queue"

local Observer          = require "cp.rx.Observer"
local Reference         = require "cp.rx.Reference"
local Subject           = require "cp.rx.Subject"
local util              = require "cp.rx.util"

local ReplaySubject = setmetatable({}, Subject)
ReplaySubject.__index = ReplaySubject
ReplaySubject.__tostring = util.constant('ReplaySubject')

--- cp.rx.RelaySubject.create([n]) -> cp.rx.RelaySubject
--- Constructor
--- Creates a new `ReplaySubject`.
---
--- Parameters:
---  * bufferSize      - The number of values to send to new subscribers. If `nil`, an infinite
---                     buffer is used (note that this could lead to memory issues).
---
--- Returns:
---  * The new `ReplaySubject.
function ReplaySubject.create(n)
  local self = {
    observers = {},
    stopped = false,
    completed = false,
    err = nil,
    buffer = Queue(),
    bufferSize = n
  }

  return setmetatable(self, ReplaySubject)
end

--- cp.rx.RelaySubject:subscribe([observer | onNext[, onError[, onCompleted]]]) -> cp.rx.Reference
--- Method
--- Creates a new [Observer](cp.rx.Observer.md) and attaches it to the `ReplaySubject`.
--- Immediately broadcasts the most recent contents of the buffer to the Observer.
---
--- Parameters:
---  * observer | onNext     - Either an [Observer](cp.rx.Observer.md), or a
---                           `function` to call when the `ReplaySubject` produces a value.
---  * onError               - A `function` to call when the `ReplaySubject` terminates due to an error.
---  * onCompleted           - A `function` to call when the ReplaySubject completes normally.
---
--- Returns:
---  * The [Reference](cp.rx.Reference.md).
function ReplaySubject:subscribe(onNext, onError, onCompleted)
  local observer

  if util.isa(onNext, Observer) then
    observer = onNext
  else
    observer = Observer.create(onNext, onError, onCompleted)
  end

  if self.buffer then
    for i = 1, #self.buffer do
      observer:onNext(util.unpack(self.buffer[i]))
    end
  end

  if self.stopped then
    if self.completed then
      observer:onCompleted()
    else
      observer:onError(self.err)
    end
    return Reference.create(util.noop)
  else
    return Subject.subscribe(self, observer)
  end
end

--- cp.rx.RelaySubject:onNext(...) -> nil
--- Method
--- Pushes zero or more values to the `ReplaySubject`. They will be broadcasted to all [Observers](cp.rx.Observer.md).
---
--- Parameters:
---  * ...   - The values to send.
function ReplaySubject:onNext(...)
  if not self.stopped then
    self.buffer:pushRight(util.pack(...))
    if self.bufferSize and #self.buffer > self.bufferSize then
      self.buffer:popLeft()
    end

    Subject.onNext(self, ...)
  end
end

function ReplaySubject:onError(err)
  if not self.stopped then
    self.err = err
    Subject.onError(self, err)
  end
end

function ReplaySubject:onCompleted()
  if not self.stopped then
    self.completed = true
    Subject.onCompleted(self)
  end
end

ReplaySubject.__call = ReplaySubject.onNext

return ReplaySubject