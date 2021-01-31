--- === cp.ui.Menu ===
---
--- UI for AXMenus.

local require               = require

local Element               = require "cp.ui.Element"
local go                    = require "cp.rx.go"

local find                  = string.find
local If                    = go.If
local WaitUntil             = go.WaitUntil

-- TIMEOUT_AFTER -> number
-- Constant
-- The common timeout amount in milliseconds.
local TIMEOUT_AFTER = 3000

--- cp.ui.Menu(parent, uiFinder) -> Menu
--- Constructor
--- Creates a new `Menu` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs.axuielement` when available.
---
--- Returns:
---  * A new `Menu` object.
local Menu = Element:subclass("cp.ui.Menu")

--- cp.ui.Menu.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Menu.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXMenu"
end

--- cp.ui.Menu:cancel() -> self
--- Method
--- Closes a menu.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function Menu:cancel()
    local ui = self:UI()
    if ui then
        ui:performAction("AXCancel")
    end
    return self
end

--- cp.ui.Menu:doCancel(value) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will cancel a menu.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the `Statement`.
function Menu:doCancel()
    return If(self.UI)
    :Then(function(ui)
        ui:performAction("AXCancel")
    end)
    :Then(WaitUntil(self.isShowing):Is(false):TimeoutAfter(TIMEOUT_AFTER))
    :Otherwise(false)
    :Label("Menu:doCancel")
end

--- cp.ui.Menu:doSelectItem(index) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will select an item on the `MenuButton` by index.
---
--- Parameters:
---  * index - The index number of the item to match.
---
--- Returns:
---  * the `Statement`.
function Menu:doSelectItem(index)
    return If(self.UI)
    :Then(function(ui)
        local item = ui[index]
        if item then
            item:doAXPress()
            return WaitUntil(self.isShowing):Is(false):TimeoutAfter(TIMEOUT_AFTER)
        else
            return self:doCancel()
        end
    end)
    :Then()
    :Otherwise(false)
    :Label("Menu:doSelectItem")
end

--- cp.ui.Menu:doSelectValue(value) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will select an item on the `Menu` by value.
---
--- Parameters:
---  * value - The value of the item to match.
---
--- Returns:
---  * the `Statement`.
function Menu:doSelectValue(value)
    return If(self.UI)
    :Then(function(ui)
        for _, item in ipairs(ui) do
            local title = item:attributeValue("AXTitle")
            if title == value then
                item:doAXPress()
                return WaitUntil(self.isShowing):Is(false):TimeoutAfter(TIMEOUT_AFTER)
            end
        end
        return self:doCancel():Then(false)
    end)
    :Otherwise(false)
    :Label("Menu:doSelectValue")
end

--- cp.ui.Menu:doSelectValue(pattern[, altPattern]) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will select an item on the `Menu` by value.
---
--- Parameters:
---  * pattern - The pattern to match.
---  * [altPattern] - An optional alternate pattern to match if the first pattern fails.
---
--- Returns:
---  * the `Statement`.
function Menu:doSelectItemMatching(pattern, altPattern)
    return If(self.UI)
    :Then(function(ui)
        local patterns = {pattern}
        if altPattern then table.insert(patterns, altPattern) end
        for _, selectedPattern in pairs(patterns) do
            for _,item in ipairs(ui) do
                local title = item:attributeValue("AXTitle")
                if title then
                    local s,e = find(title, selectedPattern)
                    if s == 1 and e == title:len() then
                        -- perfect match
                        item:doAXPress()
                        return WaitUntil(self.isShowing):Is(false):TimeoutAfter(TIMEOUT_AFTER)
                    end
                end
            end
        end
        return self:doCancel():Then(false)
    end)
    :Otherwise(false)
    :Label("Menu:doSelectItemMatching")
end

return Menu