-- local log           = require("hs.logger").new("rxgo")
local inspect       = require("hs.inspect")

local timer         = require("hs.timer")
local prop          = require("cp.prop")
local rx            = require("cp.rx")

local Observable    = rx.Observable
local Observer      = rx.Observer
local insert        = table.insert
local pack, unpack  = table.pack, table.unpack
local format        = string.format

local Statement, SubStatement

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

local function toObservable(thing, params)
    if type(thing) == "function" then
        thing = thing(unpack(params or {}))
    end

    local obs
    if Observable.is(thing) then
        obs = thing
    elseif Statement.is(thing) then
        obs = thing:observable()
    elseif prop.is(thing) then
        obs = thing:observe()
    else
        obs = Observable.of(thing)
    end

    return obs or Observable.empty()
end

local function toObservables(things, params)
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
    function statement.modifier(name)
        return SubStatement.Definition.new(name, statement)
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

--- cp.rx.go.Statement:toObservable() -> cp.rx.Observable
--- Method
--- Returns a new `Observable` instance for the `Statement`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Observable`.
function Statement.mt:toObservable()
    local onObservable = self[METADATA].onObservable
    local o = onObservable(self:context())
    return o
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

--- cp.rx.go.Statement:After(seconds) -> nil
--- Method
--- Requests the statement to be executed after the specified amount of time in seconds.
---
--- Parameters:
---  * seconds      - The number of seconds to delay the execution.
---
--- Returns:
---  * Nothing.
function Statement.mt:After(seconds)
    if not self._timer then
        self._timer = timer.doAfter(seconds, function() self:Now() end)
    else
        self._timer:setNextTrigger(seconds)
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
--  * name     - The name of the statement.
--
-- Returns:
--  * The new Statement Definition.
function SubStatement.Definition.new(name, parent)
    assert(type(name) == "string" and name:len() > 0, "Parameter #1 must be a non-empty string")
    return setmetatable({
        name = name,
        parent = parent,
    }, SubStatement.Definition.mt)
end

function SubStatement.Definition.apply(subStatement, parent)
    assert(SubStatement.Definition.is(subStatement), "Parameter #1 must be a SubStatement")
    return {
        define = function()
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
    }
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
    }, SubStatement.mt)
    statement.mt.__index = statement.mt
    statement.mt.__call = SubStatement.mt.__call

    -- provides an `is` function to test instances
    function statement.is(thing)
        return is(thing, statement.mt)
    end

    -- allow creating of a `modifier` statement
    function statement.modifier(name)
        if SubStatement.Definition.is(name) then
            return SubStatement.Definition.apply(name, statement)
        elseif type(name) == "string" then
            return SubStatement.Definition.new(name, statement)
        else
            error(format("Parameter #1 must be either a string or a SubStatement but was: %s", inspect(name)))
        end
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

    self.parent[self.name] = statement
    self.parent.mt[self.name] = function(this, parent, ...)
        if self.parent ~= parent then
            return statement(this, parent, ...)
        end
        return statement(this, ...)
    end

    return statement
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

--- cp.rx.go.Given.Then <Statement.Config>
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
Given.Then.modifier(Given.Then):define()

local function requireAll(observable)
    return observable:all()
end

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

Require.modifier("Is")
:onInit(function(context, value)
    context.filter = function(observable)
        return observable:all(function(result) return result == value end)
    end
end)
:define()

Require.Is.modifier(Require.OrThrow)

return {
    is = is,
    toObservable = toObservable,
    toObservables = toObservables,
    Statement = Statement,
    SubStatement = SubStatement,
    Given = Given,
    Require = Require,
}