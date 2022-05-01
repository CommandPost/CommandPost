--- === plugins.finalcutpro.workflowextension ===
---
--- Workflow Extension Helper
---
--- Commands that can be SENT to the Workflow Extension:
---
---  PING           - Send a ping
---  INCR f         - Increment by Frame        (where f is number of frames)
---  DECR f         - Decrement by Frame        (where f is number of frames)
---  GOTO s         - Goto Timeline Position    (where s is number of seconds)
---
---
---  Commands that can be RECEIVED from the Workflow Extension:
---
---  DONE           - Connection successful
---  PONG           - Recieve a pong
---  PLHD s         - The playhead time has changed                (where s is playhead position in seconds)
---
---  SEQC sequenceName || startTime || duration || frameDuration || container || timecodeFormat || objectType
---     - The active sequence has changed
---       (sequenceName is a string)
---       (startTime in seconds)
---       (duration in seconds)
---       (frameDuration in seconds)
---       (container as a string)
---       (timecodeFormat as a string: DropFrame, NonDropFrame, Unspecified or Unknown)
---       (objectType as a string: Event, Library, Project, Sequence or Unknown)
---
---  RNGC startTime || duration
---     - The active sequence time range has changed
---       (startTime in seconds)
---       (duration in seconds)

local require           = require

local log               = require "hs.logger".new "workflowextension"

local socket            = require "hs.socket"
local timer             = require "hs.timer"

local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local playErrorSound    = tools.playErrorSound

local mod = {}

-- SOCKET_PORT -> number
-- Constant
-- The socket port we use to communicate with the CommandPost Workflow Extension
--
-- Notes:
--  * This is defined within the Workflow Extension
local SOCKET_PORT = 43426

-- NUMBER_OF_PLAYHEAD_INCREMENTS -> number
-- Constant
-- The number of playhead action increments
local NUMBER_OF_PLAYHEAD_INCREMENTS = 50

--- plugins.finalcutpro.workflowextension.connected() -> boolean
--- Variable
--- Is CommandPost connected to the Workflow Extension?
mod.connected = false

-- commandHandler -> table
-- Variable
-- A table that contains all the functions that are triggered by the Workflow Extension commands.
local commandHandler = {
    ["DONE"] =  function()
                    log.df("[Workflow Extension] Connected")
                    mod.connected = true
                end,
    ["PONG"] =  function()
                    --log.df("[Workflow Extension] Pong Recieved!")
                end,
    ["PLHD"] =  function()
                    --log.df("[Workflow Extension] Playhead Timeline Changed")
                    --------------------------------------------------------------------------------
                    -- Let's update the isPlaying prop in the unlikely case that we haven't already
                    -- updated it via other means at this point in time:
                    --------------------------------------------------------------------------------
                    --fcp.viewer.isPlaying:update()
                end,
    ["SEQC"] =  function()
                    --log.df("[Workflow Extension] Active Project has Changed")
                end,
    ["RNGC"] =  function()
                    --log.df("[Workflow Extension] Active Project Duration and/or Start Time has changed")
                end,
}

--- plugins.finalcutpro.workflowextension.connectionCallback() -> none
--- Function
--- Triggers when the Socket makes a connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.connectionCallback()
    mod.socketClient:read("\r\n")
end

--- plugins.finalcutpro.workflowextension.callback() -> none
--- Function
--- Triggers when the Socket receives data.
---
--- Parameters:
---  * data - The incoming data.
---
--- Returns:
---  * None
function mod.callback(data)
    --------------------------------------------------------------------------------
    -- Get the command and send it to the command handler:
    --------------------------------------------------------------------------------
    local command = data and data:sub(1, 4)
    if commandHandler[command] then
        commandHandler[command]()
    else
        log.ef("[Workflow Extension] Unknown Command Received: %s", command)
    end

    --------------------------------------------------------------------------------
    -- Read the next message:
    --------------------------------------------------------------------------------
    if mod.socketClient and mod.socketClient:connected() then
        mod.socketClient:read("\r\n")
    end
end

--- plugins.finalcutpro.workflowextension.connect() -> none
--- Function
--- Connect to the Workflow Extension Socket Server.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.connect()
    mod.socketClient:connect("localhost", SOCKET_PORT, mod.connectionCallback)
end

--- plugins.finalcutpro.workflowextension.setupClient() -> none
--- Function
--- Sets up the Workflow Extension Socket Client
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setupClient()
    --------------------------------------------------------------------------------
    -- Create a new Socket connection:
    --------------------------------------------------------------------------------
    mod.socketClient = socket.new()
    mod.socketClient:setCallback(mod.callback)

    --------------------------------------------------------------------------------
    -- Try to connect:
    --------------------------------------------------------------------------------
    mod.connect()

    --------------------------------------------------------------------------------
    -- Setup a connection timer if the initial connection fails:
    --------------------------------------------------------------------------------
    mod.connectionTimer = timer.new(1, function()
        if not mod.socketClient:connected() and fcp.isFrontmost() then
            --------------------------------------------------------------------------------
            -- Make sure the Workflow Extension is open:
            --------------------------------------------------------------------------------
            if fcp:isEnabled({"Window", "Extensions", "CommandPost"}) then
                fcp:doSelectMenu({"Window", "Extensions", "CommandPost"}):Now()
            else
                log.ef("[Workflow Extension] Failed to open CommandPost Extension from the menubar")
            end

            --------------------------------------------------------------------------------
            -- Try and connect again:
            --------------------------------------------------------------------------------
            if not mod.socketClient:connected() then
                mod.connect()
            end
        end
    end)
