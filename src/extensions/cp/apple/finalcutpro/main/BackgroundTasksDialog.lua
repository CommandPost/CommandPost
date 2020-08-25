--- === cp.apple.finalcutpro.main.BackgroundTasksDialog ===
---
--- Represents the Background Tasks warning dialog.

--local log					= require "hs.logger".new "BackgroundTasksDialog"

local axutils               = require "cp.ui.axutils"
local Button                = require "cp.ui.Button"
local Dialog                = require "cp.ui.Dialog"
local strings               = require "cp.apple.finalcutpro.strings"

local cache                 = axutils.cache
local childFromLeft         = axutils.childFromLeft
local childMatching         = axutils.childMatching

local BackgroundTasksDialog = Dialog:subclass("cp.apple.finalcutpro.main.BackgroundTasksDialog")

--- cp.apple.finalcutpro.main.BackgroundTasksDialog.matches(element) -> boolean
--- Function
--- Checks if the element is an `BackgroundTasksDialog` instance.
---
--- Parameters:
--- * element       - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches the pattern for a `BackgroundTasksDialog``.
function BackgroundTasksDialog.static.matches(element)
    if Dialog.matches(element) and #element == 6 then
        local backgroundTasksString = strings:find("FFTranscodeMissingOpticalFlowMessageText")
        local backgroundTasks = backgroundTasksString and string.gsub(backgroundTasksString, "%%@", ".*")
        return axutils.childMatching(element, function(e)
            local value = e:attributeValue("AXValue")
            return type(value) == "string" and value:find(backgroundTasks)
        end)
    end
end

--- cp.apple.finalcutpro.main.BackgroundTasksDialog(cpApp)
--- Constructor
--- Creates a new Background Tasks [Dialog](cp.ui.Dialog.md)
function BackgroundTasksDialog:initialize(cpApp)
    Dialog.initialize(self, cpApp, cpApp.UI:mutate(function(original)
        return cache(self, "_window", function()
            return childMatching(original(), BackgroundTasksDialog.matches)
        end, BackgroundTasksDialog.matches)
    end))
end

--- cp.apple.finalcutpro.main.BackgroundTasksDialog.cancel <cp.ui.Button>
--- Field
--- The Cancel button.
function BackgroundTasksDialog.lazy.value:cancel()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_cancel", function()
            return childFromLeft(original(), 1, Button.matches)
        end, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.BackgroundTasksDialog.continue <cp.ui.Button>
--- Field
--- The Continue button.
function BackgroundTasksDialog.lazy.value:continue()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_continue", function()
            return childFromLeft(original(), 2, Button.matches)
        end, Button.matches)
    end))
end

return BackgroundTasksDialog
