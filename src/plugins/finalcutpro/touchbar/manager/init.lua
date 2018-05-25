--- === plugins.finalcutpro.touchbar.manager ===
---
--- Final Cut Pro Touch Bar Manager.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local function updateStatus(enabled)
    mod._manager.groupStatus("fcpx", enabled)
end

--- plugins.finalcutpro.touchbar.manager.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.enabled = config.prop("enableTouchBar", false):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Update Touch Bar Buttons when FCPX is active:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:watch(updateStatus)
        fcp.app.showing:watch(updateStatus)
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:unwatch(updateStatus)
        fcp.app.showing:unwatch(updateStatus)
    end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.touchbar.manager",
    group = "finalcutpro",
    dependencies = {
        ["core.touchbar.manager"]       = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Connect to Manager:
    --------------------------------------------------------------------------------
    mod._manager = deps.manager

    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Update visibility:
    --------------------------------------------------------------------------------
    mod.enabled:update()
end

return plugin
