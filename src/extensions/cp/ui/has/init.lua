--- === cp.ui.has ===
---
--- This module contains several support functions and classes to help define [Element](cp.ui.Element.md)
--- values for lists of `hs.axuielement`s. A typical example is the `AXChildren` of many elements,
--- which can come in complicated orders and combinations.
---
--- There are several functions to help define 

local require                       = require

local inspect                       = require "hs.inspect"

local is                            = require "cp.is"

local Builder                       = require "cp.ui.Builder"
local Element                       = require "cp.ui.Element"
local AliasHandler                  = require "cp.ui.has.AliasHandler"
local ElementHandler                = require "cp.ui.has.ElementHandler"
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
    if UIHandler:isClassOf(value) then
        return value
    elseif Element:isSupertypeOf(value) or Builder:isClassOf(value) then
        return ElementHandler(value)
    elseif isTable(value) then
        local count = #value
        if count == 1 then
            return toHandler(value[1], errorLevel + 1)
        elseif count > 1 then
            return ListHandler(toHandlers(value, errorLevel + 1))
        end
    end
    errorLevel = errorLevel or 1
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


return has