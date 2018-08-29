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
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local Element						= require("cp.ui.Element")
local prop							= require("cp.prop")

local If                            = require("cp.rx.go.If")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local CheckBox = Element:subtype()

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
    return Element.matches(element) and element:attributeValue("AXRole") == "AXCheckBox"
end

--- cp.ui.CheckBox.new(parent, uiFinder) -> cp.ui.CheckBox
--- Constructor
--- Creates a new CheckBox.
---
--- Parameters:
---  * parent		- The parent object.
---  * uiFinder		- A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * The new `CheckBox`.
function CheckBox.new(parent, uiFinder)
    local o = Element.new(parent, uiFinder, CheckBox)

--- cp.ui.CheckBox.title <cp.prop: string; read-only>
--- Field
--- The button title, if available.
    local title   = axutils.prop(o.UI, "AXTitle")

--- cp.ui.CheckBox.checked <cp.prop: boolean>
--- Field
--- Indicates if the checkbox is currently checked.
--- May be set by calling as a function with `true` or `false` to the function.
    local checked = o.UI:mutate(
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
        checked = checked, title = title,
    }

    return o
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

--- cp.ui.CheckBox:doPress() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will press the button when executed, if available at the time.
--- If not an `error` is sent.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` which will press the button when executed.
function CheckBox:doPress()
    return If(self.UI):Then(function(ui)
        ui:doPress()
        return true
    end)
    :Otherwise(false)
    :ThenYield()
    :Label("CheckBox:doPress")
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

return CheckBox
