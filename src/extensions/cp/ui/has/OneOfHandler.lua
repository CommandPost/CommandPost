--- === cp.ui.has.OneOfHandler ===
---
--- A handler that receives multiple child [Handler](cp.ui.has.Handler.md) instances, makes all of them available,
--- but will only match the first one that matches a given `hs.axuielement` list.

local require               = require

local ElementChoice         = require "cp.ui.has.ElementChoice"
local UIHandler             = require "cp.ui.has.UIHandler"

local OneOfHandler = UIHandler:subclass("cp.ui.has.OneOfHandler")

--- cp.ui.has.OneOfHandler(handlerList) -> cp.ui.has.OneOfHandler
--- Constructor
--- Creates a new `OneOfHandler` instance.
---
--- Parameters:
---  * handlerList - The list of [UIHandler](cp.ui.has.UIHandler.md) instances to use to build the list.
---
--- Returns:
---  * The new `OneOfHandler` instance.
function OneOfHandler:initialize(handlerList)
    UIHandler.initialize(self)
    self.handlerList = handlerList
end

--- cp.ui.has.OneOfHandler:matches(uiList) -> true, cp.slice | false, nil
--- Method
--- Processes the list `hs.axuielement` and returns a `true` if the `hs.axuielement` matches, otherwise `false`.
--- If the `hs.axuielement` matches, a [slice](cp.slice.md) of the remaining `hs.axuielement` objects is returned.
---
--- Parameters:
---  * elements - The `cp.slice` of `hs.axuielement` objects to match against.
---
--- Returns:
---  * `true` if the handler matches the `hs.axuielement`, otherwise `false`.
---  * The remaining `hs.axuielement` objects that were not matched as a slice, or `nil` if it was not matched.
function OneOfHandler:matches(uiList)
    local handlerList = self.handlerList
    for _, handler in ipairs(handlerList) do
        local result, remainingUIList = handler:matches(uiList)
        if result then
            return true, remainingUIList
        end
    end
    return false, nil
end

--- cp.ui.has.OneOfHandler:build(parent, uiListFinder) -> cp.ui.has.ElementChoice
--- Method
--- Builds an [has](cp.ui.has.md) instance for the `handlerList` provided to the constructor.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiListFinder - A callable value which returns the list of `hs.axuielement` objects to match against.
---
--- Returns:
---  * The new [ElementChoice](cp.ui.has.ElementChoice.md) instance.
function OneOfHandler:build(parent, uiListFinder)
    return ElementChoice:of(self.handlerList)(parent, uiListFinder)
end

return OneOfHandler