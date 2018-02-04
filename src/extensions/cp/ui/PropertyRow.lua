--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.PropertyRow ===
---
--- Represents a list of property rows, typically in a Property Inspector.
local log						= require("hs.logger").new("propertyRow")

local prop						= require("cp.prop")

local axutils					= require("cp.ui.axutils")
local Button					= require("cp.ui.Button")

local geometry					= require("hs.geometry")

local PropertyRow = {}

function PropertyRow.matches(element)
	return true
end

function PropertyRow:new(parent, labelKey, propertiesUI)
	local o = prop.extend({
		_parent = parent,
		_labelKeys = type(labelKey) == "string" and {labelKey} or labelKey,
		_propertiesUI = propertiesUI or "UI",
		_children = nil,
	}, PropertyRow)

	o.label = prop(function(self)
		local app = self:app()
		for _,key in ipairs(self._labelKeys) do
			local label = app:string(key)
			if label then
				return label
			end
		end
		return nil
	end):bind(o)

	return o
end

function PropertyRow:parent()
	return self._parent
end

function PropertyRow:app()
	return self:parent():app()
end

function PropertyRow:UI()
	return self:labelUI()
end

PropertyRow.isShowing = prop(function(self)
	return self:UI() ~= nil
end):bind(PropertyRow)

function PropertyRow:show()
	local ui = self:UI()
end

function PropertyRow:labelKeys()
	return self._labelKeys()
end

function PropertyRow:propertiesUI()
	local parent = self:parent()
	local propFn = parent[self._propertiesUI]
	return propFn and propFn(parent) or nil
end

function PropertyRow:labelUI()
	return axutils.cache(self, "_labelUI", function()
		local ui = self:propertiesUI()
		if ui then
			local label = self:label()
			return axutils.childMatching(ui, function(child)
				return child:attributeValue("AXRole") == "AXStaticText"
					and child:attributeValue("AXValue") == label
			end)
		end
		return nil
	end)
end

function PropertyRow:children()
	local label = self:labelUI()
	if not label then
		return nil
	end

	local children = self._children
	-- check the children are still valid
	if children and #children > 0 and not axutils.isValid(children[1]) then
		children = nil
	end
	-- check if we have children cached
	if not chidren and label then
		local labelFrame = geometry.new(label:frame())
		children = axutils.childrenMatching(self:propertiesUI(), function(child)
			-- match the children who are right of the label element (and not the AXScrollBar)
			return labelFrame:intersect(child:frame()).h > 0 and child:attributeValue("AXRole") ~= "AXScrollBar"
		end)
		table.sort(children, axutils.compareLeftToRight)
		self._children = children
	end
	return children
end

function PropertyRow:resetButton()
	if not self._resetButton then
		self._resetButton = Button:new(self, function()
			local children = self:children()
			if children then
				local last = children[#children]
				return Button.matches(last) and last or nil
			end
			return nil
		end)
	end
	return self._resetButton
end

function PropertyRow:reset()
	self:resetButton():press()
	return self
end

return PropertyRow