--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Table ===
---
--- Represents an AXTable in the Apple Accessibility UX API.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("Table")
local inspect						= require("hs.inspect")
local drawing						= require("hs.drawing")
local geometry						= require("hs.geometry")

local just							= require("cp.just")
local axutils						= require("cp.ui.axutils")
local tools							= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Table = {}
Table.mt = {}
Table.mt.__index = Table.mt

--- cp.ui.Table.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `Table`.
---
--- Parameters:
---  * `thing`		- The thing to check
---
--- Returns:
---  * `true` if the thing is a `Table` instance.
function Table.is(thing)
	return thing and getmetatable(thing) == Table.mt
end

--- cp.ui.Table.cellTextValue(cell) -> boolean
--- Function
--- Returns the cell's text value.
---
--- Parameters:
---  * `cell`	- The cell to check
---
--- Returns:
---  * The combined text value of the cell.
function Table.cellTextValue(cell, value)
	local textValue = nil
	if #cell > 0 then
		for i,item in ipairs(cell) do
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
---  * `cell`	- The cell to check
---  * `value`	- The text value to compare.
---
--- Returns:
---  * `true` if the cell text value equals the provided `value`.
function Table.cellTextValueIs(cell, value)
	return Table.cellTextValue(cell) == value
end

--- cp.ui.Table.discloseRow(row) -> boolean
--- Function
--- Discloses the row, if possible.
---
--- Parameters:
---  * `row`		- The row to disclose
---
--- Returns:
---  * `true` if the row is disclosable and is now expanded.
function Table.discloseRow(row)
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
---  * `rows`		- The array of rows to process.
---  * `names`		- The array of names to navigate down
---
--- Returns:
---  * The row that was visited, or `nil` if not.
function Table.findRow(rows, names)
	if rows then
		local name = table.remove(names, 1)
		for i,row in ipairs(rows) do
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
---  * `rows`		- The array of rows to process.
---  * `names`		- The array of names to navigate down
---  * `actionFn`	- A function to execute when the target row is found.
---
--- Returns:
---  * The row that was visited, or `nil` if not.
function Table.visitRow(rows, names, actionFn)
	local row = Table.findRow(rows, names)
	if row then actionFn(row) end
	return row
end

--- cp.ui.Table.visitRow(rows, names) -> axuielement
--- Function
--- Selects the row at the sub-level named in the `names` table.
---
--- Parameters:
---  * `rows`		- The array of rows to process.
---  * `names`		- The array of names to navigate down
---
--- Returns:
---  * The row that was visited, or `nil` if not.
function Table.selectRow(rows, names)
	return Table.visitRow(rows, names, function(row) row:setAttributeValue("AXSelected", true) end)
end

--- cp.ui.Table.matches(element)
--- Function
--- Checks if the element is a valid table.
---
--- Parameters:
---  * `element`	- The element to check.
---
--- Returns:
---  * `true` if it matches.
function Table.matches(element)
	return element ~= nil
end

--- cp.ui.Table.new(parent, finder) -> Table
--- Constructor
--- Creates a new Table.
---
--- Parameters:
---  * `parent`		- The parent object.
---  * `finder`		- A function which will return the `axuielement` that this table represents.
function Table.new(parent, finder)
	local o = {_parent = parent, _finder = finder}
	return setmetatable(o, Table.mt)
end

--- cp.ui.Table:uncached() -> Table
--- Method
--- Calling this will force the table to look up the `axuielement` on demand, rather than caching the result.
---
--- Parameters:
---  * None
---
---  * The same `Table`, now uncached..
function Table.mt:uncached()
	self._uncached = true
	return self
end

--- cp.ui.Table:parent() -> value
--- Method
--- The table's parent, as provided in the constructor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table's parent.
function Table.mt:parent()
	return self._parent
end

--- cp.ui.Table:UI() -> axuielement | nil
--- Method
--- Returns the current `axuielement` element for the table. May be `nil` if it is not available at present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `axuielement` for the Table.
function Table.mt:UI()
	if not self._uncached then
		return axutils.cache(self, "_ui", function()
			return self._finder()
		end,
		Table.matches)
	else
		return self._finder()
	end
end

--- cp.ui.Table:UI() -> axuielement | nil
--- Method
--- Returns the `axuielement` that contains the actual rows.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The content UI element, or `nil`.
function Table.mt:contentUI()
	return axutils.cache(self, "_content", function()
		local ui = self:UI()
		return ui and axutils.childMatching(ui, Table.matchesContent)
	end,
	Table.matchesContent)
end

--- cp.ui.Table.matchesContent(element) -> boolean
--- Function
--- Checks if the `element` is a valid table content element.
---
--- Parameters:
---  * `element`	- The element to check
---
--- Returns:
---  * `true` if the element is a valid content element.
function Table.matchesContent(element)
	if element then
		local role = element:attributeValue("AXRole")
		return role == "AXOutline" or role == "AXTable"
	end
	return false
end

