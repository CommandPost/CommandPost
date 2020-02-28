--- === plugins.core.display ===
---
--- Display Controls.

local require                   = require

local log                       = require "hs.logger".new("display")

local brightness                = require "hs.brightness"

local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"

local displayNotification       = dialog.displayNotification
local format                    = string.format

local plugin = {
    id = "core.core.display",
    group = "core",
    dependencies = {
        ["core.commands.global"] = "global",
    }
}

local lastBrightnessValue

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("brightnessIncrease")
        :whenActivated(function()
            -- TODO: This is set to 2 because of a bug in Hammerspoon: https://github.com/Hammerspoon/hammerspoon/issues/2312
            if brightness.set(brightness.get() + 2) then
                displayNotification(format(i18n("brightness") .. ": %s", brightness.get()))
            end
        end)
        :titled(i18n("increase") .. " " .. i18n("brightness"))

    deps.global
        :add("brightnessDecrease")
        :whenActivated(function()
            if brightness.set(brightness.get() - 1) then
                displayNotification(format(i18n("brightness") .. ": %s", brightness.get()))
            end
        end)
        :titled(i18n("decrease") .. " " .. i18n("brightness"))

end

return plugin