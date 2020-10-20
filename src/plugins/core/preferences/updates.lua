--- === plugins.core.preferences.updates ===
---
--- Updates Module.

local require           = require

local hs                = _G.hs

--local log               = require "hs.logger" .new "updates"

local timer             = require "hs.timer"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local idle              = require "cp.idle"

local checkForUpdates   = hs.checkForUpdates
local doAfter           = timer.doAfter
local doEvery           = timer.doEvery

local mod = {}

--- plugins.core.preferences.updates.automaticallyCheckForUpdates <cp.prop: boolean>
--- Variable
--- Automatically check for updates?
mod.automaticallyCheckForUpdates = config.prop("automaticallyCheckForUpdates", true):watch(function(value)
    if value then
        --------------------------------------------------------------------------------
        -- Start update timer:
        --------------------------------------------------------------------------------
        if not mod.timer then
            mod.timer = doEvery(3600, function() -- Check every hour
                if not mod._alreadyInQueue then
                    idle.queue(30, function() -- Wait until the Mac is idle for 30 seconds
                        hs.checkForUpdates(true)
                        if hs.updateAvailable() then
                            doAfter(1, function()
                                checkForUpdates()
                            end)
                        end
                        mod._alreadyInQueue = false
                    end, false)
                    mod._alreadyInQueue = true
                end
            end):fire()
        end
    else
        --------------------------------------------------------------------------------
        -- Destroy update timer:
        --------------------------------------------------------------------------------
        if mod.timer then
            mod.timer:stop()
            mod.timer  = nil
        end
    end
end)

local plugin = {
    id              = "core.preferences.updates",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"]               = "menu",
        ["core.preferences.panels.general"] = "general",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- We don't want to do it automatically with Sparkle,
    -- we want to do it manually in Lua-land:
    --------------------------------------------------------------------------------
    hs.automaticallyCheckForUpdates(false)

    --------------------------------------------------------------------------------
    -- Add update info to menubar:
    --------------------------------------------------------------------------------
    local top = deps.menu.top
    top
        :addItem(0.00000000000000000000000000001, function()
            if hs.updateAvailable() then
                local version, build = hs.updateAvailable()
                return {
                    title   = i18n("updateAvailable") .. ": " .. version .. " (" .. build .. ")",
                    fn      = function() hs.focus(); checkForUpdates() end
                }
            end
        end)
        :addSeparator(2)

    --------------------------------------------------------------------------------
    -- General Preferences:
    --------------------------------------------------------------------------------
    local general = deps.general
    general
        :addCheckbox(4,
            {
                label       = i18n("automaticallyCheckForUpdates"),
                onchange    = function() mod.automaticallyCheckForUpdates:toggle() end,
                checked     = function() return mod.automaticallyCheckForUpdates() end,
                disabled    = function() return not hs.canCheckForUpdates() end,
            }
        )
        :addButton(5,
            {
                label   = i18n("checkForUpdatesNow"),
                width       = 200,
                onclick = function() checkForUpdates() end,
            }
        )

end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Check for updates when CommandPost first loads:
    --------------------------------------------------------------------------------
    if mod.automaticallyCheckForUpdates() then
        hs.checkForUpdates(true)
    end

    --------------------------------------------------------------------------------
    -- Setup update timer:
    --------------------------------------------------------------------------------
    mod.automaticallyCheckForUpdates:update()
end

return plugin
