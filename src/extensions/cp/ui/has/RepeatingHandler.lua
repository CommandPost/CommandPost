--- === cp.ui.has.RepeatingHandler ===
---
--- A [RepeatingHandler](cp.ui.has.RepeatingHandler.md) is a [UIHandler](cp.ui.has.UIHandler.md) that can be used to build an [ElementRepeater](cp.ui.has.ElementRepeater.md).

local require                           = require

local ElementRepeater                   = require "cp.ui.has.ElementRepeater"
local UIHandler                         = require "cp.ui.has.UIHandler"

local RepeatingHandler = UIHandler:subclass("cp.ui.has.RepeatingHandler")

--- cp.ui.has.RepeatingHandler(handler, [minCount], [maxCount]) -> cp.ui.has.RepeatingHandler
--- Constructor
--- Creates a new `RepeatingHandler` instance.
---
--- Parameters:
---  * handler - The [UIHandler](cp.ui.has.UIHandler.md) to use to build the repeating element.
---  * minCount - The minimum number of times to repeat the element. (default is no limit)
---  * maxCount - The maximum number of times to repeat the element. (default is no limit)
---
--- Returns:
---  * The new `RepeatingHandler` instance.
function RepeatingHandler:initialize(handler, minCount, maxCount)
    UIHandler.initialize(self)
    self.handler = handler
    self.minCount = minCount
    self.maxCount = maxCount
end

--- cp.ui.has.RepeatingHandler:matches(uiList) -> true, cp.slice | false, nil
--- Method
--- Matches multiple instances of the `handler`, between `minCount` and `maxCount` (if specified).
--- If `minCount` is specified and it repeats less than that value, it will return `false`.
--- If `maxCount` is specified it will ignore any subsequent matches, and they will be returned in the slice.
---
--- Parameters:
---  * uiList - The `cp.slice` of `hs.axuielement` objects to match against.
---
--- Returns:
---  * `true` if the handler matches the `hs.axuielement`, otherwise `false`.
---  * The remaining `hs.axuielement` objects that were not matched as a slice, or `nil` if it was not matched.
function RepeatingHandler:matches(uiList)
    local handler = self.handler
    local minCount = self.minCount
    local maxCount = self.maxCount
    local count = 0
    local success, remainder
    while true do
        success, remainder = handler:matches(uiList)
        if not success then
            if minCount and count < minCount then
                return false, nil
            else
                return true, uiList
            end
        end
        count = count + 1
        uiList = remainder
        if maxCount and count > maxCount then
            return true, uiList
        end
    end
end

--- cp.ui.has.RepeatingHandler:build(parent, uiListFinder) -> cp.ui.has.ElementRepeater
--- Method
--- Builds an [ElementRepeater](cp.ui.has.ElementRepeater.md) instance for the `handler` provided to the constructor.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiListFinder - A callable value which returns the list of `hs.axuielement` objects to match against.
---
--- Returns:
---  * The new [ElementRepeater](cp.ui.has.ElementRepeater.md) instance.
function RepeatingHandler:build(parent, uiListFinder)
    return ElementRepeater(parent, uiListFinder, self.handler, self.minCount, self.maxCount)
end

return RepeatingHandler