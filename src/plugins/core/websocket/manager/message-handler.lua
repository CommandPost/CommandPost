--- === plugins.core.websocket.manager.message-handler ===
---
--- WebSocket Message Handler
---
--- Processes incoming WebSocket messages, validates them, executes commands,
--- and generates responses.

local require = require

local json      = require "hs.json"
local timer     = require "hs.timer"

local log       = require("hs.logger").new("ws_msg")

local mod = {}

--- plugins.core.websocket.manager.message-handler.MESSAGE_TYPES
--- Constant
--- Valid message types
mod.MESSAGE_TYPES = {
    COMMAND = "command",
    QUERY = "query",
    PING = "ping",
    RESPONSE = "response",
    EVENT = "event",
}

--- plugins.core.websocket.manager.message-handler.init(actionManager)
--- Function
--- Initializes the message handler with the action manager.
---
--- Parameters:
---  * actionManager - The CommandPost action manager
---
--- Returns:
---  * None
function mod.init(actionManager)
    mod.actionManager = actionManager
end

--- plugins.core.websocket.manager.message-handler.parseMessage(message) -> table | nil, string
--- Function
--- Parses a raw message into a table.
---
--- Parameters:
---  * message - The raw message string
---
--- Returns:
---  * Parsed message table or nil
---  * Error message if parsing failed
function mod.parseMessage(message)
    if type(message) ~= "string" then
        return nil, "Message must be a string"
    end

    local ok, data = pcall(json.decode, message)
    if not ok then
        return nil, "Invalid JSON: " .. tostring(data)
    end

    if type(data) ~= "table" then
        return nil, "Message must be a JSON object"
    end

    return data, nil
end

--- plugins.core.websocket.manager.message-handler.validateMessage(data) -> boolean, string
--- Function
--- Validates a parsed message.
---
--- Parameters:
---  * data - The parsed message table
---
--- Returns:
---  * true if valid, false otherwise
---  * Error message if invalid
function mod.validateMessage(data)
    if not data.type then
        return false, "Missing 'type' field"
    end

    local validType = false
    for _, msgType in pairs(mod.MESSAGE_TYPES) do
        if data.type == msgType then
            validType = true
            break
        end
    end

    if not validType then
        return false, "Invalid message type: " .. tostring(data.type)
    end

    if data.type == mod.MESSAGE_TYPES.COMMAND or data.type == mod.MESSAGE_TYPES.QUERY then
        if not data.payload then
            return false, "Missing 'payload' field for " .. data.type
        end

        -- For COMMAND, require action/handler. For QUERY, it's optional (e.g., ping, listHandlers)
        if data.type == mod.MESSAGE_TYPES.COMMAND then
            if not data.payload.action and not data.payload.handler then
                return false, "Missing 'action' or 'handler' field in payload"
            end
        end
    end

    return true, nil
end

--- plugins.core.websocket.manager.message-handler.handleMessage(connection, message) -> table
--- Function
--- Handles an incoming message and returns a response.
---
--- Parameters:
---  * connection - The connection object
---  * message - The raw message string
---
--- Returns:
---  * Response table
function mod.handleMessage(connection, message)
    log.df("Handling message on connection %s", connection.id)

    -- Parse message
    local data, parseError = mod.parseMessage(message)
    if not data then
        log.ef("Failed to parse message: %s", parseError)
        return mod.createErrorResponse(nil, "Parse error: " .. parseError)
    end

    -- Validate message
    local valid, validError = mod.validateMessage(data)
    if not valid then
        log.ef("Invalid message: %s", validError)
        return mod.createErrorResponse(data.id, "Validation error: " .. validError)
    end

    -- Handle different message types
    if data.type == mod.MESSAGE_TYPES.PING then
        return mod.handlePing(data)
    elseif data.type == mod.MESSAGE_TYPES.COMMAND then
        return mod.handleCommand(data)
    elseif data.type == mod.MESSAGE_TYPES.QUERY then
        return mod.handleQuery(data)
    else
        return mod.createErrorResponse(data.id, "Unsupported message type: " .. data.type)
    end
end

--- plugins.core.websocket.manager.message-handler.handlePing(data) -> table
--- Function
--- Handles a ping message.
---
--- Parameters:
---  * data - The message data
---
--- Returns:
---  * Pong response
function mod.handlePing(data)
    return {
        type = "pong",
        id = data.id,
        timestamp = timer.secondsSinceEpoch(),
    }
end

