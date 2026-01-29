--- === cp.ui.Grid ===
---
--- An `AXGrid` UI element. It typically represents multiple items of the same type,
--- arranged into a grid of some number of columns and rows.
---
--- These are accessible via an [ElementRepeater](cp.ui.has.ElementRepeater.md) at the [children](cp.ui.HasRepeatingChildren.md#children) property,
--- and an indication of how it's split up via the [rowCount](cp.ui.Grid.md#rowCount) property.
---
--- Extends: [cp.ui.Element](cp.ui.Element.md)
--- Includes:
---  * [HasRepeatingChildren](cp.ui.HasRepeatingChildren.md)

local require                   = require

-- local log                       = require "hs.logger".new "Grid"

local ax                        = require "cp.fn.ax"
local has                       = require "cp.ui.has"
local Element                   = require "cp.ui.Element"
local HasRepeatingChildren      = require "cp.ui.HasRepeatingChildren"

local go                        = require "cp.rx.go"
local If                        = go.If

local handler, zeroOrMore       = has.handler, has.zeroOrMore

local Grid = Element:subclass("cp.ui.Grid")
                    :include(HasRepeatingChildren)
                    :delegateTo("children")
                    :defineBuilder("containing")

--- === cp.ui.Grid.Builder ===
---
--- Builder for [Grid](cp.ui.Grid.md).
---
--- Extends [Builder](cp.ui.Builder.md).

--- cp.ui.Grid.Builder:containing(childHandler) -> cp.ui.Builder
--- Method
--- Sets the `Element` type for the `children` property.
---
--- Parameters:
---  * childHandler - The `Element` type to use for the `children` property.
---
--- Returns:
---  * The `Builder` instance.

--- cp.ui.Grid:containing(childHandler) -> cp.ui.Builder
--- Function
--- Sets the `Element` type for the `children` property.
---
--- Parameters:
---  * childHandler - The `Element` type to use for the `children` property.
---
--- Returns:
---  * The `Builder` instance.

--- cp.ui.Grid.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Grid`.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * A boolean
Grid.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXGrid")

--- cp.ui.Grid(parent, uiFinder, childHandler) -> cp.ui.Grid
--- Constructor
--- Creates a new `Grid` instance.
---
--- Parameters:
---  * parent - The parent `Element` or `nil` if there is no parent.
---  * uiFinder - A `hs.ui.AXUIElement` or `axuielementObject` to use to find the `Grid` in the UI.
---  * childHandler - The `Element` type to use for the `children` property.
---
--- Returns:
---  * A new `Grid` instance.
function Grid:initialize(parent, uiFinder, childHandler)
    Element.initialize(self, parent, uiFinder)
    self._childHandler = handler(childHandler)
    self:childHandler(self._childHandler)
end

--- cp.ui.Grid.rowCount <cp.prop: number; read-only; live>
--- Field
--- The number of rows in the grid.
function Grid.lazy.prop:rowCount()
    return ax.prop(self.UI, "AXRowCount")
end

--- cp.ui.Grid.selectedChildrenUI() -> <cp.prop: table of hs.axuielement, live>
--- Function
--- Returns the `hs.axuielement`s for the selected children.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `hs.axuielement`s.
function Grid.lazy.prop:selectedChildrenUI()
    return self:watchFor(
        "AXSelectedChildrenChanged",
        ax.prop(self.UI, "AXSelectedChildren", true),
        0.01
    )
end

--- cp.ui.Grid.selectedChildren <cp.ui.ElementRepeater: cp.ui.Element|any>
--- Field
--- The selected children of the grid.
--- These will match the types defined by the `childHandler` in the initializer.
function Grid.lazy.value:selectedChildren()
    return zeroOrMore(self._childHandler):build(self, self.selectedChildrenUI)
    -- return self:repeater(self.selectedChildrenUI)
end

--- cp.ui.Grid:selectChildUI(childUI) -> self
--- Method
--- Select a specific child within a Scroll Area.
---
--- Parameters:
---  * childUI - The `hs.axuielement` object of the child you want to select.
---
--- Return:
---  * Self
function Grid:selectChildUI(childUI)
    if childUI then
        self:selectedChildrenUI({childUI})
    end
    return self
end

--- cp.ui.Grid:selectChild(child) -> self
--- Method
--- Select a specific child within a Scroll Area.
---
--- Parameters:
---  * child - The child you want to select.
---
--- Return:
---  * Self
function Grid:selectChild(child)
    local childUI = child and child:UI()
    if childUI then
        self:selectedChildrenUI({childUI})
    end
    return self
end

--- cp.ui.Grid:doSelectChild(child) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that selects a specific child within the Grid.
---
--- Parameters:
---  * child - The child [Element](cp.ui.Element.md) you want to select.
---
--- Returns:
---  * A [Statement](cp.rx.go.Statement.md) that can be used to select the specified child.
function Grid:doSelectChild(child)
    return If(self.UI):Then(function()
        self:selectChild(child)
    end)
    :Label("Grid:doSelectChild(child)")
end

--- cp.ui.Grid:selectChildAt(index) -> self
--- Method
--- Select a child element in the given a specific index.
---
--- Parameters:
---  * index - The index of the child you want to select.
---
--- Return:
---  * Self
function Grid:selectChildAt(index)
    local ui = self:childrenUI()
    if ui and index >= 0 and #ui >= index then
        self:selectChildUI(ui[index])
    end
    return self
end

--- cp.ui.Grid:doSelectChildAt(index) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that selects a child element in the given a specific index.
---
--- Parameters:
---  * index - The index of the child you want to select.
---
--- Returns:
---  * A [Statement](cp.rx.go.Statement.md) that can be used to select the specified child.
function Grid:doSelectChildAt(index)
    return If(self.UI):Then(function()
        self:selectChildAt(index)
    end)
    :Label("Grid:doSelectChildAt(index)")
end

--- cp.ui.Grid:selectAll([childrenUI]) -> self
--- Method
--- Select all children in a scroll area.
---
--- Parameters:
---  * childrenUI - A table of `hs.axuielement` objects.
---
--- Return:
---  * Self
function Grid:selectAll(childrenUI)
    childrenUI = childrenUI or self:childrenUI()
    if childrenUI then
        self:selectedChildrenUI(childrenUI)
    end
    return self
end

--- cp.ui.Grid:doSelectAll([childrenUI]) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that selects all children in a scroll area.
---
--- Parameters:
---  * childrenUI - A table of `hs.axuielement` objects.
---
--- Returns:
---  * A [Statement](cp.rx.go.Statement.md) that can be used to select all children.
function Grid:doSelectAll(childrenUI)
    return If(self.UI):Then(function()
        self:selectAll(childrenUI)
    end)
    :Label("Grid:doSelectAll(childrenUI)")
end

--- cp.ui.Grid:saveLayout() -> table
--- Method
--- Saves the current layout of the Grid.
---
--- Parameters:
---  * None
---
--- Return:
---  * A table of the current layout of the Grid.
function Grid:saveLayout()
    local layout = {}
    local children = self:childrenUI()
    if children then
        for _,child in ipairs(children) do
            local frame = child.AXFrame
            if frame then
                table.insert(layout, {
                    x = frame.x,
                    y = frame.y,
                    width = frame.w,
                    height = frame.h,
                })
            end
        end
    end
    return layout
end

return Grid