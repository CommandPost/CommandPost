--- === plugins.core.monogram.manager ===
---
--- Monogram Manager Plugin.

local require                   = require

local log                       = require "hs.logger".new "monogram"

local application               = require "hs.application"
local inspect                   = require "hs.inspect"
local timer                     = require "hs.timer"
local udp                       = require "hs.socket.udp"

local config                    = require "cp.config"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local doAfter                   = timer.doAfter
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local ensureDirectoryExists     = tools.ensureDirectoryExists
local execute                   = _G.hs.execute
local infoForBundleID           = application.infoForBundleID
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local playErrorSound            = tools.playErrorSound

local mod = {}

-- UDP_PORT -> number
-- Constant
-- The port to setup the UDP server on.
local UDP_PORT = 51234

-- MONOGRAM_CREATOR_BUNDLE_ID -> string
-- Constant
-- The Monogram Creator Bundle ID.
local MONOGRAM_CREATOR_BUNDLE_ID = "com.monogramcc.Monogram-Creator"

-- MONOGRAM_CREATOR_DOWNLOAD_URL -> string
-- Constant
-- The Monogram Creator Download URL.
local MONOGRAM_CREATOR_DOWNLOAD_URL = "https://monogramcc.com/download"

--- plugins.core.monogram.manager.NUMBER_OF_FAVOURITES -> number
--- Constant
--- Number of favourites
mod.NUMBER_OF_FAVOURITES = 20

--- plugins.core.monogram.manager.favourites <cp.prop: table>
--- Variable
--- A `cp.prop` that that contains all the Monogram Favourites.
mod.favourites = json.prop(os.getenv("HOME") .. "/Library/Application Support/CommandPost/", "Monogram", "Favourites.cpMonogram", {})

-- getMonogramCreatorBundleID() -> string
-- Function
-- Returns the Monogram Creator Bundle ID. It first tries to find a running version
-- of Monogram Creator, and if none is running then checks for installations of the
-- Internal release, then Alpha, then Beta, then public release.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The bundle ID as a string, or `nil` if Monogram Creator is not installed.
local function getMonogramCreatorBundleID()
    if application.get(MONOGRAM_CREATOR_BUNDLE_ID .. "-Internal") then
        return MONOGRAM_CREATOR_BUNDLE_ID .. "-Internal"
    elseif application.get(MONOGRAM_CREATOR_BUNDLE_ID .. "-Alpha") then
        return MONOGRAM_CREATOR_BUNDLE_ID .. "-Alpha"
    elseif application.get(MONOGRAM_CREATOR_BUNDLE_ID .. "-Beta") then
        return MONOGRAM_CREATOR_BUNDLE_ID .. "-Beta"
    elseif application.get(MONOGRAM_CREATOR_BUNDLE_ID) then
        return MONOGRAM_CREATOR_BUNDLE_ID
    elseif infoForBundleID(MONOGRAM_CREATOR_BUNDLE_ID .. "-Internal") then
        return MONOGRAM_CREATOR_BUNDLE_ID .. "-Internal"
    elseif infoForBundleID(MONOGRAM_CREATOR_BUNDLE_ID .. "-Alpha") then
        return MONOGRAM_CREATOR_BUNDLE_ID .. "-Alpha"
    elseif infoForBundleID(MONOGRAM_CREATOR_BUNDLE_ID .. "-Beta") then
        return MONOGRAM_CREATOR_BUNDLE_ID .. "-Beta"
    elseif infoForBundleID(MONOGRAM_CREATOR_BUNDLE_ID) then
        return MONOGRAM_CREATOR_BUNDLE_ID
    end
end

--- plugins.core.monogram.manager.performAction -> table
--- Variable
--- A table of actions that are triggered by the callback function.
mod.performAction = {}

--- plugins.core.monogram.manager.plugins -> table
--- Variable
--- A table of Monogram plugins to install.
mod.plugins = {}

--- plugins.core.monogram.manager.registerPlugin(name, path) -> none
--- Function
--- Registers a new Monogram plugin.
---
--- Parameters:
---  * name - The name of the plugin.
---  * path - The path to the folder containing the plugin.
---
--- Returns:
---  * None
function mod.registerPlugin(name, path)
    mod.plugins[name] = path
