--- === hs.loupedeckct ===
---
--- Adds Loupedeck CT Support

--[[
EXAMPLE USAGE:

ct = require "hs.loupedeckct"
ct.callback(function(data) print(string.format("data: %s", hs.inspect(data))) end)
ct.connect()
--]]

local log               = require "hs.logger".new("loupedeckct", 5)

local canvas            = require "hs.canvas"
local drawing           = require "hs.drawing"
local hsmath            = require "hs.math"
local network           = require "hs.network"
local timer             = require "hs.timer"
local usb               = require "hs.usb"
local utf8              = require "hs.utf8"
local websocket         = require "hs.websocket"

local doAfter           = timer.doAfter
local hexDump           = utf8.hexDump
local randomFromRange   = hsmath.randomFromRange

local mod               = {}

local callbackRegister  = {}

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

-- send() -> none
-- Function
-- Sends a message via the websocket if connected
--
-- Parameters:
--  * message - The message to send.
--
-- Returns:
--  * None
local function send(message)
    if connected() then
        --log.df("Sending: %s", message)
        mod._websocket:send(message)
    end
end

-- fromHex(str) -> string
-- Function
-- Converts a hex string representation to hex data
--
-- Parameters:
--  * str - The string to process
--
-- Returns:
--  * A string
local function fromHex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function tohex(str)
    return (str:gsub('.', function (c)
       return string.format('%02X', string.byte(c))
    end))
end

