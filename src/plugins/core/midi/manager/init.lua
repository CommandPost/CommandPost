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

local doAfter     = timer.doAfter

local mod = {}

--- plugins.core.midi.manager.loupedeckFnPressed -> boolean
--- Variable
--- Is the Fn key on the Loupedeck+ pressed?
mod.loupedeckFnPressed = false

-- midiActions -> table
-- Variable
-- A table of all the MIDI actions.
local midiActions = {}

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

--- plugins.core.midi.manager.numberOfBanks -> number
--- Variable
--- The number of banks per application.
mod.numberOfBanks = 9

--- plugins.core.midi.manager.maxItems -> number
--- Variable
--- The maximum number of MIDI items per bank.
mod.maxItems = 100

--- plugins.core.loupedeckct.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("midi.activeBanks", {})

--- plugins.core.loupedeckct.manager.activeLoupedeckBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeLoupedeckBanks = config.prop("loupedeckplus.activeBanks", {})

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
    -- NOTE TO FUTURE CHRIS:
    -- Why the hell do we write to the preferences file in one format, then
    -- convert it here? It seems past Chris wasn't completely crazy - the reason
    -- is because of the way the MIDI Editor is setup, it's possible to set a
    -- commandType (for example), before a channel is set. This was essentially a
    -- "hack job" to speed up MIDI performance, without breaking legacy MIDI
    -- layouts. However, in April 2020, Chris tweaked it again to add support
    -- for custom applications - separating the "group" into "bundleID" and
    -- "bankID".
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    --
    -- When the items table is updated, we also update the midiActions table for
    -- faster processing in the MIDI callback.
    --
    -- midiActions[bundleID][bankID][deviceName][channel][commandType][controllerNumber] -> OPTIONAL: [controllerValue]
    --
    --------------------------------------------------------------------------------
    midiActions = nil
    midiActions = {}
    local items = mod.items()

    for bundleID, app in pairs(items) do
        if type(app) == "table" then
            for bankID, bank in pairs(app) do
                if type(bank) == "table" then
                    for _, button in pairs(bank) do
                        if button.device and button.channel and button.commandType and button.commandType == "pitchWheelChange" then
                            if not midiActions[bundleID] then
                                midiActions[bundleID] = {}
                            end
                            if not midiActions[bundleID][bankID] then
                                midiActions[bundleID][bankID] = {}
                            end
                            if not midiActions[bundleID][bankID][button.device] then
                                midiActions[bundleID][bankID][button.device] = {}
                            end
                            if not midiActions[bundleID][bankID][button.device][button.channel] then
                                midiActions[bundleID][bankID][button.device][button.channel] = {}
                            end
                            if not midiActions[bundleID][bankID][button.device][button.channel][button.commandType] then
                                midiActions[bundleID][bankID][button.device][button.channel][button.commandType] = {}
                            end
                            if button.action and button.handlerID and string.sub(button.handlerID, -13) == "_midicontrols" then
                                if type(button.action) == "table" then
                                    if not midiActions[bundleID][bankID][button.device][button.channel][button.commandType]["action"] then
                                        midiActions[bundleID][bankID][button.device][button.channel][button.commandType]["action"] = {}
                                    end
                                    for id, value in pairs(button.action) do
                                        midiActions[bundleID][bankID][button.device][button.channel][button.commandType]["action"][id] = value
                                    end
                                elseif type(button.action) == "string" then
                                    midiActions[bundleID][bankID][button.device][button.channel][button.commandType]["action"] = button.action
                                end
                                if button.handlerID then
                                    midiActions[bundleID][bankID][button.device][button.channel][button.commandType]["handlerID"] = button.handlerID
                                end
                            end
                        elseif button.device and button.channel and button.commandType and button.number and button.action then
                            if type(button.number) == "string" then
                                button.number = tonumber(button.number)
                            end
                            if not midiActions[bundleID] then
                                midiActions[bundleID] = {}
                            end
                            if not midiActions[bundleID][bankID] then
                                midiActions[bundleID][bankID] = {}
                            end
                            if not midiActions[bundleID][bankID][button.device] then
                                midiActions[bundleID][bankID][button.device] = {}
                            end
                            if not midiActions[bundleID][bankID][button.device][button.channel] then
                                midiActions[bundleID][bankID][button.device][button.channel] = {}
                            end
                            if not midiActions[bundleID][bankID][button.device][button.channel][button.commandType] then
                                midiActions[bundleID][bankID][button.device][button.channel][button.commandType] = {}
                            end
                            if not midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number] then
                                midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number] = {}
                            end
                            if button.value and button.value ~= i18n("none") and button.handlerID and string.sub(button.handlerID, -13) ~= "_midicontrols" then
                                if button.action then
                                    if not midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number][button.value] then
                                        midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number][button.value] = {}
                                    end
                                    if type(button.action) == "table" then
                                        if not midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number][button.value]["action"] then
                                            midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number][button.value]["action"] = {}
                                        end
                                        for id, value in pairs(button.action) do
                                            midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number][button.value]["action"][id] = value
                                        end
                                    elseif type(button.action) == "string" then
                                        midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number][button.value]["action"] = button.action
                                    end

                                    if button.handlerID then
                                        midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number][button.value]["handlerID"] = button.handlerID
                                    end
                                end
                            else
                                if button.action then
                                    if type(button.action) == "table" then
                                        if not midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number]["action"] then
                                            midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number]["action"] = {}
                                        end
                                        for id, value in pairs(button.action) do
                                            midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number]["action"][id] = value
                                        end
                                    elseif type(button.action) == "string" then
                                        midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number]["action"] = button.action
                                    end
                                    if button.handlerID then
                                        midiActions[bundleID][bankID][button.device][button.channel][button.commandType][button.number]["handlerID"] = button.handlerID
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Loupedeck+ Support:
    --
    -- The P1-P8 knobs on the Loupedeck+ have different MIDI values depending on
    -- whether the 'Hue', 'Sat' or 'Lum' lights are activate and lit up. As
    -- CommandPost uses banks, as opposed to these Loupedeck+ modes, we basically
    -- just ignore whatever the lights say, and the knobs do the same thing in
    -- CommandPost regardless of what "mode" the Loupedeck+ is in.
    --------------------------------------------------------------------------------
    local loupedeckItems = mod._loupedeckItems()

    for bundleID, app in pairs(items) do
        if type(app) == "table" then
            for bankID, bank in pairs(app) do
                if type("bank") == "table" then
                    for buttonID, button in pairs(bank) do
                        if button.action then
                            --------------------------------------------------------------------------------
                            -- Press Button:
                            --------------------------------------------------------------------------------
                            if string.sub(buttonID, -5) == "Press" then
                                local original = tonumber(string.sub(buttonID, 0, -6))
                                local numbers = {original}
                                if original >= 1 and original <= 8 then
                                    numbers = {original, original + 8, original + 8 + 8, original + 8 + 8 + 8}
                                end
                                for _, number in pairs(numbers) do
                                    if not midiActions[bundleID][bankID] then
                                        midiActions[bundleID][bankID] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"] then
                                        midiActions[bundleID][bankID]["Loupedeck+"] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"][number] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"][number] = {}
                                    end
                                    if type(button.action) == "table" then
                                        if not midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"][number]["action"] then
                                            midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"][number]["action"] = {}
                                        end
                                        for id, value in pairs(button.action) do
                                            midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"][number]["action"][id] = value
                                        end
                                    elseif type(button.action) == "string" then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"][number]["action"] = button.action
                                    end
                                    if button.handlerID then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["noteOn"][number]["handlerID"] = button.handlerID
                                    end
                                end
                            end

                            --------------------------------------------------------------------------------
                            -- Left Knob Turn:
                            --------------------------------------------------------------------------------
                            if string.sub(buttonID, -4) == "Left" then
                                local original = tonumber(string.sub(buttonID, 0, -5))
                                local numbers = {original}
                                if original >= 1 and original <= 8 then
                                    numbers = {original, original + 8, original + 8 + 8, original + 8 + 8 + 8}
                                end
                                for _, number in pairs(numbers) do
                                    if not midiActions[bundleID][bankID] then
                                        midiActions[bundleID][bankID] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"] then
                                        midiActions[bundleID][bankID]["Loupedeck+"] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][127] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][127] = {}
                                    end
                                    if type(button.action) == "table" then
                                        if not midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][127]["action"] then
                                            midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][127]["action"] = {}
                                        end
                                        for id, value in pairs(button.action) do
                                            midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][127]["action"][id] = value
                                        end
                                    elseif type(button.action) == "string" then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][127]["action"] = button.action
                                    end
                                    if button.handlerID then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][127]["handlerID"] = button.handlerID
                                    end
                                end
                            end

                            --------------------------------------------------------------------------------
                            -- Right Knob Turn:
                            --------------------------------------------------------------------------------
                            if string.sub(buttonID, -5) == "Right" then
                                local original = tonumber(string.sub(buttonID, 0, -6))
                                local numbers = {original}
                                if original >= 1 and original <= 8 then
                                    numbers = {original, original + 8, original + 8 + 8, original + 8 + 8 + 8}
                                end
                                for _, number in pairs(numbers) do
                                    if not midiActions[bundleID][bankID] then
                                        midiActions[bundleID][bankID] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"] then
                                        midiActions[bundleID][bankID]["Loupedeck+"] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number] = {}
                                    end
                                    if not midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][1] then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][1] = {}
                                    end
                                    if type(button.action) == "table" then
                                        if not midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][1]["action"] then
                                            midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][1]["action"] = {}
                                        end
                                        for id, value in pairs(button.action) do
                                            midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][1]["action"][id] = value
                                        end
                                    elseif type(button.action) == "string" then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][1]["action"] = button.action
                                    end
                                    if button.handlerID then
                                        midiActions[bundleID][bankID]["Loupedeck+"][0]["controlChange"][number][1]["handlerID"] = button.handlerID
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- plugins.core.midi.manager._loupedeckItems <cp.prop: table>
-- Field
-- Contains all the saved MIDI Loupedeck+ items
mod._loupedeckItems = json.prop(config.userConfigRootPath, "Loupedeck", "Default v2.cpLoupedeck", {}):watch(convertPreferencesToMIDIActions)

