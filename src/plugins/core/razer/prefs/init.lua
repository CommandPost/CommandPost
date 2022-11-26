--- === plugins.core.razer.prefs ===
---
--- Razer Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "prefsRazer"

local application               = require "hs.application"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"

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
local tableCount                = tools.tableCount
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- SNIPPET_LED_HELP_URL -> string
-- Constant
-- URL to Snippet Support Site
local SNIPPET_LED_HELP_URL = "https://help.commandpost.io/advanced/snippets_for_led_colors"

--- plugins.core.razer.prefs.pasteboard <cp.prop: table>
--- Field
--- Pasteboard
mod.pasteboard = json.prop(config.cachePath, "Razer", "Pasteboard.cpCache", {})

--- plugins.core.razer.prefs.lastDevice <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastDevice = config.prop("razer.preferences.lastDevice", "Razer Tartarus V2")

--- plugins.core.razer.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Application used in the Preferences Panel.
mod.lastApplication = config.prop("razer.preferences.lastApplication", "All Applications")

--- plugins.core.razer.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastBank = config.prop("razer.preferences.lastBank", "1")

--- plugins.core.razer.prefs.lastControlType <cp.prop: string>
--- Field
--- Last Selected Control Type used in the Preferences Panel.
mod.lastControlType = config.prop("razer.preferences.lastControlType", "button")

--- plugins.core.razer.prefs.lastControlID <cp.prop: string>
--- Field
--- Last Selected Control ID used in the Preferences Panel.
mod.lastControlID = config.prop("razer.preferences.lastControlID", "1")

--- plugins.core.razer.prefs.changeBankOnHardwareWhenChangingHere <cp.prop: boolean>
--- Field
--- Should we change bank on hardware when changing in preferences?
mod.changeBankOnHardwareWhenChangingHere = config.prop("razer.preferences.changeBankOnHardwareWhenChangingHere", true)

