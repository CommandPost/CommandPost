--- === cp.apple.finalcutpro.timeline.ToolPalette ===
---
--- Represents the Tool Palette Menu Button in the Timeline.
---
--- Extends:
--- * [MenuButton](cp.ui.MenuButton.md)

local require                   = require

-- local log                       = require "hs.logger".new "ToolPalette"

local MenuButton                = require "cp.ui.MenuButton"
local strings                   = require "cp.apple.finalcutpro.strings"

local ToolPalette = MenuButton:subclass("cp.apple.finalcutpro.timeline.ToolPalette")

-- Note: Because this button has an icon label, not text, they are all blank strings.
-- As such, we have to check the value by reading the AXHelp value of the MenuButton.
-- This gives us a localized string

--- cp.apple.finalcutpro.timeline.ToolPalette.OPTIONS <table of tables>
--- Constant
--- The options for the Tool Palette Menu Button.
---
--- Notes:
---  * Contains `SELECT`, `TRIM`, `POSITION`, `RANGE`, `BLADE`, `ZOOM`, and `HAND`.
---  * The `CommandSetID` value can be used with `cp.apple.finalcutpro:doShortcut()`.
ToolPalette.static.OPTIONS = {
    SELECT = {
        AXHelpKey = "FFArrowToolTip",
        AXIdentifier = "selectToolArrowOrRangeSelection:",
        CommandSetID = "SelectToolArrowOrRangeSelection",
    },
    TRIM = {
        AXHelpKey = "FFTrimToolTip",
        AXIdentifier = "selectToolTrim:",
        CommandSetID = "SelectToolTrim",
    },
    POSITION = {
        AXHelpKey = "FFPositionToolTip",
        AXIdentifier = "selectToolPlacement:",
        CommandSetID = "SelectToolPlacement",
    },
    RANGE = {
        AXHelpKey = "FFRangeSelectionToolTip",
        AXIdentifier = "selectToolRangeSelection:",
        CommandSetID = "SelectToolRangeSelection",
    },
    BLADE = {
        AXHelpKey = "FFBladeToolTip",
        AXIdentifier = "selectToolBlade:",
        CommandSetID = "SelectToolBlade",
    },
    ZOOM = {
        AXHelpKey = "FFZoomToolTip",
        AXIdentifier = "selectToolZoom:",
        CommandSetID = "SelectToolZoom",
    },
    HAND = {
        AXHelpKey = "FFHandToolTip",
        AXIdentifier = "selectToolHand:",
        CommandSetID = "SelectToolHand",
    },
}

