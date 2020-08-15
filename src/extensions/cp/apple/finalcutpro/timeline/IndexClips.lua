--- === cp.apple.finalcutpro.timeline.IndexClips ===
---
--- *Extends [IndexSection](cp.apple.finalcutpro.timeline.IndexSection.md)*
---
--- Provides access to the 'Clips' section of the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md)

local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local RadioButton           = require "cp.ui.RadioButton"
local RadioGroup            = require "cp.ui.RadioGroup"
local Table                 = require "cp.ui.Table"

local strings               = require "cp.apple.finalcutpro.strings"
local IndexSection          = require "cp.apple.finalcutpro.timeline.IndexSection"

local cache                 = axutils.cache
local childWith             = axutils.childWith
local childWithRole         = axutils.childWithRole
local childMatching         = axutils.childMatching
local hasChild              = axutils.hasChild

local If                    = go.If

local IndexClips = IndexSection:subclass("cp.apple.finalcutpro.timeline.IndexClips")

--- cp.apple.finalcutpro.timeline.IndexClips(index) -> IndexClips
--- Constructor
--- Creates the `IndexClips` instance.
---
--- Parameters:
--- * index - The [Index](cp.apple.finalcutpro.timeline.Index.md) instance.

--- cp.apple.finalcutpro.timeline.IndexClips.activate <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) that activates the 'Clips' section.
function IndexClips.lazy.value:activate()
    return self:index():mode():clips()
end

--- cp.apple.finalcutpro.timeline.IndexClips.list <cp.ui.Table>
--- Field
--- The list of clips as a [Table](cp.ui.Table.md).
function IndexClips.lazy.value:list()
    return Table(self, self.UI:mutate(function(original)
        if self.activate:checked() then
            return cache(self, "_list", function()
                local scrollArea = childWithRole(original(), "AXScrollArea")
                return scrollArea and childMatching(scrollArea, Table.matches)
            end)
        end
    end))
end

