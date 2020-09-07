--- === plugins.aftereffects.preferences ===
---
--- After Effects Preferences Panel

local require               = require

local application           = require "hs.application"
local dialog                = require "hs.dialog"
local image                 = require "hs.image"
local osascript             = require "hs.osascript"

local ae                    = require "cp.adobe.aftereffects"
local config                = require "cp.config"
local html                  = require "cp.web.html"
local i18n                  = require "cp.i18n"

local applescript           = osascript.applescript
local imageFromPath         = image.imageFromPath
local infoForBundleID       = application.infoForBundleID
local webviewAlert          = dialog.webviewAlert

local mod = {}

-- scanEffects() -> none
-- Function
-- Scans After Effects to generate a list of installed effects.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function scanEffects()
    if not ae:allowScriptsToWriteFilesAndAccessNetwork() then
        webviewAlert(mod._manager.getWebview(), function() end, i18n("allowScriptsTurnedOff"), i18n("allowScriptsTurnedOffDescription"), i18n("ok"))
    else
        webviewAlert(mod._manager.getWebview(), function(result)
            if result == i18n("ok") then
                applescript([[
                    tell application id "]] .. ae:bundleID() .. [["
                        DoScriptFile "]] .. config.bundledPluginsPath .. [[/aftereffects/preferences/js/scaneffects.jsx"
                    end tell
                ]])
            end
        end, i18n("scanAfterEffectsDescription"), i18n("scanAfterEffectsDescriptionTwo"), i18n("ok"), i18n("cancel"))
    end
end

local plugin = {
    id              = "aftereffects.preferences",
    group           = "aftereffects",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    mod._manager = deps.manager
    local bundleID = ae:bundleID()
    if infoForBundleID(bundleID) then
        local panel = deps.manager.addPanel({
            priority    = 2041,
            id          = "aftereffects",
            label       = i18n("afterEffects"),
            image       = imageFromPath(config.bundledPluginsPath .. "/aftereffects/preferences/images/aftereffects.icns"),
            tooltip     = i18n("afterEffects"),
            height      = 230,
        })

        panel
            :addHeading(1, i18n("effects"))
            :addParagraph(2, html.span { class="tbTip" } ( i18n("effectsCacheDescription") .. "<br /><br />", false ).. "\n\n")
            :addButton(3,
                {
                    label 	    = "Scan Effects",
                    width       = 200,
                    onclick	    = scanEffects,
                }
            )
        return panel
    end
    return mod
end

return plugin
