--- === cp.ui.RadioButton ===
---
--- Radio Button Module.
---
--- This represents an `hs._asm.axuielement` with a `AXRadioButton` role.
--- It allows checking and modifying the `checked` status like so:
---
--- ```lua
--- myButton:checked() == true			-- happens to be checked already
--- myButton:checked(false) == false	-- update to unchecked.
--- myButton.checked:toggle() == true	-- toggled back to being checked.
--- ```
---
--- You can also call instances of `RadioButton` as a function, which will return
--- the `checked` status:
---
--- ```lua
--- myButton() == true			-- still true
--- myButton(false) == false	-- now false
--- ```

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require
local axutils						= require("cp.ui.axutils")
local Element                       = require("cp.ui.Element")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local RadioButton = Element:subtype()

--- cp.ui.RadioButton.matches(element) -> boolean
--- Function
--- Checks if the provided `hs._asm.axuielement` is a RadioButton.
---
--- Parameters:
--- * element		- The `axuielement` to check.
---
--- Returns:
--- * `true` if it's a match, or `false` if not.
function RadioButton.matches(element)
    local o = Element.matches(element) and element:attributeValue("AXRole") == "AXRadioButton"

    prop.bind(o) {
--- cp.ui.RadioButton.checked <cp.prop: boolean>
--- Field
--- Indicates if the checkbox is currently checked.
--- May be set by calling as a function with `true` or `false` to the function.
        checked = o.UI:mutate(
            function(original) -- get
                local ui = original()
                return ui and ui:attributeValue("AXValue") == 1
            end,
            function(value, original) -- set
                local ui = original()
                if ui and value ~= (ui:attributeValue("AXValue") == 1) then
                    ui:doPress()
                end
            end
        ),
    }
    return o
end

--- cp.ui.RadioButton.new(axuielement, function) -> RadioButton
--- Method
--- Creates a new RadioButton.
---
--- Parameters:
--- * parent		- The parent object.
--- * finderFn		- A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
--- * The new `RadioButton`.
function RadioButton.new(parent, finderFn)
    return Element.new(parent, finderFn, RadioButton)
end

--- cp.ui.RadioButton:toggle() -> self
--- Method
--- Toggles the `checked` status of the button.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `RadioButton` instance.
function RadioButton:toggle()
    self.checked:toggle()
    return self
end

--- cp.ui.RadioButton:press() -> self
--- Method
--- Attempts to press the button. May fail if the `UI` is not available.
---
--- Parameters:
--- * None
---
--- Returns:
--- The `RadioButton` instance.
function RadioButton:press()
    local ui = self:UI()
    if ui then
        ui:doPress()
    end
    return self
end

-- TODO: Add documentation
function RadioButton:saveLayout()
    return {
        checked = self:checked()
    }
end

-- TODO: Add documentation
function RadioButton:loadLayout(layout)
    if layout then
        self:checked(layout.checked)
    end
end

-- Allows the RadioButton to be called as a function and will return the `checked` value.
function RadioButton.__call(self, parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:checked(value)
end

return RadioButton
