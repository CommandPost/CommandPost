--- === cp.rx ===
---
--- Reactive Extensions for Lua.
---
--- RxLua gives Lua the power of Observables, which are data structures that represent a stream of values that arrive over time. They're very handy when dealing with events, streams of data, asynchronous requests, and concurrency.
---
--- * Originally forked from: https://github.com/bjornbytes/rxlua
--- * MIT License: https://github.com/bjornbytes/RxLua/blob/master/LICENSE

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log = require("hs.logger").new("rx")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
-- local inspect = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local timer = require("hs.timer")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local format = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local util = {}

local defaultScheduler = nil

util.pack = table.pack or function(...) return { n = select('#', ...), ... } end
util.unpack = table.unpack or _G.unpack
util.eq = function(x, y) return x == y end
util.noop = function() end
util.identity = function(x) return x end
util.constant = function(x) return function() return x end end
util.isa = function(object, class)
  if type(object) == 'table' then
    local mt = getmetatable(object)
    return mt and mt.__index == class or util.isa(mt, class)
  end
end
util.tryWithObserver = function(observer, fn, ...)
  local args = util.pack(...)
  local success, result = xpcall(function() fn(util.unpack(args)) end, debug.traceback)
  if not success then
    observer:onError(result)
  end
  return success, result
end
util.defaultScheduler = function(newScheduler)
    if newScheduler and type(newScheduler.schedule) == "function" then
        defaultScheduler = newScheduler
    end
    return defaultScheduler
end
util.tableId = function(value)
    local __tostring
    local mt = getmetatable(value)
    if mt then
        __tostring = mt.__tostring
        mt.__tostring = nil
    end

    local id = tostring(value)

    if mt then
        mt.__tostring = __tostring
    end
    return id
end

--- === cp.rx.Reference ===
---
--- A handle representing the link between an [Observer](cp.rx.Observer.md) and an [Observable](cp.rx.Observable.md), as well as any
--- work required to clean up after the Observable completes or the Observer cancels.
local Reference = {}
Reference.__index = Reference
Reference.__tostring = util.constant('Reference')

--- cp.rx.Reference.create(action) -> cp.rx.Reference
--- Constructor
--- Creates a new Reference.
---
--- Parameters:
--- * action - The action to run when the reference is canceld. It will only be run once.
---
--- Returns:
--- * the [Reference](cp.rx.Reference.md).
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
--- * None
---
--- Returns:
--- * Nothing
function Reference:cancel()
  if self.cancelled then return end
  self.action(self)
  self.cancelled = true
end

--- === cp.rx.Observer ===
---
--- Observers are simple objects that receive values from [Observables](cp.rx.Observables.md).
local Observer = {}
Observer.__index = Observer
Observer.__tostring = util.constant('Observer')

--- cp.rx.Observer.is(thing) -> boolean
--- Function
--- Tests if the `thing` is an `Observer`.
---
--- Parameters:
--- * thing   - The thing to test.
---
--- Returns:
--- * `true` if the thing is an `Observer`, otherwise `false`.
function Observer.is(thing)
    return util.isa(thing, Observer)
end

