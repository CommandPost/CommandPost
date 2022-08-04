--- === plugins.core.accessibility.tools ===
---
--- Actions for control user interface elements via the Accessibility API.

local require               = require

--local log                   = require "hs.logger".new "axtools"

local ax                    = require "hs.axuielement"
local eventtap              = require "hs.eventtap"
local mouse                 = require "hs.mouse"

local deferred              = require "cp.deferred"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local event                 = eventtap.event
local optionPressed         = tools.optionPressed
local playErrorSound        = tools.playErrorSound
local shiftPressed          = tools.shiftPressed

local mod = {}

--- plugins.core.accessibility.tools.currentlyDragging -> boolean
--- Variable
--- Are we currently dragging something?
mod.currentlyDragging = false

local plugin = {
    id              = "core.accessibility.tools",
    group           = "core",
    dependencies    = {
        ["core.commands.global"] = "global",
    }
}

--- plugins.core.accessibility.tools.changeElementUnderMouse(increase) -> none
--- Function
--- Change the value of a Accessibility Element under the mouse.
---
--- Parameters:
---  * increase - A boolean to set the direction.
---
--- Returns:
---  * None
function mod.changeElementUnderMouse(increase)
    local element = ax.systemElementAtPosition(mouse.absolutePosition())

    if not element then
        playErrorSound()
    end

    local role = element:attributeValue("AXRole")
    if role == "AXSlider" then
        --------------------------------------------------------------------------------
        -- Slider:
        --------------------------------------------------------------------------------
        local amount = 1
        if shiftPressed() then
            amount = 10
        end
        for _=1, amount do
            if increase then
                element:performAction("AXIncrement")
            else
                element:performAction("AXDecrement")
            end
        end
    elseif role == "AXValueIndicator" then
        --------------------------------------------------------------------------------
        -- Value Indicator from a Slider:
        --------------------------------------------------------------------------------
        local parent = element:attributeValue("AXParent")
        if parent then
            local amount = 1
            if shiftPressed() then
                amount = 10
            end
            for _=1, amount do
                if increase then
                    parent:performAction("AXIncrement")
                else
                    parent:performAction("AXDecrement")
                end
            end
        end
    elseif role == "AXTextField" then
        --------------------------------------------------------------------------------
        -- Text Field:
        --------------------------------------------------------------------------------
        local currentValue = element:attributeValue("AXValue")
        local currentValueNumber = currentValue and tonumber(currentValue)
        if currentValueNumber then
            local newValue = currentValueNumber
            local amount = 1
            if shiftPressed() then
                amount = 10
            end
            if optionPressed() then
                amount = 0.01
            end
            if increase then
                newValue = newValue + amount
            else
                newValue = newValue - amount
            end
            element:setAttributeValue("AXFocused", true)
            element:setAttributeValue("AXValue", tostring(newValue))
            element:performAction("AXConfirm")
        end
    elseif role == "AXStaticText" then
        --------------------------------------------------------------------------------
        -- Static Text (DaVinci Resolve):
        --------------------------------------------------------------------------------
        local currentCursorType = mouse.currentCursorType()
        if mod.currentlyDragging then
            mod.originalPosition = mouse.absolutePosition()
            local currentPosition = mouse.absolutePosition()

            local amount = 1
            if mod.shiftPressed then
                amount = 10
            end
            if mod.optionPressed then
                amount = 0.5
            end

            if not increase then amount = amount * -1 end

            event.newMouseEvent(event.types.leftMouseDragged, { x = currentPosition.x + amount, y = currentPosition.y })
                :setProperty(event.properties.mouseEventDeltaX, amount)
                :post()
        else
            if currentCursorType == "daVinciResolveHorizontalArrows" then
                mod.shiftPressed = shiftPressed()
                mod.optionPressed = optionPressed()
                mod.currentlyDragging = true
                local currentPosition = mouse.absolutePosition()
                event.newMouseEvent(event.types.leftMouseDown, currentPosition):post()
                if not mod.finishDragging then
                    mod.finishDragging = deferred.new(0.5):action(function()
                        local newCurrentPosition = mouse.absolutePosition()
                        event.newMouseEvent(event.types.leftMouseUp, newCurrentPosition):post()
                        mod.currentlyDragging = nil
                        mod.finishDragging = nil
                        mod.shiftPressed = nil
                        mod.optionPressed = nil
                    end)
                end
                mod.finishDragging()
            end
        end
    end
end

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Actions:
    --------------------------------------------------------------------------------
    local cmds = deps.global
    cmds
        :add("incrementAXElementUnderMouse")
        :whenActivated(function() mod.changeElementUnderMouse(true) end)
        :titled(i18n("incrementUserInterfaceElementUnderMouse"))
        :subtitled(i18n("holdDownShiftToChangeLargerIncrementsAndOptionForSmaller"))

    cmds
        :add("decrementAXElementUnderMouse")
        :whenActivated(function() mod.changeElementUnderMouse(false) end)
        :titled(i18n("decrementUserInterfaceElementUnderMouse"))
        :subtitled(i18n("holdDownShiftToChangeLargerIncrementsAndOptionForSmaller"))

    return mod
end

return plugin
