--- === plugins.finalcutpro.advanced.disablewaveforms ===
---
--- Disable Waveforms Plugin.

local require = require

local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local prop              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.advanced.disablewaveforms.disableWaveform <cp.prop: boolean>
--- Variable
--- Waveforms Disabled?
mod.disableWaveform = prop.new(function()
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    return not fcp.preferences.FFAudioDisableWaveformDrawing
end, function(value)
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    if value then
        fcp.preferences.FFAudioDisableWaveformDrawing = false
    else
        fcp.preferences.FFAudioDisableWaveformDrawing = true
    end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.advanced.disablewaveforms",
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
    deps.prefs.panel
        :addCheckbox(2204,
        {
            label = i18n("enableWaveformDrawing"),
            onchange = function(_, params) mod.disableWaveform(params.checked) end,
            checked = function() return mod.disableWaveform() end,
        })

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpDisableWaveforms")
        :whenActivated(function() mod.enabled:toggle() end)

    return mod
end

return plugin
