--- === cp.ui.ScrollBar ===
---
--- Provides access to `AXScrollBar` `axuielement` values.

local log	                    = require "hs.logger" .new "ScrollBar"

local axutils	                = require "cp.ui.axutils"
local Element	                = require "cp.ui.Element"

local ScrollBar = Element:subclass("cp.ui.ScrollBar")

--- cp.ui.ScrollBar.VERTICAL_ORIENTATION <string>
--- Constant
--- The value for `AXOrientation` when it is vertical.
ScrollBar.static.VERTICAL_ORIENTATION = "AXVerticalOrientation"

--- cp.ui.ScrollBar.HORIZONTAL_ORIENTATION <string>
--- Constant
--- The value for `AXOrientation` when it is horizontal.
ScrollBar.static.HORIZONTAL_ORIENTATION = "AXHorizontalOrientation"

--- cp.ui.ScrollBar.matches(element) -> boolean
--- Method
--- Checks if the element is a `ScrollBar`.
---
--- Parameters:
--- * element - The `axuielement` being matched.
---
--- Returns:
--- * `true` if matches, otherwise `false`.
function ScrollBar.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXScrollBar"
end

--- cp.ui.ScrollBar(parent, uiFinder) -> cp.ui.ScrollBar
--- Constructor
--- Creates a new `ScrollBar` instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - the parent object.
--- * uiFinder - a `function` or `cp.prop` that provides the `AXScrollBar` `axuielement`.
---
--- Returns:
--- * The new `ScrollBar`.

--- cp.ui.ScrollBar.orientation <cp.prop: string; read-only>
--- Field
--- The `AXOrientation` string.
function ScrollBar.lazy.prop:orientation()
    return axutils.prop(self.UI, "AXOrientation")
end

--- cp.ui.ScrollBar.vertical <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the `ScrollBar` is vertical, otherwise `false`.
function ScrollBar.lazy.prop:vertical()
    return self.orientation:mutate(function(original)
        return original() == ScrollBar.VERTICAL_ORIENTATION
    end)
end

--- cp.ui.ScrollBar.horizontal <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the `ScrollBar` is horizontal, otherwise `false`.
function ScrollBar.lazy.prop:horizontal()
    return self.orientation:mutate(function(original)
        return original() == ScrollBar.HORIZONTAL_ORIENTATION
    end)
end

--- cp.ui.ScrollBar.hidden <cp.prop: boolean; read-only, live?>
--- Field
--- Is `true` if the `ScrollBar` is currently hidden.
function ScrollBar.lazy.prop:hidden()
    return axutils.prop(self.UI, "AXHidden")
end

--- cp.ui.ScrollBar.value <cp.prop: number; live?>
--- Field
--- Is the numeric scroll value, typically between `0.0` and `1.0`. May be set.
function ScrollBar.lazy.prop:value()
    return axutils.prop(self.UI, "AXValue", true)
end

--- cp.ui.ScrollBar:saveLayout() -> table
--- Method
--- Saves the `ScrollBar` layout configuration.
---
--- Returns:
--- * a `table` with the configuration parameters.
function ScrollBar:saveLayout()
    local layout = Element.saveLayout(self)
    layout.value = self:value()
    return layout
end

--- cp.ui.ScrollBar:loadLayout(layout)
--- Method
--- Loads the provided `layout` table of configuration parameters.
---
--- Parameters:
--- * layout - the table of parameters.
function ScrollBar:loadLayout(layout)
    layout = layout or {}
    if layout.value then
        log.df("ScrollBar:loadLayout: setting value to %d", layout.value)
        self.value:set(layout.value)
    end
end

return ScrollBar