-- decimalToHex(v) -> string
-- Function
-- Converts a decimal number to a hex string
--
-- Parameters:
--  * v - Number to convert
--
-- Returns:
--  * Hex string
local function decimalToHex(v)
    return string.format("%02x", v)
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
    send(fromHex("130e013da81c9ba72a8c87d4f6a135a289066c")) -- Starting background loop
    send(fromHex("131c0261f1392a8e936ba66e992daedb40f65f")) -- Getting device information?
    send(fromHex("030703")) -- Request Serial Number
    send(fromHex("030d04")) -- Request MCU ID
    send(fromHex("030405")) -- Request Self Tests
    send(fromHex("041a0700")) -- Register 0
    send(fromHex("041a0801")) -- Register 1
    send(fromHex("041a0902")) -- Register 2
    send(fromHex("041e0a00")) -- Wheel sensitivity: 4 ???
    send(fromHex("04090b03")) -- Reset Device???

    --------------------------------------------------------------------------------
    -- COMMAND: 07 02 FA 00 00 00 00
    --                            ^
    --                ^  ^  ^  ^  blue
    --                ^  ^  ^  green
    --                ^  ^  red
    --                ^  button id
    --                callback id
    --------------------------------------------------------------------------------
    -- Reset all the buttons to black.
    for i=12, 31 do
        callbackRegister[i] = function() -- Do nothing end
    end
    send(fromHex("07020c07000000"))
    send(fromHex("07020d08000000"))
    send(fromHex("07020e09000000"))
    send(fromHex("07020f0a000000"))
    send(fromHex("0702100b000000"))
    send(fromHex("0702110c000000"))
    send(fromHex("0702120d000000"))
    send(fromHex("0702130e000000"))
    send(fromHex("0702140f000000"))
    send(fromHex("07021510000000"))
    send(fromHex("07021611000000"))
    send(fromHex("07021712000000"))
    send(fromHex("07021813000000"))
    send(fromHex("07021914000000"))
    send(fromHex("07021a15000000"))
    send(fromHex("07021b16000000"))
    send(fromHex("07021c17000000"))
    send(fromHex("07021d18000000"))
    send(fromHex("07021e19000000"))
    send(fromHex("07021f1a000000"))
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
        log.ef("Callback recieved an invalid type: %s", type(callbackFn))
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
    --------------------------------------------------------------------------------
    -- WEBSOCKET OPENED:
    --------------------------------------------------------------------------------
    if event == "open" then
        mod._connected = true

        -- Initialise the big screen:
        initaliseDevice()

        triggerCallback({
            ["action"] = "open",
        })
    --------------------------------------------------------------------------------
    -- WEBSOCKET CLOSED:
    --------------------------------------------------------------------------------
    elseif event == "closed" then
        mod._connected = false

        triggerCallback({
            ["action"] = "closed",
        })
    --------------------------------------------------------------------------------
    -- WEBSOCKET FAILED:
    --------------------------------------------------------------------------------
    elseif event == "fail" then
        mod._connected = false

        triggerCallback({
            ["action"] = "fail",
            ["error"] = message,
        })
    --------------------------------------------------------------------------------
    -- WEBSOCKET RECIEVED PONG:
    --------------------------------------------------------------------------------
    elseif event == "pong" then
        log.df("PONG RECEIVED!")
        triggerCallback({
            ["action"] = "pong",
        })
    --------------------------------------------------------------------------------
    -- WEBSOCKET RECIEVED MESSAGE:
    --------------------------------------------------------------------------------
    elseif event == "recieved" then
        --------------------------------------------------------------------------------
        -- BUTTON EVENTS:
        --------------------------------------------------------------------------------
        local command = message:byte(1)
        local subchar = message:byte(2)
        if command == 0x05 and subchar == 0x00 then
            local id = message:byte(4)
            local dirByte = message:byte(5)

            local direction
            if dirByte == 0x00 then
                direction = "down"
            elseif dirByte == 0x01 then
                direction = "up"
            else
                log.ef("Invalid Button Direction: %s", dirByte)
            end
            if direction then
                triggerCallback({
                    ["action"] = "button_press",
                    ["id"] = id,
                    ["direction"] = direction,
                })
            end
        --------------------------------------------------------------------------------
        -- ENCODER EVENTS:
        --------------------------------------------------------------------------------
        elseif command == 0x05 and subchar == 0x01 then
            local id = message:byte(4)
            local dirByte = message:byte(5)
            local direction
            if dirByte == 0xFF then
                direction = "left"
            elseif dirByte == 0x01 then
                direction = "right"
            else
                log.ef("Invalid Encoder Direction: %s", dirByte)
            end
            if direction then
                triggerCallback({
                    ["action"] = "encoder_step",
                    ["id"] = id,
                    ["direction"] = direction,
                })
            end
        --------------------------------------------------------------------------------
        -- TOUCH EVENTS:
        --------------------------------------------------------------------------------
        elseif command == 0x09 then
            --------------------------------------------------------------------------------
            -- BIG WHEEL:
            --------------------------------------------------------------------------------
            if subchar == 0x52 or subchar == 0x72 then
                local x = message:byte(6)
                local y = message:byte(8)
                local direction
                if subchar == 0x52 then
                    direction = "pressed"
                else
                    direction = "released"
                end
                triggerCallback({
                    ["action"] = "wheel_touch",
                    ["x"] = x,
                    ["y"] = y,
                    ["direction"] = direction,
                    ["eventID"] = 0,
                })
            --------------------------------------------------------------------------------
            -- MAIN TOUCH SCREEN:
            --------------------------------------------------------------------------------
            elseif subchar == 0x4D or subchar == 0x6D then
                local x = message:byte(5)
                local y = message:byte(7)
                local eventID = message:byte(9)
                local direction
                if subchar == 0x4D then
                    direction = "pressed"
                else
                    direction = "released"
                end
                triggerCallback({
                    ["action"] = "screen_touch",
                    ["x"] = x,
                    ["y"] = y,
                    ["direction"] = direction,
                    ["eventID"] = eventID,
                })
            else
                log.ef("Unknown Touch Event: %s", hexDump(message))
            end
        --------------------------------------------------------------------------------
        -- SERIAL NUMBER:
        --------------------------------------------------------------------------------
        elseif command == 0x1F then
            local serialNumber = message:sub(3)
            triggerCallback({
                ["action"] = "serialNumber",
                ["serialNumber"] = serialNumber,
            })
        --------------------------------------------------------------------------------
        -- FIRMWARE VERSION:
        --
        -- Message sent (3): (3) 03-07-03
        -- Message received (12): (12) 0C-07-03-00-00-08-00-09-00-01-00-0A
        -- Firmware version 'B': '0.0.8'
        -- Firmware version 'C': '0.9.0'
        -- Firmware version 'I': '1.0.10'
        --------------------------------------------------------------------------------
        elseif command == 0x0C and subchar == 0x07 then
            triggerCallback({
                ["action"] = "firmwareVersion",
                ["B"] = message:byte(4) .. "." .. message:byte(5) .. "." .. message:byte(6),
                ["C"] = message:byte(7) .. "." .. message:byte(8) .. "." .. message:byte(9),
                ["I"] = message:byte(10) .. "." .. message:byte(11) .. "." .. message:byte(12),
            })
        --------------------------------------------------------------------------------
        -- MCU ID:
        --------------------------------------------------------------------------------
        elseif command == 0x0F and subchar == 0x0D then
            triggerCallback({
                ["action"] = "mcuID",
                ["mcuID"] = tohex(message):sub(7),
            })
        --------------------------------------------------------------------------------
        -- SELF TEST:
        --
        -- Message sent (3): (3) 03-04-05
        -- Message received (7): (7) 07-04-05-BF-00-3F-00
        -- Self-tests: 0x003F00BF
        --------------------------------------------------------------------------------
        elseif command == 0x07 then
            triggerCallback({
                ["action"] = "selfTest",
                ["result"] = tohex(message):sub(5),
            })
        --------------------------------------------------------------------------------
        -- LOOP BACK CONFIRMATION:
        --
        -- Starting background loop (100.127.24.1:80)
        -- Sending message (19): (19) 13-0E-01-53-B7-00-6D-1C-3F-98-C1-D0-80-5C-50-B7 ...
        -- Message sent (19): (19) 13-0E-01-53-B7-00-6D-1C-3F-98-C1-D0-80-5C-50-B7-F2-0C-E7
        -- Message received (19): (19) 13-0E-01-53-B7-00-6D-1C-3F-98-C1-D0-80-5C-50-B7 ...
        -- Loopback True
        --------------------------------------------------------------------------------
        elseif command == 0x13 and subchar == 0x0E then
            log.df("loop back confirmation")
        --------------------------------------------------------------------------------
        -- DEVICE INFORMATION:
        --
        -- Sending message (19): (19) 13-1C-02-7E-1E-38-CF-55-8B-2C-13-AB-14-64-71-1C ...
        -- Message sent (19): (19) 13-1C-02-7E-1E-38-CF-55-8B-2C-13-AB-14-64-71-1C-ED-B0-8A
        -- Message received (19): (19) 13-1C-02-64-42-AA-22-DC-81-7A-80-DB-E9-E7-31-03 ...
        -- Get device information
        --------------------------------------------------------------------------------
        elseif command == 0x13 and subchar == 0x1C then
            log.df("getting device information")
        --------------------------------------------------------------------------------
        -- WHEEL SENSITIVITY:
        --
        -- Sending message (4): (4) 04-1E-0A-00
        -- Message sent (4): (4) 04-1E-0A-00
        -- Message received (4): (4) 04-1E-0A-04
        -- Wheel sensitivity: 4
        --------------------------------------------------------------------------------
        elseif command == 0x04 and subchar == 0x1E then
            log.df("wheel sensitivity?")
        --------------------------------------------------------------------------------
        -- RESET DEVICE:
        --
        -- Resetting device
        -- Sending message (4): (4) 04-09-0B-09
        -- Message sent (4): (4) 04-09-0B-09
        -- Message received (4): (4) 04-09-0B-01
        --------------------------------------------------------------------------------
        elseif command == 0x04 and subchar == 0x09 then
            log.df("resetting device?")
        --------------------------------------------------------------------------------
        -- REGISTER CONFIRMATION:
        --------------------------------------------------------------------------------
        elseif command == 0x08 and subchar == 0x1A then
            --------------------------------------------------------------------------------
            -- REGISTER 0:
            --
            -- Sending message (4): (4) 04-1A-07-00
            -- Message sent (4): (4) 04-1A-07-00
            -- Message received (8): (8) 08-1A-07-00-00-00-00-02
            -- Register 0: 0x00000002
            --------------------------------------------------------------------------------
            if message:byte(3) == 0x07 then
                log.df("Register 0 Confirmed.")
            --------------------------------------------------------------------------------
            -- REGISTER 1:
            --
            -- Sending message (4): (4) 04-1A-08-01
            -- Message sent (4): (4) 04-1A-08-01
            -- Message received (8): (8) 08-1A-08-01-00-01-00-00
            -- Register 1: 0x00010000
            --------------------------------------------------------------------------------
            elseif message:byte(3) == 0x08 then
                log.df("Register 1 Confirmed.")
            --------------------------------------------------------------------------------
            -- REGISTER 2:
            --
            -- Sending message (4): (4) 04-1A-09-02
            -- Message sent (4): (4) 04-1A-09-02
            -- Message received (8): (8) 08-1A-09-02-02-00-09-00
            -- Register 2: 0x02000900
            --------------------------------------------------------------------------------
            elseif message:byte(3) == 0x09 then
                log.df("Register 2 Confirmed.")
            else
                log.ef("Unknown Register")
            end
        --------------------------------------------------------------------------------
        -- CONFIRMATION:
        --------------------------------------------------------------------------------
        elseif command == 0x03 then
            --log.wf("Unknown Confirmation Recieved:\n%s", hexDump(message))
            --------------------------------------------------------------------------------
            -- CHANGE BUTTON COLOR CONFIRMATION:
            --------------------------------------------------------------------------------
            if subchar == 0x02 then
                local id = message:byte(3)
                if id == 0x00 then
                    log.df("Button Message Confirmation with no callback assigned.")
                else
                    if callbackRegister[id] then
                        --log.df("Triggering callback with ID: %s", id)
                        callbackRegister[id]()
                        callbackRegister[id] = nil
                    else
                        log.ef("No valid callback found: %s", id)
                    end
                end
            end
        --------------------------------------------------------------------------------
        -- SCREEN CONFIRMATION:
        --------------------------------------------------------------------------------
        elseif command == 0x04 and subchar == 0x0f then
            --log.wf("Unknown Screen Confirmation Recieved:\n%s", hexDump(message))
            log.df("screen confirmation recieved")
        --------------------------------------------------------------------------------
        -- SCREEN CONFIRMATION:
        --
        -- Seems to be triggered after you send RGB data to the Loupedeck CT.
        --
        -- 04 10 26 00
        --------------------------------------------------------------------------------
        elseif command == 0x04 and subchar == 0x10 then
            log.df("confirmation that RGB data has been recieved?")
        --------------------------------------------------------------------------------
        -- UNKNOWN MESSAGE:
        --------------------------------------------------------------------------------
        else
            log.wf("Unknown Message Recieved: %s", hexDump(message))
        end
    end
