local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")
local just							= require("hs.just")

local CommandsWindow = {}

CommandsWindow.GROUP						= "_NS:9"

function CommandsWindow.matches(element)
	
end


function CommandsWindow:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function CommandsWindow:app()
	return self._app
end

function CommandsWindow:UI()
	return axutils.cache(self, "_ui", function()
		local windowsUI = self:app():windowsUI()
		return windowsUI and self:_findWindowUI(windowsUI)
	end,
	CommandsWindow.matches)
end

function CommandsWindow:_findWindowUI(windows)
	for i,w in ipairs(windows) do
		if CommandsWindow.matches(w) then
			return w
		end
	end
	return nil
end
