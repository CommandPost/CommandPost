--- === plugins.core.loupedeckct.manager ===
---
--- Loupedeck CT Manager Plugin.

local require         = require

local log             = require "hs.logger".new "ldCT"

local ct              = require "hs.loupedeckct"
local drawing         = require "hs.drawing"
local image           = require "hs.image"
local timer           = require "hs.timer"
local utf8            = require "hs.utf8"

local config          = require "cp.config"

local doAfter         = timer.doAfter
local hexDump         = utf8.hexDump
local imageFromPath   = image.imageFromPath

local mod = {}

mod.vibrations = config.prop("loupedeckct.vibrations", true):watch(function(enabled)
    ct.vibrations(enabled)
end)

mod.enabled = config.prop("loupedeckct.enabled", true):watch(function(enabled)
    if enabled then
        log.df("Connecting to Loupedeck CT")
        ct.connect(true)
    else
        log.df("Disconnecting from Loupedeck CT")
        ct.disconnect()
    end
end)

--- plugins.core.loupedeckct.manager.test() -> none
--- Function
--- Sends data to all the screens and buttons for testing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.test()

    ct.startBackgroundLoop(function(response)
        --------------------------------------------------------------------------------
        -- BACKGROUND LOOP
        --
        -- Example:
        -- 3D A8 1C 9B A7 2A 8C 87 D4 F6 A1 35 A2 89 06 6C
        --------------------------------------------------------------------------------

        -- TODO: Work out what all this data is.

        log.df("Start Background Loop: id: %d; message:\n%s", response.id, hexDump(response.data))
    end)

    ct.requestDeviceInfo(function(response)
        --------------------------------------------------------------------------------
        -- Example:
        -- 3B 47 B9 65 23 4E 6D 81 3F 65 A0 AC F0 8E A1 7C
        --------------------------------------------------------------------------------

        -- TODO: Work out what all this data is.

        log.df("Device Info: id: %d; message:\n%s", response.id, hexDump(response.data))
    end)


    ct.requestSerialNumber(function(response)
        log.df("Serial Number: %s", response.serialNumber)
    end)

    ct.requestMCUID(function(response)
        log.df("MCU ID: %s", response.mcuid)
    end)

    ct.requestSelfTest(function(response)
        log.df("Self-Test: %08X", response.selfTest)
    end)


    ct.requestRegister(0, function(response)
        log.df("Register 0 value: %08X", response.value)
    end)

    ct.requestRegister(1, function(response)
        log.df("Register 1 value: %08X", response.value)
    end)

    ct.requestRegister(2, function(response)
        log.df("Register 2 value: %08X", response.value)
        log.df("Vibra waveform index: %d", response.vibraWaveformIndex)
        log.df("Backlight level: %d", response.backlightLevel)
    end)

    ct.requestWheelSensitivity(0, function(data)
        log.df("Wheel Sensitivity: id: %04x; data: %s", data.command, utf8.hexDump(data.message))
    end)

    ct.resetDevice(function(data)
        log.df("Reset Device: id: %04x; success: %s", data.id, data.success)
    end)

    doAfter(0, function()
        local color = drawing.color.hammerspoon.red
        for _, button in pairs(ct.buttonID) do
            ct.buttonColor(button, color)
        end
        for _, screen in pairs(ct.screens) do
            ct.updateScreenColor(screen, color)
        end
    end)
    doAfter(2, function()
        local color = drawing.color.hammerspoon.green
        for _, button in pairs(ct.buttonID) do
            ct.buttonColor(button, color)
        end
        for _, screen in pairs(ct.screens) do
            ct.updateScreenColor(screen, color)
        end
    end)
    doAfter(4, function()
        local color = drawing.color.hammerspoon.blue
        for _, button in pairs(ct.buttonID) do
            ct.buttonColor(button, color)
        end
        for _, screen in pairs(ct.screens) do
            ct.updateScreenColor(screen, color)
        end
    end)
    doAfter(6, function()
        local color = drawing.color.hammerspoon.black
        for _, button in pairs(ct.buttonID) do
            ct.buttonColor(button, color)
        end
        ct.updateScreenColor(ct.screens.left, color)
        ct.updateScreenColor(ct.screens.right, color)

        ct.updateScreenImage(ct.screens.middle, imageFromPath(cp.config.assetsPath .. "/middle.png"))
        ct.updateScreenImage(ct.screens.wheel, imageFromPath(cp.config.assetsPath .. "/wheel.png"))
    end)
    doAfter(8, function()
        local color = drawing.color.hammerspoon.red
        for _, button in pairs(ct.buttonID) do
            ct.buttonColor(button, color)
        end
        ct.updateScreenColor(ct.screens.left, color)
        ct.updateScreenColor(ct.screens.right, color)
        for x=0, 3 do
            for y=0, 2 do
                ct.updateScreenImage(ct.screens.middle, imageFromPath(cp.config.assetsPath .. "/button.png"), {x=x*90, y=y*90, w=90,h=90})
            end
        end
    end)
    doAfter(10, function()
        local color = drawing.color.hammerspoon.black
        for _, button in pairs(ct.buttonID) do
            ct.buttonColor(button, color)
        end
        for _, screen in pairs(ct.screens) do
            ct.updateScreenColor(screen, color)
        end
    end)
end

local function callback(data)
    log.df("ct data: %s", hs.inspect(data))
end

local plugin = {
    id          = "core.loupedeckct.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.commands.global"]            = "global",
    }
}

function plugin.init()
    --------------------------------------------------------------------------------
    -- Setup the Loupedeck CT callback:
    --------------------------------------------------------------------------------
    ct.callback(callback)

    --------------------------------------------------------------------------------
    -- Connect to the Loupedeck CT:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    return mod
end

return plugin
