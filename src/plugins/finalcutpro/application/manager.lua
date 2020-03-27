--- === plugins.finalcutpro.application.manager ===
---
--- Registers Final Cut Pro with the Core Application Manager.

local require   = require

local config    = require "cp.config"
local fcp       = require "cp.apple.finalcutpro"

local plugin = {
    id              = "finalcutpro.application.manager",
    group           = "finalcutpro",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    local iconPath = config.basePath .. "/plugins/finalcutpro/console/images/"
    local searchConsoleToolbar = {
        fcpx_videoEffect            = { path = iconPath .. "videoEffect.png",       priority = 3},
        fcpx_audioEffect            = { path = iconPath .. "audioEffect.png",       priority = 4},
        fcpx_generator              = { path = iconPath .. "generator.png",         priority = 5},
        fcpx_title                  = { path = iconPath .. "title.png",             priority = 6},
        fcpx_transition             = { path = iconPath .. "transition.png",        priority = 7},
        fcpx_fonts                  = { path = iconPath .. "font.png",              priority = 8},
        fcpx_shortcuts              = { path = iconPath .. "shortcut.png",          priority = 9},
        fcpx_menu                   = { path = iconPath .. "menu.png",              priority = 10},
    }

    deps.manager.registerApplication({
        bundleID = fcp:bundleID(),
        displayName = "Final Cut Pro",
        searchConsoleToolbar = searchConsoleToolbar,
    })
end

return plugin