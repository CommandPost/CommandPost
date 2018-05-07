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
local _                 = require("moses")

local append            = _.append

local mod = {}
mod.mt = {}

local UNFOUND = {}

--- cp.strings:context([context]) -> table | self
--- Method
--- Gets or sets a context to be set for the strings. This typically includes a `language`, which
--- provides the default language code, but may have other source-specific properties.
--- Calling this method may may clear caches, etc.
---
--- Eg:
---
--- ```lua
--- string:context({language = "fr"}) -- set the default language to French.
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
        for _,source in ipairs(self._sources) do
            source:context(context)
        end
        return self
    else
        return self._context
    end
end

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
    source:context(self._context)
    self._cache = {}
    return self
end

--- cp.strings:fromPlist(pathPattern) -> cp.strings
--- Method
--- Convenience method for adding a `plist` source to the strings instance.
---
--- Parameters:
---  * `pathPattern`	- The path to load from. May contain a special `${language}` marker which will be replace with the provided langauge when searching.
---
--- Returns:
---  * The current `cp.strings` instance.
function mod.mt:fromPlist(pathPattern)
    return self:from(plistSrc.new(pathPattern))
end

--- cp.strings:findInSources(key[, language[, quiet]]) -> string | nil
--- Method
--- Searches directly in the sources for the specified language/key combination.
---
--- Parameters:
---  * `key`		- The key to retrieve from the file.
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `quiet`		- Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:findInSources(key, language, quiet)
    for _,source in ipairs(self._sources) do
        local value = source:find(key, language, quiet)
        if value then return value end
    end
    return nil
end

--- cp.strings:findKeysInSources(value[, language]) -> string | nil
--- Method
--- Searches directly in the sources for the specified language/value combination.
---
--- Parameters:
---  * `value`		- The value to search for.
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---
--- Returns:
---  * The array of keys, or `{}` if not found.
function mod.mt:findKeysInSources(value, language)
    local keys = {}
    for _,source in ipairs(self._sources) do
        keys = append(keys, source:findKeys(value, language))
    end
    return keys
end


--- cp.strings:find(key[, language[, quiet]) -> string | nil
--- Method
--- Searches for the specified key in the specified language, caching the result when found.
---
--- Parameters:
---  * `key`		- The key to retrieve from the file.
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `quiet`		- Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:find(key, language, quiet)
    -- ensure we have a cache for the specific language
    self._cache[language] = self._cache[language] or {}
    local cache = self._cache[language]
    local value = cache[key]

    if value == nil then
        value = self:findInSources(key, language) or UNFOUND
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

--- cp.strings:findKeys(value[, language]) -> string | nil
--- Method
--- Searches for the list of keys with a matching value, in the specified language.
---
--- Parameters:
---  * `value`		- The value to search for.
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---
--- Returns:
---  * The array of keys, or `{}` if not found.
function mod.mt:findKeys(value, language)
    -- NOTE: Not bothering to cache results currently, since it should not be a frequent operation.
    return self:findKeysInSources(value, language)
end

--- cp.strings.new(context) -> cp.strings
--- Constructor
--- Creates a new `strings` instance. You should add sources with the [from](#from) or [fromPlist](#fromPlist) methods.
---
--- Parameters:
---  * context      - The initial context.
---
--- Returns:
---  * The new `cp.strings`
function mod.new(context)
    local o = {
        _sources = {},
        _cache = {},
    }
    setmetatable(o, {__index = mod.mt})

    if context then
        o:context(context)
    end

    return o
end

return mod