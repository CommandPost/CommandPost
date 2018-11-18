--- === plugins.core.menu.preferences ===
---
--- Adds a 'Preferences...' menu item to the menu.
---
--- This has to be a separate plugin to avoid a circular dependency between the menu manager and preferences manager.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

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
    id              = "core.menu.preferences",
    group           = "core",
    required        = true,
    dependencies    = {
        ["core.menu.manager"]           = "menu",
        ["core.preferences.manager"]    = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    deps.menu.bottom
        :addHeading(i18n("settings"))
        :addItem(10.1, function()
            return { title = i18n("preferences") .. "...", fn = deps.prefs.show }
        end)

        --------------------------------------------------------------------------------
        -- Add separator:
        --------------------------------------------------------------------------------
        :addItem(11, function()
            return { title = "-" }
        end)

end

return plugin
