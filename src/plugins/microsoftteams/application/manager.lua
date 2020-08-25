--- === plugins.microsoftteams.application.manager ===
---
--- Registers Microsoft Teams with the Core Application Manager if installed.

local require               = require

local application           = require "hs.application"

local infoForBundleID       = application.infoForBundleID

local plugin = {
    id              = "microsoftteams.application.manager",
    group           = "microsoftteams",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    local bundleID = "com.microsoft.teams"
    if infoForBundleID(bundleID) then
        deps.manager.registerApplication({
            bundleID = bundleID,
            displayName = "Microsoft Teams",
        })
    end
end

return plugin