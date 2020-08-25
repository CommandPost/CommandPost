--- === cp.apple.finalcutpro.main.PrimaryToolbar ===
---
--- Timeline Toolbar.

local require = require

-- local log								= require "hs.logger".new("PrimaryToolbar")

local axutils							= require "cp.ui.axutils"

local Button							= require "cp.ui.Button"
local CheckBox							= require "cp.ui.CheckBox"
local Group                             = require "cp.ui.Group"
local Toolbar                           = require "cp.ui.Toolbar"

local cache                             = axutils.cache
local childFromLeft                     = axutils.childFromLeft
local childFromRight                    = axutils.childFromRight
local childMatching                     = axutils.childMatching

local PrimaryToolbar = Toolbar:subclass("cp.apple.finalcutpro.main.PrimaryToolbar")

--- cp.apple.finalcutpro.main.PrimaryToolbar.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function PrimaryToolbar.static.matches(element)
    return Toolbar.matches(element)
end

-- getParent(element) -> none
-- Function
-- Get the parent object of a `axuielementObject`.
--
-- Parameters:
--  * element - A `axuielementObject`.
--
-- Returns:
--  * The parent of the `element` as a `axuielementObject`.
local function getParent(element)
    return element and element:attributeValue("AXParent")
end

--- cp.apple.finalcutpro.main.PrimaryToolbar(parent) -> PrimaryToolbar
--- Constructor
--- Creates a new `PrimaryToolbar` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `PrimaryToolbar` object.
function PrimaryToolbar:initialize(parent)

    local UI = parent.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), PrimaryToolbar.matches)
        end,
        PrimaryToolbar.matches)
    end)

    Toolbar.initialize(self, parent, UI)

    --------------------------------------------------------------------------------
    -- Watch for AXValueChanged notifications in the app for this CheckBox:
    --------------------------------------------------------------------------------
    self:app():notifier():watchFor("AXValueChanged", function(element)
        if element:attributeValue("AXRole") == "AXImage" then
            local eParent = getParent(element)
            if eParent then
                --------------------------------------------------------------------------------
                -- Browser showing check:
                --------------------------------------------------------------------------------
                local bsParent = getParent(self.browserShowing:UI())
                if eParent == bsParent then
                    --------------------------------------------------------------------------------
                    -- Update the checked status for any watchers:
                    --------------------------------------------------------------------------------
                    -- log.df("value changed: parent: %s", _inspect(eParent))
                    self.browserShowing.checked:update()
                end
            end
        end
    end)
end

-----------------------------------------------------------------------
--
-- THE BUTTONS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryToolbar.mediaImport <cp.ui.Button>
--- Field
--- The `Button` that will open the `MediaImport` dialog
function PrimaryToolbar.lazy.value:mediaImport()
    return Button(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 1, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.keywordEditor <cp.ui.CheckBox>
--- Field
--- The `CheckBox` that will open the `KeywordEditor` dialog when checked.
function PrimaryToolbar.lazy.value:keywordEditor()
    return CheckBox(self, self.UI:mutate(function(original)
        -- for some reason some of these buttons are individually wrapped in an AXGroup
        local group = childFromLeft(original(), 1, Group.matches)
        if group then
            return childMatching(group, CheckBox.matches)
        end
    end))
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.backgroundTasksWindow <cp.ui.CheckBox>
--- Field
--- The `CheckBox` that will open the `BackgroundTasksWindow` dialog
function PrimaryToolbar.lazy.value:backgroundTasksWindow()
    return CheckBox(self, self.UI:mutate(function(original)
        -- for some reason CheckBoxes are individually wrapped in an AXGroup
        local group = childFromLeft(original(), 2, Group.matches)
        if group then
            return childMatching(group, CheckBox.matches)
        end
    end))
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.extensions <cp.ui.Button>
--- Field
--- The `Button` that will open the "Available Extensions" dialog, or trigger the only extension, if only one is installed.
function PrimaryToolbar.lazy.value:extensions()
    return Button(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 2, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.browserShowing <cp.ui.CheckBox>
--- Field
--- The `CheckBox` indicating if the `Browser` is showing
function PrimaryToolbar.lazy.value:browserShowing()
    return CheckBox(self, self.UI:mutate(function(original)
        -- for some reason CheckBoxes are individually wrapped in an AXGroup
        local group = childFromRight(original(), 4)
        if Group.matches(group) then
            return childMatching(group, CheckBox.matches)
        end
        return nil
    end))
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.timelineShowing <cp.ui.CheckBox>
--- Field
--- The `CheckBox` indicating if the `Timeline` is showing
function PrimaryToolbar.lazy.value:timelineShowing()
    return CheckBox(self, function()
        -- for some reason CheckBoxes are individually wrapped in an AXGroup
        local group = childFromRight(self:UI(), 3)
        if Group.matches(group) then
            return childMatching(group, CheckBox.matches)
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.inspectorShowing <cp.ui.CheckBox>
--- Field
--- The `CheckBox` indicating if the Inspector is showing
function PrimaryToolbar.lazy.value:inspectorShowing()
    return CheckBox(self, function()
        -- for some reason CheckBoxes are individually wrapped in an AXGroup
        local group = childFromRight(self:UI(), 2)
        if Group.matches(group) then
            return childMatching(group, CheckBox.matches)
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.shareButton <cp.ui.Button>
--- Field
--- The Share Button.
function PrimaryToolbar.lazy.value:shareButton()
    return Button(self, function() return childFromRight(self:UI(), 1) end)
end

return PrimaryToolbar
