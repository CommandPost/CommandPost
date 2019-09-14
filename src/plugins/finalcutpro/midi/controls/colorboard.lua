--- === plugins.finalcutpro.midi.controls.colorboard ===
---
--- Final Cut Pro MIDI Color Controls.

local require = require

local log               = require "hs.logger".new "cbMIDI"

local eventtap          = require "hs.eventtap"
local inspect           = require "hs.inspect"

local fcp               = require "cp.apple.finalcutpro"
local tools             = require "cp.tools"
local i18n              = require "cp.i18n"
local deferred          = require "cp.deferred"

local upper, format     = string.upper, string.format

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
    local value
    local updateUI = deferred.new(0.01):action(function()
        local puck = puckFinderFn()
        puck:show():percent(value)
    end)
    return function(metadata)
        local midiValue
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if type(midiValue) == "number" then
                value = tools.round(midiValue / 16383*200-100)
                if midiValue == 16383/2 then value = 0 end
            end
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            midiValue = metadata.controllerValue
            if type(midiValue) == "number" then
                if shiftPressed() then
                    value = midiValue / 128*202-100
                else
                    value = midiValue / 128*128-(128/2)
                end
                if midiValue == 127/2 then value = 0 end
            end
        end
        if value == nil then
            log.ef("Unexpected MIDI value of type '%s': %s", type(midiValue), inspect(midiValue))
            return
        end
        updateUI()
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
    local value
    local updateUI = deferred.new(0.01):action(function()
        local puck = puckFinderFn()
        puck:show():angle(value)
    end)
    return function(metadata)
        local midiValue
        --------------------------------------------------------------------------------
        -- 7bit & 14bit:
        --------------------------------------------------------------------------------
        if metadata.pitchChange then
            midiValue = metadata.pitchChange
        else
            midiValue = metadata.fourteenBitValue
        end
        if metadata.fourteenBitCommand then
            value = midiValue / 16383*359
        else
            value = midiValue / 16383*362
        end
        if midiValue == 16383/2 then value = 0 end
        if value == nil then
            log.ef("Unexpected MIDI value of type '%s': %s", type(midiValue), inspect(midiValue))
            return
        end
        updateUI()
    end
end

local plugin = {
    id              = "finalcutpro.midi.controls.color",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

function plugin.init(deps)

    local colorBoard = fcp:colorBoard()

    local colorBoardAspects = {
        { title = i18n("color"),        control = colorBoard:color(),          hasAngle = true },
        { title = i18n("saturation"),   control = colorBoard:saturation()      },
        { title = i18n("exposure"),     control = colorBoard:exposure()        },
    }

    local pucks = {
        { title = "Master",             id = "master"        },
        { title = "Shadows",            id = "shadows"       },
        { title = "Midtones",           id = "midtones"      },
        { title = "Highlights",         id = "highlights"    },
    }

    local colorBoardText, puckText, descriptionText = i18n("colorBoard"), i18n("puck"), i18n("midiColorBoardDescription")
    local angleText, percentageText, colorText = i18n("angle"), i18n("percentage"), i18n("color")

    for i,puck in ipairs(pucks) do
        local puckNumber = tools.numberToWord(i)
        --------------------------------------------------------------------------------
        -- Current Pucks:
        --------------------------------------------------------------------------------
        deps.manager.controls:new("puck" .. puckNumber, {
            group = "fcpx",
            text = format("%s %s %s", colorBoardText, puckText, i),
            subText = descriptionText,
            fn = makePercentHandler(function() return colorBoard:current()[puck.id]() end),
        })

        --------------------------------------------------------------------------------
        -- Angle (Color only)
        --------------------------------------------------------------------------------
        deps.manager.controls:new("colorAnglePuck" .. puckNumber, {
            group = "fcpx",
            text = format("%s %s %s %s (%s)", colorBoardText, colorText, puckText, i, angleText),
            subText = descriptionText,
            fn = makeAngleHandler(function() return colorBoard:color()[puck.id]() end),
        })

        --------------------------------------------------------------------------------
        -- Percentages:
        --------------------------------------------------------------------------------
        for _,aspect in ipairs(colorBoardAspects) do
            local colorPanel = aspect.control:id()
            deps.manager.controls:new(colorPanel .. "PercentagePuck" .. puckNumber, {
                group = "fcpx",
                text = format("%s %s %s %s (%s)", colorBoardText, aspect.title, puckText, i, percentageText ),
                subText = descriptionText,
                fn = makePercentHandler(function() return aspect.control[puck.id]() end),
            })
        end
    end

end

return plugin
