--- === plugins.core.loupedeckct.prefs ===
---
--- Loupedeck CT Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "prefsLoupedeckCT"

local canvas                    = require "hs.canvas"
local dialog                    = require "hs.dialog"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"

local commands                  = require "cp.commands"
local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local moses                     = require "moses"
local default                   = require "default"

local doesDirectoryExist        = tools.doesDirectoryExist
local removeFilenameFromPath    = tools.removeFilenameFromPath
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- Hardcoded for now as a temporary solution:
local apps = {
    ["com.blackmagic-design.DaVinciResolve"] = "DaVinci Resolve",
    ["com.apple.finder"] = "Finder",
    ["com.apple.FinalCut"] = "Final Cut Pro",
    ["org.latenitefilms.CommandPost"] = "CommandPost",
}

--- plugins.core.loupedeckct.prefs.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

--- plugins.core.loupedeckct.prefs.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = config.assetsPath .. "/icons/"

--- plugins.core.loupedeckct.prefs.lastIconPath <cp.prop: string>
--- Field
--- Last icon path.
mod.lastIconPath = config.prop("loupedeckct.preferences.lastIconPath", mod.defaultIconPath)

--- plugins.core.loupedeckct.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Application used in the Preferences Panel.
mod.lastApplication = config.prop("loupedeckct.preferences.lastApplication", "org.latenitefilms.CommandPost")

--- plugins.core.loupedeckct.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastBank = config.prop("loupedeckct.preferences.lastBank", "1")

--- plugins.core.loupedeckct.prefs.lastSelectedControl <cp.prop: string>
--- Field
--- Last Selected Control used in the Preferences Panel.
mod.lastSelectedControl = config.prop("loupedeckct.preferences.lastSelectedControl", "1")

--- plugins.core.loupedeckct.prefs.lastSelectedControl <cp.prop: string>
--- Field
--- Last Selected Control ID used in the Preferences Panel.
mod.lastID = config.prop("loupedeckct.preferences.lastID", "7")

