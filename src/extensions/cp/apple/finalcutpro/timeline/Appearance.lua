--- === cp.apple.finalcutpro.timeline.Appearance ===
---
--- Timeline Appearance Popup module.

local require           = require

local axutils           = require "cp.ui.axutils"
local CheckBox          = require "cp.ui.CheckBox"
local Popover           = require "cp.ui.Popover"
local RadioGroup        = require "cp.ui.RadioGroup"
local Slider            = require "cp.ui.Slider"

local go                = require "cp.rx.go"

local If                = go.If
local SetProp           = go.SetProp
local WaitUntil         = go.WaitUntil

local cache             = axutils.cache
local childFromTop      = axutils.childFromTop
local childMatching     = axutils.childMatching

local Appearance = Popover:subclass("cp.apple.finalcutpro.timeline.Appearance")

--- cp.apple.finalcutpro.timeline.Appearance(toggle) -> Appearance
--- Constructor
--- Creates a new `Appearance` instance.
---
--- Parameters:
---  * toggle - The parent CheckBox toggle.
---
--- Returns:
---  * A new `Appearance` object.
function Appearance:initialize(toggle)
    Popover.initialize(self, toggle, toggle.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), Appearance.matches)
        end,
        Appearance.matches)
    end))
end

-----------------------------------------------------------------------
--
-- APPEARANCE POPOVER UI:
--
-----------------------------------------------------------------------

-- local wrapper for app's window animation pref
function Appearance.lazy.prop:_windowAnimation()
    return self:app().isWindowAnimationEnabled
end

--- cp.apple.finalcutpro.timeline.Appearance:show() -> Appearance
--- Method
--- Show the Timeline Appearance popup.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Appearance` object.
function Appearance:show()
    if not self:isShowing() then
        local originalAnimation = self._windowAnimation:get()
        self._windowAnimation:set(false)
        self:parent():checked(true)
        self._windowAnimation:set(originalAnimation)
    end
    return self
end

--- cp.apple.finalcutpro.timeline.Appearance:doShow() -> cp.rx.go.Statement
--- Method
--- A `Statement` that shows the Timeline Appearance popup.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`.
function Appearance.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(
        SetProp(self._windowAnimation):To(false)
        :Then(self:parent():doCheck())
        :Then(WaitUntil(self.isShowing))
        :ThenReset()
    )
end

-----------------------------------------------------------------------
--
-- UI ELEMENTS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.timeline.Appearance.clipHeight <cp.ui.Slider>
--- Field
--- The Clip Height Slider.
function Appearance.lazy.value:clipHeight()
    return Slider(self, function()
        return childMatching(self:UI(), function(e)
            return Slider.matches(e) and e:attributeValue("AXMaxValue") == 210
        end)
    end)
end

--- cp.apple.finalcutpro.timeline.Appearance.zoomAmount <cp.ui.Slider>
--- Field
--- The Zoom Slider.
function Appearance.lazy.value:zoomAmount()
    return Slider(self, function()
        return childFromTop(self:UI(), 1, Slider.matches)
    end)
end

--- cp.apple.finalcutpro.timeline.Appearance.clipWaveformHeight <cp.ui.RadioGroup>
--- Field
--- The Waveform Height Radio Group.
function Appearance.lazy.value:clipWaveformHeight()
    return RadioGroup(self, function()
        return childFromTop(self:UI(), 1, RadioGroup.matches)
    end)
end

--- cp.apple.finalcutpro.timeline.Appearance.clipNames <cp.ui.CheckBox>
--- Field
--- Clip Names
function Appearance.lazy.value:clipNames()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 1, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.timeline.Appearance.angles <cp.ui.CheckBox>
--- Field
--- Angles
function Appearance.lazy.value:angles()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 2, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.timeline.Appearance.clipRoles <cp.ui.CheckBox>
--- Field
--- Clip Roles
function Appearance.lazy.value:clipRoles()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 3, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.timeline.Appearance.laneHeaders <cp.ui.CheckBox>
--- Field
--- Lane Headers
function Appearance.lazy.value:laneHeaders()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 4, CheckBox.matches)
    end)
end

return Appearance
