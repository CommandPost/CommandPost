--- === plugins.core.midi.manager ===
---
--- MIDI Manager Plugin.

local require = require

local log         = require "hs.logger".new "midiManager"

local fnutils     = require "hs.fnutils"
local midi        = require "hs.midi"
local timer       = require "hs.timer"

local config      = require "cp.config"
local dialog      = require "cp.dialog"
local i18n        = require "cp.i18n"
local json        = require "cp.json"
local prop        = require "cp.prop"

local controls    = require "controls"
local default     = require "default"

local doAfter     = timer.doAfter

local mod = {}

--- plugins.core.midi.manager.DEFAULT_GROUP -> string
--- Constant
--- The default group.
mod.DEFAULT_GROUP = "global"

--- plugins.core.midi.manager.DEFAULT_MIDI_CONTROLS -> table
--- Constant
--- The default MIDI controls, so that the user has a starting point.
mod.DEFAULT_MIDI_CONTROLS = default

-- midiActions -> table
-- Variable
-- A table of all the MIDI actions.
local midiActions = {}

-- cachedActiveGroupAndSubgroup -> string
-- Variable
-- The current active group and subgroup (i.e. "fcpx1").
local cachedActiveGroupAndSubgroup

-- cachedLoupedeckActiveGroupAndSubgroup -> string
-- Variable
-- The current active group and subgroup (i.e. "fcpx1").
local cachedLoupedeckActiveGroupAndSubgroup

--- plugins.core.midi.manager.learningMode -> boolean
--- Variable
--- Whether or not the MIDI Manager is in learning mode.
mod.learningMode = false

--- plugins.core.midi.manager.controls -> table
--- Variable
--- Controls
mod.controls = controls

-- plugins.core.midi.manager._deviceNames -> table
-- Variable
-- MIDI Device Names.
mod._deviceNames = {}

-- plugins.core.midi.manager._virtualDevices -> table
-- Variable
-- MIDI Virtual Devices.
mod._virtualDevices = {}

-- plugins.core.midi.manager._groupStatus -> table
-- Variable
-- Group Statuses.
mod._groupStatus = {}

-- plugins.core.midi.manager._currentSubGroup -> table
-- Variable
-- Current MIDI Sub Group Statuses.
mod._currentSubGroup = config.prop("midiCurrentSubGroup", {})

-- plugins.core.midi.manager._currentSubGroup -> table
-- Variable
-- Current Loupedeck+ Sub Group Statuses.
mod._currentLoupedeckSubGroup = config.prop("loupedeck.currentSubGroup", {})

--- plugins.core.midi.manager.numberOfSubGroups -> number
--- Variable
--- The number of Sub Groups per Touch Bar Group.
mod.numberOfSubGroups = 9

--- plugins.core.midi.manager.maxItems -> number
--- Variable
--- The maximum number of MIDI items per group.
mod.maxItems = 100

