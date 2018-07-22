--- === cp.ui.Toolbar ===
---
--- Toolbar Module.

local require = require
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

local Button                        = require("cp.ui.Button")

local Do                            = require("cp.rx.go").Do

local Toolbar = {}

--- cp.ui.Toolbar.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Button`, returning `true` if so.
---
--- Parameters:
---  * element		- The `hs._asm.axuielement` to check.
---
--- Returns:
---  * `true` if the `element` is a `Button`, or `false` if not.
function Toolbar.matches(element)
    return element and element:attributeValue("AXRole") == "AXToolbar"
end

--- cp.ui.Toolbar.new(parent, finder) -> cp.ui.Toolbar
--- Constructor
--- Creates a new `Toolbar` instance, given the specified `parent` and `finder`
---
--- Parameters:
---  * parent   - The parent object.
---  * finder   - The `cp.prop` or `function` that finds the `hs._asm.axuielement` that represents the `Toolbar`.
---
--- Returns:
---  * The new `Toolbar` instance.
function Toolbar.new(parent, finderFn)
    local o = prop.extend(
        {
            _parent = parent,
        }, Toolbar
    )

    local UI
    if prop.is(finderFn) then
        UI = finderFn
    else
        UI = prop(function()
            return axutils.cache(o, "_ui", function()
                local ui = finderFn()
                return Toolbar.matches(ui) and ui or nil
            end,
            Toolbar.matches)
        end)
    end

    prop.bind(o) {
--- cp.ui.Toolbar.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Retrieves the `axuielement` for the `Toolbar`, or `nil` if not available..
        UI = UI,

--- cp.ui.Toolbar.isShowing <cp.prop: boolean; read-only>
--- Field
--- If `true`, the `Toolbar` is showing on screen.
        isShowing = UI:mutate(function(original, self)
            return original() ~= nil and self:parent():isShowing()
        end),

--- cp.ui.Toolbar.selectedTitle <cp.prop: string; read-only>
--- Field
--- The title of the first selected item, if available.
        selectedTitle   = UI:mutate(function(original)
            local ui = original()
            local selected = ui and ui:attributeValue("AXSelectedChildren")
            if selected and #selected > 0 then
                return selected[1]:attributeValue("AXTitle")
            end
        end),

--- cp.ui.Toolbar.frame <cp.prop: table; read-only>
--- Field
--- Returns the table containing the `x`, `y`, `w`, and `h` values for the Toolbar frame, or `nil` if not available.
        frame = UI:mutate(function(original)
            local ui = original()
            return ui and ui:frame() or nil
        end),
    }

--- cp.ui.Toolbar.overflowButton <cp.ui.Button>
--- Field
--- The "overflow" button which appears if there are more toolbar items
--- available than can be fit on screen.
    o.overflowButton = Button.new(o, UI:mutate(function(original)
        local ui = original()
        return ui and ui:attributeValue("AXOverflowButton")
    end))

    if prop.is(parent.UI) then
        o.UI:monitor(parent.UI)
    end

    if prop.is(parent.isShowing) then
        o.isShowing:monitor(parent.isShowing)
    end

    return o
end


--- cp.ui.Toolbar:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function Toolbar:parent()
    return self._parent
end

--- cp.ui.Toolbar:app() -> App
--- Method
--- Returns the app instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Toolbar:app()
    return self:parent():app()
end

--- cp.ui.Toolbar:isEnabled() -> boolean
--- Method
--- Returns `true` if the Toolbar is visible and enabled.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the Toolbar is visible and enabled.
function Toolbar:isEnabled()
    local ui = self:UI()
    return ui ~= nil and ui:enabled()
end

--- cp.ui.Toolbar:doSelect(title) -> Statement
--- Method
--- Returns a `Statement` that will select the toolbar item with the specified title.
---
--- Parameters:
--- * title - The title to select, if present.
---
--- Returns:
--- * A `Statement` that when executed returns `true` if the item was found and selected, otherwise `false`.
function Toolbar:doSelect(title)
    return Do(self:doShow())
    :Then(function()
        local ui = self:UI()
        local selectedTitle = self:selectedTitle()
        if selectedTitle ~= title then
            local button = ui and axutils.childWith(ui, "AXTitle", title)
            if button then
                button:doPress()
                return true
            end
        end
        return false
    end)
end

function Toolbar:doShow()
    return self:parent():doShow()
end

function Toolbar:doHide()
    return self:parent():doHide()
end

return Toolbar
