--- === plugins.core.monogram.manager ===
---
--- Monogram Manager Plugin.

local require                   = require

local log                       = require "hs.logger".new "monogram"

local application               = require "hs.application"
local json                      = require "hs.json"
local timer                     = require "hs.timer"
local udp                       = require "hs.socket.udp"

local config                    = require "cp.config"
local deferred                  = require "cp.deferred"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local doAfter                   = timer.doAfter
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local ensureDirectoryExists     = tools.ensureDirectoryExists
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID

local mod = {}

-- UDP_PORT -> number
-- Constant
-- The port to setup the UDP server on.
local UDP_PORT = 51234

-- MONOGRAM_CREATOR_BUNDLE_ID -> string
-- Constant
-- The Monogram Creator Bundle ID.
local MONOGRAM_CREATOR_BUNDLE_ID = "com.monogramcc.Monogram-Creator-Beta"

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
    application.launchOrFocusByBundleID(MONOGRAM_CREATOR_BUNDLE_ID)
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
                log.df("Copying plugin from Application Bundle to Application Support: %s", pluginName)
                local cmd = [[cp -R "]] ..  sourcePath .. pluginExtension .. [[" "]] .. destinationPath .. pluginExtension .. [["]]
                os.execute(cmd)
            else
                log.df("Monogram plugin already copied: %s", pluginName)
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Check the plugins are enabled in the Monogram Preferences:
    --------------------------------------------------------------------------------
    local homePath = os.getenv("HOME")
    local statePath = homePath .. "/Library/Application Support/Monogram/Service/state.json"
    local pluginsToInstall = {}
    if doesFileExist(statePath) then
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
                    if pluginInstalled then
                        log.df("Monogram Plugin already installed: %s", pluginName)
                    else
                        log.df("Monogram Plugin needs installing: %s", pluginName)
                        table.insert(pluginsToInstall, pluginName)
                    end
                end

                --------------------------------------------------------------------------------
                -- We need to install some plugins:
                --------------------------------------------------------------------------------
                if next(pluginsToInstall) then

                    for _, pluginName in pairs(pluginsToInstall) do
                        log.df("Installing Plugin: %s", pluginName)
                        table.insert(stateData.integrations, destinationPath .. pluginName .. ".palette")
                    end

                    local creator = application.get(MONOGRAM_CREATOR_BUNDLE_ID)

                    local didKill = false
                    if creator then
                        log.df("Killing Monogram Creator...")
                        creator:kill9()
                        didKill = true
                    end

                    log.df("Writing to preferences file...")
                    json.write(stateData, statePath, true, true)

                    if didKill then
                        mod._launcher = doAfter(1, function()
                            log.df("Relaunching Monogram Creator...")
                            mod.launchCreatorBundle()
                        end)
                    end

                end
            end

        end
    end
end

--- plugins.core.monogram.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Monogram Support.
mod.enabled = config.prop("monogram.enabled", false):watch(function(enabled)
    if enabled then
        setupPlugins()
        mod.server = udp.server(51234):receive(callbackFn)
    else
        if mod.server then
            mod.server:close()
            mod.server = nil
        end
    end
end)

local plugin = {
    id          = "core.monogram.manager",
    group       = "core",
    required    = true,
    dependencies    = {
    }
}

function plugin.init(deps, env)
    return mod
end

function plugin.postInit()
    mod.enabled:update()
end

return plugin
