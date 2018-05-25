--- === cp.console.history ===
---
--- Console History Manager.
---
--- Originally created by @asmagill
--- https://github.com/asmagill/hammerspoon-config-take2/blob/master/utils/_actions/consoleHistory.lua

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local console  = require("hs.console")
local hashFN   = require("hs.hash").MD5 -- Can use other hash fn if this proves insufficient
local settings = require("hs.settings")
local timer    = require("hs.timer")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local module   = {}

local saveLabel     = "consoleHistory" -- label for saved history
local checkInterval = settings.get(saveLabel.."consoleHistoryInterval") or 1 -- how often to check for changes
local maxLength     = settings.get(saveLabel.."consoleHistoryMaximum") or 100    -- maximum history to save

local uniqueHistory = function(raw)
    local hashed, history = {}, {}
    for i = #raw, 1, -1 do
        local key = hashFN(raw[i])
        if not hashed[key] then
            table.insert(history, 1, raw[i])
            hashed[key] = true
        end
    end
    return history
end

--- cp.console.history.clearHistory() -> none
--- Function
--- Clears the Console History.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
module.clearHistory = function() return console.setHistory({}) end

--- cp.console.history.saveHistory() -> none
--- Function
--- Saves the Console History.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
module.saveHistory = function()
    local hist, save = console.getHistory(), {}
    if #hist > maxLength then
        table.move(hist, #hist - maxLength, #hist, 1, save)
    else
        save = hist
    end
    --------------------------------------------------------------------------------
    -- Save only the unique lines:
    --------------------------------------------------------------------------------
    settings.set(saveLabel, uniqueHistory(save))
end

--- cp.console.history.retrieveHistory() -> none
--- Function
--- Retrieve's the Console History.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
module.retrieveHistory = function()
    local history = settings.get(saveLabel)
    if (history) then
        console.setHistory(history)
    end
end

module.retrieveHistory()
local currentHistoryCount = #console.getHistory()

--- cp.console.history.autosaveHistory -> timer
--- Variable
--- Auto Save History Timer.
module.autosaveHistory = timer.new(checkInterval, function()
    local historyNow = console.getHistory()
    if #historyNow ~= currentHistoryCount then
        currentHistoryCount = #historyNow
        module.saveHistory()
    end
end):start()

--- cp.console.history.pruneHistory() -> number
--- Function
--- Prune History
---
--- Parameters:
---  * None
---
--- Returns:
---  * Current History Count
module.pruneHistory = function()
    console.setHistory(uniqueHistory(console.getHistory()))
    currentHistoryCount = #console.getHistory()
    return currentHistoryCount
end

module = setmetatable(module, { __gc =  function(_)
                                    _.saveHistory()
                                end,
})

--- cp.console.history.history(toFind) -> none
--- Function
--- Gets a history item.
---
--- Parameters:
---  * toFind - Number of the item to find.
---
--- Returns:
---  * None
module.history = function(toFind)
    if type(toFind) == "number" then
        local history = console.getHistory()
        if toFind < 0 then toFind = #history - (toFind + 1) end
        local command = history[toFind]
        if command then
            print(">> " .. command)
            timer.doAfter(.1, function()
                local newHistory = console.getHistory()
                newHistory[#newHistory] = command
                console.setHistory(newHistory)
            end)

            local fn, err = load("return " .. command)
            if not fn then fn, err = load(command) end
            if fn then return fn() else return err end
        else
            error("nil item at specified history position", 2)
        end
    else
        toFind = toFind or ""
        for i,v in ipairs(console.getHistory()) do
            if v:match(toFind) then print(i, v) end
        end
    end
end

return module