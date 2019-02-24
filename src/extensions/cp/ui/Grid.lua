--- === cp.ui.Grid ===
---
--- Abstract base class for `AX` elements which form a grid, such as [Table2](cp.ui.Table2.md) and [Outline](cp.ui.Outline.md).

-- local log                       = require "hs.logger" .new "Grid"

local fnutils	                = require "hs.fnutils"

local prop	                    = require "cp.prop"
local axutils	                = require "cp.ui.axutils"
local Column                    = require "cp.ui.Column"
local Element	                = require "cp.ui.Element"
local ElementCache	            = require "cp.ui.ElementCache"
local Row                       = require "cp.ui.Row"

local valueOf                   = axutils.valueOf
local ifilter, find, map        = fnutils.ifilter, fnutils.find, fnutils.map

local Do                        = require "cp.rx.go.Do"

local Grid = Element:subclass("cp.ui.Grid")

--- cp.ui.Grid.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `Grid`.
---
--- Parameters:
---  * `thing`		- The thing to check
---
--- Returns:
---  * `true` if the thing is a `Table` instance.
function Grid.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(Grid)
end

--- cp.ui.Grid.matches(element) -> boolean
--- Function
--- Checks if the `element` is an `Grid`.
function Grid.static.matches(element)
    return Element.matches(element) and (element:attributeValue("AXRows") ~= nil or element:attributeValue("AXColumns") ~= nil)
end

--- cp.ui.Grid(parent, uiFinder) -> cp.ui.Grid
--- Constructor
--- Creates a new `Grid` with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - The parent instance.
--- * uiFinder - A `function` or a `cp.prop` which will return the `axuielement`.
---
--- Returns:
--- * The new `Grid` instance.
function Grid:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
    self._rowCache = ElementCache(self, self.createRow)
    self._columnCache = ElementCache(self, self.createColumn)
end

--- cp.ui.Grid:childrenUI() -> table of axuielements
--- Method
--- Provides a `table` containing the `axuielement`s which are children of the outline.
function Grid:childrenUI()
    return valueOf(self:UI(), "AXChildren")
end

--- cp.ui.Grid:columnsUI() -> table of axuielements
--- Method
--- Provides a `table` containing the `axuielement`s which are columns of the outline.
function Grid:columnsUI()
    return valueOf(self:UI(), "AXColumns")
end

--- cp.ui.Grid:createColumn(columnUI) -> cp.ui.Column
--- Method
--- Attempts to create a new [Column](cp.ui.Column.md) with the provided `columnUI` `axuielement`.
--- If there is a problem, an `error` is thrown.
---
--- Parameters:
--- * columnUI - the `AXColumn` `axuielement` to create a [Column](cp.ui.Column.md) for.
---
--- Returns:
--- * The [Column](cp.ui.Column.md) or an error if a problem occurred.
---
--- Notes:
--- * Subclasses which want to provide a custom [Column](cp.ui.Column.md) implementation should override this method.
function Grid:createColumn(columnUI)
    assert(Column.matches(columnUI), "The provided columnUI is not an AXColumn")
    assert(columnUI:attributeValue("AXParent") == self:UI(), "The provided `columnUI` belongs to someone else.")
    return Column(self, prop.THIS(columnUI))
end

--- cp.ui.Grid:columns() -> table of cp.ui.Columns
--- Method
--- Returns the list of [Column](cp.ui.Column.md)s.
function Grid:columns()
    return self:fetchColumns(self:columnsUI())
end

--- cp.ui.Grid:column(index) -> cp.ui.Column or nil
--- Method
--- Provides the [Column](cp.ui.Column.md) at the specified index, or `nil` if it's not available.
function Grid:column(index)
    local columns = self:columns()
    return columns and columns[index]
end

--- cp.ui.Grid:fetchColumn(columnUI) -> cp.ui.Column or nil
--- Method
--- Returns the [Column](cp.ui.Column.md) that represents the provided `columnUI`, if it is actually present.
---
--- Parameters:
--- * columnUI - The `axuielement` for the `AXColumn` to find a [Column](cp.ui.Column.md) for.
---
--- Returns:
--- * The [Column](cp.ui.Column.md), or `nil` if the `columnUI` is not available.
function Grid:fetchColumn(columnUI)
    return self._columnCache:fetchElement(columnUI)
end

