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

--local log                             = require("hs.logger").new("textInspect")

local axutils                           = require("cp.ui.axutils")
local If                                = require("cp.rx.go.If")
local tools                             = require("cp.tools")

local Button                            = require("cp.ui.Button")
local CheckBox                          = require("cp.ui.CheckBox")
local Group                             = require("cp.ui.Group")
local PopUpButton                       = require("cp.ui.PopUpButton")
local RadioButton                       = require("cp.ui.RadioButton")
local RadioGroup                        = require("cp.ui.RadioGroup")
local ScrollArea                        = require("cp.ui.ScrollArea")
local StaticText                        = require("cp.ui.StaticText")
local TextArea                          = require("cp.ui.TextArea")
local TextField                         = require("cp.ui.TextField")

local BasePanel                         = require("cp.apple.finalcutpro.inspector.BasePanel")
local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local childFromBottom                   = axutils.childFromBottom
local childFromLeft                     = axutils.childFromLeft
local childFromRight                    = axutils.childFromRight
local childFromTop                      = axutils.childFromTop
local childrenInLine                    = axutils.childrenInLine
local childrenInNextLine                = axutils.childrenInNextLine
local childWithRole                     = axutils.childWithRole
local withRole                          = axutils.withRole

local hasProperties, simple             = IP.hasProperties, IP.simple
local popUpButton, checkBox             = IP.popUpButton, IP.checkBox
local section, slider                   = IP.section, IP.slider

