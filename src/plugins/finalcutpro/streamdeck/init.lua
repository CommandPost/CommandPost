--- === plugins.finalcutpro.streamdeck ===
---
--- Stream Deck Plugin for Final Cut Pro.

local require = require

local fcp = require("cp.apple.finalcutpro")

local plugin = {
    id = "finalcutpro.streamdeck",
    group = "finalcutpro",
    dependencies = {
        ["core.streamdeck.manager"]     = "manager",
    }
}

function plugin.init(deps)
    fcp.app.frontmost:watch(function(frontmost) deps.manager.groupStatus("fcpx", frontmost) end)
end

return plugin