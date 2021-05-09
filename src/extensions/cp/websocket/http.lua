--- === cp.websocket.http ===
---
--- Provides a full HTTP-based websocket implementation.

local require           = require

local log               = require "hs.logger" .new "ws_http"
local inspect           = require "hs.inspect"
local hexDump           = require "hs.utf8" .hexDump

local status            = require "cp.websocket.status"
local event             = require "cp.websocket.event"

local websocket         = require "hs.websocket"

local mod = {}

mod.mt = {}
mod.mt.__index = mod.mt

--- cp.websocket.http.new(url, callback) -> object
--- Function
--- Creates a new websocket connection via a serial connection.
---
--- Parameters:
---  * url - The URL path to the websocket server.
---  * callback - A function that's triggered by websocket actions.
---
--- Returns:
---  * The `cp.websocket` object
---
--- Notes:
---  * The callback should accept two parameters.
---  * The first parameter is a `cp.websocket.event` value.
---  * The second parameter is a `string` with the received message or an error message.
---  * Given a path '/mysock' and a port of 8000, the websocket URL is as follows:
---   * `ws://localhost:8000/mysock`
---   * `wss://localhost:8000/mysock` (if SSL enabled)
function mod.new(url, callback)
    local o = {
        -- configuration
        _url = url,
        _callback = callback,

        -- internal
        _status = status.closed,
    }

    setmetatable(o, mod.mt)
    return o
end

--- cp.websocket.http:status() -> cp.websocket.status
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

-- The websocket message handlers
mod._handler = {
    open = function(self, message)
        self:_update(status.open, event.opened, message)
    end,

    closed = function(self, message)
        self:_update(status.closed, event.closed, message)
    end,

    fail = function(self, message)
        log.wf("Unexpected message when status is '%s':\n%s", inspect(self._status), hexDump(message))
        self:_report(event.error, message)
    end,

    received = function(self, message)
        if self._status == status.open then
            self._report(event.message, message)
        else
            mod._handler.fail(self, message)
        end
    end,

    pong = function(_, message)
        log.df("received an unsolicited 'pong': %s", hexDump(message))
    end,
}


-- cp.websocket.http:_update(statusType[, eventType[, message]])
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

--- cp.websocket.http:open() -> cp.websocket.status
--- Method
--- Attempts to open a websocket connection with the configured HTTP connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.websocket.status` after attempting to open.
function mod.mt:open()
    self:_update(status.opening, event.opening)

    self._connection = websocket.new(self._url, self:_createWebsocketCallback())
    return self._status
end

--- cp.websocket.http:isOpen() -> boolean
--- Method
--- Gets whether or not the HTTP websocket is fully open.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if open, otherwise `false`.
function mod.mt:isOpen()
    return self._connection and self._connection:status() == "open" and self._status == status.open
end


-- cp.websocket.http:_createSerialCallback() -> function
-- Private Method
-- Creates a callback function for the internal `hs.serial` connection.
function mod.mt:_createWebsocketCallback()
    return function(eventType, message)
        local handler = mod._handler[eventType]
        if handler then
            handler(self, message)
        else
            log.wf("Unsupported websocket callback type: %s; message:\n%s", inspect(eventType), hexDump(message))
        end
    end
end

-- cp.websocket.http:_report(eventType, message)
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
    self._callback(eventType, message)
end

--- cp.websocket.http:close() -> object
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

    if conn and conn:status() == "open" then
        self:_update(status.closing, event.closing)
        conn:close()
        return
    end

    self:_update(status.closed, event.closed)

    return self
end

--- cp.websocket.http:send(message[, isData]) -> object
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
        self._connection:send(message, isData)
    end

    return self
end

return mod
