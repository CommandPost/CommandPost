--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.ColorBoard ===
---
--- Color Board Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                = require("hs.logger").new("colorBoard")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop                              = require("cp.prop")
local axutils                           = require("cp.ui.axutils")

local Button                            = require("cp.ui.Button")
local RadioGroup                        = require("cp.ui.RadioGroup")

local Aspect                            = require("cp.apple.finalcutpro.inspector.color.ColorBoardAspect")

local id                                = require("cp.apple.finalcutpro.ids") "ColorBoard"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorBoard = {}

local CORRECTION_TYPE                   = "Color Board"

--- cp.apple.finalcutpro.inspector.color.ColorBoard.aspect -> table
--- Constant
--- A table containing tables of all the aspect panel settings
ColorBoard.aspect                       = {"color", "saturation", "exposure"}

--- cp.apple.finalcutpro.inspector.color.ColorBoard.aspect.color -> table
--- Constant
--- A table containing the Color Board Color panel settings
ColorBoard.aspect.color                 = {
    id                                  = 1,
    reset                               = id "ColorReset",
    global                              = { puck = id "ColorGlobalPuck", pct = id "ColorGlobalPct", angle = id "ColorGlobalAngle"},
    shadows                             = { puck = id "ColorShadowsPuck", pct = id "ColorShadowsPct", angle = id "ColorShadowsAngle"},
    midtones                            = { puck = id "ColorMidtonesPuck", pct = id "ColorMidtonesPct", angle = id "ColorMidtonesAngle"},
    highlights                          = { puck = id "ColorHighlightsPuck", pct = id "ColorHighlightsPct", angle = id "ColorHighlightsAngle"}
}

--- cp.apple.finalcutpro.inspector.color.ColorBoard.aspect.saturation -> table
--- Constant
--- A table containing the Color Board Saturation panel settings
ColorBoard.aspect.saturation            = {
    id                                  = 2,
    reset                               = id "SatReset",
    global                              = { puck = id "SatGlobalPuck", pct = id "SatGlobalPct"},
    shadows                             = { puck = id "SatShadowsPuck", pct = id "SatShadowsPct"},
    midtones                            = { puck = id "SatMidtonesPuck", pct = id "SatMidtonesPct"},
    highlights                          = { puck = id "SatHighlightsPuck", pct = id "SatHighlightsPct"}
}

--- cp.apple.finalcutpro.inspector.color.ColorBoard.aspect.exposure -> table
--- Constant
--- A table containing the Color Board Exposure panel settings
ColorBoard.aspect.exposure              = {
    id                                  = 3,
    reset                               = id "ExpReset",
    global                              = { puck = id "ExpGlobalPuck", pct = id "ExpGlobalPct"},
    shadows                             = { puck = id "ExpShadowsPuck", pct = id "ExpShadowsPct"},
    midtones                            = { puck = id "ExpMidtonesPuck", pct = id "ExpMidtonesPct"},
    highlights                          = { puck = id "ExpHighlightsPuck", pct = id "ExpHighlightsPct"}
}

--- cp.apple.finalcutpro.inspector.color.ColorBoard.currentAspect -> string
--- Variable
--- The current aspect as a string.
ColorBoard.currentAspect = "*"

--- cp.apple.finalcutpro.inspector.color.ColorBoard.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Color Board or not
---
--- Parameters:
---  * `element`    - The element you want to check
---
--- Returns:
---  * `true` if the `element` is a Color Board otherwise `false`
function ColorBoard.matches(element)
    return ColorBoard.matchesCurrent(element) or ColorBoard.matchesOriginal(element)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard.matchesOriginal(element) -> boolean
--- Function
--- Checks to see if a GUI element is the 'original' (pre-10.4) Color Board.
---
--- Parameters:
---  * `element`    - The element you want to check
---
--- Returns:
---  * `true` if the `element` is a pre-10.4 Color Board otherwise `false`
function ColorBoard.matchesOriginal(element)
    if element then
        local group = axutils.childWithRole(element, "AXGroup")
        return group and axutils.childWithID(group, id "BackButton")
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard.matchesCurrent(element) -> boolean
--- Function
--- Checks to see if a GUI element is the 'current' (10.4+) Color Board.
---
--- Parameters:
---  * `element`    - The element you want to check
---
--- Returns:
---  * `true` if the `element` is a 10.4+ Color Board otherwise `false`
function ColorBoard.matchesCurrent(element)
    if element and #element == 1 then
        local scroll = element[1]
        if scroll:attributeValue("AXRole") == "AXScrollArea" then
            local aspectGroup = axutils.childFromTop(scroll, 2)
            return RadioGroup.matches(aspectGroup)
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:new(parent) -> ColorBoard object
--- Method
--- Creates a new ColorBoard object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorBoard object
-- TODO: Use a Function instead of a Method.
function ColorBoard:new(parent) -- luacheck: ignore
    local o = {
        _parent = parent,
        _child = {}
    }
    prop.extend(o, ColorBoard)

--- cp.apple.finalcutpro.inspector.color.ColorBoard.isColorInspectorSupported <cp.prop: boolean; read-only>
--- Field
--- Checks if the Color Inspector (from 10.4) is supported.
    o.isColorInspectorSupported = parent:app():inspector():color().isSupported:wrap(o)

    return o
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:parent() -> table
--- Method
--- Returns the ColorBoard's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorBoard:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorBoard:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- COLORBOARD UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorBoard:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function ColorBoard:UI()
    return axutils.cache(self, "_ui", function()
        local ui = self:parent():correctorUI()
        if ui and ui[1] then
            local board = ui[1]
            return ColorBoard.matches(board) and board or nil
        end
        return nil
    end, ColorBoard.matches)
