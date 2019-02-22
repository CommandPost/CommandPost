--- === cp.ui.Column ===
---
--- Represents an `AXColumn` `axuielement`.

local axutils	                = require "cp.ui.axutils"
local Element	                = require "cp.ui.Element"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Column = Element:subclass("cp.ui.Column")

--- cp.ui.Column.matches(element) -> boolean
--- Function
--- Checks if the `axuielement` is a `Column`.
---
--- Parameters:
--- * element - The `axuielement` to check.
---
--- Returns:
--- * `true` if the element is a Column.
function Column.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXColumn"
end

--- cp.ui.Column.index <cp.prop: number; read-only>
--- Field
--- The numeric index of this column in the overall container, with `0` being the first item.
function Column.lazy.prop:index()
    return axutils.prop(self.UI, "AXIndex")
end

--- cp.ui.Column.selected <cp.prop: boolean>
--- Field
--- Indicates if the column is currently selected. May be set.
function Column.lazy.prop:selected()
    return axutils.prop(self.UI, "AXSelected", true)
end

--- cp.ui.Column:rows() -> table of cp.ui.Row or nil
--- Method
--- Returns a `table` of [Row](cp.ui.Row.md)s contained in the Column.
---
--- Returns:
--- * The `table`, or `nil` if the column's UI is not available.
function Column:rows()
    local ui = self:UI()
    if ui then
        local rowsUI = ui:attributeValue("AXRows")
        return self:parent():findRows(rowsUI)
    end
end

--- cp.ui.Column:visibleRows() -> table of cp.ui.Rows or nil
--- Method
--- Returns a `table` of [Row](cp.ui.Row.md)s which are currently visible on screen.
---
--- Returns:
--- * The `table`, or `nil` if the column's UI is not available.
function Column:visibleRows()
    local ui = self:UI()
    if ui then
        local rowsUI = ui:attributeValue("AXVisibleRows")
        return self:parent():findRows(rowsUI)
    end
end

return Column
