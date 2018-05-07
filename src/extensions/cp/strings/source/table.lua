--- === cp.strings.source.table ===
---
--- Loads strings from provided tables, allowing for a given language variation. Eg:
---
--- ```lua
--- local src = require("cp.strings.source.table").new():add("en", {foo = "bar"}):add("en", {foo = "baz"})
--- local valueEn = src:find("en", "foo") -- "bar"
--- local valueEs = src:find("en", "foo") -- "baz"
--- ```
---
--- This will load the file for the specified language (replacing `${language}` with `"en"` in the path) and return the value.
--- Note: This will load the file on each request. To have values cached, use the `cp.strings` module and specify a `plist` as a source.

-- local log				= require("hs.logger").new("tblsrc")

local _					= require("moses")
local find, len			= string.find, string.len
local insert			= table.insert

local mod = {}
mod.mt = {
    _context = {}
}

--- cp.strings.source.table:context([context]) -> table | self
--- Method
--- Gets or sets a context to be set for the source. This typically includes a `language`, which
--- provides the default language code, but may have other source-specific properties.
--- Calling this method may may clear caches, etc.
---
--- Eg:
---
--- ```lua
--- mySource:context({language = "fr"}) -- set the default language to French.
--- ```
---
--- Parameters:
--- * context   - A table with values which may be used by the source.
---
--- Returns:
--- * If a new context is provided, the `cp.string.source` is returned, otherwise the current context table is returned.
function mod.mt:context(context)
    if context ~= nil then
        self._context = _.extend({}, context)
        return self
    else
        return self._context
    end
end


--- cp.strings.source.table:add(keyValues, language) -> self
--- Method
--- Adds the specified table of key values in the specified language code.
---
--- Parameters:
---  * `keyValues`  - The table of key/value pairs to define.
---  * `language`   - The language code to look for (e.g. `"en"`, or `"fr"`).
---
--- Returns:
---  * The `cp.string.source`.
function mod.mt:add(keyValues, language)
    self._cache[language] = _.extend(self._cache[language] or {}, keyValues)
    return self
end

--- cp.strings.source.table:find(key[, language]) -> string
--- Method
--- Finds the specified `key` value in the plist file for the specified `language`, if the plist can be found, and contains matching key value.
---
--- Parameters:
---  * `key`        - The key to retrieve the value for.
---  * `context`    - The language code to look for (e.g. `"en"`, or `"fr"`). If none is provided, the context is checked, and if none is found, `nil` is returned.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:find(key, language)
    language = language or self._context.language
    if language and self._cache[language] then
        return self._cache[language][key]
    end
    return nil
end

--- cp.strings.source.plist:findKeys(pattern[, language]) -> {string}
--- Method
--- Finds the array of keys who's value matches the pattern in this table. It will check that the pattern matches the beginning of the value.
---
--- Parameters:
---  * `pattern		- The string pattern to match.
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`). Defaults to the `language` in the context if none is provided.
---
--- Returns:
---  * The array of keys, or `{}` if none were fround
function mod.mt:findKeys(pattern, language)
    local keys = {}
    language = language or self._context.language
    if language then
        local cache = self._cache[language]

        if cache then
            for k,v in pairs(cache) do
                local s, e = find(v, pattern)
                if s == 1 and e == len(v) then
                    insert(keys, k)
                end
            end
        end
    end
    return keys
end

function mod.mt:reset()
    self._cache = {}
end

--- cp.strings.source.table.new(context) -> source
--- Constructor
--- Creates a new `cp.strings` source that loads strings from a plist file.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new plist `source` instance.
mod.new = function(context)
    local o = {
        _cache = {},
        _context = context or {}
    }
    return setmetatable(o, {__index = mod.mt})
end

return mod