--- === plugins.finalcutpro.commands ===
---
--- The 'fcpx' command collection.
--- These are only active when FCPX is the active (ie. frontmost) application.

local require       = require

--local log           = require "hs.logger".new "fcpCmds"

local application   = require "hs.application"
local appWatcher    = require "hs.application.watcher"

local commands      = require "cp.commands"
local fcp           = require "cp.apple.finalcutpro"

local mod = {}

local plugin = {
    id              = "finalcutpro.commands",
    group           = "finalcutpro",
}

function plugin.init()
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Initialise the Final Cut Pro Commands:
    --------------------------------------------------------------------------------
    mod.cmds = commands.new("fcpx")

    local checkFrontmostApp = function()
        local frontmostApplication = application.frontmostApplication()
        local bundleID = frontmostApplication:bundleID()
        if bundleID and bundleID == fcp:bundleID() then
            mod.cmds:isEnabled(true)
        else
            mod.cmds:isEnabled(false)
        end
    end

    --------------------------------------------------------------------------------
    -- Watch for Final Cut Pro becoming active:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function(_, event)
        if event == appWatcher.activated then
            checkFrontmostApp()
        end
    end):start()

    --------------------------------------------------------------------------------
    -- Check on CommandPost's launch:
    --------------------------------------------------------------------------------
    checkFrontmostApp()

    return mod.cmds
end

return plugin
