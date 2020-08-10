--- === cp.apple.finalcutpro.timeline.Toolbar ===
---
--- Timeline Toolbar

local require = require

local axutils							= require "cp.ui.axutils"

local Button                            = require "cp.ui.Button"
local CheckBox                          = require "cp.ui.CheckBox"
local Group                             = require "cp.ui.Group"
local RadioButton						= require "cp.ui.RadioButton"
local RadioGroup                        = require "cp.ui.RadioGroup"
local StaticText                        = require "cp.ui.StaticText"

local Appearance				        = require "cp.apple.finalcutpro.timeline.Appearance"

local cache                             = axutils.cache
local childFromLeft, childFromRight     = axutils.childFromLeft, axutils.childFromRight
local childMatching                     = axutils.childMatching

local Toolbar = Group:subclass("cp.apple.finalcutpro.timeline.Toolbar")

--- cp.apple.finalcutpro.timeline.Toolbar.matches(element) -> boolean
--- Function
--- Checks if the element is a Toolbar.
---
--- Parameters:
--- * element - the `axuielement` to check.
---
--- Returns:
--- * `true` if it matches, otherwise `false`.
function Toolbar.static.matches(element)
    return Group.matches(element)
end

--- cp.apple.finalcutpro.timeline.Toolbar(timeline) -> cp.apple.finalcutpro.timeline.Toolbar
--- Constructor
--- Creates a new Toolbar with the specified parent.
---
--- Parameters:
--- * timeline - The [Timeline](cp.apple.finalcutpro.timeline.Timeline.md).
---
--- Returns:
--- * The new Toolbar instance.
function Toolbar:initialize(timeline)
    local UI = timeline.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), Toolbar.matches) -- _NS:237 in FCPX 10.4
        end, Toolbar.matches)
    end)

    Group.initialize(self, timeline, UI)
end

-----------------------------------------------------------------------
--
-- THE TOOLBAR ITEMS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.timeline.Toolbar.index <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) which indicates if the Timeline Index is visible.
function Toolbar.lazy.value:index()
    return CheckBox(self, self.UI:mutate(function(original)
        return cache(self, "_index", function()
            return childFromLeft(original(), 1, CheckBox.matches)
        end, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.back <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) for "go back in timeline history".
function Toolbar.lazy.value:back()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_back", function()
            return childFromLeft(original(), 5, Button.matches)
        end, Button.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.forward <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) for "go forward in timeline history".
function Toolbar.lazy.value:forward()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_forward", function()
            return childFromLeft(original(), 6, Button.matches)
        end, Button.matches)
    end))
end

--- === cp.apple.finalcutpro.timeline.Toolbar.Skimming ===
---
--- Provides access to mouse/trackpad skimming options.

Toolbar.static.Skimming = Group:subclass("cp.apple.finalcutpro.timeline.Toolbar.Skimming")

