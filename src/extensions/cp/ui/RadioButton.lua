--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local RadioButton = {}

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
    return element and element:attributeValue("AXRole") == "AXRadioButton"
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
    return prop.extend({_parent = parent, _finder = finderFn}, RadioButton)
end

--- cp.ui.RadioButton:parent() -> table
--- Method
--- The parent object.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The parent object.
function RadioButton:parent()
    return self._parent
end

--- cp.ui.RadioButton:app() -> table
--- Method
--- Returns the application object, via the `parent()`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The application object.
function RadioButton:app()
    return self:parent():app()
end

--- cp.ui.RadioButton.isShowing <cp.prop: boolean; read-only>
--- Field
--- If `true`, it is visible on screen.
RadioButton.isShowing = prop(function(self)
    return self:UI() ~= nil and self:parent():isShowing()
end):bind(RadioButton)

--- cp.ui.RadioButton:UI() -> hs._asm.axuielement | nil
--- Method
--- Returns the `axuielement` representing the RadioButton, or `nil` if not available.
---
--- Parameters:
--- * None
---
--- Return:
--- * The `axuielement` or `nil`.
function RadioButton:UI()
    return axutils.cache(self, "_ui", function()
        return self._finder()
    end,
    RadioButton.matches)
end

--- cp.ui.RadioButton.checked <cp.prop: boolean>
--- Field
--- Indicates if the checkbox is currently checked.
--- May be set by calling as a function with `true` or `false` to the function.
RadioButton.checked = prop(
    function(self) -- get
        local ui = self:UI()
        return ui and ui:value() == 1
    end,
    function(value, self) -- set
        local ui = self:UI()
        if ui and value ~= (ui:value() == 1) then
            ui:doPress()
        end
    end
):bind(RadioButton)

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

--- cp.ui.RadioButton:isEnabled() -> boolean
--- Method
--- Returns `true` if the radio button exists and is enabled.
---
--- Parameters:
--- * None
---
--- Returns:
--- `true` or `false`.
function RadioButton:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
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

--- cp.ui.RadioButton:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function RadioButton:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return RadioButton