--- === plugins.core.tangent.commandpost ===
---
--- CommandPost Group for the Tangent.

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "core.tangent.commandpost",
    group = "core",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return deps.tangentManager.controls:group(i18n("appName"))
end

return plugin