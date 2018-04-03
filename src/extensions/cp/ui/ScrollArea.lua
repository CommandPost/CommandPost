--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.ScrollArea ===
---
--- Scroll Area Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("ScrollArea")

local axutils							= require("cp.ui.axutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ScrollArea = {}

-- TODO: Add documentation
function ScrollArea.matches(element)
    return element and element:attributeValue("AXRole") == "AXScrollArea"
end

-- TODO: Add documentation
function ScrollArea:new(parent, finderFn)
    local o = {_parent = parent, _finder = finderFn}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- TODO: Add documentation
function ScrollArea:parent()
    return self._parent
end

-- TODO: Add documentation
function ScrollArea:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- CONTENT UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function ScrollArea:UI()
    return axutils.cache(self, "_ui", function()
        return self._finder()
    end,
    ScrollArea.matches)
end

-- TODO: Add documentation
function ScrollArea:verticalScrollBarUI()
    local ui = self:UI()
    return ui and ui:attributeValue("AXVerticalScrollBar")
end

-- TODO: Add documentation
function ScrollArea:horizontalScrollBarUI()
    local ui = self:UI()
    return ui and ui:attributeValue("AXHorizontalScrollBar")
end

-- TODO: Add documentation
function ScrollArea:isShowing()
    return self:UI() ~= nil
end

-- TODO: Add documentation
function ScrollArea:contentsUI()
    local ui = self:UI()
    if ui then
        local role = ui:attributeValue("AXRole")
        if role and role == "AXScrollArea" then
            return ui:contents()[1]
        else
            --log.ef("Expected AXScrollArea, but got %s. Returning 'nil'.", role)
            return nil
        end
    else
        --log.ef("Failed to get ScrollArea:contentsUI(). Returning 'nil'.")
        return nil
    end
end

-- TODO: Add documentation
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

-- TODO: Add documentation
function ScrollArea:selectedChildrenUI()
    local ui = self:contentsUI()
    return ui and ui:selectedChildren()
end

-- TODO: Add documentation
function ScrollArea:viewFrame()
    local ui = self:UI()
    local hScroll = self:horizontalScrollBarUI()
    local vScroll = self:verticalScrollBarUI()

    local frame = ui:frame()

    if hScroll then
        frame.h = frame.h - hScroll:frame().h
    end

    if vScroll then
        frame.w = frame.w - vScroll:frame().w
    end
    return frame
end

-- TODO: Add documentation
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
            local vScroll = self:verticalScrollBarUI()
            if vScroll then
                vScroll:setAttributeValue("AXValue", vValue)
            end
        end
    end
    return self
end

-- TODO: Add documentation
function ScrollArea:showChildAt(index)
    local ui = self:childrenUI()
    if ui and #ui >= index then
        self:showChild(ui[index])
    end
    return self
end

-- TODO: Add documentation
function ScrollArea:selectChild(childUI)
    if childUI then
        childUI:parent():setAttributeValue("AXSelectedChildren", { childUI } )
    end
    return self
end

-- TODO: Add documentation
function ScrollArea:selectChildAt(index)
    local ui = self:childrenUI()
    if ui and #ui >= index then
        self:selectChild(ui[index])
    end
    return self
end

-- TODO: Add documentation
function ScrollArea:selectAll(childrenUI)
    childrenUI = childrenUI or self:childrenUI()
    if childrenUI then
        for _,clip in ipairs(childrenUI) do
            self:selectChild(clip)
        end
    end
    return self
end

-- TODO: Add documentation
function ScrollArea:deselectAll()
    local contents = self:contentsUI()
    if contents then
        contents:setAttributeValue("AXSelectedChildren", {})
    end
    return self
end

-- TODO: Add documentation
function ScrollArea:saveLayout()
    local layout = {}
    local hScroll = self:horizontalScrollBarUI()
    if hScroll then
        layout.horizontalScrollBar = hScroll:value()
    end
    local vScroll = self:verticalScrollBarUI()
    if vScroll then
        layout.verticalScrollBar = vScroll:value()
    end
    layout.selectedChildren = self:selectedChildrenUI()

    return layout
end

-- TODO: Add documentation
function ScrollArea:loadLayout(layout)
    if layout then
        self:selectAll(layout.selectedChildren)
        local vScroll = self:verticalScrollBarUI()
        if vScroll then
            vScroll:setValue(layout.verticalScrollBar)
        end
        local hScroll = self:horizontalScrollBarUI()
        if hScroll then
            hScroll:setValue(layout.horizontalScrollBar)
        end
    end
end

--- cp.ui.ScrollArea:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function ScrollArea:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return ScrollArea