--- cp.rx.Observer.create(onNext, onError, onCompleted) -> cp.rx.Observer
--- Constructor
--- Creates a new Observer.
---
--- Parameters:
--- * onNext      - Called when the Observable produces a value.
--- * onError     - Called when the Observable terminates due to an error.
--- * onCompleted - Called when the Observable completes normally.
---
--- Returns:
--- * The new Observer.
function Observer.create(onNext, onError, onCompleted)
  local self = {
    _onNext = onNext or util.noop,
    _onError = onError or error,
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
--- * ...     - The list of values to send.
---
--- Returns:
--- * Nothing
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
--- * message  - A string describing what went wrong.
---
--- Returns:
--- * Nothing
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
--- * None
---
--- Returns:
--- * Nothing
function Observer:onCompleted()
  if not self.stopped then
    self.stopped = true
    self._onCompleted()
  end
end

--- === cp.rx.Observable ===
---
--- Observables push values to [Observers](cp.rx.Observer.md).
local Observable = {}
Observable.__index = Observable
Observable.__tostring = util.constant('Observable')

--- cp.rx.Observable.is(thing) -> boolean
--- Function
--- Checks if the thing is an instance of [Observable](cp.rx.Observable.md).
---
--- Parameters:
--- * thing   - The thing to check.
---
--- Returns:
--- * `true` if the thing is an `Observable`.
function Observable.is(thing)
    return util.isa(thing, Observable)
end

--- cp.rx.Observable.create(onSubscription) -> cp.rx.Observable
--- Constructor
--- Creates a new Observable.
---
--- Parameters:
--- * onSubscription  - The reference function that produces values.
---
--- Returns:
--- * The new `Observable`.
function Observable.create(onSubscription)
  local self = {
    _subscribe = onSubscription
  }

  return setmetatable(self, Observable)
end

--- cp.rx.Observable:subscribe(observer | onNext[, onError[, onCompleted]]) -> cp.rx.Reference
--- Method
--- Shorthand for creating an [Observer](cp.rx.Observer.md) and passing it to this Observable's [subscription](#subscri) function.
---
--- Parameters:
--- * observer | onNext     - Either an [Observer](cp.rx.Observer.md) or a `function` to be called when the Observable produces a value.
--- * onError               - A `function` to be called when the Observable terminates due to an error.
--- * onCompleted           - A 'function` to be called when the Observable completes normally.
---
--- Returns:
--- * A [Reference](cp.rx.Reference.md) which can be used to cancel the subscription.
function Observable:subscribe(onNext, onError, onCompleted)
  if Observer.is(onNext) then
    return self._subscribe(onNext)
  else
    return self._subscribe(Observer.create(onNext, onError, onCompleted))
  end
end

--- cp.rx.Observable.empty() -> cp.rx.Observable
--- Constructor
--- Returns an Observable that immediately completes without producing a value.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The new `Observable`.
function Observable.empty()
  return Observable.create(function(observer)
    observer:onCompleted()
  end)
end

--- cp.rx.Observable.never() -> cp.rx.Observable
--- Constructor
--- Returns an Observable that never produces values and never completes.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The new `Observable`.
function Observable.never()
  return Observable.create(function(_) end)
end

--- cp.rx.Observable.throw(message, ...) -> cp.rx.Observable
--- Constructor
--- Returns an Observable that immediately produces an error.
---
--- Parameters:
--- * message   - The message to send.
--- * ...       - The additional values to apply to the message, using `string.format` syntax.
---
--- Returns:
--- * The new `Observable`.
function Observable.throw(message, ...)
  if select("#", ...) > 0 then
    message = string.format(message, ...)
  end
  return Observable.create(function(observer)
    observer:onError(message)
  end)
end

--- cp.rx.Observable.of(...) -> cp.rx.Observable
--- Constructor
--- Creates an Observable that produces a set of values.
---
--- Parameters:
--- * ...     - The list of values to send as individual `onNext` values.
---
--- Returns:
--- * The new `Observable`.
function Observable.of(...)
  local args = {...}
  local argCount = select('#', ...)
  return Observable.create(function(observer)
    for i = 1, argCount do
      observer:onNext(args[i])
    end

    observer:onCompleted()
  end)
end

--- cp.rx.Observable.fromRange(initial[, limit[, step]]) -> cp.rx.Observable
--- Constructor
--- Creates an Observable that produces a range of values in a manner similar to a Lua `for` loop.
---
--- Parameters:
--- * initial   - The first value of the range, or the upper limit if no other arguments are specified.
--- * limit     - The second value of the range. Defaults to no limit.
--- * step      - An amount to increment the value by each iteration. Defaults to `1`.
---
--- Returns:
--- * The new `Observable`.
function Observable.fromRange(initial, limit, step)
  if not limit and not step then
    initial, limit = 1, initial
  end

  step = step or 1

  return Observable.create(function(observer)
    for i = initial, limit, step do
      observer:onNext(i)
    end

    observer:onCompleted()
  end)
end

--- cp.rx.Observable.fromTable(t, iterator, keys) -> cp.rx.Observable
--- Constructor
--- Creates an `Observable` that produces values from a table.
---
--- Parameters:
--- * t         - The `table` used to create the `Observable`.
--- * iterator  - An iterator used to iterate the table, e.g. `pairs` or `ipairs`. Defaults to `pairs`.
--- * keys      - If `true`, also emit the keys of the table. Defaults to `false`.
---
--- Returns:
--- * The new `Observable`.
function Observable.fromTable(t, iterator, keys)
  iterator = iterator or pairs
  return Observable.create(function(observer)
    for key, value in iterator(t) do
      observer:onNext(value, keys and key or nil)
    end

    observer:onCompleted()
  end)
end

--- cp.rx.Observable.fromCoroutine(fn, scheduler) -> cp.rx.Observable
--- Constructor
--- Creates an Observable that produces values when the specified coroutine yields.
---
--- Parameters:
--- * fn - A `coroutine` or `function` to use to generate values.  Note that if a coroutine is used, the values it yields will be shared by all subscribed [Observers](cp.rx.Observer.md) (influenced by the [Scheduler](cp.rx.Scheduler.md)), whereas a new coroutine will be created for each Observer when a `function` is used.
---
--- Returns:
--- * The new `Observable`.
function Observable.fromCoroutine(fn, scheduler)
  scheduler = scheduler or util.defaultScheduler()
  return Observable.create(function(observer)
    local thread = type(fn) == 'function' and coroutine.create(fn) or fn
    return scheduler:schedule(function()
      while not observer.stopped do
        local success, value = coroutine.resume(thread)

        if success then
          observer:onNext(value)
        else
          return observer:onError(value)
        end

        if coroutine.status(thread) == 'dead' then
          return observer:onCompleted()
        end

        coroutine.yield()
      end
    end)
  end)
end

--- cp.rx.Observable.fromFileByLine(filename) -> cp.rx.Observable
--- Constructor
--- Creates an Observable that produces values from a file, line by line.
---
--- Parameters:
--- * filename    - The name of the file used to create the Observable.
---
--- Returns:
--- * The new `Observable`.
function Observable.fromFileByLine(filename)
  return Observable.create(function(observer)
    local f = io.open(filename, 'r')
    if f
    then
      f:close()
      for line in io.lines(filename) do
        observer:onNext(line)
      end

      return observer:onCompleted()
    else
      return observer:onError(filename)
    end
  end)
end

--- cp.rx.Observable.defer(fn) -> cp.rx.Observable
--- Constructor
--- Creates an `Observable` that executes the `function` to create a new `Observable` each time an [Observer](cp.rx.Observer.md) subscribes.
---
--- Parameters:
--- * fn    - A function that returns an `Observable`.
---
--- Returns:
--- * The new `Observable`.
function Observable.defer(fn)
  return setmetatable({
    subscribe = function(_, ...)
      local observable = fn()
      return observable:subscribe(...)
    end
  }, Observable)
end

--- cp.rx.Observable.replicate(value[, count]) -> cp.rx.Observable
--- Constructor
--- Creates an `Observable` that repeats a value a specified number of times.
---
--- Parameters:
--- * value     - The value to repeat.
--- * count     - The number of times to repeat the value.  If left unspecified, the value
---                        is repeated an infinite number of times.
---
--- Returns:
--- * The new `Observable`.
function Observable.replicate(value, count)
  return Observable.create(function(observer)
    while count == nil or count > 0 do
      observer:onNext(value)
      if count then
        count = count - 1
      end
    end
    observer:onCompleted()
  end)
end

--- cp.rx.Observable:dump(name, formatter)
--- Method
--- Subscribes to this Observable and prints values it produces.
---
--- Parameters:
--- * name      - Prefixes the printed messages with a name.
--- * formatter - A function that formats one or more values to be printed. Defaults to `tostring`.
---
--- Returns:
--- * A [Reference](cp.rx.Reference.md) for the subscription.
function Observable:dump(name, formatter)
  name = name and (name .. ' ') or ''
  formatter = formatter or tostring

  local onNext = function(...) print(format("%sonNext: %s", name, formatter(...))) end
  local onError = function(e) print(format("%sonError: %s", name, e)) end
  local onCompleted = function() print(format("%sonCompleted", name)) end

  return self:subscribe(onNext, onError, onCompleted)
end

--- cp.rx.Observable:all(predicate) -> cp.rx.Observable
--- Method
--- Determine whether all items emitted by an Observable meet some criteria.
---
--- Parameters:
--- * predicate - The predicate used to evaluate objects. Defaults to the `identity`.
---
--- Returns:
--- * A new `Observable`.
function Observable:all(predicate)
  predicate = predicate or util.identity

  return Observable.create(function(observer)
    local function onNext(...)
      util.tryWithObserver(observer, function(...)
        if not predicate(...) then
          observer:onNext(false)
          observer:onCompleted()
        end
      end, ...)
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      observer:onNext(true)
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable.firstEmitting(...) -> cp.rx.Observer
--- Constructor
--- Given a set of Observables, produces values from only the first one to produce a value or complete.
---
--- Parameters:
--- * ...   - list of [Observables](cp.rx.Observable.md)
---
--- Returns:
--- * The new `Observable`.
function Observable.firstEmitting(a, b, ...)
  if not a or not b then return a end

  return Observable.create(function(observer)
    local referenceA, referenceB

    local function onNextA(...)
      if referenceB then referenceB:cancel() end
      observer:onNext(...)
    end

    local function onErrorA(e)
      if referenceB then referenceB:cancel() end
      observer:onError(e)
    end

    local function onCompletedA()
      if referenceB then referenceB:cancel() end
      observer:onCompleted()
    end

    local function onNextB(...)
      if referenceA then referenceA:cancel() end
      observer:onNext(...)
    end

    local function onErrorB(e)
      if referenceA then referenceA:cancel() end
      observer:onError(e)
    end

    local function onCompletedB()
      if referenceA then referenceA:cancel() end
      observer:onCompleted()
    end

    referenceA = a:subscribe(onNextA, onErrorA, onCompletedA)
    referenceB = b:subscribe(onNextB, onErrorB, onCompletedB)

    return Reference.create(function()
      referenceA:cancel()
      referenceB:cancel()
    end)
  end):firstEmitting(...)
end

--- cp.rx.Observable:average() -> cp.rx.Observable
--- Method
--- Returns an Observable that produces the average of all values produced by the original.
---
--- Returns:
--- * The new `Observable`.
function Observable:average()
  return Observable.create(function(observer)
    local sum, count = 0, 0

    local function onNext(value)
      sum = sum + value
      count = count + 1
    end

    local function onError(e)
      observer:onError(e)
    end

    local function onCompleted()
      if count > 0 then
        observer:onNext(sum / count)
      end

      observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:buffer(size) -> cp.rx.Observable
--- Method
--- Returns an Observable that buffers values from the original and produces them as multiple values.
---
--- Parameters:
--- * size    - The size of the buffer.
---
--- Returns:
--- * The new `Observable`.
function Observable:buffer(size)
  return Observable.create(function(observer)
    local buffer = {}

    local function emit()
      if #buffer > 0 then
        observer:onNext(util.unpack(buffer))
        buffer = {}
      end
    end

    local function onNext(...)
      local values = {...}
      for i = 1, #values do
        table.insert(buffer, values[i])
        if #buffer >= size then
          emit()
        end
      end
    end

    local function onError(message)
      emit()
      return observer:onError(message)
    end

    local function onCompleted()
      emit()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:catch(handler) -> cp.rx.Observable
--- Method
--- Returns an Observable that intercepts any errors from the previous and replace them with values
--- produced by a new Observable.
---
--- Parameters:
--- * handler - An `Observable` or a `function` that returns an `Observable` to
---             replace the source `Observable` in the event of an error.
---
--- Returns:
--- * The new `Observable`.
function Observable:catch(handler)
  handler = handler and (type(handler) == 'function' and handler or util.constant(handler))

  return Observable.create(function(observer)
    local reference

    local function onNext(...)
      return observer:onNext(...)
    end

    local function onError(e)
      if not handler then
        return observer:onCompleted()
      end

      local success, continue = pcall(handler, e)
      if success and continue then
        if reference then reference:cancel() end
        continue:subscribe(observer)
      else
        observer:onError(success and e or continue)
      end
    end

    local function onCompleted()
      observer:onCompleted()
    end

    reference = self:subscribe(onNext, onError, onCompleted)
    return reference
  end)
end

--- cp.rx.Observable:combindLatest(...) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that runs a combinator function on the most recent values from a set
--- of `Observables` whenever any of them produce a new value. The results of the combinator `function`
--- are produced by the new `Observable`.
---
--- Parameters:
--- * ...         - One or more `Observables` to combine.
--- * combinator  - A `function` that combines the latest result from each `Observable` and
---                              returns a single value.
---
--- Returns:
--- * The new `Observable`.
function Observable:combineLatest(...)
  local sources = {...}
  local combinator = table.remove(sources)
  if type(combinator) ~= 'function' then
    table.insert(sources, combinator)
    combinator = function(...) return ... end
  end
  table.insert(sources, 1, self)

  return Observable.create(function(observer)
    local latest = {}
    local pending = {util.unpack(sources)}
    local completed = {}
    local reference = {}

    local function onNext(i)
      return function(value)
        latest[i] = value
        pending[i] = nil

        if not next(pending) then
          util.tryWithObserver(observer, function()
            observer:onNext(combinator(util.unpack(latest)))
          end)
        end
      end
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted(i)
      return function()
        table.insert(completed, i)

        if #completed == #sources then
          observer:onCompleted()
        end
      end
    end

    for i = 1, #sources do
      reference[i] = sources[i]:subscribe(onNext(i), onError, onCompleted(i))
    end

    return Reference.create(function ()
      for i = 1, #reference do
        if reference[i] then reference[i]:cancel() end
      end
    end)
  end)
end

--- cp.rx.Observable:compact() -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the values of the first with falsy values removed.
---
--- Returns:
--- * The new `Observable`.
function Observable:compact()
  return self:filter(util.identity)
end

--- cp.rx.Observable:concat(...) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the values produced by all the specified `Observables` in
--- the order they are specified.
---
--- Parameters:
--- * ...     - The list of `Observables` to concatenate.
---
--- Returns:
--- * The new `Observable`.
function Observable:concat(other, ...)
  if not other then return self end

  local others = {...}

  return Observable.create(function(observer)
    local function onNext(...)
      return observer:onNext(...)
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    local function chain()
      return other:concat(util.unpack(others)):subscribe(onNext, onError, onCompleted)
    end

    return self:subscribe(onNext, onError, chain)
  end)
end

--- cp.rx.Observable:contains(value) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces a single `boolean` value representing whether or not the
--- specified value was produced by the original.
---
--- Parameters:
--- * value       - The value to search for.  `==` is used for equality testing.
---
--- Returns:
--- * The new `Observable`.
function Observable:contains(value)
  return Observable.create(function(observer)
    local reference

    local function onNext(...)
      local args = util.pack(...)

      if #args == 0 and value == nil then
        observer:onNext(true)
        if reference then reference:cancel() end
        return observer:onCompleted()
      end

      for i = 1, #args do
        if args[i] == value then
          observer:onNext(true)
          if reference then reference:cancel() end
          return observer:onCompleted()
        end
      end
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      observer:onNext(false)
      return observer:onCompleted()
    end

    reference = self:subscribe(onNext, onError, onCompleted)
    return reference
  end)
end

--- cp.rx.Observable:count([predicate]) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that produces a single value representing the number of values produced
--- by the source value that satisfy an optional predicate.
---
--- Parameters:
--- * predicate   - The predicate `function` used to match values.
---
--- Returns:
--- * The new `Observable`.
function Observable:count(predicate)
  predicate = predicate or util.constant(true)

  return Observable.create(function(observer)
    local count = 0

    local function onNext(...)
      util.tryWithObserver(observer, function(...)
        if predicate(...) then
          count = count + 1
        end
      end, ...)
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      observer:onNext(count)
      observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:debounce(time[, scheduler]) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that mirrors the source `Observable`, except that it drops items emitted by the source
--- that are followed by newer items before a timeout value expires on a specified [Scheduler](cp.rx.Scheduler.md).
--- The timer resets on each emission.
---
--- Parameters:
--- * time        - The number of milliseconds.
--- * scheduler   - The scheduler. Uses the [defaultScheduler](cp.rx.util#defaultScheduler) by default.
---
--- Returns:
--- * The new `Observable`.
function Observable:debounce(time, scheduler)
  time = time or 0
  scheduler = scheduler or util.defaultScheduler()

  return Observable.create(function(observer)
    local debounced = {}

    local function wrap(key)
      return function(...)
        if debounced[key] then
          debounced[key]:cancel()
        end

        local values = util.pack(...)

        debounced[key] = scheduler:schedule(function()
          return observer[key](observer, util.unpack(values))
        end, time)
      end
    end

    local reference = self:subscribe(wrap('onNext'), wrap('onError'), wrap('onCompleted'))

    return Reference.create(function()
      if reference then reference:cancel() end
      for _, timeout in pairs(debounced) do
        timeout:cancel()
      end
    end)
  end)
end

--- cp.rx.Observable:defaultIfEmpty(...)
--- Method
--- Returns a new `Observable` that produces a default set of items if the source `Observable` produces
--- no values.
---
--- Patameters:
--- * ...     - Zero or more values to produce if the source completes without emitting anything.
---
--- Returns:
--- * The new `Observable`.
function Observable:defaultIfEmpty(...)
  local defaults = util.pack(...)

  return Observable.create(function(observer)
    local hasValue = false

    local function onNext(...)
      hasValue = true
      observer:onNext(...)
    end

    local function onError(e)
      observer:onError(e)
    end

    local function onCompleted()
      if not hasValue then
        observer:onNext(util.unpack(defaults))
      end

      observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:delay(time, scheduler) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the values of the original delayed by a time period.
---
--- Parameters:
--- * time      - An amount in milliseconds to delay by, or a `function` which returns
---               this value.
--- * scheduler - The [Scheduler](cp.rx.Scheduler.md) to run the `Observable` on.
---
--- Returns:
--- * The new `Observable`.
function Observable:delay(time, scheduler)
  time = type(time) ~= 'function' and util.constant(time) or time
  scheduler = scheduler or util.defaultScheduler()

  return Observable.create(function(observer)
    local actions = {}

    local function delay(key)
      return function(...)
        local arg = util.pack(...)
        local handle = scheduler:schedule(function()
          observer[key](observer, util.unpack(arg))
        end, time())
        table.insert(actions, handle)
      end
    end

    local reference = self:subscribe(delay('onNext'), delay('onError'), delay('onCompleted'))

    return Reference.create(function()
      if reference then reference:cancel() end
      for i = 1, #actions do
        actions[i]:cancel()
      end
    end)
  end)
end

--- cp.rx.Observable:distinct() -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the values from the original with duplicates removed.
---
--- Returns:
--- * The new `Observable`.
function Observable:distinct()
  return Observable.create(function(observer)
    local values = {}

    local function onNext(x)
      if not values[x] then
        observer:onNext(x)
      end

      values[x] = true
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:distinctUntilChanged([comparator]) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that only produces values from the original if they are different from
--- the previous value.
---
--- Parameters:
--- * comparator    - A `function` used to compare 2 values. If unspecified, `==` is used.
---
--- Returns:
--- * The new `Observable`
function Observable:distinctUntilChanged(comparator)
  comparator = comparator or util.eq

  return Observable.create(function(observer)
    local first = true
    local currentValue = nil

    local function onNext(value, ...)
      local values = util.pack(...)
      util.tryWithObserver(observer, function()
        if first or not comparator(value, currentValue) then
          observer:onNext(value, util.unpack(values))
          currentValue = value
          first = false
        end
      end)
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:elementAt(index) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that produces the `n`th element produced by the source `Observable`.
---
--- Parameters:
--- * index     - The index of the item, with an index of `1` representing the first.
---
--- Returns:
--- * The new `Observable`.
function Observable:elementAt(index)
  return Observable.create(function(observer)
    local reference
    local i = 1

    local function onNext(...)
      if i == index then
        observer:onNext(...)
        observer:onCompleted()
        if reference then
          reference:cancel()
        end
      else
        i = i + 1
      end
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    reference = self:subscribe(onNext, onError, onCompleted)
    return reference
  end)
end

--- cp.rx.Observable:filter(predicate) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that only produces values of the first that satisfy a predicate.
---
--- Parameters:
--- * predicate - The predicate `function` used to filter values.
---
--- Returns:
--- * The new `Observable`.
function Observable:filter(predicate)
  predicate = predicate or util.identity

  return Observable.create(function(observer)
    local function onNext(...)
      util.tryWithObserver(observer, function(...)
        if predicate(...) then
          return observer:onNext(...)
        end
      end, ...)
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:switchIfEmpty(alternate) -> cp.rx.Observable
--- Method
--- Switch to an alternate `Observable` if this one sends an `onCompleted` without any `onNext`s.
---
--- Parameters:
--- * alternate  - An `Observable` to switch to if this does not send any `onNext` values before the `onCompleted`.
---
--- Returns:
--- * The new `Observable`.
function Observable:switchIfEmpty(alternate)
  return Observable.create(function(observer)
    local done = false
    local hasNext = false
    local ref = nil

    local function unsubscribe()
      if not done then
        if ref then
          ref:cancel()
          ref = nil
        end
        done = true
        return true
      end
      return false
    end

    local function onCompleted()
      if unsubscribe() then
        if hasNext then
          observer:onCompleted()
        else
          alternate:subscribe(observer)
        end
      end
    end

    local function onError(message)
      if unsubscribe() then
        observer:onError(message)
      end
    end

    local function onNext(...)
      if not done then
        hasNext = true
        observer:onNext(...)
      end
    end

    ref = self:subscribe(onNext, onError, onCompleted)

    return Reference.create(function()
      unsubscribe()
    end)
  end)
end

--- cp.rx.Observable:finalize(handler) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that mirrors the source `Observable`, but will call a specified `function`
--- when the source terminates on complete or error.
---
--- Parameters:
--- * handler   - The handler `function` to call when `onError`/`onCompleted` occurs.
---
--- Returns:
--- * The new `Observable`.
function Observable:finalize(handler)
  return Observable.create(function(observer)
    local done = false
    local sub = nil

    local function onNext(...)
      if not done then
        observer:onNext(...)
      end
    end

    local function onError(message)
      if not done then
        local ok = util.tryWithObserver(observer, handler)
        if ok then
          observer:onError(message)
        else
          done = true
          if sub then
            sub:cancel()
            sub = nil
          end
        end
      end
    end

    local function onCompleted()
      if not done then
        local ok = util.tryWithObserver(observer, handler)
        if ok then
          observer:onCompleted()
        else
          done = true
          if sub then
            sub:cancel()
            sub = nil
          end
        end
      end
    end

    sub = self:subscribe(onNext, onError, onCompleted)

    return Reference.create(function()
      done = true
      if sub then
        sub:cancel()
        sub = nil
      end
    end)
  end)
end

--- cp.rx.Observable:find(predicate) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the first value of the original that satisfies a
--- predicate.
---
--- Parameters:
--- * predicate   - The predicate `function` used to find a value.
---
--- Returns:
--- * The new `Observable`.
function Observable:find(predicate)
  predicate = predicate or util.identity

  return Observable.create(function(observer)
    local done = false
    local sub = nil

    local function cancel()
      if sub then
        sub:cancel()
        sub = nil
      end
      done = true
    end

    local function onError(message)
      if not done then
        cancel()
        observer:onError(message)
      end
    end

    local function onCompleted()
      if not done then
        cancel()
        observer:onCompleted()
      end
    end

    local function onNext(...)
      if not done then
        util.tryWithObserver(observer, function(...)
          if predicate(...) then
            observer:onNext(...)
            onCompleted()
          end
        end, ...)
      end
    end

    sub = self:subscribe(onNext, onError, onCompleted)
    if done then
      cancel()
    end
    return Reference.create(function()
      cancel()
    end)
  end)
end

--- cp.rx.Observable:first() -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that only produces the first result of the original.
--- If no values are produced, an error is thrown.
---
--- Returns:
--- * The new `Observable`.
---
--- Note:
--- * This is similar to [#next], but will throw an error if no `onNext` signal is sent before `onCompleted`.
function Observable:first()
  return self:take(1)
end

--- cp.rx.Observable:next() -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces at most the first result from the original and then completes.
--- Will not send an error if zero values are sent.
---
--- Note:
--- * This is similar to [#first], but will not throw an error if no `onNext` signal is sent before `onCompleted`.
function Observable:next()
  return Observable.create(function(observer)
    local done = false
    local ref = nil

    local function onCompleted()
      if not done then
        done = true
        if ref then
          ref:cancel()
          ref = nil
        end
        observer:onCompleted()
      end
    end

    local function onError(message)
      if not done then
        done = true
        if ref then
          ref:cancel()
          ref = nil
        end
        observer:onError(message)
      end
    end

    local function onNext(...)
      if not done then
        observer:onNext(...)
        onCompleted()
      end
    end

    ref = self:subscribe(onNext, onError, onCompleted)

    return Reference.create(function()
      done = false
      if ref then
        ref:cancel()
        ref = nil
      end
    end)
  end)
end

--- cp.rx.Observable:flatMap(callback) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that transform the items emitted by an `Observable` into `Observables`,
--- then flatten the emissions from those into a single `Observable`.
---
--- Parameters:
--- * callback - The `function` to transform values from the original `Observable`.
---
--- Returns:
--- * The new `Observable`.
function Observable:flatMap(callback)
  callback = callback or util.identity
  return self:map(callback):flatten()
end

--- cp.rx.Observable:flatMapLatest([callback]) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that uses a callback to create `Observables` from the values produced by
--- the source, then produces values from the most recent of these `Observables`.
---
--- Parameters:
--- @arg {function=identity} callback - The function used to convert values to Observables. Defaults to the [identity](cp.rx.util#identity) function.
---
--- Returns:
--- * The new `Observable`.
function Observable:flatMapLatest(callback)
  callback = callback or util.identity
  return Observable.create(function(observer)
    local innerReference

    local function onNext(...)
      observer:onNext(...)
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    local function subscribeInner(...)
      if innerReference then
        innerReference:cancel()
      end

      return util.tryWithObserver(observer, function(...)
        innerReference = callback(...):subscribe(onNext, onError)
      end, ...)
    end

    local reference = self:subscribe(subscribeInner, onError, onCompleted)
    return Reference.create(function()
      if innerReference then
        innerReference:cancel()
      end

      if reference then
        reference:cancel()
      end
    end)
  end)
end

--- cp.rx.Observable:flatten()
--- Method
--- Returns a new `Observable` that subscribes to the `Observables` produced by the original and
--- produces their values.
---
--- Returns:
--- * The new `Observable`.
function Observable:flatten()
  local stopped = false
  local outerCompleted = false
  local waiting = 0
  return Observable.create(function(observer)
    local function onError(message)
      stopped = true
      return observer:onError(message)
    end
    local function onNext(observable)
      if stopped then
        return
      end

      local ref
      local function cancelSub()
        if ref then
          ref:cancel()
          ref = nil
        end
      end

      local function innerOnNext(...)
        if stopped then
            cancelSub()
        else
            observer:onNext(...)
        end
      end

      local function innerOnError(message)
        cancelSub()
        if not stopped then
            stopped = true
            observer:onError(message)
        end
      end

      local function innerOnCompleted()
        cancelSub()
        if not stopped then
            -- log.df("flatten: inner completed: original completed: %s", outerCompleted)
            waiting = waiting - 1
            if waiting == 0 and outerCompleted then
                -- log.df("flatten: inner completed, sending on")
                stopped = true
                return observer:onCompleted()
            end
        end
      end

      waiting = waiting + 1
      ref = observable:subscribe(innerOnNext, innerOnError, innerOnCompleted)
    end

    local function onCompleted()
      -- log.df("flatten: outer completed")
      if not stopped then
        outerCompleted = true
        if waiting == 0 then
            stopped = true
            return observer:onCompleted()
        end
      end
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:ignoreElements() -> cp.rx.Observable
--- Method
--- Returns an `Observable` that terminates when the source terminates but does not produce any
--- elements.
---
--- Returns:
--- * The new `Observable`.
function Observable:ignoreElements()
  return Observable.create(function(observer)
    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(nil, onError, onCompleted)
  end)
end

--- cp.rx.Observable:last() -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that only produces the last result of the original.
---
--- Returns:
--- * The new `Observable`.
function Observable:last()
  return Observable.create(function(observer)
    local value
    local empty = true

    local function onNext(...)
      value = {...}
      empty = false
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      if not empty then
        observer:onNext(util.unpack(value or {}))
      end

      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:map(callback) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the values of the original transformed by a `function`.
---
--- Parameters:
--- * callback    - The `function` to transform values from the original `Observable`.
---
--- Returns:
--- * The new `Observable`.
function Observable:map(callback)
  return Observable.create(function(observer)
    callback = callback or util.identity
    local ref = nil

    local function onNext(...)
      local success = util.tryWithObserver(observer, function(...)
        return observer:onNext(callback(...))
      end, ...)
      if not success and ref then
        ref:cancel()
      end
    end

    local function onError(e)
      observer:onError(e)
    end

    local function onCompleted()
      observer:onCompleted()
    end

    ref = self:subscribe(onNext, onError, onCompleted)
    return ref
  end)
end

--- cp.rx.Observable:max() -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the maximum value produced by the original.
---
--- Returns:
--- * The new `Observable`.
function Observable:max()
  return self:reduce(math.max)
end

--- cp.rx.Observable:merge(...) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the values produced by all the specified `Observables` in
--- the order they are produced.
---
--- Parameters:
--- * ...       - One or more `Observables` to merge.
---
--- Returns:
--- * The new `Observable`.
function Observable:merge(...)
  local sources = {...}
  table.insert(sources, 1, self)

  return Observable.create(function(observer)
    local function onNext(...)
      return observer:onNext(...)
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted(i)
      return function()
        sources[i] = nil

        if not next(sources) then
          observer:onCompleted()
        end
      end
    end

    for i = 1, #sources do
      sources[i]:subscribe(onNext, onError, onCompleted(i))
    end
  end)
end

--- cp.rx.Observable:min() -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the minimum value produced by the original.
---
--- Returns:
--- * The new `Observable`.
function Observable:min()
  return self:reduce(math.min)
end

--- cp.rx.Observable:partition(predicate) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that produces the values of the original inside tables.
---
--- Returns:
--- * The new `Observable`.
function Observable:pack()
  return self:map(util.pack)
end

--- cp.rx.Observable:partition(predicate) -> cp.rx.Observable, cp.rx.Observable
--- Method
--- Returns two `Observables`: one that produces values for which the predicate returns truthy for,
--- and another that produces values for which the predicate returns falsy.
---
--- Parameters:
--- * predicate   - The predicate `function` used to partition the values.
---
--- Returns:
--- * The 'truthy' `Observable`.
--- * The 'falsy' `Observable`.
function Observable:partition(predicate)
  return self:filter(predicate), self:reject(predicate)
end

--- cp.rx.Observable:pluck(...) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces values computed by extracting the given keys from the
--- tables produced by the original.
---
--- Parameters:
--- * ...       - The key to extract from the `table`. Multiple keys can be specified to
---               recursively pluck values from nested tables.
---
--- Returns:
--- * The new `Observable`.
function Observable:pluck(key, ...)
  if not key then return self end

  if type(key) ~= 'string' and type(key) ~= 'number' then
    return Observable.throw('pluck key must be a string')
  end

  return Observable.create(function(observer)
    local function onNext(t)
      return observer:onNext(t[key])
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end):pluck(...)
end

--- cp.rx.Observable:reduce(accumulator[, seed]) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces a single value computed by accumulating the results of
--- running a `function` on each value produced by the original `Observable`.
---
--- Parameters:
--- * accumulator - Accumulates the values of the original `Observable`. Will be passed
---                 the return value of the last call as the first argument and the
---                 current values as the rest of the arguments.
--- * seed        - A value to pass to the accumulator the first time it is run.
---
--- Returns:
--- * The new `Observable`.
function Observable:reduce(accumulator, seed)
  return Observable.create(function(observer)
    local result = seed
    local first = true

    local function onNext(...)
      if first and seed == nil then
        result = ...
        first = false
      else
        return util.tryWithObserver(observer, function(...)
          result = accumulator(result, ...)
        end, ...)
      end
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      observer:onNext(result)
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:reject(predicate) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces values from the original which do not satisfy a predicate.
---
--- Parameters:
--- * predicate     - The predicate `function` used to reject values.
---
--- Returns:
--- * The new `Observable`.
function Observable:reject(predicate)
  predicate = predicate or util.identity

  return Observable.create(function(observer)
    local function onNext(...)
      util.tryWithObserver(observer, function(...)
        if not predicate(...) then
          return observer:onNext(...)
        end
      end, ...)
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:retry([count]) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that restarts in the event of an error.
---
--- Parameters:
--- * count     - The maximum number of times to retry.  If left unspecified, an infinite
---               number of retries will be attempted.
---
--- Returns:
--- * The new `Observable`.
function Observable:retry(count)
  return Observable.create(function(observer)
    local reference
    local retries = 0

    local function onNext(...)
      return observer:onNext(...)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    local function onError(message)
      if reference then
        reference:cancel()
      end

      retries = retries + 1
      if count and retries > count then
        return observer:onError(message)
      end

      reference = self:subscribe(onNext, onError, onCompleted)
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:retryWithDelay(count[, delay[, scheduler]]) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that restarts in the event of an error.
---
--- Parameters:
--- * count     - The maximum number of times to retry.  If left unspecified, an infinite
---               number of retries will be attempted.
--- * delay     - The delay in milliseconds. If left unspecified, defaults to 1000 (1 second).
--- * scheduler - The [Scheduler](cp.rx.Scheduler.md) to use.
---               If not specified, it will use the [defaultScheduler](cp.rx.util#defaultScheduler].
---
--- Returns:
--- * The new `Observable`.
function Observable:retryWithDelay(count, delay, scheduler)
  return Observable.create(function(observer)
    local reference
    local retries = 0

    local function onNext(...)
      return observer:onNext(...)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    local function onError(message)
      if reference then
        reference:cancel()
      end

      retries = retries + 1
      if count and retries > count then
        return observer:onError(message)
      end

      scheduler = scheduler or util.defaultScheduler()
      delay = delay or 1000

      scheduler:schedule(function()
        reference = self:subscribe(onNext, onError, onCompleted)
      end, delay)
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:sample(sampler) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces its most recent value every time the specified observable
--- produces a value.
---
--- Parameters:
--- * sampler     - The `Observable` that is used to sample values from this `Observable`.
---
--- Returns:.
--- * The new `Observable`.
function Observable:sample(sampler)
  if not sampler then error('Expected an Observable') end

  return Observable.create(function(observer)
    local latest = {}

    local function setLatest(...)
      latest = util.pack(...)
    end

    local function onNext()
      if #latest > 0 then
        return observer:onNext(util.unpack(latest))
      end
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    local sourceReference = self:subscribe(setLatest, onError)
    local sampleReference = sampler:subscribe(onNext, onError, onCompleted)

    return Reference.create(function()
      if sourceReference then sourceReference:cancel() end
      if sampleReference then sampleReference:cancel() end
    end)
  end)
end

--- cp.rx.Observable:scan(accumulator, seed) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces values computed by accumulating the results of running a
--- `function` on each value produced by the original `Observable`.
---
--- Parameters:
--- * accumulator     - Accumulates the values of the original `Observable`. Will be passed
---                     the return value of the last call as the first argument and the
---                     current values as the rest of the arguments.  Each value returned
---                     from this `function` will be emitted by the `Observable`.
--- * seed            - A value to pass to the accumulator the first time it is run.
---
--- Returns:
--- * The new `Observable`.
function Observable:scan(accumulator, seed)
  return Observable.create(function(observer)
    local result = seed
    local first = true

    local function onNext(...)
      if first and seed == nil then
        result = ...
        first = false
      else
        return util.tryWithObserver(observer, function(...)
          result = accumulator(result, ...)
          observer:onNext(result)
        end, ...)
      end
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:skip([n]) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that skips over a specified number of values produced by the original
--- and produces the rest.
---
--- Parameters:
--- * n       - The number of values to ignore. Defaults to `1`.
---
--- Returns:
--- * The new `Observable`
function Observable:skip(n)
  n = n or 1

  return Observable.create(function(observer)
    local i = 1

    local function onNext(...)
      if i > n then
        observer:onNext(...)
      else
        i = i + 1
      end
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:skipLast(count) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that omits a specified number of values from the end of the original `Observable`.
---
--- Parameters:
--- * count     - The number of items to omit from the end.
---
--- Returns:
--- * The new `Observable`.
function Observable:skipLast(count)
  local buffer = {}
  return Observable.create(function(observer)
    local function emit()
      if #buffer > count and buffer[1] then
        local values = table.remove(buffer, 1)
        observer:onNext(util.unpack(values))
      end
    end

    local function onNext(...)
      emit()
      table.insert(buffer, util.pack(...))
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      emit()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:skipUntil(other) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that skips over values produced by the original until the specified
--- `Observable` produces a value.
---
--- Parameters:
--- * other     - The `Observable` that triggers the production of values.
---
--- Returns:
--- * The new `Observable`.
function Observable:skipUntil(other)
  return Observable.create(function(observer)
    local triggered = false
    local function trigger()
      triggered = true
    end

    other:subscribe(trigger, trigger, trigger)

    local function onNext(...)
      if triggered then
        observer:onNext(...)
      end
    end

    local function onError()
      if triggered then
        observer:onError()
      end
    end

    local function onCompleted()
      if triggered then
        observer:onCompleted()
      end
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:skipWhile(predicate) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that skips elements until the predicate returns `falsy` for one of them.
---
--- Parameters:
--- * predicate     - The predicate `function` used to continue skipping values.
---
--- Returns:
--- * The new `Observable`.
function Observable:skipWhile(predicate)
  predicate = predicate or util.identity

  return Observable.create(function(observer)
    local skipping = true

    local function onNext(...)
      if skipping then
        util.tryWithObserver(observer, function(...)
          skipping = predicate(...)
        end, ...)
      end

      if not skipping then
        return observer:onNext(...)
      end
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:startWith(...) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces the specified values followed by all elements produced by
--- the source `Observable`.
---
--- Parameters:
--- * values    - The values to produce before the Observable begins producing values normally.
---
--- Returns:
--- * The new `Observable`.
function Observable:startWith(...)
  local values = util.pack(...)
  return Observable.create(function(observer)
    observer:onNext(util.unpack(values))
    return self:subscribe(observer)
  end)
end

--- cp.rx.Observable:sum() -> cp.rx.Observable
--- Method
--- Returns an `Observable` that produces a single value representing the sum of the values produced
--- by the original.
---
--- Returns:
--- * The new `Observable`.
function Observable:sum()
  return self:reduce(function(x, y) return x + y end, 0)
end

--- cp.rx.Observable:switch() -> cp.rx.Observable
--- Method
--- Given an `Observable` that produces `Observables`, returns an `Observable` that produces the values
--- produced by the most recently produced `Observable`.
---
--- Returns:
--- * The new `Observable`.
function Observable:switch()
  return Observable.create(function(observer)
    local reference

    local function onNext(...)
      return observer:onNext(...)
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    local function switch(source)
      if reference then
        reference:cancel()
      end

      reference = source:subscribe(onNext, onError, nil)
    end

    return self:subscribe(switch, onError, onCompleted)
  end)
end

--- cp.rx.Observable:take([n]) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that only produces the first n results of the original.
---
--- Parameters:
--- * n       - The number of elements to produce before completing. Defaults to `1`.
---
--- Returns:
--- * The new `Observable`.
function Observable:take(n)
  n = n or 1

  return Observable.create(function(observer)
    if n <= 0 then
      observer:onCompleted()
      return
    end

    local i = 1
    local done = false
    local ref

    local function onCompleted()
      if not done then
        done = true
        if ref then
          ref:cancel()
        end
        if i <= n then
          observer:onError(format("Expected at least %d, got %d.", n, i-1))
        else
          observer:onCompleted()
        end
      end
    end

    local function onNext(...)
      if not done and i <= n then
        i = i + 1
        observer:onNext(...)

        if i > n then
          onCompleted()
        end
      end
    end

    local function onError(e)
      if not done then
        done = true
        if ref then
          ref:cancel()
        end
        return observer:onError(e)
      end
    end

    ref = self:subscribe(onNext, onError, onCompleted)

    return Reference.create(function()
      done = true
      if ref then
        ref:cancel()
      end
    end)
  end)
end

--- cp.rx.Observable:takeLast(count) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that produces a specified number of elements from the end of a source
--- `Observable`.
---
--- Parameters:
--- * count   - The number of elements to produce.
---
--- Returns:
--- * The new `Observable`.
function Observable:takeLast(count)
  return Observable.create(function(observer)
    local buffer = {}

    local function onNext(...)
      table.insert(buffer, util.pack(...))
      if #buffer > count then
        table.remove(buffer, 1)
      end
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      for i = 1, #buffer do
        observer:onNext(util.unpack(buffer[i]))
      end
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:takeUntil(other) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that completes when the specified `Observable` fires.
---
--- Parameters:
--- * other     - The `Observable` that triggers completion of the original.
---
--- Returns:
--- * The new `Observable`.
function Observable:takeUntil(other)
  return Observable.create(function(observer)
    local function onNext(...)
      return observer:onNext(...)
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    other:subscribe(onCompleted, onCompleted, onCompleted)

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:takeWhile(predicate) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` that produces elements until the predicate returns `falsy`.
---
--- Parameters:
--- * predicate       - The predicate `function` used to continue production of values.
---
--- Returns:
--- * The new `Observable`.
function Observable:takeWhile(predicate)
  predicate = predicate or util.identity

  return Observable.create(function(observer)
    local taking = true

    local function onNext(...)
      if taking then
        util.tryWithObserver(observer, function(...)
          taking = predicate(...)
        end, ...)

        if taking then
          return observer:onNext(...)
        else
          return observer:onCompleted()
        end
      end
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:tap(onNext[, onError[, onCompleted]]) -> cp.rx.Observable
--- Method
--- Runs a `function` each time this `Observable` has activity. Similar to [subscribe](#subscribe) but does not
--- create a subscription.
---
--- Parameters:
--- * onNext        - Run when the `Observable` produces values.
--- * onError       - Run when the `Observable` encounters a problem.
--- * onCompleted   - Run when the `Observable` completes.
---
--- Returns:
--- * The new `Observable`.
function Observable:tap(_onNext, _onError, _onCompleted)
  _onNext = _onNext or util.noop
  _onError = _onError or util.noop
  _onCompleted = _onCompleted or util.noop

  return Observable.create(function(observer)
    local function onNext(...)
      util.tryWithObserver(observer, function(...)
        _onNext(...)
      end, ...)

      return observer:onNext(...)
    end

    local function onError(message)
      util.tryWithObserver(observer, function()
        _onError(message)
      end)

      return observer:onError(message)
    end

    local function onCompleted()
      util.tryWithObserver(observer, function()
        _onCompleted()
      end)

      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:timeout(timeInMs, next[, scheduler]) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that will emit an error if the specified time is exceded since the most recent `next` value.
---
--- Parameters:
--- * timeInMs          - The time in milliseconds to wait before an error is emitted.
--- * next              - If a `string`, it will be sent as an error. If an `Observable`, it will be passed on instead of an error.
--- * scheduler         - The scheduler to use. Uses the [defaultScheduler](cp.rx.util#defaultSubscriber) if not provided.
---
--- Returns:
--- * The new `Observable`.
function Observable:timeout(timeInMs, next, scheduler)
    timeInMs = type(timeInMs) == "function" and timeInMs or util.constant(timeInMs)
    scheduler = scheduler or util.defaultScheduler()

    return Observable.create(function(observer)
        local kill, subscription

        local function clean()
            if kill then
                kill:cancel()
                kill = nil
            end
            if subscription then
                subscription:cancel()
                subscription = nil
            end
        end

        local function timedOut()
            clean()
            if Observable.is(next) then
                observer:onNext(next)
            else
                observer:onError(next or format("Timed out after %d ms.", timeInMs()))
            end
            kill = nil
        end

        local function onNext(...)
            -- restart the timer...
            if kill then
                kill:cancel()
                kill = scheduler:schedule(timedOut, timeInMs())
                observer:onNext(...)
            end
        end

        local function onError(message)
            clean()
            return observer:onError(message)
        end

        local function onCompleted()
            clean()
            return observer:onCompleted()
        end

        kill = scheduler:schedule(timedOut, timeInMs())
        subscription = self:subscribe(onNext, onError, onCompleted)
        return subscription
      end)
end

--- cp.rx.Observable:unpack() -> cp.rx.Observable
--- Method
--- Returns an `Observable` that unpacks the `tables` produced by the original.
---
--- Returns:
--- * The new `Observable`.
function Observable:unpack()
  return self:map(util.unpack)
end

--- cp.rx.Observable:unwrap() -> cp.rx.Observable
--- Method
--- Returns an `Observable` that takes any values produced by the original that consist of multiple
--- return values and produces each value individually.
---
--- Returns:
--- * The new `Observable`.
function Observable:unwrap()
  return Observable.create(function(observer)
    local function onNext(...)
      local values = {...}
      for i = 1, #values do
        observer:onNext(values[i])
      end
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:window(size) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that produces a sliding window of the values produced by the original.
---
--- Parameters:
--- * size      - The size of the window. The returned `Observable` will produce this number
---               of the most recent values as multiple arguments to `onNext`.
---
--- Returns:
--- * The new `Observable`.
function Observable:window(size)
  return Observable.create(function(observer)
    local window = {}

    local function onNext(value)
      table.insert(window, value)

      if #window >= size then
        observer:onNext(util.unpack(window))
        table.remove(window, 1)
      end
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable:with(...) -> cp.rx.Observable
--- Method
--- Returns an `Observable` that produces values from the original along with the most recently
--- produced value from all other specified `Observables`. Note that only the first argument from each
--- source `Observable` is used.
---
--- Parameters:
--- * ...       - The `Observables` to include the most recent values from.
---
--- Returns:
--- * The new `Observable`.
function Observable:with(...)
  local sources = {...}

  return Observable.create(function(observer)
    local latest = setmetatable({}, {__len = util.constant(#sources)})

    local function setLatest(i)
      return function(value)
        latest[i] = value
      end
    end

    local function onNext(value)
      return observer:onNext(value, util.unpack(latest))
    end

    local function onError(e)
      return observer:onError(e)
    end

    local function onCompleted()
      return observer:onCompleted()
    end

    for i = 1, #sources do
      sources[i]:subscribe(setLatest(i), util.noop, util.noop)
    end

    return self:subscribe(onNext, onError, onCompleted)
  end)
end

--- cp.rx.Observable.zip(...) -> cp.rx.Observable
--- Constructor
--- Returns an `Observable` that merges the values produced by the source `Observables` by grouping them
--- by their index.  The first `onNext` event contains the first value of all of the sources, the
--- second `onNext` event contains the second value of all of the sources, and so on.  `onNext` is called
--- a number of times equal to the number of values produced by the `Observable` that produces the
--- fewest number of values.
---
--- Parameters:
--- * ...       - The `Observables` to zip.
---
--- Returns:
--- * The new `Observable`.
function Observable.zip(...)
  local sources = util.pack(...)
  local count = #sources

  -- log.df("zip: count = %d", count)

  return Observable.create(function(observer)
    local values = {}
    local active = {}
    for i = 1, count do
      values[i] = {n = 0}
      active[i] = true
    end

    local function onNext(i)
      return function(...)
        table.insert(values[i], util.pack(...))
        values[i].n = values[i].n + 1

        local ready = true
        for j = 1, count do
          if values[j].n == 0 then
            ready = false
            break
          end
        end

        if ready then
          local payload = {}

          for j = 1, count do
            local args = table.remove(values[j], 1)
            for _,arg in ipairs(args) do
                table.insert(payload, arg)
            end
            values[j].n = values[j].n - 1
          end

          observer:onNext(util.unpack(payload))
        end
      end
    end

    local function onError(message)
      return observer:onError(message)
    end

    local function onCompleted(i)
      return function()
        -- log.df("zip: completed #%d", i)
        active[i] = nil
        if not next(active) or values[i].n == 0 then
            -- log.df("zip: sending completed...")
          return observer:onCompleted()
        end
      end
    end

    for i = 1, count do
      sources[i]:subscribe(onNext(i), onError, onCompleted(i))
    end
  end)
end

--- === cp.rx.ImmediateScheduler ===
---
--- Schedules `Observables` by running all operations immediately.
local ImmediateScheduler = {}
ImmediateScheduler.__index = ImmediateScheduler
ImmediateScheduler.__tostring = util.constant('ImmediateScheduler')

--- cp.rx.ImmediateScheduler.create() -> cp.rx.ImmediageScheduler
--- Constructor
--- Creates a new `ImmediateScheduler`.
---
--- Returns:
--- * The new `ImmediateScheduler`.
function ImmediateScheduler.create()
  return setmetatable({}, ImmediateScheduler)
end

--- cp.rx.ImmediateScheduler:schedule(action) -> cp.rx.Reference
--- Method
--- Schedules a `function` to be run on the scheduler. It is executed immediately.
---
--- Parameters:
--- * action    - The `function` to execute.
---
--- Returns:
--- * The [Reference](cp.rx.Reference.md).
function ImmediateScheduler:schedule(action) --luacheck: ignore
  action()
  return Reference.create()
end

--- === cp.rx.CooperativeScheduler ===
---
--- Manages [Observables](cp.rx.Observer.md) using `coroutines` and a virtual clock that must be updated
--- manually.
local CooperativeScheduler = {}
CooperativeScheduler.__index = CooperativeScheduler
CooperativeScheduler.__tostring = util.constant('CooperativeScheduler')

--- cp.rx.CooperativeScheduler.create([currentTime]) -> cp.rx.CooperativeScheduler
--- Constructor
--- Creates a new `CooperativeScheduler`.
---
--- Parameters:
--- * currentTime     - A time to start the scheduler at. Defaults to `0`.
---
--- Returns:
--- * The new `CooperativeScheduler`.
function CooperativeScheduler.create(currentTime)
  local self = {
    tasks = {},
    currentTime = currentTime or 0
  }

  return setmetatable(self, CooperativeScheduler)
end

--- cp.rx.CooperativeScheduler:schedule(action[, delay]) -> cp.rx.Reference
--- Method
--- Schedules a `function` to be run after an optional delay.  Returns a [Reference](cp.rx.Reference.md) that will stop
--- the action from running.
---
--- Parameters:
--- * action      - The `function` to execute. Will be converted into a coroutine. The
---                 coroutine may yield execution back to the scheduler with an optional
---                 number, which will put it to sleep for a time period.
--- * delay       - Delay execution of the action by a virtual time period. Defaults to `0`.
---
--- Returns:
--- * The [Reference](cp.rx.Reference.md).
function CooperativeScheduler:schedule(action, delay)
  local task = {
    thread = coroutine.create(action),
    due = self.currentTime + (delay or 0)
  }

  table.insert(self.tasks, task)

  return Reference.create(function()
    return self:unschedule(task)
  end)
end

function CooperativeScheduler:unschedule(task)
  for i = 1, #self.tasks do
    if self.tasks[i] == task then
      table.remove(self.tasks, i)
    end
  end
end

--- cp.rx.CooperativeScheduler:update(delta) -> nil
--- Method
--- Triggers an update of the `CooperativeScheduler`. The clock will be advanced and the scheduler
--- will run any coroutines that are due to be run.
---
--- Parameters:
--- * delta     - An amount of time to advance the clock by. It is common to pass in the
--                time in seconds or milliseconds elapsed since this function was last
--                called. Defaults to `0`.
function CooperativeScheduler:update(delta)
  self.currentTime = self.currentTime + (delta or 0)

  local i = 1
  while i <= #self.tasks do
    local task = self.tasks[i]

    if self.currentTime >= task.due then
      local success, delay = coroutine.resume(task.thread)

      if coroutine.status(task.thread) == 'dead' then
        table.remove(self.tasks, i)
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
--- Returns:
--- * `true` if the scheduler is empty, otherwise `false`.
function CooperativeScheduler:isEmpty()
  return not next(self.tasks)
end

--- === cp.rx.TimeoutScheduler ===
---
--- A scheduler that uses the `hs.timer` library to schedule events on an event loop.
local TimeoutScheduler = {}
TimeoutScheduler.__index = TimeoutScheduler
TimeoutScheduler.__tostring = util.constant('TimeoutScheduler')

--- cp.rx.TimeoutScheduler.create() -> cp.rx.TimeoutScheduler
--- Method
--- Creates a new `TimeoutScheduler`.
---
--- Returns:
--- * The new `TimeoutScheduler`.
function TimeoutScheduler.create()
  return setmetatable({_timers = {}}, TimeoutScheduler)
end

--- cp.rx.TimeoutScheduler:schedule(action[, delay]) -> cp.rx.TimeoutScheduler
--- Method
--- Schedules an action to run at a future point in time.
---
--- Parameters:
--- * action  - The action to run.
--- * delay   - The delay, in milliseconds. Defaults to `0`.
---
--- Returns:
--- * The [Reference](cp.rx.Reference.md).
function TimeoutScheduler:schedule(action, delay)
  delay = delay or 0
  local t = timer.doAfter(delay/1000.0, action)
  self._timers[t] = true

  return Reference.create(function()
    t:stop()
    self._timers[t] = nil
  end)
end

--- cp.rx.TimeoutScheduler:stopAll() -> nil
--- Method
--- Stops all future timers from running and clears them.
function TimeoutScheduler:stopAll()
    for t,_ in pairs(self._timers) do
        t:stop()
    end
    self._timers = {}
end

-- default to using the TimeoutScheduler
util.defaultScheduler(TimeoutScheduler.create())

--- === cp.rx.Subject ===
---
--- `Subjects` function both as an [Observer](cp.rs.Observer.md) and as an [Observable](cp.rx.Observable.md). Subjects inherit all
--- `Observable` functions, including [subscribe](#subscribe). Values can also be pushed to the `Subject`, which will
--- be broadcasted to any subscribed [Observers](cp.rx.Observers.md).
local Subject = setmetatable({}, Observable)
Subject.__index = Subject
Subject.__tostring = util.constant('Subject')

---- Creates a new Subject.
-- @returns {Subject}
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
--- * observer | onNext     - Either an [Observer](cp.rx.Observer.md), or a `function` called
---                           when the `Subject` produces a value.
--- * onError               - A `function` called when the `Subject` terminates due to an error.
--- * onCompleted           - A `function` called when the `Subject` completes normally.
---
--- Returns:
--- * The [Reference](cp.rx.Reference.md)
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

  table.insert(self.observers, observer)

  return Reference.create(function()
    for i = 1, #self.observers do
      if self.observers[i] == observer then
        table.remove(self.observers, i)
        return
      end
    end
  end)
end

-- cp.rx.Subject:_stop() -> nil
-- Method
-- Stops future signals from being sent, and unsubscribs any observers.
function Subject:_stop()
  self.stopped = true
  self.observers = {}
end

--- cp.rx.Subject:onNext(...) -> nil
--- Method
--- Pushes zero or more values to the `Subject`. They will be broadcasted to all [Observers](cp.rx.Observer.md).
---
--- Parameters:
--- * ...       - The values to send.
function Subject:onNext(...)
  if not self.stopped then
    for i = 1, #self.observers do
      self.observers[i]:onNext(...)
    end
  end
end

--- cp.rx.Subject:onError(message) -> nil
--- Method
--- Signal to all `Observers` that an error has occurred.
---
--- Parameters:
--- * message     - A string describing what went wrong.
function Subject:onError(message)
  if not self.stopped then
    for i = 1, #self.observers do
      self.observers[i]:onError(message)
    end

    self:_stop()
  end
end

--- cp.rx.Subject:onCompleted() -> nil
--- Method
--- Signal to all [Observers](cp.rx.Observer.md) that the `Subject` will not produce any more values.
function Subject:onCompleted()
  if not self.stopped then
    for i = 1, #self.observers do
      self.observers[i]:onCompleted()
    end

    self:_stop()
  end
end

Subject.__call = Subject.onNext

--- === cp.rx.AsyncSubject ===
---
--- `AsyncSubjects` are subjects that produce either no values or a single value.  If
--- multiple values are produced via `onNext`, only the last one is used.  If `onError` is called, then
--- no value is produced and `onError` is called on any subscribed [Observers](cp.rx.Observers.md).
--- If an [Observer](cp.rx.Observer.md) subscribes and the `AsyncSubject` has already terminated,
--- the `Observer` will immediately receive the value or the error.
local AsyncSubject = setmetatable({}, Observable)
AsyncSubject.__index = AsyncSubject
AsyncSubject.__tostring = util.constant('AsyncSubject')

--- cp.rx.AsyncSubject.create() -> cp.rx.AsyncSubject
--- Constructor
--- Creates a new `AsyncSubject`.
---
--- Returns:
--- * The new `AsyncSubject`.
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
--- * onNext | observer - A `function` called when the `AsyncSubject` produces a value
---                       or an existing [Observer](cp.rx.Observer.md) to attach to the `AsyncSubject`.
--- * onError           - A `function` called when the `AsyncSubject` terminates due to an error.
--- * onCompleted       - A `funtion` called when the `AsyncSubject` completes normally.
---
--- Returns:
--- * The [Reference](cp.rx.Reference.md).
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
    table.insert(self.observers, observer)

    return Reference.create(function()
      for i = 1, #self.observers do
        if self.observers[i] == observer then
          table.remove(self.observers, i)
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
--- * ...       - The values to send.
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
--- * message     - A string describing what went wrong.
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

--- === cp.rx.BehaviorSubject ===
---
--- A [Subject](cp.rx.Subject.md) that tracks its current value. Provides an accessor to retrieve the most
--- recent pushed value, and all subscribers immediately receive the latest value.
local BehaviorSubject = setmetatable({}, Subject)
BehaviorSubject.__index = BehaviorSubject
BehaviorSubject.__tostring = util.constant('BehaviorSubject')

--- cp.rx.BehaviorSubject.create(...) -> cp.rx.BehaviorSubject
--- Method
--- Creates a new `BehaviorSubject`.
---
--- Parameters:
--- * ...     - The initial values.
---
--- Returns:
--- * The new `BehaviorSubject`.
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
--- * observer | onNext       - The [Observer](cp.rx.Observer.md) subscribing, or the `function` called when the
---                             `BehaviorSubject` produces a value.
--- * onError                 - A `function` called when the `BehaviorSubject` terminates due to an error.
--- * onCompleted             - A `function` called when the `BehaviorSubject` completes normally.
---
--- Returns:
--- * The [Reference](cp.rx.Reference.md)
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
--- * ...     - The values to send.
function BehaviorSubject:onNext(...)
  self.value = util.pack(...)
  return Subject.onNext(self, ...)
end

--- cp.rx.BehaviorSubject:getValue() -> anything
--- Method
--- Returns the last value emitted by the `BehaviorSubject`, or the initial value passed to the
--- constructor if nothing has been emitted yet.
---
--- Returns:
--- * The last value.
---
--- Note:
--- * You can also call the `BehaviorSubject` as a function to retrieve the value. E.g. `mySubject()`.
function BehaviorSubject:getValue()
  if self.value ~= nil then
    return util.unpack(self.value)
  end
end

BehaviorSubject.__call = BehaviorSubject.onNext

--- === cp.rx.RelaySubject ===
---
--- A [Subject](cp.rx.Subject.md) that provides new [Observers](cp.rx.Observer.md) with some or all of the most recently
--- produced values upon reference.
local ReplaySubject = setmetatable({}, Subject)
ReplaySubject.__index = ReplaySubject
ReplaySubject.__tostring = util.constant('ReplaySubject')

--- cp.rx.RelaySubject.create([n]) -> cp.rx.RelaySubject
--- Constructor
--- Creates a new `ReplaySubject`.
---
--- Parameters:
--- * bufferSize      - The number of values to send to new subscribers. If `nil`, an infinite
---                     buffer is used (note that this could lead to memory issues).
---
--- Returns:
--- * The new `ReplaySubject.
function ReplaySubject.create(n)
  local self = {
    observers = {},
    stopped = false,
    buffer = {},
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
--- * observer | onNext     - Either an [Observer](cp.rx.Observer.md), or a
---                           `function` to call when the `ReplaySubject` produces a value.
--- * onError               - A `function` to call when the `ReplaySubject` terminates due to an error.
--- * onCompleted           - A `function` to call when the ReplaySubject completes normally.
---
--- Returns:
--- * The [Reference](cp.rx.Reference.md).
function ReplaySubject:subscribe(onNext, onError, onCompleted)
  local observer

  if util.isa(onNext, Observer) then
    observer = onNext
  else
    observer = Observer.create(onNext, onError, onCompleted)
  end

  local reference = Subject.subscribe(self, observer)

  for i = 1, #self.buffer do
    observer:onNext(util.unpack(self.buffer[i]))
  end

  return reference
end

--- cp.rx.RelaySubject:onNext(...) -> nil
--- Method
--- Pushes zero or more values to the `ReplaySubject`. They will be broadcasted to all [Observers](cp.rx.Observer.md).
---
--- Parameters:
--- * ...   - The values to send.
function ReplaySubject:onNext(...)
  table.insert(self.buffer, util.pack(...))
  if self.bufferSize and #self.buffer > self.bufferSize then
    table.remove(self.buffer, 1)
  end

  return Subject.onNext(self, ...)
end

ReplaySubject.__call = ReplaySubject.onNext

Observable.wrap = Observable.buffer
Observable['repeat'] = Observable.replicate

return {
  util = util,
  Reference = Reference,
  Observer = Observer,
  Observable = Observable,
  ImmediateScheduler = ImmediateScheduler,
  CooperativeScheduler = CooperativeScheduler,
  TimeoutScheduler = TimeoutScheduler,
  Subject = Subject,
  AsyncSubject = AsyncSubject,
  BehaviorSubject = BehaviorSubject,
  ReplaySubject = ReplaySubject
}
