--- === cp.apple.finalcutpro.timeline.Toolbar ===
---
--- Timeline Toolbar

local require                           = require

local fn                                = require "cp.fn"
local ax                                = require "cp.fn.ax"

local Button                            = require "cp.ui.Button"
local CheckBox                          = require "cp.ui.CheckBox"
local Group                             = require "cp.ui.Group"
local MenuButton                        = require "cp.ui.MenuButton"
local RadioButton						= require "cp.ui.RadioButton"
local RadioGroup                        = require "cp.ui.RadioGroup"
local StaticText                        = require "cp.ui.StaticText"

local delegator                         = require "cp.delegator"

local Appearance				        = require "cp.apple.finalcutpro.timeline.Appearance"
local Duration                          = require "cp.apple.finalcutpro.timeline.Duration"
local ToolPalette                       = require "cp.apple.finalcutpro.timeline.ToolPalette"

local chain                             = fn.chain
local cache, childMatching              = ax.cache, ax.childMatching

local Toolbar = Group:subclass("cp.apple.finalcutpro.timeline.Toolbar")
    :include(delegator)
    :delegateTo("clip", "browser") -- allow properties of `clip` and `browser` to be accessed directly

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
    local UI = timeline.UI:mutate(
        cache(self, "_ui", Toolbar.matches)(
            childMatching(Toolbar.matches)
        )
    )

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
    return CheckBox(self, self.UI:mutate(
        cache(self, "_index", CheckBox.matches)(
            chain // childMatching(CheckBox.matches, 1, ax.leftToRight)
        )
    ))
end

