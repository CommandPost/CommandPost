--- === plugins.core.shortcuts.actions ===
---
--- Adds actions which allow you to trigger keyboard shortcuts.

local require           = require

--local log               = require "hs.logger".new "actions"

local eventtap          = require "hs.eventtap"
local keycodes          = require "hs.keycodes"

local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local keyStroke         = tools.keyStroke

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
                { label = "R⇧⌘", mods = {"rightshift", "cmd"} },
                { label = "⌥R⇧⌘", mods = {"alt", "rightshift", "cmd"} },
                { label = "⌃⌥R⇧⌘", mods = {"ctrl", "alt", "rightshift", "cmd"} },
                { label = "⌃R⇧⌘", mods = {"ctrl", "rightshift", "cmd"} },
                { label = "R⇧", mods = {"rightshift"} },
                { label = "⌥R⇧", mods = {"alt", "rightshift"} },
                { label = "⌃⌥R⇧", mods = {"ctrl", "alt", "rightshift"} },
                { label = "⌃R⇧", mods = {"ctrl", "rightshift"} },
                { label = "Fn⌘", mods = {"cmd", "fn"} },
                { label = "Fn⇧⌘", mods = {"shift", "cmd", "fn"} },
                { label = "Fn⌥⇧⌘", mods = {"alt", "shift", "cmd", "fn"} },
                { label = "Fn⌃⌥⇧⌘", mods = {"ctrl", "alt", "shift", "cmd", "fn"} },
                { label = "Fn⌃⇧⌘", mods = {"ctrl", "shift", "cmd", "fn"} },
                { label = "Fn⌥⌘", mods = {"alt", "cmd", "fn"} },
                { label = "Fn⌃⌥⌘", mods = {"ctrl", "alt", "cmd", "fn"} },
                { label = "Fn⌃⌘", mods = {"ctrl", "cmd", "fn"} },
                { label = "Fn⇧", mods = {"shift", "fn"} },
                { label = "Fn⌥⇧", mods = {"alt", "shift", "fn"} },
                { label = "Fn⌃⌥⇧", mods = {"ctrl", "alt", "shift", "fn"} },
                { label = "Fn⌃⇧", mods = {"ctrl", "shift", "fn"} },
                { label = "Fn⌥", mods = {"alt", "fn"} },
                { label = "Fn⌃⌥", mods = {"ctrl", "alt", "fn"} },
                { label = "Fn⌃", mods = {"ctrl", "fn"} },
                { label = "Fn", mods = {"fn"} },
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
                    --------------------------------------------------------------------------------
                    -- No Modifier:
                    --------------------------------------------------------------------------------
                    choices
                        :add(string.upper(keycode))
                        :subText(description)
                        :params({
                            character = keycode,
                            modifiers = {},
                            id = keycode,
                        })
                        :id("global_shortcuts_" .. keycode)

                    --------------------------------------------------------------------------------
                    -- With Modifier(s):
                    --------------------------------------------------------------------------------
                    for _, modifier in pairs(modifiers) do
                        choices
                            :add(string.upper(keycode) .. " + " .. modifier.label)
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

        choices
            :add("Press and hold SHIFT modifier key")
            :subText(description)
            :params({
                id = "pressShift",
            })
            :id("global_shortcuts_" .. "pressShift")

        choices
            :add("Release SHIFT modifier key")
            :subText(description)
            :params({
                id = "releaseShift",
            })
            :id("global_shortcuts_" .. "releaseShift")

        end)
        :onExecute(function(action)
            if action.id == "pressShift" then
                mod.holdDownShift = eventtap.new({eventtap.event.types.keyDown}, function(e)
                    local flags = e:getFlags()
                    flags.shift = true
                    e:setFlags(flags)
                    return false, e
                end):start()
            elseif action.id == "releaseShift" then
                mod.holdDownShift:stop()
                mod.holdDownShift = nil
            else
                keyStroke(action.modifiers, action.character)
            end
        end)
        :onActionId(function(params)
            return "global_shortcuts_" .. params.id
        end)
    return mod
end

return plugin