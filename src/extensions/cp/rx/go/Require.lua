
--- === cp.rx.go.Require ===
---
--- A `Statement` that will require that the `resolvable` value matches a predicate,
--- and if not, it will send an error.

local Observable        = require("cp.rx").Observable
local Statement         = require("cp.rx.go.Statement")

local toObservable      = Statement.toObservable

local function requireAll(observable)
    return observable:all()
end

--- cp.rx.go.Require(requirement) -> Require
--- Function
--- Creates a new `Require` `Statement` with the specified `requirement`.
--- By default, it will require that all items in the requirement are not `nil` and completed.
---
--- This is most useful with `Given`, allowing retrieval and checking of values before continuing.
---
--- Example:
---
--- ```lua
--- Given(
---     Require(someObservable):Is(2):OrThrow("Must be 2")
--- ):Then(function(someValue)
---     -- do stuff with `someValue`
--- ):Now()
--- ```
---
--- Parameters:
---  * requirement  - a `resolvable` value that will be checked.
---
--- Returns:
---  * The `Statement` instance which will check if the `requirement` matches the requirement.
local Require = Statement.named("Require")
:onInit(function(context, requirement)
    context.requirement = requirement
end)
:onObservable(function(context)
    local observable = toObservable(context.requirement)
    local predicate = context.predicate or requireAll
    observable = predicate(observable)

    observable = observable:flatMap(function(success)
        if success then
            return Observable.of(success)
        else
            return Observable.throw(context.errorMessage or "Requirement not met.", table.unpack(context.errorParams))
        end
    end)

    return observable
end)
:define()

--- cp.rx.go.Require.OrThrow <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets the message to throw if the requirement is not met.

--- cp.rx.go.Require:OrThrow(message) -> Require.OrThrow
--- Method
--- Specifies the message to throw if the requirement is not met.
---
--- Parameters:
---  * message  - The string to throw when there is an error.
---
--- Returns:
---  * The `OrThrow` `Statement.Modifier`.
Require.modifier("OrThrow")
:onInit(function(context, message, ...)
    context.errorMessage = message
    context.errorParams = table.pack(...)
end)
:define()

--- === cp.rx.go.Require.Is ===
---
--- Specifies that the `Require`d value `Is` a specific value.

--- cp.rx.go.Require.Is <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a specific value all values from the `requirement` must match.

--- cp.rx.go.Require:Is(value) -> Require.Is
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value that all results from the `requirement` must match.
---
--- Returns:
---  * The `Is` `Statement.Modifier`.

--- === cp.rx.go.Require.Are ===
---
--- Specifies that the `Require`d values `Are` a specific value.

--- cp.rx.go.Require.Are <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a specific value all values from the `requirement` must match.

--- cp.rx.go.Require:Are(value) -> Require.Are
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value that all results from the `requirement` must match.
---
--- Returns:
---  * The `Are` `Statement.Modifier`.
Require.modifier("Is", "Are")
:onInit(function(context, value)
    context.predicate = function(observable)
        return observable:all(function(result) return result == value end)
    end
end)
:define()

--- cp.rx.go.Require.Is:OrThrow(...) -> Require.OrThrow
--- Method
--- Specifies what is thrown if the [Require](cp.rx.go.Require.md) test fails.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * A [Require.OrThrow](cp.rx.go.Require.OrThrow.md) instance.
Require.Is.allow(Require.OrThrow)

--- cp.rx.go.Require.Are:OrThrow(...) -> Require.OrThrow
--- Method
--- Specifies what is thrown if the [Require](cp.rx.go.Require.md) test fails.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * A [Require.OrThrow](cp.rx.go.Require.OrThrow.md) instance.
Require.Are.allow(Require.OrThrow)

--- === cp.rx.go.Require.IsNot ===
---
--- Specifies that the `Require`d value `IsNot` a specific value.

--- cp.rx.go.Require.IsNot <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a specific value all values from the `requirement` must not match.

--- cp.rx.go.Require:IsNot(value) -> Require.IsNot
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value that all results from the `requirement` must not match.
---
--- Returns:
---  * The `IsNot` `Statement.Modifier`.

--- === cp.rx.go.Require.AreNot ===
---
--- Specifies that the `Require`d values `AreNot` a specific value.

--- cp.rx.go.Require.AreNot <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a specific value all values from the `requirement` must not match.

--- cp.rx.go.Require:AreNot(value) -> Require.AreNot
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value that all results from the `requirement` must match.
---
--- Returns:
---  * The `AreNot` `Statement.Modifier`.
Require.modifier("IsNot", "AreNot")
:onInit(function(context, value)
    context.predicate = function(observable)
        return observable:all(function(result) return result ~= value end)
    end
end)
:define()

--- cp.rx.go.Require.IsNot:OrThrow(...) -> Require.OrThrow
--- Method
--- Specifies what is thrown if the [Require](cp.rx.go.Require.md) test fails.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * A [Require.OrThrow](cp.rx.go.Require.OrThrow.md) instance.
Require.IsNot.allow(Require.OrThrow)

--- cp.rx.go.Require.AreNot:OrThrow(...) -> Require.OrThrow
--- Method
--- Specifies what is thrown if the [Require](cp.rx.go.Require.md) test fails.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * A [Require.OrThrow](cp.rx.go.Require.OrThrow.md) instance.
Require.AreNot.allow(Require.OrThrow)

--- === cp.rx.go.Require.Matches ===
---
--- Specifies that the `Require`d value `Matches` a function predicate.

--- cp.rx.go.Require.Matches <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a predicate function that checks values from the `requirement`.

--- cp.rx.go.Require:Matches(predicate) -> Require.Matches
--- Method
--- Specifies the predicate to check.
---
--- ```lua
--- Require(someObservable):Matches(function(value) return value % 2 == 0 end)
--- ```
---
--- Parameters:
---  * value  - The value that all results from the `requirement` must not match.
---
--- Returns:
---  * The `Matches` `Statement.Modifier`.
Require.modifier("Matches")
:onInit(function(context, predicate)
    context.predicate = function(observable)
        return observable:all(predicate)
    end
end)
:define()

--- cp.rx.go.Require.Matches:OrThrow(...) -> Require.OrThrow
--- Method
--- Specifies what is thrown if the [Require](cp.rx.go.Require.md) test fails.
---
--- Parameters:
---  * ...  - The list of `resolvable` items to process.
---
--- Returns:
---  * A [Require.OrThrow](cp.rx.go.Require.OrThrow.md) instance.
Require.Matches.allow(Require.OrThrow)

return Require