--- cp.apple.finalcutpro.timeline.IndexClips.all <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) that will show "All" types of media.
function IndexClips.lazy.value:all()
    return RadioButton(self, self:index().UI:mutate(function(original)
        if self.activate:checked() then
            return cache(self, "_all", function()
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

--- cp.apple.finalcutpro.timeline.IndexClips.Type.video <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Video" filter.
function IndexClips.Type.lazy.value:video()
    return RadioButton(self, self.UI:mutate(function(original)
        return childWith(original(), "AXTitle", videoFilter())
    end))
end

--- cp.apple.finalcutpro.timeline.IndexClips.Type.audio <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Audio" filter.
function IndexClips.Type.lazy.value:audio()
    return RadioButton(self, self.UI:mutate(function(original)
        return childWith(original(), "AXTitle", audioFilter())
    end))
end

--- cp.apple.finalcutpro.timeline.IndexClips.Type.titles <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Titles" filter.
function IndexClips.Type.lazy.value:titles()
    return RadioButton(self, self.UI:mutate(function(original)
        return childWith(original(), "AXTitle", titlesFilter())
    end))
end

--- cp.apple.finalcutpro.timeline.IndexClips.type <cp.apple.finalcutpro.timeline.IndexClips.Type>
--- Field
--- The [IndexClips.Type](cp.apple.finalcutpro.timeline.IndexClips.Type.md).
function IndexClips.lazy.value:type()
    return IndexClips.Type(self)
end

--- cp.apple.finalcutpro.timeline.IndexClips.video <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Video" filter.
function IndexClips.lazy.value:video()
    return self.type.video
end

--- cp.apple.finalcutpro.timeline.IndexClips.audio <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Audio" filter.
function IndexClips.lazy.value:audio()
    return self.type.audio
end

--- cp.apple.finalcutpro.timeline.IndexClips.titles <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Titles" filter.
function IndexClips.lazy.value:titles()
    return self.type.titles
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShowAll() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the clip index to "All" media types.
function IndexClips.lazy.method:doShowAll()
    return If(self:doShow())
    :Then(self.all:doPress())
    :Otherwise(false)
    :Label("IndexClips:doShowAll")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShowVideo() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the clip index to "Video" media types.
function IndexClips.lazy.method:doShowVideo()
    return If(self:doShow())
    :Then(self.video:doPress())
    :Otherwise(false)
    :Label("IndexClips:doShowVideo")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShowAudio() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the clip index to "Audio" media types.
function IndexClips.lazy.method:doShowAudio()
    return If(self:doShow())
    :Then(self.audio:doPress())
    :Otherwise(false)
    :Label("IndexClips:doShowAudio")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doShowTitles() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the clip index to "Titles" media types.
function IndexClips.lazy.method:doShowTitles()
    return If(self:doShow())
    :Then(self.titles:doPress())
    :Otherwise(false)
    :Label("IndexClips:doShowTitles")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doFindClipsContaining(text) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.go.rx.Statement.md) that will use the index to search for clips containing the specified text.
---
--- Parameters:
--- * text - The text to search for.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * Because the `text` can change each time, this result is not cached automatically. However as long as you are searching for the same text the result can be safely cached. The [#toFindMissingMedia] method does this, for example.
function IndexClips:doFindClipsContaining(text)
    return If(self:doShowClips())
    :Then(function()
        self.search:value(text)
        return true
    end)
    :Otherwise(false)
    :ThenYield()
    :Label("IndexClips:doFindClipsContaining('"..text.."')")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doFindMissingMedia() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Missing Media".
function IndexClips.lazy.method:doFindMissingMedia()
    return self:doFindClipsContaining(strings:find("FFTimelineIndexMissingMediaSearch"))
    :Label("IndexClips:doFindMissingMedia")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doFindAuditions() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Auditions".
function IndexClips.lazy.method:doFindAuditions()
    return self:doFindClipsContaining(strings:find("FFOrganizerFilterHUDClipTypeAudition"))
    :Label("IndexClips:doFindAuditions")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doFindMulticams() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Multicam" clips.
function IndexClips.lazy.method:doFindMulticams()
    return self:doFindClipsContaining(strings:find("FFOrganizerFilterHUDClipTypeMultiCam"))
    :Label("IndexClips:doFindMulticams")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doFindCompoundClips() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Compound Clips".
function IndexClips.lazy.method:doFindCompoundClips()
    return self:doFindClipsContaining(strings:find("FFOrganizerFilterHUDClipTypeCompound"))
    :Label("IndexClips:doFindCompoundClips")
end

--- cp.apple.finalcutpro.timeline.IndexClips:doFindSynchronized() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Synchronized" Clips.
function IndexClips.lazy.method:doFindSynchronized()
    return self:doFindClipsContaining(strings:find("FFOrganizerFilterHUDClipTypeSynchronized"))
    :Label("IndexClips:doFindSynchronized")
end

--- cp.apple.finalcutpro.timeline.IndexClips:saveLayout() -> table
--- Method
--- Returns a `table` containing the layout configuration for this class.
---
--- Returns:
--- * The layout configuration `table`.
function IndexClips:saveLayout()
    return {
        showing = self:isShowing(),
        all = self.all:saveLayout(),
        video = self.video:saveLayout(),
        audio = self.audio:saveLayout(),
        titles = self.titles:saveLayout(),
    }
end

--- cp.apple.finalcutpro.timeline.IndexClips:doLayout(layout) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will apply the layout provided, if possible.
---
--- Parameters:
--- * layout - the `table` containing the layout configuration. Usually created via the [#saveLayout] method.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md).
function IndexClips:doLayout(layout)
    layout = layout or {}
    return If(layout.showing == true)
    :Then(self:doShow())
    :Then(self.all:doLayout(layout.all))
    :Then(self.video:doLayout(layout.video))
    :Then(self.audio:doLayout(layout.audio))
    :Then(self.titles:doLayout(layout.titles))
    :Label("IndexClips:doLayout")
end

return IndexClips