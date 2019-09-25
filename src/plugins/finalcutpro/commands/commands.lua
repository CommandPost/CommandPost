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
    mod.isEnabled:update()
end

return plugin