local toRegionalNumber                  = tools.toRegionalNumber
local toRegionalNumberString            = tools.toRegionalNumberString


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
---  * `parent`     - The parent
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
            position            = section "Text Sequence Channel Position" {}
                                  :extend(function(row)
                                        row.x   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 3]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                        row.y   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 3 + 4]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                        row.z   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 3 + 4 + 4]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                   end),
            rotation            = section "Text Sequence Channel Rotation" {}
                                  :extend(function(row)
                                        row.x   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 6]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                        row.y   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 6 + 5]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                        row.z   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 6 + 5 + 5]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                  row.animate   =   PopUpButton(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 6 + 5 + 5 + 2]
                                                    end)
                                   end),
            scale               = section "Text Format Scale" {}
                                  :extend(function(row)
                                   row.master   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local children = rowUI and childrenInLine(rowUI)
                                                        return children and childFromLeft(children, 1, TextField.matches)
                                                    end, toRegionalNumber, toRegionalNumberString)
                                        row.x   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 7]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                        row.y   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 7 + 5]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                        row.z   =   TextField(row, function()
                                                        local rowUI = row:UI()
                                                        local index = rowUI and axutils.childIndex(rowUI)
                                                        return rowUI and rowUI:attributeValue("AXParent")[index + 7 + 5 + 5]
                                                    end, toRegionalNumber, toRegionalNumberString)
                                   end),
        },
        threeDeeText        = section "Text Style 3D Extrusion Properties" {
            depth               = slider "3D Property Extrusion Depth",
            depthDirection      = popUpButton "Bevel Properties Extrude Direction",
            weight              = slider "3D Property Extrusion Weight",
            frontEdge           = popUpButton "Bevel Properties Front Edge Profile",
            frontEdgeSize       = simple("Bevel Properties Front Edge Size", function(row)
                                    row.master = TextField(row, function()
                                        local rowUI = row:UI()
                                        local children = rowUI and childrenInLine(rowUI)
                                        return children and childFromLeft(children, 1, TextField.matches)
                                    end)

                                    row.width = TextField(row, function()
                                        local rowUI = row:UI()
                                        local children = rowUI and childrenInNextLine(rowUI)
                                        local labelUI = children and childFromLeft(children, 1, StaticText.matches)
                                        if labelUI and labelUI:attributeValue("AXValue") == self:app():string("Text Sequence Channel OutlineWidth") then
                                            return childFromLeft(children, 1, TextField.matches)
                                        end
                                    end)

                                    row.depth = TextField(row, function()
                                        local rowUI = row:UI()
                                        local widthChildren = rowUI and childrenInNextLine(rowUI)
                                        local children = widthChildren and widthChildren[1] and childrenInNextLine(widthChildren[1])
                                        local labelUI = children and childFromLeft(children, 1, StaticText.matches)
                                        if labelUI and labelUI:attributeValue("AXValue") == self:app():string("3D Property Extrusion Depth") then
                                            return childFromLeft(children, 1, TextField.matches)
                                        end
                                    end)
                                  end),
            backEdge            = popUpButton "Bevel Properties Back Edge Profile",
            backEdgeSize       = simple("Bevel Properties Back Edge Size", function(row)
                                    row.master = TextField(row, function()
                                        local rowUI = row:UI()
                                        local children = rowUI and childrenInLine(rowUI)
                                        return children and childFromLeft(children, 1, TextField.matches)
                                    end)

                                    row.width = TextField(row, function()
                                        local rowUI = row:UI()
                                        local children = rowUI and childrenInNextLine(rowUI)
                                        local labelUI = children and childFromLeft(children, 1, StaticText.matches)
                                        if labelUI and labelUI:attributeValue("AXValue") == self:app():string("Text Sequence Channel OutlineWidth") then
                                            return childFromLeft(children, 1, TextField.matches)
                                        end
                                    end)

                                    row.depth = TextField(row, function()
                                        local rowUI = row:UI()
                                        local widthChildren = rowUI and childrenInNextLine(rowUI)
                                        local children = widthChildren and widthChildren[1] and childrenInNextLine(widthChildren[1])
                                        local labelUI = children and childFromLeft(children, 1, StaticText.matches)
                                        if labelUI and labelUI:attributeValue("AXValue") == self:app():string("3D Property Extrusion Depth") then
                                            return childFromLeft(children, 1, TextField.matches)
                                        end
                                    end)
                                  end),
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
                rotation            = simple("Material Environment Rotation", function(row)
                                            row.master = TextField(row, function()
                                                local rowUI = row:UI()
                                                local children = rowUI and childrenInLine(rowUI)
                                                return children and childFromLeft(children, 1, TextField.matches)
                                            end)

                                            row.x = TextField(row, function()
                                                local rowUI = row:UI()
                                                local children = rowUI and childrenInNextLine(rowUI)
                                                local labelUI = children and childFromLeft(children, 1, StaticText.matches)
                                                if labelUI and labelUI:attributeValue("AXValue") == "X" then
                                                    return childFromLeft(children, 1, TextField.matches)
                                                end
                                            end)

                                            row.y = TextField(row, function()
                                                local rowUI = row:UI()
                                                local xChildren = rowUI and childrenInNextLine(rowUI)
                                                local children = xChildren and xChildren[1] and childrenInNextLine(xChildren[1])
                                                local labelUI = children and childFromLeft(children, 1, StaticText.matches)
                                                if labelUI and labelUI:attributeValue("AXValue") == "Y" then
                                                    return childFromLeft(children, 1, TextField.matches)
                                                end
                                            end)

                                            row.z = TextField(row, function()
                                                local rowUI = row:UI()
                                                local xChildren = rowUI and childrenInNextLine(rowUI)
                                                local yChildren = xChildren and xChildren[1] and childrenInNextLine(xChildren[1])
                                                local children = yChildren and yChildren[1] and childrenInNextLine(yChildren[1])
                                                local labelUI = children and childFromLeft(children, 1, StaticText.matches)
                                                if labelUI and labelUI:attributeValue("AXValue") == "Z" then
                                                    return childFromLeft(children, 1, TextField.matches)
                                                end
                                            end)

                                            row.animate = PopUpButton(row, function()
                                                local rowUI = row:UI()
                                                local xChildren = rowUI and childrenInNextLine(rowUI)
                                                local yChildren = xChildren and xChildren[1] and childrenInNextLine(xChildren[1])
                                                local zChildren = yChildren and yChildren[1] and childrenInNextLine(yChildren[1])
                                                local children = zChildren and zChildren[1] and childrenInNextLine(zChildren[1])
                                                local labelUI = children and childFromLeft(children, 1, StaticText.matches)
                                                if labelUI and labelUI:attributeValue("AXValue") == self:app():string("Channel Rotation3D Iterpolation Label") then
                                                    return childFromLeft(children, 1, PopUpButton.matches)
                                                end
                                            end)
                                      end),
                contrast            = slider "Material Environment Contrast",
                saturation          = slider "Material Environment Saturation",
                anisotropic         = checkBox "Material Environment Anisotropy Enable",
            },
        },
        material            = section "Material Short Desc" {},
            --------------------------------------------------------------------------------
            -- TODO: Add "Material" section contents.
            --------------------------------------------------------------------------------
        face                = section "Text Face" {
            fillWith            = popUpButton "Text Face Color Source",
            --------------------------------------------------------------------------------
            -- TODO: Add a 'ColorWell' option:
            --------------------------------------------------------------------------------
            color               = simple "Text Face Color",
            --------------------------------------------------------------------------------
            -- TODO: Complete 'Gradient' options:
            --------------------------------------------------------------------------------
            gradient            = section "Text Face Gradient" {},
            opacity             = slider "Text Face Opacity",
            blur                = slider "Text Face Blur",
        },
        outline             = section "Text Outline" {
            fillWith            = popUpButton "Text Outline Color Source",
            --------------------------------------------------------------------------------
            -- TODO: Add a 'ColorWell' option:
            --------------------------------------------------------------------------------
            color               = simple "Text Outline Color",
            opacity             = slider "Text Outline Opacity",
            blur                = slider "Text Outline Blur",
            width               = slider "Text Outline Width",
        },
        glow                = section "Text Glow" {
            fillWith            = popUpButton "Text Glow Color Source",
            --------------------------------------------------------------------------------
            -- TODO: Add a 'ColorWell' option:
            --------------------------------------------------------------------------------
            color               = simple "Text Glow Color",
            opacity             = slider "Text Glow Opacity",
            blur                = slider "Text Glow Blur",
            radius              = slider "Text Glow Radius",
        },
        dropShadow          = section "Text Drop Shadow" {
            fillWith            = popUpButton "Text Drop Shadow Color Source",
            --------------------------------------------------------------------------------
            -- TODO: Add a 'ColorWell' option:
            --------------------------------------------------------------------------------
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

--- cp.apple.finalcutpro.inspector.color.TextInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
function TextInspector.lazy.prop:bottomBarUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_bottomBarUI", function()
            local ui = original()
            local parent = ui and ui:attributeValue("AXParent")
            return parent and childFromBottom(parent, 1, Group.matches)
        end, Group.matches)
    end)
