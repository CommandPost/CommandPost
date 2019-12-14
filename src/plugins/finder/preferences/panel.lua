--- === plugins.finder.preferences.panel ===
---
--- General Preferences Panel

local require       = require

local image         = require "hs.image"

local i18n          = require "cp.i18n"
local tools         = require "cp.tools"

local iconFallback  = tools.iconFallback
local imageFromPath = image.imageFromPath

local plugin = {
    id              = "finder.preferences.panel",
    group           = "finder",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    local panel = deps.manager.addPanel({
        priority    = 2010,
        id          = "finder",
        label       = i18n("finder"),
        image       = imageFromPath(iconFallback("/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns")),
        tooltip     = i18n("finder"),
        height      = 240,
    })

    --------------------------------------------------------------------------------
    -- Setup Separator:
    --------------------------------------------------------------------------------
    panel
        :addContent(0.1, [[
            <style>
                .menubarRow {
                    display: flex;
                }

                .menubarColumn {
                    flex: 50%;
                }
            </style>
            <div class="menubarRow">
                <div class="menubarColumn">
        ]], false)
        :addContent(500, [[
                </div>
                <div class="menubarColumn">
        ]], false)
        :addContent(9000, [[
                </div>
            </div>
        ]], false)

    return panel
end

return plugin