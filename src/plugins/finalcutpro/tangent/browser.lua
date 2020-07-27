--- === plugins.finalcutpro.tangent.browser ===
---
--- Final Cut Pro Tangent Browser Group

local require               = require

--local log                   = require "hs.logger".new "tangentBrowser"

local timer                 = require "hs.timer"

local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local rescale               = tools.rescale
local delayed               = timer.delayed

local plugin = {
    id = "finalcutpro.tangent.browser",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
        ["finalcutpro.tangent.common"]  = "common",

        --------------------------------------------------------------------------------
        -- NOTE: These plugins aren't actually referred here in this plugin, but we
        --       need to include them here so that they load before this plugin loads.
        --------------------------------------------------------------------------------
        ["finalcutpro.browser.insertvertical"] = "insertvertical",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local common                        = deps.common

    local commandParameter              = common.commandParameter
    local dynamicPopupSliderParameter   = common.dynamicPopupSliderParameter
    local shortcutParameter             = common.shortcutParameter

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
    id = id + 1

    --------------------------------------------------------------------------------
    -- Browser Clip Filtering:
    --------------------------------------------------------------------------------
    local clipFilteringGroup = group:group(i18n("clipFiltering"))

    id = shortcutParameter(clipFilteringGroup, id, "allClips", "AllClips")
    id = shortcutParameter(clipFilteringGroup, id, "hideRejected", "HideRejected")
    id = shortcutParameter(clipFilteringGroup, id, "noRatingsOrKeywords", "NoRatingsOrKeywords")
    id = shortcutParameter(clipFilteringGroup, id, "favorites", "ShowFavorites")
    id = shortcutParameter(clipFilteringGroup, id, "rejected", "ShowRejected")
    id = shortcutParameter(clipFilteringGroup, id, "unused", "FilterUnusedMedia")

    local libraries = fcp:libraries()
    id = dynamicPopupSliderParameter(group, libraries.clipFiltering, id, "clipFiltering", 1)

    --------------------------------------------------------------------------------
    -- Insert Clips Vertically from Browser to Timeline:
    --------------------------------------------------------------------------------
    commandParameter(group, id, "fcpx", "insertClipsVerticallyFromBrowserToTimeline")

end

return plugin
