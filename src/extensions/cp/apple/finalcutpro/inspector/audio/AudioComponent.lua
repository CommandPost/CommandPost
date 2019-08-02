--- === cp.apple.finalcutpro.inspector.audio.AudioComponent ===
---
--- The Audio Configuration section of the Audio Inspector.

local require = require

--local log                               = require("hs.logger").new("AudioComponent")

local axutils                           = require("cp.ui.axutils")
local just                              = require("cp.just")

local Button                            = require("cp.ui.Button")
local Element                           = require("cp.ui.Element")
local Image                             = require("cp.ui.Image")
local MenuButton                        = require("cp.ui.MenuButton")
local ScrollArea                        = require("cp.ui.ScrollArea")

local cache                             = axutils.cache
local childFromLeft                     = axutils.childFromLeft
local childFromRight                    = axutils.childFromRight
local childFromTop                      = axutils.childFromTop
local childrenInLine                    = axutils.childrenInLine
local childrenMatching                  = axutils.childrenMatching
local childrenWithRole                  = axutils.childrenWithRole

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
--  * A string with "multicam", "compound", "standard" or `nil` if no clip type detected.
local function clipType(element)
    local children = element and element:children()
    if children then
        local topButton = childFromTop(children, 1, Button.matches)
        local topImage = childFromTop(children, 1, Image.matches)
        if topImage then
            local inLineWithImage = childrenInLine(topImage)
            if inLineWithImage and #inLineWithImage == 3 then
                return "multicam"
            elseif inLineWithImage and #inLineWithImage == 5 then
                return "compound"
            end
        end
        if topButton then
            local inLineWithButton = childrenInLine(topButton)
            if inLineWithButton and #inLineWithButton == 5 then
                return "standard"
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
---  * subcomponent - A boolean that defines whether or not this is a subcomponent.
---  * componentType - "multicam", "compound" or "standard"
---  * index - The index of the component
---
--- Returns:
---  * A new AudioComponent object.
function AudioComponent:initialize(parent, subcomponent, index)
    self._subcomponent = subcomponent
    self._index = index

    local UI = parent.UI:mutate(function(original)
        return cache(self, "_ui",
            function()
                return original()
            end,
            Element.matches
        )
    end)
    Element.initialize(self, parent, UI)
end

