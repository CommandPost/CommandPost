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

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Only load plugin if DaVinci Resolve is supported:
    --------------------------------------------------------------------------------
    if not resolve:isSupported() then return end

    local manager = deps.manager

    local systemPath = config.userConfigRootPath .. "/Tangent Settings/DaVinci Resolve"
    local pluginPath = config.basePath .. "/plugins/resolve/tangent/defaultmap"

    local connection = manager.newConnection("DaVinci Resolve (via CommandPost)", systemPath, nil, "Resolve", pluginPath)
    return connection
end

return plugin
