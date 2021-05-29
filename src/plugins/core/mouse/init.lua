--- === plugins.core.mouse ===
---
--- Adds mouse actions.

local require           = require

--local log               = require "hs.logger".new "pbHistory"

local eventtap          = require "hs.eventtap"
local mouse             = require "hs.mouse"

local i18n              = require "cp.i18n"
local just              = require "cp.just"

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
    }

    --------------------------------------------------------------------------------
    -- Setup Actions:
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
    -- Setup Action Handler:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_mouse", "global")
        :onChoices(function(choices)
            for _, item in pairs(options) do
                choices
                    :add(item.text)
                    :subText(item.subText)
                    :params({
                        mode = item.mode,
                    })
                    :id("global_mouse_" .. item.mode)
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
