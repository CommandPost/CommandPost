--- === plugins.core.tangent.manager ===
---
--- Tangent Control Surface Manager
---
--- This plugin allows CommandPost to communicate with Tangent's range of
--- panels (Element, Virtual Element Apps, Wave, Ripple and any future panels).
---
--- Download the Tangent Developer Support Pack & Tangent Hub Installer for Mac
--- here: http://www.tangentwave.co.uk/developer-support/

local require                   = require

local log                       = require "hs.logger".new "tangentMan"

local application               = require "hs.application"
local image                     = require "hs.image"
local tangent                   = require "hs.tangent"

local config                    = require "cp.config"
local prop                      = require "cp.prop"

local connection                = require "connection"

local imageFromPath             = image.imageFromPath
local infoForBundleID           = application.infoForBundleID
local isTangentHubInstalled     = tangent.isTangentHubInstalled
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID

local mod = {}

-- TANGENT_MAPPER_BUNDLE_ID -> string
-- Constant
-- Tangent Mapper Bundle ID.
local TANGENT_MAPPER_BUNDLE_ID = "uk.co.tangentwave.tangentmapper"

--- plugins.core.tangent.manager.NUMBER_OF_FAVOURITES -> number
--- Constant
--- Maximum number of favourites.
mod.NUMBER_OF_FAVOURITES = 50

--- plugins.core.tangent.manager.MAXIMUM_CONNECTIONS -> number
--- Constant
--- Maximum number of socket connections to Tangent Hub.
mod.MAXIMUM_CONNECTIONS = 5

--- plugins.core.tangent.manager.customApplications <cp.prop: table>
--- Variable
--- Table of Custom Applications
mod.customApplications = config.prop("tangent.customApplications", {})

--- plugins.core.tangent.manager.connections -> table
--- Variable
--- A table containing all the Tangent connections.
mod.connections = {}

--- plugins.core.tangent.manager.tangentHubInstalled <cp.prop: boolean>
--- Variable
--- Is Tangent Hub Installed?
mod.tangentHubInstalled = prop(function()
    return isTangentHubInstalled()
end)

--- plugins.core.tangent.manager.tangentMapperInstalled <cp.prop: boolean>
--- Variable
--- Is Tangent Mapper Installed?
mod.tangentMapperInstalled = prop(function()
    local info = infoForBundleID(TANGENT_MAPPER_BUNDLE_ID)
    return info ~= nil
end)

--- plugins.core.tangent.manager.launchTangentMapper() -> none
--- Function
--- Launches the Tangent Mapper.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.launchTangentMapper()
    launchOrFocusByBundleID(TANGENT_MAPPER_BUNDLE_ID)
end

--- plugins.core.tangent.manager.enabled <cp.prop: boolean>
--- Variable
--- Enable or disables the Tangent Manager.
mod.enabled = config.prop("enableTangent", false):watch(function(enabled)
    if enabled then
        mod.setupCustomApplications()
        local connections = mod.connections
        for _, c in pairs(connections) do
            c.connected(true)
        end
    else
        local connections = mod.connections
        for _, c in pairs(connections) do
            c.rebuildXML(true)
        end
    end
end)

--- plugins.core.tangent.manager.newConnection(applicationName, systemPath, userPath, task) -> connection
--- Function
--- Creates a new Tangent Connection
---
--- Parameters:
---  * applicationName - The application name as a string. This is what appears in Tangent Mapper.
---  * displayName - The application display name as a string. This is what appears in CommandPost.
---  * systemPath - A string containing the absolute path of the directory that contains the Controls and Default Map XML files.
---  * userPath - An optional string containing the absolute path of the directory that contains the User’s Default Map XML files.
---  * task - An optional string containing the name of the task associated with the application.
---         This is used to assist with automatic switching of panels when your application gains mouse focus on the GUI.
---         This parameter should only be required if the string passed in appStr does not match the Task name that the OS
---         identifies as your application. Typically, this is only usually required for Plugins which run within a parent
---         Host application. Under these circumstances it is the name of the Host Application’s Task which should be passed.
---  * pluginPath - A string containing the absolute path of the directory that contains the built-in Default Map XML files.
---  * setupFn - Setup function.
---  * transportFn - Transport function.
---
--- Returns:
---  * The connection object
function mod.newConnection(applicationName, displayName, systemPath, userPath, task, pluginPath, setupFn, transportFn)
    if not mod.connections[applicationName] then
        local connection = connection:new(applicationName, displayName, systemPath, userPath, task, pluginPath, setupFn, transportFn, mod)
        mod.connections[applicationName] = connection
        return connection
    else
        log.ef("A Tangent connection with the name '%s' is already registered.", applicationName)
    end