-- convertPreferencesToMIDIActions() -> none
-- Function
-- Reads the MIDI & Loupedeck Preferences files and converts them into a MIDI Actions
-- table which is easier to process in our MIDI callback code.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function convertPreferencesToMIDIActions()
    --------------------------------------------------------------------------------
    --
    -- When the items table is updated, we also update the midiActions table for
    -- faster processing in the MIDI callback.
    --
    -- midiActions[group][deviceName][channel][commandType][controllerNumber] -> OPTIONAL: [controllerValue]
    --
    --------------------------------------------------------------------------------
    midiActions = nil
    midiActions = {}
    local items = mod._items()
    for groupID, group in pairs(items) do
        for _, button in pairs(group) do
            if button.device and button.channel and button.commandType and button.commandType == "pitchWheelChange" then
                if not midiActions[groupID] then
                    midiActions[groupID] = {}
                end
                if not midiActions[groupID][button.device] then
                    midiActions[groupID][button.device] = {}
                end
                if not midiActions[groupID][button.device][button.channel] then
                    midiActions[groupID][button.device][button.channel] = {}
                end
                if not midiActions[groupID][button.device][button.channel][button.commandType] then
                    midiActions[groupID][button.device][button.channel][button.commandType] = {}
                end
                if button.action and button.handlerID and string.sub(button.handlerID, -13) == "_midicontrols" then
                    if type(button.action) == "table" then
                        if not midiActions[groupID][button.device][button.channel][button.commandType]["action"] then
                            midiActions[groupID][button.device][button.channel][button.commandType]["action"] = {}
                        end
                        for id, value in pairs(button.action) do
                            midiActions[groupID][button.device][button.channel][button.commandType]["action"][id] = value
                        end
                    elseif type(button.action) == "string" then
                        midiActions[groupID][button.device][button.channel][button.commandType]["action"] = button.action
                    end
                    if button.handlerID then
                        midiActions[groupID][button.device][button.channel][button.commandType]["handlerID"] = button.handlerID
                    end
                end
            elseif button.device and button.channel and button.commandType and button.number and button.action then
                if type(button.number) == "string" then
                    button.number = tonumber(button.number)
                end
                if not midiActions[groupID] then
                    midiActions[groupID] = {}
                end
                if not midiActions[groupID][button.device] then
                    midiActions[groupID][button.device] = {}
                end
                if not midiActions[groupID][button.device][button.channel] then
                    midiActions[groupID][button.device][button.channel] = {}
                end
                if not midiActions[groupID][button.device][button.channel][button.commandType] then
                    midiActions[groupID][button.device][button.channel][button.commandType] = {}
                end
                if not midiActions[groupID][button.device][button.channel][button.commandType][button.number] then
                    midiActions[groupID][button.device][button.channel][button.commandType][button.number] = {}
                end
                if button.value and button.value ~= i18n("none") and button.handlerID and string.sub(button.handlerID, -13) ~= "_midicontrols" then
                    if button.action then
                        if not midiActions[groupID][button.device][button.channel][button.commandType][button.number][button.value] then
                            midiActions[groupID][button.device][button.channel][button.commandType][button.number][button.value] = {}
                        end
                        if type(button.action) == "table" then
                            if not midiActions[groupID][button.device][button.channel][button.commandType][button.number][button.value]["action"] then
                                midiActions[groupID][button.device][button.channel][button.commandType][button.number][button.value]["action"] = {}
                            end
                            for id, value in pairs(button.action) do
                                midiActions[groupID][button.device][button.channel][button.commandType][button.number][button.value]["action"][id] = value
                            end
                        elseif type(button.action) == "string" then
                            midiActions[groupID][button.device][button.channel][button.commandType][button.number][button.value]["action"] = button.action
                        end

                        if button.handlerID then
                            midiActions[groupID][button.device][button.channel][button.commandType][button.number][button.value]["handlerID"] = button.handlerID
                        end
                    end
                else
                    if button.action then
                        if type(button.action) == "table" then
                            if not midiActions[groupID][button.device][button.channel][button.commandType][button.number]["action"] then
                                midiActions[groupID][button.device][button.channel][button.commandType][button.number]["action"] = {}
                            end
                            for id, value in pairs(button.action) do
                                midiActions[groupID][button.device][button.channel][button.commandType][button.number]["action"][id] = value
                            end
                        elseif type(button.action) == "string" then
                            midiActions[groupID][button.device][button.channel][button.commandType][button.number]["action"] = button.action
                        end
                        if button.handlerID then
                            midiActions[groupID][button.device][button.channel][button.commandType][button.number]["handlerID"] = button.handlerID
                        end
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Loupedeck+ Support:
    --------------------------------------------------------------------------------
    local loupedeckItems = mod._loupedeckItems()
    for groupID, group in pairs(loupedeckItems) do
        for buttonID, button in pairs(group) do
            if button.action then
                --------------------------------------------------------------------------------
                -- Press Button:
                --------------------------------------------------------------------------------
                if string.sub(buttonID, -5) == "Press" then
                    local number = tonumber(string.sub(buttonID, 0, -6))
                    if not midiActions[groupID] then
                        midiActions[groupID] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"] then
                        midiActions[groupID]["Loupedeck+"] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0] then
                        midiActions[groupID]["Loupedeck+"][0] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0]["noteOn"] then
                        midiActions[groupID]["Loupedeck+"][0]["noteOn"] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0]["noteOn"][number] then
                        midiActions[groupID]["Loupedeck+"][0]["noteOn"][number] = {}
                    end
                    if type(button.action) == "table" then
                        if not midiActions[groupID]["Loupedeck+"][0]["noteOn"][number]["action"] then
                            midiActions[groupID]["Loupedeck+"][0]["noteOn"][number]["action"] = {}
                        end
                        for id, value in pairs(button.action) do
                            midiActions[groupID]["Loupedeck+"][0]["noteOn"][number]["action"][id] = value
                        end
                    elseif type(button.action) == "string" then
                        midiActions[groupID]["Loupedeck+"][0]["noteOn"][number]["action"] = button.action
                    end
                    if button.handlerID then
                        midiActions[groupID]["Loupedeck+"][0]["noteOn"][number]["handlerID"] = button.handlerID
                    end
                end

                --------------------------------------------------------------------------------
                -- Left Knob Turn:
                --------------------------------------------------------------------------------
                if string.sub(buttonID, -4) == "Left" then
                    local number = tonumber(string.sub(buttonID, 0, -5))
                    if not midiActions[groupID] then
                        midiActions[groupID] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"] then
                        midiActions[groupID]["Loupedeck+"] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0] then
                        midiActions[groupID]["Loupedeck+"][0] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0]["controlChange"] then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0]["controlChange"][number] then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"][number] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][127] then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][127] = {}
                    end
                    if type(button.action) == "table" then
                        if not midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][127]["action"] then
                            midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][127]["action"] = {}
                        end
                        for id, value in pairs(button.action) do
                            midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][127]["action"][id] = value
                        end
                    elseif type(button.action) == "string" then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][127]["action"] = button.action
                    end
                    if button.handlerID then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][127]["handlerID"] = button.handlerID
                    end
                end

                --------------------------------------------------------------------------------
                -- Right Knob Turn:
                --------------------------------------------------------------------------------
                if string.sub(buttonID, -5) == "Right" then
                    local number = tonumber(string.sub(buttonID, 0, -6))
                    if not midiActions[groupID] then
                        midiActions[groupID] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"] then
                        midiActions[groupID]["Loupedeck+"] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0] then
                        midiActions[groupID]["Loupedeck+"][0] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0]["controlChange"] then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0]["controlChange"][number] then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"][number] = {}
                    end
                    if not midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][1] then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][1] = {}
                    end
                    if type(button.action) == "table" then
                        if not midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][1]["action"] then
                            midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][1]["action"] = {}
                        end
                        for id, value in pairs(button.action) do
                            midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][1]["action"][id] = value
                        end
                    elseif type(button.action) == "string" then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][1]["action"] = button.action
                    end
                    if button.handlerID then
                        midiActions[groupID]["Loupedeck+"][0]["controlChange"][number][1]["handlerID"] = button.handlerID
                    end
                end
            end
        end
    end

