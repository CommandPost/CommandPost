--- === cp.apple.finalcutpro.main.PrimaryToolbar ===
---
--- Timeline Toolbar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("PrimaryToolbar")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local prop								= require("cp.prop")

local Button							= require("cp.ui.Button")
local CheckBox							= require("cp.ui.CheckBox")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PrimaryToolbar = {}

--- cp.apple.finalcutpro.main.PrimaryToolbar.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function PrimaryToolbar.matches(element)
    return element and element:attributeValue("AXRole") == "AXToolbar"
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

--- cp.apple.finalcutpro.main.PrimaryToolbar.new(parent) -> PrimaryToolbar
--- Constructor
--- Creates a new `PrimaryToolbar` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `PrimaryToolbar` object.
function PrimaryToolbar.new(parent)
    local o = prop.extend({_parent = parent}, PrimaryToolbar)

    --------------------------------------------------------------------------------
    -- A CheckBox instance to access the browser button:
    --------------------------------------------------------------------------------
    o._browserShowing = CheckBox.new(o, function()
        local group = axutils.childFromRight(o:UI(), 4)
        if group and group:attributeValue("AXRole") == "AXGroup" then
            return axutils.childWithRole(group, "AXCheckBox")
        end
        return nil
    end)

    --- cp.apple.finalcutpro.main.PrimaryToolbar.browserShowing <cp.prop: boolean>
    --- Field
    --- If `true`, the browser panel is showing. Can be modified or watched.
    o.browserShowing = o._browserShowing.checked:wrap(o)

    --------------------------------------------------------------------------------
    -- Watch for AXValueChanged notifications in the app for this CheckBox:
    --------------------------------------------------------------------------------
    o:app():notifier():watchFor("AXValueChanged", function(element)
        if element:attributeValue("AXRole") == "AXImage" then
            local eParent = getParent(element)
            if eParent then
                --------------------------------------------------------------------------------
                -- Browser showing check:
                --------------------------------------------------------------------------------
                local bsParent = getParent(o._browserShowing:UI())
                if eParent == bsParent then
                    --------------------------------------------------------------------------------
                    -- Update the checked status for any watchers:
                    --------------------------------------------------------------------------------
                    -- log.df("value changed: parent: %s", _inspect(eParent))
                    o._browserShowing.checked:update()
                end
            end
        end
    end)

    return o
end

--- cp.apple.finalcutpro.main.PrimaryToolbar:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function PrimaryToolbar:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.PrimaryToolbar:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function PrimaryToolbar:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- TIMELINE UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryToolbar:UI() -> axuielementObject
--- Method
--- Gets the Primary Toolbar UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject`
function PrimaryToolbar:UI()
    return axutils.cache(self, "_ui", function()
        return axutils.childMatching(self:parent():UI(), PrimaryToolbar.matches)
    end,
    PrimaryToolbar.matches)
end

--- cp.apple.finalcutpro.main.PrimaryToolbar.isShowing <cp.prop: boolean>
--- Variable
--- Is the Primary Toolbar showing?
PrimaryToolbar.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(PrimaryToolbar)

-----------------------------------------------------------------------
--
-- THE BUTTONS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryToolbar:shareButton() -> Button
--- Method
--- Gets the Share Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Button` object.
function PrimaryToolbar:shareButton()
    if not self._shareButton then
        self._shareButton = Button.new(self, function() return axutils.childFromRight(self:UI(), 1) end)
    end
    return self._shareButton
end

--- cp.apple.finalcutpro.main.PrimaryToolbar:browserButton() -> CheckBox
--- Method
--- Gets the Browser Button Checkbox.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `CheckBox` object.
function PrimaryToolbar:browserButton()
    if not self._browserButton then
        self._browserButton = CheckBox.new(self, function()
            local group = axutils.childFromRight(self:UI(), 4)
            if group and group:attributeValue("AXRole") == "AXGroup" then
                return axutils.childWithRole(group, "AXCheckBox")
            end
            return nil
        end)
    end
    return self._browserButton
end

return PrimaryToolbar
