--- === plugins.finalcutpro.tangent.open ===
---
--- Final Cut Pro Tangent Open FCPX.

local require = require

local fcp                                       = require("cp.apple.finalcutpro")
local i18n                                      = require("cp.i18n")

local plugin = {
    id = "finalcutpro.tangent.open",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local fcpGroup = deps.fcpGroup
    local id = 0x00050000
    fcpGroup:action(id, i18n("cpLaunchFinalCutPro" .. "_title"), true)
        :onPress(fcp:doLaunch())

    return fcpGroup
end

return plugin
