--- === plugins.finalcutpro.tangent.timeline ===
---
--- Final Cut Pro Tangent Timeline Group/Management

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.group",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    local tangentManager = deps.tangentManager
    local fcpGroup = tangentManager.controls:group(i18n("finalCutPro"))

    fcp.isFrontmost:watch(function(value)
        fcpGroup:enabled(value)
    end)

    return fcpGroup
end

return plugin
