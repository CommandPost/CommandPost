local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local PrimaryWindow						= require("hs.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("hs.finalcutpro.main.SecondaryWindow")
local Button							= require("hs.finalcutpro.ui.Button")
local Table								= require("hs.finalcutpro.ui.Table")
local ScrollArea						= require("hs.finalcutpro.ui.ScrollArea")
local CheckBox							= require("hs.finalcutpro.ui.CheckBox")
local PopUpButton						= require("hs.finalcutpro.ui.PopUpButton")
local TextField							= require("hs.finalcutpro.ui.TextField")

local Browser = {}

Browser.EFFECTS = "Effects"
Browser.TRANSITIONS = "Transitions"

function Browser.matches(element)
	return element and element:attributeValue("AXRole") == "AXGroup"
	   and axutils.childWithID(element, "_NS:452") ~= nil
end

function Browser:new(parent, type)
	o = {_parent = parent, _type = type}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Browser:parent()
	return self._parent
end

function Browser:app()
	return self:parent():app()
end

function Browser:type()
	return self._type
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- Browser UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Browser:UI()
	if self:isShowing() then
		return axutils.cache(self, "_ui", function()
			return axutils.childMatching(self:parent():mainUI(), Browser.matches)
		end,
		Browser.matches)
	end
end

function Browser:isShowing()
	return self:app():menuBar():isChecked("Window", "Show in Workspace", self:type())
end

function Browser:show()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the workspace
	menuBar:checkMenu("Window", "Show in Workspace", self:type())
	return self
end

function Browser:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the workspace
	menuBar:uncheckMenu("Window", "Show in Workspace", self:type())
	return self
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- UI Sections
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

function Browser:mainGroupUI()
	return axutils.cache(self, "_mainGroup",
	function()
		local ui = self:UI()
		return ui and axutils.childWithRole(ui, "AXSplitGroup")
	end)
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

function Browser:sidebarHidden()
	if not self._sidebarHidden then
		self._sidebarHidden = CheckBox:new(self, function()
			return axutils.childWithRole(self:UI(), "AXCheckBox")
		end)
	end
	return self._sidebarHidden
end

function Browser:group()
	if not self._group then
		self._group = PopUpButton:new(self, function()
			return axutils.childWithRole(self:mainGroupUI(), "AXPopUpButton")
		end)
	end
	return self._group
end

function Browser:search()
	if not self._search then
		self._search = TextField:new(self, function()
			return axutils.childWithRole(self:UI(), "AXTextField")
		end)
	end
	return self._search
end

function Browser:saveLayout()
	local layout = {}
	if self:isShowing() then
		layout.showing = true
		layout.sidebarHidden = self:sidebarHidden():saveLayout()
		-- reveal the sidebar temporarily so we can save it
		self:sidebarHidden():uncheck()
		layout.sidebar = self:sidebar():saveLayout()
		self:sidebarHidden():loadLayout(layout.sidebarHidden)
		
		layout.contents = self:contents():saveLayout()
		layout.group = self:group():saveLayout()
		layout.search = self:search():saveLayout()
	end
	return layout
end

function Browser:loadLayout(layout)
	if layout and layout.showing then
		self:show()
		
		self:sidebarHidden():uncheck()
		self:sidebar():loadLayout(layout.sidebar)
		self:sidebarHidden():loadLayout(layout.sidebarHidden)

		self:group():loadLayout(layout.group)
		
		self:search():loadLayout(layout.search)
		self:contents():loadLayout(layout.contents)
	else
		self:hide()
	end
end

return Browser