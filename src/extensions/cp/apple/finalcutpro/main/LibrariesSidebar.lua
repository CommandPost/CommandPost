--- === cp.apple.finalcutpro.main.LibrariesSidebar ===
---
--- Libraries Sidebar Browser Module.

local require = require

--local log						= require "hs.logger".new "LibrariesSidebar"

local axutils                   = require "cp.ui.axutils"
local Table						= require "cp.ui.Table"

local childMatching             = axutils.childMatching

local LibrariesSidebar = Table:subclass("cp.apple.finalcutpro.main.LibrariesSidebar")

function LibrariesSidebar.static.matches(element)
    return element and element:attributeValue("AXRole") == "AXScrollArea"
    and element:attributeValueCount("AXChildren") >= 1
    and element:attributeValue("AXChildren")[1]:attributeValueCount("AXChildren") ~= 0
end

--- cp.apple.finalcutpro.main.LibrariesSidebar(parent) -> LibrariesSidebar
--- Constructor
--- Creates a new `LibrariesSidebar` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `LibrariesSidebar` object.
function LibrariesSidebar:initialize(parent)
    local UI = parent.mainGroupUI:mutate(function(original)
        local mainGroupUI = original()
        return mainGroupUI and childMatching(mainGroupUI, LibrariesSidebar.matches)
    end)
    Table.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.main.LibrariesSidebar:show() -> LibrariesSidebar
--- Method
--- Show the Libraries Sidebar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `LibrariesSidebar` object.
function LibrariesSidebar:show()
    self:parent():show()
    if not self:isShowing() then
        self:parent():parent():showLibraries():press()
    end
    return self
end

--- cp.apple.finalcutpro.main.LibrariesSidebar:selectActiveLibrary() -> LibrariesSidebar
--- Method
--- Selects the active library.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `LibrariesSidebar` object.
function LibrariesSidebar:selectActiveLibrary()
    local scrollArea = self:UI()
    local outline = scrollArea and scrollArea[1]
    if outline and outline:attributeValue("AXRole") == "AXOutline" then
        local children = outline:attributeValue("AXChildren")
        if children then
            local foundSelected = false
            for i=#children, 1, -1 do
                local child = children[i]
                if child and child:attributeValue("AXSelected") then
                    foundSelected = true
                end
                if foundSelected then
                    if child and child:attributeValue("AXDisclosureLevel") == 0 then
                        outline:setAttributeValue("AXSelectedRows", {child})
                        break
                    end
                end
            end
        end
    end
    return self
end

return LibrariesSidebar