--- === cp.apple.finalcutpro.inspector.color.ColorBoard ===
---
--- Color Board Module.

local require = require

-- local log                                = require("hs.logger").new("colorBoard")

local Aspect                            = require("cp.apple.finalcutpro.inspector.color.ColorBoardAspect")
local axutils                           = require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local Button                            = require("cp.ui.Button")
local id                                = require("cp.apple.finalcutpro.ids") "ColorBoard"
local RadioGroup                        = require("cp.ui.RadioGroup")

local go                                = require("cp.rx.go")
local If, Do, Throw                     = go.If, go.Do, go.Throw

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorBoard = Element:subclass("ColorBoard")

local CORRECTION_TYPE = "Color Board"

--- cp.apple.finalcutpro.inspector.color.ColorBoard.aspect -> table
--- Constant
--- A table containing tables of all the aspect panel settings
ColorBoard.static.aspect                       = {"color", "saturation", "exposure"}

--- cp.apple.finalcutpro.inspector.color.ColorBoard.currentAspect -> string
--- Variable
--- The current aspect as a string.
ColorBoard.static.currentAspect = "*"

--- cp.apple.finalcutpro.inspector.color.ColorBoard.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Color Board or not
---
--- Parameters:
---  * `element`    - The element you want to check
---
--- Returns:
---  * `true` if the `element` is a Color Board otherwise `false`
function ColorBoard.static.matches(element)
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
function ColorBoard.static.matchesOriginal(element)
    if Element.matches(element) then
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
    if Element.matches(element) and #element == 1 then
        local scroll = element[1]
        if scroll:attributeValue("AXRole") == "AXScrollArea" then
            local aspectGroup = axutils.childFromTop(scroll, 2)
            return RadioGroup.matches(aspectGroup)
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard(parent) -> ColorBoard object
--- Constructor
--- Creates a new ColorBoard object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorBoard object
function ColorBoard:initialize(parent)
    self._child = {}

    local UI = parent.correctorUI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            local ui = original()
            if ui and ui[1] then
                local board = ui[1]
                return ColorBoard.matches(board) and board or nil
            end
            return nil
        end, ColorBoard.matches)
    end)

    Element.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard.contentUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the `hs._asm.axuielement` object for the Color Board's content.
