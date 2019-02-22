--- === plugins.finalcutpro.inspector.show ===
---
--- Final Cut Pro Inspector Additions.

local require = require

local fcp         = require("cp.apple.finalcutpro")
local i18n        = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.inspector.show",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("goToAudioInspector")
        :whenActivated(function() fcp:inspector():audio():show() end)
        :titled(i18n("goTo") .. " " .. i18n("audio") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToInfoInspector")
        :whenActivated(function() fcp:inspector():info():show() end)
        :titled(i18n("goTo") .. " " .. i18n("info") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToTitleInspector")
        :whenActivated(function() fcp:inspector():title():show() end)
        :titled(i18n("goTo") .. " " .. i18n("title") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToTextInspector")
        :whenActivated(function() fcp:inspector():text():show() end)
        :titled(i18n("goTo") .. " " .. i18n("text") .. " " .. i18n("inspector"))

    deps.fcpxCmds
        :add("goToVideoInspector")
        :whenActivated(function() fcp:inspector():video():show() end)
        :titled(i18n("goTo") .. " " .. i18n("video") .. " " .. i18n("inspector"))
end

return plugin
