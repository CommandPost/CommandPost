--- === plugins.finalcutpro.tangent.clip ===
---
--- Final Cut Pro Tangent View Group

local require       = require

local log           = require "hs.logger".new "fcptng_timeline"

local dialog        = require "cp.dialog"
local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local plugin = {
    id = "finalcutpro.tangent.clip",
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

    local fcpGroup = deps.fcpGroup

    local baseID = 0x00100000

    local group = fcpGroup:group(i18n("clip"))

    group:action(baseID+1, i18n("breakApartClipItems"))
        :onPress(fcp:doSelectMenu({"Clip", "Break Apart Clip Items"}))

    group:action(baseID+2, i18n("detachAudio"))
        :onPress(fcp:doSelectMenu({"Clip", "Detach Audio"}))

    group:action(baseID+3, i18n("expandAudio") .. " " .. i18n("components"))
        :onPress(fcp:doSelectMenu({"Clip", "Expand Audio Components"}))

    group:action(baseID+4, i18n("expandAudio"))
        :onPress(fcp:doSelectMenu({"Clip", "Expand Audio"}))

    group:action(baseID+5, i18n("selectLeftAudioEdge"))
        :onPress(fcp:doShortcut("SelectLeftEdgeAudio")
            :Catch(function(message)
                log.wf("clip.selectLeftAudioEdge: %s", message)
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end)
        )

    group:action(baseID+6, i18n("selectRightAudioEdge"))
        :onPress(
            fcp:doShortcut("SelectRightEdgeAudio")
            :Catch(function(message)
                log.wf("clip.selectRightAudioEdge: %s", message)
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end)
        )

    group:action(baseID+7, i18n("selectLeftEdge"))
        :onPress(
            fcp:doShortcut("SelectLeftEdge")
            :Catch(function(message)
                log.wf("clip.selectLeftEdge: %s", message)
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end)
        )

    group:action(baseID+8, i18n("selectRightEdge"))
        :onPress(
            fcp:doShortcut("SelectRightEdge")
            :Catch(function(message)
                log.wf("clip.selectRightEdge: %s", message)
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end)
        )

    group:action(baseID+9, i18n("createStoryline"))
        :onPress(fcp:doSelectMenu({"Clip", "Create Storyline"}))

end

return plugin
