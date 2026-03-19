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
local hash          = require "hs.hash"

local client        = require "client"
local server        = require "server"
local messageHandler = require "message-handler"

local mod = {}

--- plugins.core.websocket.manager.AUTH_TOKEN_FILENAME
--- Constant
--- Filename for the auth token file
local AUTH_TOKEN_FILENAME = "mcp-auth-token"

--- plugins.core.websocket.manager.generateAuthToken() -> string
--- Function
--- Generates a random auth token and writes it to a well-known file.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The generated token string
local function generateAuthToken()
    -- Generate a random token using timestamp + random data
    local seed = tostring(os.time()) .. tostring(math.random(1000000, 9999999)) .. tostring(hs.processInfo.processID)
    local token = hash.SHA256(seed)
    return token
end

--- plugins.core.websocket.manager.writeAuthToken(token) -> boolean
--- Function
--- Writes the auth token to the well-known file path.
---
--- Parameters:
---  * token - The token string to write
---
--- Returns:
---  * true if written successfully
local function writeAuthToken(token)
    local tokenDir = config.userConfigRootPath
    if not tokenDir then
        tokenDir = os.getenv("HOME") .. "/.CommandPost"
    end
    -- Ensure directory exists
    os.execute("mkdir -p " .. string.format("%q", tokenDir))
    local tokenPath = tokenDir .. "/" .. AUTH_TOKEN_FILENAME
    local f = io.open(tokenPath, "w")
    if f then
        f:write(token)
        f:close()
        -- Restrict permissions to owner only
        os.execute("chmod 600 " .. string.format("%q", tokenPath))
        log.df("Auth token written to: %s", tokenPath)
        return true
    else
        log.ef("Failed to write auth token to: %s", tokenPath)
        return false
    end
end

--- plugins.core.websocket.manager.getAuthTokenPath() -> string
--- Function
--- Returns the path where the auth token file is stored.
---
--- Returns:
---  * The file path string
function mod.getAuthTokenPath()
    local tokenDir = config.userConfigRootPath
    if not tokenDir then
        tokenDir = os.getenv("HOME") .. "/.CommandPost"
    end
    return tokenDir .. "/" .. AUTH_TOKEN_FILENAME
end

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
        --log.df("WebSocket control surface enabled")
        mod.start()
    else
        --log.df("WebSocket control surface disabled")
        mod.stop()
    end
end)

--- plugins.core.websocket.manager.mode() -> string
--- Function
--- Returns the operation mode (always "server")
function mod.mode()
    return mod.MODE.SERVER
end

--- plugins.core.websocket.manager.serverPort <cp.prop: number>
--- Variable
--- Server port (default: 27480)
mod.serverPort = config.prop("websocket.serverPort", 27480):watch(function(port)
    --log.df("[PROP WATCH] WebSocket server port changed to: %d", port)
    --log.df("[PROP WATCH] Current enabled state: %s, mode: %s", tostring(mod.enabled()), mod.mode())
    if mod.enabled() and mod.mode() == mod.MODE.SERVER then
        -- Restart server with new port
        --log.df("[PROP WATCH] Restarting server with new port")
        mod.stop()
        mod.start()
    else
        --log.df("[PROP WATCH] Not restarting server (enabled: %s, mode: %s)", tostring(mod.enabled()), mod.mode())
    end
end)


--- plugins.core.websocket.manager.start() -> boolean
--- Function
--- Starts the WebSocket server.
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

    --log.df("Starting WebSocket server")
    return mod.startServer()
end

--- plugins.core.websocket.manager.stop() -> nil
--- Function
--- Stops the WebSocket server.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    --log.df("Stopping WebSocket server")
    mod.stopServer()
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

    -- Generate and write auth token for this session
    local token = generateAuthToken()
    writeAuthToken(token)
    messageHandler.setAuthToken(token)
    log.df("WebSocket server auth token generated for session")

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
    --log.df("Stopping WebSocket server")
    server.stop()
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
    --log.df("Received message on connection %s: %s", connection.id, message)

    -- Process the message
    local response = messageHandler.handleMessage(connection, message)

    -- Send response if available
    if response then
        local ok, encoded = pcall(json.encode, response)
        if ok then
            -- In client mode we must explicitly send the response back across the
            -- outbound websocket connection. In server mode the websocket callback
            -- return value is already routed to the requesting client, so sending
            -- it again would broadcast request/response traffic to every client.
            if connection and (connection.mode == "client" or connection.type == "client") then
                connection:send(encoded)
                return nil
            end
            return encoded
        else
            log.ef("Failed to encode response: %s", encoded)
        end
    end
end

--- plugins.core.websocket.manager.broadcastMessage(message) -> number
--- Function
--- Broadcasts a message to all connections.
---
--- Parameters:
---  * message - The message to broadcast (string or table)
---
--- Returns:
---  * Number of clients the message was sent to
function mod.broadcastMessage(message)
    return server.broadcast(message)
end

--- plugins.core.websocket.manager.sendMessage(message) -> boolean
--- Function
--- Broadcasts a message to all connections.
---
--- Parameters:
---  * message - The message to send (string or table)
---
--- Returns:
---  * true if sent successfully, false otherwise
function mod.sendMessage(message)
    return mod.broadcastMessage(message) > 0
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
    return {
        enabled = mod.enabled(),
        mode = mod.mode(),
        serverRunning = server.isRunning(),
        serverPort = mod.serverPort(),
        clientCount = server.getClientCount(),
        clients = server.getClientList()
    }
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
    return server.getClientList()
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

    -- Initialize audit log in the CommandPost config directory
    local configPath = config.userConfigRootPath
    if configPath then
        messageHandler.initAuditLog(configPath)
    end

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
        :titled(i18n("websocketEnableWebSocketControlSurface"))

    global
        :add("disableWebSocket")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :titled(i18n("websocketDisableWebSocketControlSurface"))

    global
        :add("toggleWebSocket")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")
        :titled(i18n("websocketToggleWebSocketControlSurface"))

    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Start if enabled:
    --------------------------------------------------------------------------------
    mod.enabled:update()
end

return plugin
