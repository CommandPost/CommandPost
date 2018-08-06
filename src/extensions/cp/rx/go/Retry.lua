--- === cp.rx.go.Retry ===
---
--- _Extends:_ [Statement](cp.rx.go.Statement.md)
---
--- A [Statement](cp.rx.go.Statement.md) that will retry the contained statement if there is an error.
--- It can be limited to a set number of retries, and have a delay added between retries.

local Statement             = require("cp.rx.go.Statement")
local toObservable          = Statement.toObservable

--- cp.rx.go.Retry(resolvable) -> Retry
--- Constructor
--- Creates a new `Retry` `Statement` that will retry the `resolveable` if it emits an error.
---
--- Example:
---
--- ```lua
--- Retry(someObservable)
--- ```
---
--- Parameters:
---  * resolvable  - a `resolvable` value, which will be retried if it sends an `error` signal.
---
--- Returns:
---  * The `Statement`.
local Retry = Statement.named("Retry")
:onInit(function(context, resolvable)
    assert(resolvable ~= nil, "The `resolveable` may not be `nil`.")
    context.resolvable = resolvable
end)
:onObservable(function(context)
    local o = toObservable(context.resolvable)
    if context.delay then
        return o:retryWithDelay(context.count, context.delay)
    else
        return o:retry(context.count)
    end
end)
:define()

--- cp.rx.go.Retry.UpTo <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets the number of times to retry.

--- cp.rx.go.Retry:UpTo(count) -> Retry.UpTo
--- Method
--- Specifies the number of times to retry up to.
---
--- Parameters:
---  * count  - The number of times to retry.
---
--- Returns:
---  * The `UpTo` `Statement.Modifier`.
Retry.modifier("UpTo")
:onInit(function(context, count)
    context.count = count
end)
:define()


--- cp.rx.go.Retry.DelayedBy <cp.rx.go.Statement.Modifier>
--- Constant
--- A `Statement.Modifier` that sets the delay between retries.

--- cp.rx.go.Retry:DelayedBy(milliseconds) -> Retry.DelayedBy
--- Method
--- Specify a time in millieconds to delay by.
---
--- Parameters:
---  * milliseconds - The amount of time do delay between retries.
---
--- Returns:
---  * The `DelayedBy` `Statement.Modifier`.
Retry.modifier("DelayedBy")
:onInit(function(context, milliseconds)
    context.delay = milliseconds
end)
:define()

Retry.UpTo.allow(Retry.DelayedBy)
Retry.DelayedBy.allow(Retry.UpTo)

return Retry