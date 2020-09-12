--- === plugins.finalcutpro.advanced.fcpxml ===
---
--- Adds preferences for extra FCPXML import and export options.

local require       = require

local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"
local prop          = require "cp.prop"

local semver        = require "semver"

local mod = {}

--- plugins.finalcutpro.advanced.fcpxml.importEnabled <cp.prop: boolean>
--- Variable
--- Are extra FCPXML import options enabled?
mod.importEnabled = prop.new(function()
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    return fcp.preferences.FFXMLImportShowExtraOptions == "1"
end, function(value)
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    if value then
        fcp.preferences.FFXMLImportShowExtraOptions = "1"
    else
        fcp.preferences.FFXMLImportShowExtraOptions = "0"
    end
end)

--- plugins.finalcutpro.advanced.fcpxml.exportEnabled <cp.prop: boolean>
--- Variable
--- Are extra FCPXML export options enabled?
mod.exportEnabled = prop.new(function()
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    return fcp.preferences.FFXMLExportShowExtraOptions == "1"
end, function(value)
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    if value then
        fcp.preferences.FFXMLExportShowExtraOptions = "1"
    else
        fcp.preferences.FFXMLExportShowExtraOptions = "0"
    end
end)


local plugin = {
    id              = "finalcutpro.advanced.fcpxml",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Sadly, this feature stopped working in 10.4.9:
    --------------------------------------------------------------------------------
    if fcp.version() <= semver("10.4.8") then
        --------------------------------------------------------------------------------
        -- Setup Menubar Preferences Panel:
        --------------------------------------------------------------------------------
        local panel = deps.prefs.panel
        if panel then
            panel
                  :addCheckbox(2205,
                  {
                      label = i18n("showHiddenFCPXMLImportOptions"),
                      onchange = function(_, params) mod.importEnabled(params.checked) end,
                      checked = mod.importEnabled,
                  })
                  :addCheckbox(2206,
                  {
                      label = i18n("showHiddenFCPXMLExportOptions"),
                      onchange = function(_, params) mod.exportEnabled(params.checked) end,
                      checked = mod.exportEnabled,
                  })
        end
    end
    return mod
end

return plugin