end

function ColorBoard:contentUI()
    return axutils.cache(self, "_content", function()
        local ui = self:UI()
        -- returns the appropriate UI depending on the version.
        return ui and ((#ui == 1 and ui[1]) or ui) or nil
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:isShowing() -> boolean
--- Method
--- Returns whether or not the Color Board is visible
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the Color Board is showing, otherwise `false`
ColorBoard.isShowing = prop.new(function(self)
    local ui = self:UI()
    return ui ~= nil and ui:attributeValue("AXSize").w > 0
end):bind(ColorBoard)

--- cp.apple.finalcutpro.inspector.color.ColorBoard:isActive() -> boolean
--- Method
--- Returns whether or not the Color Board is active
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the Color Board is active, otherwise `false`
ColorBoard.isActive = prop.new(function(self)
    return self:aspectGroup():isShowing()
end):bind(ColorBoard)

--- cp.apple.finalcutpro.inspector.color.ColorBoard:show() -> ColorBoard object
--- Method
--- Shows the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:show()
    if not self:isShowing() then
        self:parent():activateCorrection(CORRECTION_TYPE)
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:hide() -> self
--- Method
--- Hides the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:hide()
    if self:backButton():isShowing() then
        self:backButton():press()
    elseif self:isShowing() then
        self:parent():hide()
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:backButton() -> Button
--- Method
--- Returns a `Button` to access the 'Back' button, if present.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Button` for 'back'.
---
--- Notes:
--- * This no longer exists in FCP 10.4+, so will always be non-functional.
function ColorBoard:backButton()
    if not self._backButton then
        self._backButton = Button:new(self, function()
            local group = axutils.childFromTop(self:contentUI(), 1)
            if group and group:attributeValue("AXRole") == "AXGroup" then
                return axutils.childWithID(group, id "BackButton")
            end
        end)
    end
    return self._backButton
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:childUI(id) -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for a child with the specified ID.
---
--- Parameters:
---  * axID - `AXIdentifier` of the child
---
--- Returns:
---  * An `hs._asm.axuielement` object
function ColorBoard:childUI(axID)
    return axutils.cache(self._child, "_"..axID, function()
        local ui = self:contentUI()
        return ui and axutils.childWithID(ui, axID)
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:topToolbarUI() -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for the top toolbar (i.e. where the Back Button is located in Final Cut Pro 10.3)
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
---
--- Notes:
---  * This object doesn't exist in Final Cut Pro 10.4 as the Color Board is now contained within the Color Inspector
function ColorBoard:topToolbarUI()
    return axutils.cache(self, "_topToolbar", function()
        local ui = self:UI()
        if ui then
            for _,child in ipairs(ui) do
                if axutils.childWith(child, "AXIdentifier", id "BackButton") then
                    return child
                end
            end
        end
        return nil
    end)
end

-----------------------------------------------------------------------
--
-- COLOR CORRECTION PANELS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorBoard:color() -> ColorBoardAspect
--- Method
--- Returns the `color` aspect of the color board.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorBoardAspect`.
function ColorBoard:color()
    if not self._color then
        self._color = Aspect:new(self, 1)
    end
    return self._color
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:saturation() -> ColorBoardAspect
--- Method
--- Returns the `saturation` aspect of the color board.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorBoardAspect`.
function ColorBoard:saturation()
    if not self._saturation then
        self._saturation = Aspect:new(self, 2)
    end
    return self._saturation
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:exposure() -> ColorBoardAspect
--- Method
--- Returns the `exposure` aspect of the color board.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorBoardAspect`.
function ColorBoard:exposure()
    if not self._exposure then
        self._exposure = Aspect:new(self, 3)
    end
    return self._exposure
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:current() -> ColorBoardAspect
--- Method
--- Returns the currently-selected 'aspect' of the Color Board - either the `color`, `saturation` or `exposure`.
--- If the color board is not currently visible, it returns the `color` aspect by default.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The currently active `ColorBoardAspect`, or the `color` aspect if none is showing.
function ColorBoard:current()
    if self:saturation():isShowing() then
        return self:saturation()
    elseif self:exposure():isShowing() then
        return self:exposure()
    end
    return self:color()
end

-----------------------------------------------------------------------
--
-- PANEL CONTROLS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorBoard:aspectGroup() -> cp.ui.RadioGroup
--- Method
--- Returns the `RadioGroup` for the 'aspect' currently being controlled -
--- either "Color", "Saturation", or "Exposure".
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `RadioGroup`.
function ColorBoard:aspectGroup()
    if not self._aspectGroup then
        self._aspectGroup = RadioGroup:new(self, function()
            return axutils.childWithRole(self:contentUI(), "AXRadioGroup")
        end)
    end
    return self._aspectGroup
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:nextAspect() -> ColorBoard object
--- Method
--- Toggles the Color Board Panels between "Color", "Saturation" and "Exposure"
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:nextAspect()
    self:show()

    local aspects = self:aspectGroup()
    aspects:nextOption()

    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:reset() -> self
--- Method
--- Resets the current aspect.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:reset()
    self:current():reset()
    return self
end

return ColorBoard