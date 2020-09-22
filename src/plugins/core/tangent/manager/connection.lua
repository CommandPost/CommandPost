--- === plugins.core.tangent.manager.connection ===
---
--- Represents a Tangent Connection

local require = require

local log                   = require "hs.logger".new "connection"

local tangent               = require "hs.tangent"

local class                 = require "middleclass"

local connection = class "core.tangent.manager.Connection"

local function setupTangentConnection(manager)
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
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.actionOn] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.actionOff] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.parameterChange] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.parameterReset] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.parameterValueRequest] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.transport] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.menuChange] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.menuReset] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.menuStringRequest] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.modeChange] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.connected] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,

        [tangent.fromHub.disconnected] = function(metadata)
            log.df("metadata: %s", hs.inspect(metadata))
        end,
    }

    --------------------------------------------------------------------------------
    -- Register the handlers:
    --------------------------------------------------------------------------------
    for id,fn in pairs(manager.fromHub) do
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
    self.applicationName        = applicationName
    self.systemPath             = systemPath
    self.userPath               = userPath
    self.task                   = task

    self.manager                = manager

    self.device                 = setupTangentConnection(manager)
end

function connection:connect()
    local ok, errorMessage = self.device:connect(self.applicationName, self.systemPath, self.userPath, self.task)
    if not ok then
        log.ef("Failed to start Tangent Support: %s", errorMessage)
        return false
    end
end

function connection:__tostring()
    return format("connection: %s (%#010x)", self.bundleID)
end

return connection