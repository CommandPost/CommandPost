--- === plugins.finalcutpro.midi.controls.video ===
---
--- Final Cut Pro MIDI Video Inspector Controls.

local require = require

local eventtap          = require "hs.eventtap"

local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local rescale           = tools.rescale

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

local function createAbsoluteMIDISlider(param, min, max)
    local value
    local updateUI = deferred.new(0.01):action(function()
        param:value(value)
    end)
    return function(metadata)
        value = metadata.pitchChange or metadata.fourteenBitValue
        value = rescale(value, 0, 16383, min, max) + 1
        updateUI()
    end
end

local plugin = {
    id              = "finalcutpro.midi.controls.video",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

function plugin.init(deps)

    local manager = deps.manager

    --------------------------------------------------------------------------------
    -- Opacity:
    --------------------------------------------------------------------------------
    manager.controls:new("opacity", {
        group = "fcpx",
        text = "Opacity (Absolute)",
        subText = "Controls the opacity.",
        fn = createAbsoluteMIDISlider(fcp:inspector():video():compositing():opacity(), 0, 100),
    })

    --------------------------------------------------------------------------------
    -- Scale X (0 to 400):
    --------------------------------------------------------------------------------
    local cachedTransformScaleX
    local updateTransformScaleX = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():scaleX():value(cachedTransformScaleX)
    end)
    manager.controls:new("transformScaleX", {
        group = "fcpx",
        text = "Transform - Scale X (Absolute)",
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
                    cachedTransformScaleX = value
                    updateTransformScaleX()
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
                    cachedTransformScaleX = value
                    updateTransformScaleX()
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Scale Y (0 to 400):
    --------------------------------------------------------------------------------
    local cachedTransformScaleY
    local updateTransformScaleY = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():scaleY():value(cachedTransformScaleY)
    end)
    manager.controls:new("transformScaleY", {
        group = "fcpx",
        text = "Transform - Scale Y (Absolute)",
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
                    cachedTransformScaleY = value
                    updateTransformScaleY()
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
                    cachedTransformScaleY = value
                    updateTransformScaleY()


                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Scale All (0 to 400):
    --------------------------------------------------------------------------------
    local cachedScaleUI
    local updateScaleAllUI = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():scaleAll():value(cachedScaleUI)
    end)
    manager.controls:new("transformScaleAll", {
        group = "fcpx",
        text = "Transform - Scale All (Absolute)",
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
                cachedScaleUI = tools.round(midiValue / 16383 * 400)
                updateScaleAllUI()
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
                    cachedScaleUI = value
                    updateScaleAllUI()
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Position X:
    --------------------------------------------------------------------------------
    local cachedTransformPositionX
    local updateTransformPositionX = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():position().x:value(cachedTransformPositionX)
    end)
    manager.controls:new("transformPositionX", {
        group = "fcpx",
        text = "Transform - Position X (Absolute)",
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
                    cachedTransformPositionX = value
                    updateTransformPositionX()
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
                    cachedTransformPositionX = value
                    updateTransformPositionX()
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Position Y:
    --------------------------------------------------------------------------------
    local cachedTransformPositionY
    local updateTransformPositionY = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():position().y:value(cachedTransformPositionY)
    end)
    manager.controls:new("transformPositionY", {
        group = "fcpx",
        text = "Transform - Position Y (Absolute)",
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
                    cachedTransformPositionY = value
                    updateTransformPositionY()
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
                    cachedTransformPositionY = value
                    updateTransformPositionY()
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Rotation:
    --------------------------------------------------------------------------------
    local cachedTransformRotation
    local updateTransformRotation = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():rotation():value(cachedTransformRotation)
    end)
    manager.controls:new("transformRotation", {
        group = "fcpx",
        text = "Transform - Rotation (Absolute)",
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
                    cachedTransformRotation = value
                    updateTransformRotation()
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
                    cachedTransformRotation = value
                    updateTransformRotation()
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Anchor Y:
    --------------------------------------------------------------------------------
    local cachedTransformAnchorX
    local updateTransformAnchorX = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():anchor().x:value(cachedTransformAnchorX)
    end)
    manager.controls:new("transformAnchorX", {
        group = "fcpx",
        text = "Transform - Anchor X (Absolute)",
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
                    cachedTransformAnchorX = value
                    updateTransformAnchorX()
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
                    cachedTransformAnchorX = value
                    updateTransformAnchorX()
                end
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Anchor Y:
    --------------------------------------------------------------------------------
    local cachedTransformAnchorY
    local updateTransformAnchorY = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():anchor().y:value(cachedTransformAnchorY)
    end)
    manager.controls:new("transformAnchorY", {
        group = "fcpx",
        text = "Transform - Anchor Y (Absolute)",
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
                    cachedTransformAnchorY = value
                    updateTransformAnchorY()
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
                    cachedTransformAnchorY = value
                    updateTransformAnchorY()
                end
            end
        end,
    })

end

return plugin
