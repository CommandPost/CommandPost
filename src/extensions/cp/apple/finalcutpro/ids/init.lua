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

local v					= require("semver")

local config			= require("cp.config")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.cache = {}

--------------------------------------------------------------------------------
-- TODO: This should really be calling cp.apple.finalcutpro:getVersion()
--       instead, but not sure how best to do this...
--------------------------------------------------------------------------------
local function currentVersion()

	----------------------------------------------------------------------------------------
	-- GET RUNNING COPY OF FINAL CUT PRO:
	----------------------------------------------------------------------------------------
	local app = application.applicationsForBundleID("com.apple.FinalCut")

	----------------------------------------------------------------------------------------
	-- FINAL CUT PRO IS CURRENTLY RUNNING:
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
	-- NO VERSION OF FINAL CUT PRO CURRENTLY RUNNING:
	----------------------------------------------------------------------------------------
	local app = application.infoForBundleID("com.apple.FinalCut")
	if app then
		return app["CFBundleShortVersionString"]
	else
		log.df("VERSION CHECK: Could not determine Final Cut Pro's info from Bundle ID.")
	end

	----------------------------------------------------------------------------------------
	-- FINAL CUT PRO COULD NOT BE DETECTED:
	----------------------------------------------------------------------------------------
	return nil
end

local function deepextend(target, ...)
	for _,source in ipairs(table.pack(...)) do
		for key,value in pairs(source) do
			local tValue = target[key]
			if type(value) == "table" then
				if type(tValue) ~= "table" then
					tValue = {}
				end
				-- deep extend subtables
				target[key] = deepextend(tValue, value)
			else
				target[key] = value
			end
		end
	end
	return target
end

function mod.load(version)
	if not version then
		return {}
	end

	-- Make sure we're working with a semver version
	version = type(version) == "string" and v(version) or version

	local vStr = tostring(version)
	if mod.cache[vStr] then
		return mod.cache[vStr]
	end

	local vIds = {}

	local vFile = fs.pathToAbsolute(("%s/cp/apple/finalcutpro/ids/v/%s.lua"):format(config.scriptPath, version))
	if vFile then
		vIds = dofile(vFile)
	end

	-- load any previous version details.
	if version.patch > 0 then
		local pIds = mod.load(v(version.major, version.minor, version.patch-1))
		vIds = deepextend({}, pIds, vIds)
	end

	mod.cache[vStr] = vIds
	return vIds
end

function mod.version(version, subset)
	local data = mod.load(version)
	local subsetData = data[subset] or {}
	return function(name)
		return subsetData[name]
	end
end

function mod.current(subset)
	return mod.version(currentVersion(), subset)
end

function mod.__call(_,...)
	return mod.current(...)
end

return setmetatable(mod, mod)
