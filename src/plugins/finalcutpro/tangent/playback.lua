--- === plugins.finalcutpro.tangent.playback ===
---
--- Final Cut Pro Tangent Playback Group/Management

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

--- plugins.finalcutpro.tangent.playback.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro Playback actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.playback.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup)

    local baseID = 0x00060000

    mod.group = fcpGroup:group(i18n("playback"))

    mod.group:action(baseID+1, i18n("play") .. "/" .. i18n("pause"))
        :onPress(function()
            fcp:selectMenu({"View", "Playback", "Play"})
        end)

    mod.group:action(baseID+2, i18n("playSelection"))
        :onPress(function()
            fcp:selectMenu({"View", "Playback", "Play Selection"})
        end)

    mod.group:action(baseID+3, i18n("playAround"))
        :onPress(function()
            fcp:selectMenu({"View", "Playback", "Play Around"})
        end)

    mod.group:action(baseID+4, i18n("playFromBeginning"))
        :onPress(function()
            fcp:selectMenu({"View", "Playback", "Play from Beginning"})
        end)

    mod.group:action(baseID+5, i18n("playToEnd"))
        :onPress(function()
            fcp:selectMenu({"View", "Playback", "Play to End"})
        end)

    mod.group:action(baseID+6, i18n("playFullScreen"))
        :onPress(function()
            fcp:selectMenu({"View", "Playback", "Play Full Screen"})
        end)

    mod.group:action(baseID+7, i18n("loopPlayback"))
        :onPress(function()
            fcp:selectMenu({"View", "Playback", "Loop Playback"})
        end)

    mod.group:action(baseID+8, i18n("goToBeginning"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Go to", "Beginning"})
        end)

    mod.group:action(baseID+9, i18n("goToEnd"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Go to", "End"})
        end)

    mod.group:action(baseID+10, i18n("goToRangeStart"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Go to", "Range Start"})
        end)

    mod.group:action(baseID+11, i18n("goToRangeEnd"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Go to", "Range End"})
        end)

    mod.group:action(baseID+12, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("frame"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Next", "Frame"})
        end)

    mod.group:action(baseID+13, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("frame"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Previous", "Frame"})
        end)

    mod.group:action(baseID+14, i18n("play") .. " " .. i18n("reverse"))
        :onPress(function()
            if not fcp:performShortcut("PlayReverse") then
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end
        end)

    mod.group:action(baseID+15, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("edit"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Next", "Edit"})
        end)

    mod.group:action(baseID+16, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("edit"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Previous", "Edit"})
        end)

    mod.group:action(baseID+17, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("marker"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Next", "Marker"})
        end)

    mod.group:action(baseID+18, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("marker"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Previous", "Marker"})
        end)

    mod.group:action(baseID+19, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("keyframe"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Next", "Keyframe"})
        end)

    mod.group:action(baseID+20, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("keyframe"))
        :onPress(function()
            fcp:selectMenu({"Mark", "Previous", "Keyframe"})
        end)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.playback",
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