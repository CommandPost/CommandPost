--- === cp.apple.finalcutpro.inspector.share.ShareInspector ===
---
--- Share Inspector Module.
---
--- Section Rows (`compositing`, `transform`, etc.) have the following properties:
--- * enabled   - (cp.ui.CheckBox) Indicates if the section is enabled.
--- * toggle    - (cp.ui.Button) Will toggle the Hide/Show button.
--- * reset     - (cp.ui.Button) Will reset the contents of the section.
--- * expanded  - (cp.prop <boolean>) Get/sets whether the section is expanded.
---
--- Property Rows depend on the type of property:
---
--- Menu Property:
--- * value     - (cp.ui.PopUpButton) The current value of the property.
---
--- Slider Property:
--- * value     - (cp.ui.Slider) The current value of the property.
---
--- XY Property:
--- * x         - (cp.ui.TextField) The current 'X' value.
--- * y         - (cp.ui.TextField) The current 'Y' value.
---
--- CheckBox Property:
--- * value     - (cp.ui.CheckBox) The currently value.
---
--- For example:
--- ```lua
--- local share = fcp:inspector():share()
--- -- Menu Property:
--- share:compositing():blendMode():value("Subtract")
--- -- Slider Property:
--- share:compositing():opacity():value(50.0)
--- -- XY Property:
--- share:transform():position():x(-10.0)
--- -- CheckBox property:
--- share:stabilization():tripodMode():value(true)
--- ```
---
--- You should also be able to show a specific property and it will be revealed:
--- ```lua
--- share:stabilization():smoothing():show():value(1.5)
--- ```

local require = require

-- local log								= require("hs.logger").new("shareInspect")

local axutils							= require("cp.ui.axutils")
local StaticText                        = require("cp.ui.StaticText")

local strings                           = require("cp.apple.finalcutpro.strings")
local BasePanel                         = require("cp.apple.finalcutpro.inspector.BasePanel")
local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local childFromBottom, childFromTop     = axutils.childFromBottom, axutils.childFromTop
local hasAttributeValue                 = axutils.hasAttributeValue

local hasProperties                     = IP.hasProperties
local section                           = IP.section

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ShareInspector = BasePanel:subclass("cp.apple.finalcutpro.inspector.ShareInspector")

--- cp.apple.finalcutpro.inspector.share.ShareInspector.matches(element)
--- Function
--- Checks if the provided element could be a ShareInspector.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
function ShareInspector.static.matches(element)
    if BasePanel.matches(element) then
        if element:attributeValue("AXRole") == "AXGroup" and #element > 1 then
            local scrollArea = childFromBottom(element, 1)
            if scrollArea:attributeValue("AXRole") == "AXScrollArea" then
                local attributesLabel = strings:find("FFInspectorModuleProjectSharingTitle")
                local attributesUI = childFromTop(scrollArea, 1, StaticText.matches)
                return hasAttributeValue(attributesUI, "AXValue", attributesLabel)
            end
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.share.ShareInspector.new(parent) -> cp.apple.finalcutpro.share.ShareInspector
--- Constructor
--- Creates a new `ShareInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `ShareInspector` object
function ShareInspector:initialize(parent)
    BasePanel.initialize(self, parent, "Share")

    -- specify that the `contentUI` contains the PropertyRows.
    hasProperties(self, self.contentUI) {
        published             = section "Inspector Published Parameters Heading" {},
    }
end

--- cp.apple.finalcutpro.inspector.color.ShareInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
function ShareInspector.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_contentUI", function()
            local ui = original()
            if ui then
                local scrollArea = ui[1][1]
                return scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and scrollArea or nil
            end
            return nil
        end)
    end)
end

return ShareInspector
