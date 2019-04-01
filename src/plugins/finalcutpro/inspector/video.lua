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
        :whenActivated(doStabilizationMethod(fcp:string("FFStabilizationDynamic")))
        :titled(i18n("stabilizationMethod") .. ": " .. i18n("automatic"))

    fcpxCmds
        :add("stabilizationMethodInertiaCam")
        :whenActivated(doStabilizationMethod(fcp:string("FFStabilizationUseInertiaCam")))
        :titled(i18n("stabilizationMethod") .. ": " .. i18n("inertiaCam"))

    fcpxCmds
        :add("stabilizationMethodSmoothCam")
        :whenActivated(doStabilizationMethod(fcp:string("FFStabilizationUseSmoothCam")))
        :titled(i18n("stabilizationMethod") .. ": " .. i18n("smoothCam"))

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
    local rollingShutterAmounts = fcp:inspector():video().ROLLING_SHUTTER_AMOUNTS
    local rollingShutterTitle = i18n("rollingShutter")
    local rollingShutterAmount = i18n("amount")
    for _, v in pairs(rollingShutterAmounts) do
        fcpxCmds
            :add(v.flexoID)
            :whenActivated(doRollingShutterAmount(fcp:string(v.flexoID)))
            :titled(rollingShutterTitle .. " " .. rollingShutterAmount .. ": " .. i18n(v.i18n))
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
    local blendModes = fcp:inspector():video().BLEND_MODES
    for _, v in pairs(blendModes) do
        if v.flexoID ~= nil then
            fcpxCmds
                :add(v.flexoID)
                :whenActivated(doBlendMode(fcp:string(v.flexoID)))
                :titled(i18n("blendMode") .. ": " .. i18n(v.i18n))
        end
    end
end

return plugin
