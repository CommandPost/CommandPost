--- === plugins.core.tourbox.prefs ===
---
--- TourBox Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "prefsTourBox"

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
local imageFromPath             = image.imageFromPath
local infoForBundlePath         = application.infoForBundlePath
local mergeTable                = tools.mergeTable
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local webviewAlert              = dialog.webviewAlert

local mod = {}

--- plugins.core.tourbox.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Application used in the Preferences Panel.
mod.lastApplication = config.prop("tourbox.preferences.lastApplication", "All Applications")

--- plugins.core.tourbox.prefs.lastApplication <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastBank = config.prop("tourbox.preferences.lastBank", "1")

--- plugins.core.tourbox.prefs.lastPage <cp.prop: number>
--- Field
--- Last Page used in the Preferences Panel.
mod.lastPage = config.prop("tourbox.preferences.lastPage", 1)

--- plugins.core.tourbox.prefs.lastControlType <cp.prop: string>
--- Field
--- Last Selected Control Type used in the Preferences Panel.
mod.lastControlType = config.prop("tourbox.preferences.lastControlType", "side")

--- plugins.core.tourbox.prefs.lastImportPath <cp.prop: string>
--- Field
--- Last Import path.
mod.lastImportPath = config.prop("tourbox.preferences.lastImportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.tourbox.prefs.lastExportPath <cp.prop: string>
--- Field
--- Last Export path.
mod.lastExportPath = config.prop("tourbox.preferences.lastExportPath", os.getenv("HOME") .. "/Desktop/")

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

        numberOfBanks               = mod.numberOfBanks,
        i18n                        = i18n,

        lastApplication             = mod.lastApplication(),
        lastBank                    = mod.lastBank(),

        lastControlType             = mod.lastControlType(),
        lastPage                    = mod.lastPage(),

        insertImage                 = insertImage,
    }

    return renderPanel(context)
end

