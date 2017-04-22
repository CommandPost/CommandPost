--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  F I N A L   C U T   P R O   V E R S I O N                 --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.watchers.version ===
---
--- This plugin will compare the current version of Final Cut Pro to the last one run.
--- If it has changed, watchers' `change` function is called.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local config					= require("cp.config")
local fcp						= require("cp.apple.finalcutpro")
local watcher					= require("cp.watcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod._watchers = watcher:new("change")

function mod.watch(events)
	return mod._watchers:watch(events)
end

function mod.unwatch(id)
	return mod._watchers:unwatch(id)
end

function mod.getLastVersion()
	return config.get("lastVersion")
end

function mod.setLastVersion(version)
	return config.set("lastVersion", version)
end

function mod.getCurrentVersion()
	return fcp:getVersion()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.watchers.version",
	group = "finalcutpro",
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
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