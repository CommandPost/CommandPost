--- === plugins.spotify.loupedeckplugin ===
---
--- Spotify Loupedeck Plugin Actions

local require                   = require

--local log                       = require "hs.logger".new "ldPlugin"

local application               = require "hs.application"
local spotify                   = require "hs.spotify"

local launchOrFocusByBundleID   = application.launchOrFocusByBundleID

local mod = {}

-- makeFunctionHandler(fn) -> function
-- Function
-- Creates a 'handler' for triggering a function.
--
-- Parameters:
--  * fn - the function you want to trigger.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeFunctionHandler(fn)
    return function()
        fn()
    end
end

-- plugins.spotify.loupedeckplugin._registerActions(manager) -> none
-- Function
-- A private function to register actions.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._registerActions()
    --------------------------------------------------------------------------------
    -- Only run once:
    --------------------------------------------------------------------------------
    if mod._registerActionsRun then return end
    mod._registerActionsRun = true

    --------------------------------------------------------------------------------
    -- Setup Dependancies:
    --------------------------------------------------------------------------------
    local registerAction = mod.manager.registerAction

    --------------------------------------------------------------------------------
    -- Register Actions:
    --
    -- NOTE: Because of a bug in LoupedeckConfig, I've had to internally use
    --       "Slatify" instead of "Spotify" otherwise the actions appear in the
    --       official Spotify Plugin/Integration in LoupedeckConfig.
    --------------------------------------------------------------------------------
    registerAction("Splatify.Launch", makeFunctionHandler(function() launchOrFocusByBundleID("com.spotify.client") end))
    registerAction("Splatify.Play", makeFunctionHandler(function() spotify.play() end))
    registerAction("Splatify.TogglePlayPause", makeFunctionHandler(function() spotify.playpause() end))
    registerAction("Splatify.Pause", makeFunctionHandler(function() spotify.pause() end))
    registerAction("Splatify.PreviousTrack", makeFunctionHandler(function() spotify.previous() end))
    registerAction("Splatify.NextTrack", makeFunctionHandler(function() spotify.next() end))
    registerAction("Splatify.FastForwardFiveSeconds", makeFunctionHandler(function() spotify.ff() end))
    registerAction("Splatify.RewindFiveSeconds", makeFunctionHandler(function() spotify.rw() end))
    registerAction("Splatify.VolumeUp", makeFunctionHandler(function() spotify.setVolume(spotify.getVolume()+5) end))
    registerAction("Splatify.VolumeDown", makeFunctionHandler(function() spotify.setVolume(spotify.getVolume()-5) end))
    registerAction("Splatify.DisplayCurrentTrack", makeFunctionHandler(function() spotify.displayCurrentTrack() end))
end

local plugin = {
    id          = "spotify.loupedeckplugin",
    group       = "spotify",
    required    = true,
    dependencies    = {
        ["core.loupedeckplugin.manager"] = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Manage Dependencies:
    --------------------------------------------------------------------------------
    mod.manager             = deps.manager

    --------------------------------------------------------------------------------
    -- Add actions:
    --------------------------------------------------------------------------------
    mod.manager.enabled:watch(function(enabled)
        if enabled then
            mod._registerActions()
        end
    end)

    return mod
end

return plugin
