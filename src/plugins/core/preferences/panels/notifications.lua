--- === plugins.core.preferences.panels.notifications ===
---
--- Notifications Preferences Panel

local require           = require

local image             = require "hs.image"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local imageFromPath     = image.imageFromPath

local plugin = {
    id              = "core.preferences.panels.notifications",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    return deps.manager.addPanel({
        priority    = 2025,
        id          = "notifications",
        label       = i18n("notificationsPanelLabel"),
        image       = imageFromPath(config.bundledPluginsPath .. "/core/preferences/panels/images/Notifications.icns"),
        tooltip     = i18n("notificationsPanelTooltip"),
        height      = 620,
    })
end

return plugin