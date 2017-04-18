local config			= require("cp.config")
local application		= require("hs.application")
local v					= require("semver")
local fs				= require("hs.fs")

local mod = {}

mod.cache = {}

local function currentVersion()
	if not mod._currentVersion then
		local app = application.infoForBundleID("com.apple.FinalCut")
		mod._currentVersion = app and app["CFBundleShortVersionString"] or nil
	end
	return mod._currentVersion
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
	
	local vFile = fs.pathToAbsolute(("%s/cp/finalcutpro/ids/v/%s.lua"):format(config.scriptPath, version))
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
