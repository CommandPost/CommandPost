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
local WaitUntil             = go.WaitUntil

local plugin = {
    id = "finalcutpro.timeline.speed",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Set Speed Rate
    -- Slow 25% Slow 75% Fast X3 X5 X10 X30 X40 X50 X75 X100 Please! :)
    --------------------------------------------------------------------------------
    local speedPopover = fcp:timeline():speedPopover()
    local fcpxCmds = deps.fcpxCmds
    local presets = {-25, -75, -300, -1000, -3000, -4000, -5000, -7500, -10000, 25, 75, 300, 1000, 3000, 4000, 5000, 7500, 10000}
    for _, speed in pairs(presets) do
        fcpxCmds
            :add("setSpeedRateTo" .. speed)
            :whenActivated(function()
                return Do(speedPopover:doShow())
                    :Then(WaitUntil(speedPopover.isShowing):Is(true):TimeoutAfter(2000))
                    :Then(function()
                        speedPopover:rateValue(speed)
                        speedPopover:hide()
                    end)
                    :Catch(function(message)
                        displayErrorMessage(message)
                        return false
                    end)
                    :Now()
            end)
            :titled(i18n("setSpeedRateTo") .. " " .. tostring(speed) .. "%")
    end
end

return plugin
