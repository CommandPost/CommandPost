--- === plugins.core.loupedeckct.prefs ===
---
--- Loupedeck CT Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "prefsLoupedeckCT"

local application               = require "hs.application"
local canvas                    = require "hs.canvas"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local loupedeckct               = require "hs.loupedeckct"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"

local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
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

--- plugins.core.loupedeckct.prefs.iconHistory <cp.prop: table>
--- Field
--- Icon History
mod.iconHistory = json.prop(config.cachePath, "Loupedeck CT", "Icon History.cpCache", {})

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
mod.lastControlType = config.prop("loupedeckct.preferences.lastControlType", "ledButton")

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

-- insertImage(path)
-- Function
-- Encodes an image as a PNG URL String
--
-- Parameters:
--  * path - Path to the image you want to encode.
--
-- Returns:
--  * The encoded URL string
local function insertImage(path)
    local p = mod._env:pathToAbsolute(path)
    local i = image.imageFromPath(p)
    return i:encodeAsURLString(false, "PNG")
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

    --------------------------------------------------------------------------------
    -- Setup the context:
    --------------------------------------------------------------------------------
    local context = {
        builtInApps                 = builtInApps,
        userApps                    = userApps,

        spairs                      = spairs,

        numberOfBanks               = mod._ctmanager.numberOfBanks,
        i18n                        = i18n,

        lastApplication             = mod.lastApplication(),
        lastBank                    = mod.lastBank(),

        lastSelectedControl         = mod.lastSelectedControl(),
        lastID                      = mod.lastID(),
        lastControlType             = mod.lastControlType(),

        insertImage                 = insertImage,

        vibrationIndex              = loupedeckct.vibrationIndex,
    }

    return renderPanel(context)
end

local translateGroupID = {
    ["com.apple.FinalCut"] = "fcpx"
}

-- setItem(app, bank, controlType, id, valueA, valueB) -> none
-- Function
-- Update the Loupedeck CT layout file.
--
-- Parameters:
--  * app - The application bundle ID as a string
--  * bank - The bank ID as a string
--  * controlType - The control type as a string
--  * id - The ID of the item as a string
--  * valueA - The value of the item as a string
--  * valueB - An optional value
local function setItem(app, bank, controlType, id, valueA, valueB)
    local items = mod.items()

    if type(items[app]) ~= "table" then items[app] = {} end
    if type(items[app][bank]) ~= "table" then items[app][bank] = {} end
    if type(items[app][bank][controlType]) ~= "table" then items[app][bank][controlType] = {} end
    if type(items[app][bank][controlType][id]) ~= "table" then items[app][bank][controlType][id] = {} end

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
    elseif controlType == "knob" then
        return 90, 90
    elseif controlType == "sideScreen" then
        return 60, 270
    elseif controlType == "wheelScreen" then
        return 240, 240
    end
end

-- generateKnobImages(app, bank, id) -> none
-- Function
-- Generates a combined image for all the knobs.
--
-- Parameters:
--  * app - The application bundle ID
--  * bank - The bank as a string
--  * id - The ID
--
-- Returns:
--  * None
local function generateKnobImages(app, bank, bid)
    local whichScreen = "1"
    local kA = "1"
    local kB = "2"
    local kC = "3"

    if bid == "4" or bid == "5" or bid == "6" then
        whichScreen = "2"
        kA = "4"
        kB = "5"
        kC = "6"
    end

    local items = mod.items()

    local knobOneImage
    local knobTwoImage
    local knobThreeImage

    local currentApp = items[app]
    local currentBank = currentApp and currentApp[bank]
    local currentKnob = currentBank and currentBank.knob

    local currentKnobOneEncodedIcon = currentKnob and currentKnob[kA] and currentKnob[kA].encodedIcon
    local currentKnobOneEncodedIconLabel = currentKnob and currentKnob[kA] and currentKnob[kA].encodedIconLabel
    if currentKnobOneEncodedIcon and currentKnobOneEncodedIcon ~= "" then
        knobOneImage = currentKnobOneEncodedIcon
    elseif currentKnobOneEncodedIconLabel and currentKnobOneEncodedIconLabel ~= "" then
        knobOneImage = currentKnobOneEncodedIconLabel
    end

    local currentKnobTwoEncodedIcon = currentKnob and currentKnob[kB] and currentKnob[kB].encodedIcon
    local currentKnobTwoEncodedIconLabel = currentKnob and currentKnob[kB] and currentKnob[kB].encodedIconLabel
    if currentKnobTwoEncodedIcon and currentKnobTwoEncodedIcon ~= "" then
        knobTwoImage = currentKnobTwoEncodedIcon
    elseif currentKnobTwoEncodedIconLabel and currentKnobTwoEncodedIconLabel ~= "" then
        knobTwoImage = currentKnobTwoEncodedIconLabel
    end

    local currentKnobThreeEncodedIcon = currentKnob and currentKnob[kC] and currentKnob[kC].encodedIcon
    local currentKnobThreeEncodedIconLabel = currentKnob and currentKnob[kC] and currentKnob[kC].encodedIconLabel
    if currentKnobThreeEncodedIcon and currentKnobThreeEncodedIcon ~= "" then
        knobThreeImage = currentKnobThreeEncodedIcon
    elseif currentKnobThreeEncodedIconLabel and currentKnobThreeEncodedIconLabel ~= "" then
        knobThreeImage = currentKnobThreeEncodedIconLabel
    end

    local encodedKnobIcon = ""

    if knobOneImage or knobTwoImage or knobThreeImage then
        local v = canvas.new{x = 0, y = 0, w = 60, h = 270 }
        v[1] = {
            frame = { h = "100%", w = "100%", x = 0, y = 0 },
            fillColor = { alpha = 1, red = 0, green = 0, blue = 0 },
            type = "rectangle",
        }

        if knobOneImage then
            v:appendElements({
              type="image",
              image = imageFromURL(knobOneImage),
              frame = { x = 0, y = 0, h = 90, w = 60 },
            })
        end

        if knobTwoImage then
            v:appendElements({
              type="image",
              image = imageFromURL(knobTwoImage),
              frame = { x = 0, y = 90, h = 90, w = 60 },
            })
        end

        if knobThreeImage then
            v:appendElements({
              type="image",
              image = imageFromURL(knobThreeImage),
              frame = { x = 0, y = 180, h = 90, w = 60 },
            })
        end

        local knobImage = v:imageFromCanvas()
        encodedKnobIcon = knobImage:encodeAsURLString(true)
    end

    setItem(app, bank, "sideScreen", whichScreen, "encodedKnobIcon", encodedKnobIcon)
