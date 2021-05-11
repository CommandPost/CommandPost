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

local tools             = require "cp.tools"
local result            = require "cp.result"
local buffer            = require "cp.buffer"
local frame             = require "cp.websocket.frame"
local status            = require "cp.websocket.status"
local event             = require "cp.websocket.event"

local base64            = require "hs.base64"
local bytes             = require "hs.bytes"
local hash              = require "hs.hash"
local serial            = require "hs.serial"
local utf8              = require "hs.utf8"

local hexDump           = utf8.hexDump
local uint16be          = bytes.uint16be
local remainder         = bytes.remainder
local hexToBytes        = bytes.hexToBytes

local mod = {}

mod.mt = {}
mod.mt.__index = mod.mt

local CRLF = "\r\n"
local HTTP_STATUS_LINE = "HTTP/1%.1 (%d+) ([^\r\n]*)"
local HTTP_HEADER_LINE = "([^:]+):([^\r\n]*)"


local SEC_WEBSOCKET_KEY = base64.encode("CommandPostLDKey")
local WEBSOCKET_MAGIC_KEY = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
mod.SEC_WEBSOCKET_ACCEPT = hexToBytes(hash.SHA1(SEC_WEBSOCKET_KEY .. WEBSOCKET_MAGIC_KEY))

-- matchesSecWsKey(response) -> boolean
-- Function
-- Checks if the provided HTTP Response `table` matches expectations for a WebSocket upgrade request.
local function matchesSecWsKey(response)
    if response.statusCode ~= 101 then
        return result.failure("Unexpected status code: %s", inspect(response.statusCode))
    end
    if response.headers["Connection"] ~= "Upgrade" then
        return result.failure("Unexpected 'Connection' header: %s", inspect(response.headers["Connection"]))
    end
    if response.headers["Upgrade"] ~= "websocket" then
        return result.failure("Unexpected 'Upgrade' header: %s", inspect(response.headers["Upgrade"]))
    end

    local acceptKey = response.headers["Sec-WebSocket-Accept"]
    local acceptHash = base64.decode(acceptKey)
    if acceptHash ~= mod.SEC_WEBSOCKET_ACCEPT then
        return result.failure("Unexpected 'Sec-WebSocket-Accept' hash: %s", hexDump(acceptHash))
    end
    return result.success()
end

-- _createHTTPRequest(type, path[, headers[, body]]) -> strings
-- Function
-- Creates a correctly-formatted HTTP Request based on the (assumedly correct) parameters.
-- Does not check that provided parameters are legal.
--
-- Parameters:
--  * type - The type of request (eg. "GET", "POST", etc.)
--  * path - The path to request (eg. "/index.html")
--  * headers - A `table` of headers (see below). May be `nil` if no headers are provided.
--  * body - A `string` containing the body of the request. May be `nil`.
--
-- Returns:
--  * A `string` which can be sent to a server as the request content.
--
-- Notes:
--  * The `headers` is a `table` where the key/value pairs will be output verbatim. For example:
--   * `{["Foo"] = "bar"}` becomes `"Foo: bar\r\n"`
function mod._createHTTPRequest(type, path, headers, body)
    local out = bytes()

    out:write(type, " ", path, " HTTP/1.1", CRLF)

    if headers then
        for key,value in pairs(headers) do
            out:write(key, ": ", value, CRLF)
        end
    end

    out:write("\r\n")
    if body then
        out:write(body)
    end

    return out:bytes()
end

local function findEOL(data, init)
    return data:find(CRLF, init, true)
end

-- _parseHTTPResponse(data) -> result<{statusCode,reason,headers,body?}>
-- Function
-- Attempts to parse a `string` of data as an HTTP Response block.
--
-- Parameters:
--  * data - The `string` of data.
--
-- Returns:
--  * A `cp.response`. If successful, the `value` will be a `table`, as described below.
--
-- Notes:
--  * The returned `table` will have the following properties:
--   * statusCode - a `number` for the code (e.g. `200`, `404`)
--   * reason - The text reason for the response status.
--   * headers - A `table` of header key/value pairs.
--   * body - The bytes from the response body as a `string`, or `nil` if none was provided.
function mod._parseHTTPResponse(data)
    local index = 1
    local eol = findEOL(data, index)
    if not eol then
        return result.failure("No CRLF values found.")
    end

    local statusCode, reason = data:match(HTTP_STATUS_LINE, index)
    if not statusCode or not reason then
        return result.failure("Invalid HTTP Status-Line: \"%s\"", data:sub(index, eol))
    end

    local headers = {}
    index = eol+2
    eol = findEOL(data, index)
    while eol ~= nil and index ~= eol do
        local fieldName, fieldValue = data:match(HTTP_HEADER_LINE, index)
        if not fieldName or not fieldValue then
            return result.failure("Invalid HTTP Header: \"%s\"", data:sub(index, eol))
        end
        fieldValue = tools.trim(fieldValue)
        headers[fieldName] = fieldValue
        index = eol+2
        eol = findEOL(data, index)
    end

    if not eol then
        return result.failure("HTTP Response must have a blank line after the header.")
    end

    -- parse the body, if present
    local body
    index = eol+2
    if index <= #data then
        body = data:sub(index)
    end

    return result.success {
        statusCode = tonumber(statusCode),
        reason = reason,
        headers = headers,
        body = body,
    }
end

local WS_HANDSHAKE_REQUEST = mod._createHTTPRequest("GET", "/index.html", {
    ["Connection"] = "Upgrade",
    ["Upgrade"] = "websocket",
    ["Sec-WebSocket-Key"] = SEC_WEBSOCKET_KEY,
})

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

    received = function(self, message)
        if self._status == status.opening then
            local out = mod._parseHTTPResponse(message)
            if out.failure then
                log.df("HTTP Response Parse Failure: %s", out.message)
                return
            end
            local response = out.value
            if response then
                local keyCheck = matchesSecWsKey(response)
                if keyCheck.success then
                    --log.df("Serial connection handshake received!")
                    self:_update(status.open, event.opened)
                else
                    keyCheck:log("Loupedeck WebSocket Upgrade Response")
                end
            end
        elseif self._status == status.open then
            -- frames come in chunks, so buffer them together and check the whole buffer for actual frames.
            self:_bufferMessage(message)
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