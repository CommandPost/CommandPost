--- === cp.ui.ScrollArea ===
---
--- Scroll Area Module.

local require       = require

local axutils       = require("cp.ui.axutils")
local Element       = require("cp.ui.Element")
local ScrollBar     = require("cp.ui.ScrollBar")


local ScrollArea = Element:subclass("cp.ui.ScrollArea")

--- cp.ui.ScrollArea.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ScrollArea.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXScrollArea"
end

--- cp.ui.ScrollArea(parent, uiFinder) -> cp.ui.ScrollArea
--- Constructor
--- Creates a new `ScrollArea`.
---
--- Parameters:
---  * parent       - The parent object.
---  * uiFinder     - A `function` or `cp.prop` which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * The new `ScrollArea`.
function ScrollArea:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
end

--- cp.ui.ScrollArea.contentsUI <cp.prop: hs._asm.axuielement; read-only; live?>
--- Field
--- Returns the `axuielement` representing the Scroll Area Contents, or `nil` if not available.
function ScrollArea.lazy.prop:contentsUI()
    return self.UI:mutate(function(original)
        local ui = original()
        if ui then
            local role = ui:attributeValue("AXRole")
            if role and role == "AXScrollArea" then
                return ui:contents()[1]
            end
        end
    end)
end

--- cp.ui.ScrollArea.verticalScrollBar <cp.ui.ScrollBar>
--- Field
--- The vertical [ScrollBar](cp.ui.ScrollBar.md).
function ScrollArea.lazy.value:verticalScrollBar()
    return ScrollBar(self, axutils.prop(self.UI, "AXVerticalScrollBar"))
end

--- cp.ui.ScrollArea.horizontalScrollBar <cp.ui.ScrollBar>
--- Field
--- The horizontal [ScrollBar](cp.ui.ScrollBar.md).
function ScrollArea.lazy.value:horizontalScrollBar()
    return ScrollBar(self, axutils.prop(self.UI, "AXHorizontalScrollBar"))
end

--- cp.ui.ScrollArea.selectedChildrenUI <cp.prop: hs._asm.axuielement; read-only; live?>
--- Field
--- Returns the `axuielement` representing the Scroll Area Selected Children, or `nil` if not available.
function ScrollArea.lazy.prop:selectedChildrenUI()
    return axutils.prop(self.contentsUI, "AXSelectedChildren")
end

-----------------------------------------------------------------------
--
-- CONTENT UI:
--
-----------------------------------------------------------------------

--- cp.ui.ScrollArea:childrenUI(filterFn) -> hs._asm.axuielement | nil
--- Method
--- Returns the `axuielement` representing the Scroll Area Contents, or `nil` if not available.
---
--- Parameters:
---  * filterFn - The function which checks if the child matches the requirements.
---
--- Return:
---  * The `axuielement` or `nil`.
function ScrollArea:childrenUI(filterFn)
    local ui = self:contentsUI()
    if ui then
        local children
        if filterFn then
            children = axutils.childrenMatching(ui, filterFn)
        else
            children = ui:attributeValue("AXChildren")
        end
        if children then
            table.sort(children,
                function(a, b)
                    if a and b then -- Added in this to try and solve issue #950
                        local aFrame = a:frame()
                        local bFrame = b:frame()
                        if aFrame and bFrame then
                            if aFrame.y < bFrame.y then -- a is above b
                                return true
                            elseif aFrame.y == bFrame.y then
                                if aFrame.x < bFrame.x then -- a is left of b
                                    return true
                                elseif aFrame.x == bFrame.x
                                   and aFrame.w < bFrame.w then -- a starts with but finishes before b, so b must be multi-line
                                    return true
                                end
                            end
                        end
                    end
                    return false -- b is first
                end
            )
            return children
        end
    end
    return nil
end

--- cp.ui.ScrollArea.viewFrame <cp.prop:hs.geometry.rect; read-only>
--- Field
--- A `cp.prop` reporting the Scroll Area frame as a hs.geometry.rect.
function ScrollArea.lazy.prop:viewFrame()
    return self.UI:mutate(function(original)
        local ui = original()
        local hScroll = self.horizontalScrollBar:frame()
        local vScroll = self.verticalScrollBar:frame()

        local frame = ui:frame()

        if hScroll then
            frame.h = frame.h - hScroll.h
        end

        if vScroll then
            frame.w = frame.w - vScroll.w
        end
        return frame
    end)
    :monitor(self.horizontalScrollBar.frame)
    :monitor(self.verticalScrollBar.frame)
end

--- cp.ui.ScrollArea:showChild(childUI) -> self
--- Method
--- Show's a child element in a Scroll Area.
---
--- Parameters:
---  * childUI - The `hs._asm.axuielement` object of the child you want to show.
---
--- Return:
---  * Self
function ScrollArea:showChild(childUI)
    local ui = self:UI()
    if ui and childUI then
        local vFrame = self:viewFrame()
        local childFrame = childUI:frame()

        local top = vFrame.y
        local bottom = vFrame.y + vFrame.h

        local childTop = childFrame.y
        local childBottom = childFrame.y + childFrame.h

        if childTop < top or childBottom > bottom then
            -- we need to scroll
            local oFrame = self:contentsUI():frame()
            local scrollHeight = oFrame.h - vFrame.h

            local vValue
            if childTop < top or childFrame.h > vFrame.h then
                vValue = (childTop-oFrame.y)/scrollHeight
            else
                vValue = 1.0 - (oFrame.y + oFrame.h - childBottom)/scrollHeight
            end
            self.verticalScrollBar.value:set(vValue)
        end
    end
    return self
