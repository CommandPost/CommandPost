--- === cp.apple.finalcutpro.main.TimelineToolbar ===
---
--- Timeline Toolbar

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local prop								= require("cp.prop")

local RadioButton						= require("cp.ui.RadioButton")
local StaticText                        = require("cp.ui.StaticText")

local TimelineAppearance				= require("cp.apple.finalcutpro.main.TimelineAppearance")

local id								= require("cp.apple.finalcutpro.ids") "TimelineToolbar"

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local childMatching, childWithID        = axutils.childMatching, axutils.childWithID
local childFromLeft                     = axutils.childFromLeft
local cache                             = axutils.cache

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
            return childMatching(self:parent():UI(), TimelineToolbar.matches)
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
            return cache(self, "_skimmingGroup", function()
                return childWithID(original(), id "SkimmingGroup")
            end)
        end),

        -- TODO: Add documentation
        effectsGroupUI = UI:mutate(function(original, self)
            return cache(self, "_effectsGroup", function()
                return childWithID(original(), id "EffectsGroup")
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
-- THE TOOLBAR ITEMS:
--
-----------------------------------------------------------------------


--- cp.apple.finalcutpro.main.TimelineToolbar:title() -> cp.ui.StaticText
--- Method
--- Returns the title [StaticText](cp.ui.StaticText.md) from the Timeline Titlebar.
---
--- Parameters:
--- * None.
---
--- Returns:
--- * The [StaticText](cp.ui.StaticText.md) containing the title.
function TimelineToolbar:title()
    if not self._title then
        self._title = StaticText(self, self.UI:mutate(function(original)
            return cache(self, "_titleUI", function()
                return childFromLeft(original(), 1, StaticText.matches)
            end)
        end))
    end
    return self._title
end

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
        self._effectsToggle = RadioButton(self, function()
            local effectsGroup = self:effectsGroupUI()
            return effectsGroup and effectsGroup[1]
        end)
    end
    return self._effectsToggle
end

-- TODO: Add documentation
function TimelineToolbar:transitionsToggle()
    if not self._transitionsToggle then
        self._transitionsToggle = RadioButton(self, function()
            local effectsGroup = self:effectsGroupUI()
            return effectsGroup and effectsGroup[2]
        end)
    end
    return self._transitionsToggle
end

return TimelineToolbar
