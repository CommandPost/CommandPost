--- === plugins.core.loupedeckplus.prefs ===
---
--- Loupedeck+ Preferences Panel

local require = require

local log           = require "hs.logger".new "prefsLoupedeck"

local dialog        = require "hs.dialog"
local image         = require "hs.image"
local inspect       = require "hs.inspect"

local commands      = require "cp.commands"
local config        = require "cp.config"
local i18n          = require "cp.i18n"
local tools         = require "cp.tools"

local moses         = require "moses"
local default       = require "default"

local webviewAlert  = dialog.webviewAlert

local mod = {}

--- plugins.core.midi.manager.DEFAULT_CONTROLS -> table
--- Constant
--- The default MIDI controls, so that the user has a starting point.
mod.DEFAULT_CONTROLS = default

--- plugins.core.loupedeckplus.prefs.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("loupedeck.preferences.lastGroup", nil)

--- plugins.core.loupedeckplus.prefs.lastNote <cp.prop: string>
--- Field
--- Last note used in the Preferences panel.
mod.lastNote = config.prop("loupedeck.preferences.lastNote", "95")

--- plugins.core.loupedeckplus.prefs.lastIsButton <cp.prop: boolean>
--- Field
--- Whether or not the last selected item in the Preferences was a button.
mod.lastIsButton = config.prop("loupedeck.preferences.lastIsButton", true)

--- plugins.core.loupedeckplus.prefs.lastLabel <cp.prop: string>
--- Field
--- Last label used in the Preferences panel.
mod.lastLabel = config.prop("loupedeck.preferences.lastLabel", "Undo")

--- plugins.core.loupedeckplus.prefs.updateAction(button, group, actionTitle, handlerID, action) -> none
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

-- setBankLabel(group, label) -> none
-- Function
-- Sets a Loupedeck Bank Label.
--
-- Parameters:
--  * group - Group ID as string
--  * label - Label as string
--
-- Returns:
--  * None
local function setBankLabel(group, label)
    local items = mod.items()

    if not items[group] then
        items[group] = {}
    end
    items[group]["bankLabel"] = label

    mod.items(items)
end

