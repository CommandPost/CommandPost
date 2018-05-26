--- === plugins.core.menu.top ===
---
--- The top menu section.

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 1

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "core.menu.top",
    group			= "core",
    dependencies	= {
        ["core.menu.manager"]	= "manager",
    },
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)
    local top = dependencies.manager.addSection(PRIORITY)
    return top
end

return plugin