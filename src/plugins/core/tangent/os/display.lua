local log                   = require("hs.logger").new("tg_dsply")

local brightness            = require("hs.brightness")

local plugin = {
    id = "core.tangent.os.display",
    group = "core",
    dependencies = {
        ["core.tangent.os"] = "osGroup",
    }
}

function plugin.init(deps)
    local displayGroup = deps.osGroup:group(i18n("display"))

    displayGroup:parameter(0x0AD00001)
        :name(i18n("brightness"))
        :name9(i18n("brightness9"))
        :name10(i18n("brightness10"))
        :minValue(0)
        :maxValue(100)
        :stepSize(5)
        :onGet(function() return brightness.get() end)
        :onChange(function(increment)
            brightness.set(brightness.get() + increment)
        end)
        :onReset(function() brightness.set(brightness.ambient()) end)
end

return plugin