--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.text.TitleInspector ===
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
--- local text = fcp:inspector():text()
--- -- Menu Property:
--- text:compositing():blendMode():value("Subtract")
--- -- Slider Property:
--- text:compositing():opacity():value(50.0)
--- -- XY Property:
--- text:transform():position():x(-10.0)
--- -- CheckBox property:
--- text:stabilization():tripodMode():value(true)
--- ```
---
--- You should also be able to show a specific property and it will be revealed:
--- ```lua
--- text:stabilization():smoothing():show():value(1.5)
--- ```


--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("textInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")
local PopUpButton                       = require("cp.ui.PopUpButton")
local MenuButton                        = require("cp.ui.MenuButton")

local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local childFromRight                    = axutils.childFromRight
local hasProperties, simple             = IP.hasProperties, IP.simple
local section, slider                   = IP.section, IP.slider

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TitleInspector = {}

--- cp.apple.finalcutpro.inspector.text.TitleInspector.matches(element)
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
            local scrollArea = element[1]
            if scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and #scrollArea > 1 then
                return PopUpButton.matches(scrollArea[1])
            end
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.text.TitleInspector.new(parent) -> cp.apple.finalcutpro.text.TitleInspector
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
                    local scrollArea = ui[1]
                    return scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and scrollArea
                end
                return nil
            end)
        end),
    }

    -- The 'Shape Preset' popup

    o.shapePreset = PopUpButton.new(o, function()
        local ui = o.contentUI()
        return ui and PopUpButton.matches(ui[1]) and ui[1]
    end)

    -- specify that the `contentUI` contains the PropertyRows.
    hasProperties(o, o.contentUI) {
        basic             = section "basic viewset" {
            font            = simple("XXX", function(row)
                row.face        = MenuButton.new(row, function()
                    return childFromRight(row:children(), 2, MenuButton.matches)
                end)
                row.face        = MenuButton.new(row, function()
                    return childFromRight(row:children(), 1, MenuButton.matches)
                end)
            end),
            size            = slider "XXX",
            -- alignment            = simple("XXX", function(row)
            -- end),
            -- verticalAlignment    = simple("XXX", function(row)
            -- end),
        },

    }

    return o
end

--- cp.apple.finalcutpro.inspector.text.TitleInspector:parent() -> table
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

--- cp.apple.finalcutpro.inspector.text.TitleInspector:app() -> table
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

--- cp.apple.finalcutpro.inspector.text.TitleInspector:show() -> TitleInspector
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