--- === cp.apple.finalcutpro.inspector.color.CorrectionsBar ===
---
--- The Correction selection/management bar at the top of the ColorInspector
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("colorInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local CheckBox                          = require("cp.ui.CheckBox")
local just                              = require("cp.just")
local MenuButton                        = require("cp.ui.MenuButton")
local prop                              = require("cp.prop")

local Do                                = require("cp.rx.go.Do")
local If                                = require("cp.rx.go.If")
local Throw                             = require("cp.rx.go.Throw")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local CorrectionsBar = {}

local sort = table.sort

--- cp.apple.finalcutpro.inspector.color.ColorInspector.CORRECTION_TYPES
--- Constant
--- Table of Correction Types:
---
--- * "Color Board"
--- * "Color Wheels"
--- * "Color Curves"
--- * "Hue/Saturation Curves"
CorrectionsBar.CORRECTION_TYPES = {
    ["Color Board"]             = "FFCorrectorColorBoard",
    ["Color Wheels"]            = "PAECorrectorEffectDisplayName",
    ["Color Curves"]            = "PAEColorCurvesEffectDisplayName",
    ["Hue/Saturation Curves"]   = "PAEHSCurvesEffectDisplayName",
}

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function CorrectionsBar.matches(element)
    if element and element:attributeValue("AXRole") == "AXGroup" then
        local children = element:children()
        -- sort them left-to-right
        sort(children, axutils.compareLeftToRight)
        -- log.df("matches: children left to right: \n%s", _inspect(children))
        return #children >= 2
           and CheckBox.matches(children[1])
           and MenuButton.matches(children[2])
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar.new(parent) -> CorrectionsBar
--- Function
--- Creates a new Media Import object.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new CorrectionsBar object.
function CorrectionsBar.new(parent)
    local o = prop.extend({
        _parent = parent,
    }, CorrectionsBar)

    local UI = parent.topBarUI:mutate(function(original, self)
        return axutils.cache(self, "_ui",
            function()
                local ui = original()
                if ui then
                    local barUI = ui[1]
                    return CorrectionsBar.matches(barUI) and barUI or nil
                else
                    return nil
                end
            end,
            CorrectionsBar.matches
        )
    end)

    local isShowing = UI:mutate(function(original)
        return original ~= nil
    end)

    prop.bind(o) {
        --- cp.apple.finalcutpro.inspector.color.CorrectionsBar.UI <cp.prop: hs._asm.axuielement; read-only; live>
        --- Field
        --- Returns the `hs._asm.axuielement` object.
        UI = UI,

        --- cp.apple.finalcutpro.inspector.color.CorrectionsBar.isShowing <cp.prop: boolean; read-only; live>
        --- Field
        --- Is the Corrections Bar currently showing?
        isShowing = isShowing,
    }

    --- cp.apple.finalcutpro.inspector.color.CorrectionsBar.correction <cp.ui.MenuButton>
    --- Field
    --- The `MenuButton` that lists the current correction.
    o.correction = MenuButton.new(o, function()
        return axutils.childWithRole(UI(), "AXMenuButton")
    end)

    return o
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:parent() -> table
--- Method
--- Returns the Corrections Bar's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function CorrectionsBar:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function CorrectionsBar:app()
    return self:parent():app()
end


--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:show() -> self
--- Method
--- Attempts to show the bar.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `CorrectionsBar` instance.
function CorrectionsBar:show()
    self:parent():show()
    just.doUntil(self.isShowing, 5)
    return self
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:doShow() -> cp.rx.go.Statement
--- Method
--- A Statement that will attempt to show the bar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, which will resolve to `true` if successful, or send an `error` if not.
function CorrectionsBar:doShow()
    return self:parent():doShow():Label("CorrectionsBar:doShow")
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:menuButton() -> MenuButton
--- Method
--- Returns the menu button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `menuButton` object.
function CorrectionsBar:menuButton()
    if not self._menuButton then
        self._menuButton = MenuButton.new(self, function()
            return axutils.childWithRole(self:UI(), "AXMenuButton")
        end)
    end
    return self._menuButton
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:findCorrectionLabel(correctionType) -> string
--- Method
--- Returns Correction Label.
---
--- Parameters:
---  * correctionType - The correction type as string.
---
--- Returns:
---  * The correction label as string.
function CorrectionsBar:findCorrectionLabel(correctionType)
    return self:app():string(self.CORRECTION_TYPES[correctionType])
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:activate(correctionType, number) -> cp.apple.finalcutpro.inspector.color.CorrectionsBar
--- Method
--- Activates a correction type.
---
--- Parameters:
---  * `correctionType` - The correction type as string.
---  * `number` - The number of the correction.
---
--- Returns:
---  *  `cp.apple.finalcutpro.inspector.color.CorrectionsBar` object.
function CorrectionsBar:activate(correctionType, number)
    number = number or 1 -- Default to the first corrector.

    self:show()

    --------------------------------------------------------------------------------
    -- See if the correction type/number combo exists already:
    --------------------------------------------------------------------------------
    local correctionText = self:findCorrectionLabel(correctionType)
    if not correctionText then
        log.ef("Invalid Correction Type: '%s' (%s)", correctionType, correctionText)
    end

    local menuButton = self:menuButton()

    local result = just.doUntil(menuButton.isShowing)

    if result then
        local pattern = "%s*"..correctionText.." "..number
        if not menuButton:selectItemMatching(pattern) then
            --------------------------------------------------------------------------------
            -- Try adding a new correction of the specified type:
            --------------------------------------------------------------------------------
            pattern = "%+"..correctionText
            if not menuButton:selectItemMatching(pattern) then
                log.ef("Unable to find correction: '%s' (%s)", correctionType, correctionText)
                return false
            end
        end
        return true
    else
        log.ef("Corrections Bar activation failed due to menu button timing out.")
    end

    return false
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:activate(correctionType, number) -> cp.rx.go.Statement
--- Method
--- A Statement that activates a correction type.
---
--- Parameters:
---  * `correctionType` - The correction type as string.
---  * `number` - The number of the correction.
---
--- Returns:
---  *  The `Statement`.
function CorrectionsBar:doActivate(correctionType, number)
    number = number or 1
    local menuButton = self:menuButton()

    return Do(self:doShow())
    :Then(function()
        local correctionText = self:findCorrectionLabel(correctionType)
        if not correctionText then
            return Throw("Invalid Correction Type: '%s' (%s)", correctionType, correctionText)
        end

        local pattern = "%s*"..correctionText.." "..number

        return If(menuButton:doSelectItemMatching(pattern)):Is(false)
        :Then(function()
            --------------------------------------------------------------------------------
            -- Try adding a new correction of the specified type:
            --------------------------------------------------------------------------------
            pattern = "%+"..correctionText
            return If(menuButton:doSelectItemMatching(pattern)):Is(false)
            :Then(Throw("Unable to find correction: '%s' (%s)", correctionType, correctionText))
            :Otherwise(true)
        end)
        :Otherwise(true)
    end)
    :Label("doActivate")
end

--- cp.apple.finalcutpro.inspector.color.CorrectionsBar:add(correctionType) -> cp.apple.finalcutpro.inspector.color.CorrectionsBar
--- Method
--- Adds the specific correction type.
---
--- Parameters:
---  * `correctionType` - The correction type as string.
---
--- Returns:
---  *  `cp.apple.finalcutpro.inspector.color.CorrectionsBar` object.
function CorrectionsBar:add(correctionType)
    self:show()

    local correctionText = self:findCorrectionLabel(correctionType)
    if not correctionText then
        log.ef("Invalid Correction Type: %s", correctionType)
    end

    local menuButton = self:menuButton()

    local pattern = "%+"..correctionText
    if not menuButton:selectItemMatching(pattern) then
        log.ef("Unable to find correction: '%s' (%s)", correctionType, correctionText)
    end

    return self
end

return CorrectionsBar
