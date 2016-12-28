local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local PrimaryWindow						= require("hs.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("hs.finalcutpro.main.SecondaryWindow")
local Button							= require("hs.finalcutpro.ui.Button")
local BrowserList						= require("hs.finalcutpro.main.BrowserList")
local BrowserFilmstrip					= require("hs.finalcutpro.main.BrowserFilmstrip")
local Table								= require("hs.finalcutpro.ui.Table")

local Browser = {}

function Browser.matches(element)
	return axutils.childWith(element, "AXIdentifier", "_NS:82") ~= nil
end

function Browser:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Browser:app()
	return self._app
end

function Browser:isOnSecondary()
	local ui = self:UI()
	return ui and SecondaryWindow.matches(ui:window())
end

function Browser:isOnPrimary()
	local ui = self:UI()
	return ui and PrimaryWindow.matches(ui:window())
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- BROWSER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Browser:UI()
	return axutils.cache(self, "_ui", function()
		local app = self:app()
		return Browser._findBrowser(app:secondaryWindow(), app:primaryWindow())
	end,
	Browser.matches)
end

function Browser._findBrowser(...)
	for i = 1,select("#", ...) do
		local window = select(i, ...)
		if window then
			local ui = window:browserGroupUI()
			if ui then
				local browser = axutils.childMatching(ui, Browser.matches)
				if browser then return browser end
			end
		end
	end
	return nil
end

function Browser:isShowing()
	return self:UI() ~= nil
end

function Browser:showOnPrimary()
	-- show the parent.
	local menuBar = self:app():menuBar()
	
	-- if the browser is on the secondary, we need to turn it off before enabling in primary
	menuBar:uncheckMenu("Window", "Show in Secondary Display", "Browser")
	-- Then enable it in the primary
	menuBar:checkMenu("Window", "Show in Workspace", "Browser")
	return self
end

function Browser:showOnSecondary()
	-- show the parent.
	local menuBar = self:app():menuBar()
	
	menuBar:checkMenu("Window", "Show in Secondary Display", "Browser")
	return self
end


function Browser:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the workspace
	menuBar:uncheckMenu("Window", "Show in Workspace", "Browser")
	return self
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Buttons
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

function Browser:toggleViewMode()
	if not self._viewMode then
		self._viewMode = Button:new(self, {id = "_NS:82"})
	end
	return self._viewMode
end

function Browser:appearanceAndFiltering()
	if not self._appearanceAndFiltering then
		self._appearanceAndFiltering = Button:new(self, {id = "_NS:68"})
	end
	return self._appearanceAndFiltering
end

function Browser:toggleSearchBar()
	if not self._toggleSearchBar then
		self._toggleSearchBar = Button:new(self, {id = "_NS:92"})
	end
	return self._toggleSearchBar
end

Browser.ALL_CLIPS = 1
Browser.HIDE_REJECTED = 2
Browser.NO_RATINGS_OR_KEYWORDS = 3
Browser.FAVORITES = 4
Browser.REJECTED = 5
Browser.UNUSED = 6

function Browser:selectClipFiltering(filterType)
	local ui = self:UI()
	if ui then
		button = axutils.childWithID(ui, "_NS:9")
		if button then
			local menu = button[1]
			if not menu then
				button:doPress()
				menu = button[1]
			end
			local menuItem = menu[filterType]
			if menuItem then
				menuItem:doPress()
			end
		end
	end
	return self
end

function Browser:mainGroupUI()
	return axutils.cache(self, "_mainGroup", 
	function()
		local ui = self:UI()
		return ui and axutils.childWithID(ui, "_NS:344")
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
			return axutils.childWithID(self:mainGroupUI(), "_NS:9")
		end)
	end
	return self._sidebar
end

function Browser:isListView()
	return self:list():isShowing()
end

function Browser:isFilmstripView()
	return self:filmstrip():isShowing()
end

function Browser:clipsUI()
	if self:isListView() then
		return self:list():clipsUI()
	elseif self:isFilmstripView() then
		return self:filmstrip():clipsUI()
	else
		return nil
	end
end

function Browser:selectedClipsUI()
	if self:isListView() then
		return self:list():selectedClipsUI()
	elseif self:isFilmstripView() then
		return self:filmstrip():selectedClipsUI()
	else
		return nil
	end
end

function Browser:showClip(clipUI)
	if self:isListView() then
		self:list():showClip(clipUI)
	else
		self:filmstrip():showClip(clipUI)
	end
	return self
end

function Browser:selectClip(clipUI)
	if self:isListView() then
		self:list():selectClip(clipUI)
	else
		self:filmstrip():selectClip(clipUI)
	end
	return self
end

function Browser:selectClipAt(index)
	if self:isListView() then
		self:list():selectClipAt(index)
	else
		self:filmstrip():selectClipAt(index)
	end
	return self
end

return Browser