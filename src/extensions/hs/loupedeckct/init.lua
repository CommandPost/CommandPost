--- === hs.loupedeckct ===
---
--- Adds Loupedeck CT Support
---
--- Special thanks to William Viker & Håkon Nessjøen for their [NodeJS experiments](https://github.com/bitfocus/loupedeck-ct).

-- TODO:
--  [ ] Add control to enable/disable Bluetooth

--------------------------------------------------------------------------------
-- BLUETOOTH:
--
-- Message received (4): (4) 04-10-97-01
-- Message received (4): (4) 04-0F-98-01
-- WebSocket text message (37) '{"id":15,"name":"IsBluetoothEnabled"}'
-- Message 'IsBluetoothEnabled' responded in 0 ms
-- WebSocket response (63) '{
--   "id": 15,
--   "name": "IsBluetoothEnabled",
--   "data": false
-- }'
-- Message received (4): (4) 04-10-99-01
-- Message received (4): (4) 04-0F-9A-01
-- Message received (4): (4) 04-10-9B-01
-- Message received (4): (4) 04-0F-9C-01
-- Message received (4): (4) 04-10-9D-01
-- Message received (4): (4) 04-0F-9E-01
--------------------------------------------------------------------------------

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
local int8              = bytes.int8
local uint16be          = bytes.uint16be
local uint24be          = bytes.uint24be
local uint32be          = bytes.uint32be
local uint8              = bytes.uint8

local remainder         = bytes.remainder

local mod               = {}

-- callbackRegister -> table
-- Variable
-- A table of registered callbacks
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
        bytes(uint16be(commandID), uint8(registerCallback(callbackFn)), ...):bytes()
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

-- initaliseDevice() -> None
-- Function
-- Starts the background loop, performs self-test and resets screens and buttons.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function initaliseDevice()
    -- This must be executed before writing to the main Touch Screen:
    mod.resetDevice()

    -- Reset all the buttons to black:
    local black = 0x000000
    for _,id in pairs(mod.buttonID) do
        mod.buttonColor(id, black)
    end

    -- Reset all the screens to black:
    local b = drawing.color.hammerspoon.black
    for _, screen in pairs(mod.screens) do
        mod.updateScreenColor(screen, b)
    end

end

--- hs.loupedeckct.callback([callbackFn]) -> boolean
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

