--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.tangent.manager ===
---
--- Final Cut Pro Tangent Manager.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
-- local log                                       = require("hs.logger").new("fcp_tangent")

local delayed                                   = require("hs.timer").delayed

local fcp                                       = require("cp.apple.finalcutpro")

local ColorWell                                 = require("cp.apple.finalcutpro.inspector.color.ColorWell")

local format                                    = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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
    mod._manager = tangentManager

    tangentManager.addMode(0x00010003, "FCP: Board")
        :onActivate(function()
            fcp:colorBoard():show()
        end)

    tangentManager.addMode(0x00010004, "FCP: Wheels")
        :onActivate(function()
            fcp:inspector():color():colorWheels():show()
        end)

    --------------------------------------------------------------------------------
    -- Add Final Cut Pro Parameters:
    --------------------------------------------------------------------------------

    local ciGroup = fcpGroup:group(i18n("fcpx_colorInspector_action"))

    -- The section all Color Inspector controls are in.
    local baseID = 0x00300000

    local aspects = { "color", "saturation", "exposure" }

    local ranges = { "master", "shadows", "midtones", "highlights" }

    -- Handle the Color Board
    local cbGroup = ciGroup:group(i18n("colorBoard"))
    local cb = fcp:colorBoard()

    -- The multiplier for aspects (color/saturation/exposure).
    local aspectBaseID = 0x01000
    -- The multiplier for ranges.
    local rangeBaseID = 0x00100

    -- look up some terms
    local iColorBoard, iColorBoard2, iAngle, iAngle3, iPercentage, iPercentage3 =
        i18n("colorBoard"), i18n("colorBoard2"), i18n("angle"), i18n("angle3"), i18n("percentage"), i18n("percentage3")

    for i,aKey in ipairs(aspects) do
        local aspect = cb[aKey](cb)
        local aspectID = baseID + i*aspectBaseID

        local aName = i18n(aKey)
        for j,pKey in ipairs(ranges) do
            local puck = aspect[pKey](aspect)
            local rangeID = aspectID + j*rangeBaseID

            local pName, pName2 = i18n(pKey), i18n(pKey.."2")

            local percent = cbGroup:parameter(rangeID + 2)
                :name(format("%s - %s - %s - %s", iColorBoard, aName, pName, iPercentage))
                :name9(format("%s %s %s", iColorBoard2, pName2, iPercentage3))
                :minValue(-100)
                :maxValue(100)
                :stepSize(1)
                :onGet(function() return puck:show():percent() end)
                :onChange(function(value) return puck:show():shiftPercent(value) end)
                :onReset(function() puck:show():reset() end)

            if puck:hasAngle() then
                local angle = cbGroup:parameter(rangeID + 1)
                    :name(format("%s - %s - %s - %s", iColorBoard, aName, pName, iAngle))
                    :name9(format("%s %s %s", iColorBoard2, pName2, iAngle3))
                    :minValue(0)
                    :maxValue(359)
                    :stepSize(1)
                    :onGet(function() return puck:show():angle() end)
                    :onChange(function(value) return puck:show():shiftAngle(value) end)
                    :onReset(function() puck:show():reset() end)

                cbGroup:binding(format("%s %s %s", iColorBoard, pName, aName))
                    :member(angle)
                    :member(percent)
            end
        end
    end

    -- handle the color wheels
    local cwGroup = ciGroup:group(i18n("colorWheels"))
    local cw = fcp:inspector():color():colorWheels()

    local wheelsBaseID = baseID + 0x010000
    local wheelID = 0x010
    local iColorWheel, iHorizontal, iHorizontal4, iVertical, iVertical4 =
        i18n("colorWheel"), i18n("horizontal"), i18n("horizontal4"), i18n("vertical"), i18n("vertical4")
    local iSaturation, iSaturation4, iBrightness, iBrightness4 = i18n("saturation"), i18n("saturation4"), i18n("brightness"), i18n("brightness4")

    -- set up an accumulator/timer to update changes
    local changes = {}
    local changeTimer = delayed.new(0.02, function()
        for _,v in ipairs(changes) do
            if v.right ~= 0 or v.up ~= 0 then
                v.wheel:show():nudgeColor(v.right, v.up)
                v.right, v.up = 0, 0
            end
        end
    end)

    for i,pKey in ipairs(ranges) do
        local wheel = cw[pKey](cw)
        local id = wheelsBaseID + i*wheelID

        local change = {wheel = wheel, right=0, up=0}
        changes[i] = change

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
                change.right = change.right + value
                if not changeTimer:running() then
                    changeTimer:start()
                end
            end)
            :onReset(function() wheel:colorWell():reset() end)

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
                change.up = change.up + value
                if not changeTimer:running() then
                    changeTimer:start()
                end
            end)
            :onReset(function() wheel:colorWell():reset() end)

        local sat = cwGroup:parameter(id + 3)
            :name(format("%s - %s - %s", iColorWheel, iWheel, iSaturation))
            :name9(format("%s %s", iWheel4, iSaturation4))
            :minValue(0)
            :maxValue(2)
            :stepSize(0.01)
            :onGet(function() wheel:saturation():value() end)
            :onChange(function(value) wheel:show():saturation():shiftValue(value) end)
            :onReset(function() wheel:show():saturation():value(1) end)

        cwGroup:parameter(id + 4)
            :name(format("%s - %s - %s", iColorWheel, iWheel, iBrightness))
            :name9(format("%s %s", iWheel4, iBrightness4))
            :minValue(-1)
            :maxValue(1)
            :stepSize(0.01)
            :onGet(function() wheel:brightness():value() end)
            :onChange(function(value) wheel:show():brightness():shiftValue(value) end)
            :onReset(function() wheel:show():brightness():value(0) end)

        cwGroup:binding(format("%s %s", iColorBoard, iWheel))
            :members(horiz, vert, sat)
    end

    local iColorWheel4 = i18n("colorWheel4")

    -- Color Wheel Temperature
    cwGroup:parameter(wheelsBaseID+0x0101)
        :name(format("%s - %s", iColorWheel, i18n("temperature")))
        :name9(format("%s %s", iColorWheel4, i18n("temperature4")))
        :minValue(2500)
        :maxValue(10000)
        :stepSize(0.1)
        :onGet(function() return cw:temperature() end)
        :onChange(function(value) cw:show():temperatureSlider():shiftValue(value) end)
        :onReset(function() cw:show():temperature(5000) end)

    cwGroup:parameter(wheelsBaseID+0x0102)
        :name(format("%s - %s", iColorWheel, i18n("tint")))
        :name9(format("%s %s", iColorWheel4, i18n("tint4")))
        :minValue(-50)
        :maxValue(50)
        :stepSize(0.1)
        :onGet(function() return cw:tint() end)
        :onChange(function(value) cw:show():tintSlider():shiftValue(value) end)
        :onReset(function() cw:show():tintSlider():setValue(0) end)

    cwGroup:parameter(wheelsBaseID+0x0103)
        :name(format("%s - %s", iColorWheel, i18n("hue")))
        :name9(format("%s %s", iColorWheel4, i18n("hue4")))
        :minValue(0)
        :maxValue(360)
        :stepSize(0.1)
        :onGet(function() return cw:hue() end)
        :onChange(function(value)
            local currentValue = cw:show():hue()
            if currentValue then
                cw:hue(currentValue+value)
            end
        end)
        :onReset(function() cw:show():hue(0) end)

    cwGroup:parameter(wheelsBaseID+0x0104)
        :name(format("%s - %s", iColorWheel, i18n("mix")))
    :name9(format("%s %s", iColorWheel4, i18n("mix4")))
        :minValue(0)
        :maxValue(1)
        :stepSize(0.01)
        :onGet(function() return cw:mix() end)
        :onChange(function(value) cw:show():mixSlider():shiftValue(value) end)
        :onReset(function() cw:show():mix(1) end)
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

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.manager, deps.fcpGroup)

    return mod
end

return plugin