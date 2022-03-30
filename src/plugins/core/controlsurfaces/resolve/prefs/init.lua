--- === plugins.core.controlsurfaces.resolve.prefs ===
---
--- Blackmagic DaVinci Resolve Control Surface Preferences Panel

local require                   = require

local os                        = os

local log                       = require "hs.logger".new "prefsSpeedEditor"
local inspect                   = require "hs.inspect"

local application               = require "hs.application"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"
local speededitor               = require "hs.speededitor"

local config                    = require "cp.config"
local html                      = require "cp.web.html"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local copy                      = fnutils.copy
local doesDirectoryExist        = tools.doesDirectoryExist
local escapeTilda               = tools.escapeTilda
local execute                   = os.execute
local imageFromAppBundle        = image.imageFromAppBundle
local imageFromPath             = image.imageFromPath
local infoForBundlePath         = application.infoForBundlePath
local mergeTable                = tools.mergeTable
local spairs                    = tools.spairs
local split                     = tools.split
local tableContains             = tools.tableContains
local tableMatch                = tools.tableMatch
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- SNIPPET_HELP_URL -> string
-- Constant
-- URL to Snippet Support Site
local SNIPPET_HELP_URL = "https://help.commandpost.io/advanced/snippets_for_icons"

--- plugins.core.controlsurfaces.resolve.prefs.pasteboard <cp.prop: table>
--- Field
--- Pasteboard
mod.pasteboard = json.prop(config.cachePath, "DaVinci Resolve Control Surface", "Pasteboard.cpCache", {})

