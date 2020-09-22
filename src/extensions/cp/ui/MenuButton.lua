--- === cp.ui.MenuButton ===
---
--- Menu Button Module.

local require           = require

--local log               = require("hs.logger").new("MenuButton")

local axutils           = require "cp.ui.axutils"
local Element           = require "cp.ui.Element"
local Menu              = require "cp.ui.Menu"
local go                = require "cp.rx.go"
local just              = require "cp.just"

local find              = string.find
local If                = go.If
local WaitUntil         = go.WaitUntil

local MenuButton = Element:subclass("cp.ui.MenuButton")

-- TIMEOUT_AFTER -> number
-- Constant
-- The common timeout amount in milliseconds.
local TIMEOUT_AFTER = 3000

--- cp.ui.MenuButton.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function MenuButton.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXMenuButton"
end

--- cp.ui.MenuButton(parent, uiFinder) -> MenuButton
--- Constructor
--- Creates a new MenuButton.
---
--- Parameters:
--- * parent        - The parent object. Should have an `isShowing` property.
--- * uiFinder      - A `cp.prop` or function which will return a `hs._asm.axuielement`, or `nil` if it's not available.

--- cp.ui.MenuButton.value <cp.prop: anything>
--- Field
--- Returns or sets the current MenuButton value.
function MenuButton.lazy.prop:value()
    return self.UI:mutate(
        function(original)
            local ui = original()
            return ui and ui:attributeValue("AXTitle")
        end,
        function(newValue, original)
            local ui = original()
            if ui and ui:attributeValue("AXTitle") ~= newValue then
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
    :preWatch(function(_,thisProp)
        self:app():notifier():watchFor("AXMenuItemSelected", function()
            thisProp:update()
        end)
    end)
end

--- cp.ui.MenuButton.menuUI <cp.prop: hs._asm.axuielement; read-only; live?>
--- Field
--- Returns the `AXMenu` for the MenuButton if it is currently visible.
function MenuButton.lazy.prop:menuUI()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and axutils.childWithRole(ui, "AXMenu")
    end)
    -- if anyone opens the menu, update the prop watchers
    :preWatch(function(_, thisProp)
        self:app():notifier():watchFor({"AXMenuOpened", "AXMenuClosed"}, function()
            thisProp:update()
        end)
    end)
end

function MenuButton.lazy.value:menu()
    return Menu(self, self.menuUI)
end

--- cp.ui.MenuButton.title <cp.prop: string; read-only>
--- Field
--- Returns the title for the MenuButton.
function MenuButton.lazy.prop:title()
    return axutils.prop(self.UI, "AXTitle")
end

--- cp.ui.MenuButton:show() -> self
--- Method
--- Show's the MenuButton.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function MenuButton:show()
    local parent = self:parent()
    if parent.show then
        self:parent():show()
    end
    return self
end

--- cp.ui.MenuButton:selectItem(index) -> boolean
--- Method
--- Select an item on the `MenuButton` by index.
---
--- Parameters:
---  * index - The index of the item you want to select.
---
--- Returns:
---  * `true` if successfully selected, otherwise `false`.
function MenuButton:selectItem(index)
    local ui = self:UI()
    if ui then
        ui:doPress()
        local items = just.doUntil(function() return ui[1] end, 3)
        if items then
            local item = items[index]
            if item then
                -- select the menu item
                item:doPress()
                return true
            else
                -- close the menu again
                items:doCancel()
            end
        end
        self.value:update()
    end
    return false
end

--- cp.ui.MenuButton:doSelectItem(index) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will select an item on the `MenuButton` by index.
---
--- Parameters:
---  * index - The index number of the item to match.
---
--- Returns:
---  * the `Statement`.
function MenuButton:doSelectItem(index)
    return If(self:doShowMenu())
    :Then(self.menu:doSelectItem(index))
    :Otherwise(false)
    :Label("MenuButton:doSelectItem")
end

--- cp.ui.MenuButton:doSelectValue(value) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will select an item on the `MenuButton` by value.
---
--- Parameters:
---  * value - The value of the item to match.
---
--- Returns:
---  * the `Statement`.
function MenuButton:doSelectValue(value)
    return If(self:doShowMenu())
    :Then(self.menu:doSelectValue(value))
    :Otherwise(false)
    :Label("MenuButton:doSelectValue")
end

