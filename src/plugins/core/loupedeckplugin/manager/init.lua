--- === plugins.core.loupedeckplugin.manager ===
---
--- Loupedeck Plugin Manager Plugin.

local require                   = require

local log                       = require "hs.logger".new "ldPluginMan"

local application               = require "hs.application"
local fs                        = require "hs.fs"
local inspect                   = require "hs.inspect"
local task                      = require "hs.task"
local timer                     = require "hs.timer"
local websocket                 = require "hs.websocket"

local config                    = require "cp.config"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local doAfter                   = timer.doAfter
local ensureDirectoryExists     = tools.ensureDirectoryExists
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local pathToAbsolute            = fs.pathToAbsolute
local playErrorSound            = tools.playErrorSound

local mod = {}

-- CONNECTION_TIMER_RETRY_IN_SECONDS -> number
-- Constant
-- The number of seconds before we try and reconnect to the Workflow Extension
local CONNECTION_TIMER_RETRY_IN_SECONDS = 5

-- LOUPEDECK_PLUGIN_SERVER_PORT -> number
-- Constant
-- The port for the Loupedeck Plugin Server
local LOUPEDECK_PLUGIN_SERVER_PORT = 54475

--- plugins.core.loupedeckplugin.manager.NUMBER_OF_FAVOURITES -> number
--- Constant
--- Number of favourites
mod.NUMBER_OF_FAVOURITES = 50

-- LOUPEDECK_SERVICE_BUNDLE_IDENTIFIER -> string
-- Constant
-- The Bundle Identifier for the Loupedeck Service application.
local LOUPEDECK_SERVICE_BUNDLE_IDENTIFIER = "com.loupedeck.Loupedeck2"

-- LOUPEDECK_CONFIG_BUNDLE_IDENTIFIER -> string
-- Constant
-- The Bundle Identifier for the LoupedeckConfig application.
local LOUPEDECK_CONFIG_BUNDLE_IDENTIFIER = "com.loupedeck.loupedeckconfig"

-- LOUPEDECK_SUPPORT_PATH -> string
-- Constant
-- The path to where Loupedeck Plugins are stored.
local LOUPEDECK_SUPPORT_PATH = "~/.local/share/Loupedeck"

-- DLL_PATH -> string
-- Constant
-- The path to the DLL contained within the CommandPost Plugin.
local DLL_PATH = "CommandPostPlugin/bin/mac/CommandPostPlugin.dll"

--- plugins.core.loupedeckplugin.manager.favourites <cp.prop: table>
--- Variable
--- A `cp.prop` that that contains all the Monogram Favourites.
mod.favourites = json.prop(os.getenv("HOME") .. "/Library/Application Support/CommandPost/", "Loupedeck Plugin", "Favourites.cpLoupedeckPlugin", {})

--- plugins.core.loupedeckplugin.manager.performAction -> table
--- Variable
--- A table of actions that are triggered by the callback function.
mod.performAction = {}

--- plugins.core.loupedeckplugin.manager.registerAction(name, fn) -> none
--- Function
--- Registers a new Loupedeck Plugin Action.
---
--- Parameters:
---  * name - The name of the action.
---  * fn - The function to trigger.
---
--- Returns:
---  * None
function mod.registerAction(name, fn)
    mod.performAction[name] = fn
end

-- callbackFn -> table
-- Variable
-- A table of callback functions
local callbackFn = {
    ["open"] = function()
        log.df("[Loupedeck Plugin] Connected")
    end,
    ["closed"] = function()
        log.df("[Loupedeck Plugin] Disconnected")
        mod.reconnectionTimer = doAfter(CONNECTION_TIMER_RETRY_IN_SECONDS, mod.startWebSocketClient)
    end,
    ["fail"] = function()
        mod.reconnectionTimer = doAfter(CONNECTION_TIMER_RETRY_IN_SECONDS, mod.startWebSocketClient)
    end,
    ["received"] = function(message)
        local decodedData = message and json.decode(message)
        --log.df("decodedData: %s", hs.inspect(decodedData))
        local actionName = decodedData and decodedData.actionName
        local action = actionName and mod.performAction[actionName]
        if action then
            action(decodedData)
        else
            log.df("[Loupedeck Plugin] Invalid ActionName: '%s'", message)
        end
    end,
    ["pong"] = function()
        log.df("[Loupedeck Plugin] Pong!")
    end
}

