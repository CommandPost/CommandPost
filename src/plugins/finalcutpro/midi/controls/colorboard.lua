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
local log				= require("hs.logger").new("cbMIDI")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap          = require("hs.eventtap")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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

    --  * aspect - "color", "saturation" or "exposure"
    --  * property - "global", "shadows", "midtones", "highlights"

    local colorFunction = {
        [1] = "global",
        [2] = "shadows",
        [3] = "midtones",
        [4] = "highlights",
    }

    for i=1, 4 do

        --------------------------------------------------------------------------------
        -- Current Puck:
        --------------------------------------------------------------------------------
        deps.manager.controls:new("puck" .. tools.numberToWord(i), {
            group = "fcpx",
            text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("puck") .. " " .. tostring(i),
            subText = i18n("midiColorBoardDescription"),
            fn = function(metadata)
                local midiValue
                if metadata.fourteenBitCommand or metadata.pitchChange or shiftPressed() then
                    --------------------------------------------------------------------------------
                    -- 14bit:
                    --------------------------------------------------------------------------------
                    if metadata.pitchChange then
                        midiValue = metadata.pitchChange
                    else
                        midiValue = metadata.fourteenBitValue
                    end
                    if type(midiValue) == "number" then
                        local colorBoard = fcp:colorBoard()
                        if colorBoard then
                            local value = tools.round(midiValue / 16383*200-100)
                            if midiValue == 16383/2 then value = 0 end
                            colorBoard:show():applyPercentage("*", colorFunction[i], value)
                        end
                    else
                        log.ef("Unexpected type: %s", type(midiValue))
                    end
                else
                    --------------------------------------------------------------------------------
                    -- 7bit:
                    --------------------------------------------------------------------------------
                    midiValue = metadata.controllerValue
                    if type(midiValue) == "number" then
                        local colorBoard = fcp:colorBoard()
                        if colorBoard then
                            local value = tools.round(midiValue / 127*127-(127/2))
                            if midiValue == 127/2 then value = 0 end
                            colorBoard:show():applyPercentage("*", colorFunction[i], value)
                        end
                    else
                        log.ef("Unexpected type: %s", type(midiValue))
                    end
                end
            end,
        })

        --------------------------------------------------------------------------------
        -- Color (Percentage):
        --------------------------------------------------------------------------------
        deps.manager.controls:new("colorPercentagePuck" .. tools.numberToWord(i), {
            group = "fcpx",
            text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("color") .. " " .. i18n("puck") .. " " .. tostring(i) .. " (" .. i18n("percentage") .. ")",
            subText = i18n("midiColorBoardDescription"),
            fn = function(metadata)
                local midiValue
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local colorBoard = fcp:colorBoard()
                    if colorBoard then
                        local value = tools.round(midiValue / 16383*200-100)
                        if metadata.fourteenBitValue == 16383/2 then value = 0 end
                        colorBoard:show():applyPercentage("color", colorFunction[i], value)
                    end
                else
                    log.ef("Unexpected type: %s", type(midiValue))
                end
            end,
        })

        --------------------------------------------------------------------------------
        -- Color (Angle):
        --------------------------------------------------------------------------------
        deps.manager.controls:new("colorAnglePuck" .. tools.numberToWord(i), {
            group = "fcpx",
            text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("color") .. " " .. i18n("puck") .. " " .. tostring(i) .. " (" .. i18n("angle") .. ")",
            subText = i18n("midiColorBoardDescription"),
            fn = function(metadata)
                local midiValue
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local colorBoard = fcp:colorBoard()
                    if colorBoard then
                        local angle = 360
                        if fcp.isColorInspectorSupported() then
                            angle = 359
                        end
                        local value = tools.round(midiValue / (16383/angle))
                        if metadata.fourteenBitValue == 16383/2 then value = angle/2 end
                        colorBoard:show():applyAngle("color", colorFunction[i], value)
                    end
                else
                    log.ef("Unexpected type: %s", type(midiValue))
                end
            end,
        })

        --------------------------------------------------------------------------------
        -- Saturation:
        --------------------------------------------------------------------------------
        deps.manager.controls:new("saturationPuck" .. tools.numberToWord(i), {
            group = "fcpx",
            text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("saturation") .. " " .. i18n("puck") .. " " .. tostring(i),
            subText = i18n("midiColorBoardDescription"),
            fn = function(metadata)
                local midiValue
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local colorBoard = fcp:colorBoard()
                    if colorBoard then
                        local value = tools.round(midiValue / 16383*200-100)
                        if metadata.fourteenBitValue == 16383/2 then value = 0 end
                        colorBoard:show():applyPercentage("saturation", colorFunction[i], value)
                    end
                else
                    log.ef("Unexpected type: %s", type(midiValue))
                end
            end,
        })

        --------------------------------------------------------------------------------
        -- Exposure:
        --------------------------------------------------------------------------------
        deps.manager.controls:new("exposurePuck" .. tools.numberToWord(i), {
            group = "fcpx",
            text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("exposure") .. " " .. i18n("puck") .. " " .. tostring(i),
            subText = i18n("midiColorBoardDescription"),
            fn = function(metadata)
                local midiValue
                if metadata.pitchChange then
                    midiValue = metadata.pitchChange
                else
                    midiValue = metadata.fourteenBitValue
                end
                if type(midiValue) == "number" then
                    local colorBoard = fcp:colorBoard()
                    if colorBoard then
                        local value = tools.round(midiValue / 16383*200-100)
                        if metadata.fourteenBitValue == 16383/2 then value = 0 end
                        colorBoard:show():applyPercentage("exposure", colorFunction[i], value)
                    end
                else
                    log.ef("Unexpected type: %s", type(midiValue))
                end
            end,
        })

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