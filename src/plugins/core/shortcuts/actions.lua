--- === plugins.core.shortcuts.actions ===
---
--- Adds actions which allow you to trigger keyboard shortcuts.

local require           = require

--local log               = require "hs.logger".new "actions"

local eventtap          = require "hs.eventtap"
local keycodes          = require "hs.keycodes"

local i18n              = require "cp.i18n"

local keyStroke         = eventtap.keyStroke

local mod = {}

local plugin = {
    id              = "core.shortcuts.actions",
    group           = "core",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Handler:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_shortcuts", "global")
        :onChoices(function(choices)
            local modifiers = {
                { label = "⌘", mods = {"cmd"} },
                { label = "⇧⌘", mods = {"shift", "cmd"} },
                { label = "⌥⇧⌘", mods = {"alt", "shift", "cmd"} },
                { label = "⌃⌥⇧⌘", mods = {"ctrl", "alt", "shift", "cmd"} },
                { label = "⌃⇧⌘", mods = {"ctrl", "shift", "cmd"} },
                { label = "⌥⌘", mods = {"alt", "cmd"} },
                { label = "⌃⌥⌘", mods = {"ctrl", "alt", "cmd"} },
                { label = "⌃⌘", mods = {"ctrl", "cmd"} },
                { label = "⇧", mods = {"shift"} },
                { label = "⌥⇧", mods = {"alt", "shift"} },
                { label = "⌃⌥⇧", mods = {"ctrl", "alt", "shift"} },
                { label = "⌃⇧", mods = {"ctrl", "shift"} },
                { label = "⌥", mods = {"alt"} },
                { label = "⌃⌥", mods = {"ctrl", "alt"} },
                { label = "⌃", mods = {"ctrl"} },
            }
            local pressLabel = i18n("press")
            local andLabel = i18n("and")
            local description = i18n("keyboardShortcutDescription")
            for keycode, _ in pairs(keycodes.map) do
                if type(keycode) == "string"
                and keycode ~= ""
                and keycode ~= "" -- I actually have no idea what this character is, but just shows blank in the Search Console.
                and keycode ~= "cmd" and keycode ~= "rightcmd"
                and keycode ~= "shift" and keycode ~= "rightshift"
                and keycode ~= "alt" and keycode ~= "rightalt"
                and keycode ~= "ctrl" and keycode ~= "rightctrl"
                then
                    for _, modifier in pairs(modifiers) do
                        choices
                            :add(pressLabel .. " " .. modifier.label .. " " .. andLabel .. " " .. string.upper(keycode))
                            :subText(description)
                            :params({
                                character = keycode,
                                modifiers = modifier.mods,
                                id = modifier.label .. "_" .. keycode,
                            })
                            :id("global_shortcuts_" .. modifier.label .. "_" .. keycode)
                    end
                end
            end
        end)
        :onExecute(function(action)
            keyStroke(action.modifiers, action.character)
        end)
        :onActionId(function(params)
            return "global_shortcuts_" .. params.id
        end)
    return mod
end

return plugin