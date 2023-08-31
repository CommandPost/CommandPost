--- === plugins.finalcutpro.inspector.title ===
---
--- Final Cut Pro Title Inspector Additions.

local require = require

--local log                       = require "hs.logger".new "titleInspector"

local axutils                   = require "cp.ui.axutils"
local deferred                  = require "cp.deferred"
local fcp                       = require "cp.apple.finalcutpro"
local tools                     = require "cp.tools"

local Button                    = require "cp.ui.Button"
local Slider                    = require "cp.ui.Slider"
local TextField                 = require "cp.ui.TextField"

local toRegionalNumber          = tools.toRegionalNumber
local toRegionalNumberString    = tools.toRegionalNumberString

local plugin = {
    id              = "finalcutpro.inspector.title",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

local mod = {}

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

--- plugins.finalcutpro.inspector.title.motionVFXAnimationAmountAddKeyframe -> cp.ui.Button
--- Field
--- MotionVFX Title Animation Amount Add Keyframe Button
mod.motionVFXAnimationAmountAddKeyframeButton = Button(fcp.inspector.title, function()
    local title = fcp.inspector.title
    local ui = title and title:UI()
    local groupA = ui and axutils.childAtIndex(ui, 1)
    local groupB = groupA and axutils.childAtIndex(groupA, 1)
    local animationAmountSliderUI = groupB and axutils.childWithDescription(groupB, "animation amount add a keyframe")
    return animationAmountSliderUI
end)

--- plugins.finalcutpro.inspector.title.motionVFXAnimationAmountDeleteKeyframe -> cp.ui.Button
--- Field
--- MotionVFX Title Animation Amount Delete Keyframe Button
mod.motionVFXAnimationAmountDeleteKeyframeButton = Button(fcp.inspector.title, function()
    local title = fcp.inspector.title
    local ui = title and title:UI()
    local groupA = ui and axutils.childAtIndex(ui, 1)
    local groupB = groupA and axutils.childAtIndex(groupA, 1)
    local animationAmountSliderUI = groupB and axutils.childWithDescription(groupB, "animation amount delete keyframe")
    return animationAmountSliderUI
end)

--- plugins.finalcutpro.inspector.title.motionVFXAnimationAmountAnimationButton -> cp.ui.Button
--- Field
--- MotionVFX Title Animation Amount Keyframe Button
mod.motionVFXAnimationAmountKeyframeButton = Button(fcp.inspector.title, function()
    local title = fcp.inspector.title
    local ui = title and title:UI()
    local groupA = ui and axutils.childAtIndex(ui, 1)
    local groupB = groupA and axutils.childAtIndex(groupA, 1)
    local animationAmountSliderUI = groupB and axutils.childWithDescription(groupB, "animation amount animation button")
    return animationAmountSliderUI
end)

-- Mirror the Slider to the Text Box, otherwise it doesn't update correctly:
mod.motionVFXAnimationAmountSlider.value:mirror(mod.motionVFXAnimationTextField.value)

--- plugins.finalcutpro.inspector.title.toggleMotionVFXAnimationAmountKeyframe() -> none
--- Function
--- Toggles the MotionVFX Title Animation Amount Keyframe button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleMotionVFXAnimationAmountKeyframe()
    mod.motionVFXAnimationAmountAddKeyframeButton:show()
    local ui = mod.motionVFXAnimationAmountKeyframeButton:UI() or mod.motionVFXAnimationAmountAddKeyframeButton:UI() or mod.motionVFXAnimationAmountDeleteKeyframeButton:UI()
    if ui then
        local f = ui:attributeValue("AXFrame")
        if f then
            local point = {
                x = f.x + f.w - 5,
                y = f.y + (f.h / 2)
            }
            tools.ninjaMouseClick(point)
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

    deps.fcpxCmds
        :add("motionVFXAnimationAmountToggleKeyframe")
        :whenActivated(mod.toggleMotionVFXAnimationAmountKeyframe)
        :titled("MotionVFX Title - Animation Amount - Toggle Keyframe")

    return mod
end

return plugin
