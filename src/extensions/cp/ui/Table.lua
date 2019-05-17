--- === cp.ui.Table ===
---
--- Represents an AXTable in the Apple Accessibility UX API.

local require           = require

--local log				= require "hs.logger".new "table"

local axutils           = require "cp.ui.axutils"

local Button            = require "cp.ui.Button"
local Element           = require "cp.ui.Element"
local Group             = require "cp.ui.Group"
local MenuButton        = require "cp.ui.MenuButton"
local StaticText        = require "cp.ui.StaticText"
local TextField         = require "cp.ui.TextField"

local childMatching     = axutils.childMatching

local Table = Element:subclass("cp.ui.Table")

--- cp.ui.Table.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `Table`.
---
--- Parameters:
---  * `thing`      - The thing to check
---
--- Returns:
---  * `true` if the thing is a `Table` instance.
function Table.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(Table)
end

--- cp.ui.Table.cellTextValue(cell) -> boolean
--- Function
--- Returns the cell's text value.
---
--- Parameters:
---  * `cell`   - The cell to check
---
--- Returns:
---  * The combined text value of the cell.
function Table.static.cellTextValue(cell)
    local textValue = nil
    if #cell > 0 then
        for _,item in ipairs(cell) do
            local itemValue = item:attributeValue("AXValue")
            if type(itemValue) == "string" then
                textValue = (textValue or "") .. itemValue
            end
        end
    else
        local cellValue = cell:attributeValue("AXValue")
        if type(cellValue) == "string" then
            textValue = cellValue
        end
    end
    return textValue
end

--- cp.ui.Table.cellTextValueIs(cell, value) -> boolean
--- Function
--- Checks if the cell's text value equals `value`.
---
--- Parameters:
---  * `cell`   - The cell to check
---  * `value`  - The text value to compare.
---
--- Returns:
---  * `true` if the cell text value equals the provided `value`.
function Table.static.cellTextValueIs(cell, value)
    return Table.cellTextValue(cell) == value
end

--- cp.ui.Table.discloseRow(row) -> boolean
--- Function
--- Discloses the row, if possible.
---
--- Parameters:
---  * `row`        - The row to disclose
---
--- Returns:
---  * `true` if the row is disclosable and is now expanded.
function Table.static.discloseRow(row)
    local disclosing = row:attributeValue("AXDisclosing")
    if disclosing == nil then
        return false
    elseif disclosing == false then
        row:setAttributeValue("AXDisclosing", true)
    end
    return true
end

--- cp.ui.Table.findRow(rows, names) -> axuielement
--- Function
--- Finds the row at the sub-level named in the `names` table and returns it.
---
--- Parameters:
---  * `rows`       - The array of rows to process.
---  * `names`      - The array of names to navigate down
---
--- Returns:
---  * The row that was visited, or `nil` if not.
function Table.static.findRow(rows, names)
    if rows then
        local name = table.remove(names, 1)
        for _,row in ipairs(rows) do
            local cell = row[1]
            if Table.cellTextValueIs(cell, name) then
                if #names > 0 then
                    Table.discloseRow(row)
                    return Table.findRow(row:attributeValue("AXDisclosedRows"), names)
                else
                    return row
                end
            end
        end
    end
    return nil
end

--- cp.ui.Table.visitRow(rows, names, actionFn) -> axuielement
--- Function
--- Visits the row at the sub-level named in the `names` table, and executes the `actionFn`.
---
--- Parameters:
---  * `rows`       - The array of rows to process.
---  * `names`      - The array of names to navigate down
---  * `actionFn`   - A function to execute when the target row is found.
---
--- Returns:
---  * The row that was visited, or `nil` if not.
function Table.static.visitRow(rows, names, actionFn)
    local row = Table.findRow(rows, names)
    if row then actionFn(row) end
    return row
end

--- cp.ui.Table.visitRow(rows, names) -> axuielement
--- Function
--- Selects the row at the sub-level named in the `names` table.
---
--- Parameters:
---  * `rows`       - The array of rows to process.
---  * `names`      - The array of names to navigate down
---
--- Returns:
---  * The row that was visited, or `nil` if not.
function Table.static.selectRow(rows, names)
    return Table.visitRow(rows, names, function(row) row:setAttributeValue("AXSelected", true) end)
end

--- cp.ui.Table.matches(element)
--- Function
--- Checks if the element is a valid table.
---
--- Parameters:
---  * `element`    - The element to check.
---
--- Returns:
---  * `true` if it matches.
function Table.static.matches(element)
    return Element.matches(element)
end

--- cp.ui.Table(parent, uiFinder) -> self
--- Constructor
--- Creates a new Table.
---
--- Parameters:
---  * `parent`     - The parent object.
---  * `uiFinder`   - A `function` or `cp.prop` which will return the `axuielement` that this table represents.
---
--- Returns:
---  * A new `Table` instance.

