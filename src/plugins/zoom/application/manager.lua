--- === plugins.zoom.application.manager ===
---
--- Registers Zoom with the Core Application Manager if installed.

local require               = require

local application           = require "hs.application"

local infoForBundleID       = application.infoForBundleID

local plugin = {
    id              = "zoom.application.manager",
    group           = "zoom",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    local bundleID = "us.zoom.xos"
    if infoForBundleID(bundleID) then
        deps.manager.registerApplication({
            bundleID = bundleID,
            displayName = "Zoom",
            legacyGroupID = "zoom",
        })
    end
end

return plugin