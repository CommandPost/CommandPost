--- === plugins.finalcutpro.timeline.speed ===
---
--- Speed Related Actions

local require               = require

local fcp                   = require "cp.apple.finalcutpro"
local go                    = require "cp.rx.go"
local i18n                  = require "cp.i18n"
local dialog                = require "cp.dialog"

local displayErrorMessage   = dialog.displayErrorMessage

local Do                    = go.Do

local plugin = {
    id = "finalcutpro.timeline.speed",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Set Speed Rate:
    --------------------------------------------------------------------------------
    local speedPopover = fcp.timeline.speedPopover
    local fcpxCmds = deps.fcpxCmds
    local presets = {-25, -40, -50, -75, -200, -300, -1000, -2000, -3000, -4000, -5000, -7500, -10000, 25, 40, 50, 75, 200, 300, 1000, 2000, 3000, 4000, 5000, 7500, 10000}
    for _, speed in pairs(presets) do
        fcpxCmds
            :add("setSpeedRateTo" .. speed)
            :whenActivated(
                Do(speedPopover:doShow())
                :Then(speedPopover.byRate:doPress())
                :Then(function()
                    speedPopover:rate(speed)
                end)
                :Then(speedPopover:doHide())
                :Catch(function(message)
                    displayErrorMessage(message)
                    return false
                end)
            )
            :titled(i18n("setSpeedRateTo") .. " " .. tostring(speed) .. "%")
    end

    --------------------------------------------------------------------------------
    -- Set Speed to a Duration:
    -- Note, only opens the popover and clicks "Duration", which then allows the
    -- desired duration to be entered with the keyboard. Similar to the standard
    -- `Modify > Change Duration...` menu item.
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("retimeToDuration")
        :whenActivated(
            Do(speedPopover:doShow())
            :Then(speedPopover.byDuration:doPress())
            :Label("plugins.finalcutpro.timeline:retimeToDuration")
        )
        :titled(i18n("retimeToDuration"))
        :subtitled(i18n("retimeToDurationDescription"))
end

return plugin
