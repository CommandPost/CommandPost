--- === plugins.finalcutpro.tangent.modes ===
---
--- Final Cut Pro Modes for Tangent

local require = require

local i18n = require("cp.i18n")

local plugin = {
    id = "finalcutpro.tangent.modes",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    local tangentManager = deps.tangentManager
    tangentManager.addMode(0x00010004, "FCP: " .. i18n("wheels"))
end

return plugin