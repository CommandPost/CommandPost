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
        :whenActivated(function() fcp:inspector():audio():doShow():Now() end)
        :titled(i18n("goTo") .. " " .. i18n("audio") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToInfoInspector")
        :whenActivated(function() fcp:inspector():info():doShow():Now() end)
        :titled(i18n("goTo") .. " " .. i18n("info") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToTitleInspector")
        :whenActivated(function() fcp:inspector():title():doShow():Now() end)
        :titled(i18n("goTo") .. " " .. i18n("title") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToTextInspector")
        :whenActivated(function() fcp:inspector():text():doShow():Now() end)
        :titled(i18n("goTo") .. " " .. i18n("text") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToVideoInspector")
        :whenActivated(function() fcp:inspector():video():doShow():Now() end)
        :titled(i18n("goTo") .. " " .. i18n("video") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToGeneratorInspector")
        :whenActivated(function() fcp:inspector():generator():doShow():Now() end)
        :titled(i18n("goTo") .. " " .. i18n("generator") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToShareInspector")
        :whenActivated(function() fcp:inspector():share():doShow():Now() end)
        :titled(i18n("goTo") .. " " .. i18n("share") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToTransitionInspector")
        :whenActivated(function() fcp:inspector():transition():doShow():Now() end)
        :titled(i18n("goTo") .. " " .. i18n("transition") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("modifyProject")
        :whenActivated(function()
            Do(fcp:inspector():projectInfo():doShow())
                :Then(fcp:inspector():projectInfo():modify():doPress())
                :Label("plugins.finalcutpro.inspector.show.modifyProject")
                :Now()
        end)
        :titled(i18n("modifyProject"))
end

return plugin