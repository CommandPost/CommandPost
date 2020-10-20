--- === cp.config ===
---
--- Manage CommandPost's constants and settings.

local require = require

local hs                  = _G.hs

local application		  = require("hs.application")
local console			  = require("hs.console")
local fs				  = require("hs.fs")
local settings			  = require("hs.settings")
local window			  = require("hs.window")

local prop				  = require("cp.prop")
local sourcewatcher		  = require("cp.sourcewatcher")
local watcher			  = require("cp.watcher")

local mod = {}

--- cp.config.appName -> string
--- Constant
--- The name of the Application
mod.appName = "CommandPost"

--- cp.config.appVersion -> string
--- Constant
--- Application Version
mod.appVersion = hs.processInfo["version"]

--- cp.config.appBuild -> string
--- Constant
--- Application Build
mod.appBuild = hs.processInfo["build"]

--- cp.config.bundleID -> string
--- Constant
--- Application's Bundle ID
mod.bundleID = hs.processInfo["bundleID"]

--- cp.config.processID -> number
--- Constant
--- Application's Process ID
mod.processID = hs.processInfo["processID"]

--- cp.config.configPrefix -> string
--- Constant
--- Prefix used for Configuration Settings
mod.configPrefix = "cp"

--- cp.config.privacyPolicyURL -> string
--- Constant
--- URL for Privacy Policy
mod.privacyPolicyURL = "https://help.commandpost.io/getting_started/privacy_policy/"

--- cp.config.translationURL -> string
--- Constant
--- URL for Translations
mod.translationURL = "https://poeditor.com/join/project/QWvOQlF1Sy"

--- cp.config.scriptPath -> string
--- Constant
--- Path to where Application Scripts are stored
if fs.pathToAbsolute(hs.configdir .. "/cp/init.lua") then
    -------------------------------------------------------------------------------
    -- Use assets in either the Developer or User Library directory:
    -------------------------------------------------------------------------------
    mod.scriptPath			= hs.configdir

    --- cp.config.testsPath -> string
    --- Constant
    --- Path to where the Test scripts are stored. Only available in developer environments.
    mod.testsPath           = fs.pathToAbsolute(mod.scriptPath .. "/../tests")

    -- update cp.spec to use the tests path.
    require "cp.spec" .setSearchPath(mod.testsPath)
else
    -------------------------------------------------------------------------------
    -- Use assets within the Application Bundle:
    -------------------------------------------------------------------------------
    mod.scriptPath			= hs.processInfo["resourcePath"] .. "/extensions"
end

--- cp.config.assetsPath -> string
--- Constant
--- Path to where Application Assets are stored
mod.assetsPath = mod.scriptPath .. "/cp/resources/assets"

--- cp.config.basePath -> string
--- Constant
--- Path to where the Extensions & Plugins folders are stored.
mod.basePath = fs.pathToAbsolute(mod.scriptPath .. "/..")

--- cp.config.bundledPluginsPath -> string
--- Constant
--- The path to bundled plugins
mod.bundledPluginsPath = mod.basePath .. "/plugins"

--- cp.config.userConfigRootPath -> string
--- Constant
--- The path to user configuration folders
mod.userConfigRootPath = os.getenv("HOME") .. "/Library/Application Support/CommandPost"

--- cp.config.cachePath -> string
--- Constant
--- The path to the CommandPost Cache folder.
mod.cachePath = os.getenv("HOME") .. "/Library/Caches/" .. hs.processInfo.bundleID

--- cp.config.userPluginsPath -> string
--- Constant
--- The path to user plugins
mod.userPluginsPath = mod.userConfigRootPath .. "/Plugins"

--- cp.config.pluginPaths -> table
--- Constant
--- Table of Plugins Paths. Earlier entries take precedence.
mod.pluginPaths	= {
    mod.userPluginsPath,
    mod.bundledPluginsPath,
}

--- cp.config.iconPath -> string
--- Constant
--- Path to the Application Icon
mod.iconPath = hs.processInfo["resourcePath"] .. "/AppIcon.icns"

--- cp.config.menubarIconPath -> string
--- Constant
--- Path to the Menubar Application Icon
mod.menubarIconPath = mod.assetsPath .. "/CommandPost.png"

