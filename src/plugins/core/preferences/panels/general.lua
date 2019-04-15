--- === plugins.core.preferences.panels.general ===
---
--- General Preferences Panel

local require = require

local image     = require("hs.image")

local i18n      = require("cp.i18n")


local plugin = {
    id              = "core.preferences.panels.general",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    return deps.manager.addPanel({
        priority    = 2000,
        id          = "general",
        label       = i18n("generalPanelLabel"),
        image       = image.imageFromName("NSPreferencesGeneral"),
        tooltip     = i18n("generalPanelTooltip"),
        height      = 300,
    })
end

return plugin
