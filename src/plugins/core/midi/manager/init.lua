--- === plugins.core.midi.manager ===
---
--- MIDI Manager Plugin.

local require = require

local log         = require("hs.logger").new("midiManager")

local fnutils     = require("hs.fnutils")
local midi        = require("hs.midi")
local timer       = require("hs.timer")

local config      = require("cp.config")
local dialog      = require("cp.dialog")
local i18n        = require("cp.i18n")
local json        = require("cp.json")
local prop        = require("cp.prop")

local controls    = require("controls")
local default     = require("default")

local doAfter     = timer.doAfter

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.midi.manager.DEFAULT_GROUP -> string
--- Constant
--- The default group.
mod.DEFAULT_GROUP = "global"

--- plugins.core.midi.manager.FILE_NAME -> string
--- Constant
--- File name of settings file.
mod.FILE_NAME = "Default.cpMIDI"

--- plugins.core.midi.manager.FOLDER_NAME -> string
--- Constant
--- Folder Name where settings file is contained.
mod.FOLDER_NAME = "MIDI Controls"

--- plugins.core.midi.manager.DEFAULT_MIDI_CONTROLS -> table
--- Constant
--- The default MIDI controls, so that the user has a starting point.
mod.DEFAULT_MIDI_CONTROLS = default

--- plugins.core.midi.manager.learningMode -> boolean
--- Variable
--- Whether or not the MIDI Manager is in learning mode.
mod.learningMode = false

--- plugins.core.midi.manager.controls -> table
--- Variable
--- Controls
mod.controls = controls

-- plugins.core.midi.manager._deviceNames -> table
-- Constant
-- MIDI Device Names.
mod._deviceNames = {}

-- plugins.core.midi.manager._virtualDevices -> table
-- Constant
-- MIDI Virtual Devices.
mod._virtualDevices = {}

-- plugins.core.midi.manager._groupStatus -> table
-- Variable
-- Group Statuses.
mod._groupStatus = {}

-- plugins.core.midi.manager._currentSubGroup -> table
-- Variable
-- Current Touch Bar Sub Group Statuses.
mod._currentSubGroup = config.prop("midiCurrentSubGroup", {})

--- plugins.core.midi.manager.numberOfSubGroups -> number
--- Variable
--- The number of Sub Groups per Touch Bar Group.
mod.numberOfSubGroups = 9

--
-- Used to prevent callback delays (sorry David, I know this is the worst possible way to do things):
--
mod._alreadyProcessingCallback  = false
mod._lastControllerNumber       = nil
mod._lastControllerValue        = nil
mod._lastControllerChannel      = nil
mod._lastTimestamp              = nil
mod._lastPitchChange            = nil

--- plugins.core.midi.manager.maxItems -> number
--- Variable
--- The maximum number of MIDI items per group.
mod.maxItems = 50

--- plugins.core.midi.manager.buttons <cp.prop: table>
--- Field
--- Contains all the saved MIDI items
mod._items = json.prop(config.userConfigRootPath, mod.FOLDER_NAME, mod.FILE_NAME, mod.DEFAULT_MIDI_CONTROLS)

--- plugins.core.midi.manager.clear() -> none
--- Function
--- Clears the MIDI items.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.clear()
    mod._items(mod.DEFAULT_MIDI_CONTROLS)
    mod.update()
end

--- plugins.core.midi.manager.updateAction(button, group, actionTitle, handlerID, action) -> none
--- Function
--- Updates a MIDI action.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---  * actionTitle - Action Title as string
---  * handlerID - Handler ID as string
---  * action - Action in a table
---
--- Returns:
---  * None
function mod.updateAction(button, group, actionTitle, handlerID, action)
    local items = mod._items()

    button = tostring(button)
    if not items[group] then
        items[group] = {}
    end
    if not items[group][button] then
        items[group][button] = {}
    end

    --------------------------------------------------------------------------------
    -- Process Stylised Text:
    --------------------------------------------------------------------------------
    if actionTitle and type(actionTitle) == "userdata" then
        actionTitle = actionTitle:convert("text")
    end

    items[group][button]["actionTitle"] = actionTitle
    items[group][button]["handlerID"] = handlerID
    items[group][button]["action"] = action

    mod._items(items)
    mod.update()
