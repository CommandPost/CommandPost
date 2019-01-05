--- === cp.console.history ===
---
--- Console History Manager.
---
--- Based on code by @asmagill
--- https://github.com/asmagill/hammerspoon-config-take2/blob/master/utils/_actions/consoleHistory.lua

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log      = require("hs.logger").new("history")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local console  = require("hs.console")
local hash     = require("hs.hash")
local timer    = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config   = require("cp.config")
local json     = require("cp.json")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- FILE_NAME -> string
-- Constant
-- File name of settings file.
local FILE_NAME = "History.cpCache"

-- FOLDER_NAME -> string
-- Constant
-- Folder Name where settings file is contained.
local FOLDER_NAME = "Error Log"

-- MAXIMUM -> number
-- Constant
-- Maximum history to save
local MAXIMUM = 100

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- hashFN -> function
-- Variable
-- The has function. Can use other hash function if this proves insufficient.
local hashFN = hash.MD5

-- currentHistoryCount -> number
-- Variable
-- Current History Count
local currentHistoryCount = #console.getHistory()

--- cp.console.history.cache <cp.prop: table>
--- Field
--- Console History Cache
mod.cache = json.prop(config.cachePath, FOLDER_NAME, FILE_NAME, {})

-- uniqueHistory(raw) -> table
-- Function
-- Takes the raw history and returns only the unique history.
--
-- Parameters:
--  * raw - The raw history as a table
--
-- Returns:
--  * A table
local function uniqueHistory(raw)
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
function mod.clearHistory()
    return console.setHistory({})
end

--- cp.console.history.saveHistory() -> none
--- Function
--- Saves the Console History.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.saveHistory()
    local hist, save = console.getHistory(), {}
    if #hist > MAXIMUM then
        table.move(hist, #hist - MAXIMUM, #hist, 1, save)
    else
        save = hist
    end
    --------------------------------------------------------------------------------
    -- Save only the unique lines:
    --------------------------------------------------------------------------------
    mod.cache(uniqueHistory(save))
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
function mod.retrieveHistory()
    local history = mod.cache()
    if (history) then
        console.setHistory(history)
    end
end

--- cp.console.history.pruneHistory() -> number
--- Function
--- Prune History
---
--- Parameters:
---  * None
---
--- Returns:
---  * Current History Count
function mod.pruneHistory()
    console.setHistory(uniqueHistory(console.getHistory()))
    currentHistoryCount = #console.getHistory()
    return currentHistoryCount
end

--- cp.console.history.history(toFind) -> none
--- Function
--- Gets a history item.
---
--- Parameters:
---  * toFind - Number of the item to find.
---
--- Returns:
---  * None
function mod.history(toFind)
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

--- cp.console.history.init() -> self
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function mod.init()

    --------------------------------------------------------------------------------
    -- Retrieve History on Boot:
    --------------------------------------------------------------------------------
    mod.retrieveHistory()

    return mod
end

--------------------------------------------------------------------------------
-- Setup Garbage Collection:
--------------------------------------------------------------------------------
mod = setmetatable(mod, {__gc = function(_) _.saveHistory() end})

return mod.init()
