--- === plugins.finalcutpro.tangent.viewer ===
---
--- Final Cut Pro Viewer Actions for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentVideo")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

local plugin = {
    id = "finalcutpro.tangent.viewer",
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
    local id                            = 0x0F820000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local dynamicPopupSliderParameter   = common.dynamicPopupSliderParameter
    local menuParameter                 = common.menuParameter
    local popupParameter                = common.popupParameter

    --------------------------------------------------------------------------------
    -- Viewer:
    --------------------------------------------------------------------------------
    local viewerGroup = fcpGroup:group(i18n("viewer"))

    local viewer = fcp:viewer()
    local infoBar = viewer:infoBar()

        --------------------------------------------------------------------------------
        -- Viewer Zoom (Buttons):
        --------------------------------------------------------------------------------
        local zoomGroup = viewerGroup:group(i18n("zoom"))
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, fcp:string("PEViewerZoomFit"), "fit")
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, "12.5%", "12.5%")
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, "25%", "25%")
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, "50%", "50%")
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, "100%", "100%")
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, "150%", "150%")
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, "200%", "200%")
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, "400%", "400%")
        id = popupParameter(zoomGroup, infoBar.zoomMenu, id, "600%", "600%")

        --------------------------------------------------------------------------------
        -- Viewer Zoom (Knob):
        --------------------------------------------------------------------------------
        id = dynamicPopupSliderParameter(viewerGroup, infoBar.zoomMenu, id, "zoom", fcp:string("PEViewerZoomFit"))

    --------------------------------------------------------------------------------
    -- Event Viewer:
    --------------------------------------------------------------------------------
    local eventViewerGroup = fcpGroup:group(i18n("eventViewer"))

    local eventViewer = fcp:eventViewer()
    local eventViewerInfoBar = eventViewer:infoBar()

        --------------------------------------------------------------------------------
        -- Show:
        --------------------------------------------------------------------------------
        id = menuParameter(eventViewerGroup, id, "show", {"Window", "Show in Workspace", "Event Viewer"})

        --------------------------------------------------------------------------------
        -- Event Viewer Zoom (Buttons):
        --------------------------------------------------------------------------------
        local viewerZoomGroup = eventViewerGroup:group(i18n("zoom"))
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, fcp:string("PEViewerZoomFit"), "fit")
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, "12.5%", "12.5%")
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, "25%", "25%")
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, "50%", "50%")
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, "100%", "100%")
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, "150%", "150%")
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, "200%", "200%")
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, "400%", "400%")
        id = popupParameter(viewerZoomGroup, eventViewerInfoBar.zoomMenu, id, "600%", "600%")

        --------------------------------------------------------------------------------
        -- Event Viewer Zoom (Knob):
        --------------------------------------------------------------------------------
        id = dynamicPopupSliderParameter(eventViewerGroup, eventViewerInfoBar.zoomMenu, id, "zoom", fcp:string("PEViewerZoomFit"))

    --------------------------------------------------------------------------------
    -- Show Horizon:
    --------------------------------------------------------------------------------
    local viewerViewGroup = viewerGroup:group(i18n("view"))
    local eventViewerViewGroup = eventViewerGroup:group(i18n("view"))

    id = popupParameter(viewerViewGroup, infoBar.viewMenu, id, fcp:string("CPShowHorizon"), "showHorizon")
    popupParameter(eventViewerViewGroup, eventViewerInfoBar.viewMenu, id, fcp:string("CPShowHorizon"), "showHorizon")

end

return plugin
