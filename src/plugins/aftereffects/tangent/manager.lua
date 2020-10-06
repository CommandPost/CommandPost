--- === plugins.aftereffects.tangent.manager ===
---
--- Manager for After Effects Tangent Support

local require               = require

--local log                   = require "hs.logger".new("tangentManager")

local config                = require "cp.config"

local plugin = {
    id = "aftereffects.tangent.manager",
    group = "aftereffects",
    dependencies = {
        ["core.tangent.manager"] = "manager",
    }
}

function plugin.init(deps, env)
    local manager = deps.manager

    local systemPath = config.userConfigRootPath .. "/Tangent Settings/After Effects"
    local pluginPath = config.basePath .. "/plugins/aftereffects/tangent/defaultmap"

    local connection = manager.newConnection("After Effects (via CommandPost)", "After Effects", systemPath, nil, "After Effects", pluginPath)
    return connection
end

return plugin
