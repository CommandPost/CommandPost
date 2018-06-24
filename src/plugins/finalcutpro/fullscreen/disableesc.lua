--- === plugins.finalcutpro.fullscreen.disableesc ===
---
--- Disables the ESC key when Final Cut Pro is in fullscreen mode.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                               = require("hs.logger").new("disableesc")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap                          = require("hs.eventtap")
local keycodes                          = require("hs.keycodes")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local app                               = require("cp.app")
local config                            = require("cp.config")
local fcp                               = require("cp.apple.finalcutpro")
local tools                             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.fullscreen.disableesc.enabled <cp.prop: boolean>
--- Variable
--- Is the Disable ESC Key Function enabled?
mod.enabled = config.prop("fcp.disableEscKey", false)

--- plugins.finalcutpro.fullscreen.disableesc.fcpActiveFullScreen <cp.prop: boolean; read-only; live>
--- Variable
--- If `true` FCP is full-screen and the frontmost app.
mod.fcpActiveFullScreen = fcp:primaryWindow().isFullScreen:AND(app.frontmostApp:IS(fcp.app)):AND(fcp.isModalDialogOpen:IS(false))
:watch(function(enabled)
    if mod.enabled() and enabled then
        if mod._eventtap == nil then
            mod._eventtap = eventtap.new({eventtap.event.types.keyDown}, function(object)
                if object:getKeyCode() == keycodes.map.escape then
                    tools.playErrorSound()
                    return true
                end
            end):start()
        end
    else
        if mod._eventtap then
            mod._eventtap:stop()
            mod._eventtap  = nil
        end
    end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.fullscreen.disableesc",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.app"] = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

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

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    mod.fcpActiveFullScreen:update()
end

return plugin