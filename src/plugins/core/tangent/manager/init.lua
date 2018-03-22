--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.manager ===
---
--- Tangent Control Surface Manager
---
--- This plugin allows Hammerspoon to communicate with Tangent's range of
--- panels (Element, Virtual Element Apps, Wave, Ripple and any future panels).
---
--- Download the Tangent Developer Support Pack & Tangent Hub Installer for Mac
--- here: http://www.tangentwave.co.uk/developer-support/

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("tangentMan")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fs                                        = require("hs.fs")
local inspect                                   = require("hs.inspect")
local json                                      = require("hs.json")
local tangent                                   = require("hs.tangent")
local timer                                     = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")
local x                                         = require("cp.web.xml")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local moses                                     = require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.core.touchbar.manager._groupStatus -> table
-- Variable
-- Group Statuses.
mod._groupStatus = {}

--- plugins.core.touchbar.manager.defaultGroup -> string
--- Variable
--- The default group.
mod.defaultGroup = "global"

--- plugins.core.tangent.manager.MODES() -> table
--- Constant
--- The default Modes for CommandPost in the Tangent Mapper.
mod.MODES = {
    ["0x00010001"] = {
        ["name"]    =   i18n("global_command_group"),
        ["groupID"] =   "global",
    },
}

--- plugins.core.tangent.manager.customParameters
--- Constant
--- Table containing custom Tangent parameters.
mod.CUSTOM_PARAMETERS = {}

-- getCustomParameter(id) -> table
-- Function
-- Returns a custom parameter table.
--
-- Parameters:
--  * id - The ID of the table as string.
--
-- Returns:
--  * table or `nil` if no match.
local function getCustomParameter(id)
    for _, group in pairs(mod.CUSTOM_PARAMETERS) do
        for parameterID, parameter in pairs(group) do
            if parameterID == id then
                return parameter
            end
        end
    end
    return nil
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
local function loadMapping()
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

