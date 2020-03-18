--- === plugins.core.preferences.panels.scripting ===
---
--- General Preferences Panel

local require = require

local image         = require "hs.image"

local i18n          = require "cp.i18n"
local tools         = require "cp.tools"
local config        = require "cp.config"

local iconFallback  = tools.iconFallback
local imageFromPath = image.imageFromPath

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
        image       = imageFromPath(config.bundledPluginsPath .. "/core/preferences/panels/images/SEScriptEditorX.icns"),
        tooltip     = i18n("scripting"),
        height      = 220,
    })
end

return plugin