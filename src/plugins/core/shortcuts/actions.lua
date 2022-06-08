--- === plugins.core.shortcuts.actions ===
---
--- Adds actions which allow you to trigger keyboard shortcuts.

local require           = require

local log               = require "hs.logger".new "actions"

local eventtap          = require "hs.eventtap"
local fnutils           = require "hs.fnutils"
local image             = require "hs.image"
local inspect           = require "hs.inspect"
local keycodes          = require "hs.keycodes"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local keyStroke         = tools.keyStroke
local pressSystemKey    = tools.pressSystemKey
local imageFromPath     = image.imageFromPath
local copy              = fnutils.copy

local event             = eventtap.event
local newKeyEvent       = event.newKeyEvent

local mod = {}

--- plugins.core.shortcuts.actions.heldKeys -> table
--- Variable
--- A table of held down modifier keys.
mod.heldKeys = {}

local plugin = {
    id              = "core.shortcuts.actions",
    group           = "core",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Apply any held key modifiers via an event tap:
    --------------------------------------------------------------------------------
    mod.eventtap = eventtap.new({eventtap.event.types.scrollWheel, eventtap.event.types.keyUp, eventtap.event.types.keyDown}, function(e)
        local flags = e:getFlags()

        local hasChanged = false

        if mod.heldKeys["control"] == true then
            hasChanged = true
            flags["ctrl"] = true
        end
        if mod.heldKeys["option"] == true then
            hasChanged = true
            flags[ "alt"] = true
        end

        if mod.heldKeys["command"] == true then
            hasChanged = true
            flags["cmd"] = true
        end
        if mod.heldKeys["shift"] == true then
            hasChanged = true
            flags["shift"] = true
        end

        e:setFlags(flags)

        if hasChanged then
            return false, {e}
        end
    end)

    local icon = imageFromPath(config.basePath .. "/plugins/core/console/images/Keyboard.icns")

    local holdKey = function(key, isDown)
        if isDown then
            mod.eventtap:start()
            mod.heldKeys[key] = true
        else
            mod.eventtap:stop()
            mod.heldKeys[key] = nil
        end
    end

    local pressKey = function(action)
        local m = copy(action.modifiers)

        --------------------------------------------------------------------------------
        -- Inject modifier keys, if they've already been held down by a hold action:
        --------------------------------------------------------------------------------
        if mod.heldKeys["control"] == true then table.insert(m, "ctrl") end
        if mod.heldKeys["option"] == true then table.insert(m, "alt") end
        if mod.heldKeys["command"] == true then table.insert(m, "cmd") end
        if mod.heldKeys["shift"] == true then table.insert(m, "shift") end

        keyStroke(m, action.character)
    end

    local actions = {
        pressKey            = function(action) pressKey(action) end,
        systemKey           = function(action) pressSystemKey(action.key) end,
        pressTilda          = function() newKeyEvent("`", true):post() end,
        releaseTilda        = function() newKeyEvent("`", false):post() end,
        pressControl        = function() holdKey("control", true) end,
        releaseControl      = function() holdKey("control", false) end,
        pressOption         = function() holdKey("option", true) end,
        releaseOption       = function() holdKey("option", false) end,
        pressCommand        = function() holdKey("command", true) end,
        releaseCommand      = function() holdKey("command", false) end,
        pressShift          = function() holdKey("shift", true) end,
        releaseShift        = function() holdKey("shift", false) end,
    }

    --------------------------------------------------------------------------------
    -- Setup Handler:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_shortcuts", "global")
        :onChoices(function(choices)
            local modifiers = {
                { description = "COMMAND",                                                  label = "⌘", mods = {"cmd"} },
                { description = "COMMAND and SHIFT",                                        label = "⇧⌘", mods = {"shift", "cmd"} },
                { description = "OPTION and COMMAND and SHIFT",                             label = "⌥⇧⌘", mods = {"alt", "shift", "cmd"} },
                { description = "CONTROL and OPTION and COMMAND and SHIFT",                 label = "⌃⌥⇧⌘", mods = {"ctrl", "alt", "shift", "cmd"} },
                { description = "CONTROL and COMMAND and SHIFT",                            label = "⌃⇧⌘", mods = {"ctrl", "shift", "cmd"} },
                { description = "OPTION and COMMAND",                                       label = "⌥⌘", mods = {"alt", "cmd"} },
                { description = "CONTROL and OPTION and COMMAND",                           label = "⌃⌥⌘", mods = {"ctrl", "alt", "cmd"} },
                { description = "CONTROL and COMMAND",                                      label = "⌃⌘", mods = {"ctrl", "cmd"} },
                { description = "SHIFT",                                                    label = "⇧", mods = {"shift"} },
                { description = "OPTION and SHIFT",                                         label = "⌥⇧", mods = {"alt", "shift"} },
                { description = "CONTROL and OPTION and SHIFT",                             label = "⌃⌥⇧", mods = {"ctrl", "alt", "shift"} },
                { description = "CONTROL and SHIFT",                                        label = "⌃⇧", mods = {"ctrl", "shift"} },
                { description = "OPTION",                                                   label = "⌥", mods = {"alt"} },
                { description = "CONTROL and OPTION",                                       label = "⌃⌥", mods = {"ctrl", "alt"} },
                { description = "CONTROL",                                                  label = "⌃", mods = {"ctrl"} },
                { description = "COMMAND and RIGHT SHIFT",                                  label = "R⇧⌘", mods = {"rightshift", "cmd"} },
                { description = "OPTION and COMMAND and RIGHT SHIFT",                       label = "⌥R⇧⌘", mods = {"alt", "rightshift", "cmd"} },
                { description = "CONTROL and OPTION and COMMAND and RIGHT SHIFT",           label = "⌃⌥R⇧⌘", mods = {"ctrl", "alt", "rightshift", "cmd"} },
                { description = "CONTROL and COMMAND and RIGHT SHIFT",                      label = "⌃R⇧⌘", mods = {"ctrl", "rightshift", "cmd"} },
                { description = "RIGHT SHIFT",                                              label = "R⇧", mods = {"rightshift"} },
                { description = "OPTION and RIGHT SHIFT",                                   label = "⌥R⇧", mods = {"alt", "rightshift"} },
                { description = "CONTROL and OPTION and RIGHT SHIFT",                       label = "⌃⌥R⇧", mods = {"ctrl", "alt", "rightshift"} },
                { description = "CONTROL and RIGHT SHIFT",                                  label = "⌃R⇧", mods = {"ctrl", "rightshift"} },
                { description = "COMMAND and FUNCTION",                                     label = "Fn⌘", mods = {"cmd", "fn"} },
                { description = "COMMAND and SHIFT and FUNCTION",                           label = "Fn⇧⌘", mods = {"shift", "cmd", "fn"} },
                { description = "OPTION and COMMAND and SHIFT and FUNCTION",                label = "Fn⌥⇧⌘", mods = {"alt", "shift", "cmd", "fn"} },
                { description = "CONTROL and OPTION and COMMAND and SHIFT and FUNCTION",    label = "Fn⌃⌥⇧⌘", mods = {"ctrl", "alt", "shift", "cmd", "fn"} },
                { description = "CONTROL and COMMAND and SHIFT and FUNCTION",               label = "Fn⌃⇧⌘", mods = {"ctrl", "shift", "cmd", "fn"} },
                { description = "OPTION and COMMAND and FUNCTION",                          label = "Fn⌥⌘", mods = {"alt", "cmd", "fn"} },
                { description = "CONTROL and OPTION and COMMAND and FUNCTION",              label = "Fn⌃⌥⌘", mods = {"ctrl", "alt", "cmd", "fn"} },
                { description = "CONTROL and COMMAND and FUNCTION",                         label = "Fn⌃⌘", mods = {"ctrl", "cmd", "fn"} },
                { description = "SHIFT and FUNCTION",                                       label = "Fn⇧", mods = {"shift", "fn"} },
                { description = "OPTION and SHIFT and FUNCTION",                            label = "Fn⌥⇧", mods = {"alt", "shift", "fn"} },
                { description = "CONTROL and OPTION and SHIFT and FUNCTION",                label = "Fn⌃⌥⇧", mods = {"ctrl", "alt", "shift", "fn"} },
                { description = "CONTROL and SHIFT and FUNCTION",                           label = "Fn⌃⇧", mods = {"ctrl", "shift", "fn"} },
                { description = "OPTION and FUNCTION",                                      label = "Fn⌥", mods = {"alt", "fn"} },
                { description = "CONTROL and OPTION and FUNCTION",                          label = "Fn⌃⌥", mods = {"ctrl", "alt", "fn"} },
                { description = "CONTROL and FUNCTION",                                     label = "Fn⌃", mods = {"ctrl", "fn"} },
                { description = "FUNCTION",                                                 label = "Fn", mods = {"fn"} },
            }
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
                        :image(icon)

                    --------------------------------------------------------------------------------
                    -- With Modifier(s):
                    --------------------------------------------------------------------------------
                    for _, modifier in pairs(modifiers) do
                        choices
                            :add(modifier.description .. " " .. i18n("and") .. " " .. keycode .. " (" .. modifier.label .. keycode .. ")")
                            :subText(description)
                            :params({
                                character = keycode,
                                modifiers = modifier.mods,
                                id = modifier.label .. "_" .. keycode,
                            })
                            :id("global_shortcuts_" .. modifier.label .. "_" .. keycode)
                            :image(icon)
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
            :image(icon)

        choices
            :add(i18n("release") .. " CONTROL " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "releaseControl",
                id = "global_shortcuts_releaseControl"
            })
            :id("global_shortcuts_releaseControl")
            :image(icon)

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
            :image(icon)

        choices
            :add(i18n("release") .. " OPTION " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "releaseOption",
                id = "global_shortcuts_releaseOption"
            })
            :id("global_shortcuts_releaseOption")
            :image(icon)


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
            :image(icon)

        choices
            :add(i18n("release") .. " COMMAND " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "releaseCommand",
                id = "global_shortcuts_releaseCommand"
            })
            :id("global_shortcuts_releaseCommand")
            :image(icon)

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
            :image(icon)

        choices
            :add(i18n("release") .. " SHIFT " .. i18n("modifierKey"))
            :subText(description)
            :params({
                action = "releaseShift",
                id = "global_shortcuts_releaseShift"
            })
            :id("global_shortcuts_releaseShift")
            :image(icon)

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
            :image(icon)

        choices
            :add(i18n("release") .. " TILDA")
            :subText(description)
            :params({
                action = "releaseTilda",
                id = "global_shortcuts_releaseTilda"
            })
            :id("global_shortcuts_releaseTilda")
            :image(icon)

        --------------------------------------------------------------------------------
        -- Play:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("play"))
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
            :add(i18n("next"))
            :subText(description)
            :params({
                action = "systemKey",
                key = "NEXT",
                id = "global_shortcuts_next"
            })
            :id("global_shortcuts_next")
            :image(icon)

        --------------------------------------------------------------------------------
        -- Previous:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("previous"))
            :subText(description)
            :params({
                action = "systemKey",
                key = "PREVIOUS",
                id = "global_shortcuts_previous"
            })
            :id("global_shortcuts_previous")
            :image(icon)

        --------------------------------------------------------------------------------
        -- Fast:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("fast"))
            :subText(description)
            :params({
                action = "systemKey",
                key = "FAST",
                id = "global_shortcuts_fast"
            })
            :id("global_shortcuts_fast")
            :image(icon)

        --------------------------------------------------------------------------------
        -- Rewind:
        --------------------------------------------------------------------------------
        choices
            :add(i18n("rewind"))
            :subText(description)
            :params({
                action = "systemKey",
                key = "REWIND",
                id = "global_shortcuts_rewind"

            })
            :id("global_shortcuts_rewind")
            :image(icon)

        end)
        :onExecute(function(action)
            local whichAction = action.action
            if whichAction then
                local fn = actions[action.action]
                if fn then
                    fn(action)
                else
                    log.ef("Unknown action triggered in core.shortcuts.actions: %s", inspect(action))
                end
            else
                --------------------------------------------------------------------------------
                -- NOTE: This is only here for legacy reason (because we didn't have an "action"
                -- in the parameters originally.
                --------------------------------------------------------------------------------
                actions["pressKey"](action)
            end
        end)
        :onActionId(function(params)
            return "global_shortcuts_" .. params.id
        end)
    return mod
end

return plugin
