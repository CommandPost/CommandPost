--- === cp.idle ===
---
--- This library allows tasks to be queue for execution when the computer has
--- been idle for a specified amount of time. 'Idle' is defined as no keyboard
--- or mouse movement.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("idle")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local host						= require("hs.host")
local timer						= require("hs.timer")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local insert					= table.insert

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local queue = {}
local checkTimer = nil

local function checkQueue()
    if #queue == 0 and checkTimer:running() then
        checkTimer:stop()
    else
        local newQueue = {}
        for _,item in ipairs(queue) do
            -- we check idle time on every queued item
            local idleTime = host.idleTime()
            if item.seconds < idleTime then
                -- run the action, checking for errors
                local ok, result = xpcall(item.action, debug.traceback)
                if not ok then
                    log.ef("Error while processing idle queue:\n%s", result)
                    if item.retryOnError then
                        insert(newQueue, item)
                    end
                end
            else
                insert(newQueue, item)
            end
        end

        queue = newQueue
    end
end

checkTimer = timer.new(1, checkQueue, true)

--- cp.idle.queue(idleSeconds, actionFn[, retryOnError]) -> nothing
--- Function
--- Adds an action to the idle queue, which will be run after the the computer has been idle
--- for at least the specified number of seconds. It may be longer, if other items are on the queue,
--- or if other tasks are running in the application.
---
--- Parameters:
--- * `idleSeconds`		- The number of seconds of idle time must have elapsed run the action
--- * `actionFn`		- The function to execute
--- * `retryOnError`	- Optional. If set to `true`, the action will try running again if there is an error.
---
--- Returns:
--- * Nothing
function mod.queue(idleSeconds, actionFn, retryOnError)
    insert(queue, {seconds = idleSeconds, action = actionFn, retryOnError = retryOnError})
    if not checkTimer:running() then
        checkTimer:start()
    end
end

return mod
