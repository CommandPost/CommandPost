--- === cp.apple.finalcutpro.inspector.audio.AudioConfiguration ===
---
--- The Audio Configuration section of the Audio Inspector.

local require = require

local log                               = require("hs.logger").new("audioConfiguration")

local axutils                           = require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local CheckBox                          = require("cp.ui.CheckBox")
local just                              = require("cp.just")
local MenuButton                        = require("cp.ui.MenuButton")

local Do                                = require("cp.rx.go.Do")
local If                                = require("cp.rx.go.If")
local Throw                             = require("cp.rx.go.Throw")
local Require                           = require("cp.rx.go.Require")

local sort = table.sort

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local AudioConfiguration = Element:subclass("AudioConfiguration")

function AudioConfiguration.__tostring()
    return "cp.apple.finalcutpro.inspector.audio.AudioConfiguration"
end

--- cp.apple.finalcutpro.inspector.audio.AudioConfiguration.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function AudioConfiguration.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXScrollArea"
end

--- cp.apple.finalcutpro.inspector.audio.AudioConfiguration(parent) -> AudioConfiguration
--- Function
--- Creates a new Media Import object.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new AudioConfiguration object.
function AudioConfiguration:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return axutils.cache(self, "_ui",
            function()
                local ui = original()
                if ui then
                    local splitGroup = ui[1]
                    local scrollArea = splitGroup and axutils.childWithRole(splitGroup, "AXScrollArea")
                    return AudioConfiguration.matches(scrollArea) and scrollArea or nil
                else
                    return nil
                end
            end,
            AudioConfiguration.matches
        )
    end)
    Element.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.inspector.audio.AudioConfiguration:enableCheckboxes() -> table
--- Method
--- Returns a table of `hs._asm.axuielement` objects for each enable/disable toggle.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing `hs._asm.axuielement` objects.
function AudioConfiguration.lazy.prop:enableCheckboxes()
    return self.UI:mutate(function(original)
        local ui = original()
        local children = ui and ui:children()
        local firstElement = true
        local result = {}
        local firstElementFrame = nil
        for _, child in pairs(children) do
            if firstElement then
                if child:attributeValue("AXRole") == "AXButton" then
                    table.insert(result, child)
                    firstElementFrame = child:attributeValue("AXFrame")
                    firstElement = false
                end
            else
                local childFrame = child:attributeValue("AXFrame")
                if child:attributeValue("AXRole") == "AXButton" and childFrame.w == firstElementFrame.w and childFrame.h == firstElementFrame.h then
                    table.insert(result, child)
                end
            end
        end
        return result
    end)
end


--- cp.apple.finalcutpro.inspector.audio.AudioConfiguration:show() -> self
--- Method
--- Attempts to show the bar.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `AudioConfiguration` instance.
function AudioConfiguration:show()
    self:parent():show()
    just.doUntil(self.isShowing, 5)
    return self
end

--- cp.apple.finalcutpro.inspector.audio.AudioConfiguration:doShow() -> cp.rx.go.Statement
--- Method
--- A Statement that will attempt to show the bar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, which will resolve to `true` if successful, or send an `error` if not.
function AudioConfiguration.lazy.method:doShow()
    return self:parent():doShow():Label("AudioConfiguration:doShow")
end

return AudioConfiguration
