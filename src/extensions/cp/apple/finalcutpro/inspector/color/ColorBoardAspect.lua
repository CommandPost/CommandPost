--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspect.color.ColorBoardAspect ===
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

--- cp.apple.finalcutpro.inspect.color.ColorBoardAspect.ids -> table
--- Constant
--- A table containing the list of aspect IDs ("color", "saturation", "exposure").
ColorBoardAspect.ids = {"color", "saturation", "exposure"}

--- cp.apple.finalcutpro.inspect.color.ColorBoard.matches() -> boolean
--- Function
--- Checks if the element is a ColorBoardAspect.
function ColorBoardAspect.matches(element)
    return element and element:attributeValue("AXRole") == "AXGroup"
end

-- TODO: Add documentation
function ColorBoardAspect:new(parent, index)
    if index < 1 or index > #ColorBoardAspect.ids then
        error(format("The index must be between 1 and %s: %s", #ColorBoardAspect.ids, inspect(index)))
    end

    local o = prop.extend({
        _parent = parent,
        _index = index,
    }, ColorBoardAspect)

    return o
end

-- TODO: Add documentation
function ColorBoardAspect:parent()
    return self._parent
end

-- TODO: Add documentation
function ColorBoardAspect:app()
    return self:parent():app()
end

-- TODO: Add documentation
function ColorBoardAspect:UI()
    local parent = self:parent()
    -- only return the if this is the currently-selected aspect
    if parent:aspectGroup():selectedOption() == self._index then
        return parent:contentUI()
    end
end

-- TODO: Add documentation
function ColorBoardAspect:show()
    if not self:isShowing() then
        local parent = self:parent()
        parent:show()
        parent:aspectGroup():selectedOption(self._index)
        just.doUntil(function() return self:isShowing() end, 3, 0.01)
    end
    return self
end

-- TODO: Add documentation
function ColorBoardAspect:isShowing()
    return self:UI() ~= nil
end

-- TODO: Add documentation
function ColorBoardAspect:index()
    return self._index
end

-- TODO: Add documentation
function ColorBoardAspect:id()
    return ColorBoardAspect.ids[self._index]
end

-- TODO: Add documentation
function ColorBoardAspect:selected()
    return self:isShowing()
end

-- TODO: Add documentation
function ColorBoardAspect:reset()
    self:show()
    self:master():reset()
    self:shadows():reset()
    self:midtones():reset()
    self:highlights():reset()
    return self
end

-- TODO: Add documentation
function ColorBoardAspect:master()
    if not self._master then
        self._master = ColorPuck:new(
            self, ColorPuck.range.master,
            {"PAECorrectorEffectMaster", "cb master puck display name"}
        )
    end
    return self._master
end

-- TODO: Add documentation
function ColorBoardAspect:shadows()
    if not self._shadows then
        self._shadows = ColorPuck:new(
            self, ColorPuck.range.shadows,
            {"PAECorrectorEffectShadows", "cb shadow puck display name"}
        )
    end
    return self._shadows
end

-- TODO: Add documentation
function ColorBoardAspect:midtones()
    if not self._midtones then
        self._midtones = ColorPuck:new(
            self, ColorPuck.range.midtones,
            {"PAECorrectorEffectMidtones", "cb midtone puck display name"}
        )
    end
    return self._midtones
end

-- TODO: Add documentation
function ColorBoardAspect:highlights()
    if not self._highlights then
        self._highlights = ColorPuck:new(
            self, ColorPuck.range.highlights,
            {"PAECorrectorEffectHighlights", "cb highlight puck display name"}
        )
    end
    return self._highlights
end

-- TODO: Add documentation
function ColorBoardAspect:__tostring()
    return self:id()
end

return ColorBoardAspect