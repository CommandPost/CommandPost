--- === cp.ui.Dialog ===
---
--- Represents a [Window](cp.ui.Window.md) which has a `AXSubrole` of `AXDialog`.

local Window                = require "cp.ui.Window"

local Dialog = Window:subclass("cp.ui.Dialog")

function Dialog.static.matches(element)
    return Window.matches(element) and element:attributeValue("AXSubrole") == "AXDialog"
end

return Dialog