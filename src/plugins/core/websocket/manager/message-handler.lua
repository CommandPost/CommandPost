--- === plugins.core.websocket.manager.message-handler ===
---
--- WebSocket Message Handler
---
--- Processes incoming WebSocket messages, validates them, executes commands,
--- and generates responses.

local require = require

local json      = require "hs.json"
local timer     = require "hs.timer"
local just      = require "cp.just"

local log       = require("hs.logger").new("ws_msg")

local mod = {}
local sanitizeForJson

--- Authentication token for WebSocket connections.
--- Set by the manager on startup. If nil, auth is disabled (backwards compat).
local authToken = nil

--- plugins.core.websocket.manager.message-handler.setAuthToken(token) -> nil
--- Function
--- Sets the authentication token required for all non-ping messages.
---
--- Parameters:
---  * token - The token string, or nil to disable auth
function mod.setAuthToken(token)
    authToken = token
end

local MAX_SERIALIZE_DEPTH = 8
local MAX_SERIALIZE_ITEMS = 200
local MAX_SERIALIZE_NODES = 2000
local MAX_SERIALIZE_STRING_LENGTH = 4096
local SLOW_MESSAGE_WARNING_SECONDS = 0.5
local SLOW_EXECUTE_WARNING_SECONDS = 0.25
local SLOW_SERIALIZE_WARNING_SECONDS = 0.1

local wait = just.wait

local DEFAULT_HANDLER_INFO_LIMIT = 200
local MAX_HANDLER_INFO_LIMIT = 1000

-- ============================================================================
-- Audit Log
-- ============================================================================
-- Logs every MCP operation (except pings) to a rotating file for debugging.

local AUDIT_LOG_MAX_SIZE = 512 * 1024  -- 512KB before rotation
local AUDIT_LOG_MAX_FILES = 3          -- Keep 3 rotated files
local auditLogPath = nil
local auditLogEnabled = true

