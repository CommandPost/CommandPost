--- === cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover ===
---
--- Browser Marker Popup.

local require = require

--local log                             = require "hs.logger".new("browser")

--local inspect                         = require "hs.inspect"

local axutils                           = require "cp.ui.axutils"
local Element                           = require "cp.ui.Element"
local Button							= require "cp.ui.Button"
local CheckBox                          = require "cp.ui.CheckBox"
local just                              = require "cp.just"
local RadioButton					    = require "cp.ui.RadioButton"
local RadioGroup                        = require "cp.ui.RadioGroup"
local TextField							= require "cp.ui.TextField"

local cache, childMatching              = axutils.cache, axutils.childMatching
local childFromLeft, childWithRole      = axutils.childFromLeft, axutils.childWithRole


local BrowserMarkerPopover = Element:subclass("cp.apple.finalcutpro.main.BrowserMarkerPopover")

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Browser Marker Popover or not
---
--- Parameters:
---  * element - The element you want to check
---
--- Returns:
---  * `true` if the `element` is the Browser Marker Popover otherwise `false`
function BrowserMarkerPopover.static.matches(element)
    return Element.matches(element) and #element >= 5 and element:attributeValue("AXRole") == "AXPopover"
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover(parent) -> BrowserMarkerPopover
--- Constructor
--- Constructs a new Browser Marker Popover
---
--- Parameters:
--- * parent - The parent object
---
--- Returns:
--- * The new `BrowserMarkerPopover` instance.
function BrowserMarkerPopover:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), BrowserMarkerPopover.matches)
        end,
        BrowserMarkerPopover.matches)
    end)

    Element.initialize(self, parent, UI)
end

-----------------------------------------------------------------------
--
-- MARKER POPOVER UI:
--
-----------------------------------------------------------------------

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
        self:done()
    end
    just.doWhile(function() return self:isShowing() end)
    return self
end

-----------------------------------------------------------------------
--
-- UI ITEMS:
--
-----------------------------------------------------------------------

function BrowserMarkerPopover.lazy.value:type()
    return RadioGroup(self, self.UI:mutate(function(original)
        return cache(self, "_type", function()
            return childMatching(original(), RadioGroup.matches)
        end,
        RadioGroup.matches
    )
    end))
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover:standard() -> RadioButton
--- Method
--- Gets the "Standard" Marker button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `RadioButton` object.
function BrowserMarkerPopover.lazy.method:standard()
    return RadioButton(self, self.type.UI:mutate(function(original)
        return childFromLeft(original(), 1)
    end))
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
function BrowserMarkerPopover.lazy.method:toDo()
    return RadioButton(self, self.type.UI:mutate(function(original)
        return childFromLeft(original(), 2)
    end))
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.chapter() -> RadioButton
--- Method
--- Gets the "Chapter" Marker button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `RadioButton` object.
function BrowserMarkerPopover.lazy.method:chapter()
    return RadioButton(self, self.type.UI:mutate(function(original)
        return childFromLeft(original(), 3)
    end))
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.done <cp.ui.Button>
--- Field
--- The "Done" [Button](cp.ui.Button.md).
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function BrowserMarkerPopover.lazy.value:done()
    return Button(self, self.UI:mutate(function(original)
        return childWithRole(original(), "AXButton", 1)
    end))
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.delete <cp.ui.Button>
--- Field
--- Gets the "Delete" [Button](cp.ui.Button.md).
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function BrowserMarkerPopover.lazy.value:delete()
    return Button(self, self.UI:mutate(function(original)
        return childWithRole(original(), "AXButton", 2)
    end))
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.completed <cp.ui.CheckBox>
--- Field
--- Gets the "Completed" checkbox. This only available if you have a "To Do" marker selected.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function BrowserMarkerPopover.lazy.value:completed()
    return CheckBox(self, self.UI:mutate(function(original)
        return childWithRole(original(), "AXCheckBox")
    end))
end

--- cp.apple.finalcutpro.main.Browser.BrowserMarkerPopover.name <cp.ui.TextField>
--- Field
--- Gets the Marker Name [TextField](cp.ui.TextField.md).
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `TextField` object.
function BrowserMarkerPopover.lazy.value:name()
    return TextField(self, self.UI:mutate(function(original)
        return childWithRole(original(), "AXTextField")
    end))
end

return BrowserMarkerPopover
