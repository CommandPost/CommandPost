--- === plugins.finalcutpro.tangent.overlay ===
---
--- Final Cut Pro Tangent Viewer Overlay Group

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                       = require("hs.logger").new("tangentOverlay")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n        = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.tangent.overlay.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro New actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.overlay.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup, overlays)

    local baseID = 0x00120000

    mod.group = fcpGroup:group(i18n("viewerOverlay"))

    mod.group:action(baseID+1, i18n("cpViewerBasicGrid_title"))
        :onPress(function()
            overlays.basicGridEnabled:toggle()
            overlays.update()
        end)

    mod.group:action(baseID+2, i18n("cpViewerDraggableGuide_title"))
        :onPress(function()
            overlays.draggableGuideEnabled:toggle()
            overlays.update()
        end)

    mod.group:action(baseID+3, i18n("cpToggleAllViewerOverlays_title"))
        :onPress(function()
            overlays.disabled:toggle()
            overlays.update()
        end)

    local nextID = baseID+4
    for i=1, overlays.NUMBER_OF_MEMORIES do
        mod.group:action(nextID, i18n("viewStillsMemory") .. " " .. i)
        :onPress(function()
            overlays.viewMemory(i)
        end)
        nextID = nextID + 1
        mod.group:action(nextID, i18n("saveCurrentFrameToStillsMemory") .. " " .. i)
        :onPress(function()
            overlays.saveMemory(i)
        end)
        nextID = nextID + 1
    end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.overlay",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
        ["finalcutpro.viewer.overlays"] = "overlays",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    if deps and deps.fcpGroup and deps.overlays then
        mod.init(deps.fcpGroup, deps.overlays)
    end

    return mod
end

return plugin
