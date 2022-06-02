--- === cp.ui.has.ElementRepeater ===
---
--- A table that can be used to repeat the results of a [UIHandler](cp.ui.has.UIHandler.md) or [Element](cp.ui.Element.md) over a range of values.

local require                       = require

local is                            = require "cp.is"

local class                         = require "middleclass"
local lazy                          = require "cp.lazy"

local isNumber                      = is.number

local ElementRepeater = class("cp.ui.has.ElementRepeater"):include(lazy)

--- cp.ui.has.ElementRepeater(parent, uiListFinder, handler, minCount, maxCount) -> cp.ui.has.ElementRepeater
--- Constructor
--- Creates a new `ElementRepeater` instance.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiListFinder - A callable value which returns the list of `hs.axuielement` objects to match against.
---  * handler - The [UIHandler](cp.ui.has.UIHandler.md) to use to one item in the list.
---  * minCount - The minimum number of times to repeat the `handler`.
---  * maxCount - The maximum number of times to repeat the `handler`.
---
--- Returns:
---  * The new `ElementRepeater` instance.
function ElementRepeater:initialize(parent, uiListFinder, handler, minCount, maxCount)
    self.parent = parent
    self.uiListFinder = uiListFinder
    self.handler = handler
    self.minCount = minCount
    self.maxCount = maxCount
end

function ElementRepeater.lazy.value:_items()
    return setmetatable({}, {__mode = "k"})
end

--- cp.ui.has.ElementRepeater:item(index) -> any
--- Method
--- Gets the value at the specified index.
---
--- Parameters:
---  * index - The index to get the value at.
---
--- Returns:
---  * The value at the specified index.
function ElementRepeater:item(index)
    if isNumber(self.maxCount) and index > self.maxCount then
        return nil
    end

    local item = self._items[index]

    if item then return item end

    local itemUIListFinder = self.uiListFinder:mutate(function(original)
        local uiList = original()
        if not uiList then return nil end

        local success = true
        for i = 1, index - 1 do
            success, uiList = self.handler:matches(uiList)
            if not success then
                return nil
            end
        end

        -- check there are enough matching items to meet the criteria
        if isNumber(self.minCount) then
            local remainder = uiList
            for i = index, self.countCount do
                success, remainder = self.handler:matches(remainder)
                if not success then
                    break
                end
                uiList = remainder
            end
        end

        return uiList
    end)

    local value = self.handler:build(self.parent, itemUIListFinder)
    self._items[index] = value
    return value
end

--- cp.ui.has.ElementRepeater:count() -> number
--- Method
--- Gets the number of items in the repeater, based on the current `UI`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The number of items in the repeater.
function ElementRepeater:count()
    local uiList = self.uiListFinder()
    if not uiList then return 0 end

    local count = 0
    local success, remainder = true, uiList
    while true do
        if isNumber(self.maxCount) and count > self.maxCount then
            break
        end

        success, remainder = self.handler:matches(remainder)
        if not success then
            break
        end
        count = count + 1
    end

    if isNumber(self.minCount) and count < self.minCount then
        return 0
    end

    return count
end

return ElementRepeater