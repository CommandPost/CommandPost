--- === plugins.finalcutpro.tangent.view ===
---
--- Final Cut Pro Tangent View Group

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                       = require("hs.logger").new("fcptng_timeline")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                                    = require("cp.dialog")
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.tangent.view.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro View actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.view.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup)

    local baseID = 0x00080000

    mod.group = fcpGroup:group(i18n("view"))

    mod.group:action(baseID+1, i18n("zoomToFit"))
        :onPress(fcp:doSelectMenu({"View", "Zoom to Fit"}))

    mod.group:action(baseID+2, i18n("zoomToSamples"))
        :onPress(fcp:doSelectMenu({"View", "Zoom to Samples"}))

    mod.group:action(baseID+3, i18n("timelineHistory") .. " " .. i18n("back"))
        :onPress(fcp:doSelectMenu({"View", "Timeline History Back"}))

    mod.group:action(baseID+4, i18n("timelineHistory") .. " " .. i18n("forward"))
        :onPress(fcp:doSelectMenu({"View", "Timeline History Forward"}))

    mod.group:action(baseID+5, i18n("show") .. " " .. i18n("histogram"))
        :onPress(function()
            if not fcp:performShortcut("ToggleHistogram") then
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end
        end)

    mod.group:action(baseID+6, i18n("show") .. " " .. i18n("vectorscope"))
        :onPress(function()
            if not fcp:performShortcut("ToggleVectorscope") then
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end
        end)

    mod.group:action(baseID+7, i18n("show") .. " " .. i18n("videoWaveform"))
        :onPress(function()
            if not fcp:performShortcut("ToggleWaveform") then
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end
        end)

    mod.group:action(baseID+8, i18n("toggleVideoScopesInViewer"))
        :onPress(fcp:doSelectMenu({"View", "Show in Viewer", "Video Scopes"}))

    mod.group:action(baseID+9, i18n("toggleVideoScopesInEventViewer"))
        :onPress(fcp:doSelectMenu({"View", "Show in Event Viewer", "Video Scopes"}))
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.view",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.fcpGroup)

    return mod
end

return plugin