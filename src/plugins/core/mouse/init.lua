--- === plugins.core.mouse ===
---
--- Adds mouse actions.

local require           = require

--local log               = require "hs.logger".new "mouse"

local eventtap          = require "hs.eventtap"
local mouse             = require "hs.mouse"
local image             = require "hs.image"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local just              = require "cp.just"

local event             = eventtap.event
local imageFromPath     = image.imageFromPath

local mod = {}

local plugin = {
    id              = "core.mouse",
    group           = "core",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Define Modifiers:
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

    --------------------------------------------------------------------------------
    -- Setup Action Functions:
    --------------------------------------------------------------------------------
    local modeFunctions = {
        ["leftClick"] = function(action)
            local absolutePosition = mouse.absolutePosition()
            event.newMouseEvent(event.types.leftMouseDown, absolutePosition, action.modifiers):post()
            event.newMouseEvent(event.types.leftMouseUp, absolutePosition, action.modifiers):post()
        end,
        ["leftDoubleClick"] = function(action)
            local doubleClickInterval = eventtap.doubleClickInterval()
            local absolutePosition = mouse.absolutePosition()
            event.newMouseEvent(event.types.leftMouseDown, absolutePosition, action.modifiers):post()
            event.newMouseEvent(event.types.leftMouseUp, absolutePosition, action.modifiers):post()
            just.wait(doubleClickInterval)
            event.newMouseEvent(event.types.leftMouseDown, absolutePosition, action.modifiers):post()
            event.newMouseEvent(event.types.leftMouseUp, absolutePosition, action.modifiers):post()
        end,
        ["rightClick"] = function(action)
            local absolutePosition = mouse.absolutePosition()
            event.newMouseEvent(event.types.rightMouseDown, absolutePosition, action.modifiers):post()
            event.newMouseEvent(event.types.rightMouseUp, absolutePosition, action.modifiers):post()
        end,
        ["otherClick"] = function(action)
            local absolutePosition = mouse.absolutePosition()
            event.newMouseEvent(event.types.otherMouseDown, absolutePosition, action.modifiers):setProperty(event.properties.mouseEventButtonNumber, action.otherButton):post()
            event.newMouseEvent(event.types.otherMouseUp, absolutePosition, action.modifiers):setProperty(event.properties.mouseEventButtonNumber, action.otherButton):post()
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
            text = i18n("leftMouseClick"),
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "leftClick"
        },
        {
            text = i18n("rightMouseClick"),
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "rightClick"
        },
        {
            text = i18n("middleMouseClick"),
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "otherClick",
            otherButton = 2
        },
        {
            text = i18n("leftDoubleMouseClick"),
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "leftDoubleClick"
        },
    }

    for i=2, 31 do
        table.insert(options, {
            text = i18n("otherMouseButton") .. " " .. i,
            subText = i18n("triggersAVirtualMouseClick"),
            mode = "otherClick",
            otherButton = i
        })
    end

    for _, modifier in pairs(modifiers) do
        if modifier.description ~= "" then
            table.insert(options, {
                text = i18n("leftMouseClick") .. " - " .. modifier.description .. " (" .. modifier.label .. ")",
                subText = i18n("triggersAVirtualMouseClick"),
                mode = "leftClick",
                modifiers = modifier.mods
            })

            table.insert(options, {
                text = i18n("rightMouseClick") .. " - " .. modifier.description .. " (" .. modifier.label .. ")",
                subText = i18n("triggersAVirtualMouseClick"),
                mode = "rightClick",
                modifiers = modifier.mods
            })

            table.insert(options, {
                text = i18n("middleMouseClick") .. " - " .. modifier.description .. " (" .. modifier.label .. ")",
                subText = i18n("triggersAVirtualMouseClick"),
                mode = "otherClick",
                otherButton = 2,
                modifiers = modifier.mods
            })
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Scroll Wheel Actions:
    --------------------------------------------------------------------------------
    local amounts = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10}
    local directions = {"horizontal", "vertical"}
    local units = {"Line", "Pixel"}
    for _, modifier in pairs(modifiers) do
        for _, amount in pairs(amounts) do
            for _, direction in pairs(directions) do
                for _, unit in pairs(units) do
                    local directionLabel
                    if amount > 0 then
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
                        text = i18n("mouseScrollWheel") .. " - " .. math.abs(amount) .. " " .. unit .. " " .. directionLabel .. (modifier.description ~= "" and " - " .. modifier.description .. " (" .. modifier.label .. ")" or ""),
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