end

--- plugins.finalcutpro.workflowextension.isWorkflowExtensionConnected() -> boolean
--- Function
--- Are we connected to the Workflow Extension?
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.isWorkflowExtensionConnected()
    local result = mod.connected or mod.socketClient:connected()
    if not result then
        mod.connected = false
        mod.connectionTimer:start()
    end
    return result
end

--- plugins.finalcutpro.workflowextension.sendCommand(command) -> none
--- Function
--- Sends a command to the Workflow
---
--- Parameters:
---  * command - The command as a string
---
--- Returns:
---  * None
function mod.sendCommand(command)
    if mod.isWorkflowExtensionConnected() then
        mod.socketClient:send(command .. "\r\n")
    else
        log.ef("[Workflow Extension] CommandPost is not currently connected to the Workflow Extension.")
        playErrorSound()
    end
end

--------------------------------------------------------------------------------
-- Setup a Deferred Timer to help with performance:
--------------------------------------------------------------------------------
local playheadChangeValue = 0
local updatePlayhead = deferred.new(0.01):action(function()
    if playheadChangeValue > 0 then
        mod.sendCommand("INCR " .. playheadChangeValue)
    else
        mod.sendCommand("DECR " .. math.abs(playheadChangeValue))
    end
    playheadChangeValue = 0
end)

--- plugins.finalcutpro.workflowextension.incrementPlayhead(frames) -> none
--- Function
--- Increments the Final Cut Pro playhead via the Workflow Extension
---
--- Parameters:
---  * frames - The amount of frames to increment by
---
--- Returns:
---  * None
function mod.incrementPlayhead(frames)
    playheadChangeValue = playheadChangeValue + 1
    updatePlayhead()
end

--- plugins.finalcutpro.workflowextension.decrementPlayhead(frames) -> none
--- Function
--- Decrements the Final Cut Pro playhead via the Workflow Extension
---
--- Parameters:
---  * frames - The amount of frames to increment by
---
--- Returns:
---  * None
function mod.decrementPlayhead(frames)
    playheadChangeValue = playheadChangeValue - 1
    updatePlayhead()
end

--- plugins.finalcutpro.workflowextension.movePlayheadToSeconds(seconds) -> none
--- Function
--- Moves the Final Cut Pro playhead via the Workflow Extension
---
--- Parameters:
---  * seconds - The value you want the timeline playhead to move to in seconds
---
--- Returns:
---  * None
function mod.movePlayheadToSeconds(seconds)
    mod.sendCommand("GOTO " .. seconds)
end

--- plugins.finalcutpro.workflowextension.ping() -> none
--- Function
--- Sends a ping to the Workflow Extension
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.ping()
    mod.sendCommand("PING")
end

--- plugins.finalcutpro.workflowextension.setupActions() -> none
--- Function
--- Setup the Workflow Extension Actions
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setupActions()
    local icon = fcp:icon()
    mod._handler = mod.actionmanager.addHandler("fcpx_workflowextensions", "fcpx")
        :onChoices(function(choices)
            for i=1, NUMBER_OF_PLAYHEAD_INCREMENTS do
                --------------------------------------------------------------------------------
                -- Move Playhead Forward:
                --------------------------------------------------------------------------------
                local frames = i18n("frames")
                if i == 1 then frames = i18n("frame") end

                choices
                    :add(i18n("movePlayheadForward") .. " " .. i .. " " .. frames)
                    :subText(i18n("workflowExtensionMovePlayhead"))
                    :params({
                        amount = i,
                        actionType = "increment",
                        id = "fcpx_workflowextensions_increment_" .. i,
                    })
                    :id("fcpx_workflowextensions_increment_" .. i)
                    :image(icon)

                --------------------------------------------------------------------------------
                -- Move Playhead Backward:
                --------------------------------------------------------------------------------
                choices
                    :add(i18n("movePlayheadBackward") .. " " .. i .. " " .. frames)
                    :subText(i18n("workflowExtensionMovePlayhead"))
                    :params({
                        amount = i,
                        actionType = "decrement",
                        id = "fcpx_workflowextensions_decrement_" .. i,
                    })
                    :id("fcpx_workflowextensions_decrement_" .. i)
                    :image(icon)
            end
        end)
        :onExecute(function(action)
            local actionType = action.actionType
            if actionType == "increment" then
                mod.incrementPlayhead(action.amount)
            elseif actionType == "decrement" then
                mod.decrementPlayhead(action.amount)
            else
                log.ef("[Workflow Extension] Unknown Action Triggered")
            end
        end)
        :onActionId(function(params)
            return params.id
        end)
end

local plugin = {
    id = "finalcutpro.workflowextension",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["core.action.manager"]         = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Connect to Dependancies:
    --------------------------------------------------------------------------------
    mod.actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Setup the Workflow Extension Client:
    --------------------------------------------------------------------------------
    mod.setupClient()

    --------------------------------------------------------------------------------
    -- Setup the Actions:
    --------------------------------------------------------------------------------
    mod.setupActions()

    return mod
end

return plugin
