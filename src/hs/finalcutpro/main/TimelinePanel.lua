local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local TimelinePanel = {}

function TimelinePanel:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TimelinePanel:parent()
	return self._parent
end

function TimelinePanel:UI()
	local toolbarUI = self:parent():toolbarUI()
	return toolbarUI and toolbarUI[TimelinePanel.ID]
end

function TimelinePanel:isShowing()
	if self:parent():isShowing() then
		local toolbar = self:parent():toolbarUI()
		if toolbar then
			local selected = toolbar:selectedChildren()
			return #selected == 1 and selected[1] == toolbar[TimelinePanel.ID]
		end
	end
	return false
end

function TimelinePanel:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		-- get the toolbar UI
		local panel = just.doUntil(function() return self:UI() end)
		if panel then
			panel:doPress()
			return true
		end
	end
	return false
end
