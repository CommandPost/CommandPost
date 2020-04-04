--- === plugins.finalcutpro.inspector.video ===
---
--- Final Cut Pro Video Inspector Additions.

local require = require

--local log                   = require "hs.logger".new "videoInspector"

local deferred              = require "cp.deferred"
local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local go                    = require "cp.rx.go"
local i18n                  = require "cp.i18n"

local If                    = go.If
local Do                    = go.Do
local WaitUntil             = go.WaitUntil

local displayErrorMessage   = dialog.displayErrorMessage
local displayMessage        = dialog.displayMessage

-- doSpatialConformType(value) -> none
-- Function
-- Sets the Spatial Conform Type.
--
-- Parameters:
--  * value - The conform type you wish to change the clip(s) to as a Final Cut Pro string ID.
--
-- Returns:
--  * None
local function doSpatialConformType(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local libraries = fcp:browser():libraries()
    local spatialConformType = fcp:inspector():video():spatialConform():type()

    return Do(function()
        if timeline:isFocused() then
            --------------------------------------------------------------------------------
            -- Make sure at least one clip is selected in the timeline:
            --------------------------------------------------------------------------------
            local clips = timelineContents:selectedClipsUI()
            if clips and #clips == 0 then
                displayMessage(i18n("noSelectedClipsInTimeline"))
                return false
            end
        else
            --------------------------------------------------------------------------------
            -- Make sure at least one clip is selected in the browser:
            --------------------------------------------------------------------------------
            local clips = libraries:selectedClipsUI()
            if clips and #clips == 0 then
                displayMessage(i18n("noSelectedClipsInBrowser"))
                return false
            end
        end

        return Do(spatialConformType:doSelectValue(fcp:string(value)))
            :Then(WaitUntil(spatialConformType):Is(fcp:string(value)):TimeoutAfter(5000))
            :Then(true)
    end)
    :Catch(function(message)
        displayErrorMessage(message)
        return false
    end)
    :Label("video.doSpatialConformType")
end

-- doBlendMode(value) -> none
-- Function
-- Changes the Blend Mode.
--
-- Parameters:
--  * value - The blend mode you wish to change the clip(s) to as a Final Cut Pro string ID.
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
            displayMessage(i18n("noSelectedClipsInTimeline"))
            return false
        end

        return Do(blendMode:doSelectValue(fcp:string(value)))
        :Then(WaitUntil(blendMode):Is(fcp:string(value)):TimeoutAfter(2000))
        :Then(true)
    end)
    :Catch(function(message)
        displayErrorMessage(message)
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
            displayMessage(i18n("noSelectedClipsInTimeline"))
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
        displayErrorMessage(message)
        return false
    end)
    :Label("video.doStabilization")
end

