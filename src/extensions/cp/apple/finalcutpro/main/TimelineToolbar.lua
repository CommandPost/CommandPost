--- === cp.apple.finalcutpro.main.TimelineToolbar ===
---
--- Timeline Toolbar

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local require = require
local axutils							= require("cp.ui.axutils")
local prop								= require("cp.prop")

local RadioButton						= require("cp.ui.RadioButton")

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
function TimelineToolbar.new(parent)
    local o = prop.extend({_parent = parent}, TimelineToolbar)

    -- TODO: Add documentation
    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(self:parent():UI(), TimelineToolbar.matches)
        end,
        TimelineToolbar.matches)
    end)

    prop.bind(o) {
        UI = UI,

        -- TODO: Add documentation
        isShowing = UI:mutate(function(original)
            return original() ~= nil
        end),

        -- TODO: Add documentation
        -- Contains buttons relating to mouse skimming behaviour:
        skimmingGroupUI = UI:mutate(function(original, self)
            return axutils.cache(self, "_skimmingGroup", function()
                return axutils.childWithID(original(), id "SkimmingGroup")
            end)
        end),

        -- TODO: Add documentation
        effectsGroupUI = UI:mutate(function(original, self)
            return axutils.cache(self, "_effectsGroup", function()
                return axutils.childWithID(original(), id "EffectsGroup")
            end)
        end)
    }

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
-- THE BUTTONS:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineToolbar:appearance()
    if not self._appearance then
        self._appearance = TimelineAppearance.new(self)
    end
    return self._appearance
end

-- TODO: Add documentation
function TimelineToolbar:effectsToggle()
    if not self._effectsToggle then
        self._effectsToggle = RadioButton.new(self, function()
            local effectsGroup = self:effectsGroupUI()
            return effectsGroup and effectsGroup[1]
        end)
    end
    return self._effectsToggle
end

-- TODO: Add documentation
function TimelineToolbar:transitionsToggle()
    if not self._transitionsToggle then
        self._transitionsToggle = RadioButton.new(self, function()
            local effectsGroup = self:effectsGroupUI()
            return effectsGroup and effectsGroup[2]
        end)
    end
    return self._transitionsToggle
end

return TimelineToolbar
