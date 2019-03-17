--- === plugins.finalcutpro.tangent.video ===
---
--- Final Cut Pro Video Inspector for Tangent

local require = require

local log                   = require("hs.logger").new("tangentVideo")

local deferred              = require("cp.deferred")
local dialog                = require("cp.dialog")
local Do                    = require("cp.rx.go.Do")
local fcp                   = require("cp.apple.finalcutpro")
local go                    = require("cp.rx.go")
local i18n                  = require("cp.i18n")
local If                    = require('cp.rx.go.If')
local tools                 = require("cp.tools")

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
    deps.tangentManager.addMode(0x00010010, "FCP: Video")

    --------------------------------------------------------------------------------
    -- Transform Group:
    --------------------------------------------------------------------------------
    mod._videoGroup = deps.fcpGroup:group(i18n("video") .. " " .. i18n("inspector"))

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
    local shortBlendModes = {
        [1]     = "Normal",
        [2]     = "Subtract",
        [3]     = "Darken",
        [4]     = "Multiply",
        [5]     = "ColorBurn",
        [6]     = "LinBurn",
        [7]     = "Add",
        [8]     = "Lighten",
        [9]     = "Screen",
        [10]    = "ColorDodg",
        [11]    = "LinDodg",
        [12]    = "Overlay",
        [13]    = "SoftLight",
        [14]    = "HardLight",
        [15]    = "VivLight",
        [16]    = "LinLight",
        [17]    = "PinLight",
        [18]    = "HardMix",
        [19]    = "Diff",
        [20]    = "Exclusion",
        [21]    = "Stencil A",
        [22]    = "Stencil L",
        [23]    = "Sil Alpha",
        [24]    = "Sil Luma",
        [25]    = "Behind",
        [26]    = "Alpha Add",
        [27]    = "Premulti",
    }

    local getShortBlendModei18n = function(id)
        if id == 1 then
            return i18n("normal9")
        elseif id == 2 then
            return i18n("subtract9")
        elseif id == 3 then
            return i18n("darken9")
        elseif id == 4 then
            return i18n("multiply9")
        elseif id == 5 then
            return i18n("colorBurn9")
        elseif id == 6 then
            return i18n("linearBurn9")
        elseif id == 7 then
            return i18n("add9")
        elseif id == 8 then
            return i18n("lighten9")
        elseif id == 9 then
            return i18n("screen9")
        elseif id == 10 then
            return i18n("colorDodge9")
        elseif id == 11 then
            return i18n("linearDodge9")
        elseif id == 12 then
            return i18n("overlay9")
        elseif id == 13 then
            return i18n("softLight9")
        elseif id == 14 then
            return i18n("hardLight9")
        elseif id == 15 then
            return i18n("vividLight9")
        elseif id == 16 then
            return i18n("linearLight9")
        elseif id == 17 then
            return i18n("pinLight9")
        elseif id == 18 then
            return i18n("hardMix9")
        elseif id == 19 then
            return i18n("difference9")
        elseif id == 20 then
            return i18n("exclusion9")
        elseif id == 21 then
            return i18n("stencilAlpha9")
        elseif id == 22 then
            return i18n("stencilLuma9")
        elseif id == 23 then
            return i18n("silhouetteAlpha9")
        elseif id == 24 then
            return i18n("silhouetteLuma9")
        elseif id == 25 then
            return i18n("behind9")
        elseif id == 26 then
            return i18n("alphaAdd9")
        elseif id == 27 then
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

    mod._videoGroup:menu(id + 1)
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
    mod._videoBlendGroup = mod._videoGroup:group("Blend Modes")
    for code, name in spairs(fcp:inspector():video().blendModes) do
        mod._videoBlendGroup
            :action(id + 2, getLongBlendModei18n(name))
            :onPress(doBlendMode(fcp:string(code)))
        id = id + 1
    end

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
