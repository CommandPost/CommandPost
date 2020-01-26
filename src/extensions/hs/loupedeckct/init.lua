--- === hs.loupedeckct ===
---
--- Adds Loupedeck CT Support
---
--- Special thanks to William Viker & Håkon Nessjøen for their [NodeJS experiments](https://github.com/bitfocus/loupedeck-ct).

local log               = require "hs.logger".new("loupedeckct")

local bytes             = require "hs.bytes"
local drawing           = require "hs.drawing"
local hsmath            = require "hs.math"
local inspect           = require "hs.inspect"
local network           = require "hs.network"
local timer             = require "hs.timer"
local usb               = require "hs.usb"
local utf8              = require "hs.utf8"
local websocket         = require "hs.websocket"

local concat            = table.concat
local doAfter           = timer.doAfter
local floor             = math.floor
local format            = string.format
local hexDump           = utf8.hexDump
local randomFromRange   = hsmath.randomFromRange

local bytesToHex        = bytes.bytesToHex
local hexToBytes        = bytes.hexToBytes
local int16be           = bytes.int16be
local int24be           = bytes.int24be
local int32be           = bytes.int32be
local int8              = bytes.int8
local remainder         = bytes.remainder

local mod               = {}

local callbackRegister = {}

-- registerCallback(callbackFn) -> number
-- Function
-- Registers a callback.
--
--
-- Parameters:
--  * callbackFn - The callback function
--
-- Returns:
--  * A unique callback ID as a number, or `0` if none was provided.
local function registerCallback(callbackFn)
    if callbackFn == nil then
        return 0
    end

    if type(callbackFn) ~= "function" then
        error(format("expected a callback function, but got a %s", type(callbackFn), 3))
    end

    local id = randomFromRange(1, 255)
    while(callbackRegister[id])
    do
        id = randomFromRange(1, 255)
    end
    callbackRegister[id] = callbackFn
    return id
end

-- getCallback(id[, preserve]) -> function | nil
-- Function
-- Retrieves the callback function at the specified id.
--
-- Parameters:
--  * id        - the callback ID to retrieve
--  * preserve  - (optional) if `true`, the callback will not be cleared from the register. defaults to `false`.
--
-- Returns:
--  * The callback `function`, or `nil` if not available.
local function getCallback(id, preserve)
    local callback = callbackRegister[id]
    if not preserve then
        callbackRegister[id] = nil
    end
    return callback
end

-- rgbToInt16(r, g, b) -> number
-- Function
-- Converts 8-bit Red/Green/Blue values into a 16-bit integer.
--
-- Parameters:
-- * r - Red component
-- * g - Green component
-- * b - Blue component
--
-- Returns:
-- * The 16-bit integer for the colour value.
local function rgbToInt16(r, g, b)
    return (((b >> 3) & 0x1F) << 8) | (((r >> 3) & 0x1F) << 3) | ((g >> 5) & 0x07)
end

-- colorToInt16(colorTable) -> number
-- Function
-- Converts an `hs.drawing.color` value into a 16-bit integer.
--
-- Parameters:
-- * colorTable - A `table` containing a color that matches requirements for `hs.drawing.color`.
--
-- Returns:
-- * The 16-bit integer for the colour value.
local function colorToInt16(colorTable)
    local rgb = drawing.color.asRGB(colorTable)
    local r = floor(rgb.red * 255)
    local g = floor(rgb.green * 255)
    local b = floor(rgb.blue * 255)
    return rgbToInt16(r, g, b)
end

-- toInt16Color(color) -> number
-- Function
-- Attempts to convert different colour definitions to a 16-bit color value.
--
-- Parameters:
-- * color - Either a `hs.drawing.color` table, a 16-bit color value, or 24-bit hex strings (e.g. "FFFFFF")
local function toInt16Color(color)
    local colorType = type(color)
    if colorType == "string" then
        return colorToInt16({hex=color, alpha=1.0})
    elseif colorType == "table" then
        return colorToInt16(color)
    elseif colorType == "number" then
        return color
    else
        error(format("Unexpected color value: ", inspect(color)))
    end
end

-- rgbToInt24(r, g, b) -> number
-- Function
-- Converts the individual 8-bit RGB integers into a single 24-bit integer value, ordered as R,G,B.
--
-- Parameters:
-- * r - The Red component.
-- * g - The Green component.
-- * b - The Blue component.
--
-- Returns:
-- * The 24-bit integer for the color value.
local function rgbToInt24(r, g, b)
    return ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | ((b & 0xFF))
end

-- colorToInt24(colorTable) -> n umber
-- Function
-- Converts an `hs.drawing.color` value into a 16-bit integer.
--
-- Parameters:
-- * colorTable - A `table` containing a color that matches requirements for `hs.drawing.color`.
--
-- Returns:
-- * The 24-bit integer for the colour value.
local function colorToInt24(colorTable)
    local rgb = drawing.color.asRGB(colorTable)
    local r = floor(rgb.red * 255)
    local g = floor(rgb.green * 255)
    local b = floor(rgb.blue * 255)
    return rgbToInt24(r, g, b)
end

-- toInt24Color(color) -> number
-- Function
-- Attempts to convert different colour definitions to a 24-bit color value (RGB * 8-bits).
--
-- Parameters:
-- * color - Either a `hs.drawing.color` table, a 24-bit color value, or 24-bit hex strings (e.g. "FFFFFF")
local function toInt24Color(color)
    local colorType = type(color)
    if colorType == "string" then
        return colorToInt24({hex=color, alpha=1.0})
    elseif colorType == "table" then
        return colorToInt24(color)
    elseif colorType == "number" then
        return color
    else
        error(format("Unexpected color value: ", inspect(color)))
    end
end

-- findLast(haystack, needle) -> number
-- Function
-- Finds the position of the last occurance of a character in a string.
--
-- Parameters:
--  * haystack - What to search
--  * needle - What to search for
--
-- Returns:
--  * A number with the position otherwise `nil`
local function findLast(haystack, needle)
    local i=haystack:match(".*"..needle.."()")
    if i==nil then return nil else return i-1 end
end

--- hs.loupedeckct.setLogLevel(loglevel) -> none
--- Function
--- Sets the Log Level.
---
--- Parameters:
---  * loglevel - can be 'nothing', 'error', 'warning', 'info', 'debug', or 'verbose'; or a corresponding number between 0 and 5
---
--- Returns:
---  * None
function mod.setLogLevel(loglevel)
    log:setLogLevel(loglevel)
end

-- connected() -> boolean
-- Function
-- Checks if the websocket is connected or not
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if connected otherwise `false`
local function connected()
    return mod._websocket and mod._websocket:status() == "open"
end

-- send() -> boolean
-- Function
-- Sends a message via the websocket if connected
--
-- Parameters:
--  * message - The message to send.
--
-- Returns:
--  * `true` if sent.
local function send(message)
    if connected() then
        local data = type(message) == "table" and concat(message) or tostring(message)
        --log.df("Sending: %s", hexDump(data))
        mod._websocket:send(data)
        return true
    end
    return false
end

-- sendCommand(commandID[, callbackFn[, ...]]) -> boolean
-- Function
-- Sends the specified command, with the provided callback function, along with any additional binary string blocks.
--
-- Parameters:
-- * commandID  - An 16-bit integer with the command ID.
-- * callbackFn - A `function` that will be called with the `data` from the response. (optional)
-- * ...        - a variable number of byte string values, which will be concatinated together with the command and callback ID when being sent.
local function sendCommand(commandID, callbackFn, ...)
    return send(
        bytes(int16be(commandID), int8(registerCallback(callbackFn)), ...):bytes()
    )
end

-- findIPAddress() -> string | nil
-- Function
-- Searches for a valid IP address for the Loupedeck CT
--
-- Parameters:
--  * None
--
-- Returns:
--  * An IP address as a string, or `nil` if no device can be detected.
local function findIPAddress()
    local interfaces = network.interfaces()
    local interfaceID
    for _, v in pairs(interfaces) do
        if network.interfaceName(v) == "LOUPEDECK device" then
            interfaceID = v
            break
        end
    end
    local details = interfaceID and network.interfaceDetails(interfaceID)
    local ip = details and details["IPv4"] and details["IPv4"]["Addresses"] and details["IPv4"]["Addresses"][1]
    local lastDot = ip and findLast(ip, "%.")
    return ip and lastDot and string.sub(ip, 1, lastDot) .. "1"
end

local function initaliseDevice()
    mod.startBackgroundLoop(function(response)
        log.df("Start Background Loop: id: %d; message:\n%s", response.id, hexDump(response.data))
    end)

    mod.requestDeviceInfo(function(response)
        log.df("Device Info: id: %d; message:\n%s", response.id, hexDump(response.data))
    end)

    mod.requestSerialNumber(function(response)
        log.df("Serial Number: %s", response.serialNumber)
    end)

    mod.requestMCUID(function(response)
        log.df("MCU ID: %s", response.mcuid)
    end)

    mod.requestSelfTest(function(response)
        log.df("Self-Test: %08X", response.selfTest)
    end)

    mod.requestRegister(0, function(response)
        log.df("Register 0 value: %08X", response.value)
    end)

    mod.requestRegister(1, function(response)
        log.df("Register 1 value: %08X", response.value)
    end)

    mod.requestRegister(2, function(response)
        log.df("Register 2 value: %08X", response.value)
        log.df("Vibra waveform index: %d", response.vibraWaveformIndex)
        log.df("Backlight level: %d", response.backlightLevel)

        mod._vibraWaveformIndex = response.vibraWaveformIndex
        mod._backlightLevel = response.backlightLevel
    end)

    mod.requestWheelSensitivity(0, function(data)
        log.df("Wheel Sensitivity: id: %04x; data: %s", data.command, utf8.hexDump(data.message))
    end)

    mod.resetDevice(function(data)
        log.df("Reset Device: id: %04x; success: %s", data.id, data.success)
    end)

    -- Reset all the buttons to black:
    local black = 0x000000
    for _,id in pairs(mod.buttonID) do
        mod.buttonColor(id, black, function(response)
            log.df("Button %d set to black: %s", id, tostring(response.success))
        end)
    end

    -- Reset all the screens to black:
    local b = drawing.color.hammerspoon.black
    for id, screen in pairs(mod.screens) do
        mod.updateScreenColor(screen, b, nil, function()
            log.df("Screen %s set to black.", id)
        end)
    end

end

--- hs.loupedeckct.callback() -> boolean
--- Function
--- Sets a callback when new messages are received.
---
--- Parameters:
---  * callbackFn - a function to set as the callback for `hs.loupedeckct`. If the value provided is `nil`, any currently existing callback function is removed.
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.callback(callbackFn)
    if type(callbackFn) == "function" then
        mod._callback = callbackFn
        return true
    elseif type(callbackFn) == "nil" then
        mod._callback = nil
        return true
    else
        log.ef("Callback received an invalid type: %s", type(callbackFn))
        return false
    end
end

-- triggerCallback -> none
-- Function
-- Triggers a callback function
--
-- Parameters:
--  * data - Any data to pass along to the callback function as a table
--
-- Returns:
--  * None
local function triggerCallback(data)
    --------------------------------------------------------------------------------
    -- Trigger the callback:
    --------------------------------------------------------------------------------
    if mod._callback then
        local success, result = xpcall(function() mod._callback(data) end, debug.traceback)
        if not success then
            log.ef("Error in Loupedeck CT Callback: %s", result)
        end
    end
end

-- WEBSOCKET EVENTS
local events = {
    --------------------------------------------------------------------------------
    -- WEBSOCKET OPENED:
    --------------------------------------------------------------------------------
    open = function()
        mod._connected = true

        -- Initialise the big screen:
        initaliseDevice()

        triggerCallback {
            action = "open",
        }
    end,

    --------------------------------------------------------------------------------
    -- WEBSOCKET CLOSED:
    --------------------------------------------------------------------------------
    closed = function()
        mod._connected = false

        triggerCallback {
            action = "closed",
        }
    end,

    --------------------------------------------------------------------------------
    -- WEBSOCKET FAILED:
    --------------------------------------------------------------------------------
    fail = function(message)
        mod._connected = false

        triggerCallback({
            action = "fail",
            error = message,
        })
    end,

    --------------------------------------------------------------------------------
    -- WEBSOCKET RECEIVED PONG:
    --------------------------------------------------------------------------------
    pong = function()
        triggerCallback {
            action = "pong",
        }
    end,

    --------------------------------------------------------------------------------
    -- WEBSOCKET RECEIVED MESSAGE:
    --------------------------------------------------------------------------------
    received = function(message)
        -- read the command ID, callback ID and the remainder of the message...
        local id, callbackID, data = bytes.read(message,
            int16be, int8, remainder
        )

        local response = {
            id = id,
            data = data,
        }

        -- first, check if we have a callback...
        local callback = getCallback(callbackID)
        if callback then
            local ok, res = xpcall(function() return callback(response) end, debug.traceback)
            if not ok then
                log.ef("Error executing callback for %04x: %s", response.id, res)
                return
            end
        else
            -- if not, see if there is a handler.
            local handler = mod.responseHandler[id]
            if handler then
                local ok, res = xpcall(function() return handler(response) end, debug.traceback)
                if not ok then
                    log.ef("Error executing callback for %04x: %s", response.id, res)
                    return
                end
            else
                log.ef("Unsupported command: id: %04x; callback: %02x; message:\n%s", id, callbackID, hexDump(message))
                return
            end
        end
    end
}

--- hs.loupedeckct.event -> table
--- Constant
--- The set of events sent from the Loupedeck CT device.
---
--- Notes:
---  * Includes:
---    * BUTTON_PRESS - occurs when a button is pressed or released.
---    * ENCODER_MOVE - occurs when the wheel/encoder moves left or right
---    * WHEEL_PRESSED - occurs when the wheel is pressed.
---    * WHEEL_RELEASED - occurs when the wheel is released.
---    * SCREEN_PRESSED - occurs when the main screen is pressed.
---    * SCREEN_RELEASED - occurs when the main screen is released.
mod.event = {
    BUTTON_PRESS = 0x0500,
    ENCODER_MOVE = 0x0501,
    WHEEL_PRESSED = 0x0952,
    WHEEL_RELEASED = 0x0972,
    SCREEN_PRESSED = 0x094D,
    SCREEN_RELEASED = 0x096D,
    BUTTON_CONFIRMATION = 0x0302,
    SCREEN_CONFIRMATION = 0x040F,
}

-- set of response handlers for device-generated events.
mod.responseHandler = {

    -- Button Confirmation
    [mod.event.BUTTON_CONFIRMATION] = function(response)
        triggerCallback {
            action = "button_confirmation",
        }
    end,

    -- Screen Confirmation
    [mod.event.SCREEN_CONFIRMATION] = function(response)
        local success = bytes(response.data):read(int8)

        triggerCallback {
            action = "screen_confirmation",
            success = success == 1,
        }
    end,

    -- Button Press/Release
    [mod.event.BUTTON_PRESS] = function(response)
        local id, dirByte = bytes(response.data):read(int8, int8)
        local direction
        if dirByte == 0x00 then
            direction = "down"
        elseif dirByte == 0x01 then
            direction = "up"
        else
            log.ef("Invalid Button Direction: %02x", dirByte)
        end
        if direction then
            triggerCallback {
                action = "button_press",
                id = id,
                direction = direction,
            }
        end
    end,

    -- Encoder rotation
    [mod.event.ENCODER_MOVE] = function(response)
        local id, dirByte = bytes.read(response.data, int8, int8)
        local direction
        if dirByte == 0xFF then
            direction = "left"
        elseif dirByte == 0x01 then
            direction = "right"
        else
            log.ef("Invalid Encoder Direction: %02x", dirByte)
        end
        if direction then
            triggerCallback({
                action = "encoder_step",
                id = id,
                direction = direction,
            })
        end
    end,

    -- Big Wheel Pressed
    [mod.event.WHEEL_PRESSED] = function(response)
        local eventID, x, y = bytes.read(response.data, int8, int16be, int16be)
        triggerCallback {
            action = "wheel_pressed",
            x = x,
            y = y,
            eventID = eventID, -- Always 0
        }
    end,

    -- Big Wheel Released
    [mod.event.WHEEL_RELEASED] = function(response)
        local eventID, x, y = bytes.read(response.data, int8, int16be, int16be)
        triggerCallback {
            action = "wheel_released",
            x = x,
            y = y,
            eventID = eventID, -- Always 0
        }
    end,

    [mod.event.SCREEN_PRESSED] = function(response)
        local unknown, x, y, eventID = bytes.read(response.data, int8, int16be, int16be, int8)
        triggerCallback({
            action = "screen_pressed",
            x = x,
            y = y,
            eventID = eventID,
            unknown = unknown, -- Always 0
        })
    end,

    [mod.event.SCREEN_RELEASED] = function(response)
        local unknown, x, y, eventID = bytes.read(response.data, int8, int16be, int16be, int8)
        triggerCallback({
            action = "screen_released",
            x = x,
            y = y,
            eventID = eventID,
            unknown = unknown, -- Always 0
        })
    end,
}

-- websocketCallback(event, message) -> none
-- Function
-- The websocket callback function.
--
-- Parameters:
--  * event - A string containing the type of event (i.e. "open" or "closed")
--  * message - The message from the websocket
--
-- Returns:
--  * None
local function websocketCallback(event, message)
    local handler = events[event]
    if handler then
        handler(message)
    else
        log.wf("Unexpected websocket event '%s':\n%s", event, hexDump(message))
    end
end

--- hs.loupedeckct.startBackgroundLoop([callbackFn]) -> boolean
--- Function
--- Kicks off the background listening loop on the device.
---
--- Parameters:
--- * callbackFn - Optional function to call when the device responds, receiving a data table containing `id` and `message`.
---
--- Returns:
--- * `true` if the device is connected and the message was sent.
function mod.startBackgroundLoop(callbackFn)
    -- TODO: currently no idea what the trailing bytes represent. Possibly local data specific to the current machine?
    local echo = hexToBytes("3da81c9ba72a8c87d4f6a135a289066c")
    return sendCommand(
        0x130E,
        function(response)
            if response.data ~= echo then
                log.ef("Received different result from loopback confirmation: %s", response.data)
            end
            if callbackFn then
                callbackFn(response)
            end
        end,
        echo
    )
end

function mod.requestDeviceInfo(callbackFn)
    --------------------------------------------------------------------------------
    -- DEVICE INFORMATION:
    --
    -- Sending message (19): (19) 13-1C-02-7E-1E-38-CF-55-8B-2C-13-AB-14-64-71-1C ...
    -- Message sent (19): (19) 13-1C-02-7E-1E-38-CF-55-8B-2C-13-AB-14-64-71-1C-ED-B0-8A
    -- Message received (19): (19) 13-1C-02-64-42-AA-22-DC-81-7A-80-DB-E9-E7-31-03 ...
    -- Get device information
    --------------------------------------------------------------------------------

    -- TODO: figure out what these bytes mean...
    return sendCommand(0x131C, callbackFn, hexToBytes("61f1392a8e936ba66e992daedb40f65f"))
end

--- hs.loupedeckct.requestFirmwareVersion([callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT asking for its firmware version.
---
--- Parameters:
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`,
function mod.requestFirmwareVersion(callbackFn)
    --------------------------------------------------------------------------------
    -- FIRMWARE VERSION:
    --
    -- Message sent: (3) 03-07-03
    -- Message received: 0C-07-03-00-00-08-00-09-00-01-00-0A
    -- Firmware version 'B': '0.0.8'
    -- Firmware version 'C': '0.9.0'
    -- Firmware version 'I': '1.0.10'
    --------------------------------------------------------------------------------
    return sendCommand(0x0307, callbackFn and function(response)
        local data = response.data
        response.b = format("%d.%d.%d", data:byte(1), data:byte(2), data:byte(3))
        response.c = format("%d.%d.%d", data:byte(4), data:byte(5), data:byte(6))
        response.i = format("%d.%d.%d", data:byte(7), data:byte(8), data:byte(9))
        callbackFn(response)
    end)
end

--- hs.loupedeckct.requestSerialNumber([callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT asking for its serial number.
---
--- Parameters:
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, and `serialNumber`
function mod.requestSerialNumber(callbackFn)
    return sendCommand(0x0303, callbackFn and function(response)
        response.serialNumber = response.data
        callbackFn(response)
    end)
end

--- hs.loupedeckct.requestMCUID([callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT asking for its MCU ID.
---
--- Parameters:
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, and `mcuid`
function mod.requestMCUID(callbackFn)
    return sendCommand(0x030D, callbackFn and function(response)
        response.mcuid = bytesToHex(response.data)
        callbackFn(response)
    end)
end

--- hs.loupedeckct.requestSelfTest() -> boolean
--- Function
--- Sends a request to the Loupedeck CT asking it to perform a self test.
---
--- Parameters:
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, and `selfTest`.
--- * The `selfTest` value is the `data` read as a 32-bit big-endian integer.
function mod.requestSelfTest(callbackFn)
    return sendCommand(0x0304, callbackFn and function(response)
        -- Sending message (3): (3) 03-04-05
        -- Message sent (3): (3) 03-04-05
        -- Message received (7): (7) 07-04-05-BF-00-3F-00
        -- Self-tests: 0x003F00BF
        -- for some reason, the result is read back in little-endian. Testing which way the OS works?
        response.selfTest = bytes.read(response.data, bytes.int32le)
        callbackFn(response)
    end)
end

--- hs.loupedeckct.requestRegister(registerID[, callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT asking it to send the specified register number.
---
--- Parameters:
---  * registerID - The register number (typically `0`, `1`, or `2`).
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, `registerID`, and `value`.
--- * the `registerID` should be the same value as the `registerID` parameter you passed in.
--- * the `value` value is the `data` read as a 32-bit big-endian integer.
--- * if requesting register `2`, it will also have the `backlightLevel` and `vibraWaveformIndex` values.
function mod.requestRegister(registerID, callbackFn)
    -- 04 1A 01 01
    -- ^     ^  ^
    -- ^     ^  register number
    -- ^     callback ID
    -- command ID
    return sendCommand(
        0x041A,
        callbackFn and function(response)
            response.registerID, response.value = bytes.read(response.data, int8, int32be)

            if registerID == 2 then
                -- Message received (8): (8) 08-1A-09-02-03-00-09-19
                -- Register 2: 0x03000919
                -- Vibra waveform index: 25 (last byte)
                -- Backlight level: 9 (second-last byte)
                response.backlightLevel, response.vibraWaveformIndex = bytes.read(response.data, 4, int8, int8)
            end
            callbackFn(response)
        end,
        int8(registerID)
    )
end

--- hs.loupedeckct.requestWheelSensitivity([callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT asking it to send the current wheel sensitivity.
---
--- Parameters:
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, `wheelSensitivity`.
function mod.requestWheelSensitivity(callbackFn)
    return sendCommand(0x041E, callbackFn and function(response)
        response.wheelSensitivity = int8(response.data)
        callbackFn(response)
    end)
end

--- hs.loupedeckct.resetDevice([callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT asking it to reset the device.
---
--- Parameters:
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, `success`.
--- * the `success` value is a boolean, `true` or `false`.
function mod.resetDevice(callbackFn)
    return sendCommand(
        0x0409,
        callbackFn and function(response)
            response.success = bytes.read(response.data, int8) == 0x01
            callbackFn(response)
        end,
        int8(9) -- not sure why we're sending 9? type of reset?
    )
end

--- hs.loupedeckct.screens -> table
--- Constant
--- The set of screens available: `left`, `right`, `middle`, and `wheel`.
---
--- Notes:
--- * each screen has an `id`, a `width`, and a `height` value.
--- * the `id` is how the Loupedeck CT identifies the screen.
--- * the `width` and `height` are in pixels.
mod.screens = {
    left = {
        id = 0x004C,
        width = 60, height = 270,
    },
    middle = {
        id = 0x0041,
        width = 360, height = 270,
    },
    right = {
        id = 0x0052,
        width = 60, height = 270,
    },
    wheel = {
        id = 0x0057,
        width = 240, height = 240,
        prepareImage = function(_, imageBytes)
            -- TODO: This is the current workaround for the wheel screen.
            --       Why we need this... I have no idea.
            return int8(0) .. imageBytes:sub(1, -28)
        end,
    },
}

--- hs.loupedeckct.refreshScreen(screen[, callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT asking it to reset the device.
---
--- Parameters:
---  * screen       - The screen (eg. `screens.left`) to refresh.
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, `success`.
--- * the `success` value is a boolean, `true` or `false`.
function mod.refreshScreen(screen, callbackFn)
    --------------------------------------------------------------------------------
    -- COMMAND: 050F XX 004C
    --          ^    ^  ^
    --          ^    ^  screen ID
    --          ^    callback ID (8-bit int)
    --          command ID
    --------------------------------------------------------------------------------
    return sendCommand(
        0x050F,
        callbackFn and function(response)
            response.success = bytes.read(response.data, int8) == 0x01
            callbackFn(response)
        end,
        int16be(screen.id)
    )
end

--- hs.loupedeckct.updateScreenImage(screen, imageBytes[, frame][, callbackFn]) -> boolean
--- Function
--- Sends an image to the specified screen and refreshes the specified screen.
---
--- Parameters:
---  * screen       - the `screen` to update, from [hs.loupedeck.screens](#screens) (eg `hs.loupedeck.screens.left`)
---  * imageBytes   - the byte string for the image in the custom Loupedeck 16-bit RGB format or a `hs.image` object
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---  * frame        - (optional) An optional `hs.geometry.rect` object
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, `success`.
--- * the `success` value is a boolean, `true` or `false`.
function mod.updateScreenImage(screen, imageBytes, frame, callbackFn)
    --------------------------------------------------------------------------------
    -- COMMAND: FF10 XX 004C 00 00 00 00 003C 010E FFFF FFFF ....
    --          ^    ^  ^    ^     ^     ^    ^    ^
    --          ^    ^  ^    ^     ^     ^    ^    16-bit pixel values
    --          ^    ^  ^    ^     ^     ^    height (pixels)
    --          ^    ^  ^    ^     ^     width (pixels)
    --          ^    ^  ^    ^     y offset (pixels)
    --          ^    ^  ^    x offset (pixels)
    --          ^    ^  screen id
    --          ^    callback id?
    --          command id
    --------------------------------------------------------------------------------

    if type(frame) == "function" then
        callbackFn = frame
        frame = nil
    end

    frame = frame or {}

    if type(imageBytes) == "userdata" then
        imageBytes = imageBytes:getLoupedeckArray()
    end

    if screen.prepareImage then
        imageBytes = screen:prepareImage(imageBytes)
    end

    local imageSuccess = false

    if sendCommand(
        0xFF10,
        function(response)
            imageSuccess = bytes.read(response.data, int8) == 0x01
        end,
        int16be(screen.id),
        int16be(frame.x or 0),
        int16be(frame.y or 0),
        int16be(frame.w or screen.width),
        int16be(frame.h or screen.height),
        imageBytes
    ) then
        return mod.refreshScreen(screen, callbackFn and function(response)
            response.success = imageSuccess and (bytes.read(response.data, int8) == 0x01)
        end)
    end
    return false
end

-- solidColorImage(width, height, color) -> string
-- Function
-- Creates a solid-color image for the specified screen with the specified RGB value.
--
-- Parameters:
-- * w      - the width, in pixels.
-- * h      - the height, in pixels.
-- * color  - either a 16-bit RGB integer or a `hs.drawing.color` table.
--
-- Returns:
-- * A byte string containing the image data for the provided with/height
local function solidColorBytes(width, height, color)
    local color16 = toInt16Color(color)
    local colorBytes = int16be(color16)
    local result = {}
    for i=1,width*height do
        result[i] = colorBytes
    end
    return concat(result)
end

--- hs.loupedeckct.updateScreenColor(screen, color[, callbackFn]) -> boolean
--- Function
--- Sends an image to the specified screen and refreshes the specified screen.
---
--- Parameters:
---  * screen       - the `screen` to update, from [hs.loupedeck.screens](#screens) (eg `hs.loupedeck.screens.left`)
---  * color        - either a 16-bit RGB integer or an `hs.drawing.color
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---  * frame        - (optional) An optional `hs.geometry.rect` object
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, `success`.
--- * the `success` value is a boolean, `true` or `false`.
function mod.updateScreenColor(screen, color, frame, callbackFn)
    frame = frame or {}
    return mod.updateScreenImage(
        screen,
        solidColorBytes(frame.w or screen.width, frame.h or screen.height, color),
        frame,
        callbackFn
    )
end

--- hs.loupdeckct.buttonID -> table
--- Constant
--- Contains IDs for the various buttons on the Loupdeck CT.
---
--- Notes:
---  * The buttonID's are as follows:
---   * `B0`-`B8`   - 0-8 buttons
---   * `UNDO`      - Undo button
---   * `KEYBOARD`  - Keyboard button
---   * `RETURN`    - Return button
---   * `SAVE`      - Save button
---   * `LEFT_FN`   - Left Fn/lock button
---   * `RIGHT_FN`  - Right Fn/lock button
---   * `A`         - A button
---   * `B`         - B button
---   * `C`         - C button
---   * `D`         - D button
---   * `E`         - E button

mod.buttonID = {
    -- buttons 0-8
    B0 = 15, B1 = 7, B2 = 8, B3 = 9, B4 = 10, B5 = 11, B6 = 12, B7 = 13, B8 = 14,

    UNDO = 16,
    KEYBOARD = 17,
    RETURN = 18,
    SAVE = 19,
    LEFT_FN = 20,
    RIGHT_FN = 23,
    A = 21,
    B = 24,
    C = 22,
    D = 25,
    E = 26,
}

--- hs.loupedeckct.buttonColor(buttonID, color[, callbackFn]) -> boolean
--- Function
--- Changes a button color.
---
--- Parameters:
---  * buttonID     - The ID of the [button](#buttonID).
---  * color        - Either a 24-bit integer or a `hs.drawing.color` table.
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, `success`.
--- * the `success` value is a boolean, `true` or `false`.
function mod.buttonColor(buttonID, color, callbackFn)
    --------------------------------------------------------------------------------
    -- COMMAND: 07 02 FA 00 00 00 00
    --                ^  ^  ^  ^  ^
    --                ^  ^  ^  ^  blue
    --                ^  ^  ^  green
    --                ^  ^  red
    --                ^  button id
    --                callback id
    --------------------------------------------------------------------------------
    color = toInt24Color(color)

    return sendCommand(
        0x0702,
        callbackFn and function(response)
            response.success = response.id == 0x0302
            callbackFn(response)
        end,
        int8(buttonID),
        int24be(color)
    )
end

--- hs.loupedeckct.vibrate([callbackFn]) -> boolean
--- Function
--- Requests the Loupedeck to vibrate.
---
--- Parameters:
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
--- * the `response` contains the `id`, `data`, `success`.
--- * the `success` value is a boolean, `true` or `false`.
function mod.vibrate(callbackFn)
    -- Sending message (4): (4) 04-1B-6B-19
    -- Message sent (4): (4) 04-1B-6B-19
    -- Message received (4): (4) 04-1B-6B-01

    --------------------------------------------------------------------------------
    -- COMMAND: 04 1B 6B 19
    --          ^     ^  ^
    --          ^     ^  Vibra waveform index?
    --          ^     Callback ID
    --          Command ID
    --------------------------------------------------------------------------------

    return sendCommand(
        0x041B,
        callbackFn and function(response)
            response.success = int8(response.data) == 0x01
            callbackFn(response)
        end,
        int8(mod._vibraWaveformIndex)
    )
end

--- hs.loupedeckct.connect() -> boolean, errorMessage
--- Function
--- Connects to a Loupedeck CT.
---
--- Parameters:
---  * None
---
--- Returns:
---  * success - `true` on success, otherwise `nil`
---  * errorMessage - The error messages as a string or `nil` if `success` is `true`.
function mod.connect()
    local ip = findIPAddress()
    if not ip then
        return false, "Failed to find Loupedeck Network Interface."
    end

    local url = "ws://" .. ip .. ":80/"
    log.df("Connecting to websocket: %s", url)
    mod._websocket = websocket.new(url, websocketCallback)
end

--- hs.loupedeckct.autoConnect(enabled) -> None
--- Function
--- Automatically connect to the Loupedeck CT when connected.
---
--- Parameters:
---  * enabled - `true` or `false`
---
--- Returns:
---  * None
function mod.autoConnect(enabled)
    if enabled then
        mod._usbWatcher = usb.watcher.new(function(data)
            if data.productName == "LOUPEDECK device" then
                if data.eventType == "added" then
                    log.df("Loupedeck CT Connected")
                    timer.doAfter(2, function()
                        mod.connect()
                    end)
                elseif data.eventType == "removed" then
                    log.df("Loupedeck CT Disconnected")
                end
            end
        end):start()
    else
        if mod._usbWatcher then
            mod._usbWatcher:stop()
            mod._usbWatcher = nil
        end
    end
end

--- hs.loupedeckct.disconnect() -> none
--- Function
--- Disconnects from the Loupedeck CT
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.disconnect()
    if mod._websocket then
        mod._websocket:close()
        mod._websocket = nil
    end
end

--- hs.loupedeckct.test() -> none
--- Function
--- Sends data to all the screens and buttons for testing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.test()
    doAfter(0, function()
        local color = drawing.color.hammerspoon.red
        for id, button in pairs(mod.buttonID) do
            mod.buttonColor(button, color)
        end
        for id, screen in pairs(mod.screens) do
            mod.updateScreenColor(screen, color)
        end
    end)
    doAfter(5, function()
        local color = drawing.color.hammerspoon.green
        for id, button in pairs(mod.buttonID) do
            mod.buttonColor(button, color)
        end
        for id, screen in pairs(mod.screens) do
            mod.updateScreenColor(screen, color)
        end
    end)
    doAfter(10, function()
        local color = drawing.color.hammerspoon.blue
        for id, button in pairs(mod.buttonID) do
            mod.buttonColor(button, color)
        end
        for id, screen in pairs(mod.screens) do
            mod.updateScreenColor(screen, color)
        end
    end)
    doAfter(15, function()
        local color = drawing.color.hammerspoon.black
        for id, button in pairs(mod.buttonID) do
            mod.buttonColor(button, color)
        end
        mod.updateScreenColor(mod.screens.left, color)
        mod.updateScreenColor(mod.screens.right, color)

        mod.updateScreenImage(mod.screens.middle, hs.image.imageFromPath(cp.config.assetsPath .. "/middle.png"))
        mod.updateScreenImage(mod.screens.wheel, hs.image.imageFromPath(cp.config.assetsPath .. "/wheel.png"))
    end)
    doAfter(20, function()
        local color = drawing.color.hammerspoon.red
        for id, button in pairs(mod.buttonID) do
            mod.buttonColor(button, color)
        end
        mod.updateScreenColor(mod.screens.left, color)
        mod.updateScreenColor(mod.screens.right, color)
        for x=0, 3 do
            for y=0, 2 do
                mod.updateScreenImage(mod.screens.middle, hs.image.imageFromPath(cp.config.assetsPath .. "/button.png"), {x=x*90, y=y*90, w=90,h=90})
            end
        end
    end)
end

return mod