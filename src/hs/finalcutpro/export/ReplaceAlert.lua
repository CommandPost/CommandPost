local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")
local just							= require("hs.just")
local windowfilter					= require("hs.window.filter")

local ReplaceAlert = {}

function ReplaceAlert.matches(element)
	if element then
		return element:attributeValue("AXRole") == "AXSheet"
			-- NOTE: This AXIdentifier seems to be different on different machines and/or macOS versions:
		   	-- and element:attributeValue("AXIdentifier") == "_NS:79" --"_NS:46"
	end
	return false
end


function ReplaceAlert:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function ReplaceAlert:app()
	return self._app
end

function ReplaceAlert:UI()
	return axutils.cache(self, "_ui", function()
		local focusedWindowUI = self:app():UI():focusedWindow()
		if focusedWindowUI and ReplaceAlert.matches(focusedWindowUI) then
			return focusedWindowUI
		end
		return nil
	end,
	ReplaceAlert.matches)
end

function ReplaceAlert:isShowing()
	return self:UI() ~= nil
end

function ReplaceAlert:hide()
	self:pressCancel()
end

function ReplaceAlert:pressCancel()
	local ui = self:UI()
	if ui then
		local btn = ui:cancelButton()
		if btn then
			btn:doPress()
		end
	end
	return self
end

function ReplaceAlert:pressReplace()
	local ui = self:UI()
	if ui then
		local btn = ui:defaultButton()
		if btn and btn:enabled() then
			btn:doPress()
		end
	end
	return self
end

function ReplaceAlert:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

return ReplaceAlert