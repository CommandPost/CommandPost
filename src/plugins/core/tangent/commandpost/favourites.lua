--- === plugins.core.tangent.commandpost.favourites ===
---
--- Tangent Favourites.

local require = require

local log         = require("hs.logger").new("tng_favs")

local fs          = require("hs.fs")
local inspect     = require("hs.inspect")
local json        = require("hs.json")

local tools       = require("cp.tools")
local i18n        = require("cp.i18n")

local _           = require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- FAVOURITES_FILE -> number
-- Constant
-- Favourites File Name.
local FAVOURITES_FILE = "Default.cpTangent"

-- plugins.core.tangent.commandpost.favourites.ID -> number
-- Constant
-- ID for "All > CommandPost > Favourites".
mod.ID = 0x0ACF0000

-- plugins.core.tangent.commandpost.favourites.MAX_ITEMS -> number
-- Constant
-- Maximum number of favourites.
mod.MAX_ITEMS = 50

--- plugins.core.tangent.commandpost.favourites.init() -> none
--- Function
--- Initialise Module.
---
--- Parameters:
---  * tangentManager - Tangent Manager Plugin
---  * actionManager - Action Manager Plugin
---  * cpGroup - CommandPost Group
---
--- Returns:
---  * None
function mod.init(tangentManager, actionManager, cpGroup)
    mod._tangentManager = tangentManager

    mod._cpGroup = cpGroup
    mod._actionManager = actionManager

    mod._group = cpGroup:group(i18n("favourites"))

    mod.updateControls()
end

--- plugins.core.tangent.commandpost.favourites.updateControls() -> none
--- Function
--- Update Controls
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateControls()

    local max = mod.MAX_ITEMS
    local group = mod._group
    local faves = mod.favourites()

    --------------------------------------------------------------------------------
    -- Clear existing actions:
    --------------------------------------------------------------------------------
    group:reset()

    local id = mod.ID
    for i = 1, max do
        local fave = faves[i]
        if fave then
            local actionId = id + i
            group:action(actionId)
            :name(fave.actionTitle)
            :onPress(function()
                local handler = mod._actionManager.getHandler(fave.handlerID)
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

    --------------------------------------------------------------------------------
    -- Ensure the new controls are sent to Tangent Mapper:
    --------------------------------------------------------------------------------
    mod._tangentManager.updateControls()
end

-- loadFromFile() -> table
-- Function
-- Loads the Favourites from JSON file.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of favourites.
local function loadFromFile()
    --------------------------------------------------------------------------------
    -- Create folder if it doesn't exist:
    --------------------------------------------------------------------------------
    local configPath = mod._tangentManager.configPath
    local filePath = configPath .. "/" .. FAVOURITES_FILE

    if not tools.doesFileExist(filePath) then
        return {}
    end

    --------------------------------------------------------------------------------
    -- Load from file:
    --------------------------------------------------------------------------------
    local file = io.open(filePath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        if not _.isEmpty(content) then
            local faves = json.decode(content)
            local favourites = {}
            for k,v in pairs(faves) do
                favourites[tonumber(k)] = v
            end
            return favourites
        else
            return {}
        end
    else
        log.ef("Unable to load Favourites file: '%s'", filePath)
        return {}
    end
end

-- saveToFile() -> none
-- Function
-- Saves favourites to JSON file.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function saveToFile(favourites)
    --------------------------------------------------------------------------------
    -- Create folder if it doesn't exist:
    --------------------------------------------------------------------------------
    local configPath = mod._tangentManager.configPath
    if not tools.doesDirectoryExist(configPath) then
        fs.mkdir(configPath)
    end

    --------------------------------------------------------------------------------
    -- Create a table where numbers are converted to strings,
    -- to enable JSON encoding:
    --------------------------------------------------------------------------------
    local faves = {}
    for i = 1, mod.MAX_ITEMS do
        local favourite = favourites and favourites[i]
        if favourite then
            faves[tostring(i)] = favourite
        end
    end

    local ok, result = xpcall(function() return json.encode(faves) end, debug.traceback)
    if not ok then
        log.ef("An error occurred while JSON encoding Tangent Favourites:\n%s", result)
        log.df("Current Favourites: %s", inspect(favourites))
        return false
    end

    --------------------------------------------------------------------------------
    -- Save to file:
    --------------------------------------------------------------------------------
    local filePath = configPath .. "/" .. FAVOURITES_FILE
    local file = io.open(filePath, "w")
    if file then
        file:write(result)
        file:close()
        return true
    else
        log.ef("Unable to save Favourites file: '%s'", filePath)
        return false
    end
end

--- plugins.core.tangent.commandpost.favourites.saveAction(buttonID, actionTitle, handlerID, action) -> none
--- Function
--- Saves an action to Favourites.
---
--- Parameters:
---  * buttonID - The button ID as number.
---  * actionTitle - The action title as string.
---  * handlerID - The handler ID as string.
---  * action - The action table.
---
--- Returns:
---  * None
function mod.saveAction(buttonID, actionTitle, handlerID, action)
    if not mod._favourites[buttonID] then
        mod._favourites[buttonID] = {}
    end
    mod._favourites[buttonID] = {
        actionTitle = actionTitle,
        handlerID = handlerID,
        action = action,
    }
    saveToFile(mod._favourites)
    mod.updateControls()
end

--- plugins.core.tangent.commandpost.favourites.clearAction(buttonID) -> none
--- Function
--- Clears an Action from Favourites.
---
--- Parameters:
---  * buttonID - The button ID you want to clear.
---
--- Returns:
---  * None
function mod.clearAction(buttonID)
    if mod._favourites[buttonID] then
        mod._favourites[buttonID] = nil
    end
    saveToFile()
    mod.updateControls()
end

--- plugins.core.tangent.commandpost.favourites.favourites() -> table
--- Function
--- Gets a table of favourites from file.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of favourites.
function mod.favourites()
    if mod._favourites == nil then
        mod._favourites = loadFromFile()
    end
    return mod._favourites
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "core.tangent.commandpost.favourites",
    group = "core",
    dependencies = {
        ["core.tangent.manager"]        = "tangentManager",
        ["core.tangent.commandpost"]    = "cpGroup",
        ["core.action.manager"]         = "actionManager",
    }
}

function plugin.init(deps)
    mod.init(deps.tangentManager, deps.actionManager, deps.cpGroup)
    return mod
end

return plugin
