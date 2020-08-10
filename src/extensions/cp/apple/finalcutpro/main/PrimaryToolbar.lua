--- === cp.apple.finalcutpro.main.PrimaryToolbar ===
---
--- Timeline Toolbar.

local require = require

-- local log								= require "hs.logger".new("PrimaryToolbar")

local axutils							= require "cp.ui.axutils"
local prop								= require "cp.prop"

local Button							= require "cp.ui.Button"
local CheckBox							= require "cp.ui.CheckBox"
local Toolbar                           = require "cp.ui.Toolbar"


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
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(original(), PrimaryToolbar.matches)
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
                local bsParent = getParent(self._browserShowing:UI())
                if eParent == bsParent then
                    --------------------------------------------------------------------------------
                    -- Update the checked status for any watchers:
                    --------------------------------------------------------------------------------
                    -- log.df("value changed: parent: %s", _inspect(eParent))
                    self._browserShowing.checked:update()
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- A CheckBox instance to access the browser button:
--------------------------------------------------------------------------------
function PrimaryToolbar.lazy.value:_browserShowing()
    return CheckBox(self, function()
        local group = axutils.childFromRight(self:UI(), 4)
        if group and group:attributeValue("AXRole") == "AXGroup" then
            return axutils.childWithRole(group, "AXCheckBox")
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.browserShowing <cp.prop: boolean>
--- Field
--- If `true`, the browser panel is showing. Can be modified or watched.
function PrimaryToolbar.lazy.prop:browserShowing()
    return self._browserShowing.checked
end

-----------------------------------------------------------------------
--
-- THE BUTTONS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryToolbar.shareButton <cp.ui.Button>
--- Field
--- The Share Button.
function PrimaryToolbar.lazy.value:shareButton()
    return Button(self, function() return axutils.childFromRight(self:UI(), 1) end)
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.browserButton <cp.ui.CheckBox>
--- Field
--- The Browser Button Checkbox.
function PrimaryToolbar.lazy.value:browserButton()
    return CheckBox(self, function()
        local group = axutils.childFromRight(self:UI(), 4)
        if group and group:attributeValue("AXRole") == "AXGroup" then
            return axutils.childMatching(group, CheckBox.matches)
        end
        return nil
    end)
end

return PrimaryToolbar
