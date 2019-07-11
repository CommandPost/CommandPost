--- === plugins.core.loupedeck.prefs ===
---
--- Loupedeck Preferences Panel

local require = require

local log           = require "hs.logger".new "prefsLoupedeck"

local dialog        = require "hs.dialog"
local image         = require "hs.image"
local inspect       = require "hs.inspect"
local midi          = require "hs.midi"
local timer         = require "hs.timer"

local commands      = require "cp.commands"
local config        = require "cp.config"
local html          = require "cp.web.html"
local i18n          = require "cp.i18n"
local json          = require "cp.json"
local tools         = require "cp.tools"

local moses         = require "moses"

local delayed       = timer.delayed

local mod = {}

--- plugins.core.midi.manager.DEFAULT_CONTROLS -> table
--- Constant
--- The default MIDI controls, so that the user has a starting point.
mod.DEFAULT_CONTROLS = default

--- plugins.core.loupedeck.prefs.enabled <cp.prop: boolean>
--- Field
--- Enable or disable MIDI Support.
mod.enabled = config.prop("enableLoupedeck", false)

--- plugins.core.loupedeck.prefs.FILE_NAME -> string
--- Constant
--- File name of settings file.
mod.FILE_NAME = "Default.cpLoupedeck"

--- plugins.core.loupedeck.prefs.FOLDER_NAME -> string
--- Constant
--- Folder Name where settings file is contained.
mod.FOLDER_NAME = "Loupedeck"

-- plugins.core.loupedeck.prefs._items <cp.prop: table>
-- Field
-- Contains all the saved MIDI items
mod.items = json.prop(config.userConfigRootPath, mod.FOLDER_NAME, mod.FILE_NAME, {})

--- plugins.core.loupedeck.prefs.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("loupedeckPreferencesLastGroup", nil)

--- plugins.core.loupedeck.prefs.updateAction(button, group, actionTitle, handlerID, action) -> none
--- Function
--- Updates a Loupedeck action.
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
    local items = mod.items()

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

    mod.items(items)
end

-- plugins.core.loupedeck.prefs._resetMIDI() -> none
-- Function
-- Prompts to reset shortcuts to default for all groups.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._resetEverything()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            mod._midi.clear()
            mod._manager.refresh()
        end
    end, i18n("midiResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- plugins.core.loupedeck.prefs._resetMIDIGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected group (including all sub-groups).
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._resetEverythingGroup()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local items = mod.items()
            local currentGroup = string.sub(mod.lastGroup(), 1, -2)
            for groupAndSubgroupID in pairs(items) do
                if string.sub(groupAndSubgroupID, 1, -2) == currentGroup then
                    items[groupAndSubgroupID] = mod.DEFAULT_CONTROLS[groupAndSubgroupID]
                end
            end
            mod.items(items)
            mod._manager.refresh()
        end
    end, i18n("midiResetGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- plugins.core.loupedeck.prefs._resetMIDISubGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected sub-group.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._resetEverythingSubGroup()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local items = mod.items()
            local groupID = mod.lastGroup()
            items[groupID] = mod.DEFAULT_CONTROLS[groupID]
            mod.items(items)
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

-- loupedeckPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function loupedeckPanelCallback(id, params)
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
                mod.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action)
                --setValue(params["groupID"], params["buttonID"], "action", actionTitle)

                mod._manager.injectScript("setButtonPressActionValue('" .. actionTitle .. "');")

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

-- plugins.core.loupedeck.prefs._displayBooleanToString(value) -> none
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

--- plugins.core.loupedeck.prefs.init(deps, env) -> module
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
    local panelID = "loupedeck"

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
        id              = panelID,
        label           = "Loupedeck",
        image           = image.imageFromPath(env:pathToAbsolute("/images/loupedeck.icns")),
        tooltip         = "Loupedeck",
        height          = 720,
    })
        :addHeading(6, "Loupedeck+")
        :addCheckbox(7,
            {
                label       = "Enable Loupedeck+ Support",
                checked     = mod.enabled,
                onchange    = function(_, params)
                    mod.enabled(params.checked)
                end,
            }
        )
        :addContent(10, generateContent, false)

        :addButton(13,
            {
                label       = i18n("resetEverything"),
                onclick     = mod._resetEverything,
                class       = "applyTopDeviceToAll",
            }
        )
        :addButton(14,
            {
                label       = i18n("resetApplication"),
                onclick     = mod._resetEverythingGroup,
                class       = "loupedeckResetGroup",
            }
        )
        :addButton(15,
            {
                label       = i18n("resetBank"),
                onclick     = mod._resetEverythingSubGroup,
                class       = "loupedeckResetGroup",
            }
        )

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "loupedeckPanelCallback", loupedeckPanelCallback)

    return mod

end

local plugin = {
    id              = "core.loupedeck.prefs",
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