end

--- plugins.core.tangent.manager.getConnection(applicationName) -> connection
--- Function
--- Gets a Tangent connection object.
---
--- Parameters:
---  * applicationName - Your application name as a string
---
--- Returns:
---  * The connection object
function mod.getConnection(applicationName)
    return mod.connections[applicationName]
end

--- plugins.core.tangent.manager.displayNames() -> table
--- Function
--- Gets a table listing all the connections application and display names.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table where the application name is the key, and display name is the value.
function mod.displayNames()
    local displayNames = {}
    local connections = mod.connections
    for id, connection in pairs(connections) do
        displayNames[id] = connection:displayName()
    end
    return displayNames
end

--- plugins.core.tangent.manager.registerCustomApplication(displayName, bundleExecutable) -> none
--- Function
--- Registers a new Custom Application
---
--- Parameters:
---  * displayName - The display name of the custom application
---  * bundleExecutable - The bundle executable identifier of the custom application
---
--- Returns:
---  * A table where the application name is the key, and display name is the value.
function mod.registerCustomApplication(displayName, bundleExecutable)
    local customApplications = mod.customApplications()
    customApplications[bundleExecutable] = displayName
    mod.customApplications(customApplications)
    mod.setupCustomApplications()
end

--- plugins.core.tangent.manager.removeCustomApplication(displayName) -> none
--- Function
--- Removes a Custom Application.
---
--- Parameters:
---  * displayName - The display name of the Custom Application to Remove.
---
--- Returns:
---  * None
function mod.removeCustomApplication(displayName)
    local customApplications = mod.customApplications()
    for bundleExecutable, currentDisplayName in pairs(customApplications) do
        if currentDisplayName == displayName then
            local applicationName = displayName .. " (via CommandPost)"

            --------------------------------------------------------------------------------
            -- Disconnecting and removing connection:
            --------------------------------------------------------------------------------
            local connection = mod.connections[applicationName]
            connection.connected(false)
            connection._device = nil
            mod.connections[applicationName] = nil

            --------------------------------------------------------------------------------
            -- Removing Custom Application from Preferences:
            --------------------------------------------------------------------------------
            customApplications[bundleExecutable] = nil
            mod.customApplications(customApplications)
        end
    end
    mod.customApplications(customApplications)
end

--- plugins.core.tangent.manager.setupCustomApplications() -> none
--- Function
--- Setup the Custom Applications.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setupCustomApplications()
    local customApplications = mod.customApplications()
    for bundleExecutable, displayName in pairs(customApplications) do
        local applicationName = displayName .. " (via CommandPost)"
        if not mod.connections[applicationName] then
            local applicationName = displayName .. " (via CommandPost)"
            local systemPath = config.userConfigRootPath .. "/Tangent Settings/" .. bundleExecutable
            local pluginPath = config.basePath .. "/plugins/core/tangent/defaultmap"
            mod.newConnection(applicationName, displayName, systemPath, nil, bundleExecutable, pluginPath)
        else
            log.ef("Custom Application already registered: %s", bundleExecutable)
        end
    end
end

local plugin = {
    id          = "core.tangent.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.commands.global"]    = "global",
        ["core.action.manager"]     = "actionManager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connections:
    --------------------------------------------------------------------------------
    mod.actionManager = deps.actionManager

    --------------------------------------------------------------------------------
    -- Tangent Icon:
    --------------------------------------------------------------------------------
    local tangentIcon = imageFromPath(env:pathToAbsolute("/../prefs/images/tangent.icns"))

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("enableTangent")
        :whenActivated(function()
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :image(tangentIcon)
        :titled("Enable Tangent Panel Support")

    global
        :add("disableTangent")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :image(tangentIcon)
        :titled("Disable Tangent Panel Support")

    global
        :add("toggleTangent")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")
        :image(tangentIcon)
        :titled("Toggle Tangent Panel Support")

    return mod
end

function plugin.postInit()
    mod.enabled:update()
end

return plugin
