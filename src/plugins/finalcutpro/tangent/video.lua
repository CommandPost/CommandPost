--- === plugins.finalcutpro.tangent.video ===
---
--- Final Cut Pro Video Inspector for Tangent

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                   = require("hs.logger").new("tng_video")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                   = require("cp.apple.finalcutpro")
local deferred              = require("cp.deferred")

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


-- DEFER -> number
-- Constant
-- The amount of time to defer UI updates
local DEFER = 0.01

-- updateUI -> cp.deferred
-- Variable
-- Used to defer updates to a minimum period. This helps reduce overload by data from the Tangent panel.
local updateUI = deferred.new(DEFER)

local function xyParameter(group, param, id)
    -- set up the accumulator...
    local x, y = 0, 0
    updateUI:action(function()
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
    end)

    local label = param:label()
    local xParam = group:parameter(id + 1)
    :name(label .. " X")
    -- TODO: Hack to work around Tangent Hub bug that doesn't send changes if no min/max are set.
    :minValue(0)
    :maxValue(100)
    :stepSize(0.5)
    :onGet(function() return param:x() end)
    :onChange(function(amount)
        x = x + amount
        updateUI()
    end)
    :onReset(function() param:x(0) end)

    local yParam = group:parameter(id + 2)
    :name(label .. " Y")
    -- TODO: Hack to work around Tangent Hub bug that doesn't send changes if no min/max are set.
    :minValue(0)
    :maxValue(100)
    :stepSize(0.5)
    :onGet(function() return param:y() end)
    :onChange(function(amount)
        y = y + amount
        updateUI()
    end)
    :onReset(function() param:y(0) end)

    local xyBinding = group:binding(label):members(xParam, yParam)

    return id + 2, xParam, yParam, xyBinding
end

local function sliderParameter(group, param, id, minValue, maxValue, stepSize, default)
    local label = param:label()

    -- set up deferred update
    local value = 0
    updateUI:action(function()
        if value ~= 0 then
            local currentValue = param.value()
            if currentValue then
                param.value(currentValue + value)
                value = 0
            end
        end
    end)

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
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    local video = fcp:inspector():video()

    deps.tangentManager.addMode(0x00010010, "FCP: Video")
        :onActivate(function()
            if fcp.isFrontmost() then
                video:show()
            end
        end)

    local videoGroup = deps.fcpGroup:group(i18n("video") .. " " .. i18n("inspector"))

    local transform = video:transform()
    local transformGroup = videoGroup:group(transform:label())

    local id = 0x0F730000

    local px, py, rotation
    id, px, py = xyParameter(transformGroup, transform:position(), id)
    id, rotation = sliderParameter(transformGroup, transform:rotation(), id, 0, 360, 0.1)
    transformGroup:binding(tostring(transform:position()) .. " " .. tostring(transform:rotation()))
        :members(px, py, rotation)

    id = sliderParameter(transformGroup, transform:scaleAll(), id, 0, 100, 0.1, 100.0)
    id = sliderParameter(transformGroup, transform:scaleX(), id, 0, 100, 0.1, 100.0)
    id = sliderParameter(transformGroup, transform:scaleY(), id, 0, 100, 0.1, 100.0)

    id = xyParameter(transformGroup, transform:anchor(), id)

    return videoGroup, id
end

return plugin