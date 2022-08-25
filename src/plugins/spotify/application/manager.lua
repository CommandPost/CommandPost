--- === plugins.spotify.application.manager ===
---
--- Registers Spotify with the Core Application Manager if installed.

local require                   = require

local application               = require "hs.application"
local image                     = require "hs.image"
local spotify                   = require "hs.spotify"

local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local imageFromPath             = image.imageFromPath
local infoForBundleID           = application.infoForBundleID
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local playErrorSound            = tools.playErrorSound

local mod = {}

local plugin = {
    id              = "spotify.application.manager",
    group           = "spotify",
    dependencies    = {
        ["core.application.manager"]        = "manager",
        ["core.action.manager"]             = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load if Spotify is installed:
    --------------------------------------------------------------------------------
    local bundleID = "com.spotify.client"
    if not infoForBundleID(bundleID) then return end

    --------------------------------------------------------------------------------
    -- Spotify Logo:
    --------------------------------------------------------------------------------
    local iconPath = config.basePath .. "/plugins/spotify/images/spotify.icns"
    local icon = imageFromPath(iconPath)

    --------------------------------------------------------------------------------
    -- Setup the default Search Console Toolbar for Spotify:
    --------------------------------------------------------------------------------
    local searchConsoleToolbar = {
        spotify_commands = { path = iconPath, priority = 1},
    }

    --------------------------------------------------------------------------------
    -- Register the Spotify Application:
    --------------------------------------------------------------------------------
    deps.manager.registerApplication({
        bundleID = bundleID,
        displayName = "Spotify",
        legacyGroupID = "spotify",
        searchConsoleToolbar = searchConsoleToolbar,
    })

    --------------------------------------------------------------------------------
    -- Setup Handler:
    --------------------------------------------------------------------------------
    local commands = {
        ["launch"] = {
            title = i18n("launch"),
            actionFn = function() launchOrFocusByBundleID(bundleID) end,
        },
        ["play"] = {
            title = i18n("play"),
            actionFn = function() spotify.play() end,
        },
        ["togglePlayPause"] = {
            title = i18n("togglePlayPause"),
            actionFn = function() spotify.playpause() end,
        },
        ["pause"] = {
            title = i18n("pause"),
            actionFn = function() spotify.pause() end,
        },
        ["previousTrack"] = {
            title = i18n("previousTrack"),
            actionFn = function() spotify.previous() end,
        },
        ["nextTrack"] = {
            title = i18n("nextTrack"),
            actionFn = function() spotify.next() end,
        },
        ["fastForwardFiveSeconds"] = {
            title = i18n("fastForwardFiveSeconds"),
            actionFn = function() spotify.ff() end,
        },
        ["rewindFiveSeconds"] = {
            title = i18n("rewindFiveSeconds"),
            actionFn = function() spotify.rw() end,
        },
        ["volumeUp5"] = {
            title = i18n("increaseVolumeBy") .. " 5",
            actionFn = function() spotify.setVolume(spotify.getVolume()+5) end,
        },
        ["volumeDown5"] = {
            title = i18n("decreaseVolumeBy") .. " 5",
            actionFn = function() spotify.setVolume(spotify.getVolume()-5) end,
        },
        ["volumeUp4"] = {
            title = i18n("increaseVolumeBy") .. " 4",
            actionFn = function() spotify.setVolume(spotify.getVolume()+4) end,
        },
        ["volumeDown4"] = {
            title = i18n("decreaseVolumeBy") .. " 4",
            actionFn = function() spotify.setVolume(spotify.getVolume()-4) end,
        },
        ["volumeUp3"] = {
            title = i18n("increaseVolumeBy") .. " 3",
            actionFn = function() spotify.setVolume(spotify.getVolume()+3) end,
        },
        ["volumeDown3"] = {
            title = i18n("decreaseVolumeBy") .. " 3",
            actionFn = function() spotify.setVolume(spotify.getVolume()-3) end,
        },
        ["volumeUp2"] = {
            title = i18n("increaseVolumeBy") .. " 2",
            actionFn = function() spotify.setVolume(spotify.getVolume()+2) end,
        },
        ["volumeDown2"] = {
            title = i18n("decreaseVolumeBy") .. " 2",
            actionFn = function() spotify.setVolume(spotify.getVolume()-2) end,
        },
        ["volumeUp1"] = {
            title = i18n("increaseVolumeBy") .. " 1",
            actionFn = function() spotify.setVolume(spotify.getVolume()+1) end,
        },
        ["volumeDown1"] = {
            title = i18n("decreaseVolumeBy") .. " 1",
            actionFn = function() spotify.setVolume(spotify.getVolume()-1) end,
        },
        ["displayCurrentTrack"] = {
            title = i18n("displayCurrentTrack"),
            actionFn = function() spotify.displayCurrentTrack() end,
        },
    }

    local actionmanager = deps.actionmanager
    local description = i18n("spotifyCommandDescription")
    mod._handler = actionmanager.addHandler("spotify_commands", "spotify")
        :onChoices(function(choices)
            for id, command in pairs(commands) do
                choices
                    :add(command.title)
                    :subText(description)
                    :params({
                        id = id,
                    })
                    :image(icon)
                    :id("spotify_commands_" .. id)
            end
        end)
        :onExecute(function(action)
            local id = action.id
            local theChoice = id and commands[id]
            if theChoice then
                theChoice.actionFn()
            else
                playErrorSound()
            end
        end)
        :onActionId(function(params)
            return "spotify_commands_" .. params.id
        end)

    return mod
end

return plugin