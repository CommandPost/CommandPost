--- === plugins.aftereffects.application.manager ===
---
--- Registers After Effects with the Core Application Manager if installed.

local require               = require

local application           = require "hs.application"

local config                = require "cp.config"
local ae                    = require "cp.adobe.aftereffects"

local infoForBundleID       = application.infoForBundleID

local plugin = {
    id              = "aftereffects.application.manager",
    group           = "aftereffects",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    local iconPath = config.basePath .. "/plugins/core/console/images/"
    local searchConsoleToolbar = {
        aftereffects_effects    = { path = iconPath .. "fx.png",        priority = 1},
        aftereffects_shortcuts  = { path = iconPath .. "shortcut.png",  priority = 2},
    }

    local bundleID = ae:bundleID()
    if infoForBundleID(bundleID) then
        deps.manager.registerApplication({
            bundleID = bundleID,
            displayName = "Adobe After Effects",
            legacyGroupID = "aftereffects",
            searchConsoleToolbar = searchConsoleToolbar,
        })
    end
end

return plugin