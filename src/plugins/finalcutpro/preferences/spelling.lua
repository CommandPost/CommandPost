--- === plugins.finalcutpro.preferences.spelling ===
---
--- Adds Preference for "Correct Spelling Automatically" within Final Cut Pro X.

local require       = require

local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local plugin = {
    id              = "finalcutpro.preferences.spelling",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    if deps.prefs.panel then
        deps.prefs.panel
            :addCheckbox(1.001,
            {
                label = i18n("correctSpellingAutomatically"),
                onchange = function(_, params) fcp.preferences.NSAutomaticSpellingCorrectionEnabled = params.checked end,
                checked = function() return fcp.preferences.NSAutomaticSpellingCorrectionEnabled end,
            }
        )
    end
end

return plugin