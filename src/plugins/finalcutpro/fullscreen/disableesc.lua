--- === plugins.finalcutpro.fullscreen.disableesc ===
---
--- Disables the ESC key when Final Cut Pro is in fullscreen mode.

local require           = require

--local log               = require "hs.logger".new "disableesc"

local eventtap          = require "hs.eventtap"
local keycodes          = require "hs.keycodes"

local app               = require "cp.app"
local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local escape            = keycodes.map.escape
local keyDown           = eventtap.event.types.keyDown
local playErrorSound    = tools.playErrorSound

local mod = {}

-- escWatcher -> hs.eventtap object
-- Variable
-- ESC key watcher
local escWatcher

-- fcpActiveFullScreen <cp.prop: boolean; read-only; live>
-- Variable
-- If `true` FCP is full-screen and the frontmost app.
local fcpActiveFullScreen = fcp.primaryWindow.isFullScreen:AND(app.frontmostApp:IS(fcp.app)):AND(fcp.isModalDialogOpen:IS(false))

-- checkForESC(enabled) -> none
-- Function
-- Sets up event tap that checks to see if
local function checkForESC(enabled)
    if mod.enabled() and enabled then
        if escWatcher == nil then
            escWatcher = eventtap.new({keyDown}, function(object)
                if object:getKeyCode() == escape then
                    playErrorSound()
                    return true
                end
            end):start()
        end
    else
        if escWatcher then
            escWatcher:stop()
            escWatcher = nil
        end
    end
end

--- plugins.finalcutpro.fullscreen.disableesc.enabled <cp.prop: boolean>
--- Variable
--- Is the Disable ESC Key Function enabled?
mod.enabled = config.prop("fcp.disableEscKey", false):watch(function(enabled)
    if enabled then
        fcpActiveFullScreen:watch(checkForESC)
        fcpActiveFullScreen:update()
    else
        fcpActiveFullScreen:unwatch(checkForESC)
        if escWatcher then
            escWatcher:stop()
            escWatcher  = nil
        end
    end
end)

local plugin = {
    id              = "finalcutpro.fullscreen.disableesc",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    if deps and deps.prefs and deps.prefs.panel then
        deps.prefs.panel
            --------------------------------------------------------------------------------
            -- Add Preferences Checkbox:
            --------------------------------------------------------------------------------
            :addCheckbox(1.2,
            {
                label = i18n("ignoreESCKeyWhenFinalCutProIsFullscreen"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = mod.enabled,
            }
        )
    end

    return mod
end

function plugin.postInit()
    if mod.enabled then
        mod.enabled:update()
    end
end

return plugin