--- plugins.core.razer.prefs.lastImportPath <cp.prop: string>
--- Field
--- Last Import path.
mod.lastImportPath = config.prop("razer.preferences.lastImportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.razer.prefs.lastExportPath <cp.prop: string>
--- Field
--- Last Export path.
mod.lastExportPath = config.prop("razer.preferences.lastExportPath", os.getenv("HOME") .. "/Desktop/")

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

-- imageCache -> table
-- Variable
-- An image cache for objects we encode as URL strings
local imageCache = {}

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
    if not imageCache[path] then
        local p = mod._env:pathToAbsolute(path)
        local i = imageFromPath(p)
        local data = i:encodeAsURLString(false, "PNG")
        imageCache[path] = data
        return data
    else
        return imageCache[path]
    end
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
        for bundleID, v in pairs(device) do
            if v.displayName then
                userApps[bundleID] = v.displayName
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup the context:
    --------------------------------------------------------------------------------
    local context = {
        builtInApps                 = builtInApps,
        userApps                    = userApps,

        spairs                      = spairs,

        i18n                        = i18n,

        lastDevice                  = mod.lastDevice(),
        lastApplication             = mod.lastApplication(),
        lastBank                    = mod.lastBank(),

        lastControlType             = mod.lastControlType(),
        lastControlID               = mod.lastControlID(),

        insertImage                 = insertImage,

        bankLabels                  = mod._razerManager.bankLabels,

        tableCount                  = tools.tableCount,

        id                          = "razerPanelCallback",
    }

    return renderPanel(context)
end

-- setItem(app, bank, controlType, id, valueA, valueB) -> none
-- Function
-- Update the Loupedeck CT layout file.
--
-- Parameters:
--  * device- The device name as a string
--  * app - The application bundle ID as a string
--  * bank - The bank ID as a string
--  * controlType - The control type as a string
--  * controlID - The control ID as a string
--  * valueA - The value of the item as a string
--  * valueB - An optional value
--
-- Returns:
--  * None
local function setItem(device, app, bank, controlType, controlID, valueA, valueB)
    local items = mod.items()

    if type(items[device]) ~= "table" then items[device] = {} end
    if type(items[device][app]) ~= "table" then items[device][app] = {} end
    if type(items[device][app][bank]) ~= "table" then items[device][app][bank] = {} end
    if type(items[device][app][bank][controlType]) ~= "table" then items[device][app][bank][controlType] = {} end
    if type(items[device][app][bank][controlType][controlID]) ~= "table" then items[device][app][bank][controlType][controlID] = {} end

    --------------------------------------------------------------------------------
    -- Make copies of any tables for safety:
    --------------------------------------------------------------------------------
    if type(valueA) == "table" then valueA = copy(valueA) end
    if type(valueB) == "table" then valueB = copy(valueB) end

    if type(valueB) ~= "nil" then
        if not items[device][app][bank][controlType][controlID][valueA] then items[device][app][bank][controlType][controlID][valueA] = {} end
        items[device][app][bank][controlType][controlID][valueA] = valueB
    else
        items[device][app][bank][controlType][controlID] = valueA
    end

    mod.items(items)
end

-- updateUI([params]) -> none
-- Function
-- Update the Preferences Panel UI.
--
-- Parameters:
--  * params - A optional table of parameters
--
-- Returns:
--  * None
local function updateUI(params)
    --------------------------------------------------------------------------------
    -- If no parameters are supplied, just use whatever was last:
    --------------------------------------------------------------------------------
    params = params or {}

    local device        = params["device"]          or mod.lastDevice()
    local app           = params["application"]     or mod.lastApplication()

    -- Make sure the last selected app actually exists:
    local items = mod.items()
    if not items[device] or items[device] and not items[device][app] then
        app = "All Applications"
        mod.lastApplication("All Applications")
    end

    local bank          = params["bank"]            or mod.lastBank()
    local controlType   = params["controlType"]     or mod.lastControlType()
    local controlID     = params["controlID"]       or mod.lastControlID()

    local injectScript = mod._manager.injectScript

    mod.lastControlType(controlType)
    mod.lastControlID(controlID)

    local selectedDevice = items[device]
    local selectedApp = selectedDevice and selectedDevice[app]

    local ignore = (selectedApp and selectedApp.ignore) or false
    local selectedBank = selectedApp and selectedApp[bank]
    local selectedControlType = selectedBank and selectedBank[controlType]

    local selectedControlID = selectedControlType and selectedControlType[controlID]

    local pressAction = selectedControlID and selectedControlID.pressAction and selectedControlID.pressAction.actionTitle or ""
    local releaseAction = selectedControlID and selectedControlID.releaseAction and selectedControlID.releaseAction.actionTitle or ""

    local scrollUpAction = selectedControlID and selectedControlID.scrollUpAction and selectedControlID.scrollUpAction.actionTitle or ""
    local scrollDownAction = selectedControlID and selectedControlID.scrollDownAction and selectedControlID.scrollDownAction.actionTitle or ""

    local pressUpAction = selectedControlID and selectedControlID.pressUpAction and selectedControlID.pressUpAction.actionTitle or ""
    local pressDownAction = selectedControlID and selectedControlID.pressDownAction and selectedControlID.pressDownAction.actionTitle or ""
    local pressLeftAction = selectedControlID and selectedControlID.pressLeftAction and selectedControlID.pressLeftAction.actionTitle or ""
    local pressRightAction = selectedControlID and selectedControlID.pressRightAction and selectedControlID.pressRightAction.actionTitle or ""

    local releaseUpAction = selectedControlID and selectedControlID.releaseUpAction and selectedControlID.releaseUpAction.actionTitle or ""
    local releaseDownAction = selectedControlID and selectedControlID.releaseDownAction and selectedControlID.releaseDownAction.actionTitle or ""
    local releaseLeftAction = selectedControlID and selectedControlID.releaseLeftAction and selectedControlID.releaseLeftAction.actionTitle or ""
    local releaseRightAction = selectedControlID and selectedControlID.releaseRightAction and selectedControlID.releaseRightAction.actionTitle or ""

    local pressActionRepeat = selectedControlID and selectedControlID.pressActionRepeat or false

    local pressUpActionRepeat = selectedControlID and selectedControlID.pressUpActionRepeat or false
    local pressDownActionRepeat = selectedControlID and selectedControlID.pressDownActionRepeat or false
    local pressLeftActionRepeat = selectedControlID and selectedControlID.pressLeftActionRepeat or false
    local pressRightActionRepeat = selectedControlID and selectedControlID.pressRightActionRepeat or false

    local colorValue = selectedControlID and selectedControlID.led or "FFFFFF"

    local ledSnippetActionValue = selectedControlID and selectedControlID.ledSnippetAction and selectedControlID.ledSnippetAction.actionTitle or ""

    local bankLabel = selectedBank and selectedBank.bankLabel or ""

    local script = [[
        changeValueByID('device', `]] .. escapeTilda(device) .. [[`);

        changeValueByID('bankLabel', `]] .. escapeTilda(bankLabel) .. [[`);

        changeCheckedByID('ignore', ]] .. tostring(ignore) .. [[);

        changeCheckedByID('pressActionRepeat', ]] .. tostring(pressActionRepeat) .. [[);
        changeCheckedByID('pressUpActionRepeat', ]] .. tostring(pressUpActionRepeat) .. [[);
        changeCheckedByID('pressDownActionRepeat', ]] .. tostring(pressDownActionRepeat) .. [[);
        changeCheckedByID('pressLeftActionRepeat', ]] .. tostring(pressLeftActionRepeat) .. [[);
        changeCheckedByID('pressRightActionRepeat', ]] .. tostring(pressRightActionRepeat) .. [[);

        changeValueByID('pressAction', `]] .. escapeTilda(pressAction) .. [[`);
        changeValueByID('pressUpAction', `]] .. escapeTilda(pressUpAction) .. [[`);
        changeValueByID('pressDownAction', `]] .. escapeTilda(pressDownAction) .. [[`);
        changeValueByID('pressLeftAction', `]] .. escapeTilda(pressLeftAction) .. [[`);
        changeValueByID('pressRightAction', `]] .. escapeTilda(pressRightAction) .. [[`);

        changeValueByID('releaseAction', `]] .. escapeTilda(releaseAction) .. [[`);
        changeValueByID('releaseUpAction', `]] .. escapeTilda(releaseUpAction) .. [[`);
        changeValueByID('releaseDownAction', `]] .. escapeTilda(releaseDownAction) .. [[`);
        changeValueByID('releaseLeftAction', `]] .. escapeTilda(releaseLeftAction) .. [[`);
        changeValueByID('releaseRightAction', `]] .. escapeTilda(releaseRightAction) .. [[`);

        changeValueByID('scrollUpAction', `]] .. escapeTilda(scrollUpAction) .. [[`);
        changeValueByID('scrollDownAction', `]] .. escapeTilda(scrollDownAction) .. [[`);

        changeValueByID('led_snippet_action', `]] .. escapeTilda(ledSnippetActionValue) .. [[`);

        changeColor(']] .. colorValue .. [[');

        updateIgnoreVisibility();
    ]]

    --------------------------------------------------------------------------------
    -- Prevent Excessive Thumb Taps:
    --------------------------------------------------------------------------------
    local preventExcessiveThumbTaps = selectedControlID and selectedControlID.preventExcessiveThumbTaps or ""
    if controlType == "button" then
        if (device == "Razer Nostromo"          and controlID == "15")
        or (device == "Razer Orbweaver"         and controlID == "21")
        or (device == "Razer Orbweaver Chroma"  and controlID == "21")
        or (device == "Razer Tartarus"          and controlID == "16")
        or (device == "Razer Tartarus Pro"      and controlID == "20")
        or (device == "Razer Tartarus V2"       and controlID == "20")
        then
            script = script .. [[
                setStyleDisplayByClass("preventExcessiveThumbTaps", "table");
                changeValueByID('preventExcessiveThumbTaps', `]] .. escapeTilda(preventExcessiveThumbTaps) .. [[`);
            ]]
        else
            script = script .. [[
                setStyleDisplayByClass("preventExcessiveThumbTaps", "none");
            ]]
        end
    end

    if device == "Razer Nostromo" then
        script = script .. [[
            document.getElementById("razer_nostromo").style.display = "table";
            document.getElementById("razer_orbweaver").style.display = "none";
            document.getElementById("razer_orbweaver_chroma").style.display = "none";
            document.getElementById("razer_tartarus").style.display = "none";
            document.getElementById("razer_tartarus_chroma").style.display = "none";
            document.getElementById("razer_tartarus_pro").style.display = "none";
            document.getElementById("razer_tartarus_v2").style.display = "none";

            setStyleDisplayByClass("basicTartarusEffects", "none");
            setStyleDisplayByClass("extraTartarusEffects", "none");
        ]]
    elseif device == "Razer Orbweaver" then
        script = script .. [[
            document.getElementById("razer_nostromo").style.display = "none";
            document.getElementById("razer_orbweaver").style.display = "table";
            document.getElementById("razer_orbweaver_chroma").style.display = "none";
            document.getElementById("razer_tartarus").style.display = "none";
            document.getElementById("razer_tartarus_chroma").style.display = "none";
            document.getElementById("razer_tartarus_pro").style.display = "none";
            document.getElementById("razer_tartarus_v2").style.display = "none";

            setStyleDisplayByClass("basicTartarusEffects", "none");
            setStyleDisplayByClass("extraTartarusEffects", "none");
        ]]
    elseif device == "Razer Orbweaver Chroma" then
        script = script .. [[
            document.getElementById("razer_nostromo").style.display = "none";
            document.getElementById("razer_orbweaver").style.display = "none";
            document.getElementById("razer_orbweaver_chroma").style.display = "table";
            document.getElementById("razer_tartarus").style.display = "none";
            document.getElementById("razer_tartarus_chroma").style.display = "none";
            document.getElementById("razer_tartarus_pro").style.display = "none";
            document.getElementById("razer_tartarus_v2").style.display = "none";

            setStyleDisplayByClass("basicTartarusEffects", "inline-block");
            setStyleDisplayByClass("extraTartarusEffects", "inline-block");
        ]]

    elseif device == "Razer Tartarus" then
        script = script .. [[
            document.getElementById("razer_nostromo").style.display = "none";
            document.getElementById("razer_orbweaver").style.display = "none";
            document.getElementById("razer_orbweaver_chroma").style.display = "none";
            document.getElementById("razer_tartarus").style.display = "table";
            document.getElementById("razer_tartarus_chroma").style.display = "none";
            document.getElementById("razer_tartarus_pro").style.display = "none";
            document.getElementById("razer_tartarus_v2").style.display = "none";

            setStyleDisplayByClass("basicTartarusEffects", "none");
            setStyleDisplayByClass("extraTartarusEffects", "none");
        ]]
    elseif device == "Razer Tartarus Chroma" then
        script = script .. [[
            document.getElementById("razer_nostromo").style.display = "none";
            document.getElementById("razer_orbweaver").style.display = "none";
            document.getElementById("razer_orbweaver_chroma").style.display = "none";
            document.getElementById("razer_tartarus").style.display = "none";
            document.getElementById("razer_tartarus_chroma").style.display = "table";
            document.getElementById("razer_tartarus_pro").style.display = "none";
            document.getElementById("razer_tartarus_v2").style.display = "none";

            setStyleDisplayByClass("basicTartarusEffects", "inline-block");
            setStyleDisplayByClass("extraTartarusEffects", "inline-block");
        ]]
    elseif device == "Razer Tartarus Pro" then
        script = script .. [[
            document.getElementById("razer_nostromo").style.display = "none";
            document.getElementById("razer_orbweaver").style.display = "none";
            document.getElementById("razer_orbweaver_chroma").style.display = "none";
            document.getElementById("razer_tartarus").style.display = "none";
            document.getElementById("razer_tartarus_chroma").style.display = "none";
            document.getElementById("razer_tartarus_pro").style.display = "table";
            document.getElementById("razer_tartarus_v2").style.display = "none";

            setStyleDisplayByClass("basicTartarusEffects", "inline-block");
            setStyleDisplayByClass("extraTartarusEffects", "none");
        ]]
    elseif device == "Razer Tartarus V2" then
        script = script .. [[
            document.getElementById("razer_nostromo").style.display = "none";
            document.getElementById("razer_orbweaver").style.display = "none";
            document.getElementById("razer_orbweaver_chroma").style.display = "none";
            document.getElementById("razer_tartarus").style.display = "none";
            document.getElementById("razer_tartarus_chroma").style.display = "none";
            document.getElementById("razer_tartarus_pro").style.display = "none";
            document.getElementById("razer_tartarus_v2").style.display = "table";

            setStyleDisplayByClass("basicTartarusEffects", "inline-block");
            setStyleDisplayByClass("extraTartarusEffects", "inline-block");
        ]]
    end

    local label
    if controlType == "button" then
        if controlID == "Mode" then
            label = "Mode Button"
        else
            label = "Button " .. controlID
        end
    elseif controlType == "scrollWheel" then
        label = "Scroll Wheel"
    elseif controlType == "joystick" then
        label = "Joystick"
    end

    script = script .. [[
        document.getElementById("label").innerHTML = "]] .. label .. [[";
        setStyleDisplayByClass("knob", "none");
		setStyleDisplayByClass("pressAction", "none");
		setStyleDisplayByClass("ledColor", "none");
		setStyleDisplayByClass("joystickAction", "none");
    ]]

    if controlType == "button" then
        if device == "Razer Tartarus V2" or device == "Razer Tartarus Pro" or device == "Razer Orbweaver Chroma" then
            script = script .. [[
                setStyleDisplayByClass("ledColor", "table");
            ]]
        end
        script = script .. [[
            setStyleDisplayByClass("pressAction", "table");
        ]]
    elseif controlType == "scrollWheel" then
        if device == "Razer Tartarus V2" or device == "Razer Tartarus Pro" or device == "Razer Orbweaver Chroma" then
            script = script .. [[
                setStyleDisplayByClass("ledColor", "table");
            ]]
        end
        script = script .. [[
            setStyleDisplayByClass("pressAction", "table");
			setStyleDisplayByClass("knob", "table");
        ]]
    elseif controlType == "joystick" then
        script = script .. [[
            setStyleDisplayByClass("joystickAction", "table");
        ]]
    end

    script = script .. [[
        document.getElementById("controlType").value = "]] .. controlType .. [[";
		document.getElementById("controlID").value = "]] .. controlID .. [[";
    ]]

    injectScript(script)

    --------------------------------------------------------------------------------
    -- Refresh the hardware:
    --------------------------------------------------------------------------------
    mod._razerManager.refresh()
end

-- razerPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function razerPanelCallback(id, params)
    local injectScript = mod._manager.injectScript
    local callbackType = params and params["type"]
    if callbackType then
        --------------------------------------------------------------------------------
        -- TODO: One day, instead of using a crazy if...else statement, it would be
        --       better and cleaner to use a table of functions.
        --------------------------------------------------------------------------------
        if callbackType == "updateAction" then
            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            local device        = params["device"]
            local app           = params["application"]
            local bank          = params["bank"]
            local controlType   = params["controlType"]
            local controlID     = params["controlID"]
            local buttonType    = params["buttonType"]

            local activatorID   = params["application"]

            --------------------------------------------------------------------------------
            -- NOTE: "nippetAction" is not a type as it could be "snippetAction" or
            --       "ledSnippetAction"
            --------------------------------------------------------------------------------
            if buttonType:sub(-12) == "nippetAction" then
                 activatorID = "snippet"
            end

            if not mod.activator then
                mod.activator = {}
            end

            if activatorID == "snippet" and not mod.activator[activatorID] then
                --------------------------------------------------------------------------------
                -- Create a new Snippet Activator:
                --------------------------------------------------------------------------------
                mod.activator["snippet"] = mod._actionmanager.getActivator("razerPreferences_preferences_snippet")

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
                mod.activator[activatorID] = mod._actionmanager.getActivator("razerPreferences" .. activatorID)

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

                setItem(device, app, bank, controlType, controlID, buttonType, result)

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                updateUI(params)
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[activatorID]:show()
        elseif callbackType == "clearAction" then
            --------------------------------------------------------------------------------
            -- Clear an action:
            --------------------------------------------------------------------------------
            local device        = params["device"]
            local app           = params["application"]
            local bank          = params["bank"]
            local controlType   = params["controlType"]
            local controlID     = params["controlID"]
            local buttonType    = params["buttonType"]

            setItem(device, app, bank, controlType, controlID, buttonType, {})

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            updateUI(params)
        elseif callbackType == "updateApplicationAndBank" then
            local device        = params["device"]
            local app           = params["application"]
            local bank          = params["bank"]

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

                        items[device][bundleID] = {
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
                --------------------------------------------------------------------------------
                -- Update Last Application & Last Bank:
                --------------------------------------------------------------------------------
                mod.lastApplication(app)
                mod.lastBank(bank)

                --------------------------------------------------------------------------------
                -- If change bank on hardware:
                --------------------------------------------------------------------------------
                if mod.changeBankOnHardwareWhenChangingHere() then
                    --------------------------------------------------------------------------------
                    -- Update the Last Bundle ID used when "Automatically Switch Applications"
                    -- is disabled.
                    --------------------------------------------------------------------------------
                    local lastBundleID = mod.lastBundleID()
                    lastBundleID[device] = app
                    mod.lastBundleID(lastBundleID)

                    --------------------------------------------------------------------------------
                    -- Change the bank:
                    --------------------------------------------------------------------------------
                    local activeBanks = mod._razerManager.activeBanks()

                    if not activeBanks[device] then activeBanks[device] = {} end

                    activeBanks[device][app] = bank
                    mod._razerManager.activeBanks(activeBanks)
                end

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                updateUI(params)
            end
        elseif callbackType == "updateUI" then
            updateUI(params)
        elseif callbackType == "updateDevice" then
            mod.lastDevice(params.device)
            mod._manager.refresh()
        elseif callbackType == "updateColor" then
            --------------------------------------------------------------------------------
            -- Update Color:
            --------------------------------------------------------------------------------
            local device        = params["device"]
            local app           = params["application"]
            local bank          = params["bank"]
            local controlType   = params["controlType"]
            local controlID     = params["controlID"]
            local value         = params["value"]

            setItem(device, app, bank, controlType, controlID, "led", value)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._razerManager.refresh()
        elseif callbackType == "updatePreventExcessiveThumbTaps" then
            --------------------------------------------------------------------------------
            -- Update Prevent Excessive Thumb Taps:
            --------------------------------------------------------------------------------
            local device        = params["device"]
            local app           = params["application"]
            local bank          = params["bank"]
            local controlType   = params["controlType"]
            local controlID     = params["controlID"]
            local value         = params["value"]

            setItem(device, app, bank, controlType, controlID, "preventExcessiveThumbTaps", value)
        elseif callbackType == "updateBankLabel" then
            --------------------------------------------------------------------------------
            -- Update Bank Label:
            --------------------------------------------------------------------------------
            local device    = params["device"]
            local app       = params["application"]
            local bank      = params["bank"]

            local items = mod.items()

            if not items[device] then items[device] = {} end
            if not items[device][app] then items[device][app] = {} end
            if not items[device][app][bank] then items[device][app][bank] = {} end
            items[device][app][bank]["bankLabel"] = params["bankLabel"]

            mod.items(items)
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

                local path = chooseFileOrFolder(i18n("pleaseSelectAFileToImport") .. ":", lastImportPath, true, false, false, {"cpRazer"})
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
            local device    = params["device"]
            local app       = params["application"]
            local bank      = params["bank"]

            local exportSettings = function(what)
                local items = mod.items()
                local data = {}

                local filename = ""

                if what == "Everything" then
                    data = copy(items)
                    filename = "Everything"
                elseif what == "Device" then
                    data[device] = copy(items[device])
                    filename = device
                elseif what == "Application" then
                    data[device] = {}
                    data[device][app] = copy(items[device][app])
                    filename = app
                elseif what == "Bank" then
                    data[device] = {}
                    data[device][app] = {}
                    data[device][app][bank] = copy(items[device][app][bank])
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
                    json.write(path["1"] .. "/" .. filename .. " - " .. os.date("%Y%m%d %H%M") .. ".cpRazer", data)
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
                title = i18n("device"),
                fn = function() exportSettings("Device") end,
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
        elseif callbackType == "copyControlToAllBanks" then
            --------------------------------------------------------------------------------
            -- Copy Control to All Banks:
            --------------------------------------------------------------------------------
            local items = mod.items()

            local device            = params["device"]
            local app               = params["application"]
            local bank              = params["bank"]
            local controlType       = params["controlType"]
            local controlID         = params["controlID"]

            local theDevice         = items[device]
            local theApp            = theDevice and theDevice[app]
            local theBank           = theApp and theApp[bank]
            local theControlType    = theBank and theBank[controlType]
            local theControlID      = theControlType and theControlType[controlID] or {}

            local bankLabels = mod._razerManager.bankLabels
            local numberOfBanks = tableCount(bankLabels[device])

            local data = copy(theControlID)
            for b=1, numberOfBanks do
                setItem(device, app, tostring(b), controlType, controlID, data)
            end

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            mod._razerManager.refresh()
        elseif callbackType == "resetControl" then
            --------------------------------------------------------------------------------
            -- Reset Control:
            --------------------------------------------------------------------------------
            local device        = params["device"]
            local app           = params["application"]
            local bank          = params["bank"]
            local controlType   = params["controlType"]
            local controlID     = params["controlID"]

            local items = mod.items()

            if items[device] and items[device][app] and items[device][app][bank] and items[device][app][bank][controlType] and items[device][app][bank][controlType][controlID] then
                items[device][app][bank][controlType][controlID] = nil
            end

            mod.items(items)

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            updateUI(params)
        elseif callbackType == "resetEverything" then
            --------------------------------------------------------------------------------
            -- Reset Everything:
            --------------------------------------------------------------------------------
            local resetEverything = function(completelyEmpty)
                webviewAlert(mod._manager.getWebview(), function(result)
                    if result == i18n("yes") then
                        mod._razerManager.reset(completelyEmpty)
                        mod._manager.refresh()

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        mod._razerManager.refresh()
                    end
                end, i18n("razerResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
            end

            local menu = {}

            table.insert(menu, {
                title = i18n("factoryDefault"),
                fn = function() resetEverything(false) end,
            })

            table.insert(menu, {
                title = i18n("completelyEmpty"),
                fn = function() resetEverything(true) end,
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)

        elseif callbackType == "resetDevice" then
            --------------------------------------------------------------------------------
            -- Reset Device:
            --------------------------------------------------------------------------------
            local resetDevice = function(completelyEmpty)
                webviewAlert(mod._manager.getWebview(), function(result)
                    if result == i18n("yes") then
                        local items = mod.items()
                        local device = mod.lastDevice()

                        local defaultLayout = mod._razerManager.defaultLayout
                        if not items[device] then items[device] = {} end
                        items[device] = defaultLayout and defaultLayout[device] or {}

                        if completelyEmpty then
                            items[device] = {}
                        end

                        mod.items(items)
                        mod._manager.refresh()

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        mod._razerManager.refresh()
                    end
                end, i18n("razerResetDeviceConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
            end

            local menu = {}

            table.insert(menu, {
                title = i18n("factoryDefault"),
                fn = function() resetDevice(false) end,
            })

            table.insert(menu, {
                title = i18n("completelyEmpty"),
                fn = function() resetDevice(true) end,
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "resetApplication" then
            --------------------------------------------------------------------------------
            -- Reset Application:
            --------------------------------------------------------------------------------
            local resetApplication = function(completelyEmpty)
                webviewAlert(mod._manager.getWebview(), function(result)
                    if result == i18n("yes") then
                        local items = mod.items()
                        local device = mod.lastDevice()
                        local app = mod.lastApplication()

                        local defaultLayout = mod._razerManager.defaultLayout
                        if not items[device] then items[device] = {} end
                        items[device][app] = defaultLayout and defaultLayout[device] and defaultLayout[device][app] or {}

                        if completelyEmpty then
                            items[device][app] = {}
                        end

                        mod.items(items)
                        mod._manager.refresh()

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        mod._razerManager.refresh()
                    end
                end, i18n("razerResetApplicationConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
            end

            local menu = {}

            table.insert(menu, {
                title = i18n("factoryDefault"),
                fn = function() resetApplication(false) end,
            })

            table.insert(menu, {
                title = i18n("completelyEmpty"),
                fn = function() resetApplication(true) end,
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "resetBank" then
            --------------------------------------------------------------------------------
            -- Reset Bank:
            --------------------------------------------------------------------------------
            local resetBank = function(completelyEmpty)
                webviewAlert(mod._manager.getWebview(), function(result)
                    if result == i18n("yes") then
                        local items = mod.items()
                        local device = mod.lastDevice()
                        local app = mod.lastApplication()
                        local bank = mod.lastBank()

                        local defaultLayout = mod._razerManager.defaultLayout

                        if items[device] and items[device][app] and items[device][app][bank] then
                            items[device][app][bank] = defaultLayout and defaultLayout[device] and defaultLayout[device][app] and defaultLayout[device][app][bank] or {}

                            if completelyEmpty then
                                items[device][app][bank] = {}
                            end
                        end

                        mod.items(items)
                        mod._manager.refresh()

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        mod._razerManager.refresh()
                    end
                end, i18n("razerResetBankConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
            end

            local menu = {}

            table.insert(menu, {
                title = i18n("factoryDefault"),
                fn = function() resetBank(false) end,
            })

            table.insert(menu, {
                title = i18n("completelyEmpty"),
                fn = function() resetBank(true) end,
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "ledExamples" then
            --------------------------------------------------------------------------------
            -- Examples Button:
            --------------------------------------------------------------------------------
            execute('open "' .. SNIPPET_LED_HELP_URL .. '"')
        elseif callbackType == "editSnippet" then
            --------------------------------------------------------------------------------
            -- Edit Snippet:
            --------------------------------------------------------------------------------
            local device        = params["device"]
            local app           = params["application"]
            local bank          = params["bank"]
            local controlType   = params["controlType"]
            local controlID     = params["controlID"]
            local actionType    = params["actionType"]

            local items = mod.items()
            if items[device] and items[device][app] and items[device][app][bank] and items[device][app][bank][controlType] and items[device][app][bank][controlType][controlID] then
                local snippetAction = items[device][app][bank][controlType][controlID][actionType]
                local snippetID = snippetAction and snippetAction.action and snippetAction.action.id
                if snippetID then
                    local snippets = copy(mod._scriptingPreferences.snippets())

                    if not snippets[snippetID] then
                        --------------------------------------------------------------------------------
                        -- This Snippet doesn't exist in the Snippets Preferences, so it must have
                        -- been deleted or imported through one of the Control Surface panels.
                        -- It will be reimported into the Snippets Preferences.
                        --------------------------------------------------------------------------------
                        snippets[snippetID] = {
                            ["code"] = snippetAction.action.code
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
            end

            --------------------------------------------------------------------------------
            -- Open the Scripting Preferences Panel:
            --------------------------------------------------------------------------------
            mod._scriptingPreferences._manager.lastTab("scripting")
            mod._scriptingPreferences._manager.selectPanel("scripting")
            mod._scriptingPreferences._manager.show()
        elseif callbackType == "copyApplication" then
            --------------------------------------------------------------------------------
            -- Copy Application:
            --------------------------------------------------------------------------------
            local copyApplication = function(destinationApp)
                local items = mod.items()
                local device = mod.lastDevice()
                local app = mod.lastApplication()

                local data = items[device] and items[device][app]
                if data then
                    --------------------------------------------------------------------------------
                    -- Don't replace the display name:
                    --------------------------------------------------------------------------------
                    local originalDisplayName = items[device][destinationApp].displayName
                    items[device][destinationApp] = fnutils.copy(data)
                    items[device][destinationApp].displayName = originalDisplayName

                    mod.items(items)

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware (and trash the LED cache):
                    --------------------------------------------------------------------------------
                    mod._razerManager.refresh(true)

                    --------------------------------------------------------------------------------
                    -- Refresh the UI:
                    --------------------------------------------------------------------------------
                    mod._manager.refresh()
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
            local devices = items[mod.lastDevice()] or {}
            for bundleID, v in pairs(devices) do
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

            table.insert(menu, {
                title = i18n("unlistedAndIgnoredApplications"),
                fn = function() copyApplication("All Applications") end
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
        elseif callbackType == "changeIgnore" then
            local device    = params["device"]
            local app       = params["application"]
            local ignore    = params["ignore"]

            local items = mod.items()

            if not items[device] then items[device] = {} end
            if not items[device][app] then items[device][app] = {} end
            items[device][app]["ignore"] = ignore

            mod.items(items)

            --------------------------------------------------------------------------------
            -- Refresh the hardware (and trash the LED cache):
            --------------------------------------------------------------------------------
            mod._razerManager.refresh(true)
        elseif callbackType == "repeatCheckbox" then
            local device        = params["device"]
            local app           = params["application"]
            local bank          = params["bank"]
            local controlType   = params["controlType"]
            local controlID     = params["controlID"]
            local actionType    = params["actionType"]
            local value         = params["value"] or false

            setItem(device, app, bank, controlType, controlID, actionType .. "Repeat", value)
        elseif callbackType == "copyBank" then
            --------------------------------------------------------------------------------
            -- Copy Bank:
            --------------------------------------------------------------------------------
            local copyToBank = function(destinationBank)
                local items     = mod.items()
                local device    = mod.lastDevice()
                local app       = mod.lastApplication()
                local bank      = mod.lastBank()

                local data = items[device] and items[device][app] and items[device][app][bank]
                if data then
                    items[device][app][destinationBank] = fnutils.copy(data)
                    mod.items(items)

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware (and trash the LED cache):
                    --------------------------------------------------------------------------------
                    mod._razerManager.refresh(true)
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

            local deviceName = mod.lastDevice()
            local bankLabels = mod._razerManager.bankLabels
            local numberOfBanks = tableCount(bankLabels[deviceName])
            for i=1, numberOfBanks do
                table.insert(menu, {
                    title = bankLabels[deviceName][tostring(i)].label,
                    fn = function() copyToBank(tostring(i)) end
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "copyDevice" then
            --------------------------------------------------------------------------------
            -- Copy Device:
            --------------------------------------------------------------------------------
            local device = mod.lastDevice()

            local copyDevice = function(destinationDevice)
                local items = mod.items()
                local data = items[device]
                if data then
                    items[destinationDevice] = copy(data)
                    mod.items(items)

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware (and trash the LED cache):
                    --------------------------------------------------------------------------------
                    mod._razerManager.refresh(true)
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

            for _, deviceID in pairs(mod._razerManager.supportedDevices) do
                table.insert(menu, {
                    title = deviceID,
                    fn = function() copyDevice(deviceID) end
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "showContextMenu" then
            --------------------------------------------------------------------------------
            -- Show Context Menu:
            --------------------------------------------------------------------------------
            local items = mod.items()

            local device            = params["device"]
            local app               = params["application"]
            local bank              = params["bank"]
            local controlType       = params["controlType"]
            local controlID         = params["controlID"]

            local pasteboard = mod.pasteboard()

            local menu = {}

            local theDevice         = items[device]
            local theApp            = theDevice and theDevice[app]
            local theBank           = theApp and theApp[bank]
            local theControlType    = theBank and theBank[controlType]
            local theControlID      = theControlType and theControlType[controlID]

            local isControlEmpty = next(theControlID or {}) == nil

            table.insert(menu, {
                title = i18n("cut"),
                disabled = isControlEmpty,
                fn = function()
                    --------------------------------------------------------------------------------
                    -- Cut:
                    --------------------------------------------------------------------------------
                    pasteboard = copy(theControlID)
                    mod.pasteboard(pasteboard)
                    setItem(device, app, bank, controlType, controlID, {})
                    updateUI()
                end
            })

            table.insert(menu, {
                title = i18n("copy"),
                disabled = isControlEmpty,
                fn = function()
                    --------------------------------------------------------------------------------
                    -- Copy:
                    --------------------------------------------------------------------------------
                    pasteboard = copy(theControlID)
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
                    setItem(device, app, bank, controlType, controlID, copy(pasteboard))
                    updateUI()
                end
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "dropAndDrop" then
            --------------------------------------------------------------------------------
            -- Drag & Drop:
            --------------------------------------------------------------------------------
            local device            = params["device"]
            local app               = params["application"]
            local bank              = params["bank"]

            local sourceType        = params["sourceType"]
            local destinationType   = params["destinationType"]

            --------------------------------------------------------------------------------
            -- This shouldn't ever happen, but just to be safe:
            --------------------------------------------------------------------------------
            if sourceType ~= destinationType then
                return
            end

            local controlType       = destinationType

            local source            = params["sourceID"]
            local destination       = params["destinationID"]

            --------------------------------------------------------------------------------
            -- Swap controls:
            --------------------------------------------------------------------------------
            local items = mod.items()

            if not items[device] then                           items[device] = {} end
            if not items[device][app] then                      items[device][app] = {} end
            if not items[device][app][bank] then                items[device][app][bank] = {} end
            if not items[device][app][bank][controlType] then   items[device][app][bank][controlType] = {} end

            local destinationData = items[device][app][bank][controlType][destination] or {}
            local sourceData = items[device][app][bank][controlType][source] or {}

            local a = copy(destinationData)
            local b = copy(sourceData)

            items[device][app][bank][controlType][source] = a
            items[device][app][bank][controlType][destination] = b

            mod.items(items)

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Razer Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "core.razer.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.action.manager"]             = "actionmanager",
        ["core.razer.manager"]              = "razerManager",
        ["core.application.manager"]        = "appmanager",
        ["core.preferences.panels.scripting"]   = "scriptingPreferences",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._appmanager                         = deps.appmanager
    mod._manager                            = deps.manager
    mod._webviewLabel                       = deps.manager.getLabel()
    mod._actionmanager                      = deps.actionmanager
    mod._env                                = env

    mod._scriptingPreferences               = deps.scriptingPreferences

    mod._razerManager                       = deps.razerManager
    mod.items                               = deps.razerManager.items
    mod.enabled                             = deps.razerManager.enabled
    mod.automaticallySwitchApplications     = deps.razerManager.automaticallySwitchApplications
    mod.displayMessageWhenChangingBanks     = deps.razerManager.displayMessageWhenChangingBanks
    mod.lastBundleID                        = deps.razerManager.lastBundleID

    mod.keyRepeat                           = deps.razerManager.keyRepeat
    mod.delayUntilRepeat                    = deps.razerManager.delayUntilRepeat

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2032.3,
        id              = "razer",
        group           = "razer",
        groupMaster     = true,
        label           = i18n("razer"),
        image           = imageFromPath(env:pathToAbsolute("/images/razerIcon.png")),
        tooltip         = i18n("razerDevices"),
        height          = 1170,
    })
        :addHeading(1, i18n("razerDevices"))

        :addContent(2, [[
            <style>
                .menubarRow {
                    display: flex;
                }

                .menubarColumn {
                    flex: 50%;
                    height: 162px !important;
                }
            </style>
            <div class="menubarRow">
                <div class="menubarColumn">
        ]], false)

        :addCheckbox(3,
            {
                label       = i18n("enableRazerSupport"),
                checked     = mod.enabled,
                onchange    = function(_, params)
                    mod.enabled(params.checked)
                end,
            }
        )
        :addCheckbox(4,
            {
                label       =   i18n("automaticallySwitchApplications"),
                checked     =   function()
                                    local automaticallySwitchApplications = mod.automaticallySwitchApplications()
                                    return automaticallySwitchApplications[mod.lastDevice()]
                                end,
                onchange    =   function(_, params)
                                    local automaticallySwitchApplications = mod.automaticallySwitchApplications()
                                    automaticallySwitchApplications[mod.lastDevice()] = params.checked
                                    mod.automaticallySwitchApplications(automaticallySwitchApplications)
                                end,
            }
        )
        :addCheckbox(5,
            {
                label       =   i18n("displayMessageWhenChangingBanks"),
                checked     =   function()
                                    local displayMessageWhenChangingBanks = mod.displayMessageWhenChangingBanks()
                                    return displayMessageWhenChangingBanks[mod.lastDevice()]
                                end,
                onchange    =   function(_, params)
                                    local displayMessageWhenChangingBanks = mod.displayMessageWhenChangingBanks()
                                    displayMessageWhenChangingBanks[mod.lastDevice()] = params.checked
                                    mod.displayMessageWhenChangingBanks(displayMessageWhenChangingBanks)
                                end,
            }
        )
        :addCheckbox(6,
            {
                label       = i18n("changeBankOnHardwareWhenChangingHere"),
                checked     = mod.changeBankOnHardwareWhenChangingHere,
                onchange    = function(_, params)
                    mod.changeBankOnHardwareWhenChangingHere(params.checked)
                    updateUI()
                end,
            }
        )

        :addContent(6.1, [[
            <br />
                <style>
                    .keyRepeat select {
                        width: 250px;
                    }

                    .keyRepeatDropdown label {
                        width: 140px !important;
                        overflow:hidden;
                        display:inline-block;
                        text-overflow: ellipsis;
                        white-space: nowrap;
                    }

                    .keyRepeatDropdown select {
                        width: 200px !important;
                    }

                </style>
        ]], false)

        :addSelect(6.2,
            {
                label       =   i18n("keyRepeat"),
                id          =   "keyRepeat",
                class       =   "keyRepeat keyRepeatDropdown",
                value       =   function() return mod.keyRepeat() end,
                options     =   function()
                                    local options = {
                                        { value = "",                   label = i18n("useMacOSPreferences") .. "..." },
                                        { value = "2.0",                label = "2.0" .. i18n("secs", {count=2}) .. " (" .. i18n("slow") .. ")" },
                                        { value = "1.5",                label = "1.5" .. i18n("secs", {count=1}) },
                                        { value = "1.0",                label = "1.0" .. i18n("secs", {count=1}) },
                                        { value = "0.5",                label = "0.5" .. i18n("secs", {count=1}) },
                                        { value = "0.2",                label = "0.2" .. i18n("secs", {count=1}) },
                                        { value = "0.1",                label = "0.1" .. i18n("secs", {count=1}) },
                                        { value = "0.033333333333333",  label = "0.03" .. i18n("secs", {count=1}) .. " (" .. i18n("fast") .. ")" },
                                    }
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    mod.keyRepeat(params.value)
                                end,
            }
        )

        :addSelect(6.3,
            {
                label       =   i18n("delayUntilRepeat"),
                id          =   "delayUntilRepeat",
                class       =   "keyRepeat keyRepeatDropdown",
                value       =   function() return mod.delayUntilRepeat() end,
                options     =   function()
                                    local options = {
                                        { value = "",                   label = i18n("useMacOSPreferences") .. "..." },
                                        { value = "2.0",                label = "2.0" .. i18n("secs", {count=2}) .. " (" .. i18n("long") .. ")" },
                                        { value = "1.5666666666667",    label = "1.56" .. i18n("secs", {count=1}) },
                                        { value = "1.1333333333333",    label = "1.13" .. i18n("secs", {count=1}) },
                                        { value = "0.58333333333333",   label = "0.58" .. i18n("secs", {count=1}) },
                                        { value = "0.41666666666667",   label = "0.41" .. i18n("secs", {count=1}) },
                                        { value = "0.03",               label = "0.25" .. i18n("secs", {count=1}) .. " (" .. i18n("short") .. ")" },
                                    }
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    mod.delayUntilRepeat(params.value)
                                end,
            }
        )

        :addContent(7, [[
                </div>
                <div class="menubarColumn">
                <style>
                    .backlightsMode select {
                        width: 250px;
                    }

                    .restrictRightTopSectionSize label {
                        width: 250px !important;
                        overflow:hidden;
                        display:inline-block;
                        text-overflow: ellipsis;
                        white-space: nowrap;
                    }

                    .restrictRightTopSectionSize select {
                        width: 130px !important;
                    }

                    .colorPreferences input {
                        margin-left: 2px;
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
                        width: 106px;
                    }
                </style>
        ]], false)

        :addSelect(8,
            {
                label       =   i18n("backlightBrightness"),
                class       =   "backlightBrightness restrictRightTopSectionSize",
                value       =   function()
                                    local device = mod.lastDevice()
                                    local backlightBrightness = mod._razerManager.backlightBrightness()
                                    return backlightBrightness[device]
                                end,
                options     =   function()
                                    local options = {
                                        { value = "1",       label = "1 (" .. i18n("darkest") .. ")" },
                                        { value = "5",       label = "5" },
                                        { value = "10",      label = "10" },
                                        { value = "15",      label = "15" },
                                        { value = "20",      label = "20" },
                                        { value = "25",      label = "25" },
                                        { value = "30",      label = "30" },
                                        { value = "35",      label = "35" },
                                        { value = "40",      label = "40" },
                                        { value = "45",      label = "45" },
                                        { value = "50",      label = "50" },
                                        { value = "55",      label = "55" },
                                        { value = "60",      label = "60" },
                                        { value = "65",      label = "65" },
                                        { value = "70",      label = "70" },
                                        { value = "75",      label = "75" },
                                        { value = "80",      label = "80" },
                                        { value = "85",      label = "85" },
                                        { value = "90",      label = "90" },
                                        { value = "95",      label = "95" },
                                        { value = "100",     label = "100 (" .. i18n("brightest") .. ")" },
                                    }
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    local device = mod.lastDevice()
                                    local backlightBrightness = mod._razerManager.backlightBrightness()
                                    backlightBrightness[device] = params.value
                                    mod._razerManager.backlightBrightness(backlightBrightness)
                                    mod._razerManager.refresh(true)
                                end,
            }
        )

        :addSelect(9,
            {
                label       =   i18n("backlightsMode"),
                id          =   "backlightsMode",
                class       =   "backlightsMode restrictRightTopSectionSize basicTartarusEffects",
                value       =   function()
                                    local device = mod.lastDevice()
                                    local backlightsMode = mod._razerManager.backlightsMode()
                                    return backlightsMode[device]
                                end,
                options     =   function()
                                    local device = mod.lastDevice()
                                    local options

                                    if device == "Razer Tartarus V2" or device == "Razer Orbweaver Chroma" then
                                        options = {
                                            { value = "Off",              label = i18n("off") },
                                            { value = "User Defined",     label = i18n("userDefined") },
                                            { value = "Breathing",        label = i18n("breathing") },
                                            { value = "Reactive",         label = i18n("reactive") },
                                            { value = "Spectrum",         label = i18n("spectrum") },
                                            { value = "Starlight",        label = i18n("starlight") },
                                            { value = "Static",           label = i18n("static") },
                                            { value = "Wave",             label = i18n("wave") },
                                        }
                                    elseif device == "Razer Tartarus Pro" then
                                        options = {
                                            { value = "Off",              label = i18n("off") },
                                            { value = "User Defined",     label = i18n("userDefined") },
                                            { value = "Static",           label = i18n("static") },
                                        }
                                    elseif device == "Razer Tartarus Chroma" then
                                        options = {
                                            { value = "Off",              label = i18n("off") },
                                            { value = "Breathing",        label = i18n("breathing") },
                                            { value = "Spectrum",         label = i18n("spectrum") },
                                            { value = "Static",           label = i18n("static") },
                                        }
                                    end
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    local device = mod.lastDevice()
                                    local backlightsMode = mod._razerManager.backlightsMode()
                                    backlightsMode[device] = params.value
                                    mod._razerManager.backlightsMode(backlightsMode)
                                    mod._razerManager.refresh(true)
                                end,
            }
        )

        :addTextbox(10,
            {
                label       =   i18n("backlightEffectColorPrimary") .. ":",
                id          =   "backlightEffectColorPrimary",
                value       =   function()
                                    local device = mod.lastDevice()
                                    local backlightEffectColorA = mod._razerManager.backlightEffectColorA()
                                    return backlightEffectColorA[device]
                                end,
                class       =   "basicTartarusEffects restrictRightTopSectionSize colorPreferences jscolor {hash:true, borderColor:'#FFF', insetColor:'#FFF', backgroundColor:'#666'} jscolor-active",
                onchange    =   function(_, params)
                                    local device = mod.lastDevice()
                                    local backlightEffectColorA = mod._razerManager.backlightEffectColorA()
                                    backlightEffectColorA[device] = params.value
                                    mod._razerManager.backlightEffectColorA(backlightEffectColorA)
                                    mod._razerManager.refresh(true)
                                end,
            }
        )

        :addTextbox(11,
            {
                label       =   i18n("backlightEffectColorSecondary") .. ":",
                id          =   "backlightEffectColorSecondary",
                value       =   function()
                                    local device = mod.lastDevice()
                                    local backlightEffectColorB = mod._razerManager.backlightEffectColorB()
                                    return backlightEffectColorB[device]
                                end,
                class       =   "extraTartarusEffects restrictRightTopSectionSize colorPreferences jscolor {hash:true, borderColor:'#FFF', insetColor:'#FFF', backgroundColor:'#666'} jscolor-active",
                onchange    =   function(_, params)
                                    local device = mod.lastDevice()
                                    local backlightEffectColorB = mod._razerManager.backlightEffectColorB()
                                    backlightEffectColorB[device] = params.value
                                    mod._razerManager.backlightEffectColorB(backlightEffectColorB)
                                    mod._razerManager.refresh(true)
                                end,
            }
        )

        :addSelect(12,
            {
                label       =   i18n("backlightEffectDirection"),
                id          =   "backlightEffectDirection",
                class       =   "extraTartarusEffects backlightsMode restrictRightTopSectionSize",
                value       =   function()
                                    local device = mod.lastDevice()
                                    local backlightEffectDirection = mod._razerManager.backlightEffectDirection()
                                    return backlightEffectDirection[device]
                                end,
                options     =   function()
                                    local options = {
                                        { value = "left",       label = i18n("left") },
                                        { value = "right",      label = i18n("right") },
                                    }
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    local device = mod.lastDevice()
                                    local backlightEffectDirection = mod._razerManager.backlightEffectDirection()
                                    backlightEffectDirection[device] = params.value
                                    mod._razerManager.backlightEffectDirection(backlightEffectDirection)
                                    mod._razerManager.refresh(true)
                                end,
            }
        )

        :addSelect(13,
            {
                label       =   i18n("backlightEffectSpeed"),
                id          =   "backlightEffectSpeed",
                class       =   "extraTartarusEffects backlightsMode restrictRightTopSectionSize",
                value       =   function()
                                    local device = mod.lastDevice()
                                    local backlightEffectSpeed = mod._razerManager.backlightEffectSpeed()
                                    return backlightEffectSpeed[device]
                                end,
                options     =   function()
                                    local options = {
                                        { value = "1",       label = "1 (" .. i18n("fast") .. ")" },
                                        { value = "2",       label = "2" },
                                        { value = "3",       label = "3" },
                                        { value = "4",       label = "4" },
                                        { value = "5",       label = "5" },
                                        { value = "10",      label = "10" },
                                        { value = "20",      label = "20" },
                                        { value = "30",      label = "30" },
                                        { value = "40",      label = "40" },
                                        { value = "50",      label = "50" },
                                        { value = "60",      label = "60" },
                                        { value = "70",      label = "70" },
                                        { value = "80",      label = "80" },
                                        { value = "90",      label = "90" },
                                        { value = "100",     label = "100" },
                                        { value = "110",     label = "110" },
                                        { value = "120",     label = "120" },
                                        { value = "130",     label = "130" },
                                        { value = "140",     label = "140" },
                                        { value = "150",     label = "150" },
                                        { value = "160",     label = "160" },
                                        { value = "170",     label = "170" },
                                        { value = "180",     label = "180" },
                                        { value = "190",     label = "190" },
                                        { value = "200",     label = "200" },
                                        { value = "210",     label = "210" },
                                        { value = "220",     label = "220" },
                                        { value = "230",     label = "230" },
                                        { value = "240",     label = "240" },
                                        { value = "250",     label = "250" },
                                        { value = "255",     label = "255 (" .. i18n("slow") .. ")" },
                                    }
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    local device = mod.lastDevice()
                                    local backlightEffectSpeed = mod._razerManager.backlightEffectSpeed()
                                    backlightEffectSpeed[device] = params.value
                                    mod._razerManager.backlightEffectSpeed(backlightEffectSpeed)
                                    mod._razerManager.refresh(true)
                                end,
            }
        )

        :addContent(14, [[
                </div>
            </div>
            <br />
        ]], false)


        :addContent(15, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "razerPanelCallback", razerPanelCallback)

    return mod
end

return plugin
