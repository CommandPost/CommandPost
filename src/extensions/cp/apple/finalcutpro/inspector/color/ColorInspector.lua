--- === cp.apple.finalcutpro.inspector.color.ColorInspector ===
---
--- Color Inspector Module.
---
--- Extends [Element](cp.ui.Element.md).

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                = require("hs.logger").new("colorInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")

local idBoard                           = require("cp.apple.finalcutpro.ids") "ColorBoard"

local CorrectionsBar                    = require("cp.apple.finalcutpro.inspector.color.CorrectionsBar")
local ColorBoard                        = require("cp.apple.finalcutpro.inspector.color.ColorBoard")
local ColorWheels                       = require("cp.apple.finalcutpro.inspector.color.ColorWheels")
local ColorCurves                       = require("cp.apple.finalcutpro.inspector.color.ColorCurves")
local HueSaturationCurves               = require("cp.apple.finalcutpro.inspector.color.HueSaturationCurves")

local If, WaitUntil                     = require("cp.rx.go.If"), require("cp.rx.go.WaitUntil")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local v                                 = require("semver")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorInspector = Element:subclass("ColorInspector")

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
function ColorInspector.static.matches(element)
    if Element.matches(element) then
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
    local UI = parent.panelUI:mutate(function(original)
        return axutils.cache(self, "_ui",
            function()
                local ui = original()
                return ColorInspector.matches(ui) and ui or nil
            end,
            ColorInspector.matches
        )
    end)

    Element.initialize(self, parent, UI)
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
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector.isAdvanced <cp.prop: boolean; read-only>
--- Field
--- Is the Color Inspector the advanced version that was added in 10.4?
function ColorInspector.lazy.prop:isAdvanced()
    return self:app().app.version:mutate(function(original)
        local version = original()
        return version and version >= ADVANCED_VERSION
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
        self:app():menu():selectMenu({"Window", "Go To", idBoard "ColorBoard"})
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
        self:app():menu():doSelectMenu({"Window", "Go To", idBoard "ColorBoard"})
    )
    :Then(WaitUntil(self.isShowing):TimeoutAfter(2000, "Unable to activate the " .. idBoard("ColorBoard")))
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

function ColorInspector.lazy.method:doHide()
    return If(self.isShowing)
    :Then(
        self:parent():doHide()
    )
    :Label("ColorInspector:doHide")
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
