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

    --log.df("Updating WebSocket UI")

    local manager = mod._manager

    -- Log current values from manager
    --log.df("Current manager values - enabled: %s, mode: %s, serverPort: %d", tostring(manager.enabled()), manager.mode(), manager.serverPort())

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


    -- Update connection status
    local status = manager.getConnectionStatus()
    local statusText = i18n("websocketDisconnected")
    local statusClass = "status-disconnected"
    local connectionInfo = ""

    if status.enabled then
        if status.serverRunning then
            statusText = i18n("websocketServerRunning")
            statusClass = "status-connected"
            local serverAddress = string.format("ws://localhost:%d", status.serverPort)
            connectionInfo = string.format("%s: %s | %s: %d | %s: %d",
                i18n("websocketAddress"), serverAddress,
                i18n("websocketServerPort"), status.serverPort,
                i18n("websocketClients"), status.clientCount or 0)
        else
            statusText = i18n("websocketServerStopped")
            statusClass = "status-error"
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
                [[<li><strong>%s:</strong> %s<br><strong>%s:</strong> %s<br><strong>%s:</strong> %s</li>]],
                i18n("wsId"), conn.id or i18n("unknown"),
                i18n("wsStatus"), conn.state or i18n("unknown"),
                i18n("wsMode"), conn.mode or i18n("unknown")
            )
        end
    else
        connectionsHTML = [[<li class="no-connections">]] .. i18n("websocketNoActiveConnections") .. [[</li>]]
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

