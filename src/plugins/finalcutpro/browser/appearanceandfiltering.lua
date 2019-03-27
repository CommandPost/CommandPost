--- === plugins.finalcutpro.browser.appearanceandfiltering ===
---
--- Solo a clip in the Final Cut Pro Browser.

local require   = require

local log       = require("hs.logger").new("appearanceandfiltering")

local fcp       = require("cp.apple.finalcutpro")
local i18n      = require("cp.i18n")
local just      = require("cp.just")
local tools	    = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.browser.appearanceandfiltering",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    local appearanceAndFiltering = fcp.libraries.appearanceAndFiltering
    for id, value in pairs(appearanceAndFiltering.DURATION) do
        fcpxCmds
            :add("setDuration" .. id)
            :titled(i18n("setBrowserDurationTo") .. " " .. id)
            :groupedBy("browser")
            :whenActivated(function()
                if not just.doUntil(function()
                    appearanceAndFiltering:show()
                    return appearanceAndFiltering:isShowing()
                end) then
                    tools.playErrorSound()
                    log.ef("Could not open the Appearance & Filtering popup.")
                    return
                end

                appearanceAndFiltering:duration():value(value)

                if not just.doUntil(function()
                    appearanceAndFiltering:hide()
                    return not appearanceAndFiltering:isShowing()
                end) then
                    tools.playErrorSound()
                    log.ef("Could not close the Appearance & Filtering popup.")
                    return
                end
            end)
    end
end

return plugin