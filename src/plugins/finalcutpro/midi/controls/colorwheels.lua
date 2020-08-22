--- === plugins.finalcutpro.midi.controls.colorwheels ===
---
--- Final Cut Pro MIDI Color Controls.

local require = require

local log               = require "hs.logger".new "colorMIDI"

local inspect           = require "hs.inspect"

local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local optionPressed     = tools.optionPressed
local shiftPressed      = tools.shiftPressed

local rescale           = tools.rescale
local round             = tools.round

local format            = string.format

-- MAX_14BIT -> number
-- Constant
-- Maximum 14bit Limit (16383)
local MAX_14BIT = 0x3FFF

-- HALF_14BIT -> number
-- Constant
-- Half-way 14bit (8192)
local HALF_14BIT = (MAX_14BIT + 1) / 2

-- MAX_7BIT -> number
-- Constant
-- Maximum 7bit Limit (127)
local MAX_7BIT  = 0x7F

-- HALF_7BIT -> number
-- Constant
-- Half-way 7bit (64)
local HALF_7BIT = (MAX_7BIT + 1) / 2

-- UNSHIFTED_SCALE -> number
-- Constant
-- Scale unshifted 7-bit by 20%
local UNSHIFTED_SCALE = 20/100

--------------------------------------------------------------------------------
-- MIDI Controller Value (7bit):   0 to 127
-- MIDI Controller Value (14bit):  0 to 16383
--
-- Percentage Slider:           -100 to 100
-- Angle Slider:                   0 to 360 (359 in Final Cut Pro 10.4)
--
-- Wheel Color Orientation          -1 to 1
--
--
-- AudioSwift:
--
-- Relative A or Signed Bit
--  * Increase: 1-8
--  * Decrease: 65-72
--
-- Relative B or 2's Compliment
--  * Increase: 1-8
--  * Decrease: 127-120
--------------------------------------------------------------------------------

-- makeRelativeAWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeRelativeAWheelHandler(wheelFinderFn, vertical)

    local wheelRight = 0
    local wheelUp = 0

    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:colorOrientation()

            current.right = current.right + wheelRight
            current.up = current.up + wheelUp

            wheel:colorOrientation(current)

            wheelRight = 0
            wheelUp = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)

        if optionPressed() then
            if wheel:isShowing() then
                wheel:colorOrientation({right=0, up=0})
                wheelRight = 0
                wheelUp = 0
            else
                wheel:show()
            end
            return
        end

        local increment = 0.01

        if shiftPressed() then
            increment = 0.001
        end

        local midiValue = metadata.pitchChange or metadata.fourteenBitValue
        if midiValue < 8000 then
            if vertical then
                wheelUp = wheelUp + increment
            else
                wheelRight = wheelRight + increment
            end
        else
            if vertical then
                wheelUp = wheelUp - increment
            else
                wheelRight = wheelRight - increment
            end
        end

        updateUI()
    end
end

-- makeWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeWheelHandler(wheelFinderFn, vertical)

    local wheelRight = nil
    local wheelUp = nil

    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:colorOrientation()

            if wheelRight then current.right = wheelRight end
            if wheelUp then current.up = wheelUp end

            wheel:colorOrientation(current)
        else
            wheel:show()
        end
    end)

    return function(metadata)
        local midiValue, value

        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                value = rescale(midiValue, 0, MAX_14BIT, -0.33, 0.33)
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                value = (midiValue / MAX_7BIT) * 2 - 1
                if not shiftPressed() then -- scale it down
                    value = value * UNSHIFTED_SCALE
                    if midiValue == HALF_7BIT then value = 0 end
                end
            end
        end
        if value == nil then
            log.ef("Unexpected MIDI value of type '%s': %s", type(midiValue), inspect(midiValue))
        end

        if vertical then
            wheelUp = value
        else
            wheelRight = value
        end

        updateUI()
    end
end

-- makeResetColorWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for resetting a Color Wheel.
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to reset.
--
-- Returns:
--  * a func
local function makeResetColorWheelHandler(wheelFinderFn)
    return function()
        local wheel = wheelFinderFn()
        wheel:show()
        wheel:colorOrientation({right=0, up=0})
    end
end

-- makeRelativeAWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeRelativeASaturationHandler(wheelFinderFn)

    local saturationShift = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:saturationValue()
            wheel:saturationValue(current + saturationShift)
            saturationShift = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)

        if optionPressed() then
            if wheel:isShowing() then
                wheel:saturationValue(1)
                saturationShift = 0
            else
                wheel:show()
            end
            return
        end

        local increment = (shiftPressed() and 0.001) or 0.01
        local midiValue = metadata.pitchChange or metadata.fourteenBitValue
        if midiValue < 8000 then
            saturationShift = saturationShift + increment
        else
            saturationShift = saturationShift - increment
        end

        updateUI()
    end
