--- === plugins.resolve.tangent.manager ===
---
--- Manager for DaVinci Resolve's Tangent Support

local require               = require

--local log                   = require "hs.logger".new("tangentManager")

local config                = require "cp.config"
local resolve               = require "cp.blackmagic.resolve"

local plugin = {
    id = "resolve.tangent.manager",
    group = "resolve",
    dependencies = {
        ["core.tangent.manager"] = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if DaVinci Resolve is supported:
    --------------------------------------------------------------------------------
    if not resolve:isSupported() then return end

    local manager = deps.manager

    local systemPath = config.userConfigRootPath .. "/Tangent/DaVinci Resolve"
    local pluginPath = config.basePath .. "/plugins/resolve/tangent/defaultmap"
    local userPath = systemPath .. "/" .. manager.USER_CONTROL_MAPS_FOLDER

    local connection = manager.newConnection("DaVinci Resolve", systemPath, userPath, "Resolve", pluginPath, false)
    return connection
end

return plugin
