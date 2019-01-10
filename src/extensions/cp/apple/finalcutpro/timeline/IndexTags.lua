--- === cp.apple.finalcutpro.timeline.IndexTags ===
---
--- Provides access to the 'Tags' section of the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md)

local class                 = require "middleclass"
local lazy                  = require "cp.lazy"
local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local RadioButton           = require "cp.ui.RadioButton"
local RadioGroup            = require "cp.ui.RadioGroup"
local Table                 = require "cp.ui.Table"

local strings               = require "cp.apple.finalcutpro.strings"

local cache                 = axutils.cache
local childFromLeft	        = axutils.childFromLeft
local childWith             = axutils.childWith
local childWithRole         = axutils.childWithRole
local childMatching         = axutils.childMatching
local hasChild              = axutils.hasChild

local Do, If                = go.Do, go.If

local IndexTags = class("cp.apple.finalcutpro.timeline.IndexTags"):include(lazy)

--- cp.apple.finalcutpro.timeline.IndexTags(index) -> IndexTags
--- Constructor
--- Creates the `IndexTags` instance.
---
--- Parameters:
--- * index - The [Index](cp.apple.finalcutpro.timeline.Index.md) instance.
function IndexTags:initialize(index)
    self._index = index
end

--- cp.apple.finalcutpro.timeline.IndexTags:parent() -> cp.apple.finalcutpro.timeline.Index
--- Method
--- The parent index.
function IndexTags:parent()
    return self:index()
end

--- cp.apple.finalcutpro.timeline.IndexTags:app() -> cp.apple.finalcutpro
--- Method
--- The [Final Cut Pro](cp.apple.finalcutpro.md) instance.
function IndexTags:app()
    return self:parent():app()
end

function IndexTags:index()
    return self._index
end

--- cp.apple.finalcutpro.timeline.IndexTags:activate() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) that activates the 'Tags' section.
function IndexTags.lazy.method:activate()
    return self:index():mode():tags()
end

--- cp.apple.finalcutpro.timeline.IndexTags.UI <cp.prop: axuielement; read-only; live?>
--- Field
--- The `axuielement` that represents the item.
function IndexTags.lazy.prop:UI()
    return self:index().UI:mutate(function(original)
        return self:activate():checked() and original()
    end)
end

--- cp.apple.finalcutpro.timeline.IndexTags.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- Indicates if the Tags section is currently showing.
function IndexTags.lazy.prop:isShowing()
    return self:activate().checked
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Tags section in the Timeline Index, if possible.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
function IndexTags.lazy.method:doShow()
    local index = self:index()
    return Do(index.doShow)
    :Then(
        If(index.isShowing)
        :Then(self:activate().doPress)
        :Otherwise(false)
    )
    :ThenYield()
    :Label("IndexTags:doShow")
end

--- cp.apple.finalcutpro.timeline.IndexTags:list() -> cp.ui.Table
--- Method
--- Returns the list of tags as a [Table](cp.ui.Table.md).
---
--- Returns:
--- * The [Table](cp.ui.Table.md).
function IndexTags.lazy.method:list()
    return Table(self, self.UI:mutate(function(original)
        if self:activate():checked() then
            return cache(self, "_list", function()
                local scrollArea = childWithRole(original(), "AXScrollArea")
                return scrollArea and childMatching(scrollArea, Table.matches)
            end)
        end
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags:all() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) that will show "All" types of media.
function IndexTags.lazy.method:all()
    return RadioButton(self, self:index().UI:mutate(function(original)
        if self:activate():checked() then
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

local function videoFilter()
    return strings:find("FFVideoFilterLabel")
end

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

--- cp.apple.finalcutpro.timeline.IndexTags.Type:standardMarkers() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Show standard markers" filter.
function IndexTags.Type.lazy.method:standardMarkers()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 1)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type:keywords() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Keywords" filter.
function IndexTags.Type.lazy.method:keywords()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 2)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type:analysisKeywords() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Auto-analysis keywords" filter.
function IndexTags.Type.lazy.method:analysisKeywords()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 3)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type:incompleteTodos() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Incomplete todo marker" filter.
function IndexTags.Type.lazy.method:incompleteTodos()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 4)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type:completeTodos() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Complete todo marker" filter.
function IndexTags.Type.lazy.method:completeTodos()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 5)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags.Type:chapters() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Chapter markers" filter.
function IndexTags.Type.lazy.method:chapters()
    return RadioButton(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 6)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexTags:type() -> cp.apple.finalcutpro.timeline.IndexTags.Type
