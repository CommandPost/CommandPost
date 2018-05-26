--- === cp.apple.finalcutpro.inspector.title.TitleInspector ===
---
--- Title Inspector Module.
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
--- local title = fcp:inspector():title()
--- -- Menu Property:
--- title:compositing():blendMode():value("Subtract")
--- -- Slider Property:
--- title:compositing():opacity():value(50.0)
--- -- XY Property:
--- title:transform():position():x(-10.0)
--- -- CheckBox property:
--- title:stabilization():tripodMode():value(true)
--- ```
---
--- You should also be able to show a specific property and it will be revealed:
--- ```lua
--- title:stabilization():smoothing():show():value(1.5)
--- ```

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("titleInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local hasProperties                     = IP.hasProperties
local section                           = IP.section

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TitleInspector = {}

--- cp.apple.finalcutpro.inspector.title.TitleInspector.matches(element)
--- Function
--- Checks if the provided element could be a TitleInspector.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
function TitleInspector.matches(element)
    if element then
        if element:attributeValue("AXRole") == "AXGroup" and #element == 1 then
            local group = element[1]
            if group:attributeValue("AXRole") == "AXGroup" and #group == 1 then
                local scrollArea = group[1]
                if scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and #scrollArea > 1 then
                    local publishedParams = scrollArea[1]
                    return publishedParams and publishedParams:attributeValue("AXRole") == "AXStaticText"
                end
            end
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.title.TitleInspector.new(parent) -> cp.apple.finalcutpro.title.TitleInspector
--- Constructor
--- Creates a new `TitleInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `TitleInspector` object
function TitleInspector.new(parent)
    local o
    o = prop.extend({
        _parent = parent,
        _child = {},
        _rows = {},

--- cp.apple.finalcutpro.inspector.color.TitleInspector.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object for the Title Inspector.
        UI = parent.panelUI:mutate(function(original)
            return axutils.cache(o, "_ui",
                function()
                    local ui = original()
                    return TitleInspector.matches(ui) and ui or nil
                end,
                TitleInspector.matches
            )
        end),

    }, TitleInspector)

    prop.bind(o) {
--- cp.apple.finalcutpro.inspector.color.TitleInspector.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the TitleInspector is currently showing.
        isShowing = o.UI:mutate(function(original)
            return original() ~= nil
        end),

--- cp.apple.finalcutpro.inspector.color.TitleInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
        contentUI = o.UI:mutate(function(original)
            return axutils.cache(o, "_contentUI", function()
                local ui = original()
                if ui then
                    local scrollArea = ui[1][1]
                    return scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and scrollArea
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

--- cp.apple.finalcutpro.inspector.title.TitleInspector:parent() -> table
--- Method
--- Returns the TitleInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function TitleInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.title.TitleInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function TitleInspector:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.title.TitleInspector:show() -> TitleInspector
--- Method
--- Shows the Title Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * TitleInspector
function TitleInspector:show()
    if not self:isShowing() then
        self:parent():selectTab("Title")
    end
    return self
end

return TitleInspector