--- === cp.ui.Element ===
---
--- A support class for `hs.axuielement` management.
---
--- See:
---  * [Button](cp.ui.Button.md)
---  * [CheckBox](cp.rx.CheckBox.md)
---  * [MenuButton](cp.rx.MenuButton.md)

local require           = require

--local log               = require "hs.logger".new("Element")

local drawing           = require "hs.drawing"

local axutils           = require "cp.ui.axutils"
local Builder           = require "cp.ui.Builder"
local go	            = require "cp.rx.go"
local is                = require "cp.is"
local lazy              = require "cp.lazy"
local prop              = require "cp.prop"

local class             = require "middleclass"

local cache             = axutils.cache
local Do, Given, If     = go.Do, go.Given, go.If
local isFunction        = is.fn
local isCallable        = is.callable
local pack, unpack      = table.pack, table.unpack

local Element = class("cp.ui.Element"):include(lazy)

--- cp.ui.Element:defineBuilder(...) -> cp.ui.Element
--- Method
--- Defines a new [Builder](cp.ui.Builder.md) class on this `Element` with the specified additional argument names.
---
--- Parameters:
---  * ... - The names for the methods which will collect extra arguments to pass to the `Element` constructor.
---
--- Returns:
---  * The same `Element` class instance.
---
--- Notes:
---  * The order of the argument names here is the order in which they will be passed to the `Element` constructor, no matter what
---    order they are called on the `Builder` itself.
---  * Once defined, the class can be accessed via the static `<Element Name>.Builder` of the `Element` subclass.
---  * For example, if you have a `cp.ui.Element` subclass named `MyElement`, with an extra `alpha` and `beta` constructor argument, you can do this:
---    ```lua
---    -- The class definition
---    local MyElement = Element:subclass("cp.ui.MyElement"):defineBuilder("withAlpha", "withBeta")
---    -- The constructor
---    function MyElement.Builder:initialize(parent, uiFinder, alpha, beta)
---        Element.initialize(self, parent, uiFinder)
---        self.alpha = alpha
---        self.beta = beta
---    end
---    -- Create a callable `MyClass.Builder` instance
---    local myElementBuilder = MyElement:withAlpha(1):withBeta(2)
---    -- alternately, same result:
---    local myElementBuilder = MyElement:withBeta(2):withAlpha(1)
---    -- Alternately, same result:
---    local myElementBuilder = MyElement.Builder():withAlpha(1):withBeta(2)
---    -- Create an instance of `MyClass`:
---    local myElement = myElementBuilder(parent, uiFinder)
---    ```
function Element.static:defineBuilder(...)
    local args = pack(...)
    local thisType = self
    local builderClass = Builder:subclass(self.name .. ".Builder")
    self.Builder = builderClass

    function builderClass.initialize(builderType, elementType)
        elementType = elementType or thisType
        Builder.initialize(builderType, elementType, unpack(args))
    end

    for _, arg in ipairs(args) do
        self[arg] = function(elementType, ...)
            local instance = builderClass(elementType)
            return instance[arg](instance, ...)
        end
    end
    return self
end