-- callbackFn(data) -> none
-- Function
-- The callback function triggered by the UDP socket.
--
-- Parameters:
--  * data - The data read from the socket as a string
--
-- Returns:
--  * None
local function webSocketCallback(status, message)
    if callbackFn[status] then
        callbackFn[status](message)
    else
        log.df("[Loupedeck Plugin] Invalid Status: '%s'\nMessage: '%s'", status, message)
    end
end

--- plugins.core.loupedeckplugin.manager.sendMessage(message) -> none
--- Function
--- Sends a websocket message.
---
--- Parameters:
---  * message - The message to send
---
--- Returns:
---  * None
function mod.sendMessage(message)
    if mod.websocket and mod.websocket:status() == "open" then
        mod.websocket:send(message, false)
    end
end

--- plugins.core.loupedeckplugin.manager.startWebSocketClient() -> none
--- Function
--- Starts the WebSocket Client.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.startWebSocketClient()
    if mod.websocket and (mod.websocket:status() == "connecting" or mod.websocket:status() == "open") then
        return
    end

    if mod.websocket and (mod.websocket:status() == "closed" or mod.websocket:status() == "unknown" or mod.websocket:status() == "fail") then
        mod.websocket:close()
        mod.websocket = nil
    end

    if not mod.websocket then
        mod.websocket = websocket.new("ws://localhost:" .. LOUPEDECK_PLUGIN_SERVER_PORT, webSocketCallback)
    end
end

--- plugins.core.loupedeckplugin.manager.stopWebSocketClient() -> none
--- Function
--- Stops the WebSocket Client.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stopWebSocketClient()
    if mod.websocket then
        mod.websocket:close()
    end
end

--- plugins.core.loupedeckplugin.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Monogram Support.
mod.enabled = config.prop("loupedeckplugin.enabled", false):watch(function(enabled)
    if enabled then
        mod.startWebSocketClient()
    else
        mod.stopWebSocketClient()
    end
end)

