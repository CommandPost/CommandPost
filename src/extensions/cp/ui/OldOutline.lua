--- === cp.ui.OldOutline ===
---
--- Represents an `AXOutline` `axuielement`.

-- local log                       = require "hs.logger" .new "Outline"

local funtils	                = require "hs.fnutils"

local prop	                  = require "cp.prop"
local axutils	                = require "cp.ui.axutils"
local Column                  = require "cp.ui.OldColumn"
local Element	                = require "cp.ui.Element"
local Row                     = require "cp.ui.OldRow"

local valueOf                 = axutils.valueOf
local insert	                = table.insert
local ifilter	                = funtils.ifilter


local Outline = Element:subclass("cp.ui.OldOutline")

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

local function _fetchElement(cache, ui, parent, createFn)
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

local function _fetchElements(cache, uis, parent, createFn)
    if uis then
        _cleanCache(cache)
        local elements = {}

        for _,ui in ipairs(uis) do
            insert(elements, _fetchElement(cache, ui, parent, createFn))
        end

        return elements
    end
end

--- cp.ui.OldOutline.matches(element) -> boolean
--- Function
--- Checks if the `element` is an `Outline`.
---
--- Parameters:
---  * element - An element to check
---
--- Returns:
---  * A boolean
function Outline.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXOutline"
end

--- cp.ui.OldOutline(parent, uiFinder) -> cp.ui.OldOutline
--- Constructor
--- Creates a new `Outline` with the specified `parent` and `uiFinder`.
---
--- Parameters:
---  * parent - The parent instance.
---  * uiFinder - A `function` or a `cp.prop` which will return the `AXOutline` `axuielement`.
---
--- Returns:
---  * The new `Outline` instance.
function Outline:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
    self._rowCache = {}
    self._columnCache = {}
end

--- cp.ui.OldOutline:childrenUI() -> table
--- Method
--- Provides a `table` containing the `axuielement`s which are children of the outline.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function Outline:childrenUI()
    return valueOf(self:UI(), "AXChildren")
end

--- cp.ui.OldOutline:columnsUI() -> table
--- Method
--- Provides a `table` containing the `axuielement`s which are columns of the outline.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A Table
function Outline:columnsUI()
    return valueOf(self:UI(), "AXColumns")
end

--- cp.ui.OldOutline:createColumn(columnUI) -> cp.ui.OldColumn
--- Method
--- Attempts to create a new [Column](cp.ui.OldColumn.md) with the provided `columnUI` `axuielement`. If there is a problem, an `error` is thrown.
---
--- Parameters:
---  * columnUI - the `AXColumn` `axuielement` to create a [Column](cp.ui.OldColumn.md) for.
---
--- Returns:
---  * The [Column](cp.ui.OldColumn.md) or an error if a problem occurred.
---
--- Notes:
---  * Subclasses which want to provide a custom [Column](cp.ui.OldColumn.md) implementation should override this method.
function Outline:createColumn(columnUI)
    assert(Column.matches(columnUI), "The provided columnUI is not an AXColumn")
    assert(columnUI:attributeValue("AXParent") == self:UI(), "The provided `columnUI` is not in this Outline.")
    return Column(self, prop.THIS(columnUI))
end

--- cp.ui.OldOutline:columns() -> table of cp.ui.Columns
--- Method
--- Returns the list of [Column](cp.ui.OldColumn.md)s in this `Outline`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function Outline:columns()
    return self:fetchColumns(self:columnsUI())
end

--- cp.ui.OldOutline:fetchColumn(columnUI) -> cp.ui.OldColumn or nil
--- Method
--- Returns the [Column](cp.ui.OldColumn.md) that represents the provided `columnUI`, if it is actually present in the `Outline`.
---
--- Parameters:
---  * columnUI - The `axuielement` for the `AXColumn` to find a [Column](cp.ui.OldColumn.md) for.
---
--- Returns:
---  * The [Column](cp.ui.OldColumn.md), or `nil` if the `columnUI` is not in this `Outline`.
function Outline:fetchColumn(columnUI)
    return _fetchElement(self._columnCache, columnUI, self, self.createColumn)
end

