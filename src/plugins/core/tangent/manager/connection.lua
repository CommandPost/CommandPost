--- === plugins.core.tangent.manager.connection ===
---
--- Represents a Tangent Connection

local require = require

local log                   = require "hs.logger".new "connection"

local tangent               = require "hs.tangent"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local is                    = require "cp.is"

local class                 = require "middleclass"

local action                = require "action"
local controls              = require "controls"
local menu                  = require "menu"
local mode                  = require "mode"
local parameter             = require "parameter"

local doAfter               = timer.doAfter

local connection = class "core.tangent.manager.Connection"

local function setupTangentConnection(obj, manager)
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
                obj:device():sendDisplayText({"CommandPost "..version})
            end)
            --------------------------------------------------------------------------------
            -- Update Mode:
            --------------------------------------------------------------------------------
            --TODO: This should be ported across from the manager.
            manager.update()
        end,

        [tangent.fromHub.actionOn] = function(metadata)
            local control = obj.controls:findByID(metadata.actionID)
            if action.is(control) then
                control:press()
            end
        end,

        [tangent.fromHub.actionOff] = function(metadata)
            local control = obj.controls:findByID(metadata.actionID)
            if action.is(control) then
                control:release()
            end
        end,

        [tangent.fromHub.parameterChange] = function(metadata)
            local control = obj.controls:findByID(metadata.paramID)
            if parameter.is(control) then
                local newValue = control:change(metadata.increment)
                if newValue == nil then
                    newValue = control:get()
                end
                if is.number(newValue) then
                    obj:device():sendParameterValue(control.id, newValue)
                end
            end
        end,

        [tangent.fromHub.parameterReset] = function(metadata)
            local control = obj.controls:findByID(metadata.paramID)
            if parameter.is(control) then
                local newValue = control:reset()
                if newValue == nil then
                    newValue = control:get()
                end
                if is.number(newValue) then
                    obj:device():sendParameterValue(control.id, newValue)
                end
            end
        end,

        [tangent.fromHub.parameterValueRequest] = function(metadata)
            local control = obj.controls:findByID(metadata.paramID)
            if parameter.is(control) then
                local value = control:get()
                if is.number(value) then
                    obj:device():sendParameterValue(control.id, value)
                end
            end
        end,

        [tangent.fromHub.transport] = function(metadata)
            -- TODO: FCPX specific code should not be in `core`.
            --[[
            if fcp:isFrontmost() then
                if metadata.jogValue == 1 then
                    fcp.menu:doSelectMenu({"Mark", "Next", "Frame"}):Now()
                elseif metadata.jogValue == -1 then
                    fcp.menu:doSelectMenu({"Mark", "Previous", "Frame"}):Now()
                end
            end
            --]]
        end,

        [tangent.fromHub.menuChange] = function(metadata)
            local control = obj.controls:findByID(metadata.menuID)
            local increment = metadata.increment
            if menu.is(control) then
                if increment == 1 then
                    control:next()
                else
                    control:prev()
                end
                --------------------------------------------------------------------------------
                -- For some strange reason, instead of returning -1 when you turn the knob
                -- anti-clockwise, it returns 4294967295. No idea why!
                --
                --[[
                elseif increment == -1 then
                    control:prev()
                else
                    log.ef("Unexpected 'menu change' increment from Tangent: %s", increment)
                end
                --]]
                --------------------------------------------------------------------------------
                local value = control:get()
                if value ~= nil then
                    obj:device():sendMenuString(control.id, value)
                end
            end
        end,

        [tangent.fromHub.menuReset] = function(metadata)
            -- log.df("Menu Reset: %#010x", metadata.menuID)
            local control = obj.controls:findByID(metadata.menuID)
            if menu.is(control) then
                control:reset()
                local value = control:get()
                if value ~= nil then
                    obj:device():sendMenuString(control.id, value)
                end
            end
        end,

        [tangent.fromHub.menuStringRequest] = function(metadata)
            local control = obj.controls:findByID(metadata.menuID)
            if menu.is(control) then
                local value = control:get()
                if value ~= nil then
                    obj:device():sendMenuString(control.id, value)
                end
            end
        end,

        [tangent.fromHub.modeChange] = function(metadata)
            local newMode = mod.getMode(metadata.modeID)
            if newMode then
                mod.activeMode(newMode)
            end
        end,

        [tangent.fromHub.connected] = function(metadata)
            log.df("Connection to Tangent Hub (%s:%s) successfully established.", metadata.ipAddress, metadata.port)

            -- TODO: this should be migrated from the manager:
            manager._connectionConfirmed = true
            manager.connected:update()
        end,

        [tangent.fromHub.disconnected] = function(metadata)
            log.df("Connection to Tangent Hub (%s:%s) closed.", metadata.ipAddress, metadata.port)

            -- TODO: this should be migrated from the manager:
            manager._connectionConfirmed = false
            manager.connected:update()
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
function connection:initialize(applicationName, systemPath, userPath, task, manager)
    self._applicationName       = applicationName
    self._systemPath            = systemPath
    self._userPath              = userPath
    self._task                  = task

    self.manager                = manager
    self.controls               = controls(self)

    self._device                = setupTangentConnection(self, manager)
end

function connection:connect()
    local ok, errorMessage = self._device:connect(self._applicationName, self._systemPath, self._userPath, self._task)
    if not ok then
        log.ef("Failed to start Tangent Support: %s", errorMessage)
        return false
    end
end

function connection:device()
    return self._device
end

function connection:__tostring()
    return format("connection: %s (%#010x)", self.bundleID)
end

return connection