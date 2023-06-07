
--- === cp.rx.go.Do ===
---
--- A [Statement](cp.rx.go.Statement.md) that will execute the provided `resolvable` values.
--- This will resolve the provided values into [Observables](cp.rx.Observable.md) and pass on the
--- first result of each to the next stage as individual parameters.
--- This will continue until one of the `Observables` has completed, at which
--- point other results from values are ignored.
---
--- For example:
---
--- ```lua
--- Do(Observable.of(1, 2, 3), Observable.of("a", "b"))
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
--- For more power, you can add a [Then](#Then) to futher modify the results, or chain other operations.

local rx                = require "cp.rx"
local Statement         = require "cp.rx.go.Statement"

local insert            = table.insert
local Observable        = rx.Observable
local pack              = table.pack
local toObservables     = Statement.toObservables
local unpack            = table.unpack

--- cp.rx.go.Do(...) -> Do
--- Constructor
--- Begins the definition of a `Do` `Statement`.
---
--- Parameters:
---  * ...      - the list of `resolvable` values to evaluate.
---
--- Returns:
---  * A new `Do` `Statement` instance.
local Do = Statement.named("Do")
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

--- === cp.rx.go.Do.Then ===
---
--- A [Statement.Modifier](cp.rx.go.Statement.Modifier.md) of [Do](cp.rx.go.Do.md)
--- that defines what happens after the `Do` values resolve.
---
--- For example:
---
--- ```lua
--- Do(anObservable):Then(Observable.of(1, 2, 3))
--- ```
---
--- If a parameter is a `function`, it will be passed the results of the previous `Do` or `Then` parameters.
---
--- For example:
--- ```lua
--- Do(anObservable, anotherObservable)
--- :Then(function(aResult, anotherResult)
---     doSomethingWith(aResult, anotherResult)
---     return true
--- end)
--- ```

--- cp.rx.go.Do:Then(...) -> Do.Then
--- Method
--- Call this to define what will happen once the `Do` values resolve successfully. The parameters can be any 'resolvable' type.
---
--- Parameters:
---  * ...  - The list of `resolvable` values to process for each `Do` result.
---
--- Returns:
---  * The [Then](cp.rx.go.Do.Then.md) [Statement.Modifier](cp.rx.go.Statement.Modifier.md).
Do.modifier("Then")
:onInit(function(context, ...)
    insert(context.thens, pack(...))
end):define()

--- cp.rx.go.Do.Then:Then(...) -> Do.Then
--- Method
--- Allows another set of `resolvables` to be processed after a `Then` has resolved.
---
--- Parameters:
---  * ...      - The list of `resolvable` values to process.
---
--- Returns:
---  * Another [Do.Then](cp.rx.go.Do.Then.md) instance.
Do.Then.allow(Do.Then)

return Do