-- plugins.core.midi.manager._items <cp.prop: table>
-- Field
-- Contains all the saved MIDI items
mod.items = json.prop(config.userConfigRootPath, "MIDI Controls", "Default v2.cpMIDI", {}):watch(convertPreferencesToMIDIActions)

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
    mod.items({})
    mod.update()
end

--- plugins.core.midi.manager.updateAction(button, bundleID, bankID, actionTitle, handlerID, action) -> none
--- Function
--- Updates a MIDI action.
---
--- Parameters:
---  * button - Button ID as string
---  * bundleID - The application bundle ID as string
---  * bankID - The bank ID as string
---  * actionTitle - Action Title as string
---  * handlerID - Handler ID as string
---  * action - Action in a table
---
--- Returns:
---  * None
function mod.updateAction(button, bundleID, bankID, actionTitle, handlerID, action)
    local items = mod.items()

    button = tostring(button)

    if not items[bundleID] then items[bundleID] = {} end
    if not items[bundleID][bankID] then items[bundleID][bankID] = {} end
    if not items[bundleID][bankID][button] then items[bundleID][bankID][button] = {} end

    --------------------------------------------------------------------------------
    -- Process Stylised Text:
    --------------------------------------------------------------------------------
    if actionTitle and type(actionTitle) == "userdata" then
        actionTitle = actionTitle:convert("text")
    end

    items[bundleID][bankID][button]["actionTitle"] = actionTitle
    items[bundleID][bankID][button]["handlerID"] = handlerID
    items[bundleID][bankID][button]["action"] = action

    mod.items(items)
    mod.update()
