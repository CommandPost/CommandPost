--- === cp.fn.string ===
---
--- String-related functional programming helpers.

local mod = {}

--- cp.fn.string.isEmpty(str) -> boolean
--- Function
--- Checks if the string is empty.
---
--- Parameters:
---  * str - The string to check.
---
--- Returns:
---  * `true` if the string is empty, `false` otherwise.
function mod.isEmpty(str)
    return str == nil or str == ""
end

--- cp.fn.string.match(pattern) -> function(str) -> ...
--- Function
--- Creates a function that matches the given pattern. Any groups in the pattern will be returned as multiple values.
---
--- Parameters:
---  * pattern - The pattern to match.
---
--- Returns:
---  * A function that takes a string and returns the matches.
function mod.match(pattern)
    return function(str)
        return string.match(str, pattern)
    end
end

return mod