local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Browser = {}


function Browser.isBrowser(element)
	return axutils.childWith(element, "AXIdentifier", "_NS:82") ~= nil
end


function Browser:new(parent, secondary)
	o = {_parent = parent, _secondary = secondary}
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

function Browser:isOnSecondaryWindow()
	return self._secondary
end

function Browser:isOnPrimaryWindow()
	return not self._secondary
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- BROWSER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Browser:UI()
	local top = self:parent():browserGroupUI()
	if top then
		for i,child in ipairs(top) do
			if Browser.isBrowser(child) then
				return child
			end
		end
	end
	return nil
end

function Browser:isShowing()
	return self:UI() ~= nil
end

function Browser:show()
	local parent = self:parent()
	-- show the parent.
	local menuBar = self:app():menuBar()
	
	if self:isOnPrimaryWindow() then
		-- if the browser is on the secondary, we need to turn it off before enabling in primary
		menuBar:uncheckMenu("Window", "Show in Secondary Display", "Browser")
		-- Then enable it in the primary
		menuBar:checkMenu("Window", "Show in Workspace", "Browser")
	else
		menuBar:checkMenu("Window", "Show in Secondary Display", "Browser")
	end
	return self
end

function Browser:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the workspace
	menuBar:uncheckMenu("Window", "Show in Workspace", "Browser")
	return self
end


return Browser