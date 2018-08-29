--- === cp.ui.Element ===
---
--- A support class for `hs._asm.axuielement` management.
---
--- See:
--- * [Button](cp.ui.Button.md)
--- * [CheckBox](cp.rx.CheckBox.md)
--- * [MenuButton](cp.rx.MenuButton.md)

local require           = require

local axutils           = require("cp.ui.axutils")
local prop              = require("cp.prop")

local cache             = axutils.cache

local Element = {}

--- cp.ui.Element:subtype()
--- Method
--- Returns a subtype table of `Element`, suitible for extension.
---
--- Returns:
--- * The new subtype table.
function Element:subtype()
    return setmetatable({}, {__index = self})
end

--- cp.ui.Element.matches(element) -> boolean
--- Function
--- Matches to any valid `hs._asm.axuielement`. Sub-types should provide their own `match` method.
---
--- Parameters:
--- * The element to check
---
--- Returns:
--- * `true` if the element is a valid instance of an `hs._asm.axuielement`.
function Element.matches(element)
    return element ~= nil and type(element.isValid) == "function" and element:isValid()
end

function Element.new(parent, uiFinder, subtype)
    subtype = subtype or Element
    local o = prop.extend({
        _parent = parent,
    }, subtype)

    local UI
    if prop.is(uiFinder) then
        UI = uiFinder
    else
        UI = prop(function()
            return cache(o, "_ui", function()
                local ui = uiFinder()
                return (subtype.matches == nil or subtype.matches(ui)) and ui or nil
            end,
            subtype.matches)
        end)
    end

    prop.bind(o) {
        UI = UI,

--- cp.ui.Element.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- If `true`, the `Element` is showing on screen.
        isShowing = UI:ISNOT(nil):AND(parent.isShowing),

--- cp.ui.Element.isEnabled <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the `Element` is visible and enabled.
        isEnabled = axutils.prop(UI, "AXEnabled"),

--- cp.ui.Element.frame <cp.prop: table; read-only; live?>
--- Field
--- Returns the table containing the `x`, `y`, `w`, and `h` values for the `Element` frame, or `nil` if not available.
        frame = axutils.prop(UI, "AXFrame"),
    }

    if prop.is(parent.UI) then
        o.UI:monitor(parent.UI)
    end

    if prop.is(parent.isShowing) then
        o.isShowing:monitor(parent.isShowing)
    end

    return o
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