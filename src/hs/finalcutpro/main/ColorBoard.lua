local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")
local tools								= require("hs.fcpxhacks.modules.tools")
local geometry							= require("hs.geometry")

local ColorBoard = {}

ColorBoard.aspect						= {}
ColorBoard.aspect.color					= {
	id 									= 1, 
	reset 								= "_NS:288", 
	global 								= { puck = "_NS:278", pct = "_NS:70", angle = "_NS:98"}, 
	shadows 							= { puck = "_NS:273", pct = "_NS:77", angle = "_NS:104"}, 
	midtones 							= { puck = "_NS:268", pct = "_NS:84", angle = "_NS:110"}, 
	highlights 							= { puck = "_NS:258", pct = "_NS:91", angle = "_NS:116"}
}
ColorBoard.aspect.saturation			= {
	id 									= 2,
	reset 								= "_NS:538",
	global 								= { puck = "_NS:529", pct = "_NS:42"},
	shadows 							= { puck = "_NS:524", pct = "_NS:49"},
	midtones 							= { puck = "_NS:519", pct = "_NS:56"},
	highlights 							= { puck = "_NS:514", pct = "_NS:63"}
}
ColorBoard.aspect.exposure				= {
	id									= 3,
	reset								= "_NS:412",
	global								= { puck = "_NS:403", pct = "_NS:9"},
	shadows 							= { puck = "_NS:398", pct = "_NS:21"},
	midtones							= { puck = "_NS:393", pct = "_NS:28"},
	highlights							= { puck = "_NS:388", pct = "_NS:35"}
}

function ColorBoard.getAspect(aspect, property)
	local panel = nil
	if type(aspect) == "string" then
		panel = ColorBoard.aspect[aspect]
	else
		panel = name
	end
	if property then
		return panel[property]
	end
	return panel
end

function ColorBoard.isColorBoard(element)
	for i,child in ipairs(element) do
		if axutils.childWith(child, "AXIdentifier", "_NS:180") then
			return child
		end
	end
end

function ColorBoard:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function ColorBoard:parent()
	return self._parent
end

function ColorBoard:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- ColorBoard UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function ColorBoard:UI()
	local ui = self:parent():UI()
	if ColorBoard.isColorBoard(ui) then
		return ui
	else
		return nil
	end
end

function ColorBoard:isShowing()
	return self:UI() ~= nil
end

function ColorBoard:show()
	-- TODO: Simulate a 'Cmd+6' to show the color board.
	return self
end


function ColorBoard:hide()
	local ui = self:showInspectorUI()
	if ui then ui:doPress() end
	return self
end


function ColorBoard:childUI(id)
	local ui = self:UI()
	if ui then
		return axutils.childWith(ui, "AXIdentifier", id)
	end
	return nil
end

function ColorBoard:topToolbarUI()
	local ui = self:UI()
	if ui then
		for i,child in ipairs(ui) do
			if axutils.childWith(child, "AXIdentifier", "_NS:180") then
				return child
			end
		end
	end
	return nil
end

function ColorBoard:showInspectorUI()
	local ui = self:topToolbarUI()
	if ui then
		return axutils.childWith(ui, "AXIdentifier", "_NS:180")
	end
	return nil
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- Color Correction Panels
-----------------------------------------------------------------------
-----------------------------------------------------------------------

function ColorBoard:colorSatExpUI()
	local ui = self:UI()
	return ui and axutils.childWith(ui, "AXIdentifier", "_NS:128")
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- Panel Controls
---
--- These methds are passed the aspect (color, saturation, exposure)
--- and sometimes a property (id, global, shadows, midtones, highlights)
-----------------------------------------------------------------------
-----------------------------------------------------------------------

function ColorBoard:showPanel(aspect)
	aspect = ColorBoard.getAspect(aspect)
	local ui = self:colorSatExpUI()
	if aspect and ui then
		ui[aspect.id]:doPress()
	end
	return self
end

function ColorBoard:reset(aspect)
	aspect = ColorBoard.getAspect(aspect)
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

function ColorBoard:selectPuck(aspect, property)
	self:showPanel(aspect)
	local details = ColorBoard.getAspect(aspect, property)
	local puckUI = self:childUI(details.puck)
	if puckUI then
		local f = puckUI:frame()
		local centre = geometry(f.x + f.w/2, f.y + f.h/2)
		tools.ninjaMouseClick(centre)
	end
	return self
end


--- Ensures that the specified aspect/property (eg 'color/global')
--- 'edit' panel is visible and returns the specified value type UI
--- (eg. 'pct' or 'angle')
function ColorBoard:aspectPropertyPanelUI(aspect, property, type)
	if not self:isShowing() then
		return nil
	end
	self:showPanel(aspect)
	local details = ColorBoard.getAspect(aspect, property)
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

function ColorBoard:applyPercentage(aspect, property, value)
	local pctUI = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if pctUI then
		pctUI:setAttributeValue("AXValue", tostring(value))
		pctUI:doConfirm()
	end
	return self
end

function ColorBoard:shiftPercentage(aspect, property, shift)
	local ui = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if ui then
		local value = tonumber(ui:attributeValue("AXValue") or "0")
		ui:setAttributeValue("AXValue", tostring(value + shift))
		ui:doConfirm()
	end
	return self	
end

function ColorBoard:getPercentage(aspect, property)
	local pctUI = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if pctUI then
		return tonumber(pctUI:attributeValue("AXValue"))
	end
	return nil
end

function ColorBoard:applyAngle(aspect, property, value)
	local angleUI = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if angleUI then
		angleUI:setAttributeValue("AXValue", tostring(value))
		angleUI:doConfirm()
	end
	return self
end

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

function ColorBoard:getAngle(aspect, property, value)
	local angleUI = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if angleUI then
		local value = angleUI:getAttributeValue("AXValue")
		if value ~= nil then return tonumber(value) end
	end
	return nil
end



return ColorBoard