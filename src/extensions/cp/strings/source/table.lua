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
local log				= require("hs.logger").new("tblsrc")

local _					= require("moses")
local find, len			= string.find, string.len
local insert			= table.insert

local mod = {}
mod.mt = {}

--- cp.strings.source.table:find(language) -> string
--- Method
--- Finds the specified `key` value in the plist file for the specified `language`, if the plist can be found, and contains matching key value.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `key`		- The key to retrieve from the file.
---
--- Returns:
---  * The value of the key, or `nil` if not found.
function mod.mt:add(language, keyValues)
	self._cache[language] = _.extend(self._cache[language] or {}, keyValues)
	return self
end

--- cp.strings.source.table:find(language) -> string
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
	return self._cache[language] and self._cache[language][key]
end

--- cp.strings.source.plist:findKeys(language, pattern) -> {string}
--- Method
--- Finds the array of keys who's value matches the pattern in this table. It will check that the pattern matches the beginning of the value.
---
--- Parameters:
---  * `language`	- The language code to look for (e.g. `"en"`, or `"fr"`).
---  * `pattern		- The string pattern to match.
---
--- Returns:
---  * The array of keys, or `{}` if none were fround
function mod.mt:findKeys(language, pattern)

	local cache = self._cache[language]
	local keys = {}

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

--- cp.strings.source.table.new(language) -> source
--- Constructor
--- Creates a new `cp.strings` source that loads strings from a plist file.
---
--- Parameters:
---  * `pathPattern`	- The path to load from. May contain a special `${language}` marker which will be replace with the provided langauge when searching.
---  * `cacheSeconds`	- (optional) How long in seconds to keep the loaded values cached in memory. Defaults to [defaultCacheSeconds](#defaultCacheSeconds)
---
--- Returns:
---  * The new plist `source` instance.
mod.new = function()
	local o = {
		_cache = {},
	}
	return setmetatable(o, {__index = mod.mt})
end

return mod