--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.export.SaveSheet ===
---
--- Save Sheet

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("PrefsDlg")

local just							= require("cp.just")

local axutils						= require("cp.apple.finalcutpro.axutils")
local GoToPrompt					= require("cp.apple.finalcutpro.export.GoToPrompt")
local ReplaceAlert					= require("cp.apple.finalcutpro.export.ReplaceAlert")
local TextField						= require("cp.apple.finalcutpro.ui.TextField")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local SaveSheet = {}

-- TODO: Add documentation
function SaveSheet.matches(element)
	if element then
		return element:attributeValue("AXRole") == "AXSheet"
	end
	return false
end

-- TODO: Add documentation
function SaveSheet:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function SaveSheet:parent()
	return self._parent
end

-- TODO: Add documentation
function SaveSheet:app()
	return self:parent():app()
end

-- TODO: Add documentation
function SaveSheet:UI()
	return axutils.cache(self, "_ui", function()
		return axutils.childMatching(self:parent():UI(), SaveSheet.matches)
	end,
	SaveSheet.matches)
end

-- TODO: Add documentation
function SaveSheet:isShowing()
	return self:UI() ~= nil or self:replaceAlert():isShowing()
end

-- TODO: Add documentation
function SaveSheet:hide()
	self:pressCancel()
end

-- TODO: Add documentation
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

-- TODO: Add documentation
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

-- TODO: Add documentation
function SaveSheet:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

-- TODO: Add documentation
function SaveSheet:filename()
	if not self._filename then
		self._filename = TextField:new(self, function()
			return axutils.childWithRole(self:UI(), "AXTextField")
		end)
	end
	return self._filename
end

-- TODO: Add documentation
function SaveSheet:setPath(path)
	if self:isShowing() then
		-- Display the 'Go To' prompt
		self:goToPrompt():show():setValue(path):pressDefault()
	end
	return self
end

-- TODO: Add documentation
function SaveSheet:replaceAlert()
	if not self._replaceAlert then
		self._replaceAlert = ReplaceAlert:new(self)
	end
	return self._replaceAlert
end

-- TODO: Add documentation
function SaveSheet:goToPrompt()
	if not self._goToPrompt then
		self._goToPrompt = GoToPrompt:new(self)
	end
	return self._goToPrompt
end

return SaveSheet