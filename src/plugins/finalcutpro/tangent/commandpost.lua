--- === plugins.core.tangent.commandpost ===
---
--- CommandPost Group for the Tangent.

local require = require

local i18n = require "cp.i18n"

local plugin = {
    id = "finalcutpro.tangent.commandpost",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    local connection = deps.tangentManager
    return connection.controls:group(i18n("appName"))
end

return plugin
