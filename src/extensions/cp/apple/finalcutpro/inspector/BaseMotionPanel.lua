--- === cp.apple.finalcutpro.inspector.BaseMotionPanel ===
---
--- A base class for [Inspector](cp.apple.finalcutpro.inspector.Inspector.md) panels
--- that publish Motion parameters.
---
--- Extends [BasePanel](cp.apple.finalcutpro.inspector.BasePanel.md).

local require = require

local log								= require("hs.logger").new("bseMtnPnl")

local axutils							= require("cp.ui.axutils")

local BasePanel                         = require("cp.apple.finalcutpro.inspector.BasePanel")
local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local strings                           = require("cp.apple.finalcutpro.strings")
local hasProperties                     = IP.hasProperties
local section                           = IP.section

local withRole, childWithRole, withValue    = axutils.withRole, axutils.childWithRole, axutils.withValue
local cache                             = axutils.cache

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local BaseMotionPanel = BasePanel:subclass("cp.apple.finalcutpro.inspector.BaseMotionPanel")

local function findContentUI(element)
    local root = BasePanel.matches(element) and withRole(element, "AXGroup")
    local group = root and #root == 1 and childWithRole(root, "AXGroup")
    return group and #group == 1 and childWithRole(group, "AXScrollArea")
end

--- cp.apple.finalcutpro.inspector.BaseMotionPanel.matches(element)
--- Function
--- Checks if the provided element could be a BaseMotionPanel.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
function BaseMotionPanel.static.matches(element)
    local scrollArea = findContentUI(element)
    local title = scrollArea and #scrollArea > 1 and childWithRole(scrollArea, "AXStaticText")
    return title and withValue(title, strings:find("Inspector Published Parameters Heading")) or false
end

--- cp.apple.finalcutpro.inspector.BaseMotionPanel(parent, panelType) -> cp.apple.finalcutpro.inspector.BaseMotionPanel
--- Constructor
--- Creates a new `BaseMotionPanel` object
---
--- Parameters:
---  * `parent`		- The parent
---  * `panelType`  - The panel type.
---
--- Returns:
---  * A `BaseMotionPanel` object
function BaseMotionPanel:initialize(parent, panelType)
    BasePanel.initialize(self, parent, panelType)

    -- specify that the `contentUI` contains the PropertyRows.
    hasProperties(self, self.contentUI) {

--- cp.apple.finalcutpro.inspector.BaseMotionPanel.published <cp.prop: cp.ui.PropertyRow; read-only>
--- Field
--- The 'Published Parameters' section.
        published             = section "Inspector Published Parameters Heading" {},
    }
end

--- cp.apple.finalcutpro.inspector.BaseMotionPanel.contentUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The primary content `axuielement` for the panel.
function BaseMotionPanel.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return cache(self, "_content",
            function()
                local ui = findContentUI(original())
                return ui
            end,
            function(element) return withRole(element, "AXScrollArea") ~= nil end
        )
    end)
end

return BaseMotionPanel
