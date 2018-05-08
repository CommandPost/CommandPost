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


--- cp.strings.source.table:add(keyValues) -> self
--- Method
--- Adds the specified table of key values in the specified language code.
---
--- Parameters:
---  * `keyValues`  - The table of key/value pairs to define.
---
--- Returns:
---  * The `cp.string.source`.
function mod.mt:add(keyValues)
    self._cache = _.extend(self._cache or {}, keyValues)
    return self
end

--- cp.strings.source.table:find(key) -> string
--- Method
--- Finds the specified `key` value in the plist file for the specified optional `context`,
--- if the plist can be found, and contains matching key value.
---
--- Parameters:
---  * `key`        - The key to retrieve the value for.
---  * `context`    - An optional table with additional context.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:find(key)
    local values = self._cache
    if values ~= nil then
        return values[key]
    end
    return nil
end

--- cp.strings.source.plist:findKeys(pattern) -> {string}
--- Method
--- Finds the array of keys who's value matches the pattern in this table. It will check that the pattern matches the beginning of the value.
---
--- Parameters:
---  * `pattern		- The string pattern to match.
---  * `context`	- An optional additional context for the source.
---
--- Returns:
---  * The array of keys, or `{}` if none were fround
function mod.mt:findKeys(pattern)
    local keys = {}
    local cache = self._cache
    if cache then
        for k,v in pairs(cache) do
            local s, e = find(v, pattern)
            if s == 1 and e == len(v) then
                insert(keys, k)
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