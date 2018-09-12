--- === cp.apple.finalcutpro.main.TimelineAppearance ===
---
--- Timeline Appearance Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local just								= require("cp.just")
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local CheckBox					        = require("cp.ui.CheckBox")
local Slider							= require("cp.ui.Slider")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TimelineAppearance = {}

--- cp.apple.finalcutpro.main.TimelineAppearance.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function TimelineAppearance.matches(element)
    return element and element:attributeValue("AXRole") == "AXPopover"
end

--- cp.apple.finalcutpro.main.TimelineAppearance.new(app) -> TimelineAppearance
--- Constructor
--- Creates a new `TimelineAppearance` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `TimelineAppearance` object.
function TimelineAppearance.new(parent)
    local o = prop.extend({_parent = parent}, TimelineAppearance)
    return o
end

--- cp.apple.finalcutpro.main.TimelineAppearance:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function TimelineAppearance:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.TimelineAppearance:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function TimelineAppearance:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- APPEARANCE POPOVER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.TimelineAppearance:toggleUI() -> axuielementObject
--- Method
--- Gets the Toggle UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `axuielementObject` object.
function TimelineAppearance:toggleUI()
    return axutils.cache(self, "_toggleUI", function()
        return axutils.childFromRight(self:parent():UI(), 1, function(element)
            return element:attributeValue("AXRole") == "AXCheckBox"
        end)
    end)
end

--- cp.apple.finalcutpro.main.TimelineAppearance:toggle() -> CheckBox
--- Method
--- Gets the Timeline Appearance CheckBox.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `axuielementObject` object.
function TimelineAppearance:toggle()
    if not self._toggle then
        self._toggle = CheckBox(self:parent(), function()
            return self:toggleUI()
        end)
    end
    return self._toggle
end

--- cp.apple.finalcutpro.main.TimelineAppearance:UI() -> axuielementObject
--- Method
--- Gets the Timeline Appearance UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `axuielementObject` object.
function TimelineAppearance:UI()
    return axutils.cache(self, "_ui", function()
        return axutils.childMatching(self:toggleUI(), TimelineAppearance.matches)
    end,
    TimelineAppearance.matches)
end

--- cp.apple.finalcutpro.main.TimelineAppearance.isShowing <cp.prop: boolean>
--- Variable
--- Is the Timeline Appearance popup showing?
TimelineAppearance.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(TimelineAppearance)

--- cp.apple.finalcutpro.main.TimelineAppearance:UI() -> TimelineAppearance
--- Method
--- Show the Timeline Appearance popup.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `TimelineAppearance` object.
function TimelineAppearance:show()
    if not self:isShowing() then
        self:toggle():checked(true)
    end
    return self
end

--- cp.apple.finalcutpro.main.TimelineAppearance:UI() -> TimelineAppearance
--- Method
--- Hide the Timeline Appearance popup.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `TimelineAppearance` object.
function TimelineAppearance:hide()
    local ui = self:UI()
    if ui then
        ui:doCancel()
    end
    just.doWhile(function() return self:isShowing() end)
    return self
end

-----------------------------------------------------------------------
--
-- THE BUTTONS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.TimelineAppearance:clipHeight() -> Slider
--- Method
--- Get the Clip Height Slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Slider` object.
function TimelineAppearance:clipHeight()
    if not self._clipHeight then
        self._clipHeight = Slider(self, function()
            return axutils.childMatching(self:UI(), function(e)
                return e:attributeValue("AXRole") == "AXSlider" and e:attributeValue("AXMaxValue") == 210
            end)
        end)
    end
    return self._clipHeight
end

--- cp.apple.finalcutpro.main.TimelineAppearance:zoomAmount() -> Slider
--- Method
--- Get the Zoom Slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Slider` object.
function TimelineAppearance:zoomAmount()
    if not self._zoomAmount then
        self._zoomAmount = Slider(self, function()
            return axutils.childFromTop(self:UI(), 1, function(element)
                return element:attributeValue("AXRole") == "AXSlider"
            end)
        end)
    end
    return self._zoomAmount
end

return TimelineAppearance
