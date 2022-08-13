--- === plugins.core.tools.caffeinate ===
---
--- Prevents your Mac from going to sleep.

local require           = require

--local log               = require("hs.logger").new("caffeinate")

local caffeinate        = require "hs.caffeinate"

local config            = require "cp.config"
local i18n              = require "cp.i18n"

local enabled = config.prop("caffeinate.enabled", false):watch(function(value)
    if value then
        --log.df("Caffinate Enabled!")
        caffeinate.set("displayIdle", true)
        caffeinate.set("systemIdle", true)
        caffeinate.set("system", true)
    else
        --log.df("Caffinate Disabled!")
        caffeinate.set("displayIdle", false)
        caffeinate.set("systemIdle", false)
        caffeinate.set("system", false)
    end
end)

local plugin = {
    id              = "core.tools.caffeinate",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "menu",
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Add menu items:
    --------------------------------------------------------------------------------
    local menu = deps.menu
    menu.tools
        :addItem(1, function()
            return {
                title = i18n("preventMacFromSleeping"),
                fn = function()
                    enabled:toggle()
                end,
                checked = enabled()
            }
        end)

    --------------------------------------------------------------------------------
    -- Add actions:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("enablePreventMacFromSleeping")
        :whenActivated(function() enabled:value(true) end)
        :titled(i18n("enable") .. " " .. i18n("preventMacFromSleeping"))

    global
        :add("disablePreventMacFromSleeping")
        :whenActivated(function() enabled:value(false) end)
        :titled(i18n("disable") .. " " .. i18n("preventMacFromSleeping"))

    global
        :add("togglePreventMacFromSleeping")
        :whenActivated(function() enabled:toggle() end)
        :titled(i18n("toggle") .. " " .. i18n("preventMacFromSleeping"))

    --------------------------------------------------------------------------------
    -- Force an update:
    --------------------------------------------------------------------------------
    enabled:update()

end

return plugin