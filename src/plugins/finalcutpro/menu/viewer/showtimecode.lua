--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  H I G H L I G H T     P L A Y H E A D                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.viewer.showtimecode ===
---
--- Highlight Playhead Menu.

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 30000

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.menu.viewer.showtimecode",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.menu.viewer"] = "viewer"
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)
    return dependencies.viewer:addMenu(PRIORITY, function() return i18n("showTimecode") end)
end

return plugin