end

--- hs.loupedeckct.requestSerialNumber() -> none
--- Function
--- Sends a request to the Loupedeck CT asking for its serial number.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.requestSerialNumber()
    send("\3\3\6")
end

--- hs.loupedeckct.requestFirmwareVersion() -> none
--- Function
--- Sends a request to the Loupedeck CT asking for its firmware versions.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.requestFirmwareVersion()
    send("\3\7\3")
end

--- hs.loupedeckct.requestMCUID() -> none
--- Function
--- Sends a request to the Loupedeck CT asking for its MCU ID.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.requestMCUID()
    send(fromHex("030D04"))
end

--- hs.loupedeckct.requestSelfTest() -> none
--- Function
--- Sends a request to the Loupedeck CT asking it to perform a self test.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.requestSelfTest()
    send(fromHex("030405"))
end

-- registerCallback(callbackFn) -> number
-- Function
-- Registers a callback.
--
--
-- Parameters:
--  * callbackFn - The callback function
--
-- Returns:
--  * A unique callback ID as a number
local function registerCallback(callbackFn)
    local id = randomFromRange(1, 256)
    while(callbackRegister[id])
    do
        id = randomFromRange(1, 256)
    end
    callbackRegister[id] = callbackFn
    return id
end

--------------------------------------------------------------------------------
--
-- SET SCREEN IMAGES:
--
--------------------------------------------------------------------------------

