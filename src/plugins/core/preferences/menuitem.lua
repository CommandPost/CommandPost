--- === plugins.core.preferences.menuitem ===
---
--- Adds a 'Preferences...' menu item to the menu.
---
--- This has to be a separate plugin to avoid a circular dependency between the menu manager and preferences manager.

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.menuitem",
    group           = "core",
    required        = true,
    dependencies    = {
        ["core.menu.bottom"]            = "bottom",
        ["core.preferences.manager"]    = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    deps.bottom

        :addItem(10, function()
            return { title = string.upper(i18n("settings")) .. ":", disabled = true }
        end)

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
