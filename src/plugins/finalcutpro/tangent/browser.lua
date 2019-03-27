--- === plugins.finalcutpro.tangent.browser ===
---
--- Final Cut Pro Tangent Browser Group

local require = require

--local log                   = require("hs.logger").new("tangentBrowser")

local timer                 = require("hs.timer")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")
local tools                 = require("cp.tools")

local rescale               = tools.rescale
local delayed               = timer.delayed

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.browser",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)

    local id = 0x00140000
    local fcpGroup = deps.fcpGroup
    local group = fcpGroup:group(i18n("browser"))
    local appearanceAndFiltering = fcp.libraries.appearanceAndFiltering

    --------------------------------------------------------------------------------
    -- Browser Duration:
    --------------------------------------------------------------------------------
    local hidePopup = delayed.new(0.5, function()
        if appearanceAndFiltering:isShowing() then
            appearanceAndFiltering:hide()
        end
    end)

    local durations = appearanceAndFiltering.DURATION
    group:menu(id + 1)
        :name(i18n("duration"))
        :name9(i18n("duration"))
        :onGet(function()
            local value = appearanceAndFiltering:duration():value()
            if value then
                for t, n in pairs(durations) do
                    if value == n then
                        return t
                    end
                end
            end
        end)
        :onNext(function()
            appearanceAndFiltering:show():duration():increment()
            hidePopup:start()
        end)
        :onPrev(function()
            appearanceAndFiltering:show():duration():decrement()
            hidePopup:start()
        end)
        :onReset(function()
            appearanceAndFiltering:show():duration():value(0)
            appearanceAndFiltering:hide()
        end)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Browser Clip Height:
    --------------------------------------------------------------------------------
    group:menu(id + 1)
        :name(i18n("height"))
        :name9(i18n("height"))
        :onGet(function()
            local value = appearanceAndFiltering:clipHeight():value()
            if value then
                local rescaled = rescale(value, 32, 135, 1, 100)
                return rescaled and tostring(rescaled) .. "%"
            end
        end)
        :onNext(function()
            appearanceAndFiltering:show():clipHeight():increment()
            hidePopup:start()
        end)
        :onPrev(function()
            appearanceAndFiltering:show():clipHeight():decrement()
            hidePopup:start()
        end)
        :onReset(function()
            appearanceAndFiltering:show():clipHeight():value(0)
            appearanceAndFiltering:hide()
        end)

end

return plugin
