--- === cp.ui.PopUpButton ===
---
--- Pop Up Button Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

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
local PopUpButton = {}

--- cp.ui.PopUpButton.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function PopUpButton.matches(element)
    return element and element:attributeValue("AXRole") == "AXPopUpButton"
end

--- cp.ui.PopUpButton.new(axuielement, function) -> cp.ui.PopUpButton
--- Constructor
--- Creates a new PopUpButton.
---
--- Parameters:
---  * parent		- The parent table. Should have a `isShowing` property.
---
--- Returns:
---  * The new `PopUpButton` instance.
function PopUpButton.new(parent, finderFn)
    local o = prop.extend({_parent = parent, _finder = finderFn}, PopUpButton)

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end,
        PopUpButton.matches)
    end)

    if prop.is(parent.UI) then
        UI:monitor(parent.UI)
    end

    local isShowing = UI:mutate(function(original, self)
        return original() ~= nil and self:parent():isShowing()
    end)

    local value = UI:mutate(
        function(original)
            local ui = original()
            return ui and ui:value()
        end,
        function(newValue, original)
            local ui = original()
            if ui and ui:value() ~= newValue then
                local items = ui:doPress()[1]
                for _,item in ipairs(items) do
                    if item:title() == newValue then
                        item:doPress()
                        return
                    end
                end
                items:doCancel()
            end
        end
    )

    return prop.bind(o) {
        --- cp.ui.PopUpButton.UI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- Provides the `axuielement` for the `PopUpButton`.
        UI = UI,

        --- cp.ui.PopUpButton.isShowing <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- Checks if the `PopUpButton` is visible on screen.
        isShowing = isShowing,

        --- cp.ui.PopUpButton.value <cp.prop: anything>
        --- Field
        --- Returns or sets the current `PopUpButton` value.
        value = value,
    }
end

--- cp.ui.PopUpButton:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function PopUpButton:parent()
    return self._parent
end

--- cp.ui.PopUpButton:selectItem(index) -> self
--- Method
--- Select an item on the `PopUpButton` by index.
---
--- Parameters:
---  * index - The index of the item you want to select.
---
--- Returns:
---  * self
function PopUpButton:selectItem(index)
    local ui = self:UI()
    if ui then
        local items = ui:doPress()[1]
        if items then
            local item = items[index]
            if item then
                -- select the menu item
                item:doPress()
            else
                -- close the menu again
                items:doCancel()
            end
        end
    end
    return self
end

--- cp.ui.PopUpButton:getValue() -> string | nil
--- Method
--- Gets the `PopUpButton` value.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PopUpButton` value as string, or `nil` if the value cannot be determined.
function PopUpButton:getValue()
    return self:value()
end

--- cp.ui.PopUpButton:setValue(value) -> self
--- Method
--- Sets the `PopUpButton` value.
---
--- Parameters:
---  * value - The value you want to set the `PopUpButton` to.
---
--- Returns:
---  * self
function PopUpButton:setValue(value)
    self.value:set(value)
    return self
end

--- cp.ui.PopUpButton:isEnabled() -> boolean
--- Method
--- Is the `PopUpButton` enabled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if enabled otherwise `false`.
function PopUpButton:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
end

--- cp.ui.PopUpButton:press() -> self
--- Method
--- Presses the `PopUpButton`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function PopUpButton:press()
    local ui = self:UI()
    if ui then
        ui:doPress()
    end
    return self
end

-- cp.ui.PopUpButton:__call() -> boolean
-- Method
-- Allows the `PopUpButton` to be called as a function and will return the button value.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The value of the `PopUpButton`.
function PopUpButton:__call(parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

--- cp.ui.PopUpButton:saveLayout() -> table
--- Method
--- Saves the current `PopUpButton` layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current `PopUpButton` Layout.
function PopUpButton:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

--- cp.ui.PopUpButton:loadLayout(layout) -> none
--- Method
--- Loads a `PopUpButton` layout.
---
--- Parameters:
---  * layout - A table containing the `PopUpButton` layout settings - created using `cp.ui.PopUpButton:saveLayout()`.
---
--- Returns:
---  * None
function PopUpButton:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

--- cp.ui.PopUpButton:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
---  * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
---  * The `hs.image` that was created, or `nil` if the UI is not available.
function PopUpButton:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return PopUpButton
