--- === cp.apple.finalcutpro.inspector.text.TextInspector ===
---
--- Text Inspector Module.
---
--- Section Rows (`compositing`, `transform`, etc.) have the following properties:
---  * enabled   - (cp.ui.CheckBox) Indicates if the section is enabled.
---  * toggle    - (cp.ui.Button) Will toggle the Hide/Show button.
---  * reset     - (cp.ui.Button) Will reset the contents of the section.
---  * expanded  - (cp.prop <boolean>) Get/sets whether the section is expanded.
---
--- Property Rows depend on the type of property:
---
--- Menu Property:
---  * value     - (cp.ui.PopUpButton) The current value of the property.
---
--- Slider Property:
---  * value     - (cp.ui.Slider) The current value of the property.
---
--- XY Property:
---  * x         - (cp.ui.TextField) The current 'X' value.
---  * y         - (cp.ui.TextField) The current 'Y' value.
---
--- CheckBox Property:
---  * value     - (cp.ui.CheckBox) The currently value.
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

local require = require

-- local log								= require("hs.logger").new("textInspect")

local axutils							= require("cp.ui.axutils")
local CheckBox                          = require("cp.ui.CheckBox")
local Group                             = require("cp.ui.Group")
local PopUpButton                       = require("cp.ui.PopUpButton")
local RadioButton                       = require("cp.ui.RadioButton")
local RadioGroup                        = require("cp.ui.RadioGroup")

local BasePanel                         = require("cp.apple.finalcutpro.inspector.BasePanel")
local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local childFromLeft, childFromRight     = axutils.childFromLeft, axutils.childFromRight
local withRole, childWithRole           = axutils.withRole, axutils.childWithRole
local hasProperties, simple             = IP.hasProperties, IP.simple
local section, slider, popUpButton, checkBox = IP.section, IP.slider, IP.popUpButton, IP.checkBox

local If                                = require("cp.rx.go.If")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TextInspector = BasePanel:subclass("cp.apple.finalcutpro.inspector.text.TextInspector")

--- cp.apple.finalcutpro.inspector.text.TextInspector.matches(element)
--- Function
--- Checks if the provided element could be a TextInspector.
---
--- Parameters:
---  * element   - The element to check
---
--- Returns:
---  * `true` if it matches, `false` if not.
function TextInspector.static.matches(element)
    local root = BasePanel.matches(element) and withRole(element, "AXGroup")
    local scroll = root and #root == 1 and childWithRole(root, "AXScrollArea")
    return scroll and #scroll > 1 and PopUpButton.matches(scroll[1]) or false
end