end

-- updateUI(params) -> none
-- Function
-- Update the Preferences Panel UI.
--
-- Parameters:
--  * params - A table of parameters
--
-- Returns:
--  * None
local function updateUI(params)

    local app = params["application"]
    local bank = params["bank"]
    local controlType = params["controlType"]
    local bid = params["id"]

    local selectedControl = params["selectedControl"]

    local injectScript = mod._manager.injectScript

    mod.lastSelectedControl(selectedControl)
    mod.lastID(bid)
    mod.lastControlType(controlType)

    local items = mod.items()

    local selectedApp = items[app]

    local ignoreValue = (selectedApp and selectedApp.ignore) or false
    local selectedBank = selectedApp and selectedApp[bank]
    local selectedControlType = selectedBank and selectedBank[controlType]
    local selectedID = selectedControlType and selectedControlType[bid]

    local leftValue = selectedID and selectedID.leftAction and selectedID.leftAction.actionTitle or ""
    local rightValue = selectedID and selectedID.rightAction and selectedID.rightAction.actionTitle or ""
    local pressValue = selectedID and selectedID.pressAction and selectedID.pressAction.actionTitle or ""
    local upValue = selectedID and selectedID.upAction and selectedID.upAction.actionTitle or ""
    local downValue = selectedID and selectedID.downAction and selectedID.downAction.actionTitle or ""
    local doubleTapValue = selectedID and selectedID.doubleTapAction and selectedID.doubleTapAction.actionTitle or ""
    local twoFingerTapValue = selectedID and selectedID.twoFingerTapAction and selectedID.twoFingerTapAction.actionTitle or ""
    local colorValue = selectedID and selectedID.led or "FFFFFF"
    local encodedIcon = selectedID and selectedID.encodedIcon or ""
    local iconLabel = selectedID and selectedID.iconLabel or ""
    local vibrateValue = selectedID and selectedID.vibrate or ""

    local bankLabel = selectedBank and selectedBank.bankLabel or ""

    local updateIconsScript = ""

    if selectedBank then
        --------------------------------------------------------------------------------
        -- Touch Buttons:
        --------------------------------------------------------------------------------
        for i=1, 12 do
            i = tostring(i)
            local currentEncodedIcon = selectedBank.touchButton and selectedBank.touchButton[i] and selectedBank.touchButton[i].encodedIcon
            local currentIconLabel = selectedBank.touchButton and selectedBank.touchButton[i] and selectedBank.touchButton[i].iconLabel
            local currentEncodedIconLabel = selectedBank.touchButton and selectedBank.touchButton[i] and selectedBank.touchButton[i].encodedIconLabel
            if currentEncodedIcon and currentEncodedIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("touchButton]] .. i .. [[", "]] .. currentEncodedIcon .. [[")]] .. "\n"
            else
                if currentIconLabel and currentIconLabel ~= "" and currentEncodedIconLabel and currentEncodedIconLabel ~= "" then
                    updateIconsScript = updateIconsScript .. [[changeImage("touchButton]] .. i .. [[", "]] .. currentEncodedIconLabel .. [[")]] .. "\n"
                else
                    updateIconsScript = updateIconsScript .. [[changeImage("touchButton]] .. i .. [[", "]] .. insertImage("images/touchButton" .. i .. ".png") .. [[")]] .. "\n"
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Left Screen:
        --------------------------------------------------------------------------------
        local leftScreen = selectedBank and selectedBank.sideScreen and selectedBank.sideScreen["1"]
        if leftScreen and leftScreen.encodedKnobIcon and leftScreen.encodedKnobIcon ~= "" then
            updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. leftScreen.encodedKnobIcon .. [[")]] .. "\n"
        elseif leftScreen and leftScreen.encodedIcon and leftScreen.encodedIcon ~= "" then
            updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. leftScreen.encodedIcon .. [[")]] .. "\n"
        else
            updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen1.png") .. [[")]] .. "\n"
        end

        --------------------------------------------------------------------------------
        -- Right Screen:
        --------------------------------------------------------------------------------
        local rightScreen = selectedBank and selectedBank.sideScreen and selectedBank.sideScreen["2"]
        if rightScreen and rightScreen.encodedKnobIcon and rightScreen.encodedKnobIcon ~= "" then
            updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. rightScreen.encodedKnobIcon .. [[")]] .. "\n"
        elseif rightScreen and rightScreen.encodedIcon and rightScreen.encodedIcon ~= "" then
            updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. rightScreen.encodedIcon .. [[")]] .. "\n"
        else
            updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. insertImage("images/sideScreen2.png") .. [[")]] .. "\n"
        end

        --------------------------------------------------------------------------------
        -- Wheel Screen:
        --------------------------------------------------------------------------------
        local wheelScreen = selectedBank and selectedBank.wheelScreen and selectedBank.wheelScreen["1"]
        if wheelScreen and wheelScreen.encodedIcon and wheelScreen.encodedIcon ~= "" then
            updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. wheelScreen.encodedIcon .. [[")]] .. "\n"
        else
            updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. insertImage("images/wheelScreen1.png") .. [[")]] .. "\n"
        end
    else
        --------------------------------------------------------------------------------
        -- Clear all the UI elements in the Preferences Window:
        --------------------------------------------------------------------------------
        for i=1, 12 do
            i = tostring(i)
            updateIconsScript = updateIconsScript .. [[changeImage("touchButton]] .. i .. [[", "]] .. insertImage("images/touchButton" .. i .. ".png") .. [[")]] .. "\n"
        end
        updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen1.png") .. [[")]] .. "\n"
        updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. insertImage("images/sideScreen2.png") .. [[")]] .. "\n"
        updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. insertImage("images/wheelScreen1.png") .. [[")]] .. "\n"
    end

    --------------------------------------------------------------------------------
    -- Update UI on whether connected or not:
    --------------------------------------------------------------------------------
    local loadSettingsFromDevice = mod._ctmanager.loadSettingsFromDevice()
    local connected = mod._ctmanager.connected()
    local connectedScript = [[
        document.getElementById("yesLoupedeck").style.display = "block";
        document.getElementById("noLoupedeck").style.display = "none";
    ]]
    if not connected and loadSettingsFromDevice then
        connectedScript = [[
            document.getElementById("yesLoupedeck").style.display = "none";
            document.getElementById("noLoupedeck").style.display = "block";
        ]]
    end

    injectScript([[
        changeValueByID('bankLabel', ']] .. bankLabel .. [[');
        changeValueByID('press_action', ']] .. pressValue .. [[');
        changeValueByID('left_action', ']] .. leftValue .. [[');
        changeValueByID('right_action', ']] .. rightValue .. [[');
        changeValueByID('up_touch_action', ']] .. upValue .. [[');
        changeValueByID('down_touch_action', ']] .. downValue .. [[');
        changeValueByID('left_touch_action', ']] .. leftValue .. [[');
        changeValueByID('right_touch_action', ']] .. rightValue .. [[');
        changeValueByID('double_tap_touch_action', ']] .. doubleTapValue .. [[');
        changeValueByID('two_finger_touch_action', ']] .. twoFingerTapValue .. [[');
        changeValueByID('vibrate', ']] .. vibrateValue .. [[');
        changeValueByID('iconLabel', `]] .. iconLabel .. [[`);
        changeCheckedByID('ignore', ]] .. tostring(ignoreValue) .. [[);
        changeColor(']] .. colorValue .. [[');
        setIcon("]] .. encodedIcon .. [[");
    ]] .. updateIconsScript .. "\n" .. connectedScript .. "\n" .. "updateIgnoreVisibility();")
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

                --------------------------------------------------------------------------------
                -- Get list of registered and custom apps:
                --------------------------------------------------------------------------------
                local apps = {}
                local registeredApps = mod._appmanager.getApplications()
                for bundleID, v in pairs(registeredApps) do
                    if v.displayName then
                        apps[bundleID] = v.displayName
                    end
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

                --------------------------------------------------------------------------------
                -- Update the preferences file:
                --------------------------------------------------------------------------------
                local app = params["application"]
                local bank = params["bank"]
                local controlType = params["controlType"]
                local bid = params["id"]
                local buttonType = params["buttonType"]

                local result = {
                    ["actionTitle"] = actionTitle,
                    ["handlerID"] = handlerID,
                    ["action"] = action,
                }

                setItem(app, bank, controlType, bid, buttonType, result)

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
                elseif params["buttonType"] == "doubleTapAction" then
                    injectScript("changeValueByID('double_tap_touch_action', '" .. actionTitle .. "');")
                elseif params["buttonType"] == "twoFingerTapAction" then
                    injectScript("changeValueByID('two_finger_touch_action', '" .. actionTitle .. "');")
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
            local bid = params["id"]
            local buttonType = params["buttonType"]

            setItem(app, bank, controlType, bid, buttonType, {})

            mod._manager.refresh()
        elseif callbackType == "updateApplicationAndBank" then
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
                    updateUI(params)
                end
            else
                mod.lastApplication(app)
                mod.lastBank(bank)

                --------------------------------------------------------------------------------
                -- Change the bank:
                --------------------------------------------------------------------------------
                local activeBanks = mod._ctmanager.activeBanks()
                activeBanks[app] = bank
                mod._ctmanager.activeBanks(activeBanks)

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                updateUI(params)

                --------------------------------------------------------------------------------
                -- Refresh the hardware:
                --------------------------------------------------------------------------------
                mod._ctmanager.refresh()
            end
        elseif callbackType == "updateUI" then
            updateUI(params)
        elseif callbackType == "updateColor" then
            --------------------------------------------------------------------------------
            -- Update Color:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            setItem(app, bank, controlType, bid, "led", value)

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
        elseif callbackType == "updateVibrate" then
            --------------------------------------------------------------------------------
            -- Update Vibrate:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            setItem(app, bank, controlType, bid, "vibrate", value)
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

                    local newEncodedIcon = newImage:encodeAsURLString(true)
                    if newEncodedIcon then
                        --------------------------------------------------------------------------------
                        -- Save Icon to file:
                        --------------------------------------------------------------------------------
                        local app = params["application"]
                        local bank = params["bank"]
                        local bid = params["id"]

                        setItem(app, bank, controlType, bid, "encodedIcon", newEncodedIcon)

                        local changeImageScript = [[changeImage("]] .. controlType .. bid .. [[", "]] .. newEncodedIcon .. [[")]]

                        --------------------------------------------------------------------------------
                        -- Process knobs:
                        --------------------------------------------------------------------------------
                        if controlType == "knob" then

                            generateKnobImages(app, bank, bid)

                            --------------------------------------------------------------------------------
                            -- Update preferences UI:
                            --------------------------------------------------------------------------------
                            local items = mod.items()

                            local currentApp = items[app]
                            local currentBank = currentApp and currentApp[bank]
                            local currentSideScreen = currentBank and currentBank.sideScreen

                            local sideScreenOne = currentSideScreen["1"]
                            local encodedKnobIcon = sideScreenOne and sideScreenOne.encodedKnobIcon
                            local encodedIcon = sideScreenOne and sideScreenOne.encodedIcon
                            if encodedKnobIcon and encodedKnobIcon ~= "" then
                                changeImageScript = [[changeImage("sideScreen1", "]] .. encodedKnobIcon .. [[")]]
                            elseif encodedIcon and encodedIcon ~= "" then
                                changeImageScript = [[changeImage("sideScreen1", "]] .. encodedIcon .. [[")]]
                            end

                            local sideScreenTwo = currentSideScreen["2"]
                            encodedKnobIcon = sideScreenTwo and sideScreenTwo.encodedKnobIcon
                            encodedIcon = sideScreenTwo and sideScreenTwo.encodedIcon
                            if encodedKnobIcon and encodedKnobIcon ~= "" then
                                changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. encodedKnobIcon .. [[")]]
                            elseif encodedIcon and encodedIcon ~= "" then
                                changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. encodedIcon .. [[")]]
                            end

                        end

                        --------------------------------------------------------------------------------
                        -- Update preference UI via JavaScript:
                        --------------------------------------------------------------------------------
                        injectScript([[setIcon("]] .. newEncodedIcon .. [[")]] .. "\n" .. changeImageScript)

                        --------------------------------------------------------------------------------
                        -- Write to history:
                        --------------------------------------------------------------------------------
                        local iconHistory = mod.iconHistory()

                        while (#(iconHistory) >= 5) do
                            table.remove(iconHistory,1)
                        end

                        local filename = getFilenameFromPath(path, true)

                        table.insert(iconHistory, {filename, newEncodedIcon})

                        mod.iconHistory(iconHistory)

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
            local newImage = imageFromURL(encodedIcon)
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
            local bid = params["id"]

            setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        elseif callbackType == "updateButtonIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            local encodedIcon = params["icon"]

            --------------------------------------------------------------------------------
            -- Set screen limitations:
            --------------------------------------------------------------------------------
            local controlType = "touchButton"
            local width, height = getScreenSizeFromControlType(controlType)

            --------------------------------------------------------------------------------
            -- Process the Icon to remove transparency:
            --------------------------------------------------------------------------------
            local newImage = imageFromURL(encodedIcon)
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
            local bid = params["id"]

            setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        elseif callbackType == "updateSideScreenIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            local encodedIcon = params["icon"]

            --------------------------------------------------------------------------------
            -- Set screen limitations:
            --------------------------------------------------------------------------------
            local controlType = "sideScreen"
            local width, height = getScreenSizeFromControlType(controlType)

            --------------------------------------------------------------------------------
            -- Process the Icon to remove transparency:
            --------------------------------------------------------------------------------
            local newImage = imageFromURL(encodedIcon)
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
            local bid = params["id"]

            setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        elseif callbackType == "updateWheelIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            local encodedIcon = params["icon"]

            --------------------------------------------------------------------------------
            -- Set screen limitations:
            --------------------------------------------------------------------------------
            local controlType = "wheelScreen"
            local width, height = getScreenSizeFromControlType(controlType)

            --------------------------------------------------------------------------------
            -- Process the Icon to remove transparency:
            --------------------------------------------------------------------------------
            local newImage = imageFromURL(encodedIcon)
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
            local bid = params["id"]
            setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        elseif callbackType == "updateKnobIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            local encodedIcon = params["icon"]

            --------------------------------------------------------------------------------
            -- Set screen limitations:
            --------------------------------------------------------------------------------
            local controlType = "knob"
            local width, height = getScreenSizeFromControlType(controlType)

            --------------------------------------------------------------------------------
            -- Process the Icon to remove transparency:
            --------------------------------------------------------------------------------
            local newImage = imageFromURL(encodedIcon)
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
            local bid = params["id"]
            setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Generate Knob Images:
            --------------------------------------------------------------------------------
            generateKnobImages(app, bank, bid)

            --------------------------------------------------------------------------------
            -- Update Preferences Screen:
            --------------------------------------------------------------------------------
            local items = mod.items()
            local selectedApp = items[app]
            local selectedBank = selectedApp and selectedApp[bank]

            local updateIconsScript = ""

            --------------------------------------------------------------------------------
            -- Left Screen:
            --------------------------------------------------------------------------------
            local leftScreen = selectedBank and selectedBank.sideScreen and selectedBank.sideScreen["1"]
            if leftScreen and leftScreen.encodedKnobIcon and leftScreen.encodedKnobIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. leftScreen.encodedKnobIcon .. [[")]] .. "\n"
            elseif leftScreen and leftScreen.encodedIcon and leftScreen.encodedIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. leftScreen.encodedIcon .. [[")]] .. "\n"
            else
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen1.png") .. [[")]] .. "\n"
            end

            --------------------------------------------------------------------------------
            -- Right Screen:
            --------------------------------------------------------------------------------
            local rightScreen = selectedBank and selectedBank.sideScreen and selectedBank.sideScreen["2"]
            if rightScreen and rightScreen.encodedKnobIcon and rightScreen.encodedKnobIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. rightScreen.encodedKnobIcon .. [[")]] .. "\n"
            elseif rightScreen and rightScreen.encodedIcon and rightScreen.encodedIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. rightScreen.encodedIcon .. [[")]] .. "\n"
            else
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. insertImage("images/sideScreen2.png") .. [[")]] .. "\n"
            end

            injectScript(updateIconsScript)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        elseif callbackType == "iconHistory" then

            local controlType = params["controlType"]

            local menu = {}
            local iconHistory = mod.iconHistory()

            if #iconHistory > 0 then
                for i=#iconHistory, 1, -1 do
                    local item = iconHistory[i]
                    table.insert(menu,
                        {
                            title = item[1],
                            fn = function()
                                local app = params["application"]
                                local bank = params["bank"]
                                local bid = params["id"]

                                --------------------------------------------------------------------------------
                                -- Set screen limitations:
                                --------------------------------------------------------------------------------
                                local width, height = getScreenSizeFromControlType(controlType)

                                --------------------------------------------------------------------------------
                                -- Process the Icon to remove transparency:
                                --------------------------------------------------------------------------------
                                local newImage = imageFromURL(item[2])
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

                                setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

                                local changeImageScript = [[changeImage("]] .. controlType .. bid .. [[", "]] .. fixedEncodedIcon .. [[")]]

                                --------------------------------------------------------------------------------
                                -- Process knobs:
                                --------------------------------------------------------------------------------
                                if controlType == "knob" then

                                    generateKnobImages(app, bank, bid)

                                    --------------------------------------------------------------------------------
                                    -- Update preferences UI:
                                    --------------------------------------------------------------------------------
                                    local items = mod.items()

                                    local currentApp = items[app]
                                    local currentBank = currentApp and currentApp[bank]
                                    local currentSideScreen = currentBank and currentBank.sideScreen

                                    local sideScreenOne = currentSideScreen["1"]
                                    local encodedKnobIcon = sideScreenOne and sideScreenOne.encodedKnobIcon
                                    local encodedIcon = sideScreenOne and sideScreenOne.encodedIcon
                                    if encodedKnobIcon and encodedKnobIcon ~= "" then
                                        changeImageScript = [[changeImage("sideScreen1", "]] .. encodedKnobIcon .. [[")]]
                                    elseif encodedIcon and encodedIcon ~= "" then
                                        changeImageScript = [[changeImage("sideScreen1", "]] .. encodedIcon .. [[")]]
                                    else
                                        changeImageScript = [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen1.png") .. [[")]]
                                    end

                                    local sideScreenTwo = currentSideScreen["2"]
                                    encodedKnobIcon = sideScreenTwo and sideScreenTwo.encodedKnobIcon
                                    encodedIcon = sideScreenTwo and sideScreenTwo.encodedIcon
                                    if encodedKnobIcon and encodedKnobIcon ~= "" then
                                        changeImageScript = changeImageScript .. "\n" ..  [[changeImage("sideScreen2", "]] .. encodedKnobIcon .. [[")]]
                                    elseif encodedIcon and encodedIcon ~= "" then
                                        changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. encodedIcon .. [[")]]
                                    else
                                        changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen2.png") .. [[")]]
                                    end
                                end

                                --------------------------------------------------------------------------------
                                -- Update preference UI via JavaScript:
                                --------------------------------------------------------------------------------
                                injectScript([[setIcon("]] .. fixedEncodedIcon .. [[")]] .. "\n" .. changeImageScript)

                                mod._ctmanager.refresh()
                            end,
                        })
                end
            end

            if next(menu) == nil then
                table.insert(menu,
                    {
                        title = "Empty",
                        disabled = true,
                    })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.getAbsolutePosition(), true)

        elseif callbackType == "clearIcon" then
            --------------------------------------------------------------------------------
            -- Clear Icon:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]

            setItem(app, bank, controlType, bid, "encodedIcon", "")

            local items = mod.items()
            local encodedImage = insertImage("images/" .. controlType .. bid .. ".png")
            if items and items[app] and items[app][bank] and items[app][bank][controlType] and items[app][bank][controlType][bid] and items[app][bank][controlType][bid]["encodedIconLabel"] then
                if items[app][bank][controlType][bid]["iconLabel"] ~= "" then
                    encodedImage = items[app][bank][controlType][bid]["encodedIconLabel"]
                end
            end

            local changeImageScript = [[changeImage("]] .. controlType .. bid .. [[", "]] .. encodedImage .. [[")]]

            --------------------------------------------------------------------------------
            -- Process knobs:
            --------------------------------------------------------------------------------
            if controlType == "knob" then

                generateKnobImages(app, bank, bid)

                --------------------------------------------------------------------------------
                -- Update preferences UI:
                --------------------------------------------------------------------------------
                items = mod.items() -- Refresh items

                local currentApp = items[app]
                local currentBank = currentApp and currentApp[bank]
                local currentSideScreen = currentBank and currentBank.sideScreen

                local sideScreenOne = currentSideScreen["1"]
                local encodedKnobIcon = sideScreenOne and sideScreenOne.encodedKnobIcon
                local encodedIcon = sideScreenOne and sideScreenOne.encodedIcon
                if encodedKnobIcon and encodedKnobIcon ~= "" then
                    changeImageScript = [[changeImage("sideScreen1", "]] .. encodedKnobIcon .. [[")]]
                elseif encodedIcon and encodedIcon ~= "" then
                    changeImageScript = [[changeImage("sideScreen1", "]] .. encodedIcon .. [[")]]
                else
                    changeImageScript = [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen1.png") .. [[")]]
                end

                local sideScreenTwo = currentSideScreen["2"]
                encodedKnobIcon = sideScreenTwo and sideScreenTwo.encodedKnobIcon
                encodedIcon = sideScreenTwo and sideScreenTwo.encodedIcon
                if encodedKnobIcon and encodedKnobIcon ~= "" then
                    changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. encodedKnobIcon .. [[")]]
                elseif encodedIcon and encodedIcon ~= "" then
                    changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. encodedIcon .. [[")]]
                else
                    changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. insertImage("images/sideScreen1.png") .. [[")]]
                end
            end

            injectScript([[setIcon("");]] .. "\n" .. changeImageScript)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        elseif callbackType == "updateIconLabel" then
            --------------------------------------------------------------------------------
            -- Write to file:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            setItem(app, bank, controlType, bid, "iconLabel", value)

            local encodedImg = ""
            if value and trim(value) ~= "" then

                --------------------------------------------------------------------------------
                -- Set screen limitations:
                --------------------------------------------------------------------------------
                local width, height = getScreenSizeFromControlType(controlType)

                --------------------------------------------------------------------------------
                -- Make an icon using the label:
                --------------------------------------------------------------------------------
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
                    frame = { h = 100, w = 100, x = 0, y = 0 },
                    text = value,
                    textAlignment = "left",
                    textColor = { white = 1.0 },
                    textSize = 15,
                    type = "text",
                }

                local img = v:imageFromCanvas()
                encodedImg = img:encodeAsURLString(true)
            end

            setItem(app, bank, controlType, bid, "encodedIconLabel", encodedImg)

            local items = mod.items()

            local currentApp = items[app]
            local currentBank = currentApp and currentApp[bank]
            local currentControlType = currentBank and currentBank[controlType]
            local currentID = currentControlType and currentControlType[bid]

            if currentID and controlType ~= "knob" then
                if not currentID.encodedIcon or currentID.encodedIcon == "" then
                    if value ~= "" then
                        injectScript([[
                            changeImage("]] .. controlType .. bid .. [[", "]] .. encodedImg .. [[")
                        ]])
                    else
                        injectScript([[
                            changeImage("]] .. controlType .. bid .. [[", "]] .. insertImage("images/" .. controlType .. bid .. ".png") .. [[")
                        ]])
                    end
                end
            elseif controlType == "knob" then
                generateKnobImages(app, bank, bid)

                --------------------------------------------------------------------------------
                -- Refresh Items:
                --------------------------------------------------------------------------------
                items = mod.items()
                currentApp = items[app]
                currentBank = currentApp and currentApp[bank]

                --------------------------------------------------------------------------------
                -- Update preferences UI:
                --------------------------------------------------------------------------------
                local changeImageScript
                local currentSideScreen = currentBank and currentBank.sideScreen

                local sideScreenOne = currentSideScreen["1"]
                local encodedKnobIcon = sideScreenOne and sideScreenOne.encodedKnobIcon
                local encodedIcon = sideScreenOne and sideScreenOne.encodedIcon
                if encodedKnobIcon and encodedKnobIcon ~= "" then
                    changeImageScript = [[changeImage("sideScreen1", "]] .. encodedKnobIcon .. [[")]]
                elseif encodedIcon and encodedIcon ~= "" then
                    changeImageScript = [[changeImage("sideScreen1", "]] .. encodedIcon .. [[")]]
                else
                    changeImageScript = [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen1.png") .. [[")]]
                end

                local sideScreenTwo = currentSideScreen["2"]
                encodedKnobIcon = sideScreenTwo and sideScreenTwo.encodedKnobIcon
                encodedIcon = sideScreenTwo and sideScreenTwo.encodedIcon
                if encodedKnobIcon and encodedKnobIcon ~= "" then
                    changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. encodedKnobIcon .. [[")]]
                elseif encodedIcon and encodedIcon ~= "" then
                    changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. encodedIcon .. [[")]]
                else
                    changeImageScript = changeImageScript .. "\n" .. [[changeImage("sideScreen2", "]] .. insertImage("images/sideScreen2.png") .. [[")]]
                end
                if changeImageScript then
                    injectScript(changeImageScript)
                end

            end

            mod._ctmanager.refresh()

        elseif callbackType == "importSettings" then
            --------------------------------------------------------------------------------
            -- Import Settings:
            --------------------------------------------------------------------------------
            local path = dialog.chooseFileOrFolder("Please select a file to import:", "~/Desktop", true, false, false, {"cpLoupedeckCT"})
            if path and path["1"] then
                local data = json.read(path["1"])
                if data then
                    mod.items(data)
                    mod._manager.refresh()
                    mod._ctmanager.refresh()
                end
            end
        elseif callbackType == "exportSettings" then
            --------------------------------------------------------------------------------
            -- Export Settings:
            --------------------------------------------------------------------------------
            local path = dialog.chooseFileOrFolder("Please select a folder to export to:", "~/Desktop", false, true, false)
            if path and path["1"] then
                local items = mod.items()
                json.write(path["1"] .. "/Loupedeck CT Settings " .. os.date("%Y%m%d %H%M") .. ".cpLoupedeckCT", items)
            end
        elseif callbackType == "copyControlToAllBanks" then
            --------------------------------------------------------------------------------
            -- Copy Control to All Banks:
            --------------------------------------------------------------------------------
            local items = mod.items()

            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]

            local data = items[app] and items[app][bank] and items[app][bank][controlType] and items[app][bank][controlType][bid]

            local suffix = ""
            if bank:sub(-7) == "_LeftFn" then
                suffix = "_LeftFn"
            elseif bank:sub(-8) == "_RightFn" then
                suffix = "_RightFn"
            end

            if data then
                for b=1, mod._ctmanager.numberOfBanks do
                    b = tostring(b) .. suffix
                    if not items[app] then items[app] = {} end
                    if not items[app][b] then items[app][b] = {} end
                    if not items[app][b][controlType] then items[app][b][controlType] = {} end
                    if not items[app][b][controlType][bid] then items[app][b][controlType][bid] = {} end
                    if type(data) == "table" then
                        for i, v in pairs(data) do
                            items[app][b][controlType][bid][i] = v
                        end
                    end
                end
            end
            mod.items(items)
        elseif callbackType == "resetControl" then
            --------------------------------------------------------------------------------
            -- Reset Control:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]

            local items = mod.items()

            if items[app] and items[app][bank] and items[app][bank][controlType] and items[app][bank][controlType][bid] then
                items[app][bank][controlType][bid] = nil
            end

            mod.items(items)

            injectScript([[
                changeValueByID('press_action', '');
                changeValueByID('left_action', '');
                changeValueByID('right_action', '');
                changeValueByID('up_touch_action', '');
                changeValueByID('down_touch_action', '');
                changeValueByID('left_touch_action', '');
                changeValueByID('right_touch_action', '');
                changeValueByID('double_tap_touch_action', '');
                changeValueByID('two_finger_touch_action', '');
                changeValueByID('iconLabel', '');
                changeColor('FFFFFF');
                setIcon("");
                changeImage("]] .. controlType .. bid .. [[", "]] .. insertImage("images/" .. controlType .. bid .. ".png") .. [[");
            ]])

            mod._ctmanager.refresh()
        elseif callbackType == "resetEverything" then
            --------------------------------------------------------------------------------
            -- Reset Everything:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    mod._ctmanager.reset()
                    mod._manager.refresh()
                    mod._ctmanager.refresh()
                end
            end, i18n("loupedeckCTResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetApplication" then
            --------------------------------------------------------------------------------
            -- Reset Application:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local items = mod.items()
                    local app = mod.lastApplication()

                    local defaultLayout = mod._ctmanager.defaultLayout
                    items[app] = defaultLayout and defaultLayout[app] or {}

                    mod.items(items)
                    mod._manager.refresh()

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware:
                    --------------------------------------------------------------------------------
                    mod._ctmanager.refresh()
                end
            end, i18n("loupedeckCTResetApplicationConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetBank" then
            --------------------------------------------------------------------------------
            -- Reset Bank:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local items = mod.items()
                    local app = mod.lastApplication()
                    local bank = mod.lastBank()

                    local defaultLayout = mod._ctmanager.defaultLayout

                    if items[app] and items[app][bank] then
                        items[app][bank] = defaultLayout and defaultLayout[app] and defaultLayout[app][bank] or {}
                    end
                    mod.items(items)
                    mod._manager.refresh()

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware:
                    --------------------------------------------------------------------------------
                    mod._ctmanager.refresh()
                end
            end, i18n("loupedeckCTResetBankConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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
                title = "COPY ACTIVE APPLICATION TO:",
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
        elseif callbackType == "changeIgnore" then
            local app = params["application"]
            local ignore = params["ignore"]

            local items = mod.items()

            if not items[app] then items[app] = {} end
            items[app]["ignore"] = ignore

            mod.items(items)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._ctmanager.refresh()
        elseif callbackType == "copyBank" then
            --------------------------------------------------------------------------------
            -- Copy Bank:
            --------------------------------------------------------------------------------
            local numberOfBanks = mod._ctmanager.numberOfBanks

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
                title = "COPY ACTIVE BANK TO:",
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

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            for i=1, numberOfBanks do
                table.insert(menu, {
                    title = tostring(i) .. " (Left Fn)",
                    fn = function() copyToBank(i .. "_LeftFn") end
                })
            end

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            for i=1, numberOfBanks do
                table.insert(menu, {
                    title = tostring(i) .. " (Right Fn)",
                    fn = function() copyToBank(i .. "_RightFn") end
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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
    mod._appmanager             = deps.appmanager
    mod._manager                = deps.manager
    mod._webviewLabel           = deps.manager.getLabel()
    mod._actionmanager          = deps.actionmanager
    mod._env                    = env

    mod._ctmanager              = deps.ctmanager
    mod.items                   = deps.ctmanager.items
    mod.enabled                 = deps.ctmanager.enabled
    mod.loadSettingsFromDevice  = deps.ctmanager.loadSettingsFromDevice
    mod.enableFlashDrive        = deps.ctmanager.enableFlashDrive

    --------------------------------------------------------------------------------
    -- Watch for Loupedeck CT connections and disconnects:
    --------------------------------------------------------------------------------
    mod._ctmanager.connected:watch(function(connected)
        if connected then
            mod._manager.injectScript([[
                document.getElementById("yesLoupedeck").style.display = "block";
                document.getElementById("noLoupedeck").style.display = "none";
            ]])
        else
            mod._manager.injectScript([[
                document.getElementById("yesLoupedeck").style.display = "none";
                document.getElementById("noLoupedeck").style.display = "block";
            ]])
        end
    end)

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2033.1,
        id              = panelID,
        label           = "Loupedeck CT",
        image           = image.imageFromPath(env:pathToAbsolute("/images/loupedeck.icns")),
        tooltip         = "Loupedeck CT",
        height          = 980,
    })
        :addHeading(6, "Loupedeck CT")
        :addCheckbox(7,
            {
                label       = i18n("enableLoupedeckCTSupport"),
                checked     = mod.enabled,
                onchange    = function(_, params)
                    mod.enabled(params.checked)
                end,
            }
        )
        :addCheckbox(8,
            {
                label       = i18n("enableFlashDrive"),
                checked     = mod.enableFlashDrive,
                onchange    = function(_, params)
                    if params.checked then
                        webviewAlert(mod._manager.getWebview(), function() end, i18n("pleaseDisconnectAndReconnectYourLoupedeckCT"), i18n("toEnableTheFlashDriveOnLoupedeckCT"), i18n("ok"))
                    end
                    mod.enableFlashDrive(params.checked)
                end,
            }
        )

        :addCheckbox(9,
            {
                label       = i18n("storeSettingsOnFlashDrive"),
                checked     = mod.loadSettingsFromDevice,
                id          = "storeSettingsOnFlashDrive",
                onchange    = function(_, params)
                    local manager = mod._manager
                    if params.checked then
                        webviewAlert(manager.getWebview(), function(result)
                            if result == "OK" then
                                mod.loadSettingsFromDevice(params.checked)
                                mod._manager.refresh()
                                mod._ctmanager.refresh()
                            else
                                manager.injectScript("changeCheckedByID('storeSettingsOnFlashDrive', false);")
                            end
                        end, i18n("areYouSureYouWantToStoreYourSettingsOnTheLoupedeckCTFlashDrive"), i18n("areYouSureYouWantToStoreYourSettingsOnTheLoupedeckCTFlashDriveDescription"), i18n("ok"), i18n("cancel"), "warning")
                    else
                        mod.loadSettingsFromDevice(params.checked)
                        mod._manager.refresh()
                        mod._ctmanager.refresh()
                    end
                end,
            }
        )

        :addContent(11, generateContent, false)

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
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.action.manager"]             = "actionmanager",
        ["core.loupedeckct.manager"]        = "ctmanager",
        ["core.application.manager"]        = "appmanager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
