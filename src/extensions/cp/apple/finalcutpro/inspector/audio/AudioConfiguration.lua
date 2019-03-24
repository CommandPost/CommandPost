--- === cp.apple.finalcutpro.inspector.audio.AudioConfiguration ===
---
--- The Audio Configuration section of the Audio Inspector.

local require = require

local log                               = require("hs.logger").new("audioConfiguration")

local axutils                           = require("cp.ui.axutils")
local just                              = require("cp.just")

local ScrollArea                        = require("cp.ui.ScrollArea")

local AudioComponent                    = require("cp.apple.finalcutpro.inspector.audio.AudioComponent")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local AudioConfiguration = ScrollArea:subclass("cp.apple.finalcutpro.inspector.audio.AudioConfiguration")

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
    return ScrollArea.matches(element)
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
    ScrollArea.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.inspector.audio.AudioConfiguration:component() -> table
--- Method
--- Returns a table of `AudioComponent` objects for all main audio components.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing `AudioComponent` objects.
function AudioConfiguration:component(index)
    if type(index) ~= "number" then
        log.ef("component: index needs to be a valid number.")
    else
        return AudioComponent(self, false, index)
    end
end

--- cp.apple.finalcutpro.inspector.audio.AudioConfiguration:subcomponent() -> table
--- Method
--- Returns a table of `AudioComponent` objects for all audio subcomponents.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing `AudioComponent` objects.
function AudioConfiguration:subcomponent(index)
    if type(index) ~= "number" then
        log.ef("subcomponent: index needs to be a valid number.")
    else
        return AudioComponent(self, true, index)
    end
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