function mod.leftScreenImage(img)
    local drawStart = "ff1023004c00000000003c010e"
    local drawEnd = "050f23004c"
    local data = img:getLoupedeckArray()

    send(fromHex(drawStart) .. data)
    send(fromHex(drawEnd))
end

function mod.middleScreenImage(img)
    local drawStart = "ff10210041000000000168010e"
    local drawEnd = "050f210041"
    local data = img:getLoupedeckArray()

    send(fromHex(drawStart) .. data)
    send(fromHex(drawEnd))
end

function mod.rightScreenImage(img)
    local drawStart = "ff1024005200000000003c010e"
    local drawEnd = "050f240052"
    local data = img:getLoupedeckArray()

    send(fromHex(drawStart) .. data)
    send(fromHex(drawEnd))
end

function mod.wheelScreenImage(img)
    local drawStart = "ff102600570000000000f000f0"
    local drawEnd = "050f000057"
    local data = img:getLoupedeckArray()

    send(fromHex(drawStart) .. data)
    send(fromHex(drawEnd))
end

--------------------------------------------------------------------------------
--
-- SET SCREEN COLOURS:
--
--------------------------------------------------------------------------------

--[[
EXAMPLE CODE:
ct.leftScreenColor(hs.drawing.color.hammerspoon.green)
ct.middleScreenColor(hs.drawing.color.hammerspoon.green)
ct.rightScreenColor(hs.drawing.color.hammerspoon.green)
ct.wheelScreenColor(hs.drawing.color.hammerspoon.green)
--]]

