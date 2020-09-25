--- === plugins.finalcutpro.tangent.manager ===
---
--- Manager for Final Cut Pro's Tangent Support

local require               = require

local log                   = require "hs.logger".new("tangentManager")

local config                = require "cp.config"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local doesDirectoryExist    = tools.doesDirectoryExist
local doesFileExist         = tools.doesFileExist

-- FCP_KEYPRESS_APPS_PATH -> string
-- Constant
-- Final Cut Pro Keypress Apps Path for Tangent Mapper.
local FCP_KEYPRESS_APPS_PATH = "/Library/Application Support/Tangent/Hub/KeypressApps/Final Cut Pro"

-- HIDE_FILE_PATH -> string
-- Constant
-- Tangent Mapper Hide File Path.
local HIDE_FILE_PATH = "/Library/Application Support/Tangent/Hub/KeypressApps/hide.txt"

-- disableFinalCutProInTangentHub() -> none
-- Function
-- Disables the Final Cut Pro preset in the Tangent Hub Application.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function disableFinalCutProInTangentHub()
    if doesDirectoryExist(FCP_KEYPRESS_APPS_PATH) then
        if doesFileExist(HIDE_FILE_PATH) then
            --------------------------------------------------------------------------------
            -- Read existing Hide file:
            --------------------------------------------------------------------------------
            local file, errorMessage, errorNumber = io.open(HIDE_FILE_PATH, "r")
            if file then
                local fileContents = file:read("*a")
                file:close()
                if fileContents and string.match(fileContents, "Final Cut Pro") then
                    --------------------------------------------------------------------------------
                    -- Final Cut Pro is already hidden in the Tangent Hub.
                    --------------------------------------------------------------------------------
                    --log.df("Final Cut Pro is already disabled in Tangent Hub.")
                    return
                else
                    --------------------------------------------------------------------------------
                    -- Append Existing Hide File:
                    --------------------------------------------------------------------------------
                    local appendFile, errorMessageA, errorNumberA = io.open(HIDE_FILE_PATH, "a")
                    if appendFile then
                        appendFile:write("\nFinal Cut Pro")
                        appendFile:close()
                    else
                        log.ef("Failed to append existing Hide File for Tangent Mapper: %s (%s)", errorMessageA, errorNumberA)
                    end
                end
            else
                log.ef("Failed to read existing Hide File for Tangent Mapper: %s (%s)", errorMessage, errorNumber)
            end
        else
            --------------------------------------------------------------------------------
            -- Create new Hide File:
            --------------------------------------------------------------------------------
            local newFile, errorMessage, errorNumber = io.open(HIDE_FILE_PATH, "w")
            if newFile then
                newFile:write("Final Cut Pro")
                newFile:close()
            else
                log.ef("Failed to create new Hide File for Tangent Mapper: %s (%s)", errorMessage, errorNumber)
            end
        end
    end
end

local plugin = {
    id = "finalcutpro.tangent.manager",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"] = "manager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local manager = deps.manager

    local systemPath = config.userConfigRootPath .. "/Tangent Settings/Final Cut Pro"
    local pluginPath = config.basePath .. "/plugins/finalcutpro/tangent/defaultmap"

    local setupFn = function()
        -- TODO: we need to migrate settings across for legacy users.

        disableFinalCutProInTangentHub()
    end

    local transportFn = function(metadata)
        if fcp:isFrontmost() then
            if metadata.jogValue == 1 then
                fcp.menu:doSelectMenu({"Mark", "Next", "Frame"}):Now()
            elseif metadata.jogValue == -1 then
                fcp.menu:doSelectMenu({"Mark", "Previous", "Frame"}):Now()
            end
        end
    end

    local connection = manager.newConnection("Final Cut Pro (via CommandPost)", systemPath, nil, "Final Cut Pro", pluginPath, setupFn, transportFn)

    connection:addMode(0x00010004, "FCP: " .. i18n("wheels"))

    return connection
end

return plugin
