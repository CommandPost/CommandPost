--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.ColorBoard ===
---
--- Color Board Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")
local geometry							= require("hs.geometry")

local prop								= require("cp.prop")
local just								= require("cp.just")
local axutils							= require("cp.apple.finalcutpro.axutils")
local tools								= require("cp.tools")

local Pucker							= require("cp.apple.finalcutpro.main.ColorPucker")

local id								= require("cp.apple.finalcutpro.ids") "ColorBoard"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorBoard = {}

-- TODO: Add documentation
ColorBoard.aspect						= {}
ColorBoard.aspect.color					= {
	id 						= 1,
	reset 					= id "ColorReset",
	global 					= { puck = id "ColorGlobalPuck", pct = id "ColorGlobalPct", angle = id "ColorGlobalAngle"},
	shadows 				= { puck = id "ColorShadowsPuck", pct = id "ColorShadowsPct", angle = id "ColorShadowsAngle"},
	midtones 				= { puck = id "ColorMidtonesPuck", pct = id "ColorMidtonesPct", angle = id "ColorMidtonesAngle"},
	highlights 				= { puck = id "ColorHighlightsPuck", pct = id "ColorHighlightsPct", angle = id "ColorHighlightsAngle"}
}
ColorBoard.aspect.saturation			= {
	id 						= 2,
	reset 					= id "SatReset",
	global 					= { puck = id "SatGlobalPuck", pct = id "SatGlobalPct"},
	shadows 				= { puck = id "SatShadowsPuck", pct = id "SatShadowsPct"},
	midtones 				= { puck = id "SatMidtonesPuck", pct = id "SatMidtonesPct"},
	highlights 				= { puck = id "SatHighlightsPuck", pct = id "SatHighlightsPct"}
}
ColorBoard.aspect.exposure				= {
	id									= 3,
	reset								= id "ExpReset",
	global								= { puck = id "ExpGlobalPuck", pct = id "ExpGlobalPct"},
	shadows 							= { puck = id "ExpShadowsPuck", pct = id "ExpShadowsPct"},
	midtones							= { puck = id "ExpMidtonesPuck", pct = id "ExpMidtonesPct"},
	highlights							= { puck = id "ExpHighlightsPuck", pct = id "ExpHighlighsPct"}
}
ColorBoard.currentAspect = "*"

-- TODO: Add documentation
function ColorBoard.isColorBoard(element)
	for i,child in ipairs(element) do
		if axutils.childWith(child, "AXIdentifier", id "BackButton") then
			return true
		end
	end
	return false
end

-- TODO: Add documentation
function ColorBoard:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}
	
	return prop.extend(o, ColorBoard)
end

-- TODO: Add documentation
function ColorBoard:parent()
	return self._parent
end

-- TODO: Add documentation
function ColorBoard:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- COLORBOARD UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function ColorBoard:UI()
	return axutils.cache(self, "_ui",
	function()
		local parent = self:parent()
		local ui = parent:rightGroupUI()
		if ui then
			-- it's in the right panel (full-height)
			if ColorBoard.isColorBoard(ui) then
				return ui
			end
		else
			-- it's in the top-left panel (half-height)
			local top = parent:topGroupUI()
			for i,child in ipairs(top) do
				if ColorBoard.isColorBoard(child) then
					return child
				end
			end
		end
		return nil
	end,
	function(element) return ColorBoard:isColorBoard(element) end)
end

-- TODO: Add documentation
function ColorBoard:_findUI()
end

-- TODO: Add documentation
ColorBoard.isShowing = prop.new(function(self)
	local ui = self:UI()
	return ui ~= nil and ui:attributeValue("AXSize").w > 0
end):bind(ColorBoard)

-- TODO: Add documentation
ColorBoard.isActive = prop.new(function(self)
	local ui = self:colorSatExpUI()
	return ui ~= nil and axutils.childWith(ui:parent(), "AXIdentifier", id "ColorSatExp")
end):bind(ColorBoard)

-- TODO: Add documentation
function ColorBoard:show()
	if not self:isShowing() then
		self:app():menuBar():selectMenu({"Window", "Go To", "Color Board"})
	end
	return self
end

-- TODO: Add documentation
function ColorBoard:hide()
	local ui = self:showInspectorUI()
	if ui then ui:doPress() end
	return self
end

-- TODO: Add documentation
function ColorBoard:childUI(id)
	return axutils.cache(self._child, id, function()
		local ui = self:UI()
		return ui and axutils.childWith(ui, "AXIdentifier", id)
	end)
end

-- TODO: Add documentation
function ColorBoard:topToolbarUI()
	return axutils.cache(self, "_topToolbar", function()
		local ui = self:UI()
		if ui then
			for i,child in ipairs(ui) do
				if axutils.childWith(child, "AXIdentifier", id "BackButton") then
					return child
				end
			end
		end
		return nil
	end)
end

