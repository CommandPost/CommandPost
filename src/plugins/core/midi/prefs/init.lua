--- === plugins.core.midi.prefs ===
---
--- MIDI Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "prefsMIDI"

local application               = require "hs.application"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local menubar                   = require "hs.menubar"
local midi                      = require "hs.midi"
local mouse                     = require "hs.mouse"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local copy                      = fnutils.copy
local delayed                   = timer.delayed
local doesDirectoryExist        = tools.doesDirectoryExist
local escapeTilda               = tools.escapeTilda
local imageFromPath             = image.imageFromPath
local infoForBundlePath         = application.infoForBundlePath
local mergeTable                = tools.mergeTable
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local webviewAlert              = dialog.webviewAlert

local mod = {}

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

--- plugins.core.midi.prefs.lastExportPath <cp.prop: string>
--- Field
--- Last Export path.
mod.lastExportPath = config.prop("midi.preferences.lastExportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.midi.prefs.lastImportPath <cp.prop: string>
--- Field
--- Last Import path.
mod.lastImportPath = config.prop("midi.preferences.lastImportPath", os.getenv("HOME") .. "/Desktop/")

-- currentlyLearning -> boolean
-- Variable
-- Are we in learning mode?
local currentlyLearning = false

local learnApplication
local learnBank
local learnButton

local learningMidiDevices
local learningMidiDeviceNames

-- setItem(item, button, bundleID, bankID, value) -> none
-- Function
-- Stores a MIDI item in Preferences.
--
-- Parameters:
--  * item - The item you want to set.
--  * button - Button ID as string
--  * bundleID - The application bundle ID as string
--  * bankID - The bank ID as string
--  * value - The value of the item you want to set.
--
-- Returns:
--  * None
local function setItem(item, button, bundleID, bankID, value)
    local items = mod.items()

    button = tostring(button)

    if not items[bundleID] then items[bundleID] = {} end
    if not items[bundleID][bankID] then items[bundleID][bankID] = {} end
    if not items[bundleID][bankID][button] then items[bundleID][bankID][button] = {} end

    items[bundleID][bankID][button][item] = value

    mod.items(items)
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

        numberOfBanks               = mod.numberOfBanks,
        maxItems                    = mod._midi.maxItems,

        i18n                        = i18n,
        lastApplication             = mod.lastApplication(),
        lastBank                    = mod.lastBank(),

        spairs                      = spairs,
    }

    return renderPanel(context)
end

-- updateUI([highlightRow]) -> none
-- Function
-- Update the UI
--
-- Parameters:
--  * highlightRow - An optional row to highlight.
--
-- Returns:
--  * None
local function updateUI(highlightRow)
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

    --------------------------------------------------------------------------------
    -- Update Bank Label:
    --------------------------------------------------------------------------------
    local bankLabel = bank and bank.bankLabel or ""
    script = script .. [[
        document.getElementById("bankLabel").value = "]] .. bankLabel .. [[";
    ]]

    --------------------------------------------------------------------------------
    -- Update Ignore Checkbox:
    --------------------------------------------------------------------------------
    local ignore = app and app.ignore or false
    script = script .. [[
        document.getElementById("ignore").checked = ]] .. tostring(ignore) .. [[;
    ]]
    if lastApplication == "All Applications" then
        script = script .. [[
            document.getElementById("ignoreApp").style.display = "none";
        ]]
    else
        script = script .. [[
            document.getElementById("ignoreApp").style.display = "block";
        ]]
    end

    --------------------------------------------------------------------------------
    -- Highlight Row (if required):
    --------------------------------------------------------------------------------
    if highlightRow then
        script = script .. [[
            document.getElementById("row]] .. highlightRow .. [[").style.backgroundColor = "#cc5e53";
            document.getElementById("row]] .. highlightRow .. [[").style.setProperty("-webkit-transition", "background-color 1s");
        ]]
    end

    --------------------------------------------------------------------------------
    -- Update table contents:
    --------------------------------------------------------------------------------
    for i=1, maxItems do
        local buttonID = tostring(i)

        local item = bank and bank[buttonID]

        local action        = item and item.actionTitle or ""
        local device        = item and item.device or ""
        local commandType   = item and item.commandType or ""
        local number        = item and item.number or ""
        local channel       = item and item.channel or ""
        local value         = item and item.value or ""

        --------------------------------------------------------------------------------
        -- Unhighlight Row (unless highlighted):
        --------------------------------------------------------------------------------
        if i ~= tonumber(highlightRow or 0) then
            script = script .. [[
                document.getElementById("row]] .. i .. [[").style.backgroundColor = "";
                document.getElementById("row]] .. i .. [[").style.setProperty("-webkit-transition", "background-color 0s");
            ]]
        end

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
            changeValueByID('button]] .. buttonID .. [[_action', `]] .. escapeTilda(action) .. [[`);
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

    --------------------------------------------------------------------------------
    -- Force MIDI watchers to update:
    --------------------------------------------------------------------------------
    mod._midi.update()
