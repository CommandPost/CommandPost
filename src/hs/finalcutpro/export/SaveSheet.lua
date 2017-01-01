local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")
local just							= require("hs.just")
local windowfilter					= require("hs.window.filter")

local ReplaceAlert					= require("hs.finalcutpro.export.ReplaceAlert")

local SaveSheet = {}

function SaveSheet.matches(element)
	if element then
		return element:attributeValue("AXRole") == "AXSheet"
		   and axutils.childWithID(element, "_NS:115") ~= nil
	end
	return false
end


function SaveSheet:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function SaveSheet:app()
	return self._app
end

function SaveSheet:UI()
	return axutils.cache(self, "_ui", function()
		local focusedWindowUI = self:app():UI():focusedWindow()
		if focusedWindowUI and SaveSheet.matches(focusedWindowUI) then
			return focusedWindowUI
		end
		return nil
	end,
	SaveSheet.matches)
end

function SaveSheet:isShowing()
	return self:UI() ~= nil or self:replaceAlert():isShowing()
end

--- Ensures the SaveSheet is showing
function SaveSheet:show()
	if not self:isShowing() then
		-- open the window
		if self:app():menuBar():isEnabled("Final Cut Pro", "Commands", "Customize…") then
			self:app():menuBar():selectMenu("Final Cut Pro", "Commands", "Customize…")
			local ui = just.doUntil(function() return self:UI() end)
		end
	end
	return self
end

function SaveSheet:hide()
	self:pressCancel()
end

function SaveSheet:pressCancel()
	local ui = self:UI()
	if ui then
		local btn = ui:cancelButton()
		if btn then
			btn:doPress()
		end
	end
	return self
end

function SaveSheet:pressSave()
	local ui = self:UI()
	if ui then
		local btn = ui:defaultButton()
		if btn and btn:enabled() then
			btn:doPress()
		end
	end
	return self
end

function SaveSheet:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end


function SaveSheet:replaceAlert()
	if not self._replaceAlert then
		self._replaceAlert = ReplaceAlert:new(self:app())
	end
	return self._replaceAlert
end


return SaveSheet