--- cp.ui.OldOutline:fetchColumn(columnsUI) -> table of cp.ui.Columns
--- Method
--- Returns a `table` of the same length as `columnsUI`.
---
--- Parameters:
---  * columnsUI - The list of `AXColumn` `axuielement`s to find.
---
--- Returns:
---  * A `table` with the same number of elements, containing the matching [Column](cp.ui.OldColumn.md) instances.
---
--- Notes:
---  * If provided items in the table are not valid columns in this table, then `nil` will be put in the matching index.
---  * Note that this will break the standard `#`/looping behaviour for tables at that point.
function Outline:fetchColumns(columnsUI)
    return _fetchElements(self._columnCache, columnsUI, self, self.createColumn)
end

--- cp.ui.OldOutline:rowsUI() -> table of axuielement
--- Method
--- Provides a `table` containing the `axuielement`s which are rows in the outline.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function Outline:rowsUI()
    return valueOf(self:UI(), "AXRows")
end

--- cp.ui.OldOutline:createRow(rowUI) -> cp.ui.OldRow
--- Method
--- Attempts to create a new [Row](cp.ui.OldRow.md) with the provided `rowUI` `axuielement`. If there is a problem, an `error` is thrown.
---
--- Parameters:
---  * rowUI - the `AXRow` `axuielement` to create a [Row](cp.ui.OldRow.md) for.
---
--- Returns:
---  * The [Row](cp.ui.OldRow.md) or an error if a problem occurred.
---
--- Notes:
---  * Subclasses which want to provide a custom [Row](cp.ui.OldRow.md) implementation should override this method.
function Outline:createRow(rowUI)
    assert(rowUI:attributeValue("AXParent") == self:UI(), "The provided `rowUI` is not in this Outline.")
    return Row(self, prop.THIS(rowUI))
end

--- cp.ui.OldOutline:rows() -> table of cp.ui.OldRow or nil
--- Method
--- Provides a `table` with the list of `cp.ui.OldRow` elements for the rows.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the list of [Row](cp.ui.OldRow.md)s in the `Outline`, or `nil` if the `Outline` is not presently available.
function Outline:rows()
    return self:fetchRows(self:rowsUI())
end

--- cp.ui.OldOutline:fetchRow(rowUI) -> cp.ui.OldRow or nil
--- Method
--- Returns the [Row](cp.ui.OldRow.md) that represents the provided `rowUI`, if it is actually present in the `Outline`.
---
--- Parameters:
---  * rowUI - The `axuielement` for the `AXRow` to find a [Row](cp.ui.OldRow.md) for.
---
--- Returns:
---  * The [Row](cp.ui.OldRow.md), or `nil` if the `rowUI` is not in this `Outline`.
function Outline:fetchRow(rowUI)
    return _fetchElement(self._rowCache, rowUI, self, self.createRow)
end

--- cp.ui.OldOutline:fetchRows(rowsUI) -> table of cp.ui.OldRows
--- Method
--- Returns a `table` of the same length as `rowsUI`.
---
--- Parameters:
---  * rowsUI - The list of `AXRow` `axuielement`s to find.
---
--- Returns:
---  * A `table` with the same number of elements, containing the matching [Row](cp.ui.OldRow.md) instances.
---
--- Notes:
---  * If provided items in the table are not valid rows in this table, then `nil` will be put in the matching index.
---  * Note that this will break the standard `#`/looping behaviour for tables at that point.
function Outline:fetchRows(rowsUI)
    return _fetchElements(self._rowCache, rowsUI, self, self.createRow)
end

--- cp.ui.OldOutline:filterRows(matcherFn) -> table of cp.ui.OldRows or nil
--- Method
--- Returns a table only containing [Row](cp.ui.OldRow.md)s which pass the predicate `matcherFn`. The function is passed the row and returns a boolean.
---
--- Parameters:
---  * matcherFn	- the `function` that will accept a [Row](cp.ui.OldRow.md) and return a `boolean`.
---
--- Returns:
---  * A `table` of [Row](cp.ui.OldRow.md)s, or `nil` if no UI is currently available.
function Outline:filterRows(matcherFn)
    local rows = self:rows()
    return rows and ifilter(rows, matcherFn)
end


return Outline
