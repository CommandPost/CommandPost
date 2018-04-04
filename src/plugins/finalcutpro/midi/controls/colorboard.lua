--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       M I D I    C O N T R O L S                           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.midi.controls.colorboard ===
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
local log               = require("hs.logger").new("cbMIDI")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap          = require("hs.eventtap")
local inspect           = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local tools             = require("cp.tools")

local fcp               = require("cp.apple.finalcutpro")
local ColorBoardAspect	= require("cp.apple.finalcutpro.inspector.color.ColorBoardAspect")

local round             = tools.round
local upper, format     = string.upper, string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.finalcutpro.midi.controls.colorboard._colorBoard -> colorBoard
-- Variable
-- Color Board object.
mod._colorBoard = fcp:colorBoard()

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
--------------------------------------------------------------------------------

local MAX_14BIT = 0x3FFF    -- 16383
local MAX_7BIT  = 0x7F      -- 127

local PERCENTAGE_SCALE  = 128/200   -- scale unshifted 7-bit
local ANGLE_SCALE       = 128/360   -- scale angle on 7-bit

-- makePercentHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for percent controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
-- * puckFinderFn   - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
-- * a function that will receive the MIDI control metadata table and process it.
local function makePercentHandler(puckFinderFn)
    return function(metadata)
        local midiValue, value
        local puck = puckFinderFn()
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                value = (midiValue / MAX_14BIT) * 200 - 100
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                value = (midiValue / MAX_7BIT) * 200 - 100
                if not shiftPressed() then
                    value = value * PERCENTAGE_SCALE
                end
            end
        end
        if value == nil then
            log.ef("Unexpected MIDI value of type '%s': %s", type(midiValue), inspect(midiValue))
        end
        -- set the value
        puck:select():percent(value)
    end
end

-- makeAngleHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for angle controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
-- * puckFinderFn   - a function that will return the `ColorPuck` to apply the angle value to.
--
-- Returns:
-- * a function that will receive the MIDI control metadata table and process it.
local function makeAngleHandler(puckFinderFn)
    return function(metadata)
        local midiValue, value
        local puck = puckFinderFn()
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                value = (midiValue / MAX_14BIT) * 359
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                value = (midiValue / MAX_7BIT) * 359
                if not not shiftPressed() then
                    value = value * ANGLE_SCALE
                end
            end
        end
        if value == nil then
            log.ef("Unexpected MIDI value of type '%s': %s", type(midiValue), inspect(midiValue))
        end
        puck:select():angle(value)
    end
end

--- plugins.finalcutpro.midi.controls.colorboard.init() -> nil
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
    -- Percentage Slider:           -100 to 100
    -- Angle Slider:                   0 to 360 (359 in Final Cut Pro 10.4)
    --------------------------------------------------------------------------------

    local colorBoard = fcp:colorBoard()

    local colorBoardAspects = {
        { title = i18n("color"), control = colorBoard:color(), hasAngle = true },
        { title = i18n("saturation"), control = colorBoard:saturation() },
        { title = i18n("exposure"), control = colorBoard:exposure() },
    }

    local pucks = {
        { title = "Master", fn = ColorBoardAspect.master, shortcut = "m" },
        { title = "Shadows", fn = ColorBoardAspect.shadows, shortcut = "," },
        { title = "Midtones", fn = ColorBoardAspect.midtones, shortcut = "." },
        { title = "Highlights", fn = ColorBoardAspect.highlights, shortcut = "/" },
    }

    local midiText, colorBoardText, puckText, descriptionText = upper(i18n("midi")), i18n("colorBoard"), i18n("puck"), i18n("midiColorBoardDescription")
    local angleText, percentageText, colorText = i18n("angle"), i18n("percentage"), i18n("color")

    for i,puck in ipairs(pucks) do
        local puckNumber = tools.numberToWord(i)
        --------------------------------------------------------------------------------
        -- Current Pucks:
        --------------------------------------------------------------------------------
        deps.manager.controls:new("puck" .. puckNumber, {
            group = "fcpx",
            text = format("%s: %s %s %s", midiText, colorBoardText, puckText, i),
            subText = descriptionText,
            fn = makePercentHandler(function() return puck.fn( colorBoard:current() ) end),
        })

        --------------------------------------------------------------------------------
        -- Angle (Color only)
        --------------------------------------------------------------------------------
        deps.manager.controls:new("colorAnglePuck" .. puckNumber, {
            group = "fcpx",
            text = format("%s: %s %s %s %s (%s)", midiText, colorBoardText, colorText, puckText, i, angleText),
            subText = descriptionText,
            fn = makeAngleHandler(function() return puck.fn( colorBoard:color() ) end),
        })

        --------------------------------------------------------------------------------
        -- Percentages:
        --------------------------------------------------------------------------------
        for _,aspect in ipairs(colorBoardAspects) do
            local colorPanel = aspect.control:id()
            deps.manager.controls:new(colorPanel .. "PercentagePuck" .. puckNumber, {
                group = "fcpx",
                text = format("%s: %s %s %s %s (%s)", midiText, colorBoardText, aspect.title, puckText, i, percentageText ),
                subText = descriptionText,
                fn = makePercentHandler(function() return aspect.control end),
            })
        end
    end
    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.midi.controls.color",
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
