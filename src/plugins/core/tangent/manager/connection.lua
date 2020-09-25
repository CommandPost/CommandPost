--- === plugins.core.tangent.manager.connection ===
---
--- Represents a Tangent Connection

local require = require

local log                   = require "hs.logger".new "connection"

local hs                    = _G.hs

local fs                    = require "hs.fs"
local inspect               = require "hs.inspect"
local tangent               = require "hs.tangent"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local is                    = require "cp.is"
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
            log.df("InitiateComms Received:")
            log.df("    Protocol Revision: %s", metadata.protocolRev)
            log.df("    Number of Panels: %s", metadata.numberOfPanels)
            for _, v in pairs(metadata.panels) do
                log.df("        Panel Type: %s (%s)", v.panelType, string.format("%#010x", v.panelID))
            end

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
            -- log.df("Menu Reset: %#010x", metadata.menuID)
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
            log.df("Connection to Tangent Hub (%s:%s) successfully established.", metadata.ipAddress, metadata.port)
            self._connectionConfirmed = true
            self.connected:update()
        end,

        [tangent.fromHub.disconnected] = function(metadata)
            log.df("Connection to Tangent Hub (%s:%s) closed.", metadata.ipAddress, metadata.port)
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

--- plugins.core.tangent.manager.writeControlsXML() -> boolean, string
--- Function
--- Writes the Tangent controls.xml File to the User's Application Support folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successfully created otherwise `false` if an error occurred.
---  * If an error occurs an error message will also be returned as a string.
function connection:writeControlsXML()
    log.df("writing controls xml")

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
    --log.df("pluginPath: %s", pluginPath)
    --log.df("systemPath: %s", systemPath)
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

--- plugins.core.tangent.manager.getControlsXML() -> string
--- Function
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

function connection:systemPath()
    return self._systemPath
end

function connection:applicationName()
    return self._applicationName
end

function connection:userPath()
    return self._userPath
end

function connection:task()
    return self._task
end

function connection:pluginPath()
    return self._pluginPath
end

--- plugins.core.tangent.manager.addMode(id, name) -> plugins.core.tangent.manager.mode
--- Function
--- Adds a new `mode` with the specified details and returns it.
---
--- Parameters:
--- * id            - The id number of the Mode.
--- * name          - The name of the Mode.
---
--- Returns:
--- * The new `mode`
function connection:addMode(id, name)
    local m = mode(id, name, self)
    insert(self._modes, m)
    sort(self._modes, function(a,b) return a.id < b.id end)
    return m
end

--- plugins.core.tangent.manager.getMode(id) -> plugins.core.tangent.manager.mode
--- Function
--- Returns the `mode` with the specified ID, or `nil`.
---
--- Parameters:
--- * id    - The ID to find.
---
--- Returns:
--- * The `mode`, or `nil`.
function connection:getMode(id)
    for _,m in ipairs(self._modes) do
        if m.id == id then
            return m
        end
    end
    return nil
end

--- plugins.core.tangent.manager.updateControls() -> none
--- Function
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
---  * applicationName - Your application name as a string
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
function connection:initialize(applicationName, systemPath, userPath, task, pluginPath, setupFn, transportFn, manager)
    self._applicationName       = applicationName
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

    --- plugins.core.tangent.manager.activeModeID <cp.prop: string>
    --- Field
    --- The current active mode ID.
    self.activeModeID = config.prop("tangent.activeMode." .. applicationName)

    --- plugins.core.tangent.manager.activeMode <cp.prop: mode>
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

    --- plugins.core.tangent.manager.rebuildXML <cp.prop: boolean>
    --- Variable
    --- Defines whether or not we should rebuild the XML files.
    self.rebuildXML = config.prop("tangent.rebuildXML." .. applicationName, true)

    --- plugins.core.tangent.manager.connected <cp.prop: boolean>
    --- Variable
    --- A `cp.prop` that tracks the connection status to the Tangent Hub.
    self.connected = prop(
        function()
            return self._connectionConfirmed and self:device():connected()
        end,
        function(value)
            if value and not self:device():connected() then
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

    --- plugins.core.tangent.manager.connectable <cp.prop: boolean; read-only>
    --- Variable
    --- Is the Tangent Enabled and the Tangent Hub Installed?
    self.connectable = manager.enabled:AND(manager.tangentHubInstalled)

    -- Tries to reconnect to Tangent Hub when disconnected.
    self._ensureConnection = timer.new(1.0, function()
        self.connected(true)
    end)

    --- plugins.core.tangent.manager.requiresConnection <cp.prop: boolean; read-only>
    --- Variable
    --- Is `true` when the Tangent Manager is both `enabled` but not `connected`.
    self.requiresConnection = self.connectable:AND(prop.NOT(self.connected)):watch(function(required)
        if required then
            self._ensureConnection:start()
        else
            self._ensureConnection:stop()
        end
    end, true)

    --- plugins.core.tangent.manager.requiresDisconnection <cp.prop: boolean; read-only>
    --- Variable
    --- Is `true` when the Tangent Manager is both not `enabled` but is `connected`.
    self.requiresDisconnection = self.connected:AND(prop.NOT(self.connectable)):watch(function(required)
        if required then
            self.connected(false)
        end
    end, true)

end

--- plugins.core.tangent.manager.update() -> none
--- Function
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

function connection:device()
    return self._device
end

function connection:__tostring()
    return format("connection: %s", self:applicationName())
end

return connection