--- cp.ui.Grid:fetchColumn(columnsUI) -> table of cp.ui.Columns
--- Method
--- Returns a `table` of the same length as `columnsUI`.
--- If provided items in the table are not valid columns in this table, then `nil` will be put in the matching index.
--- Note that this will break the standard `#`/looping behaviour for tables at that point.
---
--- Parameters:
--- * columnsUI - The list of `AXColumn` `axuielement`s to find.
---
--- Returns:
--- * A `table` with the same number of elements, containing the matching [Column](cp.ui.Column.md) instances.
function Grid:fetchColumns(columnsUI)
    return self._columnCache:fetchElements(columnsUI)
end

--- cp.ui.Grid:rowsUI() -> table of axuielement
--- Method
--- Provides a `table` containing the `axuielement`s which are rows in the outline.
function Grid:rowsUI()
    return valueOf(self:UI(), "AXRows")
end

--- cp.ui.Grid:createRow(rowUI) -> cp.ui.Row
--- Method
--- Attempts to create a new [Row](cp.ui.Row.md) with the provided `rowUI` `axuielement`.
--- If there is a problem, an `error` is thrown.
---
--- Parameters:
--- * rowUI - the `AXRow` `axuielement` to create a [Row](cp.ui.Row.md) for.
---
--- Returns:
--- * The [Row](cp.ui.Row.md) or an error if a problem occurred.
---
--- Notes:
--- * Subclasses which want to provide a custom [Row](cp.ui.Row.md) implementation should override this method.
function Grid:createRow(rowUI)
    assert(rowUI:attributeValue("AXParent") == self:UI(), "The provided `rowUI` not from here.")
    return Row(self, prop.THIS(rowUI))
end

--- cp.ui.Grid:rows() -> table of cp.ui.Row or nil
--- Method
--- Provides a `table` with the list of `cp.ui.Row` elements for the rows.
---
--- Returns:
--- * A table containing the list of [Row](cp.ui.Row.md)s, or `nil` if not presently available.
function Grid:rows()
    return self:fetchRows(self:rowsUI())
end

--- cp.ui.Grid:row(index) -> cp.ui.Row or nil
--- Method
--- Provides the [Row](cp.ui.Row.md) at the specified index, or `nil` if it's not available.
function Grid:row(index)
    local rows = self:rows()
    return rows and rows[index]
end

--- cp.ui.Grid:fetchRow(rowUI) -> cp.ui.Row or nil
--- Method
--- Returns the [Row](cp.ui.Row.md) that represents the provided `rowUI`, if it is actually present.
---
--- Parameters:
--- * rowUI - The `axuielement` for the `AXRow` to find a [Row](cp.ui.Row.md) for.
---
--- Returns:
--- * The [Row](cp.ui.Row.md), or `nil` if the `rowUI` is not available.
function Grid:fetchRow(rowUI)
    return self._rowCache:fetchElement(rowUI)
end

--- cp.ui.Grid:fetchRows(rowsUI) -> table of cp.ui.Rows
--- Method
--- Returns a `table` of the same length as `rowsUI`.
--- If provided items in the table are not valid rows in this table, then `nil` will be put in the matching index.
--- Note that this will break the standard `#`/looping behaviour for tables at that point.
---
--- Parameters:
--- * rowsUI - The list of `AXRow` `axuielement`s to find.
---
--- Returns:
--- * A `table` with the same number of elements, containing the matching [Row](cp.ui.Row.md) instances.
function Grid:fetchRows(rowsUI)
    return self._rowCache:fetchElements(rowsUI)
end

--- cp.ui.Grid:filterRows(matcherFn) -> table of cp.ui.Rows or nil
--- Method
--- Returns a table only containing [Row](cp.ui.Row.md)s which pass the predicate `matcherFn`.
--- The function is passed the row and returns a boolean.
---
--- Parameters:
--- * matcherFn	- the `function` that will accept a [Row](cp.ui.Row.md) and return a `boolean`.
---
--- Returns:
--- * A `table` of [Row](cp.ui.Row.md)s, or `nil` if no UI is currently available.
function Grid:filterRows(matcherFn)
    local rows = self:rows()
    return rows and ifilter(rows, matcherFn)
end

