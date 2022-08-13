--- === cp.ui.has.ElementChoice ===
---
--- An [ElementChoice](cp.ui.has.ElementChoice.md) is a [has](cp.ui.has.md) instance that represents a choice of elements.
--- Only one of the choices will actually match the current set of `hs.axuielement` objects at a given time.

local require               = require

--local log                   = require "hs.logger".new "ElementChoice"

local is                    = require "cp.is"
local prop                  = require "cp.prop"
local slice                 = require "cp.slice"

local class                 = require "middleclass"
local lazy                  = require "cp.lazy"

local format                = string.format
local isTable, isNumber     = is.table, is.number

local ElementChoice = class("cp.ui.has.ElementChoice"):include(lazy)


-- noMatchUpTo(index, handlerList, uiList) -> true, cp.slice | false, nil
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
local function noMatchUpTo(index, handlerList, uiList)
    if index > #handlerList then
        return false, nil
    end
    for i=1,index-1 do
        local handler = handlerList[i]
        local result = handler:matches(uiList)
        if result then
            return false, nil
        end
    end
    return true, uiList
end

local subclassNumber = 1

--- cp.ui.has.ElementChoice:of(uiHandlers) -> cp.ui.has.ElementChoice type
--- Function
--- Returns a function that will return a new `ElementChoice` instance when passed a `parent` and `uiFinder`.
---
--- Parameters:
---  * uiHandlers - The list of [UIHandlers](cp.ui.has.UIHandler.md) to pass to the `ElementChoice` constructor.
---
--- Returns:
---  * A function that will return a new `ElementChoice` instance.

-- TODO: @randomeizer to review the below code:

function ElementChoice.static:of(uiHandlers) -- luacheck:ignore
    local choiceClass = self:subclass(format("%s_%d", self.name, subclassNumber))
    subclassNumber = subclassNumber + 1


    function choiceClass:initialize(parent, uiFinder) -- luacheck:ignore
        choiceClass.super.initialize(self, parent, uiFinder, uiHandlers)
    end

    -- map aliases to the appropriate index.
    for i, handler in ipairs(uiHandlers) do
        if handler.alias then
            choiceClass.lazy.value[handler.alias] = function(self)
                return self[i]
            end
        end
    end

    return choiceClass
end

--- cp.ui.has.ElementChoice(parent, uiFinder, uiHandlers)
--- Constructor
--- Creates a new `ElementChoice` instance.
---
--- Parameters:
---  * parent - The parent `Element` instance.
---  * uiFinder - The `hs.axuielement` finder.
---  * uiHandlers - The list of [UIHandlers](cp.ui.has.UIHandler.md) to pass to the `ElementChoice` constructor.
---
--- Returns:
---  * A new `ElementChoice` instance.
function ElementChoice:initialize(parent, uiFinder, uiHandlers)
    rawset(self, "_elements", setmetatable({}, {__mode = "k"}))
    rawset(self, "_parent", parent)
    rawset(self, "UI", prop.FROM(uiFinder))
    rawset(self, "_uiHandlers", uiHandlers)
end

--- cp.ui.has.ElementChoice:get(index) -> any
--- Method
--- Gets the `index`th element.
---
--- Parameters:
---  * index - The index of the element to get.
---
--- Returns:
---  * The `index`th element.
function ElementChoice:get(index)
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
            local found, remainingUIElements = noMatchUpTo(index, uiHandlers, uiElements)
            return found and remainingUIElements or nil
        end
    end)

    item = uiHandler:build(self._parent, itemUI)
    elements[index] = item
    return item
end

--- cp.ui.has.ElementChoice:update() -> cp.ui.has.ElementChoice
--- Method
--- Updates the cache.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * The `ElementChoice` instance.
function ElementChoice:update()
    self.UI:update()
    return self
end

function ElementChoice:__len()
    local value = self.UI:get()
    if isTable(value) then
        return #value
    end
    return 0
end

-- Note to self: defining these here so that we don't have to cache `parent`, `ui`, and `elementInits`,
-- causing infinite looping when inspecting.
function ElementChoice:__index(key)
    if not isNumber(key) then
        return
    end

    return self:get(key)
end

function ElementChoice.__newindex()
    -- read-only
end


return ElementChoice