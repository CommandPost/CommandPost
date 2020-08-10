--- === cp.apple.finalcutpro.inspector.video.VideoInspector ===
---
--- Video Inspector Module.
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
--- local video = fcp.inspector:video()
--- -- Menu Property:
--- video:compositing():blendMode():value("Subtract")
--- -- Slider Property:
--- video:compositing():opacity():value(50.0)
--- -- XY Property:
--- video:transform():position():x(-10.0)
--- -- CheckBox property:
--- video:stabilization():tripodMode():value(true)
--- ```
---
--- You should also be able to show a specific property and it will be revealed:
--- ```lua
--- video:stabilization():smoothing():show():value(1.5)
--- ```

local require = require

local log						= require "hs.logger".new "videoInspect"

local axutils					= require "cp.ui.axutils"

local BasePanel                 = require "cp.apple.finalcutpro.inspector.BasePanel"
local IP                        = require "cp.apple.finalcutpro.inspector.InspectorProperty"
local strings                   = require "cp.apple.finalcutpro.strings"

local checkBox                  = IP.checkBox
local hasProperties             = IP.hasProperties
local popUpButton               = IP.popUpButton
local section                   = IP.section
local slider                    = IP.slider
local xy                        = IP.xy

local childMatching             = axutils.childMatching
local childWithRole             = axutils.childWithRole
local compareTopToBottom        = axutils.compareTopToBottom
local snapshot                  = axutils.snapshot
local withRole                  = axutils.withRole
local withValue                 = axutils.withValue

local VideoInspector = BasePanel:subclass("cp.apple.finalcutpro.inspector.video.VideoInspector")

local function findContentUI(rootUI)
    local root = BasePanel.matches(rootUI) and withRole(rootUI, "AXGroup")
    local group = root and #root == 1 and childWithRole(root, "AXGroup")
    return group and #group == 1 and childWithRole(group, "AXScrollArea") or nil
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.matches(element)
--- Function
--- Checks if the provided element could be a VideoInspector.
---
--- Parameters:
---  * element   - The element to check
---
--- Returns:
---  * `true` if it matches, `false` if not.
function VideoInspector.static.matches(element)
    local contentUI = findContentUI(element)
    return contentUI and #contentUI > 0 and childMatching(contentUI, function(child)
        return withRole(child, "AXStaticText") and withValue(child, strings:find("FFHeliumConformEffect"))
    end) ~= nil or false
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector(parent) -> cp.apple.finalcutpro.inspector.video.VideoInspector
--- Constructor
--- Creates a new `VideoInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `VideoInspector` object
function VideoInspector:initialize(parent)
    BasePanel.initialize(self, parent, "Video")

    -- specify that the `contentUI` contains the PropertyRows.
    hasProperties(self, self.contentUI) {
        effects             = section "FFInspectorBrickEffects" {},

        compositing         = section "FFHeliumBlendCompositingEffect" {
            blendMode       = popUpButton "FFHeliumBlendMode",
            opacity         = slider "FFHeliumBlendOpacity",
        },

        transform           = section "FFHeliumXFormEffect" {
            position        = xy "FFHeliumXFormPosition",
            rotation        = slider "FFHeliumXFormRotation",
            scaleAll        = slider "FFHeliumXFormScaleInspector",
            scaleX          = slider "FFHeliumXFormScaleXInspector",
            scaleY          = slider "FFHeliumXFormScaleYInspector",
            anchor          = xy "FFHeliumXFormAnchor",
        },

        crop                = section "FFHeliumCropEffect" {
            type            = popUpButton "FFType",
            left            = slider "FFCropLeft",
            right           = slider "FFCropRight",
            top             = slider "FFCropTop",
            bottom          = slider "FFCropBottom",
        },
        distort             = section "FFHeliumDistortEffect" {
            bottomLeft      = xy "PerspectiveTile::Bottom Left",
            bottomRight     = xy "PerspectiveTile::Bottom Right",
            topRight        = xy "PerspectiveTile::Top Right",
            topLeft         = xy "PerspectiveTile::Top Left",
        },
        stabilization       = section "FFStabilizationEffect" {
            method          = popUpButton "FFStabilizationAlgorithmRequested",
            smoothing       = slider "FFStabilizationInertiaCamSmooth",
            tripodMode      = checkBox "FFStabilizationUseTripodMode",
          translationSmooth = slider "FFStabilizationTranslationSmooth",
            rotationSmoooth = slider "FFStabilizationRotationSmooth",
            scaleSmooth     = slider "FFStabilizationScaleSmooth",
        },
        rollingShutter      = section "FFRollingShutterEffect" {
            amount          = popUpButton "FFRollingShutterAmount",
        },
        spatialConform      = section "FFHeliumConformEffect" {
            type            = popUpButton "FFType",
        },
    }
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
function VideoInspector.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_contentUI", function()
            return findContentUI(original())
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:effectCheckBoxes() -> table
--- Method
--- Gets a table containing all of the effect checkboxes.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table.
function VideoInspector:effectCheckBoxes()
    local contentUI = self:contentUI()
    if contentUI then
        local effectsString = strings:find("FFInspectorBrickEffects")
        local compositingString = strings:find("FFHeliumBlendCompositingEffect")
        local children = axutils.children(contentUI, compareTopToBottom)
        local valid
        local checkBoxes = {}
        local topCheckBox
        for _, child in pairs(children) do
            if child:attributeValue("AXRole") == "AXStaticText" and child:attributeValue("AXValue") == effectsString then
                valid = true
            end
            if child:attributeValue("AXRole") == "AXStaticText" and child:attributeValue("AXValue") == compositingString then
                return checkBoxes
            end
            if valid then
                if child:attributeValue("AXRole") == "AXCheckBox" then
                    if not topCheckBox then
                        topCheckBox = child
                    else
                        local a = topCheckBox:attributeValue("AXFrame")
                        local b = child:attributeValue("AXFrame")
                        if a.x == b.x and a.w == b.w and a.h == b.h then
                            table.insert(checkBoxes, child)
                        end
                    end
                end
            end
        end
    end
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:selectedEffectCheckBox() -> axuielement
--- Function
--- Gets the selected effect checkbox object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A axuielement object.
function VideoInspector:selectedEffectCheckBox()
    local effectCheckBoxes = self:effectCheckBoxes()
    if effectCheckBoxes then
        for i, cb in pairs(effectCheckBoxes) do
            local frame = cb:attributeValue("AXFrame")
            frame.x = frame.x
            frame.w = 1
            frame.h = 1
            local s = snapshot(cb, nil, frame)
            if s then
                local c = s:colorAt({x=0, y=0})
                -- UNSELECTED: blue = 0.12049089372158
                -- WHITE: blue = 0.8587818145752
                -- YELLOW: blue = 0.048267990350723
                if c.blue > 0.7 and c.blue < 0.9 or c.blue < 0.05 and c.blue > 0.03 then
                    return effectCheckBoxes[i]
                end
            end
        end
    end
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.BLEND_MODES -> table
--- Constant
--- Blend Modes
VideoInspector.BLEND_MODES = {
    [1]     = {flexoID = "FFHeliumBlendModeNormal", i18n="normal"},
    [2]     = {}, -- Seperator
    [3]     = {flexoID = "FFHeliumBlendModeSubtract", i18n="subtract"},
    [4]     = {flexoID = "FFHeliumBlendModeDarken", i18n="darken"},
    [5]     = {flexoID = "FFHeliumBlendModeMultiply", i18n="multiply"},
    [6]     = {flexoID = "FFHeliumBlendModeColorBurn", i18n="colorBurn"},
    [7]     = {flexoID = "FFHeliumBlendModeLinearBurn", i18n="linearBurn"},
    [8]     = {}, -- Seperator
    [9]     = {flexoID = "FFHeliumBlendModeAdd", i18n="add"},
    [10]    = {flexoID = "FFHeliumBlendModeLighten", i18n="lighten"},
    [11]    = {flexoID = "FFHeliumBlendModeScreen", i18n="screen"},
    [12]    = {flexoID = "FFHeliumBlendModeColorDodge", i18n="colorDodge"},
    [13]    = {flexoID = "FFHeliumBlendModeLinearDodge", i18n="linearDodge"},
    [14]    = {}, -- Seperator
    [15]    = {flexoID = "FFHeliumBlendModeOverlay", i18n="overlay"},
    [16]    = {flexoID = "FFHeliumBlendModeSoftLight", i18n="softLight"},
    [17]    = {flexoID = "FFHeliumBlendModeHardLight", i18n="hardLight"},
    [18]    = {flexoID = "FFHeliumBlendModeVividLight", i18n="vividLight"},
    [19]    = {flexoID = "FFHeliumBlendModeLinearLight", i18n="linearLight"},
    [20]    = {flexoID = "FFHeliumBlendModePinLight", i18n="pinLight"},
    [21]    = {flexoID = "FFHeliumBlendModeHardMix", i18n="hardMix"},
    [22]    = {}, -- Seperator
    [23]    = {flexoID = "FFHeliumBlendModeDifference", i18n="difference"},
    [24]    = {flexoID = "FFHeliumBlendModeExclusion", i18n="exclusion"},
    [25]    = {}, -- Seperator
    [26]    = {flexoID = "FFHeliumBlendModeStencilAlpha", i18n="stencilAlpha"},
    [27]    = {flexoID = "FFHeliumBlendModeStencilLuma", i18n="stencilLuma"},
    [28]    = {flexoID = "FFHeliumBlendModeSilhouetteAlpha", i18n="silhouetteAlpha"},
    [29]    = {flexoID = "FFHeliumBlendModeSilhouetteLuma", i18n="silhouetteLuma"},
    [30]    = {flexoID = "FFHeliumBlendModeBehind", i18n="behind"},
    [31]    = {}, -- Seperator
    [32]    = {flexoID = "FFHeliumBlendModeAlphaAdd", i18n="alphaAdd"},
    [33]    = {flexoID = "FFHeliumBlendModePremultipliedMix", i18n="premultipliedMix"},
}

