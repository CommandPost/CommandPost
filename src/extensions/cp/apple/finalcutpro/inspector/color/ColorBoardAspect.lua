--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.ColorBoardAspect ===
---
--- Represents a particular aspect of the color board (Color/Saturation/Exposure).

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local inspect                   = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local ColorPuck                 = require("cp.apple.finalcutpro.inspector.color.ColorPuck")
local just                      = require("cp.just")
local prop                      = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorBoardAspect = {}

local format = string.format

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect.ids -> table
--- Constant
--- A table containing the list of aspect IDs ("color", "saturation", "exposure").
ColorBoardAspect.ids = {"color", "saturation", "exposure"}

--- cp.apple.finalcutpro.inspector.color.ColorBoard.matches(element) -> boolean
--- Function
--- Checks if the element is a ColorBoardAspect.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ColorBoardAspect.matches(element)
    return element and element:attributeValue("AXRole") == "AXGroup"
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:new(parent, index[, hasAngle]) -> ColorBoardAspect
--- Function
--- Creates a new `ColorBoardAspect` object.
---
--- Parameters:
---  * parent - The parent object.
---  * index - The Color Board Aspect Index.
---  * hasAngle - If `true`, the aspect has an `angle` parameter. Defaults to `false`
---
--- Returns:
---  * A new `ColorBoardAspect object.
-- TODO: Use a function instead of a method.
function ColorBoardAspect:new(parent, index, hasAngle) -- luacheck: ignore
    if index < 1 or index > #ColorBoardAspect.ids then
        error(format("The index must be between 1 and %s: %s", #ColorBoardAspect.ids, inspect(index)))
    end

    local o = prop.extend({
        _parent = parent,
        _index = index,
        _hasAngle = hasAngle,
    }, ColorBoardAspect)

    return o
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:parent() -> object
--- Method
--- Returns the Parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function ColorBoardAspect:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:app() -> App
--- Method
--- Returns the App instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function ColorBoardAspect:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:UI() -> axuielementObject
--- Method
--- Returns the Color Board Aspect Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function ColorBoardAspect:UI()
    local parent = self:parent()
    -- only return the if this is the currently-selected aspect
    if parent:aspectGroup():selectedOption() == self._index then
        return parent:contentUI()
    end
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:show() -> cp.apple.finalcutpro.inspector.color.ColorBoardAspect
--- Method
--- Shows the Color Board Aspect
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.inspector.color.ColorBoardAspect` object for method chaining.
function ColorBoardAspect:show()
    if not self:isShowing() then
        local parent = self:parent()
        parent:show()
        parent:aspectGroup():selectedOption(self._index)
        just.doUntil(function() return self:isShowing() end, 3, 0.01)
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:isShowing() -> boolean
--- Method
--- Gets whether or not the Color Board Aspect is showing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing or `false` if not.
function ColorBoardAspect:isShowing()
    return self:UI() ~= nil
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:index() -> number
--- Method
--- Gets the Color Board Aspect index.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A number.
function ColorBoardAspect:index()
    return self._index
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:hasAngle() -> boolean
--- Method
--- Checks if the aspect has an `angle` property.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if it has an `angle` propery.

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:id() -> string
--- Method
--- Gets the Color Board Aspect ID.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ID as string.
function ColorBoardAspect:id()
    return ColorBoardAspect.ids[self._index]
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:selected() -> boolean
--- Method
--- Is the Color Board Aspect selected?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if selected otherwise `false`.
function ColorBoardAspect:selected()
    return self:isShowing()
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:reset() -> cp.apple.finalcutpro.inspector.color.ColorBoardAspect
--- Method
--- Resets the Color Board Aspect.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.inspector.color.ColorBoardAspect` object for method chaining.
function ColorBoardAspect:reset()
    self:show()
    self:master():reset()
    self:shadows():reset()
    self:midtones():reset()
    self:highlights():reset()
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:master() -> ColorPuck
--- Method
--- Gets the Master ColorPuck object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Master ColorPuck object.
function ColorBoardAspect:master()
    if not self._master then
        self._master = ColorPuck.new(
            self, ColorPuck.RANGE.master,
            {"PAECorrectorEffectMaster", "cb master puck display name"},
            self._hasAngle
        )
    end
    return self._master
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:shadows() -> ColorPuck
--- Method
--- Gets the Shadows ColorPuck object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Shadows ColorPuck object.
function ColorBoardAspect:shadows()
    if not self._shadows then
        self._shadows = ColorPuck.new(
            self, ColorPuck.RANGE.shadows,
            {"PAECorrectorEffectShadows", "cb shadow puck display name"},
            self._hasAngle
        )
    end
    return self._shadows
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:midtones() -> ColorPuck
--- Method
--- Gets the Midtones ColorPuck object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Midtones ColorPuck object.
function ColorBoardAspect:midtones()
    if not self._midtones then
        self._midtones = ColorPuck.new(
            self, ColorPuck.RANGE.midtones,
            {"PAECorrectorEffectMidtones", "cb midtone puck display name"},
            self._hasAngle
        )
    end
    return self._midtones
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:highlights() -> ColorPuck
--- Method
--- Gets the Highlights ColorPuck object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Highlights ColorPuck object.
function ColorBoardAspect:highlights()
    if not self._highlights then
        self._highlights = ColorPuck.new(
            self, ColorPuck.RANGE.highlights,
            {"PAECorrectorEffectHighlights", "cb highlight puck display name"},
            self._hasAngle
        )
    end
    return self._highlights
end

-- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:__tostring() -> string
-- Method
-- Gets the Color Board Aspect ID.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The ID as string.
function ColorBoardAspect:__tostring()
    return self:id()
end

return ColorBoardAspect