-- getRow(ui, subcomponent, ct, index) -> table | nil
-- Function
-- Gets a table of UI elements in a specific row.
--
-- Parameters:
-- * None
--
-- Returns:
-- * A table of `axuielementObject` objects or `nil`.
local function getRow(ui, subcomponent, ct, index)
    if subcomponent then
        --------------------------------------------------------------------------------
        -- Subcomponent:
        --------------------------------------------------------------------------------
        if ct == "standard" then
            local children = ui and ui:children()
            local topButton = children and childFromLeft(children, 1, Button.matches)
            local topButtonFrame = topButton and topButton:frame()
            local buttons = childrenMatching(children, function(element)
                return element:frame().w == topButtonFrame.w and element:frame().h == topButtonFrame.h
            end)
            return buttons and buttons[index + 1] and childrenInLine(buttons[index + 1])
        elseif ct == "multicam" then
            local children = ui and ui:children()
            local buttons = children and childrenWithRole(children, "AXButton")
            if buttons then
                local rows = {}
                for _, child in pairs(buttons) do
                    local inLineWithButton = childrenInLine(child)
                    if #inLineWithButton == 6 then
                        table.insert(rows, inLineWithButton)
                    end
                end
                return rows[index]
            end
        elseif ct == "compound" then
            local children = ui and ui:children()
            local buttons = children and childrenWithRole(children, "AXButton")
            if buttons then
                local rows = {}
                for _, child in pairs(buttons) do
                    local inLineWithButton = childrenInLine(child)
                    if #inLineWithButton ~= 3 and #inLineWithButton ~= 5 then
                        table.insert(rows, inLineWithButton)
                    end
                end
                return rows[index]
            end
        end
    else
        --------------------------------------------------------------------------------
        -- Component:
        --------------------------------------------------------------------------------
        if ct == "standard" and index == 1 then
            local topButton = childFromTop(ui, 1, Button.matches)
            return topButton and childrenInLine(topButton)
        elseif ct == "multicam" then
            local children = ui and ui:children()
            local buttons = children and childrenWithRole(children, "AXButton")
            if buttons then
                local rows = {}
                for _, child in pairs(buttons) do
                    local inLineWithButton = childrenInLine(child)
                    if #inLineWithButton == 3 then
                        table.insert(rows, inLineWithButton)
                    end
                end
                return rows[index]
            end
        elseif ct == "compound" then
            local children = ui and ui:children()
            local buttons = children and childrenWithRole(children, "AXButton")
            if buttons then
                local rows = {}
                for _, child in pairs(buttons) do
                    local inLineWithButton = childrenInLine(child)
                    if #inLineWithButton == 3 then
                        table.insert(rows, inLineWithButton)
                    elseif #inLineWithButton == 5 then
                        table.insert(rows, 1, inLineWithButton)
                    end
                end
                return rows[index]
            end
        end
    end
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
        local ui                = self:UI()
        local subcomponent      = self._subcomponent
        local ct                = clipType(ui)
        local index             = self._index
        local row               = getRow(ui, subcomponent, ct, index)
        if row then
            if self._subcomponent then
                --------------------------------------------------------------------------------
                -- Subcomponent:
                --------------------------------------------------------------------------------
                if ct == "standard" then
                    return childFromLeft(row, 1, Button.matches)
                elseif ct == "multicam" then
                    return childFromLeft(row, 1, Button.matches)
                elseif ct == "compound" then
                    return childFromLeft(row, 1, Button.matches)
                end
            else
                --------------------------------------------------------------------------------
                -- Component:
                --------------------------------------------------------------------------------
                if ct == "standard" then
                    return childFromLeft(row, 1, Button.matches)
                elseif ct == "multicam" then
                    return childFromLeft(row, 1, Button.matches)
                elseif ct == "compound" and index ~= 1 then
                    return childFromLeft(row, 1, Button.matches)
                end
            end
        end
    end)
end

--- cp.apple.finalcutpro.inspector.audio.AudioComponent:channels() -> MenuButton
--- Method
--- Gets the channels popup menu button for the component. This only works for
--- "Standard" clip types.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `MenuButton` instance.
function AudioComponent:channels()
    return MenuButton(self, function()
        local ui                = self:UI()
        local subcomponent      = self._subcomponent
        local ct                = clipType(ui)
        local index             = self._index
        local row               = getRow(ui, subcomponent, ct, index)
        if row and ct == "standard" and index == 1 then
            return childFromRight(row, 1, MenuButton.matches)
        end
    end)
end

--- cp.apple.finalcutpro.inspector.audio.AudioComponent:showAs() -> MenuButton
--- Method
--- Gets the subroles popup menu button for the component. This only works for
--- Compound Clips.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `MenuButton` instance.
function AudioComponent:showAs()
    return MenuButton(self, function()
        local ui                = self:UI()
        local subcomponent      = self._subcomponent
        local ct                = clipType(ui)
        local index             = self._index
        local row               = getRow(ui, subcomponent, ct, index)
        if row and ct == "compound" and index == 1 then
            return childFromRight(row, 1, MenuButton.matches)
        end
    end)
end

--- cp.apple.finalcutpro.inspector.audio.AudioComponent:role() -> MenuButton
--- Method
--- Gets the role popup menu button for the subcomponent. This only works for
--- Standard Clips.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `MenuButton` instance.
function AudioComponent:role()
    return MenuButton(self, function()
        local ui                = self:UI()
        local subcomponent      = self._subcomponent
        local ct                = clipType(ui)
        local index             = self._index
        local row               = getRow(ui, subcomponent, ct, index)
        if row and self._subcomponent and ct == "standard" then
            return childFromRight(row, 1, MenuButton.matches)
        end
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