--- cp.ui.Table.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `axuielement` that contains the actual rows.
function Table.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_content", function()
            local ui = original()
            return ui and (Table.matchesContent(ui) and ui) or childMatching(ui, Table.matchesContent)
        end,
        Table.matchesContent)
    end)
end

--- cp.ui.Table.verticalScrollBarUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The vertical scroll bar UI element, if present.
function Table.lazy.prop:verticalScrollBarUI()
    return axutils.prop(self.UI, "AXVerticalScrollBar")
end

--- cp.ui.Table.horizontalScrollBarUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The horizontal scroll bar UI element, if present.
function Table.lazy.prop:horizontalScrollBarUI()
    return axutils.prop(self.UI, "AXHorizontalScrollBar")
end

--- cp.ui.Table.isFocused <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the table is focused by the user.
function Table.lazy.prop:isFocused()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and ui:focused() or axutils.childWith(ui, "AXFocused", true) ~= nil
    end)
end

--- cp.ui.Table:uncached() -> Table
--- Method
--- Calling this will force the table to look up the `axuielement` on demand, rather than caching the result.
---
--- Parameters:
---  * None
---
---  * The same `Table`, now uncached..
function Table:uncached()
    self._uncached = true
    return self
end

--- cp.ui.Table.matchesContent(element) -> boolean
--- Function
--- Checks if the `element` is a valid table content element.
---
--- Parameters:
---  * `element`    - The element to check
---
--- Returns:
---  * `true` if the element is a valid content element.
function Table.static.matchesContent(element)
    if element then
        local role = element:attributeValue("AXRole")
        return role == "AXOutline" or role == "AXTable"
    end
    return false
end

