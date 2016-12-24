local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local PrimaryWindow						= require("hs.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("hs.finalcutpro.main.SecondaryWindow")

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


return Browser