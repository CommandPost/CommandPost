--- === plugins.core.preferences.panels.notifications ===
---
--- Notifications Preferences Panel

local require           = require

local image             = require "hs.image"

local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"
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
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --
    -- NOTE: Because this is a Core Plugin, it shouldn't require FCPX, however
    --       currently the Notifications preferences panel is only used for
    --       Final Cut Pro, so there's no point showing an empty panel if FCPX
    --       is not installed.
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    return deps.manager.addPanel({
        priority    = 2025,
        id          = "notifications",
        label       = i18n("notificationsPanelLabel"),
        image       = imageFromPath(config.bundledPluginsPath .. "/core/preferences/panels/images/Notifications.icns"),
        tooltip     = i18n("notificationsPanelTooltip"),
        height      = 810,
    })
end

return plugin