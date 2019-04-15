--- === plugins.finalcutpro.midi.controls.controlui.relative ===
---
--- Adds the ability to control any Final Cut Pro User Interface Element via a MIDI Knob/Slider.

local require = require

local log               = require("hs.logger").new("midiCtrlSlider")

local ax 			          = require("hs._asm.axuielement")
local eventtap          = require("hs.eventtap")
local mouse			        = require("hs.mouse")

local deferred          = require("cp.deferred")
local dialog            = require("cp.dialog")
local i18n              = require("cp.i18n")


local mod = {}

-- plugins.finalcutpro.midi.controls.controlui.relative._changedValue -> number
-- Variable
-- Changed value.
mod._changedValue = 0

-- controlPressed() -> boolean
-- Function
-- Is the Control Key being pressed?
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if the Control key is being pressed, otherwise `false`.
local function controlPressed()
    --------------------------------------------------------------------------------
    -- Check for keyboard modifiers:
    --------------------------------------------------------------------------------
    local mods = eventtap.checkKeyboardModifiers()
    if mods['ctrl'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['capslock'] and not mods['fn'] then
        return true
    end
    return false
end

-- shiftPressed() -> boolean
-- Function
-- Is the Shift Key being pressed?
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if the Shift key is being pressed, otherwise `false`.
local function shiftPressed()
    --------------------------------------------------------------------------------
    -- Check for keyboard modifiers:
    --------------------------------------------------------------------------------
    local mods = eventtap.checkKeyboardModifiers()
    if mods['shift'] and not mods['cmd'] and not mods['alt'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
        return true
    end
    return false
end

--- plugins.finalcutpro.midi.controls.controlui.relative.control() -> nil
--- Function
--- Control Function
---
--- Parameters:
---  * metadata - table of metadata from the MIDI callback
---
--- Returns:
---  * None
function mod.control(metadata)

    if controlPressed() then
        --------------------------------------------------------------------------------
        -- CONTROL is being pressed:
        --------------------------------------------------------------------------------
        local element = ax.systemElementAtPosition(mouse.getAbsolutePosition())

        --------------------------------------------------------------------------------
        -- Ignore if this exact UI Element is already selected:
        --------------------------------------------------------------------------------
        if mod._uielement and element and mod._uielement == element
        or mod._uielement and mod._uielement == element:attributeValue("AXParent")
        or mod._parentElement and mod._parentElement == element
        or mod._parentElement and mod._parentElement == element:attributeValue("AXParent")
        then
            return
        end

        --------------------------------------------------------------------------------
        -- Check to to see if element is a UI Element we can actually use:
        --------------------------------------------------------------------------------
        local uielement
        mod._textField = false
        if element and element:attributeValue("AXRole") and element:attributeValue("AXRole") == "AXValueIndicator" then
            uielement = element:attributeValue("AXParent")

            --------------------------------------------------------------------------------
            -- Let's try grab the Text Field Instead (because Final Cut Pro is annoying):
            --------------------------------------------------------------------------------
            local parent = uielement:attributeValue("AXParent")
            for i = 1, parent:attributeValueCount("AXChildren") do
                if parent[i] == uielement then
                    if parent[i + 1]:attributeValue("AXRole") == "AXTextField" then
                        mod._parentElement = uielement
                        uielement = parent[i + 1]
                        mod._textField = true
                    end
                end
            end

        elseif element and element:attributeValue("AXRole") and element:attributeValue("AXRole") == "AXSlider" then
            uielement = element

            --------------------------------------------------------------------------------
            -- Let's try grab the Text Field Instead (because Final Cut Pro is annoying):
            --------------------------------------------------------------------------------
            local parent = uielement:attributeValue("AXParent")
            for i = 1, parent:attributeValueCount("AXChildren") do
                if parent[i] == uielement then
                    if parent[i + 1]:attributeValue("AXRole") == "AXTextField" then
                        mod._parentElement = uielement
                        uielement = parent[i + 1]
                        mod._textField = true
                    end
                end
            end

        elseif element
        and element:attributeValue("AXRole")
        and element:attributeValue("AXRole") == "AXTextField"
        and element:attributeValue("AXValue")
        and tonumber(element:attributeValue("AXValue")) then
            mod._textField = true
            uielement = element
        end

        --------------------------------------------------------------------------------
        -- Register the UI Element:
        --------------------------------------------------------------------------------
        if uielement then
            --------------------------------------------------------------------------------
            -- Success:
            --------------------------------------------------------------------------------
            dialog.displayNotification(i18n("addedFCPUIElementToMIDI"))
            mod._uielement = uielement
        else
            --------------------------------------------------------------------------------
            -- Failure:
            --------------------------------------------------------------------------------
            dialog.displayNotification(i18n("invalidFCPUIElement"))
            mod._uielement = nil
            return
        end

    else
        --------------------------------------------------------------------------------
        -- CONTROL is NOT being pressed:
        --------------------------------------------------------------------------------
        if mod._uielement then
            --------------------------------------------------------------------------------
            -- Calculate the change value:
            --------------------------------------------------------------------------------
            local midiValue
            if metadata.pitchChange then
                midiValue = metadata.pitchChange
            else
                midiValue = metadata.fourteenBitValue
            end

            if midiValue == 0 then
                mod._changedValue = mod._changedValue - 1
            else
                mod._changedValue = mod._changedValue + 1
            end

            --------------------------------------------------------------------------------
            -- Trigger UI Updater:
            --------------------------------------------------------------------------------
            mod._updateUI()
        else
            --------------------------------------------------------------------------------
            -- No UI Element is registered:
            --------------------------------------------------------------------------------
            dialog.displayNotification(i18n("noFCPUIElementDetected"))
            mod._uielement = nil
        end
    end
end

--- plugins.finalcutpro.midi.controls.controlui.relative.init() -> module
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The module
function mod.init()

    --------------------------------------------------------------------------------
    -- Set up Deferred UI Updater:
    --------------------------------------------------------------------------------
    mod._updateUI = deferred.new(0.01)
    mod._updateUI:action(function()
        if mod._changedValue ~= 0 then
            --------------------------------------------------------------------------------
            -- Get current value and update:
            --------------------------------------------------------------------------------
            local currentValue = mod._uielement:attributeValue("AXValue")
            if currentValue and tonumber(currentValue) then
                local newValue = (tonumber(currentValue) + mod._changedValue)
                if shiftPressed() then
                    if mod._changedValue < 0 then
                        newValue = newValue - 5
                    else
                        newValue = newValue + 5
                    end
                end
                if mod._textField then
                    mod._uielement:setAttributeValue("AXFocused", true)
                    mod._uielement:setAttributeValue("AXValue", tostring(newValue))
                    mod._uielement:performAction("AXConfirm")
                else
                    mod._uielement:setAttributeValue("AXValue", newValue)

                end
            else
                log.ef("Value was not a number: %s", currentValue)
            end

            --------------------------------------------------------------------------------
            -- Reset Changed Value:
            --------------------------------------------------------------------------------
            mod._changedValue = 0

        end
    end)

    local params = {
        group = "fcpx",
        text = string.upper(i18n("midi")) .. ": " .. i18n("controlFCPUIElementRelative"),
        subText = i18n("controlFCPUIElementRelativeNote"),
        fn = mod.control,
    }
    mod._manager.controls:new("controlFCPUIElementRelative", params)
    return mod
end


local plugin = {
    id              = "finalcutpro.midi.controls.controlui.relative",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

function plugin.init(deps)
    mod._manager = deps.manager
    return mod.init()
end

return plugin
