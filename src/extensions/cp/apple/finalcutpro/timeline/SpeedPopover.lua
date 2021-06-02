--- === cp.apple.finalcutpro.timeline.SpeedPopover ==
---
---  *Extends [Timeline](cp.apple.finalcutpro.timeline.md)*
---
--- Represents the Speed Popover.

-- local log                   = require "hs.logger" .new "SpeedPopover"

local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local CheckBox              = require "cp.ui.CheckBox"
local Popover               = require "cp.ui.Popover"
local RadioButton           = require "cp.ui.RadioButton"
local RadioGroup            = require "cp.ui.RadioGroup"
local TextField             = require "cp.ui.TextField"

local strings               = require "cp.apple.finalcutpro.strings"

local cache                 = axutils.cache
local childFromLeft         = axutils.childFromLeft
local childFromTop          = axutils.childFromTop
local childrenWithRole      = axutils.childrenWithRole
local childWith             = axutils.childWith
local childWithRole         = axutils.childWithRole

local If, WaitUntil         = go.If, go.WaitUntil

-- local RadioGroup for 'Set Speed'
local SetSpeed = RadioGroup:subclass("cp.apple.finalcutpro.timeline.SpeedPopover.SetSpeed")

-- The 'Rate' radio button
function SetSpeed.lazy.value:byRate()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromTop(original(), 1, RadioButton.matches)
    end))
end

-- The 'Duration' radio button
function SetSpeed.lazy.value:byDuration()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromTop(original(), 2, RadioButton.matches)
    end))
end

local SpeedPopover = Popover:subclass("cp.apple.finalcutpro.timeline.SpeedPopover")

--- cp.apple.finalcutpro.timeline.SpeedPopover.matches(element) -> boolean
--- Function
--- Checks if the element is a "Video" Role.
---
--- Parameters:
---  * element - An element to check
---
--- Returns:
---  * A boolean
function SpeedPopover.static.matches(element)
    return Popover.matches(element)
    and childWith(element, "AXValue", strings:find("FFHeliumXFormCustomSpeed"))
end

--- cp.apple.finalcutpro.timeline.SpeedPopover(parent, uiFinder)
--- Constructor
--- Creates a new instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
---  * parent - the parent `Element`.
---  * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---
--- Returns:
---  * The new `SpeedPopover`.
function SpeedPopover:initialize(timeline)
    local uiFinder = timeline.UI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            local window = ui and ui:attributeValue("AXWindow")
            local popups = window and childrenWithRole(window, "AXPopover")
            if popups then
                for _, popup in pairs(popups) do
                    if SpeedPopover.matches(popup) then
                        return popup
                    end
                end
            end
        end)
    end)
    Popover.initialize(self, timeline, uiFinder)
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:doShow() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a `Statement` that will show the Speed Popover.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Statement` which will send `true` if it successful, or `false` otherwise.
function SpeedPopover.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:app():doSelectMenu({"Modify", "Retime", "Custom Speed.*"}):Debug("Select 'Custom Speed...' Menu")
    )
    :Then(WaitUntil(self.isShowing):TimeoutAfter(1000):Debug("WaitUntil(self.isShowing)"))
    :Otherwise(true)
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:direction <cp.ui.RadioGroup>
--- Field
--- The [RadioGroup](cp.ui.RadioGroup.md) for the "Direction" radio group.
function SpeedPopover.lazy.value:direction()
    return RadioGroup(self, self.UI:mutate(function(original)
        return childFromTop(original(), 1, RadioGroup.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:forward <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Forward" radio button.
function SpeedPopover.lazy.value:forward()
    return RadioButton(self, self.direction.UI:mutate(function(original)
        return childFromLeft(original(), 1, RadioButton.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:reverse <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Reverse" radio button.
function SpeedPopover.lazy.value:reverse()
    return RadioButton(self, self.direction.UI:mutate(function(original)
        return childFromLeft(original(), 1, RadioButton.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:setSpeed <cp.ui.RadioGroup>
--- Field
--- The [RadioGroup](cp.ui.RadioGroup.md) for the "Set Speed" radio group.
function SpeedPopover.lazy.value:setSpeed()
    return SetSpeed(self, self.UI:mutate(function(original)
        return childFromTop(original(), 2, RadioGroup.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:byRate <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Rate" radio button.
function SpeedPopover.lazy.value:byRate()
    return self.setSpeed.byRate
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:byDuration <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Duration" radio button.
function SpeedPopover.lazy.value:byDuration()
    return self.setSpeed.byDuration
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:ripple <cp.ui.RadioGroup>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) for the "Ripple" checkbox.
function SpeedPopover.lazy.value:ripple()
    return CheckBox(self, self.UI:mutate(function(original)
        return childWithRole(original(), "AXCheckBox")
    end))
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:rate <cp.ui.TextField>
--- Field
--- The [TextField](cp.ui.TextField.md) for the "Rate" text field.
function SpeedPopover.lazy.value:rate()
    return TextField(self, self.UI:mutate(function(original)
        if self.rate:checked() then
            return childWithRole(original(), "AXTextField")
        end
    end))
end

--- cp.apple.finalcutpro.timeline.SpeedPopover:duration <cp.ui.TextField>
--- Field
--- The [TextField](cp.ui.TextField.md) for the "Duration" text field.
function SpeedPopover.lazy.value:duration()
    return TextField(self, self.UI:mutate(function(original)
        if self.duration:checked() then
            return childWithRole(original(), "AXTextField")
        end
    end))
end

return SpeedPopover
