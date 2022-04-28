--- === cp.ui.ScrollArea ===
---
--- A `ScrollArea` represents an `AXScrollArea`. They primarily function as a "portal"
--- to view a larger area of the contained `axuielement` within (accessed via the `AXContents` attribute),
--- and also provide access to the vertical and horizontal scroll bars (accessed via the
--- `verticalScrollBar` and `horizontalScrollBar` properties).
---
--- The class that wraps the `AXContents` attribute can be provided via the `contentsInit` parameter in the
--- constructor. If not provided it defaults to [Element](cp.ui.Element.md).
---
--- The `ScrollArea` also delegates to the `contents` property, so you can access
--- any properties of the contained [Element](cp.ui.Element.md) directly.
---
--- For example, if you have a `ScrollArea` with a `contents` of a [TextField](cp.ui.TextField.md),
--- you can normally access the text value via the [TextField.value](cp.ui.TextField.md#value) property.
--- However, if you want to access the text value via the `ScrollArea` itself, you can do so
--- via the `ScrollArea.value` property, like so:
---
--- ```lua
--- local scrollArea = ScrollArea(parent, ui, TextArea)
--- -- via `contents`:
--- local value = scrollArea.contents:value()
--- --- via delegation:
--- local value = scrollArea:value()
--- ```
---
--- It also has a [Builder](cp.ui.ScrollArea.Builder.md) that supports customising an `Element` [Builder](cp.ui.Builder.md)
--- to create a `ScrollArea` with a specified `contents` `Element` type. For example, another way to
--- define our `ScrollArea` that contains a `TextField` is:
---
--- ```lua
--- local scrollAreaWithTextField = ScrollArea:containing(TextField)
--- local scrollArea = scrollAreaWithTextField(parent, ui)
--- ```
---
--- The main advantage of this style is that you can pass the `Builder` in to other `Element` types
--- that require an "`Element` init" that will only be provided a parent and UI finder.
---
--- This is a subclass of [Element](cp.ui.Element.md).

local require                           = require

local fn                                = require "cp.fn"
local ax                                = require "cp.fn.ax"

local Element                           = require "cp.ui.Element"
local ScrollBar                         = require "cp.ui.ScrollBar"
local delegator                         = require "cp.delegator"

local chain, pipe                       = fn.chain, fn.pipe
local ifilter, sort                     = fn.table.ifilter, fn.table.sort

local ScrollArea = Element:subclass("cp.ui.ScrollArea")
    :include(delegator):delegateTo("contents")
    :defineBuilder("containing")

--- === cp.ui.ScrollArea.Builder ===
---
--- [Builder](cp.ui.Builder.md) class for [ScrollArea](cp.ui.ScrollArea.lua).

--- cp.ui.ScrollArea.Builder:containing(contentBuilder) -> cp.ui.ScrollArea.Builder
--- Method
--- Sets the content `Element` type/builder to the specified value.
---
--- Parameters:
---  * contentBuilder - A `callable` that accepts a `parent` and `uiFinder` parameter, and returns an `Element` instance.
---
--- Returns:
---  * The `Builder` instance.

--- cp.ui.ScrollArea:containing(elementInit) -> cp.ui.ScrollArea.Builder
--- Function
--- A static method that returns a new `ScrollArea.Builder`.
---
--- Parameters:
---  * elementInit - An `Element` initializer.
---
--- Returns:
---  * A new `ScrollArea.Builder` instance.

-----------------------------------------------------------------------
-- cp.ui.ScrollArea
-----------------------------------------------------------------------

--- cp.ui.ScrollArea.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
ScrollArea.static.matches = fn.all(Element.matches, ax.hasRole "AXScrollArea")

--- cp.ui.ScrollArea(parent, uiFinder[, contentsInit]) -> cp.ui.ScrollArea
--- Constructor
--- Creates a new `ScrollArea`.
---
--- Parameters:
---  * parent       - The parent object.
---  * uiFinder     - A `function` or `cp.prop` which will return the `hs.axuielement` when available.
---  * contentsInit - An optional function to initialise the `contentsUI`. Uses `cp.ui.Element` by default.
---
--- Returns:
---  * The new `ScrollArea`.
function ScrollArea:initialize(parent, uiFinder, contentsInit)
    Element.initialize(self, parent, uiFinder)
    self.contentsInit = contentsInit or Element
end

--- cp.ui.ScrollArea.contentsUI <cp.prop: hs.axuielement; read-only; live?>
--- Field
--- Returns the `axuielement` representing the Scroll Area Contents, or `nil` if not available.
function ScrollArea.lazy.prop:contentsUI()
    return self.UI:mutate(chain // ax.attribute "AXContents" >> fn.table.first)
end

--- cp.ui.ScrollArea.contents <cp.ui.Element>
--- Field
--- Returns the `Element` representing the `ScrollArea` Contents.
function ScrollArea.lazy.value:contents()
    return self.contentsInit(self, self.contentsUI)
end

--- cp.ui.ScrollArea.verticalScrollBar <cp.ui.ScrollBar>
--- Field
--- The vertical [ScrollBar](cp.ui.ScrollBar.md).
function ScrollArea.lazy.value:verticalScrollBar()
    return ScrollBar(self, ax.prop(self.UI, "AXVerticalScrollBar"))
end

--- cp.ui.ScrollArea.horizontalScrollBar <cp.ui.ScrollBar>
--- Field
--- The horizontal [ScrollBar](cp.ui.ScrollBar.md).
function ScrollArea.lazy.value:horizontalScrollBar()
    return ScrollBar(self, ax.prop(self.UI, "AXHorizontalScrollBar"))
end

--- cp.ui.ScrollArea.selectedChildrenUI <cp.prop: hs.axuielement; read-only; live?>
--- Field
--- Returns the `axuielement` representing the Scroll Area Selected Children, or `nil` if not available.
function ScrollArea.lazy.prop:selectedChildrenUI()
    return ax.prop(self.contentsUI, "AXSelectedChildren")
end

-----------------------------------------------------------------------
--
-- CONTENT UI:
--
-----------------------------------------------------------------------

--- cp.ui.ScrollArea:childrenUI(filterFn) -> hs.axuielement | nil
--- Method
--- Returns the list of `axuielement`s representing the Scroll Area Contents, sorted top-down, or `nil` if not available.
---
--- Parameters:
---  * filterFn - The function which checks if the child matches the requirements.
---
--- Return:
---  * The `axuielement` or `nil`.
function ScrollArea:childrenUI(filterFn)
    local finder = chain //
        fn.constant(self.contentsUI) >>
        ax.children >>
        ifilter(filterFn) >>
        sort(ax.topDown)
    return finder()
end

--- cp.ui.ScrollArea.viewFrame <cp.prop:table; read-only>
--- Field
--- A `cp.prop` reporting the Scroll Area frame as a table containing `{x, y, w, h}`.
function ScrollArea.lazy.prop:viewFrame()
    return self.UI:mutate(function(original)
        local ui = original()
        local hScroll = self.horizontalScrollBar:frame()
        local vScroll = self.verticalScrollBar:frame()

        local frame = ui:attributeValue("AXFrame")

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
---  * childUI - The `hs.axuielement` object of the child you want to show.
---
--- Return:
---  * Self
function ScrollArea:showChild(childUI)
    local ui = self:UI()
    if ui and childUI then
        local vFrame = self:viewFrame()
        local childFrame = childUI.AXFrame

        local top = vFrame.y
        local bottom = vFrame.y + vFrame.h

        local childTop = childFrame.y
        local childBottom = childFrame.y + childFrame.h

        if childTop < top or childBottom > bottom then
            -- we need to scroll
            local oFrame = self:contentsUI().AXFrame
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
---  * childUI - The `hs.axuielement` object of the child you want to select.
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
---  * childrenUI - A table of `hs.axuielement` objects.
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

        Element.loadLayout(layout)
    end
end

return ScrollArea
