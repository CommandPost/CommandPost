--- === plugins.zoom.application.manager ===
---
--- Registers Cisco Webex Meetings with the Core Application Manager if installed.

local require               = require

local application           = require "hs.application"

local infoForBundleID       = application.infoForBundleID

local plugin = {
    id              = "ciscowebexmeetings.application.manager",
    group           = "ciscowebexmeetings",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    local bundleID = "com.cisco.webexmeetingsapp"
    if infoForBundleID(bundleID) then
        deps.manager.registerApplication({
            bundleID = bundleID,
            displayName = "Cisco Webex Meetings",
        })
    end
end

return plugin