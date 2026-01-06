--- === plugins.core.websocket.manager ===
---
--- WebSocket Control Surface Manager
---
--- This plugin enables bidirectional communication between CommandPost and
--- external software or hardware devices via the WebSocket protocol.
--- Supports both client and server modes.

local require = require

local log           = require("hs.logger").new("ws_mgr")

local config        = require "cp.config"
local i18n          = require "cp.i18n"
local prop          = require "cp.prop"
local json          = require "hs.json"

local client        = require "client"
local server        = require "server"
local messageHandler = require "message-handler"

local mod = {}

--- plugins.core.websocket.manager.MODE
--- Constant
--- Valid operation modes
mod.MODE = {
    CLIENT = "client",
    SERVER = "server",
}

--- plugins.core.websocket.manager.enabled <cp.prop: boolean>
--- Variable
--- Enable or disable the WebSocket control surface.
mod.enabled = config.prop("websocket.enabled", false):watch(function(enabled)
    if enabled then
        log.df("WebSocket control surface enabled")
        mod.start()
    else
        log.df("WebSocket control surface disabled")
        mod.stop()
    end
end)

--- plugins.core.websocket.manager.mode <cp.prop: string>
--- Variable
--- Operation mode: "client" or "server"
--- Note: Server mode is not supported by hs.websocket
mod.mode = config.prop("websocket.mode", mod.MODE.CLIENT):watch(function(mode)
    log.df("WebSocket mode changed to: %s", mode)
    if mod.enabled() then
        -- Restart with new mode
        mod.stop()
        mod.start()
    end
end)

--- plugins.core.websocket.manager.serverPort <cp.prop: number>
--- Variable
--- Server port (default: 27480)
mod.serverPort = config.prop("websocket.serverPort", 27480):watch(function(port)
    log.df("[PROP WATCH] WebSocket server port changed to: %d", port)
    log.df("[PROP WATCH] Current enabled state: %s, mode: %s", tostring(mod.enabled()), mod.mode())
    if mod.enabled() and mod.mode() == mod.MODE.SERVER then
        -- Restart server with new port
        log.df("[PROP WATCH] Restarting server with new port")
        mod.stop()
        mod.start()
    else
        log.df("[PROP WATCH] Not restarting server (enabled: %s, mode: %s)", tostring(mod.enabled()), mod.mode())
    end
end)

--- plugins.core.websocket.manager.clientUrl <cp.prop: string>
--- Variable
--- Client connection URL
mod.clientUrl = config.prop("websocket.clientUrl", "ws://localhost:8080"):watch(function(url)
    log.df("[PROP WATCH] WebSocket client URL changed to: %s", url)
    log.df("[PROP WATCH] Current enabled state: %s, mode: %s", tostring(mod.enabled()), mod.mode())
    if mod.enabled() and mod.mode() == mod.MODE.CLIENT then
        -- Reconnect to new URL
        log.df("[PROP WATCH] Reconnecting to new URL")
        mod.stop()
        mod.start()
    else
        log.df("[PROP WATCH] Not reconnecting (enabled: %s, mode: %s)", tostring(mod.enabled()), mod.mode())
    end
end)

--- plugins.core.websocket.manager.autoReconnect <cp.prop: boolean>
--- Variable
--- Auto-reconnect on disconnect (client mode)
mod.autoReconnect = config.prop("websocket.autoReconnect", true)

--- plugins.core.websocket.manager.reconnectInterval <cp.prop: number>
--- Variable
--- Reconnect delay in seconds (client mode)
mod.reconnectInterval = config.prop("websocket.reconnectInterval", 5)

--- plugins.core.websocket.manager.start() -> boolean
--- Function
--- Starts the WebSocket control surface based on current mode.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true if started successfully, false otherwise
function mod.start()
    if not mod.enabled() then
        log.wf("Cannot start: WebSocket control surface is disabled")
        return false
    end

    local currentMode = mod.mode()
    log.df("Starting WebSocket control surface in %s mode", currentMode)

    if currentMode == mod.MODE.SERVER then
        return mod.startServer()
    elseif currentMode == mod.MODE.CLIENT then
        return mod.connectClient()
    else
        log.ef("Invalid mode: %s", currentMode)
        return false
    end
end

--- plugins.core.websocket.manager.stop() -> nil
--- Function
--- Stops the WebSocket control surface.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    log.df("Stopping WebSocket control surface")

    if mod.mode() == mod.MODE.SERVER then
        mod.stopServer()
    elseif mod.mode() == mod.MODE.CLIENT then
        mod.disconnectClient()
    end
end

--- plugins.core.websocket.manager.startServer() -> boolean
--- Function
--- Starts the WebSocket server.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true if started successfully, false otherwise
function mod.startServer()
    local port = mod.serverPort()
    log.df("Starting WebSocket server on port %d", port)
    return server.start(port, mod.handleMessage)
