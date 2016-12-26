local axutils							= require("hs.finalcutpro.axutils")

local tools								= require("hs.fcpxhacks.modules.tools")
local geometry							= require("hs.geometry")
local Table								= require("hs.finalcutpro.ui.Table")

local Filmstrip = {}

function Filmstrip.matches(element)
	return element and element:attributeValue("AXIdentifier") == "_NS:33"
end

function Filmstrip:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Filmstrip:parent()
	return self._parent
end

function Filmstrip:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE CONTENT UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Filmstrip:UI()
	return axutils.cache(self, "_ui", function()
		local main = self:parent():mainGroupUI()
		if main then
			for i,child in ipairs(main) do
				if child:attributeValue("AXRole") == "AXGroup" and #child == 1 then
					if Filmstrip.matches(child[1]) then
						return child[1]
					end
				end
			end
		end
		return nil
	end,
	Filmstrip.matches)
end

function Filmstrip:isShowing()
	return self:UI() ~= nil
end

function Filmstrip:containerUI()
	return axutils.cache(self, "_container", function()
		local ui = self:UI()
		return ui and axutils.childWithRole(ui, "AXGroup")
	end)
end

function Filmstrip:clipsUI()
	local ui = self:containerUI()
	return ui and ui:visibleChildren()
end

function Filmstrip:selectedClipsUI()
	local ui = self:containerUI()
	return ui and ui:selectedChildren()
end

function Filmstrip:showClip(clipUI)
	-- TODO implement scroll to clip
	local ui = self:UI()
	if ui then
		local vScroll = self:verticalScrollBarUI()
		local vFrame = vScroll:frame()
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
			if rowTop < top then
				vValue = (rowTop-oFrame.y)/scrollHeight
			else
				vValue = 1.0 - (oFrame.y + oFrame.h - rowBottom)/scrollHeight
			end
			vScroll:setAttributeValue("AXValue", vValue)
		end
	end
	return self
end

function Filmstrip:selectClip(clipUI)
	self:showClip(clipUI)
	tools.ninjaMouseClick(geometry.rect(clipUI.frame()).center)
	return self
end

function Filmstrip:selectClipAt(index)
	local ui = self:clipsUI()
	if ui and #ui >= index then
		self:selectClip(ui[index])
	end
	return self
end

return Filmstrip