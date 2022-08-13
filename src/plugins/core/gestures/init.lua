--- === plugins.core.gestures ===
---
--- Adds mouse actions.

local require           = require

--local log               = require "hs.logger".new "gestures"

local eventtap			= require "hs.eventtap"
local image             = require "hs.image"

local config            = require "cp.config"
local i18n              = require "cp.i18n"

local event             = eventtap.event
local imageFromPath     = image.imageFromPath

local mod = {}

local plugin = {
    id              = "core.gestures",
    group           = "core",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Action Functions:
    --------------------------------------------------------------------------------
    local modeFunctions = {
        ["Swipe"] = function(action)
            event.newGesture("beginSwipe" .. action.direction):post()
            event.newGesture("endSwipe" .. action.direction):post()
        end,
        ["Rotate"] = function(action)
            event.newGesture("beginRotate", 0):post()
            event.newGesture("endRotate", action.amount):post()
        end,
        ["Magnify"] = function(action)
            if action.amount >= 1 then
                event.newGesture("beginMagnify", 0):post()
                event.newGesture("endMagnify", action.amount):post()
            else
                event.newGesture("beginMagnify", action.amount):post()
                event.newGesture("endMagnify", 0):post()
            end
        end,
    }

    --------------------------------------------------------------------------------
    -- Setup Actions:
    --------------------------------------------------------------------------------
    local options = {
        {
            text = i18n("swipe") .. " " .. i18n("left"),
            subText = i18n("triggersAVirtualGestureAction"),
            mode = "Swipe",
            direction = "Left"
        },
        {
            text = i18n("swipe") .. " " .. i18n("right"),
            subText = i18n("triggersAVirtualGestureAction"),
            mode = "Swipe",
            direction = "Right"
        },
        {
            text = i18n("swipe") .. " " .. i18n("up"),
            subText = i18n("triggersAVirtualGestureAction"),
            mode = "Swipe",
            direction = "Up"
        },
        {
            text = i18n("swipe") .. " " .. i18n("down"),
            subText = i18n("triggersAVirtualGestureAction"),
            mode = "Swipe",
            direction = "Down"
        },
    }

    local rotationAmount = {1, 5, 10, 20, 30, 45, 60, 90, -1, -5, -10, -20, -30, -45, -60, -90}
    for _, amount in pairs(rotationAmount) do
        table.insert(options, {
            text = i18n("rotate") .. " " .. math.abs(amount) .. "° " .. (amount > 0 and i18n("right") or i18n("left")),
            subText = i18n("triggersAVirtualGestureAction"),
            mode = "Rotate",
            amount = amount
        })
    end

    local magnifyAmount = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9, -1}
    for _, amount in pairs(magnifyAmount) do
        table.insert(options, {
            text = i18n("magnify") .. " " .. math.abs(amount) .. " " .. (amount > 0 and i18n("in") or i18n("out")),
            subText = i18n("triggersAVirtualGestureAction"),
            mode = "Magnify",
            amount = amount
        })
    end

    --------------------------------------------------------------------------------
    -- Setup Action Handler:
    --------------------------------------------------------------------------------
    local icon = imageFromPath(config.basePath .. "/plugins/core/gestures/images/Trackpad.icns")
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_gestures", "global")
        :onChoices(function(choices)
            for _, item in pairs(options) do
                choices
                    :add(item.text)
                    :subText(item.subText)
                    :params({
                        mode = item.mode,
                        amount = item.amount,
                    })
                    :id("global_gestures_" .. item.mode)
                    :image(icon)
            end
        end)
        :onExecute(function(action)
            local mode = action.mode
            if modeFunctions[mode] then
                modeFunctions[mode](action)
            end
        end)
        :onActionId(function(params)
            return "global_gestures_" .. params.mode
        end)

    return mod
end

return plugin
