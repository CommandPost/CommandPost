--- === plugins.aftereffects.application.manager ===
---
--- Registers After Effects with the Core Application Manager if installed.

local require               = require

local application           = require "hs.application"

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
    local bundleID = ae:bundleID()
    if infoForBundleID(bundleID) then
        deps.manager.registerApplication({
            bundleID = bundleID,
            displayName = "Adobe After Effects",
            legacyGroupID = "aftereffects",
        })
    end
end

return plugin