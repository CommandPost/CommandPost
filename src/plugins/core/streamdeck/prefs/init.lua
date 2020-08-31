--- === plugins.core.streamdeck.prefs ===
---
--- Stream Deck Preferences Panel

local require                   = require

local os                        = os

local log                       = require "hs.logger".new "prefsStreamDeck"

local application               = require "hs.application"
local canvas                    = require "hs.canvas"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
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
local imageFromPath             = image.imageFromPath
local infoForBundlePath         = application.infoForBundlePath
local mergeTable                = tools.mergeTable
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- KEY_CREATOR_URL -> string
-- Constant
-- URL to Key Creator Website
local KEY_CREATOR_URL = "https://www.elgato.com/en/gaming/keycreator"

-- BUY_MORE_ICONS_URL -> string
-- Constant
-- URL to SideshowFX Website
local BUY_MORE_ICONS_URL = "http://www.sideshowfx.net/buy"

--- plugins.core.streamdeck.prefs.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Stream Deck Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

local iconPath = config.assetsPath .. "/icons/"

--- plugins.core.streamdeck.prefs.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = iconPath .. "Stream Deck/"

--- plugins.core.streamdeck.prefs.lastIconPath <cp.prop: string>
--- Field
--- Last icon path.
mod.lastIconPath = config.prop("streamDeck.preferences.lastIconPath", mod.defaultIconPath)

