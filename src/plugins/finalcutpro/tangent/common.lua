--- === plugins.finalcutpro.tangent.common ===
---
--- Common Final Cut Pro functions for Tangent

local require = require

local log                   = require("hs.logger").new("tangentVideo")

local geometry              = require("hs.geometry")
local timer                 = require("hs.timer")

local axutils               = require("cp.ui.axutils")
local commands              = require("cp.commands")
local deferred              = require("cp.deferred")
local dialog                = require("cp.dialog")
local Do                    = require("cp.rx.go.Do")
local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")
local If                    = require('cp.rx.go.If')
local tools                 = require("cp.tools")

local childrenMatching      = axutils.childrenMatching
local delayed               = timer.delayed
local displayMessage        = dialog.displayMessage
local ninjaMouseClick       = tools.ninjaMouseClick
local playErrorSound        = tools.playErrorSound
local tableCount            = tools.tableCount


local mod = {}

-- DEFER -> number
-- Constant
-- The amount of time to defer UI updates
local DEFER = 0.01

-- DELAY -> number
-- Constant
-- The amount of time to delay UI updates
local DELAY = 0.2

--- plugins.finalcutpro.tangent.common.popupParameter(group, param, id, value, label) -> number
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

--- plugins.finalcutpro.tangent.common.dynamicPopupSliderParameter(group, param, id, label, defaultValue) -> number
--- Function
--- Sets up a new Popup Slider parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
---  * param - The Parameter
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---  * defaultValue - The default value to use when the reset button is pressed.
---
--- Returns:
---  * An updated ID
function mod.dynamicPopupSliderParameter(group, param, id, label, defaultValue)

    local getSelectedIndex = function(menuUI)
        if menuUI then
            local children = menuUI:attributeValue("AXChildren")
            for i, v in pairs(children) do
                if v:attributeValue("AXMenuItemMarkChar") ~= nil then
                    return i
                end
            end
        end
    end

    local popupSliderCache = nil

    local updateUI = delayed.new(DELAY, function()
        Do(param:doSelectItem(popupSliderCache))
            :Then(function()
                popupSliderCache = nil
            end)
            :Label("plugins.finalcutpro.tangent.common.dynamicPopupSliderParameter.updateUI")
            :Now()
    end)

    group:menu(id + 1)
        :name(i18n(label, {default=label}))
        :name9(i18n(label .. "9", {default=i18n(label, {default=label})}))
        :onGet(function()
            if popupSliderCache and param:menuUI() then
                return param:menuUI():attributeValue("AXChildren")[popupSliderCache]:attributeValue("AXTitle")
            else
                return param:value()
            end
        end)
        :onNext(function()
            param:show()
            if not param:menuUI() then
                param:press()
            end
            if param:menuUI() then
                local max = param:menuUI():attributeValueCount("AXChildren")
                local currentValueID = popupSliderCache or getSelectedIndex(param:menuUI())
                currentValueID = currentValueID + 1
                if currentValueID > max then currentValueID = 1 end
                popupSliderCache = currentValueID
                updateUI:start()
            end
        end)
        :onPrev(function()
            param:show()
            if not param:menuUI() then
                param:press()
            end
            if param:menuUI() then
                local max = param:menuUI():attributeValueCount("AXChildren")
                local currentValueID = popupSliderCache or getSelectedIndex(param:menuUI())
                currentValueID = currentValueID - 1
                if currentValueID <= 0 then currentValueID = max end
                popupSliderCache = currentValueID
                updateUI:start()
            end
        end)
        :onReset(
            Do(function()
                popupSliderCache = type(defaultValue) == "number" and defaultValue or 1
            end)
                :Then(
                    If(function()
                        return type(defaultValue) == "string"
                    end)
                    :Then(param:doSelectValue(defaultValue))
                    :Otherwise(param:doSelectItem(defaultValue))
                )
            :Then(function()
                popupSliderCache = nil
            end)
            :Label("plugins.finalcutpro.tangent.common.dynamicPopupSliderParameter.reset")
        )
    return id + 1

end

