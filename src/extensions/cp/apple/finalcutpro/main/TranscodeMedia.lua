--- === cp.apple.finalcutpro.main.TranscodeMedia ===
---
--- Represents the Transcode Media sheet.

local log					= require "hs.logger".new "TranscodeMedia"

local Alert                 = require "cp.ui.Alert"
local axutils               = require "cp.ui.axutils"
local Button                = require "cp.ui.Button"
local CheckBox              = require "cp.ui.CheckBox"
local StaticText            = require "cp.ui.StaticText"

local cache                 = axutils.cache
local childMatching         = axutils.childMatching
local compareTopToBottom    = axutils.compareTopToBottom

local TranscodeMedia = Alert:subclass("cp.apple.finalcutpro.main.TranscodeMedia")

--- cp.apple.finalcutpro.viewer.TranscodeMedia.matches(element) -> boolean
--- Function
--- Checks if the element is an `TranscodeMedia` instance.
---
--- Parameters:
--- * element       - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches the pattern for a `Viewer` `TranscodeMedia`.
function TranscodeMedia.matches(element)
    if Alert.matches(element) and #element == 5 then
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
    local UI = parent.primaryWindow().UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), TranscodeMedia.matches)
        end,
        TranscodeMedia.matches)
    end)
    Alert.initialize(self, parent, UI)
end

return TranscodeMedia