--- plugins.core.tangent.manager.writeControlsXML() -> boolean, string
--- Function
--- Writes the Tangent controls.xml File to the User's Application Support folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  *  `true` if successfully created otherwise `false` if an error occurred.
---  *  If an error occurs an error message will also be returned as a string.
function mod.writeControlsXML()

    --------------------------------------------------------------------------------
    -- TODO: One day I'm sure David will re-write this using SLAXML. Until that day,
    --       we're just going to generate this XML file manually.
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Create folder if it doesn't exist:
    --------------------------------------------------------------------------------
    if not tools.doesDirectoryExist(mod._configPath) then
        --log.df("Tangent Settings folder did not exist, so creating one.")
        fs.mkdir(mod._configPath)
    else
        --------------------------------------------------------------------------------
        -- Backup old files first just to be safe:
        --------------------------------------------------------------------------------
        if not tools.doesDirectoryExist(mod._backupPath) then
            log.df("Tangent Backup folder did not exist, so creating one.")
            fs.mkdir(mod._backupPath)
        end
        local executeString = [[zip -r "]] .. mod._backupPath .. [[/Tangent Settings Backup ]] .. os.date("%Y%m%d %H%M") .. [[.zip" "]] .. mod._configPath .. [["]]
        local _, status = hs.execute(executeString)
        if not status then
            log.ef("Failed to backup Tangent Settings.")
        end
    end

    --------------------------------------------------------------------------------
    -- Copy existing XML files from Application Bundle to local Application Support:
    --------------------------------------------------------------------------------
    local _, status = hs.execute([[cp -a "]] .. mod._pluginPath .. [["/. "]] .. mod._configPath .. [[/"]])
    if not status then
        log.ef("Failed to copy XML files.")
        return false, "Failed to copy XML files."
    end

    --------------------------------------------------------------------------------
    -- Create "controls.xml" file:
    --------------------------------------------------------------------------------
    local mapping = {}
    local controlsFile = io.open(mod._configPath .. "/controls.xml", "w")
    if controlsFile then

        io.output(controlsFile)

        --------------------------------------------------------------------------------
        -- Set starting values:
        --------------------------------------------------------------------------------
        local currentActionID = 131073 -- Action ID starts at 0x00020001

        local root = x.TangentWave {fileType = "ControlSystem", fileVersion="3.0"} (
            --------------------------------------------------------------------------------
            -- Capabilities:
            --------------------------------------------------------------------------------
            x.Capabilities (
                x.Jog { enabled = true } ..
                x.Shuttle { enabled = false } ..
                x.StatusDisplay { lineCount = 3 }
            ) ..

            --------------------------------------------------------------------------------
            -- Modes:
            --------------------------------------------------------------------------------
            x.Modes (function()
                local modes = x()
                for modeID, metadata in tools.spairs(mod.MODES) do
                    modes = modes .. x.Mode {id=modeID} (
                        x.Name (metadata.name)
                    )
                end
                return modes
            end)

        )

        --------------------------------------------------------------------------------
        -- Get a list of Handler IDs:
        --------------------------------------------------------------------------------
        local handlerIds = mod._actionmanager.handlerIds()

        --------------------------------------------------------------------------------
        -- Add Custom Parameters to Handler IDs:
        --------------------------------------------------------------------------------
        for id, _ in pairs(mod.CUSTOM_PARAMETERS) do
            table.insert(handlerIds, id)
        end

        --------------------------------------------------------------------------------
        -- Sort the Handler IDs alphabetically:
        --------------------------------------------------------------------------------
        table.sort(handlerIds, function(a, b) return i18n(a .. "_action") < i18n(b .. "_action") end)

        --------------------------------------------------------------------------------
        -- Controls:
        --------------------------------------------------------------------------------
        local controls = x.Controls {}
        for _, handlerID in pairs(handlerIds) do

            --------------------------------------------------------------------------------
            -- Add Custom Parameters & Bindings:
            --------------------------------------------------------------------------------
            local match = false
            for customParameterID, customParameter in pairs(mod.CUSTOM_PARAMETERS) do
                if handlerID == customParameterID then

                    --------------------------------------------------------------------------------
                    -- Found a match:
                    --------------------------------------------------------------------------------
                    match = true

                    --------------------------------------------------------------------------------
                    -- Start Group:
                    --------------------------------------------------------------------------------
                    local handlerLabel = i18n(handlerID .. "_action")
                    local group = x.Group { name = handlerLabel }

                    --------------------------------------------------------------------------------
                    -- Sort table alphabetically by name:
                    --------------------------------------------------------------------------------
                    local sortedKeys = tools.getKeysSortedByValue(customParameter, function(a, b) return a.name < b.name end)

                    --------------------------------------------------------------------------------
                    -- Process the Custom Parameters:
                    --------------------------------------------------------------------------------
                    for _, id in pairs(sortedKeys) do
                        local metadata = customParameter[id]
                        if id == "bindings" then
                            -- append the bindings XML unescaped
                            group( metadata.xml, false)
                        else
                            --------------------------------------------------------------------------------
                            -- Add Parameter:
                            --------------------------------------------------------------------------------
                            group(
                                x.Parameter { id = id } (
                                    x.Name( metadata.name ) ..
                                    x.Name9( metadata.name9 ) ..
                                    x.MinValue( metadata.minValue ) ..
                                    x.MaxValue( metadata.maxValue ) ..
                                    x.StepSize( metadata.stepSize )
                                )
                            )

                            currentActionID = currentActionID + 1
                        end
                    end

                    controls:append(group)
                end
            end

            if not match then
                --------------------------------------------------------------------------------
                -- Action Manager Actions:
                --------------------------------------------------------------------------------
                local handler = mod._actionmanager.getHandler(handlerID)
                if string.sub(handlerID, -7) ~= "widgets" and string.sub(handlerID, -12) ~= "midicontrols" then
                    local handlerLabel = i18n(handler:id() .. "_action")
                    local group = x.Group { name = handlerLabel }

                    local choices = handler:choices()._choices
                    table.sort(choices, function(a, b) return a.text < b.text end)

                    for _, choice in pairs(choices) do
                        local friendlyName = makeStringTangentFriendly(choice.text)
                        if friendlyName and #friendlyName >= 1 then
                            local actionID = string.format("%#010x", currentActionID)

                            group(
                                x.Action { id = actionID } (
                                    x.Name (friendlyName)
                                )
                            )
                            currentActionID = currentActionID + 1
                            table.insert(mapping, {
                                [actionID] = {
                                    ["handlerID"] = handlerID,
                                    ["action"] = choice.params,
                                }
                            })
                        end
                    end
                    controls:append(group)
                end
            end
        end
        root:append(controls)

        --------------------------------------------------------------------------------
        -- Default Global Settings:
        --------------------------------------------------------------------------------
        root:append(
            x.DefaultGlobalSettings (
                x.KnobSensitivity { std = 5, alt = 5 } ..
                x.JogDialSensitivity { std = 5, alt = 5 } ..
                x.TrackerballSensitivity { std = 5, alt = 5 } ..
                x.TrackerballDialSensitivity { std = 5, alt = 5 } ..
                x.IndependentPanelBanks { enabled = false }
            )
        )

        --------------------------------------------------------------------------------
        -- End of XML:
        --------------------------------------------------------------------------------

        local output
        output = x([[<?xml version="1.0" encoding="UTF-8" standalone="yes"?>]], false) .. root

        --------------------------------------------------------------------------------
        -- Write to File & Close:
        --------------------------------------------------------------------------------
        io.write(tostring(output))
        io.close(controlsFile)

        --------------------------------------------------------------------------------
        -- Save Mapping File:
        --------------------------------------------------------------------------------
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
    else
        log.ef("Failed to open controls.xml file in write mode")
        return false, "Failed to open controls.xml file in write mode"
    end
