--- === cp.apple.finalcutpro.timeline.IndexTags ===
---
--- Provides access to the 'Tags' section of the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md)

local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local RadioButton           = require "cp.ui.RadioButton"
local RadioGroup            = require "cp.ui.RadioGroup"
local Table                 = require "cp.ui.Table"

local IndexSection          = require "cp.apple.finalcutpro.timeline.IndexSection"

local cache                 = axutils.cache
local childFromLeft	        = axutils.childFromLeft
local childWithRole         = axutils.childWithRole
local childMatching         = axutils.childMatching

local If                    = go.If

local IndexTags = IndexSection:subclass("cp.apple.finalcutpro.timeline.IndexTags")

--- cp.apple.finalcutpro.timeline.IndexTags.activate <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) that activates the 'Tags' section.
function IndexTags.lazy.value:activate()
    return self.index.mode.tags
end

--- cp.apple.finalcutpro.timeline.IndexTags.list <cp.ui.Table>
--- Field
--- The list of tags as a [Table](cp.ui.Table.md).
function IndexTags.lazy.value:list()
    return Table(self, self.UI:mutate(function(original)
        if self.activate:checked() then
            return cache(self, "_list", function()
                local scrollArea = childWithRole(original(), "AXScrollArea")
                return scrollArea and childMatching(scrollArea, Table.matches)
            end)
        end
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.all <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) that will show "All" types of media.
function IndexTags.lazy.value:all()
    return RadioButton(self, self.index.UI:mutate(function(original)
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

--- === cp.apple.finalcutpro.timeline.IndexTags.Type ===
---
--- The collection of [RadioButtons](cp.ui.RadioButton.md) that allow filtering by Video/Audio/Title.

IndexTags.static.Type = RadioGroup:subclass("cp.apple.finalcutpro.timeline.IndexTags.Type")

--- cp.apple.finalcutpro.timeline.IndexTags.Type.matches(element) -> boolean
--- Method
--- Checks if the `element` is the `IndexTags.Type` group.
---
--- Parameters:
--- * element - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches, otherwise `false`.
function IndexTags.Type.static.matches(element)
    return RadioGroup.matches(element) and #element == 6
end

-- cp.apple.finalcutpro.timeline.IndexTags.Type(parent) -> IndexTags.Type
-- Private Constructor
-- Constructs the `IndexTags.Type` instance.
function IndexTags.Type:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return childMatching(original(), IndexTags.Type.matches)
    end)

    RadioGroup.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type.standardMarkers <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Show standard markers" filter.
function IndexTags.Type.lazy.value:standardMarkers()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 1)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type.keywords <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Keywords" filter.
function IndexTags.Type.lazy.value:keywords()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 2)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type.analysisKeywords <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Auto-analysis keywords" filter.
function IndexTags.Type.lazy.value:analysisKeywords()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 3)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type.incompleteTodos <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Incomplete todo marker" filter.
function IndexTags.Type.lazy.value:incompleteTodos()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 4)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type.completeTodos <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Complete todo marker" filter.
function IndexTags.Type.lazy.value:completeTodos()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 5)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type.chapters <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Chapter markers" filter.
function IndexTags.Type.lazy.value:chapters()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 6)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.type <cp.apple.finalcutpro.timeline.IndexTags.Type>
--- Field
--- The [IndexTags.Type](cp.apple.finalcutpro.timeline.IndexTags.Type.md).
function IndexTags.lazy.value:type()
    return IndexTags.Type(self)
end

--- cp.apple.finalcutpro.timeline.IndexTags.standardMarkers <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Standard markers" filter.
function IndexTags.lazy.value:standardMarkers()
    return self.type.standardMarkers
end

--- cp.apple.finalcutpro.timeline.IndexTags.keywords <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Keywords" filter.
function IndexTags.lazy.value:keywords()
    return self.type.keywords
end

--- cp.apple.finalcutpro.timeline.IndexTags.analysisKeywords <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Auto-analysis keywords" filter.
function IndexTags.lazy.value:analysisKeywords()
    return self.type.analysisKeywords