--- cp.ui.Table:rowsUI([filterFn]) -> table of axuielements | nil
--- Method
--- Returns the list of rows in the table. An optional filter function may be provided.
--- It will be passed a single `AXRow` element and should return `true` if the row should be included.
---
--- Parameters:
---  * `filterFn`   - An optional function that will be called to check if individual rows should be included. If not provided, all rows are returned.
---
--- Returns:
---  * Table of rows. If the table is visible but no rows match, it will be an empty table, otherwise it will be `nil`.
function Table:rowsUI(filterFn)
    local ui = self:contentUI()
    if ui then
        local rows = {}
        for _,child in ipairs(ui) do
            if child:attributeValue("AXRole") == "AXRow" then
                if not filterFn or filterFn(child) then
                    rows[#rows + 1] = child
                end
            end
        end
        return rows
    end
    return nil
end

--- cp.ui.Table:topRowsUI(filterFn) -> table of axuielements | nil
--- Method
--- Returns a list of top-level rows in the table. An optional filter function may be provided.
--- It will be passed a single `AXRow` element and should return `true` if the row should be included.
---
--- Parameters:
---  * `filterFn`   - An optional function that will be called to check if individual rows should be included. If not provided, all rows are returned.
---
--- Returns:
---  * Table of rows. If the table is visible but no rows match, it will be an empty table, otherwise it will be `nil`.
function Table:topRowsUI(filterFn)
    return self:rowsUI(function(row)
        local disclosureLevel = row:attributeValue("AXDisclosureLevel")
        return (disclosureLevel == 0 or disclosureLevel == nil) and (filterFn == nil or filterFn(row))
    end)
end

--- cp.ui.Table:columnsUI() -> table of axuielements | nil
--- Method
--- Return a list of column headers, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of column headers. If the table is visible but no column headers are defined, an empty table is returned. If it's not visible, `nil` is returned.
function Table:columnsUI()
    local ui = self:contentUI()
    if ui then
        local columns = {}
        for _,child in ipairs(ui) do
            if child:attributeValue("AXRole") == "AXColumn" then
                columns[#columns + 1] = child
            end
        end
        return columns
    end
    return nil
end

--- cp.ui.Table:findColumnIndex(id) -> number | nil
--- Method
--- Finds the Column Index based on an `AXIdentifier` ID.
---
--- Parameters:
---  * id - The `AXIdentifier` of the column index you want to find.
---
--- Returns:
---  * A column index as a number, or `nil` if no index can be found.
function Table:findColumnIndex(id)
    local cols = self:columnsUI()
    if cols then
        for i=1,#cols do
            if cols[i]:attributeValue("AXIdentifier") == id then
                return i
            end
        end
    end
    return nil
end

--- cp.ui.Table:findCellUI(rowNumber, columnId) -> `hs._asm.axuielement` | nil
--- Method
--- Finds a specific Cell UI.
---
--- Parameters:
---  * rowNumber - The row number.
---  * columnId - The Column ID.
---
--- Returns:
---  * A `hs._asm.axuielement` object for the cell, or `nil` if the cell cannot be found.
function Table:findCellUI(rowNumber, columnId)
    local rows = self:rowsUI()
    if rows and rowNumber >= 1 and rowNumber < #rows then
        local colNumber = self:findColumnIndex(columnId)
        return colNumber and rows[rowNumber][colNumber]
    end
    return nil
end

--- cp.ui.Table:selectedRowsUI() -> table of axuielements | nil
--- Method
--- Return a table of selected row UIs.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of `hs._asm.axuielement` objects, or `nil` if none could be found.
function Table:selectedRowsUI()
    local rows = self:rowsUI()
    if rows then
        local selected = {}
        for _,row in ipairs(rows) do
            if row:attributeValue("AXSelected") then
                selected[#selected + 1] = row
            end
        end
        return selected
    end
    return nil
end

--- cp.ui.Table:viewFrame() -> hs.geometry rect
--- Method
--- Returns the Table frame.
---
--- Parameters:
---  * None
---
--- Return:
---  * The frame in the form of a `hs.geometry` rect object.
function Table:viewFrame()
    local ui = self:UI()
    if ui then
        local vFrame = ui:frame()
        local vScroll = self:verticalScrollBarUI()
        if vScroll then
            local vsFrame = vScroll:frame()
            vFrame.w = vFrame.w - vsFrame.w
            vFrame.h = vsFrame.h
        else
            local hScroll = self:horizontalScrollBarUI()
            if hScroll then
                local hsFrame = hScroll:frame()
                vFrame.w = hsFrame.w
                vFrame.h = vFrame.h - hsFrame.h
            end
        end
        return vFrame
    end
    return nil
end

--- cp.ui.Table:showRow(rowUI) -> boolean
--- Method
--- Shows a specific row.
---
--- Parameters:
---  * rowUI - The `hs._asm.axuielement` object of the row you want to show.
---
--- Return:
---  * `true` if successful, otherwise `false`.
function Table:showRow(rowUI)
    local ui = self:UI()
    if ui and rowUI then
        local vFrame = self:viewFrame()
        local rowFrame = rowUI:frame()

        local top = vFrame.y
        local bottom = vFrame.y + vFrame.h

        local rowTop = rowFrame.y
        local rowBottom = rowFrame.y + rowFrame.h

        if rowTop < top or rowBottom > bottom then
            -- we need to scroll
            local oFrame = self:contentUI():frame()
            local scrollHeight = oFrame.h - vFrame.h

            local vValue
            if rowTop < top or rowFrame.h > scrollHeight then
                vValue = (rowTop-oFrame.y)/scrollHeight
            else
                vValue = 1.0 - (oFrame.y + oFrame.h - rowBottom)/scrollHeight
            end
            local vScroll = self:verticalScrollBarUI()
            if vScroll then
                vScroll:setAttributeValue("AXValue", vValue)
            end
        end
        return true
    end
    return false
end

--- cp.ui.Table:showRowAt(index) -> boolean
--- Method
--- Shows a row at a specific index.
---
--- Parameters:
---  * index - The index of the row you wish to show.
---
--- Return:
---  * `true` if successful, otherwise `false`.
function Table:showRowAt(index)
    local rows = self:rowsUI()
    if rows then
        if index > 0 and index <= #rows then
            return self:showRow(rows[index])
        end
    end
    return false
end

--- cp.ui.Table:selectRow(rowUI) -> boolean
--- Method
--- Select a specific row.
---
--- Parameters:
---  * rowUI - The `hs._asm.axuielement` object of the row you want to select.
---
--- Return:
---  * `true` if successful, otherwise `false`.
function Table:selectRow(rowUI) -- luacheck: ignore
    if rowUI then
        rowUI:setAttributeValue("AXSelected", true)
        return true
    else
        return false
    end
end

--- cp.ui.Table:selectRowAt(index) -> boolean
--- Method
--- Select a row at a specific index.
---
--- Parameters:
---  * index - The index of the row you wish to select.
---
--- Return:
---  * `true` if successful, otherwise `false`.
function Table:selectRowAt(index)
    local ui = self:rowsUI()
    if ui and #ui >= index then
        return self:selectRow(ui[index])
    end
    return false
end

--- cp.ui.Table:deselectRow(rowUI) -> boolean
--- Method
--- Deselect a specific row.
---
--- Parameters:
---  * rowUI - The `hs._asm.axuielement` object of the row you want to deselect.
---
--- Return:
---  * `true` if successful, otherwise `false`.
function Table:deselectRow(rowUI) -- luacheck: ignore
    if rowUI then
        rowUI:setAttributeValue("AXSelected", false)
        return true
    else
        return false
    end
end

--- cp.ui.Table:deselectRowAt(index) -> boolean
--- Method
--- Deselects a row at a specific index.
---
--- Parameters:
---  * index - The index of the row you wish to deselect.
---
--- Return:
---  * `true` if successful, otherwise `false`.
function Table:deselectRowAt(index)
    local ui = self:rowsUI()
    if ui and #ui >= index then
        return self:deselectRow(ui[index])
    end
    return false
end

--- cp.ui.Table:selectAll(rowUI) -> boolean
--- Method
--- Selects the specified rows. If `rowsUI` is `nil`, then all rows will be selected.
---
--- Parameters:
---  * rowUI - A table of `hs._asm.axuielement` objects for the rows you want to select.
---
--- Return:
---  * `true` if successful, otherwise `false`.
function Table:selectAll(rowsUI)
    rowsUI = rowsUI or self:rowsUI()
    local outline = self:contentUI()
    if rowsUI and outline then
        outline:setAttributeValue("AXSelectedRows", rowsUI)
        return true
    end
    return false
end

--- cp.ui.Table:deselectAll(rowUI) -> boolean
--- Method
--- Deselects the specified rows. If `rowsUI` is `nil`, then all rows will be deselected.
---
--- Parameters:
---  * rowUI - A table of `hs._asm.axuielement` objects for the rows you want to deselect.
---
--- Return:
---  * `true` if successful, otherwise `false`.
function Table:deselectAll(rowsUI)
    rowsUI = rowsUI or self:selectedRowsUI()
    if rowsUI then
        for _,row in ipairs(rowsUI) do
            self:deselectRow(row)
        end
        return true
    end
    return false
end

--- cp.ui.Table:toCSV() -> string | nil
--- Method
--- Gets the contents of the table and formats it as a CSV string.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string or `nil` if an error occurs.
function Table:toCSV()
    if self:isShowing() then
        local result = ""
        local ui = self:contentUI()
        local group = ui and childMatching(ui, Group.matches)
        local buttons = group and axutils.childrenMatching(group, Button.matches)
        if buttons and next(buttons) ~= nil then
            for i=1, #buttons do
                result = result .. [["]] .. buttons[i]:attributeValue("AXTitle") .. [["]]
                if i ~= #buttons then
                    result = result .. ","
                else
                    result = result .. "\n"
                end
            end
            local rows = self:rowsUI()
            for r=1, #rows do
                local row = rows[r]
                local cells = row:attributeValue("AXChildren")
                if cells then
                    for c=1, #cells do
                        local cell = cells[c]
                        if cell then
                            if cell:attributeValue("AXRole") == "AXTextField" then
                                -- If there's only an AXTable > AXRow:
                                local item = cell:attributeValue("AXValue")
                                result = result .. [["]] .. item .. [["]]
                                if c ~= #cells then
                                    result = result .. ","
                                else
                                    if r ~= #rows then
                                        result = result .. "\n"
                                    end
                                end
                            else
                                -- If there's an AXTable > AXRow > AXCell:
                                local field = childMatching(cell, StaticText.matches) or childMatching(cell, TextField.matches) or childMatching(cell, MenuButton.matches)
                                local item = (field and field:attributeValue("AXValue")) or (field and field:attributeValue("AXTitle")) or ""
                                result = result .. [["]] .. item .. [["]]
                                if c ~= #cells then
                                    result = result .. ","
                                else
                                    if r ~= #rows then
                                        result = result .. "\n"
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return result
    end
end

--- cp.ui.Table:saveLayout() -> table
--- Method
--- Saves the current Table layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Table Layout.
function Table:saveLayout()
    local layout = {}
    local hScroll = self:horizontalScrollBarUI()
    if hScroll then
        layout.horizontalScrollBar = hScroll:value()
    end
    local vScroll = self:verticalScrollBarUI()
    if vScroll then
        layout.verticalScrollBar = vScroll:value()
    end
    layout.selectedRows = self:selectedRowsUI()

    return layout
end

--- cp.ui.Table:loadLayout(layout) -> none
--- Method
--- Loads a Table layout.
---
--- Parameters:
---  * layout - A table containing the Table layout settings - created using `cp.ui.Table:saveLayout()`.
---
--- Returns:
---  * None
function Table:loadLayout(layout)
    if layout then
        self:selectAll(layout.selectedRows)
        local vScroll = self:verticalScrollBarUI()
        if vScroll then
            vScroll:setValue(layout.verticalScrollBar)
        end
        local hScroll = self:horizontalScrollBarUI()
        if hScroll then
            hScroll:setValue(layout.horizontalScrollBar)
        end
    end
end

function Table.__tostring()
    return "cp.ui.Table"
end

return Table
