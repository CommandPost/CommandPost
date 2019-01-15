--- === cp.ui.Grid ===
---
--- Abstract base class for `AX` elements which form a grid, such as [Table2](cp.ui.Table2.md) and [Outline](cp.ui.Outline.md).

-- local log                       = require "hs.logger" .new "Grid"

local funtils	                = require "hs.fnutils"

local prop	                    = require "cp.prop"
local axutils	                = require "cp.ui.axutils"
local Column                    = require "cp.ui.Column"
local Element	                = require "cp.ui.Element"
local ElementCache	            = require "cp.ui.ElementCache"
local Row                       = require "cp.ui.Row"

local valueOf                   = axutils.valueOf
local ifilter	                = funtils.ifilter

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

--- cp.ui.Grid:childrenUI() -> table
--- Method
--- Provides a `table` containing the `axuielement`s which are children of the outline.
function Grid:childrenUI()
    return valueOf(self:UI(), "AXChildren")
end

--- cp.ui.Grid:columnsUI() -> table
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


return Grid