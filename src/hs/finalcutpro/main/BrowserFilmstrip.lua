local axutils							= require("hs.finalcutpro.axutils")

local tools								= require("hs.fcpxhacks.modules.tools")
local geometry							= require("hs.geometry")
local inspect 							= require("hs.inspect")

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

function Filmstrip:verticalScrollBarUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXVerticalScrollBar")
end

function Filmstrip:isShowing()
	return self:UI() ~= nil
end

function Filmstrip:contentsUI()
	local ui = self:UI()
	return ui and ui:contents()[1]
end

function Filmstrip:clipsUI()
	local ui = self:contentsUI()
	if ui then
		local clips = axutils.childrenWithRole(ui, "AXGroup")
		if clips then
			debugMessage("sorting "..#clips.." clips.")
			table.sort(clips, 
				function(a, b)
					debugMessage("sorting clip")
					local aFrame = a:frame()
					local bFrame = b:frame()
					if aFrame.y < bFrame.y then -- a is above b
						return true
					elseif aFrame.y == bFrame.y then
						if aFrame.x < bFrame.x then -- a is left of b
							return true
						elseif aFrame.x == bFrame.y 
						   and aFrame.w < bFrame.w then -- a starts with but finishes before b, so b must be multi-line
							return true
						end
					end
					return false -- b is first
				end
			)
			return clips
		end
	end
	return nil
end

function Filmstrip:selectedClipsUI()
	local ui = self:contentsUI()
	return ui and ui:selectedChildren()
end

function Filmstrip:showClip(clipUI)
	local ui = self:UI()
	if ui then
		local vScroll = self:verticalScrollBarUI()
		local vFrame = vScroll:frame()
		local clipFrame = clipUI:frame()
	
		local top = vFrame.y
		local bottom = vFrame.y + vFrame.h

		local clipTop = clipFrame.y
		local clipBottom = clipFrame.y + clipFrame.h
	
		if clipTop < top or clipBottom > bottom then
			-- we need to scroll
			local oFrame = self:contentsUI():frame()
			local scrollHeight = oFrame.h - vFrame.h
		
			local vValue = nil
			if clipTop < top or clipFrame.h > vFrame.h then
				vValue = (clipTop-oFrame.y)/scrollHeight
			else
				vValue = 1.0 - (oFrame.y + oFrame.h - clipBottom)/scrollHeight
			end
			vScroll:setAttributeValue("AXValue", vValue)
		end
	end
	return self
end

function Filmstrip:showClipAt(index)
	local ui = self:clipsUI()
	if ui and #ui >= index then
		self:showClip(ui[index])
	end
	return self
end

function Filmstrip:selectClip(clipUI)
	local labelUI = axutils.childWithRole(clipUI, "AXTextField")
	local clickPos = nil
	self:showClip(clipUI)
	if labelUI then -- use the label to find the front of the clip
		-- click half way between the top of the label and the top of the clip
		-- which should be right at the beginning of the clip.
		local labelPos = labelUI:position()
		local y = (labelPos.y + clipUI:position().y)/2
		clickPos = {x = labelPos.x, y = y}
	else -- click the top-right of the clip, which should always be safe.
		local clipFrame = clipUI:frame()
		clickPos = {x = clipFrame.x + clipFrame.w - 10, y = clipFrame.y+10}
	end
	if clickPos then
		tools.ninjaMouseClick(clickPos)
	end
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