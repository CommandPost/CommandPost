--- === cp.ui.Cell ===
---
--- Represents an `AXCell` `axuielement`.

local axutils	                    = require "cp.ui.axutils"
local Element	                    = require "cp.ui.Element"

local Cell = Element:subclass("cp.ui.Cell")

--- cp.ui.Cell.matches(element) ->  boolean
--- Function
--- Checks if the `element` is an `AXCell`.
function Cell.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXCell"
end

--- cp.ui.Cell.columnIndexRange <cp.prop: table; read-only>
--- Field
--- Returns a table of `{len,loc}`, which indicates if the cell covers multiple columns.
function Cell.lazy.prop:columnIndexRange()
    return axutils.prop(self.UI, "AXColumnIndexRange")
end

--- cp.ui.Cell.rowIndexRange <cp.prop: table; read-only>
--- Field
--- Returns a table of `{len,loc}`, which indicates if the cell covers multiple rows.
function Cell.lazy.prop:rowIndexRange()
    return axutils.prop(self.UI, "AXRowIndexRange")
end

--- cp.ui.Cell.selected <cp.prop: table>
--- Field
--- Indicates if the cell is currently selected.
function Cell.lazy.prop:selected()
    return axutils.prop(self.UI, "AXSelected")
end

--- cp.ui.Cell.childrenUI <cp.prop: table of axuielement; read-only>
--- Field
--- The list of `axuielement`s which are children of this `Cell`.
function Cell.lazy.prop:childrenUI()
    return axutils.prop(self.UI, "AXChildren")
end

--- cp.ui.Cell.value <cp.prop: anything>
--- Field
--- The cell value.
function Cell.lazy.prop:value()
    return axutils.prop(self.UI, "AXValue", true)
end

--- cp.ui.Cell.value <cp.prop: string>
--- Field
--- The cell value, if it is a string.
function Cell.lazy.prop:textValue()
    return self.value:mutate(function(original)
        local value = original()
        return type(value) == "string" and value or nil
    end)
end

return Cell