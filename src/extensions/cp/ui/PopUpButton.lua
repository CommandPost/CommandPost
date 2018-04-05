--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.PopUpButton ===
---
--- Pop Up Button Module.

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
local PopUpButton = {}

-- TODO: Add documentation
function PopUpButton.matches(element)
    return element:attributeValue("AXRole") == "AXPopUpButton"
end

--- cp.ui.PopUpButton.new(axuielement, function) -> cp.ui.PopUpButton
--- Constructor
--- Creates a new PopUpButton.
---
--- Parameters:
--- * parent		- The parent table. Should have a `isShowing` property.
---
--- Returns:
--- * The new `PopUpButton` instance.
function PopUpButton.new(parent, finderFn)
    local o = prop.extend({_parent = parent, _finder = finderFn}, PopUpButton)

    -- TODO: Add documentation
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
        UI = UI,
        isShowing = isShowing,
        value = value,
    }
end

-- TODO: Add documentation
function PopUpButton:parent()
    return self._parent
end

-- TODO: Add documentation
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

-- TODO: Add documentation
function PopUpButton:getValue()
    return self:value()
end

-- TODO: Add documentation
function PopUpButton:setValue(value)
    self.value:set(value)
    return self
end

-- TODO: Add documentation
function PopUpButton:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
end

-- TODO: Add documentation
function PopUpButton:press()
    local ui = self:UI()
    if ui then
        ui:doPress()
    end
    return self
end

function PopUpButton:__call(parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

-- TODO: Add documentation
function PopUpButton:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

-- TODO: Add documentation
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
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function PopUpButton:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return PopUpButton
