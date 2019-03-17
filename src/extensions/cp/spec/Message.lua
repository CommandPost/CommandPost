--- === cp.spec.Message ===
---
--- Provides an Message message, which can be thrown via the `error` function.

local class         = require "middleclass"

local Message         = class("cp.spec.Message")

--- cp.spec.Message.is(other) -> boolean
--- Function
--- Checks if the `other` is an instance of the `Message` class.
function Message.static.is(other)
    return other ~= nil and type(other) == "table" and other.isInstanceOf ~= nil and other:isInstanceOf(Message)
end

--- cp.spec.Message(message)
--- Constructor
--- Creates a new Message message.
---
--- Parameters:
--- * message   - the message to send.
function Message:initialize(msg)
    self.message = msg
end

--- cp.spec.Message:traceback()
--- Method
--- Stores the `debug.traceback` result at the present time. Can be retrieved via `stacktrace`
function Message:traceback()
    if self._traceback == nil then
        self._traceback = debug.traceback(self.message)
    end
    return self._traceback
end

function Message:__tostring()
    return tostring(self._traceback or self.message)
end

return Message