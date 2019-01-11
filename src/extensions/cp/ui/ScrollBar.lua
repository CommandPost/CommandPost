--- === cp.ui.ScrollBar ===
---
--- Provides access to `AXScrollBar` `axuielement` values.

local log	                    = require "hs.logger" .new "ScrollBar"

local axutils	                = require "cp.ui.axutils"
local Element	                = require "cp.ui.Element"

local ScrollBar = Element:subclass("cp.ui.ScrollBar")

ScrollBar.static.VERTICAL_ORIENTATION = "AXVerticalOrientation"
ScrollBar.static.HORIZONTAL_ORIENTATION = "AXHorizontalOrientation"

function ScrollBar.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXScrollBar"
end

function ScrollBar:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
end

function ScrollBar.lazy.prop:orientation()
    return axutils.prop(self.UI, "AXOrientation")
end

function ScrollBar.lazy.prop:vertical()
    return self.orientation:mutate(function(original)
        return original() == ScrollBar.VERTICAL_ORIENTATION
    end)
end

function ScrollBar.lazy.prop:horizontal()
    return self.orientation:mutate(function(original)
        return original() == ScrollBar.HORIZONTAL_ORIENTATION
    end)
end

function ScrollBar.lazy.prop:hidden()
    return axutils.prop(self.UI, "AXHidden")
end

function ScrollBar.lazy.prop:value()
    return axutils.prop(self.UI, "AXValue", true)
end

function ScrollBar:saveLayout()
    local layout = Element.saveLayout(self)
    layout.value = self:value()
    return layout
end

function ScrollBar:loadLayout(layout)
    layout = layout or {}
    if layout.value then
        log.df("ScrollBar:loadLayout: setting value to %d", layout.value)
        self.value:set(layout.value)
    end
end

return ScrollBar