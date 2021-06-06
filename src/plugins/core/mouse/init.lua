--- === plugins.core.mouse ===
---
--- Adds mouse actions.

local require           = require

--local log               = require "hs.logger".new "mouse"

local eventtap          = require "hs.eventtap"
local event             = require "hs.eventtap.event"
local mouse             = require "hs.mouse"
local image             = require "hs.image"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local just              = require "cp.just"

local imageFromPath     = image.imageFromPath

local mod = {}

local plugin = {
    id              = "core.mouse",
    group           = "mouse",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Action Functions:
    --------------------------------------------------------------------------------
    local modeFunctions = {
        ["leftClick"] = function()
            local absolutePosition = mouse.absolutePosition()
            eventtap.leftClick(absolutePosition, 0)
        end,
        ["leftDoubleClick"] = function()
            local doubleClickInterval = eventtap.doubleClickInterval()
            local absolutePosition = mouse.absolutePosition()
            eventtap.leftClick(absolutePosition, 0)
            just.wait(doubleClickInterval)
            eventtap.leftClick(absolutePosition, 0)
        end,
        ["rightClick"] = function()
            local absolutePosition = mouse.absolutePosition()
            eventtap.rightClick(absolutePosition, 0)
        end,
        ["middleClick"] = function()
            local absolutePosition = mouse.absolutePosition()
            eventtap.middleClick(absolutePosition, 0)
        end,
        ["otherClick"] = function(action)
            local absolutePosition = mouse.absolutePosition()
            eventtap.otherClick(absolutePosition, 0, action.otherButton)
        end,
        ["scroll"] = function(action)
            event.newScrollEvent({action.x, action.y}, action.modifiers, action.unit):post()
        end,
    }

    --------------------------------------------------------------------------------
    -- Setup Clicking Actions:
    --------------------------------------------------------------------------------
    local options = {
        {
            text = i18n("triggerALeftMouseClick"),
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "leftClick"
        },
        {
            text = i18n("triggerARightMouseClick"),
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "rightClick"
        },
        {
            text = i18n("triggerAMiddleMouseClick"),
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "middleClick"
        },
        {
            text = i18n("triggerALeftDoubleMouseClick"),
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "leftDoubleClick"
        },
    }

    for i=2, 31 do
        table.insert(options, {
            text = i18n("triggerOtherMouseButton") .. " " .. i,
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "otherClick",
            otherButton = i
        })
    end

    --------------------------------------------------------------------------------
    -- Setup Scroll Wheel Actions:
    --------------------------------------------------------------------------------
    local modifiers = {
        { description = "",                                                         label = "", mods = {} },
        { description = "COMMAND",                                                  label = "⌘", mods = {"cmd"} },
        { description = "COMMAND and SHIFT",                                        label = "⇧⌘", mods = {"shift", "cmd"} },
        { description = "OPTION and COMMAND and SHIFT",                             label = "⌥⇧⌘", mods = {"alt", "shift", "cmd"} },
        { description = "CONTROL and OPTION and COMMAND and SHIFT",                 label = "⌃⌥⇧⌘", mods = {"ctrl", "alt", "shift", "cmd"} },
        { description = "CONTROL and COMMAND and SHIFT",                            label = "⌃⇧⌘", mods = {"ctrl", "shift", "cmd"} },
        { description = "OPTION and COMMAND",                                       label = "⌥⌘", mods = {"alt", "cmd"} },
        { description = "CONTROL and OPTION and COMMAND",                           label = "⌃⌥⌘", mods = {"ctrl", "alt", "cmd"} },
        { description = "CONTROL and COMMAND",                                      label = "⌃⌘", mods = {"ctrl", "cmd"} },
        { description = "SHIFT",                                                    label = "⇧", mods = {"shift"} },
        { description = "OPTION and SHIFT",                                         label = "⌥⇧", mods = {"alt", "shift"} },
        { description = "CONTROL and OPTION and SHIFT",                             label = "⌃⌥⇧", mods = {"ctrl", "alt", "shift"} },
        { description = "CONTROL and SHIFT",                                        label = "⌃⇧", mods = {"ctrl", "shift"} },
        { description = "OPTION",                                                   label = "⌥", mods = {"alt"} },
        { description = "CONTROL and OPTION",                                       label = "⌃⌥", mods = {"ctrl", "alt"} },
        { description = "CONTROL",                                                  label = "⌃", mods = {"ctrl"} },
        { description = "COMMAND and FUNCTION",                                     label = "Fn⌘", mods = {"cmd", "fn"} },
        { description = "COMMAND and SHIFT and FUNCTION",                           label = "Fn⇧⌘", mods = {"shift", "cmd", "fn"} },
        { description = "OPTION and COMMAND and SHIFT and FUNCTION",                label = "Fn⌥⇧⌘", mods = {"alt", "shift", "cmd", "fn"} },
        { description = "CONTROL and OPTION and COMMAND and SHIFT and FUNCTION",    label = "Fn⌃⌥⇧⌘", mods = {"ctrl", "alt", "shift", "cmd", "fn"} },
        { description = "CONTROL and COMMAND and SHIFT and FUNCTION",               label = "Fn⌃⇧⌘", mods = {"ctrl", "shift", "cmd", "fn"} },
        { description = "OPTION and COMMAND and FUNCTION",                          label = "Fn⌥⌘", mods = {"alt", "cmd", "fn"} },
        { description = "CONTROL and OPTION and COMMAND and FUNCTION",              label = "Fn⌃⌥⌘", mods = {"ctrl", "alt", "cmd", "fn"} },
        { description = "CONTROL and COMMAND and FUNCTION",                         label = "Fn⌃⌘", mods = {"ctrl", "cmd", "fn"} },
        { description = "SHIFT and FUNCTION",                                       label = "Fn⇧", mods = {"shift", "fn"} },
        { description = "OPTION and SHIFT and FUNCTION",                            label = "Fn⌥⇧", mods = {"alt", "shift", "fn"} },
        { description = "CONTROL and OPTION and SHIFT and FUNCTION",                label = "Fn⌃⌥⇧", mods = {"ctrl", "alt", "shift", "fn"} },
        { description = "CONTROL and SHIFT and FUNCTION",                           label = "Fn⌃⇧", mods = {"ctrl", "shift", "fn"} },
        { description = "OPTION and FUNCTION",                                      label = "Fn⌥", mods = {"alt", "fn"} },
        { description = "CONTROL and OPTION and FUNCTION",                          label = "Fn⌃⌥", mods = {"ctrl", "alt", "fn"} },
        { description = "CONTROL and FUNCTION",                                     label = "Fn⌃", mods = {"ctrl", "fn"} },
        { description = "FUNCTION",                                                 label = "Fn", mods = {"fn"} },
    }
    local amounts = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10}
    local directions = {"horizontal", "vertical"}
    local units = {"Line", "Pixel"}
    for _, modifier in pairs(modifiers) do
        for _, amount in pairs(amounts) do
            for _, direction in pairs(directions) do
                for _, unit in pairs(units) do
                    local directionLabel
                    if amount >= 1 then
                        if direction == "horizontal" then
                            directionLabel = i18n("right")
                        else
                            directionLabel = i18n("up")
                        end
                    else
                        if direction == "horizontal" then
                            directionLabel = i18n("left")
                        else
                            directionLabel = i18n("down")
                        end
                    end

                    table.insert(options, {
                        text = i18n("triggerMouseScrollWheel") .. " - " .. math.abs(amount) .. " " .. unit .. " " .. directionLabel .. (modifier.description ~= "" and " - " .. modifier.description .. " (" .. modifier.label .. ")" or ""),
                        subText = i18n("triggerAVirtualMouseScrollWheelEvent"),
                        mode = "scroll",
                        amount = amount,
                        modifiers = modifier.mods,
                        unit = string.lower(unit),
                        x = direction == "horizontal" and amount or 0,
                        y = direction == "vertical" and amount or 0,
                    })
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Action Handler:
    --------------------------------------------------------------------------------
    local icon = imageFromPath(config.basePath .. "/plugins/core/mouse/images/mouse.png")
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_mouse", "global")
        :onChoices(function(choices)
            for _, item in pairs(options) do
                choices
                    :add(item.text)
                    :subText(item.subText)
                    :params({
                        mode = item.mode,
                        amount = item.amount,
                        modifiers = item.modifiers,
                        unit = item.unit,
                        x = item.x,
                        y = item.y,
                        otherButton = item.otherButton,
                    })
                    :id("global_mouse_" .. item.mode)
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
            return "global_mouse_" .. params.mode
        end)

    return mod
end

return plugin
