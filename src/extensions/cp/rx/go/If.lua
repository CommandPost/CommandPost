--- === cp.rx.go.If ===
---
--- A `Statement` that will check if a `resolvable` matches a predicate, then executes other `resolvables`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require = require
-- local log                   = require("hs.logger").new("go_If")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local inspect               = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local Observable            = require("cp.rx").Observable
local Statement             = require("cp.rx.go.Statement")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local toObservable          = Statement.toObservable
local toObservables         = Statement.toObservables

local insert                = table.insert
local pack, unpack          = table.pack, table.unpack
local format                = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

-- checks that the value is not false and not nil.
local function isTruthy(value)
    return value ~= false and value ~= nil
end

-- handles the 'otherwise' clauses.
local function handleOtherwises(otherwises, ...)
    if otherwises and #otherwises > 0 then
        -- loop through the `thens`, passing the results to the next via zip/flatMap
        -- log.df("If:Then:Otherwise: processing 'Otherwise' #1")
        local o2 = Observable.zip(unpack(toObservables(otherwises[1], pack(...))))
        for i = 2, #otherwises do
            -- log.df("If:Then:Otherwise: processing 'Otherwise' #%d", i)
            o2 = o2:flatMap(function(...)
                return Observable.zip(unpack(toObservables(otherwises[i], pack(...))))
            end)
        end
        return o2
    else
        -- log.df("If:Otherwise: default to `empty`")
        return Observable.of(nil)
    end
end