end

--- plugins.core.midi.manager.setItem(item, button, group, value) -> none
--- Function
--- Stores a MIDI item in Preferences.
---
--- Parameters:
---  * item - The item you want to set.
---  * button - Button ID as string
---  * group - Group ID as string
---  * value - The value of the item you want to set.
---
--- Returns:
---  * None
function mod.setItem(item, button, group, value)
    local items = mod._items()

    button = tostring(button)

    if not items[group] then
        items[group] = {}
    end
    if not items[group][button] then
        items[group][button] = {}
    end
    items[group][button][item] = value

    mod._items(items)
    mod.update()
end

--- plugins.core.midi.manager.getItem(item, button, group) -> table
--- Function
--- Gets a MIDI item from Preferences.
---
--- Parameters:
---  * item - The item you want to get.
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * A table otherwise `nil`
function mod.getItem(item, button, group)
    local items = mod._items()
    if items[group] and items[group][button] and items[group][button][item] then
        return items[group][button][item]
    else
        return nil
    end
end

--- plugins.core.midi.manager.getItems() -> tables
--- Function
--- Gets all the MIDI items in a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.getItems()
    return mod._items()
end

--- plugins.core.midi.manager.activeGroup() -> string
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
    return mod.DEFAULT_GROUP
end

--- plugins.core.midi.manager.activeSubGroup() -> string
--- Function
--- Returns the active sub-group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns the active sub group as string
function mod.activeSubGroup()
    local currentSubGroup = mod._currentSubGroup()
    local result = 1
    local activeGroup = mod.activeGroup()
    if currentSubGroup[activeGroup] then
        result = currentSubGroup[activeGroup]
    end
    return tostring(result)
end

--- plugins.core.midi.manager.forceGroupChange(combinedGroupAndSubGroupID) -> none
--- Function
--- Loads a specific sub-group.
---
--- Parameters:
---  * combinedGroupAndSubGroupID - The group and subgroup as a single string.
---
--- Returns:
---  * None
function mod.forceGroupChange(combinedGroupAndSubGroupID, notify)
    if combinedGroupAndSubGroupID then
        local group = string.sub(combinedGroupAndSubGroupID, 1, -2)
        local subGroup = string.sub(combinedGroupAndSubGroupID, -1)
        if group and subGroup then
            local currentSubGroup = mod._currentSubGroup()
            currentSubGroup[group] = tonumber(subGroup)
            mod._currentSubGroup(currentSubGroup)
        end
        if notify then
            dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("midi") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. group) .. " " .. subGroup)
        end
    end
end

--- plugins.core.midi.manager.gotoSubGroup() -> none
--- Function
--- Loads a specific sub-group.
---
--- Parameters:
---  * id - The ID of the sub-group.
---
--- Returns:
---  * None
function mod.gotoSubGroup(id)
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    currentSubGroup[activeGroup] = id
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.midi.manager.nextSubGroup() -> none
--- Function
--- Goes to the next sub-group for the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.nextSubGroup()
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    local currentSubGroupValue = currentSubGroup[activeGroup] or 1
    if currentSubGroupValue < mod.numberOfSubGroups then
        currentSubGroup[activeGroup] = currentSubGroupValue + 1
    else
        currentSubGroup[activeGroup] = 1
    end
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.midi.manager.previousSubGroup() -> none
--- Function
--- Goes to the previous sub-group for the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.previousSubGroup()
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    local currentSubGroupValue = currentSubGroup[activeGroup] or 1
    if currentSubGroupValue == 1 then
        currentSubGroup[activeGroup] = mod.numberOfSubGroups
    else
        currentSubGroup[activeGroup] = currentSubGroupValue - 1
    end
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.midi.manager.groupStatus(groupID, status) -> none
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

