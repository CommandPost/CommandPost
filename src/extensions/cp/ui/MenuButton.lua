--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.MenuButton ===
---
--- Pop Up Button Module.

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
local just							= require("cp.just")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MenuButton = {}

local find = string.find

-- TODO: Add documentation
function MenuButton.matches(element)
    return element and element:attributeValue("AXRole") == "AXMenuButton"
end

--- cp.ui.MenuButton.new(parent, finderFn) -> MenuButton
--- Constructor
--- Creates a new MenuButton.
---
--- Parameters:
--- * parent		- The parent object. Should have an `isShowing` property.
--- * finderFn		- A function which will return a `hs._asm.axuielement`, or `nil` if it's not available.
function MenuButton.new(parent, finderFn)
    local o = prop.extend({_parent = parent, _finder = finderFn}, MenuButton)

    --- cp.ui.MenuButton.UI <cp.prop: hs._asm.axuielement; read-only>
    --- Field
    --- Provides the `axuielement` for the MenuButton.
    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end,
        MenuButton.matches)
    end)

    if prop.is(parent.UI) then
        UI:monitor(parent.UI)
    end

    prop.bind(o) {
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

        title = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXTitle")
        end),
    }

    return o
end

-- TODO: Add documentation
function MenuButton:parent()
    return self._parent
end

function MenuButton:show()
    local parent = self:parent()
    if parent.show then
        self:parent():show()
    end
    return self
end

-- TODO: Add documentation
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

function MenuButton:selectItemMatching(pattern)
    local ui = self:UI()
    if ui then
        ui:doPress()
        local items = just.doUntil(function() return ui[1] end, 5, 0.01)
        if items then
            for _,item in ipairs(items) do
                local title = item:attributeValue("AXTitle")
                if title then
                    local s,e = find(title, pattern)
                    if s == 1 and e == title:len() then
                        -- perfect match
                        item:doPress()
                        return true
                    end
                end
            end
            -- if we got this far, we couldn't find it.
            items:performAction("AXCancel")
        end
        self.value:update()
    end
    return false
end

function MenuButton:getTitle()
    local ui = self:UI()
    return ui and ui:attributeValue("AXTitle")
end

-- TODO: Add documentation
function MenuButton:getValue()
    return self:value()
end

-- TODO: Add documentation
function MenuButton:setValue(value)
    self.value:set(value)
    return self
end

-- TODO: Add documentation
function MenuButton:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
end

-- TODO: Add documentation
function MenuButton:press()
    local ui = self:UI()
    if ui then
        ui:doPress()
    end
    return self
end

-- TODO: Add documentation
function MenuButton:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

-- TODO: Add documentation
function MenuButton:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

-- TODO: Add documentation
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
