--- === plugins.finalcutpro.tangent.clip ===
---
--- Final Cut Pro Tangent View Group

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("fcptng_timeline")

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

--- plugins.finalcutpro.tangent.clip.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro View actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.clip.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup)

    local baseID = 0x00100000

    mod.group = fcpGroup:group(i18n("clip"))

    mod.group:action(baseID+1, i18n("breakApartClipItems"))
        :onPress(fcp:doSelectMenu({"Clip", "Break Apart Clip Items"}))

    mod.group:action(baseID+2, i18n("detachAudio"))
        :onPress(fcp:doSelectMenu({"Clip", "Detach Audio"}))

    mod.group:action(baseID+3, i18n("expandAudio") .. " " .. i18n("components"))
        :onPress(fcp:doSelectMenu({"Clip", "Expand Audio Components"}))

    mod.group:action(baseID+4, i18n("expandAudio"))
        :onPress(fcp:doSelectMenu({"Clip", "Expand Audio"}))

    mod.group:action(baseID+5, i18n("selectLeftAudioEdge"))
        :onPress(fcp:doShortcut("SelectLeftEdgeAudio")
            :Catch(function(message)
                log.wf("clip.selectLeftAudioEdge: %s", message)
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end)
        )

    mod.group:action(baseID+6, i18n("selectRightAudioEdge"))
        :onPress(
            fcp:doShortcut("SelectRightEdgeAudio")
            :Catch(function(message)
                log.wf("clip.selectRightAudioEdge: %s", message)
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end)
        )

    mod.group:action(baseID+7, i18n("selectLeftEdge"))
        :onPress(
            fcp:doShortcut("SelectLeftEdge")
            :Catch(function(message)
                log.wf("clip.selectLeftEdge: %s", message)
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end)
        )

    mod.group:action(baseID+8, i18n("selectRightEdge"))
        :onPress(
            fcp:doShortcut("SelectRightEdge")
            :Catch(function(message)
                log.wf("clip.selectRightEdge: %s", message)
                dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
            end)
        )

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.clip",
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
