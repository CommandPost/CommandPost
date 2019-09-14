--- === plugins.finalcutpro.midi.manager ===
---
--- MIDI Manager Plugin for Final Cut Pro.

local require = require

--local log             = require "hs.logger".new "fcpMIDIman"

local application       = require "hs.application"

local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"

local mod = {}

--- plugins.finalcutpro.midi.manager.ID -> string
--- Constant
--- Group ID
mod.ID = "fcpx"

-- used to update the group status
local function updateGroupStatus(enabled)
    --------------------------------------------------------------------------------
    -- Workaround for AudioSwift Support:
    --------------------------------------------------------------------------------
    if fcp:isRunning() then
        local fcpApp = fcp.app.hsApplication()
        local frontmostApplication = application.frontmostApplication()
        if #fcpApp:visibleWindows() >= 1 and frontmostApplication:bundleID() == "com.nigelrios.AudioSwift" then
            enabled = true
        end
    end
    mod._manager.groupStatus(mod.ID, enabled)
end

local function update()
    if mod._manager.enabled() or mod._manager.enabledLoupedeck() then
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
end

local plugin = {
    id = "finalcutpro.midi.manager",
    group = "finalcutpro",
    dependencies = {
        ["core.midi.manager"]       = "manager",
    }
}

function plugin.init(deps)
    mod._manager = deps.manager

    mod._manager.enabled:watch(update)
    mod._manager.enabledLoupedeck:watch(update)

    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Update Watchers:
    --------------------------------------------------------------------------------
    update()
end

return plugin
