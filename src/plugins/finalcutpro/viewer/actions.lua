--- === plugins.finalcutpro.viewer.actions ===
---
--- Viewer Actions

local require           = require

local pasteboard        = require "hs.pasteboard"

local tools             = require "cp.tools"
local Do                = require "cp.rx.go.Do"
local fcp               = require "cp.apple.finalcutpro"
local Viewer            = require "cp.apple.finalcutpro.viewer.Viewer"
local i18n              = require "cp.i18n"

local playErrorSound    = tools.playErrorSound

local plugin = {
    id = "finalcutpro.viewer.actions",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local viewer = fcp.viewer
    local infoBar = viewer:infoBar()

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
            fcp.viewer:background(Viewer.BACKGROUND.BLACK)
        end)
        :groupedBy("viewer")
        :titled(i18n("setPlayerBackgroundTo") .. " " .. i18n("black"))

    --------------------------------------------------------------------------------
    -- Set Player Background to White:
    --------------------------------------------------------------------------------
    cmds
        :add("setPlayerBackgroundToWhite")
        :whenActivated(function()
            fcp.viewer:background(Viewer.BACKGROUND.WHITE)
        end)
        :groupedBy("viewer")
        :titled(i18n("setPlayerBackgroundTo") .. " " .. i18n("white"))

    --------------------------------------------------------------------------------
    -- Set Player Background to Checkerboard:
    --------------------------------------------------------------------------------
    cmds
        :add("setPlayerBackgroundToCheckerboard")
        :whenActivated(function()
            fcp.viewer:background(Viewer.BACKGROUND.CHECKERBOARD)
        end)
        :groupedBy("viewer")
        :titled(i18n("setPlayerBackgroundTo") .. " " .. i18n("checkerboard"))

    --------------------------------------------------------------------------------
    -- Toggle Player Background:
    --------------------------------------------------------------------------------
    cmds
        :add("togglePlayerBackground")
        :whenActivated(function()
            local current = fcp.viewer:background()
            local new = (current + 1) % 3
            fcp.viewer:background(new)
        end)
        :groupedBy("viewer")
        :titled(i18n("togglePlayerBackground"))

    --------------------------------------------------------------------------------
    -- Set Viewer to Proxy:
    --------------------------------------------------------------------------------
    cmds
        :add("setViewerToProxy")
        :whenActivated(function()
            fcp.viewer:playbackMode(Viewer.PLAYBACK_MODE.PROXY_ONLY)
        end)
        :groupedBy("viewer")
        :titled(i18n("setViewerTo") .. " " .. i18n("proxy"))

    --------------------------------------------------------------------------------
    -- Set Viewer to Proxy Preferred:
    --------------------------------------------------------------------------------
    cmds
        :add("setViewerToProxyPreferred")
        :whenActivated(function()
            fcp.viewer:playbackMode(Viewer.PLAYBACK_MODE.PROXY_PREFERRED)
        end)
        :groupedBy("viewer")
        :titled(i18n("setViewerTo") .. " " .. i18n("proxyPreferred"))

    --------------------------------------------------------------------------------
    -- Set Viewer to Optimized/Original:
    --------------------------------------------------------------------------------
    cmds
        :add("setViewerToOptimizedOriginal")
        :whenActivated(function()
            fcp.viewer:playbackMode(Viewer.PLAYBACK_MODE.ORIGINAL_BETTER_QUALITY)
        end)
        :groupedBy("viewer")
        :titled(i18n("setViewerTo") .. " " .. i18n("optimizedOriginal"))

    --------------------------------------------------------------------------------
    -- Set Viewer to Fit:
    --------------------------------------------------------------------------------
    cmds
        :add("setViewerZoomFactorToFit")
        :whenActivated(
            Do(infoBar.zoomMenu:doShow())
                :Then(infoBar.zoomMenu:doSelectValue(fcp:string("PEViewerZoomFit")))
                :Label("plugins.finalcutpro.viewer.actions.setViewerZoomFactorToFit")
        )
        :groupedBy("viewer")
        :titled(i18n("setViewerTo") .. " " .. i18n("fit"))

    --------------------------------------------------------------------------------
    -- Set Viewer to %:
    --------------------------------------------------------------------------------
    local zoomFactors = {"12.5%", "25%", "50%", "100%", "150%", "200%", "400%", "600%"}
    for _, zoomFactor in pairs(zoomFactors) do
        cmds
            :add("setViewerZoomFactorTo" .. zoomFactor)
            :whenActivated(
                Do(infoBar.zoomMenu:doShow())
                    :Then(infoBar.zoomMenu:doSelectValue(zoomFactor))
                    :Label("plugins.finalcutpro.viewer.actions.setViewerZoomFactorTo"..zoomFactor)
            )
            :groupedBy("viewer")
            :titled(i18n("setViewerTo") .. " " .. zoomFactor)
    end

    --------------------------------------------------------------------------------
    -- Copy Viewer Contents to Pasteboard:
    --------------------------------------------------------------------------------
    cmds
        :add("copyViewerContentsToPasteboard")
        :whenActivated(function()
            local videoImage = fcp.viewer:videoImage()
            if videoImage then
                local img = videoImage:snapshot()
                if img then
                    if pasteboard.writeObjects(img) then
                        return
                    end
                end
            end
            playErrorSound()
        end)
        :groupedBy("viewer")
        :titled(i18n("copyViewerContentsToPasteboard"))
end

return plugin