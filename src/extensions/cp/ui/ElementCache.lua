--- === cp.ui.ElementCache ===
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

local log                   = require "hs.logger".new "ElementCache"

local ax                    = require "cp.fn.ax"
local is                    = require "cp.is"
local prop                  = require "cp.prop"
local Element               = require "cp.ui.Element"

local pack                  = table.pack
local isCallable, isTable   = is.callable, is.table
local isNumber              = is.number

local class	                = require "middleclass"
local ElementCache = class("cp.ui.ElementCache")

--- cp.ui.ElementCache.containing(...) -> function(parent, uiFinder) -> cp.ui.ElementCache
--- Function
--- Returns a function that will return a new `ElementCache` instance when passed a `parent` and `uiFinder`.
---
--- Parameters:
---  * ... - The arguments to pass to the `ElementCache` constructor.
---
--- Returns:
---  * A function that will return a new `ElementCache` instance.
function ElementCache.static.containing(...)
    local args = pack(...)
    if #args == 1 then
        local arg = args[1]
        if not isCallable(args) and isTable(args) then
            args = arg
        end
    end
    return function(parent, uiFinder)
        return ElementCache(parent, uiFinder, args)
    end
end

--- cp.ui.ElementCache(parent, uiFinder, [elementInits])
--- Constructor
--- Creates and returns a new `ElementCache`, with the specified parent and function which
--- will create new elements on demand. An [Element init](cp.ui.Element.md) has the signature of `function(parent, ui) -> cp.ui.Element`,
--- and should take the parent provided here and the `axuielement` and return a new `Element` subclass.
---
--- Parameters:
---  * parent - the parent [Element](cp.ui.Element.md) that contains the cached items.
---  * uiFinder - a function which will return the table of child `hs.axuielement`s when available.
---  * elementInits - a table of [Element](cp.ui.Element.md) inits. Defaults to [Element](cp.ui.Element.md).
---
--- Returns:
---  * The new `ElementCache`.
---
--- Notes:
---  * If only one element init function is provided, it will be used for all children.
---  * If multiple element init functions are provided, the first one will be used for the first child, the second one for the second child, etc.
---    If there are more children than element init functions, [Element](cp.ui.Element.md) will be used for the rest.
function ElementCache:initialize(parent, uiFinder, elementInits)
    local elements = setmetatable({}, {__mode="k"})
    -- rawset(self, "_cache", elements)
    elementInits = elementInits or {}
    local ui = prop.FROM(uiFinder)

--- cp.ui.ElementCache:get(index) -> cp.ui.Element
--- Method
--- Gets the `Element` at the specified index.
---
--- Parameters:
---  * index - the index of the `Element` to get.
---
--- Returns:
---  * The `Element` at the specified index.
---
--- Notes:
---  * This will always return a value for any index above `0`, even if the `Element` is not yet available in the UI.
    function self.class:get(index)
        if index < 1 then
            return
        end

        local item = elements[index]
        if item then
            return item
        end

        local init
        local initCount = #elementInits
        if initCount == 1 then
            init = elementInits[1]
        else
            init = elementInits[index] or Element
        end

        item = init(parent, ui:mutate(function(original)
            local value = original:get()
            if isTable(value) then
                local child = value[index]
                return ax.isValid(child) and child or nil
            end
        end))
        elements[index] = item
        return item
    end

    -- Note to self: defining these here so that we don't have to cache `parent`, `ui`, and `elementInits`,
    -- causing infinite looping when inspecting.
    function self.class:__index(key)
        if not isNumber(key) or key > #self then
            return
        end

        return self:get(key)
    end

    function self.class.__newindex()
        -- read-only
    end

    function self.class:__len()
        local value = ui:get()
        if isTable(value) then
            return #value
        end
        return 0
    end
end


return ElementCache