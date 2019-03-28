--- === cp.ui.ElementCache ===
---
--- Provides caching for [Element](cp.ui.Element.md) subclasses that want to cache children.

local class	                = require "middleclass"
local axutils	            = require "cp.ui.axutils"

local insert	            = table.insert

local ElementCache = class("cp.ui.ElementCache")

--- cp.ui.ElementCache(parent[, createFn])
--- Constructor
--- Creates and returns a new `ElementCache`, with the specified parent and function which
--- will create new elements on demand. The `createFn` has the signature of `function(parent, ui) -> cp.ui.Element`,
--- and should take the parent provided here and the `axuielement` and return a new `Element` subclass.
---
--- Parameters:
--- * parent - the parent [Element](cp.ui.Element.md) that contains the cached items.
--- * createFn - a function that will create new `Element` subclasses based on cached `axuielement` values.
---
--- Returns:
--- * The new `ElementCache`.
function ElementCache:initialize(parent, createFn)
    self.items = {}
    self.parent = parent
    self.createFn = createFn
end

--- cp.ui.ElementCache:clean()
--- Method
--- Clears the cache of any invalid (aka dead) items.
function ElementCache:clean()
    local cache = self.items
    if cache then
        for ui,_ in pairs(cache) do
            if not axutils.isValid(ui) then
                cache[ui] = nil
            end
        end
    end
end

--- cp.ui.ElementCache:reset()
--- Method
--- Removes all cached items from the cache.
function ElementCache:reset()
    self.items = {}
end

--- ElementCache:cachedElement(cache, ui) -> cp.ui.Element or nil
--- Method
--- Returns the cached [Element](cp.ui.Element.md), if it is present.
function ElementCache:cachedElement(ui)
    local cache = self.items
    if cache then
        for cachedUI,row in pairs(cache) do
            if cachedUI == ui then
                return row
            end
        end
    end
end

--- ElementCache:cacheElement(element[, ui])
--- Method
--- Caches the provided [Element](cp.ui.Element.md).
---
--- Parameters:
--- * element - The [Element](cp.ui.Element.md)
--- * ui - The `axuielement` it is linked to. If not provided, it will be fetched by calling `Element:UI()`.
function ElementCache:cacheElement(element, ui)
    local cache = self.items
    ui = ui or element:UI()
    if axutils.isValid(ui) then
        cache[ui] = element
    end
end

--- ElementCache:fetchElement(ui) -> cp.ui.Element or nil
--- Method
--- Retrieves the matching [Element](cp.ui.Element.md) instance from the cache.
--- If none exists and the `createFn` was provided in the constructor,
--- it will be used to create a new one, which is automatically cached for future reference.
---
--- Parameters:
--- * ui - The `axuielement` being fetched for.
function ElementCache:fetchElement(ui)
    if ui:attributeValue("AXParent") ~= self.parent:UI() then
        return nil
    end

    if not axutils.isValid(ui) then
        return nil
    end

    local element = self:cachedElement(ui)
    local createFn = self.createFn
    if not element and createFn then
        element = createFn(self.parent, ui)
        self:cacheElement(element, ui)
    end
    return element
end

--- cp.ui.ElementCache:fetchElements(uis) -> table of cp.ui.Elements or nil
--- Method
--- Fetches a list of [Element](cp.ui.Element.md) instances linked to the provided `axuielement` list.
---
--- Parameters:
--- * uis	- A `table` of `axuielement` values.
---
--- Returns:
--- * A `table` of [Element](cp.ui.Element.md) values.
---
--- Notes:
--- * If any of the provided `axuielement` values are either not from the parent, or no longer valid, a `nil` value will be stored in the matching index. Note that in that case, this will break useage of `ipairs` due to leaving holes in the list.
function ElementCache:fetchElements(uis)
    if uis then
        self:clean()
        local elements = {}

        for _,ui in ipairs(uis) do
            insert(elements, self:fetchElement(ui))
        end

        return elements
    end
end

return ElementCache