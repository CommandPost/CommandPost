--- === plugins.core.tangent.manager.connection ===
---
--- Represents a Tangent Connection.

local require = require

local log                   = require "hs.logger".new "connection"

local hs                    = _G.hs

local fs                    = require "hs.fs"
local inspect               = require "hs.inspect"
local tangent               = require "hs.tangent"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local i18n                  = require "cp.i18n"
local is                    = require "cp.is"
local json                  = require "cp.json"
local prop                  = require "cp.prop"
local tools                 = require "cp.tools"
local x                     = require "cp.web.xml"

local class                 = require "middleclass"

local action                = require "action"
local controls              = require "controls"
local menu                  = require "menu"
local mode                  = require "mode"
local parameter             = require "parameter"

local doAfter               = timer.doAfter
local doesDirectoryExist    = tools.doesDirectoryExist
local execute               = hs.execute
local format                = string.format
local insert                = table.insert
local sort                  = table.sort

local connection = class "core.tangent.manager.Connection"

-- FAVOURITE_START_ID -> number
-- Constant
-- The starting ID for Favourites.
local FAVOURITE_START_ID = 0x0ACF0000

--- plugins.core.tangent.manager.connection:setupTangentConnection() -> hs.tangent
--- Method
--- Sets up a new Tangent Connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs.tangent` object.
function connection:setupTangentConnection()
    local t = tangent.new()

    --------------------------------------------------------------------------------
    -- Error logger:
    --------------------------------------------------------------------------------
    t:handleError(function(data)
        log.ef("Error while processing Tangent Message: '%#010x':\n%s", data.id, data)
    end)

    --------------------------------------------------------------------------------
    -- Setup handlers:
    --------------------------------------------------------------------------------
    local fromHub = {
        [tangent.fromHub.initiateComms] = function(metadata)
            --------------------------------------------------------------------------------
            -- InitiateComms:
            --------------------------------------------------------------------------------
            --[[
            log.df("InitiateComms Received:")
            log.df("    Protocol Revision: %s", metadata.protocolRev)
            log.df("    Number of Panels: %s", metadata.numberOfPanels)
            for _, v in pairs(metadata.panels) do
                log.df("        Panel Type: %s (%s)", v.panelType, string.format("%#010x", v.panelID))
            end
            --]]

            --------------------------------------------------------------------------------
            -- Display CommandPost Version on Tangent Screen:
            --------------------------------------------------------------------------------
            doAfter(1, function()
                local version = tostring(config.appVersion)
                self:device():sendDisplayText({"CommandPost "..version})
            end)

            --------------------------------------------------------------------------------
            -- Update Mode:
            --------------------------------------------------------------------------------
            self:update()
        end,

        [tangent.fromHub.actionOn] = function(metadata)
            local control = self.controls:findByID(metadata.actionID)
            if action.is(control) then
                control:press()
            end
        end,

        [tangent.fromHub.actionOff] = function(metadata)
            local control = self.controls:findByID(metadata.actionID)
            if action.is(control) then
                control:release()
            end
        end,

        [tangent.fromHub.parameterChange] = function(metadata)
            local control = self.controls:findByID(metadata.paramID)
            if parameter.is(control) then
                local newValue = control:change(metadata.increment)
                if newValue == nil then
                    newValue = control:get()
                end
                if is.number(newValue) then
                    self:device():sendParameterValue(control.id, newValue)
                end
            end
        end,

        [tangent.fromHub.parameterReset] = function(metadata)
            local control = self.controls:findByID(metadata.paramID)
            if parameter.is(control) then
                local newValue = control:reset()
                if newValue == nil then
                    newValue = control:get()
                end
                if is.number(newValue) then
                    self:device():sendParameterValue(control.id, newValue)
                end
            end
        end,

        [tangent.fromHub.parameterValueRequest] = function(metadata)
            local control = self.controls:findByID(metadata.paramID)
            if parameter.is(control) then
                local value = control:get()
                if is.number(value) then
                    self:device():sendParameterValue(control.id, value)
                end
            end
        end,

        [tangent.fromHub.transport] = function()
            local transportFn = self._transportFn
            if type(transportFn) == "function" then
                transportFn()
            end
        end,

        [tangent.fromHub.menuChange] = function(metadata)
            local control = self.controls:findByID(metadata.menuID)
            local increment = metadata.increment
            if menu.is(control) then
                if increment == 1 then
                    control:next()
                else
                    control:prev()
                end
                local value = control:get()
                if value ~= nil then
                    self:device():sendMenuString(control.id, value)
                end
            end
        end,

        [tangent.fromHub.menuReset] = function(metadata)
            local control = self.controls:findByID(metadata.menuID)
            if menu.is(control) then
                control:reset()
                local value = control:get()
                if value ~= nil then
                    self:device():sendMenuString(control.id, value)
                end
            end
        end,

        [tangent.fromHub.menuStringRequest] = function(metadata)
            local control = self.controls:findByID(metadata.menuID)
            if menu.is(control) then
                local value = control:get()
                if value ~= nil then
                    self:device():sendMenuString(control.id, value)
                end
            end
        end,

        [tangent.fromHub.modeChange] = function(metadata)
            local newMode = self:getMode(metadata.modeID)
            if newMode then
                self.activeMode(newMode)
            end
        end,

        [tangent.fromHub.connected] = function(metadata)
            log.df("Connection to Tangent Hub (%s:%s) successfully established for %s.", metadata.ipAddress, metadata.port, self:displayName())
            self._connectionConfirmed = true
            self.connected:update()
        end,

        [tangent.fromHub.disconnected] = function(metadata)
            log.df("Connection to Tangent Hub (%s:%s) closed for %s.", metadata.ipAddress, metadata.port, self:displayName())
            self._connectionConfirmed = false
            self.connected:update()
        end,
    }

    --------------------------------------------------------------------------------
    -- Register the handlers:
    --------------------------------------------------------------------------------
    for id,fn in pairs(fromHub) do
        t:handle(id, fn)
    end

    return t
end

--- plugins.core.tangent.manager.connection:updateFavourites() -> boolean, string
--- Method
--- Updates the Favourites.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function connection:updateFavourites()
    --------------------------------------------------------------------------------
    -- Reset the Favourites Group:
    --------------------------------------------------------------------------------
    local group = self.favouritesGroup
    group:reset()

    --------------------------------------------------------------------------------
    -- Re-populate the favourites:
    --------------------------------------------------------------------------------
    local faves = self.favourites()
    local max = self.manager.NUMBER_OF_FAVOURITES
    local id = FAVOURITE_START_ID
    for i = 1, max do
        local fave = faves[tostring(i)]
        if fave then
            local actionId = id + i
            group
                :action(actionId)
                :name(fave.actionTitle)
                :onPress(function()
                    local handler = mod.manager.actionManager.getHandler(fave.handlerID)
                    if handler then
                        if not handler:execute(fave.action) then
                            log.wf("Unable to execute Tangent Favourite #%s: %s", i, inspect(fave))
                        end
                    else
                        log.wf("Unable to find handler to execute Tangent Favourite #%s: %s", i, inspect(fave))
                    end
                end)
        end
    end
end

--- plugins.core.tangent.manager.connection:writeControlsXML() -> boolean, string
--- Method
--- Writes the Tangent controls.xml File to the User's Application Support folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successfully created otherwise `false` if an error occurred.
---  * If an error occurs an error message will also be returned as a string.
function connection:writeControlsXML()
    log.df("Writing Tangent Control XML for %s", self:displayName())

    --------------------------------------------------------------------------------
    -- Update Favourites:
    --------------------------------------------------------------------------------
    self:updateFavourites()

    local systemPath = self:systemPath()
    local pluginPath = self:pluginPath()

    --------------------------------------------------------------------------------
    -- Create folder if it doesn't exist:
    --------------------------------------------------------------------------------
    if not doesDirectoryExist(systemPath) then
        --log.df("Tangent Settings folder did not exist, so creating one.")
        fs.mkdir(systemPath)
    end

    --------------------------------------------------------------------------------
    -- Copy existing XML files from Application Bundle to local Application Support:
    --------------------------------------------------------------------------------
    local _, status = execute(format("cp -a %q/. %q/", pluginPath, systemPath))
    if not status then
        log.ef("Failed to copy XML files.")
        return false, "Failed to copy XML files."
    end

    --------------------------------------------------------------------------------
    -- Create "controls.xml" file:
    --------------------------------------------------------------------------------
    local controlsFile = io.open(systemPath .. "/controls.xml", "w")
    if controlsFile then
        --------------------------------------------------------------------------------
        -- Write to File & Close:
        --------------------------------------------------------------------------------
        local controlXML = self:getControlsXML()
        io.output(controlsFile)
        io.write(tostring(controlXML))
        io.close(controlsFile)
    else
        log.ef("Failed to open controls.xml file in write mode")
        return false, "Failed to open controls.xml file in write mode"
    end
end

--- plugins.core.tangent.manager.connection:getControlsXML() -> string
--- Method
--- Gets the controls XML.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The XML controls
function connection:getControlsXML()
    if not self._controlsXML then
        self._controlsXML = x._xml() .. x.TangentWave {fileType = "ControlSystem", fileVersion="3.0"} (
            --------------------------------------------------------------------------------
            -- Capabilities:
            --------------------------------------------------------------------------------
            x.Capabilities (
                x.Jog { enabled = true } ..
                x.Shuttle { enabled = false } ..
                x.StatusDisplay { lineCount = 3 }
            ) ..

            --------------------------------------------------------------------------------
            -- Default Global Settings:
            --------------------------------------------------------------------------------
            x.DefaultGlobalSettings (
                x.KnobSensitivity { std = 3, alt = 5 } ..
                x.JogDialSensitivity { std = 1, alt = 5 } ..
                x.TrackerballSensitivity { std = 1, alt = 5 } ..
                x.TrackerballDialSensitivity { std = 1, alt = 5 } ..
                x.IndependentPanelBanks { enabled = false }
            ) ..

            --------------------------------------------------------------------------------
            -- Modes:
            --------------------------------------------------------------------------------
            x.Modes (function()
                local modes = x()

                for _,m in ipairs(self._modes) do
                    modes = modes .. m:xml()
                end

                return modes
            end) ..

            self.controls:xml()

        )
    end
    return self._controlsXML
end

--- plugins.core.tangent.manager.connection:systemPath() -> string | nil
--- Method
--- Gets the system path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The system path as a string.
function connection:systemPath()
    return self._systemPath
end

--- plugins.core.tangent.manager.connection:applicationName() -> string | nil
--- Method
--- Gets the application name.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application name as a string.
function connection:applicationName()
    return self._applicationName
end

--- plugins.core.tangent.manager.connection:userPath() -> string | nil
--- Method
--- Gets the user path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The user path as a string.
function connection:userPath()
    return self._userPath
end

--- plugins.core.tangent.manager.connection:task() -> string | nil
--- Method
--- Gets the task.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The task as a string.
function connection:task()
    return self._task
end

--- plugins.core.tangent.manager.connection:pluginPath() -> string | nil
--- Method
--- Gets the plugin path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The plugin path as a string.
function connection:pluginPath()
    return self._pluginPath
end

--- plugins.core.tangent.manager.connection:addMode(id, name) -> plugins.core.tangent.manager.mode
--- Method
--- Adds a new `mode` with the specified details and returns it.
---
--- Parameters:
---  * id            - The id number of the Mode.
---  * name          - The name of the Mode.
---
--- Returns:
---  * The new `mode`
function connection:addMode(id, name)
    local m = mode(id, name, self)
    insert(self._modes, m)
    sort(self._modes, function(a,b) return a.id < b.id end)
    return m
end

--- plugins.core.tangent.manager.connection:getMode(id) -> plugins.core.tangent.manager.mode
--- Method
--- Returns the `mode` with the specified ID, or `nil`.
---
--- Parameters:
---  * id    - The ID to find.
---
--- Returns:
---  * The `mode`, or `nil`.
function connection:getMode(id)
    for _,m in ipairs(self._modes) do
        if m.id == id then
            return m
        end
    end
    return nil
end

--- plugins.core.tangent.manager.connection:updateControls() -> none
--- Method
--- Update Controls.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function connection:updateControls()
    --------------------------------------------------------------------------------
    -- We need to rewrite the Controls XML:
    --------------------------------------------------------------------------------
    self._controlsXML = nil
    self:writeControlsXML()

    --------------------------------------------------------------------------------
    -- Force a disconnection:
    --------------------------------------------------------------------------------
    if self.connected() then
        self.connected(false)
    end
end

--- plugins.core.tangent.manager.connection(bundleID, manager)
--- Constructor
--- Creates a new `Mode` instance.
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
---  * manager - The Tangent Manager module
---
--- Returns:
---  *
function connection:initialize(applicationName, displayName, systemPath, userPath, task, pluginPath, setupFn, transportFn, manager)
    self._applicationName       = applicationName
    self._displayName           = displayName
    self._systemPath            = systemPath
    self._userPath              = userPath
    self._task                  = task
    self._pluginPath            = pluginPath

    self.transportFn            = transportFn

    self.manager                = manager

    self.controls               = controls(self)

    self._modes                 = {}
    self._connectionConfirmed   = false

    self._device                = self:setupTangentConnection()

    --- plugins.core.tangent.manager.connection.activeModeID <cp.prop: string>
    --- Field
    --- The current active mode ID.
    self.activeModeID = config.prop("tangent.activeMode." .. applicationName)

    --- plugins.core.tangent.manager.connection.enabled <cp.prop: boolean>
    --- Field
    --- Whether or not the connection is enabled or disabled.
    self.enabled = config.prop("tangent.enabled." .. applicationName, true)

    --- plugins.core.tangent.manager.connection.commandPostGroup -> Group
    --- Field
    --- CommandPost Group
    self.commandPostGroup = self.controls:group(i18n("appName"))

    --- plugins.core.tangent.manager.connection.favouritesGroup -> Group
    --- Field
    --- Favourites Group
    self.favouritesGroup = self.commandPostGroup:group(i18n("favourites"))

    --- plugins.core.tangent.manager.connection.activeMode <cp.prop: mode>
    --- Constant
    --- Represents the currently active `mode`.
    self.activeMode = self.activeModeID:mutate(
        function(original)
            local id = original()
            return id and self:getMode(id)
        end,
        function(newMode, original)
            local m = mode.is(newMode) and newMode or self:getMode(newMode)
            if m then
                local oldMode = self._activeMode
                if oldMode and oldMode._deactivate then
                    oldMode._deactivate()
                end
                self._activeMode = m
                if m._activate then
                    m._activate()
                end
                self:device():sendModeValue(newMode.id)
                original(newMode.id)
            else
                error("Expected a `mode` or a valid mode `ID`: %s", inspect(newMode))
            end
        end
    )

    local homePath = os.getenv("HOME")
    local favouritesPath = homePath .. "/Library/Application Support/CommandPost/Tangent Settings"

    --- plugins.core.tangent.manager.connection.favourites <cp.prop: table>
    --- Variable
    --- A `cp.prop` that that contains all the Tangent Favourites for the connection.
    self.favourites = json.prop(favouritesPath, displayName, displayName .. ".cpTangent", {})

    --- plugins.core.tangent.manager.connection.rebuildXML <cp.prop: boolean>
    --- Variable
    --- Defines whether or not we should rebuild the XML files.
    self.rebuildXML = config.prop("tangent.rebuildXML." .. applicationName, true)

    --- plugins.core.tangent.manager.connection.connected <cp.prop: boolean>
    --- Variable
    --- A `cp.prop` that tracks the connection status to the Tangent Hub.
    self.connected = prop(
        function()
            return self._connectionConfirmed and self:device():connected()
        end,
        function(value)
            if value and self.enabled() and self:device() and not self:device():connected() then
                --------------------------------------------------------------------------------
                -- Only rebuild the controls XML when first enabled for faster startup times:
                --------------------------------------------------------------------------------
                if self.rebuildXML() then
                    self:writeControlsXML()
                    self.rebuildXML(false)
                end

                --------------------------------------------------------------------------------
                -- Run any setup functions (such as disable "Final Cut Pro" in Tangent Hub):
                --------------------------------------------------------------------------------
                if type(setupFn) == "function" then
                    setupFn()
                end

                local ok, errorMessage = self:device():connect(applicationName, systemPath, userPath, task)
                if not ok then
                    log.ef("Failed to start Tangent Support: %s", errorMessage)
                    return false
                end
            elseif not value then
                if self:device():connected() then
                    self:device():disconnect()
                end
            end
        end
    )

    --- plugins.core.tangent.manager.connection.connectable <cp.prop: boolean; read-only>
    --- Variable
    --- Is Tangent support enabled, this connection enabled and the Tangent Hub Installed?
    self.connectable = manager.enabled:AND(manager.tangentHubInstalled):AND(self.enabled)

    -- Tries to reconnect to Tangent Hub when disconnected.
    self._ensureConnection = timer.new(1.0, function()
        self.connected(true)
    end)

    --- plugins.core.tangent.manager.connection.requiresConnection <cp.prop: boolean; read-only>
    --- Variable
    --- Is `true` when the Tangent Manager is both `enabled` but not `connected`.
    self.requiresConnection = self.connectable:AND(prop.NOT(self.connected)):watch(function(required)
        if required then
            self._ensureConnection:start()
        else
            self._ensureConnection:stop()
        end
    end, true)

    --- plugins.core.tangent.manager.connection.requiresDisconnection <cp.prop: boolean; read-only>
    --- Variable
    --- Is `true` when the Tangent Manager is both not `enabled` but is `connected`.
    self.requiresDisconnection = self.connected:AND(prop.NOT(self.connectable)):watch(function(required)
        if required then
            self.connected(false)
        end
    end, true)

end

--- plugins.core.tangent.manager.connection:update() -> none
--- Method
--- Updates the Tangent GUIs.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function connection:update()
    if self.connected() then
        local activeMode = self.activeMode()
        if activeMode then
            self:device():sendModeValue(activeMode.id)
        end
    end
end

--- plugins.core.tangent.manager.connection:device() -> hs.tangent
--- Method
--- Gets the `hs.tangent` object for the connnection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs.tangent` object
function connection:device()
    return self._device
end

--- plugins.core.tangent.manager.connection:displayName() -> string
--- Method
--- Gets the display name for the connnection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string
function connection:displayName()
    return self._displayName
end

function connection:__tostring()
    return format("connection: %s", self:displayName())
end

return connection
