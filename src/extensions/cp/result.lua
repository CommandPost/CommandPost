--- === cp.result ===
---
--- Represents the result of an operation which may end in `success` or `failure`.
--- If it is a `success`, a `value` is typically provided.
--- If it is a `failure`, a `message` is typically provided.
---
--- Using this type allows for more structured checking when performing an operation which may fail in a number
--- of ways, rather than just calling `error` and crashing out. For example:
---
--- ```lua
--- function clamped(value, min, max)
---     if value < min then
---         return result.failure("expected at least %d but got %d", min, value)
---     elseif value > max then
---         return result.failure("expected at most %d but got %d", max, value")
---     else
---         return result.success(value)
---     end
--- end
---
--- local outcome = clamped(-1, 0, 100)
--- if outcome.failure then
---     error(outcome.message)
--- end
--- local value = outcome.value
--- ```
---
--- Of course, simply checking the result and throwing an `error` is a common case, so you can achieve the same result like so:
---
--- ```lua
--- local value = clamped(-1, 0, 100):get()
--- ```
---
--- If you want to perform other tasks, check for `.failure` or `.success` and perform the appropriate response.

local inspect       = require "hs.inspect"
local format        = string.format

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.result.is(value) -> boolean
--- Function
--- Checks if the `value` is an instance of a `cp.result`.
---
--- Parameters:
---  * `value`  - The value to check.
---
--- Returns:
---  * `true` if the value is an instance of `cp.result`.
function mod.is(value)
    if value and type(value) == "table" then
        local mt = getmetatable(value)
        return mt == mod.mt
    end
    return false
end

--- cp.result.success(value) -> result
--- Constructor
--- Creates a new `success` result, with the specified `value`.
function mod.success(value)
    return setmetatable({success = true, value = value}, mod.mt)
end

--- cp.result.failure(message) -> result
--- Constructor
--- Creates a new `failure` result, with the specified error `message`.
function mod.failure(message, ...)
    if message and select("#", ...) > 0 then
        message = format(message, ...)
    end

    return setmetatable({failure = true, message = message}, mod.mt)
end

--- cp.result.from(value, err) -> result
--- Constructor
--- Provides a simple wrapper for the common `value, err` pattern of function error handling in Lua.
--- If the `err` value is not `nil`, it will result in a `failure`, otherwise the `value` is passed to a `success`.
---
--- Parameters:
---  * value - The value if successful.
---  * err - The error message if there was a failure.
---
--- Returns:
---  * A `result.success` or `result.failure`.
function mod.from(value, err)
    if err then
        return mod.failure(err)
    else
        return mod.success(value)
    end
end

--- cp.result.notNil(value, err) -> result
--- Constructor
--- Provides a simple wrapper for the common `value, err` pattern of function error handling in Lua.
--- If the `value` is `nil` it will result in a `failure` with the optional `err` message, otherwise the `value` is passed to a `success`.
---
--- Parameters:
---  * value - The value if successful.
---  * err - The error message if there was a failure.
---
--- Returns:
---  * A `result.success` or `result.failure`.
function mod.notNil(value, err)
    if value == nil then
        return mod.failure(err)
    else
        return mod.success(value)
    end
end

--- cp.result:get() -> anything
--- Method
--- Gets the successful value, or throws an `error` with the provided `message`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `value` if it was a `success`, otherwise throws an `error`.
function mod.mt:get()
    if self.failure then
        error(self.message, 2)
    else
        return self.value
    end
end

function mod.mt:__tostring()
    if self.success then
        local value = self.value
        local valueType = type(value)
        if value == nil then
            value = "nil"
        elseif valueType == "table" or valueType=="userdata" then
            if value.__tostring then
                value = tostring(value)
            else
                value = inspect(value)
            end
        else
            value = tostring(value)
        end
        return format("success: %s", value)
    else
        return self.message == nil and "error" or format("error: %s", inspect(self.message))
    end
end

function mod.mt.__eq(a,b)
    if a.success then
        return b.success and a.value == b.value
    elseif a.failure then
        return b.failure and a.message == b.message
    else
        return false
    end
end

return mod