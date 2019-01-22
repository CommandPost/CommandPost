--- === cp.apple.finalcutpro.browser.Columns ===
---
--- Final Cut Pro Browser List View Columns

local require = require

--local log                   = require("hs.logger").new("Columns")

local geometry              = require("hs.geometry")

local axutils               = require("cp.ui.axutils")
local tools                 = require("cp.tools")

local Element               = require("cp.ui.Element")
local Menu                  = require("cp.ui.Menu")

local childWithRole         = axutils.childWithRole

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Columns = Element:subclass("cp.apple.finalcutpro.browser.Columns")

--- cp.apple.finalcutpro.browser.Columns(parent) -> Columns
--- Constructor
--- Constructs a new Columns object.
---
--- Parameters:
--- * parent - The parent object
---
--- Returns:
--- * The new `Columns` instance.
function Columns:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return childWithRole(original(), "AXScrollArea")
    end)
    Element.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.browser.Columns:show() -> self
--- Method
--- Shows the Browser List View columns menu popup.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function Columns:show()
    local ui = self:UI()
    if ui then
        local frame = ui:attributeValue("AXFrame")
        if frame then
            local point = geometry.point(frame.w/2, frame.y+4)
            tools.ninjaRightMouseClick(point)
        end
    end
    return self
end

--- cp.apple.finalcutpro.browser.Columns:isMenuShowing() -> boolean
--- Method
--- Is the Columns menu popup showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the columns menu popup is showing, otherwise `false`
function Columns:isMenuShowing()
    return self:menu():isShowing()
end

--- cp.apple.finalcutpro.browser.Columns:menu() -> cp.ui.Menu
--- Method
--- Gets the Columns menu object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Menu` object.
function Columns.lazy.method:menu()
    return Menu(self, self.UI:mutate(function(original)
        return childWithRole(childWithRole(childWithRole(original(), "AXOutline"), "AXGroup"), "AXMenu")
    end))
end

return Columns
