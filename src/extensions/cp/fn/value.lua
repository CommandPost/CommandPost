--- === cp.fn.value ===
---
--- A collection of functions for working with values.

local require               = require

-- local log                   = require "hs.logger" .new "value"

local fn                    = require "cp.fn"
local is                    = require "cp.is"

local pack, unpack          = table.pack, table.unpack
local all                   = fn.all

local mod = {}

--- cp.fn.value.default(...) -> function(...) -> ...
--- Function
--- A combinator that takes a list of default values and returns a function
--- that accepts a list of values and returns the same number of values, with either
--- the value passed in or the default value if that value is `nil`.
---
--- Parameters:
---  * ... - A list of default values.
---
--- Returns:
---  * A function that accepts a list of values and returns the same number of values, with either
---  the value passed in or the default value if that value is `nil`.
---
--- Notes:
---  * Example: `cp.fn.value.default(1, 2, 3)(5, nil, 6) -- returns 5, 2, 6`
function mod.default(...)
    local defaults = pack(...)
    return function(...)
        local values = pack(...)
        local result = {}
        local count = math.max(#values, #defaults)
        for i = 1, count do
            result[i] = values[i] or defaults[i]
        end
        return unpack(result)
    end
end

--- cp.fn.value.filter(predicate, ...) -> function(value) -> value | nil
--- Function
--- Filters a value using a list of predicates which must all be `true` to succeed.
---
--- Parameters:
---  * predicate - A function that takes a value and returns `true` or `false`.
---  * ... - Optional additional predicates which must all be `true` to succeed.
---
--- Returns:
---  * A function that takes a value and returns the value if the predicates all return `true`, otherwise `nil`.
function mod.filter(predicate, ...)
    predicate = all(predicate, ...)
    return function(value)
        if predicate(value) then
            return value
        end
    end
end

--- cp.fn.value.map(mapper) -> function(value) -> any | nil
--- Function
--- If the value is not `nil`, then it will be passed to the mapper function and the result returned.
---
--- Parameters:
---  * mapper - A function that takes a value and returns a value.
---
--- Returns:
---  * A function that takes a value and returns the result of the mapper function, or `nil` if the value is `nil`.
function mod.map(mapper)
    return function(value)
        if value ~= nil then
            return mapper(value)
        end
    end
end

--- cp.fn.value.matches(predicate, ...) -> function(value) -> boolean
--- Function
--- Returns a function that returns `true` if the value matches the predicates.
---
--- Parameters:
---  * predicate - A function that takes a value and returns `true` or `false`.
---  * ... - Optional additional predicates which must all be `true` to succeed.
---
--- Returns:
---  * A function that takes a value and returns `true` if the value matches the all predicates, otherwise `false`.
function mod.matches(predicate, ...)
    predicate = all(predicate, ...)
    return function(value)
        return predicate(value)
    end
end

--- cp.fn.value.is(other) -> function(value) -> boolean
--- Function
--- Returns a function that returns `true` if the value is equal to the other value.
--- If `other` is a function, then it will be called with no arguments and the result will be compared.
---
--- Parameters:
---  * other - A value or a function that returns a value.
---
--- Returns:
---  * A function that takes a value and returns `true` if the value is equal to the other value, otherwise `false`.
function mod.is(other)
    other = is.callable(other) and other or fn.constant(other)
    return function(value)
        return value == other()
    end
end


return mod