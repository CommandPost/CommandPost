--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Timeline Appearance

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils							= require("cp.finalcutpro.axutils")

local CheckBox							= require("cp.finalcutpro.ui.CheckBox")
local Slider							= require("cp.finalcutpro.ui.Slider")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TimelineAppearance = {}

-- TODO: Add documentation
function TimelineAppearance.matches(element)
	return element and element:attributeValue("AXRole") == "AXPopover"
end

-- TODO: Add documentation
function TimelineAppearance:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function TimelineAppearance:parent()
	return self._parent
end

-- TODO: Add documentation
function TimelineAppearance:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- APPEARANCE POPOVER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineAppearance:toggleUI()
	return axutils.cache(self, "_toggleUI", function()
		return axutils.childWithID(self:parent():UI(), "_NS:154")
	end)
end

-- TODO: Add documentation
function TimelineAppearance:toggle()
	if not self._toggle then
		self._toggle = CheckBox:new(self, function()
			return self:toggleUI()
		end)
	end
	return self._toggle
end

-- TODO: Add documentation
function TimelineAppearance:UI()
	return axutils.cache(self, "_ui", function()
		return axutils.childMatching(self:toggleUI(), TimelineAppearance.matches)
	end,
	TimelineAppearance.matches)
end

-- TODO: Add documentation
function TimelineAppearance:show()
	if not self:isShowing() then
		self:toggle():check()
	end
	return self
end

-- TODO: Add documentation
function TimelineAppearance:hide()
	local ui = self:UI()
	if ui then
		ui:doCancel()
	end
	return self
end

-- TODO: Add documentation
function TimelineAppearance:isShowing()
	return self:UI() ~= nil
end

-----------------------------------------------------------------------
--
-- THE BUTTONS:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineAppearance:clipHeight()
	if not self._clipHeight then
		self._clipHeight = Slider:new(self, function()
			return axutils.childWithID(self:UI(), "_NS:104")
		end)
	end
	return self._clipHeight
end

return TimelineAppearance