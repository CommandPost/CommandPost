--- === cp.spec.Handled ===
---
--- An synchronous/asynchronous test library for Lua.

local Message           = require "cp.spec.Message"

local Handled       = Message:subclass("cp.spec.Handled")

--- cp.spec.Handled.is(other) -> boolean
--- Function
--- Checks if the `other` is an instance of the `Handled` class.
---
--- Parameters:
---  * other - An object to check.
---
--- Returns:
---  * A boolean.
function Handled.static.is(other)
    return other ~= nil and type(other) == "table" and other.isInstanceOf ~= nil and other:isInstanceOf(Handled)
end

return Handled