-- resetEverything() -> none
-- Function
-- Prompts to reset shortcuts to default for all groups.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetEverything()
    webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            mod.items(mod.DEFAULT_CONTROLS)
            mod._manager.refresh()
        end
    end, i18n("loupedeckResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- resetEverythingGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected group (including all sub-groups).
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetEverythingGroup()
    webviewAlert(mod._manager.getWebview(), function(result)
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
    end, i18n("loupedeckResetGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- resetEverythingSubGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected sub-group.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetEverythingSubGroup()
    webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local items = mod.items()
            local groupID = mod.lastGroup()
            items[groupID] = mod.DEFAULT_CONTROLS[groupID]
            mod.items(items)
            mod._manager.refresh()
        end
    end, i18n("loupedeckResetSubGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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

    --------------------------------------------------------------------------------
    -- Get last values to populate the UI when it first loads:
    --------------------------------------------------------------------------------
    local groupID = defaultGroup
    local note = mod.lastNote()
    local items = mod.items()

    local pressValue = i18n("none")
    local leftValue = i18n("none")
    local rightValue = i18n("none")

    local bankLabel

    if items[groupID] then
        bankLabel = items[groupID]["bankLabel"]
        if items[groupID][note .. "Press"] then
            if items[groupID][note .. "Press"]["actionTitle"] then
                pressValue = items[groupID][note .. "Press"]["actionTitle"]
            end
        end
        if items[groupID][note .. "Left"] then
            if items[groupID][note .. "Left"]["actionTitle"] then
                leftValue = items[groupID][note .. "Left"]["actionTitle"]
            end
        end
        if items[groupID][note .. "Right"] then
            if items[groupID][note .. "Right"]["actionTitle"] then
                rightValue = items[groupID][note .. "Right"]["actionTitle"]
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup the context:
    --------------------------------------------------------------------------------
    local context = {
        _                           = moses,
        numberOfSubGroups           = numberOfSubGroups,
        groupLabels                 = groupLabels,
        groups                      = groups,
        defaultGroup                = defaultGroup,
        bankLabel                   = bankLabel,
        i18n                        = i18n,

        lastNote                    = mod.lastNote(),
        lastIsButton                = mod.lastIsButton(),
        lastLabel                   = mod.lastLabel(),

        lastPressValue              = pressValue,
        lastLeftValue               = leftValue,
        lastRightValue              = rightValue,
    }

    return renderPanel(context)
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
                    mod.activator[groupID] = mod._actionmanager.getActivator("loupedeckPreferences" .. groupID)

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
                            if handlerTable[2] ~= "widgets" and handlerTable[2] ~= "midicontrols" and v ~= "global_menuactions" then
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

            local activatorID
            if string.sub(groupID, -2) == "fn" then
                --------------------------------------------------------------------------------
                -- Remove the "fn":
                --------------------------------------------------------------------------------
                activatorID = groupID:sub(1, -4)
            else
                activatorID = groupID:sub(1, -2)
            end

            mod.activator[activatorID]:onActivate(function(handler, action, text)
                --------------------------------------------------------------------------------
                -- Process Stylised Text:
                --------------------------------------------------------------------------------
                if text and type(text) == "userdata" then
                    text = text:convert("text")
                end
                local actionTitle = text
                local handlerID = handler:id()

                --------------------------------------------------------------------------------
                -- Update the preferences file:
                --------------------------------------------------------------------------------
                mod.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action)

                --------------------------------------------------------------------------------
                -- Update the webview:
                --------------------------------------------------------------------------------
                if params["buttonType"] == "Press" then
                    injectScript("changeValueByID('press_action', '" .. actionTitle .. "');")
                elseif params["buttonType"] == "Left" then
                    injectScript("changeValueByID('left_action', '" .. actionTitle .. "');")
                elseif params["buttonType"] == "Right" then
                    injectScript("changeValueByID('right_action', '" .. actionTitle .. "');")
                end
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[activatorID]:show()
        elseif callbackType == "clearAction" then
            --------------------------------------------------------------------------------
            -- Clear an action:
            --------------------------------------------------------------------------------
            mod.updateAction(params["buttonID"], params["groupID"], nil, nil, nil)

            if params["buttonType"] == "Press" then
                injectScript("changeValueByID('press_action', '" .. i18n("none") .. "');")
            elseif params["buttonType"] == "Left" then
                injectScript("changeValueByID('left_action', '" .. i18n("none") .. "');")
            elseif params["buttonType"] == "Right" then
                injectScript("changeValueByID('right_action', '" .. i18n("none") .. "');")
            end
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update the webview UI:
            --------------------------------------------------------------------------------
            local groupID = params["groupID"]
            local note = params["note"]
            local items = mod.items()

            local pressValue = i18n("none")
            local leftValue = i18n("none")
            local rightValue = i18n("none")

            if items[groupID] then
                if items[groupID][note .. "Press"] then
                    if items[groupID][note .. "Press"]["actionTitle"] then
                        pressValue = items[groupID][note .. "Press"]["actionTitle"]
                    end
                end
                if items[groupID][note .. "Left"] then
                    if items[groupID][note .. "Left"]["actionTitle"] then
                        leftValue = items[groupID][note .. "Left"]["actionTitle"]
                    end
                end
                if items[groupID][note .. "Right"] then
                    if items[groupID][note .. "Right"]["actionTitle"] then
                        rightValue = items[groupID][note .. "Right"]["actionTitle"]
                    end
                end
            end

            mod.lastNote(note)
            mod.lastIsButton(params["isButton"])
            mod.lastLabel(params["label"])

            injectScript([[
                changeValueByID('press_action', ']] .. pressValue .. [[');
                changeValueByID('left_action', ']] .. leftValue .. [[');
                changeValueByID('right_action', ']] .. rightValue .. [[');
            ]])
        elseif callbackType == "updateGroup" then
            --------------------------------------------------------------------------------
            -- Update Group:
            -- Change the Loupedeck+ Bank as you change the group drop down:
            --------------------------------------------------------------------------------
            mod._midi.forceLoupedeckGroupChange(params["groupID"], mod.enabled())
            mod.lastGroup(params["groupID"])
            mod._manager.refresh()
        elseif callbackType == "updateBankLabel" then
            local groupID = params["groupID"]
            local bankLabel = params["bankLabel"]
            setBankLabel(groupID, bankLabel)
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Loupedeck+ Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

-- plugins.core.loupedeckplus.prefs._displayBooleanToString(value) -> none
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

--- plugins.core.loupedeckplus.prefs.init(deps, env) -> module
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

    mod.items           = mod._midi._loupedeckItems
    mod.enabled         = mod._midi.enabledLoupedeck

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2033,
        id              = panelID,
        label           = i18n("loupedeckPlus"),
        image           = image.imageFromPath(env:pathToAbsolute("/images/loupedeck.icns")),
        tooltip         = i18n("loupedeckPlus"),
        height          = 720,
    })
        :addHeading(6, "Loupedeck+")
        :addCheckbox(7,
            {
                label       = i18n("enableLoupdeckSupport"),
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
                onclick     = resetEverything,
                class       = "applyTopDeviceToAll",
            }
        )
        :addButton(14,
            {
                label       = i18n("resetApplication"),
                onclick     = resetEverythingGroup,
                class       = "loupedeckResetGroup",
            }
        )
        :addButton(15,
            {
                label       = i18n("resetBank"),
                onclick     = resetEverythingSubGroup,
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
    id              = "core.loupedeckplus.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.midi.manager"]               = "midi",
        ["core.action.manager"]             = "actionmanager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
