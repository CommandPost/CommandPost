--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       M I D I    C O N T R O L S                           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.midi.controls.colorwheels ===
---
--- Final Cut Pro MIDI Color Controls.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log             = require("hs.logger").new("colorMIDI")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap          = require("hs.eventtap")
local inspect           = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local round             = tools.round
local upper, format     = string.upper, string.format

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

local MAX_14BIT = 0x3FFF    -- 16383
local MAX_7BIT  = 0x7F      -- 127

local UNSHIFTED_SCALE = 0.5 -- scale unshifted 7-bit by 50%


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

        --log.df("Doing stuff: %s", hs.inspect(metadata))

        log.df("-----------------------")

        local midiValue, value
        local wheel = wheelFinderFn()

        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            log.df("14bit")
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                value = (midiValue / MAX_14BIT) * 2 - 1
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            log.df("7bit")
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                value = (midiValue / MAX_7BIT) * 2 - 1
                if not shiftPressed() then -- scale it down
                    value = value * UNSHIFTED_SCALE
                end
            end
        end
        if value == nil then
            log.ef("Unexpected MIDI value of type '%s': %s", type(midiValue), inspect(midiValue))
        end

        log.df("value: %s", value)

        local current = wheel:colorOrientation()
        if current then
            if vertical then
                log.df("vertical: %s", wheel:colorOrientation())
                wheel:colorOrientation({right=current.right,up=value})
            else
                log.df("horizontal")
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

    deps.manager.controls:new("masterHorizontal", {
        group = "fcpx",
        text = "Color Wheel: Master (Horizontal)",
        subText = "Controls the Final Cut Pro Color Wheel via a MIDI Knob or Slider",
        fn = makeWheelHandler(function() return fcp:inspector():color():colorWheels():master() end, false),
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

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return mod.init(deps)
end

return plugin