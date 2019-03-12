--- === cp.pattern ===
---
--- Contains pattern matching utility functions.

-- local log                       = require "hs.logger" .new "pattern"

local mod = {}

local function escape(pattern)
    return pattern:gsub("([.?+{}%%])", "%%%1")
end

local function buildPattern(searchString, wholeWords)
    local buffer = wholeWords and "[^%S]" or ""
    return buffer .. escape(searchString) .. buffer
end

local defaultOptions = {
    caseSensitive = true,
    exact = true,
    wholeWords = false,
}

--- cp.pattern.doesMatch(value, searchString[, options]) -> boolean
--- Function
--- Checks if the provided value matches the search string, given the provided options.
---
--- Parameters:
--- * value         - The value to check.
--- * searchString  - The string values to match.
--- * options       - The table of options.
---
--- Returns:
--- * `true` if the value matches the search string
---
--- Notes:
--- * Supported options:
---     * caseSensitive - If `true`, the case in the search string must match the value.
---     * exact         - If `true`, the search string must match exactly somewhere within the value. If `false`, words separated by spaces can appear anywhere in the value.
---     * wholeWords    - If `true`, either the whole string (if `exact` is `true`) or each word (if `exact` is false) must match at word boundaries.
function mod.doesMatch(value, searchString, options)
    options = options and setmetatable(options, {__index = defaultOptions}) or defaultOptions
    local caseSensitive = options.caseSensitive == true
    local exact         = options.exact == true
    local wholeWords    = options.wholeWords == true

    local pattern       = caseSensitive and searchString or searchString:lower()

    -- add a space to allow matching patterns at beginning or end of value.
    value = " " .. (caseSensitive and value or value:lower()) .. " "

    if exact then
        pattern = buildPattern(pattern, wholeWords)
    else
        local p = ""
        for word in pattern:gmatch("%S+") do
            p = p .. ".*" .. buildPattern(word, exact, wholeWords)
        end
        pattern = p
    end

    pattern = "^.*" .. pattern .. ".*$"

    return value:find(pattern) == 1
end

return mod