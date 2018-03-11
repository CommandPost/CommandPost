--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.TimelineAppearance ===
---
--- Timeline Appearance Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local just								= require("cp.just")
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local CheckBox							= require("cp.ui.CheckBox")
local Slider							= require("cp.ui.Slider")

local id								= require("cp.apple.finalcutpro.ids") "TimelineAppearance"

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
	local o = {_parent = parent}
	return prop.extend(o, TimelineAppearance)
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
		return axutils.childWithID(self:parent():UI(), id "Toggle")
	end)
end

-- TODO: Add documentation
function TimelineAppearance:toggle()
	if not self._toggle then
		self._toggle = CheckBox:new(self:parent(), function()
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
TimelineAppearance.isShowing = prop.new(function(self)
	return self:UI() ~= nil
end):bind(TimelineAppearance)

-- TODO: Add documentation
function TimelineAppearance:show()
	if not self:isShowing() then
		self:toggle():checked(true)
	end
	return self
end

-- TODO: Add documentation
function TimelineAppearance:hide()
	local ui = self:UI()
	if ui then
		ui:doCancel()
	end
	just.doWhile(function() return self:isShowing() end)
	return self
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
			return axutils.childMatching(self:UI(), function(e)
				return e:attributeValue("AXRole") == "AXSlider" and e:attributeValue("AXMaxValue") == 210
			end)
		end)
	end
	return self._clipHeight
end

function TimelineAppearance:zoomAmount()
	if not self._zoomAmount then
		self._zoomAmount = Slider:new(self, function()
			return axutils.childWithID(self:UI(), id "ZoomAmount")
		end)
	end
	return self._zoomAmount
end

return TimelineAppearance