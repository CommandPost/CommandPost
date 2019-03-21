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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.tangent.timeline.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro Timeline actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.manager.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup)
    --------------------------------------------------------------------------------
    -- Base ID:
    --------------------------------------------------------------------------------
    local id = 0x00040000

    --------------------------------------------------------------------------------
    -- Create Timeline Group:
    --------------------------------------------------------------------------------
    mod.group = fcpGroup:group(i18n("timeline"))

    --------------------------------------------------------------------------------
    -- Timeline Zoom:
    --------------------------------------------------------------------------------
    mod._updateZoomUI = deferred.new(0.0000001)

    mod._appearancePopUpCloser = delayed.new(1, function()
        local appearance = fcp:timeline():toolbar():appearance()
        if appearance then
            appearance:hide()
        end
    end)

    mod.group:parameter(id)
        :name(i18n("zoom"))
        :name9(i18n("zoom"))
        :minValue(0)
        :maxValue(10)
        :stepSize(0.2)
        :onGet(function()
            local appearance = fcp:timeline():toolbar():appearance()
            if appearance then
                if appearance:isShowing() then
                    return appearance:show():zoomAmount():getValue()
                end
            end
        end)
        :onChange(function(change)
            mod._appearancePopUpCloser:start()
            if type(mod._zoomChange) ~= "number" then
                mod._zoomChange = 0
            end
            mod._zoomChange = mod._zoomChange + change
            mod._updateZoomUI()
        end)
        :onReset(function()
            local appearance = fcp:timeline():toolbar():appearance()
            if appearance then
                appearance:show():zoomAmount():setValue(10)
            end
        end)

    mod._updateZoomUI:action(function()
        if mod._zoomChange ~= 0 then
            local appearance = fcp:timeline():toolbar():appearance()
            if appearance then
                local currentValue = appearance:show():zoomAmount():getValue()
                if currentValue then
                    appearance:show():zoomAmount():setValue(currentValue + mod._zoomChange)
                end
            end
            mod._zoomChange = 0
        end
    end)

    --------------------------------------------------------------------------------
    -- Timeline Clip Height:
    --------------------------------------------------------------------------------
    id = id + 1
    mod._updateClipHeightUI = deferred.new(0.0000001)
    mod.group:parameter(id)
        :name(i18n("clipHeight"))
        :name9(i18n("clipHeight"))
        :minValue(35)
        :maxValue(210)
        :stepSize(1)
        :onGet(function()
            local appearance = fcp:timeline():toolbar():appearance()
            if appearance then
                if appearance:isShowing() then
                    return appearance:show():clipHeight():getValue()
                end
            end
        end)
        :onChange(function(change)
            mod._appearancePopUpCloser:start()
            if type(mod._clipHeightChange) ~= "number" then
                mod._clipHeightChange = 0
            end
            mod._clipHeightChange = mod._clipHeightChange + change
            mod._updateClipHeightUI()
        end)
        :onReset(function()
            local appearance = fcp:timeline():toolbar():appearance()
            if appearance then
                appearance:show():clipHeight():setValue(35)
            end
        end)

        mod._updateClipHeightUI:action(function()
            if mod._clipHeightChange ~= 0 then
                local appearance = fcp:timeline():toolbar():appearance()
                if appearance then
                    local currentValue = appearance:show():clipHeight():getValue()
                    if currentValue then
                        appearance:show():clipHeight():setValue(currentValue + mod._clipHeightChange)
                    end
                end
                mod._clipHeightChange = 0
            end
        end)

    --------------------------------------------------------------------------------
    -- Timeline Clip Waveform Height Knob:
    --------------------------------------------------------------------------------
    id = id + 1
    mod._cachedClipWaveformHeight = nil
    mod.group:menu(id)
        :name(i18n("clipWaveformHeight"))
        :name9(i18n("clipWaveformHeight9"))
        :onGet(function()
            if mod._cachedClipWaveformHeight then
                return i18n("mode") .. " " .. mod._cachedClipWaveformHeight
            else
                local selectedOption = fcp:timeline():toolbar():appearance():clipWaveformHeight():selectedOption()
                if selectedOption then
                    return i18n("mode") .. " " .. selectedOption
                end
            end
        end)
        :onNext(function()
            fcp:timeline():toolbar():appearance():show():clipWaveformHeight():nextOption()
            mod._cachedClipWaveformHeight = fcp:timeline():toolbar():appearance():clipWaveformHeight():selectedOption()
            mod._appearancePopUpCloser:start()
        end)
        :onPrev(function()
            fcp:timeline():toolbar():appearance():show():clipWaveformHeight():previousOption()
            mod._cachedClipWaveformHeight = fcp:timeline():toolbar():appearance():clipWaveformHeight():selectedOption()
            mod._appearancePopUpCloser:start()
        end)
        :onReset(function()
            fcp:timeline():toolbar():appearance():show():clipWaveformHeight():selectedOption(1)
            mod._cachedClipWaveformHeight = 1
            mod._appearancePopUpCloser:start()
        end)

    --------------------------------------------------------------------------------
    -- Timeline Clip Waveform Height Buttons:
    --------------------------------------------------------------------------------
    mod.clipWaveformHeightGroup = mod.group:group(i18n("clipWaveformHeight"))
    for i=1, 6 do
        id = id + 1
        mod.clipWaveformHeightGroup
            :action(id, i18n("mode") .. " " .. i)
            :onPress(function()
                fcp:timeline():toolbar():appearance():show():clipWaveformHeight():selectedOption(1)
                mod._appearancePopUpCloser:start()
            end)
    end

    --------------------------------------------------------------------------------
    -- Timeline Display Options:
    --------------------------------------------------------------------------------
    mod.viewOptions = mod.group:group(i18n("viewOptions"))

    id = id + 1
    mod.viewOptions
        :action(id, i18n("toggle") .. " " .. i18n("clipNames"))
        :onPress(function()
            fcp:timeline():toolbar():appearance():show():clipNames():toggle()
            mod._appearancePopUpCloser:start()
        end)

    id = id + 1
    mod.viewOptions
        :action(id, i18n("toggle") .. " " .. i18n("angles"))
        :onPress(function()
            fcp:timeline():toolbar():appearance():show():angles():toggle()
            mod._appearancePopUpCloser:start()
        end)

    id = id + 1
    mod.viewOptions
        :action(id, i18n("toggle") .. " " .. i18n("clipRoles"))
        :onPress(function()
            fcp:timeline():toolbar():appearance():show():clipRoles():toggle()
            mod._appearancePopUpCloser:start()
        end)

    id = id + 1
    mod.viewOptions
        :action(id, i18n("toggle") .. " " .. i18n("laneHeaders"))
        :onPress(function()
            fcp:timeline():toolbar():appearance():show():laneHeaders():toggle()
            mod._appearancePopUpCloser:start()
        end)

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.timeline",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.fcpGroup)

    return mod
end

return plugin
