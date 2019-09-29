--- === cp.rx.go.Throw ===
---
--- A [Statement](cp.rx.go.Statement.md) that will throw the provided message.
---
--- Example:
---
--- ```lua
--- Throw("There was an error: %s", errorMessage)
--- ```

local Statement             = require "cp.rx.go.Statement"
local Observable            = require "cp.rx".Observable

local format                = string.format

--- cp.rx.go.Throw([message[, ...]]) -> Throw
--- Constructor
--- Creates a new `Throw` `Statement` that will throw the message when executed.
---
--- Parameters:
---  * message  - The optional message to return. May contain `string.format` tokens
---  * ...      - The optional list of parameters to inject into the message.
---
--- Returns:
---  * The `Statement` which will send the provided error message.
local Throw = Statement.named("Throw")
:onInit(function(context, message, ...)
    context.message = message and format(message, ...) or nil
end)
:onObservable(function(context)
    return Observable.throw(context.message)
end)
:define()

return Throw