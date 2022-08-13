--- === plugins.core.macosshortcuts ===
---
--- Adds actions for macOS Monterey Shortcuts.

local require           = require

local hs                = _G.hs

local log               = require "hs.logger".new "macosshortcuts"

local shortcuts         = require "hs.shortcuts"
local image             = require "hs.image"

local tools             = require "cp.tools"
local config            = require "cp.config"
local i18n              = require "cp.i18n"

local semver            = require "semver"

local execute           = hs.execute
local imageFromPath     = image.imageFromPath

local mod = {}

local plugin = {
    id              = "core.macosshortcuts",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "preferencesManager",
        ["core.action.manager"]         = "actionmanager",
        ["core.setup"]                  = "setup",
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

    mod.enabled = config.prop("macosshortcuts.enabled", false)

    --------------------------------------------------------------------------------
    -- Setup Screen:
    --------------------------------------------------------------------------------
    local iconPath = config.basePath .. "/plugins/core/macosshortcuts/images/Shortcuts.icns"
    local setup = deps.setup
    local panel = setup.panel.new("macosshortcuts", 10.2)
        :addIcon(iconPath)
        :addParagraph(i18n("macosShortcutsSetupMessage"), false)
        :addButton({
            label       = i18n("enableShortcuts"),
            onclick     = function()
                --------------------------------------------------------------------------------
                -- This will trigger an Accessibility Popup if it's the first time we're
                -- requesting permission:
                --------------------------------------------------------------------------------
                shortcuts.list()
                mod.enabled(true)
                setup.nextPanel()
            end,
        })
        :addButton({
            label       = i18n("disableShortcuts"),
            onclick     = function()
                mod.enabled(false)
                setup.nextPanel()
            end,
        })
    if setup.onboardingRequired() then
        setup.addPanel(panel)
        setup.show()
    end

    --------------------------------------------------------------------------------
    -- Setup Action Handler:
    --------------------------------------------------------------------------------
    local preferencesManager = deps.preferencesManager
    local icon = imageFromPath(iconPath)
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_macosshortcuts", "global")
        :onChoices(function(choices)
            if mod.enabled() then
                local shortcutsList = shortcuts.list()
                local description = i18n("macOSShortcutsDescriptions")
                for _, item in pairs(shortcutsList) do
                    choices
                        :add(item.name)
                        :subText(description)
                        :params({
                            name = item.name,
                            id = item.id,
                        })
                        :id("global_macosshortcuts_" .. item.name)
                        :image(icon)
                end
            else
                choices
                    :add(i18n("macOSShortcutsDisabledSearchConsoleMessage"))
                    :subText(i18n("macOSShortcutsDisabledSearchConsoleMessageTwo"))
                    :params({
                        action = "openPreferences"
                    })
                    :id("global_macosshortcuts_disabled")
                    :image(icon)
            end
        end)
        :onExecute(function(action)
            if action.action == "openPreferences" then
                preferencesManager.show("macosshortcuts")
            else
                local name = action.name
                if name then
                    shortcuts.run(name)
                end
            end
        end)
        :onActionId(function(params)
            return "global_macosshortcuts_" .. (params.name or "disabled")
        end)

    --------------------------------------------------------------------------------
    -- Reset the handler if we enable/disable Shortcuts support:
    --------------------------------------------------------------------------------
    mod.enabled:watch(function()
        mod._handler:reset(true)
    end)

    return mod
end

return plugin
