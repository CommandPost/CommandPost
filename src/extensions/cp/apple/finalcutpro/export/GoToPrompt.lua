--- === cp.apple.finalcutpro.export.GoToPrompt ===
---
--- Go To Prompt.

local require               = require

local eventtap              = require "hs.eventtap"

local axutils               = require "cp.ui.axutils"
local just                  = require "cp.just"
local prop                  = require "cp.prop"

local Button				= require "cp.ui.Button"

local childFromLeft			= axutils.childFromLeft

local GoToPrompt = {}

--- cp.apple.finalcutpro.export.GoToPrompt.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function GoToPrompt.matches(element)
    if element then
        return element:attributeValue("AXRole") == "AXSheet"            -- it's a sheet
           and (axutils.childWithRole(element, "AXTextField") ~= nil    -- with a text field
            or axutils.childWithRole(element, "AXComboBox") ~= nil)
    end
    return false
end

--- cp.apple.finalcutpro.export.GoToPrompt.new(app) -> GoToPrompt
--- Function
--- Creates a new Go To Prompt object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new GoToPrompt object.
function GoToPrompt.new(parent)
    local o = {_parent = parent}
    return prop.extend(o, GoToPrompt)
end

--- cp.apple.finalcutpro.export.GoToPrompt:parent() -> object
--- Method
--- Returns the Parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function GoToPrompt:parent()
    return self._parent
end

--- cp.apple.finalcutpro.export.GoToPrompt:app() -> App
--- Method
--- Returns the App instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function GoToPrompt:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.export.GoToPrompt:UI() -> axuielementObject
--- Method
--- Returns the Go To Prompt Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function GoToPrompt:UI()
    return axutils.cache(self, "_ui", function()
        return axutils.childMatching(self:parent():UI(), GoToPrompt.matches)
    end,
    GoToPrompt.matches)
end

--- cp.apple.finalcutpro.export.GoToPrompt.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the 'Go To' prompt showing?
GoToPrompt.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(GoToPrompt)

--- cp.apple.finalcutpro.export.GoToPrompt:show() -> cp.apple.finalcutpro.export.GoToPrompt
--- Method
--- Shows the Go To Prompt
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.GoToPrompt` object for method chaining.
function GoToPrompt:show()
    if self:parent():isShowing() then
        eventtap.keyStroke({"cmd", "shift"}, "g")
        just.doUntil(function() return self:isShowing() end)
    end
    return self
end

--- cp.apple.finalcutpro.export.GoToPrompt:hide() -> cp.apple.finalcutpro.export.GoToPrompt
--- Method
--- Hides the Go To Prompt
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.GoToPrompt` object for method chaining.
function GoToPrompt:hide()
    self:pressCancel()
end

--- cp.apple.finalcutpro.export.GoToPrompt:pressCancel() -> cp.apple.finalcutpro.export.GoToPrompt
--- Method
--- Presses the Cancel Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.GoToPrompt` object for method chaining.
function GoToPrompt:pressCancel()
    local ui = self:UI()
    if ui then
        local btn = childFromLeft(ui, 1, Button.matches)
        if btn then
            btn:doPress()
            just.doWhile(function() return self:isShowing() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.GoToPrompt:setValue(value) -> cp.apple.finalcutpro.export.GoToPrompt
--- Method
--- Sets the value of the text box within the Go To Prompt.
---
--- Parameters:
---  * value - The value of the text box as a string.
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.GoToPrompt` object for method chaining.
function GoToPrompt:setValue(value)
    local textField = axutils.childWithRole(self:UI(), "AXTextField")
    if textField then
        textField:setAttributeValue("AXValue", value)
    else
        local comboBox = axutils.childWithRole(self:UI(), "AXComboBox")
        if comboBox then
            comboBox:setAttributeValue("AXValue", value)
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.GoToPrompt:pressDefault() -> cp.apple.finalcutpro.export.GoToPrompt
--- Method
--- Presses the Default Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.GoToPrompt` object for method chaining.
function GoToPrompt:pressDefault()
    local ui = self:UI()
    if ui then
        local btn = childFromLeft(ui, 2, Button.matches)
        if btn and btn:enabled() then
            btn:doPress()
            just.doWhile(function() return self:isShowing() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:getTitle() -> string | nil
--- Method
--- The title of the Go To Prompt window or `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The title of the Go To Prompt window as a string or `nil`.
function GoToPrompt:getTitle()
    local ui = self:UI()
    return ui and ui:title()
end

return GoToPrompt