--- cp.cp.apple.finalcutpro.timeline.Timeline.connectClip <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) which connects a clip from the Browser to the Primary Storyline in the Timeline.
function Toolbar.lazy.value:connectClip()
    return Button(self, self.UI:mutate(
        cache(self, "_connectClip", Button.matches)(
            childMatching(Button.matches, 1, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.insertClip <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) which inserts a clip from the Browser into the Timeline.
function Toolbar.lazy.value:insertClip()
    return Button(self, self.UI:mutate(
        cache(self, "_insertClip", Button.matches)(
            childMatching(Button.matches, 2, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.appendClip <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) which appends a clip from the Browser into the Timeline.
function Toolbar.lazy.value:appendClip()
    return Button(self, self.UI:mutate(
        cache(self, "_appendClip", Button.matches)(
            childMatching(Button.matches, 3, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.overwriteClip <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) which overwrites a clip from the Browser into the Timeline.
function Toolbar.lazy.value:overwriteClip()
    return Button(self, self.UI:mutate(
        cache(self, "_overwriteClip", Button.matches)(
            childMatching(Button.matches, 4, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.clipMedia <cp.ui.MenuButton>
--- Field
--- The [MenuButton](cp.ui.MenuButton.md) which allows the user to select the media type that will
--- be connected/inserted/appended/overwritten into the Timeline.
function Toolbar.lazy.value:clipMedia()
    return MenuButton(self, self.UI:mutate(
        cache(self, "_clipMedia", MenuButton.matches)(
            chain // childMatching(Group.matches, 1, ax.leftToRight) >> childMatching(MenuButton.matches)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.tool <cp.apple.finalcutpro.timeline.ToolPalette>
--- Field
--- The [ToolPalette](cp.apple.finalcutpro.timeline.ToolPalette.md), which allows the user to select the tool
--- that is being used to manipulate the timeline at present.
function Toolbar.lazy.value:tool()
    return ToolPalette(self, self.UI:mutate(
        cache(self, "_tool", ToolPalette.matches)(
            chain // childMatching(Group.matches, 2, ax.leftToRight) >> childMatching(ToolPalette.matches)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.back <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) for "go back in timeline history".
function Toolbar.lazy.value:back()
    return Button(self, self.UI:mutate(
        cache(self, "_back", Button.matches)(
            childMatching(Button.matches, 5, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.title <cp.ui.MenuButton>
--- Field
--- The [MenuButton](cp.ui.MenuButton.md) which lists the current project and allows
--- the user to switch select actions to perform with this project.
function Toolbar.lazy.value:title()
    return MenuButton(self, self.UI:mutate(
        cache(self, "_title", MenuButton.matches)(
            childMatching(MenuButton.matches, 1, ax.leftToRight)
        )
    ))
end


--- cp.apple.finalcutpro.timeline.Toolbar.duration <cp.ui.StaticText>
--- Field
--- The [StaticText](cp.ui.StaticText.md) which displays the duration of the Timeline.
--- It may contain a single timecode, in which case it is the timecode for the current project/sequence.
--- Alternately, it may contain two timelines, separated by " / ", in which case it is the duration of the
--- currently selected clips, then the current project/sequence duration.
function Toolbar.lazy.value:duration()
    return Duration(self, self.UI:mutate(
        cache(self, "_duration", StaticText.matches)(
            childMatching(StaticText.matches, 1, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.forward <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) for "go forward in timeline history".
function Toolbar.lazy.value:forward()
    return Button(self, self.UI:mutate(
        cache(self, "_forward", Button.matches)(
            childMatching(Button.matches, 6, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.clip <cp.apple.finalcutpro.timeline.Toolbar.Clip>
--- Field
--- The [Clip](cp.apple.finalcutpro.timeline.Toolbar.Clip.md) group of checkbox items.
function Toolbar.lazy.value:clip()
    return Toolbar.Clip(self)
end

-----------------------------------------------------------------------
-- NOTE: These are "delegated" to via the `clip` field.
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.timeline.Toolbar.trimAlignedEdges <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) which allows the user to trim the edges of the selected clips.
---
--- Notes:
--- * As of FCP 10.6.3, this is currently always hidden, and cannot have its value changed.
--- * Uncertain in exactly which version this turned up.

--- cp.apple.finalcutpro.timeline.Toolbar.skimming <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if video/audio skimming is active.

--- cp.apple.finalcutpro.timeline.Toolbar.audioSkimming <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if audio is played while skimming.

--- cp.apple.finalcutpro.timeline.Toolbar.solo <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if audio is soloed on the selected clip(s).

--- cp.apple.finalcutpro.timeline.Toolbar.snapping <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if snapping is enabled.

--- cp.apple.finalcutpro.timeline.Toolbar.appearanceToggle <cp.ui.CheckBox>
--- Field
--- A `CheckBox` field which will toggle the `appearance` popover.
function Toolbar.lazy.value:appearanceToggle()
    return CheckBox(self:parent(), self.UI:mutate(
        cache(self, "_appearanceToggle", CheckBox.matches)(
            childMatching(CheckBox.matches, 1, ax.rightToLeft)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.appearance <cp.apple.finalcutpro.timeline.Appearance>
--- Field
--- The [Appearance](cp.apple.finalcutpro.timeline.Appearance.md) button/palette control.
function Toolbar.lazy.value:appearance()
    return Appearance(self.appearanceToggle)
end

--- cp.apple.finalcutpro.timeline.Toolbar.browser <cp.apple.finalcutpro.timeline.Toolbar.Browser>
--- Field
--- The [Toolbar.Browser](cp.apple.finalcutpro.timeline.Toolbar.Browser.md) containing buttons that will toggle the Effects/Transitions browsers.
function Toolbar.lazy.value:browser()
    return Toolbar.Browser(self)
end

-----------------------------------------------------------------------
-- NOTE: These are "delegated" to via the `browser` field.
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.timeline.Toolbar.effects <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) which toggles the 'Effects' browser visibility.

--- cp.apple.finalcutpro.timeline.Toolbar.transitions <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) which toggles the 'Transitions' browser visibility.

-----------------------------------------------------------------------
-- Utility Classes
-----------------------------------------------------------------------

--- === cp.apple.finalcutpro.timeline.Toolbar.Clip ===
---
--- Provides access to clip options such as skimming, audio skimming, soloing and snap.

Toolbar.static.Clip = Group:subclass("cp.apple.finalcutpro.timeline.Toolbar.Clip")

-- cp.apple.finalcutpro.timeline.Toolbar.Clip(toolbar) -> Toolbar.Clip
-- Private Constructor
-- Creates a new `Toolbar.Clip` group.
--
-- Parameters:
-- * toolbar - the [Toolbar](cp.apple.finalcutpro.timeline.Toolbar.md).
function Toolbar.Clip:initialize(toolbar)
    Group.initialize(self, toolbar, toolbar.UI:mutate(
        cache(toolbar, "_clip", Group.matches)(
            childMatching(Group.matches, 1, ax.rightToLeft)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Clip.trimAlignedEdges <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) which allows the user to trim the edges of the selected clips.
---
--- Notes:
--- * As of FCP 10.6.3, this is currently always hidden, and cannot have its value changed.
--- * Uncertain in exactly which version this turned up.
function Toolbar.Clip.lazy.value:trimAlignedEdges()
    return CheckBox(self, self.UI:mutate(
        cache(self, "_trimAlignedEdges", CheckBox.matches)(
            childMatching(CheckBox.matches, 1, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Clip.skimming <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if video/audio skimming is active.
function Toolbar.Clip.lazy.value:skimming()
    return CheckBox(self, self.UI:mutate(
        cache(self, "_active", CheckBox.matches)(
            childMatching(CheckBox.matches, 4, ax.rightToLeft)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Clip.audioSkimming <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if audio is played while skimming.
function Toolbar.Clip.lazy.value:audioSkimming()
    return CheckBox(self, self.UI:mutate(
        cache(self, "_audioSkimming", CheckBox.matches)(
            childMatching(CheckBox.matches, 3, ax.rightToLeft)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Clip.solo <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if audio is soloed on the selected clip(s).
function Toolbar.Clip.lazy.value:solo()
    return CheckBox(self, self.UI:mutate(
        cache(self, "_solo", CheckBox.matches)(
            childMatching(CheckBox.matches, 2, ax.rightToLeft)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Clip.snapping <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that indicates if snapping is enabled.
function Toolbar.Clip.lazy.value:snapping()
    return CheckBox(self, self.UI:mutate(
        cache(self, "_snapping", CheckBox.matches)(
            childMatching(CheckBox.matches, 1, ax.rightToLeft)
        )
    ))
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
    RadioGroup.initialize(self, toolbar, toolbar.UI:mutate(
        cache(toolbar, "_browser", RadioGroup.matches)(
            childMatching(RadioGroup.matches, 1, ax.rightToLeft)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Browser.effects <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) which toggles the 'Effects' browser visibility.
function Toolbar.Browser.lazy.value:effects()
    return RadioButton(self, self.UI:mutate(
        cache(self, "_effects", RadioButton.matches)(
            childMatching(RadioButton.matches, 1, ax.leftToRight)
        )
    ))
end

--- cp.apple.finalcutpro.timeline.Toolbar.Browser.transitions <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) which toggles the 'Transitions' browser visibility.
function Toolbar.Browser.lazy.value:transitions()
    return RadioButton(self, self.UI:mutate(
        cache(self, "_transitions", RadioButton.matches)(
            childMatching(RadioButton.matches, 2, ax.leftToRight)
        )
    ))
end

return Toolbar
