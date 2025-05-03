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

function mod.checkFrontmostApp()
    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication and frontmostApplication:bundleID()
    if bundleID and bundleID == fcp:bundleID() then
        mod.cmds:isEnabled(true)
    else
        mod.cmds:isEnabled(false)
    end
end

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

    --------------------------------------------------------------------------------
    -- Watch for Final Cut Pro becoming active:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function(_, event)
        if event == appWatcher.activated then
            mod.checkFrontmostApp()
        end
    end):start()

    return mod.cmds
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Check on CommandPost's launch:
    --------------------------------------------------------------------------------
    mod.checkFrontmostApp()
end

return plugin