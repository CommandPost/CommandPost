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

    --------------------------------------------------------------------------------
    -- Browser Duration:
    --------------------------------------------------------------------------------
    local hidePopup = delayed.new(0.5, function()
        if fcp:libraries():appearanceAndFiltering():isShowing() then
            fcp:libraries():appearanceAndFiltering():hide()
        end
    end)

    local durations = fcp:libraries():appearanceAndFiltering().DURATION
    group:menu(id + 1)
        :name(i18n("duration"))
        :name9(i18n("duration"))
        :onGet(function()
            local value = fcp:libraries():appearanceAndFiltering():duration():value()
            if value then
                for t, n in pairs(durations) do
                    if value == n then
                        return t
                    end
                end
            end
        end)
        :onNext(function()
            fcp:libraries():appearanceAndFiltering():show():duration():increment()
            hidePopup:start()
        end)
        :onPrev(function()
            fcp:libraries():appearanceAndFiltering():show():duration():decrement()
            hidePopup:start()
        end)
        :onReset(function()
            fcp:libraries():appearanceAndFiltering():show():duration():value(0)
            fcp:libraries():appearanceAndFiltering():hide()
        end)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Browser Clip Height:
    --------------------------------------------------------------------------------
    group:menu(id + 1)
        :name(i18n("height"))
        :name9(i18n("height"))
        :onGet(function()
            local value = fcp:libraries():appearanceAndFiltering():clipHeight():value()
            if value then
                local rescaled = rescale(value, 32, 135, 1, 100)
                return rescaled and tostring(rescaled) .. "%"
            end
        end)
        :onNext(function()
            fcp:libraries():appearanceAndFiltering():show():clipHeight():increment()
            hidePopup:start()
        end)
        :onPrev(function()
            fcp:libraries():appearanceAndFiltering():show():clipHeight():decrement()
            hidePopup:start()
        end)
        :onReset(function()
            fcp:libraries():appearanceAndFiltering():show():clipHeight():value(0)
            fcp:libraries():appearanceAndFiltering():hide()
        end)

end

return plugin
