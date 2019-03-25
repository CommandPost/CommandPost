--- === plugins.finalcutpro.tangent.text ===
---
--- Final Cut Pro Text Inspector for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentVideo")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
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
    -- Setup:
    --------------------------------------------------------------------------------
    local id                            = 0x0F750000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local checkboxParameter             = common.checkboxParameter
    local checkboxSliderParameter       = common.checkboxSliderParameter
    local dynamicPopupSliderParameter   = common.dynamicPopupSliderParameter
    local ninjaButtonParameter          = common.ninjaButtonParameter
    local popupParameter                = common.popupParameter
    local sliderParameter               = common.sliderParameter

    --------------------------------------------------------------------------------
    -- TEXT INSPECTOR:
    --------------------------------------------------------------------------------
    local text                          = fcp:inspector():text()
    local textGroup                     = fcpGroup:group(i18n("text") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        --
        -- FONT STYLES:
        --
        --------------------------------------------------------------------------------

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

            id = popupParameter(rotationGroup, basic:rotation().animate, id, fcp:string("Channel Rotation3D Iterpolation Enum"):split(";")[1], i18n("useRotation"))
            id = popupParameter(rotationGroup, basic:rotation().animate, id, fcp:string("Channel Rotation3D Iterpolation Enum"):split(";")[2], i18n("useOrientation"))

            --------------------------------------------------------------------------------
            -- Scale:
            --------------------------------------------------------------------------------
            local scaleGroup = basicGroup:group(i18n("scale"))
            id = sliderParameter(scaleGroup, basic:scale().master, id, 0, 400, 0.1, 0, "Master")
            id = sliderParameter(scaleGroup, basic:scale().x, id, 0, 400, 0.1, 0, "X")
            id = sliderParameter(scaleGroup, basic:scale().y, id, 0, 400, 0.1, 0, "Y")
            sliderParameter(scaleGroup, basic:scale().z, id, 0, 400, 0.1, 0, "Z")

        --------------------------------------------------------------------------------
        --
        -- 3D TEXT:
        --
        --------------------------------------------------------------------------------

        --------------------------------------------------------------------------------
        --
        -- FACE:
        --
        --------------------------------------------------------------------------------

        --------------------------------------------------------------------------------
        --
        -- OUTLINE:
        --
        --------------------------------------------------------------------------------

        --------------------------------------------------------------------------------
        --
        -- GLOW:
        --
        --------------------------------------------------------------------------------

        --------------------------------------------------------------------------------
        --
        -- TEXT DROP SHADOW:
        --
        --------------------------------------------------------------------------------



end

return plugin
