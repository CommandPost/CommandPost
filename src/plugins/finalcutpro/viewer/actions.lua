--- === plugins.finalcutpro.viewer.actions ===
---
--- Viewer Actions

local require   = require

local fcp       = require "cp.apple.finalcutpro"
local i18n      = require "cp.i18n"


local plugin = {
    id = "finalcutpro.viewer.actions",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Show Horizon (Viewer):
    --------------------------------------------------------------------------------
    local cmds = deps.fcpxCmds
    cmds
        :add("showHorizon")
        :whenActivated(function()
            --------------------------------------------------------------------------------
            -- NOTE: 'Show Horizon' is only found in:
            -- /Applications/Final Cut Pro.app/Contents/Resources/en.lproj/PEPlayerContainerModule.nib
            --------------------------------------------------------------------------------
            fcp.viewer.infoBar.viewMenu:doSelectValue(fcp:string("CPShowHorizon")):Now()
        end)
        :titled(i18n("showHorizon") .. " (" .. i18n("viewer") .. ")")

    --------------------------------------------------------------------------------
    -- Show Horizon (Event Viewer):
    --------------------------------------------------------------------------------
    cmds
        :add("showHorizonEventViewer")
        :whenActivated(function()
            fcp.eventViewer.infoBar.viewMenu:doSelectValue(fcp:string("CPShowHorizon")):Now()
        end)
        :titled(i18n("showHorizon") .. " (" .. i18n("eventViewer") .. ")")

end

return plugin