end

--- plugins.core.midi.manager.setItem(item, button, bundleID, bankID, value) -> none
--- Function
--- Stores a MIDI item in Preferences.
---
--- Parameters:
---  * item - The item you want to set.
---  * button - Button ID as string
---  * bundleID - The application bundle ID as string
---  * bankID - The bank ID as string
---  * value - The value of the item you want to set.
---
--- Returns:
---  * None
function mod.setItem(item, button, bundleID, bankID, value)
    local items = mod.items()

    button = tostring(button)

    if not items[bundleID] then items[bundleID] = {} end
    if not items[bundleID][bankID] then items[bundleID][bankID] = {} end
    if not items[bundleID][bankID][button] then items[bundleID][bankID][button] = {} end

    items[bundleID][bankID][button][item] = value

    mod.items(items)
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
function mod.getItem(item, button, bundleID, bankID)
    local items = mod.items()
    return items and items[bundleID] and items[bundleID][bankID] and items[bundleID][bankID][button] and items[bundleID][bankID][button][item]
end

--- plugins.core.midi.manager.setBankLabel(group, label) -> none
--- Function
--- Sets a MIDI Bank Label.
---
--- Parameters:
---  * group - Group ID as string
---  * label - Label as string
---
--- Returns:
---  * None
function mod.setBankLabel(bundleID, bankID, label)
    local items = mod.items()

    if not items[bundleID] then items[bundleID] = {} end
    if not items[bundleID][bankID] then items[bundleID][bankID] = {} end
    items[bundleID][bankID]["bankLabel"] = label

    mod.items(items)
    mod.update()
