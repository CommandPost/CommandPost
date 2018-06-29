--- === plugins.core.watchfolders.menuitem ===
---
--- Adds the "Setup Watch Folders" to the menu bar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n        = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "core.watchfolders.menuitem",
    group			= "core",
    dependencies	= {
        ["core.menu.bottom"]			= "bottom",
        ["core.watchfolders.manager"]	= "watchfolders",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    deps.bottom:addItem(10.2, function()
        return { title = i18n("setupWatchFolders"), fn = deps.watchfolders.show }
    end)
end

return plugin
