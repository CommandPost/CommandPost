
--- === cp.rx.Observer ===
---
--- Observers are simple objects that receive values from [Observables](cp.rx.Observable.md).

local require           = require

local util              = require "cp.rx.util"

local Observer = {}
Observer.__index = Observer
Observer.__tostring = util.constant('Observer')

--- cp.rx.Observer.is(thing) -> boolean
--- Function
--- Tests if the `thing` is an `Observer`.
---
--- Parameters:
---  * thing   - The thing to test.
---
--- Returns:
---  * `true` if the thing is an `Observer`, otherwise `false`.
function Observer.is(thing)
    return util.isa(thing, Observer)
end

--- cp.rx.Observer.create(onNext, onError, onCompleted) -> cp.rx.Observer
--- Constructor
--- Creates a new Observer.
---
--- Parameters:
---  * onNext - Called when the Observable produces a value.
---  * onError - Called when the Observable terminates due to an error.
---  * onCompleted - Called when the Observable completes normally.
---
--- Returns:
---  * The new Observer.
function Observer.create(onNext, onError, onCompleted)
  local self = {
    _onNext = onNext or util.noop,
    _onError = onError or print,
    _onCompleted = onCompleted or util.noop,
    stopped = false
  }

  return setmetatable(self, Observer)
end

--- cp.rx.Observer:onNext(...) -> nil
--- Method
--- Pushes zero or more values to the Observer.
---
--- Parameters:
---  * ... - The list of values to send.
---
--- Returns:
---  * Nothing
function Observer:onNext(...)
  if not self.stopped then
    self._onNext(...)
  end
end

--- cp.rx.Observer:onError(message) -> nil
--- Method
--- Notify the Observer that an error has occurred.
---
--- Parameters:
---  * message - A string describing what went wrong.
---
--- Returns:
---  * Nothing
function Observer:onError(message)
  if not self.stopped then
    self.stopped = true
    self._onError(message)
  end
end

--- cp.rx.Observer:onCompleted() -> nil
--- Method
--- Notify the Observer that the sequence has completed and will produce no more values.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
function Observer:onCompleted()
  if not self.stopped then
    self.stopped = true
    self._onCompleted()
  end
end

return Observer