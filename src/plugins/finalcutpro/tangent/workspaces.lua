--- === plugins.finalcutpro.tangent.workspaces ===
---
--- Final Cut Pro Workspace Actions for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentVideo")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")
local tools                 = require "cp.tools"

local playErrorSound        = tools.playErrorSound


local plugin = {
    id = "finalcutpro.tangent.workspaces",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.common"]  = "common",
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    local id                            = 0x0F830000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local menuParameter                 = common.menuParameter
    local functionParameter             = common.functionParameter

    --------------------------------------------------------------------------------
    -- Workspaces:
    --------------------------------------------------------------------------------
    local workspacesGroup = fcpGroup:group(i18n("workspaces"))

    id = menuParameter(workspacesGroup, id, "default", {"Window", "Workspaces", "Default"})
    id = menuParameter(workspacesGroup, id, "organize", {"Window", "Workspaces", "Organize"})
    id = menuParameter(workspacesGroup, id, "colorAndEffects", {"Window", "Workspaces", "Color & Effects"})
    id = menuParameter(workspacesGroup, id, "dualDisplays", {"Window", "Workspaces", "Dual Displays"})

    for i=1, 5 do
        id = functionParameter(workspacesGroup, id, i18n("customWorkspace") .. " " .. tostring(i), function()
            local customWorkspaces = fcp:customWorkspaces()
            if #customWorkspaces >= i then
                fcp:doSelectMenu({"Window", "Workspaces", i}):Now()
            else
                playErrorSound()
            end
        end)
    end

end

return plugin