--- plugins.finalcutpro.tangent.common.popupSliderParameter(group, param, id, label, options, resetIndex) -> number
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

    local updateUI = delayed.new(DELAY, function()
        Do(param:doSelectItem(popupSliderCache))
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
            param:show() -- NOTE: I tried using a `doShow()` here, but it was causing a timing issue.
            local currentValue = param:value()
            local currentValueID = popupSliderCache or (currentValue and loopupID(currentValue))
            if type(currentValueID) ~= "number" then
                return
            end
            local newID = currentValueID and currentValueID + 1
            if newID > maxValue then newID = 1 end

            --------------------------------------------------------------------------------
            -- TODO: This is a horrible temporary workaround for menu non-enabled items.
            -- It should probably be some kind of loop.
            --------------------------------------------------------------------------------
            if options[newID] and options[newID].flexoID == nil then
                newID = newID + 1
            end
            if options[newID] and options[newID].flexoID == nil then
                newID = newID + 1
            end
            if newID > maxValue then newID = 1 end
            --------------------------------------------------------------------------------

            popupSliderCache = newID
            updateUI:start()
        end)
        :onPrev(function()
            param:show() -- NOTE: I tried using a `doShow()` here, but it was causing a timing issue.
            local currentValue = param:value()
            local currentValueID = popupSliderCache or (currentValue and loopupID(currentValue))
            if type(currentValueID) ~= "number" then
                return
            end
            local newID = currentValueID and currentValueID - 1
            if newID == 0 then newID = maxValue - 1 end

            --------------------------------------------------------------------------------
            -- TODO: This is a horrible temporary workaround for menu non-enabled items.
            -- It should probably be some kind of loop.
            --------------------------------------------------------------------------------
            if options[newID] and options[newID].flexoID == nil then
                newID = newID - 1
            end
            if options[newID] and options[newID].flexoID == nil then
                newID = newID - 1
            end
            if newID <= 0 then newID = maxValue - 1 end
            --------------------------------------------------------------------------------

            popupSliderCache = newID
            updateUI:start()
        end)
        :onReset(
            Do(function()
                popupSliderCache = resetIndex
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

--- plugins.finalcutpro.tangent.common.popupParameters(group, param, id, options) -> number
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

--- plugins.finalcutpro.tangent.common.checkboxParameter(group, param, id, label) -> number
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
                If(param):Is(nil):Then():Otherwise(
                    param:doPress()
                )
            ):Label("plugins.finalcutpro.tangent.common.checkboxParameter")
        )
    return id + 1
end

--- plugins.finalcutpro.tangent.common.checkboxSliderParameter(group, id, label, options, resetIndex) -> number
--- Function
--- Sets up a new Popup Slider parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
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
function mod.checkboxSliderParameter(group, id, label, options, resetIndex)

    local getIndexOfSelectedCheckbox = function()
        for i, v in pairs(options) do
            local ui = v.param and v.param:UI()
            if ui and ui:attributeValue("AXValue") == 1 then
                return i
            end
        end
    end

    local cachedValue = nil

    local maxValue = tableCount(options)

    local updateUI = delayed.new(DELAY, function()
        Do(options[1].param:doShow())
            :Then(
                options[cachedValue].param:doPress()
            )
            :Then(function()
                cachedValue = nil
            end)
            :Label("plugins.finalcutpro.tangent.common.checkboxSliderParameter.updateUI")
            :Now()
    end)

    group:menu(id + 1)
        :name(i18n(label, {default=label}))
        :name9(i18n(label .. "9", {default=i18n(label, {default=label})}))
        :onGet(function()
            local index = cachedValue or getIndexOfSelectedCheckbox()
            local result = index and options[index].i18n
            return result and i18n(result .. "9", {default=i18n(result, {default=result})})
        end)
        :onNext(function()
            options[1].param:show()
            local indexOfSelectedCheckbox = getIndexOfSelectedCheckbox()
            if indexOfSelectedCheckbox then
                local currentValueID = cachedValue or getIndexOfSelectedCheckbox()
                local newID = currentValueID and currentValueID + 1
                if newID > maxValue then newID = 1 end
                cachedValue = newID
                updateUI:start()
            end
        end)
        :onPrev(function()
            options[1].param:show()
            local indexOfSelectedCheckbox = getIndexOfSelectedCheckbox()
            if indexOfSelectedCheckbox then
                local currentValueID = cachedValue or getIndexOfSelectedCheckbox()
                local newID = currentValueID and currentValueID - 1
                if newID == 0 then newID = maxValue - 1 end
                cachedValue = newID
                updateUI:start()
            end
        end)
        :onReset(
            Do(function()
                cachedValue = 1
            end)
                :Then(options[1].param:doShow())
                :Then(options[resetIndex].param:doPress())
                :Then(function()
                    cachedValue = nil
                end)
                :Label("plugins.finalcutpro.tangent.common.checkboxSliderParameter.reset")
        )
    return id + 1

