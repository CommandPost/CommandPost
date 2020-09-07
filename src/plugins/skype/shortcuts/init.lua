--- === plugins.skype.shortcuts ===
---
--- Trigger Skype Shortcuts

local require                   = require

--local log                       = require "hs.logger".new "actions"

local application               = require "hs.application"
local image                     = require "hs.image"

local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local imageFromPath             = image.imageFromPath
local keyStroke                 = tools.keyStroke
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local playErrorSound            = tools.playErrorSound

local mod = {}

local plugin = {
    id              = "skype.shortcuts",
    group           = "skype",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Shortcuts:
    --
    -- TODO: This needs to be i18n'ified.
    --------------------------------------------------------------------------------
    local shortcuts = {
        {
            title = "Open app settings",
            modifiers = {"cmd"},
            character = ","
        },
        {
            title = "Open Help in default browser",
            modifiers = {"control"},
            character = "h"
        },
        {
            title = "Send feedback",
            modifiers = {"cmd", "option"},
            character = "o"
        },
        {
            title = "Open themes",
            modifiers = {"command"},
            character = "t"
        },
        {
            title = "Toggle between light and dark mode",
            modifiers = {"command", "shift"},
            character = "t"
        },
        {
            title = "Navigate to recent chats",
            modifiers = {"option"},
            character = "1"
        },
        {
            title = "Open Notification panel",
            modifiers = {"command", "shift"},
            character = "o"
        },
        {
            title = "Search for contacts, messages and bots",
            modifiers = {"command", "option"},
            character = "f"
        },
        {
            title = "Next Conversation",
            modifiers = {"control"},
            character = "tab"
        },
        {
            title = "Previous Conversation",
            modifiers = {"control", "shift"},
            character = "tab"
        },
        {
            title = "Zoom In",
            modifiers = {"command", "shift"},
            character = "+"
        },
        {
            title = "Zoom Out",
            modifiers = {"command"},
            character = "-"
        },
        {
            title = "View actual size",
            modifiers = {"command"},
            character = "0"
        },
        {
            title = "Start new conversation",
            modifiers = {"command"},
            character = "n"
        },
        {
            title = "New group chat",
            modifiers = {"command"},
            character = "g"
        },
        {
            title = "Open contacts",
            modifiers = {"command", "shift"},
            character = "c"
        },
        {
            title = "Show conversation profile",
            modifiers = {"command"},
            character = "i"
        },
        {
            title = "Add people to conversation",
            modifiers = {"command", "shift"},
            character = "a"
        },
        {
            title = "Send a file",
            modifiers = {"command", "shift"},
            character = "f"
        },
        {
            title = "Open gallery",
            modifiers = {"command", "shift"},
            character = "g"
        },
        {
            title = "Mark as unread",
            modifiers = {"command", "shift"},
            character = "u"
        },
        {
            title = "Focus Message Composer",
            modifiers = {"control", "shift"},
            character = "e"
        },
        {
            title = "Multi-select messages",
            modifiers = {"command", "shift"},
            character = "l"
        },
        {
            title = "Archive selected conversation",
            modifiers = {"command"},
            character = "e"
        },
        {
            title = "Search within current conversation",
            modifiers = {"command"},
            character = "f"
        },
        {
            title = "Answer incoming call",
            modifiers = {"command", "shift"},
            character = "r"
        },
        {
            title = "Hang up",
            modifiers = {"command", "shift"},
            character = "h"
        },
        {
            title = "Start video call",
            modifiers = {"command", "shift"},
            character = "k"
        },
        {
            title = "Start an audio call",
            modifiers = {"command", "shift"},
            character = "r"
        },
        {
            title = "Toggle mute",
            modifiers = {"command", "shift"},
            character = "m"
        },
        {
            title = "Toggle camera",
            modifiers = {"command", "shift"},
            character = "k"
        },
        {
            title = "Launch dial pad",
            modifiers = {"command"},
            character = "2"
        },
        {
            title = "Add people to call",
            modifiers = {"command", "shift"},
            character = "a"
        },
        {
            title = "Take a snapshot",
            modifiers = {"command"},
            character = "s"
        },
        {
            title = "Resize camera preview",
            modifiers = {"command", "shift"},
            character = "j"
        },
        {
            title = "Open the main Skype window",
            modifiers = {"command"},
            character = "1"
        },
        {
            title = "Edit the last message sent",
            modifiers = {"command", "shift"},
            character = "e"
        },
        {
            title = "Close windows (split view)",
            modifiers = {"command"},
            character = "w"
        },
    }

    --------------------------------------------------------------------------------
    -- Setup Handler:
    --------------------------------------------------------------------------------
    local icon = imageFromPath(config.basePath .. "/plugins/skype/console/images/shortcut.png")
    local actionmanager = deps.actionmanager
    local description = i18n("skypeShortcutDescription")
    mod._handler = actionmanager.addHandler("skype_shortcuts", "skype")
        :onChoices(function(choices)
            for _, v in pairs(shortcuts) do
                choices
                    :add(v.title)
                    :subText(description)
                    :params({
                        modifiers = v.modifiers,
                        character = v.character,
                        id = v.title
                    })
                    :image(icon)
                    :id("skype_shortcuts_" .. "pressControl")
            end
        end)
        :onExecute(function(action)
            if launchOrFocusByBundleID("com.skype.skype") then
                keyStroke(action.modifiers, action.character)
            else
                playErrorSound()
            end
        end)
        :onActionId(function(params)
            return "skype_shortcuts" .. params.id
        end)
    return mod
end

return plugin