--- === cp.apple.finalcutpro.viewer.InfoBar ===
---
--- Represents the bar of information about the [Viewer](cp.apple.finalcutpro.viewer.Viewer.md) (format, title, viewing options).
---
--- See also [ControlBar](cp.apple.finalcutpro.viewer.ControlBar.md).

local axutils           = require "cp.ui.axutils"
local Group             = require "cp.ui.Group"
local Image             = require "cp.ui.Image"
local MenuButton        = require "cp.ui.MenuButton"
local StaticText        = require "cp.ui.StaticText"

local match, sub        = string.match, string.sub

local cache             = axutils.cache
local childFromLeft     = axutils.childFromLeft
local childFromTop      = axutils.childFromTop
local childFromRight    = axutils.childFromRight
local leftToRight       = axutils.compareLeftToRight

local InfoBar = Group:subclass("cp.apple.finalcutpro.viewer.InfoBar")

--- cp.apple.finalcutpro.viewer.InfoBar.matches(element) -> boolean
--- Function
--- Checks if the element is an `InfoBar` instance.
---
--- Parameters:
--- * element       - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches the pattern for a `Viewer` `InfoBar`.
function InfoBar.matches(element)
    if Group.matches(element) and #element == 5 then
        local children = axutils.children(element, leftToRight)

        return children ~= nil
            and StaticText.matches(children[1])
            and Image.matches(children[2])
            and StaticText.matches(children[3])
            and MenuButton.matches(children[4])
            and MenuButton.matches(children[5])
    end
    return false
end

--- cp.apple.finalcutpro.viewer.InfoBar(viewer)
--- Constructor
--- Creates a new `InfoBar` instance.
---
--- Parameters:
---  * viewer       - The [Viewer](cp.apple.finalcutpro.viewer.Viewer.md) instance.
---
--- Returns:
---  * The new `InfoBar`.
function InfoBar:initialize(viewer)
    local uiFinder = viewer.UI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            return ui and childFromTop(ui, 1)
        end)
    end)

    Group.initialize(self, viewer, uiFinder)
end

--- cp.apple.finalcutpro.viewer.InfoBar.formatField <cp.ui.StaticText>
--- Field
--- The "Field" value for the current clip, as a [StaticText](cp.ui.StaticText.md)
function InfoBar.lazy.value:formatField()
    return StaticText(self, self.UI:mutate(function(original)
        return cache(self, "_format", function()
            return childFromLeft(original(), 1, StaticText.matches)
        end, StaticText.matches)
    end))
end

--- cp.apple.finalcutpro.viewer.InfoBar.format <cp.prop: number; read-only>
--- Field
--- Provides the full format text value, or `nil` if not available.
function InfoBar.lazy.prop:format()
    return self.formatField.value
end

--- cp.apple.finalcutpro.viewer.InfoBar.framerate <cp.prop: number; read-only>
--- Field
--- Provides the framerate as a number, or `nil` if not available.
function InfoBar.lazy.prop:framerate()
    return self.format:mutate(function(original)
        local formatValue = original()
        local framerate = formatValue and match(formatValue, ' %d%d%.?%d?%d?[pi]')
        return framerate and tonumber(sub(framerate, 1,-2))
    end)
end

--- cp.apple.finalcutpro.viewer.InfoBar.titleField <cp.ui.StaticText>
--- Field
--- Provides the Title of the clip in the Viewer as a [StaticText](cp.ui.StaticText.md).
function InfoBar.lazy.value:titleField()
    return StaticText(self, self.UI:mutate(function(original)
        return childFromLeft(original(), 2, StaticText.matches)
    end))
end

--- cp.apple.finalcutpro.viewer.InfoBar.title <cp.prop: string; read-only; live?>
--- Field
--- Provides the Title of the clip in the Viewer as a [StaticText](cp.ui.StaticText.md).
function InfoBar.lazy.prop:title()
    return self.titleField.value
end

--- cp.apple.finalcutpro.viewer.InfoBar:viewMenu <cp.ui.MenuButton>
--- Field
--- The [MenuButton](cp.ui.MenuButton.md) for the "View" menu.
function InfoBar.lazy.value:viewMenu()
    return MenuButton(self, self.UI:mutate(function(original)
        return childFromRight(original(), 1, MenuButton.matches)
    end))
end

--- cp.apple.finalcutpro.viewer.InfoBar:zoomwMenu <cp.ui.MenuButton>
--- Field
--- The [MenuButton](cp.ui.MenuButton.md) for the "Zoom Level" menu.
function InfoBar.lazy.value:zoomMenu()
    return MenuButton(self, self.UI:mutate(function(original)
        return childFromRight(original(), 2, MenuButton.matches)
    end))
end

return InfoBar