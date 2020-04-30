--- === plugins.core.loupedeckplus.prefs ===
---
--- Loupedeck+ Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "prefsLoupedeck"

local application               = require "hs.application"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"

local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local applicationsForBundleID   = application.applicationsForBundleID
local chooseFileOrFolder        = dialog.chooseFileOrFolder
local copy                      = fnutils.copy
local doesDirectoryExist        = tools.doesDirectoryExist
local escapeTilda               = tools.escapeTilda
local infoForBundlePath         = application.infoForBundlePath
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local mergeTable                = tools.mergeTable
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- LD_BUNDLE_ID -> string
-- Constant
-- The official Loupedeck App bundle identifier.
local LD_BUNDLE_ID = "com.loupedeck.Loupedeck2"

--- plugins.core.loupedeckplus.prefs.lastApplication <cp.prop: string>
--- Field
--- Last application used in the Preferences Drop Down.
mod.lastApplication = config.prop("loupedeckplus.preferences.lastApplication", "All Applications")

--- plugins.core.loupedeckplus.prefs.lastBank <cp.prop: string>
--- Field
--- Last bank used in the Preferences Drop Down.
mod.lastBank = config.prop("loupedeckplus.preferences.lastBank", "1")

--- plugins.core.loupedeckplus.prefs.lastNote <cp.prop: string>
--- Field
--- Last note used in the Preferences panel.
mod.lastNote = config.prop("loupedeckplus.preferences.lastNote", "95")

--- plugins.core.loupedeckplus.prefs.lastIsButton <cp.prop: boolean>
--- Field
--- Whether or not the last selected item in the Preferences was a button.
mod.lastIsButton = config.prop("loupedeckplus.preferences.lastIsButton", true)

--- plugins.core.loupedeckplus.prefs.lastLabel <cp.prop: string>
--- Field
--- Last label used in the Preferences panel.
mod.lastLabel = config.prop("loupedeckplus.preferences.lastLabel", "Undo")

--- plugins.core.loupedeckplus.prefs.lastExportPath <cp.prop: string>
--- Field
--- Last Export path.
mod.lastExportPath = config.prop("loupedeckplus.preferences.lastExportPath", os.getenv("HOME") .. "/Desktop/")

--- plugins.core.loupedeckplus.prefs.lastImportPath <cp.prop: string>
--- Field
--- Last Import path.
mod.lastImportPath = config.prop("loupedeckplus.preferences.lastImportPath", os.getenv("HOME") .. "/Desktop/")

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

        lastApplication             = mod.lastApplication(),
        lastBank                    = mod.lastBank(),

        i18n                        = i18n,

        lastNote                    = mod.lastNote(),
        lastIsButton                = mod.lastIsButton(),
        lastLabel                   = mod.lastLabel(),
    }

    return renderPanel(context)
end

