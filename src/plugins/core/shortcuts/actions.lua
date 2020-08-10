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
local pressSystemKey    = tools.pressSystemKey

local event             = eventtap.event

local newKeyEvent       = event.newKeyEvent

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

        --------------------------------------------------------------------------------
        -- Press & Hold CONTROL:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("pressAndHold") .. " CONTROL " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "pressControl",
                id = "global_shortcuts_pressControl"
            })
            :id("global_shortcuts_pressControl")

        choices
            :add(i18n("release") .. " CONTROL " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "releaseControl",
                id = "global_shortcuts_releaseControl"
            })
            :id("global_shortcuts_releaseControl")

        --------------------------------------------------------------------------------
        -- Press & Hold OPTION:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("pressAndHold") .. " OPTION " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "pressOption",
                id = "global_shortcuts_pressOption"
            })
            :id("global_shortcuts_pressOption")

        choices
            :add(i18n("release") .. " OPTION " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "releaseOption",
                id = "global_shortcuts_releaseOption"
            })
            :id("global_shortcuts_releaseOption")


        --------------------------------------------------------------------------------
        -- Press & Hold COMMAND:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("pressAndHold") .. " COMMAND " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "pressCommand",
                id = "global_shortcuts_pressCommand"
            })
            :id("global_shortcuts_pressCommand")

        choices
            :add(i18n("release") .. " COMMAND " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "releaseCommand",
                id = "global_shortcuts_releaseCommand"
            })
            :id("global_shortcuts_releaseCommand")

        --------------------------------------------------------------------------------
        -- Press & Hold SHIFT:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("pressAndHold") .. " SHIFT " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "pressShift",
                id = "global_shortcuts_pressShift"
            })
            :id("global_shortcuts_pressShift")

        choices
            :add(i18n("release") .. " SHIFT " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "releaseShift",
                id = "global_shortcuts_releaseShift"
            })
            :id("global_shortcuts_releaseShift")

        --------------------------------------------------------------------------------
        -- Press & Hold TILDA:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("pressAndHold") .. " TILDA")
            :subText(description)
            :params({
                action = "pressTilda",
                id = "global_shortcuts_pressTilda"
            })
            :id("global_shortcuts_pressTilda")

        choices
            :add(i18n("release") .. " TILDA")
            :subText(description)
            :params({
                action = "releaseTilda",
                id = "global_shortcuts_releaseTilda"
            })
            :id("global_shortcuts_releaseTilda")

        --------------------------------------------------------------------------------
        -- Play:
        --------------------------------------------------------------------------------
        choices
            :add("Play")
            :subText(description)
            :params({
                action = "systemKey",
                key = "PLAY",
                id = "global_shortcuts_play"
            })
            :id("global_shortcuts_play")

        --------------------------------------------------------------------------------
        -- Next:
        --------------------------------------------------------------------------------
        choices
            :add("Next")
            :subText(description)
            :params({
                action = "systemKey",
                key = "NEXT",
                id = "global_shortcuts_next"
            })
            :id("global_shortcuts_next")

        --------------------------------------------------------------------------------
        -- Previous:
        --------------------------------------------------------------------------------
        choices
            :add("Previous")
            :subText(description)
            :params({
                action = "systemKey",
                key = "PREVIOUS",
                id = "global_shortcuts_previous"
            })
            :id("global_shortcuts_previous")

        --------------------------------------------------------------------------------
        -- Fast:
        --------------------------------------------------------------------------------
        choices
            :add("Fast")
            :subText(description)
            :params({
                action = "systemKey",
                key = "FAST",
                id = "global_shortcuts_fast"
            })
            :id("global_shortcuts_fast")

        --------------------------------------------------------------------------------
        -- Rewind:
        --------------------------------------------------------------------------------
        choices
            :add("Rewind")
            :subText(description)
            :params({
                action = "systemKey",
                key = "REWIND",
                id = "global_shortcuts_rewind"

            })
            :id("global_shortcuts_rewind")

        end)
        :onExecute(function(action)
            if not action.action then
                keyStroke(action.modifiers, action.character)
            elseif action.action == "systemKey" then
                pressSystemKey(action.key)
            elseif action.action == "pressTilda" then
                newKeyEvent("`", true):post()
            elseif action.action == "releaseTilda" then
                newKeyEvent("`", false):post()
            elseif action.action == "pressControl" then
                mod.holdDownControl = eventtap.new({eventtap.event.types.keyDown}, function(e)
                    local flags = e:getFlags()
                    flags.control = true
                    e:setFlags(flags)
                    return false, e
                end):start()
            elseif action.action == "releaseControl" then
                mod.holdDownControl:stop()
                mod.holdDownControl = nil
            elseif action.action == "pressOption" then
                mod.holdDownOption = eventtap.new({eventtap.event.types.keyDown}, function(e)
                    local flags = e:getFlags()
                    flags.option = true
                    e:setFlags(flags)
                    return false, e
                end):start()
            elseif action.action == "releaseOption" then
                mod.holdDownOption:stop()
                mod.holdDownOption = nil
            elseif action.action == "pressCommand" then
                mod.holdDownCommand = eventtap.new({eventtap.event.types.keyDown}, function(e)
                    local flags = e:getFlags()
                    flags.command = true
                    e:setFlags(flags)
                    return false, e
                end):start()
            elseif action.action == "releaseCommand" then
                mod.holdDownCommand:stop()
                mod.holdDownCommand = nil
            elseif action.action == "pressShift" then
                mod.holdDownShift = eventtap.new({eventtap.event.types.keyDown}, function(e)
                    local flags = e:getFlags()
                    flags.shift = true
                    e:setFlags(flags)
                    return false, e
                end):start()
            elseif action.action == "releaseShift" then
                mod.holdDownShift:stop()
                mod.holdDownShift = nil
            end
        end)
        :onActionId(function(params)
            return "global_shortcuts_" .. params.id
        end)
    return mod
end

return plugin