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

    -- Find the handler
    local handler = mod.actionManager:getHandler(handlerId)
    if not handler then
        log.wf("Handler not found: %s (len: %d)", handlerId, #handlerId)
        log.wf("Requested handler ID bytes: %s", {string.byte(handlerId, 1, #handlerId)})

        -- Debug: Try to access the handlers table directly
        local handlersTable = mod.actionManager.handlers()
        log.df("Direct handlers table lookup for '%s': %s", handlerId, handlersTable[handlerId] ~= nil)

        -- Try to find similar handlers
        local handlerIds = mod.actionManager.handlerIds()
        for _, id in ipairs(handlerIds) do
            if id:lower():gsub("%s+", "") == handlerId:lower():gsub("%s+", "") then
                log.df("Found matching handler after normalization: '%s' (requested: '%s')", id, handlerId)
                log.df("Direct table lookup: %s", handlersTable[id] ~= nil)

                log.df("Trying to get handler with normalized ID...")
                handler = mod.actionManager:getHandler(id)
                if handler then
                    log.df("Successfully retrieved handler with normalized ID: '%s'", id)
                    handlerId = id  -- Update to the correct ID
                    break
                else
                    log.wf("getHandler still returned nil for ID: '%s' (len: %d)", id, #id)
                    log.wf("ID bytes: %s", {string.byte(id, 1, #id)})
                    -- Try direct table access as workaround
                    handler = handlersTable[id]
                    if handler then
                        log.df("Workaround: Retrieved handler directly from table for ID: '%s'", id)
                        handlerId = id
                        break
                    end
                end
            end
        end

        if not handler then
            log.wf("Available handlers: %s", table.concat(mod.actionManager.handlerIds(), ", "))
            return mod.createErrorResponse(data.id, "Handler not found: " .. handlerId)
        end
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
        local handlerIds = mod.actionManager.handlerIds()
        local handlers = {}
        for _, id in ipairs(handlerIds) do
            local handler = mod.actionManager:getHandler(id)
            if handler then
                table.insert(handlers, {
                    id = id,
                    group = handler:group(),
                    label = handler:label()
                })
            end
        end
        return mod.createSuccessResponse(data.id, {handlers = handlers})
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
