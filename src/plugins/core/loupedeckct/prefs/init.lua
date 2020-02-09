--- === plugins.core.loupedeckct.prefs ===
---
--- Loupedeck CT Preferences Panel

local require = require

local log           = require "hs.logger".new "prefsLoupedeckCT"

local dialog        = require "hs.dialog"
local image         = require "hs.image"
local inspect       = require "hs.inspect"

local commands      = require "cp.commands"
local config        = require "cp.config"
local json          = require "cp.json"


local i18n          = require "cp.i18n"
local tools         = require "cp.tools"

local moses         = require "moses"
local default       = require "default"

local webviewAlert  = dialog.webviewAlert

local mod = {}





-- Hardcoded for now:
local apps = {
    ["com.apple.finder"] = "Finder",
    ["com.apple.FinalCut"] = "Final Cut Pro",
}





--- plugins.core.loupedeckct.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Application used in the Preferences Panel.
mod.lastApplication = config.prop("loupedeckct.preferences.lastApplication", "com.apple.FinalCut")

--- plugins.core.loupedeckct.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastBank = config.prop("loupedeckct.preferences.lastBank", "1")

--- plugins.core.loupedeckct.prefs.lastSelectedControl <cp.prop: string>
--- Field
--- Last Selected Control used in the Preferences Panel.
mod.lastSelectedControl = config.prop("loupedeckct.preferences.lastSelectedControl", "1")





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
            items({})
            mod._manager.refresh()
        end
    end, i18n("loupedeckResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- resetApplication() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected group (including all sub-groups).
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetApplication()
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

-- resetBank() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected sub-group.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetBank()
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
    -- Get last values to populate the UI when it first loads:
    --------------------------------------------------------------------------------
    local lastApplication = mod.lastApplication()
    local lastBank = mod.lastBank()
    local lastSelectedControl = mod.lastSelectedControl()

    local lastBankLabel = ""
    local lastPressValue = ""
    local lastLeftValue = ""
    local lastRightValue = ""
    local lastColorValue = "FFFFFF"

    if mod.items[lastApplication] and mod.items[lastApplication][lastBank] then
        if mod.items[lastApplication][lastBank]["bankLabel"] then
           lastBankLabel = mod.items[lastApplication][lastBank]["bankLabel"]
        end

        if mod.items[lastApplication][lastBank][lastSelectedControl] then

            if mod.items[lastApplication][lastBank][lastSelectedControl]["Left"] then
                if mod.items[lastApplication][lastBank][lastSelectedControl]["Left"]["actionTitle"] then
                    lastLeftValue = mod.items[lastApplication][lastBank][lastSelectedControl]["Left"]["actionTitle"]
                end
            end

            if mod.items[lastApplication][lastBank][lastSelectedControl]["Right"] then
                if mod.items[lastApplication][lastBank][lastSelectedControl]["Right"]["actionTitle"] then
                    lastLeftValue = mod.items[lastApplication][lastBank][lastSelectedControl]["Right"]["actionTitle"]
                end
            end

            if mod.items[lastApplication][lastBank][lastSelectedControl]["Press"] then
                if mod.items[lastApplication][lastBank][lastSelectedControl]["Press"]["actionTitle"] then
                    lastLeftValue = mod.items[lastApplication][lastBank][lastSelectedControl]["Press"]["actionTitle"]
                end
            end

            if mod.items[lastApplication][lastBank][lastSelectedControl]["LED"] then
                lastColorValue = mod.items[lastApplication][lastBank][lastSelectedControl]["LED"]
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup the context:
    --------------------------------------------------------------------------------
    local context = {
        apps                        = apps,

        numberOfSubGroups           = 9,
        i18n                        = i18n,

        lastApplication             = lastApplication,
        lastBank                    = lastBank,
        lastSelectedControl         = lastSelectedControl,
        lastBankLabel               = lastBankLabel,
        lastPressValue              = lastPressValue,
        lastLeftValue               = lastLeftValue,
        lastRightValue              = lastRightValue,
        lastColorValue              = lastColorValue,
    }

    return renderPanel(context)
end

local translateGroupID = {
    ["com.apple.FinalCut"] = "fcpx"
}

-- loupedeckCTPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function loupedeckCTPanelCallback(id, params)
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
                        if handlerTable[1] == groupID or handlerTable[1] == translateGroupID[groupID] or handlerTable[1] == "global" then
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
                    if groupID == "com.apple.FinalCut" then
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

                --------------------------------------------------------------------------------
                -- Update the preferences file:
                --------------------------------------------------------------------------------
                local a = params["application"]
                local b = params["bank"]
                local c = params["selectedControl"]
                local d = params["buttonType"]

                local items = mod.items()

                if not items[a] then items[a] = {} end
                if not items[a][b] then items[a][b] = {} end
                if not items[a][b][c] then items[a][b][c] = {} end
                if not items[a][b][c][d] then items[a][b][c][d] = {} end

                items[a][b][c][d]["actionTitle"] = actionTitle
                items[a][b][c][d]["handlerID"] = handlerID
                items[a][b][c][d]["action"] = action

                mod.items(items)

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
            local a = params["application"]
            local b = params["bank"]
            local c = params["selectedControl"]
            local d = params["buttonType"]

            local items = mod.items()

            if items[a] and items[a][b] and items[a][b][c] and items[a][b][c][d] then
                items[a][b][c][d] = nil
            end

            mod.items(items)
        elseif callbackType == "updateApplicationAndBank" then
            mod.lastApplication(params["application"])
            mod.lastBank(params["bank"])
            mod._manager.refresh()
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update UI:
            --------------------------------------------------------------------------------
            local a = params["application"]
            local b = params["bank"]
            local c = params["selectedControl"]

            mod.lastSelectedControl(c)

            local pressValue = ""
            local leftValue = ""
            local rightValue = ""
            local colorValue = "FFFFFF"

            local items = mod.items()

            if items[a] and items[a][b] and items[a][b][c] then
                if items[a][b][c]["Left"] then
                    if items[a][b][c]["Left"]["actionTitle"] then
                        leftValue = items[a][b][c]["Left"]["actionTitle"]
                    end
                end

                if items[a][b][c]["Right"] then
                    if items[a][b][c]["Right"]["actionTitle"] then
                        rightValue = items[a][b][c]["Right"]["actionTitle"]
                    end
                end

                if items[a][b][c]["Press"] then
                    if items[a][b][c]["Press"]["actionTitle"] then
                        pressValue = items[a][b][c]["Press"]["actionTitle"]
                    end
                end

                if items[a][b][c]["LED"] then
                    colorValue = items[a][b][c]["LED"]
                end
            end

            injectScript([[
                changeValueByID('press_action', ']] .. pressValue .. [[');
                changeValueByID('left_action', ']] .. leftValue .. [[');
                changeValueByID('right_action', ']] .. rightValue .. [[');
                changeColor(']] .. colorValue .. [[');
            ]])
        elseif callbackType == "updateColor" then
            --------------------------------------------------------------------------------
            -- Update Color:
            --------------------------------------------------------------------------------
            local a = params["application"]
            local b = params["bank"]
            local c = params["selectedControl"]
            local v = params["value"]

            local items = mod.items()

            if not items[a] then items[a] = {} end
            if not items[a][b] then items[a][b] = {} end
            if not items[a][b][c] then items[a][b][c] = {} end

            items[a][b][c]["LED"] = v

            mod.items(items)
        elseif callbackType == "updateBankLabel" then
            --------------------------------------------------------------------------------
            -- Update Bank Label:
            --------------------------------------------------------------------------------
            local a = params["application"]
            local b = params["bank"]

            local items = mod.items()

            if not items[a] then items[a] = {} end
            if not items[a][b] then items[a][b] = {} end
            items[a][b]["bankLabel"] = params["bankLabel"]

            mod.items(items)
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Loupedeck CT Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

-- plugins.core.loupedeckct.prefs._displayBooleanToString(value) -> none
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

--- plugins.core.loupedeckct.prefs.init(deps, env) -> module
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
    local panelID = "loupedeckct"

    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._manager        = deps.manager
    mod._webviewLabel   = deps.manager.getLabel()
    mod._actionmanager  = deps.actionmanager
    mod._env            = env

    mod._ctmanager      = deps.ctmanager
    mod.items           = deps.ctmanager.items
    mod.enabled         = deps.ctmanager.enabled

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2033.1,
        id              = panelID,
        label           = "Loupedeck CT",
        image           = image.imageFromPath(env:pathToAbsolute("/images/loupedeck.icns")),
        tooltip         = "Loupedeck CT",
        height          = 730,
    })
        :addHeading(6, "Loupedeck CT")
        :addCheckbox(7,
            {
                label       = "Enable Loupedeck CT Support",
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
                onclick     = resetApplication,
                class       = "loupedeckResetGroup",
            }
        )
        :addButton(15,
            {
                label       = i18n("resetBank"),
                onclick     = resetBank,
                class       = "loupedeckResetGroup",
            }
        )

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "loupedeckCTPanelCallback", loupedeckCTPanelCallback)

    return mod

end

local plugin = {
    id              = "core.loupedeckct.prefs",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]        = "manager",
        ["core.action.manager"]             = "actionmanager",
        ["core.loupedeckct.manager"]        = "ctmanager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