--- cp.apple.finalcutpro.inspector.video.VideoInspector.CROP_TYPES -> table
--- Constant
--- Crop Types
VideoInspector.CROP_TYPES = {
    [1]     = {flexoID = "FFTrim", i18n = "trim"},
    [2]     = {flexoID = "FFCrop", i18n = "crop"},
    [3]     = {flexoID = "FFKenBurns", i18n = "kenBurns"},
}

--- cp.apple.finalcutpro.inspector.video.VideoInspector.STABILIZATION_METHODS -> table
--- Constant
--- Stabilisation Methods
VideoInspector.STABILIZATION_METHODS = {
    [1]     = {flexoID = "FFStabilizationDynamic", i18n="automatic"},
    [2]     = {flexoID = "FFStabilizationUseInertiaCam", i18n="inertiaCam"},
    [3]     = {flexoID = "FFStabilizationUseSmoothCam", i18n="smoothCam"},
}

--- cp.apple.finalcutpro.inspector.video.VideoInspector.ROLLING_SHUTTER_AMOUNTS -> table
--- Constant
--- Rolling Shutter Amounts
VideoInspector.ROLLING_SHUTTER_AMOUNTS = {
    [1]     = {flexoID = "FFRollingShutterAmountNone", i18n="none"},
    [2]     = {flexoID = "FFRollingShutterAmountLow", i18n="low"},
    [3]     = {flexoID = "FFRollingShutterAmountMedium", i18n="medium"},
    [4]     = {flexoID = "FFRollingShutterAmountHigh", i18n="high"},
    [5]     = {flexoID = "FFRollingShutterAmountExtraHigh", i18n="extraHigh"},
}

--- cp.apple.finalcutpro.inspector.video.VideoInspector.SPATIAL_CONFORM_TYPES -> table
--- Constant
--- Spatial Conform Types
VideoInspector.SPATIAL_CONFORM_TYPES = {
    [1]     = {flexoID = "FFConformTypeFit", i18n="fit"},
    [2]     = {flexoID = "FFConformTypeFill", i18n="fill"},
    [3]     = {flexoID = "FFConformTypeNone", i18n="none"},
}

return VideoInspector
