--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                          M I D I     P L U G I N                           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.midi.manager ===
---
--- MIDI Manager Plugin for Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("fcpMidiMan")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local fcp                                       = require("cp.apple.finalcutpro")
local just                                      = require("cp.just")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.midi.manager.ID -> string
--- Constant
--- Group ID
mod.ID = "fcpx"

--- plugins.finalcutpro.midi.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable MIDI Support.
mod.enabled = config.prop("enableMIDI", false):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Update MIDI Commands when Final Cut Pro is shown or hidden:
        --------------------------------------------------------------------------------
        mod._fcpWatchID = fcp:watch({
            active      = function() mod._manager.groupStatus(mod.ID, true) end,
            inactive    = function() mod._manager.groupStatus(mod.ID, false) end,
            show        = function() mod._manager.groupStatus(mod.ID, true) end,
            hide        = function() mod._manager.groupStatus(mod.ID, false) end,
        })
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        if mod._fcpWatchID and mod._fcpWatchID.id then
            fcp:unwatch(mod._fcpWatchID.id)
            mod._fcpWatchID = nil
        end
    end
end)

--- plugins.finalcutpro.midi.manager.transmitMTC <cp.prop: boolean>
--- Field
--- Enable or disable Transmit MTC Support.
mod.transmitMTC = config.prop("transmitMTC", false):watch(function(enabled)
    if enabled then
        log.df("FCPX Transmit MTC Enabled!")
    else
        log.df("FCPX Transmit MTC Disabled!")
    end
end)

--- plugins.finalcutpro.midi.manager.transmitMMC <cp.prop: boolean>
--- Field
--- Enable or disable Transmit MMC Support.
mod.transmitMMC = config.prop("transmitMMC", false):watch(function(enabled)

    --------------------------------------------------------------------------------
    -- Get Transmit MMC Device Name:
    --------------------------------------------------------------------------------
    local device = mod._manager.transmitMMCDevice() and mod._manager.transmitMMCDevice() ~= "" and mod._manager.transmitMMCDevice()
    local virtual = false
    if device and string.sub(device, 1, 8) == "virtual_" then
        device = string.sub(device, 9)
        virtual = true
    end

    if enabled and device then

        --------------------------------------------------------------------------------
        -- Transmit MMC Enabled:
        --------------------------------------------------------------------------------
        --log.df("FCPX Transmit MMC Enabled!")

        --------------------------------------------------------------------------------
        -- Setup Watcher:
        --------------------------------------------------------------------------------
        mod._mmcPlayWatcher, mod._mmcPlayWatcherFn = fcp:viewer().isPlaying:watch(function(value)

            --------------------------------------------------------------------------------
            -- Get current timecode:
            --------------------------------------------------------------------------------
            local timecode = fcp:viewer():timecode()

            --------------------------------------------------------------------------------
            -- Supported MIDI Frame Rates: "24", "25", "30 DF" or "30 NDF".
            --------------------------------------------------------------------------------
            local framerate = fcp:viewer():framerate()
            local framerateString

            if framerate == 25 then
                framerateString = "25"
            elseif framerate == 30 then
                framerateString = "30"
            elseif framerate == 24 then
                framerateString = "24"
            else
                log.wf("Non-standard Framerate: %s", framerate)
                framerateString = "25"
            end

            if value then
                --------------------------------------------------------------------------------
                -- Final Cut Pro is playing:
                --------------------------------------------------------------------------------
                if timecode and framerateString then
                    --log.df("SENDING GOTO & PLAY: %s", timecode)
                    mod._manager.sendMMC(device, virtual, "7F", "PLAY")
                    mod._manager.sendMMC(device, virtual, "7F", "GOTO", {timecode=timecode, frameRate=framerateString, subFrame="00"})
                end
            else
                --------------------------------------------------------------------------------
                -- Final Cut Pro has stopped playing:
                --------------------------------------------------------------------------------
                --log.df("SENDING STOP: %s", timecode)
                if timecode and framerateString then
                    mod._manager.sendMMC(device, virtual, "7F", "STOP")
                    mod._manager.sendMMC(device, virtual, "7F", "GOTO", {timecode=timecode, frameRate=framerateString, subFrame="00"})
                end
            end
        end)
    else
        --------------------------------------------------------------------------------
        -- Transmit MMC Disabled:
        --------------------------------------------------------------------------------
        --log.df("FCPX Transmit MMC Disabled!")

        --------------------------------------------------------------------------------
        -- Destroy Watcher:
        --------------------------------------------------------------------------------
        if mod._mmcPlayWatcherFn then
            fcp:viewer().isPlaying:unwatch(mod._mmcPlayWatcherFn)
        end
        mod._mmcPlayWatcher = nil
        mod._mmcPlayWatcherFn = nil
    end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.midi.manager",
    group = "finalcutpro",
    dependencies = {
        ["core.midi.manager"]       = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    mod._manager = deps.manager
    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    if mod._manager then

        --------------------------------------------------------------------------------
        -- Update Watchers:
        --------------------------------------------------------------------------------
        mod.enabled:update()
        mod.transmitMMC:update()
        mod.transmitMTC:update()

        --------------------------------------------------------------------------------
        -- Listen to MMC Commands in Final Cut Pro:
        --
        -- * STOP
        -- * PLAY
        -- * DEFERRED_PLAY
        -- * FAST_FORWARD
        -- * REWIND
        -- * RECORD_STROBE
        -- * RECORD_EXIT
        -- * RECORD_PAUSE
        -- * PAUSE
        -- * EJECT
        -- * CHASE
        -- * MMC_RESET
        -- * WRITE
        -- * GOTO
        -- * ERROR
        -- * SHUTTLE
        --------------------------------------------------------------------------------
        mod._manager.registerListenMMCFunction(mod.ID, function(mmcType, timecode)
            if mmcType == "GOTO" then
                if timecode then
                    --------------------------------------------------------------------------------
                    -- Make sure FCPX is active:
                    --------------------------------------------------------------------------------
                    fcp:launch()

                    --------------------------------------------------------------------------------
                    -- Wait until FCPX is active:
                    --------------------------------------------------------------------------------
                    just.doUntil(function()
                        return fcp:isFrontmost()
                    end, 3)

                    --------------------------------------------------------------------------------
                    -- Jump to the correct timecode:
                    --------------------------------------------------------------------------------
                    fcp:timeline():playhead():setTimecode(timecode)
                end
            end
        end)

        --------------------------------------------------------------------------------
        -- Listen to MTC Commands in Final Cut Pro:
        --------------------------------------------------------------------------------
        mod._manager.registerListenMTCFunction(mod.ID, function(mtcType, timecode, framerate)
            log.df("mtcType: %s, timecode: %s, framerate: %s", mtcType, timecode, framerate)
        end)

    end
end

return plugin