end

-- plugins.core.midi.manager._loupedeckItems <cp.prop: table>
-- Field
-- Contains all the saved MIDI Loupedeck+ items
mod._loupedeckItems = json.prop(config.userConfigRootPath, "Loupedeck", "Default.cpLoupedeck", {}):watch(convertPreferencesToMIDIActions)

-- plugins.core.midi.manager._items <cp.prop: table>
-- Field
-- Contains all the saved MIDI items
mod._items = json.prop(config.userConfigRootPath, "MIDI Controls", "Default.cpMIDI", mod.DEFAULT_MIDI_CONTROLS):watch(convertPreferencesToMIDIActions)

-- updateCachedActiveGroupAndSubgroup() -> none
-- Function
-- Updates the cachedActiveGroupAndSubgroup variable.
local function updateCachedActiveGroupAndSubgroup()
    cachedActiveGroupAndSubgroup = mod.activeGroup() .. mod.activeSubGroup()
end

-- updateLoupedeckCachedActiveGroupAndSubgroup() -> none
-- Function
-- Updates the cachedLoupedeckActiveGroupAndSubgroup variable.
local function updateLoupedeckCachedActiveGroupAndSubgroup()
    cachedLoupedeckActiveGroupAndSubgroup = mod.activeGroup() .. mod.activeLoupdeckSubGroup()
