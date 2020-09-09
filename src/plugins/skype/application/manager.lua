--- === plugins.skype.application.manager ===
---
--- Registers Skype with the Core Application Manager if installed.

local require               = require

local application           = require "hs.application"

local config                = require "cp.config"

local infoForBundleID       = application.infoForBundleID

local plugin = {
    id              = "skype.application.manager",
    group           = "skype",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)

    local iconPath = config.basePath .. "/plugins/core/console/images/"

    local searchConsoleToolbar = {
        skype_shortcuts = { path = iconPath .. "shortcut.png", priority = 1},
    }

    local bundleID = "com.skype.skype"
    if infoForBundleID(bundleID) then
        deps.manager.registerApplication({
            bundleID = bundleID,
            displayName = "Skype",
            legacyGroupID = "skype",
            searchConsoleToolbar = searchConsoleToolbar,
        })
    end
end

return plugin