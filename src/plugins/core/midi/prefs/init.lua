--- === plugins.core.midi.prefs ===
---
--- MIDI Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "prefsMIDI"

local application               = require "hs.application"
local canvas                    = require "hs.canvas"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local loupedeckct               = require "hs.loupedeckct"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local html                      = require "cp.web.html"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local copy                      = fnutils.copy
local delayed                   = timer.delayed
local doesDirectoryExist        = tools.doesDirectoryExist
local getFilenameFromPath       = tools.getFilenameFromPath
local imageFromURL              = image.imageFromURL
local infoForBundlePath         = application.infoForBundlePath
local mergeTable                = tools.mergeTable
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- plugins.core.midi.prefs._midiCallbackInProgress -> table
-- Variable
-- MIDI Callback in Progress
mod._midiCallbackInProgress = {}





--- plugins.core.midi.prefs.lastApplication <cp.prop: string>
--- Field
--- Last application used in the Preferences Drop Down.
mod.lastApplication = config.prop("midi.preferences.lastApplication", "All Applications")

--- plugins.core.midi.prefs.lastBank <cp.prop: string>
--- Field
--- Last bank used in the Preferences Drop Down.
mod.lastBank = config.prop("midi.preferences.lastBank", "1")

--- plugins.core.midi.prefs.scrollBarPosition <cp.prop: table>
--- Field
--- Scroll Bar Position
mod.scrollBarPosition = config.prop("midi.preferences.scrollBarPosition", {})







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
            --[[
            mod._midi.clear()
            mod._manager.refresh()
            --]]
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

        --[[
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
        --]]

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
        --[[
        if result == i18n("yes") then
            local items = mod._midi._items()
            local groupID = mod.lastGroup()
            items[groupID] = mod._midi.DEFAULT_MIDI_CONTROLS[groupID]
            mod._midi._items(items)
            mod._manager.refresh()
        end
        --]]
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
    -- Get list of registered and custom apps:
    --------------------------------------------------------------------------------
    local builtInApps = {}
    local registeredApps = mod._appmanager.getApplications()
    for bundleID, v in pairs(registeredApps) do
        if v.displayName then
            builtInApps[bundleID] = v.displayName
        end
    end

    local userApps = {}
    local items = mod.items()
    for bundleID, v in pairs(items) do
        if v.displayName then
            userApps[bundleID] = v.displayName
        end
    end

    local context = {
        builtInApps                 = builtInApps,
        userApps                    = userApps,

        numberOfBanks               = mod._midi.numberOfBanks,
        maxItems                    = mod._midi.maxItems,

        i18n                        = i18n,
        lastApplication             = mod.lastApplication(),
        lastBank                    = mod.lastBank(),

        spairs                      = spairs,
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
local function setValue(app, bank, buttonID, field, value)
    mod._manager.injectScript("setMidiValue('" .. app .. "', '" .. bank .. "', '" .. buttonID .. "', '" .. field .. "', '" .. value .. "');")
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
local function stopLearning(_, params, cancel)

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
        local groupID = params["application"] .. params["bank"]

        setValue(groupID, params["buttonID"], "device", "")
        mod._midi.setItem("device", params["buttonID"], params["application"], params["bank"], nil)

        setValue(groupID, params["buttonID"], "commandType", "")
        mod._midi.setItem("commandType", params["buttonID"], params["application"], params["bank"], nil)

        setValue(groupID, params["buttonID"], "channel", "")
        mod._midi.setItem("channel", params["buttonID"], params["application"], params["bank"], nil)

        setValue(groupID, params["buttonID"], "number", i18n("none"))
        mod._midi.setItem("number", params["buttonID"], params["application"], params["bank"], nil)

        setValue(groupID, params["buttonID"], "value", i18n("none"))
        mod._midi.setItem("value", params["buttonID"], params["application"], params["bank"], nil)
    end

    --------------------------------------------------------------------------------
    -- Update the UI:
    --------------------------------------------------------------------------------
    mod._manager.injectScript("stopLearnMode()")

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
local function startLearning(id, params)

    --------------------------------------------------------------------------------
    -- Save Group ID & Button ID both locally, and within the module, for the
    -- callback:
    --------------------------------------------------------------------------------
    local app = params["application"]
    local bank = params["bank"]
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
    injectScript("startLearnMode('" .. buttonID .. "')")

    --------------------------------------------------------------------------------
    -- Reset the current line item:
    --------------------------------------------------------------------------------
    setItem("device", buttonID, app, bank, nil)
    setItem("commandType", buttonID, app, bank, nil)
    setItem("channel", buttonID, app, bank, nil)
    setItem("number", buttonID, app, bank, nil)
    setItem("value", buttonID, app, bank, nil)

    updateUI()

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
                                        setItem("device", learnButtonID, learnGroupID, nil)
                                        setItem("commandType", learnButtonID, learnGroupID, nil)
                                        setItem("channel", learnButtonID, learnGroupID, nil)
                                        setItem("number", learnButtonID, learnGroupID, nil)
                                        setItem("value", learnButtonID, learnGroupID, nil)

                                        --------------------------------------------------------------------------------
                                        -- Exit the callback:
                                        --------------------------------------------------------------------------------
                                        stopLearning(id, params)

                                        --------------------------------------------------------------------------------
                                        -- Highlight the row red in JavaScript Land:
                                        --------------------------------------------------------------------------------
                                        injectScript("highlightRowRed('row" .. learnGroupID .. "', " .. i .. ")")

                                        updateUI()

                                        return
                                    end
                                end
                            end
                        end

                        --------------------------------------------------------------------------------
                        -- Save Preferences:
                        --------------------------------------------------------------------------------
                        if metadata.isVirtual then
                            setItem("device", learnButtonID, learnGroupID, "virtual_" .. callbackDeviceName)
                        else
                            setItem("device", learnButtonID, learnGroupID, callbackDeviceName)
                        end

                        setItem("commandType", learnButtonID, learnGroupID, commandType)
                        setItem("channel", learnButtonID, learnGroupID, metadata.channel)

                        if commandType == "noteOff" or commandType == "noteOn" then
                            setItem("number", learnButtonID, learnGroupID, metadata.note)
                            setItem("value", learnButtonID, learnGroupID, i18n("none"))
                        elseif commandType == "controlChange" then
                            setItem("number", learnButtonID, learnGroupID, metadata.controllerNumber)
                            setItem("value", learnButtonID, learnGroupID, controllerValue)
                        elseif commandType == "pitchWheelChange" then
                            setItem("value", learnButtonID, learnGroupID, metadata.pitchChange)
                        end

                        --------------------------------------------------------------------------------
                        -- Stop Learning:
                        --------------------------------------------------------------------------------
                        stopLearning(id, params)

                        updateUI()
                    end
                end)
            else
                log.ef("MIDI Device did not exist when trying to create watcher: %s", deviceName)
            end
        end
    end
