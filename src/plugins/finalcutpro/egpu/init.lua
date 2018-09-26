--- === plugins.finalcutpro.egpu ===
---
--- Final Cut Pro eGPU Support.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                               = require("hs.logger").new("eGPU")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                               = require("cp.apple.finalcutpro")
local i18n                              = require("cp.i18n")
local prop                              = require("cp.prop")
local tools                             = require("cp.tools")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local semver                            = require("semver")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.fullscreen.shortcuts.enabled <cp.prop: boolean>
--- Variable
--- Is the module enabled?
mod.enabled = prop.new(function()
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    return fcp.preferences.GPUSelectionPolicy ~= nil
end, function(value)
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    if value then
        fcp.preferences.GPUSelectionPolicy = "preferRemovable"
        fcp.preferences.GPUEjectPolicy = "relaunch"
    else
        fcp.preferences.GPUSelectionPolicy = nil
        fcp.preferences.GPUEjectPolicy = nil
    end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.egpu",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.app"] = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)


    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then

        --------------------------------------------------------------------------------
        -- Check macOS Version:
        --------------------------------------------------------------------------------
        local osVersion = tools.macOSVersion()
        local allowEGPU = false
        local os = semver(osVersion)
        if os >= semver("10.13.4") and os < semver("10.4.0") then
            allowEGPU = true
        end

        deps.prefs.panel
            --------------------------------------------------------------------------------
            -- Add Preferences Checkbox:
            --------------------------------------------------------------------------------
            :addCheckbox(1.01,
            {
                label = i18n("enableEGPUSupport"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = mod.enabled,
                disabled = not allowEGPU,
            }
        )
    end

    return mod
end

return plugin
