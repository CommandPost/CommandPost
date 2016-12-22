local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local geometry							= require("hs.geometry")
local fnutils							= require("hs.fnutils")
local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Playhead							= require("hs.finalcutpro.main.Playhead")

local TimelineContent = {}

function TimelineContent:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TimelineContent:parent()
	return self._parent
end

function TimelineContent:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE CONTENT UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function TimelineContent:UI()
	return axutils.cache(self, "_ui", function()
		local scrollArea = self:scrollAreaUI()
		if scrollArea then
			return axutils.childWith(scrollArea, "AXIdentifier", "_NS:16")
		end
		return nil
	end)
end

function TimelineContent:scrollAreaUI()
	return axutils.cache(self, "_scrollArea", function()
		local main = self:parent():mainUI()
		if main then
			return axutils.childMatching(main, function(child)
				return child:attributeValue("AXIdentifier") == "_NS:9" 
				   and child:attributeValue("AXHorizontalScrollBar") ~= nil
			end)
		end
		return nil
	end)
end

function TimelineContent:isShowing()
	return self:UI() ~= nil
end

function TimelineContent:show()
	self:parent():show()
	return self
end

function TimelineContent:hide()
	self:parent():hide()
	return self
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- PLAYHEAD
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function TimelineContent:playhead()
	if not self._playhead then
		self._playhead = Playhead:new(self)
	end
	return self._playhead
end

function TimelineContent:horizontalScrollUI()
	local ui = self:scrollAreaUI()
	return ui and ui[2]
end

function TimelineContent:verticalScrollUI()
	local ui = self:scrollAreaUI()
	return ui and ui[3]
end

function TimelineContent:viewWidth()
	local hScroll = self:horizontalScrollUI()
	return hScroll and hScroll:size().w or nil
end

function TimelineContent:viewHeight()
	local vScroll = self:verticalScrollUI()
	return vScroll and vScroll:size().h or nil
end

function TimelineContent:viewFrame()
	local scrollArea = self:scrollAreaUI()
	if scrollArea then
		local sap = scrollArea:position()
		local horizontalScroll = scrollArea[2]
		local verticalScroll = scrollArea[3]
		return {x = sap.x, y = sap.y, w = horizontalScroll:size().w, h = verticalScroll:size().h}
	end
	return nil
end

function TimelineContent:timelineFrame()
	local ui = self:UI()
	return ui and ui:frame()
end

function TimelineContent:scrollHorizontalBy(shift)
	local ui = self:horizontalScrollUI()
	if ui then
		local indicator = ui[1]
		local value = indicator:attributeValue("AXValue")
		indicator:setAttributeValue("AXValue", value + shift)
	end
end

function TimelineContent:scrollHorizontalTo(value)
	local ui = self:horizontalScrollUI()
	if ui then
		local indicator = ui[1]
		value = math.max(0, math.min(1, value))
		if indicator:attributeValue("AXValue") ~= value then
			indicator:setAttributeValue("AXValue", value)
		end
	end
end

function TimelineContent:scrollVerticalBy(shift)
	local ui = self:verticalScrollUI()
	if ui then
		local indicator = ui[1]
		local value = indicator:attributeValue("AXValue")
		indicator:setAttributeValue("AXValue", value + shift)
	end
end

function TimelineContent:scrollVerticalTo(value)
	local ui = self:verticalScrollUI()
	if ui then
		local indicator = ui[1]
		value = math.max(0, math.min(1, value))
		if indicator:attributeValue("AXValue") ~= value then
			indicator:setAttributeValue("AXValue", value)
		end
	end
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- CLIPS
-----------------------------------------------------------------------
-----------------------------------------------------------------------

--- hs.finalcutpro.main.TimelineContent:selectedClipsUI(expandedGroups, filterFn) -> table of axuielements
--- Function
--- Returns a table containing the list of selected clips. 
---
--- If `expandsGroups` is true any AXGroup items will be expanded to the list of contained AXLayoutItems.
---
--- If `filterFn` is provided it will be called with a single argument to check if the provided
--- clip should be included in the final table.
---
--- Parameters:
---  * expandGroups	- (optional) if true, expand AXGroups to include contained AXLayoutItems
---  * filterFn		- (optional) if provided, the function will be called to check each clip
---
--- Returns:
---  * The table of selected axuielements that match the conditions
---
function TimelineContent:selectedClipsUI(expandGroups, filterFn)
	local ui = self:UI()
	if ui then
		local clips = ui:attributeValue("AXSelectedChildren")
		return self:_filterClips(clips, expandGroups, filterFn)
	end
	return nil
end

--- hs.finalcutpro.main.TimelineContent:clipsUI(expandedGroups, filterFn) -> table of axuielements
--- Function
--- Returns a table containing the list of clips in the Timeline.
---
--- If `expandsGroups` is true any AXGroup items will be expanded to the list of contained AXLayoutItems.
---
--- If `filterFn` is provided it will be called with a single argument to check if the provided
--- clip should be included in the final table.
---
--- Parameters:
---  * expandGroups	- (optional) if true, expand AXGroups to include contained AXLayoutItems
---  * filterFn		- (optional) if provided, the function will be called to check each clip
---
--- Returns:
---  * The table of axuielements that match the conditions
---
function TimelineContent:clipsUI(expandGroups, filterFn)
	local ui = self:UI()
	if ui then
		local clips = fnutils.filter(ui:children(), function(child)
			local role = child:attributeValue("AXRole")
			return role == "AXLayoutItem" or role == "AXGroup"
		end)
		return self:_filterClips(clips, expandGroups, filterFn)
	end
	return nil
end

function TimelineContent:_filterClips(clips, expandGroups, filterFn)
	if expandGroups then
		return self:_expandClips(clips, filterFn)
	elseif filterFn ~= nil then
		return fnutils.filter(clips, filterFn)
	else
		return clips
	end
end

function TimelineContent:_expandClips(clips, filterFn)
	return fnutils.mapCat(clips, function(child)
		local role = child:attributeValue("AXRole")
		if role == "AXLayoutItem" then
			if filterFn == nil or filterFn(child) then 
				return {child}
			end
		elseif role == "AXGroup" then
			return self:_expandClips(child:attributeValue("AXChildren"), filterFn)
		end
		return {}
	end)
end

return TimelineContent