--- plugins.core.midi.manager.midiCallback(object, deviceName, commandType, description, metadata) -> none
--- Function
--- MIDI Callback
---
--- Parameters:
---  * object - The `hs.midi` userdata object
---  * deviceName - Device name as string
---  * commandType - Command Type as string
---  * description - Description as string
---  * metadata - A table containing metadata for the MIDI command
---
--- Returns:
---  * None
function mod.midiCallback(_, deviceName, commandType, _, metadata)
    --------------------------------------------------------------------------------
    -- Ignore callbacks when in learning mode:
    --------------------------------------------------------------------------------
    if mod.learningMode then
        return false
    end

    --------------------------------------------------------------------------------
    -- Get Active Group:
    --------------------------------------------------------------------------------
    local activeGroup = mod.activeGroup() .. mod.activeSubGroup()

    --------------------------------------------------------------------------------
    -- Get Items:
    --------------------------------------------------------------------------------
    local items = mod._items()

    --------------------------------------------------------------------------------
    -- Prefix Virtual Devices:
    --------------------------------------------------------------------------------
    if metadata.isVirtual == true then
        deviceName = "virtual_" .. deviceName
    end

    --------------------------------------------------------------------------------
    -- Support 14bit Control Change Messages:
    --------------------------------------------------------------------------------
    local controllerValue = metadata.controllerValue
    if metadata.fourteenBitCommand then
        controllerValue = metadata.fourteenBitValue
    end

    --------------------------------------------------------------------------------
    -- The loop of doom. Sorry David. I know you'll eventually want to completely
    -- re-write this. Apologies!!
    --------------------------------------------------------------------------------
    if items[activeGroup] then
        for _, item in pairs(items[activeGroup]) do
            if deviceName == item.device and item.channel == metadata.channel and item.commandType == commandType then
                --------------------------------------------------------------------------------
                -- Note On:
                --------------------------------------------------------------------------------
                if commandType == "noteOn" and metadata.velocity ~= 0 then
                    if tostring(item.number) == tostring(metadata.note) then
                        if item.handlerID and item.action then
                            local handler = mod._actionmanager.getHandler(item.handlerID)
                            handler:execute(item.action)
                        end
                        return
                    end
                --------------------------------------------------------------------------------
                -- Control Change:
                --------------------------------------------------------------------------------
                elseif commandType == "controlChange" then
                    if tostring(item.number) == tostring(metadata.controllerNumber) then
                        if item.handlerID and string.sub(item.handlerID, -13) and string.sub(item.handlerID, -13) == "_midicontrols" then
                            --------------------------------------------------------------------------------
                            -- MIDI Controls:
                            --------------------------------------------------------------------------------
                            local id = item.action.id
                            local control = controls:get(id)
                            local params = control:params()
                            if mod._alreadyProcessingCallback then
                                if mod._lastControllerNumber == metadata.controllerNumber and mod._lastControllerChannel == metadata.channel then
                                    if mod._lastControllerValue == controllerValue then
                                        return
                                    else
                                        doAfter(0, function()
                                            if metadata.timestamp == mod._lastTimestamp then
                                                local ok, result = xpcall(function() params.fn(metadata, deviceName) end, debug.traceback)
                                                if not ok then
                                                    log.ef("Error while processing MIDI Callback: %s", result)
                                                end
                                                mod._alreadyProcessingCallback = false
                                            end
                                        end)
                                    end
                                end
                                mod._lastTimestamp = metadata and metadata.timestamp
                            else
                                mod._alreadyProcessingCallback = true
                                doAfter(0, function()
                                    local ok, result = xpcall(function() params.fn(metadata, deviceName) end, debug.traceback)
                                    if not ok then
                                        log.ef("Error while processing MIDI Callback: %s", result)
                                    end
                                    mod._alreadyProcessingCallback = false
                                end)
                                mod._lastControllerNumber = metadata and metadata.controllerNumber
                                mod._lastControllerValue = metadata and controllerValue
                                mod._lastControllerChannel = metadata and metadata.channel
                            end
                        elseif tostring(item.value) == tostring(controllerValue) then
                            if item.handlerID and item.action then
                                local handler = mod._actionmanager.getHandler(item.handlerID)
                                handler:execute(item.action)
                            end
                            return
                        end
                    end
                --------------------------------------------------------------------------------
                -- Pitch Wheel Change:
                --------------------------------------------------------------------------------
                elseif commandType == "pitchWheelChange" then
                    if item.handlerID and string.sub(item.handlerID, -13) and string.sub(item.handlerID, -13) == "_midicontrols" then
                        --------------------------------------------------------------------------------
                        -- MIDI Controls for Pitch Wheel:
                        --------------------------------------------------------------------------------
                        local id = item.action.id
                        local control = controls:get(id)
                        local params = control:params()
                        if mod._alreadyProcessingCallback then
                            if mod._lastControllerChannel == metadata.channel then
                                if mod._lastPitchChange == metadata.pitchChange then
                                    return
                                else
                                    doAfter(0, function()
                                        if metadata.timestamp == mod._lastTimestamp then
                                            local ok, result = xpcall(function() params.fn(metadata, deviceName) end, debug.traceback)
                                            if not ok then
                                                log.ef("Error while processing MIDI Callback: %s", result)
                                            end
                                            mod._alreadyProcessingCallback = false
                                        end
                                    end)
                                end
                            end
                            mod._lastTimestamp = metadata and metadata.timestamp
                        else
                            mod._alreadyProcessingCallback = true
                            doAfter(0, function()
                                local ok, result = xpcall(function() params.fn(metadata, deviceName) end, debug.traceback)
                                if not ok then
                                    log.ef("Error while processing MIDI Callback: %s", result)
                                end
                                mod._alreadyProcessingCallback = false
                            end)
                            mod._lastPitchChange = metadata and metadata.pitchChange
                            mod._lastControllerChannel = metadata and metadata.channel
                        end
                    elseif item.handlerID and item.action then
                        --------------------------------------------------------------------------------
                        -- Just trigger the handler if Pitch Wheel value changes at all:
                        --------------------------------------------------------------------------------
                        local handler = mod._actionmanager.getHandler(item.handlerID)
                        handler:execute(item.action)
                        return
                    end
                end
            end
        end
    end