--- cp.ui.Grid:findRow(matcherFn) -> cp.ui.Row or nil
--- Method
--- Returns a [Row](cp.ui.Row.md) that has a result of `true` when passed to the `matcherFn` predicate,
--- or `nil` if none was matched.
---
--- Parameters:
--- * matcherFn - The function to check the [Row](cp.ui.Row.md) with.
---
--- Returns:
--- * The matching [Row](cp.ui.Row.md) or `nil`.
function Grid:findRow(matcherFn)
    local rows = self:rows()
    return rows and find(rows, matcherFn)
end

local function walkRows(rows, path, actionFn)
    if rows then
        local name = table.remove(path, 1)
        for _,row in ipairs(rows) do
            local cell = row:cells()[1]
            if cell:textValueIs(name) then
                if #path > 0 then
                    row:discloseRow()
                    return walkRows(row:disclosedRows(), path, actionFn)
                else
                    actionFn(row)
                    return row
                end
            end
        end
    end
    return nil
end

--- cp.ui.Grid:visitRow(path, actionFn) -> cp.ui.Row
--- Method
--- Visits the row at the sub-level named in the `names` table, and executes the `actionFn`.
---
--- Parameters:
---  * `names`		- The array of names to navigate down
---  * `actionFn`	- A function to execute when the target row is found.
---
--- Returns:
---  * The row that was visited, or `nil` if not.
function Grid:visitRow(path, actionFn)
    return walkRows(self:rows(), path, actionFn)
end

--- cp.ui.Grid:findColumnIndex(id) -> number | nil
--- Method
--- Finds the Column Index based on an `AXIdentifier` ID.
---
--- Parameters:
---  * id - The `AXIdentifier` of the column index you want to find.
---
--- Returns:
---  * A column index as a number, or `nil` if no index can be found.
function Grid:findColumnIndex(id)
    local cols = self:columns()
    if cols then
        for i=1,#cols do
            if cols[i]:identifier() == id then
                return i
            end
        end
    end
    return nil
end

--- cp.ui.Grid:findCell(rowNumber, columnId) -> `hs._asm.axuielement` | nil
--- Method
--- Finds a specific [Cell](cp.ui.Cell.md).
---
--- Parameters:
---  * rowNumber - The row number.
---  * columnId - The Column ID.
---
--- Returns:
---  * A `hs._asm.axuielement` object for the cell, or `nil` if the cell cannot be found.
function Grid:findCell(rowNumber, columnId)
    local rows = self:rows()
    if rows and rowNumber >= 1 and rowNumber < #rows then
        local colNumber = self:findColumnIndex(columnId)
        return colNumber and rows[rowNumber]:cells()[colNumber]
    end
    return nil
end

--- cp.ui.Grid:selectRow(path) -> cp.ui.Row
--- Method
--- Selects the row at the sub-level named in the `path` table.
---
--- Parameters:
--- * path - A `table` of names to navigate through to find the [Row](cp.ui.Row.md) to select.
---
--- Returns:
--- * The selected [Row](cp.ui.Row.md), or `nil` if not found.
function Grid:selectRow(path)
    return self:visitRow(path, function(row) row:selected(true) end)
end

--- cp.ui.Grid:doSelectRow(path) -> [Statement](cp.rx.go.Statement.md)
--- Method
--- Selects the row at the sub-level named in the `path` table.
---
--- Parameters:
--- * path - A `table` of names to navigate through to find the [Row](cp.ui.Row.md) to select.
---
--- Returns:
--- * The selected [Row](cp.ui.Row.md), or `nil` if not found.
function Grid:doSelectRow(path)
    return Do(function()
        return self:visitRow(path, function(row) row:selected(true) end)
    end)
end

--- cp.ui.Grid.selectedRowsUI <cp.prop: table of axuielement; live?>
--- Field
--- Contains the list of currently-selected row `axuilements`. Can be set.
---
--- Notes:
--- * Also see [#selectedRows]
function Grid.lazy.prop:selectedRowsUI()
    return axutils.prop(self.UI, "AXSelectedRows", true)
end

--- cp.ui.Grid.selectedRows <cp.prop: table of cp.ui.Row; live?>
--- Field
--- Contains the list of currently-selected [Row](cp.ui.Row.md)s. Can be set.
function Grid.lazy.prop:selectedRows()
    return self.selectedRows:mutate(function(original)
        local rowsUI = original()
        return self:fetchRows(rowsUI)
    end),
    function(newRows, original)
        if newRows then
            local rowsUI = map(newRows, function(row) return row:UI() end)
            original(rowsUI)
        else
            original(nil)
        end
    end
end

return Grid