end

--- plugins.core.midi.manager.getBankLabel(group) -> string
--- Function
--- Returns a specific MIDI Bank Label.
---
--- Parameters:
---  * group - Group ID as string
---
--- Returns:
---  * Label as string
function mod.getBankLabel(group)
    local items = mod.items()
    return items and items[bundleID] and items[bundleID][bankID] and items[bundleID][bankID] and items[bundleID][bankID]["bankLabel"]
end

--- plugins.core.midi.manager.getLoupedeckBankLabel(group) -> string
--- Function
--- Returns a specific Loupedeck Bank Label.
---
--- Parameters:
---  * group - Group ID as string
---
--- Returns:
---  * Label as string
function mod.getLoupedeckBankLabel(group)
    local items = mod._loupedeckItems()
    return items and items[bundleID] and items[bundleID][bankID] and items[bundleID][bankID] and items[bundleID][bankID]["bankLabel"]
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
    return mod.items()
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

    if mod.learningMode then
        return
    end

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    local bankID = "1"

    if deviceName == "Loupedeck+" then
        --------------------------------------------------------------------------------
        -- Get active bank from preferences:
        --------------------------------------------------------------------------------
        local activeLoupedeckBanks = mod.activeLoupedeckBanks()
        if activeLoupedeckBanks[bundleID] then
            bankID = activeLoupedeckBanks[bundleID]
        end

        --------------------------------------------------------------------------------
        -- Treat the "Fn" key as a modifier and adjust the group accordingly:
        --------------------------------------------------------------------------------
        if metadata.note and metadata.note == 110 and metadata.channel and metadata.channel == 0 then
            if commandType == "noteOn" then
                mod.loupedeckFnPressed = true
            elseif commandType == "noteOff" then
                mod.loupedeckFnPressed = false
            end
        end
        if mod.loupedeckFnPressed then
            group = group .. "fn"
        end
    else
        --------------------------------------------------------------------------------
        -- Get active bank from preferences:
        --------------------------------------------------------------------------------
        local activeBanks = mod.activeBanks()
        if activeBanks[bundleID] then
            bankID = activeBanks[bundleID]
        end

        --------------------------------------------------------------------------------
        -- Revert to "All Applications" if no settings for frontmost app exist:
        --------------------------------------------------------------------------------
        if not actions[bundleID] then
            bundleID = "All Applications"
        end

        bankID = activeBanks[bundleID] or "1"
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

    local app = midiActions and midiActions[bundleID]
    local bank = app and app[bankID]
    local device = bank and bank[deviceName]
    local ch = device and device[channel]
    local ct = ch and ch[commandType]
    local cn = ct and ct[controllerNumber]

    if ct then
        if commandType == "pitchWheelChange" then
            --------------------------------------------------------------------------------
            -- Pitch Wheel Change doesn't have a controllerNumber:
            --------------------------------------------------------------------------------
            if ct.handlerID and string.sub(ct.handlerID, -13) == "_midicontrols" then
                doAfter(0, function()
                    local id = ct.action.id
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
        elseif cn then
            local v
            if cn[controllerValue] and cn[controllerValue]["action"] then
                v = cn[controllerValue]
            elseif cn["action"] then
                v = cn
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
    local items = mod.items()
    local usedDevices = {}
    for _, v in pairs(items) do
        for _, vv in pairs(v) do
            table.insert(usedDevices, vv.device)
        end
    end

    --------------------------------------------------------------------------------
    -- Watch for Loupedeck+ if enabled:
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
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

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
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")

    return mod
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
    mod.items:update()
end

return plugin
