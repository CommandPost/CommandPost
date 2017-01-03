local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")
local fnutils							= require("hs.fnutils")

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
	   and #element == 4
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
-- Actions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

function Browser:showSidebar()
	if not self:sidebar():isShowing() then
		self:sidebarToggle():toggle()
	end
	return self
end

function Browser:hideSidebar()
	if self:sidebar():isShowing() then
		self:sidebarToggle():toggle()
	end
	return self
end

function Browser:toggleSidebar()
	local isShowing = self:sidebar():isShowing()
	self:sidebarToggle():toggle()
	return self
end

function Browser:showInstalledEffects()
	self:group():selectItem(1)
	return self
end

function Browser:showInstalledTransitions()
	self:showInstalledEffects()
	return self
end

function Browser:showAllEffects()
	self:showSidebar()
	self:sidebar():selectRowAt(1)
	return self
end

function Browser:showAllTransitions()
	return self:showAllEffects()
end

function Browser:_allRowsUI()
	--------------------------------------------------------------------------------
	-- Find the two 'All' rows (Video/Audio)
	--------------------------------------------------------------------------------
	return self:sidebar():rowsUI(function(row)
		local label = row[1][1]
		local value = label and label:attributeValue("AXValue")
		--------------------------------------------------------------------------------
		-- ENGLISH:		All
		-- GERMAN: 		Alle
		-- SPANISH: 	Todo
		-- FRENCH: 		Tous
		-- JAPANESE:	すべて
		-- CHINESE:		全部
		--------------------------------------------------------------------------------
		-- TODO: Use i18n to get the appropriate value for the current language
		return (value == "All") or (value == "Alle") or (value == "Todo") or (value == "Tous") or (value == "すべて") or (value == "全部")
	end)
end

function Browser:showAllVideoEffects()
	local allRows = self:_allRowsUI()
	if allRows and #allRows == 2 then
		--------------------------------------------------------------------------------
		-- Click 'All Video':
		--------------------------------------------------------------------------------
		self:sidebar():selectRow(allRows[1])
		return true
	end
	return false
end

function Browser:showAllAudioEffects()
	local allRows = self:_allRowsUI()
	if allRows and #allRows == 2 then
		--------------------------------------------------------------------------------
		-- Click 'All Video':
		--------------------------------------------------------------------------------
		self:sidebar():selectRow(allRows[2])
		return true
	end
	return false
end

function Browser:getCurrentEffects()
	return self:contents():childrenUI()
end

function Browser:getCurrentTransitions()
	return self:contents():childrenUI()
end

--- Returns the list of titles for all effects/transitions currently visible
function Browser:getCurrentTitles()
	local contents = self:contents():childrenUI()
	if contents ~= nil then
		return fnutils.map(contents, function(child)
			return child:attributeValue("AXTitle")
		end)
	end
	return nil
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
		end):uncached()
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

function Browser:sidebarToggle()
	if not self._sidebarToggle then
		self._sidebarToggle = CheckBox:new(self, function()
			return axutils.childWithRole(self:UI(), "AXCheckBox")
		end)
	end
	return self._sidebarToggle
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
		layout.sidebarToggle = self:sidebarToggle():saveLayout()
		-- reveal the sidebar temporarily so we can save it
		self:showSidebar()
		layout.sidebar = self:sidebar():saveLayout()
		self:sidebarToggle():loadLayout(layout.sidebarToggle)
		
		layout.contents = self:contents():saveLayout()
		layout.group = self:group():saveLayout()
		layout.search = self:search():saveLayout()
	end
	return layout
end

function Browser:loadLayout(layout)
	if layout and layout.showing then
		self:show()
		
		self:showSidebar()
		self:sidebar():loadLayout(layout.sidebar)
		self:sidebarToggle():loadLayout(layout.sidebarToggle)

		self:group():loadLayout(layout.group)
		
		self:search():loadLayout(layout.search)
		self:contents():loadLayout(layout.contents)
	else
		self:hide()
	end
end

return Browser