--- === plugins.diskutility.application.manager ===
---
--- Registers Disk Utility with the Core Application Manager.

local plugin = {
    id              = "diskutility.application.manager",
    group           = "diskutility",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    deps.manager.registerApplication({
        bundleID = "com.apple.DiskUtility",
        displayName = "Disk Utility",
    })
end

return plugin