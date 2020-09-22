--- === plugins.finalcutpro.tangent.os ===
---
--- macOS Group for the Tangent.

local require = require

local i18n = require("cp.i18n")


local plugin = {
    id = "finalcutpro.tangent.os",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    local tangentManager = deps.tangentManager
    local connection = tangentManager.getConnection("CommandPost")
    return connection.controls:group(i18n("macOS"))
end

return plugin
