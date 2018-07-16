
--- === cp.rx.go.Done ===
---
--- A [Statement](cp.rx.go.Statement.md) that will complete without sending any values.
---
--- Example:
---
--- ```lua
--- Done()
--- ```

local Statement             = require("cp.rx.go.Statement")
local Observable            = require("cp.rx").Observable

--- cp.rx.go.Done() -> Done
--- Constructor
--- Creates a new `Done` `Statement` that will complete without sending any values.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` which will complete immediately.
local Done = Statement.named("Done")
:onObservable(function()
    return Observable.empty()
end)
:define()

return Done