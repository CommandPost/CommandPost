--- === plugins.finalcutpro.timeline.navigation ===
---
--- Actions to control Timeline Navigation.

local require       = require

--local log           = require "hs.logger".new "timelinenavigation"

local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local plugin = {
    id                = "finalcutpro.timeline.navigation",
    group            = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "commands",
    }
}

function plugin.init(deps)
    for i=1, 9 do
        deps.commands
            :add(i18n("openRecentProjectStartingWith") .. " " .. i)
            :whenActivated(function()
                fcp:timeline():openProject(tostring(i) .. ".*")
            end)
            :titled(i18n("openRecentProjectStartingWith") .. " " .. i)
    end
end

return plugin