end

--- plugins.core.midi.manager.devices() -> table
--- Function
--- Gets a table of Physical MIDI Device Names.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of Physical MIDI Device Names.
function mod.devices()
    return mod._deviceNames
end

--- plugins.core.midi.manager.virtualDevices() -> table
--- Function
--- Gets a table of Virtual MIDI Source Names.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of Virtual MIDI Source Names.
function mod.virtualDevices()
    return mod._virtualDevices
end

--- plugins.core.midi.manager.getDevice(deviceName, virtual) -> hs.midi object | nil
--- Function
--- Gets a MIDI Device.
---
--- Parameters:
---  * deviceName - The device name.
---  * virtual - A boolean that defines whether or not the device is virtual.
---
--- Returns:
---  * A `hs.midi` object or nil if no MIDI device by that name exists.
function mod.getDevice(deviceName, virtual)
    if virtual then
        deviceName = "virtual_" .. deviceName
    end
    return mod._midiDevices and mod._midiDevices[deviceName]
end

--- plugins.core.midi.manager.start() -> boolean
--- Function
--- Starts the MIDI Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    if not mod._midiDevices then
        mod._midiDevices = {}
    end

    --------------------------------------------------------------------------------
    -- For performance, we only use watchers for USED devices:
    --------------------------------------------------------------------------------
    local items = mod._items()
    local usedDevices = {}
    for _, v in pairs(items) do
        for _, vv in pairs(v) do
            table.insert(usedDevices, vv.device)
        end
    end

    --------------------------------------------------------------------------------
    -- Create a table of both Physical & Virtual MIDI Devices:
    --------------------------------------------------------------------------------
    local devices = {}
    for _, v in pairs(mod.devices()) do
        table.insert(devices, v)
    end
    for _, v in pairs(mod.virtualDevices()) do
        table.insert(devices, "virtual_" .. v)
    end

    --------------------------------------------------------------------------------
    -- Create MIDI Watchers for MIDI Devices that have actions assigned to them:
    --------------------------------------------------------------------------------
    for _, deviceName in ipairs(devices) do
        if not mod._midiDevices[deviceName] then
            if fnutils.contains(usedDevices, deviceName) then
                if string.sub(deviceName, 1, 8) == "virtual_" then
                    --log.df("Creating new Virtual MIDI Source Watcher: %s", deviceName)
                    mod._midiDevices[deviceName] = midi.newVirtualSource(string.sub(deviceName, 9))
                    if mod._midiDevices[deviceName] then
                        mod._midiDevices[deviceName]:callback(mod.midiCallback)
                    end
                else
                    --log.df("Creating new Physical MIDI Watcher: %s", deviceName)
                    mod._midiDevices[deviceName] = midi.new(deviceName)
                    if mod._midiDevices[deviceName] then
                        mod._midiDevices[deviceName]:callback(mod.midiCallback)
                    end
                end
            end
        end
    end
