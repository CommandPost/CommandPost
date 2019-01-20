--- === cp.apple.finalcutpro.browser.AppearanceAndFiltering ===
---
--- Clip Appearance & Filtering Menu Popover

local require = require

--local log                   = require("hs.logger").new("appearanceAndFiltering")

local axutils               = require("cp.ui.axutils")

local Button			    = require("cp.ui.Button")
local CheckBox              = require("cp.ui.CheckBox")
local Popover               = require("cp.ui.Popover")
local PopUpButton           = require("cp.ui.PopUpButton")
local Slider                = require("cp.ui.Slider")

local cache                 = axutils.cache
local childFromRight        = axutils.childFromRight
local childFromTop          = axutils.childFromTop
local childMatching         = axutils.childMatching
local childrenWithRole      = axutils.childrenWithRole

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local AppearanceAndFiltering = Popover:subclass("cp.apple.finalcutpro.browser.AppearanceAndFiltering")

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the "Clip Appearance & Filtering Menu" popover or not.
---
--- Parameters:
---  * element - The element you want to check
---
--- Returns:
---  * `true` if the `element` is the "Clip Appearance & Filtering Menu" popover otherwise `false`
function AppearanceAndFiltering.static.matches(element)
    return Popover.matches(element)
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering(parent) -> AppearanceAndFiltering
--- Constructor
--- Constructs a new "Clip Appearance & Filtering Menu" popover.
---
--- Parameters:
--- * parent - The parent object
---
--- Returns:
--- * The new `AppearanceAndFiltering` instance.
function AppearanceAndFiltering:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), AppearanceAndFiltering.matches)
        end,
        AppearanceAndFiltering.matches)
    end)

    Popover.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering.DURATION -> table
--- Constant
--- A lookup table of the duration values.
AppearanceAndFiltering.DURATION = {
    ["All"]         = 0,
    ["30min"]       = 1,
    ["10min"]       = 2,
    ["5min"]        = 3,
    ["2min"]        = 4,
    ["1min"]        = 5,
    ["30sec"]       = 6,
    ["10sec"]       = 7,
    ["5sec"]        = 8,
    ["2sec"]        = 9,
    ["1sec"]        = 10,
    ["1/2sec"]      = 11
}

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering:show() -> self
--- Method
--- Shows the "Clip Appearance & Filtering Menu" Popover
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function AppearanceAndFiltering:show()
    if not self:isShowing() then
        self:button():press()
    end
    return self
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering:button() -> cp.ui.Button
--- Method
--- Gets the "Clip Appearance & Filtering Menu" button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function AppearanceAndFiltering.lazy.method:button()
    return Button(self, self:parent().UI:mutate(function(original)
        return childFromRight(childrenWithRole(original(), "AXButton"), 2)
    end))
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering:clipHeight() -> cp.ui.Slider
--- Method
--- Gets the Clip Height Slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Slider` object.
function AppearanceAndFiltering.lazy.method:clipHeight()
    return Slider(self, self.UI:mutate(function(original)
        return childFromTop(childrenWithRole(original(), "AXSlider"), 2)
    end))
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering:duration() -> cp.ui.Slider
--- Method
--- Gets the Duration Slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Slider` object.
function AppearanceAndFiltering.lazy.method:duration()
    return Slider(self, self.UI:mutate(function(original)
        return childFromTop(childrenWithRole(original(), "AXSlider"), 3)
    end))
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering:groupBy() -> cp.ui.PopUpButton
--- Method
--- Gets the "Group By" popup button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `PopUpButton` object.
function AppearanceAndFiltering.lazy.method:groupBy()
    return PopUpButton(self, self.UI:mutate(function(original)
        return childFromTop(childrenWithRole(original(), "AXPopUpButton"), 1)
    end))
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering:sortBy() -> cp.ui.PopUpButton
--- Method
--- Gets the "Sort By" popup button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `PopUpButton` object.
function AppearanceAndFiltering.lazy.method:sortBy()
    return PopUpButton(self, self.UI:mutate(function(original)
        return childFromTop(childrenWithRole(original(), "AXPopUpButton"), 2)
    end))
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering:waveForms() -> cp.ui.CheckBox
--- Method
--- Gets the Waveforms checkbox.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `CheckBox` object.
function AppearanceAndFiltering.lazy.method:waveForms()
    return CheckBox(self, self.UI:mutate(function(original)
        return childFromTop(childrenWithRole(original(), "AXCheckBox"), 1)
    end))
end

--- cp.apple.finalcutpro.browser.AppearanceAndFiltering:continuousPlayback() -> cp.ui.CheckBox
--- Method
--- Gets the Continuous Playback checkbox.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `CheckBox` object.
function AppearanceAndFiltering.lazy.method:continuousPlayback()
    return CheckBox(self, self.UI:mutate(function(original)
        return childFromTop(childrenWithRole(original(), "AXCheckBox"), 2)
    end))
end

return AppearanceAndFiltering