-- setItem(app, bank, controlType, id, valueA, valueB) -> none
-- Function
-- Update the Loupedeck CT layout file.
--
-- Parameters:
--  * app - The application bundle ID as a string
--  * bank - The bank ID as a string
--  * controlType - The control type as a string
--  * valueA - The value of the item as a string
--  * valueB - An optional value
--
-- Returns:
--  * None
local function setItem(app, bank, controlType, valueA, valueB)
    local items = mod.items()

    if type(items[app]) ~= "table" then items[app] = {} end
    if type(items[app][bank]) ~= "table" then items[app][bank] = {} end
    if type(items[app][bank][controlType]) ~= "table" then items[app][bank][controlType] = {} end

    if type(valueB) ~= nil then
        if not items[app][bank][controlType][valueA] then items[app][bank][controlType][valueA] = {} end
        items[app][bank][controlType][valueA] = valueB
    else
        items[app][bank][controlType] = valueA
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
    if not params then
        params = {
            ["application"] = mod.lastApplication(),
            ["bank"] = mod.lastBank(),
            ["controlType"] = mod.lastControlType(),
        }
    end

    local app = params["application"]
    local bank = params["bank"]
    local controlType = params["controlType"]

    local injectScript = mod._manager.injectScript

    mod.lastControlType(controlType)

    local items = mod.items()

    local selectedApp = items[app]

    local ignore = (selectedApp and selectedApp.ignore) or false
    local selectedBank = selectedApp and selectedApp[bank]
    local selectedControlType = selectedBank and selectedBank[controlType]

    local doubleClickPressAction = selectedControlType and selectedControlType.doubleClickPressAction and selectedControlType.doubleClickPressAction.actionTitle or ""
    local doubleClickReleaseAction = selectedControlType and selectedControlType.doubleClickReleaseAction and selectedControlType.doubleClickReleaseAction.actionTitle or ""
    local leftAction = selectedControlType and selectedControlType.leftAction and selectedControlType.leftAction.actionTitle or ""
    local leftDownAction = selectedControlType and selectedControlType.leftDownAction and selectedControlType.leftDownAction.actionTitle or ""
    local leftLeftAction = selectedControlType and selectedControlType.leftLeftAction and selectedControlType.leftLeftAction.actionTitle or ""
    local leftRightAction = selectedControlType and selectedControlType.leftRightAction and selectedControlType.leftRightAction.actionTitle or ""
    local leftShortAction = selectedControlType and selectedControlType.leftShortAction and selectedControlType.leftShortAction.actionTitle or ""
    local leftSideAction = selectedControlType and selectedControlType.leftSideAction and selectedControlType.leftSideAction.actionTitle or ""
    local leftTallAction = selectedControlType and selectedControlType.leftTallAction and selectedControlType.leftTallAction.actionTitle or ""
    local leftTopAction = selectedControlType and selectedControlType.leftTopAction and selectedControlType.leftTopAction.actionTitle or ""
    local leftUpAction = selectedControlType and selectedControlType.leftUpAction and selectedControlType.leftUpAction.actionTitle or ""
    local pressAction = selectedControlType and selectedControlType.pressAction and selectedControlType.pressAction.actionTitle or ""
    local pressActionRepeat = selectedControlType and selectedControlType.pressActionRepeat or false
    local pressSideAction = selectedControlType and selectedControlType.pressSideAction and selectedControlType.pressSideAction.actionTitle or ""
    local pressSideActionRepeat = selectedControlType and selectedControlType.pressSideActionRepeat or false
    local pressTopAction = selectedControlType and selectedControlType.pressTopAction and selectedControlType.pressTopAction.actionTitle or ""
    local releaseAction = selectedControlType and selectedControlType.releaseAction and selectedControlType.releaseAction.actionTitle or ""
    local releaseSideAction = selectedControlType and selectedControlType.releaseSideAction and selectedControlType.releaseSideAction.actionTitle or ""
    local releaseTopAction = selectedControlType and selectedControlType.releaseTopAction and selectedControlType.releaseTopAction.actionTitle or ""
    local rightAction = selectedControlType and selectedControlType.rightAction and selectedControlType.rightAction.actionTitle or ""
    local rightDownAction = selectedControlType and selectedControlType.rightDownAction and selectedControlType.rightDownAction.actionTitle or ""
    local rightLeftAction = selectedControlType and selectedControlType.rightLeftAction and selectedControlType.rightLeftAction.actionTitle or ""
    local rightRightAction = selectedControlType and selectedControlType.rightRightAction and selectedControlType.rightRightAction.actionTitle or ""
    local rightShortAction = selectedControlType and selectedControlType.rightShortAction and selectedControlType.rightShortAction.actionTitle or ""
    local rightSideAction = selectedControlType and selectedControlType.rightSideAction and selectedControlType.rightSideAction.actionTitle or ""
    local rightTallAction = selectedControlType and selectedControlType.rightTallAction and selectedControlType.rightTallAction.actionTitle or ""
    local rightTopAction = selectedControlType and selectedControlType.rightTopAction and selectedControlType.rightTopAction.actionTitle or ""
    local rightUpAction = selectedControlType and selectedControlType.rightUpAction and selectedControlType.rightUpAction.actionTitle or ""

    local doubleClickPressActionRepeat = selectedControlType and selectedControlType.doubleClickPressActionRepeat or false

    local bankLabel = selectedBank and selectedBank.bankLabel or ""

    injectScript([[
        changeValueByID('bankLabel', `]] .. escapeTilda(bankLabel) .. [[`);
        changeCheckedByID('doubleClickPressActionRepeat', ]] .. tostring(doubleClickPressActionRepeat) .. [[);
        changeCheckedByID('ignore', ]] .. tostring(ignore) .. [[);
        changeCheckedByID('pressActionRepeat', ]] .. tostring(pressActionRepeat) .. [[);
        changeCheckedByID('pressSideActionRepeat', ]] .. tostring(pressSideActionRepeat) .. [[);
        changeValueByID('doubleClickPressAction', `]] .. escapeTilda(doubleClickPressAction) .. [[`);
        changeValueByID('doubleClickReleaseAction', `]] .. escapeTilda(doubleClickReleaseAction) .. [[`);
        changeValueByID('leftAction', `]] .. escapeTilda(leftAction) .. [[`);
        changeValueByID('leftDownAction', `]] .. escapeTilda(leftDownAction) .. [[`);
        changeValueByID('leftLeftAction', `]] .. escapeTilda(leftLeftAction) .. [[`);
        changeValueByID('leftRightAction', `]] .. escapeTilda(leftRightAction) .. [[`);
        changeValueByID('leftShortAction', `]] .. escapeTilda(leftShortAction) .. [[`);
        changeValueByID('leftSideAction', `]] .. escapeTilda(leftSideAction) .. [[`);
        changeValueByID('leftTallAction', `]] .. escapeTilda(leftTallAction) .. [[`);
        changeValueByID('leftTopAction', `]] .. escapeTilda(leftTopAction) .. [[`);
        changeValueByID('leftUpAction', `]] .. escapeTilda(leftUpAction) .. [[`);
        changeValueByID('pressAction', `]] .. escapeTilda(pressAction) .. [[`);
        changeValueByID('pressSideAction', `]] .. escapeTilda(pressSideAction) .. [[`);
        changeValueByID('pressTopAction', `]] .. escapeTilda(pressTopAction) .. [[`);
        changeValueByID('releaseAction', `]] .. escapeTilda(releaseAction) .. [[`);
        changeValueByID('releaseSideAction', `]] .. escapeTilda(releaseSideAction) .. [[`);
        changeValueByID('releaseTopAction', `]] .. escapeTilda(releaseTopAction) .. [[`);
        changeValueByID('rightAction', `]] .. escapeTilda(rightAction) .. [[`);
        changeValueByID('rightDownAction', `]] .. escapeTilda(rightDownAction) .. [[`);
        changeValueByID('rightLeftAction', `]] .. escapeTilda(rightLeftAction) .. [[`);
        changeValueByID('rightRightAction', `]] .. escapeTilda(rightRightAction) .. [[`);
        changeValueByID('rightShortAction', `]] .. escapeTilda(rightShortAction) .. [[`);
        changeValueByID('rightSideAction', `]] .. escapeTilda(rightSideAction) .. [[`);
        changeValueByID('rightTallAction', `]] .. escapeTilda(rightTallAction) .. [[`);
        changeValueByID('rightTopAction', `]] .. escapeTilda(rightTopAction) .. [[`);
        changeValueByID('rightUpAction', `]] .. escapeTilda(rightUpAction) .. [[`);
        updateIgnoreVisibility();
    ]])
