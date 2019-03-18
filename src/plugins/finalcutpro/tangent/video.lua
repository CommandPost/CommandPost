--- === plugins.finalcutpro.tangent.video ===
---
--- Final Cut Pro Video Inspector for Tangent

local require = require

local log                   = require("hs.logger").new("tangentVideo")

local timer                 = require("hs.timer")

local deferred              = require("cp.deferred")
local dialog                = require("cp.dialog")
local Do                    = require("cp.rx.go.Do")
local fcp                   = require("cp.apple.finalcutpro")
local go                    = require("cp.rx.go")
local i18n                  = require("cp.i18n")
local If                    = require('cp.rx.go.If')
local tools                 = require("cp.tools")

local delayed               = timer.delayed
local spairs                = tools.spairs
local WaitUntil             = go.WaitUntil

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- DEFER -> number
-- Constant
-- The amount of time to defer UI updates
local DEFER = 0.01

-- doStabilizationMethod(value) -> none
-- Function
-- Enables or disables Stabilisation.
--
-- Parameters:
--  * value - The stabilisation mode you wish to change the clip(s) too as a string
--            (as it appears in the Inspector in English).
--
-- Returns:
--  * None
local function doStabilizationMethod(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local method = fcp:inspector():video():stabilization():method()

    return Do(function()
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        local clips = timelineContents:selectedClipsUI()
        if clips and #clips == 0 then
            log.ef("Set Blend Mode Failed: No clips selected.")
            tools.playErrorSound()
            return false
        end

        return Do(method:doSelectValue(value))
        :Then(WaitUntil(method):Is(value):TimeoutAfter(2000))
        :Then(true)
    end)
    :Catch(function(message)
        dialog.displayErrorMessage(message)
        return false
    end)
    :Label("video.doStabilizationMethod")
end


-- xyParameter() -> none
-- Function
-- Sets up a new XY Parameter
--
-- Parameters:
--  * group - The Tangent Group
--  * param - The Parameter
--  * id - The Tangent ID
--
-- Returns:
--  * An updated ID
--  * The `x` parameter value
--  * The `y` parameter value
--  * The xy binding
local function xyParameter(group, param, id, minValue, maxValue, stepSize)
    minValue, maxValue, stepSize = minValue or 0, maxValue or 100, stepSize or 0.5

    --------------------------------------------------------------------------------
    -- Set up the accumulator:
    --------------------------------------------------------------------------------
    local x, y = 0, 0
    local updateUI = deferred.new(DEFER)
    local updating = false
    updateUI:action(
        If(function() return not updating and (x ~= 0 or y ~= 0) end)
        :Then(
            Do(param:doShow())
            :Then(function()
                updating = true
                if x ~= 0 then
                    local current = param:x()
                    if current then
                        param:x(current + x)
                    end
                    x = 0
                end
                if y ~= 0 then
                    local current = param:y()
                    if current then
                        param:y(current + y)
                    end
                    y = 0
                end
                updating = false
            end)
        )
    )

    local label = param:label()
    local xParam = group:parameter(id + 1)
        :name(label .. " X")
        :minValue(minValue)
        :maxValue(maxValue)
        :stepSize(stepSize)
        :onGet(function() return param:x() end)
        :onChange(function(amount)
            x = x + amount
            updateUI()
        end)
        :onReset(function() param:x(0) end)

    local yParam = group:parameter(id + 2)
        :name(label .. " Y")
        :minValue(minValue)
        :maxValue(maxValue)
        :stepSize(stepSize)
        :onGet(function() return param:y() end)
        :onChange(function(amount)
            y = y + amount
            updateUI()
        end)
        :onReset(function() param:y(0) end)

    local xyBinding = group:binding(label):members(xParam, yParam)

    return id + 2, xParam, yParam, xyBinding
end

-- sliderParameter() -> none
-- Function
-- Sets up a new Slider Parameter
--
-- Parameters:
--  * group - The Tangent Group
--  * param - The Parameter
--  * id - The Tangent ID
--  * minValue - The minimum value
--  * maxValue - The maximum value
--  * stepSize - The step size
--  * default - The default value
--
-- Returns:
--  * An updated ID
--  * The parameters value
local function sliderParameter(group, param, id, minValue, maxValue, stepSize, default)
    local label = param:label()

    --------------------------------------------------------------------------------
    -- Set up deferred update:
    --------------------------------------------------------------------------------
    local value = 0
    local updateUI = deferred.new(DEFER)
    local updating = false
    updateUI:action(
        If(function() return not updating and value ~= 0 end)
        :Then(
            Do(param:doShow())
            :Then(function()
                updating = true
                local currentValue = param:value()
                if currentValue then
                    param:value(currentValue + value)
                    value = 0
                end
                updating = false
            end)
        )
    )

    default = default or 0

    local valueParam = group:parameter(id + 1)
        :name(label)
        :minValue(minValue)
        :maxValue(maxValue)
        :stepSize(stepSize)
        :onGet(function() return param:value() end)
        :onChange(function(amount)
            value = value + amount
            updateUI()
        end)
        :onReset(function() param:value(default) end)

    return id + 1, valueParam
end

-- doBlendMode(value) -> none
-- Function
-- Changes the Blend Mode.
--
-- Parameters:
--  * value - The blend mode you wish to change the clip(s) too as a string.
--
-- Returns:
--  * None
local function doBlendMode(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local blendMode = fcp:inspector():video():compositing():blendMode()

    return Do(function()
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        local clips = timelineContents:selectedClipsUI()
        if clips and #clips == 0 then
            log.ef("Set Blend Mode Failed: No clips selected.")
            tools.playErrorSound()
            return false
        end

        return Do(blendMode:doSelectValue(value))
        :Then(WaitUntil(blendMode):Is(value):TimeoutAfter(2000))
        :Then(true)
    end)
    :Catch(function(message)
        dialog.displayErrorMessage(message)
        return false
    end)
    :Label("video.doBlendMode")
end

--- plugins.finalcutpro.tangent.video.init(deps) -> self
--- Function
--- Initialise the module.
---
--- Parameters:
---  * deps - Dependancies
---
--- Returns:
---  * Self
function mod.init(deps)
    local video = fcp:inspector():video()

    --------------------------------------------------------------------------------
    -- Video Mode:
    --------------------------------------------------------------------------------
    deps.tangentManager.addMode(0x00010010, "FCP: " .. i18n("video"))

    --------------------------------------------------------------------------------
    -- Video Group:
    --------------------------------------------------------------------------------
    mod._videoGroup = deps.fcpGroup:group(i18n("video") .. " " .. i18n("inspector"))

    --------------------------------------------------------------------------------
    -- Transform Group:
    --------------------------------------------------------------------------------
    local transform = video:transform()
    local transformGroup = mod._videoGroup:group(transform:label())

    --------------------------------------------------------------------------------
    -- Scale & Anchor:
    --------------------------------------------------------------------------------
    local id = 0x0F730000

    local px, py, rotation
    id, px, py = xyParameter(transformGroup, transform:position(), id, 0, 1000, 0.1)
    id, rotation = sliderParameter(transformGroup, transform:rotation(), id, 0, 360, 0.1)
    transformGroup:binding(tostring(transform:position()) .. " " .. tostring(transform:rotation()))
        :members(px, py, rotation)

    id = sliderParameter(transformGroup, transform:scaleAll(), id, 0, 100, 0.1, 100.0)
    id = sliderParameter(transformGroup, transform:scaleX(), id, 0, 100, 0.1, 100.0)
    id = sliderParameter(transformGroup, transform:scaleY(), id, 0, 100, 0.1, 100.0)

    id = xyParameter(transformGroup, transform:anchor(), id, 0, 1000, 0.1)

    --------------------------------------------------------------------------------
    -- Video Blend Modes Knob:
    --------------------------------------------------------------------------------
    local getShortBlendModei18n = function(i)
        if i == 1 then
            return i18n("normal9")
        elseif i == 2 then
            return i18n("subtract9")
        elseif i == 3 then
            return i18n("darken9")
        elseif i == 4 then
            return i18n("multiply9")
        elseif i == 5 then
            return i18n("colorBurn9")
        elseif i == 6 then
            return i18n("linearBurn9")
        elseif i == 7 then
            return i18n("add9")
        elseif i == 8 then
            return i18n("lighten9")
        elseif i == 9 then
            return i18n("screen9")
        elseif i == 10 then
            return i18n("colorDodge9")
        elseif i == 11 then
            return i18n("linearDodge9")
        elseif i == 12 then
            return i18n("overlay9")
        elseif i == 13 then
            return i18n("softLight9")
        elseif i == 14 then
            return i18n("hardLight9")
        elseif i == 15 then
            return i18n("viviLight9")
        elseif i == 16 then
            return i18n("linearLight9")
        elseif i == 17 then
            return i18n("pinLight9")
        elseif i == 18 then
            return i18n("hardMix9")
        elseif i == 19 then
            return i18n("difference9")
        elseif i == 20 then
            return i18n("exclusion9")
        elseif i == 21 then
            return i18n("stencilAlpha9")
        elseif i == 22 then
            return i18n("stencilLuma9")
        elseif i == 23 then
            return i18n("silhouetteAlpha9")
        elseif i == 24 then
            return i18n("silhouetteLuma9")
        elseif i == 25 then
            return i18n("behind9")
        elseif i == 26 then
            return i18n("alphaAdd9")
        elseif i == 27 then
            return i18n("premultipliedMix9")
        end
    end

    local getLongBlendModei18n = function(name)
        if name == "Normal" then
            return i18n("normal")
        elseif name == "Subtract" then
            return i18n("subtract")
        elseif name == "Darken" then
            return i18n("darken")
        elseif name == "Multiply" then
            return i18n("multiply")
        elseif name == "Color Burn" then
            return i18n("colorBurn")
        elseif name == "Linear Burn" then
            return i18n("linearBurn")
        elseif name == "Add" then
            return i18n("add")
        elseif name == "Lighten" then
            return i18n("lighten")
        elseif name == "Screen" then
            return i18n("screen")
        elseif name == "Color Dodge" then
            return i18n("colorDodge")
        elseif name == "Linear Dodge" then
            return i18n("linearDodge")
        elseif name == "Overlay" then
            return i18n("overlay")
        elseif name == "Soft Light" then
            return i18n("softLight")
        elseif name == "Hard Light" then
            return i18n("hardLight")
        elseif name == "Vivid Light" then
            return i18n("vividLight")
        elseif name == "Linear Light" then
            return i18n("linearLight")
        elseif name == "Pin Light" then
            return i18n("pinLight")
        elseif name == "Hard Mix" then
            return i18n("hardMix")
        elseif name == "Difference" then
            return i18n("difference")
        elseif name == "Exclusion" then
            return i18n("exclusion")
        elseif name == "Stencil Alpha" then
            return i18n("stencilAlpha")
        elseif name == "Stencil Luma" then
            return i18n("stencilLuma")
        elseif name == "Silhouette Alpha" then
            return i18n("silhouetteAlpha")
        elseif name == "Silhouette Luma" then
            return i18n("silhouetteLuma")
        elseif name == "Behind" then
            return i18n("behind")
        elseif name == "Alpha Add" then
            return i18n("alphaAdd")
        elseif name == "Premultiplied Mix" then
            return i18n("premultipliedMix")
        end
    end

    local blendModes = {
        [1] = "FFHeliumBlendModeNormal",
        [2] = "FFHeliumBlendModeSubtract",
        [3] = "FFHeliumBlendModeDarken",
        [4] = "FFHeliumBlendModeMultiply",
        [5] = "FFHeliumBlendModeColorBurn",
        [6] = "FFHeliumBlendModeLinearBurn",
        [7] = "FFHeliumBlendModeAdd",
        [8] = "FFHeliumBlendModeLighten",
        [9] = "FFHeliumBlendModeScreen",
        [10] = "FFHeliumBlendModeColorDodge",
        [11] = "FFHeliumBlendModeLinearDodge",
        [12] = "FFHeliumBlendModeOverlay",
        [13] = "FFHeliumBlendModeSoftLight",
        [14] = "FFHeliumBlendModeHardLight",
        [15] = "FFHeliumBlendModeVividLight",
        [16] = "FFHeliumBlendModeLinearLight",
        [17] = "FFHeliumBlendModePinLight",
        [18] = "FFHeliumBlendModeHardMix",
        [19] = "FFHeliumBlendModeDifference",
        [20] = "FFHeliumBlendModeExclusion",
        [21] = "FFHeliumBlendModeStencilAlpha",
        [22] = "FFHeliumBlendModeStencilLuma",
        [23] = "FFHeliumBlendModeSilhouetteAlpha",
        [24] = "FFHeliumBlendModeSilhouetteLuma",
        [25] = "FFHeliumBlendModeBehind",
        [26] = "FFHeliumBlendModeAlphaAdd",
        [27] = "FFHeliumBlendModePremultipliedMix",
    }
    local numberOfBlendModes = 27

    local blendModeNameToID = function(value)
        for i, code in pairs(blendModes) do
            if value == fcp:string(code) then
                return i
            end
        end
    end

    local blendModeUpdate = deferred.new(0.5):action(function()
        video:compositing():blendMode():value(mod._nextBlendMode)
        mod.cachedBlendModeID = nil
    end)

    mod.cachedBlendModeID = nil

    local onChange = function(increase)
        video:compositing():blendMode():show()

        local currentBlendMode = video:compositing():blendMode():value()
        local currentBlendModeID = mod.cachedBlendModeID or (currentBlendMode and blendModeNameToID(currentBlendMode))
        if currentBlendModeID then
            if increase then
                currentBlendModeID = currentBlendModeID + 1
                if currentBlendModeID > numberOfBlendModes then
                    currentBlendModeID = 1
                end
            else
                currentBlendModeID = currentBlendModeID - 1
                if currentBlendModeID <= 0 then
                    currentBlendModeID = numberOfBlendModes
                end
            end

            mod.cachedBlendModeID = currentBlendModeID

            local newName = currentBlendModeID and fcp:string(blendModes[currentBlendModeID])
            if newName then
                mod._nextBlendMode = newName
                blendModeUpdate()
            end
        end
    end

    local compositing = video:compositing()
    local compositingGroup = mod._videoGroup:group(compositing:label())

    id = id + 1
    compositingGroup:menu(id)
        :name(i18n("blendMode"))
        :name9(i18n("blendMode9"))
        :onGet(function()
            if mod.cachedBlendModeID then
                return getShortBlendModei18n(mod.cachedBlendModeID)
            else
                local currentBlendMode = video:compositing():blendMode():value()
                local result = currentBlendMode and blendModeNameToID(currentBlendMode)
                return result and getShortBlendModei18n(result)
            end
        end)
        :onNext(function() onChange(true) end)
        :onPrev(function() onChange(false) end)
        :onReset(function()
            video:compositing():blendMode():show():value(fcp:string("FFHeliumBlendModeNormal"))
        end)

    --------------------------------------------------------------------------------
    -- Video Blend Modes Buttons:
    --------------------------------------------------------------------------------
    id = id + 1
    mod._videoBlendGroup = compositingGroup:group("Blend Modes")
    for code, name in spairs(fcp:inspector():video().blendModes) do
        mod._videoBlendGroup
            :action(id, getLongBlendModei18n(name))
            :onPress(doBlendMode(fcp:string(code)))
        id = id + 1
    end

    --------------------------------------------------------------------------------
    -- Crop Group:
    --------------------------------------------------------------------------------
    id = id + 1
    local crop = video:crop()
    local cropGroup = mod._videoGroup:group(crop:label())

    id = sliderParameter(cropGroup, crop:left(), id, 0, 1080, 0.1, 0)
    id = sliderParameter(cropGroup, crop:right(), id, 0, 1080, 0.1, 0)
    id = sliderParameter(cropGroup, crop:top(), id, 0, 1080, 0.1, 0)
    id = sliderParameter(cropGroup, crop:bottom(), id, 0, 1080, 0.1, 0)

    --------------------------------------------------------------------------------
    -- Crop Type Buttons:
    --------------------------------------------------------------------------------
    local cropTypes = {
        [1] = {flexoID = "FFTrim", i18n = "trim"},
        [2] = {flexoID = "FFCrop", i18n = "crop"},
        [3] = {flexoID = "FFKenBurns", i18n = "kenBurns"},
    }

    id = id + 1
    for _, v in pairs(cropTypes) do
        cropGroup
            :action(id, i18n(v.i18n))
            :onPress(function()
                video:crop():type():show()
                video:crop():type():value(fcp:string(v.flexoID))
            end)
        id = id + 1
    end

    --------------------------------------------------------------------------------
    -- Crop Type Knob:
    --------------------------------------------------------------------------------
    local cropTypeNameToID = function(name)
        for i, v in pairs(cropTypes) do
            if name == fcp:string(v.flexoID) then
                return i
            end
        end
    end

    local cropTypeUpdate = delayed.new(0.5, function()
        video:crop():type():value(fcp:string(cropTypes[mod._cropTypeCache].flexoID))
        mod._cropTypeCache = nil
    end)

    mod._cropTypeCache = nil
    cropGroup:menu(id)
        :name(i18n("type"))
        :name9(i18n("type"))
        :onGet(function()
            if mod._cropTypeCache then
                return i18n(cropTypes[mod._cropTypeCache].i18n)
            else
                return video:crop():type():value()
            end
        end)
        :onNext(function()
            video:crop():type():show()
            local currentValue = video:crop():type():value()
            local currentValueID = mod._cropTypeCache or (currentValue and cropTypeNameToID(currentValue))
            local newID = currentValueID and currentValueID + 1
            if newID == 4 then newID = 1 end
            mod._cropTypeCache = newID
            cropTypeUpdate:start()
        end)
        :onPrev(function()
            video:crop():type():show()
            local currentValue = video:crop():type():value()
            local currentValueID = mod._cropTypeCache or (currentValue and cropTypeNameToID(currentValue))
            local newID = currentValueID and currentValueID - 1
            if newID == 0 then newID = 3 end
            mod._cropTypeCache = newID
            cropTypeUpdate:start()
        end)
        :onReset(function()
            video:crop():type():show()
            video:crop():type():value(fcp:string("FFTrim"))
        end)

    --------------------------------------------------------------------------------
    -- Distort Group:
    --------------------------------------------------------------------------------
    local distort = video:distort()
    local distortGroup = mod._videoGroup:group(distort:label())

    id = id + 1
    id = xyParameter(distortGroup, distort:bottomLeft(), id, 0, 1080, 0.1)
    id = xyParameter(distortGroup, distort:bottomRight(), id, 0, 1080, 0.1)
    id = xyParameter(distortGroup, distort:topRight(), id, 0, 1080, 0.1)
    id = xyParameter(distortGroup, distort:topLeft(), id, 0, 1080, 0.1)

    --------------------------------------------------------------------------------
    -- Opacity:
    --------------------------------------------------------------------------------
    id = sliderParameter(compositingGroup, compositing:opacity(), id, 0, 100, 0.1, 100)

    --------------------------------------------------------------------------------
    -- Stabilization Enable/Disable:
    --------------------------------------------------------------------------------
    local stabilization = video:stabilization()
    local stabilizationGroup = mod._videoGroup:group(stabilization:label())

    id = id + 1
    stabilizationGroup
        :action(id, i18n("toggle"))
        :onPress(function()
            stabilization:show()
            local checkbox = stabilization.enabled
            if checkbox then
                checkbox:toggle()
            end
        end)

    --------------------------------------------------------------------------------
    -- Stabilization Method Buttons:
    --------------------------------------------------------------------------------
    id = id + 1
    stabilizationGroup
        :action(id, i18n("automatic"))
        :onPress(doStabilizationMethod("Automatic"))


    id = id + 1
    stabilizationGroup
        :action(id, i18n("inertiaCam"))
        :onPress(doStabilizationMethod("InertiaCam"))

    id = id + 1
    stabilizationGroup
        :action(id, i18n("smoothCam"))
        :onPress(doStabilizationMethod("SmoothCam"))

    --------------------------------------------------------------------------------
    -- Stabilization Method Knob:
    --------------------------------------------------------------------------------
    local stabilizationMethods = {
        [1] = {flexoID = "FFStabilizationDynamic", i18n="automatic"},
        [2] = {flexoID = "FFStabilizationUseInertiaCam", i18n="inertiaCam"},
        [3] = {flexoID = "FFStabilizationUseSmoothCam", i18n="smoothCam"},
    }

    local stabilizationMethodToID = function(name)
        for i, v in pairs(stabilizationMethods) do
            if name == fcp:string(v.flexoID) then
                return i
            end
        end
    end

    local stabilizationMethodUpdate = delayed.new(0.5, function()
        video:stabilization():method():value(fcp:string(stabilizationMethods[mod._stabilizationMethodCache].flexoID))
        mod._stabilizationMethodCache = nil
    end)

    mod._stabilizationMethodCache = nil
    id = id + 1
    stabilizationGroup:menu(id)
        :name(i18n("method"))
        :name9(i18n("method"))
        :onGet(function()
            if mod._stabilizationMethodCache then
                return i18n(stabilizationMethods[mod._stabilizationMethodCache].i18n)
            else
                return stabilization:method():value()
            end
        end)
        :onNext(function()
            stabilization:method():show()
            local currentValue = stabilization:method():value()
            local currentValueID = mod._stabilizationMethodCache or (currentValue and stabilizationMethodToID(currentValue))
            local newID = currentValueID and currentValueID + 1
            if newID == 4 then newID = 1 end
            mod._stabilizationMethodCache = newID
            stabilizationMethodUpdate:start()
        end)
        :onPrev(function()
            stabilization:method():show()
            local currentValue = stabilization:method():value()
            local currentValueID = mod._stabilizationMethodCache or (currentValue and stabilizationMethodToID(currentValue))
            local newID = currentValueID and currentValueID - 1
            if newID == 0 then newID = 3 end
            mod._stabilizationMethodCache = newID
            stabilizationMethodUpdate:start()
        end)
        :onReset(function()
            mod._stabilizationMethodCache = 1
            video:stabilization():method():show()
            video:stabilization():method():value(fcp:string("FFStabilizationDynamic"))
            mod._stabilizationMethodCache = nil
        end)

    --------------------------------------------------------------------------------
    -- Stabilization Sliders:
    --------------------------------------------------------------------------------
    id = id + 1
    id = sliderParameter(stabilizationGroup, stabilization:translationSmooth(), id, 0, 4.5, 0.1, 1.5)
    id = sliderParameter(stabilizationGroup, stabilization:rotationSmoooth(), id, 0, 4.5, 0.1, 1.5)
    id = sliderParameter(stabilizationGroup, stabilization:scaleSmooth(), id, 0, 4.5, 0.1, 1.5)
    id = sliderParameter(stabilizationGroup, stabilization:smoothing(), id, 0, 3, 0.1, 1)

    --------------------------------------------------------------------------------
    -- Stabilization Checkboxes:
    --------------------------------------------------------------------------------
    --tripodMode

    --------------------------------------------------------------------------------
    -- Rolling Shutter:
    --------------------------------------------------------------------------------
    -- TODO

    --------------------------------------------------------------------------------
    -- Spatial Conform:
    --------------------------------------------------------------------------------
    -- TODO

    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.video",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
        ["core.tangent.manager"]       = "tangentManager",
    }
}

function plugin.init(deps)
    return mod.init(deps)
end

return plugin
