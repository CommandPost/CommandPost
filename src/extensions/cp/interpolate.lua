--- === cp.interpolate ===
---
--- Provides a function that will interpolate values into a string.
--- It also augments the standard `string` to override the "mod" (`%`) operator so that
--- any string can be easily interpolated, like so:
---
--- ```lua
--- "Hello ${world}" % { world = "Earth" }
--- ```

-- local log   = require "hs.logger" .new "interpolate"

-- local PATTERN = "%$%{(%a%w*)(%:[-0-9%.]*[cdeEfgGiouxXsq])?%}"
local TOKEN_PATTERN = "(%$%b{})"
local KEY_PATTERN = "^%$%{(%a%w*)%}$"
local KEY_FORMAT_PATTERN = "^%$%{(%a%w*)[:]([-0-9%.]*[cdeEfgGiouxXsq])%}$"

local function interpolate(s, values)
    return (s:gsub(TOKEN_PATTERN,
        function(token)
            local key, fmt = token:match(KEY_PATTERN), "s"
            if not key then
                key, fmt = token:match(KEY_FORMAT_PATTERN)
            end

            if not key then
                error("Invalid replacement token: " .. token)
            end

            local value = values[key]
            return ("%" .. fmt):format(value)
        end
    ))
end

getmetatable("").__mod = interpolate

return interpolate

