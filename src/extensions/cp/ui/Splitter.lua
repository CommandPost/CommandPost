--- === cp.ui.Splitter ===
---
--- Represents an `AXSplitter`.

local axutils	                = require "cp.ui.axutils"
local Element	                = require "cp.ui.Element"

local Splitter = Element:subclass("cp.ui.Element")

--- cp.ui.Splitter.VERTICAL_ORIENTATION <string>
--- Constant
--- The value for `AXOrientation` when it is vertical.
Splitter.static.VERTICAL_ORIENTATION = "AXVerticalOrientation"

--- cp.ui.Splitter.HORIZONTAL_ORIENTATION <string>
--- Constant
--- The value for `AXOrientation` when it is horizontal.
Splitter.static.HORIZONTAL_ORIENTATION = "AXHorizontalOrientation"


function Splitter.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXSplitter"
end

function Splitter.lazy.prop:maxValue()
    return axutils.prop(self.UI, "AXMaxValue")
end

function Splitter.lazy.prop:minValue()
    return axutils.prop(self.UI, "AXMinValue")
end

function Splitter.lazy.prop:nextContentsUI()
    return axutils.prop(self.UI, "AXNextContents")
end

function Splitter.lazy.prop:previousContentsUI()
    return axutils.prop(self.UI, "AXPreviousContents")
end

--- cp.ui.Splitter.orientation <cp.prop: string; read-only>
--- Field
--- The `AXOrientation` string.
function Splitter.lazy.prop:orientation()
    return axutils.prop(self.UI, "AXOrientation")
end

--- cp.ui.Splitter.vertical <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the `Splitter` is vertical, otherwise `false`.
function Splitter.lazy.prop:vertical()
    return self.orientation:mutate(function(original)
        return original() == Splitter.VERTICAL_ORIENTATION
    end)
end

--- cp.ui.Splitter.horizontal <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the `Splitter` is horizontal, otherwise `false`.
function Splitter.lazy.prop:horizontal()
    return self.orientation:mutate(function(original)
        return original() == Splitter.HORIZONTAL_ORIENTATION
    end)
end

function Splitter.lazy.prop:value()
    return axutils.prop(self.UI, "AXValue")
end

return Splitter