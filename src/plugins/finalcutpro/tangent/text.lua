--- === plugins.finalcutpro.tangent.text ===
---
--- Final Cut Pro Text Inspector for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentText")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

local plugin = {
    id = "finalcutpro.tangent.text",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.common"]  = "common",
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    local id                            = 0x0F750000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local buttonParameter               = common.buttonParameter
    local checkboxParameter             = common.checkboxParameter
    local checkboxSliderParameter       = common.checkboxSliderParameter
    local doShowParameter               = common.doShowParameter
    local dynamicPopupSliderParameter   = common.dynamicPopupSliderParameter
    local ninjaButtonParameter          = common.ninjaButtonParameter
    local popupParameter                = common.popupParameter
    local sliderParameter               = common.sliderParameter

    --------------------------------------------------------------------------------
    -- TEXT INSPECTOR:
    --------------------------------------------------------------------------------
    local text = fcp.inspector.text
    local textGroup = fcpGroup:group(i18n("text") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        -- Show Inspector:
        --------------------------------------------------------------------------------
        id = doShowParameter(textGroup, text, id, i18n("show") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        --
        -- PRESETS:
        --
        --------------------------------------------------------------------------------
        local presetsGroup = textGroup:group(i18n("presets"))

            --------------------------------------------------------------------------------
            -- Save Format Attributes:
            --------------------------------------------------------------------------------
            id = popupParameter(presetsGroup, text:preset(), id, fcp:string("Text Style Save Format"), i18n("saveFormatAttributes"))

            --------------------------------------------------------------------------------
            -- Save Appearance Attributes:
            --------------------------------------------------------------------------------
            id = popupParameter(presetsGroup, text:preset(), id, fcp:string("Text Style Save Style"), i18n("saveAppearanceAttributes"))

            --------------------------------------------------------------------------------
            -- Save All Format and Appearance Attributes:
            --------------------------------------------------------------------------------
            id = popupParameter(presetsGroup, text:preset(), id, fcp:string("Text Style Save All"), i18n("saveAllFormatAndAppearanceAttributes"))

            --------------------------------------------------------------------------------
            -- 2D Styles:
            --
            -- Currently none of these menu items have AXTitles, so there's not much
            -- we can do here. Reserving some IDs just in case.
            --------------------------------------------------------------------------------
            id = id + 10

            --------------------------------------------------------------------------------
            -- 3D Styles:
            --
            -- Currently none of these menu items have AXTitles, so there's not much
            -- we can do here. Reserving some IDs just in case.
            --------------------------------------------------------------------------------
            id = id + 10

        --------------------------------------------------------------------------------
        --
        -- BASIC:
        --
        --------------------------------------------------------------------------------
        local basic                     = text:basic()
        local basicGroup                = textGroup:group(i18n("basic"))

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(basicGroup, basic.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Font:
            --------------------------------------------------------------------------------
            id = dynamicPopupSliderParameter(basicGroup, basic:font().family, id, i18n("font") .. " " .. i18n("family"), "Helvetica Neue")
            id = dynamicPopupSliderParameter(basicGroup, basic:font().typeface, id, i18n("font") .. " " .. i18n("typeface"), "Regular")

            --------------------------------------------------------------------------------
            -- Size:
            --------------------------------------------------------------------------------
            id = sliderParameter(basicGroup, basic:size(), id, -6, 288, 0.1, 152)

            --------------------------------------------------------------------------------
            -- Alignment (Buttons):
            --------------------------------------------------------------------------------
            local alignment             = basic:alignment()
            local alignmentGroup        = basicGroup:group(i18n("alignment"))

            id = checkboxParameter(alignmentGroup, alignment.left, id, "left")
            id = checkboxParameter(alignmentGroup, alignment.center, id, "center")
            id = checkboxParameter(alignmentGroup, alignment.right, id, "right")

            id = checkboxParameter(alignmentGroup, alignment.justifiedLeft, id, i18n("justifiedLeft"))
            id = checkboxParameter(alignmentGroup, alignment.justifiedCenter, id, i18n("justifiedCenter"))
            id = checkboxParameter(alignmentGroup, alignment.justifiedRight, id, i18n("justifiedRight"))
            id = checkboxParameter(alignmentGroup, alignment.justifiedFull, id, i18n("justifiedFull"))

            --------------------------------------------------------------------------------
            -- Alignment (Knob):
            --------------------------------------------------------------------------------
            local alignmentOptions = {
                [1] = { param = alignment.left,                 i18n = "left" },
                [2] = { param = alignment.center,               i18n = "center" },
                [3] = { param = alignment.right,                i18n = "right" },
                [4] = { param = alignment.justifiedLeft,        i18n = "justifiedLeft" },
                [5] = { param = alignment.justifiedCenter,      i18n = "justifiedCenter" },
                [6] = { param = alignment.justifiedRight,       i18n = "justifiedRight" },
                [7] = { param = alignment.justifiedFull,        i18n = "justifiedFull" },
            }
            id = checkboxSliderParameter(basicGroup, id, "alignment", alignmentOptions, 1)

            --------------------------------------------------------------------------------
            -- Vertical Alignment (Buttons):
            --------------------------------------------------------------------------------
            local verticalAlignment         = basic:verticalAlignment()
            local verticalAlignmentGroup    = basicGroup:group(i18n("vertical") .. " " .. i18n("alignment"))

            id = checkboxParameter(verticalAlignmentGroup, verticalAlignment.top, id, "top")
            id = checkboxParameter(verticalAlignmentGroup, verticalAlignment.middle, id, "middle")
            id = checkboxParameter(verticalAlignmentGroup, verticalAlignment.bottom, id, "bottom")

            --------------------------------------------------------------------------------
            -- Vertical Alignment (Knob):
            --------------------------------------------------------------------------------
            local verticalAlignmentOptions = {
                [1] = { param = verticalAlignment.top,                i18n = "top" },
                [2] = { param = verticalAlignment.middle,             i18n = "middle" },
                [3] = { param = verticalAlignment.bottom,             i18n = "bottom" },
            }
            id = checkboxSliderParameter(basicGroup, id, i18n("vertical") .. " " .. i18n("alignment"), verticalAlignmentOptions, 1)

            --------------------------------------------------------------------------------
            -- Line Spacing:
            --------------------------------------------------------------------------------
            id = sliderParameter(basicGroup, basic:lineSpacing(), id, -100, 100, 0.1, 0)

            --------------------------------------------------------------------------------
            -- Tracking:
            --------------------------------------------------------------------------------
            id = sliderParameter(basicGroup, basic:tracking(), id, -100, 100, 0.1, 0)

            --------------------------------------------------------------------------------
            -- Kerning:
            --------------------------------------------------------------------------------
            id = sliderParameter(basicGroup, basic:kerning(), id, -100, 100, 0.1, 0)

            --------------------------------------------------------------------------------
            -- Baseline:
            --------------------------------------------------------------------------------
            id = sliderParameter(basicGroup, basic:baseline(), id, -100, 100, 0.1, 0)

            --------------------------------------------------------------------------------
            -- All Caps:
            --------------------------------------------------------------------------------
            id = checkboxParameter(basicGroup, basic:allCaps().value, id, "allCaps")

            --------------------------------------------------------------------------------
            -- All Caps Size:
            --------------------------------------------------------------------------------
            id = sliderParameter(basicGroup, basic:allCapsSize(), id, 0, 100, 0.1, 80)

            --------------------------------------------------------------------------------
            -- Position:
            --------------------------------------------------------------------------------
            local positionGroup = basicGroup:group(i18n("position"))
            id = sliderParameter(positionGroup, basic:position().x, id, -5000, 5000, 0.1, 0, "X")
            id = sliderParameter(positionGroup, basic:position().y, id, -5000, 5000, 0.1, 0, "Y")
            id = sliderParameter(positionGroup, basic:position().z, id, -5000, 5000, 0.1, 0, "Z")

            --------------------------------------------------------------------------------
            -- Rotation:
            --------------------------------------------------------------------------------
            local rotationGroup = basicGroup:group(i18n("rotation"))
            id = sliderParameter(rotationGroup, basic:rotation().x, id, -5000, 5000, 0.1, 0, "X")
            id = sliderParameter(rotationGroup, basic:rotation().y, id, -5000, 5000, 0.1, 0, "Y")
            id = sliderParameter(rotationGroup, basic:rotation().z, id, -5000, 5000, 0.1, 0, "Z")

                --------------------------------------------------------------------------------
                -- Animate:
                --------------------------------------------------------------------------------
                id = dynamicPopupSliderParameter(rotationGroup, basic:rotation().animate, id, "animate" , fcp:string("Channel Rotation3D Iterpolation Enum"):split(";")[1])

                local rotationAnimateGroup = rotationGroup:group(i18n("animate"))
                id = popupParameter(rotationAnimateGroup, basic:rotation().animate, id, fcp:string("Channel Rotation3D Iterpolation Enum"):split(";")[1], i18n("useRotation"))
                id = popupParameter(rotationAnimateGroup, basic:rotation().animate, id, fcp:string("Channel Rotation3D Iterpolation Enum"):split(";")[2], i18n("useOrientation"))

            --------------------------------------------------------------------------------
            -- Scale:
            --------------------------------------------------------------------------------
            local scaleGroup = basicGroup:group(i18n("scale"))
            id = sliderParameter(scaleGroup, basic:scale().master, id, 0, 400, 0.1, 0, "Master")
            id = sliderParameter(scaleGroup, basic:scale().x, id, 0, 400, 0.1, 0, "X")
            id = sliderParameter(scaleGroup, basic:scale().y, id, 0, 400, 0.1, 0, "Y")
            id = sliderParameter(scaleGroup, basic:scale().z, id, 0, 400, 0.1, 0, "Z")

        --------------------------------------------------------------------------------
        --
        -- 3D TEXT:
        --
        --------------------------------------------------------------------------------
        local threeDeeText              = text:threeDeeText()
        local threeDeeTextGroup         = textGroup:group(i18n("threeDeeText"))

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(threeDeeTextGroup, threeDeeText.enabled, id, "toggle")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(threeDeeTextGroup, threeDeeText.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Depth:
            --------------------------------------------------------------------------------
            id = sliderParameter(threeDeeTextGroup, threeDeeText:depth(), id, 0, 100, 0.1, 10, "depth")

            --------------------------------------------------------------------------------
            -- Depth Direction:
            --------------------------------------------------------------------------------
            local depthDirections = fcp:string("Bevel Properties Extrude Direction Enum"):split(";")
            local depthDirectionsGroup = threeDeeTextGroup:group(i18n("depthDirection"))

            id = dynamicPopupSliderParameter(threeDeeTextGroup, threeDeeText:depthDirection().value, id, "depthDirection" , depthDirections[3])

            for _, v in pairs(depthDirections) do
                if v ~= "-" then
                    id = popupParameter(depthDirectionsGroup, threeDeeText:depthDirection().value, id, v, v)
                end
            end

            --------------------------------------------------------------------------------
            -- Weight:
            --------------------------------------------------------------------------------
            id = sliderParameter(threeDeeTextGroup, threeDeeText:weight(), id, -5, 5, 0.1, 0, "weight")

            --------------------------------------------------------------------------------
            -- Front Edge:
            --------------------------------------------------------------------------------
            local frontEdges = fcp:string("Bevel Properties Front Profile Enum"):split(";")
            local frontEdgesGroup = threeDeeTextGroup:group(i18n("frontEdge"))

            id = dynamicPopupSliderParameter(threeDeeTextGroup, threeDeeText:frontEdge().value, id, "frontEdge" , frontEdges[3])

            for _, v in pairs(frontEdges) do
                if v ~= "-" then
                    id = popupParameter(frontEdgesGroup, threeDeeText:frontEdge().value, id, v, v)
                end
            end

            --------------------------------------------------------------------------------
            -- Front Edge Size:
            --------------------------------------------------------------------------------
            id = sliderParameter(threeDeeTextGroup, threeDeeText:frontEdgeSize().master, id, 0, 10, 0.1, 4, "frontEdgeSize", threeDeeText:frontEdgeSize().width, threeDeeText:frontEdgeSize().depth)
            id = sliderParameter(threeDeeTextGroup, threeDeeText:frontEdgeSize().width, id, 0, 10, 0.1, 4, "frontEdgeSizeWidth")
            id = sliderParameter(threeDeeTextGroup, threeDeeText:frontEdgeSize().depth, id, 0, 10, 0.1, 4, "frontEdgeSizeDepth")

            --------------------------------------------------------------------------------
            -- Back Edge:
            --------------------------------------------------------------------------------
            local backEdges = fcp:string("Bevel Properties Back Profile Enum"):split(";")
            local backEdgesGroup = threeDeeTextGroup:group(i18n("backEdge"))

            id = dynamicPopupSliderParameter(threeDeeTextGroup, threeDeeText:backEdge().value, id, "backEdge" , backEdges[1])

            for _, v in pairs(backEdges) do
                if v ~= "-" then
                    id = popupParameter(backEdgesGroup, threeDeeText:backEdge().value, id, v, v)
                end
            end

            --------------------------------------------------------------------------------
            -- Back Edge Size:
            --------------------------------------------------------------------------------
            id = sliderParameter(threeDeeTextGroup, threeDeeText:backEdgeSize().master, id, 0, 10, 0.1, 4, "backEdgeSize", threeDeeText:backEdgeSize().width, threeDeeText:backEdgeSize().depth)
            id = sliderParameter(threeDeeTextGroup, threeDeeText:backEdgeSize().width, id, 0, 10, 0.1, 4, "backEdgeSizeWidth")
            id = sliderParameter(threeDeeTextGroup, threeDeeText:backEdgeSize().depth, id, 0, 10, 0.1, 4, "backEdgeSizeDepth")

            --------------------------------------------------------------------------------
            -- Inside Corners:
            --------------------------------------------------------------------------------
            local insideCorners = fcp:string("Bevel Properties Corner Style Enum"):split(";")
            local insideCornersGroup = threeDeeTextGroup:group(i18n("insideCorners"))

            id = dynamicPopupSliderParameter(threeDeeTextGroup, threeDeeText:insideCorners().value, id, "insideCorners" , insideCorners[1])

            for _, v in pairs(insideCorners) do
                if v ~= "-" then
                    id = popupParameter(insideCornersGroup, threeDeeText:insideCorners().value, id, v, v)
                end
            end

            --------------------------------------------------------------------------------
            -- LIGHTING:
            --------------------------------------------------------------------------------
            local lighting                  = text:lighting()
            local lightingGroup             = threeDeeTextGroup:group(i18n("lighting"))

                --------------------------------------------------------------------------------
                -- Reset:
                --------------------------------------------------------------------------------
                id = ninjaButtonParameter(lightingGroup, lighting.reset, id, "reset")

                --------------------------------------------------------------------------------
                -- Lighting Style:
                --------------------------------------------------------------------------------
                local lightingStyles = fcp:string("Bevel Properties Lighting Style Enum"):split(";")
                local lightingStyleGroup = lightingGroup:group(i18n("lightingStyle"))

                id = dynamicPopupSliderParameter(lightingGroup, lighting:lightingStyle().value, id, "lightingStyle" , lightingStyles[2])

                for _, v in pairs(lightingStyles) do
                    if v ~= "-" then
                        id = popupParameter(lightingStyleGroup, lighting:lightingStyle().value, id, v, v)
                    end
                end

                --------------------------------------------------------------------------------
                -- Intensity:
                --------------------------------------------------------------------------------
                id = sliderParameter(lightingGroup, lighting:intensity(), id, 0, 100, 0.1, 100, "intensity")

                --------------------------------------------------------------------------------
                -- SELF SHADOWS:
                --------------------------------------------------------------------------------
                local selfShadows               = lighting:selfShadows()
                local selfShadowsGroup          = lightingGroup:group(i18n("selfShadows"))

                    --------------------------------------------------------------------------------
                    -- Enable/Disable:
                    --------------------------------------------------------------------------------
                    id = checkboxParameter(selfShadowsGroup, selfShadows.enabled, id, "toggle")

                    --------------------------------------------------------------------------------
                    -- Reset:
                    --------------------------------------------------------------------------------
                    id = ninjaButtonParameter(selfShadowsGroup, selfShadows.reset, id, "reset")

                    --------------------------------------------------------------------------------
                    -- Opacity:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(selfShadowsGroup, selfShadows:opacity(), id, 0, 100, 0.1, 100, "opacity")

                    --------------------------------------------------------------------------------
                    -- Softness:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(selfShadowsGroup, selfShadows:softness(), id, 0, 100, 0.1, 0, "softness")

                --------------------------------------------------------------------------------
                -- ENVIRONMENT:
                --------------------------------------------------------------------------------
                local environment               = lighting:environment()
                local environmentGroup          = lightingGroup:group(i18n("environment"))

                    --------------------------------------------------------------------------------
                    -- Type:
                    --------------------------------------------------------------------------------
                    local environmentTypes = fcp:string("Material Environment Map Selection Enum"):split(";")
                    local environmentTypeGroup = environmentGroup:group(i18n("type"))

                    id = dynamicPopupSliderParameter(environmentGroup, environment:type().value, id, "type" , environmentTypes[4])

                    for _, v in pairs(environmentTypes) do
                        if v ~= "-" then
                            id = popupParameter(environmentTypeGroup, environment:type().value, id, v, v)
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Intensity:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(environmentGroup, environment:intensity(), id, 0, 100, 0.1, 100, "intensity")

                    --------------------------------------------------------------------------------
                    -- Rotation:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(environmentGroup, environment:rotation().master, id, -5000, 5000, 0.1, 0, "master")
                    id = sliderParameter(environmentGroup, environment:rotation().x, id, -5000, 5000, 0.1, 0, "X")
                    id = sliderParameter(environmentGroup, environment:rotation().y, id, -5000, 5000, 0.1, 0, "Y")
                    id = sliderParameter(environmentGroup, environment:rotation().z, id, -5000, 5000, 0.1, 0, "Z")

                        --------------------------------------------------------------------------------
                        -- Animate:
                        --------------------------------------------------------------------------------
                        id = dynamicPopupSliderParameter(environmentGroup, environment:rotation().animate, id, "animate" , fcp:string("Channel Rotation3D Iterpolation Enum"):split(";")[1])

                        local environmentAnimateGroup = environmentGroup:group(i18n("animate"))
                        id = popupParameter(environmentAnimateGroup, environment:rotation().animate, id, fcp:string("Channel Rotation3D Iterpolation Enum"):split(";")[1], i18n("useRotation"))
                        id = popupParameter(environmentAnimateGroup, environment:rotation().animate, id, fcp:string("Channel Rotation3D Iterpolation Enum"):split(";")[2], i18n("useOrientation"))

                    --------------------------------------------------------------------------------
                    -- Contrast:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(environmentGroup, environment:contrast(), id, 0, 100, 0.1, 100, "contrast")

                    --------------------------------------------------------------------------------
                    -- Saturation:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(environmentGroup, environment:saturation(), id, 0, 100, 0.1, 100, "saturation")

                    --------------------------------------------------------------------------------
                    -- Anisotropic:
                    --------------------------------------------------------------------------------
                    id = checkboxParameter(environmentGroup, environment:anisotropic().value, id, "anisotropic")

        --------------------------------------------------------------------------------
        --
        -- MATERIAL:
        --
        --------------------------------------------------------------------------------

            --------------------------------------------------------------------------------
            -- TODO: Add Material section once it's added to the FCPX API.
            --------------------------------------------------------------------------------
            id = id + 20

        --------------------------------------------------------------------------------
        --
        -- FACE:
        --
        --------------------------------------------------------------------------------
        local face                      = text:face()
        local faceGroup                 = textGroup:group(i18n("face"))

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(faceGroup, face.enabled, id, "toggle")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(faceGroup, face.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Fill with:
            --------------------------------------------------------------------------------
            id = dynamicPopupSliderParameter(faceGroup, face:fillWith().value, id, "fillWith" , fcp:string("Text Color Source Enum"):split(";")[1])

            local faceFillWithGroup = faceGroup:group(i18n("fillWith"))
            id = popupParameter(faceFillWithGroup, face:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[1], i18n("color"))
            id = popupParameter(faceFillWithGroup, face:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[2], i18n("gradient"))
            id = popupParameter(faceFillWithGroup, face:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[3], i18n("texture"))

            --------------------------------------------------------------------------------
            -- Color:
            --
            -- I'm not sure there's any use having a Tangent Control for colour,
            -- but let's reserve some IDs just in case.
            --------------------------------------------------------------------------------
            id = id + 10

            --------------------------------------------------------------------------------
            -- Gradient:
            --
            -- I'm not sure there's any use having a Tangent Controls for gradients,
            -- but let's reserve some IDs just in case.
            --------------------------------------------------------------------------------
            id = id + 20

            --------------------------------------------------------------------------------
            -- Opacity:
            --------------------------------------------------------------------------------
            id = sliderParameter(faceGroup, face:opacity(), id, 0, 100, 0.1, 100, "opacity")

            --------------------------------------------------------------------------------
            -- Blur:
            --------------------------------------------------------------------------------
            id = sliderParameter(faceGroup, face:blur(), id, 0, 10, 0.1, 0, "blur")

        --------------------------------------------------------------------------------
        --
        -- OUTLINE:
        --
        --------------------------------------------------------------------------------
        local outline                   = text:outline()
        local outlineGroup              = textGroup:group(i18n("outline"))

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(outlineGroup, outline.enabled, id, "toggle")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(outlineGroup, outline.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Fill with:
            --------------------------------------------------------------------------------
            id = dynamicPopupSliderParameter(outlineGroup, outline:fillWith().value, id, "fillWith" , fcp:string("Text Color Source Enum"):split(";")[1])

            local outlineFillWithGroup = outlineGroup:group(i18n("fillWith"))
            id = popupParameter(outlineFillWithGroup, outline:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[1], i18n("color"))
            id = popupParameter(outlineFillWithGroup, outline:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[2], i18n("gradient"))
            id = popupParameter(outlineFillWithGroup, outline:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[3], i18n("texture"))

            --------------------------------------------------------------------------------
            -- Color:
            --
            -- I'm not sure there's any use having a Tangent Control for colour,
            -- but let's reserve some IDs just in case.
            --------------------------------------------------------------------------------
            id = id + 10

            --------------------------------------------------------------------------------
            -- Gradient:
            --
            -- I'm not sure there's any use having a Tangent Controls for gradients,
            -- but let's reserve some IDs just in case.
            --------------------------------------------------------------------------------
            id = id + 20

            --------------------------------------------------------------------------------
            -- Opacity:
            --------------------------------------------------------------------------------
            id = sliderParameter(outlineGroup, outline:opacity(), id, 0, 100, 0.1, 100, "opacity")

            --------------------------------------------------------------------------------
            -- Blur:
            --------------------------------------------------------------------------------
            id = sliderParameter(outlineGroup, outline:blur(), id, 0, 10, 0.1, 0, "blur")

            --------------------------------------------------------------------------------
            -- Width:
            --------------------------------------------------------------------------------
            id = sliderParameter(outlineGroup, outline:width(), id, 0, 15, 0.1, 1, "width")

        --------------------------------------------------------------------------------
        --
        -- GLOW:
        --
        --------------------------------------------------------------------------------
        local glow                      = text:glow()
        local glowGroup                 = textGroup:group(i18n("glow"))

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(glowGroup, glow.enabled, id, "toggle")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(glowGroup, glow.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Color:
            --
            -- I'm not sure there's any use having a Tangent Control for colour,
            -- but let's reserve some IDs just in case.
            --------------------------------------------------------------------------------
            id = id + 10

            --------------------------------------------------------------------------------
            -- Opacity:
            --------------------------------------------------------------------------------
            id = sliderParameter(glowGroup, glow:opacity(), id, 0, 100, 0.1, 100, "opacity")

            --------------------------------------------------------------------------------
            -- Blur:
            --------------------------------------------------------------------------------
            id = sliderParameter(glowGroup, glow:blur(), id, 0, 10, 0.1, 1, "blur")

            --------------------------------------------------------------------------------
            -- Radius:
            --------------------------------------------------------------------------------
            id = sliderParameter(glowGroup, glow:radius(), id, 0, 100, 0.1, 0, "radius")

        --------------------------------------------------------------------------------
        --
        -- TEXT DROP SHADOW:
        --
        --------------------------------------------------------------------------------
        local dropShadow                = text:dropShadow()
        local dropShadowGroup           = textGroup:group(i18n("dropShadow"))

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(dropShadowGroup, dropShadow.enabled, id, "toggle")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(dropShadowGroup, dropShadow.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Fill with:
            --------------------------------------------------------------------------------
            id = dynamicPopupSliderParameter(dropShadowGroup, dropShadow:fillWith().value, id, "fillWith" , fcp:string("Text Color Source Enum"):split(";")[1])

            local dropShadowFillWithGroup = dropShadowGroup:group(i18n("fillWith"))
            id = popupParameter(dropShadowFillWithGroup, dropShadow:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[1], i18n("color"))
            id = popupParameter(dropShadowFillWithGroup, dropShadow:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[2], i18n("gradient"))
            id = popupParameter(dropShadowFillWithGroup, dropShadow:fillWith().value, id, fcp:string("Text Color Source Enum"):split(";")[3], i18n("texture"))

            --------------------------------------------------------------------------------
            -- Color:
            --
            -- I'm not sure there's any use having a Tangent Control for colour, but
            -- let's reserve some IDs just in case.
            --------------------------------------------------------------------------------
            id = id + 10

            --------------------------------------------------------------------------------
            -- Opacity:
            --------------------------------------------------------------------------------
            id = sliderParameter(dropShadowGroup, dropShadow:opacity(), id, 0, 100, 0.1, 100, "opacity")

            --------------------------------------------------------------------------------
            -- Blur:
            --------------------------------------------------------------------------------
            id = sliderParameter(dropShadowGroup, dropShadow:blur(), id, 0, 10, 0.1, 0, "blur")

            --------------------------------------------------------------------------------
            -- Distance:
            --------------------------------------------------------------------------------
            id = sliderParameter(dropShadowGroup, dropShadow:distance(), id, 0, 100, 0.1, 5, "distance")

            --------------------------------------------------------------------------------
            -- Angle:
            --------------------------------------------------------------------------------
            id = sliderParameter(dropShadowGroup, dropShadow:angle(), id, -5000, 5000, 0.1, 315, "angle")

        --------------------------------------------------------------------------------
        --
        -- TEXT LAYER BUTTONS:
        --
        --------------------------------------------------------------------------------
        local textLayerGroup = textGroup:group(i18n("textLayer"))

        id = buttonParameter(textLayerGroup, text:textLayerLeft(), id, "leftTextLayer")
        id = buttonParameter(textLayerGroup, text:textLayerRight(), id, "rightTextLayer")
        buttonParameter(textLayerGroup, text:deselectAll(), id, "deselectAll")

end

return plugin
