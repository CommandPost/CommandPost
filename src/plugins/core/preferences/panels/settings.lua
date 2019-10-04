--- === plugins.core.preferences.panels.settings ===
---
--- Settings Preferences Panel

local require       = require

local hs            = hs

local image         = require "hs.image"

local i18n          = require "cp.i18n"

local execute       = hs.execute
local imageFromName = image.imageFromName

local plugin = {
    id              = "core.preferences.panels.settings",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    local panel = deps.manager.addPanel({
        priority    = 9000,
        id          = "settings",
        label       = i18n("settings"),
        image       = imageFromName("NSAdvanced"),
        tooltip     = i18n("settings"),
        height      = 170,
    })

    panel
        :addContent(1, [[<p style="padding-left:20px;">]] .. i18n("settingsDescription") .. [[</p>]], false)
        :addButton(2,
            {
                label 	    = i18n("openUserSettingsFolder"),
                width       = 200,
                onclick	    = function() execute([[open ~/Library/Application\ Support/CommandPost]]) end,
            }
        )

    return panel
end

return plugin
