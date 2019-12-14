--- === plugins.finalcutpro.advanced.multicam ===
---
--- Show Timeline In Player.

local require   = require

local fcp       = require "cp.apple.finalcutpro"
local i18n      = require "cp.i18n"
local prop      = require "cp.prop"

local mod = {}

--- plugins.finalcutpro.advanced.multicam.enabled <cp.prop: boolean; live>
--- Constant
--- Use Better Quality in Angles Viewer?
mod.enabled = prop.new(function()
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    return fcp.preferences.FFMultiCamGridQuailtyLevel == 10
end, function(value)
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    if value then
        fcp.preferences:set("FFMultiCamGridQuailtyLevel", 10)
    else
        fcp.preferences:set("FFMultiCamGridQuailtyLevel", nil)
    end
end)

local plugin = {
    id              = "finalcutpro.advanced.multicam",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel
            :addCheckbox(2204.12,
            {
                label = i18n("useBetterQualityInAnglesViewer"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = function() return mod.enabled() end,
            })
    end

    return mod
end

return plugin
