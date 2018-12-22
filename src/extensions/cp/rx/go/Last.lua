
--- === cp.rx.go.Last ===
---
--- A `Statement` that will complete after the only the last result resolves.

local Statement         = require("cp.rx.go.Statement")
local toObservable      = Statement.toObservable

--- cp.rx.go.Last(resolvable) -> Last
--- Constructor
--- Creates a new `Last` `Statement` that will return the first value from the `resolvable` and complete.
---
--- Example:
---
--- ```lua
--- Last(someObservable)
--- ```
---
--- Parameters:
---  * resolvable  - a `resolvable` value, of which the first result will be returned.
---
--- Returns:
---  * The `Statement` which will return the first value when executed.
local Last = Statement.named("Last")
:onInit(function(context, resolvable)
    assert(resolvable ~= nil, "The Last `resolvable` may not be `nil`.")
    context.resolvable = resolvable
end)
:onObservable(function(context)
    return toObservable(context.resolvable):last()
end)
:define()

return Last