--- cp.config.languagePath -> string
--- Constant
--- Path to the Languages Folder
mod.languagePath = mod.scriptPath .. "/languages/"

--- cp.config.sourceExtensions -> table
--- Constant
--- Extensions for files which will trigger a reload when modified.
mod.sourceExtensions = { ".lua", ".html", ".htm", ".css", ".json" }

--- cp.config.sourceWatcher -> SourceWatcher
--- Constant
--- A `cp.sourcewatcher` that will watch for source files and reload CommandPost if any change.
mod.sourceWatcher = sourcewatcher.new(mod.sourceExtensions)
    :watchPath(mod.scriptPath)
    :watchPath(mod.userPluginsPath)
    :watchPath(mod.bundledPluginsPath)

--- cp.config.application() -> hs.application object
--- Function
--- Returns the Application as a hs.application object
---
--- Parameters:
---  * None
---
--- Returns:
---  * hs.application object
function mod.application()
    if not mod._application then
        mod._application = application.applicationForPID(mod.processID)
    end
    return mod._application
end

--- cp.config.frontmost <cp.prop: boolean; read-only>
--- Field
--- Returns whether or not the Application is frontmost.
mod.frontmost = prop.new(function()
    local app = mod.application()
    local fw = window.focusedWindow()

    return fw ~= nil and fw:application() == app
end)

--- cp.config.get(key[, defaultValue]) -> string or boolean or number or nil or table or binary data
--- Function
--- Loads a setting
---
--- Parameters:
---  * key - A string containing the name of the setting
---  * defaultValue - A default value if the setting doesn't already exist
---
--- Returns:
---  * The value of the setting
function mod.get(key, defaultValue)
    local value = settings.get(mod.configPrefix .. "." .. key)
    if value == nil then
        value = defaultValue
    end
    return value
end

--- cp.config.set(key, value)
--- Function
--- Saves a setting with common datatypes
---
--- Parameters:
---  * `key`		- A string containing the name of the setting
---  * `value`		- An optional value for the setting. Valid datatypes are:
---    * string
---    * number
---    * boolean
---    * nil
---    * table (which may contain any of the same valid datatypes)
---  * if no value is provided, it is assumed to be nil
---
--- Returns:
---  * None
---
--- Notes:
---  * This function cannot set dates or raw data types
function mod.set(key, value)
    if type(key) ~= "string" then
        error("The key must be a string: %s", hs.inspect(key))
    end
    settings.set(mod.configPrefix .. "." .. key, value)
    if mod._propCache then
        local p = mod._propCache[key]
        if p then
            p:update()
        end
    end
end

--- cp.config.prop(key[, defaultValue]) -> cp.prop
--- Function
--- Returns a `cp.prop` instance connected to the value of the specified key. When the value is modified, it will be notified.
---
--- Parameters:
--- * `key`				- The configuration setting key.
--- * `defaultValue`	- The default value if the key has not been set.
---
--- Returns:
--- * A `cp.prop` instance for the key.
function mod.prop(key, defaultValue)
    local propValue = nil
    if not mod._propCache then
        mod._propCache = {}
    else
        propValue = mod._propCache[key]
    end

    if not propValue then
        propValue = prop.new(
            function() return mod.get(key, defaultValue) end,
            function(value) mod.set(key, value) end
        ):deepTable():label("config: "..key)
        mod._propCache[key] = propValue
    end

    return propValue
end

--- cp.config.reset()
--- Function
--- Resets all the settings for the Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.reset()
    for _,v in ipairs(settings.getKeys()) do
        settings.set(v, nil)
    end
    mod.watcher:notify("reset")
    console.clearConsole()
    hs.reload()
end

--- cp.config.watcher() -> watcher
--- Variable
--- Config Watcher
mod.watcher = watcher.new("reset")

--- cp.config.watch(events) -> id
--- Function
--- Watches for config events.
---
--- Parameters:
---  * `events`	- a table containing functions for each event to watch for.
---
--- Returns:
---  * a unique ID that can be used to `unwatch`.
---
--- Notes:
---  * Supported events:
---  ** `reset()`	- occurs after CommandPost's settings are reset.
function mod.watch(events)
    return mod.watcher:watch(events)