--- plugins.core.loupedeckplugin.manager.installPlugin() -> boolean
--- Function
--- Installs the Loupedeck Plugin.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false` if fails.
function mod.installPlugin()
    log.df("[Loupedeck Plugin] Installing Loupedeck Plugin...")

    --------------------------------------------------------------------------------
    -- Make sure the plugin path actually exists:
    --------------------------------------------------------------------------------
    if not ensureDirectoryExists(LOUPEDECK_SUPPORT_PATH, "Plugins") then
        log.ef("[Loupedeck Plugin] Failed to create folder: %s", LOUPEDECK_SUPPORT_PATH .. "/Plugins/")
        return false
    end

    local loupedeckSupportPath               = pathToAbsolute(LOUPEDECK_SUPPORT_PATH)
    local basePath                          = config.basePath
    local embeddedCommandPostPluginPath     = basePath .. "/plugins/core/loupedeckplugin/plugin/CommandPostPlugin"
    local destination                       = loupedeckSupportPath .."/Plugins/" .. DLL_PATH
    local source                            = basePath .. "/plugins/core/loupedeckplugin/plugin/" .. DLL_PATH
    local userCommandPostPluginPath         = loupedeckSupportPath .. "/Plugins/CommandPostPlugin"

    --------------------------------------------------------------------------------
    -- Check if latest plugin is already installed.
    --------------------------------------------------------------------------------
    local ok
    _, ok = os.execute([[/usr/bin/diff "]] .. source .. [[" "]] .. destination .. [["]])
    if not ok then
        log.df("[Loupedeck Plugin] Latest plugin already installed.")
        return true
    end

    --------------------------------------------------------------------------------
    -- Remove the existing plugin:
    --------------------------------------------------------------------------------
    log.df("[Loupedeck Plugin] Removing the existing plugin...")
    _, ok = os.execute([[/bin/rm -R "]] .. userCommandPostPluginPath .. [["]])
    if not ok then
        log.df("[Loupedeck Plugin] Failed to remove the existing plugin.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Create a folder for the Plugin:
    --------------------------------------------------------------------------------
    log.df("[Loupedeck Plugin] Creating folder for plugin...")
    _, ok = os.execute([[/bin/mkdir "]] .. userCommandPostPluginPath .. [["]])
    if not ok then
        log.df("[Loupedeck Plugin] Failed to make a folder for the CommandPost Plugin.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Copying the latest plugin:
    --------------------------------------------------------------------------------
    log.df("[Loupedeck Plugin] Copying latest plugin to Loupedeck folder...")
    _, ok = os.execute([[/bin/cp -R "]] .. embeddedCommandPostPluginPath .. [[/" "]] .. userCommandPostPluginPath .. [["]])
    if not ok then
        log.df("[Loupedeck Plugin] Failed copy the Loupedeck Plugin.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Restart Loupedeck:
    --------------------------------------------------------------------------------
    log.df("[Loupedeck Plugin] Restarting Loupedeck Service & LoupedeckConfig Application...")
    local loupedeckService = application.get(LOUPEDECK_SERVICE_BUNDLE_IDENTIFIER)
    if loupedeckService then
        loupedeckService:kill9()
        doAfter(1, function()
            launchOrFocusByBundleID(LOUPEDECK_SERVICE_BUNDLE_IDENTIFIER)
        end)
    end

    local loupedeckConfig = application.get(LOUPEDECK_CONFIG_BUNDLE_IDENTIFIER)
    if loupedeckConfig then
        loupedeckConfig:kill9()
        doAfter(1, function()
            launchOrFocusByBundleID(LOUPEDECK_CONFIG_BUNDLE_IDENTIFIER)
        end)
    end

    --------------------------------------------------------------------------------
    -- Victory!
    --------------------------------------------------------------------------------
    log.df("[Loupedeck Plugin] Successfully Installed!")
    return true
end

--- plugins.core.loupedeckplugin.manager.updatePlugin() -> none
--- Function
--- Updates the Loupedeck Plugin.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updatePlugin()
    --log.df("[Loupedeck Plugin] Checking if we need to update Loupedeck Plugin...")

    --------------------------------------------------------------------------------
    -- Make sure the plugin path actually exists:
    --------------------------------------------------------------------------------
    if not ensureDirectoryExists(LOUPEDECK_SUPPORT_PATH, "Plugins") then
        log.ef("[Loupedeck Plugin] Failed to create folder: %s", LOUPEDECK_SUPPORT_PATH .. "/Plugins/")
        return
    end

    local loupedeckSupportPath               = pathToAbsolute(LOUPEDECK_SUPPORT_PATH)
    local basePath                          = config.basePath
    local embeddedCommandPostPluginPath     = basePath .. "/plugins/core/loupedeckplugin/plugin/CommandPostPlugin"
    local destination                       = loupedeckSupportPath .."/Plugins/" .. DLL_PATH
    local source                            = basePath .. "/plugins/core/loupedeckplugin/plugin/" .. DLL_PATH
    local userCommandPostPluginPath         = loupedeckSupportPath .. "/Plugins/CommandPostPlugin"

    task.new("/usr/bin/diff", function(exitCode, _, _)
        if exitCode == 0 then
            log.df("[Loupedeck Plugin] Latest plugin installed.")
        else
            --log.df("[Loupedeck Plugin] The latest CommandPost Loupedeck Plugin is being installed...")

            --------------------------------------------------------------------------------
            -- Step 1: Remove the existing plugin:
            --------------------------------------------------------------------------------
            log.df("[Loupedeck Plugin] Removing the existing plugin...")
            task.new("/bin/rm", function()
                --------------------------------------------------------------------------------
                -- Step 2: Create a folder for the Plugin:
                --------------------------------------------------------------------------------
                log.df("[Loupedeck Plugin] Making a directory for the CommandPost Plugin...")
                task.new("/bin/mkdir", function(mkDirExitCode, mkDirStdOut, mkDirStdErr)
                    if mkDirExitCode ~= 0 then
                        log.ef("[Loupedeck Plugin] Failed to make the Loupedeck CommandPost Plugin directory:")
                        log.df(" - exitCode: '%s', %s", mkDirExitCode, type(mkDirExitCode))
                        log.df(" - stdOut: '%s', %s", mkDirStdOut, type(mkDirStdOut))
                        log.df(" - stdErr: '%s', %s", mkDirStdErr, type(mkDirStdErr))
                    else
                        --------------------------------------------------------------------------------
                        -- Step 3: Copying the latest plugin:
                        --------------------------------------------------------------------------------
                        log.df("[Loupedeck Plugin] Copying the latest plugin...")
                        task.new("/bin/cp", function(copyExitCode, copyStdOut, copyStdErr)
                            if copyExitCode ~= 0 then
                                log.ef("Failed to copy the Loupedeck CommandPost Plugin:")
                                log.df(" - exitCode: '%s', %s", copyExitCode, type(copyExitCode))
                                log.df(" - stdOut: '%s', %s", copyStdOut, type(copyStdOut))
                                log.df(" - stdErr: '%s', %s", copyStdErr, type(copyStdErr))
                            else
                                log.df("[Loupedeck Plugin] Plugin Copied!")

                                local loupedeckService = application.get(LOUPEDECK_SERVICE_BUNDLE_IDENTIFIER)
                                if loupedeckService then
                                    loupedeckService:kill9()
                                    doAfter(1, function()
                                        launchOrFocusByBundleID(LOUPEDECK_SERVICE_BUNDLE_IDENTIFIER)
                                    end)
                                end

                                local loupedeckConfig = application.get(LOUPEDECK_CONFIG_BUNDLE_IDENTIFIER)
                                if loupedeckConfig then
                                    loupedeckConfig:kill9()
                                    doAfter(1, function()
                                        launchOrFocusByBundleID(LOUPEDECK_CONFIG_BUNDLE_IDENTIFIER)
                                    end)
                                end
                            end
                        end, {"-R", embeddedCommandPostPluginPath .. "/", userCommandPostPluginPath .. "/"}):start() -- Copy Plugin
                    end
                end, {userCommandPostPluginPath}):start() -- Make Directory
            end, {"-R", userCommandPostPluginPath}):start() -- Remove Directory
        end
    end, {source, destination}):start()
end

--- plugins.core.loupedeckplugin.manager.removePlugin() -> boolean
--- Function
--- Removes the Loupedeck Plugin.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Will always return `true`.
function mod.removePlugin()
    log.df("[Loupedeck Plugin] Removing Loupedeck Plugin...")

    local loupedeckSupportPath = pathToAbsolute(LOUPEDECK_SUPPORT_PATH)
    if not loupedeckSupportPath then
        log.ef("[Loupedeck Plugin] Failed to remove plugin, as this directory doesn't exist: %s", LOUPEDECK_SUPPORT_PATH)
    end

    local userCommandPostPluginPath = loupedeckSupportPath .. "/Plugins/CommandPostPlugin"
    local output, ok = os.execute([[/bin/rm -R "]] .. userCommandPostPluginPath .. [["]])
    if not ok then
        log.ef(string.format("[Loupedeck Plugin] Failed to delete plugin '%s': %s", userCommandPostPluginPath, output))
    end

    return true
end

--- plugins.core.loupedeckplugin.manager.setEnabled(enabled) -> none
--- Function
--- Enables or disables Loupedeck Plugin Support.
---
--- Parameters:
---  * enabled - A boolean
---
--- Returns:
---  * `true` if Loupedeck Plugin support is enabled, otherwise `false`
function mod.setEnabled(enabled)
    if enabled then
        local result = mod.installPlugin()
        if result then
            -- Disable other built-in support:
            config.prop("loupedeckct.enabled")(false)
            config.prop("loupedecklive.enabled")(false)
        end
        mod.enabled(result)
    else
        local result = mod.removePlugin()
        mod.enabled(not result)
    end
    return mod.enabled()
end

local plugin = {
    id          = "core.loupedeckplugin.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"] = "actionManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Register favourites:
    --------------------------------------------------------------------------------
    for i=1, mod.NUMBER_OF_FAVOURITES do
        mod.registerAction("CommandPostFavourite" .. string.format("%02d", i), function(data)
            if data.actionType == "press" then
                --------------------------------------------------------------------------------
                -- Knob Pressed:
                --------------------------------------------------------------------------------
                local faves = mod.favourites()
                local fave = faves["press_" .. i]
                if fave then
                    local handler = deps.actionManager.getHandler(fave.handlerID)
                    if handler then
                        if not handler:execute(fave.action) then
                            log.ef("[Loupedeck Plugin] Unable to execute Loupedeck Plugin Favourite #%s: %s", i, fave and inspect(fave))
                        end
                    else
                        log.ef("[Loupedeck Plugin] Unable to find handler to execute Loupedeck Plugin Favourite #%s: %s", i, fave and inspect(fave))
                    end
                else
                    log.ef("[Loupedeck Plugin] No action is assigned to the favourite in the Loupedeck Plugin Panel in CommandPost.")
                    playErrorSound()
                end
            elseif data.actionType == "turn" then
                --------------------------------------------------------------------------------
                -- Knob Turned:
                --------------------------------------------------------------------------------
                if data.actionValue < 0 then
                    local faves = mod.favourites()
                    local fave = faves["left_" .. i]
                    if fave then
                        local handler = deps.actionManager.getHandler(fave.handlerID)
                        if handler then
                            if not handler:execute(fave.action) then
                                log.ef("[Loupedeck Plugin] Unable to execute Loupedeck Plugin Favourite #%s: %s", i, fave and inspect(fave))
                            end
                        else
                            log.ef("[Loupedeck Plugin] Unable to find handler to execute Loupedeck Plugin Favourite #%s: %s", i, fave and inspect(fave))
                        end
                    else
                        log.ef("[Loupedeck Plugin] No action is assigned to the favourite in the Loupedeck Plugin Panel in CommandPost.")
                        playErrorSound()
                    end
                else
                    local faves = mod.favourites()
                    local fave = faves["right_" .. i]
                    if fave then
                        local handler = deps.actionManager.getHandler(fave.handlerID)
                        if handler then
                            if not handler:execute(fave.action) then
                                log.ef("[Loupedeck Plugin] Unable to execute Loupedeck Plugin Favourite #%s: %s", i, fave and inspect(fave))
                            end
                        else
                            log.ef("[Loupedeck Plugin] Unable to find handler to execute Loupedeck Plugin Favourite #%s: %s", i, fave and inspect(fave))
                        end
                    else
                        log.ef("[Loupedeck Plugin] No action is assigned to the favourite in the Loupedeck Plugin Panel in CommandPost.")
                        playErrorSound()
                    end
                end
            else
                log.ef("[Loupedeck Plugin] ERROR: An unexpected actionType was recieved: %s", data and hs.inspect(data))
            end
        end)
    end

    return mod
end

function plugin.postInit()
    mod.enabled:update()
    if mod.enabled() then
        mod.updatePlugin()
    end
end

return plugin
