--- === cp.apple.finalcutpro.main.TranscodeMedia ===
---
--- Represents the Transcode Media sheet.

--local log					= require "hs.logger".new "TranscodeMedia"

local axutils               = require "cp.ui.axutils"
local Button                = require "cp.ui.Button"
local CheckBox              = require "cp.ui.CheckBox"
local StaticText            = require "cp.ui.StaticText"
local Sheet                 = require "cp.ui.Sheet"

local cache                 = axutils.cache
local childFromLeft         = axutils.childFromLeft
local childFromTop          = axutils.childFromTop
local childMatching         = axutils.childMatching
local compareTopToBottom    = axutils.compareTopToBottom

local TranscodeMedia = Sheet:subclass("cp.apple.finalcutpro.main.TranscodeMedia")

--- cp.apple.finalcutpro.viewer.TranscodeMedia.matches(element) -> boolean
--- Function
--- Checks if the element is an `TranscodeMedia` instance.
---
--- Parameters:
--- * element       - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches the pattern for a `Viewer` `TranscodeMedia`.
function TranscodeMedia.static.matches(element)
    if Sheet.matches(element) and #element == 5 then
        local children = axutils.children(element, compareTopToBottom)
        return children ~= nil
            and StaticText.matches(children[1])
            and CheckBox.matches(children[2])
            and CheckBox.matches(children[3])
            and Button.matches(children[4])
            and Button.matches(children[5])
    end
end

--- cp.apple.finalcutpro.viewer.TranscodeMedia(viewer)
--- Constructor
--- Creates a new `TranscodeMedia` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * The new `TranscodeMedia`.
function TranscodeMedia:initialize(parent)
    local UI = parent.primaryWindow.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), TranscodeMedia.matches)
        end,
        TranscodeMedia.matches)
    end)

    Sheet.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.main.TranscodeMedia.createOptimizedMedia <cp.ui.CheckBox>
--- Field
--- The "Create Optimized Media" check box, as a [CheckBox](cp.ui.CheckBox.md)
function TranscodeMedia.lazy.value:createOptimizedMedia()
    return CheckBox(self, self.UI:mutate(function(original)
        return cache(self, "_createOptimizedMedia", function()
            return childFromTop(original(), 1, CheckBox.matches)
        end, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.main.TranscodeMedia.createProxyMedia <cp.ui.CheckBox>
--- Field
--- The "Create Proxy Media" check box, as a [CheckBox](cp.ui.CheckBox.md)
function TranscodeMedia.lazy.value:createProxyMedia()
    return CheckBox(self, self.UI:mutate(function(original)
        return cache(self, "_createProxyMedia", function()
            return childFromTop(original(), 2, CheckBox.matches)
        end, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.main.TranscodeMedia.cancel <cp.ui.Button>
--- Field
--- The "Cancel" button, as a [Button](cp.ui.Button.md)
function TranscodeMedia.lazy.value:cancel()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_cancel", function()
            return childFromTop(original(), 1, Button.matches)
        end, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.TranscodeMedia.ok <cp.ui.Button>
--- Field
--- The "OK" button, as a [Button](cp.ui.Button.md)
function TranscodeMedia.lazy.value:ok()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_ok", function()
            return childFromLeft(original(), 2, Button.matches)
        end, Button.matches)
    end))
end

return TranscodeMedia