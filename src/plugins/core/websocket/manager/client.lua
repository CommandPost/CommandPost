--- === plugins.core.websocket.manager.client ===
---
--- WebSocket Client Mode Implementation
---
--- Handles connecting to external WebSocket servers, managing the connection
--- lifecycle, and auto-reconnection logic.

local require = require

local websocket = require "hs.websocket"
local timer     = require "hs.timer"

local log       = require("hs.logger").new("ws_client")

local connection = require "connection"

local mod = {}

--- plugins.core.websocket.manager.client.init(manager)
--- Function
--- Initializes the client module.
---
--- Parameters:
---  * manager - The websocket manager instance
---
--- Returns:
---  * None
function mod.init(manager)
    mod.manager = manager
    mod.connection = nil
    mod.reconnectTimer = nil
    mod.reconnectAttempts = 0
end

--- plugins.core.websocket.manager.client.connect(url, messageHandler) -> boolean
--- Function
--- Connects to a WebSocket server.
---
--- Parameters:
---  * url - The WebSocket server URL (ws:// or wss://)
---  * messageHandler - Function to handle incoming messages
---
--- Returns:
---  * true if connection initiated, false otherwise
function mod.connect(url, messageHandler)
    if not url or url == "" then
        log.ef("Cannot connect: URL is empty")
        return false
    end

    -- Disconnect existing connection first
    if mod.connection then
        --log.df("Disconnecting existing connection before connecting to new URL")
        mod.disconnect()
    end

    --log.df("Connecting to WebSocket server: %s", url)

    local ws = websocket.new(url, function(event, message)
        mod.handleEvent(event, message, messageHandler)
    end)

    if not ws then
        log.ef("Failed to create WebSocket client")
        return false
    end

    -- Create connection object
    mod.connection = connection(ws, "client", {
        onMessage = messageHandler,
        onClose = function()
            mod.handleDisconnect()
        end,
        onError = function(conn, error)
            mod.handleError(error)
        end,
    })

    return true
end

--- plugins.core.websocket.manager.client.disconnect() -> nil
--- Function
--- Disconnects from the WebSocket server.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.disconnect()
    --log.df("Disconnecting client")

    -- Stop reconnect timer
    if mod.reconnectTimer then
        mod.reconnectTimer:stop()
        mod.reconnectTimer = nil
    end

    -- Close connection
    if mod.connection then
        mod.connection:close()
        mod.connection = nil
    end

    mod.reconnectAttempts = 0
end

--- plugins.core.websocket.manager.client.send(message) -> boolean
--- Function
--- Sends a message to the server.
---
--- Parameters:
---  * message - The message to send (string or table)
---
--- Returns:
---  * true if sent successfully, false otherwise
function mod.send(message)
    if not mod.connection then
        log.wf("Cannot send message: not connected")
        return false
    end

    return mod.connection:send(message)
end

--- plugins.core.websocket.manager.client.isConnected() -> boolean
--- Function
--- Checks if the client is connected.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true if connected, false otherwise
function mod.isConnected()
    return mod.connection and mod.connection:isConnected()
end

--- plugins.core.websocket.manager.client.handleEvent(event, message, messageHandler) -> nil
--- Function
--- Handles WebSocket events.
---
--- Parameters:
---  * event - The event type (string: "open", "closed", "fail", "received", "pong")
---  * message - The message (if any)
---  * messageHandler - The message handler function
---
--- Returns:
---  * None
function mod.handleEvent(event, message, messageHandler)
    if event == "open" then
        --log.df("WebSocket client connected")
        if mod.connection then
            mod.connection:setState(connection.states.CONNECTED)
        end
        mod.reconnectAttempts = 0

        -- Notify manager
        if mod.manager and mod.manager.notifyConnectionStatusChanged then
            mod.manager.notifyConnectionStatusChanged()
        end

    elseif event == "closed" then
        --log.df("WebSocket client disconnected")
        mod.handleDisconnect()

    elseif event == "fail" then
        log.ef("WebSocket client connection failed: %s", message or "unknown error")
        mod.handleError(message)

    elseif event == "received" then
        if mod.connection and messageHandler then
            messageHandler(mod.connection, message)
        end
    elseif event == "pong" then
        --log.df("WebSocket received pong")
    end
end

--- plugins.core.websocket.manager.client.handleDisconnect() -> nil
--- Function
--- Handles disconnection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.handleDisconnect()
    if mod.connection then
        mod.connection:setState(connection.states.DISCONNECTED)
    end

    -- Notify manager
    if mod.manager and mod.manager.notifyConnectionStatusChanged then
        mod.manager.notifyConnectionStatusChanged()
    end

    -- Schedule reconnect if enabled
    if mod.manager and mod.manager.autoReconnect and mod.manager.autoReconnect() then
        mod.scheduleReconnect()
    end
end

--- plugins.core.websocket.manager.client.handleError(error) -> nil
--- Function
--- Handles connection errors.
---
--- Parameters:
---  * error - The error message
---
--- Returns:
---  * None
function mod.handleError(error)
    if mod.connection then
        mod.connection:handleError(error)
    end

    -- Notify manager
    if mod.manager and mod.manager.notifyConnectionStatusChanged then
        mod.manager.notifyConnectionStatusChanged()
    end

    -- Schedule reconnect if enabled
    if mod.manager and mod.manager.autoReconnect and mod.manager.autoReconnect() then
        mod.scheduleReconnect()
    end
end

--- plugins.core.websocket.manager.client.scheduleReconnect() -> nil
--- Function
--- Schedules an automatic reconnection attempt.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.scheduleReconnect()
    if mod.reconnectTimer then
        return -- Already scheduled
    end

    mod.reconnectAttempts = mod.reconnectAttempts + 1

    -- Exponential backoff: 5s, 10s, 20s, 40s, max 60s
    local baseDelay = mod.manager and mod.manager.reconnectInterval and mod.manager.reconnectInterval() or 5
    local delay = math.min(baseDelay * math.pow(2, mod.reconnectAttempts - 1), 60)

    --log.df("Scheduling reconnect attempt %d in %d seconds", mod.reconnectAttempts, delay)

    mod.reconnectTimer = timer.doAfter(delay, function()
        mod.reconnectTimer = nil

        if not mod.isConnected() and mod.manager then
            local url = mod.manager.clientUrl and mod.manager.clientUrl() or ""
            if url ~= "" then
                --log.df("Attempting to reconnect (attempt %d)", mod.reconnectAttempts)
                mod.connect(url, mod.manager.handleMessage)
            end
        end
    end)
end

--- plugins.core.websocket.manager.client.getConnectionInfo() -> table | nil
--- Function
--- Gets information about the current connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Connection info table or nil
function mod.getConnectionInfo()
    if mod.connection then
        return mod.connection:getInfo()
    end
    return nil
end

return mod
