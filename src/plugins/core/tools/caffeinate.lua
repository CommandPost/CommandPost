--- === plugins.core.tools.caffeinate ===
---
--- Prevents your Mac from going to sleep.

local require           = require

local caffeinate        = require "hs.caffeinate"

local config            = require "cp.config"
local i18n              = require "cp.i18n"

local enabled = config.prop("caffeinate.enabled", false):watch(function(value)
    if value then
        caffeinate.set("displayIdle", true)
        caffeinate.set("systemIdle", true)
        caffeinate.set("system", true)
    else
        caffeinate.set("displayIdle", false)
        caffeinate.set("systemIdle", false)
        caffeinate.set("system", false)
    end
end)

local plugin = {
    id				= "core.tools.caffeinate",
    group			= "core",
    dependencies	= {
        ["core.menu.manager"] = "menu",
        ["core.watchfolders.manager"]	= "watchfolders",
    }
}

function plugin.init(deps)
    deps.menu.tools
        :addItem(1, function()
            return {
                title = i18n("preventMacFromSleeping"),
                fn = function()
                    enabled:toggle()
                end,
                checked = enabled()
            }
        end)

    enabled:update()
end

return plugin