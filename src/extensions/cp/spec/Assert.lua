--- === cp.spec.Assert ===
---
--- Provides an Assert message, which can be thrown via the `error` function.

local Message         = require "cp.spec.Message"

local Assert         = Message:subclass("cp.spec.Assert")

--- cp.spec.Assert.is(other) -> boolean
--- Function
--- Checks if the `other` is an instance of the `Assert` class.
function Assert.static.is(other)
    return other ~= nil and type(other) == "table" and other.isInstanceOf ~= nil and other:isInstanceOf(Assert)
end

return Assert