--- === cp.rx.go.First ===
---
--- _Extends:_ [Statement](cp.rx.go.Statement.md)
---
--- A [Statement](cp.rx.go.Statement.md) that will complete after the first result resolves.

local Statement             = require "cp.rx.go.Statement"
local toObservable          = Statement.toObservable

--- cp.rx.go.First(resolvable) -> First
--- Constructor
--- Creates a new `First` `Statement` that will return the first value from the `resolvable` and complete.
---
--- Example:
---
--- ```lua
--- First(someObservable)
--- ```
---
--- Parameters:
---  * resolvable  - a `resolvable` value, of which the first result will be returned.
---
--- Returns:
---  * The `Statement` which will return the first value when executed.
local First = Statement.named("First")
:onInit(function(context, resolvable)
    assert(resolvable ~= nil, "The First `resolveable` may not be `nil`.")
    context.resolvable = resolvable
end)
:onObservable(function(context)
    return toObservable(context.resolvable):first()
end)
:define()

return First