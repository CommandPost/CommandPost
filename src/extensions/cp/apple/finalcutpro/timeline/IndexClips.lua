--- === cp.apple.finalcutpro.timeline.IndexClips ===
---
--- Provides access to the 'Clips' section of the [Timeline Index](cp.apple.finalcutpro.timeline.IndexClips)

local class                 = require "middleclass"
local lazy                  = require "cp.lazy"
local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local RadioButton           = require "cp.ui.RadioButton"
local RadioGroup            = require "cp.ui.RadioGroup"
local Table                 = require "cp.ui.Table"

local strings               = require "cp.apple.finalcutpro.strings"

local cache                 = axutils.cache
local childWith             = axutils.childWith
local childWithRole         = axutils.childWithRole
local childMatching         = axutils.childMatching
local hasChild              = axutils.hasChild

local Do, If                = go.Do, go.If

local IndexClips = class("cp.apple.finalcutpro.timeline.IndexClips"):include(lazy)

--- cp.apple.finalcutpro.timeline.IndexClips(index) -> IndexClips
--- Constructor
--- Creates the `IndexClips` instance.
---
--- Parameters:
--- * index - The [Index](cp.apple.finalcutpro.timeline.Index.md) instance.
function IndexClips:initialize(index)
    self._index = index
end

--- cp.apple.finalcutpro.timeline.IndexClips:parent() -> cp.apple.finalcutpro.timeline.Index
--- Method
--- The parent index.
function IndexClips:parent()
    return self:index()
end

--- cp.apple.finalcutpro.timeline.IndexClips:app() -> cp.apple.finalcutpro
--- Method
--- The [Final Cut Pro](cp.apple.finalcutpro.md) instance.
function IndexClips:app()
    return self:parent():app()
end

function IndexClips:index()
    return self._index
end

--- cp.apple.finalcutpro.timeline.IndexClips:activate() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) that activates the 'Clips' section.
function IndexClips.lazy.method:activate()
    return self:index():mode():clips()
end

--- cp.apple.finalcutpro.timeline.IndexClips.UI <cp.prop: axuielement; read-only; live?>
--- Field
--- The `axuielement` that represents the item.
function IndexClips.lazy.prop:UI()
    return self:index().UI:mutate(function(original)
        return self:activate():checked() and original()
    end)
end

--- cp.apple.finalcutpro.timeline.IndexClips.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- Indicates if the Clips section is currently showing.
function IndexClips.lazy.prop:isShowing()
    return self:activate().checked
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Clips section in the Timeline Index, if possible.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
function IndexClips.lazy.method:doShow()
    local index = self:index()
    return Do(index.doShow)
    :Then(
        If(index.isShowing)
        :Then(index:mode():clips().doPress)
        :Otherwise(false)
    )
    :ThenYield()
    :Label("IndexClips:doShow")
end

--- cp.apple.finalcutpro.timeline.IndexClips:list() -> cp.ui.Table
--- Method
--- Returns the list of clips as a [Table](cp.ui.Table.md).
---
--- Returns:
--- * The [Table](cp.ui.Table.md).
function IndexClips.lazy.method:list()
    return Table(self, self.UI:mutate(function(original)
        if self:activate():checked() then
            return cache(self, "_list", function()
                local scrollArea = childWithRole(original(), "AXScrollArea")
                return scrollArea and childMatching(scrollArea, Table.matches)
            end)
        end
    end))
end

--- cp.apple.finalcutpro.timeline.IndexClips:all() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) that will show "All" types of media.
function IndexClips.lazy.method:all()
    return RadioButton(self, self:index().UI:mutate(function(original)
        if self:activate():checked() then
            return cache(self, "_clips", function()
                local group = childMatching(original(), function(child)
                    return RadioGroup.matches(child) and #child == 1
                end)

                return group and group[1]
            end)
        end
    end))
end

