--- === plugins.core.websocket.prefs ===
---
--- WebSocket Control Surface Preferences Panel

local require = require

local log           = require("hs.logger").new("ws_prefs")
local inspect       = require "hs.inspect"

local dialog        = require "hs.dialog"
local image         = require "hs.image"
local timer         = require "hs.timer"

local config        = require "cp.config"
local html          = require "cp.web.html"
local i18n          = require "cp.i18n"
local tools         = require "cp.tools"

local doAfter       = timer.doAfter
local imageFromPath = image.imageFromPath
local webviewAlert  = dialog.webviewAlert

local mod = {}

-- renderPanel(context) -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderPanel(context)
    if not mod._renderPanel then
        local errorMessage
        mod._renderPanel, errorMessage = mod._env:compileTemplate("html/panel.html")
        if errorMessage then
            log.ef(errorMessage)
            return nil
        end
    end
    return mod._renderPanel(context)
end

-- generateContent() -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML content as string
local function generateContent()
    local context = {
        webviewLabel = mod._prefsManager.getLabel(),
        i18n = i18n,
        manager = mod._manager,  -- Pass manager to template
    }
    return renderPanel(context)
end

-- updateUI() -> none
-- Function
-- Updates the preferences panel user interface.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updateUI()
    local injectScript = mod._prefsManager.injectScript
    if not injectScript then
        log.wf("injectScript not available")
        return
    end

    log.df("Updating WebSocket UI")

    local manager = mod._manager

    -- Log current values from manager
    log.df("Current manager values - enabled: %s, mode: %s, serverPort: %d, clientUrl: '%s'",
        tostring(manager.enabled()), manager.mode(), manager.serverPort(), manager.clientUrl())

    -- Update enabled checkbox
    injectScript([[
        var elem = document.getElementById("enableWebSocket");
        if (elem) {
            elem.checked = ]] .. tostring(manager.enabled()) .. [[;
        }
    ]])

    -- Update mode selection
    injectScript([[
        var elem = document.getElementById("mode");
        if (elem) {
            elem.value = "]] .. manager.mode() .. [[";
            updateModeVisibility();
        }
    ]])

    -- Update server port
    injectScript([[
        var elem = document.getElementById("serverPort");
        if (elem) {
            elem.value = "]] .. manager.serverPort() .. [[";
        }
    ]])

    -- Update client URL
    injectScript([[
        var elem = document.getElementById("clientUrl");
        if (elem) {
            elem.value = "]] .. tools.escapeTilda(manager.clientUrl()) .. [[";
        }
    ]])

    -- Update auto-reconnect
    injectScript([[
        var elem = document.getElementById("autoReconnect");
        if (elem) {
            elem.checked = ]] .. tostring(manager.autoReconnect()) .. [[;
        }
    ]])

    -- Update reconnect interval
    injectScript([[
        var elem = document.getElementById("reconnectInterval");
        if (elem) {
            elem.value = "]] .. manager.reconnectInterval() .. [[";
        }
    ]])

    -- Update connection status
    local status = manager.getConnectionStatus()
    local statusText = "已断开"
    local statusClass = "status-disconnected"
    local connectionInfo = ""

    if status.enabled then
        if status.mode == "server" then
            if status.serverRunning then
                statusText = "服务器运行中"
                statusClass = "status-connected"
                local serverAddress = string.format("ws://localhost:%d", status.serverPort)
                connectionInfo = string.format("地址: %s | 端口: %d | 客户端: %d", serverAddress, status.serverPort, status.clientCount or 0)
            else
                statusText = "服务器已停止"
                statusClass = "status-error"
            end
        else
            if status.clientConnected then
                statusText = "已连接"
                statusClass = "status-connected"
                connectionInfo = "地址: " .. (status.clientUrl or "")
            else
                statusText = "已断开"
                statusClass = "status-disconnected"
            end
        end
    end

    injectScript(string.format([[
        var statusIndicator = document.getElementById("statusIndicator");
        if (statusIndicator) {
            statusIndicator.textContent = "%s";
            statusIndicator.className = "%s";
        }
        var connectionInfoElem = document.getElementById("connectionInfo");
        if (connectionInfoElem) {
            connectionInfoElem.textContent = "%s";
        }
    ]], statusText, statusClass, connectionInfo))

    -- Update active connections list
    local connections = status.clients or (status.connectionInfo and {status.connectionInfo} or {})
    local connectionsHTML = ""

    if #connections > 0 then
        for _, conn in ipairs(connections) do
            connectionsHTML = connectionsHTML .. string.format(
                [[<li><strong>ID:</strong> %s<br><strong>状态:</strong> %s<br><strong>模式:</strong> %s</li>]],
                conn.id or "未知",
                conn.state or "未知",
                conn.mode or "未知"
            )
        end
    else
        connectionsHTML = [[<li class="no-connections">暂无活动连接</li>]]
    end

    injectScript(string.format([[
        var connectionsList = document.getElementById("connectionsList");
        if (connectionsList) {
            connectionsList.innerHTML = `%s`;
        }
    ]], connectionsHTML))
