--- === plugins.finalcutpro.inspector.show ===
---
--- Final Cut Pro Inspector Additions.

local require       = require

--local log           = require "hs.logger".new "inspShow"

local fcp           = require "cp.apple.finalcutpro"
local go            = require "cp.rx.go"
local i18n          = require "cp.i18n"

local Do            = go.Do

local plugin = {
    id              = "finalcutpro.inspector.show",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    deps.fcpxCmds
        :add("goToAudioInspector")
        :whenActivated(fcp:inspector():audio():doShow())
        :titled(i18n("goTo") .. " " .. i18n("audio") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToInfoInspector")
        :whenActivated(fcp:inspector():info():doShow())
        :titled(i18n("goTo") .. " " .. i18n("info") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToTitleInspector")
        :whenActivated(fcp:inspector():title():doShow())
        :titled(i18n("goTo") .. " " .. i18n("title") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToTextInspector")
        :whenActivated(fcp:inspector():text():doShow())
        :titled(i18n("goTo") .. " " .. i18n("text") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToVideoInspector")
        :whenActivated(fcp:inspector():video():doShow())
        :titled(i18n("goTo") .. " " .. i18n("video") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToGeneratorInspector")
        :whenActivated(fcp:inspector():generator():doShow())
        :titled(i18n("goTo") .. " " .. i18n("generator") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToShareInspector")
        :whenActivated(fcp:inspector():share():doShow())
        :titled(i18n("goTo") .. " " .. i18n("share") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToTransitionInspector")
        :whenActivated(fcp:inspector():transition():doShow())
        :titled(i18n("goTo") .. " " .. i18n("transition") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("modifyProject")
        :whenActivated(Do(fcp:inspector():projectInfo():doShow())
            :Then(fcp:inspector():projectInfo():modify():doPress())
            :Label("plugins.finalcutpro.inspector.show.modifyProject")
        )
        :titled(i18n("modifyProject"))
end

return plugin