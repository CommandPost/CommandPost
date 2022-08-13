--- === plugins.core.macosshortcuts.preferences ===
---
--- macOS Shortcuts Preferences Panel

local require           = require

local hs                = _G.hs

local image             = require "hs.image"
local shortcuts         = require "hs.shortcuts"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local semver            = require "semver"

local execute           = hs.execute
local imageFromPath     = image.imageFromPath

local plugin = {
    id              = "core.macosshortcuts.preferences",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
        ["core.macosshortcuts"]         = "macosshortcuts",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Shortcuts support requires macOS Monterey:
    --------------------------------------------------------------------------------
    local macOSVersion = semver(tools.macOSVersion())
    local macOSMonterey = semver("12.0.0")
    if macOSVersion < macOSMonterey then
        return
    end

    local macosshortcuts = deps.macosshortcuts

    local panel = deps.manager.addPanel({
        priority    = 2049.1,
        id          = "macosshortcuts",
        label       = i18n("shortcuts"),
        image       = imageFromPath(config.basePath .. "/plugins/core/macosshortcuts/images/Shortcuts.icns"),
        tooltip     = i18n("macOSShortcuts"),
        height      = 260,
    })

    panel
        :addHeading(1, i18n("macOSShortcuts"))
        :addParagraph(2, i18n("macOSShortcutsPreferencesPanelDescription"), false)
        :addParagraph(2.1, "<br />", false)
        :addCheckbox(3,
            {
                label       = i18n("enableMacOSShortcutsSupport"),
                checked     = macosshortcuts.enabled,
                onchange    = function(enabled)
                    if enabled then
                        --------------------------------------------------------------------------------
                        -- This will trigger an Accessibility Popup if it's the first time we're
                        -- requesting permission:
                        --------------------------------------------------------------------------------
                        shortcuts.list()
                    end
                    macosshortcuts.enabled:toggle()
                end,
            }
        )
        :addParagraph(3.1, "<br />", false)
        :addButton(4,
            {
                label 	    = i18n("openSystemPreferences"),
                width       = 200,
                onclick	    = function()
                    --------------------------------------------------------------------------------
                    -- This will trigger an Accessibility Popup if it's the first time we're
                    -- requesting permission:
                    --------------------------------------------------------------------------------
                    shortcuts.list()

                    execute([[open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"]])
                end,
            }
        )

    return panel
end

return plugin
