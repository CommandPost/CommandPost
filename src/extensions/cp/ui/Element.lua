--- === cp.ui.Element ===
---
--- A support class for `hs._asm.axuielement` management.
---
--- See:
--- * [Button](cp.ui.Button.md)
--- * [CheckBox](cp.rx.CheckBox.md)
--- * [MenuButton](cp.rx.MenuButton.md)
local require           = require
local log               = require("hs.logger").new("Element")

local axutils           = require("cp.ui.axutils")
local prop              = require("cp.prop")

local class             = require("middleclass")
local lazy              = require("cp.lazy")

local cache             = axutils.cache

local Element = class("Element"):include(lazy)

--- cp.ui.Element.matches(element) -> boolean
--- Function
--- Matches to any valid `hs._asm.axuielement`. Sub-types should provide their own `match` method.
---
--- Parameters:
--- * The element to check
---
--- Returns:
--- * `true` if the element is a valid instance of an `hs._asm.axuielement`.
function Element.static.matches(element)
    return element ~= nil and type(element.isValid) == "function" and element:isValid()
end

function Element:initialize(parent, uiFinder)
    self._parent = parent

    local UI
    if prop.is(uiFinder) then
        UI = uiFinder
    elseif type(uiFinder) == "function" then
        UI = prop(function()
            return cache(self, "_ui", function()
                local ui = uiFinder()
                return (self.class.matches == nil or self.class.matches(ui)) and ui or nil
            end,
            self.class.matches)
        end)
    end

    prop.bind(self) {
        UI = UI
    }

    if prop.is(parent.UI) then
        UI:monitor(parent.UI)
    end
end

--- cp.ui.Element.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- If `true`, the `Element` is showing on screen.
function Element.lazy.prop:isShowing()
    local parent = self:parent()
    local isShowing = self.UI:ISNOT(nil):AND(parent.isShowing)
    if prop.is(parent.isShowing) then
        isShowing:monitor(parent.isShowing)
    end
    return isShowing
end

--- cp.ui.Element.isEnabled <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the `Element` is visible and enabled.
function Element.lazy.prop:isEnabled()
    return axutils.prop(self.UI, "AXEnabled")
end

--- cp.ui.Element.frame <cp.prop: table; read-only; live?>
--- Field
--- Returns the table containing the `x`, `y`, `w`, and `h` values for the `Element` frame, or `nil` if not available.
function Element.lazy.prop:frame()
    return axutils.prop(self.UI, "AXFrame")
end

--- cp.ui.Element:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function Element:parent()
    return self._parent
end

--- cp.ui.Element:app() -> App
--- Method
--- Returns the app instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Element:app()
    return self:parent():app()
end

--- cp.ui.Element:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the button in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
---  * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
---  * The `hs.image` that was created.
function Element:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return Element