--- cp.ui.Element:isTypeOf(thing) -> boolean
--- Function
--- Checks if the `thing` is an `Element`. If called on subclasses, it will check
--- if the `thing` is an instance of the subclass.
---
--- Parameters:
---  * `thing`		- The thing to check
---
--- Returns:
---  * `true` if the thing is a `Element` instance.
---
--- Notes:
---  * This is a type method, not an instance method or a type function. It is called with `:` on the type itself,
---    not an instance. For example `Element:isTypeOf(value)`
function Element.static:isTypeOf(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(self)
end

--- cp.ui.Element.matches(element) -> boolean
--- Function
--- Matches to any valid `hs.axuielement`. Sub-types should provide their own `matches` method.
---
--- Parameters:
---  * The element to check
---
--- Returns:
---  * `true` if the element is a valid instance of an `hs.axuielement`.
function Element.static.matches(element)
    return element ~= nil and isFunction(element.isValid) and element:isValid()
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
---  * parent - The parent Element (may be `nil`)
---  * uiFinder - The `function` or `prop` that actually provides the current `axuielement` instance.
---
--- Returns:
---  * The new `Element` instance.
function Element:initialize(parent, uiFinder)
    self._parent = parent

    local UI
    if prop.is(uiFinder) then
        UI = uiFinder
    elseif isCallable(uiFinder) then
        UI = prop(function()
            return cache(self, "_ui", function()
                local ui = uiFinder()
                return (self.class.matches == nil or self.class.matches(ui)) and ui or nil
            end,
            self.class.matches)
        end)
    else
        error "Expected either a cp.prop, function, or callable table for uiFinder."
    end

    self.UI = UI
    UI:bind(self, "UI")

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
---  * value - The value to compare to.
---
--- Returns:
---  * `true` if the current [#value] is equal to the provided `value`.
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
--- By default, will ask the `parent` to show, if the `parent` is available.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A Statement
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
    local parent = self:parent()
    if parent then
        parent:show()
    end
    return self
end

--- cp.ui.Element:focus() -> self, boolean
--- Method
--- Attempt to set the focus on the element.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self, boolean - the boolean indicates if the focus was set.
function Element:focus()
    return self:setAttributeValue("AXFocused", true)
end

--- cp.ui.Element:doFocus() -> cp.rx.go.Statement
--- Method
--- A `Statement` that attempts to set the focus on the element.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`.
function Element.lazy.method:doFocus()
    return self:doSetAttributeValue("AXFocused", true)
    :Label("cp.ui.Element:doFocus()")
end

--- cp.ui.Element:attributeValue(id) -> anything, true | nil, false
--- Method
--- Attempts to retrieve the specified `AX` attribute value, if the `UI` is available.
---
--- Parameters:
---  * id - The `AX` attribute to retrieve.
---
--- Returns:
---  * The current value for the attribute, or `nil` if the `UI` is not available, followed by `true` if the `UI` is present and was called.
function Element:attributeValue(id)
    local ui = self:UI()
    if ui then
        return ui:attributeValue(id), true
    end
    return nil, false
end

--- cp.ui.Element:setAttributeValue(id, value) -> self, boolean
--- Method
--- If the `UI` is available, set the named `AX` attribute to the `value`.
---
--- Parameters:
---  * id - The `AX` id to set.
---  * value - The new value.
---
--- Returns:
---  * The `Element` instance, then `true` if the UI is available and the value was set, otherwise false.
function Element:setAttributeValue(id, value)
    local ui = self:UI()
    if ui then
        ui:setAttributeValue(id, value)
        return self, true
    end
    return self, false
end

--- cp.ui.Element:performAction(id) -> boolean
--- Method
--- Attempts to perform the specified `AX` action, if the `UI` is available.
---
--- Parameters:
---  * id - The `AX` action to perform.
---
--- Returns:
---  * `true` if the `UI` is available and the action was performed, otherwise `false`.
function Element:performAction(id)
    local ui = self:UI()
    if ui then
        ui:performAction(id)
        return self, true
    end
    return self, false
end

--- cp.ui.Element:doSetAttributeValue(id, value) -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` which will attempt to update the specified `AX` attribute to the new `value`.
---
--- Parameters:
---  * id   - The `string` for the AX action to perform.
---  * value - The new value to set.
---
--- Returns:
---  * The `Statement` which will perform the action and resolve to `true` if the UI is available and set, otherwise `false`.
function Element:doSetAttributeValue(id, value)
    return If(self.UI)
    :Then(function(ui)
        ui:setAttributeValue(id, value)
        return true
    end)
    :Otherwise(false)
    :Label("cp.ui.Element:doSetAttributeValue('" .. id .. "', value)")
end

--- cp.ui.Element:doPerformAction(id) -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` which will attempt to perform the action with the specified id (eg. "AXCancel")
---
--- Parameters:
---  * id   - The `string` for the AX action to perform.
---
--- Returns:
---  * The `Statement` which will perform the action.
function Element:doPerformAction(id)
    return If(self.UI)
    :Then(function(ui)
        ui:performAction(id)
        return true
    end)
    :Otherwise(false)
    :Label("cp.ui.Element:doPerformAction('" .. id .. "')")
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

--- cp.ui.Element.isFocused <cp.prop: boolean; read-only?; live?>
--- Field
--- Returns `true` if the `AXFocused` attribute is `true`. Not always a reliable way to determine focus however.
function Element.lazy.prop:isFocused()
    return axutils.prop(self.UI, "AXFocused", true)
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

local RED_COLOR = { red = 1, green = 0, blue = 0, alpha = 0.75 }

--- cp.ui.Element:doHighlight([color], [duration]) -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` which will attempt to highlight the `Element` with the specified `color` and `duration`.
---
--- Parameters:
---  * color	- The `hs.drawing` color to use. (defaults to red)
---  * duration	- The `number` of seconds to highlight for. (defaults to `3` seconds)
---
--- Returns:
---  * The `Statement` which will perform the action.
function Element:doHighlight(color, duration)
    if type(color) == "number" then
        duration = color
        color = nil
    end
    color = color or RED_COLOR
    duration = duration or 3
    --log.df("doHighlight: color=%s, duration=%d", hs.inspect(color), duration)
    local highlight

    return If(self.frame)
    :Then(function(frame)
        return Do(function()
            --log.df("doHighlight: frame: %s", hs.inspect(frame))
            highlight = drawing.rectangle(frame)
            highlight:setStrokeColor(color)
            highlight:setFill(false)
            highlight:setStrokeWidth(3)
            highlight:show()
            return true
        end)
        :ThenDelay(duration * 1000)
    end)
    :Otherwise(false)
    :Finally(function()
        --log.df("doHighlight: Finally...")
        if highlight then
            --log.df("doHighlight: Finally: removing highlight...")
            highlight:delete()
            highlight = nil
        end
    end)
    :Label("cp.ui.Element:doHighlight(color, duration)")
end

--- cp.ui.Element:highlight([color], [duration]) -> cp.ui.Element
--- Method
--- Highlights the `Element` with the specified `color` and `duration`.
---
--- Parameters:
---  * color	- The `hs.drawing` color to use. (defaults to red)
---  * duration	- The `number` of seconds to highlight for. (defaults to `3` seconds)
---
--- Returns:
---  * the same `Element` instance.
function Element:highlight(color, duration)
    self:doHighlight(color, duration):Now()
    return self
end


--- cp.ui.Element:saveLayout() -> table
--- Method
--- Returns a `table` containing the current configuration details for this Element (or subclass).
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
--- Notes:
---  * When subclassing, the overriding `saveLayout` method should call the parent's saveLayout method,
--- then add values to it, like so:
---    ```
---    function MyElement:saveLayout()
---        local layout = Element.saveLayout(self)
---        layout.myConfig = self.myConfig
---        return layout
---    end
---    ```
function Element.saveLayout(_)
    return {}
end

--- cp.ui.Element:loadLayout(layout) -> nil
--- Method
--- When called, the Element (or subclass) will attempt to load the layout based on the parameters
--- provided by the `layout` table. This table should generally be generated via the [#saveLayout] method.
---
--- Parameters:
---  * layout - a `table` of parameters that will be used to layout the element.
---
--- Returns:
---  * None
---
--- Notes:
---  * When subclassing, the overriding `loadLayout` method should call the parent's `loadLayout` method,
--- then process any custom values from it, like so:
---    ```
---    function MyElement:loadLayout(layout)
---        Element.loadLayout(self, layout)
---        self.myConfig = layout.myConfig
---    end
---    ```
function Element.loadLayout(_, _)
end

function Element.lazy.method:doSaveLayout()
    return Do(function() return self:saveLayout() end)
    :Label("cp.ui.Element:doSaveLayout()")
end

--- cp.ui.Element:doLayout(layout) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) which will attempt to load the layout based on the parameters
--- provided by the `layout` table. This table should generally be generated via the [#saveLayout] method.
---
--- Parameters:
---  * layout - a `table` of parameters that will be used to layout the element.
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md) to execute.
---
--- Notes:
---  * By default, to enable backwards-compatibility, this method will simply call the [#loadLayout]. Override it to provide more optimal asynchonous behaviour if required.
---  * When subclassing, the overriding `doLayout` method should call the parent class's `doLayout` method,
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
    :Label("cp.ui.Element:doLayout(layout)")
end

function Element:doStoreLayout(id)
    return Given(self:doSaveLayout())
    :Then(function(layout)
        local layouts = self.__storedLayouts or {}
        layouts[id] = layout
        self.__storedLayouts = layouts
        return layout
    end)
    :Label("cp.ui.Element:doStoreLayout(id)")
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
    :Label("cp.ui.Element:doForgetLayout(id)")
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
    :Label("cp.ui.Element:doRecallLayout(id, preserve)")
end

-- This just returns the same element when it is called as a method. (eg. `fcp.viewer == fcp.viewer`)
-- This is a bridge while we migrate to using `lazy.value` instead of `lazy.method` (or methods)
-- in the FCPX API.
function Element:__call()
    return self
end

return Element
