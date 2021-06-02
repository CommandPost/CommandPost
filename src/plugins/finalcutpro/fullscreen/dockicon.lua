--- === plugins.finalcutpro.fullscreen.dockicon ===
---
--- Manages the CommandPost dock icon when FCP is full-screen.
--- [Due to some quirkiness](https://github.com/Hammerspoon/hammerspoon/issues/1184)
--- in how macOS manages full-screen windows, it seems that we need to make
--- CP 'dockless' when an app we are working with goes full-screen. Otherwise
--- our drawing/canvas images will not display correctly.

local require       = require

--local log           = require "hs.logger".new "dockicon"

local hs            = _G.hs

local timer         = require "hs.timer"
local window        = require "hs.window"

local app           = require "cp.app"
local config        = require "cp.config"
local fcp           = require "cp.apple.finalcutpro"
local prop          = require "cp.prop"

local doAfter       = timer.doAfter

local mod = {}

--- plugins.finalcutpro.fullscreen.dockicon.dockIconEnabled <cp.prop: boolean; read-only; live>
--- Variable
--- If `true` the CommandPost dock icon should be hidden.
mod.dockIconEnabled = prop(
    function()
        return hs.dockIcon()
    end,
    function(enabled)
        --------------------------------------------------------------------------------
        -- Ignore if the Dock Icon is already hidden:
        --------------------------------------------------------------------------------
        if not config.get("dockIcon", true) then return end

        --------------------------------------------------------------------------------
        -- Ignore if we're mid-change:
        --------------------------------------------------------------------------------
        if mod._working then return end

        --------------------------------------------------------------------------------
        -- Setting the dockIcon makes CommandPost the 'focused' app,
        -- so this is a workaround:
        --------------------------------------------------------------------------------
        mod._working = true
        local focusedWindow = window.focusedWindow()
        hs.dockIcon(enabled)

        if focusedWindow then
            doAfter(0.3, function()
                focusedWindow:focus()
                mod._working = false
            end)
        else
            mod._working = false
        end
    end
)

--- plugins.finalcutpro.fullscreen.dockicon.fcpActiveFullScreen <cp.prop: boolean; read-only; live>
--- Variable
--- If `true` FCP is full-screen and the frontmost app.
mod.fcpActiveFullScreen = fcp.primaryWindow.isFullScreen:AND(app.frontmostApp:IS(fcp.app))
:bind(mod, "fcpActiveFullScreen")
:watch(function(fullScreen)
    mod.dockIconEnabled(not fullScreen)
end)

local plugin = {
    id              = "finalcutpro.fullscreen.dockicon",
    group           = "finalcutpro",
}

function plugin.init()
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Update Dock Icon:
    --------------------------------------------------------------------------------
    if mod.dockIconEnabled then
        mod.dockIconEnabled:update()
    end
end

return plugin