--- Method
--- The [IndexTags.Type](cp.apple.finalcutpro.timeline.IndexTags.Type.md).
function IndexTags.lazy.method:type()
    return IndexTags.Type(self)
end

--- cp.apple.finalcutpro.timeline.IndexTags:standardMarkers() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Standard markers" filter.
function IndexTags.lazy.method:standardMarkers()
    return self:type():standardMarkers()
end

--- cp.apple.finalcutpro.timeline.IndexTags:keywords() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Keywords" filter.
function IndexTags.lazy.method:keywords()
    return self:type():keywords()
end

--- cp.apple.finalcutpro.timeline.IndexTags:analysisKeywords() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Auto-analysis keywords" filter.
function IndexTags.lazy.method:analysisKeywords()
    return self:type():analysisKeywords()
end

--- cp.apple.finalcutpro.timeline.IndexTags:incompleteTodos() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Incomplete todo marker" filter.
function IndexTags.lazy.method:incompleteTodos()
    return self:type():incompleteTodos()
end

--- cp.apple.finalcutpro.timeline.IndexTags:completeTodos() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Complete todo marker" filter.
function IndexTags.lazy.method:completeTodos()
    return self:type():completeTodos()
end

--- cp.apple.finalcutpro.timeline.IndexTags:chapters() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) for the "Chapter markers" filter.
function IndexTags.lazy.method:chapters()
    return self:type():chapters()
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowAll() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "All" media types.
function IndexTags.lazy.method:doShowAll()
    return If(self.doShow)
    :Then(self:all().doPress)
    :Otherwise(false)
    :Label("IndexTags:doShowAll")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowStandardMarkers() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Standard" markers.
function IndexTags.lazy.method:doShowStandardMarkers()
    return If(self.doShow)
    :Then(self:standardMarkers().doPress)
    :Otherwise(false)
    :Label("IndexTags:doShowStandardMarkers")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowKeywords() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Keywords".
function IndexTags.lazy.method:doShowKeywords()
    return If(self.doShow)
    :Then(self:keywords().doPress)
    :Otherwise(false)
    :Label("IndexTags:doShowKeywords")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowAnalysisKeywords() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Analysis Keywords".
function IndexTags.lazy.method:doShowAnalysisKeywords()
    return If(self.doShow)
    :Then(self:analysisKeywords().doPress)
    :Otherwise(false)
    :Label("IndexTags:doShowAnalysisKeywords")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowIncompleteTodos() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Incomplete Todo Markers".
function IndexTags.lazy.method:doShowIncompleteTodos()
    return If(self.doShow)
    :Then(self:incompleteTodos().doPress)
    :Otherwise(false)
    :Label("IndexTags:doShowIncompleteTodos")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowCompleteTodos() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Complete Todos".
function IndexTags.lazy.method:doShowCompleteTodos()
    return If(self.doShow)
    :Then(self:completeTodos().doPress)
    :Otherwise(false)
    :Label("IndexTags:doShowCompleteTodos")
end

--- cp.apple.finalcutpro.timeline.IndexTags:doShowChapters() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will set the tag index to "Chapter" markers.
function IndexTags.lazy.method:doShowChapters()
    return If(self.doShow)
    :Then(self:chapters().doPress)
    :Otherwise(false)
    :Label("IndexTags:doShowChapters")
end

return IndexTags