end

--- cp.apple.finalcutpro.timeline.IndexTags.incompleteTodos <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Incomplete todo marker" filter.
function IndexTags.lazy.value:incompleteTodos()
    return self.type.incompleteTodos
end

--- cp.apple.finalcutpro.timeline.IndexTags.completeTodos <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Complete todo marker" filter.
function IndexTags.lazy.value:completeTodos()
    return self.type.completeTodos
end

--- cp.apple.finalcutpro.timeline.IndexTags.chapters <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) for the "Chapter markers" filter.
function IndexTags.lazy.value:chapters()
    return self.type.chapters
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowAll() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "All" media types.
function IndexTags.lazy.method:doShowAll()
    return If(self:doShow())
    :Then(self.all:doPress())
    :Otherwise(false)
    :Label("IndexTags:doShowAll")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowStandardMarkers() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Standard" markers.
function IndexTags.lazy.method:doShowStandardMarkers()
    return If(self:doShow())
    :Then(self.standardMarkers:doPress())
    :Otherwise(false)
    :Label("IndexTags:doShowStandardMarkers")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowKeywords() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Keywords".
function IndexTags.lazy.method:doShowKeywords()
    return If(self:doShow())
    :Then(self.keywords:doPress())
    :Otherwise(false)
    :Label("IndexTags:doShowKeywords")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowAnalysisKeywords() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Analysis Keywords".
function IndexTags.lazy.method:doShowAnalysisKeywords()
    return If(self:doShow())
    :Then(self.analysisKeywords:doPress())
    :Otherwise(false)
    :Label("IndexTags:doShowAnalysisKeywords")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowIncompleteTodos() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Incomplete Todo Markers".
function IndexTags.lazy.method:doShowIncompleteTodos()
    return If(self:doShow())
    :Then(self.incompleteTodos:doPress())
    :Otherwise(false)
    :Label("IndexTags:doShowIncompleteTodos")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowCompleteTodos() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Complete Todos".
function IndexTags.lazy.method:doShowCompleteTodos()
    return If(self:doShow())
    :Then(self.completeTodos:doPress())
    :Otherwise(false)
    :Label("IndexTags:doShowCompleteTodos")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowChapters() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Chapter" markers.
function IndexTags.lazy.method:doShowChapters()
    return If(self:doShow())
    :Then(self.chapters:doPress())
    :Otherwise(false)
    :Label("IndexTags:doShowChapters")
end

--- cp.apple.finalcutpro.timeline.IndexTags:saveLayout() -> table
--- Method
--- Returns a `table` containing the layout configuration for this class.
---
--- Returns:
--- * The layout configuration `table`.
function IndexTags:saveLayout()
    return {
        showing = self:isShowing(),
        all = self.all:saveLayout(),
        standardMarkers = self.standardMarkers:saveLayout(),
        keywords = self.keywords:saveLayout(),
        analysisKeywords = self.analysisKeywords:saveLayout(),
        incompleteTodos = self.incompleteTodos:saveLayout(),
        completeTodos = self.completeTodos:saveLayout(),
        chapters = self.chapters:saveLayout(),
    }
end

--- cp.apple.finalcutpro.timeline.IndexTags:doLayout(layout) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will apply the layout provided, if possible.
---
--- Parameters:
--- * layout - the `table` containing the layout configuration. Usually created via the [#saveLayout] method.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md).
function IndexTags:doLayout(layout)
    layout = layout or {}
    return If(layout.showing == true)
    :Then(self:doShow())
    :Then(self.all:doLayout(layout.all))
    :Then(self.standardMarkers:doLayout(layout.standardMarkers))
    :Then(self.keywords:doLayout(layout.keywords))
    :Then(self.analysisKeywords:doLayout(layout.analysisKeywords))
    :Then(self.incompleteTodos:doLayout(layout.incompleteTodos))
    :Then(self.completeTodos:doLayout(layout.completeTodos))
    :Then(self.chapters:doLayout(layout.chapters))
    :Label("IndexTags:doLayout")
end

return IndexTags