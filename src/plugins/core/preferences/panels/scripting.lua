--- === plugins.core.preferences.panels.scripting ===
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
    id              = "core.preferences.panels.scripting",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    return deps.manager.addPanel({
        priority    = 2045,
        id          = "scripting",
        label       = i18n("scripting"),
        image       = imageFromPath(iconFallback("/Applications/Utilities/Script Editor.app/Contents/Resources/SEScriptEditorX.icns")),
        tooltip     = i18n("scripting"),
        height      = 220,
    })
end

return plugin