end

-- makeAbsoluteSaturationHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeAbsoluteSaturationHandler(wheelFinderFn)
    local saturationValue = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            wheel:saturationValue(saturationValue)
            saturationValue = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)
        local midiValue
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                saturationValue = rescale(midiValue, 0, 16383, 0, 2)
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                local value
                if shiftPressed() then
                    value = midiValue / 128 * 2
                else
                    value = midiValue / 128 * 2
                end
                if midiValue == HALF_7BIT then value = 1 end
                saturationValue = value
            end
        end

        updateUI()
    end
end

-- makeRelativeAWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeRelativeABrightnessHandler(wheelFinderFn)

    local brightnessShift = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:brightnessValue()
            wheel:brightnessValue(current + brightnessShift)
            brightnessShift = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)

        if optionPressed() then
            if wheel:isShowing() then
                wheel:brightnessValue(1)
                brightnessShift = 0
            else
                wheel:show()
            end
            return
        end

        local increment = (shiftPressed() and 0.001) or 0.01
        local midiValue = metadata.pitchChange or metadata.fourteenBitValue
        if midiValue < 8000 then
            brightnessShift = brightnessShift + increment
        else
            brightnessShift = brightnessShift - increment
        end

        updateUI()
    end
end

-- makeAbsoluteBrightnessHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeAbsoluteBrightnessHandler(wheelFinderFn)
    local brightnessValue = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            wheel:brightnessValue(brightnessValue)
            brightnessValue = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)
        local midiValue
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                brightnessValue = rescale(midiValue, 0, 16383, -0.4, 0.4)
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                local value
                if shiftPressed() then
                    value = midiValue / 128 * 0.8 - 0.4
                else
                    value = midiValue / 128 * 0.8 - 0.4
                end
                if midiValue == HALF_7BIT then value = 0 end
                brightnessValue = value
            end
        end

        updateUI()
    end
end

-- makeAbsoluteTemperatureHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeAbsoluteTemperatureHandler()
    --------------------------------------------------------------------------------
    -- 2500 to 10000; Middle is 5000
    --------------------------------------------------------------------------------
    local temperatureValue = 0
    local wheel = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            wheel:temperature(temperatureValue)
            temperatureValue = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)
        local midiValue
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                local value
                if midiValue == HALF_14BIT then
                    value = 5000
                elseif midiValue < HALF_14BIT then
                    value = rescale(midiValue, 0, HALF_14BIT-1, 2500, 4997)
                elseif midiValue > HALF_14BIT then
                    value = rescale(midiValue, HALF_14BIT+1, MAX_14BIT, 5001, 10000)
                end
                temperatureValue = value
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                local value
                if midiValue == HALF_7BIT then
                    value = 5000
                elseif midiValue < HALF_7BIT then
                    value = rescale(midiValue, 0, HALF_7BIT-1, 2500, 4997)
                elseif midiValue > HALF_7BIT then
                    value = rescale(midiValue, HALF_7BIT+1, MAX_7BIT, 5001, 10000)
                end
                temperatureValue = value
            end
        end
        updateUI()
    end
end

-- makeRelativeATemperatureHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeRelativeATemperatureHandler()

    local temperatureShift = 0
    local wheel = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:temperature()
            wheel:temperature(current + temperatureShift)
            temperatureShift = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)

        if optionPressed() then
            if wheel:isShowing() then
                wheel:temperature(5000)
                temperatureShift = 0
            else
                wheel:show()
            end
            return
        end

        local increment = (shiftPressed() and 0.001) or 0.01
        local midiValue = metadata.pitchChange or metadata.fourteenBitValue
        if midiValue < 8000 then
            temperatureShift = temperatureShift + increment
        else
            temperatureShift = temperatureShift - increment
        end

        updateUI()
    end
end

-- makeAbsoluteTintHandler() -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeAbsoluteTintHandler()
    --------------------------------------------------------------------------------
    -- -50 to 50
    --------------------------------------------------------------------------------
    local tintValue = 0
    local wheel = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            wheel:tint(tintValue)
            tintValue = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)
        local midiValue
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                tintValue = round(midiValue / 16383 * (50*2) - 50)
                if midiValue == 16383/2 then tintValue = 0 end
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                tintValue = round(midiValue / 127 * (50*2) - 50)
            end
        end
        updateUI()
    end
