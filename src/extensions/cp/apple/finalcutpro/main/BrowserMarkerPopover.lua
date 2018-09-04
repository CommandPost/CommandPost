--- === cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover ===
---
--- Browser Marker Popup.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                             = require("hs.logger").new("browser")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
--local inspect                         = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local Button							= require("cp.ui.Button")
local CheckBox                          = require("cp.ui.CheckBox")
local just                              = require("cp.just")
local prop                              = require("cp.prop")
local RadioButton					    = require("cp.ui.RadioButton")
local TextField							= require("cp.ui.TextField")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local BrowserMarkerPopover = {}

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Browser Marker Popover or not
---
--- Parameters:
---  * element - The element you want to check
---
--- Returns:
---  * `true` if the `element` is the Browser Marker Popover otherwise `false`
function BrowserMarkerPopover.matches(element)
    return element and element:attributeValue("AXRole") == "AXPopover" and element:attributeValueCount("AXChildren") >= 5
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.new(parent) -> BrowserMarkerPopover
--- Constructor
--- Constructs a new Browser Marker Popover
---
--- Parameters:
--- * parent - The parent object
---
--- Returns:
--- * The new `BrowserMarkerPopover` instance.
function BrowserMarkerPopover.new(parent)
    local o = prop.extend({_parent = parent}, BrowserMarkerPopover)
    return o
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:parent() -> table
--- Method
--- Returns the Browser Marker Popover's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function BrowserMarkerPopover:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function BrowserMarkerPopover:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- MARKER POPOVER UI:
--
-----------------------------------------------------------------------


--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Browser Marker Popover
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function BrowserMarkerPopover:UI()
    return axutils.cache(self, "_ui", function()
        return axutils.childMatching(self:parent():UI(), BrowserMarkerPopover.matches)
    end,
    BrowserMarkerPopover.matches)
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.isShowing <cp.prop: boolean>
--- Field
--- Is the Browser Marker Popover showing?
BrowserMarkerPopover.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(BrowserMarkerPopover)

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:show() -> BrowserMarkerPopover
--- Method
--- Shows the Browser Marker Popover by triggering "Add Marker and Modify" from the menu bar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * BrowserMarkerPopover object
function BrowserMarkerPopover:show()
    if not self:isShowing() then
        self:app():selectMenu({"Mark", "Markers", "Add Marker and Modify"})
    end
    return self
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:hide() -> BrowserMarkerPopover
--- Method
--- Hides the Browser Marker Popover by clicking "Done" on the popover.
---
--- Parameters:
---  * None
---
--- Returns:
---  * BrowserMarkerPopover object
function BrowserMarkerPopover:hide()
    local ui = self:UI()
    if ui then
        self:done():press()
    end
    just.doWhile(function() return self:isShowing() end)
    return self
end

-----------------------------------------------------------------------
--
-- UI ITEMS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:standard() -> RadioButton
--- Method
--- Gets the "Standard" Marker button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `RadioButton` object.
function BrowserMarkerPopover:standard()
    if not self._standard then
        self._standard = RadioButton(self, function()
            local radioGroup = axutils.childWithRole(self:UI(), "AXRadioGroup")
            return radioGroup and axutils.childFromLeft(radioGroup, 1)
        end)
    end
    return self._standard
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:toDo() -> RadioButton
--- Method
--- Gets the "To Do" Marker button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `RadioButton` object.
function BrowserMarkerPopover:toDo()
    if not self._toDo then
        self._toDo = RadioButton(self, function()
            local radioGroup = axutils.childWithRole(self:UI(), "AXRadioGroup")
            return radioGroup and axutils.childFromLeft(radioGroup, 2)
        end)
    end
    return self._toDo
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:chapter() -> RadioButton
--- Method
--- Gets the "Chapter" Marker button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `RadioButton` object.
function BrowserMarkerPopover:chapter()
    if not self._chapter then
        self._chapter = RadioButton(self, function()
            local radioGroup = axutils.childWithRole(self:UI(), "AXRadioGroup")
            return radioGroup and axutils.childFromLeft(radioGroup, 3)
        end)
    end
    return self._chapter
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:done() -> Button
--- Method
--- Gets the "Done" button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function BrowserMarkerPopover:done()
    if not self._done then
        self._done = Button(self, function()
            local buttons = axutils.childrenWithRole(self:UI(), "AXButton")
            return buttons and buttons[1]
        end)
    end
    return self._done
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:delete() -> Button
--- Method
--- Gets the "Delete" button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function BrowserMarkerPopover:delete()
    if not self._delete then
        self._delete = Button(self, function()
            local buttons = axutils.childrenWithRole(self:UI(), "AXButton")
            return buttons and buttons[2]
        end)
    end
    return self._delete
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:completed() -> CheckBox
--- Method
--- Gets the "Completed" checkbox. This only available if you have a "To Do" marker selected.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function BrowserMarkerPopover:completed()
    if not self._completed then
        self._completed = CheckBox(self, function()
            local checkbox = axutils.childrenWithRole(self:UI(), "AXCheckBox")
            return checkbox and checkbox[1]
        end)
    end
    return self._completed
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:name() -> TextField
--- Method
--- Gets the Marker Name text field.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `TextField` object.
function BrowserMarkerPopover:name()
    if not self._name then
        self._name = TextField(self, function()
            return axutils.childWithRole(self:UI(), "AXTextField")
        end)
    end
    return self._name
end

return BrowserMarkerPopover
