--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.main.TimelineToolbar ===
---
--- Timeline Toolbar

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils							= require("cp.finalcutpro.axutils")

local CheckBox							= require("cp.finalcutpro.ui.CheckBox")
local RadioButton						= require("cp.finalcutpro.ui.RadioButton")

local TimelineAppearance				= require("cp.finalcutpro.main.TimelineAppearance")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TimelineToolbar = {}

-- TODO: Add documentation
function TimelineToolbar.matches(element)
	-----------------------------------------------------------------------
	-- NOTE: _NS:237 is correct for both 10.3.2 and 10.3.3:
	-----------------------------------------------------------------------
	return element and element:attributeValue("AXIdentifier") ~= "_NS:237"
end

-- TODO: Add documentation
function TimelineToolbar:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function TimelineToolbar:parent()
	return self._parent
end

-- TODO: Add documentation
function TimelineToolbar:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- TIMELINE UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineToolbar:UI()
	return axutils.cache(self, "_ui", function()
		return axutils.childMatching(self:parent():UI(), TimelineToolbar.matches)
	end,
	TimelineToolbar.matches)
end

-- TODO: Add documentation
function TimelineToolbar:isShowing()
	return self:UI() ~= nil
end

-- TODO: Add documentation
-- Contains buttons relating to mouse skimming behaviour:
function TimelineToolbar:skimmingGroupUI()
	return axutils.cache(self, "_skimmingGroup", function()
		-----------------------------------------------------------------------
		-- _NS:178 is for 10.3.2 and _NS:179 is for 10.3.3:
		-----------------------------------------------------------------------
		return axutils.childWithID(self:UI(), "_NS:178") or axutils.childWithID(self:UI(), "_NS:179")
	end)
end

-- TODO: Add documentation
function TimelineToolbar:effectsGroupUI()
	return axutils.cache(self, "_effectsGroup", function()
		-----------------------------------------------------------------------
		-- NOTE: _NS:165 is for FCPX 10.3.2 and _NS:166 is for 10.3.3:
		-----------------------------------------------------------------------
		return axutils.childWithID(self:UI(), "_NS:165") or axutils.childWithID(self:UI(), "_NS:166")
	end)
end

-----------------------------------------------------------------------
--
-- THE BUTTONS:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineToolbar:appearance()
	if not self._appearance then
		self._appearance = TimelineAppearance:new(self)
	end
	return self._appearance
end

-- TODO: Add documentation
function TimelineToolbar:effectsToggle()
	if not self._effectsToggle then
		self._effectsToggle = RadioButton:new(self, function()
			return self:effectsGroupUI()[1]
		end)
	end
	return self._effectsToggle
end

-- TODO: Add documentation
function TimelineToolbar:transitionsToggle()
	if not self._transitionsToggle then
		self._transitionsToggle = RadioButton:new(self, function()
			return self:effectsGroupUI()[2]
		end)
	end
	return self._transitionsToggle
end

return TimelineToolbar