end

--- cp.apple.finalcutpro.inspector.color.TextInspector.textLayerLeft <cp.ui.Button>
--- Field
--- The left text layer arrow at the bottom of the Inspector.
function TextInspector:textLayerLeft()
    return Button(self, function()
        local bottomBarUI = self.bottomBarUI()
        local group = bottomBarUI and childFromLeft(bottomBarUI, 1, Group.matches)
        return group and childFromLeft(group, 1, Button.matches)
    end)
end

--- cp.apple.finalcutpro.inspector.color.TextInspector.textLayerRight <cp.ui.Button>
--- Field
--- The left text layer arrow at the bottom of the Inspector.
function TextInspector:textLayerRight()
    return Button(self, function()
        local bottomBarUI = self.bottomBarUI()
        local group = bottomBarUI and childFromLeft(bottomBarUI, 1, Group.matches)
        return group and childFromLeft(group, 2, Button.matches)
    end)
end

--- cp.apple.finalcutpro.inspector.color.TextInspector.deselectAll <cp.ui.Button>
--- Field
--- The left text layer arrow at the bottom of the Inspector.
function TextInspector:deselectAll()
    return Button(self, function()
        local bottomBarUI = self.bottomBarUI()
        return bottomBarUI and childFromLeft(bottomBarUI, 1, Button.matches)
    end)
end

--- cp.apple.finalcutpro.inspector.color.TextInspector.preset <cp.ui.PopUpButton>
--- Field
--- The preset popup found at the top of the inspector.
function TextInspector:preset()
    return PopUpButton(self, function()
        local ui = self.contentUI()
        return ui and PopUpButton.matches(ui[1]) and ui[1]
    end)
end

--- cp.apple.finalcutpro.inspector.color.TextInspector.textArea <cp.ui.TextArea>
--- Field
--- The Text Inspector main Text Area.
function TextInspector:textArea()
    return TextArea(self, function()
        local contentUI = self.contentUI()
        local scrollArea = contentUI and childFromTop(contentUI, 1, ScrollArea.matches)
        return scrollArea and TextArea.matches(scrollArea[1]) and scrollArea[1]
    end)
end

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
