--- === cp.ui.PopUpButton ===
---
--- Pop Up Button Module.

local require = require

local axutils                       = require("cp.ui.axutils")
local Element                       = require("cp.ui.Element")
local go                            = require("cp.rx.go")

local If, WaitUntil                 = go.If, go.WaitUntil

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PopUpButton = Element:subclass("cp.ui.PopUpButton")

-- TIMEOUT_AFTER -> number
-- Constant
-- The common timeout amount in milliseconds.
local TIMEOUT_AFTER = 3000

--- cp.ui.PopUpButton.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function PopUpButton.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXPopUpButton"
end

--- cp.ui.PopUpButton(parent, uiFinder) -> cp.ui.PopUpButton
--- Constructor
--- Creates a new PopUpButton.
---
--- Parameters:
---  * parent       - The parent table. Should have a `isShowing` property.
---  * uiFinder      - The `function` or `cp.prop` that provides the current `hs._asm.axuielement`.
---
--- Returns:
---  * The new `PopUpButton` instance.

--- cp.ui.PopUpButton.value <cp.prop: anything; live>
--- Field
--- Returns or sets the current `PopUpButton` value.
function PopUpButton.lazy.prop:value()
    return self.UI:mutate(
        function(original)
            local ui = original()
            return ui and ui:value()
        end,
        function(newValue, original)
            local ui = original()
            if ui and ui:value() ~= newValue then
                local items = ui:doPress()[1]
                if items then
                    for _,item in ipairs(items) do
                        if item:title() == newValue then
                            item:doPress()
                            return
                        end
                    end
                    items:doCancel()
                end
            end
        end
    )
    -- if anyone starts watching, then register with the app notifier.
    :preWatch(function(_, theProp)
        self:app():notifier():watchFor("AXMenuItemSelected", function()
            theProp:update()
        end)
    end)
end

--- cp.ui.PopUpButton.menuUI <cp.prop: hs._asm.axuielement; read-only; live?>
--- Field
--- Returns the `AXMenu` for the PopUpMenu if it is currently visible.
function PopUpButton.lazy.prop:menuUI()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and axutils.childWithRole(ui, "AXMenu")
    end)
    -- if anyone opens the menu, update the prop watchers
    :preWatch(function(_, theProp)
        self:app():notifier():watchFor({"AXMenuOpened", "AXMenuClosed"}, function()
            theProp:update()
        end)
    end)
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

--- cp.ui.PopUpButton:doSelectItem(index) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will select an item on the `PopUpButton` by index.
---
--- Parameters:
---  * index - The index number of the item you want to select.
---
--- Returns:
---  * the `Statement`.
function PopUpButton:doSelectItem(index)
    return If(self.UI)
    :Then(If(self.menuUI):Is(nil):Then(self:doPress()))
    :Then(WaitUntil(self.menuUI):TimeoutAfter(TIMEOUT_AFTER))
    :Then(function(menuUI)
        local item = menuUI[index]
        if item then
            item:doPress()
            return true
        else
            item:doCancel()
            return false
        end
    end)
    :Then(WaitUntil(self.menuUI):Is(nil):TimeoutAfter(TIMEOUT_AFTER))
    :Otherwise(false)
    :Label("PopUpMenu:doSelectItem")
end

--- cp.ui.PopUpButton:doSelectValue(value) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will select an item on the `PopUpButton` by value.
---
--- Parameters:
---  * value - The value of the item to match.
---
--- Returns:
---  * the `Statement`.
function PopUpButton:doSelectValue(value)
    return If(self.UI)
    :Then(If(self.menuUI):Is(nil):Then(self:doPress()))
    :Then(WaitUntil(self.menuUI):TimeoutAfter(TIMEOUT_AFTER))
    :Then(function(menuUI)
        for _,item in ipairs(menuUI) do
            if item:title() == value then
                item:doPress()
                return true
            end
        end
        menuUI:doCancel()
        return false
    end)
    :Then(WaitUntil(self.menuUI):Is(nil):TimeoutAfter(TIMEOUT_AFTER))
    :Otherwise(false)
    :Label("PopUpButton:doSelectValue")
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

--- cp.ui.PopUpButton:doPress() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that presses the `PopUpButton`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function PopUpButton.lazy.method:doPress()
    return If(self.UI)
    :Then(function(ui)
        ui:doPress()
    end)
    :ThenYield()
    :Label("PopUpButton:doPress")
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

function PopUpButton:__tostring()
    return string.format("cp.ui.PopUpButton: %s", self:value())
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
---  * layout - A table containing the `PopUpButton` layout settings - created using [saveLayout](#saveLayout).
---
--- Returns:
---  * None
function PopUpButton:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

return PopUpButton
