--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.CorrectionsBar ===
---
--- The Correction selection/management bar at the top of the ColorInspector
---
--- Requires Final Cut Pro 10.4 or later.

local log								= require("hs.logger").new("colorInspect")

local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")
local MenuButton						= require("cp.ui.MenuButton")

local sort								= table.sort

local CorrectionsBar = {}

--- cp.apple.finalcutpro.inspector.color.ColorInspector.CORRECTION_TYPES
--- Constant
--- Table of Correction Types
CorrectionsBar.CORRECTION_TYPES = {
	["Color Board"] 			= "FFCorrectorColorBoard",
	["Color Wheels"]			= "PAECorrectorEffectDisplayName",
	["Color Curves"] 			= "PAEColorCurvesEffectDisplayName",
	["Hue/Saturation Curves"] 	= "PAEHSCurvesEffectDisplayName",
}

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

function CorrectionsBar:isShowing()
	return self:UI() ~= nil
end

function CorrectionsBar:menuButton()
	if not self._menuButton then
		self._menuButton = MenuButton:new(self, function()
			return axutils.childWithRole(self:UI(), "AXMenuButton")
		end)
	end
	return self._menuButton
end

function CorrectionsBar:findCorrectionLabel(correctionType)
	return self:app():string(self.CORRECTION_TYPES[correctionType])
end

function CorrectionsBar:activate(correctionType, number)
	number = number or 1 -- default to the first corrector.

	self:show()

	-- see if the correction type/number combo exists already
	local correctionText = self:findCorrectionLabel(correctionType)
	if not correctionText then
		log.ef("Invalid Correction Type: %s", correctionType)
	end

	local menuButton = self:menuButton()
	if menuButton:isShowing() then
		local pattern = "%s*"..correctionText.." "..number
		if not menuButton:selectItemMatching(pattern) then
			-- try adding a new correction of the specified type.
			pattern = "%+"..correctionText
			if not menuButton:selectItemMatching(pattern) then
				log.ef("Invalid Correction Type: %s", correctionType)
			end
		end
	end

	return self
end

return CorrectionsBar