--- === plugins.finalcutpro.midi.controls.video ===
---
--- Final Cut Pro MIDI Video Inspector Controls.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log             = require("hs.logger").new("videoMIDI")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap          = require("hs.eventtap")
--local inspect           = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
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

--- plugins.finalcutpro.midi.controls.video.init() -> nil
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
    -- Scale X (0 to 400):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("transformScaleX", {
        group = "fcpx",
        text = "MIDI: Transform - Scale X",
        subText = i18n("midiVideoInspector"),
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
                    local value = tools.round(midiValue / 16383 * 400)
                    fcp:inspector():video():show():transform():scaleX():value(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 400
                    else
                        value = midiValue
                    end
                    fcp:inspector():video():show():transform():scaleX():value(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Scale Y (0 to 400):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("transformScaleY", {
        group = "fcpx",
        text = "MIDI: Transform - Scale Y",
        subText = i18n("midiVideoInspector"),
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
                    local value = tools.round(midiValue / 16383 * 400)
                    fcp:inspector():video():show():transform():scaleY():value(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 400
                    else
                        value = midiValue
                    end
                    fcp:inspector():video():show():transform():scaleY():value(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Scale All (0 to 400):
    --------------------------------------------------------------------------------
    deps.manager.controls:new("transformScaleAll", {
        group = "fcpx",
        text = "MIDI: Transform - Scale All",
        subText = i18n("midiVideoInspector"),
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
                    local value = tools.round(midiValue / 16383 * 400)
                    fcp:inspector():video():show():transform():scaleAll():value(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 400
                    else
                        value = midiValue
                    end
                    fcp:inspector():video():show():transform():scaleAll():value(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Position X:
    --------------------------------------------------------------------------------
    deps.manager.controls:new("transformPositionX", {
        group = "fcpx",
        text = "MIDI: Transform - Position X",
        subText = i18n("midiVideoInspector"),
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
                    local value = tools.round(midiValue / 16383 * 400)
                    fcp:inspector():video():show():transform():position().x:value(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 400
                    else
                        value = midiValue
                    end
                    fcp:inspector():video():show():transform():position().x:value(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Position Y:
    --------------------------------------------------------------------------------
    deps.manager.controls:new("transformPositionY", {
        group = "fcpx",
        text = "MIDI: Transform - Position Y",
        subText = i18n("midiVideoInspector"),
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
                    local value = tools.round(midiValue / 16383 * 400)
                    fcp:inspector():video():show():transform():position().y:value(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 400
                    else
                        value = midiValue
                    end
                    fcp:inspector():video():show():transform():position().y:value(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Rotation:
    --------------------------------------------------------------------------------
    deps.manager.controls:new("transformRotation", {
        group = "fcpx",
        text = "MIDI: Transform - Rotation",
        subText = i18n("midiVideoInspector"),
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
                    local value = tools.round(midiValue / 16383 * 400)
                    fcp:inspector():video():show():transform():rotation():value(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 400
                    else
                        value = midiValue
                    end
                    fcp:inspector():video():show():transform():rotation():value(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Anchor Y:
    --------------------------------------------------------------------------------
    deps.manager.controls:new("transformAnchorX", {
        group = "fcpx",
        text = "MIDI: Transform - Anchor X",
        subText = i18n("midiVideoInspector"),
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
                    local value = tools.round(midiValue / 16383 * 400)
                    fcp:inspector():video():show():transform():anchor().x:value(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 400
                    else
                        value = midiValue
                    end
                    fcp:inspector():video():show():transform():anchor().x:value(value)
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Anchor X:
    --------------------------------------------------------------------------------
    deps.manager.controls:new("transformAnchorY", {
        group = "fcpx",
        text = "MIDI: Transform - Anchor Y",
        subText = i18n("midiVideoInspector"),
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
                    local value = tools.round(midiValue / 16383 * 400)
                    fcp:inspector():video():show():transform():anchor().y:value(value)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    local value
                    if shiftPressed() then
                        value = midiValue / 127 * 400
                    else
                        value = midiValue
                    end
                    fcp:inspector():video():show():transform():anchor().y:value(value)
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
    id              = "finalcutpro.midi.controls.video",
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
