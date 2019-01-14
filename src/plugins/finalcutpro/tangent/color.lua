--- === plugins.finalcutpro.tangent.manager ===
---
--- Final Cut Pro Tangent Color Manager.

local require = require

local log                                       = require("hs.logger").new("fcp_tangent")

local deferred                                  = require("cp.deferred")
local prop                                      = require("cp.prop")

local ColorWell                                 = require("cp.apple.finalcutpro.inspector.color.ColorWell")
local dialog                                    = require("cp.dialog")
local fcp                                       = require("cp.apple.finalcutpro")
local i18n                                      = require("cp.i18n")

local go                                        = require("cp.rx.go")
local If, Do                                    = go.If, go.Do

local format                                    = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- TODO: Add Documentation
local function doShortcut(id)
    return fcp:doShortcut(id):Catch(function(message)
        log.wf("Unable to perform %q shortcut: %s", id, message)
        dialog.displayMessage(i18n("tangentFinalCutProShortcutFailed"))
    end)
end

--- plugins.finalcutpro.tangent.manager.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(tangentManager, fcpGroup)
    --------------------------------------------------------------------------------
    -- Add Final Cut Pro Modes:
    --------------------------------------------------------------------------------
    tangentManager.addMode(0x00010003, "FCP: Board")

    tangentManager.addMode(0x00010004, "FCP: Wheels")

    --------------------------------------------------------------------------------
    -- Add Final Cut Pro Parameters:
    --------------------------------------------------------------------------------
    local updateUI = deferred.new(0.01)

    local ciGroup = fcpGroup:group(i18n("fcpx_colorInspector_action"))

    -- The section all Color Inspector controls are in.
    local baseID = 0x00300000

    local aspects = { "color", "saturation", "exposure" }

    local ranges = { "master", "shadows", "midtones", "highlights" }

    --------------------------------------------------------------------------------
    -- Handle the Color Board:
    --------------------------------------------------------------------------------
    local cbGroup = ciGroup:group(i18n("colorBoard"))
    local cb = fcp:colorBoard()

    --------------------------------------------------------------------------------
    -- The multiplier for aspects (color/saturation/exposure):
    --------------------------------------------------------------------------------
    local aspectBaseID = 0x01000
    -- The multiplier for ranges.
    local rangeBaseID = 0x00100

    --------------------------------------------------------------------------------
    -- Look up some terms:
    --------------------------------------------------------------------------------
    local iColorBoard, iColorBoard2, iAngle, iAngle3, iPercentage, iPercentage3 =
        i18n("colorBoard"), i18n("colorBoard2"), i18n("angle"), i18n("angle3"), i18n("percentage"), i18n("percentage3")

    for i,aKey in ipairs(aspects) do
        local aspect = cb[aKey](cb)
        local aspectID = baseID + i*aspectBaseID

        local aName = i18n(aKey)
        for j,pKey in ipairs(ranges) do
            local puck = aspect[pKey](aspect)

            -- set up the UI update action...
            local percentChange, angleChange = 0, 0
            local updating = prop.FALSE()

            local update = Do(
                If(updating):Is(false):Then(
                    Do(function()
                        updating(true)
                        return true
                    end)
                    :Then(
                        If(function() return percentChange ~= 0 end)
                        :Then(puck:doShow())
                        :Then(function()
                            local value = puck:percent()
                            if value then
                                puck:percent(value + percentChange)
                                percentChange = 0
                                return true
                            end
                            return false
                        end)
                        :ThenYield()
                        :Otherwise(false)
                    ):Then(
                        If(function() return angleChange ~= 0 end)
                        :Then(puck:doShow())
                        :Then(function()
                            local value = puck:angle()
                            if value then
                                puck:angle(value + angleChange)
                                angleChange = 0
                                return true
                            end
                            return false
                        end)
                        :ThenYield()
                        :Otherwise(false)
                    )
                    :Finally(function() updating(false) end)
                )
            ):Label("color:update")

            updateUI:action(update)

            local rangeID = aspectID + j*rangeBaseID

            local pName, pName2 = i18n(pKey), i18n(pKey.."2")

            local lastPercent, lastAngle

            local percent = cbGroup:parameter(rangeID + 2)
                :name(format("%s - %s - %s - %s", iColorBoard, aName, pName, iPercentage))
                :name9(format("%s %s %s", iColorBoard2, pName2, iPercentage3))
                :minValue(-100)
                :maxValue(100)
                :stepSize(1)
                :onGet(function()
                    if puck:isShowing() then
                        lastPercent = puck:percent()
                    end
                    return lastPercent
                end)
                :onChange(function(change)
                    percentChange = percentChange + change
                    updateUI()
                end)
                :onReset(puck:doReset())

            if puck:hasAngle() then
                local angle = cbGroup:parameter(rangeID + 1)
                    :name(format("%s - %s - %s - %s", iColorBoard, aName, pName, iAngle))
                    :name9(format("%s %s %s", iColorBoard2, pName2, iAngle3))
                    :minValue(0)
                    :maxValue(359)
                    :stepSize(1)
                    :onGet(function()
                        if puck:isShowing() then
                            lastAngle = puck:angle()
                        end
                        return lastAngle
                    end)
                    :onChange(function(change)
                        angleChange = angleChange + change
                        updateUI()
                    end)
                    :onReset(puck:doReset())

                cbGroup:binding(format("%s %s %s", iColorBoard, pName, aName))
                    :member(angle)
                    :member(percent)
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Handle the Color Wheels:
    --------------------------------------------------------------------------------
    local cwGroup = ciGroup:group(i18n("colorWheels"))
    local ci = fcp:inspector():color()
    local cw = ci:colorWheels()

    local wheelsBaseID = baseID + 0x010000
    local wheelID = 0x010
    local iColorWheel, iHorizontal, iHorizontal4, iVertical, iVertical4 =
        i18n("colorWheel"), i18n("horizontal"), i18n("horizontal4"), i18n("vertical"), i18n("vertical4")
    local iSaturation, iSaturation4, iBrightness, iBrightness4 = i18n("saturation"), i18n("saturation4"), i18n("brightness"), i18n("brightness4")

    for i,pKey in ipairs(ranges) do
        local wheel = cw[pKey](cw)
        local id = wheelsBaseID + i*wheelID

        -- set up the UI update action...
        local rightChange, upChange, satChange, brightChange = 0, 0, 0, 0

        local updating = prop.FALSE()
        local update = Do(function()
            updating(true)
            return true
        end)
        :Then(
            If(function() return rightChange ~= 0 or upChange ~= 0 end)
            :Then(wheel:doShow())
            :Then(function()
                wheel:nudgeColor(rightChange, upChange)
                rightChange, upChange = 0, 0
                return true
            end)
        ):Then(
            If(function() return satChange ~= 0 end)
            :Then(wheel:doShow())
            :Then(function()
                wheel:saturation():shiftValue(satChange)
                satChange = 0
                return true
            end)
        ):Then(
            If(function() return brightChange ~= 0 end)
            :Then(wheel:doShow())
            :Then(function()
                wheel:brightness():shiftValue(brightChange)
                brightChange = 0
                return true
            end)
        ):Finally(function()
            updating(false)
        end)

        updateUI:action(update)

        local iWheel, iWheel4 = i18n(pKey), i18n(pKey.."4")

        local horiz = cwGroup:parameter(id + 1)
            :name(format("%s - %s - %s", iColorWheel, iWheel, iHorizontal))
            :name9(format("%s %s", iWheel4, iHorizontal4))
            :minValue(-1)
            :maxValue(1)
            :stepSize(ColorWell.KEY_PRESS)
            :onGet(function()
                local orientation = wheel:colorOrientation()
                return orientation and orientation.right
            end)
            :onChange(function(value)
                rightChange = rightChange + value
                updateUI()
            end)
            :onReset(wheel:colorWell():doReset())

        local vert = cwGroup:parameter(id + 2)
            :name(format("%s - %s - %s", iColorWheel, iWheel, iVertical))
            :name9(format("%s %s", iWheel4, iVertical4))
            :minValue(-1)
            :maxValue(1)
            :stepSize(ColorWell.KEY_PRESS)
            :onGet(function()
                local orientation = wheel:colorOrientation()
                return orientation and orientation.up
            end)
            :onChange(function(value)
                upChange = upChange + value
                updateUI()
            end)
            :onReset(wheel:colorWell():doReset())

        local sat = cwGroup:parameter(id + 3)
            :name(format("%s - %s - %s", iColorWheel, iWheel, iSaturation))
            :name9(format("%s %s", iWheel4, iSaturation4))
            :minValue(0)
            :maxValue(2)
            :stepSize(0.001)
            :onGet(function() wheel:saturation():value() end)
            :onChange(function(value)
                satChange = satChange + value
                updateUI()
            end)
            :onReset(function() wheel:show():saturation():value(1) end)

        cwGroup:parameter(id + 4)
            :name(format("%s - %s - %s", iColorWheel, iWheel, iBrightness))
            :name9(format("%s %s", iWheel4, iBrightness4))
            :minValue(-1)
            :maxValue(1)
            :stepSize(0.001)
            :onGet(function() wheel:brightness():value() end)
            :onChange(function(value)
                brightChange = brightChange + value
                updateUI()
            end)
            :onReset(function() wheel:show():brightness():value(0) end)

        cwGroup:binding(format("%s %s", iColorBoard, iWheel))
            :members(horiz, vert, sat)
    end

    local iColorWheel4 = i18n("colorWheel4")

    --------------------------------------------------------------------------------
    -- Color Wheel Temperature:
    --------------------------------------------------------------------------------

    -- Set up UI Updates:
    local tempChange, tintChange, hueChange, mixChange = 0, 0, 0, 0
    local updating = prop.FALSE()
    local update = Do(
        function() updating(true) end
    ):Then(
        If(function() return tempChange ~= 0 end)
        :Then(cw:doShow())
        :Then(function()
            cw:temperatureSlider():shiftValue(tempChange)
            tempChange = 0
            return true
        end)
    ):Then(
        If(function() return tintChange ~= 0 end)
        :Then(cw:doShow())
        :Then(function()
            cw:show():tintSlider():shiftValue(tintChange)
            tintChange = 0
            return true
        end)
    ):Then(
        If(function() return hueChange ~= 0 end)
        :Then(cw:doShow())
        :Then(function()
            local currentValue = cw:show():hue()
            if currentValue then
                cw:hue(currentValue+hueChange)
            end
            hueChange = 0
            return true
        end)
    ):Then(
        If(function() return mixChange ~= 0 end)
        :Then(cw:doShow())
        :Then(function()
            cw:show():mixSlider():shiftValue(mixChange)
            mixChange = 0
            return true
        end)
    )

    updateUI:action(update)

    -- Color Wheel Temperature
    cwGroup:parameter(wheelsBaseID+0x0101)
        :name(format("%s - %s", iColorWheel, i18n("temperature")))
        :name9(format("%s %s", iColorWheel4, i18n("temperature4")))
        :minValue(2500)
        :maxValue(10000)
        :stepSize(0.1)
        :onGet(function() return cw:temperature() end)
        :onChange(function(value)
            tempChange = tempChange + value
            updateUI()
        end)
        :onReset(function() cw:show():temperature(5000) end)

    --------------------------------------------------------------------------------
    -- Color Wheel Tint:
    --------------------------------------------------------------------------------
    cwGroup:parameter(wheelsBaseID+0x0102)
        :name(format("%s - %s", iColorWheel, i18n("tint")))
        :name9(format("%s %s", iColorWheel4, i18n("tint4")))
        :minValue(-50)
        :maxValue(50)
        :stepSize(0.1)
        :onGet(function() return cw:tint() end)
        :onChange(function(value)
            tintChange = tintChange + value
            updateUI()
        end)
        :onReset(function() cw:show():tintSlider():setValue(0) end)

    --------------------------------------------------------------------------------
    -- Color Wheel Hue:
    --------------------------------------------------------------------------------
    cwGroup:parameter(wheelsBaseID+0x0103)
        :name(format("%s - %s", iColorWheel, i18n("hue")))
        :name9(format("%s %s", iColorWheel4, i18n("hue4")))
        :minValue(0)
        :maxValue(360)
        :stepSize(0.1)
        :onGet(function() return cw:hue() end)
        :onChange(function(value)
            hueChange = hueChange + value
            updateUI()
        end)
        :onReset(function() cw:show():hue(0) end)

    --------------------------------------------------------------------------------
    -- Color Wheel Mix:
    --------------------------------------------------------------------------------
    cwGroup:parameter(wheelsBaseID+0x0104)
        :name(format("%s - %s", iColorWheel, i18n("mix")))
    :name9(format("%s %s", iColorWheel4, i18n("mix4")))
        :minValue(0)
        :maxValue(1)
        :stepSize(0.01)
        :onGet(function() return cw:mix() end)
        :onChange(function(value)
            mixChange = mixChange + value
            updateUI()
        end)
        :onReset(function() cw:show():mix(1) end)

    --------------------------------------------------------------------------------
    --
    -- COLOR SHORTCUTS:
    --
    --------------------------------------------------------------------------------
    local colorShortcutGroup = fcpGroup:group(i18n("colorShortcuts"))

    colorShortcutGroup:action(wheelsBaseID+0x0105, i18n("applyColorCorrectionFromPreviousClip"))
        :onPress(doShortcut("SetCorrectionFromEdit-Back-1"))
    colorShortcutGroup:action(wheelsBaseID+0x0106, i18n("applyColorCorrectionFromThreeClipsBack"))
        :onPress(doShortcut("SetCorrectionFromEdit-Back-3"))
    colorShortcutGroup:action(wheelsBaseID+0x0107, i18n("applyColorCorrectionFromTwoClipsBack"))
        :onPress(doShortcut("SetCorrectionFromEdit-Back-2"))
    colorShortcutGroup:action(wheelsBaseID+0x0108, i18n("enableDisableBalanceColor"))
        :onPress(doShortcut("ToggleColorBalance"))

    colorShortcutGroup:action(wheelsBaseID+0x0109, i18n("goToColorInspector"))
        :onPress(fcp:doSelectMenu({"Window", "Go To", "Color Inspector"}))

    colorShortcutGroup:action(wheelsBaseID+0x0110, i18n("matchColor"))
        :onPress(fcp:doSelectMenu({"Modify", "Match Color…"}))

    colorShortcutGroup:action(wheelsBaseID+0x0111, i18n("saveColorEffectPreset"))
        :onPress(doShortcut("SaveColorEffectPreset"))
    colorShortcutGroup:action(wheelsBaseID+0x0112, i18n("toggleColorCorrectionEffects"))
        :onPress(doShortcut("ColorBoard-ToggleAllCorrection"))
    colorShortcutGroup:action(wheelsBaseID+0x0113, i18n("toggleEffects"))
        :onPress(doShortcut("ToggleSelectedEffectsOff"))

    colorShortcutGroup:action(wheelsBaseID+0x0114, i18n("viewAlphaColorChannel"))
        :onPress(fcp:doSelectMenu({"View", "Show in Viewer", "Color Channels", "Alpha"}))

    colorShortcutGroup:action(wheelsBaseID+0x0115, i18n("viewRedColorChannel"))
        :onPress(fcp:doSelectMenu({"View", "Show in Viewer", "Color Channels", "Red"}))

    colorShortcutGroup:action(wheelsBaseID+0x0116, i18n("viewGreenColorChannel"))
        :onPress(fcp:doSelectMenu({"View", "Show in Viewer", "Color Channels", "Green"}))

    colorShortcutGroup:action(wheelsBaseID+0x0117, i18n("viewBlueColorChannel"))
        :onPress(fcp:doSelectMenu({"View", "Show in Viewer", "Color Channels", "Blue"}))

    colorShortcutGroup:action(wheelsBaseID+0x0118, i18n("viewAllColorChannels"))
        :onPress(fcp:doSelectMenu({"View", "Show in Viewer", "Color Channels", "All"}))

    colorShortcutGroup:action(wheelsBaseID+0x0119, i18n("switchBetweenInsideOutsideMarks"))
        :onPress(doShortcut("ColorBoard-ToggleInsideColorMask"))
    --------------------------------------------------------------------------------
    --
    -- COLOR BOARD ACTIONS:
    --
    --------------------------------------------------------------------------------

    ciGroup:action(wheelsBaseID+0x0120, i18n("addColorBoardEffect"))
        :onPress(ci:doAddCorrection("Color Board"))

    ciGroup:action(wheelsBaseID+0x0121, i18n("addColorWheelsEffect"))
        :onPress(ci:doAddCorrection("Color Wheels"))

    ciGroup:action(wheelsBaseID+0x0122, i18n("addColorCurvesEffect"))
        :onPress(ci:doAddCorrection("Color Curves"))

    ciGroup:action(wheelsBaseID+0x0123, i18n("addHueSatCurvesEffect"))
        :onPress(ci:doAddCorrection("Hue/Saturation Curves"))

    cbGroup:action(wheelsBaseID+0x0124, i18n("colorBoardShowColor"))
        :onPress(cb:color():doShow())

    cbGroup:action(wheelsBaseID+0x0125, i18n("colorBoardShowSaturation"))
        :onPress(cb:saturation():doShow())

    cbGroup:action(wheelsBaseID+0x0126, i18n("colorBoardShowExposure"))
        :onPress(cb:exposure():doShow())

    cbGroup:action(wheelsBaseID+0x0127, i18n("colorBoardNextPane"))
        :onPress(cb:aspectGroup():doNextOption())

    cbGroup:action(wheelsBaseID+0x0128, i18n("colorBoardPreviousPane"))
        :onPress(cb:aspectGroup():doPreviousOption())

    cbGroup:action(wheelsBaseID+0x0129, i18n("resetAllControls"))
        :onPress(doShortcut("ColorBoard-ResetAllPucks"))

    cbGroup:action(wheelsBaseID+0x0130, i18n("resetCurrentEffectPane"))
        :onPress(doShortcut("ColorBoard-ResetPucksOnCurrentBoard"))

    cbGroup:action(wheelsBaseID+0x0131, i18n("resetSelectedControl"))
        :onPress(doShortcut("ColorBoard-ResetSelectedPuck"))
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.color",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"]       = "manager",
        ["finalcutpro.tangent.group"]  = "fcpGroup",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.manager, deps.fcpGroup)

    return mod
end

return plugin
