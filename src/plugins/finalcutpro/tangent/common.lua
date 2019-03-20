--- === plugins.finalcutpro.tangent.common ===
---
--- Common Final Cut Pro functions for Tangent

local require = require

local log                   = require("hs.logger").new("tangentVideo")

local geometry              = require("hs.geometry")
local timer                 = require("hs.timer")

local axutils               = require("cp.ui.axutils")
local deferred              = require("cp.deferred")
local Do                    = require("cp.rx.go.Do")
local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")
local If                    = require('cp.rx.go.If')
local tools                 = require("cp.tools")

local childrenMatching      = axutils.childrenMatching
local delayed               = timer.delayed
local ninjaMouseClick       = tools.ninjaMouseClick
local playErrorSound        = tools.playErrorSound
local tableCount            = tools.tableCount

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

--- plugins.finalcutpro.tangent.common.popupParameter() -> none
--- Function
--- Sets up a new Popup Parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
---  * param - The Parameter.
---  * id - The Tangent ID.
---  * value - The value to select as a string.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---
--- Returns:
---  * An updated ID
function mod.popupParameter(group, param, id, value, label)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(
            Do(param:doShow())
                :Then(param:doSelectValue(value))
                :Label("plugins.finalcutpro.tangent.common.popupParameter")
        )
    return id + 1
end

--- plugins.finalcutpro.tangent.common.popupSliderParameter() -> none
--- Function
--- Sets up a new Popup Slider parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
---  * param - The Parameter
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---  * options - A table of options. The key for each option should be a number ID
---              (in the order it appears in the UI), and the value should be another
---              table with keys for `flexoID` and `i18n` values.
---  * resetIndex - An index of which item to use when "reset" is triggered.
---
--- Returns:
---  * An updated ID
function mod.popupSliderParameter(group, param, id, label, options, resetIndex)

    local popupSliderCache = nil

    local maxValue = tableCount(options)

    local loopupID = function(name)
        for i, v in pairs(options) do
            if v.flexoID then
                if name == fcp:string(v.flexoID) then
                    return i
                end
            end
        end
    end

    local updateUI = delayed.new(0.5, function()
        Do(param:doShow())
            :Then(param:doSelectValue(fcp:string(options[popupSliderCache].flexoID)))
            :Then(function()
                popupSliderCache = nil
            end)
            :Label("plugins.finalcutpro.tangent.common.popupSliderParameter.updateUI")
            :Now()
    end)

    group:menu(id + 1)
        :name(i18n(label, {default=label}))
        :name9(i18n(label .. "9", {default=i18n(label, {default=label})}))
        :onGet(function()
            if popupSliderCache then
                if options[popupSliderCache].i18n ~= nil then
                    local v = options[popupSliderCache].i18n
                    return i18n(v .. "9", {default= i18n(v, {default=v})})
                end
            else
                local i = loopupID(param:value())
                local v = options[i] and options[i].i18n
                return v and i18n(v .. "9", {default=i18n(v, {default=v})})
            end
        end)
        :onNext(function()
            param:show()
            local currentValue = param:value()
            local currentValueID = popupSliderCache or (currentValue and loopupID(currentValue))
            local newID = currentValueID and currentValueID + 1
            if newID == maxValue then newID = 1 end

            --------------------------------------------------------------------------------
            -- This is a horrible temporary workaround for menu non-enabled items.
            -- It should probably be some kind of loop.
            --------------------------------------------------------------------------------
            if options[newID].flexoID == nil then
                newID = newID + 1
            end
            if options[newID].flexoID == nil then
                newID = newID + 1
            end
            --------------------------------------------------------------------------------

            popupSliderCache = newID
            updateUI:start()
        end)
        :onPrev(function()
            param:show()
            local currentValue = param:value()
            local currentValueID = popupSliderCache or (currentValue and loopupID(currentValue))
            local newID = currentValueID and currentValueID - 1
            if newID == 0 then newID = maxValue - 1 end

            --------------------------------------------------------------------------------
            -- This is a horrible temporary workaround for menu non-enabled items.
            -- It should probably be some kind of loop.
            --------------------------------------------------------------------------------
            if options[newID].flexoID == nil then
                newID = newID - 1
            end
            if options[newID].flexoID == nil then
                newID = newID - 1
            end
            if newID <= 0 then newID = maxValue - 1 end
            --------------------------------------------------------------------------------

            popupSliderCache = newID
            updateUI:start()
        end)
        :onReset(
            Do(function()
                popupSliderCache = 1
            end)
                :Then(param:doShow())
                :Then(param:doSelectValue(fcp:string(options[resetIndex].flexoID)))
                :Then(function()
                    popupSliderCache = nil
                end)
                :Label("plugins.finalcutpro.tangent.common.popupSliderParameter.reset")
        )
    return id + 1

end