--- plugins.core.loupedeckct.prefs.lastControlType <cp.prop: string>
--- Field
--- Last Selected Control Type used in the Preferences Panel.
mod.lastControlType = config.prop("loupedeckct.preferences.lastControlType", "1")

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
            mod.items({})
            mod._manager.refresh()

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        end
    end, i18n("loupedeckCTResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- resetApplication() -> none
-- Function
-- Reset the current application.
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
            local app = mod.lastApplication()
            local bank = mod.lastBank()
            items[app] = nil
            mod.items(items)
            mod._manager.refresh()

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        end
    end, i18n("loupedeckCTResetApplicationConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- resetBank() -> none
-- Function
-- Reset the current bank.
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
            local app = mod.lastApplication()
            local bank = mod.lastBank()
            if items[app] and items[app][bank] then
                items[app][bank] = nil
            end
            mod.items(items)
            mod._manager.refresh()

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        end
    end, i18n("loupedeckCTResetBankConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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
    local lastID = mod.lastID()
    local lastControlType = mod.lastControlType()

    local lastBankLabel = ""
    local lastPressValue = ""
    local lastLeftValue = ""
    local lastRightValue = ""
    local lastColorValue = "FFFFFF"

    local lastTouchUpValue
    local lastTouchDownValue
    local lastTouchLeftValue
    local lastTouchRightValue

    local items = mod.items()

    if items[lastApplication] and items[lastApplication][lastBank] then
        if items[lastApplication][lastBank]["bankLabel"] then
           lastBankLabel = items[lastApplication][lastBank]["bankLabel"]
        end

        if items[lastApplication][lastBank][lastControlType] and items[lastApplication][lastBank][lastControlType][lastID] then

            if items[lastApplication][lastBank][lastControlType][lastID]["leftAction"] then
                if items[lastApplication][lastBank][lastControlType][lastID]["leftAction"]["actionTitle"] then
                    lastLeftValue = items[lastApplication][lastBank][lastControlType][lastID]["leftAction"]["actionTitle"]
                end
            end

            if items[lastApplication][lastBank][lastControlType][lastID]["rightAction"] then
                if items[lastApplication][lastBank][lastControlType][lastID]["rightAction"]["actionTitle"] then
                    lastRightValue = items[lastApplication][lastBank][lastControlType][lastID]["rightAction"]["actionTitle"]
                end
            end

            if items[lastApplication][lastBank][lastControlType][lastID]["pressAction"] then
                if items[lastApplication][lastBank][lastControlType][lastID]["pressAction"]["actionTitle"] then
                    lastPressValue = items[lastApplication][lastBank][lastControlType][lastID]["pressAction"]["actionTitle"]
                end
            end

            if items[lastApplication][lastBank][lastControlType][lastID]["upAction"] then
                if items[lastApplication][lastBank][lastControlType][lastID]["upAction"]["actionTitle"] then
                    lastPressValue = items[lastApplication][lastBank][lastControlType][lastID]["upAction"]["actionTitle"]
                end
            end

            if items[lastApplication][lastBank][lastControlType][lastID]["downAction"] then
                if items[lastApplication][lastBank][lastControlType][lastID]["downAction"]["actionTitle"] then
                    lastPressValue = items[lastApplication][lastBank][lastControlType][lastID]["downAction"]["actionTitle"]
                end
            end

            if items[lastApplication][lastBank][lastControlType][lastID]["led"] then
                lastColorValue = items[lastApplication][lastBank][lastControlType][lastID]["led"]
            end

            if items[lastApplication][lastBank][lastControlType][lastID]["encodedIcon"] then
                lastEncodedIcon = items[lastApplication][lastBank][lastControlType][lastID]["encodedIcon"]
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
        lastControlType             = lastControlType,
        lastEncodedIcon             = lastEncodedIcon,
        lastID                      = lastID,
        lastTouchUpValue            = lastTouchUpValue,
        lastTouchDownValue          = lastTouchDownValue,
        lastTouchLeftValue          = lastTouchLeftValue,
        lastTouchRightValue         = lastTouchRightValue,
    }

    return renderPanel(context)
end

local translateGroupID = {
    ["com.apple.FinalCut"] = "fcpx"
}

local function setItem(app, bank, controlType, id, valueA, valueB)
    local items = mod.items()

    if not items[app] then items[app] = {} end
    if not items[app][bank] then items[app][bank] = {} end
    if not items[app][bank][controlType] then items[app][bank][controlType] = {} end
    if not items[app][bank][controlType][id] then items[app][bank][controlType][id] = {} end

    if valueB then
        if not items[app][bank][controlType][id][valueA] then items[app][bank][controlType][id][valueA] = {} end
        items[app][bank][controlType][id][valueA] = valueB
    else
        items[app][bank][controlType][id] = valueA
    end

    mod.items(items)
end

-- getScreenSizeFromControlType(controlType) -> number, number
-- Function
-- Converts a controlType to a width and height.
--
-- Parameters:
--  * controlType - A string defining the control type.
--
-- Returns:
--  * width as a number
--  * height as a number
local function getScreenSizeFromControlType(controlType)
    if controlType == "touchButton" then
        return 90, 90
    elseif controlType == "sideScreen" then
        return 60, 270
    elseif controlType == "wheelScreen" then
        return 240, 240
    end
end

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
                local app = params["application"]
                local bank = params["bank"]
                local controlType = params["controlType"]
                local id = params["id"]
                local buttonType = params["buttonType"]

                local result = {
                    ["actionTitle"] = actionTitle,
                    ["handlerID"] = handlerID,
                    ["action"] = action,
                }

                setItem(app, bank, controlType, id, buttonType, result)

                --------------------------------------------------------------------------------
                -- Update the webview:
                --------------------------------------------------------------------------------
                if params["buttonType"] == "pressAction" then
                    injectScript("changeValueByID('press_action', '" .. actionTitle .. "');")
                elseif params["buttonType"] == "leftAction" then
                    injectScript("changeValueByID('left_action', '" .. actionTitle .. "');")
                    injectScript("changeValueByID('left_touch_action', '" .. actionTitle .. "');")
                elseif params["buttonType"] == "rightAction" then
                    injectScript("changeValueByID('right_action', '" .. actionTitle .. "');")
                    injectScript("changeValueByID('right_touch_action', '" .. actionTitle .. "');")
                elseif params["buttonType"] == "upAction" then
                    injectScript("changeValueByID('up_touch_action', '" .. actionTitle .. "');")
                elseif params["buttonType"] == "downAction" then
                    injectScript("changeValueByID('down_touch_action', '" .. actionTitle .. "');")
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
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local id = params["id"]
            local buttonType = params["buttonType"]

            local result = {
                [buttonType] = nil
            }

            setItem(app, bank, controlType, id, result)
        elseif callbackType == "updateApplicationAndBank" then
            mod.lastApplication(params["application"])
            mod.lastBank(params["bank"])
            mod._manager.refresh()
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update UI:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local id = params["id"]

            local selectedControl = params["selectedControl"]

            mod.lastSelectedControl(selectedControl)
            mod.lastID(id)
            mod.lastControlType(controlType)

            local pressValue = ""
            local leftValue = ""
            local rightValue = ""
            local colorValue = "FFFFFF"
            local encodedIcon = ""
            local upValue = ""
            local downValue = ""

            local items = mod.items()

            if items[app] and items[app][bank] and items[app][bank][controlType] and items[app][bank][controlType][id] then
                local item = items[app][bank][controlType][id]
                if item["leftAction"] and item["leftAction"]["actionTitle"] then
                    leftValue = item["leftAction"]["actionTitle"]
                end

                if item["rightAction"] and item["rightAction"]["actionTitle"] then
                    rightValue = item["rightAction"]["actionTitle"]
                end

                if item["pressAction"] and item["pressAction"]["actionTitle"] then
                    pressValue = item["pressAction"]["actionTitle"]
                end

                if item["upAction"] and item["upAction"]["actionTitle"] then
                    upValue = item["upAction"]["actionTitle"]
                end

                if item["downAction"] and item["downAction"]["actionTitle"] then
                    downValue = item["downAction"]["actionTitle"]
                end

                if item["led"] then
                    colorValue = item["led"]
                end

                if item["encodedIcon"] then
                    encodedIcon = item["encodedIcon"]
                end
            end

            injectScript([[
                changeValueByID('press_action', ']] .. pressValue .. [[');
                changeValueByID('left_action', ']] .. leftValue .. [[');
                changeValueByID('right_action', ']] .. rightValue .. [[');
                changeValueByID('up_touch_action', ']] .. upValue .. [[');
                changeValueByID('down_touch_action', ']] .. downValue .. [[');
                changeValueByID('left_touch_action', ']] .. leftValue .. [[');
                changeValueByID('right_touch_action', ']] .. rightValue .. [[');
                changeColor(']] .. colorValue .. [[');
                setIcon("]] .. encodedIcon .. [[")
            ]])
        elseif callbackType == "updateColor" then
            --------------------------------------------------------------------------------
            -- Update Color:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local id = params["id"]
            local value = params["value"]

            setItem(app, bank, controlType, id, "led", value)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        elseif callbackType == "updateBankLabel" then
            --------------------------------------------------------------------------------
            -- Update Bank Label:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]

            local items = mod.items()

            if not items[app] then items[app] = {} end
            if not items[app][bank] then items[app][bank] = {} end
            items[app][bank]["bankLabel"] = params["bankLabel"]

            mod.items(items)
        elseif callbackType == "iconClicked" then
            --------------------------------------------------------------------------------
            -- Icon Clicked:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(mod.lastIconPath()) then
                mod.lastIconPath(mod.defaultIconPath())
            end

            local result = dialog.chooseFileOrFolder(i18n("pleaseSelectAnIcon"), mod.lastIconPath(), true, false, false, mod.supportedExtensions, true)
            local failed = false
            if result and result["1"] then
                local path = result["1"]

                --------------------------------------------------------------------------------
                -- Save path for next time:
                --------------------------------------------------------------------------------
                mod.lastIconPath(removeFilenameFromPath(path))

                local icon = image.imageFromPath(path)
                if icon then
                    --------------------------------------------------------------------------------
                    -- Set screen limitations:
                    --------------------------------------------------------------------------------
                    local controlType = params["controlType"]
                    local width, height = getScreenSizeFromControlType(controlType)

                    local a = canvas.new{x = 0, y = 0, w = width, h = height }
                    a[1] = {
                        --------------------------------------------------------------------------------
                        -- Force Black background:
                        --------------------------------------------------------------------------------
                        frame = { h = "100%", w = "100%", x = 0, y = 0 },
                        fillColor = { alpha = 1, red = 0, green = 0, blue = 0 },
                        type = "rectangle",
                    }
                    a[2] = {
                      type="image",
                      image = icon,
                      frame = { x = 0, y = 0, h = "100%", w = "100%" },
                    }
                    local newImage = a:imageFromCanvas()

                    local encodedIcon = newImage:encodeAsURLString(true)
                    if encodedIcon then
                        --------------------------------------------------------------------------------
                        -- Save Icon to file:
                        --------------------------------------------------------------------------------
                        local app = params["application"]
                        local bank = params["bank"]
                        local controlType = params["controlType"]
                        local id = params["id"]

                        setItem(app, bank, controlType, id, {["encodedIcon"] = encodedIcon})

                        injectScript([[setIcon("]] .. encodedIcon .. [[")]])

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        mod._ctmanager.refresh()
                    else
                        failed = true
                    end
                else
                    failed = true
                end
                if failed then
                    webviewAlert(mod._manager.getWebview(), function() end, i18n("fileCouldNotBeRead"), i18n("pleaseTryAgain"), i18n("ok"))
                end
            else
                --------------------------------------------------------------------------------
                -- Clear Icon:
                --------------------------------------------------------------------------------
                local app = params["application"]
                local bank = params["bank"]
                local controlType = params["controlType"]
                local id = params["id"]

                setItem(app, bank, controlType, id, "encodedIcon", nil)

                injectScript([[setIcon("")]])

                --------------------------------------------------------------------------------
                -- Refresh the hardware:
                --------------------------------------------------------------------------------
                mod._ctmanager.refresh()
            end
        elseif callbackType == "badExtension" then
            --------------------------------------------------------------------------------
            -- Bad Icon File Extension:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function() end, i18n("badStreamDeckIcon"), i18n("pleaseTryAgain"), i18n("ok"))
        elseif callbackType == "updateIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            local encodedIcon = params["icon"]

            --------------------------------------------------------------------------------
            -- Set screen limitations:
            --------------------------------------------------------------------------------
            local controlType = params["controlType"]
            local width, height = getScreenSizeFromControlType(controlType)

            --------------------------------------------------------------------------------
            -- Process the Icon to remove transparency:
            --------------------------------------------------------------------------------
            local newImage = image.imageFromURL(encodedIcon)
            local v = canvas.new{x = 0, y = 0, w = width, h = height }
            v[1] = {
                --------------------------------------------------------------------------------
                -- Force Black background:
                --------------------------------------------------------------------------------
                frame = { h = "100%", w = "100%", x = 0, y = 0 },
                fillColor = { alpha = 1, red = 0, green = 0, blue = 0 },
                type = "rectangle",
            }
            v[2] = {
              type="image",
              image = newImage,
              frame = { x = 0, y = 0, h = "100%", w = "100%" },
            }
            local fixedImage = v:imageFromCanvas()
            local fixedEncodedIcon = fixedImage:encodeAsURLString(true)

            --------------------------------------------------------------------------------
            -- Write to file:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local id = params["id"]

            setItem(app, bank, controlType, id, {["encodedIcon"] = fixedEncodedIcon})

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
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