end

--- plugins.core.tangent.manager.addModes(modes) -> none
--- Function
--- Adds modes to the existing modes table.
---
--- Parameters:
---  * modes - a table containing the new modes items.
---
--- Returns:
---  * None
function mod.addModes(modes)
    if modes and type(modes) == "table" then
        mod.MODES = tools.mergeTable(mod.MODES, modes)
    end
end

--- plugins.core.tangent.manager.addParameters(modes) -> none
--- Function
--- Adds modes to the existing modes table.
---
--- Parameters:
---  * modes - a table containing the new modes items.
---
--- Returns:
---  * None
function mod.addParameters(parameters)
    if parameters and type(parameters) == "table" then
        mod.CUSTOM_PARAMETERS = tools.mergeTable(mod.CUSTOM_PARAMETERS, parameters)
    end
end

-- getTangentIDFromGroupID(groupID) -> none
-- Function
-- Get Tangent ID from Group ID.
--
-- Parameters:
--  * groupID - the plain text group ID.
--
-- Returns:
--  * The ID used by Tangent as a string - for example: "0x00010001".
local function getTangentIDFromGroupID(groupID)
    for id, metadata in pairs(mod.MODES) do
        if metadata.groupID == groupID then
            return id
        end
    end
    return nil
end

--- plugins.core.touchbar.manager.currentSubGroup -> table
--- Variable
--- Current Tangent Sub Group.
mod.currentSubGroup = config.prop("tangentCurrentSubGroup", {})

--- plugins.core.touchbar.manager.activeGroup() -> string
--- Function
--- Returns the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns the active group or `manager.defaultGroup` as a string.
function mod.activeGroup()
    local groupStatus = mod._groupStatus
    for group, status in pairs(groupStatus) do
        if status then
            return group
        end
    end
    return mod.defaultGroup
end

--- plugins.core.touchbar.manager.update() -> none
--- Function
--- Updates the Tangent GUIs.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    local activeGroup = mod.activeGroup()
    if activeGroup then

        local currentSubGroup = mod.currentSubGroup()
        local tangentID = currentSubGroup and currentSubGroup[activeGroup] or getTangentIDFromGroupID(activeGroup)

        --log.df("UPDATE TANGENT GROUP: %s (%s)", mod.activeGroup(), tangentID)

        --------------------------------------------------------------------------------
        -- Send Mode to Tangent:
        --------------------------------------------------------------------------------
        if tangentID then
            tangent.sendModeValue(tonumber(tangentID))
        end
    end
end

--- plugins.core.touchbar.manager.groupStatus(groupID, status) -> none
--- Function
--- Updates a group's visibility status.
---
--- Parameters:
---  * groupID - the group you want to update as a string.
---  * status - the status of the group as a boolean.
---
--- Returns:
---  * None
function mod.groupStatus(groupID, status)
    mod._groupStatus[groupID] = status
    mod.update()
end