--- cp.ui.MenuButton:selectItemMatching(pattern) -> boolean
--- Method
--- Select an item on the `MenuButton` by pattern.
---
--- Parameters:
---  * pattern - A pattern used to select the `MenuButton` item.
---
--- Returns:
---  * `true` if successfully selected, otherwise `false`.
function MenuButton:selectItemMatching(pattern)
    local ui = self:UI()
    if ui then
        local title = ui:attributeValue("AXTitle")
        if string.match(title, pattern) then
            -- Don't bother selecting if it's already selected.
            return true
        end
        ui:doPress()
        local items = just.doUntil(function() return ui[1] end, 5, 0.01)
        if items then
            local found = false
            for _,item in ipairs(items) do
                local itemTitle = item:attributeValue("AXTitle")
                if itemTitle then
                    local s,e = find(itemTitle, pattern)
                    if s == 1 and e == itemTitle:len() then
                        -- perfect match
                        item:doPress()
                        found = true
                        break
                    end
                end
            end
            if not found then
                -- if we got this far, we couldn't find it.
                items:performAction("AXCancel")
            end
            -- wait until the menu closes.
            just.doWhile(function() return ui[1] end, 5, 0.01)
            return found
        end
        self.value:update()
    end
    return false
end

--- cp.ui.MenuButton:doSelectItemMatching(pattern[, altPattern]) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will select an item on the `MenuButton` by pattern.
---
--- Parameters:
---  * pattern - The pattern to match.
---  * [altPattern] - An optional alternate pattern to match if the first pattern fails.
---
--- Returns:
---  * the `Statement`.
function MenuButton:doSelectItemMatching(pattern, altPattern)
    return If(self:doShowMenu())
    :Then(self.menu:doSelectItemMatching(pattern, altPattern))
    :Otherwise(false)
    :Label("MenuButton:doSelectItemMatching")
end

--- cp.ui.MenuButton:getTitle() -> string | nil
--- Method
--- Gets the `MenuButton` title.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `MenuButton` title as string, or `nil` if the title cannot be determined.
function MenuButton:getTitle()
    return self:title()
end

--- cp.ui.MenuButton:getValue() -> string | nil
--- Method
--- Gets the `MenuButton` value.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `MenuButton` value as string, or `nil` if the value cannot be determined.
function MenuButton:getValue()
    return self:value()
end

--- cp.ui.MenuButton:setValue(value) -> self
--- Method
--- Sets the `MenuButton` value.
---
--- Parameters:
---  * value - The value you want to set the `MenuButton` to.
---
--- Returns:
---  * self
function MenuButton:setValue(value)
    self.value:set(value)
    return self
end

--- cp.ui.MenuButton:press() -> self
--- Method
--- Presses the MenuButton.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function MenuButton:press()
    local ui = self:UI()
    if ui then
        ui:doPress()
    end
    return self
end

--- cp.ui.MenuButton:doPress() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that presses the `MenuButton`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function MenuButton.lazy.method:doPress()
    return If(self.UI)
    :Then(function(ui)
        ui:doPress()
        return true
    end)
    :ThenYield()
    :Otherwise(false)
    :Label("MenuButton:doPress")
end

--- cp.ui.MenuButton:doShowMenu() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that presses the `MenuButton` if the menu is not showing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function MenuButton.lazy.method:doShowMenu()
    return If(self.menu.isShowing):Is(false)
    :Then(If(self:doPress()):Then(WaitUntil(self.menu.isShowing):TimeoutAfter(TIMEOUT_AFTER)))
    :Otherwise(true)
    :Label("MenuButton:doShowMenu")
end

--- cp.ui.MenuButton:saveLayout() -> table
--- Method
--- Saves the current `MenuButton` layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current `MenuButton` Layout.
function MenuButton:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

--- cp.ui.MenuButton:loadLayout(layout) -> none
--- Method
--- Loads a `MenuButton` layout.
---
--- Parameters:
---  * layout - A table containing the `MenuButton` layout settings - created using [saveLayout](#saveLayout).
---
--- Returns:
---  * None
function MenuButton:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

-- cp.ui.MenuButton:__call() -> boolean
-- Method
-- Allows the `MenuButton` to be called as a function and will return the `checked` value.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The value of the CheckBox.
function MenuButton:__call(parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

function MenuButton:__tostring()
    return string.format("cp.ui.MenuButton: %s (%s)", self:title(), self:parent())
end

return MenuButton
