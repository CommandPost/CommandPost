--- === plugins.finalcutpro.open ===
---
--- Opens Final Cut Pro via Global Shortcut & Menubar.

local require = require

local fcp           = require("cp.apple.finalcutpro")
local i18n          = require("cp.i18n")


local mod = {}

--- plugins.finalcutpro.open.app() -> none
--- Function
--- Opens Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.app()
    fcp:launch()
end

--- plugins.finalcutpro.open.commandEditor() -> none
--- Function
--- Opens the Final Cut Pro Command Editor
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.commandEditor()
    fcp:launch()
    fcp:commandEditor():show()
end


local plugin = {
    id = "finalcutpro.open",
    group = "finalcutpro",
    dependencies = {
        ["core.commands.global"] = "global",
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Global Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("cpLaunchFinalCutPro")
        :activatedBy():ctrl():alt():cmd("l")
        :whenPressed(mod.app)
        :groupedBy("finalCutPro")

    --------------------------------------------------------------------------------
    -- Final Cut Pro Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("cpOpenCommandEditor")
        :titled(i18n("openCommandEditor"))
        :whenActivated(mod.commandEditor)

    return mod
end

return plugin
