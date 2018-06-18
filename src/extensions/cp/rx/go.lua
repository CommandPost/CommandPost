--- === cp.rx.go ===
---
--- Adds `Statements` to make processing of `cp.rx.Observable` values
--- in ways that are more familiar to synchronous programmers.
---
--- A common activity is to perform some tasks, wait for the results and
--- do some more work with those results.
---
--- Lets say you want to calculate the price of an item that is in USD and
--- output it in AUD. We have `anItem` that will return an `Observable`
--- that fetches the item price, and an `exchangeRate` function that will
--- fetch the current exchange rate for two currencies.
---
--- Using reactive operators, you could use the `zip` function to achieve this:
---
--- ```lua
--- Observable.zip(
---     anItem:priceInUSD(),
---     exchangeRate("USD", "AUD")
--- )
--- :subscribe(function(price, rate)
---     print "AUD Price: ", price * rate
--- end)
--- ```
---
--- The final subscription will only be executed once both `anObservable` and `anotherObservable` push
--- a value. It will continue calling it while both keep producing values, but will complete if any of them
--- complete.
---
--- Using the `Given` statement it would look like this:
---
--- ```lua
--- Given(
---    anItem:priceInUSD(),
---    exchangeRate("USD", "AUD"),
--- )
--- :Now(function(price, rate)
---     print "AUD Price: ", price * rate
--- end)
--- ```

-- local log           = require("hs.logger").new("rxgo")
local inspect       = require("hs.inspect")

local prop          = require("cp.prop")
local rx            = require("cp.rx")

local Observable    = rx.Observable
local Observer      = rx.Observer
local insert        = table.insert
local pack, unpack  = table.pack, table.unpack
local format        = string.format

local Statement, SubStatement
local toObservable, toObservables

-----------------------------------------------------------
-- Utility functions
-----------------------------------------------------------

-- private key for storing the metadata table for instances.
local METADATA = {}

local function is(thing, class)
    if type(thing) == "table" then
        class = class.mt or class
        return thing == class or is(getmetatable(thing), class)
    end
    return false
end

local function append(tbl, ...)
    for _,v in ipairs(pack(...)) do
        insert(tbl, v)
    end
    return tbl
end

--- cp.rx.go.toObservable(thing[, params]) -> cp.rx.Observable
--- Function
--- Converts the `thing` into an `Observable`. It converts the following:
---
--- * `Observable`          - Returned unchanged.
--- * `cp.rx.go.Statement`  - Returns the result of the `toObservable()` method. Note: this will cancel any scheduled executions for the Statement.
--- * `cp.prop`             - Returns the `cp.prop:observe()` value.
--- * `function`            - Executes the function, passing in the `params` as a list of values, returning the results converted to an `Observable`.
--- * Other values          - Returned via `Observable.of(thing)`.
---
--- Note that with `functions`, the function is not executed immediately, but it will be passed the params as
--- a list when the resulting `Observable` is subscribed to. For example:
---
--- ```lua
--- -- set up the function
--- multiply = toObservable(function(one, two) return one * two end, {2, 3})
--- -- nothing has happened yet
--- multiply:subscribe(function(result) print(result) end)
--- -- now the function has been executed
--- ```
--- This results in printing `6`.
---
--- Parameters:
---  * thing    - The thing to convert.
---  * params   - Optional table list to pass as parameters for the `thing` if it's a `function`.
---
--- Returns:
---  * The `Observable`.
toObservable = function(thing, params)
    if type(thing) == "function" then
        local results = pack(thing(unpack(params or {})))
        if #results > 1 then
            return Observable.zip(unpack(toObservables(results)))
        else
            return toObservable(results[1])
        end
    end

    local obs
    if Observable.is(thing) then
        obs = thing
    elseif Statement.is(thing) then
        obs = thing:toObservable()
    elseif prop.is(thing) then
        obs = thing:observe()
    else
        obs = Observable.of(thing)
    end

    return obs or Observable.empty()
end

