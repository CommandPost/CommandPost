--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector.ColorInspector.CorrectionsBar ===
---
--- The Correction selection/management bar at the top of the ColorInspector
---
--- Requires Final Cut Pro 10.4 or later.

local log								= require("hs.logger").new("colorInspect")

local axutils							= require("cp.ui.axutils")
local prop								= require("cp.prop")

local sort								= table.sort

local CorrectionsBar = {}

function CorrectionsBar.matches(element)
	if element and element:attributeValue("AXRole") == "AXGroup" then
		local children = element:children()
		-- sort them left-to-right
		sort(children, axutils.compareLeftToRight)
		return #children >= 2
		   and children[1]:attributeValue("AXRole") == "AXCheckBox"
		   and children[2]:attributeValue("AXRole") == "AXMenuButton"
	end
	return false
end

function CorrectionsBar:new(parent)
	local o = {
		_parent = parent,
	}
	prop.extend(o, CorrectionsBar)
	return o
end

function CorrectionsBar:parent()
	return self._parent
end

function CorrectionsBar:app()
	return self:parent():app()
end

function CorrectionsBar:UI()
	return axutils.cache(self, "_ui",
		function()
			local ui = self:parent():UI()
			if ui then
				local barUI = axutils.childFromTop(ui, 1)
				return CorrectionsBar.matches(barUI[1]) and barUI[1] or nil
			else
				return nil
			end
		end,
		CorrectionsBar.matches
	)
end

return CorrectionsBar