--- About:
-- This plugin will compare the current version of Final Cut Pro to the last one run.
-- If it has changed, watchers' `change` function is called.

-- Imports
local metadata					= require("cp.metadata")
local fcp						= require("cp.finalcutpro")
local watcher					= require("cp.watcher")

-- The Module
local mod = {}

mod._watchers = watcher:new("change")

function mod.watch(events)
	return mod._watchers:watch(events)
end

function mod.unwatch(id)
	return mod._watchers:unwatch(id)
end

function mod.getLastVersion()
	return metadata.get("lastVersion")
end

function mod.setLastVersion(version)
	return metadata.set("lastVersion", version)
end

function mod.getCurrentVersion()
	return fcp:getVersion()
end

-- The Plugin
local plugin = {}

function plugin.init(deps)
	return mod
end

function plugin.postInit(deps)
	--------------------------------------------------------------------------------
	-- Check for Final Cut Pro Updates:
	--------------------------------------------------------------------------------
	local lastVersion = mod.getLastVersion()
	local currentVersion = mod.getCurrentVersion()
	if lastVersion ~= nil and lastVersion ~= currentVersion then
		mod._watchers:notify("change", lastVersion, currentVersion)
	end
	mod.setLastVersion(currentVersion)	
end

return plugin