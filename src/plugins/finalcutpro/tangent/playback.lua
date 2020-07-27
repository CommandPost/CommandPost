--- === plugins.finalcutpro.tangent.playback ===
---
--- Final Cut Pro Tangent Playback Group/Management

local require = require

local log                   = require "hs.logger".new "playback"

local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"

local displayMessage        = dialog.displayMessage

-- doShortcut(id) -> none
-- Function
--
-- Parameters:
--  * id - The
--
-- Returns:
--  * None
local function doShortcut(id)
    return fcp:doShortcut(id):Catch(function(message)
        log.wf("Unable to perform %q shortcut: %s", id, message)
        displayMessage(i18n("tangentFinalCutProShortcutFailed"))
    end)
end

local plugin = {
    id = "finalcutpro.tangent.playback",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local baseID = 0x00060000
    local group = deps.fcpGroup:group(i18n("playback"))

    group:action(baseID+1, i18n("play") .. "/" .. i18n("pause"))
        :onPress(function()
            fcp:doSelectMenu({"View", "Playback", "Play"}):Now()
        end)

    group:action(baseID+2, i18n("playSelection"))
        :onPress(function()
            fcp:doSelectMenu({"View", "Playback", "Play Selection"}):Now()
        end)

    group:action(baseID+3, i18n("playAround"))
        :onPress(function()
            fcp:doSelectMenu({"View", "Playback", "Play Around"}):Now()
        end)

    group:action(baseID+4, i18n("playFromBeginning"))
        :onPress(function()
            fcp:doSelectMenu({"View", "Playback", "Play from Beginning"}):Now()
        end)

    group:action(baseID+5, i18n("playToEnd"))
        :onPress(function()
            fcp:doSelectMenu({"View", "Playback", "Play to End"})
        end)

    group:action(baseID+6, i18n("playFullScreen"))
        :onPress(function()
            fcp:doSelectMenu({"View", "Playback", "Play Full Screen"})
        end)

    group:action(baseID+7, i18n("loopPlayback"))
        :onPress(function()
            fcp:doSelectMenu({"View", "Playback", "Loop Playback"}):Now()
        end)

    group:action(baseID+8, i18n("goToBeginning"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Go to", "Beginning"}):Now()
        end)

    group:action(baseID+9, i18n("goToEnd"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Go to", "End"}):Now()
        end)

    group:action(baseID+10, i18n("goToRangeStart"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Go to", "Range Start"}):Now()
        end)

    group:action(baseID+11, i18n("goToRangeEnd"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Go to", "Range End"}):Now()
        end)

    group:action(baseID+12, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("frame"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Next", "Frame"}):Now()
        end)

    group:action(baseID+13, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("frame"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Previous", "Frame"}):Now()
        end)

    group:action(baseID+14, i18n("play") .. " " .. i18n("reverse"))
        :onPress(function()
            doShortcut("PlayReverse"):Now()
        end)

    group:action(baseID+15, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("edit"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Next", "Edit"}):Now()
        end)

    group:action(baseID+16, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("edit"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Previous", "Edit"}):Now()
        end)

    group:action(baseID+17, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("marker"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Next", "Marker"}):Now()
        end)

    group:action(baseID+18, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("marker"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Previous", "Marker"}):Now()
        end)

    group:action(baseID+19, i18n("goTo") .. " " .. i18n("next") .. " " .. i18n("keyframe"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Next", "Keyframe"}):Now()
        end)

    group:action(baseID+20, i18n("goTo") .. " " .. i18n("previous") .. " " .. i18n("keyframe"))
        :onPress(function()
            fcp:doSelectMenu({"Mark", "Previous", "Keyframe"}):Now()
        end)
end

return plugin
