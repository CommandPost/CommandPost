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

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("shareInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")
local StaticText                        = require("cp.ui.StaticText")

local strings                           = require("cp.apple.finalcutpro.strings")
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
local ShareInspector = {}

--- cp.apple.finalcutpro.inspector.share.ShareInspector.matches(element)
--- Function
--- Checks if the provided element could be a ShareInspector.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
function ShareInspector.matches(element)
    if element then
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
function ShareInspector.new(parent)
    local o
    o = prop.extend({
        _parent = parent,
        _child = {},
        _rows = {},

--- cp.apple.finalcutpro.inspector.color.ShareInspector.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object for the Share Inspector.
        UI = parent.panelUI:mutate(function(original)
            return axutils.cache(o, "_ui",
                function()
                    local ui = original()
                    return ShareInspector.matches(ui) and ui or nil
                end,
                ShareInspector.matches
            )
        end),

    }, ShareInspector)

    prop.bind(o) {
--- cp.apple.finalcutpro.inspector.color.ShareInspector.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the ShareInspector is currently showing.
        isShowing = o.UI:mutate(function(original)
            return original() ~= nil
        end),

--- cp.apple.finalcutpro.inspector.color.ShareInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
        contentUI = o.UI:mutate(function(original)
            return axutils.cache(o, "_contentUI", function()
                local ui = original()
                if ui then
                    local scrollArea = ui[1][1]
                    return scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and scrollArea or nil
                end
                return nil
            end)
        end),
    }

    -- specify that the `contentUI` contains the PropertyRows.
    hasProperties(o, o.contentUI) {
        published             = section "Inspector Published Parameters Heading" {},
    }

    return o
end

--- cp.apple.finalcutpro.inspector.share.ShareInspector:parent() -> table
--- Method
--- Returns the ShareInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ShareInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.share.ShareInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ShareInspector:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.share.ShareInspector:show() -> ShareInspector
--- Method
--- Shows the Share Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * ShareInspector
function ShareInspector:show()
    if not self:isShowing() then
        self:parent():selectTab("Share")
    end
    return self
end

return ShareInspector