end

local function updateUI()

    local injectScript = mod._manager.injectScript

    local lastApplication = mod.lastApplication()
    local lastBank = mod.lastBank()

    local maxItems = mod._midi.maxItems
    local items = mod.items()

    local app = items and items[lastApplication]
    local bank = app and app[lastBank]

    local midiDevices = mod._midi.devices()
    local virtualMidiDevices = mod._midi.virtualDevices()

    local script = ""

    for i=1, maxItems do
        local buttonID = tostring(i)

        local item = bank and bank[buttonID]

        local action        = item and item.actionTitle or ""
        local device        = item and item.device or ""
        local commandType   = item and item.commandType or ""
        local number        = item and item.number or ""
        local channel       = item and item.channel or ""
        local value         = item and item.value or ""

        local dc = [[
                    <option value="">]] .. i18n("none") .. [[</option>
                    <option disabled="disabled" value="">--------------------------</option>
                    <option disabled="disabled" value="">]] .. string.upper(i18n("physical")) .. [[:</option>
                    <option disabled="disabled" value="">--------------------------</option>
        ]]

        local foundDevice = false
        for _, deviceName in ipairs(midiDevices) do
            if deviceName ~= "Loupedeck+" and deviceName ~= "virtual_Loupedeck+" then
                local selected = ""
                if device == deviceName then
                    selected = [[selected=""]]
                    foundDevice = true
                end
                dc = dc .. [[
                    <option ]] .. selected .. [[ value="]] .. deviceName .. [[">]] .. deviceName .. [[</option>
                ]]
            end
        end
        if device ~= "" and not foundDevice and not (string.sub(device, 1, 8) == "virtual_") then
            dc = dc .. [[
                    <option selected="" value="]] .. device .. [[">]] .. device .. [[ (Offline)</option>
            ]]
        elseif #midiDevices == 0 then
            dc = dc .. [[
                    <option disabled="disabled" value="">]] ..  i18n("noDevicesDetected") .. [[</option>
            ]]
        end


        dc = dc .. [[
                    <option disabled="disabled" value="">--------------------------</option>
                    <option disabled="disabled" value="">]] .. string.upper(i18n("virtual")) .. [[:</option>
                    <option disabled="disabled" value="">--------------------------</option>
        ]]
        local foundVirtualDevice = false
        for _, deviceName in ipairs(virtualMidiDevices) do
            if deviceName ~= "Loupedeck+" and deviceName ~= "virtual_Loupedeck+" then
                local selected = ""
                if device == "virtual_" .. deviceName then
                    selected = [[selected=""]]
                    foundVirtualDevice = true
                end
                dc = dc .. [[
                    <option ]] .. selected .. [[ value="virtual_]] .. deviceName .. [[">]] .. deviceName .. [[</option>
                ]]
            end
        end
        if device ~= "" and not foundVirtualDevice and string.sub(device, 1, 8) == "virtual_" then
            dc = dc .. [[
                    <option selected="" value="virtual_]] .. device .. [[">]] .. device .. [[ (Offline)</option>
            ]]
        elseif #virtualMidiDevices == 0 then
            dc = dc .. [[
                    <option disabled="disabled" value="">]] ..  i18n("noDevicesDetected") .. [[</option>
            ]]
        end

        script = script .. [[
            changeValueByID('button]] .. buttonID .. [[_action', ']] .. action .. [[');
            changeValueByID('button]] .. buttonID .. [[_device', ']] .. device .. [[');
            changeValueByID('button]] .. buttonID .. [[_commandType', ']] .. commandType .. [[');
            changeValueByID('button]] .. buttonID .. [[_number', ']] .. number .. [[');
            changeValueByID('button]] .. buttonID .. [[_channel', ']] .. channel .. [[');
            changeValueByID('button]] .. buttonID .. [[_value', ']] .. value .. [[');


            changeInnerHTMLByID('button]] .. buttonID .. [[_device', `]] .. dc .. [[`);
        ]]
    end

    --------------------------------------------------------------------------------
    -- Update Scroll Bar Position:
    --------------------------------------------------------------------------------
    local scrollBarPositions = mod.scrollBarPosition()
    local scrollBarPosition = scrollBarPositions and scrollBarPositions[lastApplication] and scrollBarPositions[lastApplication][lastBank] or 0
    script = script .. [[
        document.getElementById("scrollArea").scrollTop = ]] .. scrollBarPosition .. [[;
    ]]


    injectScript(script)
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

                --------------------------------------------------------------------------------
                -- Get list of registered and custom apps:
                --------------------------------------------------------------------------------
                local apps = {}
                local legacyGroupIDs = {}
                local registeredApps = mod._appmanager.getApplications()
                for bundleID, v in pairs(registeredApps) do
                    if v.displayName then
                        apps[bundleID] = v.displayName
                    end
                    legacyGroupIDs[bundleID] = v.legacyGroupID or bundleID
                end
                local items = mod.items()
                for bundleID, v in pairs(items) do
                    if v.displayName then
                        apps[bundleID] = v.displayName
                    end
                end

                --------------------------------------------------------------------------------
                -- Add allowance for "All Applications":
                --------------------------------------------------------------------------------
                apps["All Applications"] = "All Applications"

                for groupID,_ in pairs(apps) do
                    --------------------------------------------------------------------------------
                    -- Create new Activator:
                    --------------------------------------------------------------------------------
                    mod.activator[groupID] = mod._actionmanager.getActivator("loupedeckCTPreferences" .. groupID)

                    --------------------------------------------------------------------------------
                    -- Restrict Allowed Handlers for Activator to current group (and global):
                    --------------------------------------------------------------------------------
                    local allowedHandlers = {}
                    for _,v in pairs(handlerIds) do
                        local handlerTable = tools.split(v, "_")
                        if handlerTable[1] == groupID or handlerTable[1] == legacyGroupIDs[groupID] or handlerTable[1] == "global" then
                            --------------------------------------------------------------------------------
                            -- Don't include "widgets" (that are used for the Touch Bar):
                            --------------------------------------------------------------------------------
                            if handlerTable[2] ~= "widgets" and v ~= "global_menuactions" then
                                table.insert(allowedHandlers, v)
                            end
                        end
                    end
                    local unpack = table.unpack
                    mod.activator[groupID]:allowHandlers(unpack(allowedHandlers))
                    mod.activator[groupID]:preloadChoices()

                    --------------------------------------------------------------------------------
                    -- Gather Toolbar Icons for Search Console:
                    --------------------------------------------------------------------------------
                    local defaultSearchConsoleToolbar = mod._appmanager.defaultSearchConsoleToolbar()
                    local appSearchConsoleToolbar = mod._appmanager.getSearchConsoleToolbar(groupID) or {}
                    local searchConsoleToolbar = mergeTable(defaultSearchConsoleToolbar, appSearchConsoleToolbar)
                    mod.activator[groupID]:toolbarIcons(searchConsoleToolbar)
                end
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
            local activatorID = params["application"]
            mod.activator[activatorID]:onActivate(function(handler, action, text)
                --------------------------------------------------------------------------------
                -- Process Stylised Text:
                --------------------------------------------------------------------------------
                if text and type(text) == "userdata" then
                    text = text:convert("text")
                end
                local actionTitle = text
                local handlerID = handler:id()

                mod._midi.updateAction(params["buttonID"], params["application"], params["bank"], actionTitle, handlerID, action)

                updateUI()
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[activatorID]:show()
        elseif callbackType == "clear" then
            --------------------------------------------------------------------------------
            -- Clear:
            --------------------------------------------------------------------------------
            mod._midi.setItem("device", params["buttonID"], params["application"], params["bank"], nil)
            mod._midi.setItem("channel", params["buttonID"], params["application"], params["bank"], nil)
            mod._midi.setItem("commandType", params["buttonID"], params["application"], params["bank"], nil)
            mod._midi.setItem("number", params["buttonID"], params["application"], params["bank"], nil)
            mod._midi.setItem("value", params["buttonID"], params["application"], params["bank"], nil)

            --------------------------------------------------------------------------------
            -- Remove the red highlight if it's still there:
            --------------------------------------------------------------------------------
            injectScript("unhighlightRowRed('row" .. params["buttonID"] .. "')")

            updateUI()
        elseif callbackType == "applyToAll" then
            local app = params["application"]
            local bank = params["bank"]

            --------------------------------------------------------------------------------
            -- Apply the selected item to all banks:
            --------------------------------------------------------------------------------
            local getItem = mod._midi.getItem
            local device = getItem("device", params["buttonID"], app, bank)
            local channel = getItem("channel", params["buttonID"], app, bank)
            local commandType = getItem("commandType", params["buttonID"], app, bank)
            local number = getItem("number", params["buttonID"], app, bank)
            local value = getItem("value", params["buttonID"], app, bank)
            local action = getItem("action", params["buttonID"], app, bank)
            local actionTitle = getItem("actionTitle", params["buttonID"], app, bank)
            local handlerID = getItem("handlerID", params["buttonID"], app, bank)

            local setItem = mod._midi.setItem
            for i = 1, mod._midi.numberOfBanks do
                local groupID = currentGroup .. tostring(i)
                setItem("device", params["buttonID"], app, bank, device)
                setItem("channel", params["buttonID"], app, bank, channel)
                setItem("commandType", params["buttonID"], app, bank, commandType)
                setItem("number", params["buttonID"], app, bank, number)
                setItem("value", params["buttonID"], app, bank, value)
                setItem("action", params["buttonID"], app, bank, action)
                setItem("actionTitle", params["buttonID"], app, bank, actionTitle)
                setItem("handlerID", params["buttonID"], app, bank, handlerID)
            end
        elseif callbackType == "updateNumber" then
            --------------------------------------------------------------------------------
            -- Update Number:
            --------------------------------------------------------------------------------
            --log.df("Updating Device: %s", params["number"])
            mod._midi.setItem("number", params["buttonID"], params["application"], params["bank"], params["number"])
        elseif callbackType == "updateDevice" then
            --------------------------------------------------------------------------------
            -- Update Device:
            --------------------------------------------------------------------------------
            --log.df("Updating Device: %s", params["device"])
            mod._midi.setItem("device", params["buttonID"], params["application"], params["bank"], params["device"])
        elseif callbackType == "updateCommandType" then
            --------------------------------------------------------------------------------
            -- Update Command Type:
            --------------------------------------------------------------------------------
            --log.df("Updating Command Type: %s", params["commandType"])
            mod._midi.setItem("commandType", params["buttonID"], params["application"], params["bank"], params["commandType"])
        elseif callbackType == "updateChannel" then
            --------------------------------------------------------------------------------
            -- Update Channel:
            --------------------------------------------------------------------------------
            --log.df("Updating Channel: %s", params["channel"])
            mod._midi.setItem("channel", params["buttonID"], params["application"], params["bank"], params["channel"])
        elseif callbackType == "updateValue" then
            --------------------------------------------------------------------------------
            -- Update Value:
            --------------------------------------------------------------------------------
            --log.df("Updating Value: %s", params["value"])
            mod._midi.setItem("value", params["buttonID"], params["application"], params["bank"], params["value"])
        elseif callbackType == "learnButton" then
            --------------------------------------------------------------------------------
            -- Learn Button:
            --------------------------------------------------------------------------------
            if mod._currentlyLearning then
                stopLearning(id, params, true)
            else
                startLearning(id, params)
            end
        elseif callbackType == "scrollBarPosition" then
            --------------------------------------------------------------------------------
            -- Save Scrollbar Position:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local value = params["value"]

            local scrollBarPosition = mod.scrollBarPosition()

            if not scrollBarPosition[app] then scrollBarPosition[app] = {} end

            scrollBarPosition[app][bank] = value

            mod.scrollBarPosition(scrollBarPosition)

        elseif callbackType == "updateBankLabel" then
            --------------------------------------------------------------------------------
            -- Update Bank Label:
            --------------------------------------------------------------------------------
            mod._midi.setBankLabel(params["application"], params["bank"], params["bankLabel"])
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update UI:
            --------------------------------------------------------------------------------
            updateUI()
        elseif callbackType == "updateApplicationAndBank" then
            --stopLearning(id, params)

            local app = params["application"]
            local bank = params["bank"]

            if app == "Add Application" then
                injectScript([[
                    changeValueByID('application', ']] .. mod.lastApplication() .. [[');
                ]])
                local files = chooseFileOrFolder(i18n("pleaseSelectAnApplication") .. ":", "/Applications", true, false, false, {"app"}, false)
                if files then
                    local path = files["1"]
                    local info = path and infoForBundlePath(path)
                    local displayName = info and info.CFBundleDisplayName or info.CFBundleName
                    local bundleID = info and info.CFBundleIdentifier
                    if displayName and bundleID then
                        local items = mod.items()

                        --------------------------------------------------------------------------------
                        -- Get list of registered and custom apps:
                        --------------------------------------------------------------------------------
                        local apps = {}
                        local registeredApps = mod._appmanager.getApplications()
                        for theBundleID, v in pairs(registeredApps) do
                            if v.displayName then
                                apps[theBundleID] = v.displayName
                            end
                        end
                        for theBundleID, v in pairs(items) do
                            if v.displayName then
                                apps[theBundleID] = v.displayName
                            end
                        end

                        --------------------------------------------------------------------------------
                        -- Prevent duplicates:
                        --------------------------------------------------------------------------------
                        for i, _ in pairs(items) do
                            if i == bundleID or tableContains(apps, bundleID) then
                                return
                            end
                        end

                        items[bundleID] = {
                            ["displayName"] = displayName,
                        }
                        mod.items(items)
                    else
                        log.ef("Something went wrong trying to add a custom application. bundleID: %s, displayName: %s", bundleID, displayName)
                    end

                    --------------------------------------------------------------------------------
                    -- Update the UI:
                    --------------------------------------------------------------------------------
                    mod._manager.refresh()
                end
            else
                mod.lastApplication(app)
                mod.lastBank(bank)

                --------------------------------------------------------------------------------
                -- Change the bank:
                --------------------------------------------------------------------------------
                --local activeBanks = mod._ctmanager.activeBanks()
                --activeBanks[app] = bank
                --mod._ctmanager.activeBanks(activeBanks)

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                updateUI()
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
    mod._appmanager     = deps.appmanager
    mod._midi           = deps.midi
    mod._manager        = deps.manager
    mod._webviewLabel   = deps.manager.getLabel()
    mod._actionmanager  = deps.actionmanager
    mod._env            = env

    mod.items           = deps.midi.items

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
        priority        = 2035,
        id              = panelID,
        label           = i18n("midi"),
        image           = image.imageFromPath(config.bundledPluginsPath .. "/core/midi/prefs/images/AudioMIDISetup.icns"),
        tooltip         = i18n("midi"),
        height          = 750,
        closeFn         = mod._destroyMIDIWatchers,
    })
        --------------------------------------------------------------------------------
        --
        -- MIDI TOOLS:
        --
        --------------------------------------------------------------------------------
        :addHeading(1, i18n("midi"))

        :addCheckbox(2,
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

        --[[
        :addButton(3,
            {
                width       = 200,
                label       = i18n("openAudioMIDISetup"),
                onclick     = function() hs.open("/Applications/Utilities/Audio MIDI Setup.app") end,
                class       = "openAudioMIDISetup",
            }
        )
        --]]

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
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.midi.manager"]               = "midi",
        ["core.action.manager"]             = "actionmanager",
        ["core.application.manager"]        = "appmanager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