--- cp.rx.go.If(value) -> If
--- Constructor
--- Creates a new `If` `Statement` which will check the first result of `value`.
--- By default, it will check if the value is `truthy` - not `nil` and not `false`.
--- Other checks can be specified via the `If:Is/IsNot/Matches` methods.
--- If the check passes, the `If:Then(...)` method is processed. If not, the `Otherwise` method
--- can specify other `resolvables` to execute instead.
---
--- Example:
---
--- ```lua
--- If(someObservable):Is(true):Then(
---     function() ... end
--- ):Otherwise(
---     function() ... end
--- )
--- ```
---
--- Parameters:
---  * requirement  - a `resolvable` value that will be checked.
---
--- Returns:
---  * The `Statement` instance which will check if the `resolvable` matches the requirement.
local If = Statement.named("If")
:onInit(function(context, value)
    assert(value ~= nil, "The 'If' value may  not be `nil`.")
    context.value = value
    context.predicate = isTruthy
    context.thens = {}
    context.otherwises = {}
end)
:onObservable(function(context)
    local thens = context.thens
    assert(#thens > 0, "Please specify a 'Then'")

    -- we only deal with the first result
    local o = toObservable(context.value):next()
    local handled = false

    o = o:flatMap(function(...)
        handled = true
        if context.predicate(...) then
            -- loop through the `thens`, passing the results to the next via zip/flatMap
            local o2 = Observable.zip(unpack(toObservables(thens[1], pack(...))))
            for i = 2, #thens do
                -- log.df("If:Then: processing 'Then' #%d", i)
                o2 = o2:flatMap(function(...)
                    return Observable.zip(unpack(toObservables(thens[i], pack(...))))
                end)
            end
            return o2
        else
            return handleOtherwises(context.otherwises, ...)
        end
    end)
    :switchIfEmpty(Observable.defer(function()
        if not handled then
            return handleOtherwises(context.otherwises)
        else
            return Observable.of(nil)
        end
    end))

    return o
end)
:define()

--- === cp.rx.go.If.Then ===
---
--- A `Statement.Modifier` that defines what happens when an `If` matches.

--- cp.rx.go.If.Then <cp.rx.go.Statement.Modifier>
--- Constant
--- This is a configuration of `If`, which should be created via `If:Then(...)`.

--- cp.rx.go.If:Then(...) -> If.Then
--- Method
--- Call this to define what will happen if value resolves successfully.
--- The parameters can be any `resolvable` type.
---
--- For example:
--- ```lua
--- If(anObservable)
--- :Then(function(aResult)
---     doSomethingWith(aResult, anotherResult)
---     return true
--- end)
--- ```
---
--- Parameters:
---  * ...  - The list of `resolveable` values to process for the successful `If` result.
---
--- Returns:
---  * The `Then` `Statement.Modifier`.
If.modifier("Then")
:onInit(function(context, ...)
    insert(context.thens, pack(...))
end)
:define()

--- cp.rx.go.If.Then:Then(...) -> If.Then
--- Method
--- Each [Then](cp.rx.go.If.Then.md) can have a subsequent `Then` which will be executed after the previous one resolves.
---
--- Parameters:
---  * ...  - The list of `resolvable` values to process for the sucessful `If` result.
---
--- Returns:
---  * A new [If.Then](cp.rx.go.If.Then.md) instance.
If.Then.allow(If.Then)

--- === cp.rx.go.If.Then.Otherwise ===
---
--- A [Statement.Modifier](cp.rx.go.Statement.Modifier.md) of [If](cp.rx.go.If.md), which should be created via `If:Then(...):Otherwise(...)`.

--- cp.rx.go.If.Then:Otherwise(...) -> If.Then.Otherwise
--- Method
--- Call this to define what will happen if value doesn't resolve successfully.
--- The parameters can be any `resolvable` type.
---
--- For example:
--- ```lua
--- If(anObservable)
--- :Then(function(aResult)
---     doSomethingWith(aResult, anotherResult)
---     return true
--- end)
--- :Otherwise(false)
--- ```
---
--- Parameters:
---  * ...  - The list of `resolveable` values to process for the unsuccessful `If` result.
---
--- Returns:
---  * The `Then` `Statement.Modifier`.
If.Then.modifier("Otherwise")
:onInit(function(context, ...)
    insert(context.otherwises, pack(...))
end)
:define()

--- === cp.rx.go.If.Then.Otherwise.Then ===
---
--- Each [Otherwise](cp.rx.go.If.Then.Otherwise.md) can have a subsequent `Then` which will be executed after the previous one resolves.
If.Then.Otherwise.modifier("Then")
:onInit(function(context, ...)
    insert(context.otherwises, pack(...))
end)
:define()

--- cp.rx.go.If.Then.Otherwise.Then:Then(...) -> If.Then.Otherwise.Then
--- Method
--- Specifies additional `resolvables` to resolve after the previous `Then`.
---
--- Parameters:
---  * ...      - The list of `resolvable` values.
---
--- Returns:
---  * The new `Then` instance.
If.Then.Otherwise.Then.allow(If.Then.Otherwise.Then)


--- === cp.rx.go.If.Is ===
---
--- A [Statement.Modifier](cp.rx.go.Statement.Modifier.md) for [If](cp.rx.go.If.md) that sets a specific value to match.

--- cp.rx.go.If:Is(value) -> If.Is
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value to check for.
---
--- Returns:
---  * The [Is](cp.rx.go.If.Is.md) [Statement.Modifier](cp.rx.go.Statement.Modifier.md).


--- === cp.rx.go.If.Are ===
---
--- A [Statement.Modifier] of [If](cp.rx.go.If.md) that sets the values to match.

--- cp.rx.go.If:Are(value) -> If.Are
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value to wait for.
---
--- Returns:
---  * The [Are](cp.rx.go.If.Are.md) [Statement.Modifier](cp.rx.go.Statement.Modifier.md).
If.modifier("Is", "Are")
:onInit(function(context, value)
    context.predicate = function(theValue) return theValue == value end
end)
:define()

--- cp.rx.go.If.Is:Then(...) -> If.Then
--- Method
--- Specifies what happens after the [If](cp.rx.go.If.md) test passes.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * An [If.Then](cp.rx.go.If.Then.md) instance.
If.Is.allow(If.Then)

--- cp.rx.go.If.Are:Then(...) -> If.Then
--- Method
--- Specifies what happens after the [If](cp.rx.go.If.md) test passes.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * An [If.Then](cp.rx.go.If.Then.md) instance.
If.Are.allow(If.Then)

--- === cp.rx.go.If.IsNot ===
---
--- A [Statement.Modifier](cp.rx.go.Statement.Modifier.md) for [If](cp.rx.go.If.md) that sets a specific value to *not* match.

--- cp.rx.go.If:IsNot(value) -> If.IsNot
--- Method
--- Specifies the value to not match.
---
--- Parameters:
---  * value  - The value to check for.
---
--- Returns:
---  * The [IsNot](cp.rx.go.If.IsNot.md) [Statement.Modifier](cp.rx.go.Statement.Modifier.md).

--- === cp.rx.go.If.AreNot ===
---
--- A [Statement.Modifier](cp.rx.go.Statement.Modifier.md) for [If](cp.rx.go.If.md) that sets the values to *not* match.

--- cp.rx.go.If:AreNot(value) -> If.AreNot
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value to not match.
---
--- Returns:
---  * The [AreNot](cp.rx.go.If.AreNot.md) [Statement.Modifier](cp.rx.go.Statement.Modifier.md).
If.modifier("IsNot", "AreNot")
:onInit(function(context, value)
    context.predicate = function(theValue) return theValue ~= value end
end)
:define()

--- cp.rx.go.If.IsNot:Then(...) -> If.Then
--- Method
--- Specifies what happens after the [If](cp.rx.go.If.md) test passes.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * An [If.Then](cp.rx.go.If.Then.md) instance.
If.IsNot.allow(If.Then)

--- cp.rx.go.If.AreNot:Then(...) -> If.Then
--- Method
--- Specifies what happens after the [If](cp.rx.go.If.md) test passes.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * An [If.Then](cp.rx.go.If.Then.md) instance.
If.AreNot.allow(If.Then)

--- === cp.rx.go.If.Matches ===
---
--- A [Statement.Modifier](cp.rx.go.Statement.Modifier.md) for [If](cp.rx.go.If.md) that sets a predicate check values against.

--- cp.rx.go.If:Matches(predicate) -> If.Matches
--- Method
--- Specifies the predicate function that will check the `value` results.
---
--- Example:
--- ```lua
--- If(someObservable):Matches(function(value) return value % 2 == 0 end):Then(doSomething())
--- ```
---
--- Parameters:
---  * predicate  - The function that will get called to determine if it has been found.
---
--- Returns:
---  * The [Matches](cp.rx.go.If.Matches.md) [Statement.Modifier](cp.rx.go.Statement.Modifier.md).
If.modifier("Matches")
:onInit(function(context, predicate)
    if type(predicate) ~= "function" then
        error(format("The 'Matches' predicate must be a function, but was: %s", inspect(predicate)))
    end
    context.predicate = predicate
end)
:define()

--- cp.rx.go.If.Matches:Then(...) -> If.Then
--- Method
--- Specifies what happens after the [If](cp.rx.go.If.md) test passes.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * An [If.Then](cp.rx.go.If.Then.md) instance.
If.Matches.allow(If.Then)

return If