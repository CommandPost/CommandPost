--- === cp.apple.finalcutpro.inspector.color.ColorInspector ===
---
--- Color Inspector Module.

local require               = require

local log                   = require "hs.logger".new "colorInspect"

local axutils               = require "cp.ui.axutils"

local BasePanel             = require "cp.apple.finalcutpro.inspector.BasePanel"

local ColorBoard            = require "cp.apple.finalcutpro.inspector.color.ColorBoard"
local ColorCurves           = require "cp.apple.finalcutpro.inspector.color.ColorCurves"
local ColorWheels           = require "cp.apple.finalcutpro.inspector.color.ColorWheels"
local CorrectionsBar        = require "cp.apple.finalcutpro.inspector.color.CorrectionsBar"
local HueSaturationCurves   = require "cp.apple.finalcutpro.inspector.color.HueSaturationCurves"

local If                    = require "cp.rx.go.If"
local WaitUntil             = require "cp.rx.go.WaitUntil"

local childFromTop          = axutils.childFromTop
local childWithRole         = axutils.childWithRole
local withRole              = axutils.withRole

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorInspector = BasePanel:subclass("cp.apple.finalcutpro.inspector.color.ColorInspector")

--- cp.apple.finalcutpro.inspector.color.ColorInspector.matches(element)
--- Function
--- Checks if the specified element is the Color Inspector element.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if the element is the Color Inspector.
function ColorInspector.static.matches(element)
    if BasePanel.matches(element) then
        local root = #element == 1 and withRole(element, "AXGroup")
        if root then
            local split = childWithRole(root, "AXSplitGroup")
            local top = split and withRole(childFromTop(split, 1), "AXGroup")
            return top and #top == 1 and CorrectionsBar.matches(top[1]) or false
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector(parent) -> ColorInspector object
--- Method
--- Creates a new ColorInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorInspector object
function ColorInspector:initialize(parent)
    BasePanel.initialize(self, parent, "Color")
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector.topBarUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object representing the top bar.
function ColorInspector.lazy.prop:topBarUI()
    return self.UI:mutate(function(original)
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
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector.correctorUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object representing the currently-selected corrector panel.
function ColorInspector.lazy.prop:correctorUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_corrector",
            function()
                local ui = original()
                if ui and ColorInspector.matches(ui)then
                    local split = ui[1]
                    return axutils.childFromTop(split, 2)
                end
                return nil
            end, function(element) return original() ~= nil and element ~= nil end
        )
    end)
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
function ColorInspector.lazy.method:corrections()
    return CorrectionsBar(self)
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
        self:app():menu():selectMenu({"Window", "Go To", "Color Inspector"})
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempts to show the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if successful or sending an error if not.
function ColorInspector.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(
        self:app():menu():doSelectMenu({"Window", "Go To", "Color Inspector"})
    )
    :Then(WaitUntil(self.isShowing):TimeoutAfter(2000, "Unable to activate the Color Inspector"))
    :Otherwise(true)
    :Label("ColorInspector:doShow")
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

--- cp.apple.finalcutpro.inspector.color.ColorInspector:doActivateCorrection(correctionType[, number]) -> cp.rx.go.Statement<boolean>
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that activates the named correction type and number, if present.
--- If no corrector with the type/number combination exists, a new one is added.
---
--- Parameters:
---  * correctionType   - The string for the type of correction (in English). E.g. "Color Wheels", "Color Board", etc.
---  * number           - The correction number for that type. Defaults to `1`.
---
--- Returns:
---  * The `Statement`, which sends a single `true` value if successful, or sends an error if not.
function ColorInspector:doActivateCorrection(correctionType, number)
    return self:corrections():doActivate(correctionType, number):Label("ColorInspector:doActivateCorrection")
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

--- cp.apple.finalcutpro.inspector.color.ColorInspector:doAddCorrection(correctionType) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that adds the named correction type.
---
--- Parameters:
---  * correctionType   - The string for the type of correction (in English). E.g. "Color Wheels", "Color Board", etc.
---
--- Returns:
---  * The `Statement`, resolving to `true` if successful, or sending an error if not.
function ColorInspector:doAddCorrection(correctionType)
    return self:corrections():doAdd(correctionType):Label("ColorInspector:doAddCorrection")
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
function ColorInspector.lazy.method:colorBoard()
    return ColorBoard(self)
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
function ColorInspector.lazy.method:colorWheels()
    return ColorWheels(self)
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
function ColorInspector.lazy.method:colorCurves()
    return ColorCurves(self)
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
function ColorInspector.lazy.method:hueSaturationCurves()
    return HueSaturationCurves(self)
end

return ColorInspector