end

-- makeRelativeATintHandler() -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeRelativeATintHandler()

    local tintShift = 0
    local wheel = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:tint()
            wheel:tint(current + tintShift)
            tintShift = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)

        if optionPressed() then
            if wheel:isShowing() then
                wheel:tint(0)
                tintShift = 0
            else
                wheel:show()
            end
            return
        end

        local increment = (shiftPressed() and 0.001) or 0.01
        local midiValue = metadata.pitchChange or metadata.fourteenBitValue
        if midiValue < 8000 then
            tintShift = tintShift + increment
        else
            tintShift = tintShift - increment
        end

        updateUI()
    end
end

-- makeAbsoluteHueHandler() -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeAbsoluteHueHandler()
    --------------------------------------------------------------------------------
    -- 0 to 360:
    --------------------------------------------------------------------------------
    local hueValue = 0
    local wheel = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            wheel:hue(hueValue)
            hueValue = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)
        local midiValue
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                hueValue = round(midiValue / 16383 * 360)
                if midiValue == 16383/2 then hueValue = 0 end
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                hueValue = round(midiValue / 127 * 360)
            end
        end
        updateUI()
    end
end

-- makeRelativeAHueHandler() -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeRelativeAHueHandler()

    local hueShift = 0
    local wheel = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:hue()
            wheel:hue(current + hueShift)
            hueShift = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)

        if optionPressed() then
            if wheel:isShowing() then
                wheel:hue(0)
                hueShift = 0
            else
                wheel:show()
            end
            return
        end

        local increment = (shiftPressed() and 0.001) or 0.01
        local midiValue = metadata.pitchChange or metadata.fourteenBitValue
        if midiValue < 8000 then
            hueShift = hueShift + increment
        else
            hueShift = hueShift - increment
        end

        updateUI()
    end
end

-- makeAbsoluteMixHandler() -> function
-- Function
-- Creates a 'handler' for Mix.
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeAbsoluteMixHandler()
    --------------------------------------------------------------------------------
    -- 0 to 1:
    --------------------------------------------------------------------------------
    local mixValue = 0
    local wheel = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            wheel:mix(mixValue)
            mixValue = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)
        local midiValue
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                mixValue = round(midiValue / 16383)
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                mixValue = midiValue / 127
            end
        end
        updateUI()
    end
end

-- makeRelativeAMixHandler() -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the MIDI control metadata table and process it.
local function makeRelativeAMixHandler()

    local mixShift = 0
    local wheel = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:mix()
            wheel:mix(current + mixShift)
            mixShift = 0
        else
            wheel:show()
        end
    end)

    return function(metadata)

        if optionPressed() then
            if wheel:isShowing() then
                wheel:mix(0)
                mixShift = 0
            else
                wheel:show()
            end
            return
        end

        local increment = (shiftPressed() and 0.001) or 0.01
        local midiValue = metadata.pitchChange or metadata.fourteenBitValue
        if midiValue < 8000 then
            mixShift = mixShift + increment
        else
            mixShift = mixShift - increment
        end

        updateUI()
    end
end

-- makeResetMixHandler() -> function
-- Function
-- Creates a 'handler' for resetting the Mix of a Color Wheel.
--
-- Parameters:
--  * None
--
-- Returns:
--  * a func
local function makeResetMixHandler()
    return function()
        local wheel = fcp.inspector.color.colorWheels
        wheel:show()
        wheel:mix(0)
    end
end

-- makeResetHueHandler() -> function
-- Function
-- Creates a 'handler' for resetting the Saturation of a Color Wheel.
--
-- Parameters:
--  * None
--
-- Returns:
--  * a func
local function makeResetHueHandler()
    return function()
        local wheel = fcp.inspector.color.colorWheels
        wheel:show()
        wheel:hue(0)
    end
end

-- makeResetTintHandler() -> function
-- Function
-- Creates a 'handler' for resetting the Saturation of a Color Wheel.
--
-- Parameters:
--  * None
--
-- Returns:
--  * a func
local function makeResetTintHandler()
    return function()
        local wheel = fcp.inspector.color.colorWheels
        wheel:show()
        wheel:tint(0)
    end
end

-- makeResetTemperatureHandler() -> function
-- Function
-- Creates a 'handler' for resetting the Saturation of a Color Wheel.
--
-- Parameters:
--  * None
--
-- Returns:
--  * a func
local function makeResetTemperatureHandler()
    return function()
        local wheel = fcp.inspector.color.colorWheels
        wheel:show()
        wheel:temperature(5000)
    end
