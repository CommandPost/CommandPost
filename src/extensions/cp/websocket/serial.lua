--- === cp.websocket.serial ===
---
--- A partial implementation of the websocket API communicating
--- via serial port rather than HTTP.
---
--- It implements the same basic methods as `hs.websocket`, so can
--- be dropped in as a replacement without change, other than the
--- initial construction.
---
--- Note that it does not support any websocket extensions.

local require           = require

local log               = require "hs.logger" .new "ws_serial"
local inspect           = require "hs.inspect"

local buffer            = require "cp.websocket.buffer"
local frame             = require "cp.websocket.frame"
local status            = require "cp.websocket.status"
local event             = require "cp.websocket.event"
local bytes             = require "hs.bytes"
local serial            = require "hs.serial"
local utf8              = require "hs.utf8"

local hexDump           = utf8.hexDump
local uint16be          = bytes.uint16be
local remainder         = bytes.remainder

local mod = {}

mod.mt = {}
mod.mt.__index = mod.mt

-- TODO: This is hard-coded for the response from a Loupedeck device. Make more general!
local WS_HANDSHAKE_REQUEST =
"GET /index.html HTTP/1.1\r\n"..
"Connection: Upgrade\r\n"..
"Upgrade: websocket\r\n"..
"Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"..
"\r\n"

local WS_HANDSHAKE_RESPONSE =
"HTTP/1.1 101 Switching Protocols\r\n"..
"Upgrade: websocket\r\n"..
"Connection: Upgrade\r\n"..
"Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n"..
"\r\n"

--- cp.websocket.serial.new(deviceName, baudRate, dataBits, stopBits, callback) -> object
--- Function
--- Creates a new websocket connection via a serial connection.
---
--- Parameters:
---  * deviceName - The name of the USB Device
---  * baudRate - The connection baud rate
---  * dataBits - The data bits.
---  * stopBits - The stop bits.
---  * callback - A function that's triggered by websocket actions.
---
--- Returns:
---  * The `cp.websocket` object
---
--- Notes:
---  * The callback should accept two parameters.
---  * The first parameter is a `cp.websocket.event` value.
---  * The second parameter is a `string` with the received message or an error message.
function mod.new(deviceName, baudRate, dataBits, stopBits, callback)
    local o = {
        -- configuration
        _deviceName                 = deviceName,
        _baudRate                   = baudRate,
        _dataBits                   = dataBits,
        _stopBits                   = stopBits,
        _callback                   = callback,

        -- internal
        _status                     = status.closed,
        _serialBuffer               = buffer.new(),
        _messageBytes               = bytes.new(),
    }
    setmetatable(o, mod.mt)
    return o
end

--- cp.websocket.serial:status() -> cp.websocket.status
--- Method
--- Returns the current connection status.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The current `cp.websocket.status`.
function mod.mt:status()
    return self._status
end

-- The serial port message handlers
mod._handler = {
    opened = function(self, _)
        --log.df("Serial connection opened, sending handshake request.")
        self._status = status.opening
        self._connection:sendData(WS_HANDSHAKE_REQUEST)
    end,

    closed = function(self, _)
        --log.df("Serial connection closed.")
        self._status = status.closed
        self._connection = nil
        self:_report(event.closed)
    end,

    removed = function(self, _)
        --log.df("Serial device removed.")
        self:close()
    end,

    received = function(self, message, hexadecimalString)
        if self._status == status.opening and message == WS_HANDSHAKE_RESPONSE then
            --log.df("Serial connection handshake received!")
            self:_update(status.open, event.opened)
        elseif self._status == status.open then
            -- frames come in chunks, so buffer them together and check the whole buffer for actual frames.
            self:_bufferMessage(message)
        elseif self._status == status.opening then
            -- Ignore any random messages whilst still opening...
            return
        else
            mod._handler.error(self, message)
        end
    end,

    error = function(self, message)
        log.wf("Unexpected message when status is '%s':\n%s", inspect(self._status), hexDump(message))
        self:_report(event.error, message)
    end,
}

-- cp.websocket.serial:_update(statusType[, eventType[, message]])
-- Private Method
-- Updates the status, and optionally sends an event to the callback if the status changed.
--
-- Parameters:
--  * statusType - The new `cp.websocket.status`
--  * eventType - The `cp.websocket.event` type to send if the status changed. (optional)
--  * message - The message data to send with the event type. (optional)
--
-- Returns:
--  * Nothing
function mod.mt:_update(statusType, eventType, message)
    local oldStatus = self._status
    self._status = statusType
    if eventType and oldStatus ~= statusType then
        self:_report(eventType, message)
    end
end

