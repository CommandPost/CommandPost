--- === plugins.finalcutpro.tangent.timeline ===
---
--- Final Cut Pro Tangent Timeline Group/Management

local require = require

local fcp                                       = require("cp.apple.finalcutpro")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.open",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    local fcpGroup = deps.fcpGroup
    local id = 0x00050000
    fcpGroup:action(id, i18n("cpLaunchFinalCutPro" .. "_title"))
        :onPress(fcp:doLaunch())

    return fcpGroup
end

return plugin
