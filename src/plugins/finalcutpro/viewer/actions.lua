--- === plugins.finalcutpro.viewer.actions ===
---
--- Viewer Actions

local require   = require

local fcp       = require "cp.apple.finalcutpro"
local i18n      = require "cp.i18n"

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.viewer.actions",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("showHorizon")
        :whenActivated(function()
            --------------------------------------------------------------------------------
            -- NOTE: 'Show Horizon' is only found in:
            -- /Applications/Final Cut Pro.app/Contents/Resources/en.lproj/PEPlayerContainerModule.nib
            --------------------------------------------------------------------------------
            fcp.viewer.infoBar.viewMenu:doSelectValue(fcp:string("CPShowHorizon")):Now()
        end)
        :titled(i18n("showHorizon"))

    return mod
end

return plugin
