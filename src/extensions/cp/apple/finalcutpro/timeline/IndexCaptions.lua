--- === cp.apple.finalcutpro.timeline.IndexCaptions ===
---
--- Provides access to the 'Captions' section of the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md)

local class                 = require "middleclass"
local lazy                  = require "cp.lazy"
local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local Button                = require "cp.ui.Button"
local Table                 = require "cp.ui.Table"

local cache                 = axutils.cache
local childWithRole         = axutils.childWithRole
local childMatching         = axutils.childMatching
local childFromBottom	    = axutils.childFromBottom

local Do, If                = go.Do, go.If

local IndexCaptions = class("cp.apple.finalcutpro.timeline.IndexCaptions"):include(lazy)

--- cp.apple.finalcutpro.timeline.IndexCaptions(index) -> IndexCaptions
--- Constructor
--- Creates the `IndexCaptions` instance.
---
--- Parameters:
--- * index - The [Index](cp.apple.finalcutpro.timeline.Index.md) instance.
function IndexCaptions:initialize(index)
    self._index = index
end

--- cp.apple.finalcutpro.timeline.IndexCaptions:parent() -> cp.apple.finalcutpro.timeline.Index
--- Method
--- The parent index.
function IndexCaptions:parent()
    return self:index()
end

--- cp.apple.finalcutpro.timeline.IndexCaptions:app() -> cp.apple.finalcutpro
--- Method
--- The [Final Cut Pro](cp.apple.finalcutpro.md) instance.
function IndexCaptions:app()
    return self:parent():app()
end

function IndexCaptions:index()
    return self._index
end

--- cp.apple.finalcutpro.timeline.IndexCaptions:activate() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) that activates the 'Captions' section.
function IndexCaptions.lazy.method:activate()
    return self:index():mode():captions()
end

--- cp.apple.finalcutpro.timeline.IndexCaptions.UI <cp.prop: axuielement; read-only; live?>
--- Field
--- The `axuielement` that represents the item.
function IndexCaptions.lazy.prop:UI()
    return self:index().UI:mutate(function(original)
        return self:activate():checked() and original()
    end)
end

--- cp.apple.finalcutpro.timeline.IndexCaptions.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- Indicates if the Captions section is currently showing.
function IndexCaptions.lazy.prop:isShowing()
    return self:activate().checked
end

--- cp.apple.finalcutpro.timeline.IndexCaptions:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Captions section in the Timeline Index, if possible.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
function IndexCaptions.lazy.method:doShow()
    local index = self:index()
    return Do(index.doShow)
    :Then(
        If(index.isShowing)
        :Then(self:activate().doPress)
        :Otherwise(false)
    )
    :ThenYield()
    :Label("IndexCaptions:doShow")
end

--- cp.apple.finalcutpro.timeline.IndexCaptions:list() -> cp.ui.Table
--- Method
--- Returns the list of captions as a [Table](cp.ui.Table.md).
---
--- Returns:
--- * The [Table](cp.ui.Table.md).
function IndexCaptions.lazy.method:list()
    return Table(self, self.UI:mutate(function(original)
        if self:activate():checked() then
            return cache(self, "_list", function()
                local scrollArea = childWithRole(original(), "AXScrollArea")
                return scrollArea and childMatching(scrollArea, Table.matches)
            end)
        end
    end))
end

function IndexCaptions.lazy.method:viewErrors()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_viewErrors", function()
            return childFromBottom(original(), 1, Button.matches)
        end)
    end))
end


--- cp.apple.finalcutpro.timeline.IndexCaptions:saveLayout() -> table
--- Method
--- Returns a `table` containing the layout configuration for this class.
---
--- Returns:
--- * The layout configuration `table`.
function IndexCaptions:saveLayout()
    return {
        showing = self:isShowing(),
    }
end

--- cp.apple.finalcutpro.timeline.IndexCaptions:doLayout(layout) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will apply the layout provided, if possible.
---
--- Parameters:
--- * layout - the `table` containing the layout configuration. Usually created via the [#saveLayout] method.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md).
function IndexCaptions:doLayout(layout)
    layout = layout or {}
    return If(layout.showing == true)
    :Then(self:doShow())
    :Label("IndexCaptions:doLayout")
end

return IndexCaptions