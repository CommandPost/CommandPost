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
local Element                       = require("cp.ui.Element")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local RadioButton = Element:subclass("RadioButton")

--- cp.ui.RadioButton.matches(element) -> boolean
--- Function
--- Checks if the provided `hs._asm.axuielement` is a RadioButton.
---
--- Parameters:
--- * element		- The `axuielement` to check.
---
--- Returns:
--- * `true` if it's a match, or `false` if not.
function RadioButton.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXRadioButton"
end

--- cp.ui.RadioButton(axuielement, function) -> RadioButton
--- Method
--- Creates a new RadioButton.
---
--- Parameters:
--- * parent		- The parent object.
--- * finderFn		- A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
--- * The new `RadioButton`.
function RadioButton:initialize(parent, finderFn)
    Element.initialize(self, parent, finderFn)
end

--- cp.ui.RadioButton.checked <cp.prop: boolean>
--- Field
--- Indicates if the checkbox is currently checked.
--- May be set by calling as a function with `true` or `false` to the function.
function RadioButton.lazy.prop:checked()
    return self.UI:mutate(
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
    )
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

function RadioButton.__tostring()
    return "cp.ui.RadioButton"
end

return RadioButton
