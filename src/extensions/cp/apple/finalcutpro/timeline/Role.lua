--- === cp.apple.finalcutpro.timeline.Role ===
---
--- *Extends [Row](cp.ui.Row.md)*
---
--- Represents a Role in the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md).

local axutils	            = require "cp.ui.axutils"
local Row	                = require "cp.ui.Row"
local CheckBox	            = require "cp.ui.CheckBox"
local StaticText	        = require "cp.ui.StaticText"

local childWithRole, childFromLeft	    = axutils.childWithRole, axutils.childFromLeft

local Role = Row:subclass("cp.apple.finalcutpro.timeline.Role")

--- cp.apple.finalcutpro.timeline.Role.TITLE_KEY <table>
--- Constant
--- Contains the list of [strings](cp.apple.finalcutpro.strings.md) used for default roles.
---
--- Notes:
--- * CAPTIONS - "Captions"
--- * VIDEO - "Video"
--- * TITLES - "Titles"
--- * DIALOGUE - "Dialogue"
--- * MUSIC - "Music"
--- * EFFECTS - "Effects"
Role.static.TITLE_KEY = {
    CAPTIONS	= "FFTimelineIndexCaptions",
    VIDEO       = "v.video",
    TITLES      = "v.titles",
    DIALOGUE    = "a.dialogue",
    MUSIC       = "a.music",
    EFFECTS     = "a.effects",
}

--- cp.apple.finalcutpro.timeline.Role.TYPE <table>
--- Constant
--- Contains the set of role types.
---
--- Notes:
--- * VIDEO - A Video Role
--- * AUDIO - An Audio Role
--- * CAPTION - A Caption Role
Role.static.TYPE = {
    VIDEO = 1,
    AUDIO = 2,
    CAPTION = 3,
}

--- cp.apple.finalcutpro.timeline.Role.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Role`.
---
--- Parameters:
--- * element - the `axuielement` to check.
---
--- Returns:
--- * `true` if it matches, otherwise `false`.
function Role.static.matches(element)
    return Row.matches(element)
    and CheckBox.matches(childFromLeft(element[1], 1))
    and StaticText.matches(childFromLeft(element[1], 2))
end

--- cp.apple.finalcutpro.timeline.Role(parent, uiFinder, type)
--- Constructor
--- Creates the new Role. Typically this is not called directly, but rather by one of the
--- subclass roles, such as [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md) or
--- [VideoRole](cp.apple.finalcutpro.timeline.VideoRole.md).
---
--- Parameters:
--- * parent - The parent [Element](cp.ui.Element.md)
--- * uiFinder - The `function` or `cp.prop` that provides the `axuielement`.
--- * type - The [#TYPE] of Role.
---
--- Returns:
--- * The new `Role` instance.
function Role:initialize(parent, uiFinder, type)
    Row.initialize(self, parent, uiFinder)
    self._type = type
    self.video = type == Role.TYPE.VIDEO
    self.audio = type == Role.TYPE.AUDIO
    self.caption = type == Role.TYPE.CAPTION
end

--- cp.apple.finalcutpro.timeline.Role:type() -> cp.apple.finalcut.timeline.Role.TYPE
--- Method
--- Returns the type of Role this is.
function Role:type()
    return self._type
end

--- cp.apple.finalcutpro.timeline.Role.cellUI <cp.prop: axuielement; read-only>
--- Field
--- The AXCell `axuielement` containing the Role details.
function Role.lazy.prop:cellUI()
    return self.UI:mutate(function(original)
        return childWithRole(original(), "AXCell")
    end)
end

--- cp.apple.finalcutpro.timeline.Role.subroleRow <cp.prop: boolean; read-only>
--- Field
--- This is `true` if the `Role` is an Subrole [Row](cp.ui.Row.md).
function Role.lazy.prop:subroleRow()
    return self.disclosureLevel:mutate(function(original)
        return original() == 1
    end)
end

--- cp.apple.finalcutpro.timeline.Role:active() -> cp.ui.CheckBox
--- Method
--- The [CheckBox](cp.ui.CheckBox.md) that determines if the `Role` is active in the timeline.
function Role.lazy.method:active()
    return CheckBox(self, self.cellUI:mutate(function(original)
        return childFromLeft(original(), 1, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Role:title() -> cp.ui.StaticText
--- Method
--- The [StaticText](cp.ui.StaticText.md) containing the title.
function Role.lazy.method:title()
    return StaticText(self, self.cellUI:mutate(function(original)
        return childFromLeft(original(), 1, StaticText.matches)
    end))
end

return Role