end

--- plugins.core.monogram.manager.registerAction(name, fn) -> none
--- Function
--- Registers a new Monogram Action.
---
--- Parameters:
---  * name - The name of the plugin.
---  * fn - The function to trigger.
---
--- Returns:
---  * None
function mod.registerAction(name, fn)
    mod.performAction[name] = fn
end

-- callbackFn(data) -> none
-- Function
-- The callback function triggered by the UDP socket.
--
-- Parameters:
--  * data - The data read from the socket as a string
--
-- Returns:
--  * None
local function callbackFn(data)
    if data then
        local decodedData = json.decode(data)
        --print(string.format("decodedData: %s", hs.inspect(decodedData)))
        local action = mod.performAction[decodedData.input]
        if action then
            action(decodedData)
        else
            log.ef("Unknown Monogram Action: %s", decodedData.input)
        end
    end
end

--- plugins.core.monogram.manager.launchCreatorBundle() -> none
--- Function
--- Launch the Monogram Creator.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.launchCreatorBundle()
    local bundleID = getMonogramCreatorBundleID()
    if bundleID then
        launchOrFocusByBundleID(bundleID)
    end
end


--- plugins.core.monogram.manager.launchCreatorBundle() -> none
--- Function
--- Launch the Monogram Creator.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.openDownloadMonogramCreatorURL()
    execute("open " .. MONOGRAM_CREATOR_DOWNLOAD_URL)
end

-- setupPlugin()
-- Function
-- Copies Monogram Plugins from CommandPost application bundle to
-- the Application Support folder, then adds the paths to Monogram
-- Creator's preferences file.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function setupPlugins()
    --------------------------------------------------------------------------------
    -- List of Monogram Plugins:
    --------------------------------------------------------------------------------
    local plugins = mod.plugins

    --------------------------------------------------------------------------------
    -- Copy Monogram Plugins to Application Support Folder:
    --------------------------------------------------------------------------------
    local userConfigRootPath = config.userConfigRootPath
    local destinationPath = userConfigRootPath .. "/Monogram/Plugins/"
    if ensureDirectoryExists(userConfigRootPath, "Monogram", "Plugins") then
        for pluginName, sourcePath in pairs(plugins) do
            local pluginExtension = pluginName .. ".palette"
            if not doesDirectoryExist(destinationPath .. pluginExtension) then
                local cmd = [[cp -R "]] ..  sourcePath .. pluginExtension .. [[" "]] .. destinationPath .. pluginExtension .. [["]]
                local _, status = os.execute(cmd)
                if not status then
                    log.ef("Failed to execute: %s", cmd)
                    return false
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Check the plugins are enabled in the Monogram Preferences:
    --------------------------------------------------------------------------------
    local homePath = os.getenv("HOME")
    local statePath = homePath .. "/Library/Application Support/Monogram/Service/state.json"
    local pluginsToInstall = {}
    if not doesFileExist(statePath) then
        log.ef("The Monogram State file could not be found. Is Monogram Creator Installed?")
        return false
    else
        local stateData = json.read(statePath)
        if stateData then
            local integrations = stateData.integrations
            if integrations then
                for pluginName, _ in pairs(plugins) do
                    local pluginInstalled = false
                    for _, path in pairs(integrations) do
                        if path == destinationPath .. pluginName .. ".palette" then
                            pluginInstalled = true
                        end
                    end
                    if not pluginInstalled then
                        table.insert(pluginsToInstall, pluginName)
                    end
                end

                --------------------------------------------------------------------------------
                -- We need to install some plugins:
                --------------------------------------------------------------------------------
                if next(pluginsToInstall) then
                    for _, pluginName in pairs(pluginsToInstall) do
                        table.insert(stateData.integrations, destinationPath .. pluginName .. ".palette")
                    end

                    local bundleID = getMonogramCreatorBundleID()
                    local creator = application.get(bundleID)

                    local didKill = false
                    if creator then
                        creator:kill9()
                        didKill = true
                    end

                    json.write(statePath, stateData)

                    if didKill then
                        mod._launcher = doAfter(1, function()
                            mod.launchCreatorBundle()
                        end)
                    end
                end
            end
        end
    end
    return true
