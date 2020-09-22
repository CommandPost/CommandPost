--- === plugins.finalcutpro.tangent.features ===
---
--- Final Cut Pro CommandPost Actions for Tangent

local require   = require

--local log       = require "hs.logger".new "tangentVideo"

local fcp       = require "cp.apple.finalcutpro"
local i18n      = require "cp.i18n"

local plugin = {
    id = "finalcutpro.tangent.features",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.common"]  = "common",
        ["finalcutpro.tangent.group"]   = "fcpGroup",

        --------------------------------------------------------------------------------
        -- NOTE: These plugins aren't actually referred here in this plugin, but we
        --       need to include them here so that they load before this plugin loads.
        --------------------------------------------------------------------------------
        ["finalcutpro.console"] = "console",
        ["finalcutpro.text2speech"] = "text2speech",
        ["finalcutpro.timeline.movetoplayhead"] = "movetoplayhead",
        ["finalcutpro.timeline.captions"] = "captions",
        ["finalcutpro.timeline.zoomtoselection"] = "zoomtoselection",
        ["finalcutpro.timeline.playhead"] = "playhead",
        ["finalcutpro.browser.addnote"] = "addnote",
        ["finalcutpro.advanced.disablewaveforms"] = "disablewaveforms",
        ["finalcutpro.hud.manager"] = "hud",
        ["finalcutpro.hud.panels.search"] = "search",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    local id                            = 0x0F810000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local commandParameter              = common.commandParameter

    --------------------------------------------------------------------------------
    -- CommandPost Actions:
    --------------------------------------------------------------------------------
    local commandPostGroup = fcpGroup:group(i18n("appName"))

    id = commandParameter(commandPostGroup, id, "fcpx", "cpConsole")
    id = commandParameter(commandPostGroup, id, "fcpx", "cpText2Speech")
    id = commandParameter(commandPostGroup, id, "fcpx", "cpMoveToPlayhead")
    id = commandParameter(commandPostGroup, id, "fcpx", "cpPasteTextAsCaption")
    id = commandParameter(commandPostGroup, id, "fcpx", "cpZoomToSelection")
    id = commandParameter(commandPostGroup, id, "fcpx", "cpScrollingTimeline")
    id = commandParameter(commandPostGroup, id, "fcpx", "cpAddNoteToSelectedClips")
    id = commandParameter(commandPostGroup, id, "fcpx", "cpDisableWaveforms")
    id = commandParameter(commandPostGroup, id, "fcpx", "cpHUD")
    commandParameter(commandPostGroup, id, "fcpx", "cpHUDSearch")

end

return plugin
