--- === cp.apple.finalcutpro.inspector.color.ColorBoardAspect ===
---
--- Represents a particular aspect of the color board (Color/Saturation/Exposure).

local require = require

local inspect                   = require "hs.inspect"

local ColorPuck                 = require "cp.apple.finalcutpro.inspector.color.ColorPuck"
local Group                     = require "cp.ui.Group"
local just                      = require "cp.just"

local go                        = require "cp.rx.go"
local If, Do, Throw, WaitUntil  = go.If, go.Do, go.Throw, go.WaitUntil

local format = string.format

local ColorBoardAspect = Group:subclass("cp.apple.finalcutpro.inspector.color.ColorBoardAspect")

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect.ids -> table
--- Constant
--- A table containing the list of aspect IDs ("color", "saturation", "exposure").
ColorBoardAspect.static.ids = {"color", "saturation", "exposure"}

--- cp.apple.finalcutpro.inspector.color.ColorBoard.matches(element) -> boolean
--- Function
--- Checks if the element is a ColorBoardAspect.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ColorBoardAspect.static.matches(element)
    return Group.matches(element)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect(parent, index[, hasAngle]) -> ColorBoardAspect
--- Constructor
--- Creates a new `ColorBoardAspect` object.
---
--- Parameters:
---  * parent - The parent object.
---  * index - The Color Board Aspect Index.
---  * hasAngle - If `true`, the aspect has an `angle` parameter. Defaults to `false`
---
--- Returns:
---  * A new `ColorBoardAspect object.
function ColorBoardAspect:initialize(parent, index, hasAngle)
    if index < 1 or index > #ColorBoardAspect.ids then
        error(format("The index must be between 1 and %s: %s", #ColorBoardAspect.ids, inspect(index)))
    end

    self._index = index
    self._hasAngle = hasAngle

    local UI = parent.contentUI:mutate(function(original)
        -- only return the if this is the currently-selected aspect
        local ui = original()
        if ui and parent.aspectGroup:selectedOption() == index then
            return ui
        end
    end)

    Group.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:selected() -> boolean
--- Field
--- Is the Color Board Aspect selected?
function ColorBoardAspect.lazy.prop:selected()
    return self.isShowing
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
        parent.aspectGroup:selectedOption(self._index)
        just.doUntil(function() return self:isShowing() end, 3, 0.01)
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows this Color Board Aspect.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if successful or throwing an error if not.
function ColorBoardAspect.lazy.method:doShow()
    local parent = self:parent()

    return If(self.isShowing):Is(false)
    :Then(parent:doSelectAspect(self._index))
    :Then(
        WaitUntil(self.isShowing)
        :TimeoutAfter(3000, Throw("Unable to show the %q aspect of the Color Board", self:id()))
    )
    :Otherwise(true)
    :Label("ColorBoardAspect:doShow")
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
function ColorBoardAspect:hasAngle()
    return self._hasAngle
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:id() -> string
--- Method
--- Gets the Color Board Aspect ID.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ID as string.
function ColorBoardAspect.lazy.method:id()
    return ColorBoardAspect.ids[self._index]
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
    self.master:reset()
    self.shadows:reset()
    self.midtones:reset()
    self.highlights:reset()
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect:reset() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that resets all pucks in the the Color Board Aspect.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, which will resolve to `true` if sucessful, or throws an error if not.
function ColorBoardAspect.lazy.method:doReset()
    return Do(self:doShow())
    :Then(self.master:doReset())
    :Then(self.shadows:doReset())
    :Then(self.midtones:doReset())
    :Then(self:highlight():doReset())
    :Labeled("ColorBoardAspect:doReset")
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect.master <ColorPuck>
--- Field
--- The Master ColorPuck object.
function ColorBoardAspect.lazy.value:master()
    return ColorPuck(
        self, ColorPuck.RANGE.master,
        {"CPColorBoardMaster", "cb master puck display name"},
        self._hasAngle
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect.shadows <ColorPuck>
--- Field
--- The Shadows ColorPuck object.
function ColorBoardAspect.lazy.value:shadows()
    return ColorPuck(
        self, ColorPuck.RANGE.shadows,
        {"CPBolorBoardShadows", "cb shadow puck display name"},
        self._hasAngle
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect.midtones <ColorPuck>
--- Field
--- The Midtones ColorPuck object.
function ColorBoardAspect.lazy.value:midtones()
    return ColorPuck(
        self, ColorPuck.RANGE.midtones,
        {"CPColorBoardMidtones", "cb midtone puck display name"},
        self._hasAngle
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorBoardAspect.highlights <ColorPuck>
--- Field
--- The Highlights ColorPuck object.
function ColorBoardAspect.lazy.value:highlights()
    return ColorPuck(
        self, ColorPuck.RANGE.highlights,
        {"CPColorBoardHighlights", "cb highlight puck display name"},
        self._hasAngle
    )
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