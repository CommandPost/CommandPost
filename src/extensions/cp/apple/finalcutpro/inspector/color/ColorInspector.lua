--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.ColorInspector ===
---
--- Color Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                = require("hs.logger").new("colorInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop                              = require("cp.prop")
local axutils                           = require("cp.ui.axutils")

local idBoard                           = require("cp.apple.finalcutpro.ids") "ColorBoard"

local CorrectionsBar                    = require("cp.apple.finalcutpro.inspector.color.CorrectionsBar")
local ColorBoard                        = require("cp.apple.finalcutpro.inspector.color.ColorBoard")
local ColorWheels                       = require("cp.apple.finalcutpro.inspector.color.ColorWheels")
local ColorCurves                       = require("cp.apple.finalcutpro.inspector.color.ColorCurves")
local HueSaturationCurves               = require("cp.apple.finalcutpro.inspector.color.HueSaturationCurves")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local v                                 = require("semver")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorInspector = {}

local ADVANCED_VERSION = v("10.4")

--- cp.apple.finalcutpro.inspector.color.ColorInspector.matches(element)
--- Function
--- Checks if the specified element is the Color Inspector element.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if the element is the Color Inspector.
function ColorInspector.matches(element)
    if element then
        local role = element:attributeValue("AXRole") -- 10.4+
        if role == "AXGroup" and #element == 1 then
            local split = element[1]
            if split:attributeValue("AXRole") == "AXSplitGroup" then
                local top = axutils.childFromTop(split, 1)
                if top and top:attributeValue("AXRole") == "AXGroup" and #top == 1 then
                    -- check it's the correction bar.
                    return CorrectionsBar.matches(top[1])
                end
            end
        else -- 10.3 Color Board
            return ColorBoard.matchesOriginal(element)
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector.new(parent) -> ColorInspector object
--- Method
--- Creates a new ColorInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorInspector object
function ColorInspector.new(parent)

    local o = prop.extend({
        _parent = parent,
        _child = {}
    }, ColorInspector)


--- cp.apple.finalcutpro.inspector.color.ColorInspector.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object for the Color Inspector. Prior to FCPX 10.4 this will be the Color Board.
    o.UI = parent.panelUI:mutate(function(original, self)
        return axutils.cache(self, "_ui",
            function()
                local ui = original()
                return ColorInspector.matches(ui) and ui or nil
            end,
            ColorInspector.matches
        )
    end):bind(o)

--- cp.apple.finalcutpro.inspector.color.ColorInspector.topBarUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object representing the top bar.
    o.topBarUI = o.UI:mutate(function(original, self)
        return axutils.cache(self, "_topBar",
            function()
                local ui = original()
                if ui and #ui == 1 then
                    local split = ui[1]
                    return #split == 3 and axutils.childFromTop(split, 1) or nil
                end
                return nil
            end,
            function(element) return element:attributeValue("AXRole") == "AXGroup" end
        )
    end):bind(o)

--- cp.apple.finalcutpro.inspector.color.ColorInspector.correctorUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object representing the currently-selected corrector panel.
    o.correctorUI = o.UI:mutate(function(original, self)
        return axutils.cache(self, "_corrector",
            function()
                local ui = original()
                if ui then
                    if ColorBoard.matchesOriginal(ui) then -- 10.3 Color Board
                        return ui
                    elseif ColorInspector.matches(ui) then -- 10.4+ Color Inspector
                        local split = ui[1]
                        return axutils.childFromTop(split, 2)
                    end
                end
                return nil
            end, function(element) return original() ~= nil and element ~= nil end
        )
    end):bind(o)

--- cp.apple.finalcutpro.inspector.color.ColorInspector.isShowing <cp.prop: boolean; read-only; live>
--- Field
--- Checks if the Color Inspector is visible.
    o.isShowing = o.UI:mutate(function(original)
        return original() ~= nil
    end):bind(o)


--- cp.apple.finalcutpro.inspector.color.ColorInspector.isAdvanced <cp.prop: boolean; read-only>
--- Field
--- Is the Color Inspector the advanced version that was added in 10.4?
    o.isAdvanced = parent:app().app.version:mutate(function(original)
        local version = original()
        return version and version >= ADVANCED_VERSION
    end):bind(o)

    return o
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector:parent() -> table
--- Method
--- Returns the ColorInspector's parent table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorInspector:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- COLOR INSPECTOR UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorInspector:corrections() -> CorrectionsBar
--- Method
--- Returns the `CorrectionsBar` instance representing the available corrections,
--- and currently selected correction type.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `CorrectionsBar` instance.
function ColorInspector:corrections()
    if not self._corrections then
        self._corrections = CorrectionsBar.new(self)
    end
    return self._corrections
end

--------------------------------------------------------------------------------
--
-- COLOR INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorInspector:show() -> self
--- Method
--- Shows the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorInspector object
function ColorInspector:show()
    if not self:isShowing() then
        self:app():menuBar():selectMenu({"Window", "Go To", idBoard "ColorBoard"})
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector:activateCorrection(correctionType[, number]) -> self
--- Method
--- Activates the named correction type and number, if present. If no corrector with the type/number combination exists, a new one is added.
---
--- Parameters:
---  * correctionType   - The string for the type of correction (in English). E.g. "Color Wheels", "Color Board", etc.
---  * number           - The correction number for that type. Defaults to `1`.
---
--- Returns:
---  * ColorInspector object
function ColorInspector:activateCorrection(correctionType, number)
    self:corrections():activate(correctionType, number)
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector:addCorrection(correctionType) -> self
--- Method
--- Adds the named correction type.
---
--- Parameters:
---  * correctionType   - The string for the type of correction (in English). E.g. "Color Wheels", "Color Board", etc.
---
--- Returns:
---  * ColorInspector object
function ColorInspector:addCorrection(correctionType)
    self:corrections():add(correctionType)
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector:hide() -> ColorInspector
--- Method
--- Hides the Color Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorInspector object
function ColorInspector:hide()
    if self:isShowing() then
        self:parent():hide()
    end
    return self
end

--------------------------------------------------------------------------------
--
-- COLOR BOARD:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorInspector:colorBoard() -> ColorBoard
--- Method
--- Gets the ColorBoard object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new ColorBoard object
function ColorInspector:colorBoard()
    if not self._colorBoard then
        self._colorBoard = ColorBoard.new(self)
    end
    return self._colorBoard
end

--------------------------------------------------------------------------------
--
-- COLOR WHEELS:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorInspector:colorWheels() -> ColorWheels
--- Method
--- Gets the ColorWheels object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new ColorWheels object
function ColorInspector:colorWheels()
    if not self._colorWheels then
        self._colorWheels = ColorWheels.new(self)
    end
    return self._colorWheels
end

--------------------------------------------------------------------------------
--
-- COLOR CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorInspector:colorCurves() -> ColorCurves
--- Method
--- Gets the ColorCurves object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new ColorCurves object
function ColorInspector:colorCurves()
    if not self._colorCurves then
        self._colorCurves = ColorCurves:new(self)
    end
    return self._colorCurves
end

--------------------------------------------------------------------------------
--
-- HUE/SATURATION CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorInspector:hueSaturationCurves() -> HueSaturationCurves
--- Method
--- Gets the HueSaturationCurves object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new HueSaturationCurves object
function ColorInspector:hueSaturationCurves()
    if not self._hueSaturationCurves then
        self._hueSaturationCurves = HueSaturationCurves:new(self)
    end
    return self._hueSaturationCurves
end

return ColorInspector