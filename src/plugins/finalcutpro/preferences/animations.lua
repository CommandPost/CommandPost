--- === plugins.finalcutpro.preferences.animations ===
---
--- Adds Preference for "Enable User Interface Animations" within Final Cut Pro X.

local require       = require

local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local plugin = {
    id              = "finalcutpro.preferences.animations",
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
            :addCheckbox(1.0001,
            {
                label = i18n("enableUserInterfaceAnimations"),
                onchange = function(_, params) fcp:isWindowAnimationEnabled(params.checked) end,
                checked = function() return fcp:isWindowAnimationEnabled() end,
            }
        )
    end
end

return plugin