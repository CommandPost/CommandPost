--- === cp.apple.finalcutpro.inspector.audio.AudioComponent ===
---
--- The Audio Configuration section of the Audio Inspector.

local require = require

--local log                               = require("hs.logger").new("AudioComponent")

local axutils                           = require("cp.ui.axutils")
local just                              = require("cp.just")

local Button                            = require("cp.ui.Button")
local Element                           = require("cp.ui.Element")
local ScrollArea                        = require("cp.ui.ScrollArea")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local AudioComponent = Element:subclass("cp.apple.finalcutpro.inspector.audio.AudioComponent")

--- cp.apple.finalcutpro.inspector.audio.AudioComponent.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function AudioComponent.static.matches(element)
    return ScrollArea.matches(element)
end

-- clipType(element) -> string | nil
-- Function
-- Gets the clip type.
--
-- Parameters:
--  * element - The element to check
--
-- Returns:
--  * "multicam", "compound", "standard" or `nil`
--  * A table of children
local function clipType(element)
    local children = element and element:children()
    if children then
        local topButton = axutils.childFromTop(children, 1, function(e) return e:attributeValue("AXRole") == "AXButton" end)
        local topImage = axutils.childFromTop(children, 1, function(e) return e:attributeValue("AXRole") == "AXImage" end)
        if topImage then
            local inLineWithImage = axutils.childrenInLine(topImage)
            if inLineWithImage and #inLineWithImage == 3 then
                return "multicam", inLineWithImage
            elseif inLineWithImage and #inLineWithImage == 5 then
                return "compound", inLineWithImage
            end
        end
        if topButton then
            local inLineWithButton = axutils.childrenInLine(topButton)
            if inLineWithButton and #inLineWithButton == 5 then
                return "standard", inLineWithButton
            end
        end
    end
end

--- cp.apple.finalcutpro.inspector.audio.AudioComponent(parent) -> AudioComponent
--- Function
--- Creates a new Audio Component object.
---
--- Parameters:
---  * parent - The parent object.
---  * topComponent - A boolean that defines whether or not this is a top component.
---  * componentType - "multicam", "compound" or "standard"
---  * componentIndex - The index of the component
---
--- Returns:
---  * A new AudioComponent object.
function AudioComponent:initialize(parent, topComponent, componentIndex)

    self._topComponent = topComponent
    self._componentIndex = componentIndex

    local UI = parent.UI:mutate(function(original)
        return axutils.cache(self, "_ui",
            function()
                return original()
            end,
            Element.matches
        )
    end)
    Element.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.inspector.audio.AudioComponent:enabled() -> Button
--- Method
--- Gets the enable/disable button for the component.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Button` instance.
function AudioComponent:enabled()
    return Button(self, function()
        local ui = self:UI()
        local ct = clipType(ui)
        local enabledUI
        if self._topComponent then
            --------------------------------------------------------------------------------
            -- Top Component:
            --------------------------------------------------------------------------------
            if ct == "standard" then
                enabledUI = axutils.childFromLeft(ui, 1, function(element) return element:attributeValue("AXRole") == "AXButton" end)
            end
        else
            --------------------------------------------------------------------------------
            -- Sub-component:
            --------------------------------------------------------------------------------
            if ct == "standard" then
                local children = ui and ui:children()
                local topButton = children and axutils.childFromLeft(children, 1, function(element) return element:attributeValue("AXRole") == "AXButton" end)
                local topButtonFrame = topButton and topButton:frame()
                local buttons = axutils.childrenMatching(children, function(element)
                    return element:frame().w == topButtonFrame.w and element:frame().h == topButtonFrame.h
                end)
                enabledUI = buttons[self._componentIndex + 1]
            elseif ct == "multicam" or ct == "compound" then
                local children = ui and ui:children()
                local topButton = children and axutils.childFromLeft(children, 1, function(element) return element:attributeValue("AXRole") == "AXButton" end)
                local topButtonFrame = topButton and topButton:frame()
                local buttons = axutils.childrenMatching(children, function(element)
                    return element:frame().w == topButtonFrame.w and element:frame().h == topButtonFrame.h
                end)
                enabledUI = buttons[self._componentIndex]
            end
        end
        return enabledUI
    end)
end

--- cp.apple.finalcutpro.inspector.audio.AudioComponent:show() -> self
--- Method
--- Attempts to show the bar.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `AudioComponent` instance.
function AudioComponent:show()
    self:parent():show()
    just.doUntil(self.isShowing, 5)
    return self
end

--- cp.apple.finalcutpro.inspector.audio.AudioComponent:doShow() -> cp.rx.go.Statement
--- Method
--- A Statement that will attempt to show the bar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, which will resolve to `true` if successful, or send an `error` if not.
function AudioComponent.lazy.method:doShow()
    return self:parent():doShow():Label("AudioComponent:doShow")
end

return AudioComponent