--- plugins.core.streamdeck.prefs.lastExportPath <cp.prop: string>
--- Field
--- Last Export path.
mod.lastExportPath = config.prop("streamDeck.preferences.lastExportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.streamdeck.prefs.lastImportPath <cp.prop: string>
--- Field
--- Last Import path.
mod.lastImportPath = config.prop("streamDeck.preferences.lastImportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.streamdeck.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Application used in the Preferences Panel.
mod.lastApplication = config.prop("streamDeck.preferences.lastApplication", "All Applications")

--- plugins.core.streamdeck.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastBank = config.prop("streamDeck.preferences.lastBank", "1")

--- plugins.core.streamdeck.prefs.lastDevice <cp.prop: string>
--- Field
--- Last Device used in the Preferences Panel.
mod.lastDevice = config.prop("streamDeck.preferences.lastDevice", "Original")

--- plugins.core.streamdeck.prefs.lastUnit <cp.prop: string>
--- Field
--- Last Unit used in the Preferences Panel.
mod.lastUnit = config.prop("streamDeck.preferences.lastUnit", "1")

--- plugins.core.touchbar.prefs.scrollBarPosition <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.scrollBarPosition = config.prop("streamDeck.preferences.scrollBarPosition", {})

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
    local device = params["device"]
    local unit = params["unit"]
    local app = params["application"]
    local bank = params["bank"]

    local injectScript = mod._manager.injectScript

    local script = [[
        changeValueByID("device", "]] .. device .. [[");
        changeValueByID("unit", "]] .. unit .. [[");
        changeValueByID("application", "]] .. app .. [[");
        changeValueByID("bank", "]] .. bank .. [[");
    ]]

    --------------------------------------------------------------------------------
    -- Show the appropriate amount of rows:
    --------------------------------------------------------------------------------
    local numberOfButtons = mod._sd.numberOfButtons[device]
    for i=1, 32 do
        if i > numberOfButtons then
            script = script .. [[
                document.getElementById("row_]] .. tostring(i) .. [[").style.display = "none";
            ]] .. "\n"
        else
            script = script .. [[
                document.getElementById("row_]] .. tostring(i) .. [[").style.display = "table";
            ]] .. "\n"
        end

        if i == numberOfButtons then
            script = script .. [[
                document.getElementById("down_]] .. tostring(i) .. [[").style.display = "none";
            ]] .. "\n"
        else
            script = script .. [[
                document.getElementById("down_]] .. tostring(i) .. [[").style.display = "inline-block";
            ]] .. "\n"
        end
    end

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
    -- Update all Action Titles, Labels & Icons:
    --------------------------------------------------------------------------------
    for i=1, numberOfButtons do
        local buttonData = bankData and bankData[tostring(i)]
        if buttonData and buttonData.actionTitle and buttonData.actionTitle ~= "" then
            script = script .. [[
                document.getElementById("action_]] .. tostring(i) .. [[").value = `]] .. escapeTilda(buttonData.actionTitle) .. [[`;
            ]] .. "\n"
        else
            script = script .. [[
                document.getElementById("action_]] .. tostring(i) .. [[").value = "]] .. i18n("none") .. [[";
            ]] .. "\n"
        end

        if buttonData and buttonData.label and buttonData.label ~= "" then
            script = script .. [[
                document.getElementById("label_]] .. tostring(i) .. [[").value = "]] .. buttonData.label .. [[";
            ]] .. "\n"
        else
            script = script .. [[
                document.getElementById("label_]] .. tostring(i) .. [[").value = "";
            ]] .. "\n"
        end

        if buttonData and buttonData.icon and buttonData.icon ~= "" then
            script = script .. [[
                document.getElementById("dropzone]] .. i .. [[_preview").innerHTML = "<img src=']] .. buttonData.icon .. [['>";
                document.getElementById("dropzone]] .. i .. [[").className = "dropzone dropped";
            ]] .. "\n"
        else
            script = script .. [[
                document.getElementById("dropzone]] .. i .. [[_preview").innerHTML = "icon";
                document.getElementById("dropzone]] .. i .. [[").className = "dropzone";
            ]] .. "\n"
        end
    end

    --------------------------------------------------------------------------------
    -- Update Bank Label:
    --------------------------------------------------------------------------------
    local bankLabel = bankData and bankData.bankLabel
    if bankLabel and bankLabel ~= "" then
        script = script .. [[
            document.getElementById("bankLabel").value = `]] .. escapeTilda(bankLabel) .. [[`;
        ]] .. "\n"
    else
        script = script .. [[
            document.getElementById("bankLabel").value = "";
        ]] .. "\n"
    end

    --------------------------------------------------------------------------------
    -- Update Scroll Bar Position:
    --------------------------------------------------------------------------------
    local scrollBarPositions = mod.scrollBarPosition()
    local scrollBarPosition = scrollBarPositions and scrollBarPositions[device] and scrollBarPositions[device][unit] and scrollBarPositions[device][unit][app] and scrollBarPositions[device][unit][app][bank] or 0
    script = script .. [[
        document.getElementById("scrollArea").scrollTop = ]] .. scrollBarPosition .. [[;
    ]]

    --------------------------------------------------------------------------------
    -- Inject Script:
    --------------------------------------------------------------------------------
    injectScript(script)

    --------------------------------------------------------------------------------
    -- Update the hardware:
    --------------------------------------------------------------------------------
    mod._sd.update()
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
        elseif callbackType == "changeScrollAreaPosition" then
            --------------------------------------------------------------------------------
            -- Change Scroll Area Position:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]
            local position = params["position"]

            local scrollBarPositions = mod.scrollBarPosition()

            if not scrollBarPositions[device] then scrollBarPositions[device] = {} end
            if not scrollBarPositions[device][unit] then scrollBarPositions[device][unit] = {} end
            if not scrollBarPositions[device][unit][app] then scrollBarPositions[device][unit][app] = {} end

            scrollBarPositions[device][unit][app][bank] = tonumber(position)

            mod.scrollBarPosition(scrollBarPositions)
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
        elseif callbackType == "up" then
            --------------------------------------------------------------------------------
            -- Move Up:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"]

            local nextButton = tostring(tonumber(button) - 1)

            local items = mod.items()

            if not items[device] then items[device] = {} end
            if not items[device][unit] then items[device][unit] = {} end
            if not items[device][unit][app] then items[device][unit][app] = {} end
            if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end

            if not items[device][unit][app][bank][button] then items[device][unit][app][bank][button] = {} end
            if not items[device][unit][app][bank][nextButton] then items[device][unit][app][bank][nextButton] = {} end

            local a = items[device] and items[device][unit] and items[device][unit][app] and items[device][unit][app][bank] and items[device][unit][app][bank][button] and copy(items[device][unit][app][bank][button])
            local b = items[device] and items[device][unit] and items[device][unit][app] and items[device][unit][app][bank] and items[device][unit][app][bank][nextButton] and copy(items[device][unit][app][bank][nextButton])

            items[device][unit][app][bank][button] = b
            items[device][unit][app][bank][nextButton] = a

            mod.items(items)

            updateUI(params)
        elseif callbackType == "down" then
            --------------------------------------------------------------------------------
            -- Move Down:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"]

            local nextButton = tostring(tonumber(button) + 1)

            local items = mod.items()

            if not items[device] then items[device] = {} end
            if not items[device][unit] then items[device][unit] = {} end
            if not items[device][unit][app] then items[device][unit][app] = {} end
            if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end

            if not items[device][unit][app][bank][button] then items[device][unit][app][bank][button] = {} end
            if not items[device][unit][app][bank][nextButton] then items[device][unit][app][bank][nextButton] = {} end

            local a = items[device] and items[device][unit] and items[device][unit][app] and items[device][unit][app][bank] and items[device][unit][app][bank][button] and copy(items[device][unit][app][bank][button])
            local b = items[device] and items[device][unit] and items[device][unit][app] and items[device][unit][app][bank] and items[device][unit][app][bank][nextButton] and copy(items[device][unit][app][bank][nextButton])

            items[device][unit][app][bank][button] = b
            items[device][unit][app][bank][nextButton] = a

            mod.items(items)

            updateUI(params)
        elseif callbackType == "select" then
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
                local legacyGroupIDs = {}
                local registeredApps = mod._appmanager.getApplications()
                for bundleID, v in pairs(registeredApps) do
                    if v.displayName then
                        apps[bundleID] = v.displayName
                    end
                    legacyGroupIDs[bundleID] = v.legacyGroupID or bundleID
                end
                local items = mod.items()

                for _, device in pairs(items) do
                    for _, unit in pairs(device) do
                        for bundleID, v in pairs(unit) do
                            if v.displayName then
                                apps[bundleID] = v.displayName
                            end
                        end
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
                    mod.activator[groupID] = mod._actionmanager.getActivator("streamDeck.preferences." .. groupID)

                    --------------------------------------------------------------------------------
                    -- Restrict Allowed Handlers for Activator to current group (and global):
                    --------------------------------------------------------------------------------
                    local allowedHandlers = {}
                    for _,v in pairs(handlerIds) do
                        local handlerTable = tools.split(v, "_")
                        if handlerTable[1] == groupID or handlerTable[1] == legacyGroupIDs[groupID] or handlerTable[1] == "global" then
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
                local device = params["device"]
                local unit = params["unit"]
                local app = params["application"]
                local bank = params["bank"]
                local button = params["button"]

                local items = mod.items()

                if not items[device] then items[device] = {} end
                if not items[device][unit] then items[device][unit] = {} end
                if not items[device][unit][app] then items[device][unit][app] = {} end
                if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end
                if not items[device][unit][app][bank][button] then items[device][unit][app][bank][button] = {} end

                items[device][unit][app][bank][button].actionTitle = actionTitle
                items[device][unit][app][bank][button].label = actionTitle
                items[device][unit][app][bank][button].handlerID = handlerID
                items[device][unit][app][bank][button].action = action

                mod.items(items)

                updateUI(params)
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[activatorID]:show()
        elseif callbackType == "clear" then
            --------------------------------------------------------------------------------
            -- Clear:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"]

            local items = mod.items()

            if items[device] and items[device][unit] and items[device][unit][app] and items[device][unit][app][bank] and items[device][unit][app][bank][button] then
                items[device][unit][app][bank][button] = {}
            end

            mod.items(items)

            updateUI(params)
        elseif callbackType == "iconClicked" then
            --------------------------------------------------------------------------------
            -- Icon Clicked:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"]

            if not doesDirectoryExist(mod.lastIconPath()) then
                mod.lastIconPath(mod.defaultIconPath())
            end

            local result = chooseFileOrFolder(i18n("pleaseSelectAnIcon"), mod.lastIconPath(), true, false, false, mod.supportedExtensions, true)
            local failed = false
            if result and result["1"] then
                local path = result["1"]

                --------------------------------------------------------------------------------
                -- Save path for next time:
                --------------------------------------------------------------------------------
                mod.lastIconPath(removeFilenameFromPath(path))

                local icon = imageFromPath(path)
                if icon then
                    local genericPath = iconPath .. "Generic/Ionicons"
                    local touchBarPath = iconPath .. "Touch Bar"
                    if string.sub(path, 1, string.len(genericPath)) == genericPath or string.sub(path, 1, string.len(touchBarPath)) == touchBarPath then
                        --------------------------------------------------------------------------------
                        -- One of our pre-supplied images:
                        --------------------------------------------------------------------------------
                        local originalImage = imageFromPath(path):template(false)
                        if originalImage then

                            local a = canvas.new{x = 0, y = 0, w = 50, h = 50 }
                            a[1] = {
                              type="image",
                              image = originalImage,
                              frame = { x = "10%", y = "10%", h = "80%", w = "80%" },
                            }
                            a[2] = {
                              type = "rectangle",
                              action = "fill",
                              fillColor = { white = 1 },
                              compositeRule = "sourceAtop",
                            }
                            local newImage = a:imageFromCanvas()

                            local encodedIcon = newImage:encodeAsURLString()

                            local items = mod.items()

                            if not items[device] then items[device] = {} end
                            if not items[device][unit] then items[device][unit] = {} end
                            if not items[device][unit][app] then items[device][unit][app] = {} end
                            if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end
                            if not items[device][unit][app][bank][button] then items[device][unit][app][bank][button] = {} end

                            items[device][unit][app][bank][button].icon = encodedIcon

                            mod.items(items)

                            updateUI(params)
                        else
                            failed = true
                        end
                    else
                        --------------------------------------------------------------------------------
                        -- An image from outside the pre-supplied image path:
                        --------------------------------------------------------------------------------
                        local a = canvas.new{x = 0, y = 0, w = 50, h = 50 }
                        a[1] = {
                          type="image",
                          image = icon,
                          frame = { x = "10%", y = "10%", h = "80%", w = "80%" },
                        }
                        local newImage = a:imageFromCanvas()

                        local encodedIcon = newImage:encodeAsURLString()
                        if encodedIcon then

                            local items = mod.items()

                            if not items[device] then items[device] = {} end
                            if not items[device][unit] then items[device][unit] = {} end
                            if not items[device][unit][app] then items[device][unit][app] = {} end
                            if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end
                            if not items[device][unit][app][bank][button] then items[device][unit][app][bank][button] = {} end

                            items[device][unit][app][bank][button].icon = encodedIcon

                            mod.items(items)

                            updateUI(params)
                        else
                            failed = true
                        end
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
                local items = mod.items()

                if not items[device] then items[device] = {} end
                if not items[device][unit] then items[device][unit] = {} end
                if not items[device][unit][app] then items[device][unit][app] = {} end
                if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end
                if not items[device][unit][app][bank][button] then items[device][unit][app][bank][button] = {} end

                items[device][unit][app][bank][button].icon = nil

                mod.items(items)

                updateUI(params)
            end
        elseif callbackType == "updateIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            local device = params["device"]
            local unit = params["unit"]
            local app = params["application"]
            local bank = params["bank"]
            local button = params["button"]
            local icon = params["icon"]

            local items = mod.items()

            if not items[device] then items[device] = {} end
            if not items[device][unit] then items[device][unit] = {} end
            if not items[device][unit][app] then items[device][unit][app] = {} end
            if not items[device][unit][app][bank] then items[device][unit][app][bank] = {} end
            if not items[device][unit][app][bank][button] then items[device][unit][app][bank][button] = {} end

            items[device][unit][app][bank][button].icon = icon

            mod.items(items)

            updateUI(params)
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
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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
            popup:popupMenu(mouse.getAbsolutePosition(), true)
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Stream Deck Preferences Panel:")
            log.df("id: %s", hs.inspect(id))
            log.df("params: %s", hs.inspect(params))
        end
    end
end

local plugin = {
    id              = "core.streamdeck.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.streamdeck.manager"]         = "sd",
        ["core.action.manager"]             = "actionmanager",
        ["core.application.manager"]        = "appmanager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._appmanager     = deps.appmanager
    mod._sd             = deps.sd
    mod._manager        = deps.manager
    mod._webviewLabel   = deps.manager.getLabel()
    mod._actionmanager  = deps.actionmanager
    mod._env            = env

    mod.items           = deps.sd.items
    mod.enabled         = deps.sd.enabled

    mod.numberOfBanks   = deps.manager.NUMBER_OF_BANKS
    mod.numberOfDevices = deps.manager.NUMBER_OF_DEVICES

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2032,
        id              = "streamdeck",
        label           = i18n("streamdeckPanelLabel"),
        image           = imageFromPath(env:pathToAbsolute("images/streamdeck.icns")),
        tooltip         = i18n("streamdeckPanelTooltip"),
        height          = 880,
    })
        :addHeading(6, i18n("streamDeck"))
        :addCheckbox(7,
            {
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
        :addParagraph(8, html.span {class="tip"} (html(i18n("streamDeckAppTip"), false) ) .. "\n\n")
        :addContent(10, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "streamDeckPanelCallback", streamDeckPanelCallback)

    return mod
end

return plugin
