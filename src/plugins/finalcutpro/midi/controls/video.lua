--- === plugins.finalcutpro.midi.controls.video ===
---
--- Final Cut Pro MIDI Video Inspector Controls.

local require = require

local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local rescale           = tools.rescale

local function createAbsoluteMIDIOpacitySlider()
    local value
    local updateUI = deferred.new(0.01):action(function()
        fcp:inspector():video():compositing():opacity():show():value(value)
    end)
    return function(metadata)
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            local midiValue
            if metadata.pitchChange then
                midiValue = metadata.pitchChange
            else
                midiValue = metadata.fourteenBitValue
            end
            value = rescale(midiValue, 0, 16383, 0, 100)
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            local controllerValue = metadata.controllerValue
            value = rescale(controllerValue, 0, 127, 0, 100)
            updateUI()
        end
    end
end

local function createAbsoluteMIDIScaleSlider(paramFn)
    local value
    local updateUI = deferred.new(0.01):action(function()
        param = paramFn()
        param:show():value(value)
    end)
    return function(metadata)
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            local midiValue
            if metadata.pitchChange then
                midiValue = metadata.pitchChange
            else
                midiValue = metadata.fourteenBitValue
            end
            value = rescale(midiValue, 0, 16383, 0, 100)
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            local controllerValue = metadata.controllerValue
            if controllerValue == 64 then
                value = 100
            elseif controllerValue < 64 then
                value = rescale(controllerValue, 0, 63, 0, 99)
            elseif controllerValue > 64 then
                if controllerValue < 96 then
                    value = rescale(controllerValue, 64, 96, 101, 200)
                else
                    value = rescale(controllerValue, 97, 127, 201, 400)
                end
            end
            updateUI()
        end
    end
end

local function createAbsoluteMIDIPositionSlider(param)
    local value
    local updateUI = deferred.new(0.01):action(function()
        param:show():value(value)
    end)
    return function(metadata)
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            local midiValue
            if metadata.pitchChange then
                midiValue = metadata.pitchChange
            else
                midiValue = metadata.fourteenBitValue
            end
            value = rescale(midiValue, 0, 16383, 0, 100)
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            local controllerValue = metadata.controllerValue
            if controllerValue == 64 then
                value = 0
            elseif controllerValue < 64 then
                value = rescale(controllerValue, 0, 63, -2500, -0.1)
            elseif controllerValue > 64 then
                value = rescale(controllerValue, 64, 127, 0.1, 2500)
            end
            updateUI()
        end
    end
end

local function createAbsoluteMIDIRotationSlider()
    local value
    local updateUI = deferred.new(0.01):action(function()
        fcp:inspector():video():show():transform():rotation():show():value(value)
    end)
    return function(metadata)
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            local midiValue
            if metadata.pitchChange then
                midiValue = metadata.pitchChange
            else
                midiValue = metadata.fourteenBitValue
            end
            value = rescale(midiValue, 0, 16383, 0, 100)
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            local controllerValue = metadata.controllerValue
            if controllerValue == 64 then
                value = 0
            elseif controllerValue < 64 then
                value = rescale(controllerValue, 0, 63, -180, -0.1)
            elseif controllerValue > 64 then
                value = rescale(controllerValue, 64, 127, 1, 180)
            end
            updateUI()
        end
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
    -- Opacity (0 to 100):
    --------------------------------------------------------------------------------
    manager.controls:new("opacity", {
        group = "fcpx",
        text = i18n("opacity") .. "(" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIOpacitySlider(),
    })

    --------------------------------------------------------------------------------
    -- Scale X (0 to 400):
    --------------------------------------------------------------------------------
    manager.controls:new("transformScaleX", {
        group = "fcpx",
        text = i18n("transform") .. " - " .. i18n("scale") .. " X (" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIScaleSlider(function() return fcp:inspector():video():show():transform():scaleX() end),
    })

    --------------------------------------------------------------------------------
    -- Scale Y (0 to 400):
    --------------------------------------------------------------------------------
    manager.controls:new("transformScaleY", {
        group = "fcpx",
        text = i18n("transform") .. " - " .. i18n("scale") .. " Y (" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIScaleSlider(function() return fcp:inspector():video():show():transform():scaleY() end),
    })

    --------------------------------------------------------------------------------
    -- Scale All (0 to 400):
    --------------------------------------------------------------------------------
    manager.controls:new("transformScaleAll", {
        group = "fcpx",
        text = i18n("transform") .. " - " .. i18n("scale") .. " " .. i18n("all") .. " (" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIScaleSlider(function() return fcp:inspector():video():show():transform():scaleAll() end),
    })

    --------------------------------------------------------------------------------
    -- Position X (-2500 to 2500)
    --------------------------------------------------------------------------------
    manager.controls:new("transformPositionX", {
        group = "fcpx",
        text = i18n("transform") .. " - " .. i18n("position") .. " X (" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIPositionSlider(function() return fcp:inspector():video():show():transform():position().x end),
    })

    --------------------------------------------------------------------------------
    -- Position Y (-2500 TO 2500):
    --------------------------------------------------------------------------------
    manager.controls:new("transformPositionY", {
        group = "fcpx",
        text = i18n("transform") .. " - " .. i18n("position") .. " Y (" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIPositionSlider(function() return fcp:inspector():video():show():transform():position().y end),
    })

    --------------------------------------------------------------------------------
    -- Rotation (-180 to 180):
    --------------------------------------------------------------------------------
    manager.controls:new("transformRotation", {
        group = "fcpx",
        text = i18n("transform") .. " - " .. i18n("rotation") .. " (" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIRotationSlider(),
    })

    --------------------------------------------------------------------------------
    -- Anchor Y (-2500 to 2500):
    --------------------------------------------------------------------------------
    manager.controls:new("transformAnchorX", {
        group = "fcpx",
        text = i18n("transform") .. " - " .. i18n("anchor") .. " X (" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIPositionSlider(function() return fcp:inspector():video():show():transform():anchor().x end),
    })

    --------------------------------------------------------------------------------
    -- Anchor Y (-2500 to 2500):
    --------------------------------------------------------------------------------
    manager.controls:new("transformAnchorY", {
        group = "fcpx",
        text = i18n("transform") .. " - " .. i18n("anchor") .. " Y (" .. i18n("absolute") .. ")",
        subText = i18n("midiVideoInspector"),
        fn = createAbsoluteMIDIPositionSlider(function() return fcp:inspector():video():show():transform():anchor().y end),
    })

end

return plugin