end

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

--- plugins.core.midi.manager.activeSubGroup() -> string
--- Function
--- Returns the active sub-group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns the active sub group as string
function mod.activeLoupdeckSubGroup()
    local currentSubGroup = mod._currentLoupedeckSubGroup()
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
        updateCachedActiveGroupAndSubgroup()
    end
end

--- plugins.core.midi.manager.forceLoupedeckGroupChange(combinedGroupAndSubGroupID) -> none
--- Function
--- Loads a specific sub-group.
---
--- Parameters:
---  * combinedGroupAndSubGroupID - The group and subgroup as a single string.
---
--- Returns:
---  * None
function mod.forceLoupedeckGroupChange(combinedGroupAndSubGroupID, notify)
    if combinedGroupAndSubGroupID then
        local group = string.sub(combinedGroupAndSubGroupID, 1, -2)
        local subGroup = string.sub(combinedGroupAndSubGroupID, -1)
        if group and subGroup then
            local currentSubGroup = mod._currentLoupedeckSubGroup()
            currentSubGroup[group] = tonumber(subGroup)
            mod._currentLoupedeckSubGroup(currentSubGroup)
        end
        if notify then
            dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("loupedeckPlus") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. group) .. " " .. subGroup)
        end
        updateLoupedeckCachedActiveGroupAndSubgroup()
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
    updateCachedActiveGroupAndSubgroup()
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
    updateCachedActiveGroupAndSubgroup()
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
    updateCachedActiveGroupAndSubgroup()
end

--- plugins.core.midi.manager.gotoLoupedeckSubGroup() -> none
--- Function
--- Loads a specific sub-group.
---
--- Parameters:
---  * id - The ID of the sub-group.
---
--- Returns:
---  * None
function mod.gotoLoupedeckSubGroup(id)
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentLoupedeckSubGroup()
    currentSubGroup[activeGroup] = id
    mod._currentLoupedeckSubGroup(currentSubGroup)
    updateLoupedeckCachedActiveGroupAndSubgroup()
end

--- plugins.core.midi.manager.nextLoupedeckSubGroup() -> none
--- Function
--- Goes to the next sub-group for the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.nextLoupedeckSubGroup()
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentLoupedeckSubGroup()
    local currentSubGroupValue = currentSubGroup[activeGroup] or 1
    if currentSubGroupValue < mod.numberOfSubGroups then
        currentSubGroup[activeGroup] = currentSubGroupValue + 1
    else
        currentSubGroup[activeGroup] = 1
    end
    mod._currentLoupedeckSubGroup(currentSubGroup)
    updateLoupedeckCachedActiveGroupAndSubgroup()
end