-- updateUI() -> none
-- Function
-- Update the UI
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updateUI()
    local injectScript = mod._manager.injectScript

    local app = mod.lastApplication()
    local bank = mod.lastBank()
    local note = mod.lastNote()

    local items = mod.items()

    local appData = items[app]
    local bankData = appData and appData[bank]

    local script = ""

    --------------------------------------------------------------------------------
    -- Update Bank Label:
    --------------------------------------------------------------------------------
    local bankLabel = bankData and bankData.bankLabel or ""
    script = script .. [[
        document.getElementById("bankLabel").value = "]] .. bankLabel .. [[";
    ]]

    --------------------------------------------------------------------------------
    -- Update Ignore Checkbox:
    --------------------------------------------------------------------------------
    local ignore = appData and appData.ignore or false
    script = script .. [[
        document.getElementById("ignore").checked = ]] .. tostring(ignore) .. [[;
    ]]
    if app == "All Applications" then
        script = script .. [[
            document.getElementById("ignoreApp").style.display = "none";
        ]]
    else
        script = script .. [[
            document.getElementById("ignoreApp").style.display = "block";
        ]]
    end

    --------------------------------------------------------------------------------
    -- Update Action Labels:
    --------------------------------------------------------------------------------
    local pressValue = i18n("none")
    local leftValue = i18n("none")
    local rightValue = i18n("none")

    if bankData then
        if bankData[note .. "Press"] and bankData[note .. "Press"]["actionTitle"] then
            pressValue = bankData[note .. "Press"]["actionTitle"]
        end
        if bankData[note .. "Left"] and bankData[note .. "Left"]["actionTitle"] then
            leftValue = bankData[note .. "Left"]["actionTitle"]
        end
        if bankData[note .. "Right"] and bankData[note .. "Right"]["actionTitle"] then
            rightValue = bankData[note .. "Right"]["actionTitle"]
        end
    end
    script = script .. [[
        changeValueByID('press_action', `]] .. escapeTilda(pressValue) .. [[`);
        changeValueByID('left_action', `]] .. escapeTilda(leftValue) .. [[`);
        changeValueByID('right_action', `]] .. escapeTilda(rightValue) .. [[`);
    ]]

    --------------------------------------------------------------------------------
    -- Inject Script:
    --------------------------------------------------------------------------------
    injectScript(script)
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
                    mod.activator[groupID] = mod._actionmanager.getActivator("loupedeckCTPreferences" .. groupID)

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
                            if handlerTable[2] ~= "widgets" and v ~= "global_menuactions" then
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

                local items = mod.items()

                local button = params["buttonID"]
                local bundleID = params["application"]
                local bankID = params["bank"]

                if not items[bundleID] then items[bundleID] = {} end
                if not items[bundleID][bankID] then items[bundleID][bankID] = {} end
                if not items[bundleID][bankID][button] then items[bundleID][bankID][button] = {} end

                items[bundleID][bankID][button]["actionTitle"] = actionTitle
                items[bundleID][bankID][button]["handlerID"] = handlerID
                items[bundleID][bankID][button]["action"] = action

                mod.items(items)

                updateUI()
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
            local button = params["buttonID"]

            local items = mod.items()

            button = tostring(button)

            if not items[app] then items[app] = {} end
            if not items[app][bank] then items[app][bank] = {} end
            if not items[app][bank][button] then items[app][bank][button] = {} end

            items[app][bank][button]["actionTitle"] = nil
            items[app][bank][button]["handlerID"] = nil
            items[app][bank][button]["action"] = nil

            mod.items(items)

            updateUI()
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
                local activeBanks = mod._midi.activeLoupedeckBanks()

                -- Remove the 'fn':
                if string.sub(bank, -2) == "fn" then
                    bank = string.sub(bank, 1, -3)
                end
                activeBanks[app] = bank
                mod._midi.activeLoupedeckBanks(activeBanks)

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                updateUI()
            end
        elseif callbackType == "changeControl" then
            mod.lastNote(params["note"])
            mod.lastIsButton(params["isButton"])
            mod.lastLabel(params["label"])

            updateUI()
        elseif callbackType == "updateUI" then
            updateUI()
        elseif callbackType == "updateBankLabel" then
            local app = params["application"]
            local bank = params["bank"]
            local bankLabel = params["bankLabel"]

            local items = mod.items()

            if not items[app] then items[app] = {} end
            if not items[app][bank] then items[app][bank] = {} end

            items[app][bank]["bankLabel"] = bankLabel

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

                local path = chooseFileOrFolder(i18n("pleaseSelectAFileToImport") .. ":", lastImportPath, true, false, false, {"cpLoupedeckPlus"})
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
                    json.write(path["1"] .. "/" .. filename .. " - " .. os.date("%Y%m%d %H%M") .. ".cpLoupedeckPlus", data)
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
        elseif callbackType == "changeIgnore" then
            --------------------------------------------------------------------------------
            -- Change Ignore:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local ignore = params["ignore"]

            local items = mod.items()

            if not items[app] then items[app] = {} end
            items[app]["ignore"] = ignore

            mod.items(items)
        elseif callbackType == "resetEverything" then
            --------------------------------------------------------------------------------
            -- Reset Everything:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local default = copy(mod._midi.defaultLoupedeckLayout)
                    mod.items(default)

                    updateUI()
                end
            end, i18n("loupedeckResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetApplication" then
            --------------------------------------------------------------------------------
            -- Reset Application:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local app = params["application"]

                    local items = mod.items()

                    local default = mod._midi.defaultLoupedeckLayout[app] or {}
                    items[app] = copy(default)

                    mod.items(items)

                    updateUI()
                end
            end, i18n("loupedeckResetGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetBank" then
            --------------------------------------------------------------------------------
            -- Reset Bank:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then

                    local app = params["application"]
                    local bank = params["bank"]

                    local items = mod.items()

                    if not items[app] then items[app] = {} end
                    if not items[app][bank] then items[app][bank] = {} end

                    local default = mod._midi.defaultLoupedeckLayout[app] and mod._midi.defaultLoupedeckLayout[app][bank] or {}
                    items[app][bank] = copy(default)

                    mod.items(items)

                    updateUI()
                end

            end, i18n("loupedeckResetSubGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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

local plugin = {
    id              = "core.loupedeckplus.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.midi.manager"]               = "midi",
        ["core.action.manager"]             = "actionmanager",
        ["core.application.manager"]        = "appmanager",
        ["core.commands.global"]            = "global",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._appmanager     = deps.appmanager
    mod._midi           = deps.midi
    mod._manager        = deps.manager
    mod._actionmanager  = deps.actionmanager
    mod._env            = env

    mod.items           = mod._midi.loupedeckItems
    mod.enabled         = mod._midi.enabledLoupedeck

    mod.numberOfBanks   = deps.manager.NUMBER_OF_BANKS

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("enableLoupedeckPlus")
        :whenActivated(function()
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :titled(i18n("enableLoupedeckPlusSupport"))

    global
        :add("disableLoupedeckPlus")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :titled(i18n("disableLoupedeckPlusSupport"))

    global
        :add("disableLoupedeckPlusandLaunchLoupedeckApp")
        :whenActivated(function()
            mod.enabled(false)
            launchOrFocusByBundleID(LD_BUNDLE_ID)
        end)
        :groupedBy("commandPost")
        :titled(i18n("disableLoupedeckPlusSupportAndLaunchLoupedeckApp"))

    global
        :add("enableLoupedeckPlusandKillLoupedeckApp")
        :whenActivated(function()
            local apps = applicationsForBundleID(LD_BUNDLE_ID)
            if apps then
                for _, app in pairs(apps) do
                    app:kill9()
                end
            end
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :titled(i18n("enableLoupedeckPlusSupportQuitLoupedeckApp"))

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2033,
        id              = "loupedeck",
        label           = i18n("loupedeckPlus"),
        image           = image.imageFromPath(env:pathToAbsolute("/images/loupedeck.icns")),
        tooltip         = i18n("loupedeckPlus"),
        height          = 805,
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

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "loupedeckPanelCallback", loupedeckPanelCallback)

    return mod
end

return plugin
