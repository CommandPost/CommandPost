--- === cp.ui.Table ===
---
--- A Table UI element.

local require = require

-- local log                                   = require "hs.logger".new "Table"

local LazyList                              = require "cp.collect.LazyList"

local fn                                    = require "cp.fn"
local ax                                    = require "cp.fn.ax"
local prop                                  = require "cp.prop"
local Column                                = require "cp.ui.Column"
local Element                               = require "cp.ui.Element"
local Row                                   = require "cp.ui.Row"

local class                                 = require "middleclass"

local chain                                 = fn.chain
local get                                   = fn.table.get

local Table = Element:subclass("cp.ui.Table")

--- cp.ui.Table.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Table`.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * A boolean
Table.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXTable")

--- cp.ui.Table.withRowsOf(...) -> function(parent, uiFinder) -> Table
--- Function
--- A combinator that returns a function expecting a `parent` and `uiFinder` and returns a `Table` instance, with
--- the arguments defining the [Cell](cp.ui.Cell.md.html) instances that make up the rows of the table.
---
--- Parameters:
---  * ... - One or more arguments to pass to the constructor.
---
--- Returns:
---  * A function that will return a new `Table` instance.
function Table.static.withRowsOf(...)
    local factory = Table.OfRows(...)
    return function(parent, uiFinder)
        return Table(parent, uiFinder, factory)
    end
end

-- cp.ui.Table(parent, uiFinder, factory) -> cp.ui.Table
-- Constructor
-- Creates a new `Table` instance.
--
-- Parameters:
--  * parent - The parent `Element` instance.
--  * uiFinder - A `hs.uielement` or `axuielementObject` that will be used to find this element.
--  * cellTypes - A table of `cp.ui.Element` initialisers which will be the content of the [Cell](cp.ui.Cell.md) instances.
--
-- Returns:
--  * A new `Table` instance.
function Table:initialize(parent, uiFinder, factory)
    Element.initialize(self, parent, uiFinder)

    self._factory = factory

    self._headerType = Element
    self._rowType = Row
    self._columnType = Column
end

--- cp.ui.Table:headerType(elementType) -> cp.ui.Table
--- Method
--- Sets the `headerType` for the header.
---
--- Parameters:
---  * `elementType`	- The `Element` type to use for the header, or a function that accepts `parent` and `uiFinder` and returns an `Element`.
---
--- Returns:
---  * The `Table` instance (for chaining).
function Table:headerType(elementType)
    self._headerType = elementType
    return self
end

--- cp.ui.Table:rowType(rowType) -> cp.ui.Table
--- Method
--- Sets the `rowType` for the rows.
---
--- Parameters:
---  * `rowType`	- The `Row` type to use for the rows, or a function that accepts `parent` and `uiFinder` and returns a `Row`.
---
--- Returns:
---  * The `Table` instance (for chaining).
function Table:rowType(rowType)
    self._rowType = rowType
    return self
end

-- cp.ui.Table:columnType(columnType) -> cp.ui.Table
-- Method
-- Sets the `columnType` for the columns.
--
-- Parameters:
--  * `columnType`	- The `Column` type to use for the columns, or a function that accepts `parent` and `uiFinder` and returns a `Column`.
--
-- Returns:
--  * The `Table` instance (for chaining).
function Table:columnType(columnType)
    self._columnType = columnType
    return self
end


--- cp.ui.Table.header <cp.ui.Element>
--- Field
--- The `Element` representing the `AXHeader` of the `Table`.
function Table.lazy.value:header()
    return self._headerType(self, self.UI:mutate(ax.attribute "AXHeader"))
end

--- cp.ui.Table.rowsUI <cp.prop: table of axuielement; live?; read-only>
--- Field
--- The list of `Row`s which are children of this `Table`.
function Table.lazy.prop:rowsUI()
    return ax.prop(self.UI, "AXRows")
end

--- cp.ui.Table.rows <table of cp.ui.Row; live?; read-only>
--- Field
--- The list of `Row`s which are children of this `Table`.
function Table.lazy.value:rows()
    return self._factory:createRows(self, self.rowsUI)
end

--- cp.ui.Table.selectedRowsUI <cp.prop: table of cp.ui.Row; live?; read-only>
--- Field
--- The list of `Row`s which are selected in this `Table`.
function Table.lazy.prop:selectedRowsUI()
    return ax.prop(self.UI, "AXSelectedRows")
end

--- cp.ui.Table.visibleRowsUI <cp.prop: table of cp.ui.Row; live?; read-only>
--- Field
--- The list of `Row`s which are visible in this `Table`.
function Table.lazy.prop:visibleRowsUI()
    return ax.prop(self.UI, "AXVisibleRows")
end

--- cp.ui.Table.columnsUI <cp.prop: table of axuielement; live?; read-only>
--- Field
--- The list of `Column`s which are children of this `Table`.
function Table.lazy.prop:columnsUI()
    return ax.prop(self.UI, "AXColumns")
end

--- cp.ui.Table.selectedColumnsUI <cp.prop: table of cp.ui.Column; live?; read-only>
--- Field
--- The list of `Column`s which are selected in this `Table`.
function Table.lazy.prop:selectedColumnsUI()
    return ax.prop(self.UI, "AXSelectedColumns")
end

--- cp.ui.Table.visibleColumnsUI <cp.prop: table of cp.ui.Column; live?; read-only>
--- Field
--- The list of `Column`s which are visible in this `Table`.
function Table.lazy.prop:visibleColumnsUI()
    return ax.prop(self.UI, "AXVisibleColumns")
end

-- === cp.ui.Table.Factory ===
--
-- A factory for processing `Table` contents.
Table.Factory = class("cp.ui.Table.Factory")

-- Table.Factory:createRow(tbl, rowFinder) -> cp.ui.Row
-- Function
-- Creates a new `Row` instance.
--
-- Parameters:
--  * tbl - The `Table` instance.
--  * row - A callable that will return the `axuielementObject` for the row.
--
-- Returns:
--  * The new `Row` instance.
function Table.Factory.createRow(_, _)
    error("Unimplemented", 2)
end

-- cp.ui.Table.Factory:createRows(tableUI) -> table of cp.ui.Row
-- Function
-- Creates the rows for the `Table`.
--
-- Parameters:
--  * tableUI - The `axuielementObject` for the `Table`.
--
-- Returns:
--  * A table of `Row`s.
function Table.Factory.createRows(_)
    error("Unimplemented", 2)
end

--- === cp.ui.Table.OfRows === ---
---
--- Processes the contents of the Table as a list of rows.
--- Each of the defined `Element` initialisers will be used to create a cell within each `Row`.
Table.OfRows = class("cp.ui.Table.OfRows")

--- cp.ui.Table.OfRows(...) -> cp.ui.Table.OfRows
--- Constructor
--- Creates a new `Table.OfRows` instance.
---
--- Parameters:
---  * ... - The `Cell` initialisers.
---
--- Returns:
---  * A new `Table.OfRows` instance.
function Table.OfRows:initialize(...)
    self._cellInitialisers = {...}
end

--- cp.ui.Table.OfRows:createRow(tbl, rowFinder) -> cp.ui.Row
--- Method
--- Creates a new `Row` instance.
---
--- Parameters:
---  * tbl - The `Table` instance.
---  * rowFinder - a callable that will return the `axuielementObject` for the row.
---
--- Returns:
---  * The new `Row` instance.
function Table.OfRows:createRow(tbl, rowFinder)
    return tbl._rowType(tbl, rowFinder, self._cellInitialisers)
end

--- cp.ui.Table.OfRows:createRows(tbl, rowsFinder) -> table of cp.ui.Row
--- Method
--- Creates the [Row](cp.ui.Row.md)s for the `Table`.
---
--- Parameters:
---  * tbl - The `Table` instance
---  * rowsFinder - a callable that will return the a table of `cp.ui.Row` values.
---
--- Returns:
---  * A table of `Row`s.
function Table.OfRows:createRows(tbl, rowsFinder)
    local rowsProp = prop.FROM(rowsFinder)

    return LazyList(
        function()
            local rowsUI = rowsProp()
            return rowsUI and #rowsUI or 0
        end,
        function(index)
            return self:createRow(
                tbl,
                rowsProp:mutate(chain // ax.uielementList >> get(index))
            )
        end
    )
end

return Table