function ColorBoard.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_content", function()
            local ui = original()
            -----------------------------------------------------------------------
            -- Returns the appropriate UI depending on the version:
            -----------------------------------------------------------------------
            return ui and ((#ui == 1 and ui[1]) or ui) or nil
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard.isShowing <cp.prop: boolean; read-only; live>
--- Field
--- Returns whether or not the Color Board is visible.
function ColorBoard.lazy.prop:isShowing()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui ~= nil and ui:attributeValue("AXSize").w > 0
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:isActive <cp.prop: boolean; read-only>
--- Field
--- Returns whether or not the Color Board is active
function ColorBoard.lazy.prop:isActive()
    return self:aspectGroup().isShowing
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard.topToolbarUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Gets the `hs._asm.axuielement` object for the top toolbar (i.e. where the Back Button is located in Final Cut Pro 10.3)
---
--- Notes:
---  * This object doesn't exist in Final Cut Pro 10.4 as the Color Board is now contained within the Color Inspector
function ColorBoard.lazy.prop:topToolbarUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_topToolbar", function()
            local ui = original()
            if ui then
                for _,child in ipairs(ui) do
                    if axutils.childWith(child, "AXIdentifier", id "BackButton") then
                        return child
                    end
                end
            end
            return nil
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard.isAdvanced <cp.prop: boolean; read-only>
--- Field
--- Checks if the advanced Color Inspector (from 10.4) is supported.
function ColorBoard.lazy.prop:isAdvanced()
    return self:parent().isAdvanced
end

-----------------------------------------------------------------------
--
-- COLORBOARD UI:
--
-----------------------------------------------------------------------

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

--- cp.apple.finalcutpro.inspector.color.ColorBoard:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Color Board.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, which will send a single `true` if successful, otherwise `false`, or an error being sent.
function ColorBoard.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(
        self:parent():doActivateCorrection(CORRECTION_TYPE)
    )
    :Otherwise(true)
    :Label("ColorBoard:doShow")
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

--- cp.apple.finalcutpro.inspector.color.ColorBoard:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that hides the Color Board.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, which will send a single `true` if successful, otherwise `false`, or an error being sent.
function ColorBoard.lazy.method:doHide()
    return If(self:backButton().isShowing)
    :Then(
        self:backButton():doPress()
    )
    :Otherwise(
        self:parent():doHide()
    )
    :Label("ColorBoard:doHide")
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:backButton() -> Button
--- Method
--- Returns a `Button` to access the 'Back' button, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Button` for 'back'.
---
--- Notes:
---  * This no longer exists in FCP 10.4+, so will always be non-functional.
function ColorBoard:backButton()
    if not self._backButton then
        self._backButton = Button(self, function()
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
function ColorBoard.lazy.method:color()
    return Aspect(self, 1, true)
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
function ColorBoard.lazy.method:saturation()
    return Aspect(self, 2)
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
function ColorBoard.lazy.method:exposure()
    return Aspect(self, 3)
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

--- cp.apple.finalcutpro.inspector.color.ColorBoard:doResetCurrent([range]) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will reset the current 'active' aspect (e.g. `color`) in the Color Board.
--- If the `range` is provided, only that subset (`master`, `shadows`, `midtones`, `highlights`) will be reset.
---
--- Parameters:
--- * range     - Optional range to reset in the current aspect.
---
--- Returns:
--- * The `Statement`, resolving with `true` if completed or an error if not.
function ColorBoard:doResetCurrent(range)
    return Do(self:doShow())
    :Then(function()
        local current = self:current()
        if range then
            local puckFn = current[range]
            if type(puckFn) ~= "function" then
                return Throw("Invalid range: %s", range)
            end

            local puck = puckFn(current)
            if puck and type(puck.doReset) == "function" then
                return puck:doReset()
            else
                return Throw("Invalid puck: %s", range)
            end
        else
            return current:doReset()
        end
    end)
    :Label("ColorBoard:doResetCurrent")
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
function ColorBoard.lazy.method:aspectGroup()
    return RadioGroup(self, function()
        return axutils.childWithRole(self:contentUI(), "AXRadioGroup")
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:doSelectAspect(index) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to select the specified aspect `index`.
--- If the `index` is not between `1` and `3`, and error will be thrown.
---
--- Parameters:
--- * index     - The index to select.
---
--- Returns:
--- * The `Statement`, which will resolve to `true` if successful, or throw an error if not.
function ColorBoard:doSelectAspect(index)
    return Do(self:doShow())
    :Then(self:aspectGroup():doSelectOption(index))
    :Label("ColorBoard:doSelectAspect")
end

--- cp.apple.finalcutpro.inspector.color.ColorBoard:doSelectAspect(index) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to select the specified aspect `index`.
--- If the `index` is not between `1` and `3`, and error will be thrown.
---
--- Parameters:
--- * index     - The index to select.
---
--- Returns:
--- * The `Statement`, which will resolve to `true` if successful, or throw an error if not.
function ColorBoard:doSelectAspect(index)
    return Do(self:doShow())
    :Then(self:aspectGroup():doSelectOption(index))
    :Label("ColorBoard:doSelectAspect")
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

--- cp.apple.finalcutpro.inspector.color.ColorBoard:doNextAspect() -> cp.rx.go.Statement<boolean>
--- Method
--- A [Statement](cp.rx.go.Statement.md) that toggles the Color Board Panels between "Color", "Saturation" and "Exposure".
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard.lazy.method:doNextAspect()
    local aspects = self:aspectGroup()
    return Do(self:doShow())
    :Then(
        aspects:doNextOption()
    )
    :Label("ColorBoard:doNextAspect")
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