-- TODO: Add documentation
function ColorBoard:showInspectorUI()
	return axutils.cache(self, "_showInspector", function()
		local ui = self:topToolbarUI()
		if ui then
			return axutils.childWith(ui, "AXIdentifier", id "BackButton")
		end
		return nil
	end)
end

-----------------------------------------------------------------------
--
-- COLOR CORRECTION PANELS:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function ColorBoard:colorSatExpUI()
	return axutils.cache(self, "_colorSatExp", function()
		local ui = self:UI()
		return ui and axutils.childWith(ui, "AXIdentifier", id "ColorSatExp")
	end)
end

-- TODO: Add documentation
function ColorBoard:getAspect(aspect, property)
	local panel = nil
	if type(aspect) == "string" then
		if aspect == ColorBoard.currentAspect then
			-- return the currently-visible aspect
			local ui = self:colorSatExpUI()
			if ui then
				for k,value in pairs(ColorBoard.aspect) do
					if ui[value.id]:value() == 1 then
						panel = value
					end
				end
			end
		else
			panel = ColorBoard.aspect[aspect]
		end
	else
		panel = name
	end
	if panel and property then
		return panel[property]
	end
	return panel
end

-----------------------------------------------------------------------
--
-- PANEL CONTROLS:
--
-- These methds are passed the aspect (color, saturation, exposure)
-- and sometimes a property (id, global, shadows, midtones, highlights)
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function ColorBoard:showPanel(aspect)
	self:show()
	aspect = self:getAspect(aspect)
	local ui = self:colorSatExpUI()
	if aspect and ui and ui[aspect.id]:value() == 0 then
		ui[aspect.id]:doPress()
	end
	return self
end

-- TODO: Add documentation
function ColorBoard:reset(aspect)
	aspect = self:getAspect(aspect)
	self:showPanel(aspect)
	local ui = self:UI()
	if ui then
		local reset = axutils.childWith(ui, "AXIdentifier", aspect.reset)
		if reset then
			reset:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function ColorBoard:puckUI(aspect, property)
	local details = self:getAspect(aspect, property)
	return self:childUI(details.puck)
end

-- TODO: Add documentation
function ColorBoard:selectPuck(aspect, property)
	self:showPanel(aspect)
	local puckUI = self:puckUI(aspect, property)
	if puckUI then
		local f = puckUI:frame()
		local centre = geometry(f.x + f.w/2, f.y + f.h/2)
		tools.ninjaMouseClick(centre)
	end
	return self
end

-- TODO: Add documentation
-- Ensures that the specified aspect/property (eg 'color/global')
-- 'edit' panel is visible and returns the specified value type UI
-- (eg. 'pct' or 'angle')
function ColorBoard:aspectPropertyPanelUI(aspect, property, type)
	if not self:isShowing() then
		return nil
	end
	self:showPanel(aspect)
	local details = self:getAspect(aspect, property)
	if not details[type] then
		return nil
	end
	local ui = self:childUI(details[type])
	if not ui then -- short inspector panels can hide some details panels
		self:selectPuck(aspect, property)
		-- try again
		ui = self:childUI(details[type])
	end
	return ui
end

-- TODO: Add documentation
function ColorBoard:applyPercentage(aspect, property, value)
	local pctUI = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if pctUI then
		pctUI:setAttributeValue("AXValue", tostring(value))
		pctUI:doConfirm()
	end
	return self
end

-- TODO: Add documentation
function ColorBoard:shiftPercentage(aspect, property, shift)
	local ui = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if ui then
		local value = tonumber(ui:attributeValue("AXValue") or "0")
		ui:setAttributeValue("AXValue", tostring(value + shift))
		ui:doConfirm()
	end
	return self
end

-- TODO: Add documentation
function ColorBoard:getPercentage(aspect, property)
	local pctUI = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if pctUI then
		return tonumber(pctUI:attributeValue("AXValue"))
	end
	return nil
end

-- TODO: Add documentation
function ColorBoard:applyAngle(aspect, property, value)
	local angleUI = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if angleUI then
		angleUI:setAttributeValue("AXValue", tostring(value))
		angleUI:doConfirm()
	end
	return self
end

-- TODO: Add documentation
function ColorBoard:shiftAngle(aspect, property, shift)
	local ui = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if ui then
		local value = tonumber(ui:attributeValue("AXValue") or "0")
		-- loop around between 0 and 360 degrees
		value = (value + shift + 360) % 360
		ui:setAttributeValue("AXValue", tostring(value))
		ui:doConfirm()
	end
	return self
end

-- TODO: Add documentation
function ColorBoard:getAngle(aspect, property, value)
	local angleUI = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if angleUI then
		local value = angleUI:getAttributeValue("AXValue")
		if value ~= nil then return tonumber(value) end
	end
	return nil
end

-- TODO: Add documentation
function ColorBoard:startPucker(aspect, property)
	if self.pucker then
		self.pucker:cleanup()
		self.pucker = nil
	end
	self.pucker = Pucker:new(self, aspect, property):start()
	return self.pucker
end

return ColorBoard