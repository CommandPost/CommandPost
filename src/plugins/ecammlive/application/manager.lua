--- === plugins.ecammlive.application.manager ===
---
--- Registers Ecamm Live with the Core Application Manager.

local plugin = {
    id              = "ecammlive.application.manager",
    group           = "ecammlive",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    deps.manager.registerApplication({
        bundleID = "com.ecamm.EcammLive",
        displayName = "Ecamm Live",
    })
end

return plugin