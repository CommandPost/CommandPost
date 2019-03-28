--- === plugins.finalcutpro.inspector.video ===
---
--- Final Cut Pro Video Inspector Additions.

local require = require

local log               = require("hs.logger").new("videoInspector")

local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local go                = require("cp.rx.go")
local i18n              = require("cp.i18n")
local tools             = require("cp.tools")

local Do                = go.Do
local WaitUntil         = go.WaitUntil

-- doSpatialConformType(value) -> none
-- Function
-- Sets the Spatial Conform Type.
--
-- Parameters:
--  * value - The conform type you wish to change the clip(s) too as a string
--            (as it appears in the Inspector in English).
--
-- Returns:
--  * None
local function doSpatialConformType(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local spatialConformType = fcp:inspector():video():spatialConform():type()

    return Do(function()
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        local clips = timelineContents:selectedClipsUI()
        if clips and #clips == 0 then
            log.ef("Set Spatial Conform Failed: No clips selected.")
            tools.playErrorSound()
            return false
        end

        return Do(spatialConformType:doSelectValue(value))
        :Then(WaitUntil(spatialConformType):Is(value):TimeoutAfter(2000))
        :Then(true)
    end)
    :Catch(function(message)
        dialog.displayErrorMessage(message)
        return false
    end)
    :Label("video.doSpatialConformType")

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

-- doStabilization(value) -> none
-- Function
-- Enables or disables Stabilisation.
--
-- Parameters:
--  * value - `true` to enable, `false` to disable.
--
-- Returns:
--  * None
local function doStabilization(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local stabilization = fcp:inspector():video():stabilization().enabled

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

        if value then
            return Do(stabilization:doCheck())
            :Then(WaitUntil(stabilization):Is(value):TimeoutAfter(2000))
            :Then(true)
        else
            return Do(stabilization:doUncheck())
            :Then(WaitUntil(stabilization):Is(value):TimeoutAfter(2000))
            :Then(true)
        end
    end)
    :Catch(function(message)
        dialog.displayErrorMessage(message)
        return false
    end)
    :Label("video.doStabilization")
end

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

-- doRollingShutter(value) -> none
-- Function
-- Enables or disables Stabilisation.
--
-- Parameters:
--  * value - `true` to enable, `false` to disable.
--
-- Returns:
--  * None
local function doRollingShutter(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local rollingShutter = fcp:inspector():video():rollingShutter().enabled

    return Do(function()
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        local clips = timelineContents:selectedClipsUI()
        if clips and #clips == 0 then
            log.ef("Set Rolling Shutter Failed: No clips selected.")
            tools.playErrorSound()
            return false
        end

        if value then
            return Do(rollingShutter:doCheck())
            :Then(WaitUntil(rollingShutter):Is(value):TimeoutAfter(2000))
            :Then(true)
        else
            return Do(rollingShutter:doUncheck())
            :Then(WaitUntil(rollingShutter):Is(value):TimeoutAfter(2000))
            :Then(true)
        end
    end)
    :Catch(function(message)
        dialog.displayErrorMessage(message)
        return false
    end)
    :Label("video.doRollingShutter")
end

-- doRollingShutterAmount(value) -> none
-- Function
-- Sets the Rolling Shutter Amount.
--
-- Parameters:
--  * value - The rolling shutter amount you wish to change the clip(s) too as a string
--            (as it appears in the Inspector in English).
--
-- Returns:
--  * None
local function doRollingShutterAmount(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local method = fcp:inspector():video():rollingShutter():amount()

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
    :Label("video.doRollingShutterAmount")
end

local function getLongBlendModei18n(name)
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.inspector.video",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Stabilization:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("cpStabilizationEnable")
        :whenActivated(doStabilization(true))

    fcpxCmds
        :add("cpStabilizationDisable")
        :whenActivated(doStabilization(false))

    --------------------------------------------------------------------------------
    -- Stabilization Method:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("stabilizationMethodAutomatic")
        :whenActivated(doStabilizationMethod("Automatic"))
        :titled(i18n("stabilizationMethod") .. ": " .. fcp:string("FFStabilizationDynamic"))

    fcpxCmds
        :add("stabilizationMethodInertiaCam")
        :whenActivated(doStabilizationMethod("InertiaCam"))
        :titled(i18n("stabilizationMethod") .. ": " .. fcp:string("FFStabilizationUseInertiaCam"))

    fcpxCmds
        :add("stabilizationMethodSmoothCam")
        :whenActivated(doStabilizationMethod("SmoothCam"))
        :titled(i18n("stabilizationMethod") .. ": " .. fcp:string("FFStabilizationUseSmoothCam"))

    --------------------------------------------------------------------------------
    -- Rolling Shutter:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpRollingShutterEnable")
        :whenActivated(doRollingShutter(true))

    fcpxCmds
        :add("cpRollingShutterDisable")
        :whenActivated(doRollingShutter(false))

    --------------------------------------------------------------------------------
    -- Rolling Shutter Amount:
    --------------------------------------------------------------------------------
    local rollingShutterAmounts = {
        ["FFRollingShutterAmountNone"] = "None",
        ["FFRollingShutterAmountLow"] = "Low",
        ["FFRollingShutterAmountMedium"] = "Medium",
        ["FFRollingShutterAmountHigh"] = "High",
        ["FFRollingShutterAmountExtraHigh"] = "Extra High",
    }

    local rollingShutterTitle = fcp:string("FFRollingShutterEffect")
    local rollingShutterAmount = fcp:string("FFRollingShutterAmount")
    for code, name in pairs(rollingShutterAmounts) do
        fcpxCmds
            :add(name)
            :whenActivated(doRollingShutterAmount(name))
            :titled(rollingShutterTitle .. " " .. rollingShutterAmount .. ": " .. fcp:string(code))
    end

    --------------------------------------------------------------------------------
    -- Spatial Conform:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpSetSpatialConformTypeToFit")
        :whenActivated(doSpatialConformType("Fit"))

    fcpxCmds
        :add("cpSetSpatialConformTypeToFill")
        :whenActivated(doSpatialConformType("Fill"))

    fcpxCmds
        :add("cpSetSpatialConformTypeToNone")
        :whenActivated(doSpatialConformType("None"))

    --------------------------------------------------------------------------------
    -- Blend Modes:
    --------------------------------------------------------------------------------
    local blendModes = fcp:inspector():video().blendModes
    for code, name in pairs(blendModes) do
        fcpxCmds
            :add(name)
            :whenActivated(doBlendMode(fcp:string(code)))
            :titled(i18n("blendMode") .. ": " .. getLongBlendModei18n(name))
    end
end

return plugin
