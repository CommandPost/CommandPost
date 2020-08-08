--- === plugins.skype.application.manager ===
---
--- Registers Skype with the Core Application Manager if installed.

local require               = require

local application           = require "hs.application"

local infoForBundleID       = application.infoForBundleID

local plugin = {
    id              = "skype.application.manager",
    group           = "skype",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    local bundleID = "com.skype.skype"
    if infoForBundleID(bundleID) then
        deps.manager.registerApplication({
            bundleID = bundleID,
            displayName = "Skype",
        })
    end
end

return plugin