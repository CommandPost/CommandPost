--- === cp.apple.finalcutpro.timeline.Role ===
---
--- *Extends [Row](cp.ui.Row.md)*
---
--- Represents a Role in the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md).

-- local log	                = require "hs.logger" .new "Row"

local localeID	            = require "cp.i18n.localeID"
local axutils	            = require "cp.ui.axutils"
local Row	                = require "cp.ui.Row"
local CheckBox	            = require "cp.ui.CheckBox"
local StaticText	        = require "cp.ui.StaticText"

local fcpApp	            = require "cp.apple.finalcutpro.app"
local strings	            = require "cp.apple.finalcutpro.strings"

local childWithRole, childFromLeft	    = axutils.childWithRole, axutils.childFromLeft
local format	                        = string.format

local en                                = localeID("en")

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
    VIDEO = "VIDEO",
    AUDIO = "AUDIO",
    CAPTION = "CAPTION",
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

--- cp.apple.finalcutpro.timeline.Role.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `Role`.
---
--- Parameters:
---  * `thing`		- The thing to check
---
--- Returns:
---  * `true` if the thing is a `Table` instance.
function Role.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(Role)
end

--- cp.apple.finalcutpro.timeline.Role.findTitle(title) -> string
--- Function
--- Checks if FCPX is not currently running in English, it will check if the title is one
--- of the default English Role titles, and return the current language instead. If it's not found,
--- unmodified `title` is returned.
function Role.findTitle(title)
    local fcpLocale = fcpApp:currentLocale()
    if en:matches(fcpLocale) == 0 then -- not in english
        for _,key in pairs(Role.TITLE_KEY) do
            local value = strings:find(key, en)
            if value == title then
                return strings:find(key, fcpLocale)
            end
        end
    end
    return title
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

--- cp.apple.finalcutpro.timeline.Role.active <cp.ui.CheckBox>
--- Field
--- The [CheckBox](cp.ui.CheckBox.md) that determines if the `Role` is active in the timeline.
function Role.lazy.value:active()
    return CheckBox(self, self.cellUI:mutate(function(original)
        return childFromLeft(original(), 1, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Role.title <cp.ui.StaticText>
--- Field
--- The [StaticText](cp.ui.StaticText.md) containing the title.
function Role.lazy.value:title()
    return StaticText(self, self.cellUI:mutate(function(original)
        return childFromLeft(original(), 1, StaticText.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Role:doActivate() -> cp.rx.go.Statement.md
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will activate the current role, if possible.
function Role.lazy.method:doActivate()
    return self.active:doCheck()
end

--- cp.apple.finalcutpro.timeline.Role:doDeactivate() -> cp.rx.go.Statement.md
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will deactivate the current role, if possible.
function Role.lazy.method:doDeactivate()
    return self.active:doUncheck()
end

function Role:__tostring()
    local title = self.title:value() or "[Unknown]"
    return format("%s: %s", Row.__tostring(self), title)
end

return Role