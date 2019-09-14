--- === cp.ui.TextArea ===
---
--- UI Text Area.

local require = require

local Element = require("cp.ui.Element")



--- cp.ui.TextArea(parent, uiFinder) -> TextArea
--- Constructor
--- Creates a new `TextArea` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * A new `TextArea` object.
local TextArea = Element:subclass("cp.ui.TextArea")

--- cp.ui.TextArea.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function TextArea.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXTextArea"
end

--- cp.ui.TextArea.value <cp.prop: string>
--- Field
--- The current value of the text field.
function TextArea.lazy.prop:value()
    return self.UI:mutate(
        function(original)
            local ui = original()
            local value = ui and ui:attributeValue("AXValue") or nil
            return value
        end,
        function(value, original)
            local ui = original()
            if ui then
                value = tostring(value)
                ui:setAttributeValue("AXValue", value)
                ui:performAction("AXConfirm")
            end
        end
    )
end

return TextArea