end

--- plugins.finalcutpro.tangent.common.doShortcut(id) -> none
--- Function
--- Triggers a shortcut via Rx.
---
--- Parameters:
---  * id - The ID of the shortcut.
---
--- Returns:
---  * None
function mod.doShortcut(id)
    return fcp:doShortcut(id):Catch(function(message)
        log.wf("Unable to perform %q shortcut: %s", id, message)
        displayMessage(i18n("tangentFinalCutProShortcutFailed"))
    end)
end

--- plugins.finalcutpro.tangent.common.radioButtonParameter(group, param, id, label) -> number
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
function mod.radioButtonParameter(group, param, id, label)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(
            Do(param:doShow())
                :Then(param:doPress())
                :Label("plugins.finalcutpro.tangent.common.radioButtonParameter")
        )
    return id + 1
end

--- plugins.finalcutpro.tangent.common.buttonParameter(group, param, id, label) -> number
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

--- plugins.finalcutpro.tangent.common.doShowParameter(group, param, id, label) -> number
--- Function
--- Sets up a new `DoShow` Parameter for the Tangent
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
function mod.doShowParameter(group, param, id, label)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(
            Do(param:doShow())
            :Label("plugins.finalcutpro.tangent.common.buttonParameter")
        )
    return id + 1
end

--- plugins.finalcutpro.tangent.common.commandParameter(group, id, commandID) -> number
--- Function
--- Sets up a new Command Parameter for the Tangent
---
--- Parameters:
---  * group - The Tangent Group.
---  * id - The Tangent ID.
---  * commandID - The command ID.
---
--- Returns:
---  * An updated ID
function mod.commandParameter(group, id, groupID, commandID)
    local cmd = commands.group(groupID):get(commandID)
    group
        :action(id + 1, cmd:getTitle())
        :onPress(function()
            cmd:pressed()
        end)
    return id + 1
end

--- plugins.finalcutpro.tangent.common.shortcutParameter(group, id, label, shortcutID) -> number
--- Function
--- Sets up a new Final Cut Pro Shortcut Parameter for the Tangent.
---
--- Parameters:
---  * group - The Tangent Group.
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---  * shortcutID - The shortcut ID.
---
--- Returns:
---  * An updated ID
function mod.shortcutParameter(group, id, label, shortcut)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(fcp:doShortcut(shortcut))
    return id + 1
end

--- plugins.finalcutpro.tangent.common.menuParameter(group, id, label, path) -> number
--- Function
--- Sets up a new Final Cut Pro Menu Parameter for the Tangent.
---
--- Parameters:
---  * group - The Tangent Group.
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---  * path - The list of menu items you'd like to activate as a table.
---
--- Returns:
---  * An updated ID
function mod.menuParameter(group, id, label, path)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(fcp:doSelectMenu(path))
    return id + 1
end

--- plugins.finalcutpro.tangent.common.functionParameter(group, id, label, fn) -> number
--- Function
--- Sets up a new Function Parameter for the Tangent.
---
--- Parameters:
---  * group - The Tangent Group.
---  * id - The Tangent ID.
---  * label - The label to be used by the Tangent. This can either be an i18n ID or
---            a plain string.
---  * path - The list of menu items you'd like to activate as a table.
---
--- Returns:
---  * An updated ID
function mod.functionParameter(group, id, label, fn)
    group
        :action(id + 1, i18n(label, {default=label}))
        :onPress(fn)
    return id + 1
end

--- plugins.finalcutpro.tangent.common.buttonParameter(group, param, id, label) -> number
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

--- plugins.finalcutpro.tangent.common.checkboxParameterByIndex(group, section, nextSection, id, label, index) -> number
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