--- cp.apple.finalcutpro.inspector.text.TextInspector(parent) -> cp.apple.finalcutpro.text.TextInspector
--- Constructor
--- Creates a new `TextInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `TextInspector` object
function TextInspector:initialize(parent)
    BasePanel.initialize(self, parent)

    -- specify that the `contentUI` contains the PropertyRows.
    hasProperties(self, self.contentUI) {
        basic             = section "FCP Text Inspector Basic Heading" {
            font            = simple("Text Font Folder", function(row)
                row.family        = PopUpButton(row, function()
                    return childFromRight(row, 2, PopUpButton.matches)
                end)
                row.typeface        = PopUpButton(row, function()
                    return childFromRight(row, 1, PopUpButton.matches)
                end)
            end),
            size            = slider "Text Format Size",
            alignment       = simple("Text Paragraph Alignment", function(row)
                row.flush = Group(row, function()
                    return childFromRight(row, 2, Group.matches)
                end)

                row.left = CheckBox(row, function()
                    return childFromLeft(row.flush:UI(), 1, CheckBox.matches)
                end)
                row.center = CheckBox(row, function()
                    return childFromLeft(row.flush:UI(), 2, CheckBox.matches)
                end)
                row.right = CheckBox(row, function()
                    return childFromLeft(row.flush:UI(), 3, CheckBox.matches)
                end)

                row.justified = Group(row, function()
                    return childFromRight(row, 1, Group.matches)
                end)

                row.justifiedLeft = CheckBox(row, function()
                    return childFromLeft(row.justified:UI(), 1, CheckBox.matches)
                end)

                row.justifiedCenter = CheckBox(row, function()
                    return childFromLeft(row.justified:UI(), 2, CheckBox.matches)
                end)

                row.justifiedRight = CheckBox(row, function()
                    return childFromLeft(row.justified:UI(), 3, CheckBox.matches)
                end)

                row.justifiedFull = CheckBox(row, function()
                    return childFromLeft(row.justified:UI(), 4, CheckBox.matches)
                end)
            end),
            verticalAlignment    = simple("Text Layout Vertical Alignment", function(row)
                row.options = RadioGroup(row, function()
                    return childFromLeft(row:children(), 1, RadioGroup.matches)
                end)

                row.top = RadioButton(row, function()
                    return childFromLeft(row.options:UI(), 1)
                end)

                row.middle = RadioButton(row, function()
                    return childFromLeft(row.options:UI(), 2)
                end)

                row.bottom = RadioButton(row, function()
                    return childFromLeft(row.options:UI(), 3)
                end)
            end),
            lineSpacing         = slider "Text Layout Line Spacing",
            tracking            = slider "Text Format Tracking",
            kerning             = slider "Text Format Kerning",
            baseline            = slider "Text Format Baseline",
            allCaps             = checkBox "Text Format All Caps",
            allCapsSize         = slider "Text Format All Caps Size",
        },
        threeDeeText        = section "Text Style 3D Extrusion Properties" {
            depth               = slider "3D Property Extrusion Depth",
            depthDirection      = popUpButton "Bevel Properties Extrude Direction",
            weight              = slider "3D Property Extrusion Weight",
            frontEdge           = popUpButton "Bevel Properties Front Edge Profile",
            frontEdgeSize       = slider "Bevel Properties Front Edge Size",
            backEdge            = popUpButton "Bevel Properties Back Edge Profile",
            insideCorners       = popUpButton "Bevel Properties Corner Style",
        },
        lighting            = section "Extrusion Properties Lighting Folder" {
            lightingStyle       = popUpButton "Bevel Properties Lighting Style",
            intensity           = slider "Bevel Properties Lighting Style Intensity",
            selfShadows         = section "Extrusion Properties Self Shadows Folder" {
                opacity             = slider "Extrusion Properties Self Shadows Opacity",
                softness            = slider "Extrusion Properties Self Shadows Softness",
            },
            environment         = section "Material Environment Properties" {
                type                = popUpButton "Material Environment Type",
                intensity           = slider "Material Environment Intensity",
                rotation            = slider "Material Environment Rotation",
                contrast            = slider "Material Environment Contrast",
                saturation          = slider "Material Environment Saturation",
                anisotropic         = checkBox "Material Environment Anisotropy Enable",
            },
        },
        -- TODO: skipping "Material" for now...
        face                = section "Text Face" {
            fillWith            = popUpButton "Text Face Color Source",
            -- TODO: Add a 'ColorWell' option.
            color               = simple "Text Face Color",
            -- TODO: Complete 'Gradient' options.
            gradient            = section "Text Face Gradient" {},
            opacity             = slider "Text Face Opacity",
            blur                = slider "Text Face Blur",
        },
        outline             = section "Text Outline" {
            fillWith            = popUpButton "Text Outline Color Source",
            -- TODO: Add a 'ColorWell' option.
            color               = simple "Text Outline Color",
            opacity             = slider "Text Outline Opacity",
            blur                = slider "Text Outline Blur",
            width               = slider "Text Outline Width",
        },
        glow                = section "Text Glow" {
            fillWith            = popUpButton "Text Glow Color Source",
            -- TODO: Add a 'ColorWell' option.
            color               = simple "Text Glow Color",
            opacity             = slider "Text Glow Opacity",
            blur                = slider "Text Glow Blur",
            radius              = slider "Text Glow Radius",
        },
        dropShadow          = section "Text Drop Shadow" {
            fillWith            = popUpButton "Text Drop Shadow Color Source",
            -- TODO: Add a 'ColorWell' option.
            color               = simple "Text Drop Shadow Color",
            opacity             = slider "Text Drop Shadow Opacity",
            blur                = slider "Text Drop Shadow Blur",
            distance            = slider "Text Drop Shadow Distance",
            angle               = slider "Text Drop Shadow Angle",
        },
    }
end

--- cp.apple.finalcutpro.inspector.color.TextInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
function TextInspector.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_contentUI", function()
            local ui = original()
            if ui then
                local scrollArea = ui[1]
                return scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and scrollArea or nil
            end
            return nil
        end)
    end)
end

-- The 'Shape Preset' popup
function TextInspector.lazy.value:shapePreset()
    return PopUpButton(self, function()
        local ui = self.contentUI()
        return ui and PopUpButton.matches(ui[1]) and ui[1]
    end)
end

--------------------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.text.TextInspector:show() -> TextInspector
--- Method
--- Shows the Text Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * TextInspector
function TextInspector:show()
    if not self:isShowing() then
        self:parent():selectTab("Text")
    end
    return self
end


--- cp.apple.finalcutpro.inspector.text.TextInspector:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Text Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function TextInspector.lazy.method:doShow()
    return If(self.isShowing):IsNot(true)
    :Then(self:parent():doSelectTab("Text"))
    :Label("TextInspector:doShow")
end

--- cp.apple.finalcutpro.inspector.text.TextInspector:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that hides the Text Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function TextInspector.lazy.method:doHide()
    return If(self.isShowing)
    :Then(self:parent():doHide())
    :Label("TextInspector:doHide")
end

return TextInspector
