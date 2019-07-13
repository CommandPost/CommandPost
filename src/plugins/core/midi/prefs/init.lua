--- === plugins.core.midi.prefs ===
---
--- MIDI Preferences Panel

local require = require

local log           = require "hs.logger".new "prefsMIDI"

local dialog        = require "hs.dialog"
local image         = require "hs.image"
local inspect       = require "hs.inspect"
local midi          = require "hs.midi"
local timer         = require "hs.timer"

local commands      = require "cp.commands"
local config        = require "cp.config"
local tools         = require "cp.tools"
local html          = require "cp.web.html"
local i18n          = require "cp.i18n"

local moses         = require "moses"

local delayed       = timer.delayed

local mod = {}

-- plugins.core.midi.prefs._midiCallbackInProgress -> table
-- Variable
-- MIDI Callback in Progress
mod._midiCallbackInProgress = {}

--- plugins.core.midi.prefs.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("midiPreferencesLastGroup", nil)

--- plugins.core.midi.prefs.scrollBarPosition <cp.prop: table>
--- Field
--- Scroll Bar Position
mod.scrollBarPosition = config.prop("midiPreferencesScrollBarPosition", {})

-- plugins.core.midi.prefs._resetMIDI() -> none
-- Function
-- Prompts to reset shortcuts to default for all groups.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._resetMIDI()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            mod._midi.clear()
            mod._manager.refresh()
        end
    end, i18n("midiResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- plugins.core.midi.prefs._resetMIDIGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected group (including all sub-groups).
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._resetMIDIGroup()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local items = mod._midi._items()
            local currentGroup = string.sub(mod.lastGroup(), 1, -2)
            for groupAndSubgroupID in pairs(items) do
                if string.sub(groupAndSubgroupID, 1, -2) == currentGroup then
                    items[groupAndSubgroupID] = mod._midi.DEFAULT_MIDI_CONTROLS[groupAndSubgroupID]
                end
            end
            mod._midi._items(items)
            mod._manager.refresh()
        end
    end, i18n("midiResetGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- plugins.core.midi.prefs._resetMIDISubGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected sub-group.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._resetMIDISubGroup()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local items = mod._midi._items()
            local groupID = mod.lastGroup()
            items[groupID] = mod._midi.DEFAULT_MIDI_CONTROLS[groupID]
            mod._midi._items(items)
            mod._manager.refresh()
        end
    end, i18n("midiResetSubGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- renderPanel(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderPanel(context)
    if not mod._renderPanel then
        local err
        mod._renderPanel, err = mod._env:compileTemplate("html/panel.html")
        if err then
            error(err)
        end
    end
    return mod._renderPanel(context)
end

-- generateContent() -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML content as string
local function generateContent()

    --------------------------------------------------------------------------------
    -- Build a table of all the devices recognised when initialising the panel:
    --------------------------------------------------------------------------------
    local midiDevices = mod._midi.devices()
    local virtualMidiDevices = mod._midi.virtualDevices()
    local devices = {}
    for _, device in pairs(midiDevices) do
        if device ~= "Loupedeck+" then
            table.insert(devices, device)
        end
    end
    for _, device in pairs(virtualMidiDevices) do
        table.insert(devices, "virtual_" .. device)
    end
    mod._devices = devices

    --------------------------------------------------------------------------------
    -- The Group Select:
    --------------------------------------------------------------------------------
    local groups = {}
    local groupLabels = {}
    local defaultGroup
    local numberOfSubGroups = mod._midi.numberOfSubGroups
    if mod.lastGroup() then defaultGroup = mod.lastGroup() end -- Get last group from preferences.
    for _,id in ipairs(commands.groupIds()) do
        table.insert(groupLabels, {
            value = id,
            label = i18n("shortcut_group_" .. id, {default = id}),
        })
        for subGroupID=1, numberOfSubGroups do
            defaultGroup = defaultGroup or id .. subGroupID
            groups[#groups + 1] = id .. subGroupID
        end
    end
    table.sort(groupLabels, function(a, b) return a.label < b.label end)

    local context = {
        _                           = moses,
        numberOfSubGroups           = numberOfSubGroups,
        groupLabels                 = groupLabels,
        groups                      = groups,
        defaultGroup                = defaultGroup,
        webviewLabel                = mod._manager.getLabel(),
        maxItems                    = mod._midi.maxItems,
        midiDevices                 = mod._midi.devices(),
        virtualMidiDevices          = mod._midi.virtualDevices(),
        scrollBarPosition           = mod.scrollBarPosition(),
        items                       = mod._midi.getItems(),
        i18nSelect 	                = i18n("select"),
        i18nClear 	                = i18n("clear"),
        i18nNone 		            = i18n("none"),
        i18nLearn 	                = i18n("learn"),
        i18nPhysical	            = i18n("physical"),
        i18nVirtual	                = i18n("virtual"),
        i18nOffline	                = i18n("offline"),
        i18nApplication             = i18n("application"),
        i18nMidiEditor              = i18n("midiEditor"),
        i18nAction                  = i18n("action"),
        i18nDevice                  = i18n("device"),
        i18nNoteCC                  = i18n("noteCC"),
        i18nChannel                 = i18n("channel"),
        i18nValue                   = i18n("value"),
        i18nNoDevicesDetected       = i18n("noDevicesDetected"),
        i18nCommmandType            = i18n("commandType"),
        i18nNoteOff                 = i18n("noteOff"),
        i18nNoteOn                  = i18n("noteOn"),
        i18nPolyphonicKeyPressure   = i18n("polyphonicKeyPressure"),
        i18nControlChange           = i18n("controlChange"),
        i18nProgramChange           = i18n("programChange"),
        i18nChannelPressure         = i18n("channelPressure"),
        i18nPitchWheelChange        = i18n("pitchWheelChange"),
        i18nAll                     = i18n("all"),
        i18nBank                    = i18n("bank"),
    }

    return renderPanel(context)

end

-- setValue(groupID, buttonID, field, value) -> string
-- Function
-- Sets the value of a HTML field.
--
-- Parameters:
--  * groupID - the group ID
--  * buttonID - the button ID
--  * field - the field
--  * value - the value you want to set the field to
--
-- Returns:
--  * None
local function setValue(groupID, buttonID, field, value)
    mod._manager.injectScript("setMidiValue('" .. groupID .. "', '" .. buttonID .. "', '" .. field .. "', '" .. value .. "');")
end

--- plugins.core.midi.prefs._currentlyLearning -> boolean
--- Variable
--- Are we in learning mode?
mod._currentlyLearning = false

-- plugins.core.midi.prefs._destroyMIDIWatchers() -> none
-- Function
-- Destroys any MIDI Watchers.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._destroyMIDIWatchers()
    --------------------------------------------------------------------------------
    -- Destroy the MIDI watchers:
    --------------------------------------------------------------------------------
    --log.df("Destroying any MIDI Watchers")
    if mod.learningMidiDeviceNames and mod.learningMidiDevices then
        for _, id in pairs(mod.learningMidiDeviceNames) do
            if mod.learningMidiDevices[id] then
                mod.learningMidiDevices[id] = nil
            end
        end
    end
    mod.learningMidiDevices = nil
    mod.learningMidiDeviceNames = nil
end

-- plugins.core.midi.prefs._stopLearning(id, params) -> none
-- Function
-- Sets the Group Editor
--
-- Parameters:
--  * id - The ID of the callback
--  * params - The paramaters from the callback
--
-- Returns:
--  * None
function mod._stopLearning(_, params, cancel)

    --------------------------------------------------------------------------------
    -- We've stopped learning:
    --------------------------------------------------------------------------------
    mod._currentlyLearning = false

    --------------------------------------------------------------------------------
    -- Re-enable the main MIDI Callback:
    --------------------------------------------------------------------------------
    mod._midi.learningMode = false

    --------------------------------------------------------------------------------
    -- Reset the current line item:
    --------------------------------------------------------------------------------
    if cancel then
        setValue(params["groupID"], params["buttonID"], "device", "")
        mod._midi.setItem("device", params["buttonID"], params["groupID"], nil)

        setValue(params["groupID"], params["buttonID"], "commandType", "")
        mod._midi.setItem("commandType", params["buttonID"], params["groupID"], nil)

        setValue(params["groupID"], params["buttonID"], "channel", "")
        mod._midi.setItem("channel", params["buttonID"], params["groupID"], nil)

        setValue(params["groupID"], params["buttonID"], "number", i18n("none"))
        mod._midi.setItem("number", params["buttonID"], params["groupID"], nil)

        setValue(params["groupID"], params["buttonID"], "value", i18n("none"))
        mod._midi.setItem("value", params["buttonID"], params["groupID"], nil)
    end

    --------------------------------------------------------------------------------
    -- Update the UI:
    --------------------------------------------------------------------------------
    mod._manager.injectScript("stopLearnMode('" .. i18n("learn") .. "')")

    --------------------------------------------------------------------------------
    -- Destroy the MIDI watchers:
    --------------------------------------------------------------------------------
    mod._destroyMIDIWatchers()

end

-- plugins.core.midi.prefs._startLearning(id, params) -> none
-- Function
-- Sets the Group Editor
--
-- Parameters:
--  * id - The ID of the callback
--  * params - The paramaters from the callback
--
-- Returns:
--  * None
function mod._startLearning(id, params)

    --------------------------------------------------------------------------------
    -- Save Group ID & Button ID both locally, and within the module, for the
    -- callback:
    --------------------------------------------------------------------------------
    local groupID = params["groupID"]
    local buttonID = params["buttonID"]

    mod._learnGroupID = groupID
    mod._learnButtonID = buttonID

    --------------------------------------------------------------------------------
    -- Setup some locals:
    --------------------------------------------------------------------------------
    local injectScript = mod._manager.injectScript
    local setItem = mod._midi.setItem

    --------------------------------------------------------------------------------
    -- Destroy any leftover MIDI Watchers:
    --------------------------------------------------------------------------------
    mod._destroyMIDIWatchers()

    --------------------------------------------------------------------------------
    -- We're currently learning:
    --------------------------------------------------------------------------------
    mod._currentlyLearning = true

    --------------------------------------------------------------------------------
    -- Stop the main MIDI Callback Function:
    --------------------------------------------------------------------------------
    mod._midi.learningMode = true

    --------------------------------------------------------------------------------
    -- Start Learning Mode in JavaScript Land:
    --------------------------------------------------------------------------------
    injectScript("startLearnMode('" .. groupID .. "', '" .. buttonID .. "', '" .. i18n("stop") .. "')")

    --------------------------------------------------------------------------------
    -- Reset the current line item:
    --------------------------------------------------------------------------------
    setValue(groupID, buttonID, "device", "")
    setItem("device", buttonID, groupID, nil)

    setValue(groupID, buttonID, "commandType", "")
    setItem("commandType", buttonID, groupID, nil)

    setValue(groupID, buttonID, "channel", "")
    setItem("channel", buttonID, groupID, nil)

    setValue(groupID, buttonID, "number", i18n("none"))
    setItem("number", buttonID, groupID, nil)

    setValue(groupID, buttonID, "value", i18n("none"))
    setItem("value", buttonID, groupID, nil)

    --------------------------------------------------------------------------------
    -- Setup MIDI watchers:
    --------------------------------------------------------------------------------
    mod.learningMidiDeviceNames = midi.devices()
    for _, v in pairs(midi.virtualSources()) do
        table.insert(mod.learningMidiDeviceNames, "virtual_" .. v)
    end
    mod.learningMidiDevices = {}
    for _, deviceName in ipairs(mod.learningMidiDeviceNames) do
        --------------------------------------------------------------------------------
        -- Prevent Loupedeck+'s from appearing in the MIDI Preferences:
        --------------------------------------------------------------------------------
        if deviceName ~= "Loupedeck+" and deviceName ~= "virtual_Loupedeck+" then
            log.df("deviceName: %s", deviceName)
            if string.sub(deviceName, 1, 8) == "virtual_" then
                --log.df("Creating new Virtual MIDI Source Watcher: %s", string.sub(deviceName, 9))
                mod.learningMidiDevices[deviceName] = midi.newVirtualSource(string.sub(deviceName, 9))
            else
                --log.df("Creating new MIDI Device Watcher: %s", deviceName)
                mod.learningMidiDevices[deviceName] = midi.new(deviceName)
            end
            if mod.learningMidiDevices[deviceName] then
                mod.learningMidiDevices[deviceName]:callback(function(_, callbackDeviceName, commandType, _, metadata)

                    local learnGroupID = mod._learnGroupID
                    local learnButtonID = mod._learnButtonID

                    if not mod._currentlyLearning then
                        --------------------------------------------------------------------------------
                        -- First in, best dressed:
                        --------------------------------------------------------------------------------
                        return
                    end

                    if commandType == "controlChange" or commandType == "noteOn" or commandType == "pitchWheelChange" then

                        --------------------------------------------------------------------------------
                        -- Debugging:
                        --------------------------------------------------------------------------------
                        --log.df("commandType: %s", commandType)
                        --log.df("metadata: %s", hs.inspect(metadata))
                        --log.df("learnGroupID: %s", learnGroupID)
                        --log.df("learnButtonID: %s", learnButtonID)

                        --------------------------------------------------------------------------------
                        -- Support 14bit Control Change Messages:
                        --------------------------------------------------------------------------------
                        local controllerValue = metadata.controllerValue
                        if metadata.fourteenBitCommand then
                            controllerValue = metadata.fourteenBitValue
                        end

                        --------------------------------------------------------------------------------
                        -- Ignore noteOff Commands:
                        --------------------------------------------------------------------------------
                        if commandType == "noteOn" and metadata.velocity == 0 then return end

                        --------------------------------------------------------------------------------
                        -- Check it's not already in use:
                        --------------------------------------------------------------------------------
                        local items = mod._midi._items()
                        if items[learnGroupID] then
                            for i, item in pairs(items[learnGroupID]) do
                                if learnButtonID and i ~= tonumber(learnButtonID) then
                                    --------------------------------------------------------------------------------
                                    -- Check for matching devices:
                                    --------------------------------------------------------------------------------
                                    local deviceMatch = false
                                    if metadata.isVirtual and item.device == "virtual_" .. callbackDeviceName then deviceMatch = true end
                                    if not metadata.isVirtual and item.device == callbackDeviceName then deviceMatch = true end

                                    --------------------------------------------------------------------------------
                                    -- Check for matching metadata:
                                    --------------------------------------------------------------------------------
                                    local match = false
                                    if item.commandType == commandType then
                                        if commandType == "noteOn" then
                                            if item.channel == metadata.channel and item.number == metadata.note then
                                                match = true
                                            end
                                        end
                                        if commandType == "controlChange" then
                                            if item.channel == metadata.channel and item.number == metadata.controllerNumber and item.value == controllerValue then
                                                match = true
                                            end
                                        end
                                        if commandType == "pitchWheelChange" then
                                            if item.number == metadata.pitchChange then
                                                match = true
                                            end
                                        end
                                    end

                                    --------------------------------------------------------------------------------
                                    -- Duplicate Found:
                                    --------------------------------------------------------------------------------
                                    if deviceMatch and match then

                                        --log.wf("Duplicate MIDI Command Found:\nGroup: %s\nButton: %s", learnGroupID, learnButtonID)

                                        --------------------------------------------------------------------------------
                                        -- Reset the current line item:
                                        --------------------------------------------------------------------------------
                                        setValue(learnGroupID, learnButtonID, "device", "")
                                        setItem("device", learnButtonID, learnGroupID, nil)

                                        setValue(learnGroupID, learnButtonID, "commandType", "")
                                        setItem("commandType", learnButtonID, learnGroupID, nil)

                                        setValue(learnGroupID, learnButtonID, "channel", "")
                                        setItem("channel", learnButtonID, learnGroupID, nil)

                                        setValue(learnGroupID, learnButtonID, "number", i18n("none"))
                                        setItem("number", learnButtonID, learnGroupID, nil)

                                        setValue(learnGroupID, learnButtonID, "value", i18n("none"))
                                        setItem("value", learnButtonID, learnGroupID, nil)

                                        --------------------------------------------------------------------------------
                                        -- Exit the callback:
                                        --------------------------------------------------------------------------------
                                        mod._stopLearning(id, params)

                                        --------------------------------------------------------------------------------
                                        -- Highlight the row red in JavaScript Land:
                                        --------------------------------------------------------------------------------
                                        injectScript("highlightRowRed('" .. learnGroupID .. "', " .. i .. ")")
                                        return
                                    end
                                end
                            end
                        end

                        --------------------------------------------------------------------------------
                        -- Update the UI & Save Preferences:
                        --------------------------------------------------------------------------------
                        if metadata.isVirtual then
                            setValue(learnGroupID, learnButtonID, "device", "virtual_" .. callbackDeviceName)
                            setItem("device", learnButtonID, learnGroupID, "virtual_" .. callbackDeviceName)
                        else
                            setValue(learnGroupID, learnButtonID, "device", callbackDeviceName)
                            setItem("device", learnButtonID, learnGroupID, callbackDeviceName)
                        end

                        setValue(learnGroupID, learnButtonID, "commandType", commandType)
                        setItem("commandType", learnButtonID, learnGroupID, commandType)

                        setValue(learnGroupID, learnButtonID, "channel", metadata.channel)
                        setItem("channel", learnButtonID, learnGroupID, metadata.channel)

                        if commandType == "noteOff" or commandType == "noteOn" then

                            setValue(learnGroupID, learnButtonID, "number", metadata.note)
                            setItem("number", learnButtonID, learnGroupID, metadata.note)

                            setValue(learnGroupID, learnButtonID, "value", i18n("none"))
                            setItem("value", learnButtonID, learnGroupID, i18n("none"))

                        elseif commandType == "controlChange" then

                            setValue(learnGroupID, learnButtonID, "number", metadata.controllerNumber)
                            setItem("number", learnButtonID, learnGroupID, metadata.controllerNumber)

                            setValue(learnGroupID, learnButtonID, "value", controllerValue)
                            setItem("value", learnButtonID, learnGroupID, controllerValue)

                        elseif commandType == "pitchWheelChange" then

                            setValue(learnGroupID, learnButtonID, "value", metadata.pitchChange)
                            setItem("value", learnButtonID, learnGroupID, metadata.pitchChange)

                        end

                        --------------------------------------------------------------------------------
                        -- Stop Learning:
                        --------------------------------------------------------------------------------
                        mod._stopLearning(id, params)

                        --------------------------------------------------------------------------------
                        -- If the device isn't already listed in the panel we need to refresh:
                        --------------------------------------------------------------------------------
                        if not tools.tableContains(mod._devices, callbackDeviceName) then
                            mod._manager.refresh()
                        end
                    end
                end)
            else
                log.ef("MIDI Device did not exist when trying to create watcher: %s", deviceName)
            end
        end
    end
end

-- midiPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function midiPanelCallback(id, params)
    local injectScript = mod._manager.injectScript
    local callbackType = params and params["type"]
    if callbackType then
        if callbackType == "updateAction" then
            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            if not mod.activator then
                mod.activator = {}
                local handlerIds = mod._actionmanager.handlerIds()
                for _,groupID in ipairs(commands.groupIds()) do
                    --------------------------------------------------------------------------------
                    -- Create new Activator:
                    --------------------------------------------------------------------------------
                    mod.activator[groupID] = mod._actionmanager.getActivator("midiPreferences" .. groupID)

                    --------------------------------------------------------------------------------
                    -- Restrict Allowed Handlers for Activator to current group (and global):
                    --------------------------------------------------------------------------------
                    local allowedHandlers = {}
                    for _,v in pairs(handlerIds) do
                        local handlerTable = tools.split(v, "_")
                        if handlerTable[1] == groupID or handlerTable[1] == "global" then
                            --------------------------------------------------------------------------------
                            -- Don't include "widgets" (that are used for the Touch Bar):
                            --------------------------------------------------------------------------------
                            if handlerTable[2] ~= "widgets" then
                                table.insert(allowedHandlers, v)
                            end
                        end
                    end
                    local unpack = table.unpack
                    mod.activator[groupID]:allowHandlers(unpack(allowedHandlers))
                    mod.activator[groupID]:preloadChoices()

                    --------------------------------------------------------------------------------
                    -- Allow specific toolbar icons in the Console:
                    --------------------------------------------------------------------------------
                    if groupID == "fcpx" then
                        local iconPath = config.basePath .. "/plugins/finalcutpro/console/images/"
                        local toolbarIcons = {
                            fcpx_midicontrols   = { path = iconPath .. "midi.png",          priority = 1},
                            global_midibanks    = { path = iconPath .. "bank.png",          priority = 2},
                            fcpx_videoEffect    = { path = iconPath .. "videoEffect.png",   priority = 3},
                            fcpx_audioEffect    = { path = iconPath .. "audioEffect.png",   priority = 4},
                            fcpx_generator      = { path = iconPath .. "generator.png",     priority = 5},
                            fcpx_title          = { path = iconPath .. "title.png",         priority = 6},
                            fcpx_transition     = { path = iconPath .. "transition.png",    priority = 7},
                            fcpx_fonts          = { path = iconPath .. "font.png",          priority = 8},
                            fcpx_shortcuts      = { path = iconPath .. "shortcut.png",      priority = 9},
                            fcpx_menu           = { path = iconPath .. "menu.png",          priority = 10},
                        }
                        mod.activator[groupID]:toolbarIcons(toolbarIcons)
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
            local groupID = params["groupID"]
            local activatorID = groupID:sub(1, -2)

            mod.activator[activatorID]:onActivate(function(handler, action, text)
                --------------------------------------------------------------------------------
                -- Process Stylised Text:
                --------------------------------------------------------------------------------
                if text and type(text) == "userdata" then
                    text = text:convert("text")
                end
                local actionTitle = text
                local handlerID = handler:id()
                mod._midi.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action)
                setValue(params["groupID"], params["buttonID"], "action", actionTitle)
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[activatorID]:show()
        elseif callbackType == "clear" then
            --------------------------------------------------------------------------------
            -- Clear:
            --------------------------------------------------------------------------------
            setValue(params["groupID"], params["buttonID"], "device", "")
            mod._midi.setItem("device", params["buttonID"], params["groupID"], nil)

            setValue(params["groupID"], params["buttonID"], "channel", "")
            mod._midi.setItem("channel", params["buttonID"], params["groupID"], nil)

            setValue(params["groupID"], params["buttonID"], "commandType", "")
            mod._midi.setItem("commandType", params["buttonID"], params["groupID"], nil)

            setValue(params["groupID"], params["buttonID"], "number", i18n("none"))
            mod._midi.setItem("number", params["buttonID"], params["groupID"], nil)

            setValue(params["groupID"], params["buttonID"], "value", i18n("none"))
            mod._midi.setItem("value", params["buttonID"], params["groupID"], nil)

            --------------------------------------------------------------------------------
            -- Remove the red highlight if it's still there:
            --------------------------------------------------------------------------------
            injectScript("unhighlightRowRed('" .. params["groupID"] .. "', " .. params["buttonID"] .. ")")
        elseif callbackType == "applyToAll" then
            --------------------------------------------------------------------------------
            -- Apply the selected item to all banks:
            --------------------------------------------------------------------------------
            local getItem = mod._midi.getItem
            local device = getItem("device", params["buttonID"], params["groupID"])
            local channel = getItem("channel", params["buttonID"], params["groupID"])
            local commandType = getItem("commandType", params["buttonID"], params["groupID"])
            local number = getItem("number", params["buttonID"], params["groupID"])
            local value = getItem("value", params["buttonID"], params["groupID"])
            local action = getItem("action", params["buttonID"], params["groupID"])
            local actionTitle = getItem("actionTitle", params["buttonID"], params["groupID"])
            local handlerID = getItem("handlerID", params["buttonID"], params["groupID"])

            local currentGroup = params["groupID"]:sub(1, -2)
            local setItem = mod._midi.setItem
            for i = 1, mod._midi.numberOfSubGroups do
                local groupID = currentGroup .. tostring(i)
                setItem("device", params["buttonID"], groupID, device)
                setItem("channel", params["buttonID"], groupID, channel)
                setItem("commandType", params["buttonID"], groupID, commandType)
                setItem("number", params["buttonID"], groupID, number)
                setItem("value", params["buttonID"], groupID, value)
                setItem("action", params["buttonID"], groupID, action)
                setItem("actionTitle", params["buttonID"], groupID, actionTitle)
                setItem("handlerID", params["buttonID"], groupID, handlerID)
            end
        elseif callbackType == "updateNumber" then
            --------------------------------------------------------------------------------
            -- Update Number:
            --------------------------------------------------------------------------------
            --log.df("Updating Device: %s", params["number"])
            mod._midi.setItem("number", params["buttonID"], params["groupID"], params["number"])
        elseif callbackType == "updateDevice" then
            --------------------------------------------------------------------------------
            -- Update Device:
            --------------------------------------------------------------------------------
            --log.df("Updating Device: %s", params["device"])
            mod._midi.setItem("device", params["buttonID"], params["groupID"], params["device"])
        elseif callbackType == "updateCommandType" then
            --------------------------------------------------------------------------------
            -- Update Command Type:
            --------------------------------------------------------------------------------
            --log.df("Updating Command Type: %s", params["commandType"])
            mod._midi.setItem("commandType", params["buttonID"], params["groupID"], params["commandType"])
        elseif callbackType == "updateChannel" then
            --------------------------------------------------------------------------------
            -- Update Channel:
            --------------------------------------------------------------------------------
            --log.df("Updating Channel: %s", params["channel"])
            mod._midi.setItem("channel", params["buttonID"], params["groupID"], params["channel"])
        elseif callbackType == "updateValue" then
            --------------------------------------------------------------------------------
            -- Update Value:
            --------------------------------------------------------------------------------
            --log.df("Updating Value: %s", params["value"])
            mod._midi.setItem("value", params["buttonID"], params["groupID"], params["value"])
        elseif callbackType == "updateGroup" then
            --------------------------------------------------------------------------------
            -- Update Group:
            -- Change the MIDI Bank as you change the group drop down:
            --------------------------------------------------------------------------------
            mod._midi.forceGroupChange(params["groupID"], mod._midi.enabled())
            mod._stopLearning(id, params)
            mod.lastGroup(params["groupID"])
            mod._manager.refresh()
        elseif callbackType == "learnButton" then
            --------------------------------------------------------------------------------
            -- Learn Button:
            --------------------------------------------------------------------------------
            if mod._currentlyLearning then
                mod._stopLearning(id, params, true)
            else
                mod._startLearning(id, params)
            end
        elseif callbackType == "scrollBarPosition" then
            local value = params["value"]
            local groupID = params["groupID"]
            if value and groupID then
                local scrollBarPosition = mod.scrollBarPosition()
                scrollBarPosition[groupID] = value
                mod.scrollBarPosition(scrollBarPosition)
            end
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in MIDI Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

-- plugins.core.midi.prefs._applyTopDeviceToAll() -> none
-- Function
-- Applies the Top Group to all the subsequent groups.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._applyTopDeviceToAll()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local currentGroup = mod.lastGroup()
            local value = mod._midi.getItem("device", "1", currentGroup)
            if value then
                local maxItems = mod._midi.maxItems
                for i=1, maxItems do
                    mod._midi.setItem("device", tostring(i), currentGroup, value)
                end
                mod._manager.refresh()
            end
        end
    end, i18n("midiTopDeviceToAll"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

--- plugins.core.midi.prefs.init(deps, env) -> module
--- Function
--- Initialise the Module.
---
--- Parameters:
---  * deps - Dependancies Table
---  * env - Environment Table
---
--- Returns:
---  * The Module
function mod.init(deps, env)

    --------------------------------------------------------------------------------
    -- Define the Panel ID:
    --------------------------------------------------------------------------------
    local panelID = "midi"

    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._midi           = deps.midi
    mod._manager        = deps.manager
    mod._webviewLabel   = deps.manager.getLabel()
    mod._actionmanager  = deps.actionmanager
    mod._env            = env

    --------------------------------------------------------------------------------
    -- Refresh the webview if MIDI devices are added or removed.
    -- There's a slight delay on this, otherwise CommandPost gets stuck in an
    -- infinite loop.
    --------------------------------------------------------------------------------
    mod._refreshTimer = delayed.new(0.2, function()
        if mod._manager._webview ~= nil and mod._manager.currentPanelID() == panelID then
            --log.df("Refreshing MIDI Preferences as number of MIDI Devices have changed.")
            mod._manager.refresh()
        --else
            --log.df("Not Refereshing MIDI Preferences as the panel is not active.")
        end
    end)
    mod._midi.numberOfMidiDevices:watch(function()
         mod._refreshTimer:start()
    end)

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2033,
        id              = panelID,
        label           = i18n("midi"),
        image           = image.imageFromPath(tools.iconFallback("/Applications/Utilities/Audio MIDI Setup.app/Contents/Resources/AudioMIDISetup.icns")),
        tooltip         = i18n("midi"),
        height          = 610,
        closeFn         = mod._destroyMIDIWatchers,
    })
        --------------------------------------------------------------------------------
        --
        -- MIDI TOOLS:
        --
        --------------------------------------------------------------------------------
        :addHeading(0.1, i18n("midiTools"))
        :addButton(0.2,
            {
                width       = 200,
                label       = i18n("openAudioMIDISetup"),
                onclick     = function() hs.open("/Applications/Utilities/Audio MIDI Setup.app") end,
                class       = "openAudioMIDISetup",
            }
        )
        :addParagraph(5, html.br())
        --------------------------------------------------------------------------------
        --
        -- MIDI CONTROLS:
        --
        --------------------------------------------------------------------------------
        :addHeading(6, i18n("midiControls"))
        :addCheckbox(7,
            {
                label       = i18n("enableMIDI"),
                checked     = mod._midi.enabled,
                onchange    = function(_, params)
                    --------------------------------------------------------------------------------
                    -- Toggle Preference:
                    --------------------------------------------------------------------------------
                    mod._midi.enabled(params.checked)
                end,
            }
        )
        :addContent(10, generateContent, false)
        :addButton(12,
            {
                label       = i18n("applyTopDeviceToAll"),
                onclick     = mod._applyTopDeviceToAll,
                class       = "applyTopDeviceToAll",
            }
        )
        :addButton(13,
            {
                label       = i18n("resetEverything"),
                onclick     = mod._resetMIDI,
                class       = "midiResetGroup",
            }
        )
        :addButton(14,
            {
                label       = i18n("resetApplication"),
                onclick     = mod._resetMIDIGroup,
                class       = "midiResetGroup",
            }
        )
        :addButton(15,
            {
                label       = i18n("resetBank"),
                onclick     = mod._resetMIDISubGroup,
                class       = "midiResetGroup",
            }
        )

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "midiPanelCallback", midiPanelCallback)

    return mod

end

local plugin = {
    id              = "core.midi.prefs",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]        = "manager",
        ["core.midi.manager"]               = "midi",
        ["core.action.manager"]             = "actionmanager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
