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

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("videoInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local hasProperties                     = IP.hasProperties
local section, slider, xy, popUpButton, checkBox = IP.section, IP.slider, IP.xy, IP.popUpButton, IP.checkBox

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local VideoInspector = {}

--- cp.apple.finalcutpro.inspector.video.VideoInspector.matches(element)
--- Function
--- Checks if the provided element could be a VideoInspector.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
function VideoInspector.matches(element)
    if element then
        if element:attributeValue("AXRole") == "AXGroup" and #element == 1 then
            local group = element[1]
            return group and group:attributeValue("AXRole") == "AXGroup" and #group == 1
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.new(parent) -> cp.apple.finalcutpro.video.VideoInspector
--- Constructor
--- Creates a new `VideoInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `VideoInspector` object
function VideoInspector.new(parent)
    local o
    o = prop.extend({
        _parent = parent,
        _child = {},
        _rows = {},

--- cp.apple.finalcutpro.inspector.color.VideoInspector.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object for the Video Inspector.
        UI = parent.panelUI:mutate(function(original)
            return axutils.cache(o, "_ui",
                function()
                    local ui = original()
                    return VideoInspector.matches(ui) and ui or nil
                end,
                VideoInspector.matches
            )
        end),

    }, VideoInspector)

    prop.bind(o) {
--- cp.apple.finalcutpro.inspector.color.VideoInspector.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the VideoInspector is currently showing.
        isShowing = o.UI:ISNOT(nil),

--- cp.apple.finalcutpro.inspector.color.VideoInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
        contentUI = o.UI:mutate(function(original)
            return axutils.cache(o, "_contentUI", function()
                local ui = original()
                if ui then
                    local group = ui[1]
                    if group then
                        local scrollArea = group[1]
                        return scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and scrollArea
                    end
                end
                return nil
            end)
        end),
    }

    -- specify that the `contentUI` contains the PropertyRows.
    hasProperties(o, o.contentUI) {
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
        },
        rollingShutter      = section "FFRollingShutterEffect" {
            amount          = popUpButton "FFRollingShutterAmount",
        },
        spatialConform      = section "FFHeliumConformEffect" {
            type            = popUpButton "FFType",
        },
    }

    return o
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:parent() -> table
--- Method
--- Returns the VideoInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function VideoInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function VideoInspector:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.video.VideoInspector:show() -> VideoInspector
--- Method
--- Shows the Video Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * VideoInspector
function VideoInspector:show()
    if not self:isShowing() then
        self:parent():selectTab("Video")
    end
    return self
end

return VideoInspector