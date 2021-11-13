--- === plugins.core.macosshortcuts ===
---
--- Adds actions for macOS Monterey Shortcuts.

local require           = require

--local log               = require "hs.logger".new "macosshortcuts"

local shortcuts         = require "hs.shortcuts"
local image             = require "hs.image"

local config            = require "cp.config"
local i18n              = require "cp.i18n"

local imageFromPath     = image.imageFromPath

local mod = {}

local plugin = {
    id              = "core.macosshortcuts",
    group           = "core",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Action Handler:
    --------------------------------------------------------------------------------
    local icon = imageFromPath(config.basePath .. "/plugins/core/macosshortcuts/images/Shortcuts.icns")
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_macosshortcuts", "global")
        :onChoices(function(choices)
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
        end)
        :onExecute(function(action)
            local name = action.name
            if name then
                shortcuts.run(name)
            end
        end)
        :onActionId(function(params)
            return "global_macosshortcuts_" .. params.name
        end)

    return mod
end

return plugin
