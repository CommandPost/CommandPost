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

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require = require
local log               = require("hs.logger").new("strings")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local inspect           = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local plistSrc          = require("cp.strings.source.plist")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _                 = require("moses")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local append            = _.append

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- UNFOUND -> table
-- Constant
-- Default Unfound Value.
local UNFOUND = {}

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}
mod.mt = {}

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
        self._cache = nil
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

--- cp.strings:findInSources(key[, context[, quiet]]) -> string | nil
--- Method
--- Searches directly in the sources for the specified key.
---
--- Parameters:
---  * `key`        - The key to retrieve from the file.
---  * `context`    - Optional table with additional/alternate context.
---  * `quiet`      - Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:findInSources(key, context) -- TODO: Quiet isn't actually used?
    for _,source in ipairs(self._sources) do
        local value = source:find(key, context)
        if value then return value end
    end
    return nil
end

--- cp.strings:findKeysInSources(value[, context]) -> string | nil
--- Method
--- Searches directly in the sources for the specified key value pattern.
---
--- Parameters:
---  * `value`      - The value to search for.
---  * `context`    - Optional additional context for the request.
---
--- Returns:
---  * The array of keys, or `{}` if not found.
function mod.mt:findKeysInSources(value, context)
    local keys = {}
    for _,source in ipairs(self._sources) do
        keys = append(keys, source:findKeys(value, context))
    end
    return keys
end


--- cp.strings:find(key[, context[, quiet]) -> string | nil
--- Method
--- Searches for the specified key, caching the result when found.
---
--- Parameters:
---  * `key`        - The key to retrieve from the file.
---  * `context`    - Optional table with additional/alternate context.
---  * `quiet`      - Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:find(key, context, quiet)
    -- ensure we have a cache for the specific language
    local cache = self._cache
    local value = context == nil and cache and cache[key] or nil

    if value == nil then
        value = self:findInSources(key, context) or UNFOUND
        if context == nil then
            if cache == nil then
                cache = {}
                self._cache = cache
            end
            cache[key] = value
        end
    end

    if value == UNFOUND then
        if not quiet then
            log.wf("Unable to find '%s' in context: %s", key, inspect(context))
        end
        return nil
    else
        return value
    end
end

--- cp.strings:findKeys(value[, context]) -> string | nil
--- Method
--- Searches for the list of keys with a matching value, in the specified language.
---
--- Parameters:
---  * `value`      - The value to search for.
---  * `context`    - The language code to look for (e.g. `"en"`, or `"fr"`).
---
--- Returns:
---  * The array of keys, or `{}` if not found.
function mod.mt:findKeys(value, context)
    -- NOTE: Not bothering to cache results currently, since it should not be a frequent operation.
    return self:findKeysInSources(value, context)
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
