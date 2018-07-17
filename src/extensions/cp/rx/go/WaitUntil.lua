
--- === cp.rx.go.WaitUntil ===
---
--- A [Statement](cp.rx.go.Statement.md) that will wait for the first value from a `resolveable` that matches the predicate.

local Statement                 = require("cp.rx.go.Statement")
local toObservable              = Statement.toObservable

-- checks that the value is not false and not nil.
local function isTruthy(value)
    return value ~= false and value ~= nil
end

--- cp.rx.go.WaitUntil(requirement) -> WaitUntil
--- Constructor
--- Creates a new `WaitUntil` `Statement` with the specified `requirement`.
--- By default, it will wait until the value is `truthy` - not `nil` and not `false`.
---
--- Example:
---
--- ```lua
--- WaitUntil(someObservable):Is(true)
--- ```
---
--- Parameters:
---  * requirement  - a `resolvable` value that will be checked.
---
--- Returns:
---  * The `Statement` instance which will check if the `resolvable` matches the requirement.
local WaitUntil = Statement.named("WaitUntil")
:onInit(function(context, requirement)
    assert(requirement ~= nil, "The WaitUntil requirement may not be `nil`.")
    context.requirement = requirement
end)
:onObservable(function(context)
    local o = toObservable(context.requirement)

    local predicate = context.predicate or isTruthy
    o = o:find(predicate)

    return o
end)
:define()

--- cp.rx.go.WaitUntil.Is <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a specific value to wait for.

--- cp.rx.go.WaitUntil:Is(value) -> WaitUntil.Is
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value to wait for.
---
--- Returns:
---  * The `Is` `Statement.Modifier`.

--- cp.rx.go.WaitUntil.Are <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets the values to match.

--- cp.rx.go.WaitUntil:Are(value) -> WaitUntil.Are
--- Method
--- Specifies the value to check.
---
--- Parameters:
---  * value  - The value to wait for.
---
--- Returns:
---  * The `Are` `Statement.Modifier`.
WaitUntil.modifier("Is", "Are")
:onInit(function(context, thisValue)
    context.predicate = function(value) return value == thisValue end
end)
:define()

--- cp.rx.go.WaitUntil.IsNot <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a value that is skipped over.

--- cp.rx.go.WaitUntil:IsNot(value) -> WaitUntil.IsNot
--- Method
--- Specifies the value to skip.
---
--- Parameters:
---  * value  - The value to skip over.
---
--- Returns:
---  * The `IsNot` `Statement.Modifier`.

--- cp.rx.go.WaitUntil.AreNot <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a value to skip over.

--- cp.rx.go.WaitUntil:AreNot(value) -> WaitUntil.AreNot
--- Method
--- Specifies the value to skip over.
---
--- Parameters:
---  * value  - The value to skip over.
---
--- Returns:
---  * The `AreNot` `Statement.Modifier`.
WaitUntil.modifier("IsNot", "AreNot")
:onInit(function(context, thisValue)
    context.predicate = function(value) return value ~= thisValue end
end)
:define()

--- cp.rx.go.WaitUntil.Matches <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets a predicate check values against.

--- cp.rx.go.WaitUntil:Matches(predicate) -> WaitUntil.Matches
--- Method
--- Specifies the predicate function that will check the `requirement` results.
---
--- Example:
--- ```lua
--- WaitUntil(someObservable):Matches(function(value) return value % 2 == 0 end)
--- ```
---
--- Parameters:
---  * predicate  - The function that will get called to determine if it has been found.
---
--- Returns:
---  * The `Matches` `Statement.Modifier`.
WaitUntil.modifier("Matches")
:onInit(function(context, predicate)
    context.predicate = predicate
end)
:define()

return WaitUntil