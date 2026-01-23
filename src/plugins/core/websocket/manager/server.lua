--- === plugins.core.websocket.manager.server ===
---
--- WebSocket Server Mode Implementation
---
--- Handles accepting WebSocket client connections, managing multiple clients,
--- and broadcasting messages.

local require = require

local httpserver = require "hs.httpserver"

local log       = require("hs.logger").new("ws_server")

local connection = require "connection"

local mod = {}

--- plugins.core.websocket.manager.server.init(manager)
--- Function
--- Initializes the server module.
---
--- Parameters:
---  * manager - The websocket manager instance
---
--- Returns:
---  * None
function mod.init(manager)
    mod.manager = manager
    mod.server = nil
    mod.clients = {}
    mod.clientCounter = 0
    mod.messageHandler = nil
end

--- plugins.core.websocket.manager.server.start(port, messageHandler) -> boolean
--- Function
--- Starts the WebSocket server.
---
--- Parameters:
---  * port - The port to listen on
---  * messageHandler - Function to handle incoming messages
---
--- Returns:
---  * true if server started, false otherwise
---
--- Notes:
---  * Uses hs.httpserver with WebSocket support
---  * WebSocket endpoint will be available at ws://localhost:<port>
function mod.start(port, messageHandler)
    if mod.server then
        log.wf("Server already running, stopping first")
        mod.stop()
    end

    --log.df("Starting WebSocket server on port %d", port)

    -- Create HTTP server with WebSocket support
    mod.server = httpserver.new(false, false)
    mod.server:setPort(port)
    mod.messageHandler = messageHandler

    -- Enable WebSocket endpoint
    mod.server:websocket("/", function(message)
        return mod.handleMessage(message)
    end)

    -- Start the server
    mod.server:start()

    --log.df("WebSocket server started on ws://localhost:%d/", port)
    return true
end

--- plugins.core.websocket.manager.server.stop() -> nil
--- Function
--- Stops the WebSocket server and disconnects all clients.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    --log.df("Stopping WebSocket server")

    -- Clear clients
    mod.clients = {}
    mod.clientCounter = 0
    mod.messageHandler = nil

    -- Stop server
    if mod.server then
        local ok, err = pcall(function()
            mod.server:stop()
        end)

        if not ok then
            log.ef("Error stopping server: %s", err)
        end

        mod.server = nil
    end

    -- Notify manager
    if mod.manager and mod.manager.notifyConnectionStatusChanged then
        mod.manager.notifyConnectionStatusChanged()
    end
end

--- plugins.core.websocket.manager.server.handleMessage(message) -> string
--- Function
--- Handles an incoming WebSocket message from any client.
---
--- Parameters:
---  * message - The received message string
---
--- Returns:
---  * Response message string (or empty string if no response)
function mod.handleMessage(message)
    --log.df("Received message: %s", message)

    -- Create a mock connection object for the message handler
    local conn = {
        id = "server",
        type = "server",
        send = function(self, msg)
            -- Broadcast response to all clients
            mod.broadcast(msg)
        end,
    }

    -- Call the message handler if available
    if mod.messageHandler then
        local ok, result = pcall(function()
            return mod.messageHandler(conn, message)
        end)

        if not ok then
            log.ef("Error in message handler: %s", result)
            return ""
        end

        -- Return response (will be sent to the client that sent the message)
        return result or ""
    end

    return ""
end

--- plugins.core.websocket.manager.server.broadcast(message) -> number
--- Function
--- Broadcasts a message to all connected clients.
---
--- Parameters:
---  * message - The message to broadcast (string or table)
---
--- Returns:
---  * Number of clients the message was sent to
---
--- Notes:
---  * With hs.httpserver websocket, messages are sent to all connected clients
function mod.broadcast(message)
    if not mod.server then
        log.wf("Cannot broadcast: server not running")
        return 0
    end

    -- Convert table to JSON if needed
    local msg = message
    if type(message) == "table" then
        local json = require "hs.json"
        local ok, encoded = pcall(json.encode, message)
        if ok then
            msg = encoded
        else
            log.ef("Failed to encode message: %s", encoded)
            return 0
        end
    end

    -- Send to all clients via httpserver
    local ok, err = pcall(function()
        mod.server:send(tostring(msg))
    end)

    if not ok then
        log.ef("Failed to broadcast message: %s", err)
        return 0
    end

    --log.df("Broadcast message sent")
    return 1
end

--- plugins.core.websocket.manager.server.isRunning() -> boolean
--- Function
--- Checks if the server is running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true if server is running, false otherwise
function mod.isRunning()
    return mod.server ~= nil
end

--- plugins.core.websocket.manager.server.getClientCount() -> number
--- Function
--- Gets the number of connected clients.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Number of connected clients
---
--- Notes:
---  * hs.httpserver does not provide a way to get the exact client count
---  * Returns 1 if server is running, 0 otherwise
function mod.getClientCount()
    return mod.server ~= nil and 1 or 0
end

--- plugins.core.websocket.manager.server.getClientList() -> table
--- Function
--- Gets a list of all connected clients.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Array of client info tables
---
--- Notes:
---  * hs.httpserver does not provide individual client information
function mod.getClientList()
    if mod.server then
        return {{
            id = "httpserver-ws",
            type = "server",
            state = "connected"
        }}
    end
    return {}
end

return mod
