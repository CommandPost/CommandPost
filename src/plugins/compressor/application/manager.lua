--- === plugins.compressor.application.manager ===
---
--- Registers Compressor with the Core Application Manager.

local require   = require

local compressor    = require "cp.apple.compressor"

local plugin = {
    id              = "compressor.application.manager",
    group           = "compressor",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    deps.manager.registerApplication({
        bundleID = compressor:bundleID(),
        displayName = "Compressor",
    })
end

return plugin