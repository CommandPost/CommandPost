--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.export.GoToPrompt ===
---
--- Go To Prompt.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")
local eventtap						= require("hs.eventtap")

local axutils						= require("cp.apple.finalcutpro.axutils")
local just							= require("cp.just")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local GoToPrompt = {}

-- TODO: Add documentation
function GoToPrompt.matches(element)
	if element then
		return element:attributeValue("AXRole") == "AXSheet"			-- it's a sheet
		   and (axutils.childWithRole(element, "AXTextField") ~= nil 	-- with a text field
		    or axutils.childWithRole(element, "AXComboBox") ~= nil)
	end
	return false
end

-- TODO: Add documentation
function GoToPrompt:new(parent)
	local o = {_parent = parent}
	return prop.extend(o, GoToPrompt)
end

-- TODO: Add documentation
function GoToPrompt:parent()
	return self._parent
end

-- TODO: Add documentation
function GoToPrompt:app()
	return self:parent():app()
end

-- TODO: Add documentation
function GoToPrompt:UI()
	return axutils.cache(self, "_ui", function()
		return axutils.childMatching(self:parent():UI(), GoToPrompt.matches)
	end,
	GoToPrompt.matches)
end

--- cp.apple.finalcutpro.export.GoToPrompt.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the 'Go To' prompt showing?
GoToPrompt.isShowing = prop.new(function(self)
	return self:UI() ~= nil
end):bind(GoToPrompt)

-- TODO: Add documentation
function GoToPrompt:show()
	if self:parent():isShowing() then
		eventtap.keyStroke({"cmd", "shift"}, "g")
		just.doUntil(function() return self:isShowing() end)
	end
	return self
end

-- TODO: Add documentation
function GoToPrompt:hide()
	self:pressCancel()
end

-- TODO: Add documentation
function GoToPrompt:pressCancel()
	local ui = self:UI()
	if ui then
		local btn = ui:cancelButton()
		if btn then
			btn:doPress()
			just.doWhile(function() return self:isShowing() end)
		end
	end
	return self
end

-- TODO: Add documentation
function GoToPrompt:setValue(value)
	local textField = axutils.childWithRole(self:UI(), "AXTextField")
	if textField then
		textField:setAttributeValue("AXValue", value)
	else
		local comboBox = axutils.childWithRole(self:UI(), "AXComboBox")
		if comboBox then
			comboBox:setAttributeValue("AXValue", value)
		end
	end
	return self
end

-- TODO: Add documentation
function GoToPrompt:pressDefault()
	local ui = self:UI()
	if ui then
		local btn = ui:defaultButton()
		if btn and btn:enabled() then
			btn:doPress()
			just.doWhile(function() return self:isShowing() end)
		end
	end
	return self
end

-- TODO: Add documentation
function GoToPrompt:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

return GoToPrompt