--- summarizePayload(data) -> string
--- Summarizes a message payload for audit logging (abbreviated, no secrets).
local function summarizePayload(data)
    if not data or not data.payload then return "" end
    local p = data.payload
    if p.code then
        -- Truncate Lua code to first 80 chars
        local code = tostring(p.code):gsub("\n", " "):sub(1, 80)
        return "code=" .. code
    elseif p.handler then
        return "handler=" .. tostring(p.handler) .. " action=" .. tostring(p.actionId or "")
    elseif p.query then
        return "query=" .. tostring(p.query)
    elseif p.operations then
        return "batch_ops=" .. tostring(#p.operations)
    end
    return ""
end

--- rotateAuditLog() -> nil
--- Rotates the audit log file if it exceeds the max size.
local function rotateAuditLog()
    if not auditLogPath then return end
    local attr = hs.fs and hs.fs.attributes and hs.fs.attributes(auditLogPath)
    if not attr or not attr.size or attr.size < AUDIT_LOG_MAX_SIZE then return end

    -- Rotate: .log.2 -> .log.3, .log.1 -> .log.2, .log -> .log.1
    for i = AUDIT_LOG_MAX_FILES - 1, 1, -1 do
        local src = auditLogPath .. "." .. i
        local dst = auditLogPath .. "." .. (i + 1)
        os.rename(src, dst)
    end
    os.rename(auditLogPath, auditLogPath .. ".1")
end

--- writeAuditLog(entry) -> nil
--- Appends a log entry to the audit log file.
local function writeAuditLog(entry)
    if not auditLogEnabled or not auditLogPath then return end
    rotateAuditLog()
    -- Use raw io here since this is internal logging, not user code
    local f = io.open(auditLogPath, "a")
    if f then
        f:write(entry .. "\n")
        f:close()
    end
end

--- mod.initAuditLog(configPath) -> nil
--- Initializes the audit log path.
function mod.initAuditLog(configPath)
    if configPath then
        auditLogPath = configPath .. "/mcp-audit.log"
        log.df("MCP audit log: %s", auditLogPath)
    end
end

--- plugins.core.websocket.manager.message-handler.MESSAGE_TYPES
--- Constant
--- Valid message types
mod.MESSAGE_TYPES = {
    COMMAND = "command",
    QUERY = "query",
    PING = "ping",
    RESPONSE = "response",
    EVENT = "event",
    EXECUTE = "execute",
    BATCH = "batch",
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

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- expandFCPXActionId(handlerId, actionId) -> string
-- Function
-- Expands a simplified FCPX action ID back to full path for matching.
-- Also accepts full paths and returns them unchanged.
--
-- Parameters:
--  * handlerId - The handler ID (e.g., "fcpx_videoEffect")
--  * actionId  - The (possibly simplified) action ID
--
-- Returns:
--  * The original actionId if it's a full path, or nil if simplifed (requiring pattern matching)
local function expandFCPXActionId(handlerId, actionId)
    if not actionId or type(actionId) ~= "string" then
        return actionId
    end

    -- If it starts with "/", it's already a full path
    if actionId:sub(1, 1) == "/" then
        return actionId
    end

    -- Otherwise it's a simplified path (e.g., "Blur/Prism")
    -- Return nil to indicate pattern matching is needed
    return nil
end

-- matchesSimplifiedPath(fullPath, simplifiedPath) -> boolean
-- Function
-- Checks if a full FCPX plugin path matches a simplified path.
--
-- Parameters:
--  * fullPath       - The full plugin path (e.g., "/Applications/.../Effects.localized/Blur.localized/Prism.localized")
--  * simplifiedPath - The simplified path (e.g., "Blur/Prism" or "Effects/Blur/Prism")
--
-- Returns:
--  * true if the simplified path matches the end of the full path
local function matchesSimplifiedPath(fullPath, simplifiedPath)
    if not fullPath or not simplifiedPath then
        return false
    end

    -- Normalize the full path:
    -- 1. Remove .localized suffixes (but keep the directory separators)
    -- 2. Replace multiple consecutive slashes with single slash
    local normalizedFull = fullPath:gsub("%.localized", "")
    normalizedFull = normalizedFull:gsub("/+", "/")

    -- Normalize the simplified path
    local normalizedSimple = simplifiedPath:gsub("%.localized", "")
    normalizedSimple = normalizedSimple:gsub("/+", "/")

    -- Add trailing slash to both for consistent matching
    if normalizedFull:sub(-1) ~= "/" then
        normalizedFull = normalizedFull .. "/"
    end
    if normalizedSimple:sub(-1) ~= "/" then
        normalizedSimple = normalizedSimple .. "/"
    end

    -- The simplified path should match the end of the normalized full path
    local result = normalizedFull:sub(-#normalizedSimple) == normalizedSimple

    -- Debug logging for first few comparisons
    if fullPath:find("Prism") then
        --log.df("Matching: %s", simplifiedPath)
        --log.df("  Full (norm): %s", normalizedFull:sub(-100))
        --log.df("  Simple (norm): %s", normalizedSimple)
        --log.df("  Match result: %s", tostring(result))
    end

    return result
end

-- findFCPXPluginBySimplifiedPath(choices, simplifiedPath) -> table | nil
-- Function
-- Finds an FCPX plugin choice by matching a simplified path against full paths,
-- or by matching category/name combination for plugins without paths.
--
-- Parameters:
--  * choices        - Array of choice objects from handler
--  * simplifiedPath - The simplified path to match (e.g., "Blur/Prism" or "Levels/Adaptive Limiter")
--
-- Returns:
--  * The matching choice object, or nil if not found
local function findFCPXPluginBySimplifiedPath(choices, simplifiedPath)
    --log.df("Searching %d choices for simplified path: %s", #choices, simplifiedPath)

    -- Track name-only matches as fallback (lower priority than exact category/name)
    local nameOnlyMatch = nil

    for i, choice in ipairs(choices) do
        if type(choice.params) == "table" then
            local matched = false

            -- Try matching against full path if available
            if choice.params.path then
                matched = matchesSimplifiedPath(choice.params.path, simplifiedPath)
                if matched then
                    --log.df("Found FCPX plugin by path: %s matches simplified path: %s", choice.params.path, simplifiedPath)
                    return choice
                end
            end

            -- Try matching against category/name combination for plugins without paths
            if not matched and choice.params.category and choice.params.name then
                local categoryName = choice.params.category .. "/" .. choice.params.name
                if categoryName == simplifiedPath then
                    --log.df("Found FCPX plugin by category/name: %s matches simplified path: %s", categoryName, simplifiedPath)
                    return choice
                end
            end

            -- Try name-only match as fallback (for inputs like "Cross Dissolve" without category)
            if not matched and not nameOnlyMatch and choice.params.name then
                if choice.params.name == simplifiedPath then
                    nameOnlyMatch = choice
                end
            end

            -- Log first few choices for debugging
            if i <= 3 then
                if choice.params.path then
                    --log.df("Choice %d (path): %s does not match %s", i, choice.params.path:sub(-80), simplifiedPath)
                elseif choice.params.category and choice.params.name then
                    --log.df("Choice %d (cat/name): %s/%s does not match %s", i, choice.params.category, choice.params.name, simplifiedPath)
                end
            end
        end
    end

    -- Return name-only match if no exact match was found
    if nameOnlyMatch then
        --log.df("Found FCPX plugin by name-only: %s", nameOnlyMatch.params.name)
        return nameOnlyMatch
    end

    --log.df("No matching plugin found for: %s", simplifiedPath)
    return nil
end

-- getHandlerChoices(handler) -> table | nil
-- Function
-- Safely fetches a handler's available choices, preferring cached choices.
--
-- Parameters:
--  * handler - The action handler
--
-- Returns:
--  * Array of choices, or nil if unavailable
local function getHandlerChoices(handler)
    if not handler then
        return nil
    end

    local handlerChoices = handler._choices
    if handlerChoices then
        return handlerChoices:getChoices()
    end

    local ok, choicesResult = pcall(function()
        return handler:choices()
    end)

    if ok and choicesResult then
        return choicesResult:getChoices()
    end

    return nil
end

-- copyTable(original) -> table | any
-- Function
-- Creates a shallow copy of a table so cached handler choice params are not
-- mutated while building action payloads.
--
-- Parameters:
--  * original - The original value
--
-- Returns:
--  * A shallow-copied table, or the original value if it is not a table
local function copyTable(original)
    if type(original) ~= "table" then
        return original
    end

    local copy = {}
    local key = next(original)
    while key ~= nil do
        copy[key] = rawget(original, key)
        key = next(original, key)
    end
    return copy
end

-- clampInteger(value, defaultValue, minimumValue, maximumValue) -> number
-- Function
-- Coerces a value to an integer within the supplied bounds.
--
-- Parameters:
--  * value - The raw value
--  * defaultValue - The fallback integer
--  * minimumValue - The minimum allowed value
--  * maximumValue - The maximum allowed value
--
-- Returns:
--  * The bounded integer value
local function clampInteger(value, defaultValue, minimumValue, maximumValue)
    local numberValue = tonumber(value)
    if not numberValue then
        return defaultValue
    end

    local integerValue = math.floor(numberValue)
    if integerValue < minimumValue then
        return minimumValue
    elseif integerValue > maximumValue then
        return maximumValue
    end

    return integerValue
end

local function summarizeCode(code)
    if type(code) ~= "string" then
        return "<non-string code>"
    end

    local summary = code:gsub("%s+", " ")
    if #summary > 160 then
        summary = summary:sub(1, 157) .. "..."
    end
    return summary
end

local function createSerializationState()
    return {
        refs = {},
        nodes = 0,
        tables = 0,
        userdata = 0,
        maxDepth = 0,
        truncated = false,
        truncationReason = nil,
    }
end

local function markSerializationTruncated(state, reason)
    if state and not state.truncated then
        state.truncated = true
        state.truncationReason = reason
    end
end

local function safeJsonKey(key, index)
    local keyType = type(key)
    if keyType == "string" then
        if #key > MAX_SERIALIZE_STRING_LENGTH then
            return key:sub(1, MAX_SERIALIZE_STRING_LENGTH) .. "... [truncated]"
        end
        return key
    elseif keyType == "number" or keyType == "boolean" then
        return tostring(key)
    end
    return "[" .. keyType .. ":" .. tostring(index or "?") .. "]"
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
    elseif data.type == mod.MESSAGE_TYPES.EXECUTE then
        if not data.payload then
            return false, "Missing 'payload' field for execute"
        end
        if not data.payload.code or type(data.payload.code) ~= "string" then
            return false, "Missing or invalid 'code' field in execute payload"
        end
    elseif data.type == mod.MESSAGE_TYPES.BATCH then
        if not data.payload then
            return false, "Missing 'payload' field for batch"
        end
        if not data.payload.operations or type(data.payload.operations) ~= "table" then
            return false, "Missing or invalid 'operations' array in batch payload"
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
    --log.df("Handling message on connection %s", connection.id)

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

    -- Authentication check (skip for ping — allows health checks without auth)
    if authToken and data.type ~= mod.MESSAGE_TYPES.PING then
        local msgToken = data.auth
        if not msgToken or msgToken ~= authToken then
            log.wf("WebSocket auth failed for message id=%s type=%s", tostring(data.id), tostring(data.type))
            return mod.createErrorResponse(data.id, "Authentication failed: invalid or missing auth token")
        end
    end

    local startedAt = timer.secondsSinceEpoch()
    local response

    -- Handle different message types
    if data.type == mod.MESSAGE_TYPES.PING then
        response = mod.handlePing(data)
    elseif data.type == mod.MESSAGE_TYPES.COMMAND then
        response = mod.handleCommand(data)
    elseif data.type == mod.MESSAGE_TYPES.QUERY then
        response = mod.handleQuery(data)
    elseif data.type == mod.MESSAGE_TYPES.EXECUTE then
        response = mod.handleExecute(data)
    elseif data.type == mod.MESSAGE_TYPES.BATCH then
        response = mod.handleBatch(data)
    else
        response = mod.createErrorResponse(data.id, "Unsupported message type: " .. data.type)
    end

    local elapsed = timer.secondsSinceEpoch() - startedAt
    if elapsed >= SLOW_MESSAGE_WARNING_SECONDS then
        log.wf(
            "Slow websocket message id=%s type=%s elapsed=%.3fs bytes=%d status=%s",
            tostring(data.id),
            tostring(data.type),
            elapsed,
            type(message) == "string" and #message or 0,
            response and tostring(response.status) or "unknown"
        )
    end

    -- Audit log (skip pings to avoid noise)
    if data.type ~= mod.MESSAGE_TYPES.PING then
        pcall(function()
            local status = response and response.status or "unknown"
            local errMsg = response and response.error or ""
            local summary = summarizePayload(data)
            local entry = string.format(
                "%s | %s | %s | %.3fs | %s | %s",
                os.date("%Y-%m-%d %H:%M:%S"),
                tostring(data.type),
                status,
                elapsed,
                summary,
                errMsg ~= "" and ("err=" .. tostring(errMsg):sub(1, 100)) or ""
            )
            writeAuditLog(entry)
        end)
    end

    return response
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

    --log.df("Executing command - Handler: %s, Action ID: %s", handlerId, actionId or "none")

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
            local action
            local choiceParams = nil

            -- Check if this is a FCPX plugin handler (video effects, audio effects, etc.)
            local isFCPXPlugin = handlerId == "fcpx_videoEffect" or handlerId == "fcpx_audioEffect" or
                                handlerId == "fcpx_generator" or handlerId == "fcpx_title" or
                                handlerId == "fcpx_transition"

            if isFCPXPlugin then
                -- For FCPX plugin handlers, actionId can be:
                -- 1. Full path (e.g., "/Applications/Final Cut Pro.app/.../Prism.localized")
                -- 2. Simplified path (e.g., "Blur/Prism")
                --log.df("Searching for FCPX plugin by path: %s", actionId)

                -- Check if actionId is a full path or simplified path
                local isFullPath = actionId:sub(1, 1) == "/"

                local handlerChoices = handler._choices
                if handlerChoices then
                    local allChoices = handlerChoices:getChoices()

                    if isFullPath then
                        -- Direct full path match
                        for _, choice in ipairs(allChoices) do
                            if type(choice.params) == "table" and choice.params.path == actionId then
                                choiceParams = choice.params
                                --log.df("Found matching FCPX plugin (full path): %s", choice.params.name or "unknown")
                                break
                            end
                        end
                    else
                        -- Try simplified path matching
                        local matchingChoice = findFCPXPluginBySimplifiedPath(allChoices, actionId)
                        if matchingChoice then
                            choiceParams = matchingChoice.params
                            --log.df("Found matching FCPX plugin (simplified path): %s", choiceParams.name or "unknown")
                        end
                    end
                else
                    log.wf("Handler choices not cached for %s", handlerId)
                    local ok, choicesResult = pcall(function()
                        return handler:choices()
                    end)
                    if ok and choicesResult then
                        local allChoices = choicesResult:getChoices()

                        if isFullPath then
                            -- Direct full path match
                            for _, choice in ipairs(allChoices) do
                                if type(choice.params) == "table" and choice.params.path == actionId then
                                    choiceParams = choice.params
                                    --log.df("Found matching FCPX plugin (full path): %s", choice.params.name or "unknown")
                                    break
                                end
                            end
                        else
                            -- Try simplified path matching
                            local matchingChoice = findFCPXPluginBySimplifiedPath(allChoices, actionId)
                            if matchingChoice then
                                choiceParams = matchingChoice.params
                                --log.df("Found matching FCPX plugin (simplified path): %s", choiceParams.name or "unknown")
                            end
                        end
                    end
                end

                if choiceParams then
                    -- Copy the params so cached handler choices remain immutable.
                    action = copyTable(choiceParams)
                else
                    log.ef("FCPX plugin not found with path: %s", actionId)
                    return nil, "Plugin not found: " .. actionId
                end
            else
                -- For other handlers, use the original logic
                -- Parse the actionId to extract the actual command ID
                -- Format is typically "prefix:commandId" (e.g., "cmds:preferencesfinalcutpro")
                local colonPos = actionId:find(":")
                local commandId
                if colonPos then
                    -- Extract the command ID after the colon
                    commandId = actionId:sub(colonPos + 1)
                else
                    -- No prefix found, use the raw actionId
                    commandId = actionId
                end

                -- Look up the choice details to get the params
                -- Access handler's internal choices directly to avoid thread issues
                local handlerChoices = handler._choices
                if handlerChoices then
                    local allChoices = handlerChoices:getChoices()
                    for _, choice in ipairs(allChoices) do
                        if choice.id == commandId then
                            choiceParams = choice.params
                            break
                        end
                    end
                else
                    -- Choices not yet cached - this might happen in secondary thread
                    log.wf("Handler choices not cached for %s - attempting to access in secondary thread", handlerId)
                    local ok, choicesResult = pcall(function()
                        return handler:choices()
                    end)
                    if ok and choicesResult then
                        local allChoices = choicesResult:getChoices()
                        for _, choice in ipairs(allChoices) do
                            if choice.id == commandId then
                                choiceParams = choice.params
                                break
                            end
                        end
                    end
                end

                -- Create action object with params if found
                if choiceParams then
                    -- Copy the params so cached handler choices remain immutable.
                    if type(choiceParams) == "table" then
                        action = copyTable(choiceParams)
                        action.id = commandId
                    else
                        -- choiceParams is a string or other type, wrap it in params
                        action = {
                            id = commandId,
                            params = choiceParams
                        }
                    end
                else
                    action = { id = commandId }
                end
            end

            return handler:execute(action)
        else
            -- Execute the handler itself (may open action chooser)
            return handler(parameters)
        end
    end)

    if ok then
        --log.df("Command executed successfully: %s/%s", handlerId, actionId or "none")
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

    --log.df("Handling query: %s", queryType or "none")

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

        --log.df("Returning %d handlers in response", #handlers)
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

        local includeChoices = data.payload.includeChoices ~= false
        if includeChoices then
            local choices = getHandlerChoices(handler) or {}
            local limit = clampInteger(data.payload.limit, DEFAULT_HANDLER_INFO_LIMIT, 0, MAX_HANDLER_INFO_LIMIT)
            local offset = clampInteger(data.payload.offset, 0, 0, #choices)
            local includeParams = data.payload.includeParams == true
            local summarizedChoices = {}
            local lastIndex = math.min(#choices, offset + limit)

            for index = offset + 1, lastIndex do
                local choice = choices[index]
                local summary = {
                    id = choice.id,
                    text = choice.text,
                    subText = choice.subText,
                }
                if includeParams then
                    summary.params = sanitizeForJson(choice.params)
                end
                table.insert(summarizedChoices, summary)
            end

            handlerInfo.choiceCount = #choices
            handlerInfo.returnedChoiceCount = #summarizedChoices
            handlerInfo.offset = offset
            handlerInfo.limit = limit
            handlerInfo.hasMoreChoices = lastIndex < #choices
            handlerInfo.includeParams = includeParams
            handlerInfo.choices = summarizedChoices
        else
            local cachedChoices = handler._choices
            if cachedChoices then
                handlerInfo.choiceCount = #cachedChoices:getChoices()
            end
        end

        return mod.createSuccessResponse(data.id, {handler = handlerInfo})
    elseif queryType == "ping" then
        return mod.createSuccessResponse(data.id, {message = "pong"})
    else
        -- For other queries, treat as command
        return mod.handleCommand(data)
    end
end

-- ============================================================================
-- Lua Execution Support (for MCP)
-- ============================================================================

-- sanitizeForJson(value, seen) -> any
-- Function
-- Recursively converts a Lua value into a JSON-safe representation.
-- Handles tables, functions, userdata, and circular references.
--
-- Parameters:
--  * value - Any Lua value
--  * seen  - Internal table for tracking circular references
--
-- Returns:
--  * A JSON-safe value
function sanitizeForJson(value, state, depth)
    state = state or createSerializationState()
    depth = depth or 0
    local t = type(value)

    state.nodes = state.nodes + 1
    if state.nodes > MAX_SERIALIZE_NODES then
        markSerializationTruncated(state, "max node count exceeded")
        return "[truncated: max nodes]"
    end

    if depth > state.maxDepth then
        state.maxDepth = depth
    end

    if depth >= MAX_SERIALIZE_DEPTH then
        markSerializationTruncated(state, "max depth exceeded")
        return "[truncated: max depth]"
    end

    if value == nil then
        return json.null
    elseif t == "boolean" or t == "number" then
        return value
    elseif t == "string" then
        if #value > MAX_SERIALIZE_STRING_LENGTH then
            markSerializationTruncated(state, "max string length exceeded")
            return value:sub(1, MAX_SERIALIZE_STRING_LENGTH) .. "... [truncated]"
        end
        return value
    elseif t == "table" then
        if state.refs[value] then
            return "[circular reference]"
        end
        state.refs[value] = true
        state.tables = state.tables + 1

        -- Determine if array-like without invoking __pairs metamethods.
        local arrayLength = rawlen(value)
        local isArray = arrayLength > 0
        local key = nil
        local keyCount = 0
        while true do
            key = next(value, key)
            if key == nil then break end

            keyCount = keyCount + 1
            if keyCount > MAX_SERIALIZE_ITEMS then
                markSerializationTruncated(state, "max table items exceeded")
                break
            end

            if isArray then
                if type(key) ~= "number" or key < 1 or key ~= math.floor(key) or key > arrayLength then
                    isArray = false
                end
            else
                -- Continue iterating to count raw keys and trigger truncation above.
            end
        end

        local result = {}
        if isArray then
            local limit = math.min(arrayLength, MAX_SERIALIZE_ITEMS)
            if arrayLength > MAX_SERIALIZE_ITEMS then
                markSerializationTruncated(state, "max array items exceeded")
            end
            for i = 1, limit do
                result[i] = sanitizeForJson(rawget(value, i), state, depth + 1)
            end
            if arrayLength > limit then
                result[limit + 1] = "[truncated " .. tostring(arrayLength - limit) .. " items]"
            end
        else
            local itemIndex = 0
            local currentKey = nil
            while true do
                currentKey = next(value, currentKey)
                if currentKey == nil then break end

                itemIndex = itemIndex + 1
                if itemIndex > MAX_SERIALIZE_ITEMS then
                    markSerializationTruncated(state, "max object items exceeded")
                    result.__truncated = "[truncated after " .. tostring(MAX_SERIALIZE_ITEMS) .. " entries]"
                    break
                end

                result[safeJsonKey(currentKey, itemIndex)] =
                    sanitizeForJson(rawget(value, currentKey), state, depth + 1)
            end
        end

        state.refs[value] = nil
        return result
    elseif t == "function" then
        return "[function]"
    elseif t == "userdata" then
        state.userdata = state.userdata + 1
        markSerializationTruncated(state, "userdata coerced to placeholder")
        return "[userdata]"
    else
        local ok, str = pcall(tostring, value)
        if ok then
            if #str > MAX_SERIALIZE_STRING_LENGTH then
                markSerializationTruncated(state, "max fallback string length exceeded")
                return str:sub(1, MAX_SERIALIZE_STRING_LENGTH) .. "... [truncated]"
            end
            return str
        end
        return "[" .. t .. "]"
    end
end

-- ============================================================================
-- Sandboxed Lua Execution Environment
-- ============================================================================

-- Build a sandboxed environment that inherits from _G but blocks dangerous functions.
-- This prevents MCP execute_lua from performing file I/O, shell execution, or
-- modifying the global environment directly.
local sandboxedEnv
do
    local BLOCKED_FUNCTIONS = {
        -- Shell execution
        "os.execute",
        -- File deletion / rename
        "os.remove",
        "os.rename",
        -- Raw file I/O (cp.* and hs.* APIs are preferred)
        "io.open",
        "io.popen",
        "io.input",
        "io.output",
        "io.lines",
        -- Dynamic code loading from files
        "dofile",
        "loadfile",
        -- Module escape vectors
        "package.loadlib",
        "rawget (global scope bypass)",
    }

    -- Modules that are forbidden via require() to prevent sandbox escapes.
    -- Requesting one of these returns the already-sandboxed version instead of
    -- the real module.
    local BLOCKED_REQUIRE_MODULES = {
        ["os"]  = true,
        ["io"]  = true,
    }

    -- Create sandbox as a proxy table that inherits from _G
    sandboxedEnv = setmetatable({}, {
        __index = function(_, key)
            return _G[key]
        end,
        __newindex = function(t, key, value)
            -- Allow setting new locals/globals within the sandbox, but not on _G itself
            rawset(t, key, value)
        end,
    })

    -- Create shadowed versions of os and io that block dangerous functions
    local sandboxedOs = setmetatable({}, {__index = os})
    sandboxedOs.execute = function() error("os.execute is not permitted in MCP sandbox", 2) end
    sandboxedOs.remove = function() error("os.remove is not permitted in MCP sandbox", 2) end
    sandboxedOs.rename = function() error("os.rename is not permitted in MCP sandbox", 2) end
    rawset(sandboxedEnv, "os", sandboxedOs)

    local sandboxedIo = setmetatable({}, {__index = io})
    sandboxedIo.open = function() error("io.open is not permitted in MCP sandbox", 2) end
    sandboxedIo.popen = function() error("io.popen is not permitted in MCP sandbox", 2) end
    sandboxedIo.input = function() error("io.input is not permitted in MCP sandbox", 2) end
    sandboxedIo.output = function() error("io.output is not permitted in MCP sandbox", 2) end
    sandboxedIo.lines = function() error("io.lines is not permitted in MCP sandbox", 2) end
    rawset(sandboxedEnv, "io", sandboxedIo)

    -- Block dofile and loadfile
    rawset(sandboxedEnv, "dofile", function() error("dofile is not permitted in MCP sandbox", 2) end)
    rawset(sandboxedEnv, "loadfile", function() error("loadfile is not permitted in MCP sandbox", 2) end)

    -- Block rawget to prevent bypassing the sandbox metatable (e.g., rawget(_G, "os"))
    rawset(sandboxedEnv, "rawget", function(t, k)
        -- Allow rawget on non-global tables (needed by some CP modules internally)
        if t == _G or t == sandboxedEnv then
            error("rawget on the global environment is not permitted in MCP sandbox", 2)
        end
        return rawget(t, k)
    end)

    -- Block package.loadlib to prevent loading arbitrary C libraries
    local sandboxedPackage = setmetatable({}, {__index = package})
    sandboxedPackage.loadlib = function() error("package.loadlib is not permitted in MCP sandbox", 2) end
    rawset(sandboxedEnv, "package", sandboxedPackage)

    -- Wrap require() to prevent sandbox escape via require("os") / require("io")
    local realRequire = _G.require
    rawset(sandboxedEnv, "require", function(modname)
        if type(modname) == "string" and BLOCKED_REQUIRE_MODULES[modname] then
            -- Return the already-sandboxed version instead of the real module
            return rawget(sandboxedEnv, modname)
        end
        return realRequire(modname)
    end)

    -- Also block hs.execute if available
    pcall(function()
        local hs_orig = _G.hs
        if hs_orig and hs_orig.execute then
            local sandboxedHs = setmetatable({}, {__index = hs_orig})
            sandboxedHs.execute = function() error("hs.execute is not permitted in MCP sandbox", 2) end
            rawset(sandboxedEnv, "hs", sandboxedHs)
        end
    end)

    log.df("MCP Lua sandbox initialized — blocked: %s", table.concat(BLOCKED_FUNCTIONS, ", "))
end

-- Maximum number of Lua VM instructions before an execution is terminated.
-- Prevents infinite loops from freezing CommandPost's main thread.
-- 50 million instructions ≈ several seconds of CPU time on modern hardware,
-- which is generous enough for legitimate operations but will catch runaway code.
local MAX_EXECUTION_INSTRUCTIONS = 50000000

-- executeLuaCode(code, previousResult) -> any, string | nil
-- Function
-- Compiles and executes Lua code in a sandboxed environment with an optional `_prev` value for chaining.
--
-- Parameters:
--  * code - Lua source code
--  * previousResult - Optional previous batch result exposed as `_prev`
--
-- Returns:
--  * The serialized result, or nil if execution failed
--  * An error message, or nil if execution succeeded
local function executeLuaCode(code, previousResult, requestId)
    local executeStartedAt = timer.secondsSinceEpoch()

    -- Try as expression first (prepend "return"), then as statement.
    -- `_prev` is injected as a local to avoid leaking shared global state
    -- across concurrent requests.
    -- NOTE: Uses sandboxedEnv instead of _G to restrict dangerous operations.
    local fn, compileError = load("local _prev = ...; return " .. code, "mcp-execute", "t", sandboxedEnv)
    if not fn then
        fn, compileError = load("local _prev = ...; " .. code, "mcp-execute", "t", sandboxedEnv)
    end
    if not fn then
        return nil, "Compilation error: " .. tostring(compileError)
    end

    -- Install an instruction-count hook to prevent infinite loops from
    -- blocking CommandPost's main thread. The hook fires every 10000
    -- instructions and errors if the budget is exceeded.
    local instructionCount = 0
    debug.sethook(function()
        instructionCount = instructionCount + 10000
        if instructionCount > MAX_EXECUTION_INSTRUCTIONS then
            error("Execution limit exceeded (" .. MAX_EXECUTION_INSTRUCTIONS .. " instructions). Possible infinite loop.", 2)
        end
    end, "", 10000)

    local results = {pcall(fn, previousResult)}
    local ok = table.remove(results, 1)

    -- Always clear the hook, even on error
    debug.sethook()

    if not ok then
        return nil, "Runtime error: " .. tostring(results[1])
    end

    local serializeStartedAt = timer.secondsSinceEpoch()
    local serializationState = createSerializationState()
    local serialized

    if #results == 0 then
        serialized = json.null
    elseif #results == 1 then
        serialized = sanitizeForJson(results[1], serializationState, 0)
    else
        serialized = {}
        for i, v in ipairs(results) do
            serialized[i] = sanitizeForJson(v, serializationState, 0)
        end
    end

    local serializeElapsed = timer.secondsSinceEpoch() - serializeStartedAt
    local executeElapsed = timer.secondsSinceEpoch() - executeStartedAt
    if executeElapsed >= SLOW_EXECUTE_WARNING_SECONDS
        or serializeElapsed >= SLOW_SERIALIZE_WARNING_SECONDS
        or serializationState.truncated then
        log.wf(
            "WebSocket execute diagnostics id=%s total=%.3fs serialize=%.3fs nodes=%d tables=%d userdata=%d depth=%d truncated=%s reason=%s code=%s",
            tostring(requestId),
            executeElapsed,
            serializeElapsed,
            serializationState.nodes or 0,
            serializationState.tables or 0,
            serializationState.userdata or 0,
            serializationState.maxDepth or 0,
            tostring(serializationState.truncated),
            tostring(serializationState.truncationReason),
            summarizeCode(code)
        )
    end

    -- Return serialization metadata alongside the result
    local meta = nil
    if serializationState.truncated then
        meta = {
            _truncated = true,
            _truncationReason = serializationState.truncationReason,
            _serializationNodes = serializationState.nodes or 0,
            _serializationDepth = serializationState.maxDepth or 0,
        }
    end

    return serialized, nil, meta
end

--- plugins.core.websocket.manager.message-handler.handleExecute(data) -> table
--- Function
--- Handles an execute message by running arbitrary Lua code.
---
--- Parameters:
---  * data - The message data with payload.code containing Lua source
---  * previousResult - Optional previous batch result, exposed to Lua as `_prev`
---
--- Returns:
---  * Response table with the execution result
function mod.handleExecute(data, previousResult)
    local code = data.payload and data.payload.code
    if not code or type(code) ~= "string" then
        return mod.createErrorResponse(data.id, "Missing or invalid 'code' field in payload")
    end

    local serialized, executeError, serializeMeta = executeLuaCode(code, previousResult, data.id)
    if executeError then
        return mod.createErrorResponse(data.id, executeError)
    end

    local result = {result = serialized}

    -- Surface truncation metadata so callers know data was lost
    if serializeMeta then
        result._truncated = serializeMeta._truncated
        result._truncationReason = serializeMeta._truncationReason
        result._serializationNodes = serializeMeta._serializationNodes
        result._serializationDepth = serializeMeta._serializationDepth
    end

    return mod.createSuccessResponse(data.id, result)
end

--- plugins.core.websocket.manager.message-handler.handleBatch(data) -> table
--- Function
--- Handles a batch message by executing multiple operations sequentially.
--- Supports chaining execute and command operations.
---
--- Parameters:
---  * data - The message data with payload.operations array and optional payload.stopOnError
---
--- Returns:
---  * Response table with results array
function mod.handleBatch(data)
    local operations = data.payload and data.payload.operations
    if not operations or type(operations) ~= "table" then
        return mod.createErrorResponse(data.id, "Missing or invalid 'operations' array in payload")
    end

    local stopOnError = data.payload.stopOnError ~= false -- default true
    local results = {}
    local lastResult = nil

    for i, op in ipairs(operations) do
        local opId = (data.id or "batch") .. "_" .. i
        local response

        if op.type == "execute" then
            response = mod.handleExecute({
                id = opId,
                payload = {code = op.code or ""},
            }, lastResult)
        elseif op.type == "command" then
            response = mod.handleCommand({
                id = opId,
                payload = op,
            })
        elseif op.type == "query" then
            response = mod.handleQuery({
                id = opId,
                payload = op,
            })
        elseif op.type == "delay" then
            local delay = tonumber(op.seconds)
            if delay == nil then
                response = mod.createErrorResponse(opId, "Delay operation requires a numeric 'seconds' value")
            elseif delay < 0 then
                response = mod.createErrorResponse(opId, "Delay seconds must be non-negative")
            else
                local sleepTime = math.min(delay, 10)
                wait(sleepTime)
                response = mod.createSuccessResponse(opId, {delayed = sleepTime})
            end
        else
            response = mod.createErrorResponse(opId,
                "Unknown operation type: " .. tostring(op.type) .. ". Valid types: execute, command, query, delay")
        end

        -- Track last successful result for chaining
        if response and response.status == "success" and response.result then
            lastResult = response.result.result or response.result
        end

        table.insert(results, {
            index = i,
            status = response and response.status or "error",
            result = response and response.result or nil,
            error = response and response.error or nil,
        })

        if stopOnError and response and response.status == "error" then
            break
        end
    end

    return mod.createSuccessResponse(data.id, {
        results = results,
        totalOperations = #operations,
        completedOperations = #results,
    })
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
