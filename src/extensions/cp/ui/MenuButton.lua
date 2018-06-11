--- === cp.ui.MenuButton ===
---
--- Pop Up Button Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                       = require("hs.logger").new("MenuButton")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
-- local inspect                   = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local just							= require("cp.just")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local find                          = string.find

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MenuButton = {}

--- cp.ui.MenuButton.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function MenuButton.matches(element)
    return element and element:attributeValue("AXRole") == "AXMenuButton"
end

--- cp.ui.MenuButton.new(parent, finderFn) -> MenuButton
--- Constructor
--- Creates a new MenuButton.
---
--- Parameters:
--- * parent		- The parent object. Should have an `isShowing` property.
--- * finderFn		- A `cp.prop` or function which will return a `hs._asm.axuielement`, or `nil` if it's not available.
function MenuButton.new(parent, finderFn)
    local o = prop.extend({_parent = parent, _finder = finderFn}, MenuButton)

    --- cp.ui.MenuButton.UI <cp.prop: hs._asm.axuielement; read-only>
    --- Field
    --- Provides the `axuielement` for the MenuButton.
    local UI
    if prop.is(finderFn) then
        UI = finderFn
    else
        UI = prop(function(self)
            return axutils.cache(self, "_ui", function()
                return self._finder()
            end,
            MenuButton.matches)
        end)

        if prop.is(parent.UI) then
            UI:monitor(parent.UI)
        end
    end

    prop.bind(o) {
        --- cp.ui.MenuButton:UI() -> hs._asm.axuielement | nil
        --- Method
        --- Returns the `axuielement` representing the MenuButton, or `nil` if not available.
        ---
        --- Parameters:
        ---  * None
        ---
        --- Return:
        ---  * The `axuielement` or `nil`.
        UI = UI,

        --- cp.ui.MenuButton.isShowing <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- Checks if the MenuButton is visible on screen.
        isShowing = UI:ISNOT(nil),

        --- cp.ui.MenuButton.value <cp.prop: anything>
        --- Field
        --- Returns or sets the current MenuButton value.
        value = UI:mutate(
            function(original)
                local ui = original()
                return ui and ui:attributeValue("AXTitle")
            end,
            function(value, original)
                local ui = original()
                if ui and not ui:attributeValue("AXTitle") == value then
                    local items = ui:doPress()[1]
                    for _,item in items do
                        if item:title() == value then
                            item:doPress()
                            return
                        end
                    end
                    items:doCancel()
                end
            end
        ),

        --- cp.ui.MenuButton.title <cp.prop: string; read-only>
        --- Field
        --- Returns the MenuButton's title.
        title = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXTitle")
        end),
    }

    return o
end

--- cp.ui.MenuButton:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function MenuButton:parent()
    return self._parent
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
        ui:doPress()
        local items = just.doUntil(function() return ui[1] end, 5, 0.01)
        if items then
            local found = false
            for _,item in ipairs(items) do
                local title = item:attributeValue("AXTitle")
                if title then
                    local s,e = find(title, pattern)
                    if s == 1 and e == title:len() then
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
    local ui = self:UI()
    return ui and ui:attributeValue("AXTitle")
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

--- cp.ui.MenuButton:isEnabled() -> boolean
--- Method
--- Is the `MenuButton` enabled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if enabled otherwise `false`.
function MenuButton:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
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
---  * layout - A table containing the `MenuButton` layout settings - created using `cp.ui.MenuButton:saveLayout()`.
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

--- cp.ui.MenuButton:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function MenuButton:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return MenuButton