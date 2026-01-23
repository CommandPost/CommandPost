--- === plugins.core.websocket.manager.connection ===
---
--- WebSocket Connection Handler
---
--- Manages individual WebSocket connections, including state tracking,
--- message queuing, and error handling.

local require = require

local class     = require "middleclass"
local json      = require "hs.json"
local timer     = require "hs.timer"
local uuid      = require "hs.host".uuid

local log       = require("hs.logger").new("ws_conn")

local connection = class("core.websocket.manager.connection")

--- plugins.core.websocket.manager.connection.states
--- Constant
--- Connection states
connection.static.states = {
    CONNECTING = "connecting",
    CONNECTED = "connected",
    DISCONNECTED = "disconnected",
    ERROR = "error",
}

--- plugins.core.websocket.manager.connection(websocket, mode, callbacks)
--- Constructor
--- Creates a new Connection instance.
---
--- Parameters:
---  * websocket - The hs.websocket object
---  * mode - "client" or "server"
---  * callbacks - Table of callback functions (onMessage, onClose, onError)
---
--- Returns:
---  * A new connection instance
function connection:initialize(websocket, mode, callbacks)
    self.id = uuid()
    self.websocket = websocket
    self.mode = mode or "client"
    self.state = connection.states.CONNECTING
    self.lastActivity = timer.secondsSinceEpoch()
    self.callbacks = callbacks or {}
    self.messageQueue = {}

    --log.df("New connection created: %s (mode: %s)", self.id, self.mode)
end

--- plugins.core.websocket.manager.connection:send(message) -> boolean
--- Method
--- Sends a message through the WebSocket connection.
---
--- Parameters:
---  * message - The message to send (string or table)
---
--- Returns:
---  * true if sent successfully, false otherwise
function connection:send(message)
    if not self:isConnected() then
        log.wf("Cannot send message - connection %s is not connected (state: %s)", self.id, self.state)
        return false
    end

    local data = message
    if type(message) == "table" then
        local ok, encoded = pcall(json.encode, message)
        if not ok then
            log.ef("Failed to encode message to JSON: %s", encoded)
            return false
        end
        data = encoded
    end

    local ok, result = pcall(function()
        self.websocket:send(data)
    end)

    if ok then
        self.lastActivity = timer.secondsSinceEpoch()
        --log.df("Message sent on connection %s", self.id)
        return true
    else
        log.ef("Failed to send message on connection %s: %s", self.id, result)
        return false
    end
end

--- plugins.core.websocket.manager.connection:close() -> nil
--- Method
--- Closes the WebSocket connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function connection:close()
    if self.websocket then
        --log.df("Closing connection: %s", self.id)
        self.state = connection.states.DISCONNECTED

        local ok, err = pcall(function()
            self.websocket:close()
        end)

        if not ok then
            log.ef("Error closing connection %s: %s", self.id, err)
        end

        if self.callbacks.onClose then
            self.callbacks.onClose(self)
        end
    end
end

--- plugins.core.websocket.manager.connection:isConnected() -> boolean
--- Method
--- Checks if the connection is currently connected.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true if connected, false otherwise
function connection:isConnected()
    return self.state == connection.states.CONNECTED
end

--- plugins.core.websocket.manager.connection:setState(state) -> nil
--- Method
--- Sets the connection state.
---
--- Parameters:
---  * state - The new state
---
--- Returns:
---  * None
function connection:setState(state)
    if self.state ~= state then
        --log.df("Connection %s state changed: %s -> %s", self.id, self.state, state)
        self.state = state
        self.lastActivity = timer.secondsSinceEpoch()
    end
end

--- plugins.core.websocket.manager.connection:handleMessage(message) -> nil
--- Method
--- Handles an incoming message.
---
--- Parameters:
---  * message - The received message
---
--- Returns:
---  * None
function connection:handleMessage(message)
    self.lastActivity = timer.secondsSinceEpoch()

    if self.callbacks.onMessage then
        self.callbacks.onMessage(self, message)
    else
        log.wf("No message callback defined for connection %s", self.id)
    end
end

--- plugins.core.websocket.manager.connection:handleError(error) -> nil
--- Method
--- Handles a connection error.
---
--- Parameters:
---  * error - The error message or object
---
--- Returns:
---  * None
function connection:handleError(error)
    log.ef("Connection %s error: %s", self.id, error)
    self.state = connection.states.ERROR
    self.lastActivity = timer.secondsSinceEpoch()

    if self.callbacks.onError then
        self.callbacks.onError(self, error)
    end
end

--- plugins.core.websocket.manager.connection:getInfo() -> table
--- Method
--- Gets information about this connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table containing connection information
function connection:getInfo()
    return {
        id = self.id,
        mode = self.mode,
        state = self.state,
        lastActivity = self.lastActivity,
        isConnected = self:isConnected(),
    }
end

return connection
