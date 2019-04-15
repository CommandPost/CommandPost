--- === plugins.finalcutpro.midi.manager ===
---
--- MIDI Manager Plugin for Final Cut Pro.

local require = require

local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")


local mod = {}

--- plugins.finalcutpro.midi.manager.ID -> string
--- Constant
--- Group ID
mod.ID = "fcpx"

-- used to update the group status
local function updateGroupStatus(enabled)
    mod._manager.groupStatus(mod.ID, enabled)
end

--- plugins.finalcutpro.midi.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable MIDI Support.
mod.enableMIDI = config.prop("enableMIDI", false):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Update MIDI Commands when Final Cut Pro is shown or hidden:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:watch(updateGroupStatus)
        fcp.app.showing:watch(updateGroupStatus)
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:unwatch(updateGroupStatus)
        fcp.app.showing:unwatch(updateGroupStatus)
    end
end)


local plugin = {
    id = "finalcutpro.midi.manager",
    group = "finalcutpro",
    dependencies = {
        ["core.midi.manager"]       = "manager",
    }
}

function plugin.init(deps)
    mod._manager = deps.manager
    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Update Watchers:
    --------------------------------------------------------------------------------
    mod.enableMIDI:update()
end

return plugin
