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
--- local video = fcp:inspector():video()
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

-- local log								= require("hs.logger").new("videoInspect")

local axutils							= require("cp.ui.axutils")

local strings                           = require("cp.apple.finalcutpro.strings")
local BasePanel                         = require("cp.apple.finalcutpro.inspector.BasePanel")

local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local hasProperties                     = IP.hasProperties
local section, slider, xy, popUpButton, checkBox = IP.section, IP.slider, IP.xy, IP.popUpButton, IP.checkBox
local withRole, childWithRole           = axutils.withRole, axutils.childWithRole
local withValue, childMatching          = axutils.withValue, axutils.childMatching

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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
        return withRole(child, "AXStaticText") and withValue(child, strings:find("FFHeliumBlendCompositingEffect"))
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

--- cp.apple.finalcutpro.inspector.color.VideoInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
function VideoInspector.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_contentUI", function()
            return findContentUI(original())
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.blendModes() -> table
--- Function
--- Returns a table of Blend Modes where the key is the string ID, and the value
--- is the name of the blend mode in English.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of blend modes
function VideoInspector.lazy.value.blendModes()
    return {
        ["FFHeliumBlendModeNormal"] = "Normal",
        ["FFHeliumBlendModeSubtract"] = "Subtract",
        ["FFHeliumBlendModeDarken"] = "Darken",
        ["FFHeliumBlendModeMultiply"] = "Multiply",
        ["FFHeliumBlendModeColorBurn"] = "Color Burn",
        ["FFHeliumBlendModeLinearBurn"] = "Linear Burn",
        ["FFHeliumBlendModeAdd"] = "Add",
        ["FFHeliumBlendModeLighten"] = "Lighten",
        ["FFHeliumBlendModeScreen"] = "Screen",
        ["FFHeliumBlendModeColorDodge"] = "Color Dodge",
        ["FFHeliumBlendModeLinearDodge"] = "Linear Dodge",
        ["FFHeliumBlendModeOverlay"] = "Overlay",
        ["FFHeliumBlendModeSoftLight"] = "Soft Light",
        ["FFHeliumBlendModeHardLight"] = "Hard Light",
        ["FFHeliumBlendModeVividLight"] = "Vivid Light",
        ["FFHeliumBlendModeLinearLight"] = "Linear Light",
        ["FFHeliumBlendModePinLight"] = "Pin Light",
        ["FFHeliumBlendModeHardMix"] = "Hard Mix",
        ["FFHeliumBlendModeDifference"] = "Difference",
        ["FFHeliumBlendModeExclusion"] = "Exclusion",
        ["FFHeliumBlendModeStencilAlpha"] = "Stencil Alpha",
        ["FFHeliumBlendModeStencilLuma"] = "Stencil Luma",
        ["FFHeliumBlendModeSilhouetteAlpha"] = "Silhouette Alpha",
        ["FFHeliumBlendModeSilhouetteLuma"] = "Silhouette Luma",
        ["FFHeliumBlendModeBehind"] = "Behind",
        ["FFHeliumBlendModeAlphaAdd"] = "Alpha Add",
        ["FFHeliumBlendModePremultipliedMix"] = "Premultiplied Mix",
    }
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.cropTypes() -> table
--- Function
--- Returns a table of Crop Types where the key is the string ID, and the value
--- is the name of the crop type in English.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of crop types
function VideoInspector.lazy.value.cropTypes()
    return {
        ["FFTrim"] = "Trim",
        ["FFCrop"] = "Crop",
        ["FFKenBurns"] = "Ken Burns"
    }
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.rollingShutterAmounts() -> table
--- Function
--- Returns a table of Rolling Shutter Amounts where the key is the string ID, and the value
--- is the name of the Rolling Shutter Amount in English.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of rolling shutter amounts
function VideoInspector.lazy.value.rollingShutterAmounts()
    return {
        ["FFRollingShutterAmountNone"] = "None",
        ["FFRollingShutterAmountLow"] = "Low",
        ["FFRollingShutterAmountMedium"] = "Medium",
        ["FFRollingShutterAmountHigh"] = "High",
        ["FFRollingShutterAmountExtraHigh"] = "Extra High",
    }
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.stabilizationMethods() -> table
--- Function
--- Returns a table of Stabilization Methods where the key is the string ID, and the value
--- is the name of the Stabilization Method in English.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of Stabilization Methods
function VideoInspector.lazy.value.stabilizationMethods()
    return {
        ["FFStabilizationDynamic"] = "Automatic",
        ["FFStabilizationUseInertiaCam"] = "InertiaCam",
        ["FFStabilizationUseSmoothCam"] = "SmoothCam",
    }
end

return VideoInspector