end

-- makeResetSaturationHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for resetting the Saturation of a Color Wheel.
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to reset.
--
-- Returns:
--  * a func
local function makeResetSaturationHandler(wheelFinderFn)
    return function()
        local wheel = wheelFinderFn()
        wheel:show()
        wheel:saturationValue(1)
    end
end

-- makeResetBrightnessHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for resetting the Brightness of a Color Wheel.
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to reset.
--
-- Returns:
--  * a func
local function makeResetBrightnessHandler(wheelFinderFn)
    return function()
        local wheel = wheelFinderFn()
        wheel:show()
        wheel:brightnessValue(0)
    end
end

local plugin = {
    id              = "finalcutpro.midi.controls.colorwheels",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

function plugin.init(deps)

    local absolute      = i18n("absolute")
    local brightness    = i18n("brightness")
    local colorWheel    = i18n("colorWheel")
    local horizontal    = i18n("horizontal")
    local hue           = i18n("hue")
    local mix           = i18n("mix")
    local relativeA     = i18n("relativeA")
    local reset         = i18n("reset")
    local saturation    = i18n("saturation")
    local temperature   = i18n("temperature")
    local tint          = i18n("tint")
    local vertical      = i18n("vertical")

    local midiControlColorWheel = i18n("midiControlColorWheel")
    local holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset = i18n("holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset")

    local colourWheels = {
        { title = i18n("master"),       control = fcp.inspector.color.colorWheels.master,       id = "master" },
        { title = i18n("shadows"),      control = fcp.inspector.color.colorWheels.shadows,      id = "shadows" },
        { title = i18n("midtones"),     control = fcp.inspector.color.colorWheels.midtones,     id = "midtones" },
        { title = i18n("highlights"),   control = fcp.inspector.color.colorWheels.highlights,   id = "highlights" },
    }

    for _, v in pairs(colourWheels) do
        --------------------------------------------------------------------------------
        -- Color Wheel (Absolute):
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "Horizontal", {
            group = "fcpx",
            text = format("%s - %s - %s (%s)", colorWheel, v.title, horizontal, absolute),
            subText = midiControlColorWheel,
            fn = makeWheelHandler(function() return v.control end, false),
        })

        deps.manager.controls:new(v.id .. "Vertical", {
            group = "fcpx",
            text = format("%s - %s - %s (%s)", colorWheel, v.title, vertical, absolute),
            subText = midiControlColorWheel,
            fn = makeWheelHandler(function() return v.control end, true),
        })

        --------------------------------------------------------------------------------
        -- Color Wheel (Relative A):
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "HorizontalRelative", {
            group = "fcpx",
            text = format("%s - %s - %s (%s)", colorWheel, v.title, horizontal, relativeA),
            subText = holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset,
            fn = makeRelativeAWheelHandler(function() return v.control end, false),
        })

        deps.manager.controls:new(v.id .. "VerticalRelative", {
            group = "fcpx",
            text = format("%s - %s - %s (%s)", colorWheel, v.title, vertical, relativeA),
            subText = holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset,
            fn = makeRelativeAWheelHandler(function() return v.control end, true),
        })

        --------------------------------------------------------------------------------
        -- Color Wheel - Reset:
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "Reset", {
            group = "fcpx",
            text = format("%s - %s - %s", colorWheel, v.title, reset),
            subText = i18n("resetsAColorWheelUsingAMIDIDevice"),
            fn = makeResetColorWheelHandler(function() return v.control end),
        })

        --------------------------------------------------------------------------------
        -- Saturation (Absolute):
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "Saturation", {
            group = "fcpx",
            text = format("%s - %s - %s (%s)", colorWheel, v.title, saturation, absolute),
            subText = midiControlColorWheel,
            fn = makeAbsoluteSaturationHandler(function() return v.control end, true),
        })

        --------------------------------------------------------------------------------
        -- Saturation (Relative A):
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "SaturationRelativeA", {
            group = "fcpx",
            text = format("%s - %s - %s (%s)", colorWheel, v.title, saturation, relativeA),
            subText = holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset,
            fn = makeRelativeASaturationHandler(function() return v.control end, true),
        })

        --------------------------------------------------------------------------------
        -- Saturation - Reset:
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "SaturationReset", {
            group = "fcpx",
            text = format("%s - %s - %s - %s", colorWheel, v.title, saturation, reset),
            subText = i18n("resetsSaturationUsingAMIDIDevice"),
            fn = makeResetSaturationHandler(function() return v.control end),
        })

        --------------------------------------------------------------------------------
        -- Brightness (Absolute):
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "Brightness", {
            group = "fcpx",
            text = format("%s - %s - %s (%s)", colorWheel, v.title, brightness, absolute),
            subText = midiControlColorWheel,
            fn = makeAbsoluteBrightnessHandler(function() return v.control end, true),
        })

        --------------------------------------------------------------------------------
        -- Brightness (Relative A):
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "BrightnessRelativeA", {
            group = "fcpx",
            text = format("%s - %s - %s (%s)", colorWheel, v.title, brightness, relativeA),
            subText = holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset,
            fn = makeRelativeABrightnessHandler(function() return v.control end, true),
        })

        --------------------------------------------------------------------------------
        -- Brightness - Reset:
        --------------------------------------------------------------------------------
        deps.manager.controls:new(v.id .. "BrightnessReset", {
            group = "fcpx",
            text = format("%s - %s - %s - %s", colorWheel, v.title, brightness, reset),
            subText = i18n("resetsBrightnessUsingAMIDIDevice"),
            fn = makeResetBrightnessHandler(function() return v.control end),
        })
    end

    --------------------------------------------------------------------------------
    -- Color Wheel - Temperature:
    --------------------------------------------------------------------------------
        -- Absolute:
        deps.manager.controls:new("colorWheelTemperature", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, temperature, absolute),
            subText = midiControlColorWheel,
            fn = makeAbsoluteTemperatureHandler(),
        })

        -- Relative A:
        deps.manager.controls:new("colorWheelTemperatureRelativeA", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, temperature, relativeA),
            subText = holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset,
            fn = makeRelativeATemperatureHandler(),
        })

        -- Reset:
        deps.manager.controls:new("colorWheelTemperatureReset", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, temperature, reset),
            subText = i18n("resetsTemperatureUsingAMIDIDevice"),
            fn = makeResetTemperatureHandler(),
        })

    --------------------------------------------------------------------------------
    -- Color Wheel - Tint:
    --------------------------------------------------------------------------------
        -- Absolute:
        deps.manager.controls:new("colorWheelTint", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, tint, absolute),
            subText = midiControlColorWheel,
            fn = makeAbsoluteTintHandler(),
        })

        -- Relative A:
        deps.manager.controls:new("colorWheelTintRelativeA", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, tint, relativeA),
            subText = holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset,
            fn = makeRelativeATintHandler(),
        })

        -- Reset:
        deps.manager.controls:new("colorWheelTintReset", {
            group = "fcpx",
            text = format("%s - %s - %s", colorWheel, tint, reset),
            subText = i18n("resetsTintUsingAMIDIDevice"),
            fn = makeResetTintHandler(),
        })

    --------------------------------------------------------------------------------
    -- Color Wheel - Hue:
    --------------------------------------------------------------------------------
        -- Absolute:
        deps.manager.controls:new("colorWheelHue", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, hue, absolute),
            subText = midiControlColorWheel,
            fn = makeAbsoluteHueHandler(),
        })

        -- Relative A:
        deps.manager.controls:new("colorWheelHueRelativeA", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, hue, relativeA),
            subText = holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset,
            fn = makeRelativeAHueHandler(),
        })

        -- Reset:
        deps.manager.controls:new("colorWheelHueReset", {
            group = "fcpx",
            text = format("%s - %s - %s", colorWheel, hue, reset),
            subText = i18n("resetsHueUsingAMIDIDevice"),
            fn = makeResetHueHandler(),
        })

    --------------------------------------------------------------------------------
    -- Color Wheel - Mix:
    --------------------------------------------------------------------------------
        -- Absolute:
        deps.manager.controls:new("colorWheelMix", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, mix, absolute),
            subText = midiControlColorWheel,
            fn = makeAbsoluteMixHandler(),
        })

        -- Relative A:
        deps.manager.controls:new("colorWheelMixRelativeA", {
            group = "fcpx",
            text = format("%s - %s (%s)", colorWheel, mix, relativeA),
            subText = holdDownShiftToChangeValueAtSmallerIncrementsAndOptionToReset,
            fn = makeRelativeAMixHandler(),
        })

        -- Reset:
        deps.manager.controls:new("colorWheelMixReset", {
            group = "fcpx",
            text = format("%s - %s - %s", colorWheel, mix, reset),
            subText = i18n("resetsMixUsingAMIDIDevice"),
            fn = makeResetMixHandler(),
        })
end

return plugin