-- cp.apple.finalcutpro.timeline.Toolbar.Skimming(toolbar) -> Toolbar.Skimming
-- Private Constructor
-- Creates a new `Toolbar.Skimming` group.
--
-- Parameters:
-- * toolbar - the [Toolbar](cp.apple.finalcutpro.timeline.Toolbar.md).
function Toolbar.Skimming:initialize(toolbar)
    Group.initialize(self, toolbar, toolbar.UI:mutate(function(original)
        return cache(self, "_skimming", function()
            return childFromRight(original(), 1, Group.matches)
        end, Group.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Skimming.active <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if video/audio skimming is active.
function Toolbar.Skimming.lazy.value:active()
    return CheckBox(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 2, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Skimming.audio <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if audio is played while skimming.
function Toolbar.Skimming.lazy.value:audio()
    return CheckBox(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 3, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Skimming.solo <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if audio is soloing the selected clip(s).
function Toolbar.Skimming.lazy.value:solo()
    return CheckBox(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 4, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Skimming.snapping <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if snapping is enabled.
function Toolbar.Skimming.lazy.value:snapping()
    return CheckBox(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 5, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.skimming <cp.apple.finalcutpro.timeline.Toolbar.Skimming>
--- Field
--- The [Skimming](cp.apple.finalcutpro.timeline.Toolbar.Skimming.md) group of checkbox items.
function Toolbar.lazy.value:skimming()
    return Toolbar.Skimming(self)
end

--- cp.apple.finalcutpro.timeline.Toolbar.skimmingGroup <cp.ui.Group>
--- Field
--- A [Group](cp.ui.Group.md) containing buttons relating to mouse skimming behaviour, waveforms, snapping, etc.
function Toolbar.lazy.value:skimmingGroup()
    return Group(self, self.UI:mutate(function(original)
        return cache(self, "_skimmingGroup", function()
            return childFromRight(original(), 1, Group.matches)
        end, Group.matches)
    end))
end

--- === cp.apple.finalcutpro.timeline.Toolbar.Browser ===
---
--- A [RadioGroup](cp.ui.RadioGroup.md) that contains buttons to show or hide the Effects and Transitions Browsers.

Toolbar.static.Browser = RadioGroup:subclass("cp.apple.finalcutpro.timeline.Toolbar.Browser")

-- cp.apple.finalcutpro.timeline.Toolbar.Browser(toolbar) -> Toolbar.Browser
-- Private Constructor
-- Creates the Browser group.
--
-- Parameters:
-- * toolbar - The [Toolbar](cp.apple.finalcutpro.timeline.Toolbar.md).
function Toolbar.Browser:initialize(toolbar)
    RadioGroup.initialize(self, toolbar, toolbar.UI:mutate(function(original)
        return cache(self, "_browser", function()
            return childFromRight(original(), 1, RadioGroup.matches)
        end, RadioGroup.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Browser.effects <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) which toggles the 'Effects' browser visibility.
function Toolbar.Browser.lazy.value:effects()
    return RadioButton(self, function()
        return childFromLeft(self:UI(), 1)
    end)
end

--- cp.apple.finalcutpro.timeline.Toolbar.Browser.transitions <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) which toggles the 'Transitions' browser visibility.
function Toolbar.Browser.lazy.method:transitions()
    return RadioButton(self, function()
        return childFromLeft(self:UI(), 2)
    end)
end

--- cp.apple.finalcutpro.timeline.Toolbar.browser <cp.apple.finalcutpro.timeline.Toolbar.Browser>
--- Field
--- The [Toolbar.Browser](cp.apple.finalcutpro.timeline.Toolbar.Browser.md) containing buttons that will toggle the Effects/Transitions browsers.
function Toolbar.lazy.value:browser()
    return Toolbar.Browser(self, self.UI:mutate(function(original)
        return cache(self, "_browser", function()
            return childFromRight(original(), 1, Toolbar.Browser.matches)
        end, Toolbar.Browser.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.title <cp.ui.StaticText>
--- Field
--- The title [StaticText](cp.ui.StaticText.md) from the Timeline Titlebar.
function Toolbar.lazy.value:title()
    return StaticText(self, self.UI:mutate(function(original)
        return cache(self, "_titleUI", function()
            return childFromLeft(original(), 1, StaticText.matches)
        end)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.duration <cp.ui.StaticText>
--- Field
--- The duration [StaticText](cp.ui.StaticText.md) from the Timeline Titlebar.
function Toolbar.lazy.value:duration()
    return StaticText(self, self.UI:mutate(function(original)
        return cache(self, "_durationUI", function()
            return childFromLeft(original(), 2, StaticText.matches)
        end)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.appearanceToggle <cp.ui.CheckBox>
--- Field
--- A `CheckBox` field which will toggle the `appearance` popover.
function Toolbar.lazy.value:appearanceToggle()
    return CheckBox(self:parent(), self.UI:mutate(function(original)
        return childFromRight(original(), 1, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Toolbar.appearance <cp.apple.finalcutpro.timeline.Appearance>
--- Field
--- The [Appearance](cp.apple.finalcutpro.timeline.Appearance.md) button/palette control.
function Toolbar.lazy.value:appearance()
    return Appearance(self.appearanceToggle)
end

return Toolbar