--- cp.rx.go.toObservables(things[, params]) -> table
--- Function
--- Converts a list of things into a list of `Observables` of those things.
---
--- For example:
--- ```lua
--- result = toObservables({1, 2, 3})
--- for _,o in ipairs(results) do
---     o:subscribe(function(x) print x end)
--- end
---
--- If any of the things are `function`s, then the `params` table is unpacked to a list
--- and passed into the function when it is called. For example:
---
--- ```lua
--- toObservables({function(x) return x * 2 end}, {3})
---     :subscribe(function(x) print end) -- outputs 6
--- ```
---
--- Any type supported by [toObservable](#toObservable) can be included in the `things` array.
---
--- Parameters:
---  * things       - a table list of things to convert to `Observables`.
---  * params       - an optional table list of parameters to pass to any `function` things.
---
--- Returns:
---  * A table list of the things, converted to `Observable`.
toObservables = function(things, params)
    local observables = {}
    for _,thing in ipairs(things) do
        insert(observables, toObservable(thing, params))
    end
    return observables
end

-----------------------------------------------------------
-- Statement and Statement Definition
-----------------------------------------------------------

Statement = {}
Statement.mt = {}
Statement.mt.__index = Statement.mt

Statement.Definition = {}
Statement.Definition.mt = {}
Statement.Definition.mt.__index = Statement.Definition.mt

-- cp.rx.go.Statement.Definition.new(name) -> Statement.Definition
-- Constructor
-- Creates a new Statement Definition.
--
-- Parameters:
--  * name     - The name of the statement.
--
-- Returns:
--  * The new Statement Definition.
function Statement.Definition.new(name)
    assert(type(name) == "string" and name:len() > 0, "Parameter #1 must be a non-empty string")
    return setmetatable({
        name = name,
    }, Statement.Definition.mt)
end

function Statement.Definition.is(thing)
    return type(thing) == "table" and is(thing.mt, Statement)
end

-- just outputs an error if you accidentally don't `define` the statement.
function Statement.Definition.mt:__call()
    error(format("The '%s' statement was not fully defined. Ensure you call `define()` to complete it.", self._statement.name))
end

--- cp.rx.go.Statement.Definition:onInit(initFn) -> Statement.Definition
--- Method
--- Defines the function which will be called to initialise the context.
--- The function will be passed the `context` table as the first parameter,
--- and any other parameters passed to the statement follow.
---
--- For example:
--- ```lua
--- local DoSomething = Statement.named("DoSomething")
--- :onInit(function(context, one, two)
---     context.one, context.two = one, two
--- end):onObserver(...):define()
---
--- DoSomething(1, 2):Now()
--- ```
---
--- Parameters:
---  * initFn       - The init function.
---
--- Returns:
---  * The Statement Definition
function Statement.Definition.mt:onInit(initFn)
    assert(type(initFn) == "function", "Parameter #1 must be a function")
    self._onInit = initFn
    return self
end

--- cp.rx.go.Statement.Definition:onObservable(observableFn) -> Statement.Definition
--- Method
--- Defines the function which will be called to create the `Observable` for the statement.
--- The function will be passed the `context` table and must return an `Observable`.
---
--- Parameters:
---  * observableFn     - The observable creator function.
---
--- Returns:
---  * The Statement Definition
function Statement.Definition.mt:onObservable(observableFn)
    assert(type(observableFn) == "function", "Parameter #1 must be a function")
    self._onObservable = observableFn
    return self
end

--- cp.rx.go.Statement.Definition:define() -> Statement
--- Method
--- Completes the definition of the statement, returning the new `Statement`.
---
--- For example:
--- ```lua
--- local DoSomething = Statement.named("DoSomething")
--- :onInit(function(context, param) context.param = param)
--- :onOnObservable(function(context) return Observable.of(context.param) end)
--- :define()
--- ```
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new Statement definition.
function Statement.Definition.mt:define()
    if self.onObservable == nil then
        error("All Statements must define an `onObservable` handler.")
    end

    -- details that apply to all instances of the definition.
    local metadata = {
        name = self.name,
        onInit = self._onInit,
        onObservable = self._onObservable
    }

    -- the new statement definition
    local statement = {}

    -- the 'class' for statement instances.
    statement.mt = setmetatable({
        [METADATA] = metadata,
    }, Statement.mt)
    statement.mt.__index = statement.mt
    statement.mt.__call = Statement.mt.__call

    -- provides an `is` function to test instances
    function statement.is(thing)
        return is(thing, statement.mt)
    end

    -- allow creating of a `modifier` statement
    function statement.modifier(...)
        return SubStatement.Definition.new(statement, ...)
    end

    setmetatable(statement, {
        __call = function(_, ...)
                -- it's a top-level statement
            return setmetatable({}, statement.mt)(...)
        end,

        -- outputs the statement name when converted to a string.
        __tostring = function()
            return metadata.name
        end,
    })

    return statement
end

--- cp.rx.go.Statement.named(named) -> Statement.Definition
--- Function
--- Starts the definition of a new `Statement` with the specified names.
---
--- Statements may have an `onInit`, and must have an `onObservable` provided,
--- and then the `define` method must be called.
---
--- For example:
--- ```lua
--- local DoSomething = Statement.named("DoSomething")
--- :onInit(function(context, param1, param2) ... end)
--- :onObserver(function(context) return Observer.of(context.param1, context.param2) end)
--- :define()
--- ```
---
--- Parameters:
---  * name     - The name of the `Statement`.
---
--- Returns:
---  * A `Statement.Definition`.
function Statement.named(name)
    return Statement.Definition.new(name)
end

--- cp.rx.go.Statement.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `Statement`.
---
--- Parameters:
---  * thing        - The thing to test.
---
--- Returns:
---  * `true` if the thing is a `Statement`.
function Statement.is(thing)
    return is(thing, Statement)
end

-- stores the default observer
local defaultObserver = Observer.create(nil, error, nil)

--- cp.rx.go.Statement.defaultObserver([observer]) -> cp.rx.Observer
--- Function
--- Gets/sets the default observer for statements which are executed without one being provided.
--- By default, an `Observer` which only outputs errors via the standard `error` function is provided.
---
--- Parameters:
---  * observer     - if provided, replaces the current default `Observer` with the one specified.
---
--- Returns:
---  * The current default `Observer`.
function Statement.defaultObserver(observer)
    if observer then
        assert(Observer.is(observer), "Parameter #1 must be a cp.rx.Observer")
        defaultObserver = observer
    end
    return defaultObserver
end

--- cp.rx.go.Statement:name()
--- Method
--- Returns the Statement name.
---
--- Returns:
---  * The Statement name.
function Statement.mt:name()
    return self[METADATA].name
end

function Statement.mt:context()
    return self._context
end

--- cp.rx.go.Statement:fullName()
--- Method
--- Returns the Statement's full name.
---
--- Returns:
---  * The full Statement name.
function Statement.mt:fullName()
    return self:name()
end

function Statement.mt:__tostring()
    return self:fullName()
end

function Statement.mt:__call(...)
    self._context = {}
    local onInit = self[METADATA].onInit
    if onInit then
        onInit(self:context(), ...)
    end
    return self
end

--- cp.rx.go.Statement:toObservable([preserveTimer]) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` instance for the `Statement`.
---
--- Parameters:
---  * preserveTimer    - If a timer has been set via [After](#After), don't cancel it. Defaults to `false`.
---
--- Returns:
---  * The `Observable`.
function Statement.mt:toObservable(preserveTimer)
    if not preserveTimer and self._timer then
        self._timer:cancel()
        self._timer = nil
    end

    local onObservable = self[METADATA].onObservable
    local o = onObservable(self:context())

    -- Check if there is a 'catch'
    if self._catcher then
        o = o:catch(function(message)
            return toObservable(self._catcher(message))
        end)
    end

    return o
end

--- cp.rx.go.Statement:Catch(handler) -> cp.rx.go.Statement
--- Method
--- Assigns a handler which will be applied at the end of the Statement.
--- The function will receive the error signal and the returned value will be pass onwards.
---
--- Parameters:
---  * handler  - The handler function
---
--- Returns:
---  * The `Statement`.
function Statement.mt:Catch(handler)
    self._catcher = handler
    return self
end

--- cp.rx.go.Statement:Now([observer]) -> nil
--- Method
--- Executes the statment immediately.
---
--- Parameters:
--- * observer      - An observer to watch the resulting `Observable`. Defaults to `Statement.defaultObserver()`.
---
--- Returns:
--- * Nothing.
function Statement.mt:Now(onNext, onError, onCompleted)
    local obs = self:toObservable()
    if Observable.is(obs) then
        local observer = Statement.defaultObserver()
        if Observer.is(onNext) then
            observer = onNext
        elseif type(onNext) == "function" or type(onError) == "function" or type(onCompleted) == "function" then
            observer = Observer.create(onNext, onError, onCompleted)
        end
        -- TODO: add more complex options for handling 'after'
        obs:subscribe(observer)
    else
        error(format("Expected an Observable but got %s", inspect(obs)))
    end
end

--- cp.rx.go.Statement:After(millis[, observer][, scheduler]) -> nil
--- Method
--- Requests the statement to be executed after the specified amount of time in seconds.
---
--- Parameters:
---  * millis      - The number of milliseconds to delay the execution.
---  * observer     - The observer to subscribe to the final result.
---  * scheduler    - (optional) the `cp.rx.Scheduler` to use. Uses the `cp.rx.util.defaultScheduler()` if none is provided.
---
--- Returns:
---  * Nothing.
function Statement.mt:After(millis, observer, scheduler)
    if not self._timer then
        -- shift the scheduler parameter if necessary
        if observer ~= nil and not Observer.is(observer) then
            scheduler = observer
            observer = nil
        end

        scheduler = scheduler or rx.util.defaultScheduler()
        self._timer = scheduler:schedule(function() self:Now(observer) end, millis)
    end
end

-----------------------------------------------------------
-- SubStatement and SubStatement Definition
-----------------------------------------------------------

SubStatement = {}
SubStatement.mt = setmetatable({}, Statement.mt)
SubStatement.mt.__index = SubStatement.mt

SubStatement.Definition = {}
SubStatement.Definition.mt = setmetatable({}, Statement.Definition.mt)
SubStatement.Definition.mt.__index = SubStatement.Definition.mt

-- cp.rx.go.Statement.Definition.new(name) -> Statement.Definition
-- Constructor
-- Creates a new Statement Definition.
--
-- Parameters:
--  * parent    - The parent Statement
--  * name      - The name of the statement.
--
-- Returns:
--  * The new Statement Definition.
function SubStatement.Definition.new(parent, ...)
    local names = pack(...)
    assert(#names > 0, "Parameter #2 must be a non-empty string.")
    local firstName = names[1]
    assert(type(firstName) == "string" and firstName:len() > 0, "Parameter #2 must be a non-empty string")
    return setmetatable({
        names = names,
        parent = parent,
    }, SubStatement.Definition.mt)
end

function SubStatement.Definition.allow(parent, subStatement)
    assert(SubStatement.Definition.is(subStatement), "Parameter #2 must be a SubStatement")
    local metadata = subStatement.mt[METADATA]
    if parent[metadata.name] ~= nil then
        error(format("There is already a '%s' SubStatement on '%s'", metadata.name, parent))
    end
    parent[metadata.name] = subStatement

    -- assign the Statement:SubStatement(...) method
    if parent.mt[metadata.name] ~= nil then
        error(format("There is already a '%s' method on '%s'", metadata.name, parent))
    end
    parent.mt[metadata.name] = function(this, ...)
        return subStatement(this, ...)
    end
end

function SubStatement.Definition.is(thing)
    return type(thing) == "table" and is(thing.mt, SubStatement)
end

--- cp.rx.go.SubStatement.Definition:define()
--- Method
--- Defines the sub-statement.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new SubStatement definition.
function SubStatement.Definition.mt:define()
    assert(self.parent ~= nil, "The parent of the SubStatement is not available.")
    local statements = {}

    for _,statementName in ipairs(self.names) do

        -- details that apply to all instances of the definition.
        local metadata = {
            name = statementName,
            onInit = self._onInit,
            onObservable = self._onObservable
        }

        -- the new statement definition
        local statement = {}

        -- the 'class' for statement instances.
        statement.mt = setmetatable({
            [METADATA] = metadata,
        }, SubStatement.mt)
        statement.mt.__index = statement.mt
        statement.mt.__call = SubStatement.mt.__call

        -- provides an `is` function to test instances
        function statement.is(thing)
            return is(thing, statement.mt)
        end

        -- creates a `modifier` statement
        function statement.modifier(first, ...)
            if type(first) == "string" then
                return SubStatement.Definition.new(statement, first, ...)
            else
                error(format("Parameter #1 must be either a string but was: %s", inspect(first)))
            end
        end

        -- allows an existing modifier to be applied to this SubStatement.
        function statement.allow(subStatement, ...)
            if not SubStatement.Definition.is(subStatement) then
                error(format("Parameter #1 must be a SubStatement Definition but was: %s", inspect(subStatement)))
            end
            return SubStatement.Definition.allow(statement, subStatement, ...)
        end

        setmetatable(statement, {
            -- called to execute the sub-statement.
            __call = function(_, parent, ...)
                return setmetatable({
                    _parent = parent,
                }, statement.mt)(...)
            end,

            -- outputs the statement name when converted to a string.
            __tostring = function()
                return tostring(self.parent) .. "..." .. metadata.name
            end,
        })

        self.parent[statementName] = statement
        self.parent.mt[statementName] = function(this, parent, ...)
            if self.parent ~= parent then
                return statement(this, parent, ...)
            end
            return statement(this, ...)
        end

        insert(statements, statement)
    end

    return unpack(statements)
end

function SubStatement.is(thing)
    return is(thing, SubStatement.mt)
end

function SubStatement.mt:context()
    return self._parent:context()
end

function SubStatement.mt:toObservable()
    local o = self._parent:toObservable()
    local metadata = self[METADATA]
    local onObservable = metadata.onObservable
    if onObservable then
        return onObservable(self:context(), o)
    else
        return o
    end
end

-----------------------------------------------------------
-- Some actual statements
-----------------------------------------------------------

-----------------------------------------------------------
-- Statement: Given...Then
-----------------------------------------------------------

--- cp.rx.go.Given <cp.rx.Statement>
--- Constant
--- A `Statement` that will execute the provided `resolvable` values and
--- This will resolve the provided values into `Observable`s and pass on the
--- first result of each to the next stage as individual parameters.
--- This will continue until one of the `Observables` has completed, at which
--- point other results from values are ignored.

--- cp.rx.go.Given(...) -> Given
--- Function
--- Begins the definition of a `Given` `Statement`.
---
--- This will resolve the provided values into `Observable`s and pass on the
--- first result of each to the next stage as individual parameters.
--- This will continue until one of the `Observables` has completed, at which
--- point other results from values are ignored.
---
--- For example:
---
--- ```lua
--- Given(Observable.of(1, 2, 3), Observable.of("a", "b"))
--- :Now(function(number, letter) print(tostring(number)..letter))
--- ```
---
--- This will result in:
---
--- ```
--- 1a
--- 2b
--- ```
---
--- For more power, you can add a `Then` to futher modify the results, or chain other operations.
--- See the `Given.Then` documentation for details.
---
--- Parameters:
---  * ...      - the list of `resolvable` values to evaluate.
---
--- Returns:
---  * A new `Given` `Statement` instance.
local Given = Statement.named("Given")
:onInit(function(context, ...)
    context.requirements = toObservables(pack(...))
    context.thens = {}
end)
:onObservable(function(context)
    local o = Observable.zip(unpack(context.requirements))
    for _,t in ipairs(context.thens) do
        o = o:flatMap(function(...)
            return Observable.zip(unpack(toObservables(t, pack(...))))
        end)
    end
    return o
end)
:define()

--- cp.rx.go.Given.Then <cp.rx.go.SubStatement>
--- Constant
--- This is a configuration of `Given`, which should be created via `Given:Then(...)`.
--- For example:
---
--- ```lua
--- Given(anObservable):Then(function(value) return value:doSomething() end)
--- ```

--- cp.rx.go.Given:Then(...) -> Given.Then
--- Method
--- Call this to define what will happen once the `Given` values resolve successfully.
--- The parameters can be any 'resolvable' type.
---
--- If a parameter is a `function`, it will be passed the results of the previous `Given` or `Then` parameters.
---
--- For example:
--- ```lua
--- Given(anObservable, anotherObservable)
--- :Then(function(aResult, anotherResult)
---     doSomethingWith(aResult, anotherResult)
---     return true
--- end)
--- ```
Given.modifier("Then")
:onInit(function(context, ...)
    insert(context.thens, pack(...))
end):define()

--- cp.rx.go.Given.Then:Then(...) -> Given.Then
--- Method
--- Allows another set of `resolvables` to be processed after a `Then`.
---
--- Parameters:
---  * ...      - The list of `resolvable` values to process.
---
--- Returns:
---  * Another `Given.Then` instance.
Given.Then.allow(Given.Then)

local function requireAll(observable)
    return observable:all()
end

--- cp.rx.go.Require <cp.rx.go.Statement>
--- Constant
---

local Require = Statement.named("Require")
:onInit(function(context, requirement)
    context.requirement = toObservable(requirement)
end)
:onObservable(function(context)
    local observable = context.requirement
    local filter = context.filter or requireAll
    observable = filter(observable)

    observable = observable:flatMap(function(success)
        if success then
            return Observable.of(success)
        else
            return Observable.throw(context.errorMessage or "Requirement not met.")
        end
    end)

    return observable
end)
:define()

Require.modifier("OrThrow")
:onInit(function(context, message)
    context.errorMessage = message
end)
:define()

Require.modifier("Is", "Are")
:onInit(function(context, value)
    context.filter = function(observable)
        return observable:all(function(result) return result == value end)
    end
end)
:define()

Require.Is.allow(Require.OrThrow)

Require.modifier("IsNot", "AreNot")
:onInit(function(context, value)
    context.filter = function(observable)
        return observable:all(function(result) return result ~= value end)
    end
end)
:define()

Require.IsNot.allow(Require.OrThrow)

local function isTruthy(value)
    return value ~= false and value ~= nil
end

local WaitUntil = Statement.named("WaitUntil")
:onInit(function(context, requirement)
    context.requirement = toObservable(requirement)
end)
:onObservable(function(context)
    local o = context.requirement

    local filter = context.filter or isTruthy
    o = o:find(filter)

    if context.timeout then
        o = o:timeout(context.timeout, context.message or format("Timed out after %d milliseconds", context.timeout))
    end

    return o
end)
:define()

WaitUntil.modifier("TimeoutAfter")
:onInit(function(context, millis, message)
    context.timeout = millis
    context.message = message
end)
:define()

WaitUntil.modifier("Is", "Are")
:onInit(function(context, thisValue)
    context.filter = function(value) return value == thisValue end
end)
:define()

-- Allow TimeoutAfter on Is and Are
WaitUntil.Is.allow(WaitUntil.TimeoutAfter)
WaitUntil.Are.allow(WaitUntil.TimeoutAfter)

WaitUntil.modifier("IsNot", "AreNot")
:onInit(function(context, thisValue)
    context.filter = function(value) return value ~= thisValue end
end)
:define()

-- allow TimeoutAfter on IsNot and AreNot
WaitUntil.IsNot.allow(WaitUntil.TimeoutAfter)
WaitUntil.AreNot.allow(WaitUntil.TimeoutAfter)

local First = Statement.named("First")
:onInit(function(context, reference)
    context.reference = toObservable(reference)
end)
:onObservable(function(context)
    return context.reference:first()
end)
:define()

local Throw = Statement.named("Throw")
:onInit(function(context, message, ...)
    context.message = message and format(message, ...) or nil
end)
:onObservable(function(context)
    return Observable.throw(context.message)
end)
:define()

local Done = Statement.named("Done")
:onObservable(function()
    return Observable.empty()
end)

local If = Statement.named("If")
:onInit(function(context, value)
    context.value = toObservable(value)
    context.filter = isTruthy
    context.thens = nil
    context.otherwises = {}
end)
:onObservable(function(context)
    assert(context.thens, "Please specify a 'Then'")

    -- we only deal with the first result
    local o = context.value:first()

    o = o:flatMap(function(...)
        if context.filter(...) then
            return Observable.zip(unpack(toObservables(context.thens, pack(...))))
        else
            return Observable.zip(unpack(toObservables(context.otherwises, pack(...))))
        end
    end)

    return o
end)
:define()

If.modifier("Then")
:onInit(function(context, ...)
    context.thens = pack(...)
end)
:define()

If.Then.modifier("Otherwise")
:onInit(function(context, ...)
    context.otherwises = pack(...)
end)
:define()

If.modifier("Is", "Are")
:onInit(function(context, value)
    context.filter = function(theValue) return theValue == value end
end)
:define()

If.Is.allow(If.Then)
If.Are.allow(If.Then)

If.modifier("IsNot", "AreNot")
:onInit(function(context, value)
    context.filter = function(theValue) return theValue ~= value end
end)
:define()

If.IsNot.allow(If.Then)
If.AreNot.allow(If.Then)

If.modifier("Matches")
:onInit(function(context, predicate)
    if type(predicate) ~= "function" then
        error(format("The 'Matches' predicate must be a function, but was: %s", inspect(predicate)))
    end
    context.filter = predicate
end)
:define()

If.Matches.allow(If.Then)

return {
    append = append,
    is = is,
    toObservable = toObservable,
    toObservables = toObservables,
    Statement = Statement,
    SubStatement = SubStatement,
    Given = Given,
    Require = Require,
    WaitUntil = WaitUntil,
    First = First,
    Throw = Throw,
    Done = Done,
    If = If,
}