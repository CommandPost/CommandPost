--- === cp.apple.finalcutpro.export.SaveSheet ===
---
--- Save Sheet

local require               = require

local axutils               = require "cp.ui.axutils"

local GoToPrompt            = require "cp.apple.finalcutpro.export.GoToPrompt"
local ReplaceAlert          = require "cp.apple.finalcutpro.export.ReplaceAlert"

local Button				= require "cp.ui.Button"
local Sheet                 = require "cp.ui.Sheet"
local TextField             = require "cp.ui.TextField"

local childFromRight	    = axutils.childFromRight
local childMatching         = axutils.childMatching

local SaveSheet = Sheet:subclass("cp.apple.finalcutpro.export.SaveSheet")

--- cp.apple.finalcutpro.export.SaveSheet.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function SaveSheet.static.matches(element)
    return Sheet.matches(element)
end

--- cp.apple.finalcutpro.export.SaveSheet(app) -> SaveSheet
--- Function
--- Creates a new SaveSheet object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new SaveSheet object.
function SaveSheet:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(original(), SaveSheet.matches)
        end,
        SaveSheet.matches)
    end)
    return Sheet.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.export.SaveSheet.save <cp.ui.Button>
--- Field
--- The "Save" `Button`.
function SaveSheet.lazy.value:save()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(original(), 1, Button.matches)
    end))
end

--- cp.apple.finalcutpro.export.SaveSheet.cancel <cp.ui.Button>
--- Field
--- The "Cancel" `Button`.
function SaveSheet.lazy.value:cancel()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(original(), 2, Button.matches)
    end))
end

--- cp.apple.finalcutpro.export.SaveSheet.filename <cp.ui.TextField>
--- Field
--- The Save Sheet Filename Text Field.
function SaveSheet.lazy.value:filename()
    return TextField(self, function()
        return childMatching(self:UI(), TextField.matches)
    end)
end

--- cp.apple.finalcutpro.export.SaveSheet:setPath(path) -> cp.apple.finalcutpro.export.SaveSheet
--- Method
--- Sets the path.
---
--- Parameters:
---  * path - The path as a string.
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.SaveSheet` object for method chaining.
function SaveSheet:setPath(path)
    if self:isShowing() then
        --------------------------------------------------------------------------------
        -- Display the 'Go To' prompt:
        --------------------------------------------------------------------------------
        local prompt = self.goToPrompt
        prompt:show():value(path)
        prompt:go()
    end
    return self
end

--- cp.apple.finalcutpro.export.SaveSheet.replaceAlert <ReplaceAlert>
--- Field
--- The Replace Alert object.
function SaveSheet.lazy.value:replaceAlert()
    return ReplaceAlert(self)
end

--- cp.apple.finalcutpro.export.SaveSheet.goToPrompt <GoToPrompt>
--- Field
--- The Go To Prompt object.
function SaveSheet.lazy.value:goToPrompt()
    return GoToPrompt(self)
end

return SaveSheet
