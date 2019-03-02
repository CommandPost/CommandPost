--- === plugins.finder.preferences.panel ===
---
--- General Preferences Panel

local require = require

local image         = require("hs.image")

local i18n          = require("cp.i18n")
local tools         = require("cp.tools")

local iconFallback  = tools.iconFallback
local imageFromPath = image.imageFromPath

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finder.preferences.panel",
    group           = "finder",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    return deps.manager.addPanel({
        priority    = 2010,
        id          = "finder",
        label       = i18n("finder"),
        image       = imageFromPath(iconFallback("/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns")),
        tooltip     = i18n("finder"),
        height      = 240,
    })
end

return plugin