end

--- cp.config.unwatch(id)
--- Function
--- Unregisters the watcher with the specified ID.
---
--- Parameters:
---  * `id`		- The ID, originally returned from the `watch` function.
---
--- Returns:
---  * `true` if a watcher with the ID existed and was successfully removed.
function mod.unwatch(id)
    return mod.watcher:unwatch(id)
end

--- cp.config.developerMode <cp.prop: boolean; read-only>
--- Field
--- When `true`, the app is in developer mode.
mod.developerMode = prop.new(function() return settings.get("MJConfigFile") ~= nil end)

--- cp.config.automaticScriptReloading <cp.prop: boolean>
--- Variable
--- Automatic Script Reloading.
mod.automaticScriptReloading = mod.prop("automaticScriptReloading", true):watch(function(value)
    if value then
        mod.sourceWatcher:start()
    else
        mod.sourceWatcher:stop()
    end
end)
mod.automaticScriptReloading:update()

--------------------------------------------------------------------------------
--
-- SHUTDOWN CALLBACK:
--
--------------------------------------------------------------------------------

--- === cp.config.shutdownCallback ===
---
--- Shutdown Callback Module.

local shutdownCallback = {}
shutdownCallback._items = {}

mod.shutdownCallback = shutdownCallback

--- cp.config.shutdownCallback:new(id, callbackFn) -> table
--- Method
--- Creates a new Shutdown Callback.
---
--- Parameters:
--- * `id`		- The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function shutdownCallback:new(id, callbackFn)

    if shutdownCallback._items[id] ~= nil then
        error("Duplicate Shutdown Callback: " .. id)
    end
    local o = {
        _id = id,
        _callbackFn = callbackFn,
    }
    setmetatable(o, self)
    self.__index = self

    shutdownCallback._items[id] = o
    return o

end

--- cp.config.shutdownCallback:get(id) -> table
--- Method
--- Creates a new Shutdown Callback.
---
--- Parameters:
--- * `id`		- The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function shutdownCallback:get(id)
    return self._items[id]
end

--- cp.config.shutdownCallback:getAll() -> table
--- Method
--- Returns all of the created Shutdown Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function shutdownCallback:getAll()
    return self._items
end

--- cp.config.shutdownCallback:id() -> string
--- Method
--- Returns the ID of the current Shutdown Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current Shutdown Callback as a `string`
function shutdownCallback:id()
    return self._id
end

--- cp.config.shutdownCallback:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current Shutdown Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function shutdownCallback:callbackFn()
    return self._callbackFn
end

--------------------------------------------------------------------------------
--
-- TEXT DROPPED TO DOCK ICON CALLBACK:
--
--------------------------------------------------------------------------------

--- === cp.config.textDroppedToDockIconCallback ===
---
--- Text Dropped to Dock Icon Callback

local textDroppedToDockIconCallback = {}
textDroppedToDockIconCallback._items = {}

mod.textDroppedToDockIconCallback = textDroppedToDockIconCallback

--- cp.config.textDroppedToDockIconCallback:new(id, callbackFn) -> table
--- Method
--- Creates a new Text Dropped to Dock Icon Callback.
---
--- Parameters:
--- * `id`		- The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function textDroppedToDockIconCallback:new(id, callbackFn)

    if textDroppedToDockIconCallback._items[id] ~= nil then
        error("Duplicate Text Dropped to Dock Icon Callback: " .. id)
    end
    local o = {
        _id = id,
        _callbackFn = callbackFn,
    }
    setmetatable(o, self)
    self.__index = self

    textDroppedToDockIconCallback._items[id] = o
    return o

end

--- cp.config.textDroppedToDockIconCallback:get(id) -> table
--- Method
--- Creates a new Text Dropped to Dock Icon Callback.
---
--- Parameters:
--- * `id`		- The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function textDroppedToDockIconCallback:get(id)
    return self._items[id]
end

--- cp.config.textDroppedToDockIconCallback:getAll() -> table
--- Method
--- Returns all of the created Text Dropped to Dock Icon Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function textDroppedToDockIconCallback:getAll()
    return self._items
end

