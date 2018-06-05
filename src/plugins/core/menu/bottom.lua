--- === plugins.core.menu.bottom ===
---
--- The bottom menu section.

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 9999999

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.menu.bottom",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"]   = "manager",
    },
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)
    local bottom = dependencies.manager.addSection(PRIORITY)

    --------------------------------------------------------------------------------
    -- Add separator:
    --------------------------------------------------------------------------------
    bottom:addItem(0, function()
        return { title = "-" }
    end)

    return bottom
end

return plugin