--- plugins.core.websocket.manager.message-handler.handleCommand(data) -> table
--- Function
--- Handles a command message by executing the specified action.
---
--- Parameters:
---  * data - The message data
---
--- Returns:
---  * Response table
function mod.handleCommand(data)
    if not mod.actionManager then
        return mod.createErrorResponse(data.id, "Action manager not initialized")
    end

    -- Support both old and new payload formats:
    -- Old format: { action: "handlerId" }
    -- New format: { handler: "handlerId", actionId: "actionId" }
    local handlerId = data.payload.handler or data.payload.action
    local actionId = data.payload.actionId
    local parameters = data.payload.parameters or {}

    log.df("Executing command - Handler: %s, Action ID: %s", handlerId, actionId or "none")

    -- Find the handler using direct table access to avoid thread issues
    local handlersTable = mod.actionManager.handlers()
    local handler = handlersTable[handlerId]

    if not handler then
        log.wf("Handler not found: %s", handlerId)
        return mod.createErrorResponse(data.id, "Handler not found: " .. handlerId)
    end

    -- Execute the action
    local ok, result = pcall(function()
        if actionId then
            -- Execute specific action within the handler
            -- Parse the actionId to extract the actual command ID
            -- Format is typically "prefix:commandId" (e.g., "cmds:preferencesfinalcutpro")
            local action
            local colonPos = actionId:find(":")
            if colonPos then
                -- Extract the command ID after the colon
                local commandId = actionId:sub(colonPos + 1)
                action = { id = commandId }
            else
                -- No prefix found, use the raw actionId
                action = { id = actionId }
            end
            return handler:execute(action)
        else
            -- Execute the handler itself (may open action chooser)
            return handler(parameters)
        end
    end)

    if ok then
        log.df("Command executed successfully: %s/%s", handlerId, actionId or "none")
        return mod.createSuccessResponse(data.id, result)
    else
        log.ef("Command execution failed: %s/%s - %s", handlerId, actionId or "none", result)
        return mod.createErrorResponse(data.id, "Execution error: " .. tostring(result))
    end
end

--- plugins.core.websocket.manager.message-handler.handleQuery(data) -> table
--- Function
--- Handles a query message.
---
--- Parameters:
---  * data - The message data
---
--- Returns:
---  * Response table
function mod.handleQuery(data)
    if not mod.actionManager then
        return mod.createErrorResponse(data.id, "Action manager not initialized")
    end

    local actionId = data.payload.action
    local queryType = data.payload.query or actionId

    log.df("Handling query: %s", queryType or "none")

    -- Handle special queries
    if queryType == "handlers" or queryType == "listHandlers" then
        -- Access handlers() directly instead of handlerIds() to avoid thread issues
        local handlersTable = mod.actionManager.handlers()
        local handlers = {}

        -- Iterate through the handlers table using pairs
        for id, handler in pairs(handlersTable) do
            if handler then
                local handlerInfo = {
                    id = id,
                    group = handler:group(),
                    label = handler:label()
                }
                table.insert(handlers, handlerInfo)
            end
        end

        log.df("Returning %d handlers in response", #handlers)
        return mod.createSuccessResponse(data.id, {handlers = handlers})
    elseif queryType == "handlerInfo" then
        -- Get detailed info about a specific handler
        local handlerId = data.payload.handler
        if not handlerId then
            return mod.createErrorResponse(data.id, "Missing 'handler' field in payload for handlerInfo query")
        end

        -- Access handlers() directly to avoid thread issues with getHandler()
        local handlersTable = mod.actionManager.handlers()
        local handler = handlersTable[handlerId]

        if not handler then
            return mod.createErrorResponse(data.id, "Handler not found: " .. handlerId)
        end

        local handlerInfo = {
            id = handlerId,
            group = handler:group(),
            label = handler:label()
        }

        return mod.createSuccessResponse(data.id, {handler = handlerInfo})
    elseif queryType == "ping" then
        return mod.createSuccessResponse(data.id, {message = "pong"})
    else
        -- For other queries, treat as command
        return mod.handleCommand(data)
    end
end

--- plugins.core.websocket.manager.message-handler.createSuccessResponse(id, result) -> table
--- Function
--- Creates a success response.
---
--- Parameters:
---  * id - The message ID
---  * result - The result data
---
--- Returns:
---  * Response table
function mod.createSuccessResponse(id, result)
    return {
        type = mod.MESSAGE_TYPES.RESPONSE,
        id = id,
        timestamp = timer.secondsSinceEpoch(),
        status = "success",
        result = result,
    }
end

--- plugins.core.websocket.manager.message-handler.createErrorResponse(id, error) -> table
--- Function
--- Creates an error response.
---
--- Parameters:
---  * id - The message ID
---  * error - The error message
---
--- Returns:
---  * Response table
function mod.createErrorResponse(id, error)
    return {
        type = mod.MESSAGE_TYPES.RESPONSE,
        id = id,
        timestamp = timer.secondsSinceEpoch(),
        status = "error",
        error = error,
    }
end

--- plugins.core.websocket.manager.message-handler.createEvent(eventType, data) -> table
--- Function
--- Creates an event message.
---
--- Parameters:
---  * eventType - The event type
---  * data - The event data
---
--- Returns:
---  * Event table
function mod.createEvent(eventType, data)
    return {
        type = mod.MESSAGE_TYPES.EVENT,
        event = eventType,
        timestamp = timer.secondsSinceEpoch(),
        data = data or {},
    }
end

return mod
