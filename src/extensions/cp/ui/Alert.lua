--- === cp.ui.Alert ===
---
--- Alert UI Module.

local require = require

local axutils                       = require("cp.ui.axutils")
local Sheet                         = require("cp.ui.Sheet")
local Button                        = require("cp.ui.Button")

local If                            = require("cp.rx.go.If")
local WaitUntil                     = require("cp.rx.go.WaitUntil")


local Alert = Sheet:subclass("cp.ui.Alert")

--- cp.ui.Alert:new(app) -> Alert
--- Constructor
--- Creates a new `Alert` instance. It will automatically search the parent's children for Alerts.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `Browser` object.
function Alert:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return axutils.childMatching(original(), Alert.matches)
    end)

    Sheet.initialize(self, parent, UI)
end

return Alert
