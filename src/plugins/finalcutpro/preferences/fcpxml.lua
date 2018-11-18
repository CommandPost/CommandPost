--- === plugins.finalcutpro.preferences.fcpxml ===
---
--- Adds preferences for extra FCPXML import and export options.

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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.preferences.fcpxml.importEnabled <cp.prop: boolean>
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

--- plugins.finalcutpro.preferences.fcpxml.exportEnabled <cp.prop: boolean>
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.preferences.fcpxml",
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
        deps.prefs.panel
            --------------------------------------------------------------------------------
            -- Add Preferences Checkbox:
            --------------------------------------------------------------------------------
            :addCheckbox(1.3,
            {
                label = i18n("showHiddenFCPXMLImportOptions"),
                onchange = function(_, params) mod.importEnabled(params.checked) end,
                checked = mod.importEnabled,
            })
            :addCheckbox(1.4,
            {
                label = i18n("showHiddenFCPXMLExportOptions"),
                onchange = function(_, params) mod.exportEnabled(params.checked) end,
                checked = mod.exportEnabled,
            })
    end

    return mod
end

return plugin
