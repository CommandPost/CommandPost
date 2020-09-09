--- === plugins.finalcutpro.tangent.timeline ===
---
--- Final Cut Pro Tangent Timeline Group/Management

local require = require

--local log                   = require("hs.logger").new("tangentTimeline")

local timer                 = require("hs.timer")

local deferred              = require("cp.deferred")
local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

local delayed               = timer.delayed

local plugin = {
    id = "finalcutpro.tangent.timeline",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"] = "fcpGroup",
        ["finalcutpro.tangent.common"] = "common",

        --------------------------------------------------------------------------------
        -- NOTE: These plugins aren't actually referred here in this plugin, but we
        --       need to include them here so that they load before this plugin loads.
        --------------------------------------------------------------------------------
        ["finalcutpro.timeline.zoomtoselection"] = "zoomtoselection",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local common = deps.common
    local fcpGroup = deps.fcpGroup

    local commandParameter = common.commandParameter
    local shortcutParameter = common.shortcutParameter

    --------------------------------------------------------------------------------
    -- Base ID:
    --------------------------------------------------------------------------------
    local id = 0x00040000

    --------------------------------------------------------------------------------
    -- Create Timeline Group:
    --------------------------------------------------------------------------------
    local timelineGroup = fcpGroup:group(i18n("timeline"))

    --------------------------------------------------------------------------------
    -- Timeline Zoom:
    --------------------------------------------------------------------------------
    local updateZoomUI = deferred.new(0.0000001)

    local appearance = fcp.timeline.toolbar.appearance

    local appearancePopUpCloser = delayed.new(1, function()
        appearance:hide()
    end)

    local zoomChange = 0

    timelineGroup:parameter(id)
        :name(i18n("zoom"))
        :name9(i18n("zoom"))
        :minValue(0)
        :maxValue(10)
        :stepSize(0.2)
        :onGet(function()
            if appearance:isShowing() then
                return appearance:show():zoomAmount()
            end
        end)
        :onChange(function(change)
            appearancePopUpCloser:start()
            if type(zoomChange) ~= "number" then
                zoomChange = 0
            end
            zoomChange = zoomChange + change
            updateZoomUI()
        end)
        :onReset(function()
            appearance:show():zoomAmount(10)
        end)

    updateZoomUI:action(function()
        if zoomChange ~= 0 then
            local currentValue = appearance:show():zoomAmount()
            if currentValue then
                appearance:show():zoomAmount(currentValue + zoomChange)
            end
            zoomChange = 0
        end
    end)

    --------------------------------------------------------------------------------
    -- Timeline Clip Height:
    --------------------------------------------------------------------------------
    id = id + 1
    local clipHeightChange = 0
    local updateClipHeightUI = deferred.new(0.0000001)
    timelineGroup:parameter(id)
        :name(i18n("clipHeight"))
        :name9(i18n("clipHeight"))
        :minValue(35)
        :maxValue(210)
        :stepSize(1)
        :onGet(function()
            if appearance:isShowing() then
                return appearance:clipHeight()
            end
        end)
        :onChange(function(change)
            appearancePopUpCloser:start()
            if type(clipHeightChange) ~= "number" then
                clipHeightChange = 0
            end
            clipHeightChange = clipHeightChange + change
            updateClipHeightUI()
        end)
        :onReset(function()
            appearance:show():clipHeight(35)
        end)

        updateClipHeightUI:action(function()
            if clipHeightChange ~= 0 then
                local currentValue = appearance:show():clipHeight()
                if currentValue then
                    appearance:show():clipHeight(currentValue + clipHeightChange)
                end
                clipHeightChange = 0
            end
        end)

    --------------------------------------------------------------------------------
    -- Timeline Clip Waveform Height Knob:
    --------------------------------------------------------------------------------
    id = id + 1
    local cachedClipWaveformHeight = nil
    local clipWaveformHeight = appearance.clipWaveformHeight
    timelineGroup:menu(id)
        :name(i18n("clipWaveformHeight"))
        :name9(i18n("clipWaveformHeight9"))
        :onGet(function()
            if cachedClipWaveformHeight then
                return i18n("mode") .. " " .. cachedClipWaveformHeight
            else
                local selectedOption = clipWaveformHeight:selectedOption()
                if selectedOption then
                    return i18n("mode") .. " " .. selectedOption
                end
            end
        end)
        :onNext(function()
            clipWaveformHeight:show():nextOption()
            cachedClipWaveformHeight = clipWaveformHeight:selectedOption()
            appearancePopUpCloser:start()
        end)
        :onPrev(function()
            clipWaveformHeight:show():previousOption()
            cachedClipWaveformHeight = clipWaveformHeight:selectedOption()
            appearancePopUpCloser:start()
        end)
        :onReset(function()
            clipWaveformHeight:show():selectedOption(1)
            cachedClipWaveformHeight = 1
            appearancePopUpCloser:start()
        end)

    --------------------------------------------------------------------------------
    -- Timeline Clip Waveform Height Buttons:
    --------------------------------------------------------------------------------
    local clipWaveformHeightGroup = timelineGroup:group(i18n("clipWaveformHeight"))
    for i=1, 6 do
        id = id + 1
        clipWaveformHeightGroup
            :action(id, i18n("mode") .. " " .. i)
            :onPress(function()
                clipWaveformHeight:show():selectedOption(1)
                appearancePopUpCloser:start()
            end)
    end

    --------------------------------------------------------------------------------
    -- Timeline Display Options:
    --------------------------------------------------------------------------------
    local viewOptions = timelineGroup:group(i18n("viewOptions"))

    id = id + 1
    viewOptions
        :action(id, i18n("toggle") .. " " .. i18n("clipNames"))
        :onPress(function()
            appearance.clipNames:show():toggle()
            appearancePopUpCloser:start()
        end)

    id = id + 1
    viewOptions
        :action(id, i18n("toggle") .. " " .. i18n("angles"))
        :onPress(function()
            appearance.angles:show():toggle()
            appearancePopUpCloser:start()
        end)

    id = id + 1
    viewOptions
        :action(id, i18n("toggle") .. " " .. i18n("clipRoles"))
        :onPress(function()
            appearance.clipRoles:show():toggle()
            appearancePopUpCloser:start()
        end)

    id = id + 1
    viewOptions
        :action(id, i18n("toggle") .. " " .. i18n("laneHeaders"))
        :onPress(function()
            appearance.laneHeaders:show():toggle()
            appearancePopUpCloser:start()
        end)

    --------------------------------------------------------------------------------
    -- Increase / Decrease Clip Height:
    --------------------------------------------------------------------------------
    local clipHeightGroup = timelineGroup:group(i18n("clipHeight"))

    id = shortcutParameter(clipHeightGroup, id, "increaseClipHeight", "IncreaseThumbnailSize")
    id = shortcutParameter(clipHeightGroup, id, "decreaseClipHeight", "DecreaseThumbnailSize")

    --------------------------------------------------------------------------------
    -- Zoom to Selection:
    --------------------------------------------------------------------------------
    commandParameter(timelineGroup, id, "fcpx", "cpZoomToSelection")

end

return plugin
