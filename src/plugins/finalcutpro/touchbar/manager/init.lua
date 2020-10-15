--- === plugins.finalcutpro.touchbar.manager ===
---
--- Final Cut Pro Touch Bar Manager.

local require = require

local config                                    = require("cp.config")
local fcp                                       = require("cp.apple.finalcutpro")


local mod = {}

-- updateStatus(enabled) -> none
-- Function
-- Updates the Final Cut Pro Group Status.
--
-- Parameters:
--  * enabled - `true` or `false`
--
-- Returns:
--  * None
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


local plugin = {
    id = "finalcutpro.touchbar.manager",
    group = "finalcutpro",
    dependencies = {
        ["core.touchbar.manager"]       = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Connect to Manager:
    --------------------------------------------------------------------------------
    mod._manager = deps.manager

    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Update visibility:
    --------------------------------------------------------------------------------
    if mod.enabled then
        mod.enabled:update()
    end
end

return plugin
