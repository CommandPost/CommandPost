--- === cp.rx.go.Given ===
---
--- A [Statement](cp.rx.go.Statement.md) that will execute the provided `resolvable` values.
--- This will resolve the provided values into [Observables](cp.rx.Observable.md) and pass on the
--- first result of each to the next stage as individual parameters.
--- This will continue until one of the `Observables` has completed, at which
--- point other results from values are ignored.

local rx                = require "cp.rx"
local Statement         = require "cp.rx.go.Statement"

local insert            = table.insert
local Observable        = rx.Observable
local pack              = table.pack
local toObservables     = Statement.toObservables
local unpack            = table.unpack

--- cp.rx.go.Given(...) -> Given
--- Constructor
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
    context.requirements = pack(...)
    context.thens = {}
end)
:onObservable(function(context, ...)
    local o = Observable.zip(unpack(toObservables(context.requirements, ...)))
    for _,t in ipairs(context.thens) do
        o = o:flatMap(function(...)
            return Observable.zip(unpack(toObservables(t, pack(...))))
        end)
    end
    return o
end)
:define()

--- === cp.rx.go.Given.Then ===
---
--- A [Statement.Modifier](cp.rx.go.Statement.Modifier.md) of [Given](cp.rx.go.Given.md)
--- that defines what happens after the `Given` values resolve.
---
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
---
--- Parameters:
---  * ...  - The list of `resolveable` values to process for each `Given` result.
---
--- Returns:
---  * The [Then](cp.rx.go.Given.Then.md) [Statement.Modifier](cp.rx.go.Statement.Modifier.md).
Given.modifier("Then")
:onInit(function(context, ...)
    insert(context.thens, pack(...))
end):define()

--- cp.rx.go.Given.Then:Then(...) -> Given.Then
--- Method
--- Allows another set of `resolvables` to be processed after a `Then` has resolved.
---
--- Parameters:
---  * ...      - The list of `resolvable` values to process.
---
--- Returns:
---  * Another [Given.Then](cp.rx.go.Given.Then.md) instance.
Given.Then.allow(Given.Then)

return Given