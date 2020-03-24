--- === plugins.motion.application.manager ===
---
--- Registers Motion with the Core Application Manager.

local require   = require

local motion    = require "cp.apple.motion"

local plugin = {
    id              = "motion.application.manager",
    group           = "motion",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    deps.manager.registerApplication({
        bundleID = motion:bundleID(),
        displayName = "Motion",
    })
end

return plugin