local fromHub = {
    [tangent.fromHub.initiateComms] = function(metadata)
        --------------------------------------------------------------------------------
        -- InitiateComms:
        --------------------------------------------------------------------------------
        log.df("InitiateComms Received:")
        log.df("    Protocol Revision: %s", metadata.protocolRev)
        log.df("    Number of Panels: %s", metadata.numberOfPanels)
        for _, v in pairs(metadata.panels) do
            log.df("        Panel Type: %s (%s)", v.panelType, string.format("%#010x", v.panelID))
        end

        --------------------------------------------------------------------------------
        -- Display CommandPost Version on Tangent Screen:
        --------------------------------------------------------------------------------
        timer.doAfter(1, function()
            local version = tostring(config.appVersion)
            tangent.sendDisplayText({"CommandPost "..version})
        end)
        --------------------------------------------------------------------------------
        -- Update Mode:
        --------------------------------------------------------------------------------
        mod.update()
    end,

    [tangent.fromHub.actionOn] = function(metadata)
        if metadata and metadata.actionID then
            local actionID = string.format("%#010x", metadata.actionID)
            local mapping = nil
            for _, v in pairs(mod._mapping) do
                if v[actionID] then
                    mapping = v[actionID]
                end
            end
            if mapping then
                -- TODO: FCPX specific code should not be in `core`.
                if string.sub(mapping.handlerID, 1, 4) == "fcpx" and fcp:isFrontmost() == false then
                    --log.df("Final Cut Pro isn't actually frontmost so ignoring.")
                    return
                end
                local handler = mod._actionmanager.getHandler(mapping.handlerID)
                handler:execute(mapping.action)
            else
                log.ef("Could not find a Mapping with Action ID: '%s'", actionID)
            end
        end
    end,

    [tangent.fromHub.actionOff] = function(metadata)
        -- A key has been released.
        log.df("A key has been released: %#010x", metadata.actionID)
    end,

    [tangent.fromHub.parameterChange] = function(metadata)
        if metadata and metadata.increment and metadata.paramID then
            if fcp.isFrontmost() == false then
                --log.df("Final Cut Pro isn't actually frontmost so ignoring.")
                return
            end

            local paramID = string.format("%#010x", metadata.paramID)
            local increment = metadata.increment

            local customParameter = getCustomParameter(paramID)
            if customParameter then
                --------------------------------------------------------------------------------
                -- Shift Value:
                --------------------------------------------------------------------------------
                local ok, result = xpcall(function()
                    return customParameter.shiftValue(increment)
                end, debug.traceback)
                if not ok then
                    log.ef("Error while executing Parameter Change: %s", result)
                    return nil
                end

                --------------------------------------------------------------------------------
                -- Send Values back to Tangent Hub:
                --------------------------------------------------------------------------------
                local value
                ok, value = xpcall(function()
                    return customParameter.getValue()
                end, debug.traceback)
                if not ok then
                    log.ef("Error while trying to send values back to Tangent during Parameter Change: %s", result)
                    return nil
                end
                if value then
                    tangent.sendParameterValue(paramID, value)
                end
            end
        end
    end,

    [tangent.fromHub.parameterReset] = function(metadata)
        local paramID = string.format("%#010x", metadata.paramID)
        local customParameter = getCustomParameter(paramID)
        if customParameter then
            customParameter.resetValue()
        end
    end,

    [tangent.fromHub.parameterValueRequest] = function(metadata)
        local paramID = string.format("%#010x", metadata.paramID)
        local customParameter = getCustomParameter(paramID)
        if customParameter then
            local value = customParameter.getValue()
            if value then
                tangent.sendParameterValue(paramID, value)
            end
        end
    end,

    [tangent.fromHub.transport] = function(metadata)
        -- TODO: FCPX specific code should not be in `core`.
        if fcp:isFrontmost() then
            if metadata.jogValue == 1 then
                fcp:menuBar():selectMenu({"Mark", "Next", "Frame"})
            elseif metadata.jogValue == -1 then
                fcp:menuBar():selectMenu({"Mark", "Previous", "Frame"})
            end
        end
    end,

    [tangent.fromHub.menuChange] = function(metadata)
        log.df("Menu Change: %#010x; %d", metadata.menuID, metadata.increment)
    end,

    [tangent.fromHub.menuReset] = function(metadata)
        log.df("Menu Reset: %#010x", metadata.menuID)
    end,

    [tangent.fromHub.menuStringRequest] = function(metadata)
        log.df("Menu String Request: %#010x; %d", metadata.menuID, metadata.increment)
    end,

    [tangent.fromHub.modeChange] = function(metadata)
        local activeGroup = mod.activeGroup()
        local modeID = metadata and metadata.modeID

        if activeGroup and modeID then
            local tangentID = getTangentIDFromGroupID(activeGroup)
            if modeID ~= tangentID then
                local currentSubGroup = mod.currentSubGroup()
                currentSubGroup[activeGroup] = modeID
                mod.currentSubGroup(currentSubGroup)
                --log.df("SAVING SUBGROUP: %s, %s", activeGroup, modeID)
            end

            --------------------------------------------------------------------------------
            -- Tell Tangent to Change Mode:
            --------------------------------------------------------------------------------
            tangent.sendModeValue(modeID)
        end
    end,

    [tangent.fromHub.connected] = function(metadata)
        log.df("Connection To Tangent Hub (%s:%s) successfully established.", metadata.ipAddress, metadata.port)
    end,

    [tangent.fromHub.disconnected] = function(metadata)
        log.df("Connection To Tangent Hub (%s:%s) closed.", metadata.ipAddress, metadata.port)
    end,
}

