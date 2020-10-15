--- === plugins.finalcutpro.commands ===
---
--- The 'fcpx' command collection.
--- These are only active when FCPX is the active (ie. frontmost) application.

local require       = require

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
    -- New Final Cut Pro Command Collection:
    --------------------------------------------------------------------------------
    mod.cmds = commands.new("fcpx")

    --------------------------------------------------------------------------------
    -- Switch to Final Cut Pro to activate:
    --------------------------------------------------------------------------------
    mod.cmds:watch({
        activate    = function()
            fcp:launch()
        end,
    })

    --------------------------------------------------------------------------------
    -- Enable/Disable as Final Cut Pro becomes Active/Inactive:
    --------------------------------------------------------------------------------
    mod.isEnabled = fcp.isFrontmost:AND(fcp.isModalDialogOpen:NOT()):watch(function(enabled)
        mod.cmds:isEnabled(enabled)
    end):label("fcpxCommandsIsEnabled")

    return mod.cmds
end

function plugin.postInit()
    if mod.isEnabled then
        mod.isEnabled:update()
    end
end

return plugin
