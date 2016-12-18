local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")
local tools								= require("hs.fcpxhacks.modules.tools")
local geometry							= require("hs.geometry")

local ColorBoard = {}

ColorBoard.aspect						= {}
ColorBoard.aspect.color					= {
	id = 1, reset = "_NS:288", 
	global = "_NS:278", shadows = "_NS:273", midtones = "_NS:268", highlights = "_NS:258"
}
ColorBoard.aspect.saturation			= {
	id = 2, reset = "_NS:538",
	global = "_NS:529", shadows = "_NS:524", midtones = "_NS:519", highlights = "_NS:514"
}
ColorBoard.aspect.exposure				= {
	id = 3, reset = "_NS:412",
	global = "_NS:403", shadows = "_NS:398", midtones = "_NS:393", highlights = "_NS:388"
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

function ColorBoard:showExposurePanel()
	local ui = self:colorSatExpUI()
	if ui then
		ui[ColorBoard.EXPOSURE_PANEL]:doPress()
	end
	return self
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
	local id = ColorBoard.getAspect(aspect, property)
	local puckUI = self:puckUI(id)
	if puckUI then
		local f = puckUI:frame()
		local centre = geometry(f.x + f.w/2, f.y + f.h/2)
		tools.ninjaMouseClick(centre)
	end
	return self
end

function ColorBoard:puckUI(id)
	local ui = self:UI()
	if ui then
		return axutils.childWith(ui, "AXIdentifier", id)
	end
	return nil
end

return ColorBoard