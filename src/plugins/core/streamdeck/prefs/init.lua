--- === plugins.core.streamdeck.prefs ===
---
--- Stream Deck Preferences Panel

local require                   = require

local os                        = os

local log                       = require "hs.logger".new "prefsStreamDeck"
local inspect                   = require "hs.inspect"

local application               = require "hs.application"
local canvas                    = require "hs.canvas"
local chooser                   = require "hs.chooser"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"
local styledtext                = require "hs.styledtext"
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
local escapeTilda               = tools.escapeTilda
local execute                   = os.execute
local getFilenameFromPath       = tools.getFilenameFromPath
local imageFromAppBundle        = image.imageFromAppBundle
local imageFromPath             = image.imageFromPath
local imageFromURL              = image.imageFromURL
local infoForBundlePath         = application.infoForBundlePath
local mergeTable                = tools.mergeTable
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local split                     = tools.split
local tableContains             = tools.tableContains
local tableMatch                = tools.tableMatch
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- ICON_LABEL_UPDATE_DELAY -> string
-- Constant
-- How long to delay updating the icon label.
local ICON_LABEL_UPDATE_DELAY = 0.5

-- DEFAULT_FONT_COLOR -> string
-- Constant
-- The default font color value.
local DEFAULT_FONT_COLOR = "FFFFFF"

-- DEFAULT_FONT_SIZE -> string
-- Constant
-- The default font size value.
local DEFAULT_FONT_SIZE = "15"

-- DEFAULT_FONT -> string
-- Constant
-- The default font value.
local DEFAULT_FONT = ".AppleSystemUIFont"

-- KEY_CREATOR_URL -> string
-- Constant
-- URL to Key Creator Website
local KEY_CREATOR_URL = "https://www.elgato.com/en/gaming/keycreator"

-- BUY_MORE_ICONS_URL -> string
-- Constant
-- URL to SideshowFX Website
local BUY_MORE_ICONS_URL = "https://www.sideshowfx.net/buy?category=Stream+Deck"

-- SNIPPET_HELP_URL -> string
-- Constant
-- URL to Snippet Support Site
local SNIPPET_HELP_URL = "https://help.commandpost.io/advanced/snippets_for_icons"

-- delayedFn -> hs.timer
-- Variable
-- A delayed timer used for the Icon Label updater.
local delayedFn

--- plugins.core.streamdeck.prefs.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Stream Deck Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

local iconPath = config.assetsPath .. "/icons/"

--- plugins.core.streamdeck.prefs.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = iconPath .. "Stream Deck/"

--- plugins.core.streamdeck.prefs.automaticallyApplyIconFromAction <cp.prop: boolean>
--- Field
--- Automatically Apply Icon from Action
mod.automaticallyApplyIconFromAction = config.prop("streamDeck.preferences.automaticallyApplyIconFromAction", true)

--- plugins.core.streamdeck.prefs.backgroundColour <cp.prop: string>
--- Field
--- Background Colour.
mod.backgroundColour = config.prop("streamDeck.preferences.backgroundColour", "#000000")

--- plugins.core.streamdeck.prefs.resizeImagesOnImport <cp.prop: string>
--- Field
--- Resize Icons on Import Preference.
mod.resizeImagesOnImport = config.prop("streamDeck.preferences.resizeImagesOnImport", "100%")

--- plugins.core.streamdeck.prefs.lastIconPath <cp.prop: string>
--- Field
--- Last icon path.
mod.lastIconPath = config.prop("streamDeck.preferences.lastIconPath", mod.defaultIconPath)

--- plugins.core.streamdeck.prefs.iconHistory <cp.prop: table>
--- Field
--- Icon History
mod.iconHistory = json.prop(config.cachePath, "Stream Deck", "Icon History.cpCache", {})

--- plugins.core.streamdeck.prefs.pasteboard <cp.prop: table>
--- Field
--- Pasteboard
mod.pasteboard = json.prop(config.cachePath, "Stream Deck", "Pasteboard.cpCache", {})

