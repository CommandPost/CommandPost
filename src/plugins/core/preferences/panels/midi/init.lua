--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 M I D I    P R E F E R E N C E S    P A N E L              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.midi ===
---
--- MIDI Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("prefsMIDI")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog                                    = require("hs.dialog")
local image                                     = require("hs.image")
local inspect                                   = require("hs.inspect")
local midi                                      = require("hs.midi")
local timer                                     = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local commands                                  = require("cp.commands")
local config                                    = require("cp.config")
local tools                                     = require("cp.tools")
local html                                      = require("cp.web.html")
local ui                                        = require("cp.web.ui")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _                                         = require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.panels.midi.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("midiPreferencesLastGroup", nil)

-- plugins.core.preferences.panels.midi.resetMIDI() -> none
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

-- plugins.core.preferences.panels.midi.resetMIDIGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected group.
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
            items[mod.lastGroup()] = nil
            mod._midi._items(items)
            mod._manager.refresh()
        end
    end, i18n("midiResetGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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
    -- The Group Select:
    --------------------------------------------------------------------------------
    local groups = {}
    local groupOptions = {}
    local defaultGroup = nil
    if mod.lastGroup() then defaultGroup = mod.lastGroup() end -- Get last group from preferences.
    for _,id in ipairs(commands.groupIds()) do
        for subGroupID=1, mod._midi.numberOfSubGroups do
            defaultGroup = defaultGroup or id .. subGroupID
            groupOptions[#groupOptions+1] = { value = id .. subGroupID, label = i18n("shortcut_group_" .. id, {default = id}) .. " (Bank " .. tostring(subGroupID) .. ")"}
            groups[#groups + 1] = id .. subGroupID
        end
    end
    table.sort(groupOptions, function(a, b) return a.label < b.label end)

    local midiGroupSelect = ui.select({
        id          = "midiGroupSelect",
        value       = defaultGroup,
        options     = groupOptions,
        required    = true,
    }) .. ui.javascript([[
        var midiGroupSelect = document.getElementById("midiGroupSelect")
        midiGroupSelect.onchange = function(e) {
            try {
                var result = {
                    id: "midiPanelCallback",
                    params: {
                        type: "updateGroup",
                        groupID: this.value,
                    },
                }
                webkit.messageHandlers.{{ label }}.postMessage(result);
            } catch(err) {
                console.log("Error: " + err)
                alert('An error has occurred. Does the controller exist yet?');
            }

            console.log("midiGroupSelect changed");
            var groupControls = document.getElementById("midiGroupControls");
            var value = midiGroupSelect.options[midiGroupSelect.selectedIndex].value;
            var children = groupControls.children;
            for (var i = 0; i < children.length; i++) {
              var child = children[i];
              if (child.id == "midiGroup_" + value) {
                  child.classList.add("selected");
              } else {
                  child.classList.remove("selected");
              }
            }
        }
    ]], {label = mod._manager.getLabel()})


    local context = {
        _                           = _,
        midiGroupSelect             = midiGroupSelect,
        groups                      = groups,
        defaultGroup                = defaultGroup,
        webviewLabel                = mod._manager.getLabel(),
        maxItems                    = mod._midi.maxItems,
        midiDevices                 = mod._midi.devices(),
        virtualMidiDevices          = mod._midi.virtualDevices(),
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
        i18nAll                     = i18n("all"),
        i18nNoDevicesDetected       = i18n("noDevicesDetected"),
        i18nCommmandType            = i18n("commandType"),
        i18nNoteOff                 = i18n("noteOff"),
        i18nNoteOn                  = i18n("noteOn"),
        i18nPolyphonicKeyPressure   = i18n("polyphonicKeyPressure"),
        i18nControlChange           = i18n("controlChange"),
        i18nProgramChange           = i18n("programChange"),
        i18nChannelPressure         = i18n("channelPressure"),
        i18nPitchWheelChange        = i18n("pitchWheelChange"),
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
    mod._manager.injectScript([[
        document.getElementById("midi]] .. groupID .. [[_button]] .. buttonID .. [[_]] .. field .. [[").value = "]] .. value .. [["
    ]])
end

--- plugins.core.preferences.panels.midi._currentlyLearning -> boolean
--- Variable
--- Are we in learning mode?
mod._currentlyLearning = false

-- plugins.core.preferences.panels.midi._destroyMIDIWatchers() -> none
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

    --------------------------------------------------------------------------------
    -- Garbage Collection:
    --------------------------------------------------------------------------------
    collectgarbage()
end

-- plugins.core.preferences.panels.midi._stopLearning(id, params) -> none
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
    local maxItems = mod._midi.maxItems
    local groupID = params["groupID"]
    local js = ""
    for i=1,maxItems,1 do
        if groupID then
            js = js .. [[document.getElementById("midi]] .. groupID .. [[_button]] .. i .. [[_learnButton").style.visibility = "visible";]] .. "\n"
            js = js .. [[document.getElementById("midi]] .. groupID .. [[_button]] .. i .. [[_learnButton").innerHTML = "]] .. i18n("learn") .. [[";]] .. "\n"
            js = js .. [[document.getElementById("midiGroup_]] .. groupID .. [[").getElementsByTagName("tr")[]] .. i .. [[].style.backgroundColor = "";]]
        end
    end
    mod._manager.injectScript(js)

    --------------------------------------------------------------------------------
    -- Destroy the MIDI watchers:
    --------------------------------------------------------------------------------
    mod._destroyMIDIWatchers()

end

mod._midiCallbackInProgress = {}

-- plugins.core.preferences.panels.midi._startLearning(id, params) -> none
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
    -- Destroy any leftover MIDI Watchers:
    --------------------------------------------------------------------------------
    mod._destroyMIDIWatchers()

    --------------------------------------------------------------------------------
    -- We're currently learning:
    --------------------------------------------------------------------------------
    mod._currentlyLearning = true

    local maxItems = mod._midi.maxItems
    local groupID = params["groupID"]
    local buttonID = params["buttonID"]
    local js = ""
    for i=1,maxItems,1 do
        js = js .. [[document.getElementById("midi]] .. groupID .. [[_button]] .. i .. [[_learnButton").style.visibility = "hidden";]] .. "\n"
        js = js .. [[document.getElementById("midi]] .. groupID .. [[_button]] .. i .. [[_learnButton").style.visibility = "hidden";]] .. "\n"
    end
    js = js .. [[document.getElementById("midi]] .. groupID .. [[_button]] .. buttonID .. [[_learnButton").style.visibility = "visible";]] .. "\n"
    js = js .. [[document.getElementById("midi]] .. groupID .. [[_button]] .. buttonID .. [[_learnButton").innerHTML = "Stop";]] .. "\n"
    mod._manager.injectScript(js)

    --------------------------------------------------------------------------------
    -- Reset the current line item:
    --------------------------------------------------------------------------------
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

    --------------------------------------------------------------------------------
    -- Setup MIDI watchers:
    --------------------------------------------------------------------------------
    mod.learningMidiDeviceNames = midi.devices()
    for _, v in pairs(midi.virtualSources()) do
        table.insert(mod.learningMidiDeviceNames, "virtual_" .. v)
    end
    mod.learningMidiDevices = {}
    for _, deviceName in ipairs(mod.learningMidiDeviceNames) do
        if string.sub(deviceName, 1, 8) == "virtual_" then
            --log.df("Creating new Virtual MIDI Source Watcher: %s", string.sub(deviceName, 9))
            mod.learningMidiDevices[deviceName] = midi.newVirtualSource(string.sub(deviceName, 9))
        else
            --log.df("Creating new MIDI Device Watcher: %s", deviceName)
            mod.learningMidiDevices[deviceName] = midi.new(deviceName)
        end
        if mod.learningMidiDevices[deviceName] then
            mod.learningMidiDevices[deviceName]:callback(function(_, callbackDeviceName, commandType, _, metadata)
                if commandType == "controlChange" or commandType == "noteOn" or commandType == "pitchWheelChange" then

                    --------------------------------------------------------------------------------
                    -- Debugging:
                    --------------------------------------------------------------------------------
                    --log.df("commandType: %s", commandType)
                    --log.df("metadata: %s", hs.inspect(metadata))

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
                    if items[groupID] then
                        for i, item in pairs(items[groupID]) do
                            if buttonID and i ~= tonumber(buttonID) then
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
                                    log.df("Duplicate MIDI Command Found!")
                                    --------------------------------------------------------------------------------
                                    -- Reset the current line item:
                                    --------------------------------------------------------------------------------
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


                                    mod._manager.injectScript([[
                                        document.getElementById("midiGroup_]] .. groupID .. [[").getElementsByTagName("tr")[]] .. i .. [[].style.setProperty("-webkit-transition", "background-color 1s");
                                        document.getElementById("midiGroup_]] .. groupID .. [[").getElementsByTagName("tr")[]] .. i .. [[].style.backgroundColor = "#cc5e53";
                                    ]])
                                    timer.doAfter(3, function()
                                        mod._manager.injectScript([[
                                            document.getElementById("midiGroup_]] .. groupID .. [[").getElementsByTagName("tr")[]] .. i .. [[].style.backgroundColor = "";
                                        ]])
                                    end)
                                    --------------------------------------------------------------------------------
                                    -- Exit the callback:
                                    --------------------------------------------------------------------------------
                                    return
                                end
                            end
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Update the UI & Save Preferences:
                    --------------------------------------------------------------------------------
                    if metadata.isVirtual then
                        setValue(params["groupID"], params["buttonID"], "device", "virtual_" .. callbackDeviceName)
                        mod._midi.setItem("device", params["buttonID"], params["groupID"], "virtual_" .. callbackDeviceName)
                    else
                        setValue(params["groupID"], params["buttonID"], "device", callbackDeviceName)
                        mod._midi.setItem("device", params["buttonID"], params["groupID"], callbackDeviceName)
                    end

                    setValue(params["groupID"], params["buttonID"], "commandType", commandType)
                    mod._midi.setItem("commandType", params["buttonID"], params["groupID"], commandType)

                    setValue(params["groupID"], params["buttonID"], "channel", metadata.channel + 1)
                    mod._midi.setItem("channel", params["buttonID"], params["groupID"], metadata.channel)

                    if commandType == "noteOff" or commandType == "noteOn" then

                        setValue(params["groupID"], params["buttonID"], "number", metadata.note)
                        mod._midi.setItem("number", params["buttonID"], params["groupID"], metadata.note)

                        setValue(params["groupID"], params["buttonID"], "value", i18n("none"))
                        mod._midi.setItem("value", params["buttonID"], params["groupID"], i18n("none"))

                    elseif commandType == "controlChange" then

                        setValue(params["groupID"], params["buttonID"], "number", metadata.controllerNumber)
                        mod._midi.setItem("number", params["buttonID"], params["groupID"], metadata.controllerNumber)

                        setValue(params["groupID"], params["buttonID"], "value", controllerValue)
                        mod._midi.setItem("value", params["buttonID"], params["groupID"], controllerValue)

                    elseif commandType == "pitchWheelChange" then

                        --setValue(params["groupID"], params["buttonID"], "number", "Pitch")
                        --mod._midi.setItem("number", params["buttonID"], params["groupID"], "Pitch")

                        setValue(params["groupID"], params["buttonID"], "value", metadata.pitchChange)
                        mod._midi.setItem("value", params["buttonID"], params["groupID"], metadata.pitchChange)

                    end

                    --------------------------------------------------------------------------------
                    -- Stop Learning:
                    --------------------------------------------------------------------------------
                    mod._stopLearning(id, params)
                end
            end)
        else
            log.ef("MIDI Device did not exist when trying to create watcher: %s", deviceName)
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
    if params and params["type"] then
        if params["type"] == "updateAction" then
            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            if not mod.activator then
                mod.activator = {}
                local handlerIds = mod._actionmanager.handlerIds()
                for _,groupID in ipairs(commands.groupIds()) do
                    for subGroupID=1, mod._midi.numberOfSubGroups do
                        --------------------------------------------------------------------------------
                        -- Create new Activator:
                        --------------------------------------------------------------------------------
                        mod.activator[groupID .. subGroupID] = mod._actionmanager.getActivator("midiPreferences" .. groupID .. subGroupID)

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
                        mod.activator[groupID .. subGroupID]:allowHandlers(unpack(allowedHandlers))
                        mod.activator[groupID .. subGroupID]:preloadChoices()
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
            local groupID = params["groupID"]
            mod.activator[groupID]:onActivate(function(handler, action, text)
                local actionTitle = text
                local handlerID = handler:id()
                mod._midi.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action)
                setValue(params["groupID"], params["buttonID"], "action", actionTitle)
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[groupID]:show()
        elseif params["type"] == "clear" then
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

        elseif params["type"] == "updateNumber" then
            --------------------------------------------------------------------------------
            -- Update Number:
            --------------------------------------------------------------------------------
            --log.df("Updating Device: %s", params["number"])
            mod._midi.setItem("number", params["buttonID"], params["groupID"], params["number"])
        elseif params["type"] == "updateDevice" then
            --------------------------------------------------------------------------------
            -- Update Device:
            --------------------------------------------------------------------------------
            --log.df("Updating Device: %s", params["device"])
            mod._midi.setItem("device", params["buttonID"], params["groupID"], params["device"])

        elseif params["type"] == "updateCommandType" then
            --------------------------------------------------------------------------------
            -- Update Command Type:
            --------------------------------------------------------------------------------
            --log.df("Updating Command Type: %s", params["commandType"])
            mod._midi.setItem("commandType", params["buttonID"], params["groupID"], params["commandType"])
        elseif params["type"] == "updateChannel" then
            --------------------------------------------------------------------------------
            -- Update Channel:
            --------------------------------------------------------------------------------
            --log.df("Updating Channel: %s", params["channel"])
            mod._midi.setItem("channel", params["buttonID"], params["groupID"], params["channel"])
        elseif params["type"] == "updateValue" then
            --------------------------------------------------------------------------------
            -- Update Value:
            --------------------------------------------------------------------------------
            --log.df("Updating Value: %s", params["value"])
            mod._midi.setItem("value", params["buttonID"], params["groupID"], params["value"])
        elseif params["type"] == "updateGroup" then
            --------------------------------------------------------------------------------
            -- Update Group:
            --------------------------------------------------------------------------------
            mod._stopLearning(id, params)
            mod.lastGroup(params["groupID"])
        elseif params["type"] == "learnButton" then
            --------------------------------------------------------------------------------
            -- Learn Button:
            --------------------------------------------------------------------------------
            if mod._currentlyLearning then
                mod._stopLearning(id, params, true)
            else
                mod._startLearning(id, params)
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

-- plugins.core.preferences.panels.midi._displayBooleanToString(value) -> none
-- Function
-- Converts a boolean to a string for use in the CSS block style value.
--
-- Parameters:
--  * value - a boolean value
--
-- Returns:
--  * A string
function mod._displayBooleanToString(value)
    if value then
        return "block"
    else
        return "none"
    end
end

-- plugins.core.preferences.panels.midi._calculateHeight() -> none
-- Function
-- Returns the correct WebView height based on whether MIDI is enabled or not.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A number
function mod._calculateHeight()
    if mod._midi.enabled() then
        return 780
    else
        return 400
    end
end

-- plugins.core.preferences.panels.midi._applyTopDeviceToAll() -> none
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


local function getMIDIDeviceList()
    local midiDevices = mod._midi.devices()
    local virtualMidiDevices = mod._midi.virtualDevices()

    local result = {}

    table.insert(result, {
        value = "",
        label = i18n("none"),
    })

    for _, device in pairs(midiDevices) do
        table.insert(result, {
            value = device,
            label = device,
        })
    end

    for _, device in pairs(virtualMidiDevices) do
        table.insert(result, {
            value = "virtual_" .. device,
            label = device,
        })
    end
    return result
end

--- plugins.core.preferences.panels.midi.init(deps, env) -> module
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
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._midi           = deps.midi
    mod._manager        = deps.manager
    mod._webviewLabel   = deps.manager.getLabel()
    mod._actionmanager  = deps.actionmanager
    mod._env            = env

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2033,
        id              = "midi",
        label           = i18n("midi"),
        image           = image.imageFromPath(tools.iconFallback("/Applications/Utilities/Audio MIDI Setup.app/Contents/Resources/AudioMIDISetup.icns")),
        tooltip         = i18n("midi"),
        height          = mod._calculateHeight,
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
        :addButton(0.3,
            {
                width       = 200,
                label       = i18n("refreshMidi"),
                onclick     = mod._manager.refresh,
                class       = "refreshMidi",
            }
        )
        :addParagraph(5, html.br())
        :addContent(1, ui.style([[
            .midiColumn {
                float: left;
                width: 50%;
            }

            .midiRow {
                clear: left;
            }

            /* Clear floats after the columns */
            .midiRow:after {
                content: "";
                display: table;
                clear: both;
            }
        ]]))
        :addContent(1.01, [[<div class="midiRow">
            <div class="midiColumn">
        ]], false)
        --------------------------------------------------------------------------------
        --
        -- MIDI Machine Control:
        --
        --------------------------------------------------------------------------------
        :addHeading(1.1, i18n("midiMachineControl"))
        :addCheckbox(1.2,
            {
                label       = i18n("transmitMMC"),
                checked     = mod._midi.transmitMMC,
                onchange    = function(_, params)
                    mod._midi.transmitMMC(params.checked)
                end,
            }
        )
        :addSelect(1.3,
            {
                label       = i18n("device"),
                width       = 250,
                value       = mod._midi.transmitMMCDevice,
                options     = getMIDIDeviceList,
                required    = true,
                onchange    = function(_, params)
                    mod._midi.transmitMMCDevice(params.value)
                end,
            }
        )
        :addCheckbox(1.4,
            {
                label       = i18n("listenMMC"),
                checked     = mod._midi.listenMMC,
                onchange    = function(_, params)
                    mod._midi.listenMMC(params.checked)
                end,
            }
        )
        :addSelect(1.5,
            {
                label       = i18n("device"),
                width       = 250,
                value       = mod._midi.listenMMCDevice,
                options     = getMIDIDeviceList,
                required    = true,
                onchange    = function(_, params)
                    mod._midi.listenMMCDevice(params.value)
                end,
            }
        )
        :addContent(1.6, [[
            </div>
            <div class="midiColumn">
        ]], false)
        --------------------------------------------------------------------------------
        --
        -- MIDI TIMECODE (MTC):
        --
        --------------------------------------------------------------------------------
        :addHeading(2, i18n("midiTimecode"))
        :addCheckbox(2.1,
            {
                label       = i18n("transmitMTC"),
                checked     = mod._midi.transmitMTC,
                onchange    = function(_, params)
                    mod._midi.transmitMTC(params.checked)
                end,
            }
        )
        :addSelect(2.2,
            {
                label       = i18n("device"),
                width       = 250,
                value       = mod._midi.transmitMTCDevice,
                options     = getMIDIDeviceList,
                required    = true,
                onchange    = function(_, params)
                    mod._midi.transmitMTCDevice(params.value)
                end,
            }
        )
        :addCheckbox(2.3,
            {
                label       = i18n("listenMTC"),
                checked     = mod._midi.listenMTC,
                onchange    = function(_, params)
                    mod._midi.listenMTC(params.checked)
                end,
            }
        )
        :addSelect(2.4,
            {
                label       = i18n("device"),
                width       = 250,
                value       = mod._midi.listenMTCDevice,
                options     = getMIDIDeviceList,
                required    = true,
                onchange    = function(_, params)
                    mod._midi.listenMTCDevice(params.value)
                end,
            }
        )
        :addContent(2.5, [[
                </div>
            </div>
        ]], false)
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

                    --------------------------------------------------------------------------------
                    -- Resize Window:
                    --------------------------------------------------------------------------------
                    local currentSize = mod._manager._webview:size()
                    currentSize["h"] = mod._calculateHeight()
                    mod._manager._webview:size(currentSize)

                    --------------------------------------------------------------------------------
                    -- Update UI:
                    --------------------------------------------------------------------------------
                    mod._manager.injectScript([[
                        document.getElementById("midiEditor").style.display = "]] .. mod._displayBooleanToString(params.checked) .. [["
                    ]])
                end,
            }
        )
        :addContent(8, [[<div id="midiEditor" style="display:]] .. mod._displayBooleanToString(mod._midi.enabled()) .. [[;">]], false)
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
                label       = i18n("midiResetGroup"),
                onclick     = mod._resetMIDIGroup,
                class       = "midiResetGroup",
            }
        )
        :addButton(14,
            {
                label       = i18n("midiResetAll"),
                onclick     = mod._resetMIDI,
                class       = "midiResetGroup",
            }
        )

        :addContent(23, [[</div>]], false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "midiPanelCallback", midiPanelCallback)

    return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.panels.midi",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]        = "manager",
        ["core.midi.manager"]               = "midi",
        ["core.action.manager"]             = "actionmanager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
