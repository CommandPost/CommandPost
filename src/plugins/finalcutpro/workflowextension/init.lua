--- === plugins.finalcutpro.workflowextension ===
---
--- Workflow Extension Helper

local require       = require

local log           = require "hs.logger".new "workflowextension"

local socket        = require "hs.socket"
local timer         = require "hs.timer"

local fcp           = require "cp.apple.finalcutpro"

-- SOCKET_PORT -> number
-- Constant
-- The socket port we use to communicate with the CommandPost Workflow Extension
--
-- Notes:
--  * This is defined within the Workflow Extension
local SOCKET_PORT = 43426

local mod = {}

local plugin = {
    id = "finalcutpro.workflowextension",
    group = "finalcutpro",
    dependencies = {
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    log.df("[plugins.finalcutpro.workflowextension] Started")

    local callback = function(data, tag)
        local command = data and data:sub(1, 4)
        local value = data and data:sub(6, -4)

        log.df("[plugins.finalcutpro.workflowextension] command: '%s', value: '%s'", command, value)

        if mod.socketClient then
            mod.socketClient:read("\r\n")
        end
    end

    local connectionCallback = function()
        log.df("[plugins.finalcutpro.workflowextension] Socket Connected!")
        mod.socketClient:read("\r\n")
    end

    mod.socketClient = socket.new()
    mod.socketClient:setCallback(callback)
    mod.socketClient:connect("localhost", 43426, connectionCallback)

    mod.connectionTimer = timer.doEvery(5, function()
        if not mod.socketClient:connected() and fcp.isFrontmost() then
            log.df("[plugins.finalcutpro.workflowextension] Attempting to connect...")

            --------------------------------------------------------------------------------
            -- Make sure the Workflow Extension is open:
            --------------------------------------------------------------------------------
            log.df("[plugins.finalcutpro.workflowextension] Opening Workflow Extension")
            if fcp:isEnabled({"Window", "Extensions", "CommandPost"}) then
                fcp:doSelectMenu({"Window", "Extensions", "CommandPost"}):Now()
            end

            --------------------------------------------------------------------------------
            -- Try and connect:
            --------------------------------------------------------------------------------
            if not mod.socketClient:connected() then
                mod.socketClient:connect("localhost", 43426, connectionCallback)
            end
        end
    end)

    -- TODO: This currently crashes the Workflow Extension:
    mod.sendPing = function()
        if mod.socketClient:connected() then
            log.df("Sending Ping")
            mod.socketClient:send("PING\r\n")
        end
    end

    return mod
end

return plugin
