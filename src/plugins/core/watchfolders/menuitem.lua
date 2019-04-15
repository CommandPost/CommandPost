--- === plugins.core.watchfolders.menuitem ===
---
--- Adds the "Setup Watch Folders" to the menu bar.

local require = require

local i18n = require("cp.i18n")


local plugin = {
    id				= "core.watchfolders.menuitem",
    group			= "core",
    dependencies	= {
        ["core.menu.manager"] = "menu",
        ["core.watchfolders.manager"]	= "watchfolders",
    }
}

function plugin.init(deps)
    deps.menu.bottom
        :addItem(10.2, function()
            return { title = i18n("setupWatchFolders"), fn = deps.watchfolders.show }
        end)
end

return plugin