end

-- destroyMIDIWatchers() -> none
-- Function
-- Destroys any MIDI Watchers.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function destroyMIDIWatchers()
    --------------------------------------------------------------------------------
    -- Destroy the MIDI watchers:
    --------------------------------------------------------------------------------
    if learningMidiDeviceNames and learningMidiDevices then
        for _, id in pairs(learningMidiDeviceNames) do
            if learningMidiDevices[id] then
                learningMidiDevices[id] = nil
            end
        end
    end
    learningMidiDevices = nil
    learningMidiDeviceNames = nil
end

-- stopLearning(params) -> none
-- Function
-- Sets the Group Editor
--
-- Parameters:
--  * params - The paramaters from the callback
--  * cancel - A boolean specifying whether or not the learning has been cancelled
--
-- Returns:
--  * None
local function stopLearning(params, cancel)
    --------------------------------------------------------------------------------
    -- We've stopped learning:
    --------------------------------------------------------------------------------
    currentlyLearning = false

    --------------------------------------------------------------------------------
    -- Re-enable the main MIDI Callback:
    --------------------------------------------------------------------------------
    mod._midi.learningMode = false

    --------------------------------------------------------------------------------
    -- Reset the current line item:
    --------------------------------------------------------------------------------
    if cancel then
        local app = params["application"]
        local bank = params["bank"]
        local button = params["buttonID"]

        local items = mod.items()

        if not items[app] then items[app] = {} end
        if not items[app][bank] then items[app][bank] = {} end
        if not items[app][bank][button] then items[app][bank][button] = {} end

        items[app][bank][button].device = nil
        items[app][bank][button].commandType = nil
        items[app][bank][button].channel = nil
        items[app][bank][button].number = nil
        items[app][bank][button].value = nil

        mod.items(items)
    end

    --------------------------------------------------------------------------------
    -- Update the UI:
    --------------------------------------------------------------------------------
    mod._manager.injectScript("stopLearnMode()")
    updateUI()

    --------------------------------------------------------------------------------
    -- Destroy the MIDI watchers:
    --------------------------------------------------------------------------------
    destroyMIDIWatchers()
end

