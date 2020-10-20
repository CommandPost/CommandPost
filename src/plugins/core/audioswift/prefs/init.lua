--- === plugins.core.audioswift.prefs ===
---
--- AudioSwift Preferences Panel

local require           = require

--local log               = require "hs.logger".new "audioSwift"

local image             = require "hs.image"

local i18n              = require "cp.i18n"

local imageFromPath     = image.imageFromPath
local execute           = _G.hs.execute

local mod = {}

local plugin = {
    id              = "core.audioswift.prefs",
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
        priority        = 9000,
        id              = "audioswift",
        label           = i18n("audioSwift"),
        image           = imageFromPath(env:pathToAbsolute("/images/AudioSwift.icns")),
        tooltip         = i18n("audioSwift"),
        height          = 265,
    })
        :addHeading(1, i18n("audioSwift"))

        :addContent(2, [[<p style="padding-left:20px;">]] .. i18n("audioSwiftDescriptionOne") .. [[<br />
        <br />
        ]] .. i18n("audioSwiftDescriptionTwo") .. [[<br />
        <br />
        ]] .. i18n("audioSwiftDescriptionThree") .. [[</p>]], false)
        :addButton(3,
            {
                label 	    = i18n("downloadAudioSwift"),
                width       = 240,
                onclick	    = function() execute([[open https://audioswiftapp.com]]) end,
            }
        )

    return mod
end

return plugin