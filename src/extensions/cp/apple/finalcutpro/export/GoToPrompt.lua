--- === cp.apple.finalcutpro.export.GoToPrompt ===
---
--- Go To Prompt.

local require               = require

local prop                  = require "cp.prop"

local axutils               = require "cp.ui.axutils"
local just                  = require "cp.just"
local tools                 = require "cp.tools"

local Button				= require "cp.ui.Button"
local ComboBox              = require "cp.ui.ComboBox"
local Sheet                 = require "cp.ui.Sheet"
local TextField             = require "cp.ui.TextField"

local cache                 = axutils.cache
local childFromLeft			= axutils.childFromLeft
local childMatching         = axutils.childMatching
local keyStroke             = tools.keyStroke
local doUntil               = just.doUntil

local GoToPrompt = Sheet:subclass("cp.apple.finalcutpro.export:GoToPrompt")

--- cp.apple.finalcutpro.export.GoToPrompt.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function GoToPrompt.static.matches(element)
    if Sheet.matches(element) then
        return (childMatching(element, TextField.matches) ~= nil    -- with a text field
            or childMatching(element, ComboBox.matches) ~= nil) -- or a combo box.
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
function GoToPrompt:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), GoToPrompt.matches)
        end,
        GoToPrompt.matches)
    end)

    Sheet.initialize(self, parent, UI)
end

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
        --------------------------------------------------------------------------------
        -- NOTE: I tried sending the keyStroke directly to FCPX, but it didn't work.
        --------------------------------------------------------------------------------
        keyStroke({"cmd", "shift"}, "g")
        doUntil(function() return self:isShowing() end)
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
    self:cancel()
end

--- cp.apple.finalcutpro.export.GoToPrompt.cancel <cp.ui.Button>
--- Field
--- The "Cancel" `Button`.
function GoToPrompt.lazy.value:cancel()
    return Button(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 1, Button.matches)
    end))
end

--- cp.apple.finalcutpro.export.GoToPrompt.go <cp.ui.Button>
--- Field
--- The "Go" `Button`.
function GoToPrompt.lazy.value:go()
    return Button(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 2, Button.matches)
    end))
end

-- Override the base `default` since it doesn't seem to be publishing "AXDefaultButton"
function GoToPrompt.lazy.value:default()
    return self.go
end

--- cp.apple.finalcutpro.export.GoToPrompt.valueText <cp.ui.TextField>
--- Field
--- The `TextField` containing the folder value, if available.
function GoToPrompt.lazy.value:valueText()
    return TextField(self, self.UI:mutate(function(original)
        return childMatching(original(), TextField.matches)
    end))
end

--- cp.apple.finalcutpro.export.GoToPrompt.valueCombo <cp.ui.ComboBox>
--- Field
--- The `ComboBox` containing the folder value, if available.
function GoToPrompt.lazy.value:valueCombo()
    return ComboBox(self,
        self.UI:mutate(function(original)
            return childMatching(original(), ComboBox.matches)
        end),
        function(list, itemUI)
            return TextField(list, prop.THIS(itemUI))
        end
    )
end

--- cp.apple.finalcutpro.export.GoToPrompt:valueField() -> TextField | ComboField
--- Method
--- Returns either the `valueText` or `valueCombo`, depending what is available on-screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `TextField` or `ComboField` containing the value.
function GoToPrompt:valueField()
    if self.valueText:isShowing() then
        return self.valueText
    else
        return self.valueCombo
    end
end

--- cp.apple.finalcutpro.export.GoToPrompt:value([newValue]) -> string
--- Method
--- Returns the current path value, or `nil`.
---
--- Parameters:
---  * newValue - (optional) The new value for the path.
---
--- Returns:
---  * The current value of the path.
function GoToPrompt:value(newValue)
    return self:valueField():value(newValue)
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
    self:value(value)
    return self
end

return GoToPrompt
