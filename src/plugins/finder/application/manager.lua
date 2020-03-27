--- === plugins.finder.application.manager ===
---
--- Registers Finder with the Core Application Manager.

local plugin = {
    id              = "finder.application.manager",
    group           = "finder",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    deps.manager.registerApplication({
        bundleID = "com.apple.finder",
        displayName = "Finder",
    })
end

return plugin