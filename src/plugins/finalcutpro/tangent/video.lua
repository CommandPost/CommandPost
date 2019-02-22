--- === plugins.finalcutpro.tangent.video ===
---
--- Final Cut Pro Video Inspector for Tangent

local require = require

local fcp                   = require("cp.apple.finalcutpro")
local deferred              = require("cp.deferred")
local i18n                  = require("cp.i18n")

local Do                    = require("cp.rx.go.Do")
local If                    = require('cp.rx.go.If')

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

    deps.tangentManager.addMode(0x00010010, "FCP: Video")

    mod._videoGroup = deps.fcpGroup:group(i18n("video") .. " " .. i18n("inspector"))

    local transform = video:transform()
    local transformGroup = mod._videoGroup:group(transform:label())

    local id = 0x0F730000

    local px, py, rotation
    id, px, py = xyParameter(transformGroup, transform:position(), id, 0, 1000, 0.1)
    id, rotation = sliderParameter(transformGroup, transform:rotation(), id, 0, 360, 0.1)
    transformGroup:binding(tostring(transform:position()) .. " " .. tostring(transform:rotation()))
        :members(px, py, rotation)

    id = sliderParameter(transformGroup, transform:scaleAll(), id, 0, 100, 0.1, 100.0)
    id = sliderParameter(transformGroup, transform:scaleX(), id, 0, 100, 0.1, 100.0)
    id = sliderParameter(transformGroup, transform:scaleY(), id, 0, 100, 0.1, 100.0)

    xyParameter(transformGroup, transform:anchor(), id, 0, 1000, 0.1)

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
