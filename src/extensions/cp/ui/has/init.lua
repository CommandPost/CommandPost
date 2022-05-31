--- === cp.ui.has ===
---
--- This module contains several support functions and classes to help define [Element](cp.ui.Element.md)
--- values for lists of `hs.axuielement`s. A typical example is the `AXChildren` of many elements,
--- which can come in complicated orders and combinations.

local require                       = require

local inspect                       = require "hs.inspect"

local Builder                       = require "cp.ui.Builder"
local Element                       = require "cp.ui.Element"
local AliasHandler                  = require "cp.ui.has.AliasHandler"
local ElementHandler                = require "cp.ui.has.ElementHandler"
local ListHandler                   = require "cp.ui.has.ListHandler"
local UIHandler                     = require "cp.ui.has.UIHandler"

local format                        = string.format
local insert                        = table.insert

local has = {}

local function toHandler(value, errorLevel)
    if UIHandler:isClassOf(value) then
        return value
    elseif Element:isSupertypeOf(value) or Builder:isClassOf(value) then
        return ElementHandler(value)
    else
        errorLevel = errorLevel or 1
        error(format("expected a cp.ui.Element, cp.ui.Builder, or cp.ui.has.UIHandler, got %s: %s", type(value), inspect(value, {depth=2})), 1 + errorLevel)
    end
end

local function toHandlers(values, errorLevel)
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

--- cp.ui.has.alias(name, uiHandler) -> cp.ui.has.AliasHandler
--- Function
--- Creates a new [AliasHandler](cp.ui.has.AliasHandler.md) for the specified [UIHandler](cp.ui.has.UIHandler.md), [Element](cp.ui.Element.md), or [Builder](cp.ui.Builder.md).
---
--- Parameters:
---  * name - The name of the field to create on the parent.
---  * uiHandler - The [UIHandler](cp.ui.has.UIHandler.md) to use to build the `Element` instance.
---
--- Returns:
---  * The new `AliasHandler` instance.
---
--- Notes:
---  * The `uiHandler` may be an [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md), in which
---    case it will be wrapped in an [ElementHandler](cp.ui.has.ElementHandler.md).
function has.alias(name, uiHandler)
    return AliasHandler(name, toHandler(uiHandler, 2))
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

return has