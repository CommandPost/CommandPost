--- === plugins.core.console.keyboardmaestromacros ===
---
--- Adds Keyboard Maestro Macros to the Search Console.

local require               = require

--local log    			    = require "hs.logger".new "keyboardmaestromacros"

local image                 = require "hs.image"
local osascript             = require "hs.osascript"
local pathwatcher           = require "hs.pathwatcher"
local plist                 = require "hs.plist"

local config                = require "cp.config"

local applescript           = osascript.applescript
local imageFromPath         = image.imageFromPath

local mod = {}

local plugin = {
    id = "core.console.keyboardmaestromacros",
    group = "core",
    dependencies = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Handler:
    --------------------------------------------------------------------------------
    local preferencesPath = "~/Library/Application Support/Keyboard Maestro/Keyboard Maestro Macros.plist"
    local iconPath = config.basePath .. "/plugins/core/console/images/keyboardmaestro.icns"
    local icon = imageFromPath(iconPath)
    mod._handler = deps.actionmanager.addHandler("global_keyboardmaestro_macros", "global")
        :onChoices(function(choices)
            local prefs = plist.read(preferencesPath)
            local macroGroups = prefs and prefs.MacroGroups
            if macroGroups then
                for _, v in pairs(macroGroups) do
                    local groupName = v.Name
                    if v.Macros then
                        for _, vv in pairs(v.Macros) do
                            local name = vv.Name
                            local uid = vv.UID
                            if name and uid then
                                choices
                                    :add(name)
                                    :subText(groupName)
                                    :params({
                                        ["uid"] = uid,
                                    })
                                    :image(icon)
                                    :id("global_keyboardmaestro_macros_" .. uid)
                            end
                        end
                    end
                end
            end
        end)
        :onExecute(function(action)
            local uid = action.uid
            if uid then
                applescript([[tell application "Keyboard Maestro Engine"
                do script "]] .. uid .. [["
                end tell]])
            end
        end)
        :onActionId(function() return "global_keyboardmaestro_macros" end)

    --------------------------------------------------------------------------------
    -- Watch for changes:
    --------------------------------------------------------------------------------
    mod._watcher = pathwatcher.new(preferencesPath, function()
        mod._handler:reset()
    end):start()

    return mod
end

return plugin
