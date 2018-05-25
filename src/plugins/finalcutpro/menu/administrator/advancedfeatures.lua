--- === plugins.finalcutpro.menu.administrator.advancedfeatures ===
---
--- Advanced Features Menu.

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY
-- Constant
-- The menubar position priority.
local PRIORITY = 10000

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.menu.administrator.advancedfeatures",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.menu.administrator"] = "administrator",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)
    return dependencies.administrator:addMenu(PRIORITY, function() return i18n("advancedFeatures") end)
end

return plugin