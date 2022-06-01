--- === cp.ui.has.ElementList ===
---
--- Provides caching for [Element](cp.ui.Element.md) subclasses that want to cache children.
---
--- It is linked to a specfic `parent` [Element](cp.ui.Element.md), and a `uiFinder` that returns
--- a list of `hs.axuielement` objects.
---
--- The `elementInit` should only expect to receive a `parent` (this `ParentElement`), then
--- a `uiFinder` "callable" pointing to the specific child at the specific index.
---
--- When the `uiFinder` resolves to an actual table, the `#myCache` call will return the number of
--- children in the table, so the cache can be looped through in a for loop with an `ipairs` function call.

local require               = require

-- local log                   = require "hs.logger".new "ElementList"

local is                    = require "cp.is"
local prop                  = require "cp.prop"
local slice                 = require "cp.slice"

local isTable               = is.table
local isNumber              = is.number
local format                = string.format

local class	                = require "middleclass"
local lazy                  = require "cp.lazy"

local ElementList = class("cp.ui.has.ElementList"):include(lazy)

-- matchesUpTo(index, handlerList, uiList) -> true, cp.slice | false, nil
-- Function
-- Given a `handlerList` and a `uiList`, checks each handler's `find` up to but not including the `index`. If all handlers
-- return `true`, then the last remainder is returned. If any handler returns `false`, then `false, nil` is returned.
--
-- Parameters:
--  * index - The index to process up to.
--  * handlerList - A list of `UIHandler` subclasses.
--  * uiList - A list of `hs.axuielement` objects.
--
-- Returns:
--  * `true, cp.slice` - If all handlers return `true`.
--  * `false, nil` - If any handler returns `false`.
local function matchesUpTo(index, handlerList, uiList)
    if index > #handlerList then
        return false, nil
    end
    local result = true
    for i=1,index-1 do
        local handler = handlerList[i]
        result, uiList = handler:matches(uiList)
        if not result then
            return false, nil
        end
    end
    return result, uiList
end

local subclassNumber = 1

--- cp.ui.has.ElementList:ofExactly(uiHandlers) -> cp.ui.has.ElementList type
--- Function
--- Returns a function that will return a new `ElementList` instance when passed a `parent` and `uiFinder`.
---
--- Parameters:
---  * uiHandlers - The list of [UIHandlers](cp.ui.has.UIHandler.md) to pass to the `ElementList` constructor.
---
--- Returns:
---  * A new `ElementList` subclass that supports the provided list of `UIHandlers`.
function ElementList.static:ofExactly(uiHandlers)
    local listClass = self:subclass(format("%s_%d", self.name, subclassNumber))
    subclassNumber = subclassNumber + 1

    function listClass:initialize(parent, uiFinder)
        listClass.super.initialize(self, parent, uiFinder, uiHandlers)
    end

    -- map aliases to the appropriate index.
    for i, handler in ipairs(uiHandlers) do
        if handler.alias then
            listClass.lazy.value[handler.alias] = function(self)
                return self[i]
            end
        end
    end

    return listClass
end

--- cp.ui.has.ElementList(parent, uiFinder, uiHandlers)
--- Constructor
--- Creates and returns a new `ElementList`, with the specified parent, uiFinder, and uiHandlers.
---
--- Parameters:
---  * parent - the parent [Element](cp.ui.Element.md) that contains the cached items.
---  * uiFinder - a function which will return the table of child `hs.axuielement`s when available.
---  * uiHandlers - a table of [UIHandlers](cp.ui.has.UIHandler.md).
---
--- Returns:
---  * The new `ElementList`.
function ElementList:initialize(parent, uiFinder, uiHandlers)
    rawset(self, "_elements", setmetatable({}, {__mode="k"}))
    -- rawset(self, "_cache", elements)
    rawset(self, "_parent", parent)
    rawset(self, "_uiHandlers", uiHandlers)
    rawset(self, "UI", prop.FROM(uiFinder))
end

--- cp.ui.has.ElementList:get(index) -> any
--- Method
--- Gets the value at the specified index. This is often an [Element](cp.ui.Element.md) subclass, but can be any type.
---
--- Parameters:
---  * index - the index of the `Element` to get.
---
--- Returns:
---  * The value at the specified index.
function ElementList:get(index)
    if index < 1 then
        return nil
    end

    local elements = self._elements
    local item = elements[index]
    if item then
        return item
    end

    local uiHandlers = self._uiHandlers
    local initCount = #uiHandlers
    if index > initCount then
        return nil
    end
    local uiHandler = uiHandlers[index]

    local itemUI = self.UI:mutate(function(original)
        local uiElements = original:get()
        if isTable(uiElements) then
            uiElements = slice.from(uiElements)
            local found, remainingUIElements = matchesUpTo(index, uiHandlers, uiElements)
            return found and remainingUIElements or nil
        end
    end)

    item = uiHandler:build(self._parent, itemUI)
    elements[index] = item
    return item
end

--- cp.ui.has.ElementList:update() -> cp.ui.has.ElementList
--- Method
--- Updates the cache.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * The `ElementList` instance.
function ElementList:update()
    self.UI:update()
    return self
end

function ElementList:__len()
    local value = self.UI:get()
    if isTable(value) then
        return #value
    end
    return 0
end

-- Note to self: defining these here so that we don't have to cache `parent`, `ui`, and `elementInits`,
-- causing infinite looping when inspecting.
function ElementList:__index(key)
    if not isNumber(key) then
        return
    end

    return self:get(key)
end

function ElementList.__newindex()
    -- read-only
end



return ElementList