end

--- plugins.core.websocket.manager.stopServer() -> nil
--- Function
--- Stops the WebSocket server.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stopServer()
    log.df("Stopping WebSocket server")
    server.stop()
end

--- plugins.core.websocket.manager.connectClient() -> boolean
--- Function
--- Connects as a WebSocket client.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true if connection initiated, false otherwise
function mod.connectClient()
    local url = mod.clientUrl()
    log.df("Connecting to WebSocket server: %s", url)
    return client.connect(url, mod.handleMessage)
end

--- plugins.core.websocket.manager.disconnectClient() -> nil
--- Function
--- Disconnects the WebSocket client.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.disconnectClient()
    log.df("Disconnecting WebSocket client")
    client.disconnect()
end

--- plugins.core.websocket.manager.handleMessage(connection, message) -> nil
--- Function
--- Handles an incoming WebSocket message.
---
--- Parameters:
---  * connection - The connection object
---  * message - The message string
---
--- Returns:
---  * None
function mod.handleMessage(connection, message)
    log.df("Received message on connection %s: %s", connection.id, message)

    -- Process the message
    local response = messageHandler.handleMessage(connection, message)

    -- Send response if available
    if response then
        local ok, encoded = pcall(json.encode, response)
        if ok then
            connection:send(encoded)
        else
            log.ef("Failed to encode response: %s", encoded)
        end
    end
end

--- plugins.core.websocket.manager.broadcastMessage(message) -> number
--- Function
--- Broadcasts a message to all connections (server mode only).
---
--- Parameters:
---  * message - The message to broadcast (string or table)
---
--- Returns:
---  * Number of clients the message was sent to
function mod.broadcastMessage(message)
    if mod.mode() ~= mod.MODE.SERVER then
        log.wf("Cannot broadcast: not in server mode")
        return 0
    end

    return server.broadcast(message)
end

--- plugins.core.websocket.manager.sendMessage(message) -> boolean
--- Function
--- Sends a message (client mode) or broadcasts (server mode).
---
--- Parameters:
---  * message - The message to send (string or table)
---
--- Returns:
---  * true if sent successfully, false otherwise
function mod.sendMessage(message)
    if mod.mode() == mod.MODE.CLIENT then
        return client.send(message)
    else
        return mod.broadcastMessage(message) > 0
    end
end

--- plugins.core.websocket.manager.sendEvent(eventType, data) -> boolean
--- Function
--- Sends an event message.
---
--- Parameters:
---  * eventType - The event type
---  * data - The event data
---
--- Returns:
---  * true if sent successfully, false otherwise
function mod.sendEvent(eventType, data)
    local event = messageHandler.createEvent(eventType, data)
    return mod.sendMessage(event)
end

--- plugins.core.websocket.manager.getConnectionStatus() -> table
--- Function
--- Gets the current connection status.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Status table
function mod.getConnectionStatus()
    local status = {
        enabled = mod.enabled(),
        mode = mod.mode(),
    }

    if mod.mode() == mod.MODE.SERVER then
        status.serverRunning = server.isRunning()
        status.serverPort = mod.serverPort()
        status.clientCount = server.getClientCount()
        status.clients = server.getClientList()
    else
        status.clientConnected = client.isConnected()
        status.clientUrl = mod.clientUrl()
        status.connectionInfo = client.getConnectionInfo()
    end

    return status
end

--- plugins.core.websocket.manager.getActiveConnections() -> table
--- Function
--- Gets a list of active connections.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Array of connection info tables
function mod.getActiveConnections()
    if mod.mode() == mod.MODE.SERVER then
        return server.getClientList()
    elseif mod.mode() == mod.MODE.CLIENT then
        local info = client.getConnectionInfo()
        return info and {info} or {}
    end
    return {}
end

--- plugins.core.websocket.manager.notifyConnectionStatusChanged() -> nil
--- Function
--- Notifies listeners that the connection status has changed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.notifyConnectionStatusChanged()
    -- Send event to preferences panel if it's open
    if mod.updateUI then
        mod.updateUI()
    end
end

local plugin = {
    id              = "core.websocket.manager",
    group           = "core",
    required        = false,
    dependencies    = {
        ["core.commands.global"]    = "global",
        ["core.action.manager"]     = "actionManager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Initialize submodules:
    --------------------------------------------------------------------------------
    client.init(mod)
    server.init(mod)
    messageHandler.init(deps.actionManager)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local global = deps.global

    global
        :add("enableWebSocket")
        :whenActivated(function()
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :titled("启用 WebSocket 控制表面")

    global
        :add("disableWebSocket")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :titled("禁用 WebSocket 控制表面")

    global
        :add("toggleWebSocket")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")
        :titled("切换 WebSocket 控制表面")

    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Start if enabled:
    --------------------------------------------------------------------------------
    mod.enabled:update()
end

return plugin
