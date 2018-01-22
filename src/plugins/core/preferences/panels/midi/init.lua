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
local log                                       = require("hs.logger").new("prefsMIDI")

local dialog                                    = require("hs.dialog")
local image                                     = require("hs.image")
local inspect                                   = require("hs.inspect")
local midi                                      = require("hs.midi")
local timer                                     = require("hs.timer")

local commands                                  = require("cp.commands")
local config                                    = require("cp.config")
local tools                                     = require("cp.tools")
local ui                                        = require("cp.web.ui")

local _                                         = require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.panels.midi.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Stream Deck Support.
mod.enabled = config.prop("enableMIDI", false)

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

-- renderRows(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderRows(context)
    if not mod._renderRows then
        local err
        mod._renderRows, err = mod._env:compileTemplate("html/rows.html")
        if err then
            error(err)
        end
    end
    return mod._renderRows(context)
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
    local groupOptions = {}
    local defaultGroup = nil
    if mod.lastGroup() then defaultGroup = mod.lastGroup() end -- Get last group from preferences.
    for _,id in ipairs(commands.groupIds()) do
        defaultGroup = defaultGroup or id
        groupOptions[#groupOptions+1] = { value = id, label = i18n("shortcut_group_"..id, {default = id})}
    end
    table.sort(groupOptions, function(a, b) return a.label < b.label end)
    mod.lastGroup(defaultGroup)

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
                webkit.messageHandlers.]] .. mod._manager.getLabel() .. [[.postMessage(result);
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
    ]])


    local context = {
        _                       = _,
        midiGroupSelect         = midiGroupSelect,
        groups                  = commands.groups(),
        defaultGroup            = defaultGroup,

        groupEditor             = mod.getGroupEditor,

        webviewLabel            = mod._manager.getLabel(),

        maxItems                = mod._midi.maxItems,
        midi                    = mod._midi,
        i18n                    = i18n,
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
                    -- Support 14bit Control Change Messages:
                    --------------------------------------------------------------------------------
                    local controllerValue = metadata.controllerValue
                    if metadata.fourteenBitCommand then
                        controllerValue = metadata.fourteenBitValue
                    end

                    --------------------------------------------------------------------------------
                    -- Ignore NoteOff Commands:
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

                                --------------------------------------------------------------------------------
                                -- Duplicate Found:
                                --------------------------------------------------------------------------------
                                if deviceMatch and match then
                                    --------------------------------------------------------------------------------
                                    -- Reset the current line item:
                                    --------------------------------------------------------------------------------
                                    setValue(params["groupID"], params["buttonID"], "device", "")
                                    mod._midi.setItem("device", params["buttonID"], params["groupID"], nil)

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

                    setValue(params["groupID"], params["buttonID"], "channel", metadata.channel)
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

                        setValue(params["groupID"], params["buttonID"], "number", "Pitch")
                        mod._midi.setItem("number", params["buttonID"], params["groupID"], "Pitch")

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
            log.df("Unknown Callback in Stream Deck Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

--- plugins.core.preferences.panels.midi.setGroupEditor(groupId, editorFn) -> none
--- Function
--- Sets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---  * editorFn - Editor Function
---
--- Returns:
---  * None
function mod.setGroupEditor(groupId, editorFn)
    if not mod._groupEditors then
        mod._groupEditors = {}
    end
    mod._groupEditors[groupId] = editorFn
end

--- plugins.core.preferences.panels.midi.getGroupEditor(groupId) -> none
--- Function
--- Gets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---
--- Returns:
---  * Group Editor
function mod.getGroupEditor(groupId)
    return mod._groupEditors and mod._groupEditors[groupId]
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
    if mod.enabled() then
        return 650
    else
        return 210
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
        :addHeading(6, i18n("midiControls"))
        :addCheckbox(7,
            {
                label       = i18n("enableMIDI"),
                checked     = mod.enabled,
                onchange    = function(_, params)
                    --------------------------------------------------------------------------------
                    -- Toggle Preference:
                    --------------------------------------------------------------------------------
                    mod.enabled(params.checked)

                    --------------------------------------------------------------------------------
                    -- Resize Window:
                    --------------------------------------------------------------------------------
                    local currentSize = mod._manager.webview:size()
                    currentSize["h"] = mod._calculateHeight()
                    mod._manager.webview:size(currentSize)

                    --------------------------------------------------------------------------------
                    -- Update UI:
                    --------------------------------------------------------------------------------
                    mod._manager.injectScript([[
                        document.getElementById("midiEditor").style.display = "]] .. mod._displayBooleanToString(params.checked) .. [["
                    ]])
                end,
            }
        )
        :addButton(7.1,
            {
                label       = i18n("openAudioMIDISetup"),
                onclick     = function() hs.open("/Applications/Utilities/Audio MIDI Setup.app") end,
                class       = "openAudioMIDISetup",
            }
        )
        :addContent(8, [[<div id="midiEditor" style="display:]] .. mod._displayBooleanToString(mod.enabled()) .. [[;">]], true)
        :addContent(10, generateContent, true)
        :addButton(11,
            {
                label       = i18n("refreshMidi"),
                onclick     = mod._manager.refresh,
                class       = "refreshMidi",
            }
        )
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
                class       = "midiResetAll",
            }
        )

        :addContent(23, [[</div>]], true)

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