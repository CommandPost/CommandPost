--- === cp.ui.Outline ===
---
--- Represents an `AXOutline` `axuielement`.

local log                       = require "hs.logger" .new "Outline"

local prop	                    = require "cp.prop"
local axutils	                = require "cp.ui.axutils"
local Column                    = require "cp.ui.Column"
local Element	                = require "cp.ui.Element"
local Row                       = require "cp.ui.Row"

local valueOf	                = axutils.valueOf
local insert	                = table.insert

local Outline = Element:subclass("cp.ui.Outline")

-- _cleanCache()
-- Local Function
-- Clears the cache of any invalid (aka dead) rows.
local function _cleanCache(cache)
    if cache then
        for ui,_ in pairs(cache) do
            if not axutils.isValid(ui) then
                cache[ui] = nil
            end
        end
    end
end

-- _cachedElement(cache, ui) -> cp.ui.Element or nil
-- Local Function
-- Returns the cached [Element](cp.ui.Element.md), if it is present.
local function _cachedElement(cache, ui)
    for cachedUI,row in pairs(cache) do
        if cachedUI == ui then
            return row
        end
    end
end

-- _cacheElement(cache, element[, ui])
-- Local Function
-- Caches the provided [Element](cp.ui.Element.md).
--
-- Parameters:
-- * element - the [Element](cp.ui.Element.md)
local function _cacheElement(cache, element, ui)
    ui = ui or element:UI()
    if axutils.isValid(ui) then
        cache[ui] = element
    end
end

local function _findElement(cache, ui, parent, createFn)
    if ui:attributeValue("AXParent") ~= parent:UI() then
        return nil
    end

    if not axutils.isValid(ui) then
        return nil
    end

    local element = _cachedElement(cache, ui)
    if not element then
        element = createFn(parent, ui)
        _cacheElement(cache, element, ui)
    end
    return element
end

local function _findElements(cache, uis, parent, createFn)
    if uis then
        _cleanCache(cache)
        local elements = {}

        for _,ui in ipairs(uis) do
            insert(elements, _findElement(cache, ui, parent, createFn))
        end

        return elements
    end
end

--- cp.ui.Outline.matches(element) -> boolean
--- Function
--- Checks if the `element` is an `Outline`.
function Outline.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXOutline"
end

--- cp.ui.Outline(parent, uiFinder) -> cp.ui.Outline
--- Constructor
--- Creates a new `Outline` with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - The parent instance.
--- * uiFinder - A `function` or a `cp.prop` which will return the `AXOutline` `axuielement`.
---
--- Returns:
--- * The new `Outline` instance.
function Outline:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
    self._rowCache = {}
    self._columnCache = {}
end

--- cp.ui.Outline:childrenUI() -> table
--- Method
--- Provides a `table` containing the `axuielement`s which are children of the outline.
function Outline:childrenUI()
    return valueOf(self:UI(), "AXChildren")
end

--- cp.ui.Outline:columnsUI() -> table
--- Method
--- Provides a `table` containing the `axuielement`s which are columns of the outline.
function Outline:columnsUI()
    return valueOf(self:UI(), "AXColumns")
end

--- cp.ui.Outline:createColumn(columnUI) -> cp.ui.Column
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
function Outline:createColumn(columnUI)
    assert(Column.matches(columnUI), "The provided columnUI is not an AXColumn")
    assert(columnUI:attributeValue("AXParent") == self:UI(), "The provided `columnUI` is not in this Outline.")
    return Column(self, prop.THIS(columnUI))
end

function Outline:columns()
    return self:findColumns(self:columnsUI())
end

--- cp.ui.Outline:findColumn(columnUI) -> cp.ui.Column or nil
--- Method
--- Returns the [Column](cp.ui.Column.md) that represents the provided `columnUI`, if it is actually present
--- in the `Outline`.
---
--- Parameters:
--- * columnUI - The `axuielement` for the `AXColumn` to find a [Column](cp.ui.Column.md) for.
---
--- Returns:
--- * The [Column](cp.ui.Column.md), or `nil` if the `columnUI` is not in this `Outline`.
function Outline:findColumn(columnUI)
    return _findElement(self._columnCache, columnUI, self, self.createColumn)
end

--- cp.ui.Outline:findColumn(columnsUI) -> table of cp.ui.Columns
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
function Outline:findColumns(columnsUI)
    return _findElements(self._columnCache, columnsUI, self, self.createColumn)
end

--- cp.ui.Outline:rowsUI() -> table of axuielement
--- Method
--- Provides a `table` containing the `axuielement`s which are rows in the outline.
function Outline:rowsUI()
    return valueOf(self:UI(), "AXRows")
end

--- cp.ui.Outline:createRow(rowUI) -> cp.ui.Row
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
function Outline:createRow(rowUI)
    assert(rowUI:attributeValue("AXParent") == self:UI(), "The provided `rowUI` is not in this Outline.")
    return Row(self, prop.THIS(rowUI))
end

--- cp.ui.Outline:rows() -> table of cp.ui.Row or nil
--- Method
--- Provides a `table` with the list of `cp.ui.Row` elements for the rows.
---
--- Returns:
--- * A table containing the list of [Row](cp.ui.Row.md)s in the `Outline`, or `nil` if the `Outline` is not presently available.
function Outline:rows()
    return self:findRows(self:rowsUI())
end

--- cp.ui.Outline:findRow(rowUI) -> cp.ui.Row or nil
--- Method
--- Returns the [Row](cp.ui.Row.md) that represents the provided `rowUI`, if it is actually present
--- in the `Outline`.
---
--- Parameters:
--- * rowUI - The `axuielement` for the `AXRow` to find a [Row](cp.ui.Row.md) for.
---
--- Returns:
--- * The [Row](cp.ui.Row.md), or `nil` if the `rowUI` is not in this `Outline`.
function Outline:findRow(rowUI)
    return _findElement(self._rowCache, rowUI, self, self.createRow)
end

--- cp.ui.Outline:findRows(rowsUI) -> table of cp.ui.Rows
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
function Outline:findRows(rowsUI)
    return _findElements(self._rowCache, rowsUI, self, self.createRow)
end

return Outline