-- findOption(axHelp) -> table | nil
-- Function
-- Returns the option for the given AXHelp value.
--
-- Parameters:
--  * axHelp - The AXHelp value to find.
--
-- Returns:
--  * The option for the given AXHelp value.
function ToolPalette.static.findOption(axHelp)
    for _, option in pairs(ToolPalette.OPTIONS) do
        local helpValue = strings:find(option.AXHelpKey)
        -- check if axHelp starts with the helpValue
        if axHelp:sub(1, #helpValue) == helpValue then
            return option
        end
    end
end

--- cp.apple.finalcutpro.timeline.ToolPalette.value <cp.prop: ToolPalette.OPTIONS, live?, read-write>
--- Field
--- A `cp.prop` containing the current [OPTIONS](#OPTIONS) value of the Tool Palette. May be `nil` if the toolbar is not available.
function ToolPalette.lazy.prop:value()
    -- mutate the UI
    return self.UI:mutate(
        function(original)
            local ui = original()
            if ui then
                return ToolPalette.findOption(ui.AXHelp)
            end
        end,
        -- when setting, match the option table to the menu that matches the AXIdentifier
        function(newValue, original)
            local ui = original()
            if not ui then return end

            local currentValue = original:get()
            if currentValue == newValue then return end

            local items = ui:performAction("AXPress")[1]
            if not items then return end

            local valueIdentifier = newValue.AXIdentifier
            for _, item in ipairs(items.AXChildren) do
                if item.AXIdentifier == valueIdentifier then
                    item:performAction("AXPress")
                    return
                end
            end
            items:performAction("AXCancel")
        end
    )
    -- if anyone starts watching, then register with the app notifier.
    :preWatch(function(_,thisProp)
        self:app():notifier():watchFor("AXMenuItemSelected", function()
            thisProp:update()
        end)
    end)
end

--- cp.apple.finalcutpro.timeline.ToolPalette.isSelect <cp.prop: boolean>
--- Field
--- A `cp.prop` that indicates if the Tool Palette is set to the `SELECT` option.
function ToolPalette.lazy.prop:isSelect()
    return self.value:mutate(
        function(original)
            return original() == ToolPalette.OPTIONS.SELECT
        end,
        function(newValue, original)
            if newValue then
                original:set(ToolPalette.OPTIONS.SELECT)
            end
        end
    )
end

--- cp.apple.finalcutpro.timeline.ToolPalette.isTrim <cp.prop: boolean>
--- Field
--- A `cp.prop` that indicates if the Tool Palette is set to the `TRIM` option.
function ToolPalette.lazy.prop:isTrim()
    return self.value:mutate(
        function(original)
            return original() == ToolPalette.OPTIONS.TRIM
        end,
        function(newValue, original)
            if newValue then
                original:set(ToolPalette.OPTIONS.TRIM)
            end
        end
    )
end

--- cp.apple.finalcutpro.timeline.ToolPalette.isPosition <cp.prop: boolean>
--- Field
--- A `cp.prop` that indicates if the Tool Palette is set to the `POSITION` option.
function ToolPalette.lazy.prop:isPosition()
    return self.value:mutate(
        function(original)
            return original() == ToolPalette.OPTIONS.POSITION
        end,
        function(newValue, original)
            if newValue then
                original:set(ToolPalette.OPTIONS.POSITION)
            end
        end
    )
end

--- cp.apple.finalcutpro.timeline.ToolPalette.isRange <cp.prop: boolean>
--- Field
--- A `cp.prop` that indicates if the Tool Palette is set to the `RANGE` option.
function ToolPalette.lazy.prop:isRange()
    return self.value:mutate(
        function(original)
            return original() == ToolPalette.OPTIONS.RANGE
        end,
        function(newValue, original)
            if newValue then
                original:set(ToolPalette.OPTIONS.RANGE)
            end
        end
    )
end

--- cp.apple.finalcutpro.timeline.ToolPalette.isBlade <cp.prop: boolean>
--- Field
--- A `cp.prop` that indicates if the Tool Palette is set to the `BLADE` option.
function ToolPalette.lazy.prop:isBlade()
    return self.value:mutate(
        function(original)
            return original() == ToolPalette.OPTIONS.BLADE
        end,
        function(newValue, original)
            if newValue then
                original:set(ToolPalette.OPTIONS.BLADE)
            end
        end
    )
end

--- cp.apple.finalcutpro.timeline.ToolPalette.isZoom <cp.prop: boolean>
--- Field
--- A `cp.prop` that indicates if the Tool Palette is set to the `ZOOM` option.
function ToolPalette.lazy.prop:isZoom()
    return self.value:mutate(
        function(original)
            return original() == ToolPalette.OPTIONS.ZOOM
        end,
        function(newValue, original)
            if newValue then
                original:set(ToolPalette.OPTIONS.ZOOM)
            end
        end
    )
end

--- cp.apple.finalcutpro.timeline.ToolPalette.isHand <cp.prop: boolean>
--- Field
--- A `cp.prop` that indicates if the Tool Palette is set to the `HAND` option.
function ToolPalette.lazy.prop:isHand()
    return self.value:mutate(
        function(original)
            return original() == ToolPalette.OPTIONS.HAND
        end,
        function(newValue, original)
            if newValue then
                original:set(ToolPalette.OPTIONS.HAND)
            end
        end
    )
end

return ToolPalette