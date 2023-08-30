--- === plugins.finalcutpro.inspector.title ===
---
--- Final Cut Pro Title Inspector Additions.

local require = require

local log                       = require "hs.logger".new "titleInspector"

local axutils                   = require "cp.ui.axutils"
local deferred                  = require "cp.deferred"
local fcp                       = require "cp.apple.finalcutpro"
local tools                     = require "cp.tools"

local Slider                    = require "cp.ui.Slider"
local TextField                 = require "cp.ui.TextField"

local toRegionalNumber          = tools.toRegionalNumber
local toRegionalNumberString    = tools.toRegionalNumberString

local plugin = {
    id              = "finalcutpro.inspector.title",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["core.monogram.manager"]       = "manager",
    }
}

local mod = {}

-- DEFER_VALUE -> number
-- Constant
-- How long we should defer all the update functions.
local DEFER_VALUE = 0.01

--- plugins.finalcutpro.inspector.title.motionVFXAnimationTextField -> cp.ui.TextField
--- Field
--- MotionVFX Title Animation Amount Text Field
mod.motionVFXAnimationTextField = TextField(fcp.inspector.title, function()
    local title = fcp.inspector.title
    local ui = title and title:UI()
    local groupA = ui and axutils.childAtIndex(ui, 1)
    local groupB = groupA and axutils.childAtIndex(groupA, 1)
    local animationAmountSliderUI = groupB and axutils.childWithDescription(groupB, "animation amount scrubber")
    return animationAmountSliderUI
end, toRegionalNumber, toRegionalNumberString):forceFocus()


--- plugins.finalcutpro.inspector.title.motionVFXAnimationAmountSlider -> cp.ui.Slider
--- Field
--- MotionVFX Title Animation Amount Slider
mod.motionVFXAnimationAmountSlider = Slider(fcp.inspector.title, function()
    local title = fcp.inspector.title
    local ui = title and title:UI()
    local groupA = ui and axutils.childAtIndex(ui, 1)
    local groupB = groupA and axutils.childAtIndex(groupA, 1)
    local animationAmountSliderUI = groupB and axutils.childWithDescription(groupB, "animation amount slider")
    return animationAmountSliderUI
end)

-- Mirror the Slider to the Text Box, otherwise it doesn't update correctly:
mod.motionVFXAnimationAmountSlider.value:mirror(mod.motionVFXAnimationTextField.value)

-- makeSliderHandler(finderFn) -> function
-- Function
-- Creates a 'handler' for slider controls, applying them to the slider returned by the `finderFn`
--
-- Parameters:
--  * finderFn - a function that will return the slider to apply the value to.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeSliderHandler(finderFn)
    local absolute
    local shift = 0
    local slider = finderFn()

    local updateUI = deferred.new(DEFER_VALUE):action(function()

        if slider:isShowing() then
            if absolute then
                slider:value(absolute)
                absolute = nil
            else
                local current = slider:value()
                slider:value(current + shift)
                shift = 0
            end
        else
            slider:show()
        end
    end)

    return function(data)
        if data.operation == "+" then
            local increment = data.params and data.params[1]
            shift = shift + increment
            updateUI()
        elseif data.operation == "=" then
            absolute = data.params and data.params[1]
            updateUI()
        end
    end
end

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- MotionVFX - Title - Animation Amount:
    --------------------------------------------------------------------------------
    local motionVFXAnimationAmountSliderValue = 0
    local updateMotionVFXAnimationAmountSlider = deferred.new(0.01):action(function()
        local s = mod.motionVFXAnimationAmountSlider
        s:show()
        local original = s:value()
        s:value(original + motionVFXAnimationAmountSliderValue)
        motionVFXAnimationAmountSliderValue = 0
    end)

    local amounts = {0.1, 0.5, 1, 2, 3, 4, 5, 10}
    for _, v in pairs(amounts) do
        deps.fcpxCmds
            :add("motionVFXAnimationAmountSliderIncrease" .. v)
            :whenActivated(function()
                motionVFXAnimationAmountSliderValue = motionVFXAnimationAmountSliderValue + v
                updateMotionVFXAnimationAmountSlider()
            end)
            :titled("MotionVFX Title - Animation Amount - Increase by " .. v)

        deps.fcpxCmds
            :add("motionVFXAnimationAmountSliderDecrease" .. v)
            :whenActivated(function()
                motionVFXAnimationAmountSliderValue = motionVFXAnimationAmountSliderValue - v
                updateMotionVFXAnimationAmountSlider()
            end)
            :titled("MotionVFX Title - Animation Amount - Decrease by " .. v)
    end

    deps.fcpxCmds
        :add("motionVFXAnimationAmountSliderZero")
        :whenActivated(function()
            local s = mod.motionVFXAnimationAmountSlider
            s:show()
            s:value(0)
        end)
        :titled("MotionVFX Title - Animation Amount - Set to Zero")

    --------------------------------------------------------------------------------
    -- MotionVFX - Title - Animation Amount - Monogram Slider:
    --------------------------------------------------------------------------------
    local registerAction = deps.manager.registerAction
    registerAction("Title Inspector.MotionVFX Title.Animation Amount", makeSliderHandler(function() return mod.motionVFXAnimationAmountSlider end))

    return mod
end

return plugin