--- plugins.core.tangent.manager.callback(id, metadata) -> none
--- Function
--- Tangent Manager Callback Function
---
--- Parameters:
---  * commands - A table of Tangent commands.
---
--- Returns:
---  * None
function mod.callback(commands)

    --------------------------------------------------------------------------------
    -- Process each individual command in the callback table:
    --------------------------------------------------------------------------------
    for _, command in ipairs(commands) do

        local id = command.id
        local metadata = command.metadata

        local fn = fromHub[id]
        if fn then
            fn(metadata)
        else
            log.ef("Unexpected Tangent Message Recieved:\nid: %s, metadata: %s", id, metadata and inspect(metadata))
            if id == "connected" then
                --------------------------------------------------------------------------------
                -- Connected:
                --------------------------------------------------------------------------------
                log.df("Connection To Tangent Hub successfully established.")

            end
        end
    end
end

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
    if tools.doesDirectoryExist("/Library/Application Support/Tangent/Hub/KeypressApps/Final Cut Pro") then
        local hideFilePath = "/Library/Application Support/Tangent/Hub/KeypressApps/hide.txt"
        if tools.doesFileExist(hideFilePath) then
            --------------------------------------------------------------------------------
            -- Read existing Hide file:
            --------------------------------------------------------------------------------
            local file = io.open(hideFilePath, "r")
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
                    local appendFile = io.open(hideFilePath, "a")
                    if appendFile then
                        appendFile:write("\nFinal Cut Pro")
                        appendFile:close()
                    else
                        log.ef("Failed to append existing Hide File for Tangent Mapper.")
                    end
                end
            else
                log.ef("Failed to read existing Hide File for Tangent Mapper.")
            end
        else
            --------------------------------------------------------------------------------
            -- Create new Hide File:
            --------------------------------------------------------------------------------
            local newFile = io.open(hideFilePath, "w")
            if newFile then
                newFile:write("Final Cut Pro")
                newFile:close()
            else
                log.ef("Failed to create new Hide File for Tangent Mapper.")
            end
        end
    else
        --log.df("Final Cut Pro preset doesn't exist in Tangent Hub.")
        return
    end
end

--- plugins.core.tangent.manager.start() -> boolean
--- Function
--- Starts the Tangent Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successfully started, otherwise `false`
function mod.start()
    if tangent.isTangentHubInstalled() then
        --------------------------------------------------------------------------------
        -- Connect to Tangent Hub:
        --------------------------------------------------------------------------------
        log.df("Connecting to Tangent Hub...")
        tangent.callback(mod.callback)
        local result, errorMessage = tangent.connect("CommandPost", mod._configPath)
        if result then
            return true
        else
            log.ef("Failed to start Tangent Support: %s", errorMessage)
            return false
        end
    else
        return false
    end
end

--- plugins.core.tangent.manager.stop() -> boolean
--- Function
--- Stops the Tangent Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    --------------------------------------------------------------------------------
    -- Disconnect from Tangent:
    --------------------------------------------------------------------------------
    tangent.disconnect()
    --log.df("Disconnected from Tangent Hub.")
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

--- plugins.core.tangent.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disables the Tangent Manager.
mod.enabled = config.prop("enableTangent", false):watch(function(enabled)
    log.df("Checking if Tangent Support is enabled...")
    if enabled then
        if not mod.areMappingsInstalled() then
            log.ef("Tangent Control and/or Mapping File doesn't exist, so disabling Tangent Support.")
            mod.enabled(false)
        else
            --------------------------------------------------------------------------------
            -- Disable "Final Cut Pro" in Tangent Hub if the preset exists:
            --------------------------------------------------------------------------------
            disableFinalCutProInTangentHub()

            --------------------------------------------------------------------------------
            -- Load Mappings:
            --------------------------------------------------------------------------------
            loadMapping()

            --------------------------------------------------------------------------------
            -- Start Module:
            --------------------------------------------------------------------------------
            mod.start()
            log.df("Tangent Support Started.")
        end
    else
        --------------------------------------------------------------------------------
        -- Stop Module:
        --------------------------------------------------------------------------------
        mod.stop()
        log.df("Tangent Support Stopped.")
    end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id          = "core.tangent.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]                         = "actionmanager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

    --------------------------------------------------------------------------------
    -- Action Manager:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Get XML Path:
    --------------------------------------------------------------------------------
    mod._pluginPath = env:pathToAbsolute("/defaultmap")
    mod._configPath = config.userConfigRootPath .. "/Tangent Settings"
    mod._backupPath = config.userConfigRootPath .. "/Tangent Settings Backups"

    --------------------------------------------------------------------------------
    -- Return Module:
    --------------------------------------------------------------------------------
    return mod

end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    mod.enabled:update()
end

return plugin
