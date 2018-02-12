--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.MenuButton ===
---
--- Pop Up Button Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")

local find							= string.find

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MenuButton = {}

-- TODO: Add documentation
function MenuButton.matches(element)
	return element:attributeValue("AXRole") == "AXMenuButton"
end

--- cp.ui.MenuButton:new(axuielement, function) -> MenuButton
--- Function
--- Creates a new MenuButton
function MenuButton:new(parent, finderFn)
	local o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function MenuButton:parent()
	return self._parent
end

-- TODO: Add documentation
function MenuButton:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	MenuButton.matches)
end

-- TODO: Add documentation
function MenuButton:selectItem(index)
	local ui = self:UI()
	if ui then
		local items = ui:doPress()[1]
		if items then
			local item = items[index]
			if item then
				-- select the menu item
				item:doPress()
				return true
			else
				-- close the menu again
				items:doCancel()
			end
		end
	end
	return false
end

function MenuButton:selectItemMatching(pattern)
	local ui = self:UI()
	if ui then
		local items = ui:doPress()[1]
		if items then
			for _,item in ipairs(items) do
				local title = item:attributeValue("AXTitle")
				if title then
					local s,e = find(title, pattern)
					if s == 1 and e == title:len() then
						-- perfect match
						item:doPress()
						return true
					end
				end
			end
			-- if we got this far, we couldn't find it.
			items:doCancel()
		end
	end
	return false
end

-- TODO: Add documentation
function MenuButton:getValue()
	local ui = self:UI()
	return ui and ui:value()
end

-- TODO: Add documentation
function MenuButton:setValue(value)
	local ui = self:UI()
	if ui and not ui:value() == value then
		local items = ui:doPress()[1]
		for i,item in items do
			if item:title() == value then
				item:doPress()
				return
			end
		end
		items:doCancel()
	end
	return self
end

-- TODO: Add documentation
function MenuButton:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function MenuButton:press()
	local ui = self:UI()
	if ui then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function MenuButton:saveLayout()
	local layout = {}
	layout.value = self:getValue()
	return layout
end

-- TODO: Add documentation
function MenuButton:loadLayout(layout)
	if layout then
		self:setValue(layout.value)
	end
end

return MenuButton
