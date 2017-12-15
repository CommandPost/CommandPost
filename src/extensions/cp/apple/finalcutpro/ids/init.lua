--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.ids ===
---
--- Final Cut Pro IDs.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("ids")

local application		= require("hs.application")
local fs				= require("hs.fs")

local config			= require("cp.config")
local tools				= require("cp.tools")

local v					= require("semver")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- cp.apple.finalcutpro.ids.cache
--- Variable
--- Cache of current Final Cut Pro IDs.
mod.cache = {}

-- currentVersion() -> string
-- Function
-- Returns the current version number of Final Cut Pro
--
-- Parameters:
--  * None
--
-- Returns:
--  * A string with Final Cut Pro's version number or `nil` if Final Cut Pro could not be detected
local function currentVersion()

	--------------------------------------------------------------------------------
	-- TODO: This should really be calling cp.apple.finalcutpro:getVersion()
	--       instead, but not sure how best to do this...
	--------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------
	-- Get running copy of Final Cut Pro:
	----------------------------------------------------------------------------------------
	local app = application.applicationsForBundleID("com.apple.FinalCut")

	----------------------------------------------------------------------------------------
	-- Final Cut Pro is currently running:
	----------------------------------------------------------------------------------------
	if app and next(app) ~= nil then
		app = app[1]
		local appPath = app:path()
		if appPath then
			local info = application.infoForBundlePath(appPath)
			if info then
				return info["CFBundleShortVersionString"]
			else
				log.df("VERSION CHECK: Could not determine Final Cut Pro's version.")
			end
		else
			log.df("VERSION CHECK: Could not determine Final Cut Pro's path.")
		end
	end

	----------------------------------------------------------------------------------------
	-- No version of Final Cut Pro currently running:
	----------------------------------------------------------------------------------------
	local app = application.infoForBundleID("com.apple.FinalCut")
	if app then
		return app["CFBundleShortVersionString"]
	else
		log.df("VERSION CHECK: Could not determine Final Cut Pro's info from Bundle ID.")
	end

	----------------------------------------------------------------------------------------
	-- Final Cut Pro could not be detected:
	----------------------------------------------------------------------------------------
	return nil

end

--- cp.apple.finalcutpro.ids.load(version) -> table
--- Function
--- Loads and caches Final Cut Pro IDs for the given version.
---
--- Parameters:
---  * version - The version number you want to load as a string (i.e. "10.4.0")
---
--- Returns:
---  * A table containing all the IDs
function mod.load(version)
	if not version then
		return {}
	end

	----------------------------------------------------------------------------------------
	-- Make sure we're working with a semver version:
	----------------------------------------------------------------------------------------
	version = type(version) == "string" and v(version) or version

	----------------------------------------------------------------------------------------
	-- Restore from cache:
	----------------------------------------------------------------------------------------
	local vStr = tostring(version)
	if mod.cache[vStr] then
		return mod.cache[vStr]
	end

	----------------------------------------------------------------------------------------
	-- Load any previous version IDs:
	----------------------------------------------------------------------------------------
	local vIds = {}
	local cachedVersionIDs = {}
	local files = tools.dirFiles(fs.pathToAbsolute(config.scriptPath .. "/cp/apple/finalcutpro/ids/v/"))
	table.sort(files, function(a,b) return a < b end)
	for _, file in ipairs(files) do
		if file:sub(-4) == ".lua" then
			local selectedVersion = file:sub(1, -5)
			if v(selectedVersion) < version then
				local path = fs.pathToAbsolute(("%s/cp/apple/finalcutpro/ids/v/%s.lua"):format(config.scriptPath, selectedVersion))
				local newIds = dofile(path)
				vIds = tools.mergeTable({}, vIds, newIds)
				table.insert(cachedVersionIDs, selectedVersion)
			end
		end
	end

	----------------------------------------------------------------------------------------
	-- Load current version ID:
	----------------------------------------------------------------------------------------
	local vFile = fs.pathToAbsolute(("%s/cp/apple/finalcutpro/ids/v/%s.lua"):format(config.scriptPath, version))
	if vFile then
		local currentIds = dofile(vFile)
		vIds = tools.mergeTable({}, vIds, currentIds)
		table.insert(cachedVersionIDs, tostring(version))
	end

	----------------------------------------------------------------------------------------
	-- Save to cache:
	----------------------------------------------------------------------------------------
	mod.cache[vStr] = vIds

	----------------------------------------------------------------------------------------
	-- Display Debug Message:
	----------------------------------------------------------------------------------------
	local result = ""
	for i, item in ipairs(cachedVersionIDs) do
		result = result .. item
		if not (i == #cachedVersionIDs) then
			result = result .. ", "
		end
	end
	log.df("Loaded Version IDs: %s", result)

	return vIds
end

--- cp.apple.finalcutpro.ids.version(version, subset) -> table
--- Function
--- Returns a table of IDs for a given Final Cut Pro version and subset
---
--- Parameters:
---  * version - The version number you want to load as a string (i.e. "10.4.0")
---  * subset - A string containing the subset of data you want to load
---
--- Returns:
---  * A table containing the subset of IDs for the selected version
function mod.version(version, subset)
	local data = mod.load(version)
	local subsetData = data[subset] or {}
	return function(name)
		return subsetData[name]
	end
end

--- cp.apple.finalcutpro.ids.current(subset) -> table
--- Function
--- Returns a table of IDs for a current version and specified subset
---
--- Parameters:
---  * subset - A string containing the subset of data you want to load
---
--- Returns:
---  * A table containing the subset of IDs for the current version
function mod.current(subset)
	return mod.version(currentVersion(), subset)
end

--
-- Allows you to call `cp.apple.finalcutpro.ids "subset"` directly for ease of use:
--
function mod.__call(_,...)
	return mod.current(...)
end

return setmetatable(mod, mod)