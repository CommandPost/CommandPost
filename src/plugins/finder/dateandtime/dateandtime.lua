--- === plugins.finder.dateandtime ===
---
--- Types the date and time in the "YYYYMMDD HHMM" format.

local require = require

local eventtap = require("hs.eventtap")


local plugin = {
    id              = "finder.dateandtime",
    group           = "finder",
    dependencies    = {
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("typeDateAndTime")
        :whenActivated(function()
            eventtap.keyStrokes(os.date("%Y%m%d %H%M"))
        end)
end

return plugin
