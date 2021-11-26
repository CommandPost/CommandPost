--- === cp.ui.Row ===
---
--- Represents an `AXRow` `axuielement`.

local ax                        = require "cp.fn.ax"
local Element	                = require "cp.ui.Element"

local Row = Element:subclass("cp.ui.Row")

--- cp.ui.Row.matches(element) -> boolean
--- Method
--- Checks if the element is a `Row`.
---
--- Parameters:
---  * element - the `axuielement` to check.
---
--- Returns:
---  * `true` if it matches, otherwise `false`.
Row.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXRow")

--- cp.ui.Row(parent, uiFinder) -> cp.ui.Row
--- Constructor
--- Creates a new `Row` instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
---  * parent - the parent `Element`.
---  * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---
--- Returns:
---  * The new `Row`.

--- cp.ui.Row.disclosing <cp.prop: boolean>
--- Field
--- Indicates if the `Row` is disclosing other `Rows`.
function Row.lazy.prop:disclosing()
    return ax.prop(self.UI, "AXDisclosing", true)
end

--- cp.ui.Row.disclosureLevel <cp.prop: number; read-only>
--- Field
--- The depth of disclosure. `0` is the top level.
function Row.lazy.prop:disclosureLevel()
    return ax.prop(self.UI, "AXDisclosureLevel")
end

--- cp.ui.Row:disclosedByRow() -> cp.ui.Row
--- Method
--- The `Row` which is disclosing this `Row`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `cp.ui.Row` object
function Row.lazy.prop:disclosedByRow()
    return ax.prop(self.UI, "AXDisclosedByRow"):mutate(function(original)
        return self:parent():fetchRow(original())
    end)
end

--- cp.ui.Row:disclosedRows() -> table of cp.ui.Row or nil
--- Method
--- If available, returns a table of [Row](cp.ui.Row.md)s that are disclosed by this `Row`.
--- If this row is currently unavailable, `nil` is returned.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `table` of Rows, or `nil`.
function Row:disclosedRows()
    local ui = self:UI()
    if ui then
        local rowsUI = ui:attributeValue("AXDisclosedRows")
        if rowsUI then
            return self:parent():fetchRows(rowsUI)
        end
    end
end

--- cp.ui.Row.selected <cp.prop: boolean>
--- Field
--- Indicates if the row is currently selected. May be set.
function Row.lazy.prop:selected()
    return ax.prop(self.UI, "AXSelected", true)
end

--- cp.ui.Row.index <cp.prop: number; read-only>
--- Field
--- The numeric index of this row in the overall container, with `0` being the first item.
function Row.lazy.prop:index()
    return ax.prop(self.UI, "AXIndex")
end

-- cp.ui.Row:__eq(other) -> boolean
-- Function
-- Checks if the two items are Rows with identical `axuielement`s, and both not `nil`.
function Row:__eq(other)
    local ui = self:UI()
    return ui ~= nil and other.UI and ui == other:UI()
end

return Row
