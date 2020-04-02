--- === plugins.finder.audio ===
---
--- Actions for Audio Controls

local require       = require

--local log           = require "hs.logger".new("audio")

local osascript     = require "hs.osascript"

local i18n          = require "cp.i18n"

local applescript   = osascript.applescript

local plugin = {
    id              = "finder.audio",
    group           = "finder",
    dependencies    = {
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("increaseVolume")
        :whenActivated(function()
            applescript([[set volume output volume (output volume of (get volume settings) + 1)]])
        end)
        :titled(i18n("increase") .. " " .. i18n("volume"))

    global
        :add("decreaseVolume")
        :whenActivated(function()
            applescript([[set volume output volume (output volume of (get volume settings) - 1)]])
        end)
        :titled(i18n("decrease") .. " " .. i18n("volume"))

    global
        :add("muteVolume")
        :whenActivated(function()
            applescript([[osascript -e "set volume with output muted"]])
        end)
        :titled(i18n("mute") .. " " .. i18n("volume"))

    global
        :add("unmuteVolume")
        :whenActivated(function()
            applescript([[osascript -e "set volume without output muted"]])
        end)
        :titled(i18n("unmute") .. " " .. i18n("volume"))

    global
        :add("toggleMuteVolume")
        :whenActivated(function()
            applescript([[
                if output muted of (get volume settings) is false then
                    set volume with output muted
                else
                    set volume without output muted
                end
            ]])
        end)
        :titled(i18n("toggle") .. " " .. i18n("mute") .. " " .. i18n("volume"))

end

return plugin
