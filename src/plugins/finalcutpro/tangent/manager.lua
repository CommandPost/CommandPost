--- === plugins.finalcutpro.tangent.manager ===
---
--- Manager for Final Cut Pro's Tangent Support

local require               = require

local log                   = require "hs.logger".new("tangentManager")

local fs                    = require "hs.fs"

local config                = require "cp.config"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local dirFiles              = tools.dirFiles
local doesDirectoryExist    = tools.doesDirectoryExist
local doesFileExist         = tools.doesFileExist
local mkdir                 = fs.mkdir
local replace               = tools.replace

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

    --------------------------------------------------------------------------------
    -- Copy User Tangent Mappings from Legacy Path to the New Path.
    --
    -- NOTE: The reason we copy, and don't move, is so that users can still
    --       roll back to a previous CommandPost release if needed.
    --------------------------------------------------------------------------------
    local suffix = manager.APPLICATION_NAME_SUFFIX
    local safeSuffix = replace(suffix, " ", "_")
    local homePath = os.getenv("HOME")
    local legacyPath = homePath .. "/Library/Application Support/Tangent/Hub/CommandPost"
    local newPath = homePath .."/Library/Application Support/Tangent/Hub/Final_Cut_Pro" .. safeSuffix
    local filesToMove = {}
    if doesDirectoryExist(legacyPath) then
        local files = dirFiles(legacyPath)
        for _, file in pairs(files) do
            if file:sub(-4) == ".xml" then
                table.insert(filesToMove, legacyPath.. "/" .. file)
            end
        end
    end
    if not doesDirectoryExist(newPath) then
        mkdir(newPath)
    end
    for _, file in pairs(filesToMove) do
        local cmd = [[cp -n "]] ..  file .. [[" "]] .. newPath .. [[" || true]]
        os.execute(cmd)
    end

    --------------------------------------------------------------------------------
    -- Copy Legacy Favourites:
    --------------------------------------------------------------------------------
    local legacyFavouritesPath = homePath .. "/Library/Application Support/CommandPost/Tangent Settings/Default.cpTangent"
    local newFavouritesPath = homePath .. "/Library/Application Support/CommandPost/Tangent Settings/Final Cut Pro/Final Cut Pro.cpTangent"
    if doesFileExist(legacyFavouritesPath) and not doesFileExist(newFavouritesPath) then
        local cmd = [[cp -n "]] ..  legacyFavouritesPath .. [[" "]] .. newFavouritesPath .. [[" || true]]
        os.execute(cmd)
    end

    --------------------------------------------------------------------------------
    -- Setup Tangent Connection:
    --------------------------------------------------------------------------------
    local setupFn = function()
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

    local systemPath = config.userConfigRootPath .. "/Tangent Settings/Final Cut Pro"
    local pluginPath = config.basePath .. "/plugins/finalcutpro/tangent/defaultmap"
    local connection = manager.newConnection("Final Cut Pro", systemPath, nil, "Final Cut Pro", pluginPath, false, setupFn, transportFn)

    connection:addMode(0x00010004, "FCP: " .. i18n("wheels"))

    return connection
end

return plugin