--- plugins.core.streamdeck.prefs.lastExportPath <cp.prop: string>
--- Field
--- Last Export path.
mod.lastExportPath = config.prop("streamDeck.preferences.lastExportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.streamdeck.prefs.lastImportPath <cp.prop: string>
--- Field
--- Last Import path.
mod.lastImportPath = config.prop("streamDeck.preferences.lastImportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.streamdeck.prefs.lastDevice <cp.prop: string>
--- Field
--- Last Device used in the Preferences Panel.
mod.lastDevice = config.prop("streamDeck.preferences.lastDevice", "Original")

--- plugins.core.streamdeck.prefs.lastUnit <cp.prop: string>
--- Field
--- Last Unit used in the Preferences Panel.
mod.lastUnit = config.prop("streamDeck.preferences.lastUnit", "1")

--- plugins.core.streamdeck.prefs.lastUnit <cp.prop: string>
--- Field
--- Last Unit used in the Preferences Panel.
mod.lastButton = config.prop("streamDeck.preferences.lastButton", "1")

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
        local errorMessage
        mod._renderPanel, errorMessage = mod._env:compileTemplate("html/panel.html")
        if errorMessage then
            log.ef(errorMessage)
            return nil
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
    for _, device in pairs(items) do
        for _, unit in pairs(device) do
            for bundleID, v in pairs(unit) do
                if v.displayName then
                    userApps[bundleID] = v.displayName
                end
            end
        end
    end

    local context = {
        id                      = "streamDeckPanelCallback",

        builtInApps             = builtInApps,
        userApps                = userApps,

        spairs                  = spairs,

        numberOfBanks           = mod.numberOfBanks,
        numberOfDevices         = mod.numberOfDevices,

        lastApplication         = mod.lastApplication(),
        lastBank                = mod.lastBank(),
        lastDevice              = mod.lastDevice(),
        lastUnit                = mod.lastUnit(),

        i18n                    = i18n,
    }

    return renderPanel(context)
end

-- updateUI(params)
-- Function
--
-- Parameters:
--  * params - A table of parameters
--
-- Returns:
--  * None
local function updateUI(params)
    --------------------------------------------------------------------------------
    -- Get parameters from table or from saved data:
    --------------------------------------------------------------------------------
    local device    = params and params["device"] or mod.lastDevice()
    local unit      = params and params["unit"] or mod.lastUnit()
    local app       = params and params["application"] or mod.lastApplication()
    local bank      = params and params["bank"] or mod.lastBank()
    local button    = params and params["button"] or mod.lastButton()

    --------------------------------------------------------------------------------
    -- Update the last button:
    --------------------------------------------------------------------------------
    mod.lastButton(button)

    --------------------------------------------------------------------------------
    -- Update the UI Dropdowns:
    --------------------------------------------------------------------------------
    local injectScript = mod._manager.injectScript

    local script = [[
        changeValueByID("device", "]] .. device .. [[");
        changeValueByID("unit", "]] .. unit .. [[");
        changeValueByID("application", "]] .. app .. [[");
        changeValueByID("bank", "]] .. bank .. [[");
    ]]

    --------------------------------------------------------------------------------
    -- Show the correct UI:
    --------------------------------------------------------------------------------
    script = script .. [[
        document.getElementById("streamdeckOriginalUI").style.display = "]] .. (device == "Original" and "inline-table" or "None") .. [[";
        document.getElementById("streamdeckMiniUI").style.display = "]] .. (device == "Mini" and "inline-table" or "None") .. [[";
        document.getElementById("streamdeckXLUI").style.display = "]] .. (device == "XL" and "inline-table" or "None") .. [[";
    ]] .. "\n"

    --------------------------------------------------------------------------------
    -- Update the UI label:
    --------------------------------------------------------------------------------
    script = script .. [[
        document.getElementById("label").innerHTML = "]] .. button .. [[";
    ]] .. "\n"

    local items = mod.items()
    local appData = items[device] and items[device][unit] and items[device][unit][app]

    --------------------------------------------------------------------------------
    -- Update Ignore Application Checkbox:
    --------------------------------------------------------------------------------
    if appData and appData.ignore and appData.ignore == true then
        script = script .. [[
            document.getElementById("ignore").checked = true;
        ]] .. "\n"
    else
        script = script .. [[
            document.getElementById("ignore").checked = false;
        ]] .. "\n"
    end

    --------------------------------------------------------------------------------
    -- You can't ignore "All Applications:"
    --------------------------------------------------------------------------------
    if app == "All Applications" then
        script = script .. [[
            document.getElementById("ignoreApp").style.display = "none";
        ]] .. "\n"
    else
        script = script .. [[
            document.getElementById("ignoreApp").style.display = "block";
        ]] .. "\n"

    end

    local bankData = appData and appData[bank]

    --------------------------------------------------------------------------------
    -- Update the button images for all the buttons:
    --------------------------------------------------------------------------------
    local numberOfButtons = mod._sd.numberOfButtons[device]

    for i=1, numberOfButtons do
        local buttonData = bankData and bankData[tostring(i)]
        local snippetImage = mod._sd.getSnippetImage(device, buttonData)
        if snippetImage then
            --------------------------------------------------------------------------------
            -- It's an image from a Snippet:
            --------------------------------------------------------------------------------
            script = script .. [[
                document.querySelector('[device="]] .. device .. [["][button="]] .. i .. [["]').style.backgroundImage = "url(']] .. snippetImage .. [[')";
            ]] .. "\n"
        elseif buttonData and buttonData.icon and buttonData.icon ~= "" then
            --------------------------------------------------------------------------------
            -- It's an image from a supplied icon:
            --------------------------------------------------------------------------------
            script = script .. [[
                document.querySelector('[device="]] .. device .. [["][button="]] .. i .. [["]').style.backgroundImage = "url(']] .. buttonData.icon .. [[')";
            ]] .. "\n"
        elseif buttonData and buttonData.encodedIconLabel and buttonData.encodedIconLabel ~= "" then
            --------------------------------------------------------------------------------
            -- It's an image from an icon label:
            --------------------------------------------------------------------------------
            script = script .. [[
                document.querySelector('[device="]] .. device .. [["][button="]] .. i .. [["]').style.backgroundImage = "url(']] .. buttonData.encodedIconLabel .. [[')";
            ]] .. "\n"
        else
            --------------------------------------------------------------------------------
            -- There's no icon for this button:
            --------------------------------------------------------------------------------
            script = script .. [[
                document.querySelector('[device="]] .. device .. [["][button="]] .. i .. [["]').style.backgroundImage = "";
            ]] .. "\n"
        end
    end

    --------------------------------------------------------------------------------
    -- Update the fields for the currently selected button:
    --------------------------------------------------------------------------------
    local pressAction = ""
    local releaseAction = ""
    local repeatPressActionUntilReleased = false
    local iconLabel = ""
    local snippetAction = ""
    local fontSize = DEFAULT_FONT_SIZE
    local fontColor = DEFAULT_FONT_COLOR
    local icon = ""

    local buttonData = bankData and bankData[button]
    if buttonData then
        pressAction                         = escapeTilda(buttonData.actionTitle)
        releaseAction                       = escapeTilda(buttonData.releaseAction and buttonData.releaseAction.actionTitle)
        repeatPressActionUntilReleased      = buttonData.repeatPressActionUntilReleased or false
        iconLabel                           = escapeTilda(buttonData.label)
        snippetAction                       = escapeTilda(buttonData.snippetAction and buttonData.snippetAction.actionTitle)
        fontSize                            = buttonData.fontSize or DEFAULT_FONT_SIZE
        fontColor                           = buttonData.fontColor or DEFAULT_FONT_COLOR
        icon                                = buttonData.icon or ""
    end

    script = script .. [[
        setIcon("]] .. icon .. [[");

        changeValueByID('press_action', `]] .. pressAction .. [[`);
        changeValueByID('release_action', `]] .. releaseAction .. [[`);
        changeValueByID('iconLabel', `]] .. iconLabel .. [[`);
        changeValueByID('snippet_action', `]] .. snippetAction .. [[`);
        changeValueByID('fontSize', ']] .. fontSize .. [[');

        changeFontColor(']] .. fontColor .. [[');

        changeCheckedByID('repeatPressActionUntilReleased', ]] .. tostring(repeatPressActionUntilReleased or false) .. [[);
    ]]

    --------------------------------------------------------------------------------
    -- Update Bank Label:
    --------------------------------------------------------------------------------
    local bankLabel = bankData and bankData.bankLabel
    script = script .. [[
        document.getElementById("bankLabel").value = `]] .. escapeTilda(bankLabel) .. [[`;
    ]] .. "\n"

    --------------------------------------------------------------------------------
    -- Inject Script:
    --------------------------------------------------------------------------------
    injectScript(script)

    --------------------------------------------------------------------------------
    -- Update the hardware:
    --------------------------------------------------------------------------------
    mod._sd.update()
end

--- plugins.core.streamdeck.prefs.setItem(app, bank, button, key, [value]) -> none
--- Method
--- Update the Stream Deck layout file.
---
--- Parameters:
---  * app - The application bundle ID as a string
---  * bank - The bank ID as a string
---  * button - The button ID as a string
---  * key - The key as a string or a table if replacing the entire button contents
---  * value - The optional value
---
--- Returns:
---  * None
function mod.setItem(app, bank, button, key, value)
    local items = mod.items()

    local lastDevice = mod.lastDevice()
    local lastUnit = mod.lastUnit()

    if not button then
        button = mod.lastButton()
    end

    if not app or not bank or not button or not key then
        log.ef("[plugins.core.streamdeck.prefs.setItem] Something has gone terribly wrong. Aborting!")
        log.ef("device: %s", lastDevice)
        log.ef("unit: %s", lastUnit)
        log.ef("app: %s", app)
        log.ef("bank: %s", bank)
        log.ef("button: %s", button)
        log.ef("key: %s", key)
        return
    end

    if type(items[lastDevice]) ~= "table" then                                  items[lastDevice] = {} end
    if type(items[lastDevice][lastUnit]) ~= "table" then                        items[lastDevice][lastUnit] = {} end
    if type(items[lastDevice][lastUnit][app]) ~= "table" then                   items[lastDevice][lastUnit][app] = {} end
    if type(items[lastDevice][lastUnit][app][bank]) ~= "table" then             items[lastDevice][lastUnit][app][bank] = {} end
    if type(items[lastDevice][lastUnit][app][bank][button]) ~= "table" then     items[lastDevice][lastUnit][app][bank][button] = {} end

    if type(value) ~= "nil" then
        if type(value) == "table" then value = copy(value) end
        items[lastDevice][lastUnit][app][bank][button][key] = value
    else
        if type(key) == "table" then key = copy(key) end
        items[lastDevice][lastUnit][app][bank][button] = key
    end

    mod.items(items)
end

--- plugins.core.streamdeck.prefs.buildIconFromLabel(params) -> string
--- Function
--- Creates a new icon image from a string.
---
--- Parameters:
---  * params - A table of parameters.
---
--- Returns:
---  * A new encoded icon as URL string.
function mod.buildIconFromLabel(params)
    local app = params["application"]
    local bank = params["bank"]
    local button = params["button"] or mod.lastButton()

    local items = mod.items()
    local lastDevice = mod.lastDevice()
    local lastUnit = mod.lastUnit()

    local currentDevice = items[lastDevice]

    local currentUnit = currentDevice and currentDevice[lastUnit]

    local selectedApp = currentUnit[app]

    local selectedBank = selectedApp and selectedApp[bank]

    local selectedButton = selectedBank and selectedBank[button]

    local fontColor = selectedButton and selectedButton.fontColor and "#" .. selectedButton.fontColor or "#" .. DEFAULT_FONT_COLOR
    local fontSize = selectedButton and selectedButton.fontSize or DEFAULT_FONT_SIZE
    local font = selectedButton and selectedButton.font or DEFAULT_FONT
    local value = selectedButton and selectedButton.label or ""

    local v = canvas.new{x = 0, y = 0, w = 100, h = 100 }
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
        textColor = { hex = fontColor },
        textSize = tonumber(fontSize),
        textFont = font,
        type = "text",
    }

    local img = v:imageFromCanvas()

    return img:encodeAsURLString(true)
end

--- plugins.core.streamdeck.prefs.processEncodedIcon(icon, controlType) -> string
--- Function
--- Processes an encoded icon.
---
--- Parameters:
---  * icon - The encoded icon as URL string or a hs.image object.
---  * controlType - The control type as string.
---
--- Returns:
---  * A new encoded icon as URL string.
function mod.processEncodedIcon(icon)

    local newImage
    if type(icon) == "userdata" then
        newImage = icon
    else
        newImage = imageFromURL(icon)
    end

    local backgroundColour = mod.backgroundColour()
    local resizeImagesOnImport = mod.resizeImagesOnImport()
    local offset = tostring( (100 - tonumber(resizeImagesOnImport:sub(1, -2))) /2 ) .. "%"

    local v = canvas.new{x = 0, y = 0, w = 100, h = 100 }

    --------------------------------------------------------------------------------
    -- Background:
    --------------------------------------------------------------------------------
    v[1] = {
        frame = { h = "100%", w = "100%", x = 0, y = 0 },
        fillColor = { alpha = 1, hex = backgroundColour },
        type = "rectangle",
    }

    --------------------------------------------------------------------------------
    -- Icon - Scaled as per preferences:
    --------------------------------------------------------------------------------
    v[2] = {
      type="image",
      image = newImage,
      frame = { x = offset, y = offset, h = resizeImagesOnImport, w = resizeImagesOnImport },
    }

    local fixedImage = v:imageFromCanvas()

    return fixedImage:encodeAsURLString(true)
end

-- streamDeckPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function streamDeckPanelCallback(id, params)
    local injectScript = mod._manager.injectScript
    local callbackType = params and params["type"]
    if callbackType then
        if callbackType == "badExtension" then
            --------------------------------------------------------------------------------
            -- Bad Icon File Extension:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function() end, i18n("badStreamDeckIcon"), i18n("pleaseTryAgain"), i18n("ok"))
        elseif callbackType == "updateAction" then
            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]

            local button = mod.lastButton()

            local buttonType = params["buttonType"]

            local activatorID = (buttonType == "snippetAction" and "snippet") or app

            if not mod.activator then
                mod.activator = {}
            end

            if activatorID == "snippet" and not mod.activator[activatorID] then
                --------------------------------------------------------------------------------
                -- Create a new Snippet Activator:
                --------------------------------------------------------------------------------
                mod.activator["snippet"] = mod._actionmanager.getActivator("streamdeck_preferences_snippet")

                --------------------------------------------------------------------------------
                -- Only allow the Snippets action group:
                --------------------------------------------------------------------------------
                mod.activator["snippet"]:allowHandlers("global_snippets")
            elseif not mod.activator[activatorID] then
                --------------------------------------------------------------------------------
                -- Create a new Action Activator:
                --------------------------------------------------------------------------------
                local handlerIds = mod._actionmanager.handlerIds()

                --------------------------------------------------------------------------------
                -- Determine if there's a legacy group ID and display name:
                --------------------------------------------------------------------------------
                local displayName
                local legacyGroupID
                local registeredApps = mod._appmanager.getApplications()
                for bundleID, v in pairs(registeredApps) do
                    if activatorID == bundleID or activatorID == v.legacyGroupID then
                        legacyGroupID = v.legacyGroupID or bundleID
                        displayName = v.displayName
                        break
                    end
                end

                --------------------------------------------------------------------------------
                -- Create new Activator:
                --------------------------------------------------------------------------------
                mod.activator[activatorID] = mod._actionmanager.getActivator("streamdeck_preferences_" .. activatorID)

                --------------------------------------------------------------------------------
                -- Don't include Touch Bar widgets, MIDI Controls or Global Menu Actions:
                --------------------------------------------------------------------------------
                local allowedHandlers = {}
                for _,v in pairs(handlerIds) do
                    local handlerTable = split(v, "_")
                    local partB = handlerTable[2]
                    if partB ~= "widgets" and partB ~= "midicontrols" and v ~= "global_menuactions" then
                        table.insert(allowedHandlers, v)
                    end
                end
                local unpack = table.unpack
                mod.activator[activatorID]:allowHandlers(unpack(allowedHandlers))

                --------------------------------------------------------------------------------
                -- Gather Toolbar Icons for Search Console:
                --------------------------------------------------------------------------------
                local defaultSearchConsoleToolbar = mod._appmanager.defaultSearchConsoleToolbar()
                local appSearchConsoleToolbar = mod._appmanager.getSearchConsoleToolbar(activatorID) or {}
                local searchConsoleToolbar = mergeTable(defaultSearchConsoleToolbar, appSearchConsoleToolbar)
                mod.activator[activatorID]:toolbarIcons(searchConsoleToolbar)

                --------------------------------------------------------------------------------
                -- Only enable handlers for the current app:
                --------------------------------------------------------------------------------
                local enabledHandlerID = legacyGroupID or activatorID
                if enabledHandlerID and enabledHandlerID == "All Applications" then
                    enabledHandlerID = "global"
                end
                mod.activator[activatorID]:enableHandlers(enabledHandlerID)

                --------------------------------------------------------------------------------
                -- Add a specific toolbar icon for the current application:
                --------------------------------------------------------------------------------
                if enabledHandlerID and enabledHandlerID ~= "global" then
                    local icon = imageFromAppBundle(activatorID)
                    mod.activator[activatorID]:setBundleID(enabledHandlerID, icon, displayName)
                end
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
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
                if buttonType == "pressAction" then
                    --------------------------------------------------------------------------------
                    -- We just do this in the "root" of the button table for legacy reasons:
                    --------------------------------------------------------------------------------
                    mod.setItem(app, bank, button, "actionTitle", actionTitle)
                    mod.setItem(app, bank, button, "handlerID", handlerID)
                    mod.setItem(app, bank, button, "action", action)
                else
                    local result = {
                        ["actionTitle"] = actionTitle,
                        ["handlerID"] = handlerID,
                        ["action"] = action,
                    }
                    mod.setItem(app, bank, button, buttonType, result)
                end

                --------------------------------------------------------------------------------
                -- If it's a press action, and no icon label already exists:
                --------------------------------------------------------------------------------
                if buttonType == "pressAction" then
                    local items = mod.items()
                    local lastDevice = mod.lastDevice()
                    local lastUnit = mod.lastUnit()

                    local iconLabel = items and items[lastDevice]
                                            and items[lastDevice][lastUnit]
                                            and items[lastDevice][lastUnit][app]
                                            and items[lastDevice][lastUnit][app][bank]
                                            and items[lastDevice][lastUnit][app][bank][button]
                                            and items[lastDevice][lastUnit][app][bank][button]["label"]

                    if (iconLabel and iconLabel == "") or not iconLabel then
                        --------------------------------------------------------------------------------
                        -- Automatically add an icon label based on the action title:
                        --------------------------------------------------------------------------------
                        mod.setItem(app, bank, button, "label", actionTitle)

                        --------------------------------------------------------------------------------
                        -- Generate encoded icon label:
                        --------------------------------------------------------------------------------
                        local encodedImg = mod.buildIconFromLabel(params) or ""
                        mod.setItem(app, bank, button, "encodedIconLabel", encodedImg)
                    end
                end

                --------------------------------------------------------------------------------
                -- If the action contains an image, apply it to the Touch Button (except
                -- if it's a Snippet Action or if "Automatically Apply Icon From Action" is
                -- disabled):
                --------------------------------------------------------------------------------
                if buttonType ~= "snippetAction" and mod.automaticallyApplyIconFromAction() then
                    local choices = handler.choices():getChoices()
                    local preSuppliedImage
                    for _, v in pairs(choices) do
                        if tableMatch(v.params, action) then
                            if v.image then
                                preSuppliedImage = v.image
                            end
                            break
                        end
                    end
                    if preSuppliedImage then
                        --------------------------------------------------------------------------------
                        -- Write to file:
                        --------------------------------------------------------------------------------
                        local encodedIcon = mod.processEncodedIcon(preSuppliedImage)
                        mod.setItem(app, bank, button, "icon", encodedIcon)
                    end
                end

                --------------------------------------------------------------------------------
                -- Change the control and update the UI:
                --------------------------------------------------------------------------------
                updateUI()

            end)

            --------------------------------------------------------------------------------
            -- Set the Query String to the currently selected action:
            --------------------------------------------------------------------------------
            local items = mod.items()
            local lastDevice = mod.lastDevice()

            local currentButton = items and items[lastDevice]
                                        and items[lastDevice][lastDevice]
                                        and items[lastDevice][lastDevice][app]
                                        and items[lastDevice][lastDevice][app][bank]
                                        and items[lastDevice][lastDevice][app][bank][button]

            local currentActionTitle

            if buttonType == "pressAction" then
                currentActionTitle = currentButton and currentButton.actionTitle
            else
                currentActionTitle = currentButton and currentButton[buttonType] and currentButton[buttonType].actionTitle
            end

            if currentActionTitle and currentActionTitle ~= "" then
                mod.activator[activatorID]:lastQueryValue(currentActionTitle)
            end

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
            local buttonType = params["buttonType"]

            local button = mod.lastButton()

            if buttonType == "pressAction" then
                --------------------------------------------------------------------------------
                -- We just do this in the "root" of the button table for legacy reasons:
                --------------------------------------------------------------------------------
                mod.setItem(app, bank, button, "actionTitle", nil)
                mod.setItem(app, bank, button, "handlerID", nil)
                mod.setItem(app, bank, button, "action", nil)
            else
                mod.setItem(app, bank, button, buttonType, nil)
            end

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            updateUI()
        elseif callbackType == "editSnippet" then
            --------------------------------------------------------------------------------
            -- Edit Snippet:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local actionType = params["actionType"]

            local button = mod.lastButton()

            local items = mod.items()
            local lastDevice = mod.lastDevice()
            local lastUnit = mod.lastUnit()


            local theDevice = items[lastDevice]
            local theUnit = theDevice and theDevice[lastUnit]
            local theApp = theUnit and theUnit[app]
            local theBank = theApp and theApp[bank]
            local theButton = theBank and theBank[button]
            local theAction = theButton and theButton[actionType]

            local snippetID = theAction and theAction.action and theAction.action.id

            if snippetID then
                local snippets = copy(mod._scriptingPreferences.snippets())

                if not snippets[snippetID] then
                    --------------------------------------------------------------------------------
                    -- This Snippet doesn't exist in the Snippets Preferences, so it must have
                    -- been deleted or imported through one of the Control Surface panels.
                    -- It will be reimported into the Snippets Preferences.
                    --------------------------------------------------------------------------------
                    snippets[snippetID] = {
                        ["code"] = theAction.action.code
                    }
                end

                --------------------------------------------------------------------------------
                -- Change the selected Snippet:
                --------------------------------------------------------------------------------
                for label, _ in pairs(snippets) do
                    if label == snippetID then
                        snippets[label].selected = true
                    else
                        snippets[label].selected = false
                    end
                end

                --------------------------------------------------------------------------------
                -- Write Preferences to disk:
                --------------------------------------------------------------------------------
                mod._scriptingPreferences.snippets(snippets)
            end

            --------------------------------------------------------------------------------
            -- Open the Scripting Preferences Panel:
            --------------------------------------------------------------------------------
            mod._scriptingPreferences._manager.lastTab("scripting")
            mod._scriptingPreferences._manager.selectPanel("scripting")
            mod._scriptingPreferences._manager.show()
        elseif callbackType == "examples" then
            --------------------------------------------------------------------------------
            -- Examples Button:
            --------------------------------------------------------------------------------
            execute('open "' .. SNIPPET_HELP_URL .. '"')
        elseif callbackType == "changeRepeatPressActionUntilReleased" then
            --------------------------------------------------------------------------------
            -- Update "Repeat Press Action Until Released":
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"] or mod.lastButton()
            local value = params["value"]

            mod.setItem(app, bank, button, "repeatPressActionUntilReleased", value)

            updateUI()
        elseif callbackType == "changeDeviceUnitApplicationBank" then
            --------------------------------------------------------------------------------
            -- Change Device/Unit/Application/Bank:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
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

                        for _, d in pairs(items) do
                            for _, u in pairs(d) do
                                for b, v in pairs(u) do
                                    if v.displayName then
                                        apps[b] = v.displayName
                                    end
                                end
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

                        if not items["Original"] then items["Original"] = {} end
                        if not items["Original"]["1"] then items["Original"]["1"] = {} end
                        if not items["Original"]["1"][bundleID] then items["Original"]["1"][bundleID] = {} end

                        items["Original"]["1"][bundleID].displayName = displayName

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
                mod.lastDevice(device)
                mod.lastUnit(unit)
                mod.lastApplication(app)
                mod.lastBank(bank)

                --------------------------------------------------------------------------------
                -- Change the bank:
                --------------------------------------------------------------------------------
                local activeBanks = mod._sd.activeBanks()
                if not activeBanks[device] then activeBanks[device] = {} end
                if not activeBanks[device][unit] then activeBanks[device][unit] = {} end
                activeBanks[device][unit][app] = tostring(bank)
                mod._sd.activeBanks(activeBanks)

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                updateUI(params)
            end
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update UI:
            --------------------------------------------------------------------------------
            updateUI(params)
        elseif callbackType == "changeBankLabel" then
            --------------------------------------------------------------------------------
            -- Change Bank Label:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]
            local bankLabel = params["bankLabel"]

            local items = mod.items()

            if not items[device] then items[device] = {} end
            if not items[device][unit] then items[device][unit] = {} end
            if not items[device][unit][app] then items[device][unit][app] = {} end
            if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end

            items[device][unit][app][bank].bankLabel = bankLabel

            mod.items(items)

        elseif callbackType == "iconClicked" then
            --------------------------------------------------------------------------------
            -- Icon Drop Zone Clicked:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(mod.lastIconPath()) then
                mod.lastIconPath(mod.defaultIconPath)
            end

            local result = chooseFileOrFolder(i18n("pleaseSelectAnIcon"), mod.lastIconPath(), true, false, false, mod.supportedExtensions, true)
            local failed = false
            if result and result["1"] then
                local path = result["1"]

                --------------------------------------------------------------------------------
                -- Save path for next time:
                --------------------------------------------------------------------------------
                mod.lastIconPath(removeFilenameFromPath(path))

                local appInfo = infoForBundlePath(path)
                local bundleID = appInfo and appInfo.CFBundleIdentifier
                local icon = imageFromPath(path) or imageFromAppBundle(bundleID)
                if icon then
                    local encodedIcon = mod.processEncodedIcon(icon)
                    if encodedIcon then
                        --------------------------------------------------------------------------------
                        -- Save Icon to file:
                        --------------------------------------------------------------------------------
                        local app = params["application"]
                        local bank = params["bank"]

                        local button = mod.lastButton()

                        mod.setItem(app, bank, button, "icon", encodedIcon)

                        --------------------------------------------------------------------------------
                        -- Write to history:
                        --------------------------------------------------------------------------------
                        local iconHistory = mod.iconHistory()
                        while (#(iconHistory) >= 5) do
                            table.remove(iconHistory,1)
                        end
                        local filename = getFilenameFromPath(path, true)
                        table.insert(iconHistory, {filename, encodedIcon})
                        mod.iconHistory(iconHistory)

                        --------------------------------------------------------------------------------
                        -- Update the UI:
                        --------------------------------------------------------------------------------
                        updateUI()
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

        elseif callbackType == "updateIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon (by drag and drop):
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"] or mod.lastButton()
            local icon = params["icon"]

            mod.setItem(app, bank, button, "icon", icon)

            updateUI()
        elseif callbackType == "dropAndDrop" then
            --------------------------------------------------------------------------------
            -- Drag & Drop:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]

            local source = params["source"]
            local destination = params["destination"]

            --------------------------------------------------------------------------------
            -- Swap controls:
            --------------------------------------------------------------------------------
            local items = mod.items()
            local lastDevice = mod.lastDevice()
            local lastUnit = mod.lastUnit()


            if not items[lastDevice] then                               items[lastDevice] = {} end
            if not items[lastDevice][lastUnit] then                     items[lastDevice][lastUnit] = {} end
            if not items[lastDevice][lastUnit][app] then                items[lastDevice][lastUnit][app] = {} end
            if not items[lastDevice][lastUnit][app][bank] then          items[lastDevice][lastUnit][app][bank] = {} end

            local destinationData = items[lastDevice][lastUnit][app][bank][destination] or {}
            local sourceData = items[lastDevice][lastUnit][app][bank][source] or {}

            local a = copy(destinationData)
            local b = copy(sourceData)

            items[lastDevice][lastUnit][app][bank][source] = a
            items[lastDevice][lastUnit][app][bank][destination] = b

            mod.items(items)

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            updateUI()

        elseif callbackType == "iconHistory" then
            --------------------------------------------------------------------------------
            -- Icon History:
            --------------------------------------------------------------------------------
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
                                local button = mod.lastButton()

                                local encodedIcon = mod.processEncodedIcon(item[2])
                                mod.setItem(app, bank, button, "icon", encodedIcon)

                                --------------------------------------------------------------------------------
                                -- Update the UI:
                                --------------------------------------------------------------------------------
                                updateUI()
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
            popup:popupMenu(mouse.absolutePosition(), true)

        elseif callbackType == "clearIcon" then
            --------------------------------------------------------------------------------
            -- Clear Icon:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local button = mod.lastButton()

            mod.setItem(app, bank, button, "icon", nil)

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            updateUI()
        elseif callbackType == "changeLabel" then
            --------------------------------------------------------------------------------
            -- Change Label:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"]
            local label = params["label"]

            local items = mod.items()

            if not items[device] then items[device] = {} end
            if not items[device][unit] then items[device][unit] = {} end
            if not items[device][unit][app] then items[device][unit][app] = {} end
            if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end
            if not items[device][unit][app][bank][button] then items[device][unit][app][bank][button] = {} end

            items[device][unit][app][bank][button].label = label

            mod.items(items)

            updateUI(params)
        elseif callbackType == "changeIgnore" then
            --------------------------------------------------------------------------------
            -- Change Ignore Preference:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local ignore = params["ignore"]

            local items = mod.items()

            if not items[device] then items[device] = {} end
            if not items[device][unit] then items[device][unit] = {} end
            if not items[device][unit][app] then items[device][unit][app] = {} end

            items[device][unit][app].ignore = ignore

            mod.items(items)

            updateUI(params)
        elseif callbackType == "resetEverything" then
            --------------------------------------------------------------------------------
            -- Reset Everything:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local defaultLayout = copy(mod._sd.defaultLayout)
                    mod.items(defaultLayout)

                    --------------------------------------------------------------------------------
                    -- Refresh the entire UI, as Custom Apps will now be gone:
                    --------------------------------------------------------------------------------
                    mod._manager.refresh()
                end
            end, i18n("streamDeckResetEverythingConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetDevice" then
            --------------------------------------------------------------------------------
            -- Reset Device:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local device = params["device"]
                    local items = mod.items()

                    local defaultLayout = mod._sd.defaultLayout
                    local blank = defaultLayout and defaultLayout[device] and copy(defaultLayout[device]) or {}

                    items[device] = blank
                    mod.items(items)
                    updateUI(params)
                end
            end, i18n("streamDeckResetDeviceConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetUnit" then
            --------------------------------------------------------------------------------
            -- Reset Unit:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local device = params["device"]
                    local unit = params["unit"]
                    local items = mod.items()

                    if not items[device] then items[device] = {} end
                    if not items[device][unit] then items[device][unit] = {} end

                    local defaultLayout = mod._sd.defaultLayout
                    local blank = defaultLayout and defaultLayout[device] and defaultLayout[device][unit] and copy(defaultLayout[device][unit]) or {}

                    items[device][unit] = blank
                    mod.items(items)
                    updateUI(params)
                end
            end, i18n("streamDeckResetUnitConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetApplication" then
            --------------------------------------------------------------------------------
            -- Reset Application:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local device = params["device"]
                    local unit = params["unit"]
                    local app = params["application"]
                    local items = mod.items()

                    if not items[device] then items[device] = {} end
                    if not items[device][unit] then items[device][unit] = {} end
                    if not items[device][unit][app] then items[device][unit][app] = {} end

                    local defaultLayout = mod._sd.defaultLayout
                    local blank = defaultLayout and defaultLayout[device] and defaultLayout[device][unit] and defaultLayout[device][unit][app] and copy(defaultLayout[device][unit][app]) or {}

                    items[device][unit][app] = blank
                    mod.items(items)
                    updateUI(params)
                end
            end, i18n("streamDeckResetApplicationConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetBank" then
            --------------------------------------------------------------------------------
            -- Reset Bank:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local device = params["device"]
                    local unit = params["unit"]
                    local app = params["application"]
                    local bank = params["bank"]
                    local items = mod.items()

                    if not items[device] then items[device] = {} end
                    if not items[device][unit] then items[device][unit] = {} end
                    if not items[device][unit][app] then items[device][unit][app] = {} end
                    if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end

                    local defaultLayout = mod._sd.defaultLayout
                    local blank = defaultLayout and defaultLayout[device] and defaultLayout[device][unit] and defaultLayout[device][unit][app] and defaultLayout[device][unit][app][bank] and copy(defaultLayout[device][unit][app][bank]) or {}

                    items[device][unit][app][bank] = blank
                    mod.items(items)
                    updateUI(params)
                end
            end, i18n("streamDeckResetBankConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "showContextMenu" then
            --------------------------------------------------------------------------------
            -- Show Context Menu:
            --------------------------------------------------------------------------------
            local items = mod.items()

            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"]

            local lastDevice = mod.lastDevice()
            local lastUnit = mod.lastUnit()

            local pasteboard = mod.pasteboard()

            local menu = {}

            local theDevice = items[lastDevice]
            local theUnit = theDevice and theDevice[lastUnit]
            local theApp = theUnit and theUnit[app]
            local theBank = theApp and theApp[bank]
            local theButton = theBank and theBank[button]

            local isButtonEmpty = next(theButton or {}) == nil

            table.insert(menu, {
                title = i18n("cut"),
                disabled = isButtonEmpty,
                fn = function()
                    --------------------------------------------------------------------------------
                    -- Cut:
                    --------------------------------------------------------------------------------
                    pasteboard = copy(theButton)
                    mod.pasteboard(pasteboard)
                    mod.setItem(app, bank, button, {})
                    updateUI()
                end
            })

            table.insert(menu, {
                title = i18n("copy"),
                disabled = isButtonEmpty,
                fn = function()
                    --------------------------------------------------------------------------------
                    -- Copy:
                    --------------------------------------------------------------------------------
                    pasteboard = copy(theButton)
                    mod.pasteboard(pasteboard)
                end
            })

            table.insert(menu, {
                title = i18n("paste"),
                disabled = not pasteboard,
                fn = function()
                    --------------------------------------------------------------------------------
                    -- Paste:
                    --------------------------------------------------------------------------------
                    mod.setItem(app, bank, button, copy(pasteboard))
                    updateUI()
                end
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "updateIconLabel" then
            --------------------------------------------------------------------------------
            -- Delay screen and UI updates to avoid lag when the user's typing:
            --------------------------------------------------------------------------------
            delayedFn = function()
                --------------------------------------------------------------------------------
                -- Write to file:
                --------------------------------------------------------------------------------
                local app = params["application"]
                local bank = params["bank"]
                local value = params["value"]

                local button = mod.lastButton()

                mod.setItem(app, bank, button, "label", value)

                --------------------------------------------------------------------------------
                -- Generate encoded icon label:
                --------------------------------------------------------------------------------
                local encodedImg = ""
                if value and trim(value) ~= "" then
                    encodedImg = mod.buildIconFromLabel(params)
                end

                mod.setItem(app, bank, button, "encodedIconLabel", encodedImg)

                updateUI()
            end

            if not mod.iconLabelDelayed then
                mod.iconLabelDelayed = delayed.new(ICON_LABEL_UPDATE_DELAY, function() delayedFn() end)
            end

            mod.iconLabelDelayed:start()
        elseif callbackType == "updateFontSize" then
            --------------------------------------------------------------------------------
            -- Update Font Size:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local value = params["value"]

            local button = mod.lastButton()

            mod.setItem(app, bank, button, "fontSize", value)

            --------------------------------------------------------------------------------
            -- Update encoded icon label:
            --------------------------------------------------------------------------------
            local encodedImg = ""
            if value and trim(value) ~= "" then
                encodedImg = mod.buildIconFromLabel(params)
            end

            mod.setItem(app, bank, button, "encodedIconLabel", encodedImg)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            updateUI()
        elseif callbackType == "updateFontColor" then
            --------------------------------------------------------------------------------
            -- Update Font Color:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local value = params["value"]

            local button = mod.lastButton()

            mod.setItem(app, bank, button, "fontColor", value)

            --------------------------------------------------------------------------------
            -- Update encoded icon label:
            --------------------------------------------------------------------------------
            local encodedImg = ""
            if value and trim(value) ~= "" then
                encodedImg = mod.buildIconFromLabel(params)
            end

            mod.setItem(app, bank, button, "encodedIconLabel", encodedImg)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            updateUI()
        elseif callbackType == "selectFont" then
            --------------------------------------------------------------------------------
            -- Select a font:
            --------------------------------------------------------------------------------
            if not mod.fontChooser then
                local completionFn = function(result)
                    if result then
                        local value = result.id

                        local app = params["application"]
                        local bank = params["bank"]
                        local button = mod.lastButton()

                        mod.setItem(app, bank, button, "font", value)

                        --------------------------------------------------------------------------------
                        -- Update encoded icon label:
                        --------------------------------------------------------------------------------
                        local encodedImg = ""
                        if value and trim(value) ~= "" then
                            encodedImg = mod.buildIconFromLabel(params)
                        end

                        mod.setItem(app, bank, button, "encodedIconLabel", encodedImg)

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        updateUI()
                    end
                end

                local fontNames = styledtext.fontNames()

                local choices = {}
                for _, v in pairs(fontNames) do
                    if string.sub(v, 1, 1) ~= "." then
                        local fontName = styledtext.new(v, {
                            font = { name = v, size = 18 },
                            color = { white = 1, alpha = 1 },
                        })
                        table.insert(choices, {
                            ["text"] = fontName,
                            ["id"] = v,
                        })
                    end
                end

                mod.fontChooser = chooser.new(completionFn)
                    :bgDark(true)
                    :choices(choices)
            end

            mod.fontChooser:show()
        elseif callbackType == "copyDevice" then
            --------------------------------------------------------------------------------
            -- Copy Device:
            --------------------------------------------------------------------------------
            local device = params["device"]

            local copyDevice = function(destinationDevice)
                local items = mod.items()
                local data = items[device]
                if data then
                    items[destinationDevice] = copy(data)
                    mod.items(items)
                end
            end

            local menu = {}

            table.insert(menu, {
                title = string.upper(i18n("copyDeviceTo")) .. ":",
                disabled = true,
            })

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            local devices = {
                ["Stream Deck"] = "Original",
                ["Stream Deck Mini"] = "Mini",
                ["Stream Deck XL"] = "XL",
            }

            for deviceLabel, deviceID in pairs(devices) do
                table.insert(menu, {
                    title = deviceLabel,
                    fn = function() copyDevice(deviceID) end
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "copyUnit" then
            --------------------------------------------------------------------------------
            -- Copy Unit:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]

            local copyUnit = function(destinationDevice, destinationUnit)
                local items = mod.items()
                local data = items[device][unit]
                if data then
                    items[destinationDevice][destinationUnit] = copy(data)
                    mod.items(items)
                end
            end

            local menu = {}

            table.insert(menu, {
                title = string.upper(i18n("copyUnitTo")) .. ":",
                disabled = true,
            })

            table.insert(menu, {
                title = "-",
                disabled = true,
            })

            local devices = {
                ["Stream Deck"] = "Original",
                ["Stream Deck Mini"] = "Mini",
                ["Stream Deck XL"] = "XL",
            }

            for deviceLabel, deviceID in pairs(devices) do
                for unitID=1, mod.numberOfDevices do
                    table.insert(menu, {
                        title = deviceLabel .. " " .. unitID,
                        fn = function() copyUnit(deviceID, tostring(unitID)) end
                    })
                end
                --------------------------------------------------------------------------------
                -- Add Spacer:
                --------------------------------------------------------------------------------
                table.insert(menu, {
                    title = "-",
                    disabled = true,
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "copyApplication" then
            --------------------------------------------------------------------------------
            -- Copy Application:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]

            local copyApplication = function(destinationApp)
                local items = mod.items()
                local app = mod.lastApplication()

                local data = items[device][unit][app]
                if data then
                    items[device][unit][destinationApp] = copy(data)
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
            for _, d in pairs(items) do
                for _, u in pairs(d) do
                    for b, v in pairs(u) do
                        if v.displayName then
                            userApps[b] = v.displayName
                        end
                    end
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
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "copyBank" then
            --------------------------------------------------------------------------------
            -- Copy Bank:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]

            local copyToBank = function(destinationBank)
                local items = mod.items()
                local app = mod.lastApplication()
                local bank = mod.lastBank()

                local data = items[device] and items[device][unit] and items[device][unit][app] and items[device][unit][app][bank]
                if data then
                    items[device][unit][app][destinationBank] = copy(data)
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

            for i=1, mod.numberOfBanks do
                table.insert(menu, {
                    title = tostring(i),
                    fn = function() copyToBank(tostring(i)) end
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "openKeyCreator" then
            --------------------------------------------------------------------------------
            -- Open Key Creator:
            --------------------------------------------------------------------------------
            execute('open "' .. KEY_CREATOR_URL .. '"')
        elseif callbackType == "buyIcons" then
            --------------------------------------------------------------------------------
            -- Buy More Icons:
            --------------------------------------------------------------------------------
            execute('open "' .. BUY_MORE_ICONS_URL .. '"')
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

                local path = chooseFileOrFolder(i18n("pleaseSelectAFileToImport") .. ":", lastImportPath, true, false, false, {"cpStreamDeck"})
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
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "exportSettings" then
            --------------------------------------------------------------------------------
            -- Export Settings:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]

            local exportSettings = function(what)
                local items = mod.items()
                local data = {}

                local filename = ""

                if what == "Everything" then
                    data = copy(items)
                    filename = "Everything"
                elseif what == "Device" then
                    data[device] = copy(items[device])
                    if device == "Original" then
                        filename = "Stream Deck"
                    else
                        filename = "Stream Deck " .. device
                    end
                elseif what == "Unit" then
                    data[device] = {}
                    data[device][unit] = copy(items[device][unit])

                    if device == "Original" then
                        filename = "Stream Deck"
                    else
                        filename = "Stream Deck " .. device
                    end
                    filename = filename .. " Unit " .. unit
                elseif what == "Application" then
                    data[device] = {}
                    data[device][unit] = {}
                    data[device][unit][app] = copy(items[device][unit][app])
                    filename = app
                elseif what == "Bank" then
                    data[device] = {}
                    data[device][unit] = {}
                    data[device][unit][app] = {}
                    data[device][unit][app][bank] = copy(items[device][unit][app][bank])
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
                    json.write(path["1"] .. "/" .. filename .. " - " .. os.date("%Y%m%d %H%M") .. ".cpStreamDeck", data)
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
                title = i18n("currentDevice"),
                fn = function() exportSettings("Device") end,
            })

            table.insert(menu, {
                title = i18n("currentUnit"),
                fn = function() exportSettings("Unit") end,
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
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "resetControl" then
            --------------------------------------------------------------------------------
            -- Reset Control:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local button = mod.lastButton()
            mod.setItem(app, bank, button, {})

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            updateUI()
        elseif callbackType == "copyControlToAllBanks" then
            --------------------------------------------------------------------------------
            -- Copy Control to All Banks:
            --------------------------------------------------------------------------------
            local items = mod.items()

            local lastDevice = mod.lastDevice()
            local lastUnit = mod.lastUnit()

            local app = params["application"]
            local bank = params["bank"]

            local lastButton = mod.lastButton()

            local theDevice = items[lastDevice]
            local theUnit = theDevice and theDevice[lastUnit]
            local theApp = theUnit and theUnit[app]
            local theBank = theApp and theApp[bank]
            local theButton = theBank and theBank[lastButton] or {}

            if theButton then
                local data = copy(theButton)
                for b=1, mod.numberOfBanks do
                    mod.setItem(app, tostring(b), lastButton, data)
                end
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

local plugin = {
    id              = "core.streamdeck.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]        = "manager",
        ["core.streamdeck.manager"]             = "sd",
        ["core.action.manager"]                 = "actionmanager",
        ["core.application.manager"]            = "appmanager",
        ["core.preferences.panels.scripting"]   = "scriptingPreferences",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._appmanager             = deps.appmanager
    mod._sd                     = deps.sd
    mod._manager                = deps.manager
    mod._webviewLabel           = deps.manager.getLabel()
    mod._actionmanager          = deps.actionmanager
    mod._env                    = env

    mod._scriptingPreferences   = deps.scriptingPreferences

    mod.numberOfBanks           = deps.manager.NUMBER_OF_BANKS
    mod.numberOfDevices         = deps.manager.NUMBER_OF_DEVICES

    mod.items                   = deps.sd.items
    mod.enabled                 = deps.sd.enabled
    mod.lastApplication         = deps.sd.lastApplication
    mod.lastBank                = deps.sd.lastBank

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2032,
        id              = "streamdeck",
        label           = i18n("streamdeckPanelLabel"),
        image           = imageFromPath(env:pathToAbsolute("images/streamdeck.icns")),
        tooltip         = i18n("streamdeckPanelTooltip"),
        height          = 1000,
    })
        :addHeading(1, i18n("streamDeck"))
        :addContent(2, [[
            <style>
                .menubarRow {
                    display: flex;
                }

                .menubarColumn {
                    flex: 50%;
                }
            </style>
            <div class="menubarRow">
                <div class="menubarColumn">
        ]], false)
        :addCheckbox(3,
            {
                class       = "enableStreamDeck",
                label       = i18n("enableStreamDeck"),
                checked     = mod.enabled,
                onchange    = function(_, params)
                    if #application.applicationsForBundleID("com.elgato.StreamDeck") == 0 then
                        mod.enabled(params.checked)
                    else
                        webviewAlert(mod._manager.getWebview(), function() end, i18n("streamDeckAppRunning"), i18n("streamDeckAppRunningMessage"), i18n("ok"))
                        mod._manager.refresh()
                    end
                end,
            }
        )
        :addCheckbox(4,
            {
                label       = i18n("automaticallySwitchApplications"),
                checked     = mod._sd.automaticallySwitchApplications,
                onchange    = function(_, params)
                    mod._sd.automaticallySwitchApplications(params.checked)
                    updateUI()
                end,
            }
        )
        :addCheckbox(5,
            {
                label       = i18n("automaticallyApplyIconFromAction"),
                checked     = mod.automaticallyApplyIconFromAction,
                onchange    = function(_, params)
                    mod.automaticallyApplyIconFromAction(params.checked)
                end,
            }
        )
        :addCheckbox(5.1,
            {
                label       = i18n("previewSelectedApplicationAndBankOnHardware"),
                checked     = mod._sd.previewSelectedApplicationAndBankOnHardware,
                onchange    = function(_, params)
                    mod._sd.previewSelectedApplicationAndBankOnHardware(params.checked)
                    updateUI()
                end,
            }
        )
        :addContent(6, [[
                </div>
                <div class="menubarColumn">
                <style>
                    .screensBacklightLevel select {
                        width: 100px;
                    }
                    .resizeImagesOnImport select {
                        width: 100px;
                    }

                    .snippetsRefreshFrequency select {
                        width: 100px;
                    }

                    .restrictRightTopSectionSize label {
                        width: 223px;
                        overflow:hidden;
                        display:inline-block;
                        text-overflow: ellipsis;
                        white-space: nowrap;
                    }

                    .imageBackgroundColourOnImport input {
                        -webkit-appearance: none;
                        text-shadow:0 1px 0 rgba(0,0,0,0.4);
                        background-color: rgba(65,65,65,1);
                        color: #bfbfbc;
                        text-decoration: none;
                        padding: 2px 18px 2px 5px;
                        border:0.5px solid black;
                        display: inline-block;
                        border-radius: 3px;
                        border-radius: 0px;
                        cursor: default;
                        font-family: -apple-system;
                        font-size: 13px;
                        width: 76px;
                    }
                </style>
        ]], false)
        :addSelect(7,
            {
                label       =   i18n("snippetsRefreshFrequency"),
                value       =   mod._sd.snippetsRefreshFrequency,
                class       =   "snippetsRefreshFrequency restrictRightTopSectionSize",
                options     =   function()
                                    local options = {}
                                    for i=1, 10 do
                                        table.insert(options, {
                                            value = tostring(i),
                                            label = tostring(i) .. (i == 1 and " second" or " seconds")
                                        })
                                    end
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    mod._sd.snippetsRefreshFrequency(params.value)
                                    if mod._sd.refreshTimer then
                                        mod._sd.refreshTimer:stop()
                                        mod._sd.refreshTimer = nil
                                        mod._sd.update()
                                    end
                                end,
            }
        )
        :addSelect(8,
            {
                label       =   i18n("resizeImagesOnImport"),
                class       =   "resizeImagesOnImport restrictRightTopSectionSize",
                value       =   mod.resizeImagesOnImport,
                options     =   function()
                                    local options = {
                                        { value = "100%",   label = "100%" },
                                        { value = "95%",    label = "95%" },
                                        { value = "90%",    label = "90%" },
                                        { value = "85%",    label = "85%" },
                                        { value = "80%",    label = "80%" },
                                        { value = "75%",    label = "75%" },
                                        { value = "70%",    label = "70%" },
                                        { value = "65%",    label = "65%" },
                                        { value = "60%",    label = "60%" },
                                        { value = "55%",    label = "55%" },
                                        { value = "50%",    label = "50%" },
                                    }
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    mod.resizeImagesOnImport(params.value)
                                end,
            }
        )
        :addTextbox(9,
            {
                label       =   i18n("imageBackgroundColourOnImport") .. ":",
                value       =   function() return mod.backgroundColour() end,
                class       =   "restrictRightTopSectionSize imageBackgroundColourOnImport jscolor {hash:true, borderColor:'#FFF', insetColor:'#FFF', backgroundColor:'#666'} jscolor-active",
                onchange    =   function(_, params) mod.backgroundColour(params.value) end,
            }
        )
        :addContent(10, [[
                </div>
            </div>
            <br />
        ]], false)
        :addParagraph(11, html.span {class="tip"} (html(i18n("streamDeckAppTip"), false) ) .. "\n\n")
        :addContent(12, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "streamDeckPanelCallback", streamDeckPanelCallback)

    return mod
end

return plugin
