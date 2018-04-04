local log                   = require("hs.logger").new("tng_video")

local fcp                   = require("cp.apple.finalcutpro")

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

local function xyParameter(group, param, id)
    local label = param:label()
    local x = group:parameter(id + 1)
    :name(label .. " X")
    :stepSize(1)
    :onGet(function() return param:x() end)
    :onChange(function(amount)
        log.df("X Changed: %s", amount)
        local value = param:x()
        if value ~= nil then
            param:x(value+amount)
        end
    end)
    :onReset(function() param:x(0) end)

    local y = group:parameter(id + 2)
    :name(label .. " Y")
    :stepSize(1)
    :onGet(function() return param:y() end)
    :onChange(function(amount)
        log.df("Y Changed: %s", amount)
        local value = param:y()
        if value ~= nil then
            param:y(value + amount)
        end
    end)
    :onReset(function() param:y(0) end)

    local b = group:binding(label):members(x, y)

    return id + 2, x, y, b
end

local function sliderParameter(group, param, id)
    local label = param:label()
    local value = group:parameter(id + 1)
    :name(label)
    :stepSize(1.0)
    :onGet(function() return param:value() end)
    :onChange(function(amount) param.value:shiftValue(amount) end)
    :onReset(function() param:value(0) end)

    return id + 1, value
end

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    local video = fcp:inspector():video()

    deps.tangentManager.addMode(0x00010010, "FCP: Video")
        :onActivate(function() video:show() end)

    local videoGroup = deps.fcpGroup:group(fcp:string("FFInspectorTabVideo"))

    local transform = video:transform()
    local transformGroup = videoGroup:group(transform:label())

    local id = 0x0F730000

    local px, py, rotation
    id, px, py = xyParameter(transformGroup, transform:position(), id)
    id, rotation = sliderParameter(transformGroup, transform:rotation(), id)
    transformGroup:binding(tostring(transform:position()) .. " " .. tostring(transform:rotation()))
        :members(px, py, rotation)

    id = sliderParameter(transformGroup, transform:scaleAll(), id)
    id = sliderParameter(transformGroup, transform:scaleX(), id)
    id = sliderParameter(transformGroup, transform:scaleY(), id)

    id = xyParameter(transformGroup, transform:anchor(), id)

    log.df("Final ID: %#010x", id)

    return videoGroup, id
end

return plugin