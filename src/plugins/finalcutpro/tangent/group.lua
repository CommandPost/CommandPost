--- === plugins.finalcutpro.tangent.timeline ===
---
--- Final Cut Pro Tangent Timeline Group/Management

local require       = require

local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local plugin = {
    id = "finalcutpro.tangent.group",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    local connection = deps.tangentManager
    local fcpGroup = connection.controls:group(i18n("finalCutPro"))

    fcp.isFrontmost:watch(function(value)
        fcpGroup:enabled(value)
    end)

    return fcpGroup
end

return plugin
