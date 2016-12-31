local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local PrimaryWindow						= require("hs.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("hs.finalcutpro.main.SecondaryWindow")
local Button							= require("hs.finalcutpro.ui.Button")
local Table								= require("hs.finalcutpro.ui.Table")
local ScrollArea						= require("hs.finalcutpro.ui.ScrollArea")

local Browser = {}

function Browser.matches(element)
	return element and element:attributeValue("AXRole") == "AXGroup"
	   and axutils.childWithID(element, "_NS:452") ~= nil
end

function Browser:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Browser:parent()
	return self._parent
end

function Browser:app()
	return self.parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- Browser UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Browser:UI()
	return axutils.cache(self, "_ui", function()
		return axutils.childMatching(self:parent():mainUI(), Browser.matches)
	end,
	Browser.matches)
end

function Browser:isShowing()
	return self:UI() ~= nil
end

function Browser:show()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the workspace
	menuBar:uncheckMenu("Window", "Show in Workspace", "Effects")
	return self
end

function Browser:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the workspace
	menuBar:uncheckMenu("Window", "Show in Workspace", "Effects")
	return self
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Buttons
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

function Browser:mainGroupUI()
	return axutils.cache(self, "_mainGroup",
	function()
		local ui = self:UI()
		return ui and axutils.childWithRole(ui, "AXSplitGroup")
	end)
end

function Browser:filmstrip()
	if not self._filmstrip then
		self._filmstrip = BrowserFilmstrip:new(self)
	end
	return self._filmstrip
end

function Browser:list()
	if not self._list then
		self._list = BrowserList:new(self)
	end
	return self._list
end

function Browser:sidebar()
	if not self._sidebar then
		self._sidebar = Table:new(self, function()
			return axutils.childWithID(self:mainGroupUI(), "_NS:66")
		end)
	end
	return self._sidebar
end

function Browser:contents()
	if not self._contents then
		self._contents = ScrollArea:new(self, function()
			return axutils.childWithID(self:mainGroupUI(), "_NS:9")
		end)
	end
	return self._contents
end

return Browser