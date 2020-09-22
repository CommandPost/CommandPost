--- === plugins.core.tangent.commandpost ===
---
--- CommandPost Group for the Tangent.

local require = require

local i18n = require("cp.i18n")


local plugin = {
    id = "core.tangent.commandpost",
    group = "core",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    local tangentManager = deps.tangentManager
    local connection = tangentManager.getConnection("CommandPost")
    return connection.controls:group(i18n("appName"))
end

return plugin