end

--- plugins.core.midi.manager.start() -> boolean
--- Function
--- Stops the MIDI Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    if mod._midiDevices and type(mod._midiDevices) == "table" then
        for _, id in pairs(mod._midiDevices) do
            mod._midiDevices[id] = nil
        end
        mod._midiDevices = nil
    end
end

--- plugins.core.midi.manager.update() -> none
--- Function
--- Updates the MIDI Watchers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        mod.start()
    else
        mod.stop()
    end
end

--- plugins.core.midi.manager.numberOfMidiDevices -> <cp.prop: number>
--- Field
--- Total number of MIDI Devices detected (including both physical and virtual).
mod.numberOfMidiDevices = prop.THIS(0)

--- plugins.core.midi.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable MIDI Support.
mod.enabled = config.prop("enableMIDI", false):watch(function() mod.update() end)

--- plugins.core.midi.manager.init(deps, env) -> none
--- Function
--- Initialises the MIDI Plugin
---
--- Parameters:
---  * deps - Dependencies Table
---  * env - Environment Table
---
--- Returns:
---  * None
function mod.init(deps)
    mod._actionmanager = deps.actionmanager
    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id          = "core.midi.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.commands.global"]            = "global",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Setup MIDI Device Callback:
    --
    -- This callback needs to be setup, regardless of whether MIDI controls are
    -- enabled or not so that we can refresh the MIDI Preferences panel if a MIDI
    -- device is added or removed.
    --------------------------------------------------------------------------------
    midi.deviceCallback(function(devices, virtualDevices)
        --log.df("MIDI Devices Updated (%s physical, %s virtual, %s total)", #devices, #virtualDevices, #devices + #virtualDevices)
        mod._deviceNames = devices
        mod._virtualDevices = virtualDevices
        mod.numberOfMidiDevices(#devices + #virtualDevices)
    end)

    --------------------------------------------------------------------------------
    -- Get list of MIDI devices:
    --------------------------------------------------------------------------------
    mod._deviceNames = midi.devices() or {}

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("cpMIDI")
        :whenActivated(mod.toggle)
        :groupedBy("commandPost")

    return mod.init(deps, env)
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)

    --------------------------------------------------------------------------------
    -- Copy Legacy Property List MIDI Controls to JSON:
    --------------------------------------------------------------------------------
    local legacyControls = config.get("midiControls", nil)
    if legacyControls and not config.get("midiControlsCopied") then
        mod._items(legacyControls)
        log.df("Copied Legacy MIDI Controls from Plist to JSON.")
        config.set("midiControlsCopied", true)
    end

    --------------------------------------------------------------------------------
    -- Setup Actions:
    --------------------------------------------------------------------------------
    mod._handlers = {}
    local controlGroups = controls.allGroups()
    for _, groupID in pairs(controlGroups) do
        mod._handlers[groupID] = deps.actionmanager.addHandler(groupID .. "_" .. "midicontrols", groupID)
            :onChoices(function(choices)
                --------------------------------------------------------------------------------
                -- Choices:
                --------------------------------------------------------------------------------
                local allControls = controls:getAll()
                for _, control in pairs(allControls) do

                    local id = control:id()
                    local params = control:params()

                    local action = {
                        id      = id,
                    }

                    if params.group == groupID then
                        choices:add(params.text)
                            :subText(params.subText)
                            :params(action)
                            :id(id)
                    end

                end
                return choices
            end)
            :onExecute(function() end)
            :onActionId(function() return "midiControls" end)
    end

    --------------------------------------------------------------------------------
    -- Start Plugin:
    --------------------------------------------------------------------------------
    mod.enabled:update()

end

return plugin
