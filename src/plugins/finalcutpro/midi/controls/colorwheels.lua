--- === plugins.finalcutpro.midi.controls.colorwheels ===
---
--- Final Cut Pro MIDI Color Controls.

local require = require

local log               = require("hs.logger").new("colorMIDI")

local eventtap          = require("hs.eventtap")
local inspect           = require("hs.inspect")

local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- shiftPressed() -> boolean
-- Function
-- Is the Shift Key being pressed?
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if the shift key is being pressed, otherwise `false`.
local function shiftPressed()
    --------------------------------------------------------------------------------
    -- Check for keyboard modifiers:
    --------------------------------------------------------------------------------
    local mods = eventtap.checkKeyboardModifiers()
    local result = false
    if mods['shift'] and not mods['cmd'] and not mods['alt'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
        result = true
    end
    return result
end

--------------------------------------------------------------------------------
-- MIDI Controller Value (7bit):   0 to 127
-- MIDI Controller Value (14bit):  0 to 16383
--
-- Percentage Slider:           -100 to 100
-- Angle Slider:                   0 to 360 (359 in Final Cut Pro 10.4)
--
-- Wheel Color Orientation          -1 to 1
--------------------------------------------------------------------------------

-- MAX_14BIT -> number
-- Constant
-- Maximum 14bit Limit (16383)
local MAX_14BIT = 0x3FFF

-- MAX_7BIT -> number
-- Constant
-- Maximum 7bit Limit (127)
local MAX_7BIT  = 0x7F

-- UNSHIFTED_SCALE -> number
-- Constant
-- Scale unshifted 7-bit by 20%
local UNSHIFTED_SCALE = 20/100

-- makeWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
-- * puckFinderFn   - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
-- * a function that will receive the MIDI control metadata table and process it.
local function makeWheelHandler(wheelFinderFn, vertical)
    return function(metadata)

        local midiValue, value
        local wheel = wheelFinderFn()

        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                value = (midiValue / MAX_14BIT) * 2 - 1
                if midiValue == 16383/2 then value = 0 end
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
                    if midiValue == 128/2 then value = 0 end
                end
            end
        end
        if value == nil then
            log.ef("Unexpected MIDI value of type '%s': %s", type(midiValue), inspect(midiValue))
        end

        local current = wheel:colorOrientation()
        if current then
            if vertical then
                wheel:colorOrientation({right=current.right,up=value})
            else
                wheel:colorOrientation({right=value,up=current.up})
            end
        end
    end
end

--- plugins.finalcutpro.midi.controls.colorwheels.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps)

    --------------------------------------------------------------------------------
    -- MIDI Controller Value (7bit):   0 to 127
    -- MIDI Controller Value (14bit):  0 to 16383
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Color Wheels (-1 to 1):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("masterHorizontal", {
        group = "fcpx",
        text = "MIDI: Color Wheel Master (Horizontal)",
        subText = i18n("midiControlColorWheel"),
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():show():master() end, false),
    })

    deps.manager.controls:new("masterVertical", {
        group = "fcpx",
        text = "MIDI: Color Wheel Master (Vertical)",
        subText = i18n("midiControlColorWheel"),
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():show():master() end, true),
    })

    deps.manager.controls:new("shadowsHorizontal", {
        group = "fcpx",
        text = "MIDI: Color Wheel Shadows (Horizontal)",
        subText = i18n("midiControlColorWheel"),
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():show():shadows() end, false),
    })

    deps.manager.controls:new("shadowsVertical", {
        group = "fcpx",
        text = "MIDI: Color Wheel Shadows (Vertical)",
        subText = i18n("midiControlColorWheel"),
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():show():shadows() end, true),
    })

    deps.manager.controls:new("midtonesHorizontal", {
        group = "fcpx",
        text = "MIDI: Color Wheel Midtones (Horizontal)",
        subText = i18n("midiControlColorWheel"),
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():show():midtones() end, false),
    })

    deps.manager.controls:new("midtonesVertical", {
        group = "fcpx",
        text = "MIDI: Color Wheel Midtones (Vertical)",
        subText = i18n("midiControlColorWheel"),
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():show():midtones() end, true),
    })

    deps.manager.controls:new("highlightsHorizontal", {
        group = "fcpx",
        text = "MIDI: Color Wheel Highlights (Horizontal)",
        subText = i18n("midiControlColorWheel"),
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():show():highlights() end, false),
    })

    deps.manager.controls:new("highlightsVertical", {
        group = "fcpx",
        text = "MIDI: Color Wheel Highlights (Vertical)",
        subText = i18n("midiControlColorWheel"),
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():show():highlights() end, true),
    })

    --------------------------------------------------------------------------------
    -- Color Wheel Saturation:
    --------------------------------------------------------------------------------
    deps.manager.controls:new("colorWheelMasterSaturation", {
        group = "fcpx",
        text = "MIDI: Color Wheel Master Saturation",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383*2)
                    if midiValue == 16383/2 then value = 1 end
                    fcp:inspector():color():colorWheels():master():show():saturationValue(value)
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
                    if midiValue == 128/2 then value = 1 end
                    fcp:inspector():color():colorWheels():master():show():saturationValue(value)
                end
            end
        end,
    })

    deps.manager.controls:new("colorWheelShadowsSaturation", {
        group = "fcpx",
        text = "MIDI: Color Wheel Shadows Saturation",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383*2)
                    if midiValue == 16383/2 then value = 1 end
                    fcp:inspector():color():colorWheels():shadows():show():saturationValue(value)
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
                    if midiValue == 128/2 then value = 1 end
                    fcp:inspector():color():colorWheels():shadows():show():saturationValue(value)
                end
            end
        end,
    })

    deps.manager.controls:new("colorWheelMidtonesSaturation", {
        group = "fcpx",
        text = "MIDI: Color Wheel Midtones Saturation",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383*2)
                    if midiValue == 16383/2 then value = 1 end
                    fcp:inspector():color():colorWheels():midtones():show():saturationValue(value)
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
                    if midiValue == 128/2 then value = 1 end
                    fcp:inspector():color():colorWheels():midtones():show():saturationValue(value)
                end
            end
        end,
    })

    deps.manager.controls:new("colorWheelHighlightsSaturation", {
        group = "fcpx",
        text = "MIDI: Color Wheel Highlights Saturation",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383*2)
                    if midiValue == 16383/2 then value = 1 end
                    fcp:inspector():color():colorWheels():highlights():show():saturationValue(value)
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
                    if midiValue == 128/2 then value = 1 end
                    fcp:inspector():color():colorWheels():highlights():show():saturationValue(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Color Wheel Brightness (-0.4 to 0.4):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("colorWheelMasterBrightness", {
        group = "fcpx",
        text = "MIDI: Color Wheel Master Brightness",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383* 0.8 - 0.4)
                    if midiValue == 16383/2 then value = 0 end
                    fcp:inspector():color():colorWheels():master():show():brightnessValue(value)
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
                    if midiValue == 128/2 then value = 0 end
                    fcp:inspector():color():colorWheels():master():show():brightnessValue(value)
                end
            end
        end,
    })

    deps.manager.controls:new("colorWheelShadowsBrightness", {
        group = "fcpx",
        text = "MIDI: Color Wheel Shadows Brightness",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383* 0.8 - 0.4)
                    if midiValue == 16383/2 then value = 0 end
                    fcp:inspector():color():colorWheels():shadows():show():brightnessValue(value)
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
                    if midiValue == 128/2 then value = 0 end
                    fcp:inspector():color():colorWheels():shadows():show():brightnessValue(value)
                end
            end
        end,
    })

    deps.manager.controls:new("colorWheelHighlightsBrightness", {
        group = "fcpx",
        text = "MIDI: Color Wheel Highlights Brightness",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383* 0.8 - 0.4)
                    if midiValue == 16383/2 then value = 0 end
                    fcp:inspector():color():colorWheels():highlights():show():brightnessValue(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 0.8 - 0.4
                    else
                        value = midiValue / 127 * 0.8 - 0.4
                    end
                    if midiValue == 128/2 then value = 0 end
                    fcp:inspector():color():colorWheels():highlights():show():brightnessValue(value)
                end
            end
        end,
    })

    deps.manager.controls:new("colorWheelMidtonesBrightness", {
        group = "fcpx",
        text = "MIDI: Color Wheel Midtones Brightness",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383* 0.8 - 0.4)
                    if midiValue == 16383/2 then value = 0 end
                    fcp:inspector():color():colorWheels():midtones():show():brightnessValue(value)
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
                    if midiValue == 128/2 then value = 0 end
                    fcp:inspector():color():colorWheels():midtones():show():brightnessValue(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Color Wheel Temperature (2500 to 10000):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("colorWheelTemperature", {
        group = "fcpx",
        text = "MIDI: Color Wheel Temperature",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383 * (10000-2500) + 2500)
                    fcp:inspector():color():colorWheels():show():temperature(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 127 * (10000-2500) + 2500)
                    fcp:inspector():color():colorWheels():show():temperature(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Color Wheel Tint (-50 to 50):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("colorWheelTint", {
        group = "fcpx",
        text = "MIDI: Color Wheel Tint",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383 * (50*2) - 50)
                    if midiValue == 16383/2 then value = 0 end
                    fcp:inspector():color():colorWheels():show():tint(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 127 * (50*2) - 50)
                    fcp:inspector():color():colorWheels():show():tint(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Color Wheel Hue (0 to 360):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("colorWheelHue", {
        group = "fcpx",
        text = "MIDI: Color Wheel Hue",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383 * 360)
                    if midiValue == 16383/2 then value = 0 end
                    fcp:inspector():color():colorWheels():show():hue(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 127 * 360)
                    fcp:inspector():color():colorWheels():show():hue(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Color Wheel Mix (0 to 1):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("colorWheelMix", {
        group = "fcpx",
        text = "MIDI: Color Wheel Mix",
        subText = i18n("midiControlColorWheel"),
        fn = function(metadata)
            local midiValue
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local value = tools.round(midiValue / 16383)
                    fcp:inspector():color():colorWheels():show():mix(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value = midiValue / 127
                    fcp:inspector():color():colorWheels():show():mix(value)
                end
            end
        end,
    })

    return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.midi.controls.colorwheels",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

function plugin.init(deps)
    return mod.init(deps)
end

return plugin
