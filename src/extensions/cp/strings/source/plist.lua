--- === cp.strings.source.plist ===
---
--- Loads strings from a `plist` with allowing for a given language variation. Eg:
---
--- ```lua
--- local plistSource = require("cp.strings.source.plist").new("/Path/To/Resources/${language}.lproj/MYLocalization.strings")
--- local value = plistSource:find("en", "AKey")
--- ```
---
--- This will load the file for the specified language (replacing `${language}` with `"en"` in the path) and return the value.
--- Note: This will load the file on each request. To have values cached, use the `cp.strings` module and specify a `plist` as a source.

-- local log				= require("hs.logger").new("plistsrc")

local _                 = require("moses")
local plist				= require("cp.plist")
local fs				= require("hs.fs")
local timer				= require("hs.timer")
local text				= require("cp.web.text")

local escapeXML, unescapeXML = text.escapeXML, text.unescapeXML
local find, len			= string.find, string.len
local insert			= table.insert

local aliases = {
    de	= "German",
    en	= "English",
    es	= "Spanish",
    fr	= "French",
    it	= "Italian",
    ja	= "Japanese",
}


local mod = {}
mod.mt = {}

--- cp.strings.source.plist.defaultCacheSeconds
--- Constant
--- The default number of seconds to cache results.
mod.defaultCacheSeconds = 60.0

--- cp.strings.source.plist:context([context]) -> table | self
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
        self:reset()
        return self
    else
        return self._context
    end
end

--- cp.strings.source.plist:pathToAbsolute([context]) -> string
--- Method
--- Finds the abolute path to the `plist` represented by this source for the specified langauge, or `nil` if it does not exist.
---
--- Parameters:
---  * `context`	- The context to determine the absolute path with. This will be added to any values provided in the default [context](#context).
---
--- Returns:
---  * The path to the file, or `nil` if not found.
function mod.mt:pathToAbsolute(context)
    local ctx = _.extend({}, self._context, context)
    local path = self._pathPattern
    for key,value in pairs(ctx) do
        path = path:gsub("${"..tostring(key).."}", tostring(value))
    end
    return fs.pathToAbsolute(path)
end

--- cp.strings.source.plist:loadFile([context]) -> string
--- Method
--- Loads the plist file for the specified context, returning the value as a table.
---
--- Parameters:
---  * `context`	- The context to determine the absolute path with. This will be added to any values provided in the default [context](#context).
---
--- Returns:
---  * The table for the specified language, or `nil` if the file doesn't exist.
function mod.mt:loadFile(context)
    local ctx = _.extend({}, self._context, context)
    local langFile = self:pathToAbsolute(context)
    if not langFile and ctx.language and aliases[ctx.language] then
        -- try an alias
        ctx.language = aliases[ctx.language]
        langFile = self:pathToAbsolute(ctx)
    end

    self._cleanup:start()
    if langFile then
        return plist.fileToTable(langFile)
    end
    return nil
end

--- cp.strings.source.plist:find(key[, language]) -> string
--- Method
--- Finds the specified `key` value in the plist file for the specified `language`, if the plist can be found, and contains matching key value.
---
--- Parameters:
---  * `key`		- The key to retrieve from the file.
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:find(key, language)
    local cache = self._cache
    if cache == nil then
        cache = {}
        self._cache = cache
    end

    local values = cache[language]
    if values == nil then
        local ctx = language and {language = language} or nil
        values = self:loadFile(ctx) or {}
        cache[language] = values
    end

    return unescapeXML(values[escapeXML(key)])
end

--- cp.strings.source.plist:findKeys(patterns[, language]) -> table of strings
--- Method
--- Finds the array of keys whos value matches the pattern in the plist file for the specified `language`, if the plist can be found, and contains matching key.
---
--- Parameters:
---  * `pattern		- The value pattern.
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---
--- Returns:
---  * The array of keys, or `{}` if none were fround
function mod.mt:findKeys(pattern, language)
    local cache = self._cache
    if cache == nil then
        cache = {}
        self._cache = cache
    end

    local values = cache[language]
    if values == nil then
        local ctx = language and {language = language} or nil
        values = self:loadFile(ctx) or {}
        cache[language] = values
    end

    local keys = {}
    for k,v in pairs(values) do
        v = unescapeXML(v)
        -- check if the pattern matches the beginning of the key value
        local s, e = find(v, pattern)
        if s == 1 and e == len(v) then
        insert(keys, unescapeXML(k))
        end
    end
    return keys
end

--- cp.strings.source.plist:reset() -> cp.strings
--- Method
--- Clears any stored key values.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The current `cp.strings` instance.
function mod.mt:reset()
    self._cache = nil
    return self
end

--- cp.strings.source.plist.new(pathPattern[, cacheSeconds]) -> source
--- Constructor
--- Creates a new `cp.strings` source that loads strings from a plist file.
---
--- Parameters:
---  * `pathPattern`	- The path to load from. May contain a special `${language}` marker which will be replace with the provided langauge when searching.
---  * `cacheSeconds`	- (optional) How long in seconds to keep the loaded values cached in memory. Defaults to [defaultCacheSeconds](#defaultCacheSeconds)
---
--- Returns:
---  * The new plist `source` instance.
mod.new = function(pathPattern, cacheSeconds)
    cacheSeconds = cacheSeconds or mod.defaultCacheSeconds
    local o = {
        _pathPattern = pathPattern,
        _context = {},
    }
    o._cleanup = timer.delayed.new(cacheSeconds, function() o:reset() end)
    return setmetatable(o, {__index = mod.mt})
end

return mod