-- startLearning(id, params) -> none
-- Function
-- Sets the Group Editor
--
-- Parameters:
--  * params - The paramaters from the callback
--
-- Returns:
--  * None
local function startLearning(params)
    local app = params["application"]
    local bank = params["bank"]
    local buttonID = params["buttonID"]

    --------------------------------------------------------------------------------
    -- Save Application & Bank within the module for callback purposes:
    --------------------------------------------------------------------------------
    learnApplication = app
    learnBank = bank
    learnButton = buttonID

    --------------------------------------------------------------------------------
    -- Setup some locals:
    --------------------------------------------------------------------------------
    local injectScript = mod._manager.injectScript

    --------------------------------------------------------------------------------
    -- Destroy any leftover MIDI Watchers:
    --------------------------------------------------------------------------------
    destroyMIDIWatchers()

    --------------------------------------------------------------------------------
    -- We're currently learning:
    --------------------------------------------------------------------------------
    currentlyLearning = true

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
    learningMidiDeviceNames = midi.devices()
    for _, v in pairs(midi.virtualSources()) do
        table.insert(learningMidiDeviceNames, "virtual_" .. v)
    end
    learningMidiDevices = {}
    for _, deviceName in ipairs(learningMidiDeviceNames) do
        --------------------------------------------------------------------------------
        -- Prevent Loupedeck+'s from appearing in the MIDI Preferences:
        --------------------------------------------------------------------------------
        if deviceName ~= "Loupedeck+" and deviceName ~= "virtual_Loupedeck+" then
            if string.sub(deviceName, 1, 8) == "virtual_" then
                learningMidiDevices[deviceName] = midi.newVirtualSource(string.sub(deviceName, 9))
            else
                learningMidiDevices[deviceName] = midi.new(deviceName)
            end
            if learningMidiDevices[deviceName] then
                learningMidiDevices[deviceName]:callback(function(_, callbackDeviceName, commandType, _, metadata)

                    if not currentlyLearning then
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
                        --log.df("learnApplication: %s", learnApplication)
                        --log.df("learnButton: %s", learnButton)

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
                        local items = mod.items()

                        local currentItem = items and items[learnApplication] and items[learnApplication][learnBank]

                        if currentItem then
                            for i, item in pairs(currentItem) do
                                if learnButton and i ~= tonumber(learnButton) then
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

                                        log.wf("Duplicate MIDI Command Found:\nApplication: %s\nBank: %s\nButton: %s", learnApplication, learnBank, learnButton)

                                        --------------------------------------------------------------------------------
                                        -- Reset the current line item:
                                        --------------------------------------------------------------------------------

                                        -- setItem(item, button, bundleID, bankID, value)

                                        setItem("device", learnButton, learnApplication, learnBank, nil)
                                        setItem("commandType", learnButton, learnApplication, learnBank, nil)
                                        setItem("channel", learnButton, learnApplication, learnBank, nil)
                                        setItem("number", learnButton, learnApplication, learnBank, nil)
                                        setItem("value", learnButton, learnApplication, learnBank, nil)

                                        --------------------------------------------------------------------------------
                                        -- Exit the callback:
                                        --------------------------------------------------------------------------------
                                        stopLearning(params)

                                        --------------------------------------------------------------------------------
                                        -- Highlight the row red in JavaScript Land:
                                        --------------------------------------------------------------------------------
                                        updateUI(i)

                                        return
                                    end
                                end
                            end
                        end

                        --------------------------------------------------------------------------------
                        -- Save Preferences:
                        --------------------------------------------------------------------------------
                        if metadata.isVirtual then
                            setItem("device", learnButton, learnApplication, learnBank, "virtual_" .. callbackDeviceName)
                        else
                            setItem("device", learnButton, learnApplication, learnBank, callbackDeviceName)
                        end

                        setItem("commandType", learnButton, learnApplication, learnBank, commandType)
                        setItem("channel", learnButton, learnApplication, learnBank, metadata.channel)

                        if commandType == "noteOff" or commandType == "noteOn" then
                            setItem("number", learnButton, learnApplication, learnBank, metadata.note)
                            setItem("value", learnButton, learnApplication, learnBank, "")
                        elseif commandType == "controlChange" then
                            setItem("number", learnButton, learnApplication, learnBank, metadata.controllerNumber)
                            setItem("value", learnButton, learnApplication, learnBank, controllerValue)
                        elseif commandType == "pitchWheelChange" then
                            setItem("value", learnButton, learnApplication, learnBank, metadata.pitchChange)
                        end

                        --------------------------------------------------------------------------------
                        -- Stop Learning:
                        --------------------------------------------------------------------------------
                        stopLearning(params)

                        updateUI()
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


                local items = mod.items()

                local button = params["buttonID"]
                local bundleID = params["application"]
                local bankID = params["bank"]

                if not items[bundleID] then items[bundleID] = {} end
                if not items[bundleID][bankID] then items[bundleID][bankID] = {} end
                if not items[bundleID][bankID][button] then items[bundleID][bankID][button] = {} end

                items[bundleID][bankID][button]["actionTitle"] = actionTitle
                items[bundleID][bankID][button]["handlerID"] = handlerID
                items[bundleID][bankID][button]["action"] = action

                mod.items(items)


                updateUI()
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[activatorID]:show()
        elseif callbackType == "clear" then
            local buttonID = params["buttonID"]
            local app = params["application"]
            local bank = params["bank"]

            --------------------------------------------------------------------------------
            -- Clear:
            --------------------------------------------------------------------------------
            setItem("device", buttonID, app, bank, nil)
            setItem("channel", buttonID, app, bank, nil)
            setItem("commandType", buttonID, app, bank, nil)
            setItem("number", buttonID, app, bank, nil)
            setItem("value", buttonID, app, bank, nil)

            --------------------------------------------------------------------------------
            -- Remove the red highlight if it's still there:
            --------------------------------------------------------------------------------
            updateUI()
        elseif callbackType == "applyToAll" then
            --------------------------------------------------------------------------------
            -- Apply the selected item to all banks:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local button = params["buttonID"]

            local items = mod.items()
            local item = items and items[app] and items[app][bank] and items[app][bank][button]

            local device = item and item.device or ""
            local channel = item and item.channel or ""
            local commandType = item and item.commandType or ""
            local number = item and item.number or ""
            local value = item and item.value or ""
            local action = item and item.action or ""
            local actionTitle = item and item.actionTitle or ""
            local handlerID = item and item.handlerID or ""

            for i = 1, mod.numberOfBanks do
                local bankID = tostring(i)
                setItem("device", button, app, bankID, device)
                setItem("channel", button, app, bankID, channel)
                setItem("commandType", button, app, bankID, commandType)
                setItem("number", button, app, bankID, number)
                setItem("value", button, app, bankID, value)
                setItem("action", button, app, bankID, action)
                setItem("actionTitle", button, app, bankID, actionTitle)
                setItem("handlerID", button, app, bankID, handlerID)
            end
        elseif callbackType == "updateNumber" then
            --------------------------------------------------------------------------------
            -- Update Number:
            --------------------------------------------------------------------------------
            setItem("number", params["buttonID"], params["application"], params["bank"], params["number"])
        elseif callbackType == "updateDevice" then
            --------------------------------------------------------------------------------
            -- Update Device:
            --------------------------------------------------------------------------------
            setItem("device", params["buttonID"], params["application"], params["bank"], params["device"])
        elseif callbackType == "updateCommandType" then
            --------------------------------------------------------------------------------
            -- Update Command Type:
            --------------------------------------------------------------------------------
            setItem("commandType", params["buttonID"], params["application"], params["bank"], params["commandType"])
        elseif callbackType == "updateChannel" then
            --------------------------------------------------------------------------------
            -- Update Channel:
            --------------------------------------------------------------------------------
            setItem("channel", params["buttonID"], params["application"], params["bank"], params["channel"])
        elseif callbackType == "updateValue" then
            --------------------------------------------------------------------------------
            -- Update Value:
            --------------------------------------------------------------------------------
            setItem("value", params["buttonID"], params["application"], params["bank"], params["value"])
        elseif callbackType == "learnButton" then
            --------------------------------------------------------------------------------
            -- Learn Button:
            --------------------------------------------------------------------------------
            if currentlyLearning then
                stopLearning(params, true)
            else
                startLearning(params)
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
            local bundleID = params["application"]
            local bankID = params["bank"]
            local label = params["bankLabel"]

            local items = mod.items()

            if not items[bundleID] then items[bundleID] = {} end
            if not items[bundleID][bankID] then items[bundleID][bankID] = {} end
            items[bundleID][bankID]["bankLabel"] = label

            mod.items(items)
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update UI:
            --------------------------------------------------------------------------------
            updateUI()
        elseif callbackType == "updateApplicationAndBank" then
            --------------------------------------------------------------------------------
            -- Update Application & Bank:
            --------------------------------------------------------------------------------
            stopLearning(params)

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
                    local displayName = info and info.CFBundleDisplayName or info.CFBundleName or info.CFBundleExecutable
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
                        webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToAddCustomApplication"), i18n("failedToAddCustomApplicationDescription"), i18n("ok"))
                        log.ef("Something went wrong trying to add a custom application.\n\nPath: '%s'\nbundleID: '%s'\ndisplayName: '%s'",path, bundleID, displayName)
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
                local activeBanks = mod._midi.activeBanks()
                activeBanks[app] = tostring(bank)
                mod._midi.activeBanks(activeBanks)

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                updateUI()
            end
        elseif callbackType == "applyTopDeviceToAll" then
            --------------------------------------------------------------------------------
            -- Apply Top Device To All:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local app = params["application"]
                    local bank = params["bank"]

                    local items = mod.items()
                    local device = items and items[app] and items[app][bank] and items[app][bank]["1"] and items[app][bank]["1"].device

                    if device then
                        local maxItems = mod._midi.maxItems
                        for i=1, maxItems do
                            setItem("device", tostring(i), app, bank, device)
                        end
                    end

                    updateUI()
                end
            end, i18n("midiTopDeviceToAll"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetEverything" then
            --------------------------------------------------------------------------------
            -- Reset Everything:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local default = copy(mod._midi.defaultLayout)
                    mod.items(default)

                    updateUI()
                end
            end, i18n("midiResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetApplication" then
            --------------------------------------------------------------------------------
            -- Reset Application:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local app = params["application"]

                    local items = mod.items()

                    local default = mod._midi.defaultLayout[app] or {}
                    items[app] = copy(default)

                    mod.items(items)

                    updateUI()
                end
            end, i18n("midiResetGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetBank" then
            --------------------------------------------------------------------------------
            -- Reset Bank:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then

                    local app = params["application"]
                    local bank = params["bank"]

                    local items = mod.items()

                    if not items[app] then items[app] = {} end
                    if not items[app][bank] then items[app][bank] = {} end

                    local default = mod._midi.defaultLayout[app] and mod._midi.defaultLayout[app][bank] or {}
                    items[app][bank] = copy(default)

                    mod.items(items)

                    updateUI()
                end

            end, i18n("midiResetSubGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "copyApplication" then
            --------------------------------------------------------------------------------
            -- Copy Application:
            --------------------------------------------------------------------------------
            local copyApplication = function(destinationApp)
                local items = mod.items()
                local app = mod.lastApplication()

                local data = items[app]
                if data then
                    items[destinationApp] = fnutils.copy(data)
                    mod.items(items)
                end
            end

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

            local menu = {}

            table.insert(menu, {
                title = string.upper(i18n("copyActiveApplicationTo")) .. ":",
                disabled = true,
            })

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            for i, v in spairs(builtInApps, function(t,a,b) return t[a] < t[b] end) do
                table.insert(menu, {
                    title = v,
                    fn = function() copyApplication(i) end
                })
            end

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            for i, v in spairs(userApps, function(t,a,b) return t[a] < t[b] end) do
                table.insert(menu, {
                    title = v,
                    fn = function() copyApplication(i) end
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.getAbsolutePosition(), true)
        elseif callbackType == "copyBank" then
            --------------------------------------------------------------------------------
            -- Copy Bank:
            --------------------------------------------------------------------------------
            local numberOfBanks = mod.numberOfBanks

            local copyToBank = function(destinationBank)
                local items = mod.items()
                local app = mod.lastApplication()
                local bank = mod.lastBank()

                local data = items[app] and items[app][bank]
                if data then
                    items[app][destinationBank] = fnutils.copy(data)
                    mod.items(items)
                end
            end

            local menu = {}

            table.insert(menu, {
                title = string.upper(i18n("copyActiveBankTo")) .. ":",
                disabled = true,
            })

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            for i=1, numberOfBanks do
                table.insert(menu, {
                    title = tostring(i),
                    fn = function() copyToBank(tostring(i)) end
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.getAbsolutePosition(), true)
        elseif callbackType == "openAudioMIDISetup" then
            hs.open("/Applications/Utilities/Audio MIDI Setup.app")
        elseif callbackType == "importSettings" then
            --------------------------------------------------------------------------------
            -- Import Settings:
            --------------------------------------------------------------------------------
            local importSettings = function(action)

                local lastImportPath = mod.lastImportPath()
                if not doesDirectoryExist(lastImportPath) then
                    lastImportPath = "~/Desktop"
                    mod.lastImportPath(lastImportPath)
                end

                local path = chooseFileOrFolder(i18n("pleaseSelectAFileToImport") .. ":", lastImportPath, true, false, false, {"cpMIDI"})
                if path and path["1"] then
                    local data = json.read(path["1"])
                    if data then
                        if action == "replace" then
                            mod.items(data)
                        elseif action == "merge" then
                            local original = mod.items()
                            local combined = mergeTable(original, data)
                            mod.items(combined)
                        end
                        mod._manager.refresh()
                    end
                end
            end

            local menu = {}

            table.insert(menu, {
                title = string.upper(i18n("importSettings")) .. ":",
                disabled = true,
            })

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            table.insert(menu, {
                title = i18n("replace"),
                fn = function() importSettings("replace") end,
            })

            table.insert(menu, {
                title = i18n("merge"),
                fn = function() importSettings("merge") end,
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.getAbsolutePosition(), true)
        elseif callbackType == "exportSettings" then
            --------------------------------------------------------------------------------
            -- Export Settings:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]

            local exportSettings = function(what)
                local items = mod.items()
                local data = {}

                local filename = ""

                if what == "Everything" then
                    data = copy(items)
                    filename = "Everything"
                elseif what == "Application" then
                    data[app] = copy(items[app])
                    filename = app
                elseif what == "Bank" then
                    data[app] = {}
                    data[app][bank] = copy(items[app][bank])
                    filename = "Bank " .. bank
                end

                local lastExportPath = mod.lastExportPath()
                if not doesDirectoryExist(lastExportPath) then
                    lastExportPath = "~/Desktop"
                    mod.lastExportPath(lastExportPath)
                end

                local path = chooseFileOrFolder(i18n("pleaseSelectAFolderToExportTo") .. ":", lastExportPath, false, true, false)
                if path and path["1"] then
                    mod.lastExportPath(path["1"])
                    json.write(path["1"] .. "/" .. filename .. " - " .. os.date("%Y%m%d %H%M") .. ".cpMIDI", data)
                end
            end

            local menu = {}

            table.insert(menu, {
                title = string.upper(i18n("exportSettings")) .. ":",
                disabled = true,
            })

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            table.insert(menu, {
                title = i18n("everything"),
                fn = function() exportSettings("Everything") end,
            })

            table.insert(menu, {
                title = i18n("currentApplication"),
                fn = function() exportSettings("Application") end,
            })

            table.insert(menu, {
                title = i18n("currentBank"),
                fn = function() exportSettings("Bank") end,
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.getAbsolutePosition(), true)
        elseif callbackType == "changeIgnore" then
            --------------------------------------------------------------------------------
            -- Change Ignore:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local ignore = params["ignore"]

            local items = mod.items()

            if not items[app] then items[app] = {} end
            items[app]["ignore"] = ignore

            mod.items(items)
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

    mod.numberOfBanks   = deps.manager.NUMBER_OF_BANKS

    --------------------------------------------------------------------------------
    -- Refresh the webview if MIDI devices are added or removed.
    -- There's a slight delay on this, otherwise CommandPost gets stuck in an
    -- infinite loop.
    --------------------------------------------------------------------------------
    mod._refreshTimer = delayed.new(0.2, function()
        if mod._manager._webview ~= nil and mod._manager.currentPanelID() == panelID then
            --log.df("Refreshing MIDI Preferences as number of MIDI Devices have changed.")
            updateUI()
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
        image           = imageFromPath(config.bundledPluginsPath .. "/core/midi/prefs/images/AudioMIDISetup.icns"),
        tooltip         = i18n("midi"),
        height          = 800,
        closeFn         = destroyMIDIWatchers,
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

        :addContent(10, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "midiPanelCallback", midiPanelCallback)

    return mod
end

return plugin
