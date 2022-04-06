--- === plugins.finalcutpro.timeline.horizontal ===
---
--- Actions for changing the Timeline Horizontally

local require                   = require

local eventtap                  = require "hs.eventtap"

local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"

local checkKeyboardModifiers    = eventtap.checkKeyboardModifiers

local plugin = {
    id = "finalcutpro.timeline.horizontal",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local fcpxCmds = deps.fcpxCmds

    local increments = {0.001, 0.01, 0.1, 1}
    for _, increment in pairs(increments) do
        fcpxCmds
            :add("shiftTimelineHorizontallyIncrease" .. increment)
            :whenActivated(function()
                local value = increment
                if checkKeyboardModifiers()["shift"] then
                    value = value * 2
                end
                fcp.timeline.contents:scrollArea():show():shiftHorizontalBy(value)
            end)
            :titled(i18n("increaseTimelineHorizontalScrollBy") .. " " .. increment)
            :subtitled(i18n("holdingDownShiftWillDoubleThisValue"))

        fcpxCmds
            :add("shiftTimelineHorizontallyDecrease" .. increment)
            :whenActivated(function()
                local value = increment
                if checkKeyboardModifiers()["shift"] then
                    value = value * 2
                end
                fcp.timeline.contents:scrollArea():show():shiftHorizontalBy(value * -1)
            end)
            :titled(i18n("decreaseTimelineHorizontalScrollBy") .. " " .. increment)
            :subtitled(i18n("holdingDownShiftWillDoubleThisValue"))
    end

end

return plugin
