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
local require                                   = require

local log                                       = require("hs.logger").new("tangentMan")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fs                                        = require("hs.fs")
local inspect                                   = require("hs.inspect")
local tangent                                   = require("hs.tangent")
local timer                                     = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")
local x                                         = require("cp.web.xml")
local prop                                      = require("cp.prop")

local mode                                      = require("mode")
local controls                                  = require("controls")
local action                                    = require("action")
local parameter                                 = require("parameter")
local menu                                      = require("menu")

local insert, sort                              = table.insert, table.sort

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

-- plugins.core.touchbar.manager._modes -> table
-- Variable
-- Modesf
mod._modes = {}

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

--- plugins.core.tangent.manager.controls
--- Constant
--- The set of controls currently registered.
mod.controls = controls.new()

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
    local controlsFile = io.open(mod._configPath .. "/controls.xml", "w")
    if controlsFile then

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
            -- Default Global Settings:
            --------------------------------------------------------------------------------
            x.DefaultGlobalSettings (
                x.KnobSensitivity { std = 5, alt = 5 } ..
                x.JogDialSensitivity { std = 5, alt = 5 } ..
                x.TrackerballSensitivity { std = 5, alt = 5 } ..
                x.TrackerballDialSensitivity { std = 5, alt = 5 } ..
                x.IndependentPanelBanks { enabled = false }
            ) ..

            --------------------------------------------------------------------------------
            -- Modes:
            --------------------------------------------------------------------------------
            x.Modes (function()
                local modes = x()

                for _,m in ipairs(mod._modes) do
                    modes = modes .. m:xml()
                end

                return modes
            end) ..

            mod.controls:xml()

        )

        local output = x._xml() .. root

        --------------------------------------------------------------------------------
        -- Write to File & Close:
        --------------------------------------------------------------------------------
        io.output(controlsFile)
        io.write(tostring(output))
        io.close(controlsFile)
    else
        log.ef("Failed to open controls.xml file in write mode")
        return false, "Failed to open controls.xml file in write mode"
    end
end

function mod.updateControls()
    mod.writeControlsXML()
    if mod.connected() then
        tangent.sendApplicationDefinition()
    end
end

--- plugins.core.tangent.manager.addMode(id, name) -> plugins.core.tangent.manager.mode
--- Function
--- Adds a new `mode` with the specified details and returns it.
---
--- Parameters:
--- * id            - The id number of the Mode.
--- * name          - The name of the Mode.
---
--- Returns:
--- * The new `mode`
function mod.addMode(id, name)
    local m = mode.new(id, name, mod)
    insert(mod._modes, m)
    sort(mod._modes, function(a,b) return a.name < b.name end)
    return m
end

--- plugins.core.tangent.manager.getMode(id) -> plugins.core.tangent.manager.mode
--- Function
--- Returns the `mode` with the specified ID, or `nil`.
---
--- Parameters:
--- * id    - The ID to find.
---
--- Returns:
--- * The `mode`, or `nil`.
function mod.getMode(id)
    for _,m in ipairs(mod._modes) do
        if m.id == id then
            return m
        end
    end
    return nil
end

--- plugins.core.tangent.manager.currentMode <cp.prop: mode>
--- Constant
--- Represents the currently active `mode`.
mod.currentMode = prop(
    function()
        return mod._currentMode
    end,
    function(newMode)
        log.df("currentMode: ")
        newMode = mode.is(newMode) and newMode or mod.getMode(newMode)
        mod._currentMode = newMode
        if newMode then
            tangent.sendModeValue(newMode.id)
        end
    end
)

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
    if mod.connected() then
        local currentMode = mod.currentMode()
        if currentMode then
            tangent.sendModeValue(currentMode.id)
        end
    end
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
        local control = mod.controls:findByID(metadata.actionID)
        if action.is(control) then
            control:press()
        end
    end,

    [tangent.fromHub.actionOff] = function(metadata)
        local control = mod.controls:findByID(metadata.actionID)
        if action.is(control) then
            control:release()
        end
    end,

    [tangent.fromHub.parameterChange] = function(metadata)
        local control = mod.controls:findByID(metadata.paramID)
        if parameter.is(control) then
            local newValue = control:change(metadata.increment)
            if newValue ~= nil then
                tangent.sendParameterValue(control.id, newValue)
            end
        end
    end,

    [tangent.fromHub.parameterReset] = function(metadata)
        local control = mod.controls:findByID(metadata.paramID)
        if parameter.is(control) then
            local newValue = control:reset()
            if newValue ~= nil then
                tangent.sendParameterValue(control.id, newValue)
            end
        end
    end,

    [tangent.fromHub.parameterValueRequest] = function(metadata)
        local control = mod.controls:findByID(metadata.paramID)
        if parameter.is(control) then
            local value = control:get()
            if value ~= nil then
                tangent.sendParameterValue(control.id, value)
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
        -- log.df("Menu Change: %#010x; %d", metadata.menuID, metadata.increment)
        local control = mod.controls:findByID(metadata.menuID)
        local increment = metadata.increment
        if menu.is(control) then
            if increment == 1 then
                control:next()
            elseif increment == -1 then
                control:prev()
            else
                log.ef("Unexpected 'menu change' increment from Tangent: %s", increment)
            end
            local value = control:get()
            if value ~= nil then
                tangent.sendMenuString(control.id, value)
            end
        end
    end,

    [tangent.fromHub.menuReset] = function(metadata)
        -- log.df("Menu Reset: %#010x", metadata.menuID)
        local control = mod.controls:findByID(metadata.menuID)
        if menu.is(control) then
            control:reset()
            local value = control:get()
            if value ~= nil then
                tangent.sendMenuString(control.id, value)
            end
        end
    end,

    [tangent.fromHub.menuStringRequest] = function(metadata)
        local control = mod.controls:findByID(metadata.menuID)
        if menu.is(control) then
            local value = control:get()
            if value ~= nil then
                tangent.sendMenuString(control.id, value)
            end
        end
    end,

    [tangent.fromHub.modeChange] = function(metadata)
        log.df("modeChange: called: %#010x", metadata.modeID)
        local newMode = mod.getMode(metadata.modeID)
        if newMode then
            log.df("modeChange: found mode: %#010x", newMode.id)
            local oldMode = mod.currentMode()
            if oldMode == nil or oldMode.id ~= newMode.id then
                log.df("modeChange: deactivating %s", oldMode)
                if oldMode then oldMode:deactivate() end
                log.df("modeChange: activating %s", newMode)
                newMode:activate()
            end
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
            local ok, result = xpcall(function() fn(metadata) end, debug.traceback)
            if not ok then
                log.ef("Error while processing Tangent Message: '%#010x':\n%s", id, result)
            end
        else
            log.ef("Unexpected Tangent Message Recieved:\nid: %s, metadata: %s", id, inspect(metadata))
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

function mod.connected()
    return tangent.connected()
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
    return tools.doesFileExist(mod._configPath .. "/controls.xml")
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

-- secret test function...
function mod._test(...)
    return require("all_tests")(...)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id          = "core.tangent.manager",
    group       = "core",
    required    = true,
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(_, env)

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
