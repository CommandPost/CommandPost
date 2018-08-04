--- === plugins.finalcutpro.tangent.playback ===
---
--- Final Cut Pro Tangent Playback Group/Management

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                       = require("hs.logger").new("fcptng_timeline")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                                    = require("cp.dialog")
local fcp                                       = require("cp.apple.finalcutpro")
local i18n                                      = require("cp.i18n")

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
        :onPress(fcp:doSelectMenu({"View", "Playback", "Play"}))

    mod.group:action(baseID+2, i18n("playSelection"))
        :onPress(fcp:doSelectMenu({"View", "Playback", "Play Selection"}))

    mod.group:action(baseID+3, i18n("playAround"))
        :onPress(fcp:doSelectMenu({"View", "Playback", "Play Around"}))

    mod.group:action(baseID+4, i18n("playFromBeginning"))
        :onPress(fcp:doSelectMenu({"View", "Playback", "Play from Beginning"}))

    mod.group:action(baseID+5, i18n("playToEnd"))
        :onPress(fcp:doSelectMenu({"View", "Playback", "Play to End"}))

    mod.group:action(baseID+6, i18n("playFullScreen"))
        :onPress(fcp:doSelectMenu({"View", "Playback", "Play Full Screen"}))

    mod.group:action(baseID+7, i18n("loopPlayback"))
        :onPress(fcp:doSelectMenu({"View", "Playback", "Loop Playback"}))

    mod.group:action(baseID+8, i18n("goToBeginning"))
        :onPress(fcp:doSelectMenu({"Mark", "Go to", "Beginning"}))

    mod.group:action(baseID+9, i18n("goToEnd"))
        :onPress(fcp:doSelectMenu({"Mark", "Go to", "End"}))

    mod.group:action(baseID+10, i18n("goToRangeStart"))
        :onPress(fcp:doSelectMenu({"Mark", "Go to", "Range Start"}))

    mod.group:action(baseID+11, i18n("goToRangeEnd"))
        :onPress(fcp:doSelectMenu({"Mark", "Go to", "Range End"}))

    mod.group:action(baseID+12, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("frame"))
        :onPress(fcp:doSelectMenu({"Mark", "Next", "Frame"}))

    mod.group:action(baseID+13, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("frame"))
        :onPress(fcp:doSelectMenu({"Mark", "Previous", "Frame"}))

    mod.group:action(baseID+14, i18n("play") .. " " .. i18n("reverse"))
        :onPress(function()
            if not fcp:performShortcut("PlayReverse") then
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end
        end)

    mod.group:action(baseID+15, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("edit"))
        :onPress(fcp:doSelectMenu({"Mark", "Next", "Edit"}))

    mod.group:action(baseID+16, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("edit"))
        :onPress(fcp:doSelectMenu({"Mark", "Previous", "Edit"}))

    mod.group:action(baseID+17, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("marker"))
        :onPress(fcp:doSelectMenu({"Mark", "Next", "Marker"}))

    mod.group:action(baseID+18, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("marker"))
        :onPress(fcp:doSelectMenu({"Mark", "Previous", "Marker"}))

    mod.group:action(baseID+19, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("keyframe"))
        :onPress(fcp:doSelectMenu({"Mark", "Next", "Keyframe"}))

    mod.group:action(baseID+20, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("keyframe"))
        :onPress(fcp:doSelectMenu({"Mark", "Previous", "Keyframe"}))
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
