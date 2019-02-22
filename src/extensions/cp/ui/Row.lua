--- === cp.ui.Row ===
---
--- Represents an `AXRow` `axuielement`.

-- local log	                = require "hs.logger" .new "Row"

local go	                = require "cp.rx.go"
local prop	                = require "cp.prop"
local axutils	            = require "cp.ui.axutils"
local Cell	                = require "cp.ui.Cell"
local Element	            = require "cp.ui.Element"
local ElementCache	        = require "cp.ui.ElementCache"

local If , Do               = go.If, go.Do

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Row = Element:subclass("cp.ui.Row")

--- cp.ui.Row.matches(element) -> boolean
--- Method
--- Checks if the element is a `Row`.
---
--- Parameters:
--- * element - the `axuielement` to check.
---
--- Returns:
--- * `true` if it matches, otherwise `false`.
function Row.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXRow"
end

--- cp.ui.Row(parent, uiFinder)
--- Constructor
--- Creates a new `Row` based on the provided parent [Element](cp.ui.Element.md) and `uiFinder`.
---
--- Parameters:
--- * parent	- The parent [Element](cp.ui.Element.md)
--- * uiFinder	- Either a function or [prop](cp.prop.md)
function Row:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
    self._cellCache = ElementCache(self, self.createCell)
end

--- cp.ui.Row:createCell(ui) -> cp.ui.Cell
--- Method
--- This method creates a new [Cell](cp.ui.Cell.md) based on the provided `axuielement` value.
--- Subclasses should override this method to create custom suclasses of [Cell](cp.ui.Cell.md)
--- if necessary.
---
--- Parameters:
--- * ui - The `AXCell` `axuielement` to create a [Cell](cp.ui.Cell.md) for.
---
--- Returns:
--- * The new [Cell](cp.ui.Cell.md) (or subclass) instance.
function Row:createCell(ui)
    return Cell(self, prop.THIS(ui))
end

--- cp.ui.Row.disclosing <cp.prop: boolean>
--- Field
--- Indicates if the `Row` is disclosing other `Rows`.
function Row.lazy.prop:disclosing()
    return axutils.prop(self.UI, "AXDisclosing", true)
end

--- cp.ui.Row.disclosureLevel <cp.prop: number; read-only>
--- Field
--- The depth of disclosure. `0` is the top level.
function Row.lazy.prop:disclosureLevel()
    return axutils.prop(self.UI, "AXDisclosureLevel")
end

--- cp.ui.Row:disclosedByRow() -> cp.ui.Row
--- Method
--- The `Row` which is disclosing this `Row`.
function Row.lazy.prop:disclosedByRow()
    return axutils.prop(self.UI, "AXDisclosedByRow"):mutate(function(original)
        return self:parent():fetchRow(original())
    end)
end

--- cp.ui.Row:disclosedRows() -> table of cp.ui.Row or nil
--- Method
--- If available, returns a table of [Row](cp.ui.Row.md)s that are disclosed by this `Row`.
--- If this row is currently unavailable, `nil` is returned.
---
--- Returns:
--- * The `table` of Rows, or `nil`.
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
    return axutils.prop(self.UI, "AXSelected", true)
end

--- cp.ui.Row.index <cp.prop: number; read-only>
--- Field
--- The numeric index of this row in the overall container, with `0` being the first item.
function Row.lazy.prop:index()
    return axutils.prop(self.UI, "AXIndex")
end

--- cp.ui.Row.childrenUI <cp.prop: table of axuielement; read-only>
--- Field
--- The list of `axuielement` children.
function Row.lazy.prop:childrenUI()
    return axutils.prop(self.UI, "AXChildren")
end

--- cp.ui.Row.cells <cp.prop: table of Cell; read-only>
--- Field
--- The list of [Cell](cp.ui.Cell.md)s in the row.
function Row.lazy.prop:cells()
    return self.childrenUI:mutate(function(original)
        return self._cellCache:fetchElements(original())
    end)
end

--- cp.ui.Row:doDisclose() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will disclose the row contents.
function Row.lazy.method:doDisclose()
    return If(self.disclosing):Is(false)
    :Then(function()
        self:disclosing(true)
        return true
    end)
    :Otherwise(false)
    :Label("Row:doDisclose")
end

--- cp.ui.Row:doConceal() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will conceal the row contents.
function Row.lazy.method:doConceal()
    return If(self.disclosing)
    :Then(function()
        self:disclosing(false)
        return true
    end)
    :Otherwise(false)
    :Label("Row:doConceal")
end

--- cp.ui.Row:doToggle() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that toggles disclosing the row contents.
function Row.lazy.method:doToggle()
    return Do(function()
        self:disclosing(false)
        return true
    end)
    :Label("Row:doToggle")
end

--- cp.ui.Row:doSelect() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempts to select the row, if it is available.
function Row.lazy.method:doSelect()
    return Do(function()
        self:selected(true)
    end)
    :Label("Row:doSelect")
end

--- cp.ui.Row:doDeselect() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempts to deselect the row, if it is available.
function Row.lazy.method:doDeselect()
    return Do(function()
        self:selected(false)
    end)
end

-- cp.ui.Row:__eq(other) -> boolean
-- Function
-- Checks if the two items are Rows with identical `axuielement`s, and both not `nil`.
function Row:__eq(other)
    local ui = self:UI()
    return ui ~= nil and other.UI and ui == other:UI()
end

return Row
