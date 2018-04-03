--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.manager ===
---
--- Tangent/Action Co-Ordinator Plugin
---
--- This uses the Tangent Manager Plugin to link Tangent Actions with CP Actions.
---
--- NOTE: Due to the dynamic nature of the CP Action API, CP Actions which
--- are mapped to Tangent Actions will not be portable between systems.

local log               = require("hs.logger").new("tg_actions")

local json              = require("hs.json")
local config            = require("cp.config")
local tools             = require("cp.tools")

local moses             = require("moses")

local mod = {}

-- makeStringTangentFriendly(value) -> none
-- Function
-- Removes any illegal characters from the value
--
-- Parameters:
--  * value - The string you want to process
--
-- Returns:
--  * A string that's valid for Tangent's panels
local function makeStringTangentFriendly(value)
    local result = ""
    for i = 1, #value do
        local letter = value:sub(i,i)
        local byte = string.byte(letter)
        if byte >= 32 and byte <= 126 then
            result = result .. letter
        --else
            --log.df("Illegal Character: %s", letter)
        end
    end
    if #result == 0 then
        return nil
    else
        --------------------------------------------------------------------------------
        -- Trim Results, just to be safe:
        --------------------------------------------------------------------------------
        return tools.trim(result)
    end
end

-- loadMapping() -> none
-- Function
-- Loads the Tangent Mapping file from the Application Support folder.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if successful, otherwise `false`
local function loadMapping() --luacheck:ignore
    local mappingFilePath = mod._configPath .. "/mapping.json"
    if not tools.doesFileExist(mappingFilePath) then
        log.ef("Tangent Mapping could not be found.")
        return false
    end
    local file = io.open(mappingFilePath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        if not moses.isEmpty(content) then
            --log.df("Loaded Tangent Mappings.")
            mod._mapping = json.decode(content)
            return true
        else
            log.ef("Empty Tangent Mapping: '%s'", mappingFilePath)
            return false
        end
    else
        log.ef("Unable to load Tangent Mapping: '%s'", mappingFilePath)
        return false
    end
end

function mod.init(tangentManager, actionManager)
    mod._tangentManager = tangentManager
    mod._actionManager = actionManager

    --------------------------------------------------------------------------------
    -- Get XML Path:
    --------------------------------------------------------------------------------
    mod._configPath = config.userConfigRootPath .. "/Tangent Settings"
end

function mod.buildActionMap()

    local actionManager, tangentManager = mod._actionManager, mod._tangentManager
    local currentActionID = 0x00020001 -- Action ID starts at 0x00020001
    local mapping = {}

    for _,handler in pairs(actionManager.handlers()) do
        local handlerID = handler:id()
        if string.sub(handlerID, -7) ~= "widgets" and string.sub(handlerID, -12) ~= "midicontrols" then
            local handlerLabel = i18n(handlerID .. "_action")
            local group = tangentManager.controls:group( handlerLabel )

            local choices = handler:choices():getChoices()
            table.sort(choices, function(a, b) return a.text < b.text end)

            for _, choice in pairs(choices) do
                local actionID = currentActionID
                local name = makeStringTangentFriendly(choice.text)

                if name and #name > 0 then
                    group:action(actionID, name)

                    currentActionID = currentActionID + 1
                    table.insert(mapping, {
                        [actionID] = {
                            ["handlerID"] = handlerID,
                            ["action"] = choice.params,
                        }
                    })
                end
            end
        end
    end

    local mappingFile = io.open(mod._configPath .. "/mapping.json", "w")
    if mappingFile then
        io.output(mappingFile)
        io.write(json.encode(mapping))
        io.close(mappingFile)
        mod._mapping = mapping
        return true
    else
        log.ef("Failed to open mapping.json file in write mode")
        return false, "Failed to open mapping.json file in write mode"
    end
end

--- plugins.core.tangent.manager.areMappingsInstalled() -> boolean
--- Function
--- Are mapping files installed?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if mapping files are installed otherwise `false`
function mod.areMappingsInstalled()
    return tools.doesFileExist(mod._configPath .. "/controls.xml") and tools.doesFileExist(mod._configPath .. "/mapping.json")
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id          = "core.tangent.actions",
    group       = "core",
    dependencies    = {
        ["core.tangent.manager"]                        = "tangentmanager",
        ["core.action.manager"]                         = "actionmanager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(_)

    -- TODO: Figure out what to do with actions.
    -- mod.init(deps.tangentmanager, deps.actionmanager)

    --------------------------------------------------------------------------------
    -- Return Module:
    --------------------------------------------------------------------------------
    return mod

end

return plugin