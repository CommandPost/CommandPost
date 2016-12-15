local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")
local just							= require("hs.just")

local Button						= require("hs.finalcutpro.ui.Button")

local PrimaryWindow = {}

PrimaryWindow.GROUP						= "_NS:9"

function PrimaryWindow:new(app)
	o = {
		_app = app
	}
	setmetatable(o, self)
	self.__index = self
	
	return o
end

function PrimaryWindow:app()
	return self._app
end

function PrimaryWindow:UI()
	local ui = self:app():UI():mainWindow()
	if not self:_isPrimaryWindow(ui) then
		local windowsUI = self:app():windowsUI()
		ui = windowsUI and self:_findWindowUI(windowsUI)
	end
	return ui
end

function PrimaryWindow:_findWindowUI(windows)
	for i,w in ipairs(windows) do
		if self:isPrimaryWindow(w)
		then
			return w
		end
	end
	return nil
end

function PrimaryWindow:_isPrimaryWindow(w)
	return w and w:attributeValue("AXSubrole") == "AXStandardWindow"
end

function PrimaryWindow:isFullScreen()
	return self:UI():fullScreen()
end

function PrimaryWindow:setFullScreen(isFullScreen)
	self:UI():setFullScreen(isFullScreen)
	return self
end

function PrimaryWindow:toggleFullScreen()
	self:UI():setFullScreen(not self:isFullScreen())
	return self
end

return PrimaryWindow