-- events -> table
-- Constant
-- A table containing functions triggered by websocket events.
local events = {
    --------------------------------------------------------------------------------
    -- WEBSOCKET OPENED:
    --------------------------------------------------------------------------------
    open = function()
        initaliseDevice()
        triggerCallback {
            action = "websocket_open",
        }
    end,

    --------------------------------------------------------------------------------
    -- WEBSOCKET CLOSED:
    --------------------------------------------------------------------------------
    closed = function()
        triggerCallback {
            action = "websocket_closed",
        }
    end,

    --------------------------------------------------------------------------------
    -- WEBSOCKET FAILED:
    --------------------------------------------------------------------------------
    fail = function(message)
        triggerCallback({
            action = "websocket_fail",
            error = message,
        })
    end,

    --------------------------------------------------------------------------------
    -- WEBSOCKET RECEIVED PONG:
    --------------------------------------------------------------------------------
    pong = function()
        triggerCallback {
            action = "websocket_pong",
        }
    end,

    --------------------------------------------------------------------------------
    -- WEBSOCKET RECEIVED MESSAGE:
    --------------------------------------------------------------------------------
    received = function(message)
        -- read the command ID, callback ID and the remainder of the message...
        local id, callbackID, data = bytes.read(message,
            uint16be, uint8, remainder
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
            elseif not mod.ignoreResponses[id] then
                log.ef("Unexpected command: id: %04x; callback: %02x; message:\n%s", id, callbackID, hexDump(message))
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
}

--- hs.loupedeckct.ignoreResponses -> table
--- Constant
--- A table of responses to ignore.
mod.ignoreResponses = {
    [0x0302] = true, -- Button Color confirmation
    [0x040F] = true, -- Screen Image Update confirmation
    [0x041B] = true, -- Vibration confirmation
    [0x0409] = true, -- Reset Device
}

-- convertXandYtoButtonID(x, y) -> number
-- Function
-- Converts X and Y coordinates into a button ID for the middle touch screen.
--
-- Parameters:
--  * x - The x-axis as a number
--  * y - The y-axis as a number
--
-- Returns:
--  * A button ID as a number. Left to right, top to bottom.
local function convertXandYtoButtonID(x, y)
    local button = 0
    -- First Row:
    if x >= 60 and x <= 140 then
        -- Top Row:
        if y >= 0 and y <= 100 then
            button = 1
        end

        -- Middle Row:
        if y >= 110 and y <= 170 then
            button = 5
        end

        -- Bottom Row:
        if y >= 200 and y <= 260 then
            button = 9
        end
    end

    -- Second Row:
    if x >= 160 and x <= 230 then
        -- Top Row:
        if y >= 0 and y <= 100 then
            button = 2
        end

        -- Middle Row:
        if y >= 110 and y <= 170 then
            button = 6
        end

        -- Bottom Row:
        if y >= 200 and y <= 260 then
            button = 10
        end
    end

    -- Third Row:
    if x >= 240 and x <= 320 then
        -- Top Row:
        if y >= 0 and y <= 100 then
            button = 3
        end

        -- Middle Row:
        if y >= 110 and y <= 170 then
            button = 7
        end

        -- Bottom Row:
        if y >= 200 and y <= 260 then
            button = 11
        end
    end

    -- Fourth Row:
    if x >= 340 and x <= 390 then
        -- Top Row:
        if y >= 0 and y <= 100 then
            button = 4
        end

        -- Middle Row:
        if y >= 110 and y <= 170 then
            button = 8
        end

        -- Bottom Row:
        if y >= 200 and y <= 260 then
            button = 12
        end
    end
    return button
end

--- hs.loupedeckct.responseHandler -> table
--- Constant
--- Set of response handlers for device-generated events.
mod.responseHandler = {
    --------------------------------------------------------------------------------
    -- BUTTON PRESS/RELEASE:
    --
    -- Examples:
    -- 07 00        Down
    -- 07 01        Up
    --------------------------------------------------------------------------------
    [mod.event.BUTTON_PRESS] = function(response)
        local id, dirByte = bytes(response.data):read(int8, int8)
        if dirByte == 0x00 then
            response.direction = "down"
        elseif dirByte == 0x01 then
            response.direction = "up"
        else
            log.ef("Invalid Button Direction: %02x", dirByte)
            return
        end
        response.buttonID = id
        triggerCallback(response)
    end,

    --------------------------------------------------------------------------------
    -- ENCODER ROTATION:
    --
    -- Examples:
    -- 01 01    Right
    -- 01 FF    Left
    --------------------------------------------------------------------------------
    [mod.event.ENCODER_MOVE] = function(response)
        local id, dirByte = bytes.read(response.data, uint8, int8)
        if dirByte == -1 then
            response.direction = "left"
        elseif dirByte == 1 then
            response.direction = "right"
        else
            log.ef("Invalid Encoder Direction: %02x", dirByte)
            return
        end
        response.buttonID = id
        triggerCallback(response)
    end,

    --------------------------------------------------------------------------------
    -- WHEEL PRESSED:
    --
    -- Example:
    -- 00 00 7E 00 76 00
    --------------------------------------------------------------------------------
    [mod.event.WHEEL_PRESSED] = function(response)
        response.multitouch, response.x, response.y, response.unknown = bytes.read(response.data, uint8, int16be, int16be, uint8)
        response.multitouch = response.multitouch == 0x01
        triggerCallback(response)
    end,

    --------------------------------------------------------------------------------
    -- WHEEL RELEASED:
    --
    -- Example:
    -- 00 00 7B 00 94 00
    --------------------------------------------------------------------------------
    [mod.event.WHEEL_RELEASED] = function(response)
        response.multitouch, response.x, response.y, response.unknown = bytes.read(response.data, uint8, int16be, int16be, uint8)
        response.multitouch = response.multitouch == 0x01
        triggerCallback(response)
    end,

    --------------------------------------------------------------------------------
    -- SCREEN PRESSED:
    --
    -- Example:
    -- 00 01 C9 00 9A 27
    --------------------------------------------------------------------------------
    [mod.event.SCREEN_PRESSED] = function(response)
        response.multitouch, response.x, response.y, response.pressure = bytes.read(response.data, uint8, int16be, int16be, uint8)

        -- Get button ID:
        local buttonID = convertXandYtoButtonID(response.x, response.y)
        if buttonID > 0 then
            response.buttonID = buttonID
        end

        triggerCallback(response)
        -- Vibrate if enabled:
        if mod._vibrations then
            mod.vibrate()
        end
    end,

    --------------------------------------------------------------------------------
    -- SCREEN RELEASED:
    --
    -- Example:
    -- 00 01 BC 00 BE 25
    --------------------------------------------------------------------------------
    [mod.event.SCREEN_RELEASED] = function(response)
        response.multitouch, response.x, response.y, response.pressure = bytes.read(response.data, uint8, int16be, int16be, uint8)

        -- Get button ID:
        local buttonID = convertXandYtoButtonID(response.x, response.y)
        if buttonID > 0 then
            response.buttonID = buttonID
        end

        triggerCallback(response)
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
---  * callbackFn - Optional function to call when the device responds, receiving a data table containing `id` and `message`.
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
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
---  * the `response` contains the `id`, `data`,
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
---  * the `response` contains the `id`, `data`, and `serialNumber`
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
---  * the `response` contains the `id`, `data`, and `mcuid`
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
---  * the `response` contains the `id`, `data`, and `selfTest`.
---  * The `selfTest` value is the `data` read as a 32-bit big-endian integer.
function mod.requestSelfTest(callbackFn)
    return sendCommand(0x0304, callbackFn and function(response)
        --------------------------------------------------------------------------------
        -- Sending message (3): (3) 03-04-05
        -- Message sent (3): (3) 03-04-05
        -- Message received (7): (7) 07-04-05-BF-00-3F-00
        -- Self-tests: 0x003F00BF
        --
        -- for some reason, the result is read back in little-endian.
        -- Testing which way the OS works?
        --------------------------------------------------------------------------------
        response.selfTest = bytes.read(response.data, bytes.int32le)
        callbackFn(response)
    end)
end

-- function processRegisterResponse(response) -> nil
-- function
-- Receives the raw value of a register and interprets it, adding properties to the `response` table.
--
-- Parameters:
--  * response - the response from the websocket call.
--
-- Returns:
--  * the updated `response` table.
--
-- Notes:
--  * Adds `flashDriveEnabled` for register `0` responses.
--  * Adds `vibraWaveformIndex` and `backlightLevel` for register `2` responses.
local function processRegisterResponse(response)
    response.registerID, response.value = bytes.read(response.data, uint8, uint32be)
    if response.registerID == 0 then
        --------------------------------------------------------------------------------
        -- 00 00 00 00 03       flash disabled
        -- ^  ^        ^
        -- ^  ^        flash status (03 disabled/02 enabled)
        -- ^  unknown
        -- register id
        --------------------------------------------------------------------------------
        response.flashDriveEnabled = (response.value & 0x01) ~= 0x01
    --elseif registerID == 1 then
        --------------------------------------------------------------------------------
        -- TODO: FIND OUT WHAT THIS IS:
        --
        -- 01 00 01 00 00
        --------------------------------------------------------------------------------
    elseif response.registerID == 2 then
        --------------------------------------------------------------------------------
        -- 03 00 09 19
        -- ^  ^  ^  ^
        -- ^  ^  ^  vibra waveform index: 25 (0x19)
        -- ^  ^  backlight level: 9 (0x09)
        -- ^  unknown
        -- unknown
        --------------------------------------------------------------------------------
        response.vibraWaveformIndex = response.value & 0xFF
        response.backlightLevel = (response.value >> 8) & 0xFF
    end
    return response
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
---  * the `response` contains the `id`, `data`, `registerID`, and `value`.
---  * the `registerID` should be the same value as the `registerID` parameter you passed in.
---  * the `value` value is the `data` read as a 32-bit big-endian integer.
---  * if requesting register `2`, it will also have the `backlightLevel` and `vibraWaveformIndex` values.
function mod.requestRegister(registerID, callbackFn)
    --------------------------------------------------------------------------------
    -- 04 1A 01 01
    -- ^     ^  ^
    -- ^     ^  register number
    -- ^     callback ID
    -- command ID
    --------------------------------------------------------------------------------
    return sendCommand(
        0x041A,
        callbackFn and function(response)
            processRegisterResponse(response)
            callbackFn(response)
        end,
        uint8(registerID)
    )
end

--- hs.loupedeckct.updateRegister(registerID, value[, callbackFn]) -> boolean
--- Function
--- Sends a new value to the Loupedeck CT for the specified register value.
---
--- Parameters:
---  * registerID - The register to update (0/1/2)
---  * value      - a 32-bit integer value for the register
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
---  * The Loupedeck CT needs to be powered cycled for the drive to be mounted.
function mod.updateRegister(registerID, value, callbackFn)
    if registerID < 0 or registerID > 2 then
        error(format("expected registerID of 0/1/2 but got %d", registerID), 2)
    end
    if type(value) ~= "number" then
        error(format("expected value to be a number, but was %s", type(value)))
    end
    --------------------------------------------------------------------------------
    -- UPDATE REGISTER 0/1/2:
    --
    -- Example:
    -- 08 19 58 00 00 00 00 02
    -- ^     ^  ^  ^
    -- ^     ^  ^  new uint32be value for the register
    -- ^     ^  the register number (0/1/2)
    -- ^     the callback ID
    -- the command ID
    --------------------------------------------------------------------------------
    return sendCommand(
        0x0819,
        callbackFn and function(response)
            processRegisterResponse(response)
            callbackFn(response)
        end,
        uint8(registerID),
        uint32be(value)
    )
end

--- hs.loupedeckct.updateFlashDrive(enabled[, callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT to enable or disable the Flash Drive.
---
--- Parameters:
---  * enabled - `true` to enable otherwise `false`
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
---  * The Loupedeck CT needs to be powered cycled for the drive to be mounted.
function mod.updateFlashDrive(enabled, callbackFn)
    --------------------------------------------------------------------------------
    -- FLASH DRIVE STATUS:
    --
    -- 00 00 00 00 03       flash disabled
    -- 00 00 00 00 02       flash enabled
    --
    -- Note: best guess is that the last bit (0x01) is the flash enabled/disabled value
    -- while the second last bit (0x02) is for something else.
    --------------------------------------------------------------------------------
    return mod.requestRegister(0, function(response)
        processRegisterResponse(response)
        if response.flashDriveEnabled ~= enabled then
            local value = response.value
            value = enabled and (value - 0x01) or (value + 0x01)
            mod.updateRegister(0, value, callbackFn)
        elseif callbackFn then
            callbackFn(response)
        end
    end)
end

--- hs.loupedeckct.updateVibraWaveformIndex(value[, callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT to update the Vibra waveform index.
---
--- Parameters:
---  * value - an 8-bit number with the new vibra waveform index.
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
---  * The Loupedeck CT needs to be powered cycled for the drive to be mounted.
function mod.updateVibraWaveformIndex(value, callbackFn)
    return mod.requestRegister(2, function(response)
        processRegisterResponse(response)
        if response.vibraWaveformIndex ~= value then
            local mask = 0xFFFFFF00
            local newValue = (response.value & mask) + value
            mod.updateRegister(2, newValue, callbackFn)
        elseif callbackFn then
            callbackFn(response)
        end
    end)
end

--- hs.loupedeckct.updateBacklightLevel(value[, callbackFn]) -> boolean
--- Function
--- Sends a request to the Loupedeck CT to update the Vibra waveform index.
---
--- Parameters:
---  * value - an 8-bit number with the new backlight level.
---  * callbackFn - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
---  * The Loupedeck CT needs to be powered cycled for the drive to be mounted.
function mod.updateBacklightLevel(value, callbackFn)
    return mod.requestRegister(2, function(response)
        processRegisterResponse(response)
        if response.backlightLevel ~= value then
            local mask = 0xFFFF00FF
            local newValue = (response.value & mask) + (value << 8)
            mod.updateRegister(2, newValue, callbackFn)
        elseif callbackFn then
            callbackFn(response)
        end
    end)
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
---  * the `response` contains the `id`, `data`, `wheelSensitivity`.
function mod.requestWheelSensitivity(callbackFn)
    return sendCommand(
        0x041E,
        callbackFn and function(response)
            response.wheelSensitivity = uint8(response.data)
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
---  * the `response` contains the `id`, `data`, `success`.
---  * the `success` value is a boolean, `true` or `false`.
function mod.resetDevice(callbackFn)
    return sendCommand(
        0x0409,
        callbackFn and function(response)
            response.success = bytes.read(response.data, uint8) == 0x01
            callbackFn(response)
        end,
        uint8(9) -- not sure why we're sending 9? type of reset?
    )
end

--- hs.loupedeckct.screens -> table
--- Constant
--- The set of screens available: `left`, `right`, `middle`, and `wheel`.
---
--- Notes:
---  * each screen has an `id`, a `width`, and a `height` value.
---  * the `id` is how the Loupedeck CT identifies the screen.
---  * the `width` and `height` are in pixels.
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
        circular = true,
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
---  * the `response` contains the `id`, `data`, `success`.
---  * the `success` value is a boolean, `true` or `false`.
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
            response.success = bytes.read(response.data, uint8) == 0x01
            callbackFn(response)
        end,
        uint16be(screen.id)
    )
end

--- hs.loupedeckct.updateScreenImage(screen, imageBytes[, frame][, callbackFn]) -> boolean
--- Function
--- Sends an image to the specified screen and refreshes the specified screen.
---
--- Parameters:
---  * screen       - the `screen` to update, from [hs.loupedeck.screens](#screens) (eg `hs.loupedeck.screens.left`)
---  * imageBytes   - the byte string for the image in the custom Loupedeck 16-bit RGB format or a `hs.image` object
---  * frame        - (optional) An optional `hs.geometry.rect` object
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
---  * the `response` contains the `id`, `data`, `success`.
---  * the `success` value is a boolean, `true` or `false`.
function mod.updateScreenImage(screen, imageBytes, frame, callbackFn)
    --------------------------------------------------------------------------------
    -- COMMAND: FF10 XX 004C 00 00 00 00 003C 010E (00) FFFF FFFF ....
    --          ^    ^  ^    ^     ^     ^    ^    ^    ^
    --          ^    ^  ^    ^     ^     ^    ^    ^    16-bit pixel values
    --          ^    ^  ^    ^     ^     ^    ^    Unknown, only present for circular displays.
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

    local imageSuccess = false

    if sendCommand(
        0xFF10,
        function(response)
            imageSuccess = bytes.read(response.data, uint8) == 0x01
        end,
        uint16be(screen.id),
        int16be(frame.x or 0),
        int16be(frame.y or 0),
        int16be(frame.w or screen.width),
        int16be(frame.h or screen.height),
        screen.circular and uint8(0) or "",
        imageBytes
    ) then
        return mod.refreshScreen(screen, callbackFn and function(response)
            response.success = imageSuccess and (bytes.read(response.data, uint8) == 0x01)
        end)
    end
    return false
end

-- convertButtonIDtoXYCoordinates() -> buttonID
-- Function
-- Gets the X and Y coordinates of a specific button on the middle touch screen.
--
-- Parameters:
--  * buttonID - A number between 1 and 12 (left to right, top to bottom).
--
-- Returns:
--  * x - The x coordinates of the screen for the specific button as a number
--  * y - The y coordinates of the screen for the specific button as a number
local function convertButtonIDtoXYCoordinates(buttonID)
    return floor(((buttonID-1) % 4)) * 90, floor(((buttonID-1) / 4)) * 90
end

--- hs.loupedeckct.updateScreenButtonImage(buttonID, imageBytes[, callbackFn]) -> boolean
--- Function
--- Sends an image to the specified button on the middle screen.
---
--- Parameters:
---  * buttonID     - The button number (left to right, top to bottom)
---  * imageBytes   - the byte string for the image in the custom Loupedeck 16-bit RGB format or a `hs.image` object
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
---  * the `response` contains the `id`, `data`, `success`.
---  * the `success` value is a boolean, `true` or `false`.
function mod.updateScreenButtonImage(buttonID, imageBytes, callbackFn)
    local x, y = convertButtonIDtoXYCoordinates(buttonID)
    mod.updateScreenImage(mod.screens.middle, imageBytes, {x=x, y=y, w=90,h=90}, callbackFn)
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
    local colorBytes = uint16be(color16)
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
---  * frame        - (optional) An optional `hs.geometry.rect` object
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
---  * the `response` contains the `id`, `data`, `success`.
---  * the `success` value is a boolean, `true` or `false`.
function mod.updateScreenColor(screen, color, frame, callbackFn)
    frame = frame or {}
    return mod.updateScreenImage(
        screen,
        solidColorBytes(frame.w or screen.width, frame.h or screen.height, color),
        frame,
        callbackFn
    )
end

--- hs.loupedeckct.updateScreenButtonColor(buttonID, color[, callbackFn]) -> boolean
--- Function
--- Sends an image to the specified screen and refreshes the specified screen.
---
--- Parameters:
---  * buttonID     - The button number (left to right, top to bottom)
---  * color        - either a 16-bit RGB integer or an `hs.drawing.color
---  * callbackFn   - (optional) Function called with a `response` table as the first parameter
---
--- Returns:
---  * `true` if the device is connected and the message was sent.
---
--- Notes:
---  * the `response` contains the `id`, `data`, `success`.
---  * the `success` value is a boolean, `true` or `false`.
function mod.updateScreenButtonColor(buttonID, color, callbackFn)
    local x, y = convertButtonIDtoXYCoordinates(buttonID)
    mod.updateScreenColor(mod.screens.middle, color, {x=x, y=y, w=90,h=90}, callbackFn)
end

--- hs.loupdeckct.buttonID -> table
--- Constant
--- Contains IDs for the various buttons on the Loupdeck CT.
---
--- Notes:
---  * The buttonID's are as follows:
---   * `B1`-`B8`   - 1-8 buttons
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
---   * `O`         - O button
mod.buttonID = {
    B1 = 7,
    B2 = 8,
    B3 = 9,
    B4 = 10,
    B5 = 11,
    B6 = 12,
    B7 = 13,
    B8 = 14,

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
    O = 15,
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
---  * the `response` contains the `id`, `data`, `success`.
---  * the `success` value is a boolean, `true` or `false`.
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
        uint8(buttonID),
        uint24be(color)
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
---  * the `response` contains the `id`, `data`, `success`.
---  * the `success` value is a boolean, `true` or `false`.
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
            response.success = uint8(response.data) == 0x01
            callbackFn(response)
        end,
        uint8(0x19)
    )
end

local function updateWatcher(enabled)
    if enabled then
        if not mod._usbWatcher then
            mod._usbWatcher = usb.watcher.new(function(data)
                if data.productName == "LOUPEDECK device" then
                    if data.eventType == "added" then
                        --log.df("Loupedeck CT Connected")
                        doAfter(4, function()
                            mod.connect(true)
                        end)
                    --elseif data.eventType == "removed" then
                        --log.df("Loupedeck CT Disconnected")
                    end
                end
            end):start()
        end
    else
        if mod._usbWatcher then
            mod._usbWatcher:stop()
            mod._usbWatcher = nil
        end
    end
end

--- hs.loupedeckct.vibrations(enabled) -> boolean
--- Function
--- Gets or sets vibrations on button presses.
---
--- Parameters:
---  * enabled - An optional boolean which sets whether or not vibrations are enabled
---
--- Returns:
---  * `true` if enabled, otherwise `false`
function mod.vibrations(enabled)
    if type(enabled) ~= nil then
        mod._vibrations = enabled == true or false
    end
    return mod._vibrations
end

--- hs.loupedeckct.connect(retry) -> boolean, errorMessage
--- Function
--- Connects to a Loupedeck CT.
---
--- Parameters:
---  * retry - `true` if you want to keep trying to connect, otherwise `false`
---
--- Returns:
---  * None
---
--- Notes:
---  * The callback with an action of "failed_to_find_device" will trigger
---    if the device cannot be connected to.
function mod.connect(retry)
    --------------------------------------------------------------------------------
    -- Setup retry watchers:
    --------------------------------------------------------------------------------
    updateWatcher(retry)

    --------------------------------------------------------------------------------
    -- Find the Loupedeck CT Device:
    --------------------------------------------------------------------------------
    local ip = findIPAddress()
    if not ip then
        if retry then
            doAfter(2, function()
                mod.connect(true)
            end)
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Attempt to connect:
    --------------------------------------------------------------------------------
    local url = "ws://" .. ip .. ":80/"
    --log.df("Connecting to Loupedeck CT: %s", url)
    mod._websocket = websocket.new(url, websocketCallback)
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

        -- Destroy any watchers:
        updateWatcher()
    end
end

return mod
