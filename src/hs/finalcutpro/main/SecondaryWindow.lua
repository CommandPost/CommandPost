local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")
local just							= require("hs.just")

local Button						= require("hs.finalcutpro.ui.Button")

local SecondaryWindow = {}

function SecondaryWindow.matches(element)
	if element and element:attributeValue("AXSubrole") == "AXUnknown" then
		local children = element:attributeValue("AXChildren")
		return children and #children == 1 and children[1]:attributeValue("AXRole") == "AXSplitGroup"
	end
	return false
end

function SecondaryWindow:new(app)
	o = {
		_app = app
	}
	setmetatable(o, self)
	self.__index = self
	
	return o
end

function SecondaryWindow:app()
	return self._app
end

function SecondaryWindow:show()
	-- Currently a null-op. Determin if there are any scenarios where we need to force this.
	return true
end

function SecondaryWindow:UI()
	return axutils.cache(self, "_ui", function()
		local ui = self:app():UI()
		if ui then
			if SecondaryWindow.matches(ui:mainWindow()) then
				return ui:mainWindow()
			else
				local windowsUI = self:app():windowsUI()
				return windowsUI and self:_findWindowUI(windowsUI)
			end
		end
		return nil
	end,
	SecondaryWindow.matches)
end

function SecondaryWindow:_findWindowUI(windows)
	for i,w in ipairs(windows) do
		if SecondaryWindow.matches(w) then return w end
	end
	return nil
end

function SecondaryWindow:isFullScreen()
	local ui = self:UI()
	return ui and ui:fullScreen()
end

function SecondaryWindow:setFullScreen(isFullScreen)
	local ui = self:UI()
	if ui then ui:setFullScreen(isFullScreen) end
	return self
end

function SecondaryWindow:toggleFullScreen()
	local ui = self:UI()
	if ui then ui:setFullScreen(not self:isFullScreen()) end
	return self
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- UI STRUCTURE
-----------------------------------------------------------------------
-----------------------------------------------------------------------

-- The top AXSplitGroup contains the 
function SecondaryWindow:rootGroupUI()
	return axutils.cache(self, "_rootGroup", function()
		local ui = self:UI()
		return ui and axutils.childWith(ui, "AXRole", "AXSplitGroup")
	end)
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- VIEWER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function SecondaryWindow:viewerGroupUI()
	return self:rootGroupUI()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------

function SecondaryWindow:timelineGroupUI()
	return axutils.cache(self, "_timelineGroup", function()
		-- for some reason, the Timeline is burried under three levels
		local root = self:rootGroupUI()
		if root and root[1] and root[1][1] then
			return root[1][1]
		end
	end)
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- BROWSER
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function SecondaryWindow:browserGroupUI()
	return self:rootGroupUI()
end

return SecondaryWindow
