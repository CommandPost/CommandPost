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

local require = require
local Element                       = require("cp.ui.Element")
local go                            = require("cp.rx.go")

local If, Do                        = go.If, go.Do

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local RadioButton = Element:subclass("cp.ui.RadioButton")

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

--- cp.ui.RadioButton:doToggle() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will toggle the button value when executed, if available at the time.
--- If not an `error` is sent.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` which will toggle the button when executed.
function RadioButton.lazy.method:doToggle()
    return If(self.UI):Then(function()
        self.checked:toggle()
        return true
    end)
    :Otherwise(false)
    :ThenYield()
    :Label("RadioButton:doToggle")
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

--- cp.ui.RadioButton:doPress() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will press the button when executed, if available at the time.
--- If not an `error` is sent.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` which will press the button when executed.
function RadioButton.lazy.method:doPress()
    return If(self.UI):Then(function(ui)
        ui:doPress()
        return true
    end)
    :Otherwise(false)
    :ThenYield()
    :Label("RadioButton:doPress")
end

--- cp.ui.RadioButton:saveLayout() -> table
--- Method
--- Returns a `table` with the button's current state. This can be passed to [#loadLayout]
--- later to restore the original state.
---
--- Returns:
--- * The table of the layout state.
function RadioButton:saveLayout()
    local layout = Element.saveLayout(self)
    layout.checked = self:checked()
    return layout
end

--- cp.ui.RadioButton:loadLayout(layout) -> nil
--- Method
--- Processes the `layout` table to restore this to match the provided `layout`.
---
--- Parameters:
--- * layout - the table of state values to restore to.
function RadioButton:loadLayout(layout)
    Element.loadLayout(self, layout)
    if layout then
        self:checked(layout.checked)
    end
end

--- cp.ui.RadioButton:doLayout(layout) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will apply the layout provided, if possible.
---
--- Parameters:
--- * layout - the `table` containing the layout configuration. Usually created via the [#saveLayout] method.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md).
function RadioButton:doLayout(layout)
    layout = layout or {}
    return Do(Element.doLayout(self, layout))
    :Then(
        If(self.checked):IsNot(layout.checked)
        :Then(self:doPress())
        :Otherwise(true)
    )
    :Label("RadioButton:doLayout")
end

-- Allows the RadioButton to be called as a function and will return the `checked` value.
function RadioButton.__call(self, parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:checked(value)
end

return RadioButton
