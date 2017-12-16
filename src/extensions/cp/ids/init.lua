--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                              I D S    A P I                                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ids ===
---
--- Allows managing values/IDs which can vary between versions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("ids")

local fs				= require("hs.fs")
local tools				= require("cp.tools")

local v					= require("semver")

local insert, remove	= table.insert, table.remove

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

-- toVersion(value) -> semver
-- Function
-- Converts the string/semver value to a semver
--
-- Parameters:
-- * value	- The value to convert
--
-- Returns:
-- * The value as a `semver`, or `nil` if it's not a valid version value.
local function toVersion(value)
	if value then
		return type(value) == "string" and v(value) or value
	end
	return nil
end

--- cp.ids.new(path[, currentVersionFn]) -> cp.ids
--- Function
--- Creates a new `ids` instance with the specified path to the version files and
--- a function to find the current version, if appropriate.
---
--- Parameters:
--- * `path`				- The path to the version files.
--- * `currentVersionFn`	- An optional function that will return the current version as a string or `semver`.
---
--- Returns:
--- * A new `cp.ids` instance.
function mod.new(path, currentVersionFn)
	local o = {
		cache = {},
		path = path,
		_currentVersion = currentVersionFn,
	}

	return setmetatable(o, mod.mt)
end

--- cp.ids:currentVersion() -> semver
--- Method
--- Returns the current version number for the `IDs` library. May be `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `semver` with the version number or `nil` if none is available.
function mod.mt:currentVersion()
	return toVersion(self._currentVersion and self._currentVersion() or nil)
end

function mod.mt:versions()
	if not mod._versions then
		local versions = {}
		local path = fs.pathToAbsolute(self.path)
		for file in fs.dir(path) do
			if file:sub(-4) == ".lua" then
				local versionString = file:sub(1, -5)
				local version = toVersion(versionString)
				if version then
					insert(versions, version)
				end
			end
		end
		table.sort(versions)
		mod._versions = versions
	end
	return mod._versions
end

--- cp.ids:previousVersion([version]) -> semver
--- Method
--- Returns the previous version number that has stored IDs.
---
--- Parameters:
---  * version		- The version number you want to load as a string (i.e. "10.4.0") or a `semver`, or `nil` to use the current version.
---
--- Returns:
---  * A `semver` instance for the previous version.
function mod.mt:previousVersion(version)
	version = toVersion(version or self:currentVersion())

	-- check if we're working with a specific version
	local versions = self:versions()
	if version == nil then
		return #versions > 0 and versions[#versions] or nil
	end

	local prev = nil

	for i,ver in ipairs(versions) do
		if ver < version then
			prev = ver
		end
		if ver >= version then
			break
		end
	end
	return prev
end

--- cp.ids:load([version]) -> table
--- Method
--- Loads and caches IDs for the given version. It will search through previous versions,
--- with each subsequent version file overriding the previous version's value, if present.
---
--- Parameters:
---  * version - The version number you want to load as a string (i.e. "10.4.0"). If not provided, the current version is loaded.
---
--- Returns:
---  * A table containing all the IDs
function mod.mt:load(version)
	version = toVersion(version or self:currentVersion())

	if not version then
		return {}
	end

	----------------------------------------------------------------------------------------
	-- Restore from cache:
	----------------------------------------------------------------------------------------
	local vStr = tostring(version)

	local vIds = self.cache[vStr]

	if vIds then
		return vIds
	end

	local prevVersion = self:previousVersion(version)
	if prevVersion then
		vIds = self:load(self:previousVersion(version))
	else
		vIds = {}
	end

	----------------------------------------------------------------------------------------
	-- Load current version ID:
	----------------------------------------------------------------------------------------
	local vFile = fs.pathToAbsolute(("%s/%s.lua"):format(self.path, vStr))

	if vFile then
		local currentIds = dofile(vFile)
		vIds = tools.mergeTable({}, vIds, currentIds)
	end

	----------------------------------------------------------------------------------------
	-- Save to cache:
	----------------------------------------------------------------------------------------
	self.cache[vStr] = vIds

	return vIds
end

--- cp.ids:of(version, subset) -> table
--- Method
--- Returns a table of the IDs of the specified version and subset.
---
--- Parameters:
---  * version - The version number you want to load as a string (i.e. "10.4.0")
---  * subset - A string containing the subset of data you want to load
---
--- Returns:
---  * A table containing the subset of IDs for the selected version. Will never be `nil`.
function mod.mt:of(version, subset)
	local data = self:load(version)
	local subsetData = data[subset] or {}
	return function(name)
		return subsetData[name]
	end
end

--- cp.ids:ofCurrent(subset) -> table
--- Method
--- Returns a table of IDs for a current version and specified subset
---
--- Parameters:
---  * subset - A string containing the subset of data you want to load
---
--- Returns:
---  * A table containing the subset of IDs for the current version
function mod.mt:ofCurrent(subset)
	return self:of(self:currentVersion(), subset)
end

--
-- Allows you to call `cp.ids "subset"` directly for ease of use:
--
function mod.mt:__call(...)
	return self:ofCurrent(...)
end

return setmetatable(mod, mod)