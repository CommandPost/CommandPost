--- === plugins.resolve.manager ===
---
--- The Manager Plugin for Blackmagic DaVinci Resolve.

local require       = require

local application   = require "hs.application"

local commands      = require "cp.commands"
local config        = require "cp.config"
local i18n          = require "cp.i18n"
local resolve       = require "cp.blackmagic.resolve"

local mod = {}

local plugin = {
    id              = "resolve.manager",
    group           = "resolve",
    dependencies = {
        ["core.commands.global"] = "global",
        ["core.midi.manager"] = "midiManager",
    }
}

-- used to update the group status
local function updateGroupStatus(enabled)
    --------------------------------------------------------------------------------
    -- Workaround for AudioSwift Support:
    --------------------------------------------------------------------------------
    if resolve:isRunning() then
        local resolveApp = resolve.app.hsApplication()
        local frontmostApplication = application.frontmostApplication()
        if #resolveApp:visibleWindows() >= 1 and frontmostApplication:bundleID() == "com.nigelrios.AudioSwift" then
            enabled = true
        end
    end
    mod._midiManager.groupStatus(mod.ID, enabled)
end

function plugin.init(deps)
    if resolve:isSupported() then
        --------------------------------------------------------------------------------
        -- Setup Resolve Specific Commands:
        --------------------------------------------------------------------------------
        mod.cmds = commands.new("resolve")
        mod.cmds:watch({
            activate    = function()
                resolve:launch()
            end,
        })
        mod.isEnabled = resolve.isFrontmost:watch(function(enabled)
            mod.cmds:isEnabled(enabled)
        end):label("resolveCommandsIsEnabled")

        --------------------------------------------------------------------------------
        -- Global Commands:
        --------------------------------------------------------------------------------
        local global = deps.global
        global
            :add("launchResolve")
            :whenPressed(function()
                resolve:launch()
            end)
            :groupedBy("resolve")
            :titled(i18n("launch") .. " " .. i18n("daVinciResolve"))

        --------------------------------------------------------------------------------
        -- MIDI Watcher:
        --------------------------------------------------------------------------------
        mod._midiManager = deps.midiManager
        mod.enableMIDI = config.prop("enableMIDI", false):watch(function(enabled)
            if enabled then
                --------------------------------------------------------------------------------
                -- Update MIDI Commands when Resolve is shown or hidden:
                --------------------------------------------------------------------------------
                resolve.app.frontmost:watch(updateGroupStatus)
                resolve.app.showing:watch(updateGroupStatus)
            else
                --------------------------------------------------------------------------------
                -- Destroy Watchers:
                --------------------------------------------------------------------------------
                resolve.app.frontmost:unwatch(updateGroupStatus)
                resolve.app.showing:unwatch(updateGroupStatus)
            end
        end)

        return mod
    end
end

function plugin.postInit()
    if resolve:isSupported() then
        mod.isEnabled:update()
        mod.enableMIDI:update()
    end
end

return plugin
