--- === plugins.core.preferences.panels.notifications ===
---
--- Notifications Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local image                                     = require("hs.image")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.panels.notifications",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return deps.manager.addPanel({
        priority    = 2025,
        id          = "notifications",
        label       = i18n("notificationsPanelLabel"),
        image       = image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/Notifications.prefPane/Contents/Resources/Notifications.icns")),
        tooltip     = i18n("notificationsPanelTooltip"),
        height      = 620,
    })
end

return plugin
