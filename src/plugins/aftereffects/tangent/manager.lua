--- === plugins.aftereffects.tangent.manager ===
---
--- Manager for After Effects Tangent Support

local require               = require

--local log                   = require "hs.logger".new("tangentManager")

local config                = require "cp.config"
local i18n                  = require "cp.i18n"

local plugin = {
    id = "aftereffects.tangent.manager",
    group = "aftereffects",
    dependencies = {
        ["core.tangent.manager"] = "manager",
    }
}

function plugin.init(deps, env)
    local manager = deps.manager

    local systemPath = config.userConfigRootPath .. "/Tangent/After Effects"
    local pluginPath = config.basePath .. "/plugins/aftereffects/tangent/defaultmap"
    local userPath = systemPath .. "/" .. manager.USER_CONTROL_MAPS_FOLDER

    local connection = manager.newConnection("After Effects", systemPath, userPath, "After Effects", pluginPath, false)

    connection:addMode(0x00010001, i18n("default"))

    return connection
end

return plugin
