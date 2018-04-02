local fcp               = require("cp.apple.finalcutpro")

local plugin = {
    id = "finalcutpro.tangent.group",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    local tangentManager = deps.tangentManager
    local fcpGroup = tangentManager.controls:group(i18n("finalCutPro"))

    fcp.isFrontmost:watch(function(value)
        fcpGroup:enabled(value)
    end)

    return fcpGroup
end

return plugin