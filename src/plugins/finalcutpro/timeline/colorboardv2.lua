--- === plugins.finalcutpro.timeline.colorboardv2 ===
---
--- Color Board Plugins.

local require = require

--local log                   = require "hs.logger".new "colorBoard"

local deferred              = require "cp.deferred"
local fcp                   = require "cp.apple.finalcutpro"
local go                    = require "cp.rx.go"
local i18n                  = require "cp.i18n"
local prop                  = require "cp.prop"

local Do                    = go.Do
local Done                  = go.Done
local format                = string.format
local If                    = go.If

local mod = {}

local plugin = {
    id = "finalcutpro.timeline.colorboardv2",
    group = "finalcutpro",
    dependencies = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local options = {}

    local updateUI = deferred.new(0.01)

    local aspects = { "color", "saturation", "exposure" }
    local ranges = { "master", "shadows", "midtones", "highlights" }
    local amounts = {1, 2, 3, 4, 5, 10}

    local cb = fcp.colorBoard

    local iColorBoard = i18n("colorBoard")
    local iAngle = i18n("angle")
    local iPercentage = i18n("percentage")
    local iUp = i18n("up")
    local iDown = i18n("down")

    for _, currentAspect in ipairs(aspects) do
        local iAspect = i18n(currentAspect)
        local aspect = cb[currentAspect](cb)
        for _, range in ipairs(ranges) do
            local iRange = i18n(range)
            local puck = aspect[range](aspect)

            -- set up the UI update action...
            local percentChange, angleChange = 0, 0
            local updating = prop.FALSE()

            local update = Do(
                If(updating):Is(false):Then(
                    Do(function()
                        updating(true)
                        return true
                    end)
                    :Then(
                        If(function() return percentChange ~= 0 end)
                        :Then(
                            If(function() return puck:isShowing() end):Is(false):Then(puck:doShow()):Then(Done())
                        )
                        :Then(function()
                            local value = puck:percent()
                            if value then
                                puck:percent(value + percentChange)
                                percentChange = 0
                                return true
                            end
                            return false
                        end)
                        :ThenYield()
                        :Otherwise(false)
                    ):Then(
                        If(function() return angleChange ~= 0 end)
                        :Then(
                            If(function() return puck:isShowing() end):Is(false):Then(puck:doShow()):Then(Done())
                        )
                        :Then(function()
                            local value = puck:angle()
                            if value then
                                puck:angle(value + angleChange)
                                angleChange = 0
                                return true
                            end
                            return false
                        end)
                        :ThenYield()
                        :Otherwise(false)
                    )
                    :Finally(function() updating(false) end)
                )
            ):Label("colorboardv2:update")

            updateUI:action(update)

            --------------------------------------------------------------------------------
            -- Setup all the different types of actions:
            --------------------------------------------------------------------------------
            for _, amount in pairs(amounts) do
                local id
                id = format("colorboard_%s_%s_percentage_up_%s", aspect, range, amount)
                options[id] = {
                    id = id,
                    label = format("%s - %s - %s - %s - %s %s", iColorBoard, iAspect, iRange, iPercentage, iUp, amount),
                    fn = function()
                        percentChange = percentChange + amount
                        updateUI()
                    end
                }

                id = format("colorboard_%s_%s_percentage_down_%s", aspect, range, amount)
                options[id] = {
                    id = id,
                    label = format("%s - %s - %s - %s - %s %s", iColorBoard, iAspect, iRange, iPercentage, iDown, amount),
                    fn = function()
                        percentChange = percentChange - amount
                        updateUI()
                    end
                }

                if puck:hasAngle() then
                    id = format("colorboard_%s_%s_angle_up_%s", aspect, range, amount)
                    options[id] = {
                        id = id,
                        label = format("%s - %s - %s - %s - %s %s", iColorBoard, iAspect, iRange, iAngle, iUp, amount),
                        fn = function()
                            percentChange = percentChange + amount
                            updateUI()
                        end
                    }

                    id = format("colorboard_%s_%s_angle_down_%s", aspect, range, amount)
                    options[id] = {
                        id = id,
                        label = format("%s - %s - %s - %s - %s %s", iColorBoard, iAspect, iRange, iAngle, iDown, amount),
                        fn = function()
                            percentChange = percentChange - amount
                            updateUI()
                        end
                    }
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Action Manager:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    local colorBoardActionSubTitle = i18n("colorBoardActionSubTitle")
    mod._handler = actionmanager.addHandler("fcpx_colorboard", "fcpx")
        :onChoices(function(choices)
            for id, item in pairs(options) do
                choices
                    :add(item.label)
                    :subText(colorBoardActionSubTitle)
                    :params({
                        id = id,
                    })
                    :id(id)
            end
        end)
        :onExecute(function(action)
            options[action.id].fn()
        end)
        :onActionId(function(params)
            return params.id
        end)

    return mod
end

return plugin