--- plugins.core.midi.manager.previousLoupedeckSubGroup() -> none
--- Function
--- Goes to the previous sub-group for the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.previousLoupedeckSubGroup()
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentLoupedeckSubGroup()
    local currentSubGroupValue = currentSubGroup[activeGroup] or 1
    if currentSubGroupValue == 1 then
        currentSubGroup[activeGroup] = mod.numberOfSubGroups
    else
        currentSubGroup[activeGroup] = currentSubGroupValue - 1
    end
    mod._currentLoupedeckSubGroup(currentSubGroup)
    updateLoupedeckCachedActiveGroupAndSubgroup()
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
    updateCachedActiveGroupAndSubgroup()
    updateLoupedeckCachedActiveGroupAndSubgroup()
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

    log.df("commandType: %s", commandType)
    log.df("metadata: %s", hs.inspect(metadata))

    if mod.learningMode then
        return
    end

    local group = cachedActiveGroupAndSubgroup

    if deviceName == "Loupedeck+" then
        group = cachedLoupedeckActiveGroupAndSubgroup
    end

    local channel = metadata.channel
    local controllerNumber = metadata.controllerNumber or metadata.note
    local controllerValue = metadata.controllerValue

    if metadata.fourteenBitCommand then
        controllerValue = metadata.fourteenBitValue
    end

    if metadata.isVirtual then
        deviceName = "virtual_" .. deviceName
    end

    if midiActions
    and midiActions[group]
    and midiActions[group][deviceName]
    and midiActions[group][deviceName][channel]
    and midiActions[group][deviceName][channel][commandType] then
        if commandType == "pitchWheelChange" then
            --------------------------------------------------------------------------------
            -- Pitch Wheel Change doesn't have a controllerNumber:
            --------------------------------------------------------------------------------
            local v = midiActions[group][deviceName][channel][commandType]
            if v.handlerID and string.sub(v.handlerID, -13) == "_midicontrols" then
                doAfter(0, function()
                    local id = v.action.id
                    local control = controls:get(id)
                    if control then
                        local params = control:params()
                        if params then
                            local ok, result = xpcall(function() params.fn(metadata, deviceName) end, debug.traceback)
                            if not ok then
                                log.ef("Error while processing MIDI Callback: %s", result)
                            end
                        end
                    end
                end)
            end
        elseif midiActions[group][deviceName][channel][commandType][controllerNumber] then
            local v
            if midiActions[group][deviceName][channel][commandType][controllerNumber][controllerValue] and midiActions[group][deviceName][channel][commandType][controllerNumber][controllerValue]["action"] then
                v = midiActions[group][deviceName][channel][commandType][controllerNumber][controllerValue]
            elseif midiActions[group][deviceName][channel][commandType][controllerNumber] and midiActions[group][deviceName][channel][commandType][controllerNumber]["action"] then
                v = midiActions[group][deviceName][channel][commandType][controllerNumber]
            end
            if v then
                if v.handlerID and string.sub(v.handlerID, -13) == "_midicontrols" then
                    doAfter(0, function()
                        local id = v.action.id
                        local control = controls:get(id)
                        if control then
                            local params = control:params()
                            if params then
                                local ok, result = xpcall(function() params.fn(metadata, deviceName) end, debug.traceback)
                                if not ok then
                                    log.ef("Error while processing MIDI Callback: %s", result)
                                end
                            end
                        end
                    end)
                elseif commandType == "pitchWheelChange" or commandType == "controlChange" or (commandType == "noteOn" and metadata.velocity ~= 0) then
                    doAfter(0, function()
                        local handler = mod._actionmanager.getHandler(v.handlerID)
                        if handler then
                            handler:execute(v.action)
                        end
                    end)
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
    -- Watch for Loupedeck+ is enabled:
    --------------------------------------------------------------------------------
    if mod.enabledLoupedeck() then
        table.insert(usedDevices, "Loupedeck+")
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

--- plugins.core.midi.manager.stop() -> boolean
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
    if mod.enabled() or mod.enabledLoupedeck() then
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

--- plugins.core.midi.manager.enabledLoupedeck <cp.prop: boolean>
--- Field
--- Enable or disable MIDI Loupedeck Support.
mod.enabledLoupedeck = config.prop("enableLoupedeck", false):watch(function() mod.update() end)

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
        :whenActivated(mod.enabled:toggle())
        :groupedBy("commandPost")

    return mod.init(deps, env)
end

function plugin.postInit(deps)
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
    mod._items:update()

    --------------------------------------------------------------------------------
    -- Update "Bank" caches:
    --------------------------------------------------------------------------------
    updateCachedActiveGroupAndSubgroup()
    updateLoupedeckCachedActiveGroupAndSubgroup()
end

return plugin
