--- === cp.apple.finalcutpro.export.ReplaceAlert ===
---
--- Replace Alert

local require           = require

local axutils						= require "cp.ui.axutils"
local Sheet                         = require "cp.ui.Sheet"
local TextField                     = require "cp.ui.TextField"

local cache                         = axutils.cache
local childMatching                 = axutils.childMatching

local ReplaceAlert = Sheet:subclass("cp.apple.finalcutpro.export.ReplaceAlert")

--- cp.apple.finalcutpro.export.ReplaceAlert.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ReplaceAlert.static.matches(element)
    if Sheet.matches(element) then
        return childMatching(element, TextField.matches) == nil 	-- with no text fields
    end
    return false
end

--- cp.apple.finalcutpro.export.ReplaceAlert(app) -> ReplaceAlert
--- Constructor
--- Creates a new Replace Alert object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new ReplaceAlert object.
function ReplaceAlert:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), ReplaceAlert.matches)
        end,
        ReplaceAlert.matches)
    end)

    Sheet.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.export.ReplaceAlert:pressReplace() -> cp.apple.finalcutpro.export.ReplaceAlert
--- Method
--- Presses the Replace button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ReplaceAlert` object for method chaining.
function ReplaceAlert:pressReplace()
    return self:pressDefault()
end

return ReplaceAlert
