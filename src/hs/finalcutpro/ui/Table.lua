local log							= require("hs.logger").new("Table")
local inspect						= require("hs.inspect")
local drawing						= require("hs.drawing")


local axutils						= require("hs.finalcutpro.axutils")
local tools							= require("hs.fcpxhacks.modules.tools")
local geometry						= require("hs.geometry")
local just							= require("hs.just")

local Table = {}

--- hs.finalcutpro.ui.Table:new(axuielement, table) -> Table
--- Function:
--- Creates a new Table
function Table:new(parent, finder)
	o = {_parent = parent, _finder = finder}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Table:parent()
	return self._parent
end

function Table:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end)
end

function Table:outlineUI()
	return axutils.cache(self, "_outline", function()
		local ui = self:UI()
		return ui and axutils.childWithRole(ui, "AXOutline")
	end)
end

function Table:verticalScrollBarUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXVerticalScrollBar")
end

function Table:horizontalScrollBarUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXHorizontalScrollBar")
end

function Table:isShowing()
	return self:UI() ~= nil
end

function Table:isFocused()
	local ui = self:UI()
	return ui and ui:focused() or axutils.childWith(ui, "AXFocused", true) ~= nil
end

-- Returns the list of rows in the table
function Table:rowsUI()
	local ui = self:outlineUI()
	if ui then
		local rows = {}
		for i,child in ipairs(ui) do
			if child:attributeValue("AXRole") == "AXRow" then
				rows[#rows + 1] = child
			end
		end
		return rows
	end
	return nil
end

function Table:columnsUI()
	local ui = self:outlineUI()
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

function Table:findColumnNumber(id)
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

function Table:findCellUI(rowNumber, columnId)
	local rows = self:rowsUI()
	if rows and rowNumber >= 1 and rowNumber < #rows then
		local colNumber = self:findColumnNumber(columnId)
		return colNumber and rows[rowNumber][colNumber]
	end
	return nil
end

function Table:selectedRowsUI()
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
			local oFrame = self:outlineUI():frame()
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
	end
	return self
end

function Table:showRowAt(index)
	local rows = self:rowsUI()
	if rows then
		if index > 0 and index <= #rows then
			self:showRow(rows[index])
		end
	end
	return self
end

function Table:selectRow(rowUI)
	self:showRow(rowUI)
	local mouseTarget = geometry.rect(rowUI[1]:frame()).center
	tools.ninjaMouseClick(mouseTarget, function()
		local selected = self:selectedRowsUI()
		return selected and #selected == 1 and selected[1] == rowUI
	end)
end

function Table:selectRowAt(index)
	local ui = self:rowsUI()
	if ui and #ui >= index then
		self:selectRow(ui[index])
	end
end


return Table