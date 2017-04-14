--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- TBC

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils							= require("cp.finalcutpro.axutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ScrollArea = {}

-- TODO: Add documentation
function ScrollArea.matches(element)
	return element and element:attributeValue("AXRole") == "AXScrollArea"
end

-- TODO: Add documentation
function ScrollArea:new(parent, finderFn)
	o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function ScrollArea:parent()
	return self._parent
end

-- TODO: Add documentation
function ScrollArea:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- CONTENT UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function ScrollArea:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	ScrollArea.matches)
end

-- TODO: Add documentation
function ScrollArea:verticalScrollBarUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXVerticalScrollBar")
end

-- TODO: Add documentation
function ScrollArea:horizontalScrollBarUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXHorizontalScrollBar")
end

-- TODO: Add documentation
function ScrollArea:isShowing()
	return self:UI() ~= nil
end

-- TODO: Add documentation
function ScrollArea:contentsUI()
	local ui = self:UI()
	return ui and ui:contents()[1]
end

-- TODO: Add documentation
function ScrollArea:childrenUI(filterFn)
	local ui = self:contentsUI()
	if ui then
		local children = nil
		if filterFn then
			children = axutils.childrenMatching(ui, filterFn)
		else
			children = ui:attributeValue("AXChildren")
		end
		if children then
			table.sort(children,
				function(a, b)
					local aFrame = a:frame()
					local bFrame = b:frame()
					if aFrame.y < bFrame.y then -- a is above b
						return true
					elseif aFrame.y == bFrame.y then
						if aFrame.x < bFrame.x then -- a is left of b
							return true
						elseif aFrame.x == bFrame.x
						   and aFrame.w < bFrame.w then -- a starts with but finishes before b, so b must be multi-line
							return true
						end
					end
					return false -- b is first
				end
			)
			return children
		end
	end
	return nil
end

-- TODO: Add documentation
function ScrollArea:selectedChildrenUI()
	local ui = self:contentsUI()
	return ui and ui:selectedChildren()
end

-- TODO: Add documentation
function ScrollArea:viewFrame()
	local ui = self:UI()
	local hScroll = self:horizontalScrollBarUI()
	local vScroll = self:verticalScrollBarUI()

	local frame = ui:frame()

	if hScroll then
		frame.h = frame.h - hScroll:frame().h
	end

	if vScroll then
		frame.w = frame.w - vScroll:frame().w
	end
	return frame
end

-- TODO: Add documentation
function ScrollArea:showChild(childUI)
	local ui = self:UI()
	if ui and childUI then
		local vFrame = self:viewFrame()
		local childFrame = childUI:frame()

		local top = vFrame.y
		local bottom = vFrame.y + vFrame.h

		local childTop = childFrame.y
		local childBottom = childFrame.y + childFrame.h

		if childTop < top or childBottom > bottom then
			-- we need to scroll
			local oFrame = self:contentsUI():frame()
			local scrollHeight = oFrame.h - vFrame.h

			local vValue = nil
			if childTop < top or childFrame.h > vFrame.h then
				vValue = (childTop-oFrame.y)/scrollHeight
			else
				vValue = 1.0 - (oFrame.y + oFrame.h - childBottom)/scrollHeight
			end
			vScroll:setAttributeValue("AXValue", vValue)
		end
	end
	return self
end

-- TODO: Add documentation
function ScrollArea:showChildAt(index)
	local ui = self:childrenUI()
	if ui and #ui >= index then
		self:showChild(ui[index])
	end
	return self
end

-- TODO: Add documentation
function ScrollArea:selectChild(childUI)
	if childUI then
		childUI:parent():setAttributeValue("AXSelectedChildren", { childUI } )
	end
	return self
end

-- TODO: Add documentation
function ScrollArea:selectChildAt(index)
	local ui = self:childrenUI()
	if ui and #ui >= index then
		self:selectChild(ui[index])
	end
	return self
end

-- TODO: Add documentation
function ScrollArea:selectAll(childrenUI)
	childrenUI = childrenUI or self:childrenUI()
	if childrenUI then
		for i,clip in ipairs(childrenUI) do
			self:selectChild(child)
		end
	end
	return self
end

-- TODO: Add documentation
function ScrollArea:deselectAll()
	local contents = self:contentsUI()
	if contents then
		contents:setAttributeValue("AXSelectedChildren", {})
	end
	return self
end

-- TODO: Add documentation
function ScrollArea:saveLayout()
	local layout = {}
	local hScroll = self:horizontalScrollBarUI()
	if hScroll then
		layout.horizontalScrollBar = hScroll:value()
	end
	local vScroll = self:verticalScrollBarUI()
	if vScroll then
		layout.verticalScrollBar = vScroll:value()
	end
	layout.selectedChildren = self:selectedChildrenUI()

	return layout
end

-- TODO: Add documentation
function ScrollArea:loadLayout(layout)
	if layout then
		self:selectAll(layout.selectedChildren)
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

return ScrollArea