--- plugins.finalcutpro.tangent.common.popupParameters() -> none
--- Function
--- Sets up a new Popup Parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
---  * param - The Parameter
---  * id - The Tangent ID.
---  * options - A table of options. The key for each option should be a number ID
---              (in the order it appears in the UI), and the value should be another
---              table with keys for `flexoID` and `i18n` values.
---
--- Returns:
---  * An updated ID
function mod.popupParameters(group, param, id, options)
    for i=1, tableCount(options) do
        local v = options[i]
        if v.flexoID ~= nil then
            id = mod.popupParameter(group, param, id, fcp:string(v.flexoID), v.i18n)
        end
    end
    return id
end

--- plugins.finalcutpro.tangent.common.checkboxParameter() -> none
--- Function
--- Sets up a new Checkbox Parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
---  * param - The Parameter
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---
--- Returns:
---  * An updated ID
function mod.checkboxParameter(group, param, id, label)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(
            Do(param:doShow()):Then(
                If(param.enabled):Is(nil):Then():Otherwise(
                    param.enabled:doPress()
                )
            ):Label("plugins.finalcutpro.tangent.common.checkboxParameter")
        )
    return id + 1
end

--- plugins.finalcutpro.tangent.common.buttonParameter() -> none
--- Function
--- Sets up a new Button Parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
---  * param - The Parameter
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---
--- Returns:
---  * An updated ID
function mod.buttonParameter(group, param, id, label)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(
            Do(param:doShow()):Then(
                param:doPress()
            ):Label("plugins.finalcutpro.tangent.common.buttonParameter")
        )
    return id + 1
end

--- plugins.finalcutpro.tangent.common.buttonParameter() -> none
--- Function
--- Sets up a new Button Parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
---  * param - The Parameter
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---
--- Returns:
---  * An updated ID
function mod.ninjaButtonParameter(group, param, id, label)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(function()
            param:show()
            local frame = param:frame()
            if frame then
                local center = geometry(frame).center
                if center then
                    ninjaMouseClick(center)
                    return
                end
            end
            playErrorSound()
        end)
    return id + 1
end

--- plugins.finalcutpro.tangent.common.checkboxParameterByIndex() -> none
--- Function
--- Sets up a new AXCheckBox object for the Tangent.
---
--- Parameters:
---  * group - The Tangent Group.
---  * section - The section as it appears in the FCPX Inspector.
---  * nextSection - The next section as it appears in the FCPX Inspector.
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---  * index - The index of the checkbox in the section.
---
--- Returns:
---  * An updated ID
function mod.checkboxParameterByIndex(group, section, nextSection, id, label, index)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(function()
            section:show():expanded(true)
            local children = section:propertiesUI():children()
            local sectionFrame = section and section:UI() and section:UI():frame()
            local nextSectionFrame = nextSection and nextSection:UI() and nextSection:UI():frame()
            local allowedX = section and section.enabled and section.enabled:UI() and section.enabled:UI():frame().x
            if sectionFrame and allowedX then
                local checkboxes = childrenMatching(children, function(e)
                    local frame = e:attributeValue("AXFrame")
                    local result = e:attributeValue("AXRole") == "AXCheckBox"
                        and frame.x == allowedX
                        and frame.y > (sectionFrame.y + sectionFrame.h)
                    if nextSectionFrame then
                        result = result and ((frame.y + frame.h) < nextSectionFrame.y)
                    end
                    return result
                end)
                local checkbox = checkboxes and checkboxes[index]
                if checkbox then
                    checkbox:doPress()
                    return
                end
            end
            playErrorSound()
        end)
    return id + 1
end

--- plugins.finalcutpro.tangent.common.xyParameter() -> none
--- Function
--- Sets up a new XY Parameter
---
--- Parameters:
---  * group - The Tangent Group
---  * param - The Parameter
---  * id - The Tangent ID
---
--- Returns:
---  * An updated ID
---  * The `x` parameter value
---  * The `y` parameter value
---  * The xy binding
function mod.xyParameter(group, param, id, minValue, maxValue, stepSize)
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
        ):Label("plugins.finalcutpro.tangent.common.xyParameter.updateUI")
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

--- plugins.finalcutpro.tangent.common.sliderParameter() -> none
--- Function
--- Sets up a new Slider Parameter
---
--- Parameters:
---  * group - The Tangent Group
---  * param - The Parameter
---  * id - The Tangent ID
---  * minValue - The minimum value
---  * maxValue - The maximum value
---  * stepSize - The step size
---  * default - The default value
---
--- Returns:
---  * An updated ID
---  * The parameters value
function mod.sliderParameter(group, param, id, minValue, maxValue, stepSize, default)
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
        ):Label("plugins.finalcutpro.tangent.common.sliderParameter.updateUI")
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.common",
    group = "finalcutpro",
}

function plugin.init()
    return mod
end

return plugin
