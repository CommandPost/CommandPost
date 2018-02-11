--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--      M O B I L E   N O T I F I C A T I O N S   M E N U   S E C T I O N     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.helpandsupport.finalcutpro ===
---
--- The Help & Support > CommandPost menu section.

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 20

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.menu.helpandsupport.finalcutpro",
    group           = "finalcutpro",
    dependencies    = {
        ["core.menu.helpandsupport"] = "helpandsupport"
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)
    return dependencies.helpandsupport:addMenu(PRIORITY, function() return i18n("finalCutPro") end)
end

return plugin