--- === cp.apple.finalcutpro.timeline.IndexClips.Type ===
---
--- The collection of [RadioButtons](cp.ui.RadioButton.md) that allow filtering by Video/Audio/Title.

IndexClips.static.Type = RadioGroup:subclass("cp.apple.finalcutpro.timeline.IndexClips.Type")

local function videoFilter()
    return strings:find("FFVideoFilterLabel")
end

local function audioFilter()
    return strings:find("FFAudioFilterLabel")
end

local function titlesFilter()
    return strings:find("FFTitlesFilterLabel")
end

--- cp.apple.finalcutpro.timeline.IndexClips.Type.matches(element) -> boolean
--- Method
--- Checks if the `element` is the `IndexClips.Type` group.
---
--- Parameters:
--- * element - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches, otherwise `false`.
function IndexClips.Type.static.matches(element)
    return RadioGroup.matches(element)
    and hasChild(element, function(child)
        return RadioButton.matches(child) and child:attributeValue("AXTitle") == videoFilter()
    end)
end

-- cp.apple.finalcutpro.timeline.IndexClips.Type(parent) -> IndexClips.Type
-- Private Constructor
-- Constructs the `IndexClips.Type` instance.
function IndexClips.Type:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return childMatching(original(), IndexClips.Type.matches)
    end)

    RadioGroup.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.timeline.IndexClips.Type:video() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Video" filter.
function IndexClips.Type.lazy.method:video()
    return RadioButton(self, self.UI:mutate(function(original)
        return childWith(original(), "AXTitle", videoFilter())
    end))
end

--- cp.apple.finalcutpro.timeline.IndexClips.Type:audio() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Audio" filter.
function IndexClips.Type.lazy.method:audio()
    return RadioButton(self, self.UI:mutate(function(original)
        return childWith(original(), "AXTitle", audioFilter())
    end))
end

--- cp.apple.finalcutpro.timeline.IndexClips.Type:titles() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Titles" filter.
function IndexClips.Type.lazy.method:titles()
    return RadioButton(self, self.UI:mutate(function(original)
        return childWith(original(), "AXTitle", titlesFilter())
    end))
end

--- cp.apple.finalcutpro.timeline.IndexClips:type() -> cp.apple.finalcutpro.timeline.IndexClips.Type
--- Method
--- The [IndexClips.Type](cp.apple.finalcutpro.timeline.IndexClips.Type.md).
function IndexClips.lazy.method:type()
    return IndexClips.Type(self)
end

--- cp.apple.finalcutpro.timeline.IndexClips:video() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Video" filter.
function IndexClips.lazy.method:video()
    return self:type():video()
end

--- cp.apple.finalcutpro.timeline.IndexClips:audio() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Audio" filter.
function IndexClips.lazy.method:audio()
    return self:type():audio()
end

--- cp.apple.finalcutpro.timeline.IndexClips:titles() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Titles" filter.
function IndexClips.lazy.method:titles()
    return self:type():titles()
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShowAll() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the clip index to "All" media types.
function IndexClips.lazy.method:doShowAll()
    return If(self.doShow)
    :Then(self:all().doPress)
    :Otherwise(false)
    :Label("IndexClips:doShowAll")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShowVideo() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the clip index to "Video" media types.
function IndexClips.lazy.method:doShowVideo()
    return If(self.doShow)
    :Then(self:video().doPress)
    :Otherwise(false)
    :Label("IndexClips:doShowVideo")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShowAudio() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the clip index to "Audio" media types.
function IndexClips.lazy.method:doShowAudio()
    return If(self.doShow)
    :Then(self:audio().doPress)
    :Otherwise(false)
    :Label("IndexClips:doShowAudio")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShowTitles() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the clip index to "Titles" media types.
function IndexClips.lazy.method:doShowTitles()
    return If(self.doShow)
    :Then(self:titles().doPress)
    :Otherwise(false)
    :Label("IndexClips:doShowTitles")
end

return IndexClips