--- === cp.apple.finalcutpro.timeline.IndexCaptions ===
---
--- Provides access to the 'Captions' section of the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md)

local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local Button                = require "cp.ui.Button"
local Table                 = require "cp.ui.Table"

local IndexSection          = require "cp.apple.finalcutpro.timeline.IndexSection"

local cache                 = axutils.cache
local childWithRole         = axutils.childWithRole
local childMatching         = axutils.childMatching
local childFromBottom	    = axutils.childFromBottom

local If                    = go.If

local IndexCaptions = IndexSection:subclass("cp.apple.finalcutpro.timeline.IndexCaptions")

--- cp.apple.finalcutpro.timeline.IndexCaptions.activate <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.md) that activates the 'Captions' section.
function IndexCaptions.lazy.value:activate()
    return self.index.mode.captions
end

--- cp.apple.finalcutpro.timeline.IndexCaptions.list <cp.ui.Table>
--- Field
--- The list of captions as a [Table](cp.ui.Table.md).
function IndexCaptions.lazy.value:list()
    return Table(self, self.UI:mutate(function(original)
        if self.activate:checked() then
            return cache(self, "_list", function()
                local scrollArea = childWithRole(original(), "AXScrollArea")
                return scrollArea and childMatching(scrollArea, Table.matches)
            end)
        end
    end))
end

--- cp.apple.finalcutpro.timeline.IndexCaptions.viewErrors <cp.ui.Button>
--- Field
--- The [Button](cp.ui.Button.md) that will allow viewing errors in the Captions list.
function IndexCaptions.lazy.value:viewErrors()
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