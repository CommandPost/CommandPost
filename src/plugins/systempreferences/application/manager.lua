--- === plugins.systempreferences.application.manager ===
---
--- Registers System Preferences with the Core Application Manager.

local require               = require

local plugin = {
    id              = "systempreferences.application.manager",
    group           = "systempreferences",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    deps.manager.registerApplication({
        bundleID = "com.apple.systempreferences",
        displayName = "System Preferences",
    })
end

return plugin