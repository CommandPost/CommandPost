--- === cp.is ===
---
--- A simple class that lets you test if a value `is` a particular type.
--- Note: for best performance, assign the specific checks you want to use to local functions. Eg:
---
--- ```lua
--- local is_nothing = require("cp.is").nothing
--- is_nothing(nil) == true
--- ```
---
--- You can also get functions that negate the functions below by calling `is.nt.XXX(...)` (read: "isn't XXX").
--- The individual functions are not documented, but all will work as expected. Eg:
---
--- ```lua
--- is.blank("") == true
--- is.nt.blank("") == false
--- ```
---
--- They can also be assigned directly to local values for better performance:
---
--- ```lua
--- local isnt_blank = is.nt.blank
--- isnt_blank(nil) == false
--- ```

local type = type

--- cp.is.nothing(value) -> boolean
--- Function
--- Check if the value is `nil`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_nothing(value)
    return value == nil
end

--- cp.is.string(value) -> boolean
--- Function
--- Check if the value is a string.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_string(value)
    return type(value) == "string"
end

--- cp.is.fn(value) -> boolean
--- Function
--- Check if the value is a `function`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_fn(value)
    return type(value) == "function"
end

--- cp.is.number(value) -> boolean
--- Function
--- Check if the value is a `number`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_number(value)
    return type(value) == "number"
end

--- cp.is.boolean(value) -> boolean
--- Function
--- Check if the value is a `function`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_boolean(value)
    return type(value) == "boolean"
end

--- cp.is.table(value) -> boolean
--- Function
--- Check if the value is a `table`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_table(value)
    return type(value) == "table"
end

--- cp.is.userdata(value) -> boolean
--- Function
--- Check if the value is a `userdata` object.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_userdata(value)
    return type(value) == "userdata"
end

--- cp.is.object(value) -> boolean
--- Function
--- Check if the value is a `object`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_object(value)
    return is_table(value) or is_userdata(value)
end

--- cp.is.list(value) -> boolean
--- Function
--- Check if the value is a `list`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_list(value)
    return is_object(value) and #value > 0
end

--- cp.is.truthy(value) -> boolean
--- Function
--- Check if the value is a `truthy` value.
--- A value is considered to be truthy if it is not `nil` nor `false`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_truthy(value)
    return value ~= nil and value ~= false
end

--- cp.is.falsey(value) -> boolean
--- Function
--- Check if the value is a `falsey` value.
--- A value is considered to be `falsey` if it is `nil` or `false`.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_falsey(value)
    return not is_truthy(value)
end

-- has_callable(value) -> boolean
-- Private Function
-- Checks if the value is a table with a `__call` function, or if its metatable (if present) has one.
--
-- Parameters:
-- * value  - The value to check.
--
-- Returns:
-- * `true` if the value is a `table` and has a `__call` function or a metatable ancestor has one.
local function has_callable(value, checked)
    if is_table(value) then
        checked = checked or {}
        checked[value] = true
        if is_fn(value.__call) then
            return true
        else
            local mt = getmetatable(value)
            if not checked[mt] then
                return has_callable(getmetatable(value), checked)
            end
        end
    end
    return false
end

--- cp.is.callable(value) -> boolean
--- Function
--- Check if the value is a callable - either a `function` or a `table` with `__call` in it's metatable hierarchy.
---
--- Parameters:
--- * value     - the value to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_callable(value)
    return is_fn(value) or is_table(value) and has_callable(getmetatable(value))
end

--- cp.is.blank(value) -> boolean
--- Function
--- Check if the value is a blank string value - either `nil` or `tostring(value) == ""`.
---
--- Parameters:
--- * value     - the value to check.
---
--- Returns:
--- * `true` if it matches, `false` if not.
local function is_blank(value)
    return value == nil or tostring(value) == ""
end

local is = {
    nothing         = is_nothing,
    string          = is_string,
    fn              = is_fn,
    number          = is_number,
    boolean         = is_boolean,
    table           = is_table,
    userdata        = is_userdata,
    object          = is_object,
    list            = is_list,
    truthy          = is_truthy,
    falsey          = is_falsey,
    falsy           = is_falsey,
    callable        = is_callable,
    blank           = is_blank,
}

-- prepare `is.nt`
local isnt = {}
for k,fn in pairs(is) do
    isnt[k] = function(value) return not fn(value) end
end
is.nt = isnt

return is