end

-- removePlugins()
-- Function
-- Deletes Monogram Plugins.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function removePlugins()
    --------------------------------------------------------------------------------
    -- List of Monogram Plugins:
    --------------------------------------------------------------------------------
    local plugins = mod.plugins

    --------------------------------------------------------------------------------
    -- Remove the Monogram Plugins from the Application Support Folder:
    --------------------------------------------------------------------------------
    local userConfigRootPath = config.userConfigRootPath
    local destinationPath = userConfigRootPath .. "/Monogram/Plugins/"
    local cmd = [[rm -rf "]] .. destinationPath .. [["]]
    local _, status = execute(cmd)
    if not status then
        log.ef("Failed to remove Monogram Plugin Folder")
        return false
    end

    --------------------------------------------------------------------------------
    -- Remove plugins from Monogram Preferences:
    --------------------------------------------------------------------------------
    local homePath = os.getenv("HOME")
    local statePath = homePath .. "/Library/Application Support/Monogram/Service/state.json"
    if not doesFileExist(statePath) then
        log.ef("The Monogram State file could not be found. Is Monogram Creator Installed?")
        return false
    else
        local stateData = json.read(statePath)
        if stateData then
            local integrations = stateData.integrations
            if integrations then
                local intergrationsToKeep = {}
                for _, path in pairs(integrations) do
                    local needsRemoving = false
                    for pluginName, _ in pairs(plugins) do
                        if path == destinationPath .. pluginName .. ".palette" then
                            needsRemoving = true
                        end
                    end
                    if not needsRemoving then
                        table.insert(intergrationsToKeep, path)
                    end
                end

                --------------------------------------------------------------------------------
                -- Update Monogram Preferences:
                --------------------------------------------------------------------------------
                stateData.integrations = intergrationsToKeep

                local bundleID = getMonogramCreatorBundleID()
                local creator = application.get(bundleID)

                local didKill = false
                if creator then
                    creator:kill9()
                    didKill = true
                end

                json.write(statePath, stateData)

                if didKill then
                    mod._launcher = doAfter(1, function()
                        mod.launchCreatorBundle()
                    end)
                end
            end
        end
    end

    return true
end

--- plugins.core.monogram.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Monogram Support.
mod.enabled = config.prop("monogram.enabled", false):watch(function(enabled)
    if enabled then
        mod.server = udp.server(UDP_PORT):receive(callbackFn)
    else
        if mod.server then
            mod.server:close()
            mod.server = nil
        end
    end
end)

--- plugins.core.monogram.manager.setEnabled() -> none
--- Function
--- Enables or disables Monogram Support.
---
--- Parameters:
---  * enabled - A boolean
---
--- Returns:
---  * `true` if Monogram support is enabled, otherwise `false`
function mod.setEnabled(enabled)
    if enabled then
        if setupPlugins() then
            mod.enabled(true)
        else
            log.ef("Failed to install Monogram Plugins.")
        end
    else
        if removePlugins() then
            mod.enabled(false)
        else
            log.ef("Failed to remove Monogram Plugins.")
        end
    end
    return mod.enabled()
end

local plugin = {
    id          = "core.monogram.manager",
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
        mod.registerAction("CommandPost Favourites.Favourite " .. i, function()
            local faves = mod.favourites()
            local fave = faves[tostring(i)]
            if fave then
                local handler = deps.actionManager.getHandler(fave.handlerID)
                if handler then
                    if not handler:execute(fave.action) then
                        log.ef("Unable to execute Monogram Favourite #%s: %s", i, inspect(fave))
                    end
                else
                    log.ef("Unable to find handler to execute Monogram Favourite #%s: %s", i, inspect(fave))
                end
            else
                log.ef("No action is assigned to the favourite in the Monogram Control Surfaces Panel in CommandPost.")
                playErrorSound()
            end
        end)
    end

    return mod
end

function plugin.postInit()
    mod.enabled:update()
end

return plugin
