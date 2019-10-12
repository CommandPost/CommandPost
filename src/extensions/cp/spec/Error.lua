--- === cp.spec.Error ===
---
--- Provides an Error message, which can be thrown via the `error` function.

local Message         = require "cp.spec.Message"

local Error         = Message:subclass("cp.spec.Error")

--- cp.spec.Error.is(other) -> boolean
--- Function
--- Checks if the `other` is an instance of the `Error` class.
function Error.static.is(other)
    return other ~= nil and type(other) == "table" and other.isInstanceOf ~= nil and other:isInstanceOf(Error)
end

return Error