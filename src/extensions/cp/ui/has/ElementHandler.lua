
--- === cp.ui.has.ElementHandler ===
---
--- Handles a single [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md).

local require                   = require

local ax                        = require "cp.fn.ax"
local slice                     = require "cp.slice"
local UIHandler                 = require "cp.ui.has.UIHandler"

local ElementHandler = UIHandler:subclass("cp.ui.has.ElementHandler")

--- cp.ui.has.ElementHandler(elementBuilder) -> cp.ui.has.ElementHandler
--- Constructor
--- Creates a new `ElementHandler` instance.
---
--- Parameters:
---  * elementBuilder - The [Element](cp.ui.Element.md) or [Builder](cp.ui.Builder.md) to use to create the `Element` instance.
---
--- Returns:
---  * The new `ElementHandler` instance.
function ElementHandler:initialize(elementBuilder)
    UIHandler.initialize(self)
    self.elementBuilder = elementBuilder
end

--- cp.ui.has.ElementHandler:matches(uiList) -> true, cp.slice | false, nil
--- Method
--- Processes the list `hs.axuielement` and returns a `true` if the `hs.axuielement` matches, otherwise `false`.
--- If the `hs.axuielement` matches, a [slice](cp.slice.md) of the remaining `hs.axuielement` objects is returned.
---
--- Parameters:
---  * uiList - The `cp.slice` of `hs.axuielement` objects to match against.
---
--- Returns:
---  * `true` if the handler matches the `hs.axuielement`, otherwise `false`.
---  * The remaining `hs.axuielement` objects that were not matched as a slice, or `nil` if it was not matched.
function ElementHandler:matches(uiList)
    local elementBuilder = self.elementBuilder
    if elementBuilder.matches(uiList[1]) then
        return true, uiList:drop(1)
    end
    return false, nil
end

--- cp.ui.has.ElementHandler:build(parent, uiListFinder) -> any
--- Method
--- Builds the [Element](cp.ui.Element.md) for the `elementBuilder` provided to the constructor.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiListFinder - A callable value which returns the list of `hs.axuielement` objects to match against.
---
--- Returns:
---  * The new [Element](cp.ui.Element.md) instance.
function ElementHandler:build(parent, uiListFinder)
    local key = {}
    local ui = uiListFinder:mutate(
        ax.cache(parent, key, self.elementBuilder.matches)(function(original)
            local uiList = original()
            if uiList and self:matches(slice.from(uiList)) then
                return uiList[1]
            end
        end)
    )
    return self.elementBuilder(parent, ui)
end

return ElementHandler