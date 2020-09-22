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
    return deps.tangentManager.controls:group(i18n("macOS"))
end

return plugin
