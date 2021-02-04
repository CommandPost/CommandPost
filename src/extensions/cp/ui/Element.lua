--- === cp.ui.Element ===
---
--- A support class for `hs.axuielement` management.
---
--- See:
--- * [Button](cp.ui.Button.md)
--- * [CheckBox](cp.rx.CheckBox.md)
--- * [MenuButton](cp.rx.MenuButton.md)
local require           = require

-- local log               = require "hs.logger".new("Element")

local axutils           = require "cp.ui.axutils"
local go	            = require "cp.rx.go"
local If                = require "cp.rx.go.If"
local lazy              = require "cp.lazy"
local prop              = require "cp.prop"

local class             = require "middleclass"

local cache             = axutils.cache
local Do, Given         = go.Do, go.Given

local Element = class("cp.ui.Element"):include(lazy)

--- cp.ui.Element.matches(element) -> boolean
--- Function
--- Matches to any valid `hs.axuielement`. Sub-types should provide their own `matches` method.
---
--- Parameters:
--- * The element to check
---
--- Returns:
--- * `true` if the element is a valid instance of an `hs.axuielement`.
function Element.static.matches(element)
    return element ~= nil and type(element.isValid) == "function" and element:isValid()
end

-- Defaults to describing the class by it's class name
function Element:__tostring()
    return self.class.name
end

--- cp.ui.Element(parent, uiFinder) -> cp.ui.Element
--- Constructor
--- Creates a new `Element` with the specified `parent` and `uiFinder`.
--- The `uiFinder` may be either a `function` that returns an `axuielement`, or a [cp.prop](cp.prop.md).
---
--- Parameters:
--- * parent - The parent Element (may be `nil`)
--- * uiFinder - The `function` or `prop` that actually provides the current `axuielement` instance.
---
--- Returns:
--- * The new `Element` instance.
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
    else
        error "Expected either a cp.prop or function for uiFinder."
    end

    prop.bind(self) {
        UI = UI
    }

    if prop.is(parent.UI) then
        UI:monitor(parent.UI)
    end
end

--- cp.ui.Element.value <cp.prop: anything; live?>
--- Field
--- The 'AXValue' of the element.
function Element.lazy.prop:value()
    return axutils.prop(self.UI, "AXValue", true)
end

--- cp.ui.Element.textValue <cp.prop: string; read-only; live?>
--- Field
--- The 'AXValue' of the element, if it is a `string`.
function Element.lazy.prop:textValue()
    return self.value:mutate(function(original)
        local value = original()
        return type(value) == "string" and value or nil
    end)
end