-- doStabilizationMethod(value) -> none
-- Function
-- Enables or disables Stabilisation.
--
-- Parameters:
--  * value - Thestabilisation mode you wish to change the clip(s) to as a Final Cut Pro string ID.
--
-- Returns:
--  * None
local function doStabilizationMethod(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local stabilization = fcp:inspector():video():stabilization()
    local method = fcp:inspector():video():stabilization():method()

    return If(function()
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        local clips = timelineContents:selectedClipsUI()
        if clips and #clips == 0 then
            displayMessage(i18n("noSelectedClipsInTimeline"))
            return false
        else
            return true
        end
    end):Is(true):Then(
        If(stabilization:doShow())
        :Then(
            If(stabilization.isShowing)
            :Then(
                If(stabilization.enabled.checked):Is(false)
                :Then(stabilization.enabled:doCheck())
                :Then(WaitUntil(stabilization.enabled):Is(true):TimeoutAfter(2000))
            )
            :Then(
                If(method.isEnabled) -- Only try and "tick" it if it's enabled. The stabilisation might still be processing.
                :Then(method:doSelectValue(fcp:string(value)))
                :Then(WaitUntil(method):Is(fcp:string(value)):TimeoutAfter(2000))
            )
            :Then(true)
            :Otherwise(function()
                displayMessage(i18n("noSelectedClipsInTimeline"))
                return false
            end)
        )
        :Otherwise(function()
            displayMessage(i18n("noSelectedClipsInTimeline"))
            return false
        end)
    )
    :Catch(function(message)
        displayErrorMessage(message)
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
            displayMessage(i18n("noSelectedClipsInTimeline"))
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
        displayErrorMessage(message)
        return false
    end)
    :Label("video.doRollingShutter")
end

-- doRollingShutterAmount(value) -> none
-- Function
-- Sets the Rolling Shutter Amount.
--
-- Parameters:
--  * value - The rolling shutter amount you wish to change the clip(s) to as a Final Cut Pro string ID.
--
-- Returns:
--  * None
local function doRollingShutterAmount(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local rollingShutter = fcp:inspector():video():rollingShutter()
    local amount = rollingShutter:amount()

    return If(function()
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        local clips = timelineContents:selectedClipsUI()
        if clips and #clips == 0 then
            displayMessage(i18n("noSelectedClipsInTimeline"))
            return false
        else
            return true
        end
    end):Is(true):Then(
        If(rollingShutter:doShow())
        :Then(
            If(rollingShutter.isShowing)
            :Then(
                If(rollingShutter.enabled.checked):Is(false)
                :Then(rollingShutter.enabled:doCheck())
                :Then(WaitUntil(rollingShutter.enabled):Is(true):TimeoutAfter(2000))
            )
            :Then(
                If(amount.isEnabled) -- Only try and "tick" it if it's enabled. It might still be processing.
                :Then(amount:doSelectValue(fcp:string(value)))
                :Then(WaitUntil(amount):Is(fcp:string(value)):TimeoutAfter(2000))
            )
            :Then(true)
            :Otherwise(function()
                displayMessage(i18n("noSelectedClipsInTimeline"))
                return false
            end)
        )
        :Otherwise(function()
            displayMessage(i18n("noSelectedClipsInTimeline"))
            return false
        end)
    )
    :Catch(function(message)
        displayErrorMessage(message)
        return false
    end)
    :Label("video.doRollingShutterAmount")
end

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
        :whenActivated(function() doStabilization(true):Now() end)

    fcpxCmds
        :add("cpStabilizationDisable")
        :whenActivated(function() doStabilization(false):Now() end)

    --------------------------------------------------------------------------------
    -- Stabilization Method:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("stabilizationMethodAutomatic")
        :whenActivated(function() doStabilizationMethod("FFStabilizationDynamic"):Now() end)
        :titled(i18n("stabilizationMethod") .. ": " .. i18n("automatic"))

    fcpxCmds
        :add("stabilizationMethodInertiaCam")
        :whenActivated(function() doStabilizationMethod("FFStabilizationUseInertiaCam"):Now() end)
        :titled(i18n("stabilizationMethod") .. ": " .. i18n("inertiaCam"))

    fcpxCmds
        :add("stabilizationMethodSmoothCam")
        :whenActivated(function() doStabilizationMethod("FFStabilizationUseSmoothCam"):Now() end)
        :titled(i18n("stabilizationMethod") .. ": " .. i18n("smoothCam"))

    --------------------------------------------------------------------------------
    -- Rolling Shutter:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpRollingShutterEnable")
        :whenActivated(function() doRollingShutter(true):Now() end)

    fcpxCmds
        :add("cpRollingShutterDisable")
        :whenActivated(function() doRollingShutter(false):Now() end)

    --------------------------------------------------------------------------------
    -- Rolling Shutter Amount:
    --------------------------------------------------------------------------------
    local rollingShutterAmounts = fcp:inspector():video().ROLLING_SHUTTER_AMOUNTS
    local rollingShutterTitle = i18n("rollingShutter")
    local rollingShutterAmount = i18n("amount")
    for _, v in pairs(rollingShutterAmounts) do
        fcpxCmds
            :add(v.flexoID)
            :whenActivated(function() doRollingShutterAmount(v.flexoID):Now() end)
            :titled(rollingShutterTitle .. " " .. rollingShutterAmount .. ": " .. i18n(v.i18n))
    end

    --------------------------------------------------------------------------------
    -- Spatial Conform:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpSetSpatialConformTypeToFit")
        :whenActivated(function() doSpatialConformType("FFConformTypeFit"):Now() end)

    fcpxCmds
        :add("cpSetSpatialConformTypeToFill")
        :whenActivated(function() doSpatialConformType("FFConformTypeFill"):Now() end)

    fcpxCmds
        :add("cpSetSpatialConformTypeToNone")
        :whenActivated(function() doSpatialConformType("FFConformTypeNone"):Now() end)

    --------------------------------------------------------------------------------
    -- Blend Modes:
    --------------------------------------------------------------------------------
    local blendModes = fcp:inspector():video().BLEND_MODES
    for _, v in pairs(blendModes) do
        if v.flexoID ~= nil then
            fcpxCmds
                :add(v.flexoID)
                :whenActivated(function() doBlendMode(v.flexoID):Now() end)
                :titled(i18n("blendMode") .. ": " .. i18n(v.i18n))
        end
    end

    --------------------------------------------------------------------------------
    -- Position:
    --------------------------------------------------------------------------------
    local shiftAmounts = {0.1, 1, 5, 10, 15, 20, 25, 30, 35, 40}

    local shiftXPositionValue = 0
    local updateShiftXPositionValue = deferred.new(0.01):action(function()
        local position = fcp:inspector():video():transform():position()
        position:show()
        local originalPosition = position:x()
        position:x(originalPosition + shiftXPositionValue)
        shiftXPositionValue = 0
    end)
    local shiftXPosition = function(value)
        shiftXPositionValue = shiftXPositionValue + value
        updateShiftXPositionValue()
    end

    local shiftYPositionValue = 0
    local updateShiftYPositionValue = deferred.new(0.01):action(function()
        local position = fcp:inspector():video():transform():position()
        position:show()
        local originalPosition = position:y()
        position:y(originalPosition + shiftYPositionValue)
        shiftYPositionValue = 0
    end)
    local shiftYPosition = function(value)
        shiftYPositionValue = shiftYPositionValue + value
        updateShiftYPositionValue()
    end

    for _, shiftAmount in pairs(shiftAmounts) do
        fcpxCmds:add("shiftPositionLeftPixels" .. shiftAmount  .. "Pixels")
            :titled(i18n("shiftPositionLeftPixels", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftXPosition(shiftAmount * -1) end)
            :whenRepeated(function() shiftXPosition(shiftAmount * -1) end)

        fcpxCmds:add("shiftPositionRightPixels" .. shiftAmount .. "Pixels")
            :titled(i18n("shiftPositionRightPixels", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftXPosition(shiftAmount) end)
            :whenRepeated(function() shiftXPosition(shiftAmount) end)

        fcpxCmds:add("shiftPositionUp" .. shiftAmount .. "Pixels")
            :titled(i18n("shiftPositionUpPixels", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftYPosition(shiftAmount) end)
            :whenRepeated(function() shiftYPosition(shiftAmount) end)

        fcpxCmds:add("shiftPositionDown" .. shiftAmount .. "Pixels")
            :titled(i18n("shiftPositionDownPixels", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftYPosition(shiftAmount * -1) end)
            :whenRepeated(function() shiftYPosition(shiftAmount * -1) end)
   end

    fcpxCmds:add("resetPositionX")
        :titled(i18n("reset") .. " " .. i18n("position") .. " X")
        :groupedBy("timeline")
        :whenPressed(function()
            local position = fcp:inspector():video():transform():position()
            position:show()
            position:x(0)
        end)

    fcpxCmds:add("resetPositionY")
        :titled(i18n("reset") .. " " .. i18n("position") .. " Y")
        :groupedBy("timeline")
        :whenPressed(function()
            local position = fcp:inspector():video():transform():position()
            position:show()
            position:y(0)
        end)

    --------------------------------------------------------------------------------
    -- Scale All:
    --------------------------------------------------------------------------------
    local shiftScaleValue = 0
    local updateShiftScale = deferred.new(0.01):action(function()
        local scaleAll = fcp:inspector():video():transform():scaleAll()
        scaleAll:show()
        local original = scaleAll:value()
        scaleAll:value(original + shiftScaleValue)
        shiftScaleValue = 0
    end)
    local shiftScale = function(value)
        shiftScaleValue = shiftScaleValue + value
        updateShiftScale()
    end
    for _, shiftAmount in pairs(shiftAmounts) do
        fcpxCmds:add("shiftScaleUp" .. shiftAmount)
            :titled(i18n("shiftScaleUp", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftScale(shiftAmount) end)
            :whenRepeated(function() shiftScale(shiftAmount) end)

        fcpxCmds:add("shiftScaleDown" .. shiftAmount)
            :titled(i18n("shiftScaleDown", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftScale(shiftAmount * -1) end)
            :whenRepeated(function() shiftScale(shiftAmount * -1) end)
    end

    fcpxCmds:add("resetScale")
        :titled(i18n("reset") .. " " .. i18n("scale") .. " " .. i18n("all"))
        :groupedBy("timeline")
        :whenPressed(function()
            local scaleAll = fcp:inspector():video():transform():scaleAll()
            scaleAll:show()
            scaleAll:value(100)
        end)

    --------------------------------------------------------------------------------
    -- Rotation:
    --------------------------------------------------------------------------------
    local shiftRotationValue = 0
    local updateShiftRotation = deferred.new(0.01):action(function()
        local rotation = fcp:inspector():video():transform():rotation()
        rotation:show()
        local original = rotation:value()
        rotation:value(original + shiftRotationValue)
        shiftRotationValue = 0
    end)
    local shiftRotation = function(value)
        shiftRotationValue = shiftRotationValue + value
        updateShiftRotation()
    end
    for _, shiftAmount in pairs(shiftAmounts) do
        fcpxCmds:add("shiftRotationLeft" .. shiftAmount)
            :titled(i18n("shiftRotationLeft", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftRotation(shiftAmount) end)
            :whenRepeated(function() shiftRotation(shiftAmount) end)

        fcpxCmds:add("shiftRotationRight" .. shiftAmount)
            :titled(i18n("shiftRotationRight", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftRotation(shiftAmount * -1) end)
            :whenRepeated(function() shiftRotation(shiftAmount * -1) end)
    end

    fcpxCmds:add("resetRotation")
        :titled(i18n("reset") .. " " .. i18n("rotation"))
        :groupedBy("timeline")
        :whenPressed(function()
            local rotation = fcp:inspector():video():transform():rotation()
            rotation:show()
            rotation:value(0)
        end)

    --------------------------------------------------------------------------------
    -- Opacity:
    --------------------------------------------------------------------------------
    local shiftOpacityValue = 0
    local updateShiftOpacity = deferred.new(0.01):action(function()
        local opacity = fcp:inspector():video():compositing():opacity()
        opacity:show()
        local original = opacity:value()
        opacity:value(original + shiftOpacityValue)
        shiftOpacityValue = 0
    end)
    local shiftOpacity = function(value)
        shiftOpacityValue = shiftOpacityValue + value
        updateShiftOpacity()
    end
    for _, shiftAmount in pairs(shiftAmounts) do
        fcpxCmds:add("shiftOpacityLeft" .. shiftAmount)
            :titled(i18n("decreaseOpacity", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftOpacity(shiftAmount * -1) end)
            :whenRepeated(function() shiftOpacity(shiftAmount * -1) end)

        fcpxCmds:add("shiftOpacityRight" .. shiftAmount)
            :titled(i18n("increaseOpacity", {amount=shiftAmount, count=shiftAmount}))
            :groupedBy("timeline")
            :whenPressed(function() shiftOpacity(shiftAmount) end)
            :whenRepeated(function() shiftOpacity(shiftAmount) end)
    end

    fcpxCmds:add("resetOpacity")
        :titled(i18n("reset") .. " " .. i18n("opacity"))
        :groupedBy("timeline")
        :whenPressed(function()
            local opacity = fcp:inspector():video():compositing():opacity()
            opacity:show()
            opacity:value(100)
        end)

    --------------------------------------------------------------------------------
    -- Crop:
    --------------------------------------------------------------------------------
    local CROP_TYPES = fcp:inspector():video().CROP_TYPES
    for _, c in pairs(CROP_TYPES) do
        fcpxCmds:add("cropType" .. c.i18n)
            :titled(i18n("cropType") .. ": " .. i18n(c.i18n))
            :whenPressed(function()
                local cropType = fcp:inspector():video():crop():type()
                cropType:doShow():Then(
                    cropType:doSelectValue(fcp:string(c.flexoID))
                ):Now()
            end)
    end

    local cropLeftValue = 0
    local updateCropLeft = deferred.new(0.01):action(function()
        local cropLeft = fcp:inspector():video():crop():left()
        cropLeft:show()
        local original = cropLeft:value()
        cropLeft:value(original + cropLeftValue)
        cropLeftValue = 0
    end)

    local cropRightValue = 0
    local updateCropRight = deferred.new(0.01):action(function()
        local cropRight = fcp:inspector():video():crop():right()
        cropRight:show()
        local original = cropRight:value()
        cropRight:value(original + cropRightValue)
        cropRightValue = 0
    end)

    local cropTopValue = 0
    local updateCropTop = deferred.new(0.01):action(function()
        local cropTop = fcp:inspector():video():crop():top()
        cropTop:show()
        local original = cropTop:value()
        cropTop:value(original + cropTopValue)
        cropTopValue = 0
    end)

    local cropBottomValue = 0
    local updateCropBottom = deferred.new(0.01):action(function()
        local cropBottom = fcp:inspector():video():crop():bottom()
        cropBottom:show()
        local original = cropBottom:value()
        cropBottom:value(original + cropBottomValue)
        cropBottomValue = 0
    end)

    local cropAmounts = {0.1, 1, 5, 10, 15, 20, 25, 30, 35, 40}
    for _, c in pairs(cropAmounts) do
        fcpxCmds:add("cropLeftIncrease" .. c)
            :titled(i18n("crop") .. " " .. i18n("left") .. " " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                cropLeftValue = cropLeftValue + c
                updateCropLeft()
            end)

        fcpxCmds:add("cropLeftDecrease" .. c)
            :titled(i18n("crop") .. " " .. i18n("left") .. " " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                cropLeftValue = cropLeftValue - c
                updateCropLeft()
            end)

        fcpxCmds:add("cropRightIncrease" .. c)
            :titled(i18n("crop") .. " " .. i18n("right") .. " " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                cropRightValue = cropRightValue + c
                updateCropRight()
            end)

        fcpxCmds:add("cropRightDecrease" .. c)
            :titled(i18n("crop") .. " " .. i18n("right") .. " " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                cropRightValue = cropRightValue - c
                updateCropRight()
            end)

        fcpxCmds:add("cropTopIncrease" .. c)
            :titled(i18n("crop") .. " " .. i18n("top") .. " " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                cropTopValue = cropTopValue + c
                updateCropTop()
            end)

        fcpxCmds:add("cropTopDecrease" .. c)
            :titled(i18n("crop") .. " " .. i18n("top") .. " " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                cropTopValue = cropTopValue - c
                updateCropTop()
            end)

        fcpxCmds:add("cropBottomIncrease" .. c)
            :titled(i18n("crop") .. " " .. i18n("bottom") .. " " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                cropBottomValue = cropBottomValue + c
                updateCropBottom()
            end)

        fcpxCmds:add("cropBottomDecrease" .. c)
            :titled(i18n("crop") .. " " .. i18n("bottom") .. " " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                cropBottomValue = cropBottomValue - c
                updateCropBottom()
            end)
    end

    fcpxCmds:add("cropResetLeft")
        :titled(i18n("crop") .. " " .. i18n("left") .. " " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():crop():left():show():value(0)
        end)

    fcpxCmds:add("cropResetRight")
        :titled(i18n("crop") .. " " .. i18n("right") .. " " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():crop():right():show():value(0)
        end)

    fcpxCmds:add("cropResetTop")
        :titled(i18n("crop") .. " " .. i18n("top") .. " " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():crop():top():show():value(0)
        end)

    fcpxCmds:add("cropResetBottom")
        :titled(i18n("crop") .. " " .. i18n("bottom") .. " " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():crop():bottom():show():value(0)
        end)

    --------------------------------------------------------------------------------
    -- Distort:
    --------------------------------------------------------------------------------
    local distortBottomLeftXValue = 0
    local updateDistortBottomLeftX = deferred.new(0.01):action(function()
        local d = fcp:inspector():video():distort():bottomLeft().x
        d:show()
        local original = d:value()
        d:value(original + distortBottomLeftXValue)
        distortBottomLeftXValue = 0
    end)

    local distortBottomLeftYValue = 0
    local updateDistortBottomLeftY = deferred.new(0.01):action(function()
        local d = fcp:inspector():video():distort():bottomLeft().x
        d:show()
        local original = d:value()
        d:value(original + distortBottomLeftYValue)
        distortBottomLeftYValue = 0
    end)

    local distortBottomRightXValue = 0
    local updateDistortBottomRightX = deferred.new(0.01):action(function()
        local d = fcp:inspector():video():distort():bottomRight().x
        d:show()
        local original = d:value()
        d:value(original + distortBottomRightXValue)
        distortBottomRightXValue = 0
    end)

    local distortBottomRightYValue = 0
    local updateDistortBottomRightY = deferred.new(0.01):action(function()
        local d = fcp:inspector():video():distort():bottomRight().x
        d:show()
        local original = d:value()
        d:value(original + distortBottomRightYValue)
        distortBottomRightYValue = 0
    end)


    local distortTopLeftXValue = 0
    local updateDistortTopLeftX = deferred.new(0.01):action(function()
        local d = fcp:inspector():video():distort():topLeft().x
        d:show()
        local original = d:value()
        d:value(original + distortTopLeftXValue)
        distortTopLeftXValue = 0
    end)

    local distortTopLeftYValue = 0
    local updateDistortTopLeftY = deferred.new(0.01):action(function()
        local d = fcp:inspector():video():distort():topLeft().x
        d:show()
        local original = d:value()
        d:value(original + distortTopLeftYValue)
        distortTopLeftYValue = 0
    end)

    local distortTopRightXValue = 0
    local updateDistortTopRightX = deferred.new(0.01):action(function()
        local d = fcp:inspector():video():distort():topRight().x
        d:show()
        local original = d:value()
        d:value(original + distortTopRightXValue)
        distortTopRightXValue = 0
    end)

    local distortTopRightYValue = 0
    local updateDistortTopRightY = deferred.new(0.01):action(function()
        local d = fcp:inspector():video():distort():topRight().x
        d:show()
        local original = d:value()
        d:value(original + distortTopRightYValue)
        distortTopRightYValue = 0
    end)

    local distortAmounts = {0.1, 1, 5, 10, 15, 20, 25, 30, 35, 40}
    for _, c in pairs(distortAmounts) do
        --------------------------------------------------------------------------------
        -- Bottom Left:
        --------------------------------------------------------------------------------
        fcpxCmds:add("distortBottomLeftXIncrease" .. c)
            :titled(i18n("distort") .. " ".. i18n("bottom") .. " " .. i18n("left") .. " X " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                distortBottomLeftXValue = distortBottomLeftXValue + c
                updateDistortBottomLeftX()
            end)
        fcpxCmds:add("distortBottomLeftYIncrease" .. c)
            :titled(i18n("distort") .. " " .. i18n("bottom") .. " " .. i18n("left") .. " Y " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                distortBottomLeftYValue = distortBottomLeftYValue + c
                updateDistortBottomLeftY()
            end)
        fcpxCmds:add("distortBottomLeftXDecrease" .. c)
            :titled(i18n("distort") .. " ".. i18n("bottom") .. " " .. i18n("left") .. " X " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                distortBottomLeftXValue = distortBottomLeftXValue - c
                updateDistortBottomLeftX()
            end)
        fcpxCmds:add("distortBottomLeftYDecrease" .. c)
            :titled(i18n("distort") .. " " .. i18n("bottom") .. " " .. i18n("left") .. " Y " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                distortBottomLeftYValue = distortBottomLeftYValue - c
                updateDistortBottomLeftY()
            end)

        --------------------------------------------------------------------------------
        -- Bottom Right:
        --------------------------------------------------------------------------------
        fcpxCmds:add("distortBottomRightXIncrease" .. c)
            :titled(i18n("distort") .. " ".. i18n("bottom") .. " " .. i18n("right") .. " X " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                distortBottomRightXValue = distortBottomRightXValue + c
                updateDistortBottomRightX()
            end)
        fcpxCmds:add("distortBottomRightYIncrease" .. c)
            :titled(i18n("distort") .. " " .. i18n("bottom") .. " " .. i18n("right") .. " Y " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                distortBottomRightYValue = distortBottomRightYValue + c
                updateDistortBottomRightY()
            end)
        fcpxCmds:add("distortBottomRightXDecrease" .. c)
            :titled(i18n("distort") .. " ".. i18n("bottom") .. " " .. i18n("right") .. " X " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                distortBottomRightXValue = distortBottomRightXValue - c
                updateDistortBottomRightX()
            end)
        fcpxCmds:add("distortBottomRightYDecrease" .. c)
            :titled(i18n("distort") .. " " .. i18n("bottom") .. " " .. i18n("right") .. " Y " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                distortBottomRightYValue = distortBottomRightYValue + c
                updateDistortBottomRightY()
            end)

        --------------------------------------------------------------------------------
        -- Top Left:
        --------------------------------------------------------------------------------
        fcpxCmds:add("distortTopLeftXIncrease" .. c)
            :titled(i18n("distort") .. " ".. i18n("top") .. " " .. i18n("left") .. " X " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                distortTopLeftXValue = distortTopLeftXValue + c
                updateDistortTopLeftX()
            end)
        fcpxCmds:add("distortTopLeftYIncrease" .. c)
            :titled(i18n("distort") .. " " .. i18n("top") .. " " .. i18n("left") .. " Y " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                distortTopLeftYValue = distortTopLeftYValue + c
                updateDistortTopLeftY()
            end)
        fcpxCmds:add("distortTopLeftXDecrease" .. c)
            :titled(i18n("distort") .. " ".. i18n("top") .. " " .. i18n("left") .. " X " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                distortTopLeftXValue = distortTopLeftXValue - c
                updateDistortTopLeftX()
            end)
        fcpxCmds:add("distortTopLeftYDecrease" .. c)
            :titled(i18n("distort") .. " " .. i18n("top") .. " " .. i18n("left") .. " Y " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                distortTopLeftYValue = distortTopLeftYValue - c
                updateDistortTopLeftY()
            end)

        --------------------------------------------------------------------------------
        -- Top Right:
        --------------------------------------------------------------------------------
        fcpxCmds:add("distortTopRightXIncrease" .. c)
            :titled(i18n("distort") .. " ".. i18n("top") .. " " .. i18n("right") .. " X " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                distortTopRightXValue = distortTopRightXValue + c
                updateDistortTopRightX()
            end)
        fcpxCmds:add("distortTopRightYIncrease" .. c)
            :titled(i18n("distort") .. " " .. i18n("top") .. " " .. i18n("right") .. " Y " .. i18n("increase") .. " " .. c .. "px")
            :whenPressed(function()
                distortTopRightYValue = distortTopRightYValue + c
                updateDistortTopRightY()
            end)
        fcpxCmds:add("distortTopRightXDecrease" .. c)
            :titled(i18n("distort") .. " ".. i18n("top") .. " " .. i18n("right") .. " X " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                distortTopRightXValue = distortTopRightXValue - c
                updateDistortTopRightX()
            end)
        fcpxCmds:add("distortTopRightYDecrease" .. c)
            :titled(i18n("distort") .. " " .. i18n("top") .. " " .. i18n("right") .. " Y " .. i18n("decrease") .. " " .. c .. "px")
            :whenPressed(function()
                distortTopRightYValue = distortTopRightYValue + c
                updateDistortTopRightY()
            end)
    end

    fcpxCmds:add("distortBottomLeftXReset")
        :titled(i18n("distort") .. " ".. i18n("bottom") .. " " .. i18n("left") .. " X " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():distort():bottomLeft().x:show():value(0)
        end)

    fcpxCmds:add("distortBottomLeftYReset")
        :titled(i18n("distort") .. " ".. i18n("bottom") .. " " .. i18n("left") .. " Y " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():distort():bottomLeft().y:show():value(0)
        end)

    fcpxCmds:add("distortBottomRightXReset")
        :titled(i18n("distort") .. " ".. i18n("bottom") .. " " .. i18n("right") .. " X " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():distort():bottomRight().x:show():value(0)
        end)

    fcpxCmds:add("distortBottomRightYReset")
        :titled(i18n("distort") .. " ".. i18n("bottom") .. " " .. i18n("right") .. " Y " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():distort():bottomRight().y:show():value(0)
        end)

    fcpxCmds:add("distortTopLeftXReset")
        :titled(i18n("distort") .. " ".. i18n("top") .. " " .. i18n("left") .. " X " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():distort():topLeft().x:show():value(0)
        end)

    fcpxCmds:add("distortTopLeftYReset")
        :titled(i18n("distort") .. " ".. i18n("top") .. " " .. i18n("left") .. " Y " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():distort():topLeft().y:show():value(0)
        end)

    fcpxCmds:add("distortTopRightXReset")
        :titled(i18n("distort") .. " ".. i18n("top") .. " " .. i18n("right") .. " X " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():distort():topRight().x:show():value(0)
        end)

    fcpxCmds:add("distortTopRightYReset")
        :titled(i18n("distort") .. " ".. i18n("top") .. " " .. i18n("right") .. " Y " .. i18n("reset"))
        :whenPressed(function()
            fcp:inspector():video():distort():topRight().y:show():value(0)
        end)

    --------------------------------------------------------------------------------
    -- Effects:
    --------------------------------------------------------------------------------
    fcpxCmds:add("toggleSelectedEffect")
        :titled(i18n("toggle") .. " " .. i18n("selected") .. " " .. i18n("effect"))
        :whenPressed(function()
            fcp:inspector():video():show()
            local checkbox = fcp:inspector():video():selectedEffectCheckBox()
            if checkbox then
                checkbox:performAction("AXPress")
            end
        end)

    for i=1, 9 do
        fcpxCmds:add("toggleEffect" .. i)
            :titled(i18n("toggle") .. " " .. i18n("effect") .. " " .. i)
            :whenPressed(function()
                fcp:inspector():video():show()
                local checkboxes = fcp:inspector():video():effectCheckBoxes()
                if checkboxes and checkboxes[i] then
                    checkboxes[i]:performAction("AXPress")
                end
            end)
    end

end

return plugin
