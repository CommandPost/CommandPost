--- === plugins.core.loupedeckct.manager ===
---
--- Loupedeck CT Manager Plugin.

local require         = require

local log             = require "hs.logger".new "ldCT"

local application     = require "hs.application"
local appWatcher      = require "hs.application.watcher"
local ct              = require "hs.loupedeckct"
local drawing         = require "hs.drawing"
local image           = require "hs.image"
local timer           = require "hs.timer"
local utf8            = require "hs.utf8"

local config          = require "cp.config"
local json            = require "cp.json"

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
        mod._appWatcher:start()
    else
        log.df("Disconnecting from Loupedeck CT")
        ct.disconnect()
        mod._appWatcher:stop()
    end
end)

--- plugins.core.loupedeckct.prefs.items <cp.prop: table>
--- Field
--- Contains all the saved Loupedeck CT data
mod.items = json.prop(config.userConfigRootPath, "Loupedeck CT", "Default.cpLoupedeckCT", {})

mod.activeBanks = config.prop("loupedeckct.activeBanks", {})

local translateButtons = {
    [1]                         = "Knob 1",
    [2]                         = "Knob 2",
    [3]                         = "Knob 3",
    [4]                         = "Knob 4",
    [5]                         = "Knob 5",
    [6]                         = "Knob 6",
    [ct.buttonID.B1]            = "1",
    [ct.buttonID.B2]            = "2",
    [ct.buttonID.B3]            = "3",
    [ct.buttonID.B4]            = "4",
    [ct.buttonID.B5]            = "5",
    [ct.buttonID.B6]            = "6",
    [ct.buttonID.B7]            = "7",
    [ct.buttonID.B8]            = "8",
    [ct.buttonID.O]             = "O",
    [ct.buttonID.UNDO]          = "Undo",
    [ct.buttonID.KEYBOARD]      = "Keyboard",
    [ct.buttonID.RETURN]        = "Return",
    [ct.buttonID.SAVE]          = "Save",
    [ct.buttonID.LEFT_FN]       = "Fn (Left)",
    [ct.buttonID.RIGHT_FN]      = "Fn (Right)",
    [ct.buttonID.A]             = "A",
    [ct.buttonID.B]             = "B",
    [ct.buttonID.C]             = "C",
    [ct.buttonID.D]             = "D",
    [ct.buttonID.E]             = "E",
}

local buttonsWithLEDs = {
    ["1"]                       = ct.buttonID.B1,
    ["2"]                       = ct.buttonID.B2,
    ["3"]                       = ct.buttonID.B3,
    ["4"]                       = ct.buttonID.B4,
    ["5"]                       = ct.buttonID.B5,
    ["6"]                       = ct.buttonID.B6,
    ["7"]                       = ct.buttonID.B7,
    ["8"]                       = ct.buttonID.B8,
    ["O"]                       = ct.buttonID.O,
    ["Undo"]                    = ct.buttonID.UNDO,
    ["Keyboard"]                = ct.buttonID.KEYBOARD,
    ["Return"]                  = ct.buttonID.RETURN,
    ["Save"]                    = ct.buttonID.SAVE,
    ["Fn (Left)"]               = ct.buttonID.LEFT_FN,
    ["Fn (Right)"]              = ct.buttonID.RIGHT_FN,
    ["A"]                       = ct.buttonID.A,
    ["B"]                       = ct.buttonID.B,
    ["C"]                       = ct.buttonID.C,
    ["D"]                       = ct.buttonID.D,
    ["E"]                       = ct.buttonID.E,
}

function mod.refresh()
    local items = mod.items()

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    local activeBanks = mod.activeBanks()
    local bank = activeBanks[bundleID] or "1"

    for id, realID in pairs(buttonsWithLEDs) do
        if items[bundleID] and items[bundleID][bank] and items[bundleID][bank][id] and items[bundleID][bank][id]["LED"] then
            ct.buttonColor(realID, {hex="#" .. items[bundleID][bank][id]["LED"]})
        else
            ct.buttonColor(realID, {hex="#000000"})
        end
    end
end

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

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    local items = mod.items()

    local activeBanks = mod.activeBanks()
    local bank = activeBanks[bundleID] or "1"

    if items[bundleID] and items[bundleID][bank] then
        if data.id == ct.event.BUTTON_PRESS and data.direction == "down" then
            --------------------------------------------------------------------------------
            -- BUTTON PRESS:
            --------------------------------------------------------------------------------
            local button = translateButtons[data.buttonID]
            if items[bundleID][bank][button] and items[bundleID][bank][button]["Press"] then
                local handlerID = items[bundleID][bank][button]["Press"]["handlerID"]
                local action = items[bundleID][bank][button]["Press"]["action"]
                if handlerID and action then
                    local handler = mod._actionmanager.getHandler(handlerID)
                    handler:execute(action)
                end
            end
        elseif data.id == ct.event.ENCODER_MOVE then
            if data.direction == "left" then
                --------------------------------------------------------------------------------
                -- TURN KNOB LEFT:
                --------------------------------------------------------------------------------
                local button = translateButtons[data.buttonID]
                if items[bundleID][bank][button] and items[bundleID][bank][button]["Left"] then
                    local handlerID = items[bundleID][bank][button]["Left"]["handlerID"]
                    local action = items[bundleID][bank][button]["Left"]["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
            elseif data.direction == "right" then
                --------------------------------------------------------------------------------
                -- TURN KNOB RIGHT:
                --------------------------------------------------------------------------------
                local button = translateButtons[data.buttonID]
                if items[bundleID][bank][button] and items[bundleID][bank][button]["Right"] then
                    local handlerID = items[bundleID][bank][button]["Right"]["handlerID"]
                    local action = items[bundleID][bank][button]["Right"]["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
            end
        elseif data.id == ct.event.WHEEL_PRESSED then

        elseif data.id == ct.event.SCREEN_PRESSED then

        end

    end
end

local plugin = {
    id          = "core.loupedeckct.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Setup the Loupedeck CT callback:
    --------------------------------------------------------------------------------
    ct.callback(callback)

    --------------------------------------------------------------------------------
    -- Setup watch to refresh the Loupedeck CT when apps change focus:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function()
        mod.refresh()
    end)

    --------------------------------------------------------------------------------
    -- Connect to the Loupedeck CT:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    return mod
end

return plugin