end

--- cp.ui.ScrollArea:showChildAt(index) -> self
--- Method
--- Show's a child element in a Scroll Area given a specific index.
---
--- Parameters:
---  * index - The index of the child you want to show.
---
--- Return:
---  * Self
function ScrollArea:showChildAt(index)
    local ui = self:childrenUI()
    if ui and #ui >= index then
        self:showChild(ui[index])
    end
    return self
end

--- cp.ui.ScrollArea:selectChild(childUI) -> self
--- Method
--- Select a specific child within a Scroll Area.
---
--- Parameters:
---  * childUI - The `hs._asm.axuielement` object of the child you want to select.
---
--- Return:
---  * Self
function ScrollArea:selectChild(childUI)
    if childUI then
        local parent = childUI.parent and childUI:parent()
        if parent then
            parent:setAttributeValue("AXSelectedChildren", { childUI } )
        end
    end
    return self
end

--- cp.ui.ScrollArea:selectChildAt(index) -> self
--- Method
--- Select a child element in a Scroll Area given a specific index.
---
--- Parameters:
---  * index - The index of the child you want to select.
---
--- Return:
---  * Self
function ScrollArea:selectChildAt(index)
    local ui = self:childrenUI()
    if ui and #ui >= index then
        self:selectChild(ui[index])
    end
    return self
end

--- cp.ui.ScrollArea:selectAll(childrenUI) -> self
--- Method
--- Select all children in a scroll area.
---
--- Parameters:
---  * childrenUI - A table of `hs._asm.axuielement` objects.
---
--- Return:
---  * Self
function ScrollArea:selectAll(childrenUI)
    childrenUI = childrenUI or self:childrenUI()
    if childrenUI then
        for _,clip in ipairs(childrenUI) do
            self:selectChild(clip)
        end
    end
    return self
end

--- cp.ui.ScrollArea:deselectAll() -> self
--- Method
--- Deselect all children in a scroll area.
---
--- Parameters:
---  * None
---
--- Return:
---  * Self
function ScrollArea:deselectAll()
    local contents = self:contentsUI()
    if contents then
        contents:setAttributeValue("AXSelectedChildren", {})
    end
    return self
end

--- cp.ui.ScrollArea:shiftHorizontalBy(amount) -> number
--- Method
--- Attempts to shift the horizontal scroll bar by the specified amount.
---
--- Parameters:
---  * amount - The amount to shift
---
--- Returns:
---  * The actual value of the horizontal scroll bar.
function ScrollArea:shiftHorizontalBy(amount)
    return self.horizontalScrollBar:shiftValueBy(amount)
end

--- cp.ui.ScrollArea:shiftHorizontalTo(value) -> number
--- Method
--- Attempts to shift the horizontal scroll bar to the specified value.
---
--- Parameters:
---  * value - The new value (typically between `0` and `1`).
---
--- Returns:
---  * The actual value of the horizontal scroll bar.
function ScrollArea:shiftHorizontalTo(value)
    return self.horizontalScrollBar:value(value)
end

--- cp.ui.ScrollArea:shiftVerticalBy(amount) -> number
--- Method
--- Attempts to shift the vertical scroll bar by the specified amount.
---
--- Parameters:
---  * amount - The amount to shift
---
--- Returns:
---  * The actual value of the vertical scroll bar.
function ScrollArea:shiftVerticalBy(amount)
    return self.verticalScrollBar:shiftValueBy(amount)
end

--- cp.ui.ScrollArea:shiftVerticalTo(value) -> number
--- Method
--- Attempts to shift the vertical scroll bar to the specified value.
---
--- Parameters:
---  * value - The new value (typically between `0` and `1`).
---
--- Returns:
---  * The actual value of the vertical scroll bar.
function ScrollArea:shiftVerticalTo(value)
    return self.verticalScrollBar:value(value)
end

--- cp.ui.ScrollArea:saveLayout() -> table
--- Method
--- Saves the current Scroll Area layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Scroll Area Layout.
function ScrollArea:saveLayout()
    local layout = Element.saveLayout(self)

    layout.horizontalScrollBar = self.horizontalScrollBar:saveLayout()
    layout.verticalScrollBar = self.verticalScrollBar:saveLayout()
    layout.selectedChildren = self:selectedChildrenUI()

    return layout
end

--- cp.ui.ScrollArea:loadLayout(layout) -> none
--- Method
--- Loads a Scroll Area layout.
---
--- Parameters:
---  * layout - A table containing the ScrollArea layout settings, typically created using [saveLayout](#saveLayout).
---
--- Returns:
---  * None
function ScrollArea:loadLayout(layout)
    if layout then
        self:selectAll(layout.selectedChildren)

        self.verticalScrollBar:loadLayout(layout.verticalScrollBar)
        self.horizontalScrollBar:loadLayout(layout.horizontalScrollBar)
    end
end

return ScrollArea