--- cp.ui.Element.valueIs(value) -> boolean
--- Method
--- Checks if the current value of this element is the provided value.
---
--- Parameters:
--- * value - The value to compare to.
---
--- Returns:
--- * `true` if the current [#value] is equal to the provided `value`.
function Element:valueIs(value)
    return self:value() == value
end

--- cp.ui.Element.title <cp.prop: string; read-only, live?>
--- Field
--- The 'AXTitle' of the element.
function Element.lazy.prop:title()
    return axutils.prop(self.UI, "AXTitle")
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

--- cp.ui.Element:doShow() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will ensure the Element is showing.
function Element.lazy.method:doShow()
    return If(function() return self:parent() end)
    :Then(function(parent) return parent.doShow and parent:doShow() end)
    :Otherwise(false)
end

--- cp.ui.Element:show() -> self
--- Method
--- Shows the Element.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function Element:show()
    self:parent():show()
    return self
end

--- cp.ui.Element:focus() -> self
--- Method
--- Set the focus on an element.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function Element:focus()
    local ui = self.UI()
    if ui then
        ui:setAttributeValue("AXFocused", true)
    end
    return self
end

--- cp.ui.Element.role <cp.prop: string; read-only>
--- Field
--- Returns the `AX` role name for the element.
function Element.lazy.prop:role()
    return axutils.prop(self.UI, "AXRole")
end

--- cp.ui.Element.subrole <cp.prop: string; read-only>
--- Field
--- Returns the `AX` subrole name for the element.
function Element.lazy.prop:subrole()
    return axutils.prop(self.UI, "AXSubrole")
end

--- cp.ui.Element.identifier <cp.prop: string; read-only>
--- Field
--- Returns the `AX` identifier for the element.
function Element.lazy.prop:identifier()
    return axutils.prop(self.UI, "AXIdentifier")
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

--- cp.ui.Element.position <cp.prop: table; read-only; live?>
--- Field
--- Returns the table containing the `x` and `y` values for the `Element` frame, or `nil` if not available.
-- TODO: ensure no other 'position' props are getting created elsewhere...
-- function Element.lazy.prop:position()
--     return axutils.prop(self.UI, "AXPosition")
-- end

--- cp.ui.Element.size <cp.prop: table; read-only; live?>
--- Field
--- Returns the table containing the `w` and `h` values for the `Element` frame, or `nil` if not available.
-- TODO: ensure no other 'size' props are getting created elswehere...
-- function Element.lazy.prop:size()
--     return axutils.prop(self.UI, "AXSize")
-- end

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
    local parent = self:parent()
    return parent and parent:app()
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


--- cp.ui.Element:saveLayout() -> table
--- Method
--- Returns a `table` containing the current configuration details for this Element (or subclass).
---
--- Notes:
--- * When subclassing, the overriding `saveLayout` method should call the parent's saveLayout method,
--- then add values to it, like so:
---    ```
---    function MyElement:saveLayout()
---        local layout = Element.saveLayout(self)
---        layout.myConfig = self.myConfig
---        return layout
---    end
---    ```
function Element.saveLayout()
    return {}
end

--- cp.ui.Element:loadLayout(layout) -> nil
--- Method
--- When called, the Element (or subclass) will attempt to load the layout based on the parameters
--- provided by the `layout` table. This table should generally be generated via the [#saveLayout] method.
---
--- Parameters:
--- * layout - a `table` of parameters that will be used to layout the element.
---
--- Notes:
--- * When subclassing, the overriding `loadLayout` method should call the parent's `loadLayout` method,
--- then process any custom values from it, like so:
---    ```
---    function MyElement:loadLayout(layout)
---        Element.loadLayout(self, layout)
---        self.myConfig = layout.myConfig
---    end
---    ```
function Element.loadLayout(_)
end

function Element:doSaveLayout()
    return Do(function() return self:saveLayout() end)
    :Label("Element:doSaveLayout")
end

--- cp.ui.Element:doLayout(layout) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) which will attempt to load the layout based on the parameters
--- provided by the `layout` table. This table should generally be generated via the [#saveLayout] method.
---
--- Parameters:
--- * layout - a `table` of parameters that will be used to layout the element.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md) to execute.
---
--- Notes:
--- * By default, to enable backwards-compatibility, this method will simply call the [#loadLayout]. Override it to provide more optimal asynchonous behaviour if required.
--- * When subclassing, the overriding `doLayout` method should call the parent class's `doLayout` method,
--- then process any custom values from it, like so:
---    ```lua
---    function MyElement:doLayout(layout)
---        layout = layout or {}
---        return Do(Element.doLayout(self, layout))
---        :Then(function()
---            self.myConfig = layout.myConfig
---        end)
---        :Label("MyElement:doLayout")
---    end
---    ```
function Element:doLayout(layout)
    return Given(layout)
    :Then(function(_layout)
        self:loadLayout(_layout)
        return true
    end)
    :Label("Element:doLayout")
end

function Element:doStoreLayout(id)
    return Given(self:doSaveLayout())
    :Then(function(layout)
        local layouts = self.__storedLayouts or {}
        layouts[id] = layout
        self.__storedLayouts = layouts
        return layout
    end)
    :Label("Element:doStoreLayout")
end

function Element:doForgetLayout(id)
    return Do(function()
        local layouts = self.__storedLayouts
        if layouts then
            layouts[id] = nil
        end
        for _ in pairs(layouts) do -- luacheck: ignore
            return -- there are still layouts stored.
        end
        self.__storedLayouts = nil
    end)
    :Label("Element:doForgetLayout")
end

function Element:doRecallLayout(id, preserve)
    local doForget = preserve and nil or self:doForgetLayout(id)

    return Given(function()
        local layouts = self.__storedLayouts
        return layouts and layouts[id]
    end)
    :Then(function(layout)
        local doLayout = self:doLayout(layout)
        if doForget then
            doLayout = Do(doLayout):Then(doForget)
        end
        return doLayout
    end)
    :Label("Element:doRecallLayout")
end

-- This just returns the same element when it is called as a method. (eg. `fcp.viewer == fcp.viewer`)
-- This is a bridge while we migrate to using `lazy.value` instead of `lazy.method` (or methods)
-- in the FCPX API.
function Element:__call()
    return self
end

return Element
