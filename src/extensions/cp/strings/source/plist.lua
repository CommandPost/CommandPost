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

--- cp.strings.source.plist:pathToAbsolute(language) -> string
--- Method
--- Finds the abolute path to the `plist` represented by this source for the specified langauge, or `nil` if it does not exist.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---
--- Returns:
---  * The path to the file, or `nil` if not found.
function mod.mt:pathToAbsolute(language)
    local langPath = language and self._pathPattern:gsub("%${language}", language) or self._pathPattern
    return fs.pathToAbsolute(langPath)
end

--- cp.strings.source.plist:loadFile(language) -> string
--- Method
--- Loads the plist file for the specified language, returning the value as a table.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---
--- Returns:
---  * The table for the specified language, or `nil` if the file doesn't exist.
function mod.mt:loadFile(language)
    local langFile = self:pathToAbsolute(language)
    if not langFile and aliases[language] then
        -- try an alias
        langFile = self:pathToAbsolute(aliases[language])
    end

    self._cleanup:start()
    if langFile then
        return plist.fileToTable(langFile)
    end
    return nil
end

--- cp.strings.source.plist:find(language, key) -> string
--- Method
--- Finds the specified `key` value in the plist file for the specified `language`, if the plist can be found, and contains matching key value.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `key`		- The key to retrieve from the file.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:find(language, key)
    self._cache = self._cache or {}
    self._cache[language] = self._cache[language] or self:loadFile(language) or {}

    return unescapeXML(self._cache[language][escapeXML(key)])
end

--- cp.strings.source.plist:findKeys(language, pattern) -> {string}
--- Method
--- Finds the array of keys whos value matches the pattern in the plist file for the specified `language`, if the plist can be found, and contains matching key.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `pattern		- The value pattern.
---
--- Returns:
---  * The array of keys, or `{}` if none were fround
function mod.mt:findKeys(language, pattern)

    self._cache = self._cache or {}
    self._cache[language] = self._cache[language] or self:loadFile(language) or {}

    local keys = {}
    local cache = self._cache[language]
    for k,v in pairs(cache) do
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

--- cp.strings.source.plist.new(language) -> source
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
    }
    o._cleanup = timer.delayed.new(cacheSeconds, function() o:reset() end)
    return setmetatable(o, {__index = mod.mt})
end

return mod