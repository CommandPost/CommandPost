--- === plugins.core.tourbox.prefs ===
---
--- Tourbox Preferences Panel

local require           = require

--local log               = require "hs.logger".new "audioSwift"

local image             = require "hs.image"

local i18n              = require "cp.i18n"

local imageFromPath     = image.imageFromPath
local execute           = hs.execute

local mod = {}

local plugin = {
    id              = "core.tourbox.prefs",
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
        id              = "tourbox",
        label           = i18n("tourBox"),
        image           = imageFromPath(env:pathToAbsolute("/images/TourBox.icns")),
        tooltip         = i18n("tourBox"),
        height          = 240,
    })
        :addHeading(1, "TourBox Support")
        :addContent(2, [[<p style="padding-left:20px;">We are planning to add built-in TourBox support in a future beta.<br />
        <br />
        In the meantime, you can control CommandPost via keyboard shortcuts in TourBox Console.
        </p>]], false)
        :addButton(3,
            {
                label 	    = "Download TourBox Console",
                width       = 240,
                onclick	    = function() execute([[open https://www.tourboxtech.com/en/]]) end,
            }
        )

    return mod
end

return plugin