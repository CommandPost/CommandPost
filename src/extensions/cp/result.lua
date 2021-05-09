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

local format = string.format

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

--- cp.result:check() -> anything
--- Method
--- Checks if this result was a `failure`, and if so throws an `error` with the provided `message`. Otherwise, it returns the `success` `value`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `value` if it was a `success`, otherwise throws an `error`.
function mod.mt:check()
    if self.failure then
        error(self.message, 2)
    else
        return self.value
    end
end

return mod