function mod.leftScreenColor(colorObject)
    local c = canvas.new{x = 0, y = 0, w = 60, h = 270 }
    c[1] = {
      type = "rectangle",
      action = "fill",
      fillColor = colorObject,
    }
    local img = c:imageFromCanvas()
    mod.leftScreenImage(img)
end


function mod.middleScreenColor(colorObject)
    local c = canvas.new{x = 0, y = 0, w = 360, h = 270 }
    c[1] = {
      type = "rectangle",
      action = "fill",
      fillColor = colorObject,
    }
    local img = c:imageFromCanvas()
    mod.middleScreenImage(img)
end


function mod.rightScreenColor(colorObject)
    local c = canvas.new{x = 0, y = 0, w = 60, h = 270 }
    c[1] = {
      type = "rectangle",
      action = "fill",
      fillColor = colorObject,
    }
    local img = c:imageFromCanvas()
    mod.rightScreenImage(img)
end

function mod.wheelScreenColor(colorObject)
    local c = canvas.new{x = 0, y = 0, w = 240, h = 240 }
    c[1] = {
      type = "rectangle",
      action = "fill",
      fillColor = colorObject,
    }
    local img = c:imageFromCanvas()
    mod.wheelScreenImage(img)
end

--------------------------------------------------------------------------------
--
-- BUTTON COLORS:
--
--------------------------------------------------------------------------------

--- hs.loupedeckct.buttonColor(buttonID, colorObject, callbackFn) -> none
--- Function
--- Changes a button color.
---
--- Parameters:
---  * buttonID - The ID of the button. A number between 7 and 26.
---  * colorObject - A `hs.drawing.color` object
---  * callbackFn - An optional callback function
---
--- Returns:
---  * None
---
--- Notes:
---  * The buttonID's are as follows:
---   * 7-14    = 1-8 buttons
---   * 15      = O button
---   * 16      = Undo button
---   * 17      = Keyboard button
---   * 18      = Return button
---   * 19      = Save button
---   * 20      = Left Fn/lock button
---   * 21      = A button
---   * 22      = C button
---   * 23      = Right Fn/lock button
---   * 24      = B button
---   * 25      = D button
---   * 26      = E button
function mod.buttonColor(buttonID, colorObject, callbackFn)
    --------------------------------------------------------------------------------
    -- COMMAND: 07 02 FA 00 00 00 00
    --                            ^
    --                ^  ^  ^  ^  blue
    --                ^  ^  ^  green
    --                ^  ^  red
    --                ^  button id
    --                callback id
    --------------------------------------------------------------------------------
    colorObject = drawing.color.asRGB(colorObject)

    local callbackID = 0
    if type(callbackFn) == "function" then
        callbackID = registerCallback(callbackFn)
    end

    local red = colorObject.red and colorObject.red * 255 or 0
    local green = colorObject.green and colorObject.green * 255 or 0
    local blue = colorObject.blue and colorObject.blue * 255 or 0

    local result = "0702" .. decimalToHex(callbackID) .. decimalToHex(buttonID) .. decimalToHex(red) .. decimalToHex(green) .. decimalToHex(blue)
    send(fromHex(result))
end

-- ct.allButtonColor(hs.drawing.color.hammerspoon.red)
function mod.allButtonColor(colorObject)
    for i=7, 26 do
        mod.buttonColor(i, colorObject)
    end
end

--------------------------------------------------------------------------------
--
-- CONNECTION:
--
--------------------------------------------------------------------------------

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
                    doAfter(2, function()
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

return mod
