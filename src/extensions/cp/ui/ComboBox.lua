--- === cp.ui.ComboBox ===
---
--- Combo Box Module.

local require = require

local axutils                   = require "cp.ui.axutils"
local Element                   = require "cp.ui.Element"
local Button                    = require "cp.ui.TextField"
local List                      = require "cp.ui.List"
local ScrollArea                = require "cp.ui.ScrollArea"
local TextField                 = require "cp.ui.TextField"

local childMatching             = axutils.childMatching

local ComboBox = TextField:subclass("cp.ui.ComboBox")

--- cp.ui.ComboBox.matches(element[, subrole]) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---  * subrole - (optional) If provided, the field must have the specified subrole.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ComboBox.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXComboBox"
end

function ComboBox.lazy.value:showMenu()
    return Button(self, self.UI:mutate(function(original)
        return childMatching(original(), Button.matches)
    end))
end

function ComboBox.lazy.method:doShowMenu()
    return self.showMenu:doPress()
end

function ComboBox.lazy.value:menuArea()
    return ScrollArea(self, self.UI:mutate(function(original)
        return childMatching(original(), ScrollArea.matches)
    end))
end

function ComboBox.lazy.value:menuList()
    return List(self.menuArea,
        self.menuArea.UI:mutate(function(original)
            return childMatching(original(), List.matches)
        end),
        self._listAdaptorFn
    )
end

--- cp.ui.ComboBox(parent, uiFinder, listAdaptorFn, [, getConvertFn[, setConvertFn]]) -> ComboBox
--- Method
--- Creates a new ComboBox. They have a parent and a finder function.
--- Additionally, an optional `convert` function can be provided, with the following signature:
---
--- `function(textValue) -> anything`
---
--- The `value` will be passed to the function before being returned, if present. All values
--- passed into `value(x)` will be converted to a `string` first via `tostring`.
---
--- For example, to have the value be converted into a `number`, simply use `tonumber` like this:
---
--- ```lua
--- local numberField = ComboBox(parent, function() return ... end, tonumber, tostring)
--- ```
---
--- Parameters:
---  * parent   - The parent object.
---  * uiFinder - The function will return the `axuielement` for the ComboBox.
---  * listAdaptorFn    - A function that will recieve a `List` and `AXUIElement` value and return an `Element`
---  * getConvertFn    - (optional) If provided, will be passed the `string` value when returning.
---  * setConvertFn    - (optional) If provided, will be passed the `number` value when setting.
---
--- Returns:
---  * The new `ComboBox`.
function ComboBox:initialize(parent, uiFinder, listAdaptorFn, getConvertFn, setConvertFn)
    self._listAdaptorFn = listAdaptorFn
    TextField.initialize(self, parent, uiFinder, getConvertFn, setConvertFn)
end

function ComboBox.__call(self, parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

return ComboBox
