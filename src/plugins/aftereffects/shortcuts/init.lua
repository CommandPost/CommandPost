--- === plugins.aftereffects.shortcuts ===
---
--- Trigger After Effects Shortcuts

local require                   = require

--local log                       = require "hs.logger".new "actions"

local application               = require "hs.application"
local image                     = require "hs.image"

local ae                        = require "cp.adobe.aftereffects"
local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local imageFromPath             = image.imageFromPath
local keyStroke                 = tools.keyStroke
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local playErrorSound            = tools.playErrorSound

local mod = {}

local plugin = {
    id              = "aftereffects.shortcuts",
    group           = "aftereffects",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Handler:
    --------------------------------------------------------------------------------
    local bundleID = ae:bundleID()
    local icon = imageFromPath(config.basePath .. "/plugins/aftereffects/console/images/shortcut.png")
    local description = i18n("afterEffectsShortcutDescription")
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("aftereffects_shortcuts", "aftereffects")
        :onChoices(function(choices)
            local prefs = ae:shortcutsPreferences()
            for _, section in pairs(prefs) do
                for _, s in pairs(section) do
                    choices
                        :add(s.label)
                        :subText(description)
                        :params({
                            modifiers = s.modifiers,
                            character = s.character,
                            id = s.label,
                        })
                        :image(icon)
                        :id("aftereffects_shortcuts" .. s.label)
                end
            end
        end)
        :onExecute(function(action)
            if launchOrFocusByBundleID(bundleID) then
                keyStroke(action.modifiers, action.character)
            else
                playErrorSound()
            end
        end)
        :onActionId(function(params)
            return "aftereffects_shortcuts" .. params.id
        end)
    return mod
end

return plugin