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

mod._colorBoard = fcp:colorBoard()

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

    local colorPanels = {
        [1] = "exposure",
        [2] = "saturation",
        [3] = "color",
    }

    for i=1, 4 do

        --------------------------------------------------------------------------------
        -- Current Pucks:
        --------------------------------------------------------------------------------
        deps.manager.controls:new("puck" .. tools.numberToWord(i), {
            group = "fcpx",
            text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("puck") .. " " .. tostring(i),
            subText = i18n("midiColorBoardDescription"),
            fn = function(metadata)
                local midiValue
                mod._colorBoard:show()
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
                        if mod._colorBoard then
                            local value = tools.round(midiValue / 16383*200-100)
                            if midiValue == 16383/2 then value = 0 end
                            mod._colorBoard:applyPercentage("*", colorFunction[i], value)
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
                        if mod._colorBoard then
                            local value = tools.round(midiValue / 127*127-(127/2))
                            if midiValue == 127/2 then value = 0 end
                            mod._colorBoard:applyPercentage("*", colorFunction[i], value)
                        end
                    else
                        log.ef("Unexpected type: %s", type(midiValue))
                    end
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
                mod._colorBoard:show()

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
                        if mod._colorBoard then
                            local value = tools.round(midiValue / 16383*200-100)
                            if midiValue == 16383/2 then value = 0 end
                            mod._colorBoard:applyAngle("color", colorFunction[i], value)
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
                        if mod._colorBoard then
                            local value = tools.round(midiValue / 127*127-(127/2))
                            if midiValue == 127/2 then value = 0 end
                            mod._colorBoard:applyAngle("color", colorFunction[i], value)
                        end
                    else
                        log.ef("Unexpected type: %s", type(midiValue))
                    end
                end
            end,
        })

        for whichPanel=1, 3 do

            --------------------------------------------------------------------------------
            -- Percentage:
            --------------------------------------------------------------------------------
            local colorPanel = colorPanels[whichPanel]
            deps.manager.controls:new(colorPanel .. "PercentagePuck" .. tools.numberToWord(i), {
                group = "fcpx",
                text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n(colorPanel) .. " " .. i18n("puck") .. " " .. tostring(i) .. " (" .. i18n("percentage") .. ")",
                subText = i18n("midiColorBoardDescription"),
                fn = function(metadata)
                    local midiValue
                    mod._colorBoard:show()
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
                        if mod._colorBoard then
                            local value = tools.round(midiValue / 16383*200-100)
                            if midiValue == 16383/2 then value = 0 end
                            mod._colorBoard:applyPercentage(colorPanel, colorFunction[i], value)
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
                        if mod._colorBoard then
                            local value = tools.round(midiValue / 127*127-(127/2))
                            if midiValue == 127/2 then value = 0 end
                            mod._colorBoard:applyPercentage(colorPanel, colorFunction[i], value)
                        end
                    else
                        log.ef("Unexpected type: %s", type(midiValue))
                    end
                end
                end,
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