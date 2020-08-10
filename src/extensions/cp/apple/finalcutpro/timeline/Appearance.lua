--- === cp.apple.finalcutpro.timeline.Appearance ===
---
--- Timeline Appearance Module.

local require = require

local just								= require "cp.just"
local axutils							= require "cp.ui.axutils"

local CheckBox					        = require "cp.ui.CheckBox"
local Popover                           = require "cp.ui.Popover"
local RadioGroup                        = require "cp.ui.RadioGroup"
local Slider							= require "cp.ui.Slider"

local go                                = require "cp.rx.go"
local If, WaitUntil                     = go.If, go.WaitUntil

local cache                             = axutils.cache
local childFromTop                      = axutils.childFromTop
local childMatching                     = axutils.childMatching

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
    Popover.initialize(toggle, toggle.UI:mutate(function(original)
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

--- cp.apple.finalcutpro.timeline.Appearance:UI() -> Appearance
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
        self:parent():checked(true)
    end
    return self
end

function Appearance.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(self:parent():doCheck())
    :Then(WaitUntil(self.isShowing))
    :Label("Appearance:doShow")
end

--- cp.apple.finalcutpro.timeline.Appearance:UI() -> Appearance
--- Method
--- Hide the Timeline Appearance popup.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Appearance` object.
function Appearance:hide()
    local ui = self:UI()
    if ui then
        ui:doCancel()
    end
    just.doWhile(function() return self:isShowing() end)
    return self
end

function Appearance:doHide()
    return If(self.UI)
    :Then(function(ui)
        ui:doCancel()
    end)
    :Then(WaitUntil(self.isShowing):Is(false))
    :Label("Appearance:doHide")
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