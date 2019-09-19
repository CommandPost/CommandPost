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
        :groupedBy("viewer")
        :titled(i18n("showHorizon") .. " (" .. i18n("viewer") .. ")")

    --------------------------------------------------------------------------------
    -- Show Horizon (Event Viewer):
    --------------------------------------------------------------------------------
    cmds
        :add("showHorizonEventViewer")
        :whenActivated(function()
            fcp.eventViewer.infoBar.viewMenu:doSelectValue(fcp:string("CPShowHorizon")):Now()
        end)
        :groupedBy("viewer")
        :titled(i18n("showHorizon") .. " (" .. i18n("eventViewer") .. ")")

    --------------------------------------------------------------------------------
    -- Set Player Background to Black:
    --------------------------------------------------------------------------------
    cmds
        :add("setPlayerBackgroundToBlack")
        :whenActivated(function()
            fcp.preferences:set("FFPlayerBackground", 0)
        end)
        :groupedBy("viewer")
        :titled(i18n("setPlayerBackgroundTo") .. " " .. i18n("black"))

    --------------------------------------------------------------------------------
    -- Set Player Background to White:
    --------------------------------------------------------------------------------
    cmds
        :add("setPlayerBackgroundToWhite")
        :whenActivated(function()
            fcp.preferences:set("FFPlayerBackground", 1)
        end)
        :groupedBy("viewer")
        :titled(i18n("setPlayerBackgroundTo") .. " " .. i18n("white"))

    --------------------------------------------------------------------------------
    -- Set Player Background to Checkerboard:
    --------------------------------------------------------------------------------
    cmds
        :add("setPlayerBackgroundToCheckerboard")
        :whenActivated(function()
            fcp.preferences:set("FFPlayerBackground", 2)
        end)
        :groupedBy("viewer")
        :titled(i18n("setPlayerBackgroundTo") .. " " .. i18n("checkerboard"))

    --------------------------------------------------------------------------------
    -- Toggle Player Background:
    --------------------------------------------------------------------------------
    cmds
        :add("togglePlayerBackground")
        :whenActivated(function()
            local current = fcp.preferences:get("FFPlayerBackground")
            local new = 0
            if current == 0 then
                new = 1
            elseif current == 1 then
                new = 2
            elseif current == 2 then
                new = 0
            end
            fcp.preferences:set("FFPlayerBackground", new)
        end)
        :groupedBy("viewer")
        :titled(i18n("togglePlayerBackground"))

    --------------------------------------------------------------------------------
    -- Set Viewer to Proxy:
    --------------------------------------------------------------------------------
    cmds
        :add("setViewerToProxy")
        :whenActivated(function()
            fcp.preferences:set("FFPlayerQuality", 4)
        end)
        :groupedBy("viewer")
        :titled(i18n("setViewerTo") .. " " .. i18n("proxy"))

    --------------------------------------------------------------------------------
    -- Set Viewer to Optimized/Original:
    --------------------------------------------------------------------------------
    cmds
        :add("setViewerToOptimizedOriginal")
        :whenActivated(function()
            fcp.preferences:set("FFPlayerQuality", 10)
        end)
        :groupedBy("viewer")
        :titled(i18n("setViewerTo") .. " " .. i18n("optimizedOriginal"))
end

return plugin