-- simplifyActionId(handlerID, actionId) -> string
-- Function
-- Simplifies action IDs by removing common path prefixes for FCPX plugins.
--
-- Parameters:
--  * handlerID - The handler ID (e.g., "fcpx_videoEffect")
--  * actionId  - The full action ID (path or identifier)
--
-- Returns:
--  * Simplified action ID, or original if no simplification needed
local function simplifyActionId(handlerID, actionId)
    if not actionId or type(actionId) ~= "string" then
        return actionId
    end

    -- Only simplify FCPX plugin paths
    local fcpxPluginHandlers = {
        ["fcpx_videoEffect"] = true,
        ["fcpx_audioEffect"] = true,
        ["fcpx_generator"] = true,
        ["fcpx_title"] = true,
        ["fcpx_transition"] = true
    }

    if not fcpxPluginHandlers[handlerID] then
        return actionId
    end

    -- Handle System Components (e.g., CoreAudio components)
    -- Pattern: /System/Library/Components/ComponentName.component/...
    local systemComponentsPrefix = "/System/Library/Components/"
    if actionId:find(systemComponentsPrefix, 1, true) then
        local componentName = actionId:match("/System/Library/Components/([^/]+)%.component/")
        if componentName then
            return componentName
        end
    end

    -- Handle Flexo Framework Effect Bundles
    -- Pattern: /Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Resources/Effect Bundles/Name.Category.audio.effectBundle
    local flexoPrefix = "/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Resources/Effect Bundles/"
    if actionId:find(flexoPrefix, 1, true) then
        local bundleName = actionId:match("/Effect Bundles/(.+)%.effectBundle$")
        if bundleName then
            -- Parse the bundle name: "Name.Category.audio" -> extract Name and Category
            -- Format can be: "Mud Removal 2.EQ.audio" or similar
            local name, category = bundleName:match("^(.+)%.([^%.]+)%.[^%.]+$")
            if name and category then
                return category .. "/" .. name
            else
                -- Fallback: just use the first part before any dot
                local simpleName = bundleName:match("^([^%.]+)")
                return simpleName or bundleName
            end
        end
    end

    -- Remove common FCPX plugin path prefix
    -- Pattern: /Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/.../Effects.localized/.../...localized
    local commonPrefix = "/Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/"

    -- Check if it's a full FCPX plugin path
    local startIdx = actionId:find(commonPrefix, 1, true)
    if startIdx then
        -- Find the start of the meaningful path after .fxp/Contents/Resources/
        -- This handles both "Templates.localized" and "PETemplates.localized"
        local afterResources = actionId:match(".fxp/Contents/Resources/(.+)$")
        if afterResources then
            -- Remove the first directory level (Templates.localized or PETemplates.localized, etc.)
            -- and get the remaining path
            local remainingPath = afterResources:match("[^/]+/(.+)$") or afterResources

            -- Extract all path parts and remove .localized suffix from each
            local parts = {}
            for part in (remainingPath .. "/"):gmatch("([^/]+)/") do
                -- Remove .localized suffix if present
                local cleanPart = part:gsub("%.localized$", "")
                if cleanPart ~= "" then
                    table.insert(parts, cleanPart)
                end
            end

            -- Join with forward slashes
            if #parts >= 2 then
                -- Return at least category/name (e.g., "Blur/Prism")
                -- or type/category/name (e.g., "Effects/Blur/Prism")
                local startIndex = #parts >= 3 and 1 or 2
                return table.concat(parts, "/", startIndex)
            end
        end
    end

    return actionId
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
local function openActionChooser(opts)
    --log.df("Opening CommandPost Action Chooser")

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
            --log.df("Action selected - Handler: %s, Raw Action ID: %s, Full Action ID: %s, Title: %s", handlerID, rawActionId, fullActionId, actionTitle)
            --log.df("Action object: %s", inspect(action))

            -- Determine the actual action ID to use
            local actualActionId = fullActionId or rawActionId

            -- For fcpx_shortcuts handler: the fullActionId is generic "fcpxShortcuts"
            -- but the actual CommandSetID is stored in action itself (if it's a string)
            -- or in action.params (if it's a table)
            if fullActionId == "fcpxShortcuts" then
                if type(action) == "string" then
                    -- action is the CommandSetID directly (e.g., "SelectToolTrim")
                    actualActionId = action
                    --log.df("Using action string as actualActionId: %s", actualActionId)
                elseif type(action) == "table" and action.params then
                    -- action.params contains the CommandSetID
                    actualActionId = action.params
                    --log.df("Using action.params as actualActionId: %s", actualActionId)
                end
            -- For FCPX plugin handlers (video effects, audio effects, generators, etc.):
            -- The fullActionId is generic (e.g., "fcpx_videoEffect"), but the actual
            -- unique identifier is stored in action.path or action.name
            elseif handlerID == "fcpx_videoEffect" or handlerID == "fcpx_audioEffect" or
                   handlerID == "fcpx_generator" or handlerID == "fcpx_title" or
                   handlerID == "fcpx_transition" then
                if type(action) == "table" then
                    -- Use path as the primary identifier
                    -- If no path, use category/name format for uniqueness
                    if action.path then
                        actualActionId = action.path
                    elseif action.category and action.name then
                        actualActionId = action.category .. "/" .. action.name
                    else
                        actualActionId = action.name or fullActionId
                    end
                    --log.df("Using FCPX plugin path/name as actualActionId: %s", actualActionId)
                end
            end

            -- Simplify actionId for FCPX plugins (remove common path prefixes)
            local simplifiedActionId = simplifyActionId(handlerID, actualActionId)
            --log.df("Simplified actionId: %s -> %s", actualActionId, simplifiedActionId)

            -- Update UI to show selected action
            local injectScript = mod._prefsManager.injectScript
            if injectScript then
                local titleJson = json.encode(actionTitle)
                local handlerJson = json.encode(handlerID)
                local rawActionIdJson = json.encode(rawActionId)
                local actualActionIdJson = json.encode(actualActionId)
                local simplifiedActionIdJson = json.encode(simplifiedActionId)

                -- Create example JSON message with simplified actionId
                local exampleMsg = json.encode({
                    type = "command",
                    id = "msg-001",
                    payload = {
                        handler = handlerID,
                        actionId = simplifiedActionId
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
                        handler.textContent = "%s: " + %s + " | %s: " + %s;
                        jsonElem.textContent = "%s\\n" + %s;
                    }
                ]], titleJson,
                    i18n("wsHandler"), handlerJson, i18n("wsActionId"), simplifiedActionIdJson,
                    i18n("websocketMessageExample"), json.encode(exampleMsg)))
            end
        end)

        mod.actionActivator = activator
    end

    -- If a bundleID was provided, try to enable handlers for that bundle (group)
    if opts and type(opts) == "table" and opts.bundleID and opts.bundleID ~= "" then
        local bundleID = opts.bundleID
        --log.df("openActionChooser: applying bundleID filter: %s", bundleID)
        local appInfo = nil
        if mod._appmanager and mod._appmanager.getApplications then
            local apps = mod._appmanager.getApplications() or {}
            appInfo = apps[bundleID]
        end

        local groupID = nil
        if appInfo and appInfo.legacyGroupID then
            groupID = appInfo.legacyGroupID
        else
            -- Fallback: assume bundleID may itself be a group ID
            groupID = bundleID
        end

        -- Try to get an icon for the bundle (best-effort)
        local icon = nil
        local displayName = (appInfo and appInfo.displayName) and appInfo.displayName or bundleID
        local ok, err = pcall(function()
            if image and image.imageFromAppBundle then
                icon = image.imageFromAppBundle(bundleID)
            end
        end)

        -- Apply filters to activator
        local applied, applyErr = pcall(function()
            if groupID and mod.actionActivator and mod.actionActivator.enableHandlers then
                mod.actionActivator:enableHandlers(groupID)
            end
            if mod.actionActivator and mod.actionActivator.setBundleID then
                if icon then
                    mod.actionActivator:setBundleID(bundleID, icon, displayName)
                else
                    mod.actionActivator:setBundleID(bundleID, nil, displayName)
                end
            end
        end)
        if not applied then
            log.ef("openActionChooser: bundleID filter apply failed: %s", tostring(applyErr))
        end
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
        tooltip = i18n("websocketControlSurfaceSettings"),
        height = 800,
    })
    :addContent(0.1, generateContent, false)

    -- Setup panel callbacks
    panel:addHandler("onchange", "websocketPanelCallback", function(id, params)
        --log.df("websocketPanelCallback called - id: %s, params: %s", id, inspect(params))
        local manager = mod._manager

        -- Extract type from params (postMessage format)
        local actionType = params.type or id

        if actionType == "enableWebSocket" then
            --log.df("Enable checkbox changed: %s", params.checked)
            manager.enabled(params.checked)
            updateUI()

        elseif actionType == "mode" then
            --log.df("Mode changed to: %s", params.value)
            manager.mode(params.value)
            updateUI()

        elseif actionType == "serverPort" then
            local port = tonumber(params.value)
            local currentPort = manager.serverPort()
            --log.df("Server port change request - current: %d, new: %s", currentPort, params.value)
            if port and port > 0 and port <= 65535 then
                --log.df("Setting server port to: %d", port)
                manager.serverPort(port)
                local savedPort = manager.serverPort()
                --log.df("Server port after save: %d (saved successfully: %s)", savedPort, tostring(savedPort == port))
                updateUI()
            else
                webviewAlert(mod._prefsManager.getWebview(), function() end,
                    i18n("websocketInvalidPortNumber"),
                    i18n("websocketInvalidPortNumberDescription"),
                    i18n("ok"))
            end


        elseif actionType == "testConnection" then
            local status = manager.getConnectionStatus()
            local message = ""

            if status.enabled then
                if status.serverRunning then
                    message = i18n("websocketServerRunningWithDetails", {port = status.serverPort, count = status.clientCount})
                else
                    message = i18n("websocketServerNotRunning")
                end
            else
                message = i18n("websocketControlSurfaceDisabled")
            end

            webviewAlert(mod._prefsManager.getWebview(), function() end,
                i18n("websocketConnectionStatus"),
                message,
                i18n("ok"))

        elseif actionType == "refreshStatus" then
            --log.df("Refresh status clicked")
            updateUI()

        elseif actionType == "openActionChooser" then
            --log.df("Open Action Chooser requested - params: %s", inspect(params))
            -- Pass through optional bundleID filter
            openActionChooser(params)

        elseif actionType == "requestAppList" then
            --log.df("App list requested from webview")
            -- Gather registered applications from appmanager
            local apps = {}
            if mod._appmanager and mod._appmanager.getApplications then
                local registered = mod._appmanager.getApplications() or {}
                for bundleID, info in pairs(registered) do
                    table.insert(apps, {bundleID = bundleID, displayName = info.displayName or bundleID})
                end
            end
            -- Inject JS to populate select element
            local injectScript = mod._prefsManager.injectScript
            if injectScript then
                local options = ""
                for _,app in ipairs(apps) do
                    options = options .. string.format("<option value='%s'>%s</option>", app.bundleID, tools.escapeTilda(app.displayName))
                end
                local allAppsText = i18n("allApplications")
                injectScript(string.format([[
                    var select = document.getElementById('actionAppFilter');
                    if (select) {
                        select.innerHTML = '<option value="">%s</option>' + `%s`;
                    }
                ]], allAppsText, options))
            end

        elseif actionType == "copyToClipboard" then
            --log.df("Copy to clipboard requested")
            local text = params.text
            if text and text ~= "" then
                -- Put text on the clipboard
                hs.pasteboard.setContents(text)

                -- Notify JavaScript of success
                local injectScript = mod._prefsManager.injectScript
                if injectScript then
                    injectScript([[
                        if (typeof onCopySuccess === 'function') {
                            onCopySuccess();
                        }
                    ]])
                end
                --log.df("Text copied to clipboard successfully")
            else
                log.wf("No text to copy")

                -- Notify JavaScript of error
                local injectScript = mod._prefsManager.injectScript
                if injectScript then
                    injectScript([[if (typeof onCopyError === 'function') { onCopyError('No text provided'); }]])
                end
            end

        else
            log.wf("Unknown callback type: %s (id: %s)", actionType, id)
            log.wf("params: %s", inspect(params))
        end
    end)

    -- Watch for panel changes to update UI when switching to this panel
    deps.prefsManager.lastTab:watch(function(tabId)
        --log.df("Panel switched to: %s", tabId)
        if tabId == "websocket" then
            -- Log current values before UI update
            --log.df("Before updateUI - serverPort: %d", mod._manager.serverPort())

            -- Schedule updateUI to run after HTML is generated and rendered
            --log.df("Scheduling updateUI() for WebSocket panel")
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
                    --log.df("Now calling updateUI()")
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