--- cp.websocket.serial:open() -> cp.websocket.status
--- Method
--- Attempts to open a websocket connection with the configured serial connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.websocket.status` after attempting to open.
function mod.mt:open()
    --log.df("Opening serial connection...")
    self:_update(status.opening, event.opening)

    local connection = serial.newFromName(self._deviceName)
    if connection then
        connection
            :baudRate(self._baudRate)
            :dataBits(self._dataBits)
            :stopBits(self._stopBits)
            :callback(self:_createSerialCallback())

        self._connection = connection:open()

        if not self._connection then
            -- TODO: Check if these are necessary. It's possible that hs.serial is already sending events for these.
            log.ef("Unable to open serial connection.")
            self:_report(event.error, "Unable to open serial connection.")
            self:_update(status.closed, event.closed)
        end

        --if self._connection:isOpen() then
            --log.df("Loupedeck serial connection is open...")
        --end
    end
    return self._status
end

--- cp.websocket.serial:isOpen() -> boolean
--- Method
--- Gets whether or not the serial websocket is fully open.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if open, otherwise `false`.
function mod.mt:isOpen()
    return self._connection and self._connection:isOpen() and self._status == status.open
end

-- cp.websocket.serial:_createSerialCallback() -> function
-- Private Method
-- Creates a callback function for the internal `hs.serial` connection.
function mod.mt:_createSerialCallback()
    return function(_, callbackType, message, hexadecimalString)
        local handler = mod._handler[callbackType]
        if handler then
            handler(self, message, hexadecimalString)
        else
            log.wf("Unsupported serial callback type: %s; message:\n%s", inspect(callbackType), hexDump(message))
        end
    end
end

-- cp.websocket.serial:_report(eventType, message)
-- Private Method
-- Sends an event to the callback function with the specified event type and message.
--
-- Parameters:
--  * eventType - the `cp.websocket.event` type.
--  * message - The message bytes to send. May be `nil` for some event types.
--
-- Returns:
--  * Nothing
function mod.mt:_report(eventType, message)
    if self._callback then
        self._callback(eventType, message)
    else
        log.ef("No callback supplied - this shouldn't happen.")
    end
end

--- cp.websocket.serial:close() -> object
--- Method
--- Closes a websocket connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.websocket.serial` object
---
--- Notes:
---  * The `status` may be either `closing` or `closed` after calling this method.
---  * To be notified the close has completed, listen for the `cp.websocket.event.closed` event in the callback.
function mod.mt:close()
    if self._status == status.closed or self._status == status.closing then
        return self
    end

    local conn = self._connection
    self._connection = nil

    if conn and conn:isOpen() then
        self:_update(status.closing, event.closing)
        conn:close()
        return
    end

    self:_update(status.closed, event.closed)

    return self
end

--- cp.websocket.serial:send(message[, isData]) -> object
--- Method
--- Sends a message to the websocket client.
---
--- Parameters:
---  * message - A string containing the message to send.
---  * isData - An optional boolean that sends the message as binary data (defaults to true).
---
--- Returns:
---  * The `cp.websocket.serial` object
---
--- Notes:
---  * Forcing a text representation by setting isData to `false` may alter the data if it
---   contains invalid UTF8 character sequences (the default string behavior is to make
---   sure everything is "printable" by converting invalid sequences into the Unicode
---   Invalid Character sequence).
function mod.mt:send(message, isData)
    if self:isOpen() then
        local opcode = frame.opcode.binary
        -- fix UTF-8 if sending as `text`
        if isData == false then
            message = utf8.fixUTF8(message)
            opcode = frame.opcode.text
        end

        local value = frame.new(true, opcode, true, message)
        self._connection:sendData(value:toBytes())
    end

    return self
end

function mod.mt:_bufferMessage(message)
    local buff = self._serialBuffer
    buff:push(message)

    while true do

        local outcome = frame.fromBuffer(buff)
        if outcome.failure then
            -- not enough data yet, come back later
            return
        end

        local frm = outcome.value.frame
        if frm:isControlFrame() then
            if frm.opcode == frame.opcode.close then
                local payloadData = frm.payloadData
                local statusCode, errMessage
                if payloadData and #payloadData > 0 then
                    statusCode, errMessage = bytes.read(payloadData, uint16be, remainder)
                end
                log.ef("error from server: %x00 %s", statusCode, errMessage)

                self:_report(event.closing)
                frm.mask = true

                -- send it straight back, masked
                self._connection:sendData(frm:toBytes())

                -- TODO: Do we need to report(event.closed) also?
            elseif frm.opcode == frame.opcode.ping then
                local pong = frame.new(true, frame.opcode.pong, true, frm.payloadData)
                self._connection:sendData(pong:toBytes())
            end
        else
            local msgBytes = self._messageBytes
            local payloadData = frm.payloadData
            if frm.opcode == frame.opcode.text then
                payloadData = utf8.fixUTF8(payloadData)
            end
            msgBytes:write(payloadData)

            if frm.final then
                local messageData = msgBytes:bytes()
                self._messageBytes = bytes.new()
                self:_report(event.message, messageData)
            end
        end

    end -- while
end

return mod