end

-- ============================================================================
-- Action Query Interface Functions
-- ============================================================================

-- Simple JSON encoder helper (must be defined before use)
local json = {}

function json.encode(data)
    local dataType = type(data)

    if dataType == "nil" then
        return "null"
    elseif dataType == "boolean" then
        return data and "true" or "false"
    elseif dataType == "number" then
        return tostring(data)
    elseif dataType == "string" then
        local escaped = data:gsub("\\", "\\\\")
            :gsub("\"", "\\\"")
            :gsub("\n", "\\n")
            :gsub("\r", "\\r")
            :gsub("\t", "\\t")
        return "\"" .. escaped .. "\""
    elseif dataType == "table" then
        local is_array = #data > 0
        local parts = {}

        if is_array then
            for i = 1, #data do
                table.insert(parts, json.encode(data[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(data) do
                table.insert(parts, json.encode(k) .. ":" .. json.encode(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return "null"
    end
end

--- openActionChooser() -> none
-- Function
-- Opens CommandPost's built-in action chooser (activator).
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function openActionChooser()
    log.df("Opening CommandPost Action Chooser")

    -- Create activator if it doesn't exist
    if not mod.actionActivator then
        local handlerIds = mod._actionmanager.handlerIds()

        -- Get all available handlers (no filtering)
        local activator = mod._actionmanager.getActivator("websocketActionQuery")

        -- Allow all handlers
        activator:allowHandlers(table.unpack(handlerIds))

        -- Setup toolbar icons from app manager
        local searchConsoleToolbar = mod._appmanager.defaultSearchConsoleToolbar() or {}
        activator:toolbarIcons(searchConsoleToolbar)

        -- Setup activation callback
        activator:onActivate(function(handler, action, text)
            -- Process stylised text
            if text and type(text) == "userdata" then
                text = text:convert("text")
            end

            local actionTitle = text or action.id or "Unknown"
            local rawActionId = action.id or "unknown"
            local handlerID = handler:id()

            -- Get the complete action ID from the handler
            local fullActionId = handler:actionId(action)
            log.df("Action selected - Handler: %s, Raw Action ID: %s, Full Action ID: %s, Title: %s",
                   handlerID, rawActionId, fullActionId, actionTitle)
            log.df("Action object: %s", inspect(action))

            -- Update UI to show selected action
            local injectScript = mod._prefsManager.injectScript
            if injectScript then
                local titleJson = json.encode(actionTitle)
                local handlerJson = json.encode(handlerID)
                local rawActionIdJson = json.encode(rawActionId)
                local fullActionIdJson = json.encode(fullActionId or rawActionId)

                -- Create example JSON message
                local exampleMsg = json.encode({
                    type = "command",
                    id = "msg-001",
                    payload = {
                        handler = handlerID,
                        actionId = fullActionId or rawActionId
                    }
                })

                injectScript(string.format([[
                    var display = document.getElementById("selectedActionDisplay");
                    var title = document.getElementById("selectedActionTitle");
                    var handler = document.getElementById("selectedActionHandler");
                    var jsonElem = document.getElementById("selectedActionJson");

                    if (display && title && handler && jsonElem) {
                        display.style.display = "block";
                        title.textContent = %s;
                        handler.textContent = "Handler: " + %s + " | Action ID: " + %s;
                        jsonElem.textContent = "WebSocket 消息示例:\n" + %s;
                    }
                ]], titleJson, handlerJson, fullActionIdJson, json.encode(exampleMsg)))
            end
        end)

        mod.actionActivator = activator
    end

    -- Show the activator
    mod.actionActivator:show()
end

--- plugins.core.websocket.prefs.init(deps, env) -> module
--- Function
--- Initialise the Module.
---
--- Parameters:
---  * deps - Dependencies
---  * env - Environment
---
--- Returns:
---  * The module
function mod.init(deps, env)
    mod._manager = deps.manager
    mod._prefsManager = deps.prefsManager
    mod._actionmanager = deps.actionmanager
    mod._appmanager = deps.appmanager
    mod._env = env

    -- Setup update callback in manager
    deps.manager.updateUI = updateUI

    -- Create preferences panel
    local panel = deps.prefsManager.addPanel({
        priority = 2033,
        id = "websocket",
        label = "WebSocket",
        image = imageFromPath(env:pathToAbsolute("/images/websocket.png")),
        tooltip = "WebSocket 控制表面设置",
        height = 800,
    })
    :addContent(0.1, generateContent, false)

    -- Setup panel callbacks
    panel:addHandler("onchange", "websocketPanelCallback", function(id, params)
        log.df("websocketPanelCallback called - id: %s, params: %s", id, inspect(params))
        local manager = mod._manager

        -- Extract type from params (postMessage format)
        local actionType = params.type or id

        if actionType == "enableWebSocket" then
            log.df("Enable checkbox changed: %s", params.checked)
            manager.enabled(params.checked)
            updateUI()

        elseif actionType == "mode" then
            log.df("Mode changed to: %s", params.value)
            manager.mode(params.value)
            updateUI()

        elseif actionType == "serverPort" then
            local port = tonumber(params.value)
            local currentPort = manager.serverPort()
            log.df("Server port change request - current: %d, new: %s", currentPort, params.value)
            if port and port > 0 and port <= 65535 then
                log.df("Setting server port to: %d", port)
                manager.serverPort(port)
                local savedPort = manager.serverPort()
                log.df("Server port after save: %d (saved successfully: %s)", savedPort, tostring(savedPort == port))
                updateUI()
            else
                webviewAlert(mod._prefsManager.getWebview(), function() end,
                    "无效的端口号",
                    "请输入 1 到 65535 之间的有效端口号",
                    "确定")
            end

        elseif actionType == "clientUrl" then
            local currentUrl = manager.clientUrl()
            log.df("Client URL change request - current: '%s', new: '%s'", currentUrl, params.value)
            if params.value and params.value ~= "" then
                log.df("Setting client URL to: %s", params.value)
                manager.clientUrl(params.value)
                local savedUrl = manager.clientUrl()
                log.df("Client URL after save: '%s' (saved successfully: %s)", savedUrl, tostring(savedUrl == params.value))
                updateUI()
            else
                webviewAlert(mod._prefsManager.getWebview(), function() end,
                    "无效的服务器地址",
                    "请输入有效的 WebSocket 服务器地址 (例如: ws://localhost:8080)",
                    "确定")
            end

        elseif actionType == "autoReconnect" then
            log.df("Auto-reconnect changed: %s", params.checked)
            manager.autoReconnect(params.checked)
            updateUI()

        elseif actionType == "reconnectInterval" then
            local interval = tonumber(params.value)
            if interval and interval > 0 then
                log.df("Reconnect interval changed to: %d", interval)
                manager.reconnectInterval(interval)
                updateUI()
            end

        elseif actionType == "testConnection" then
            local status = manager.getConnectionStatus()
            local message = ""

            if status.enabled then
                if status.mode == "server" then
                    if status.serverRunning then
                        message = string.format("服务器正在运行\n端口: %d\n已连接客户端数: %d", status.serverPort, status.clientCount)
                    else
                        message = "服务器未运行"
                    end
                else
                    if status.clientConnected then
                        message = "已连接到服务器\n地址: " .. (status.clientUrl or "")
                    else
                        message = "未连接到服务器"
                    end
                end
            else
                message = "WebSocket 控制表面已禁用"
            end

            webviewAlert(mod._prefsManager.getWebview(), function() end,
                "连接状态",
                message,
                "确定")

        elseif actionType == "refreshStatus" then
            log.df("Refresh status clicked")
            updateUI()

        elseif actionType == "openActionChooser" then
            log.df("Open Action Chooser requested")
            openActionChooser()

        else
            log.df("Unknown callback type: %s (id: %s)", actionType, id)
            log.df("params: %s", inspect(params))
        end
    end)

    -- Watch for panel changes to update UI when switching to this panel
    deps.prefsManager.lastTab:watch(function(tabId)
        log.df("Panel switched to: %s", tabId)
        if tabId == "websocket" then
            -- Log current values before UI update
            log.df("Before updateUI - serverPort: %d, clientUrl: '%s'",
                mod._manager.serverPort(), mod._manager.clientUrl())

            -- Schedule updateUI to run after HTML is generated and rendered
            log.df("Scheduling updateUI() for WebSocket panel")
            doAfter(0.5, function()
                log.df("Executing updateUI() for WebSocket panel")
                -- Force blur on active element to ensure pending changes are saved
                local injectScript = mod._prefsManager.injectScript
                if injectScript then
                    log.df("Injecting blur script for active element")
                    injectScript([[
                        var activeElement = document.activeElement;
                        console.log('[WebSocket Lua] Active element:', activeElement ? activeElement.id : 'none');
                        if (activeElement && activeElement.tagName === 'INPUT') {
                            console.log('[WebSocket Lua] Blurring active input:', activeElement.id);
                            activeElement.blur();
                        }
                    ]])
                end
                -- Small delay to allow blur event to process
                doAfter(0.1, function()
                    log.df("Now calling updateUI()")
                    updateUI()
                end)
            end)
        end
    end)

    return mod
end

local plugin = {
    id = "core.websocket.prefs",
    group = "core",
    dependencies = {
        ["core.controlsurfaces.manager"] = "prefsManager",
        ["core.websocket.manager"] = "manager",
        ["core.action.manager"] = "actionmanager",
        ["core.application.manager"] = "appmanager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
