--- === plugins.core.tangent.os ===
---
--- macOS Group for the Tangent.

local require = require

local i18n = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "core.tangent.os",
    group = "core",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    return deps.tangentManager.controls:group(i18n("macOS"))
end

return plugin
