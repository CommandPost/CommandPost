--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.export.ReplaceAlert ===
---
--- Replace Alert

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ReplaceAlert = {}

--- cp.apple.finalcutpro.export.ReplaceAlert.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ReplaceAlert.matches(element)
    if element then
        return element:attributeValue("AXRole") == "AXSheet"			-- it's a sheet
           and axutils.childWithRole(element, "AXTextField") == nil 	-- with no text fields
    end
    return false
end

--- cp.apple.finalcutpro.export.ReplaceAlert.new(app) -> ReplaceAlert
--- Constructor
--- Creates a new Replace Alert object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new ReplaceAlert object.
function ReplaceAlert.new(parent)
    local o = {_parent = parent}
    return prop.extend(o, ReplaceAlert)
end

--- cp.apple.finalcutpro.export.ReplaceAlert:parent() -> object
--- Method
--- Returns the Parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function ReplaceAlert:parent()
    return self._parent
end

--- cp.apple.finalcutpro.export.ReplaceAlert:app() -> App
--- Method
--- Returns the App instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function ReplaceAlert:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.export.ReplaceAlert:UI() -> axuielementObject
--- Method
--- Returns the Replace Alert Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function ReplaceAlert:UI()
    return axutils.cache(self, "_ui", function()
        return axutils.childMatching(self:parent():UI(), ReplaceAlert.matches)
    end,
    ReplaceAlert.matches)
end

--- cp.apple.finalcutpro.export.ReplaceAlert.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the Replace File alert showing?
ReplaceAlert.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(ReplaceAlert)

--- cp.apple.finalcutpro.export.ReplaceAlert:hide() -> none
--- Method
--- Hides the Replace Alert.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function ReplaceAlert:hide()
    self:pressCancel()
end

--- cp.apple.finalcutpro.export.ReplaceAlert:pressCancel() -> cp.apple.finalcutpro.export.ReplaceAlert
--- Method
--- Presses the Cancel button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ReplaceAlert` object for method chaining.
function ReplaceAlert:pressCancel()
    local ui = self:UI()
    if ui then
        local btn = ui:cancelButton()
        if btn then
            btn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ReplaceAlert:pressReplace() -> cp.apple.finalcutpro.export.ReplaceAlert
--- Method
--- Presses the Replace button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ReplaceAlert` object for method chaining.
function ReplaceAlert:pressReplace()
    local ui = self:UI()
    if ui then
        local btn = ui:defaultButton()
        if btn and btn:enabled() then
            btn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ReplaceAlert:getTitle() -> string | nil
--- Method
--- The title of the Replace Alert window or `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The title of the Replace Alert window as a string or `nil`.
function ReplaceAlert:getTitle()
    local ui = self:UI()
    return ui and ui:title()
end

return ReplaceAlert
