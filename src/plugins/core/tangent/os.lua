--- === plugins.core.tangent.os ===
---
--- macOS Group for the Tangent.

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

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return deps.tangentManager.controls:group(i18n("macOS"))
end

return plugin