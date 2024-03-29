--- === plugins.resolve.application.manager ===
---
--- Registers Motion with the Core Application Manager.

local require   = require

local resolve    = require "cp.blackmagic.resolve"

local plugin = {
    id              = "resolve.application.manager",
    group           = "resolve",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    if resolve:isSupported() then
        deps.manager.registerApplication({
            bundleID = resolve:bundleID(),
            displayName = "DaVinci Resolve",
            legacyGroupID = "resolve",
        })
    end
end

return plugin