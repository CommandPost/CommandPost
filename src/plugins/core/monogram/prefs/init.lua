--- === plugins.core.monogram.prefs ===
---
--- Monogram Preferences Panel

local require           = require

--local log               = require "hs.logger".new "audioSwift"

local image             = require "hs.image"

local i18n              = require "cp.i18n"
local html              = require "cp.web.html"

local imageFromPath     = image.imageFromPath
local execute           = _G.hs.execute

local mod = {}

local plugin = {
    id              = "core.monogram.prefs",
    group           = "core",
    dependencies    = {
        ["core.monogram.manager"]           = "monogram",
        ["core.controlsurfaces.manager"]    = "manager",

    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    local manager = deps.manager
    local monogram = deps.monogram

    manager.addPanel({
        priority        = 9010,
        id              = "monogram",
        label           = i18n("monogram"),
        image           = imageFromPath(env:pathToAbsolute("/images/Monogram.icns")),
        tooltip         = i18n("monogram"),
        height          = 210,
    })
        :addContent(1, html.style ([[
                .buttonOne {
                    float:left;
                    width: 192px;
                }
                .buttonTwo {
                    float:left;
                    margin-left: 5px;
                    width: 192px;
                }
            ]], true))
        :addHeading(2, "Monogram Support")
        :addCheckbox(3,
            {
                label = "Enable Monogram Support",
                onchange = function(_, params) monogram.enabled(params.checked) end,
                checked = monogram.enabled,

            }
        )
        :addParagraph(4, html.br())
        :addButton(5,
            {
                label 	    = "Open Monogram Creator",
                onclick	    = function() monogram.launchCreatorBundle() end,
                class       = "buttonOne",
            }
        )
        :addButton(6,
            {
                label 	    = "Download Monogram Creator",
                onclick	    = function() execute([[open https://monogramcc.com/download]]) end,
                class       = "buttonTwo",
            }
        )

    return mod
end

return plugin