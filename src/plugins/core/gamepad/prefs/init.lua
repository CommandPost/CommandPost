--- === plugins.core.gamepad.prefs ===
---
--- Gamepad Preferences Panel

local require           = require

--local log               = require "hs.logger".new "audioSwift"

local image             = require "hs.image"

local i18n              = require "cp.i18n"

local imageFromPath     = image.imageFromPath
local execute           = hs.execute

local mod = {}

local plugin = {
    id              = "core.gamepad.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]    = "manager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._manager        = deps.manager

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 9005,
        id              = "gamepad",
        label           = i18n("gamepad"),
        image           = imageFromPath(env:pathToAbsolute("/images/Gamepad.icns")),
        tooltip         = i18n("gamepad"),
        height          = 240,
    })
        :addHeading(1, "Gamepad Support")

        :addContent(2, [[<p style="padding-left:20px;">We are planning to add built-in Gamepad support in a future release.<br />
        <br />
        In the meantime, you can use the free <strong>Enjoyable</strong> app to assign virtual keyboard presses to Gamepad controllers.
        </p>]], false)
        :addButton(3,
            {
                label 	    = "Download Enjoyable",
                width       = 240,
                onclick	    = function() execute([[open https://yukkurigames.com/enjoyable/]]) end,
            }
        )

    return mod
end

return plugin