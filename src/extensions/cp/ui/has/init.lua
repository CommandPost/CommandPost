--- === cp.ui.has ===
---
--- This module contains several support functions and classes to help define [Element](cp.ui.Element.md)
--- values for lists of `hs.axuielement`s. A typical example is the `AXChildren` of many elements,
--- which can come in complicated orders and combinations.
---
--- Basically, it lets you define [UIHandler](cp.ui.has.UIHandler.md) values that expect to be receiving a list
--- of `hs.axuielement`s, consume some of them, returning the remaining list, and then build a value to process
--- them (often, but not always, an [Element](cp.ui.Element.md)).
---
--- There are two main things you can do with a [UIHandler](cp.ui.has.UIHandler.md):
---
--- 1. Match a list of `hs.axuielement`s against it.
--- 2. Build a value from the list of `hs.axuielement`s.
---
--- ## Example
---
--- For example, lets say our app has an `AXBox` element with an `AXChildren` attribute that has something like this:
---
--- > AXStaticText, AXTextField, AXStaticText, AXCheckBox
---
--- This might be a text field and a checkbox, each with a descriptive label. We can build a [UIHandler](cp.ui.has.UIHandler.md)
--- that will match against this list like so:
---
--- ```lua
--- local fn        = require "cp.fn"
--- local ax        = require "cp.fn.ax"
--- local Element   = require "cp.ui.Element"
--- local has       = require "cp.ui.has"
---
--- local Box = Element:subclass("my.Box")
---
--- Box.static.matches = ax.matchesIf(Element.matches, ax.hasRole("AXBox"))
---
--- Box.static.childrenHandler = has.list {
---     StaticText, TextField,
---     StaticText, CheckBox,
--- }
--- ```
---
--- The `Box.childrenHandler` will be a [ListHandler](cp.ui.has.ListHandler.md). We can then use it to build an [ElementList](cp.ui.has.ElementList.md):
---
--- ```lua
--- function Box.lazy.prop:childrenUI()
---     return ax.prop(self.UI, "AXChildren")
--- end
---
--- function Box.lazy.value:children()
---     return self.class.childrenHandler:build(self, self.childrenUI) -- returns ElementList
--- end
--- ```
---
--- Now, we can use the `children` property to get the list of children:
---
--- ```lua
--- local box = Box(parent, uiFinder)
--- local textField = box.children[2]
--- local checkBox = box.children[4]
--- ```
---
--- It would also be nice if we could give them a name, rather than an index number. We can redefine the
--- `childrenHandler` like so:
---
--- ```lua
--- Box.static.childrenHandler = has.list {
---     StaticText, has.alias "textField" { TextField },
---     StaticText, has.alias "checkBox" { CheckBox },
--- }
--- ```
---
--- Now, we can be more specific:
---
--- ```lua
--- local box = Box(parent, uiFinder)
--- local textField = box.children.textField
--- local checkBox = box.children.checkBox
--- -- can still us index if you want:
--- checkBox = box.children[4]
--- ```
---
--- As indicated, accessing via index will still work, even with an alias set.
---
--- There are several functions to help define the structure. More details are below.
---
--- ## `list`
---
--- [list](cp.ui.has.md#list) is a function that takes a list of [UIHandler](cp.ui.has.UIHandler.md)s.
--- It expects that it will be given a list of `hs.axuielement` objects, and will match through all
--- of the handlers in the list, in order. It returns an [ElementList](cp.ui.has.ElementList.md).
---
--- ### Example:
---
--- Here, the list has a [StaticText](cp.ui.StaticText.md) followed by a [TextField](cp.ui.TextField.md):
---
--- ```lua
--- has.list {
---     StaticText, TextField
--- }
--- ```
---
--- ## `alias`
---
--- [alias](cp.ui.has.md#alias) is a function that takes an alias and returns a function that accepts a handler.
--- It returns a function that will return the result of the handler, but will also set the alias on the result.
---
--- ### Example:
---
--- Here, the list has a [StaticText](cp.ui.StaticText.md) followed by a [TextField](cp.ui.TextField.md):
---
--- ```lua
--- has.list {
---     StaticText, has.alias "textField" { TextField },
--- }
--- ```
---
--- ## `oneOf`
---
--- [oneOf](cp.ui.has.md#oneOf) is a function that takes a list of [UIHandler](cp.ui.has.UIHandler.md)s.
--- It expects that it will be given a list of `hs.axuielement` objects, and will attempt to match through
--- all of the handlers in the list, in order. It returns the first match and stops processing.
---
--- ### Example:
---
--- A piece of UI could be a [PopUpButton](cp.ui.PopUpButton.md) or a [TextField](cp.ui.TextField.md), depending
--- on the context.
---
--- ```lua
--- has.oneOf {
---     has.alias "preset" { PopUpButton },
---     has.alias "other" { TextField },
--- }
--- ```
---
--- This will return a [OneOfHandler](cp.ui.has.OneOfHandler.md), which will build an [ElementChoice](cp.ui.has.ElementChoice.md).
--- Again, `alias` is optional, but it's clearer here than using an index.
---
--- ## `optional`
---
--- [optional](cp.ui.has.md#optional) is a function that takes a handler. It returns an [OptionalHandler](cp.ui.has.OptionalHandler.md),
--- which will build whatever the wrapped handler builds, but it will pass a `match` even if the wrapped handler
--- doesn't match.
---
--- ### Example:
---
--- In this case, a labeled [PopUpButton](cp.ui.PopUpButton.md) may not be present at all:
---
--- ```lua
--- has.optional {
---     StaticText, has.alias "mode" { PopUpButton },
--- }
--- ```
---
--- Here, it will build an [ElementList](cp.ui.has.ElementList.md) because it has been passed multiple handlers.
--- That list will have a field called `mode` that returns the [PopUpButton](cp.ui.PopUpButton.md).
---
--- ## `ended`
---
--- [ended](cp.ui.has.md#ended) is a special case. It is an [EndHandler](cp.ui.has.EndHandler.md) that will
--- return `nil`, and not consume any of the `hs.axuielement` objects. However, if that list is not empty, it will fail.
---
--- It basically provides a way of guaranteeing that the definition has completely consumed the available
--- `hs.axuielement` objects.
---
--- ### Example:
---
--- Here, we have a [StaticText](cp.ui.StaticText.md) followed by a [TextField](cp.ui.TextField.md):
---
--- ```lua
--- has.list {
---     StaticText, TextField,
---     has.ended
--- }
--- ```
---
--- If there are any extra `hs.axuielement` objects after the TextField, it will fail.
---
--- ## `element`
---
--- [element](cp.ui.has.md#element) is a function that takes an [Element](cp.ui.Element.md) and returns an [ElementHandler](cp.ui.has.ElementHandler.md).
--- It can be used to specify that an item is a single element, if that is ambiguous.
---
--- In most cases, you can just pass in the [Element](cp.ui.Element.md) directly, and it will be wrapped automatically.
---
--- ### Example:
---
--- Here, we have a [StaticText](cp.ui.StaticText.md) followed by a [TextField](cp.ui.TextField.md), wrapped explicitly:
---
--- ```lua
--- has.list {
---     has.element(StaticText), has.alias "textField" { has.element(TextField) },
--- }
--- ```
---
--- ## `handler`
---
--- [handler](cp.ui.has.md#handler) is a function that takes a value and returns a [UIHandler](cp.ui.has.UIHandler.md) for it,
--- or throws an error if not supported.
---
--- It will accept the following input, and return the specified handler:
---
--- * [UIHandler](cp.ui.has.UIHandler.md): returns the handler, unmodified.
--- * [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md): returns a [ElementHandler](cp.ui.has.ElementHandler.md) for the element.
--- * `table`: If the table only contains one element, it will be wrapped using [handler](cp.ui.has.md#handler) and returned directly.
---   Otherwise, it will be wrapped using [list](cp.ui.has.md#list) and returned as an [ElementList](cp.ui.has.ElementList.md).
---
--- It is used internally to process input for most of the above, including [#alias] and [#optional].
---
--- ### Example:
---
--- Here, we have a [StaticText](cp.ui.StaticText.md) followed by a [TextField](cp.ui.TextField.md):


local require                       = require

local inspect                       = require "hs.inspect"

local is                            = require "cp.is"

local Builder                       = require "cp.ui.Builder"
local Element                       = require "cp.ui.Element"
local AliasHandler                  = require "cp.ui.has.AliasHandler"
local ElementHandler                = require "cp.ui.has.ElementHandler"
local EndHandler                    = require "cp.ui.has.EndHandler"
local ListHandler                   = require "cp.ui.has.ListHandler"
local OneOfHandler                  = require "cp.ui.has.OneOfHandler"
local OptionalHandler               = require "cp.ui.has.OptionalHandler"
local RepeatingHandler              = require "cp.ui.has.RepeatingHandler"
local UIHandler                     = require "cp.ui.has.UIHandler"

local format                        = string.format
local insert                        = table.insert
local isTable                       = is.table

local has = {}

local toHandler, toHandlers

-- toHandler(value[, errorLevel]) -> cp.ui.has.UIHandler
-- Function
-- Converts a value to a `UIHandler`.
--
-- Parameters:
--  * value - The value to convert.
--  * errorLevel - The error level to use when an error occurs. Defaults to `1`.
--
-- Returns:
--  * The `UIHandler`
--
-- Notes:
--  * If the value is already a `UIHandler`, it is returned.
--  * If the value is an [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md), it is wrapped in a `ElementHandler`.
--  * If the value is a table with a single value, it is converted to a `UIHandler`.
--  * If the value is a table with multiple values, it is converted to a `ListHandler`.
toHandler = function(value, errorLevel)
    errorLevel = errorLevel or 1
    if UIHandler:isSuperclassFor(value) then
        return value
    elseif Element:isSuperclassOf(value) or Builder:isSuperclassFor(value) then
        return ElementHandler(value)
    elseif isTable(value) then
        local count = #value
        if count == 1 then
            return toHandler(value[1], errorLevel + 1)
        elseif count > 1 then
            return ListHandler(toHandlers(value, errorLevel + 1))
        end
    end
    error(format("expected an Element, Builder, UIHandler, or table thereof, got %s: %s", type(value), inspect(value, {depth=2})), 1 + errorLevel)
end

toHandlers = function(values, errorLevel)
    local handlers = {}
    for i, value in ipairs(values) do
        local success, result = pcall(toHandler, value, 1 + errorLevel)
        if success then
            insert(handlers, result)
        else
            error(format("at %d: %s", i, result), 1 + errorLevel)
        end
    end
    return handlers
end

--- cp.ui.has.handler(value) -> cp.ui.has.UIHandler
--- Function
--- Converts a value to a `UIHandler`.
---
--- Parameters:
---  * value - The value to convert.
---
--- Returns:
---  * The `UIHandler`
---
--- Notes:
--  * If the value is already a `UIHandler`, it is returned.
--  * If the value is an [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md), it is wrapped in a `ElementHandler`.
--  * If the value is a table with a single value, it is converted to a `UIHandler`.
--  * If the value is a table with multiple values, it is converted to a `ListHandler`.
function has.handler(value)
    return toHandler(value, 2)
end

--- cp.ui.has.element(elementBuilder) -> cp.ui.has.ElementHandler
--- Function
--- Creates a new [ElementHandler](cp.ui.has.ElementHandler.md) for the specified [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md).
---
--- Parameters:
---  * elementBuilder - The [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md) to use to create the `Element` instance.
---
--- Returns:
---  * The new `ElementHandler` instance.
function has.element(elementBuilder)
    return ElementHandler(elementBuilder)
end

--- cp.ui.has.alias(name) -> function(uiHandler) -> cp.ui.has.AliasHandler
--- Function
--- Creates a new [AliasHandler](cp.ui.has.AliasHandler.md) for the specified [UIHandler](cp.ui.has.UIHandler.md), [Element](cp.ui.Element.md), or [Builder](cp.ui.Builder.md).
---
--- Parameters:
---  * name - The name of the field to create on the parent.
---
--- Returns:
---  * A function which accepts an [Element](cp.ui.Element.md)/[Builder](cp.ui.Builder.md), a [UIHandler](cp.ui.has.UIHandler.md), or a list of `Element`/`UIHandler` values.
---
--- Notes:
---  * The `uiHandler` may be an [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md), in which
---    case it will be wrapped in an [ElementHandler](cp.ui.has.ElementHandler.md).
---  * The `uiHandler` may be a [UIHandler](cp.ui.has.UIHandler.md), in which case it will be used as is.
---  * The `uiHandler` may be a list of `Element`/`Builder`/`UIHandler` values. If there is only one value, it is treated as if it were passed in directly.
---    If there are more than one, it is treated as a [list](#list).
function has.alias(name)
    return function(uiHandler)
        return AliasHandler(name, toHandler(uiHandler, 2))
    end
end

--- cp.ui.has.list(uiHandlers) -> cp.ui.has.ListHandler
--- Function
--- Creates a new [ListHandler](cp.ui.has.ListHandler.md) for the specified list of [UIHandler](cp.ui.has.UIHandler.md)s.
---
--- Parameters:
---  * uiHandlers - The list of [UIHandler](cp.ui.has.UIHandler.md)s to use to build the `Element` instances.
---
--- Returns:
---  * The new `ListHandler` instance.
---
--- Notes:
---  * Items in `uiHandlers` may also be [Element](cp.ui.Element.md)s or [Builder](cp.ui.Builder.md), in which
---    case they will be wrapped in an [ElementHandler](cp.ui.has.ElementHandler.md).
function has.list(uiHandlers)
    return ListHandler(toHandlers(uiHandlers, 2))
end

--- cp.ui.has.oneOf(uiHandlers) -> cp.ui.has.OneOfHandler
--- Function
--- Creates a new [OneOfHandler](cp.ui.has.OneOfHandler.md) for the specified list of [UIHandler](cp.ui.has.UIHandler.md)s.
---
--- Parameters:
---  * uiHandlers - The list of [UIHandler](cp.ui.has.UIHandler.md)s to use to build the `Element` instances.
---
--- Returns:
---  * The new `OneOfHandler` instance.
---
--- Notes:
---  * Items in `uiHandlers` may also be [Element](cp.ui.Element.md)s or [Builder](cp.ui.Builder.md), in which
---    case they will be wrapped in an [ElementHandler](cp.ui.has.ElementHandler.md).
function has.oneOf(uiHandlers)
    return OneOfHandler(toHandlers(uiHandlers, 2))
end

--- cp.ui.has.optional(handlerOrList) -> cp.ui.has.OptionalHandler
--- Function
--- Creates a new [OptionalHandler](cp.ui.has.OptionalHandler.md) for the specified [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md).
---
--- Parameters:
---  * handlerOrList - The [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md) to use to build the `Element` instance.
---
--- Returns:
---  * The new `OptionalHandler` instance.
---
--- Notes:
---  * The `handlerOrList` may be a single [UIHandler](cp.ui.has.UIHandler.md) or a table of [UIHandlers](cp.ui.has.UIHandler.md), in which case they will be wrapped
---    in a [ListHandler](cp.ui.has.ListHandler.md).
function has.optional(handlerOrList)
    return OptionalHandler(toHandler(handlerOrList, 2))
end

--- cp.ui.has.zeroOrMore(handlerOrList) -> cp.ui.has.RepeatingHandler
--- Function
--- Creates a new [RepeatingHandler](cp.ui.has.RepeatingHandler.md) for the specified [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md).
---
--- Parameters:
---  * handlerOrList - The [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md) to use to build the `Element` instance.
---
--- Returns:
---  * The new `RepeatingHandler` instance.
---
--- Notes:
---  * The `handlerOrList` may be a single [UIHandler](cp.ui.has.UIHandler.md) or a table of [UIHandlers](cp.ui.has.UIHandler.md), in which case they will be wrapped
---    in a [ListHandler](cp.ui.has.ListHandler.md).
function has.zeroOrMore(handlerOrList)
    return RepeatingHandler(toHandler(handlerOrList, 2))
end

--- cp.ui.has.atLeast(minCount) -> function(handlerOrList) -> cp.ui.has.RepeatingHandler
--- Function
--- Creates a new [RepeatingHandler](cp.ui.has.RepeatingHandler.md) for the specified [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md).
---
--- Parameters:
---  * minCount - The minimum number of times the [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md) should be repeated.
---
--- Returns:
---  * The new `RepeatingHandler` instance.
---
--- Notes:
---  * The `handlerOrList` may be a single [UIHandler](cp.ui.has.UIHandler.md) or a table of [UIHandlers](cp.ui.has.UIHandler.md), in which case they will be wrapped
---    in a [ListHandler](cp.ui.has.ListHandler.md).
function has.atLeast(minCount)
    return function(handlerOrList)
        return RepeatingHandler(toHandler(handlerOrList, 2), minCount)
    end
end

--- cp.ui.has.atMost(maxCount) -> function(handlerOrList) -> cp.ui.has.RepeatingHandler
--- Function
--- Creates a new [RepeatingHandler](cp.ui.has.RepeatingHandler.md) for the specified [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md).
---
--- Parameters:
---  * maxCount - The maximum number of times the [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md) should be repeated.
---
--- Returns:
---  * The new `RepeatingHandler` instance.
---
--- Notes:
---  * The `handlerOrList` may be a single [UIHandler](cp.ui.has.UIHandler.md) or a table of [UIHandlers](cp.ui.has.UIHandler.md), in which case they will be wrapped
---    in a [ListHandler](cp.ui.has.ListHandler.md).
function has.atMost(maxCount)
    return function(handlerOrList)
        return RepeatingHandler(toHandler(handlerOrList, 2), nil, maxCount)
    end
end

--- cp.ui.has.between(minCount, maxCount) -> function(handlerOrList) -> cp.ui.has.RepeatingHandler
--- Function
--- Creates a new [RepeatingHandler](cp.ui.has.RepeatingHandler.md) for the specified [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md).
---
--- Parameters:
---  * minCount - The minimum number of times the [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md) should be repeated.
---  * maxCount - The maximum number of times the [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md) should be repeated.
---
--- Returns:
---  * The new `RepeatingHandler` instance.
---
--- Notes:
---  * The `handlerOrList` may be a single [UIHandler](cp.ui.has.UIHandler.md) or a table of [UIHandlers](cp.ui.has.UIHandler.md), in which case they will be wrapped
---    in a [ListHandler](cp.ui.has.ListHandler.md).
function has.between(minCount, maxCount)
    return function(handlerOrList)
        return RepeatingHandler(toHandler(handlerOrList, 2), minCount, maxCount)
    end
end

--- cp.ui.has.exactly(count) -> function(handlerOrList) -> cp.ui.has.RepeatingHandler
--- Function
--- Creates a new [RepeatingHandler](cp.ui.has.RepeatingHandler.md) for the specified [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md).
---
--- Parameters:
---  * count - The number of times the [UIHandler](cp.ui.has.UIHandler.md) or table of [UIHandlers](cp.ui.has.UIHandler.md) must be repeated.
---
--- Returns:
---  * The new `RepeatingHandler` instance.
---
--- Notes:
---  * The `handlerOrList` may be a single [UIHandler](cp.ui.has.UIHandler.md) or a table of [UIHandlers](cp.ui.has.UIHandler.md), in which case they will be wrapped
---    in a [ListHandler](cp.ui.has.ListHandler.md).
function has.exactly(count)
    return function(handlerOrList)
        return RepeatingHandler(toHandler(handlerOrList, 2), count, count)
    end
end

--- cp.ui.has.ended <cp.ui.has.EndHandler>
--- Constant
--- Enforces that the complete list of `hs.axuielement`s have been processed.
has.ended = EndHandler()

return has