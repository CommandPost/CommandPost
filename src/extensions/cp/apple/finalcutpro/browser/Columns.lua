--- === cp.apple.finalcutpro.browser.Columns ===
---
--- Final Cut Pro Browser List View Columns

local require = require

--local log                       = require("hs.logger").new("Columns")

local ax                        = require("hs._asm.axuielement")

local geometry                  = require("hs.geometry")

local axutils                   = require("cp.ui.axutils")
local tools                     = require("cp.tools")

local Element                   = require("cp.ui.Element")
local Menu                      = require("cp.ui.Menu")

local systemElementAtPosition   = ax.systemElementAtPosition
local childWithRole             = axutils.childWithRole

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
---  * parent - The parent object
---
--- Returns:
---  * The new `Columns` instance.
function Columns:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return childWithRole(original(), "AXScrollArea")
    end)
    Element.initialize(self, parent, UI)
end

--- getVisibleHeightOfAXOutline(ui) -> number | nil
--- Constructor
--- Gets the visible height of an `AXOutline` object.
---
--- Parameters:
---  * ui - The `AXOutline` object to check.
---
--- Returns:
---  * The height of the visible area of the `AXOutline` or `nil` if something goes wrong.
local function getVisibleHeightOfAXOutline(ui)
    if ui then
        local visibleRows = ui:attributeValue("AXVisibleRows")
        if visibleRows and #visibleRows >= 1 then
            local firstRowUI = ui:attributeValue("AXChildren")[1]
            local lastRowUI = ui:attributeValue("AXChildren")[#visibleRows]
            if firstRowUI and lastRowUI then
                local firstFrame = firstRowUI:attributeValue("AXFrame")
                local lastFrame = lastRowUI:attributeValue("AXFrame")
                local top = firstFrame and firstFrame.y
                local bottom = lastFrame and lastFrame.y + lastFrame.h
                if top and bottom then
                    return bottom - top
                end
            end
        end
    end
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
        local scrollAreaFrame = ui:attributeValue("AXFrame")
        local outlineUI = childWithRole(ui, "AXOutline")
        local visibleHeight = getVisibleHeightOfAXOutline(outlineUI)
        local outlineFrame = outlineUI and outlineUI:attributeValue("AXFrame")
        if scrollAreaFrame and outlineFrame and visibleHeight then
            local headerHeight = (scrollAreaFrame.h - visibleHeight) / 2
            local point = geometry.point(scrollAreaFrame.x+headerHeight, scrollAreaFrame.y+headerHeight)
            local element = point and systemElementAtPosition(point)
            if element and element:attributeValue("AXParent"):attributeValue("AXParent") == outlineUI then
                --cp.dev.highlightPoint(point)
                tools.ninjaRightMouseClick(point)
            end
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