end

-- tourBoxPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function tourBoxPanelCallback(id, params)
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
                local legacyGroupIDs = {}
                local registeredApps = mod._appmanager.getApplications()
                for bundleID, v in pairs(registeredApps) do
                    if v.displayName then
                        apps[bundleID] = v.displayName
                    end
                    legacyGroupIDs[bundleID] = v.legacyGroupID or bundleID
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
                    mod.activator[groupID] = mod._actionmanager.getActivator("tourBoxPreferences" .. groupID)

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
                local app = params["application"]
                local bank = params["bank"]
                local controlType = params["controlType"]
                local buttonType = params["buttonType"]

                local result = {
                    ["actionTitle"] = actionTitle,
                    ["handlerID"] = handlerID,
                    ["action"] = action,
                }

                setItem(app, bank, controlType, buttonType, result)

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
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local buttonType = params["buttonType"]

            setItem(app, bank, controlType, buttonType, {})

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            updateUI(params)
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

                        items[bundleID] = {
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
                mod.lastApplication(app)
                mod.lastBank(bank)

                --------------------------------------------------------------------------------
                -- Change the bank:
                --------------------------------------------------------------------------------
                local activeBanks = mod._tourboxManager.activeBanks()

                -- Remove the '_LeftFn' and '_RightFn'
                local newBank = bank
                if string.sub(bank, -7) == "_LeftFn" then
                    newBank = string.sub(bank, 1, -8)
                end
                if string.sub(bank, -8) == "_RightFn" then
                    newBank = string.sub(bank, 1, -9)
                end

                activeBanks[app] = newBank
                mod._tourboxManager.activeBanks(activeBanks)

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                updateUI(params)
            end
        elseif callbackType == "updateUI" then
            updateUI(params)
        elseif callbackType == "updatePage" then
            --------------------------------------------------------------------------------
            -- Update Page:
            --------------------------------------------------------------------------------
            local page = params["value"]
            mod.lastPage(page)
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

                local path = chooseFileOrFolder(i18n("pleaseSelectAFileToImport") .. ":", lastImportPath, true, false, false, {"cpLoupedeckCT"})
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
            local app = params["application"]
            local bank = params["bank"]

            local exportSettings = function(what)
                local items = mod.items()
                local data = {}

                local filename = ""

                if what == "Everything" then
                    data = copy(items)
                    filename = "Everything"
                elseif what == "Application" then
                    data[app] = copy(items[app])
                    filename = app
                elseif what == "Bank" then
                    data[app] = {}
                    data[app][bank] = copy(items[app][bank])
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
                    json.write(path["1"] .. "/" .. filename .. " - " .. os.date("%Y%m%d %H%M") .. ".cpLoupedeckCT", data)
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
        elseif callbackType == "copyControlToAllBanks" then
            --------------------------------------------------------------------------------
            -- Copy Control to All Banks:
            --------------------------------------------------------------------------------
            local items = mod.items()

            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]

            local data = items[app] and items[app][bank] and items[app][bank][controlType]

            local suffix = ""
            if bank:sub(-7) == "_LeftFn" then
                suffix = "_LeftFn"
            elseif bank:sub(-8) == "_RightFn" then
                suffix = "_RightFn"
            end

            if data then
                for b=1, mod.numberOfBanks do
                    b = tostring(b) .. suffix

                    if not items[app] then items[app] = {} end
                    if not items[app][b] then items[app][b] = {} end
                    if not items[app][b][controlType] then items[app][b][controlType] = {} end
                    if type(data) == "table" then
                        for i, v in pairs(data) do
                            items[app][b][controlType][i] = v
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

            local items = mod.items()

            if items[app] and items[app][bank] and items[app][bank][controlType] then
                items[app][bank][controlType] = nil
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
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    mod._tourboxManager.reset()
                    mod._manager.refresh()
                end
            end, i18n("tourBoxResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetApplication" then
            --------------------------------------------------------------------------------
            -- Reset Application:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local items = mod.items()
                    local app = mod.lastApplication()

                    local defaultLayout = mod._tourboxManager.defaultLayout
                    items[app] = defaultLayout and defaultLayout[app] or {}

                    mod.items(items)
                    mod._manager.refresh()
                end
            end, i18n("tourBoxResetApplicationConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetBank" then
            --------------------------------------------------------------------------------
            -- Reset Bank:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local items = mod.items()
                    local app = mod.lastApplication()
                    local bank = mod.lastBank()

                    local defaultLayout = mod._tourboxManager.defaultLayout

                    if items[app] and items[app][bank] then
                        items[app][bank] = defaultLayout and defaultLayout[app] and defaultLayout[app][bank] or {}
                    end
                    mod.items(items)
                    mod._manager.refresh()
                end
            end, i18n("tourBoxResetBankConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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
        elseif callbackType == "changeIgnore" then
            local app = params["application"]
            local ignore = params["ignore"]

            local items = mod.items()

            if not items[app] then items[app] = {} end
            items[app]["ignore"] = ignore

            mod.items(items)
        elseif callbackType == "repeatCheckbox" then
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local actionType = params["actionType"]
            local value = params["value"] or false
            setItem(app, bank, controlType, actionType .. "Repeat", value)
        elseif callbackType == "copyBank" then
            --------------------------------------------------------------------------------
            -- Copy Bank:
            --------------------------------------------------------------------------------
            local numberOfBanks = mod.numberOfBanks

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
                title = string.upper(i18n("copyActiveBankTo")) .. ":",
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
            log.df("Unknown Callback in TourBox Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "core.tourbox.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.action.manager"]             = "actionmanager",
        ["core.tourbox.manager"]            = "tourboxManager",
        ["core.application.manager"]        = "appmanager",
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

    mod._tourboxManager                     = deps.tourboxManager
    mod.items                               = deps.tourboxManager.items
    mod.enabled                             = deps.tourboxManager.enabled
    mod.automaticallySwitchApplications     = deps.tourboxManager.automaticallySwitchApplications
    mod.numberOfBanks                       = deps.manager.NUMBER_OF_BANKS

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2033.1,
        id              = "tourbox",
        label           = i18n("tourBox"),
        image           = imageFromPath(env:pathToAbsolute("/images/TourBox.icns")),
        tooltip         = i18n("tourBox"),
        height          = 1040,
    })
        :addHeading(6, i18n("tourBox"))
        :addCheckbox(7.1,
            {
                label       = i18n("enableTourBoxSupport"),
                checked     = mod.enabled,
                onchange    = function(_, params)
                    mod.enabled(params.checked)
                end,
            }
        )
        :addCheckbox(10,
            {
                label       = i18n("automaticallySwitchApplications"),
                checked     = mod.automaticallySwitchApplications,
                onchange    = function(_, params)
                    mod.automaticallySwitchApplications(params.checked)
                end,
            }
        )
        :addParagraph(12, html.span {class="tip"} (html(i18n("tourBoxRequirementsTip"), false) ) .. "\n\n")
        :addParagraph(13, html.span {class="tip"} (html(i18n("tourBoxAppTip"), false) ) .. "\n\n")
        :addContent(14, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "tourBoxPanelCallback", tourBoxPanelCallback)

    return mod
end

return plugin
