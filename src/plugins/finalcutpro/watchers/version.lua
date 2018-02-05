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

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                    = require("cp.config")
local fcp                       = require("cp.apple.finalcutpro")
local prop                      = require("cp.prop")
local watcher                   = require("cp.watcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.finalcutpro.watchers.version._watchers -> table
-- Variable
-- Watchers.
mod._watchers = watcher.new("change")

--- plugins.finalcutpro.watchers.version.watch(events) -> watcher
--- Function
--- Watch Events.
---
--- Parameters:
---  * events - Events to watch
---
--- Returns:
---  * The Watcher
function mod.watch(events)
    return mod._watchers:watch(events)
end

--- plugins.finalcutpro.watchers.version.unwatch(id) -> none
--- Function
--- Unwatch a watcher.
---
--- Parameters:
---  * id - The ID of the watcher to unwatch
---
--- Returns:
---  * None
function mod.unwatch(id)
    return mod._watchers:unwatch(id)
end

--- plugins.finalcutpro.watchers.version.lastVersion <cp.prop: string>
--- Variable
--- The last Final Cut Pro version.
mod.lastVersion = config.prop("lastVersion")

--- plugins.finalcutpro.watchers.version.currentVersion <cp.prop: string>
--- Variable
--- The current Final Cut Pro version.
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
function plugin.init()
    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
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