--- cp.ui.Table:verticalScrollBarUI() -> axuielement | nil
--- Method
--- Finds the vertical scroll bar UI element, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The UI element, or `nil`.
function Table.mt:verticalScrollBarUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXVerticalScrollBar")
end

--- cp.ui.Table:horizontalScrollBarUI() -> axuielement | nil
--- Method
--- Finds the horizontal scroll bar UI element, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The UI element, or `nil`.
function Table.mt:horizontalScrollBarUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXHorizontalScrollBar")
end

--- cp.ui.Table:isShowing() -> boolean
--- Method
--- Checks if the table is visible.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the element is visible.
function Table.mt:isShowing()
	return self:UI() ~= nil
end

--- cp.ui.Table:isFocused() -> boolean
--- Method
--- Checks if the table is focused by the user.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the element is focused.
function Table.mt:isFocused()
	local ui = self:UI()
	return ui and ui:focused() or axutils.childWith(ui, "AXFocused", true) ~= nil
end

--- cp.ui.Table:rowsUI([filterFn]) -> table of axuielements | nil
--- Method
--- Returns the list of rows in the table. An optional filter function may be provided.
--- It will be passed a single `AXRow` element and should return `true` if the row should be included.
---
--- Parameters:
---  * `filterFn`	- An optional function that will be called to check if individual rows should be included. If not provided, all rows are returned.
--- 
--- Returns:
---  * Table of rows. If the table is visible but no rows match, it will be an empty table, otherwise it will be `nil`.
function Table.mt:rowsUI(filterFn)
	local ui = self:contentUI()
	if ui then
		local rows = {}
		for i,child in ipairs(ui) do
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
---  * `filterFn`	- An optional function that will be called to check if individual rows should be included. If not provided, all rows are returned.
--- 
--- Returns:
---  * Table of rows. If the table is visible but no rows match, it will be an empty table, otherwise it will be `nil`.
function Table.mt:topRowsUI(filterFn)
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
function Table.mt:columnsUI()
	local ui = self:contentUI()
	if ui then
		local columns = {}
		for i,child in ipairs(ui) do
			if child:attributeValue("AXRole") == "AXColumn" then
				columns[#columns + 1] = child
			end
		end
		return columns
	end
	return nil
end

-- TODO: Add documentation
function Table.mt:findColumnIndex(id)
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

-- TODO: Add documentation
function Table.mt:findCellUI(rowNumber, columnId)
	local rows = self:rowsUI()
	if rows and rowNumber >= 1 and rowNumber < #rows then
		local colNumber = self:findColumnIndex(columnId)
		return colNumber and rows[rowNumber][colNumber]
	end
	return nil
end

-- TODO: Add documentation
function Table.mt:selectedRowsUI()
	local rows = self:rowsUI()
	if rows then
		local selected = {}
		for i,row in ipairs(rows) do
			if row:attributeValue("AXSelected") then
				selected[#selected + 1] = row
			end
		end
		return selected
	end
	return nil
end

-- TODO: Add documentation
function Table.mt:viewFrame()
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

-- TODO: Add documentation
function Table.mt:showRow(rowUI)
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

			local vValue = nil
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

-- TODO: Add documentation
function Table.mt:showRowAt(index)
	local rows = self:rowsUI()
	if rows then
		if index > 0 and index <= #rows then
			return self:showRow(rows[index])
		end
	end
	return false
end

-- TODO: Add documentation
function Table.mt:selectRow(rowUI)
	if rowUI then
		rowUI:setAttributeValue("AXSelected", true)
		return true
	else
		return false
	end
end

-- TODO: Add documentation
function Table.mt:selectRowAt(index)
	local ui = self:rowsUI()
	if ui and #ui >= index then
		return self:selectRow(ui[index])
	end
	return false
end

-- TODO: Add documentation
function Table.mt:deselectRow(rowUI)
	if rowUI then
		rowUI:setAttributeValue("AXSelected", false)
		return true
	else
		return false
	end
end

-- TODO: Add documentation
function Table.mt:deselectRowAt(index)
	local ui = self:rowsUI()
	if ui and #ui >= index then
		return self:deselectRow(ui[index])
	end
	return false
end

-- TODO: Add documentation
-- Selects the specified rows. If `rowsUI` is `nil`, then all rows will be selected.
function Table.mt:selectAll(rowsUI)
	rowsUI = rowsUI or self:rowsUI()
	local outline = self:contentUI()
	if rowsUI and outline then
		outline:setAttributeValue("AXSelectedRows", rowsUI)
		return true
	end
	return false
end

-- TODO: Add documentation
-- Deselects the specified rows. If `rowsUI` is `nil`, then all rows will be deselected.
function Table.mt:deselectAll(rowsUI)
	rowsUI = rowsUI or self:selectedRowsUI()
	if rowsUI then
		for i,row in ipairs(rowsUI) do
			self:deselectRow(row)
		end
		return true
	end
	return false
end

-- TODO: Add documentation
function Table.mt:saveLayout()
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

-- TODO: Add documentation
function Table.mt:loadLayout(layout)
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

return Table