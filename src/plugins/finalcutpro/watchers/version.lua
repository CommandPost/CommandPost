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
local prop						= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod._watchers = watcher.new("change")

function mod.watch(events)
	return mod._watchers:watch(events)
end

function mod.unwatch(id)
	return mod._watchers:unwatch(id)
end

mod.lastVersion = config.prop("lastVersion")

mod.currentVersion = prop(function()
	return fcp:getVersion()
end)

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
	local lastVersion = mod.lastVersion()
	local currentVersion = mod.currentVersion()
	if lastVersion ~= nil and lastVersion ~= currentVersion then
		mod._watchers:notify("change", lastVersion, currentVersion)
	end
	mod.lastVersion(currentVersion)
end

return plugin