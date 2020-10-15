--- === plugins.finalcutpro.advanced.playbackrendering ===
---
--- Playback Rendering Plugin.

local require   = require

local fcp       = require "cp.apple.finalcutpro"
local i18n      = require "cp.i18n"

local mod = {}

--- plugins.finalcutpro.advanced.playbackrendering.enabled <cp.prop: boolean>
--- Variable
--- Gets whether or not Playback Rendering is enabled.
mod.enabled = fcp.preferences:prop("FFSuspendBGOpsDuringPlay", true)

local plugin = {
    id              = "finalcutpro.advanced.playbackrendering",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel
            :addCheckbox(2204.1,
            {
                label = i18n("enableRenderingDuringPlayback"),
                onchange = function(_, params) mod.enabled(not params.checked) end,
                checked = function() return not mod.enabled() end,
            })
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpAllowTasksDuringPlayback")
        :whenActivated(function() mod.enabled:toggle() end)

    return mod
end

return plugin
