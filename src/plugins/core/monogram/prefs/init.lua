--- === plugins.core.monogram.prefs ===
---
--- Monogram Preferences Panel

local require           = require

--local log               = require "hs.logger".new "audioSwift"

local image             = require "hs.image"

local i18n              = require "cp.i18n"

local imageFromPath     = image.imageFromPath
local execute           = hs.execute

local mod = {}

local plugin = {
    id              = "core.monogram.prefs",
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
        priority        = 9010,
        id              = "monogram",
        label           = i18n("monogram"),
        image           = imageFromPath(env:pathToAbsolute("/images/Monogram.icns")),
        tooltip         = i18n("monogram"),
        height          = 240,
    })
        :addHeading(1, "Monogram/Palette Support")
        :addContent(2, [[<p style="padding-left:20px;">We are hoping to add built-in Monogram/Palette support in a future release.<br />
        <br />
        In the meantime, you can use MIDI commands and keyboard shortcuts to control CommandPost via Monogram Creator.
        </p>]], false)
        :addButton(3,
            {
                label 	    = "Download Monogram Creator",
                width       = 240,
                onclick	    = function() execute([[open https://monogramcc.com/download]]) end,
            }
        )

    return mod
end

return plugin