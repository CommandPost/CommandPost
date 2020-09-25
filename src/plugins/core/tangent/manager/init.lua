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
local tangent                   = require "hs.tangent"

local config                    = require "cp.config"
local prop                      = require "cp.prop"

local connection                = require "connection"

local infoForBundleID           = application.infoForBundleID
local isTangentHubInstalled     = tangent.isTangentHubInstalled
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID

local mod = {}

-- TANGENT_MAPPER_BUNDLE_ID -> string
-- Constant
-- Tangent Mapper Bundle ID.
local TANGENT_MAPPER_BUNDLE_ID = "uk.co.tangentwave.tangentmapper"

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
        local connections = mod.connections
        for _, c in pairs(connections) do
            c.connected(true)
        end
    else
        log.df("tangent support is disabled so rebuild xml when next enabled")
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
---  * applicationName - Your application name as a string
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
function mod.newConnection(applicationName, systemPath, userPath, task, pluginPath, setupFn, transportFn)
    if not mod.connections[applicationName] then
        local connection = connection:new(applicationName, systemPath, userPath, task, pluginPath, setupFn, transportFn, mod)
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

local plugin = {
    id          = "core.tangent.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.commands.global"]            = "global",
    }
}
function plugin.init(deps)
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
        :image(tourBoxIcon)
        :titled("Enable Tangent Panel Support")

    global
        :add("disableTangent")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled("Disable Tangent Panel Support")

    global
        :add("toggleTourBox")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled("Toggle Tangent Panel Support")

    return mod
end

function plugin.postInit()
    mod.enabled:update()
end

return plugin
