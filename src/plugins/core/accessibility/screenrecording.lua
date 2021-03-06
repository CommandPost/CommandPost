--- === plugins.core.accessibility.screenrecording ===
---
--- Screen Recording Permission.

local require           = require

local hs                = _G.hs

--local log               = require "hs.logger".new "screenrecording"

local application       = require "hs.application"
local timer             = require "hs.timer"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local doAfter           = timer.doAfter
local doEvery           = timer.doEvery
local execute           = hs.execute

local mod = {}

local plugin = {
    id              = "core.accessibility.screenrecording",
    group           = "core",
    required        = true,
    dependencies    = {
        ["core.setup"]  = "setup",
    }
}

function plugin.init(deps)
    mod.setup = deps.setup
    mod.panel = mod.setup.panel.new("screenrecording", 10.1)
        :addIcon(tools.iconFallback(config.basePath .. "/plugins/core/accessibility/images/Displays.icns"))
        :addParagraph(i18n("screenRecordingNote"), false)
        :addButton({
            label       = i18n("allowScreenRecording"),
            onclick     = function()
                hs.screenRecordingState(true)
                doAfter(3, function()
                    if not application.get("System Preferences") then
                        execute([[open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"]])
                    end
                end)
            end,
        })
        :addButton({
            label       = i18n("quit"),
            onclick     = function() config.application():kill() end,
        })
    if not hs.screenRecordingState() then
        mod.setup.addPanel(mod.panel)
        mod.setup.show()
        mod.timer = doEvery(0.1, function()
            if hs.screenRecordingState() then
                --------------------------------------------------------------------------------
                -- Screen recording was disabled, but now it's enabled,
                -- so we need to restart CommandPost:
                --------------------------------------------------------------------------------
                doAfter(3, function()
                    hs.relaunch()
                end)
            end
        end)
    end
    return mod
end

return plugin