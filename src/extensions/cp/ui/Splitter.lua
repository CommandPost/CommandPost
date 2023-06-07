--- === cp.ui.Splitter ===
---
--- Represents an `AXSplitter`.

local require                   = require

local ax                        = require "cp.fn.ax"
local Element	                = require "cp.ui.Element"

local Splitter = Element:subclass("cp.ui.Splitter")

--- cp.ui.Splitter.VERTICAL_ORIENTATION <string>
--- Constant
--- The value for `AXOrientation` when it is vertical.
Splitter.static.VERTICAL_ORIENTATION = "AXVerticalOrientation"

--- cp.ui.Splitter.HORIZONTAL_ORIENTATION <string>
--- Constant
--- The value for `AXOrientation` when it is horizontal.
Splitter.static.HORIZONTAL_ORIENTATION = "AXHorizontalOrientation"

--- cp.ui.Splitter.matches(value) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * value - The value to check.
---
--- Returns:
---  * `true` if the value matches, `false` otherwise.
Splitter.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXSplitter")

--- cp.ui.Splitter.maxValue <cp.prop: number, read-only>
--- Field
--- The maximum value of the splitter.
function Splitter.lazy.prop:maxValue()
    return ax.prop(self.UI, "AXMaxValue")
end

--- cp.ui.Splitter.minValue <cp.prop: number, read-only>
--- Field
--- The minimum value of the splitter.
function Splitter.lazy.prop:minValue()
    return ax.prop(self.UI, "AXMinValue")
end

--- cp.ui.Splitter.nextContentsUI <cp.prop: axuielementObject, read-only, live?>
--- Field
--- The `axuielementObject` for the next contents of the splitter.
function Splitter.lazy.prop:nextContentsUI()
    return ax.prop(self.UI, "AXNextContents")
end

--- cp.ui.Splitter.previousContentsUI <cp.prop: axuielementObject, read-only, live?>
--- Field
--- The `axuielementObject` for the previous contents of the splitter.
function Splitter.lazy.prop:previousContentsUI()
    return ax.prop(self.UI, "AXPreviousContents")
end

--- cp.ui.Splitter.orientation <cp.prop: string; read-only>
--- Field
--- The `AXOrientation` string.
function Splitter.lazy.prop:orientation()
    return ax.prop(self.UI, "AXOrientation")
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
    return ax.prop(self.UI, "AXValue")
end

return Splitter