--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.TimelineToolbar ===
---
--- Timeline Toolbar

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils							= require("cp.apple.finalcutpro.axutils")
local prop								= require("cp.prop")

local CheckBox							= require("cp.apple.finalcutpro.ui.CheckBox")
local RadioButton						= require("cp.apple.finalcutpro.ui.RadioButton")

local TimelineAppearance				= require("cp.apple.finalcutpro.main.TimelineAppearance")

local id								= require("cp.apple.finalcutpro.ids") "TimelineToolbar"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TimelineToolbar = {}

-- TODO: Add documentation
function TimelineToolbar.matches(element)
	return element and element:attributeValue("AXIdentifier") ~= id "ID"
end

-- TODO: Add documentation
function TimelineToolbar:new(parent)
	local o = {_parent = parent}
	return prop.extend(o, TimelineToolbar)
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
TimelineToolbar.isShowing = prop.new(function(this)
	return self:UI() ~= nil
end):bind(TimelineToolbar)

-- TODO: Add documentation
-- Contains buttons relating to mouse skimming behaviour:
function TimelineToolbar:skimmingGroupUI()
	return axutils.cache(self, "_skimmingGroup", function()
		return axutils.childWithID(self:UI(), id "SkimmingGroup")
	end)
end

-- TODO: Add documentation
function TimelineToolbar:effectsGroupUI()
	return axutils.cache(self, "_effectsGroup", function()
		return axutils.childWithID(self:UI(), id "EffectsGroup")
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