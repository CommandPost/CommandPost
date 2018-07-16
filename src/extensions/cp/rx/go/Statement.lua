--- === cp.rx.go.Statement ===
---
--- A `Statement` is defined to enable processing of asynchronous `resolvable` values such
--- as [cp.rx.Observable](cp.rx.Observable.md) values.
---
--- To define a new `Statement`, you call the [named](#named) constructor, assigning the result
--- to a constant value and calling the [define](#define) method.
---
--- ## Definine a new Statement
---
--- To define a new `Statement` implementation, we use the [Statement.named](cp.rx.go.Statement.md#named) constructor.
--- This gives us a [Statement.Definition](cp.rx.go.Statement.Definition.md) which allows
--- us to set the rules for the statement before finally "defining" it.
---
--- For example, the [First](cp.rx.go.First.md) statement is defined like so:
---
--- ```lua
--- local First = Statement.named("First")
--- :onInit(function(context, resolvable)
---     assert(resolvable ~= nil, "The First `resolveable` may not be `nil`.")
---     context.resolvable = resolvable
--- end)
--- :onObservable(function(context)
---     return toObservable(context.resolvable):first()
--- end)
--- :define()
--- ```
---
--- Once you've defined a statement, you then execute it by calling the statement directly, passing
--- in any parameters.
---
--- For example:
--- ```lua
--- local First = require("cp.rx.go").First
--- First(Observable.of(1, 2, 3))
--- :Now(
---     function(value) print("Received: "..tostring(value)) end,
---     function(message) print("Error: "..tostring(message)) end,
---     function() print("Completed") end
--- )
--- ```
---
--- This will output:
--- ```
--- Received: 1
--- Completed
--- ```
---
--- The `Observable` as passed to the `onInit` function handler as the second parameter.
--- `context` is always the first parameter, followed by any values passed to the constructor call.
---
--- The `onObservable` function handler is called once the statement is actually executing, typically
--- by calling the [Now](cp.rx.go.Statement.md#Now) or [After](cp.rx.go.Statement.md#After) methods.
---
--- > It is recommended that any conversion of input parameters are converted to `Observable`s as
--- > late as possible, typically in the `onObservable` function handler. Otherwise, input values
--- > may get resolved before the user intends.

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log           = require("hs.logger").new("Statement")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local inspect       = require("hs.inspect")

-----------------------------------------------------------
-- Imports and Local functions
-----------------------------------------------------------
local prop          = require("cp.prop")
local rx            = require("cp.rx")

local Observable    = rx.Observable
local Observer      = rx.Observer
local insert        = table.insert
local pack, unpack  = table.pack, table.unpack

local format        = string.format

-----------------------------------------------------------
-- Utility functions
-----------------------------------------------------------

-- checks if the `thing` is or extends the `class`
local function is(thing, class)
    if type(thing) == "table" then
        class = class.mt or class
        return thing == class or is(getmetatable(thing), class)
    end
    return false
end

-- private key for storing the metadata table for instances.
local METADATA = {}

local Statement

Statement = {}
Statement.mt = {}
Statement.mt.__index = Statement.mt

--- cp.rx.go.Statement.toObservable(thing[, params]) -> cp.rx.Observable
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
function Statement.toObservable(thing, params)
    if type(thing) == "function" then
        -- log.df("toObservable: function")
        local results = pack(thing(unpack(params or {})))
        if #results > 1 then
            -- log.df("toObservable: function: multiple results, zipping...")
            return Observable.zip(unpack(Statement.toObservables(results)))
        else
            -- log.df("toObservable: function: single result: %s", type(results[1]))
            return Statement.toObservable(results[1])
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

    return obs
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
function Statement.toObservables(things, params)
    local observables = {}
    for _,thing in ipairs(things) do
        -- log.df("toObservables: processing thing #%d: %s", i, type(thing))
        insert(observables, Statement.toObservable(thing, params))
    end
    return observables
end

Statement.Definition = {}
Statement.Definition.mt = {}
Statement.Definition.mt.__index = Statement.Definition.mt

--- === cp.rx.go.Statement.Definition ===
---
--- A [Statement](cp.rx.go.Statement.md) is defined before being executable.

-- cp.rx.go.Statement.Definition.new(name) -> Statement.Definition
-- Constructor
-- Creates a new Statement Definition.
--
-- Parameters:
--  * name     - The name of the statement.
--
-- Returns:
--  * The new Statement Definition.
--
-- Note:
--  * Generally, use the [Statement.named(...)](cp.rx.go.Statement.md#named) function to create a `Statement.Definition`.
function Statement.Definition.new(name)
    assert(type(name) == "string" and name:len() > 0, "Parameter #1 must be a non-empty string")
    return setmetatable({
        name = name,
    }, Statement.Definition.mt)
end

--- cp.rx.go.Statement.Definition.is(thing) -> boolean
--- Function
--- Checks if the `thing` is an instance of `Statement.Definition`.
---
--- Parameters:
---  * thing    - The thing to check.
---
--- Returns:
---  * `true` if the thing is a `Statement.Definition`.
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
--- end):onObservable(...):define()
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
--- Defines the function which will be called to create the [Observable](cp.rx.Observable.md)
--- for the [Statement](cp.rx.go.Statement.md).
--- The function will be passed the `context` table and must return an `Observable`.
---
--- Parameters:
---  * observableFn     - The observable creator function.
---
--- Returns:
---  * The `Statement.Definition`
function Statement.Definition.mt:onObservable(observableFn)
    assert(type(observableFn) == "function", "Parameter #1 must be a function")
    self._onObservable = observableFn
    return self
end

--- cp.rx.go.Statement.Definition:define() -> Statement
--- Method
--- Completes the definition of the [Statement](cp.rx.go.Statement.md).
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
---  * The new [Statement](cp.rx.go.Statement.md).
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
    statement.mt.__tostring = function(s)
        return s:context()._label or Statement.mt.__tostring(s)
    end

    -- provides an `is` function to test instances
    function statement.is(thing)
        return is(thing, statement.mt)
    end

    -- allow creating of a `modifier` statement
    function statement.modifier(...)
        return Statement.Modifier.Definition.new(statement, ...)
    end

    setmetatable(statement, {
        __call = function(_, ...)
                -- it's a top-level statement
            return setmetatable({}, statement.mt):__init(...)
        end,

        -- outputs the statement name when converted to a string.
        __tostring = function()
            return metadata.name
        end,
    })

    return statement
end

--- cp.rx.go.Statement.named(name) -> Statement.Definition
--- Constructor
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
---  * A [Statement.Definition](cp.rx.go.Statement.Definition.md).
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
local function simpleObserverFactory()
    return Observer.create(nil, error, nil)
end

local defaultObserverFactory = simpleObserverFactory

--- cp.rx.go.Statement.defaultObserverFactory([factoryFn]) -> nil
--- Function
--- Gets/sets the factory function which creates a new `Observer` for Statements which are executed without one being provided.
--- By default, an `Observer` which only outputs errors via the standard `error` function is provided.
---
--- Parameters:
---  * factoryFn     - if provided, replaces the current default factory function.
---
--- Returns:
---  * A new `Observer`, or the previous factory function if a new one was provided.
---
--- Notes:
---  * The factory function has no arguments provided and must return a new `Observer` instance.
function Statement.defaultObserverFactory(factoryFn)
    if factoryFn then
        assert(type(factoryFn) == "function", "Parameter #1 must be a function.")
        defaultObserverFactory = factoryFn
    else
        defaultObserverFactory = simpleObserverFactory
    end
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
    return self:Now(...)
end

function Statement.mt:__init(...)
    self._context = {}
    local onInit = self[METADATA].onInit
    if onInit then
        onInit(self:context(), ...)
    end
    return self
end

--- cp.rx.go.Statement:Label(label) -> Statement
--- Method
--- Sets the custom `label` for the Statement. This will
--- be used instead of the `name` when outputting it as a `string`
--- if set. Defaults to `nil`.
---
--- Parameters:
---  * label - Optional new value for the label. If provided, the `Statement` is returned.
---
--- Returns:
---  * The `Statement` if a new lable is specified, otherwise the current label value.
function Statement.mt:Label(label)
    local ctx = self:context()
    ctx._label = label
    if ctx._debug then ctx._debug = label end
    return self
end

--- cp.rx.go.Statement:Debug([label]) -> Statement
--- Method
--- Indicates that the results of the `Statement` should be output to the Error Log.
---
--- Parameters:
---  * label    - If specified, this is output in the log.
---
--- Returns:
---  * The same `Statement` instance.
function Statement.mt:Debug(label)
    local context = self:context()
    context._debug = label or context._label or self:fullName()
    return self
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
---  * The same `Statement`.
function Statement.mt:Catch(handler)
    self:context()._catcher = handler
    return self
end

--- cp.rx.go.Statement:ThenDelay(millis) -> cp.rx.go.Statement
--- Method
--- Indicates that there will be a delay after this statement by the
--- specified number of `millis`. This will happen after any `TimeoutAfter`/`Catch`/`Debug`
--- actions.
---
--- Parameters:
---  * millis   - the amount of time to delay, in millisecods.
---
--- Returns:
---  * The same `Statement`.
function Statement.mt:ThenDelay(millis)
    self:context()._delay = millis
    return self
end

--- cp.rx.go.Statement:TimeoutAfter(millis[, next][, scheduler]) -> cp.rx.go.Statement
--- Method
--- Indicates that this statement should time out after the specified number of milliseconds.
--- This can be called multiple times before the statement is executed, and the most recent
--- configuration will be used at that time.
---
--- The `next` value may be either a string to send as the error, or a `resolvable` value to
--- pass on instead of failing. If nothing is provided, a default error message is output.
---
--- Parameters:
---  * millis       - A `number` or a `function` returning the number of milliseconds to wait before timing out.
---  * next         - Optional string or `resolvable` value indicating how to handle it.
---  * scheduler    - The `cp.rx.Scheduler` to use when timing out. Defaults to `cp.rx.defaultScheduler()`.
---
--- Returns:
---  * The same `Statement`.
function Statement.mt:TimeoutAfter(millis, next, scheduler)
    self:context()._timeout = {
        millis = millis,
        next = next,
        scheduler = scheduler
    }
    return self
end

--- cp.rx.go.Statement:toObservable([preserveTimer]) -> cp.rx.Observable
--- Method
--- Returns a new `Observable` instance for the `Statement`. Unless `preserveTimer` is `true`, this will
--- cancel any scheduled execution of the statement via [After](#After)
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
    local context = self:context()
    local o = onObservable(context)

    if context._timeout then
        local timeout = context._timeout
        o = o:timeout(timeout.millis, timeout.next, timeout.scheduler)
    end

    if context._debug then
        local label = context._debug
        o = o:tap(
            function(...)
                print("[NEXT: " .. label .."]: ", ...)
            end,
            function(message)
                print("[ERROR: " .. label .. "]: ", message)
            end,
            function()
                print("[COMPLETED: " .. label .. "]")
            end
        )
    end

    -- Check if there is a 'catch'
    if context._catcher then
        o = o:catch(function(message)
            return Statement.toObservable(context._catcher(message))
        end)
    end

    -- only delay after everything else
    if context._delay then
        o = o:delay(context._delay)
    end

    return o
end

--- cp.rx.go.Statement:Now([observer]) -> nil
--- Method
--- Executes the statment immediately.
---
--- Parameters:
--- * observer      - An observer to watch the resulting `Observable`. Defaults to the default observer factory.
---
--- Returns:
--- * Nothing.
function Statement.mt:Now(onNext, onError, onCompleted)
    local obs = self:toObservable()
    if Observable.is(obs) then
        local observer
        if Observer.is(onNext) then
            observer = onNext
        elseif type(onNext) == "function" or type(onError) == "function" or type(onCompleted) == "function" then
            observer = Observer.create(onNext, onError or error, onCompleted)
        else
            observer = defaultObserverFactory()
        end
        obs:subscribe(observer)
    else
        error(format("BUG: Expected an Observable but got %s", inspect(obs)))
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
-- Statement.Modifier and Statement.Modifier Definition
-----------------------------------------------------------

--- === cp.rx.go.Statement.Modifier ===
---
--- A `Statement.Modifier` is an extension to a `Statement` that provides additional configuration details.
--- They are initiated via the [modifier](#modifier) method of a defined `Statement`.

Statement.Modifier = {}
Statement.Modifier.mt = setmetatable({}, Statement.mt)
Statement.Modifier.mt.__index = Statement.Modifier.mt

Statement.Modifier.Definition = {}
Statement.Modifier.Definition.mt = setmetatable({}, Statement.Definition.mt)
Statement.Modifier.Definition.mt.__index = Statement.Modifier.Definition.mt


--- === cp.rx.go.Statement.Modifier.Definition ===
---
--- A [Statement.Modifier](cp.rx.go.Statement.Modifier.md) is defined before being executable.

-- cp.rx.go.Statement.Modifier.Definition.new(name) -> Statement.Definition
-- Constructor
-- Creates a new Statement Definition.
--
-- Parameters:
--  * parent    - The parent Statement
--  * name      - The name of the statement.
--
-- Returns:
--  * The new Statement Definition.
function Statement.Modifier.Definition.new(parent, ...)
    local names = pack(...)
    assert(#names > 0, "Parameter #2 must be a non-empty string.")
    local firstName = names[1]
    assert(type(firstName) == "string" and firstName:len() > 0, "Parameter #2 must be a non-empty string")
    return setmetatable({
        names = names,
        parent = parent,
    }, Statement.Modifier.Definition.mt)
end

-- cp.rx.go.Statement.Modifier.Definition.allow(parent, modifier) -> nil
-- Function
-- Indicates that the `Statement.Modifier` allows another `Statement.Modifier` to be allowed as a method call to the `parent`.
--
-- Parameters:
--  * parent        - The parent `Statement.Modifier`.
--  * modifier      - The other `Statement.Modifier` to allow as a method call. May be the same as `parent`.
--
-- Returns:
--  * Nothing
function Statement.Modifier.Definition.allow(parent, modifier)
    assert(Statement.Modifier.Definition.is(modifier), "Parameter #2 must be a Statement.Modifier")
    local metadata = modifier.mt[METADATA]
    if parent[metadata.name] ~= nil then
        error(format("There is already a '%s' Statement.Modifier on '%s'", metadata.name, parent))
    end
    parent[metadata.name] = modifier

    -- assign the Statement:Modifier(...) method
    if parent.mt[metadata.name] ~= nil then
        error(format("There is already a '%s' method on '%s'", metadata.name, parent))
    end
    parent.mt[metadata.name] = function(this, ...)
        return modifier(this, ...)
    end
end

--- cp.rx.go.Statement.Modifier.Definition.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `Statement.Modifier.Definition`.
---
--- Parameters:
---  * thing    - The thing to check.
---
--- Returns:
---  * `true` if the thing is a `Statement.Modifier.Definition`.
function Statement.Modifier.Definition.is(thing)
    return type(thing) == "table" and is(thing.mt, Statement.Modifier)
end

--- cp.rx.go.Statement.Modifier.Definition:define()
--- Method
--- Defines the `Statement.Modifier`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new [Statement.Modifier](cp.rx.go.Statement.Modifier.md) definition.
function Statement.Modifier.Definition.mt:define()
    assert(self.parent ~= nil, "The parent of the Statement.Modifier is not available.")
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
        }, Statement.Modifier.mt)
        statement.mt.__index = statement.mt
        statement.mt.__call = Statement.Modifier.mt.__call
        statement.mt.__tostring = function(s)
            return s:context()._label or Statement.Modifier.mt.__tostring(s)
        end

        -- provides an `is` function to test instances
        function statement.is(thing)
            return is(thing, statement.mt)
        end

        -- creates a `modifier` statement
        function statement.modifier(first, ...)
            if type(first) == "string" then
                return Statement.Modifier.Definition.new(statement, first, ...)
            else
                error(format("Parameter #1 must be either a string but was: %s", inspect(first)))
            end
        end

        -- allows an existing modifier to be applied to this Statement.Modifier.
        function statement.allow(modifier, ...)
            if not Statement.Modifier.Definition.is(modifier) then
                error(format("Parameter #1 must be a Statement.Modifier Definition but was: %s", inspect(modifier)))
            end
            return Statement.Modifier.Definition.allow(statement, modifier, ...)
        end

        setmetatable(statement, {
            -- called to execute the sub-statement.
            __call = function(_, parent, ...)
                return setmetatable({
                    _parent = parent,
                }, statement.mt):__init(...)
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

--- cp.rx.go.Statement.Modifier.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `Statement.Modifier`.
---
--- Parameters:
---  * thing    - The thing to check.
---
--- Returns:
---  * `true` if the `thing` is a `Statement.Modifier`.
function Statement.Modifier.is(thing)
    return is(thing, Statement.Modifier.mt)
end

--- cp.rx.go.Statement.Modifier:context() -> table
--- Method
--- Returns the `context` table for the `Statement.Modifier`.
--- The `context` is shared between the `Statement` and all `Statement.Modifiers` when being executed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `context` table.
function Statement.Modifier.mt:context()
    return self._parent:context()
end

--- cp.rx.go.Statement.Modifier:toObservable() -> cp.rx.Observable
--- Method
--- Creates a new `Observable` instance for the current configuration.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new `Observable` instance.
function Statement.Modifier.mt:toObservable()
    local o = self._parent:toObservable()
    local metadata = self[METADATA]
    local onObservable = metadata.onObservable
    if onObservable then
        return onObservable(self:context(), o)
    else
        return o
    end
end

return Statement