--- plugins.finalcutpro.tangent.common.xyParameter(group, param, id, minValue, maxValue, stepSize) -> number
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
                mod._manager.controls:findByID(id + 1):update() -- Force the Tangent display to update.
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

--- plugins.finalcutpro.tangent.common.sliderParameter(group, param, id, minValue, maxValue, stepSize, default, label, optionalParamA, optionalParamB) -> number, parameter
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
---  * label - An optional label as an i18n ID or plain string. If no label is supplied the
---            `param` label will be used.
---  * optionalParamA - An optional parameter. Useful if you need to link parameters.
---  * optionalParamB - An optional parameter. Useful if you need to link parameters.
---
--- Returns:
---  * An updated ID
---  * The parameters value
function mod.sliderParameter(group, param, id, minValue, maxValue, stepSize, default, label, optionalParamA, optionalParamB)
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
                    if optionalParamA then
                        optionalParamA:value(currentValue + value)
                    end
                    if optionalParamB then
                        optionalParamB:value(currentValue + value)
                    end
                    value = 0
                end
                mod._manager.controls:findByID(id + 1):update() -- Force the Tangent display to update.
                updating = false
            end)
        ):Label("plugins.finalcutpro.tangent.common.sliderParameter.updateUI")
    )

    default = default or 0
    label = (label and i18n(label, {default=label})) or param:label()

    local valueParam = group:parameter(id + 1)
        :name(label)
        :minValue(minValue)
        :maxValue(maxValue)
        :stepSize(stepSize)
        :onGet(function()
            local currentValue = param:value()
            return currentValue and currentValue + value
        end)
        :onChange(function(amount)
            value = value + amount
            updateUI()
        end)
        :onReset(function() param:value(default) end)

    return id + 1, valueParam
end

--- plugins.finalcutpro.tangent.common.volumeSliderParameter(group, param, id, minValue, maxValue, stepSize, default, label) -> number, parameter
--- Function
--- Sets up a new Volume Slider Parameter
---
--- Parameters:
---  * group - The Tangent Group
---  * param - The Parameter
---  * id - The Tangent ID
---  * minValue - The minimum value
---  * maxValue - The maximum value
---  * stepSize - The step size
---  * default - The default value
---  * label - An optional label as an i18n ID or plain string. If no label is supplied the
---            `param` label will be used.
---
--- Returns:
---  * An updated ID
---  * The parameters value
function mod.volumeSliderParameter(group, param, id, minValue, maxValue, stepSize, default, label)
    --------------------------------------------------------------------------------
    -- Set up deferred update:
    --------------------------------------------------------------------------------
    local value = 0
    local updateUI = deferred.new(DEFER)
    local updating = false
    local wasPlaying = false
    updateUI:action(
        If(function() return not updating and value ~= 0 end)
        :Then(
            Do(param:doShow())
            :Then(function()
                updating = true
                end)
            :Then(
                If(function()
                    wasPlaying = fcp:timeline():isPlaying()
                    return wasPlaying
                end)
                :Then(fcp:doSelectMenu({"View", "Playback", "Play"}))
                :Then(fcp:doSelectMenu({"Modify", "Add Keyframe to Selected Effect in Animation Editor"}))
            )
            :Then(function()
                local currentValue = param:value()
                if currentValue then
                    param:value(currentValue + value)
                    value = 0
                end
            end)
            :Then(
                If(function()
                    return wasPlaying
                end)
                :Then(fcp:doSelectMenu({"View", "Playback", "Play"}))
            )
            :Then(function()
                updating = false
                end)
        ):Label("plugins.finalcutpro.tangent.common.volumeSliderParameter.updateUI")
    )

    default = default or 0
    label = (label and i18n(label, {default=label})) or param:label()

    local valueParam = group:parameter(id + 1)
        :name(label)
        :minValue(minValue)
        :maxValue(maxValue)
        :stepSize(stepSize)
        :onGet(function()
            local currentValue = param:value()
            return currentValue and currentValue + value
        end)
        :onChange(function(amount)
            value = value + amount
            updateUI()
        end)
        :onReset(function() param:value(default) end)

    return id + 1, valueParam
end


local plugin = {
    id = "finalcutpro.tangent.common",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"] = "manager",
    },
}

function plugin.init(deps)
    mod._manager = deps.manager
    return mod
end

return plugin
