--- === cp.strings ===
---
--- Provides strings from (potentially) multiple sources, with support for loading from multiple languages.
---
--- ```lua
--- local strs = require("cp.strings").new():fromPlist("/Path/To/Resources/${language}.lproj/MYLocalization.strings")
--- local value = strs:find("en", "AKey")
--- ```
---
--- This will load the file for the specified language (replacing `${language}` with `"en"` in the path) and return the value.
--- Note: This will load the file on each request. To have values cached, use the `cp.strings` module and specify a `plist` as a source.

local log               = require("hs.logger").new("strings")
local plistSrc          = require("cp.strings.source.plist")
local append            = require("moses").append

local mod = {}
mod.mt = {}

local UNFOUND = {}

--- cp.strings:from(source) -> cp.strings
--- Method
--- Adds the source to the strings sources.
---
--- Parameters:
---  * `source`		- The source to add.
---
--- Returns:
---  * The current `cp.strings` instance.
function mod.mt:from(source)
    table.insert(self._sources, source)
    self._cache = {}
    return self
end

--- cp.strings:fromPlist(pathPattern) -> cp.strings
--- Method
--- Convenience method for addedn a `plist` source to the strings instance.
---
--- Parameters:
---  * `pathPattern`	- The path to load from. May contain a special `${language}` marker which will be replace with the provided langauge when searching.
---
--- Returns:
---  * The current `cp.strings` instance.
function mod.mt:fromPlist(pathPattern)
    return self:from(plistSrc.new(pathPattern))
end

--- cp.strings:findInSources(language, key[, quiet]) -> string | nil
--- Method
--- Searches directly in the sources for the specified language/key combination.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `key`		- The key to retrieve from the file.
---  * `quiet`		- Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:findInSources(language, key, quiet)
    for _,source in ipairs(self._sources) do
        local value = source:find(language, key, quiet)
        if value then return value end
    end
    return nil
end

--- cp.strings:findKeysInSources(language, value) -> string | nil
--- Method
--- Searches directly in the sources for the specified language/value combination.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `value`		- The value to search for.
---
--- Returns:
---  * The array of keys, or `{}` if not found.
function mod.mt:findKeysInSources(language, value)
    local keys = {}
    for _,source in ipairs(self._sources) do
        keys = append(keys, source:findKeys(language, value))
    end
    return keys
end


--- cp.strings:find(language, key[, quiet]) -> string | nil
--- Method
--- Searches for the specified key in the specified language, caching the result when found.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `key`		- The key to retrieve from the file.
---  * `quiet`		- Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:find(language, key, quiet)
    -- ensure we have a cache for the specific language
    self._cache[language] = self._cache[language] or {}
    local cache = self._cache[language]
    local value = cache[key]

    if value == nil then
        value = self:findInSources(language, key) or UNFOUND
        cache[key] = value
    end

    if value == UNFOUND then
        if not quiet then
            log.wf("Unable to find '%s' in '%s'", key, language)
        end
        return nil
    else
        return value
    end
end

--- cp.strings:findKeysIn(language, value) -> string | nil
--- Method
--- Searches for the list of keys with a matching value, in the specified language.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `value`		- The value to search for.
---
--- Returns:
---  * The array of keys, or `{}` if not found.
function mod.mt:findKeys(language, value)
    -- NOTE: Not bothering to cache results currently, since it should not be a frequent operation.
    return self:findKeysInSources(language, value)
end

--- cp.strings.new() -> cp.strings
--- Constructor
--- Creates a new `strings` instance. You should add sources with the [from](#from) or [fromPlist](#fromPlist) methods.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new `cp.strings`
function mod.new()
    local o = {
        _sources = {},
        _cache = {},
    }
    return setmetatable(o, {__index = mod.mt})
end

return mod