--- cp.config.textDroppedToDockIconCallback:id() -> string
--- Method
--- Returns the ID of the current Text Dropped to Dock Icon Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current Shutdown Callback as a `string`
function textDroppedToDockIconCallback:id()
    return self._id
end

--- cp.config.textDroppedToDockIconCallback:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current Text Dropped to Dock Icon Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function textDroppedToDockIconCallback:callbackFn()
    return self._callbackFn
end

--------------------------------------------------------------------------------
--
-- FILE DROPPED TO DOCK ICON CALLBACK:
--
--------------------------------------------------------------------------------

--- === cp.config.fileDroppedToDockIconCallback ===
---
--- File Dropped to Dock Icon Callback

local fileDroppedToDockIconCallback = {}
fileDroppedToDockIconCallback._items = {}

mod.fileDroppedToDockIconCallback = fileDroppedToDockIconCallback

--- cp.config.fileDroppedToDockIconCallback:new(id, callbackFn) -> table
--- Method
--- Creates a new File Dropped to Dock Icon Callback.
---
--- Parameters:
--- * `id`		- The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function fileDroppedToDockIconCallback:new(id, callbackFn)

    if fileDroppedToDockIconCallback._items[id] ~= nil then
        error("Duplicate File Dropped to Dock Icon Callback: " .. id)
    end
    local o = {
        _id = id,
        _callbackFn = callbackFn,
    }
    setmetatable(o, self)
    self.__index = self

    fileDroppedToDockIconCallback._items[id] = o
    return o

end

--- cp.config.fileDroppedToDockIconCallback:get(id) -> table
--- Method
--- Creates a new File Dropped to Dock Icon Callback.
---
--- Parameters:
--- * `id`		- The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function fileDroppedToDockIconCallback:get(id)
    return self._items[id]
end

--- cp.config.fileDroppedToDockIconCallback:getAll() -> table
--- Method
--- Returns all of the created File Dropped to Dock Icon Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function fileDroppedToDockIconCallback:getAll()
    return self._items
end

--- cp.config.fileDroppedToDockIconCallback:id() -> string
--- Method
--- Returns the ID of the current Text Dropped to Dock Icon Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current File Dropped to Dock Icon Callback as a `string`
function fileDroppedToDockIconCallback:id()
    return self._id
end

--- cp.config.fileDroppedToDockIconCallback:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current File Dropped to Dock Icon Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function fileDroppedToDockIconCallback:callbackFn()
    return self._callbackFn
end

--------------------------------------------------------------------------------
--
-- DOCK ICON CLICKED CALLBACK:
--
--------------------------------------------------------------------------------

--- === cp.config.dockIconClickCallback ===
---
--- Callback which triggers when the CommandPost Dock Icon is clicked

local dockIconClickCallback = {}
dockIconClickCallback._items = {}

mod.dockIconClickCallback = dockIconClickCallback

--- cp.config.dockIconClickCallback:new(id, callbackFn) -> table
--- Method
--- Creates a new File Dropped to Dock Icon Callback.
---
--- Parameters:
--- * `id`		- The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function dockIconClickCallback:new(id, callbackFn)

    if dockIconClickCallback._items[id] ~= nil then
        error("Duplicate Dock Icon Click Callback: " .. id)
    end
    local o = {
        _id = id,
        _callbackFn = callbackFn,
    }
    setmetatable(o, self)
    self.__index = self

    dockIconClickCallback._items[id] = o
    return o

end

--- cp.config.dockIconClickCallback:get(id) -> table
--- Method
--- Creates a new Dock Icon Click Callback.
---
--- Parameters:
--- * `id`		- The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function dockIconClickCallback:get(id)
    return self._items[id]
end

--- cp.config.dockIconClickCallback:getAll() -> table
--- Method
--- Returns all of the created Dock Icon Click Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function dockIconClickCallback:getAll()
    return self._items
end

--- cp.config.dockIconClickCallback:id() -> string
--- Method
--- Returns the ID of the current Dock Icon Click Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current File Dropped to Dock Icon Callback as a `string`
function dockIconClickCallback:id()
    return self._id
end

--- cp.config.dockIconClickCallback:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current Dock Icon Click Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function dockIconClickCallback:callbackFn()
    return self._callbackFn
end

return mod