--- plugins.core.controlsurfaces.resolve.prefs.lastExportPath <cp.prop: string>
--- Field
--- Last Export path.
mod.lastExportPath = config.prop("daVinciResolveControlSurface.preferences.lastExportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.controlsurfaces.resolve.prefs.lastImportPath <cp.prop: string>
--- Field
--- Last Import path.
mod.lastImportPath = config.prop("daVinciResolveControlSurface.preferences.lastImportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.controlsurfaces.resolve.prefs.lastDevice <cp.prop: string>
--- Field
--- Last Device used in the Preferences Panel.
mod.lastDevice = config.prop("daVinciResolveControlSurface.preferences.lastDevice", "Speed Editor")

--- plugins.core.controlsurfaces.resolve.prefs.lastUnit <cp.prop: string>
--- Field
--- Last Unit used in the Preferences Panel.
mod.lastUnit = config.prop("daVinciResolveControlSurface.preferences.lastUnit", "1")

--- plugins.core.controlsurfaces.resolve.prefs.lastUnit <cp.prop: string>
--- Field
--- Last Unit used in the Preferences Panel.
mod.lastButton = config.prop("daVinciResolveControlSurface.preferences.lastButton", "1")

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
    local i = imageFromPath(p)
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
        id                      = "daVinciResolveControlSurfacePanelCallback",

        builtInApps             = builtInApps,
        userApps                = userApps,

        spairs                  = spairs,

        numberOfBanks           = mod.numberOfBanks,
        numberOfDevices         = mod.numberOfDevices,

        insertImage             = insertImage,

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
    -- Change the UI depending on the selected control:
    --------------------------------------------------------------------------------
    if button == "JOG WHEEL" then
        script = script .. [[
            setStyleDisplayByClass("seButtonSection", "none");
            setStyleDisplayByClass("seJogWheelSection", "table");
        ]] .. "\n"
    else
        script = script .. [[
            setStyleDisplayByClass("seButtonSection", "table");
            setStyleDisplayByClass("seJogWheelSection", "none");
        ]] .. "\n"
    end

    --------------------------------------------------------------------------------
    -- Only show LED options if the button has an LED:
    --------------------------------------------------------------------------------
    if tableContains(speededitor.ledNames, button) then
        script = script .. [[
            setStyleDisplayByClass("seLEDSection", "table");
        ]] .. "\n"

    else
        script = script .. [[
            setStyleDisplayByClass("seLEDSection", "none");
        ]] .. "\n"

    end

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
    -- Update the fields for the currently selected button:
    --------------------------------------------------------------------------------
    local pressAction = ""
    local releaseAction = ""
    local snippetAction = ""
    local turnLeftAction = ""
    local turnRightAction = ""
    local ledAlwaysOn = false
    local repeatPressActionUntilReleased = false
    local sensitivity = mod._resolveManager.defaultSensitivity[device]

    local buttonData = bankData and bankData[button]
    if buttonData then
        pressAction                         = escapeTilda(buttonData.pressAction        and buttonData.pressAction.actionTitle)
        releaseAction                       = escapeTilda(buttonData.releaseAction      and buttonData.releaseAction.actionTitle)
        snippetAction                       = escapeTilda(buttonData.snippetAction      and buttonData.snippetAction.actionTitle)
        turnLeftAction                      = escapeTilda(buttonData.turnLeftAction     and buttonData.turnLeftAction.actionTitle)
        turnRightAction                     = escapeTilda(buttonData.turnRightAction    and buttonData.turnRightAction.actionTitle)

        ledAlwaysOn                         = buttonData.ledAlwaysOn or ledAlwaysOn
        repeatPressActionUntilReleased      = buttonData.repeatPressActionUntilReleased or repeatPressActionUntilReleased

        sensitivity                         = buttonData.sensitivity or sensitivity
    end

    script = script .. [[
        changeValueByID('pressAction', `]] .. pressAction .. [[`);
        changeValueByID('releaseAction', `]] .. releaseAction .. [[`);
        changeValueByID('snippetAction', `]] .. snippetAction .. [[`);

        changeValueByID('turnLeftAction', `]] .. turnLeftAction .. [[`);
        changeValueByID('turnRightAction', `]] .. turnRightAction .. [[`);

        changeCheckedByID('repeatPressActionUntilReleased', ]] .. tostring(repeatPressActionUntilReleased or false) .. [[);
        changeCheckedByID('ledAlwaysOn', ]] .. tostring(ledAlwaysOn or false) .. [[);

        changeValueByID("sensitivity", "]] .. sensitivity .. [[");
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
    mod._resolveManager.update()
end

--- plugins.core.controlsurfaces.resolve.prefs.setItem(app, bank, button, key, [value]) -> none
--- Method
--- Update the Speed Editor layout file.
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
        log.ef("[plugins.core.controlsurfaces.resolve.prefs.setItem] Something has gone terribly wrong. Aborting!")
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

-- daVinciResolveControlSurfacePanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function daVinciResolveControlSurfacePanelCallback(id, params)
    local injectScript = mod._manager.injectScript
    local callbackType = params and params["type"]
    if callbackType then
        if callbackType == "updateAction" then
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
                mod.activator["snippet"] = mod._actionmanager.getActivator("speededitor_preferences_snippet")

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
                mod.activator[activatorID] = mod._actionmanager.getActivator("speededitor_preferences_" .. activatorID)

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
                local result = {
                    ["actionTitle"] = actionTitle,
                    ["handlerID"] = handlerID,
                    ["action"] = action,
                }
                mod.setItem(app, bank, button, buttonType, result)

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

            local currentActionTitle = currentButton and currentButton[buttonType] and currentButton[buttonType].actionTitle

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

            mod.setItem(app, bank, button, buttonType, nil)

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
        elseif callbackType == "changeLEDAlwaysOn" then
            --------------------------------------------------------------------------------
            -- Update "LED Always On":
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"] or mod.lastButton()
            local value = params["value"]

            mod.setItem(app, bank, button, "ledAlwaysOn", value)

            updateUI()
        elseif callbackType == "changeSensitivity" then
            --------------------------------------------------------------------------------
            -- Update "Sensitivity":
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"] or mod.lastButton()
            local value = params["value"]

            mod.setItem(app, bank, button, "sensitivity", value)

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
                local activeBanks = mod._resolveManager.activeBanks()
                if not activeBanks[device] then activeBanks[device] = {} end
                if not activeBanks[device][unit] then activeBanks[device][unit] = {} end
                activeBanks[device][unit][app] = tostring(bank)
                mod._resolveManager.activeBanks(activeBanks)

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
                    local defaultLayout = copy(mod._resolveManager.defaultLayout)
                    mod.items(defaultLayout)

                    --------------------------------------------------------------------------------
                    -- Refresh the entire UI, as Custom Apps will now be gone:
                    --------------------------------------------------------------------------------
                    mod._manager.refresh()
                end
            end, i18n("daVinciResolveControlSurfaceResetEverythingConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetDevice" then
            --------------------------------------------------------------------------------
            -- Reset Device:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local device = params["device"]
                    local items = mod.items()

                    local defaultLayout = mod._resolveManager.defaultLayout
                    local blank = defaultLayout and defaultLayout[device] and copy(defaultLayout[device]) or {}

                    items[device] = blank
                    mod.items(items)
                    updateUI(params)
                end
            end, i18n("daVinciResolveControlSurfaceResetDeviceConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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

                    local defaultLayout = mod._resolveManager.defaultLayout
                    local blank = defaultLayout and defaultLayout[device] and defaultLayout[device][unit] and copy(defaultLayout[device][unit]) or {}

                    items[device][unit] = blank
                    mod.items(items)
                    updateUI(params)
                end
            end, i18n("daVinciResolveControlSurfaceResetUnitConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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

                    local defaultLayout = mod._resolveManager.defaultLayout
                    local blank = defaultLayout and defaultLayout[device] and defaultLayout[device][unit] and defaultLayout[device][unit][app] and copy(defaultLayout[device][unit][app]) or {}

                    items[device][unit][app] = blank
                    mod.items(items)
                    updateUI(params)
                end
            end, i18n("daVinciResolveControlSurfaceResetApplicationConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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

                    local defaultLayout = mod._resolveManager.defaultLayout
                    local blank = defaultLayout and defaultLayout[device] and defaultLayout[device][unit] and defaultLayout[device][unit][app] and defaultLayout[device][unit][app][bank] and copy(defaultLayout[device][unit][app][bank]) or {}

                    items[device][unit][app][bank] = blank
                    mod.items(items)
                    updateUI(params)
                end
            end, i18n("daVinciResolveControlSurfaceResetBankConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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

            for deviceID, _ in pairs(mod._resolveManager.devices) do
                table.insert(menu, {
                    title = deviceID,
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

            for deviceID, _ in pairs(mod._resolveManager.devices) do
                for unitID=1, mod.numberOfDevices do
                    table.insert(menu, {
                        title = deviceID .. " " .. unitID,
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

                local path = chooseFileOrFolder(i18n("pleaseSelectAFileToImport") .. ":", lastImportPath, true, false, false, {"cpSpeedEditor"})
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
                        filename = "Speed Editor"
                    else
                        filename = "Speed Editor " .. device
                    end
                elseif what == "Unit" then
                    data[device] = {}
                    data[device][unit] = copy(items[device][unit])

                    if device == "Original" then
                        filename = "Speed Editor"
                    else
                        filename = "Speed Editor " .. device
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
                    json.write(path["1"] .. "/" .. filename .. " - " .. os.date("%Y%m%d %H%M") .. ".cpSpeedEditor", data)
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
            log.df("Unknown Callback in DaVinci Resolve Control Surfaces Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "core.controlsurfaces.resolve.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]            = "manager",
        ["core.controlsurfaces.resolve.manager"]    = "resolveManager",
        ["core.action.manager"]                     = "actionmanager",
        ["core.application.manager"]                = "appmanager",
        ["core.preferences.panels.scripting"]       = "scriptingPreferences",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._appmanager             = deps.appmanager
    mod._resolveManager         = deps.resolveManager
    mod._manager                = deps.manager
    mod._webviewLabel           = deps.manager.getLabel()
    mod._actionmanager          = deps.actionmanager
    mod._env                    = env

    mod._scriptingPreferences   = deps.scriptingPreferences

    mod.numberOfBanks           = deps.manager.NUMBER_OF_BANKS
    mod.numberOfDevices         = deps.manager.NUMBER_OF_DEVICES

    mod.items                   = deps.resolveManager.items
    mod.enabled                 = deps.resolveManager.enabled
    mod.lastApplication         = deps.resolveManager.lastApplication
    mod.lastBank                = deps.resolveManager.lastBank

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2032,
        id              = "daVinciResolve",
        label           = "Resolve",
        image           = imageFromPath(env:pathToAbsolute("images/resolve.icns")),
        tooltip         = i18n("daVinciResolve"),
        height          = 960,
    })
        :addHeading(1, i18n("daVinciResolveControlSurfaceSupport"))
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
                label       = i18n("enableDaVinciResolveControlSurfaceSupport"),
                checked     = mod.enabled,
                onchange    = function(_, params)
                    mod.enabled(params.checked)
                end,
            }
        )
        :addCheckbox(4,
            {
                label       = i18n("automaticallySwitchApplications"),
                checked     = mod._resolveManager.automaticallySwitchApplications,
                onchange    = function(_, params)
                    mod._resolveManager.automaticallySwitchApplications(params.checked)
                    updateUI()
                end,
            }
        )
        :addContent(6, [[
                </div>
                <div class="menubarColumn">
                <style>
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
                </style>
        ]], false)
        :addSelect(7,
            {
                label       =   i18n("snippetsRefreshFrequency"),
                value       =   mod._resolveManager.snippetsRefreshFrequency,
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
                                    mod._resolveManager.snippetsRefreshFrequency(params.value)
                                    if mod._resolveManager.refreshTimer then
                                        mod._resolveManager.refreshTimer:stop()
                                        mod._resolveManager.refreshTimer = nil
                                        mod._resolveManager.update()
                                    end
                                end,
            }
        )
        :addContent(10, [[
                </div>
            </div>
            <br />
        ]], false)
        :addParagraph(11, html.span {class="tip"} (html(i18n("daVinciResolveControlSurfaceTip"), false) ) .. "\n\n")
        :addContent(12, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "daVinciResolveControlSurfacePanelCallback", daVinciResolveControlSurfacePanelCallback)

    return mod
end

return plugin
