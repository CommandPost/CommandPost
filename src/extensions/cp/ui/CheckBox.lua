--- === cp.ui.CheckBox ===
---
--- Check Box UI Module.
---
--- This represents an `hs._asm.axuielement` with a `AXCheckBox` role.
--- It allows checking and modifying the `checked` status like so:
---
--- ```lua
--- myButton:checked() == true			-- happens to be checked already
--- myButton:checked(false) == false	-- update to unchecked.
--- myButton.checked:toggle() == true	-- toggled back to being checked.
--- ```
---
--- You can also call instances of `CheckBox` as a function, which will return
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
local CheckBox = {}

--- cp.ui.CheckBox.matches(element) -> boolean
--- Function
--- Checks if the provided `hs._asm.axuielement` is a CheckBox.
---
--- Parameters:
---  * element		- The `axuielement` to check.
---
--- Returns:
---  * `true` if it's a match, or `false` if not.
function CheckBox.matches(element)
    return element ~= nil and element:attributeValue("AXRole") == "AXCheckBox"
end

--- cp.ui.CheckBox.new(parent, finderFn) -> cp.ui.CheckBox
--- Constructor
--- Creates a new CheckBox.
---
--- Parameters:
---  * parent		- The parent object.
---  * finderFn		- A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * The new `CheckBox`.
function CheckBox.new(parent, finderFn)
    local o = prop.extend({_parent = parent, _finder = finderFn}, CheckBox)

    --- cp.ui.CheckBox:UI() -> hs._asm.axuielement | nil
    --- Method
    --- Returns the `axuielement` representing the CheckBox, or `nil` if not available.
    ---
    --- Parameters:
    ---  * None
    ---
    --- Return:
    ---  * The `axuielement` or `nil`.
    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end,
        CheckBox.matches)
    end)

    --- cp.ui.CheckBox.isShowing <cp.prop: boolean; read-only>
    --- Field
    --- If `true`, it is visible on screen.
    local isShowing = UI:mutate(function(original, self)
        return original() ~= nil and self:parent():isShowing()
    end)

    --- cp.ui.CheckBox.checked <cp.prop: boolean>
    --- Field
    --- Indicates if the checkbox is currently checked.
    --- May be set by calling as a function with `true` or `false` to the function.
    local checked = UI:mutate(
        function(original) -- get
            local ui = original()
            return ui ~= nil and ui:value() == 1
        end,
        function(value, original) -- set
            local ui = original()
            if ui and value ~= (ui:value() == 1) then
                ui:doPress()
            end
        end
    )

    prop.bind(o) {
        UI = UI, isShowing = isShowing, checked = checked,
    }

    return o
end

--- cp.ui.CheckBox:parent() -> table
--- Method
--- The parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function CheckBox:parent()
    return self._parent
end

--- cp.ui.CheckBox:toggle() -> self
--- Method
--- Toggles the `checked` status of the button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `CheckBox` instance.
function CheckBox:toggle()
    self.checked:toggle()
    return self
end

--- cp.ui.CheckBox:isEnabled() -> boolean
--- Method
--- Returns `true` if the radio button exists and is enabled.
---
--- Parameters:
---  * None
---
--- Returns:
--- `true` or `false`.
function CheckBox:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
end

--- cp.ui.CheckBox:press() -> self
--- Method
--- Attempts to press the button. May fail if the `UI` is not available.
---
--- Parameters:
---  * None
---
--- Returns:
--- The `CheckBox` instance.
function CheckBox:press()
    local ui = self:UI()
    if ui then
        ui:doPress()
    end
    return self
end

--- cp.ui.CheckBox:saveLayout() -> table
--- Method
--- Returns a table containing the layout settings for the checkbox.
--- This table may be passed to the `loadLayout` method to restore the saved layout.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A settings table.
function CheckBox:saveLayout()
    return {
        checked = self:checked()
    }
end

--- cp.ui.CheckBox:loadLayout(layout) -> nil
--- Method
--- Applies the settings in the provided layout table.
---
--- Parameters:
---  * layout		- The table containing layout settings. Usually created by the `saveLayout` method.
---
--- Returns:
---  * nil
function CheckBox:loadLayout(layout)
    if layout then
        self:checked(layout.checked)
    end
end

-- cp.ui.Button:__call() -> boolean
-- Method
-- Allows the CheckBox to be called as a function and will return the `checked` value.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The value of the CheckBox.
function CheckBox:__call(parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:checked(value)
end

--- cp.ui.CheckBox:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
---  * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
---  * The `hs.image` that was created, or `nil` if the UI is not available.
function CheckBox:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return CheckBox