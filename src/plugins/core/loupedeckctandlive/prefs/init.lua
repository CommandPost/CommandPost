--- === plugins.core.loupedeckctandlive.prefs ===
---
--- Preferences Panels for Loupedeck CT, Loupedeck Live, Loupedeck Live-S and Razer Stream Controller.

local require                   = require

local log                       = require "hs.logger".new "prefsLoupedeckCT"

local application               = require "hs.application"
local canvas                    = require "hs.canvas"
local chooser                   = require "hs.chooser"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local loupedeck                 = require "hs.loupedeck"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"
local styledtext                = require "hs.styledtext"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local cpDialog                  = require "cp.dialog"
local html                      = require "cp.web.html"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local copy                      = fnutils.copy
local delayed                   = timer.delayed
local displayChooseFromList     = cpDialog.displayChooseFromList
local doesDirectoryExist        = tools.doesDirectoryExist
local escapeTilda               = tools.escapeTilda
local execute                   = os.execute
local getFilenameFromPath       = tools.getFilenameFromPath
local imageFromAppBundle        = image.imageFromAppBundle
local imageFromPath             = image.imageFromPath
local imageFromURL              = image.imageFromURL
local infoForBundlePath         = application.infoForBundlePath
local isImage                   = tools.isImage
local mergeTable                = tools.mergeTable
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local split                     = tools.split
local tableContains             = tools.tableContains
local tableMatch                = tools.tableMatch
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

-- ICON_LABEL_UPDATE_DELAY -> string
-- Constant
-- How long to delay updating the icon label.
local ICON_LABEL_UPDATE_DELAY = 0.5

-- KEY_CREATOR_URL -> string
-- Constant
-- URL to Key Creator Website
local KEY_CREATOR_URL = "https://www.elgato.com/en/gaming/keycreator"

-- BUY_MORE_ICONS_URL -> string
-- Constant
-- URL to SideshowFX Website
local BUY_MORE_ICONS_URL = "https://www.sideshowfx.net/buy?category=Loupedeck"

-- SNIPPET_HELP_URL -> string
-- Constant
-- URL to Snippet Support Site
local SNIPPET_HELP_URL = "https://commandpost.io/scripting/snippets-for-icons/"

-- SNIPPET_LED_HELP_URL -> string
-- Constant
-- URL to Snippet Support Site
local SNIPPET_LED_HELP_URL = "https://commandpost.io/scripting/snippets-for-led-colors/"

-- delayedFn -> hs.timer
-- Variable
-- A delayed timer used for the Icon Label updater.
local delayedFn

--- plugins.core.loupedeckctandlive.prefs.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp", "app"}

--- plugins.core.loupedeckctandlive.prefs.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = config.assetsPath .. "/icons/"

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

--- plugins.core.loupedeckctandlive.prefs.new() -> Loupedeck
--- Constructor
--- Creates a new Loupedeck Preferences panel.
---
--- Parameters:
---  * deviceType - The device type defined in `hs.loupedeck.deviceTypes`
---
--- Returns:
---  * None
---
--- Notes:
---  * The deviceType should be either `hs.loupedeck.deviceTypes.LIVE`
---    or `hs.loupedeck.deviceTypes.CT`.
function mod.new(deviceType)
    local o = {}

    if deviceType == loupedeck.deviceTypes.CT then
        --------------------------------------------------------------------------------
        -- Loupedeck CT:
        --------------------------------------------------------------------------------
        o.id                = "loupedeckct"
        o.configFolder      = "Loupedeck CT"
        o.device            = mod._deviceManager.devices.CT
        o.priority          = 2033.01
        o.label             = "Loupedeck CT"
        o.commandID         = "LoupedeckCT"
        o.resetCommandID    = "loupedeckCT"
        o.height            = 1150
        o.preferencesGroup  = "loupedeck"
    elseif deviceType == loupedeck.deviceTypes.LIVE then
        --------------------------------------------------------------------------------
        -- Loupedeck Live:
        --------------------------------------------------------------------------------
        o.id                = "loupedecklive"
        o.configFolder      = "Loupedeck Live"
        o.device            = mod._deviceManager.devices.LIVE
        o.priority          = 2033.02
        o.label             = "Loupedeck Live"
        o.commandID         = "LoupedeckLive"
        o.resetCommandID    = "loupedeckLive"
        o.height            = 1140
        o.preferencesGroup  = "loupedeck"
    elseif deviceType == loupedeck.deviceTypes.LIVE_S then
        --------------------------------------------------------------------------------
        -- Loupedeck Live:
        --------------------------------------------------------------------------------
        o.id                = "loupedecklives"
        o.configFolder      = "Loupedeck Live-S"
        o.device            = mod._deviceManager.devices.LIVE_S
        o.priority          = 2033.02
        o.label             = "Loupedeck Live-S"
        o.commandID         = "LoupedeckLiveS"
        o.resetCommandID    = "loupedeckLiveS"
        o.height            = 1140
        o.preferencesGroup  = "loupedeck"
    elseif deviceType == loupedeck.deviceTypes.RAZER_STREAM_CONTROLLER then
        --------------------------------------------------------------------------------
        -- Razer Stream Controller:
        --------------------------------------------------------------------------------
        o.id                = "razerstreamcontroller"
        o.configFolder      = "Razer Stream Controller"
        o.device            = mod._deviceManager.devices.RAZER_STREAM_CONTROLLER
        o.priority          = 2032.34
        o.label             = "Razer Stream Controller"
        o.commandID         = "RazerStreamController"
        o.resetCommandID    = "razerStreamController"
        o.height            = 1140
        o.preferencesGroup  = "razer"
    else
        log.ef("Invalid Loupedeck Device Type: %s", deviceType)
        return
    end

    --------------------------------------------------------------------------------
    -- Number of Touch Buttons:
    --------------------------------------------------------------------------------
    if deviceType == loupedeck.deviceTypes.LIVE_S then
        o.numberOfTouchButtons = 15
    else
        o.numberOfTouchButtons = 12
    end

    --- plugins.core.loupedeckctandlive.prefs.lastDevice <cp.prop: string>
    --- Field
    --- The last selected device as a string.
    o.lastDevice = config.prop(o.id .. ".preferences.lastDevice", "1")

    --- plugins.core.loupedeckctandlive.prefs.lastIconPath <cp.prop: string>
    --- Field
    --- Last icon path.
    o.lastIconPath = config.prop(o.id .. ".preferences.lastIconPath", mod.defaultIconPath)

    --- plugins.core.loupedeckctandlive.prefs.iconHistory <cp.prop: table>
    --- Field
    --- Icon History
    o.iconHistory = json.prop(config.cachePath, o.configFolder, "Icon History.cpCache", {})

    --- plugins.core.loupedeckctandlive.prefs.pasteboard <cp.prop: table>
    --- Field
    --- Pasteboard
    o.pasteboard = json.prop(config.cachePath, o.configFolder, "Pasteboard.cpCache", {})

    --- plugins.core.loupedeckctandlive.prefs.lastExportPath <cp.prop: string>
    --- Field
    --- Last Export path.
    o.lastExportPath = config.prop(o.id .. ".preferences.lastExportPath", os.getenv("HOME") .. "/Desktop/")

    --- plugins.core.loupedeckctandlive.prefs.lastImportPath <cp.prop: string>
    --- Field
    --- Last Import path.
    o.lastImportPath = config.prop(o.id .. ".preferences.lastImportPath", os.getenv("HOME") .. "/Desktop/")

    --- plugins.core.loupedeckctandlive.prefs.lastApplication <cp.prop: string>
    --- Field
    --- Last Application used in the Preferences Panel.
    o.lastApplication = config.prop(o.id .. ".preferences.lastApplication", "All Applications"):watch(function(value)
        mod._deviceManager.lastApplication(value)
    end)

    --- plugins.core.loupedeckctandlive.prefs.lastBank <cp.prop: string>
    --- Field
    --- Last Bank used in the Preferences Panel.
    o.lastBank = config.prop(o.id .. ".preferences.lastBank", "1"):watch(function(value)
        mod._deviceManager.lastBank(value)
    end)

    --- plugins.core.loupedeckctandlive.prefs.lastSelectedControl <cp.prop: string>
    --- Field
    --- Last Selected Control used in the Preferences Panel.
    o.lastSelectedControl = config.prop(o.id .. ".preferences.lastSelectedControl", "1")

    --- plugins.core.loupedeckctandlive.prefs.lastID <cp.prop: string>
    --- Field
    --- Last Selected Control ID used in the Preferences Panel.
    o.lastID = config.prop(o.id .. ".preferences.lastID", "7")

    --- plugins.core.loupedeckctandlive.prefs.resizeImagesOnImport <cp.prop: string>
    --- Field
    --- Resize Icons on Import Preference.
    o.resizeImagesOnImport = config.prop(o.id .. ".preferences.resizeImagesOnImport", "100%")

    --- plugins.core.loupedeckctandlive.prefs.backgroundColour <cp.prop: string>
    --- Field
    --- Background Colour.
    o.backgroundColour = config.prop(o.id .. ".preferences.backgroundColour", "#000000")

    --- plugins.core.loupedeckctandlive.prefs.lastControlType <cp.prop: string>
    --- Field
    --- Last Selected Control Type used in the Preferences Panel.
    o.lastControlType = config.prop(o.id .. ".preferences.lastControlType", "ledButton")

    --- plugins.core.loupedeckctandlive.prefs.automaticallyApplyIconFromAction <cp.prop: boolean>
    --- Field
    --- Automatically Apply Icon from Action
    o.automaticallyApplyIconFromAction = config.prop(o.id .. ".preferences.automaticallyApplyIconFromAction", true)

    o.items                               = o.device.items
    o.enabled                             = o.device.enabled
    o.loadSettingsFromDevice              = o.device.loadSettingsFromDevice
    o.enableFlashDrive                    = o.device.enableFlashDrive
    o.automaticallySwitchApplications     = o.device.automaticallySwitchApplications
    o.screensBacklightLevel               = o.device.screensBacklightLevel
    o.snippetsRefreshFrequency            = o.device.snippetsRefreshFrequency
    o.getScreenSizeFromControlType        = o.device.getScreenSizeFromControlType

    --------------------------------------------------------------------------------
    -- Watch for Loupedeck CT Unit 1 connections and disconnects:
    --------------------------------------------------------------------------------
    o.device.connected[1]:watch(function(connected)
        if o.loadSettingsFromDevice() and not connected then
            mod._manager.injectScript([[
                if (document.getElementById("yesLoupedeck")) {
                    document.getElementById("yesLoupedeck").style.display = "none";
                    document.getElementById("noLoupedeck").style.display = "block";
                }
            ]])
        else
            mod._manager.injectScript([[
                if (document.getElementById("yesLoupedeck")) {
                    document.getElementById("yesLoupedeck").style.display = "block";
                    document.getElementById("noLoupedeck").style.display = "none";
                }
            ]])
        end
    end)

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    o.panel             =  mod._manager.addPanel({
        group           = o.preferencesGroup,
        priority        = o.priority,
        id              = o.id,
        label           = o.label,
        image           = imageFromPath(mod._env:pathToAbsolute("/images/loupedeck.icns")),
        tooltip         = o.label,
        height          = o.height,
    })

        :addHeading(1, o.label)

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

        :addCheckbox(7.1,
            {
                label       = i18n("enable" .. o.commandID .. "Support"),
                checked     = o.enabled,
                id          = "enable" .. o.commandID .. "Support",
                onchange    = function(_, params)
                    if mod._deviceManager.loupedeckPlugin.enabled() then
                        mod._manager.injectScript([[changeCheckedByID("enable]] .. o.commandID .. [[Support", false)]])
                        webviewAlert(mod._manager.getWebview(), function() end, i18n("loupedeckPluginIsActive"), i18n("loupedeckPluginIsActiveExplanation"), i18n("ok"))
                    else
                        o.enabled(params.checked)
                    end
                end,
            }
        )

        :addCheckbox(7.2,
            {
                label       = i18n("automaticallySwitchApplications"),
                checked     = o.automaticallySwitchApplications,
                onchange    = function(_, params)
                    o.automaticallySwitchApplications(params.checked)
                end,
            }
        )

        :addCheckbox(7.3,
            {
                label       = i18n("automaticallyApplyIconFromAction"),
                checked     = o.automaticallyApplyIconFromAction,
                onchange    = function(_, params)
                    o.automaticallyApplyIconFromAction(params.checked)
                end,
            }
        )

    if deviceType == loupedeck.deviceTypes.CT then
        o.panel
            :addCheckbox(8,
                {
                    label       = i18n("enableFlashDrive"),
                    checked     = o.enableFlashDrive,
                    onchange    = function(_, params)
                        if params.checked then
                            webviewAlert(mod._manager.getWebview(), function() end, i18n("pleaseDisconnectAndReconnectYour" .. o.commandID), i18n("toEnableTheFlashDriveOn" .. o.commandID), i18n("ok"))
                        end
                        o.enableFlashDrive(params.checked)
                    end,
                }
            )

            :addCheckbox(9,
                {
                    label       = i18n("storeSettingsOnFlashDrive"),
                    checked     = o.loadSettingsFromDevice,
                    id          = "storeSettingsOnFlashDrive",
                    onchange    = function(_, params)
                        local manager = mod._manager
                        if params.checked then
                            webviewAlert(manager.getWebview(), function(result)
                                if result == "OK" then
                                    o.loadSettingsFromDevice(params.checked)
                                    mod._manager.refresh()
                                    o.device:refresh(tonumber(o.lastDevice()))
                                else
                                    manager.injectScript("changeCheckedByID('storeSettingsOnFlashDrive', false);")
                                end
                            end, i18n("areYouSureYouWantToStoreYourSettingsOnThe" .. o.commandID .. "FlashDrive"), i18n("areYouSureYouWantToStoreYourSettingsOnThe" .. o.commandID .. "FlashDriveDescription"), i18n("ok"), i18n("cancel"), "warning")
                        else
                            o.loadSettingsFromDevice(params.checked)
                            mod._manager.refresh()
                            o.device:refresh(tonumber(o.lastDevice()))
                        end
                    end,
                }
            )
    end

    o.panel
        :addCheckbox(9.1,
            {
                label       = i18n("previewSelectedApplicationAndBankOnHardware"),
                checked     = mod._deviceManager.previewSelectedApplicationAndBankOnHardware,
                onchange    = function(_, params)
                    --------------------------------------------------------------------------------
                    -- Update preferences:
                    --------------------------------------------------------------------------------
                    mod._deviceManager.previewSelectedApplicationAndBankOnHardware(params.checked)

                    --------------------------------------------------------------------------------
                    -- Update last application & bank:
                    --------------------------------------------------------------------------------
                    local lastApplication = o.lastApplication()
                    local lastBank = o.lastBank()

                    mod._deviceManager.lastApplication(lastApplication)
                    mod._deviceManager.lastBank(lastBank)

                    --------------------------------------------------------------------------------
                    -- Refresh all devices:
                    --------------------------------------------------------------------------------
                    for _, device in pairs(mod._deviceManager.devices) do
                        for deviceNumber=1, mod._deviceManager.NUMBER_OF_DEVICES do
                            device:clearCache(deviceNumber)
                            device:refresh(deviceNumber)
                        end
                    end
                end,
            }
        )

    o.panel
        :addContent(11, [[
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

        :addSelect(12,
            {
                label       =   i18n("snippetsRefreshFrequency"),
                value       =   o.snippetsRefreshFrequency,
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
                                    o.snippetsRefreshFrequency(params.value)
                                    if o.device.refreshTimer then
                                        o.device.refreshTimer:stop()
                                        o.device.refreshTimer = nil
                                        o.device:refresh(tonumber(o.lastDevice()))
                                    end
                                end,
            }
        )

        :addSelect(12.1,
            {
                label       =   i18n("screensBacklightLevel"),
                value       =   o.screensBacklightLevel,
                class       =   "screensBacklightLevel restrictRightTopSectionSize",
                options     =   function()
                                    local options = {}
                                    for i=1, 10 do
                                        table.insert(options, {
                                            value = tostring(i),
                                            label = tostring(i)
                                        })
                                    end
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    o.screensBacklightLevel(params.value)
                                    o.device:updateBacklightLevel(tonumber(o.lastDevice()), tonumber(params.value))
                                end,
            }
        )

        :addSelect(12.2,
            {
                label       =   i18n("resizeImagesOnImport"),
                class       =   "resizeImagesOnImport restrictRightTopSectionSize",
                value       =   o.resizeImagesOnImport,
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
                                    o.resizeImagesOnImport(params.value)
                                end,
            }
        )

        :addTextbox(12.3,
            {
                label       =   i18n("imageBackgroundColourOnImport") .. ":",
                value       =   function() return o.backgroundColour() end,
                class       =   "restrictRightTopSectionSize imageBackgroundColourOnImport jscolor {hash:true, borderColor:'#FFF', insetColor:'#FFF', backgroundColor:'#666'} jscolor-active",
                onchange    =   function(_, params) o.backgroundColour(params.value) end,
            }
        )

        :addContent(13, [[
                </div>
            </div>
            <br />
        ]], false)

        :addParagraph(14, html.span {class="tip"} (html(i18n("loupedeckAppTip"), false) ) .. "\n\n")

        :addContent(15, function(...) return o:generateContent(...) end, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    o.panel:addHandler("onchange", o.id, function(...) o:panelCallback(...) end)

    setmetatable(o, mod.mt)
    return o
end

--- plugins.core.loupedeckctandlive.prefs:renderPanel(context) -> none
--- Method
--- Generates the Preference Panel HTML Content.
---
--- Parameters:
---  * context - Table of data that you want to share with the renderer
---
--- Returns:
---  * HTML content as string
function mod.mt:renderPanel(context)
    if not self._renderPanel then
        local err
        self._renderPanel, err = mod._env:compileTemplate("html/panel.html")
        if err then
            error(err)
        end
    end
    return self._renderPanel(context)
end

-- insertImageCache -> table
-- Variable
-- A cache for commonly inserted images.
local insertImageCache = {}

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
    if insertImageCache[path] then
        return insertImageCache[path]
    else
        local p = mod._env:pathToAbsolute(path)
        local i = imageFromPath(p)
        local result = i:encodeAsURLString(false, "PNG")
        insertImageCache[path] = result
        return result
    end
end

--- plugins.core.loupedeckctandlive.prefs:generateContent() -> string
--- Method
--- Generates the Preference Panel HTML Content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * HTML content as string
function mod.mt:generateContent()
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
    local items = self.items()

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

        numberOfBanks               = mod.numberOfBanks,
        i18n                        = i18n,

        lastApplication             = self.lastApplication(),
        lastBank                    = self.lastBank(),

        lastSelectedControl         = self.lastSelectedControl(),
        lastID                      = self.lastID(),
        lastControlType             = self.lastControlType(),

        insertImage                 = insertImage,

        vibrationIndex              = loupedeck.vibrationIndex,
        wheelSensitivityIndex       = loupedeck.wheelSensitivityIndex,

        numberOfUnits               = mod._deviceManager.NUMBER_OF_DEVICES,

        id                          = self.id,
    }
    return self:renderPanel(context)
end

--- plugins.core.loupedeckctandlive.prefs:setItem(app, bank, controlType, id, valueA, valueB) -> none
--- Method
--- Update the Loupedeck CT layout file.
---
--- Parameters:
---  * app - The application bundle ID as a string
---  * bank - The bank ID as a string
---  * controlType - The control type as a string
---  * id - The ID of the item as a string
---  * valueA - The value of the item as a string
---  * valueB - An optional value
---
--- Returns:
---  * None
function mod.mt:setItem(app, bank, controlType, id, valueA, valueB)
    local items = self.items()
    local lastDevice = self.lastDevice()

    if type(items[lastDevice]) ~= "table" then items[lastDevice] = {} end
    if type(items[lastDevice][app]) ~= "table" then items[lastDevice][app] = {} end
    if type(items[lastDevice][app][bank]) ~= "table" then items[lastDevice][app][bank] = {} end
    if type(items[lastDevice][app][bank][controlType]) ~= "table" then items[lastDevice][app][bank][controlType] = {} end
    if type(items[lastDevice][app][bank][controlType][id]) ~= "table" then items[lastDevice][app][bank][controlType][id] = {} end

    --------------------------------------------------------------------------------
    -- Make copies of any tables for safety:
    --------------------------------------------------------------------------------
    if type(valueA) == "table" then valueA = copy(valueA) end
    if type(valueB) == "table" then valueB = copy(valueB) end

    if type(valueB) ~= "nil" then
        if not items[lastDevice][app][bank][controlType][id][valueA] then items[lastDevice][app][bank][controlType][id][valueA] = {} end
        items[lastDevice][app][bank][controlType][id][valueA] = valueB
    else
        items[lastDevice][app][bank][controlType][id] = valueA
    end

    self.items(items)
end

--- plugins.core.loupedeckctandlive.prefs:generateKnobImages(app, bank, id) -> none
--- Method
--- Generates a combined image for all the knobs on a single side. Which side is generated is determined by the knob id.
---
--- Parameters:
---  * app - The application bundle ID as a string.
---  * bank - The bank as a string.
---  * id - The knob ID as a string.
---
--- Returns:
---  * None
function mod.mt:generateKnobImages(app, bank, bid)
    --------------------------------------------------------------------------------
    -- Handle Snippets:
    --------------------------------------------------------------------------------
    local function getEncodedSnippet(b, i)
        local currentSnippet = b.knob and b.knob[i] and b.knob[i].snippetAction
        if currentSnippet and currentSnippet.action then
            local code = currentSnippet.action.code
            if code then
                --------------------------------------------------------------------------------
                -- Load Snippet from Snippet Preferences if it exists:
                --------------------------------------------------------------------------------
                local snippetID = currentSnippet.action.id
                local snippets = mod._scriptingPreferences.snippets()
                if snippets[snippetID] then
                    code = snippets[snippetID].code
                end

                local successful, result = pcall(load(code))
                if successful and isImage(result) then
                    local size = result:size()
                    if size.w == 60 and size.h == 90 then
                        --------------------------------------------------------------------------------
                        -- The generated image is already 60x90 so proceed:
                        --------------------------------------------------------------------------------
                        return result:encodeAsURLString(true)
                    else
                        --------------------------------------------------------------------------------
                        -- The generated image is not 60x90 so process:
                        --------------------------------------------------------------------------------
                        local v = canvas.new{x = 0, y = 0, w = 60, h = 90 }

                        --------------------------------------------------------------------------------
                        -- Black Background:
                        --------------------------------------------------------------------------------
                        v[1] = {
                            frame = { h = "100%", w = "100%", x = 0, y = 0 },
                            fillColor = { alpha = 1, hex = "#000000" },
                            type = "rectangle",
                        }

                        --------------------------------------------------------------------------------
                        -- Icon - Scaled to fit:
                        --------------------------------------------------------------------------------
                        v[2] = {
                          type="image",
                          image = result,
                          frame = { x = 0, y = 0, h = "100%", w = "100%" },
                        }

                        local fixedImage = v:imageFromCanvas()

                        return fixedImage:encodeAsURLString(true)
                    end
                end
            end
        end
    end

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

    local items = self.items()

    local knobOneImage
    local knobTwoImage
    local knobThreeImage

    local lastDevice = self.lastDevice()

    local currentDevice = items[lastDevice]
    local currentApp = currentDevice and currentDevice[app]
    local currentBank = currentApp and currentApp[bank]
    local currentKnob = currentBank and currentBank.knob

    local currentKnobOneEncodedIcon = currentKnob and currentKnob[kA] and currentKnob[kA].encodedIcon
    local currentKnobOneEncodedIconLabel = currentKnob and currentKnob[kA] and currentKnob[kA].encodedIconLabel
    local currentKnobOneEncodedSnippet = currentBank and getEncodedSnippet(currentBank, kA)

    if currentKnobOneEncodedSnippet then
        knobOneImage = currentKnobOneEncodedSnippet
    elseif currentKnobOneEncodedIcon and currentKnobOneEncodedIcon ~= "" then
        knobOneImage = currentKnobOneEncodedIcon
    elseif currentKnobOneEncodedIconLabel and currentKnobOneEncodedIconLabel ~= "" then
        knobOneImage = currentKnobOneEncodedIconLabel
    end

    local currentKnobTwoEncodedIcon = currentKnob and currentKnob[kB] and currentKnob[kB].encodedIcon
    local currentKnobTwoEncodedIconLabel = currentKnob and currentKnob[kB] and currentKnob[kB].encodedIconLabel
    local currentKnobTwoEncodedSnippet = currentBank and getEncodedSnippet(currentBank, kB)
    if currentKnobTwoEncodedSnippet then
        knobTwoImage = currentKnobTwoEncodedSnippet
    elseif currentKnobTwoEncodedIcon and currentKnobTwoEncodedIcon ~= "" then
        knobTwoImage = currentKnobTwoEncodedIcon
    elseif currentKnobTwoEncodedIconLabel and currentKnobTwoEncodedIconLabel ~= "" then
        knobTwoImage = currentKnobTwoEncodedIconLabel
    end

    local currentKnobThreeEncodedIcon = currentKnob and currentKnob[kC] and currentKnob[kC].encodedIcon
    local currentKnobThreeEncodedIconLabel = currentKnob and currentKnob[kC] and currentKnob[kC].encodedIconLabel
    local currentKnobThreeEncodedSnippet = currentBank and getEncodedSnippet(currentBank, kC)
    if currentKnobThreeEncodedSnippet then
        knobThreeImage = currentKnobThreeEncodedSnippet
    elseif currentKnobThreeEncodedIcon and currentKnobThreeEncodedIcon ~= "" then
        knobThreeImage = currentKnobThreeEncodedIcon
    elseif currentKnobThreeEncodedIconLabel and currentKnobThreeEncodedIconLabel ~= "" then
        knobThreeImage = currentKnobThreeEncodedIconLabel
    end

    local encodedKnobIcon
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
    else
        encodedKnobIcon = ""
    end

    self:setItem(app, bank, "sideScreen", whichScreen, "encodedKnobIcon", encodedKnobIcon)
end

--- plugins.core.loupedeckctandlive.prefs:updateUI([params]) -> none
--- Function
--- Update the Preferences Panel UI.
---
--- Parameters:
---  * params - A optional table of parameters
---
--- Returns:
---  * None
function mod.mt:updateUI(params)
    --------------------------------------------------------------------------------
    -- If no parameters are supplied, just use whatever was last:
    --------------------------------------------------------------------------------
    if not params then
        params = {
            ["application"]     = self.lastApplication(),
            ["bank"]            = self.lastBank(),
            ["controlType"]     = self.lastControlType(),
            ["id"]              = self.lastID()
        }
    end

    local app = params["application"]
    local bank = params["bank"]
    local controlType = params["controlType"]
    local bid = params["id"]

    local selectedControl = params["selectedControl"]

    local injectScript = mod._manager.injectScript

    self.lastSelectedControl(selectedControl)
    self.lastID(bid)
    self.lastControlType(controlType)

    local numberOfTouchButtons = self.numberOfTouchButtons

    local items = self.items()

    local lastDevice = self.lastDevice()

    local currentDevice = items[lastDevice]

    local selectedApp = currentDevice and currentDevice[app]

    local ignoreValue = (selectedApp and selectedApp.ignore) or false
    local selectedBank = selectedApp and selectedApp[bank]
    local selectedControlType = selectedBank and selectedBank[controlType]
    local selectedID = selectedControlType and selectedControlType[bid]

    local topLeftValue = selectedID and selectedID.topLeftAction and selectedID.topLeftAction.actionTitle or ""
    local bottomLeftValue = selectedID and selectedID.bottomLeftAction and selectedID.bottomLeftAction.actionTitle or ""
    local topMiddleValue = selectedID and selectedID.topMiddleAction and selectedID.topMiddleAction.actionTitle or ""
    local bottomMiddleValue = selectedID and selectedID.bottomMiddleAction and selectedID.bottomMiddleAction.actionTitle or ""
    local topRightValue = selectedID and selectedID.topRightAction and selectedID.topRightAction.actionTitle or ""
    local bottomRightValue = selectedID and selectedID.bottomRightAction and selectedID.bottomRightAction.actionTitle or ""

    local leftValue = selectedID and selectedID.leftAction and selectedID.leftAction.actionTitle or ""
    local rightValue = selectedID and selectedID.rightAction and selectedID.rightAction.actionTitle or ""
    local pressValue = selectedID and selectedID.pressAction and selectedID.pressAction.actionTitle or ""
    local releaseValue = selectedID and selectedID.releaseAction and selectedID.releaseAction.actionTitle or ""
    local upValue = selectedID and selectedID.upAction and selectedID.upAction.actionTitle or ""
    local downValue = selectedID and selectedID.downAction and selectedID.downAction.actionTitle or ""
    local doubleTapValue = selectedID and selectedID.doubleTapAction and selectedID.doubleTapAction.actionTitle or ""
    local twoFingerTapValue = selectedID and selectedID.twoFingerTapAction and selectedID.twoFingerTapAction.actionTitle or ""

    local snippetValue = selectedID and selectedID.snippetAction and selectedID.snippetAction.actionTitle or ""
    local ledSnippetActionValue = selectedID and selectedID.ledSnippetAction and selectedID.ledSnippetAction.actionTitle or ""

    local colorValue = selectedID and selectedID.led or "FFFFFF"
    local encodedIcon = selectedID and selectedID.encodedIcon or ""
    local iconLabel = selectedID and selectedID.iconLabel or ""

    local fontColorValue = selectedID and selectedID.fontColor or DEFAULT_FONT_COLOR
    local fontSizeValue = selectedID and selectedID.fontSize or DEFAULT_FONT_SIZE

    local vibratePressValue = selectedID and selectedID.vibratePress or ""
    local vibrateReleaseValue = selectedID and selectedID.vibrateRelease or ""
    local vibrateLeftValue = selectedID and selectedID.vibrateLeft or ""
    local vibrateRightValue = selectedID and selectedID.vibrateRight or ""

    local repeatPressActionUntilReleasedValue = selectedID and selectedID.repeatPressActionUntilReleased or false

    local wheelSensitivityValue = selectedID and selectedID.wheelSensitivity or tostring(loupedeck.defaultWheelSensitivityIndex)

    local bankLabel = selectedBank and selectedBank.bankLabel or ""

    local updateIconsScript = ""

    if selectedBank then
        --------------------------------------------------------------------------------
        -- Touch Buttons:
        --------------------------------------------------------------------------------
        for i=1, numberOfTouchButtons do
            i = tostring(i)
            local currentEncodedIcon = selectedBank.touchButton and selectedBank.touchButton[i] and selectedBank.touchButton[i].encodedIcon
            local currentIconLabel = selectedBank.touchButton and selectedBank.touchButton[i] and selectedBank.touchButton[i].iconLabel
            local currentEncodedIconLabel = selectedBank.touchButton and selectedBank.touchButton[i] and selectedBank.touchButton[i].encodedIconLabel

            --------------------------------------------------------------------------------
            -- Handle Snippets:
            --------------------------------------------------------------------------------
            local currentSnippet = selectedBank.touchButton and selectedBank.touchButton[i] and selectedBank.touchButton[i].snippetAction
            if currentSnippet and currentSnippet.action then
                local code = currentSnippet.action.code
                if code then
                    --------------------------------------------------------------------------------
                    -- Load Snippet from Snippet Preferences if it exists:
                    --------------------------------------------------------------------------------
                    local snippetID = currentSnippet.action.id
                    local snippets = mod._scriptingPreferences.snippets()
                    if snippets[snippetID] then
                        code = snippets[snippetID].code
                    end

                    local successful, result = pcall(load(code))
                    if successful and isImage(result) then
                        local size = result:size()
                        if size.w == 90 and size.h == 90 then
                            --------------------------------------------------------------------------------
                            -- The generated image is already 90x90 so proceed:
                            --------------------------------------------------------------------------------
                            currentEncodedIcon = result:encodeAsURLString(true)
                        else
                            --------------------------------------------------------------------------------
                            -- The generated image is not 90x90 so process:
                            --------------------------------------------------------------------------------
                            local v = canvas.new{x = 0, y = 0, w = 90, h = 90 }

                            --------------------------------------------------------------------------------
                            -- Black Background:
                            --------------------------------------------------------------------------------
                            v[1] = {
                                frame = { h = "100%", w = "100%", x = 0, y = 0 },
                                fillColor = { alpha = 1, hex = "#000000" },
                                type = "rectangle",
                            }

                            --------------------------------------------------------------------------------
                            -- Icon - Scaled to fit:
                            --------------------------------------------------------------------------------
                            v[2] = {
                              type="image",
                              image = result,
                              frame = { x = 0, y = 0, h = "100%", w = "100%" },
                            }

                            local fixedImage = v:imageFromCanvas()

                            currentEncodedIcon = fixedImage:encodeAsURLString(true)
                        end
                    end
                end
            end

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
        if self.id ~= "loupedecklives" then
            local leftScreen = selectedBank and selectedBank.sideScreen and selectedBank.sideScreen["1"]
            if leftScreen and leftScreen.encodedKnobIcon and leftScreen.encodedKnobIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. leftScreen.encodedKnobIcon .. [[")]] .. "\n"
            elseif leftScreen and leftScreen.encodedIcon and leftScreen.encodedIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. leftScreen.encodedIcon .. [[")]] .. "\n"
            else
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen1.png") .. [[")]] .. "\n"
            end
        end

        --------------------------------------------------------------------------------
        -- Right Screen:
        --------------------------------------------------------------------------------
        if self.id ~= "loupedecklives" then
            local rightScreen = selectedBank and selectedBank.sideScreen and selectedBank.sideScreen["2"]
            if rightScreen and rightScreen.encodedKnobIcon and rightScreen.encodedKnobIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. rightScreen.encodedKnobIcon .. [[")]] .. "\n"
            elseif rightScreen and rightScreen.encodedIcon and rightScreen.encodedIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. rightScreen.encodedIcon .. [[")]] .. "\n"
            else
                updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. insertImage("images/sideScreen2.png") .. [[")]] .. "\n"
            end
        end

        --------------------------------------------------------------------------------
        -- Wheel Screen:
        --------------------------------------------------------------------------------
        if self.id == "loupedeckct" then
            local wheelScreen = selectedBank and selectedBank.wheelScreen and selectedBank.wheelScreen["1"]

            local newEncodedIcon
            if wheelScreen and wheelScreen.encodedIcon and wheelScreen.encodedIcon ~= "" then
                newEncodedIcon = wheelScreen.encodedIcon
            end

            --------------------------------------------------------------------------------
            -- Handle Snippets:
            --------------------------------------------------------------------------------
            local currentSnippet = selectedBank.wheelScreen and selectedBank.wheelScreen["1"] and selectedBank.wheelScreen["1"].snippetAction
            if currentSnippet and currentSnippet.action then
                local code = currentSnippet.action.code
                if code then
                    --------------------------------------------------------------------------------
                    -- Load Snippet from Snippet Preferences if it exists:
                    --------------------------------------------------------------------------------
                    local snippetID = currentSnippet.action.id
                    local snippets = mod._scriptingPreferences.snippets()
                    if snippets[snippetID] then
                        code = snippets[snippetID].code
                    end

                    local successful, result = pcall(load(code))
                    if successful and isImage(result) then
                        local size = result:size()
                        if size.w == 240 and size.h == 240 then
                            --------------------------------------------------------------------------------
                            -- The generated image is already 240x240 so proceed:
                            --------------------------------------------------------------------------------
                            encodedIcon = result:encodeAsURLString(true)
                        else
                            --------------------------------------------------------------------------------
                            -- The generated image is not 240x240 so process:
                            --------------------------------------------------------------------------------
                            local v = canvas.new{x = 0, y = 0, w = 240, h = 240 }

                            --------------------------------------------------------------------------------
                            -- Black Background:
                            --------------------------------------------------------------------------------
                            v[1] = {
                                frame = { h = "100%", w = "100%", x = 0, y = 0 },
                                fillColor = { alpha = 1, hex = "#000000" },
                                type = "rectangle",
                            }

                            --------------------------------------------------------------------------------
                            -- Icon - Scaled as per preferences:
                            --------------------------------------------------------------------------------
                            v[2] = {
                              type="image",
                              image = result,
                              frame = { x = 0, y = 0, h = "100%", w = "100%" },
                            }

                            local fixedImage = v:imageFromCanvas()

                            newEncodedIcon = fixedImage:encodeAsURLString(true)
                        end
                    end
                end
            end

            if newEncodedIcon then
                updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. newEncodedIcon .. [[")]] .. "\n"
            else
                updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. insertImage("images/wheelScreen1.png") .. [[")]] .. "\n"
            end
        end
    else
        --------------------------------------------------------------------------------
        -- Clear all the UI elements in the Preferences Window:
        --------------------------------------------------------------------------------
        for i=1, numberOfTouchButtons do
            i = tostring(i)
            updateIconsScript = updateIconsScript .. [[changeImage("touchButton]] .. i .. [[", "]] .. insertImage("images/touchButton" .. i .. ".png") .. [[")]] .. "\n"
        end

        if self.id ~= "loupedecklives" then
            updateIconsScript = updateIconsScript .. [[changeImage("sideScreen1", "]] .. insertImage("images/sideScreen1.png") .. [[")]] .. "\n"
            updateIconsScript = updateIconsScript .. [[changeImage("sideScreen2", "]] .. insertImage("images/sideScreen2.png") .. [[")]] .. "\n"
        end

        if self.id == "loupedeckct" then
            updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. insertImage("images/wheelScreen1.png") .. [[")]] .. "\n"
        end
    end

    --------------------------------------------------------------------------------
    -- Update UI on whether Unit 1 is connected or not:
    --------------------------------------------------------------------------------
    local loadSettingsFromDevice = self.device.loadSettingsFromDevice()
    local connected = self.device.connected[1]()
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

    --------------------------------------------------------------------------------
    -- Inject Script:
    --------------------------------------------------------------------------------
    injectScript([[
        changeValueByID('unit', `]] .. escapeTilda(lastDevice) .. [[`);
        changeValueByID('bankLabel', `]] .. escapeTilda(bankLabel) .. [[`);
        changeValueByID('press_action', `]] .. escapeTilda(pressValue) .. [[`);
        changeValueByID('release_action', `]] .. escapeTilda(releaseValue) .. [[`);
        changeValueByID('left_action', `]] .. escapeTilda(leftValue) .. [[`);
        changeValueByID('right_action', `]] .. escapeTilda(rightValue) .. [[`);
        changeValueByID('top_left_action', `]] .. escapeTilda(topLeftValue) .. [[`);
        changeValueByID('bottom_left_action', `]] .. escapeTilda(bottomLeftValue) .. [[`);
        changeValueByID('top_middle_action', `]] .. escapeTilda(topMiddleValue) .. [[`);
        changeValueByID('bottom_middle_action', `]] .. escapeTilda(bottomMiddleValue) .. [[`);
        changeValueByID('top_right_action', `]] .. escapeTilda(topRightValue) .. [[`);
        changeValueByID('bottom_right_action', `]] .. escapeTilda(bottomRightValue) .. [[`);
        changeValueByID('up_touch_action', `]] .. escapeTilda(upValue) .. [[`);
        changeValueByID('down_touch_action', `]] .. escapeTilda(downValue) .. [[`);
        changeValueByID('left_touch_action', `]] .. escapeTilda(leftValue) .. [[`);
        changeValueByID('right_touch_action', `]] .. escapeTilda(rightValue) .. [[`);
        changeValueByID('double_tap_touch_action', `]] .. escapeTilda(doubleTapValue) .. [[`);
        changeValueByID('two_finger_touch_action', `]] .. escapeTilda(twoFingerTapValue) .. [[`);
        changeValueByID('snippet_action', `]] .. escapeTilda(snippetValue) .. [[`);
        changeValueByID('led_snippet_action', `]] .. escapeTilda(ledSnippetActionValue) .. [[`);
        changeValueByID('wheel_snippet_action', `]] .. escapeTilda(snippetValue) .. [[`);
        changeValueByID('vibratePress', ']] .. vibratePressValue .. [[');
        changeValueByID('vibrateRelease', ']] .. vibrateReleaseValue .. [[');
        changeValueByID('vibrateLeft', ']] .. vibrateLeftValue .. [[');
        changeValueByID('vibrateRight', ']] .. vibrateRightValue .. [[');
        changeValueByID('fontSize', ']] .. fontSizeValue .. [[');
        changeValueByID('wheelSensitivity', ']] .. wheelSensitivityValue .. [[');
        changeValueByID('iconLabel', `]] .. iconLabel .. [[`);
        changeCheckedByID('ignore', ]] .. tostring(ignoreValue) .. [[);
        changeCheckedByID('repeatPressActionUntilReleased', ]] .. tostring(repeatPressActionUntilReleasedValue) .. [[);
        changeColor(']] .. colorValue .. [[');
        changeFontColor(']] .. fontColorValue .. [[');
        setIcon("]] .. encodedIcon .. [[");
    ]] .. updateIconsScript .. "\n" .. connectedScript .. "\n" .. "updateIgnoreVisibility();")
end

--- plugins.core.loupedeckctandlive.prefs:processEncodedIcon(icon, controlType) -> string
--- Function
--- Processes an encoded icon.
---
--- Parameters:
---  * icon - The encoded icon as URL string or a hs.image object.
---  * controlType - The control type as string.
---
--- Returns:
---  * A new encoded icon as URL string.
function mod.mt:processEncodedIcon(icon, controlType)
    local width, height = self.getScreenSizeFromControlType(controlType)

    local newImage
    if type(icon) == "userdata" then
        newImage = icon
    else
        newImage = imageFromURL(icon)
    end

    local backgroundColour = self.backgroundColour()
    local resizeImagesOnImport = self.resizeImagesOnImport()
    local offset = tostring( (100 - tonumber(resizeImagesOnImport:sub(1, -2))) /2 ) .. "%"

    local v = canvas.new{x = 0, y = 0, w = width, h = height }

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

--- plugins.core.loupedeckctandlive.prefs:buildIconFromLabel(params) -> string
--- Function
--- Creates a new icon image from a string.
---
--- Parameters:
---  * params - A table of parameters.
---
--- Returns:
---  * A new encoded icon as URL string.
function mod.mt:buildIconFromLabel(params)
    local app = params["application"]
    local bank = params["bank"]
    local controlType = params["controlType"]
    local bid = params["id"]

    local items = self.items()

    local lastDevice = self.lastDevice()
    local currentDevice = items[lastDevice]

    local selectedApp = currentDevice[app]

    local selectedBank = selectedApp and selectedApp[bank]
    local selectedControlType = selectedBank and selectedBank[controlType]
    local selectedID = selectedControlType and selectedControlType[bid]

    local fontColor = selectedID and selectedID.fontColor and "#" .. selectedID.fontColor or "#" .. DEFAULT_FONT_COLOR
    local fontSize = selectedID and selectedID.fontSize or DEFAULT_FONT_SIZE
    local font = selectedID and selectedID.font or DEFAULT_FONT
    local value = selectedID and selectedID.iconLabel or ""

    local width, height = self.getScreenSizeFromControlType(controlType)

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
        textColor = { hex = fontColor },
        textSize = tonumber(fontSize),
        textFont = font,
        type = "text",
    }

    local img = v:imageFromCanvas()

    return img:encodeAsURLString(true)
end

-- changeControl(controlType, id) -> none
-- Function
-- Triggers a JavaScript function to change the control on the UI.
--
-- Parameters:
--  * controlType - The control type.
--  * id - The control ID.
--
-- Returns:
--  * None
local function changeControl(controlType, id)
    local injectScript = mod._manager.injectScript
    injectScript("changeControl('', '', '" .. controlType .. "', '" .. id .. "');")
end

--- plugins.core.loupedeckctandlive.prefs:refreshDevice() -> none
--- Method
--- Refreshes the currently selected Loupedeck Device.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.mt:refreshDevice()
    local lastDevice = self.lastDevice()
    self.device:refresh(tonumber(lastDevice))
end

--- plugins.core.loupedeckctandlive.prefs:panelCallback(id, params) -> none
--- Method
--- JavaScript Callback for the Preferences Panel
---
--- Parameters:
---  * id - ID as string
---  * params - Table of paramaters
---
--- Returns:
---  * None
function mod.mt:panelCallback(id, params)
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
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]

            local buttonType = params["buttonType"]
            local activatorID = params["application"]

            --------------------------------------------------------------------------------
            -- NOTE: "nippetAction" is not a type as it could be "snippetAction" or
            --       "ledSnippetAction"
            --------------------------------------------------------------------------------
            if buttonType:sub(-12) == "nippetAction" then
                 activatorID = "snippet"
            end

            if not self.activator then
                self.activator = {}
            end

            if activatorID == "snippet" and not self.activator[activatorID] then
                --------------------------------------------------------------------------------
                -- Create a new Snippet Activator:
                --------------------------------------------------------------------------------
                self.activator["snippet"] = mod._actionmanager.getActivator(self.id .. "_preferences_snippet")

                --------------------------------------------------------------------------------
                -- Only allow the Snippets action group:
                --------------------------------------------------------------------------------
                self.activator["snippet"]:allowHandlers("global_snippets")
            elseif not self.activator[activatorID] then
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
                self.activator[activatorID] = mod._actionmanager.getActivator(self.id .. "_preferences_" .. activatorID)

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
                self.activator[activatorID]:allowHandlers(unpack(allowedHandlers))

                --------------------------------------------------------------------------------
                -- Gather Toolbar Icons for Search Console:
                --------------------------------------------------------------------------------
                local defaultSearchConsoleToolbar = mod._appmanager.defaultSearchConsoleToolbar()
                local appSearchConsoleToolbar = mod._appmanager.getSearchConsoleToolbar(activatorID) or {}
                local searchConsoleToolbar = mergeTable(defaultSearchConsoleToolbar, appSearchConsoleToolbar)
                self.activator[activatorID]:toolbarIcons(searchConsoleToolbar)

                --------------------------------------------------------------------------------
                -- Only enable handlers for the current app:
                --------------------------------------------------------------------------------
                local enabledHandlerID = legacyGroupID or activatorID
                if enabledHandlerID and enabledHandlerID == "All Applications" then
                    enabledHandlerID = "global"
                end
                self.activator[activatorID]:enableHandlers(enabledHandlerID)

                --------------------------------------------------------------------------------
                -- Add a specific toolbar icon for the current application:
                --------------------------------------------------------------------------------
                if enabledHandlerID and enabledHandlerID ~= "global" then
                    local icon = imageFromAppBundle(activatorID)
                    self.activator[activatorID]:setBundleID(enabledHandlerID, icon, displayName)
                end
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
            self.activator[activatorID]:onActivate(function(handler, action, text)
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

                self:setItem(app, bank, controlType, bid, buttonType, result)

                --------------------------------------------------------------------------------
                -- If it's a press action, and no icon label already exists:
                --------------------------------------------------------------------------------
                if buttonType == "pressAction" and controlType == "touchButton" then
                    local items = self.items()
                    local lastDevice = self.lastDevice()
                    local iconLabel = items and items[lastDevice] and items[lastDevice][app] and items[lastDevice][app][bank] and items[lastDevice][app][bank][controlType] and items[lastDevice][app][bank][controlType][bid] and items[lastDevice][app][bank][controlType][bid]["iconLabel"]
                    if (iconLabel and iconLabel == "") or not iconLabel then
                        --------------------------------------------------------------------------------
                        -- Automatically add an icon label based on the action title:
                        --------------------------------------------------------------------------------
                        self:setItem(app, bank, controlType, bid, "iconLabel", actionTitle)

                        --------------------------------------------------------------------------------
                        -- Generate encoded icon label:
                        --------------------------------------------------------------------------------
                        local encodedImg = self:buildIconFromLabel(params) or ""
                        self:setItem(app, bank, controlType, bid, "encodedIconLabel", encodedImg)
                    end
                end

                --------------------------------------------------------------------------------
                -- If the action contains an image, apply it to the Touch Button (except
                -- if it's a Snippet Action or if "Automatically Apply Icon From Action" is
                -- disabled):
                --------------------------------------------------------------------------------
                if controlType == "touchButton" and buttonType ~= "snippetAction" and self.automaticallyApplyIconFromAction() then
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
                        local encodedIcon = self:processEncodedIcon(preSuppliedImage, controlType)
                        self:setItem(app, bank, controlType, bid, "encodedIcon", encodedIcon)
                    end
                end

                --------------------------------------------------------------------------------
                -- Process knobs:
                --------------------------------------------------------------------------------
                if controlType == "knob" then
                    self:generateKnobImages(app, bank, bid)
                end

                --------------------------------------------------------------------------------
                -- Change the control and update the UI:
                --------------------------------------------------------------------------------
                changeControl(controlType, bid)

                --------------------------------------------------------------------------------
                -- Refresh the hardware:
                --------------------------------------------------------------------------------
                self:refreshDevice()
            end)

            --------------------------------------------------------------------------------
            -- Set the Query String to the currently selected action:
            --------------------------------------------------------------------------------
            local items = self.items()
            local lastDevice = self.lastDevice()
            local currentAction = items and items[lastDevice] and items[lastDevice][app] and items[lastDevice][app][bank] and items[lastDevice][app][bank][controlType] and items[lastDevice][app][bank][controlType][bid] and items[lastDevice][app][bank][controlType][bid][buttonType]
            local currentActionTitle = currentAction and currentAction.actionTitle
            if currentActionTitle and currentActionTitle ~= "" then
                self.activator[activatorID]:lastQueryValue(currentActionTitle)
            end

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            self.activator[activatorID]:show()
        elseif callbackType == "clearAction" then
            --------------------------------------------------------------------------------
            -- Clear an action:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local buttonType = params["buttonType"]

            self:setItem(app, bank, controlType, bid, buttonType, {})

            --------------------------------------------------------------------------------
            -- Process knobs:
            --------------------------------------------------------------------------------
            if controlType == "knob" then
                self:generateKnobImages(app, bank, bid)
            end

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            self:updateUI(params)
        elseif callbackType == "updateUnit" then
            --------------------------------------------------------------------------------
            -- Update the unit:
            --------------------------------------------------------------------------------
            local unit = params["unit"]
            self.lastDevice(unit)

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            self:updateUI()
        elseif callbackType == "updateApplicationAndBank" then
            local app = params["application"]
            local bank = params["bank"]

            --------------------------------------------------------------------------------
            -- Delete Application:
            --------------------------------------------------------------------------------
            if app == "Delete Application" then
                local items = self.items()
                local apps = {}
                local bundleIDs = {}

                for _, device in pairs(items) do
                    for theBundleID, v in pairs(device) do
                        if v.displayName then
                            table.insert(apps, v.displayName)
                            bundleIDs[v.displayName] = theBundleID
                        end
                    end
                end

                local result = displayChooseFromList(i18n("pleaseSelectAnApplicationToDelete"), apps)
                if result then
                    for _, appName in pairs(result) do
                        local whichBundleID = bundleIDs[appName]
                        for i=1, mod._deviceManager.NUMBER_OF_DEVICES do
                            items[tostring(i)][whichBundleID] = nil
                        end
                    end
                    self.items(items)
                end

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                mod._manager.refresh()
            --------------------------------------------------------------------------------
            -- Add Application:
            --------------------------------------------------------------------------------
            elseif app == "Add Application" then
                injectScript([[
                    changeValueByID('application', ']] .. self.lastApplication() .. [[');
                ]])
                local files = chooseFileOrFolder(i18n("pleaseSelectAnApplication") .. ":", "/Applications", true, false, false, {"app"}, false)
                if files then
                    local path = files["1"]
                    local info = path and infoForBundlePath(path)
                    local displayName = info and info.CFBundleDisplayName or info.CFBundleName or info.CFBundleExecutable
                    local bundleID = info and info.CFBundleIdentifier
                    if displayName and bundleID then
                        local items = self.items()

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
                        for _, device in pairs(items) do
                            for theBundleID, v in pairs(device) do
                                if v.displayName then
                                    apps[theBundleID] = v.displayName
                                end
                            end
                        end

                        --------------------------------------------------------------------------------
                        -- Prevent duplicates:
                        --------------------------------------------------------------------------------
                        for i, v in pairs(items) do
                            if (i == bundleID and v.displayName) or tableContains(apps, bundleID) then
                                webviewAlert(mod._manager.getWebview(), function() end, i18n("duplicateApplication"), i18n("duplicateApplicationDescription"), i18n("ok"))
                                return
                            end
                        end
                        local lastDevice = self.lastDevice()

                        if not items[lastDevice] then
                            items[lastDevice] = {}
                        end

                        items[lastDevice][bundleID] = {
                            ["displayName"] = displayName,
                        }
                        self.items(items)
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
                self.lastApplication(app)
                self.lastBank(bank)

                --------------------------------------------------------------------------------
                -- Change the bank:
                --------------------------------------------------------------------------------
                local activeBanks = self.device.activeBanks()

                -- Remove the '_LeftFn' and '_RightFn'
                local newBank = bank
                if string.sub(bank, -7) == "_LeftFn" then
                    newBank = string.sub(bank, 1, -8)
                end
                if string.sub(bank, -8) == "_RightFn" then
                    newBank = string.sub(bank, 1, -9)
                end

                activeBanks[app] = newBank
                self.device.activeBanks(activeBanks)

                --------------------------------------------------------------------------------
                -- Update the UI:
                --------------------------------------------------------------------------------
                self:updateUI(params)

                --------------------------------------------------------------------------------
                -- Refresh the hardware:
                --------------------------------------------------------------------------------
                if mod._deviceManager.previewSelectedApplicationAndBankOnHardware() then
                    --------------------------------------------------------------------------------
                    -- Refresh all devices:
                    --------------------------------------------------------------------------------
                    for _, device in pairs(mod._deviceManager.devices) do
                        for deviceNumber=1, mod._deviceManager.NUMBER_OF_DEVICES do
                            device:clearCache(deviceNumber)
                            device:refresh(deviceNumber)
                        end
                    end
                else
                    --------------------------------------------------------------------------------
                    -- Just refresh the active device:
                    --------------------------------------------------------------------------------
                    self:refreshDevice()
                end
            end
        elseif callbackType == "updateUI" then
            self:updateUI(params)
        elseif callbackType == "updateColor" then
            --------------------------------------------------------------------------------
            -- Update Color:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "led", value)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "updateBankLabel" then
            --------------------------------------------------------------------------------
            -- Update Bank Label:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]

            local items = self.items()
            local lastDevice = self.lastDevice()

            if not items[lastDevice] then items[lastDevice] = {} end
            if not items[lastDevice][app] then items[lastDevice][app] = {} end
            if not items[lastDevice][app][bank] then items[lastDevice][app][bank] = {} end
            items[lastDevice][app][bank]["bankLabel"] = params["bankLabel"]

            self.items(items)
        elseif callbackType == "updateVibratePress" then
            --------------------------------------------------------------------------------
            -- Update Vibrate Press:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "vibratePress", value)
        elseif callbackType == "updateVibrateRelease" then
            --------------------------------------------------------------------------------
            -- Update Vibrate Release:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "vibrateRelease", value)
        elseif callbackType == "updateVibrateLeft" then
            --------------------------------------------------------------------------------
            -- Update Vibrate Left:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "vibrateLeft", value)
        elseif callbackType == "updateVibrateRight" then
            --------------------------------------------------------------------------------
            -- Update Vibrate Right:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "vibrateRight", value)
        elseif callbackType == "updateWheelSensitivity" then
            --------------------------------------------------------------------------------
            -- Update Wheel Sensitivity:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "wheelSensitivity", value)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "iconClicked" then
            --------------------------------------------------------------------------------
            -- Icon Drop Zone Clicked:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(self.lastIconPath()) then
                self.lastIconPath(self.defaultIconPath)
            end

            local result = chooseFileOrFolder(i18n("pleaseSelectAnIcon"), self.lastIconPath(), true, false, false, mod.supportedExtensions, true)
            local failed = false
            if result and result["1"] then
                local path = result["1"]

                --------------------------------------------------------------------------------
                -- Save path for next time:
                --------------------------------------------------------------------------------
                self.lastIconPath(removeFilenameFromPath(path))

                local appInfo = infoForBundlePath(path)
                local bundleID = appInfo and appInfo.CFBundleIdentifier
                local icon = imageFromPath(path) or imageFromAppBundle(bundleID)
                if icon then
                    local controlType = params["controlType"]
                    local encodedIcon = self:processEncodedIcon(icon, controlType)
                    if encodedIcon then
                        --------------------------------------------------------------------------------
                        -- Save Icon to file:
                        --------------------------------------------------------------------------------
                        local app = params["application"]
                        local bank = params["bank"]
                        local bid = params["id"]

                        self:setItem(app, bank, controlType, bid, "encodedIcon", encodedIcon)

                        --------------------------------------------------------------------------------
                        -- Process knobs:
                        --------------------------------------------------------------------------------
                        if controlType == "knob" then
                            self:generateKnobImages(app, bank, bid)
                        end

                        --------------------------------------------------------------------------------
                        -- Write to history:
                        --------------------------------------------------------------------------------
                        local iconHistory = self.iconHistory()
                        while (#(iconHistory) >= 5) do
                            table.remove(iconHistory,1)
                        end
                        local filename = getFilenameFromPath(path, true)
                        table.insert(iconHistory, {filename, encodedIcon})
                        self.iconHistory(iconHistory)

                        --------------------------------------------------------------------------------
                        -- Update the UI:
                        --------------------------------------------------------------------------------
                        self:updateUI(params)

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        self:refreshDevice()
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
            -- Bad Icon File Extension from a Drag & Drop:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function() end, i18n("badLoupedeckIcon"), i18n("badLoupedeckIconTip"), i18n("ok"))
        elseif callbackType == "updateIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            local icon = params["icon"]
            local controlType = params["controlType"]
            local encodedIcon = self:processEncodedIcon(icon, controlType)

            --------------------------------------------------------------------------------
            -- Write to file:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local bid = params["id"]

            self:setItem(app, bank, controlType, bid, "encodedIcon", encodedIcon)

            --------------------------------------------------------------------------------
            -- Process knobs:
            --------------------------------------------------------------------------------
            self:generateKnobImages(app, bank, bid)

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            self:updateUI(params)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "updateButtonIcon" then
            --------------------------------------------------------------------------------
            -- Update Button Icon After A Drag & Drop:
            --------------------------------------------------------------------------------
            local icon = params["icon"]
            local controlType = "touchButton"
            local encodedIcon = self:processEncodedIcon(icon, controlType)

            --------------------------------------------------------------------------------
            -- Write to file:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local bid = params["id"]
            self:setItem(app, bank, controlType, bid, "encodedIcon", encodedIcon)

            --------------------------------------------------------------------------------
            -- Change the control and update the UI:
            --------------------------------------------------------------------------------
            changeControl(controlType, bid)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "updateSideScreenIcon" then
            --------------------------------------------------------------------------------
            -- Update Side Screen Icons after a Drag & Drop:
            --------------------------------------------------------------------------------
            local icon = params["icon"]
            local controlType = "sideScreen"
            local encodedIcon = self:processEncodedIcon(icon, controlType)

            --------------------------------------------------------------------------------
            -- Write to file:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local bid = params["id"]

            self:setItem(app, bank, controlType, bid, "encodedIcon", encodedIcon)

            --------------------------------------------------------------------------------
            -- Process knobs:
            --------------------------------------------------------------------------------
            self:generateKnobImages(app, bank, bid)

            --------------------------------------------------------------------------------
            -- Change the control and update the UI:
            --------------------------------------------------------------------------------
            changeControl(controlType, bid)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "updateWheelIcon" then
            --------------------------------------------------------------------------------
            -- Update Wheel Icon via Drag & Drop:
            --------------------------------------------------------------------------------
            local icon = params["icon"]
            local controlType = "wheelScreen"
            local encodedIcon = self:processEncodedIcon(icon, controlType)

            --------------------------------------------------------------------------------
            -- Write to file:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local bid = params["id"]
            self:setItem(app, bank, controlType, bid, "encodedIcon", encodedIcon)

            --------------------------------------------------------------------------------
            -- Change the control and update the UI:
            --------------------------------------------------------------------------------
            changeControl(controlType, bid)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "updateKnobIcon" then
            --------------------------------------------------------------------------------
            -- Update Knob Icon After A Drag & Drop:
            --------------------------------------------------------------------------------
            local icon = params["icon"]
            local controlType = "knob"
            local encodedIcon = self:processEncodedIcon(icon, controlType)

            --------------------------------------------------------------------------------
            -- Write to file:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local bid = params["id"]
            self:setItem(app, bank, controlType, bid, "encodedIcon", encodedIcon)

            --------------------------------------------------------------------------------
            -- Generate Knob Images:
            --------------------------------------------------------------------------------
            self:generateKnobImages(app, bank, bid)

            --------------------------------------------------------------------------------
            -- Change the control and update the UI:
            --------------------------------------------------------------------------------
            changeControl(controlType, bid)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "iconHistory" then

            local controlType = params["controlType"]

            local menu = {}
            local iconHistory = self.iconHistory()

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

                                local encodedIcon = self:processEncodedIcon(item[2], controlType)
                                self:setItem(app, bank, controlType, bid, "encodedIcon", encodedIcon)

                                --------------------------------------------------------------------------------
                                -- Process knobs:
                                --------------------------------------------------------------------------------
                                if controlType == "knob" then
                                    self:generateKnobImages(app, bank, bid)
                                end

                                --------------------------------------------------------------------------------
                                -- Update the UI:
                                --------------------------------------------------------------------------------
                                self:updateUI(params)

                                --------------------------------------------------------------------------------
                                -- Refresh the hardware:
                                --------------------------------------------------------------------------------
                                self:refreshDevice()
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
            local controlType = params["controlType"]
            local bid = params["id"]

            self:setItem(app, bank, controlType, bid, "encodedIcon", "")

            --------------------------------------------------------------------------------
            -- Process knobs:
            --------------------------------------------------------------------------------
            if controlType == "knob" then
                self:generateKnobImages(app, bank, bid)
            end

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            self:updateUI(params)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
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
                local controlType = params["controlType"]
                local bid = params["id"]
                local value = params["value"]

                self:setItem(app, bank, controlType, bid, "iconLabel", value)

                --------------------------------------------------------------------------------
                -- Generate encoded icon label:
                --------------------------------------------------------------------------------
                local encodedImg = ""
                if value and trim(value) ~= "" then
                    encodedImg = self:buildIconFromLabel(params)
                end

                self:setItem(app, bank, controlType, bid, "encodedIconLabel", encodedImg)

                --------------------------------------------------------------------------------
                -- Generate knob images if needed:
                --------------------------------------------------------------------------------
                if controlType == "knob" then
                    self:generateKnobImages(app, bank, bid)
                end

                --------------------------------------------------------------------------------
                -- Change the control and update the UI:
                --------------------------------------------------------------------------------
                local items = self.items()
                local lastDevice = self.lastDevice()

                local currentDevice = items[lastDevice]
                local currentApp = currentDevice and currentDevice[app]
                local currentBank = currentApp and currentApp[bank]
                local currentControlType = currentBank and currentBank[controlType]
                local currentID = currentControlType and currentControlType[bid]

                if controlType == "knob" then
                    --------------------------------------------------------------------------------
                    -- Update knobs:
                    --------------------------------------------------------------------------------
                    local whichScreen = "1"
                    if bid == "4" or bid == "5" or bid == "6" then
                        whichScreen = "2"
                    end

                    local currentSideScreen = currentBank and currentBank.sideScreen
                    local sideScreen = currentSideScreen[whichScreen]
                    local encodedKnobIcon = sideScreen and sideScreen.encodedKnobIcon
                    local encodedIcon = sideScreen and sideScreen.encodedIcon
                    if encodedKnobIcon and encodedKnobIcon ~= "" then
                        injectScript([[changeImage("sideScreen]] .. whichScreen .. [[", "]] .. encodedKnobIcon .. [[")]])
                    elseif encodedIcon and encodedIcon ~= "" then
                        injectScript([[changeImage("sideScreen]] .. whichScreen .. [[", "]] .. encodedIcon .. [[")]])
                    else
                        injectScript([[changeImage("sideScreen]] .. whichScreen .. [[", "]] .. insertImage("images/sideScreen" .. whichScreen .. ".png") .. [[")]])
                    end
                else
                    --------------------------------------------------------------------------------
                    -- Update buttons:
                    --------------------------------------------------------------------------------
                    local encodedIcon = currentID.encodedIcon
                    local encodedIconLabel = currentID.encodedIconLabel
                    if encodedIcon and encodedIcon ~= "" then
                        injectScript([[changeImage("]] .. controlType .. bid .. [[", "]] .. encodedIcon .. [[")]])
                    elseif encodedIconLabel and encodedIconLabel ~= "" then
                        injectScript([[changeImage("]] .. controlType .. bid .. [[", "]] .. encodedIconLabel .. [[")]])
                    else
                        injectScript([[changeImage("]] .. controlType .. bid .. [[", "]] .. insertImage("images/" .. controlType .. bid .. ".png") .. [[")]])
                    end
                end

                --------------------------------------------------------------------------------
                -- Refresh the hardware:
                --------------------------------------------------------------------------------
                self:refreshDevice()
            end

            if not self.iconLabelDelayed then
                self.iconLabelDelayed = delayed.new(ICON_LABEL_UPDATE_DELAY, function() delayedFn() end)
            end

            self.iconLabelDelayed:start()
        elseif callbackType == "importSettings" then
            --------------------------------------------------------------------------------
            -- Import Settings:
            --------------------------------------------------------------------------------
            local importSettings = function(action)

                local lastImportPath = self.lastImportPath()
                if not doesDirectoryExist(lastImportPath) then
                    lastImportPath = "~/Desktop"
                    self.lastImportPath(lastImportPath)
                end

                local path = chooseFileOrFolder(i18n("pleaseSelectAFileToImport") .. ":", lastImportPath, true, false, false, {"cp" .. self.commandID})
                if path and path["1"] then
                    local data = json.read(path["1"])
                    if data then
                        --------------------------------------------------------------------------------
                        -- Allow for legacy files that don't contain a "unit":
                        --------------------------------------------------------------------------------
                        for i, _ in pairs(data) do
                            if not tonumber(i) then
                                local lastDevice = self.lastDevice()
                                data = { [lastDevice] = copy(data) }
                                break
                            end
                        end

                        if action == "replace" then
                            self.items(data)
                        elseif action == "merge" then
                            local original = self.items()
                            local combined = mergeTable(original, data)
                            self.items(combined)
                        end

                        --------------------------------------------------------------------------------
                        -- Reload Preferences:
                        --------------------------------------------------------------------------------
                        mod._manager.refresh()

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        self:refreshDevice()

                        --------------------------------------------------------------------------------
                        -- Save import path for next time:
                        --------------------------------------------------------------------------------
                        local folder = removeFilenameFromPath(path["1"])
                        self.lastImportPath(folder)
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
            local app = params["application"]
            local bank = params["bank"]

            local exportSettings = function(what)
                local items = self.items()
                local lastDevice = self.lastDevice()
                local data = {}

                local filename = ""

                if what == "Everything" then
                    data = copy(items)
                    filename = "Everything"
                elseif what == "Unit" then
                    data[lastDevice] = copy(items[lastDevice])
                    filename = "Unit " .. lastDevice
                elseif what == "Application" then
                    data[lastDevice] = {}
                    data[lastDevice][app] = copy(items[lastDevice][app])
                    filename = "Unit " .. lastDevice .. " - " .. app
                elseif what == "Bank" then
                    data[lastDevice] = {}
                    data[lastDevice][app] = {}
                    data[lastDevice][app][bank] = copy(items[lastDevice][app][bank])
                    filename = "Unit " .. lastDevice .. " - " .. app .. " - Bank " .. bank
                end

                local lastExportPath = self.lastExportPath()
                if not doesDirectoryExist(lastExportPath) then
                    lastExportPath = "~/Desktop"
                    self.lastExportPath(lastExportPath)
                end

                local path = chooseFileOrFolder(i18n("pleaseSelectAFolderToExportTo") .. ":", lastExportPath, false, true, false)
                if path and path["1"] then
                    self.lastExportPath(path["1"])
                    json.write(path["1"] .. "/" .. filename .. " - " .. os.date("%Y%m%d %H%M") .. ".cp" .. self.commandID, data)
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
                title = i18n("unit"),
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
        elseif callbackType == "copyControlToAllBanks" then
            --------------------------------------------------------------------------------
            -- Copy Control to All Banks:
            --------------------------------------------------------------------------------
            local items = self.items()
            local lastDevice = self.lastDevice()

            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]

            local data = items[lastDevice] and items[lastDevice][app] and items[lastDevice][app][bank] and items[lastDevice][app][bank][controlType] and items[lastDevice][app][bank][controlType][bid]

            local suffix = ""
            if bank:sub(-7) == "_LeftFn" then
                suffix = "_LeftFn"
            elseif bank:sub(-8) == "_RightFn" then
                suffix = "_RightFn"
            end

            if data then
                for b=1, mod.numberOfBanks do
                    b = tostring(b) .. suffix

                    if not items[lastDevice][app] then items[lastDevice][app] = {} end
                    if not items[lastDevice][app][b] then items[lastDevice][app][b] = {} end
                    if not items[lastDevice][app][b][controlType] then items[lastDevice][app][b][controlType] = {} end
                    if not items[lastDevice][app][b][controlType][bid] then items[lastDevice][app][b][controlType][bid] = {} end
                    if type(data) == "table" then
                        for i, v in pairs(data) do
                            items[lastDevice][app][b][controlType][bid][i] = v
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Generate an Encoded Icon Label if needed:
                    --------------------------------------------------------------------------------
                    local value = items[lastDevice][app][b][controlType][bid].iconLabel
                    if value then
                        local encodedImg = self:buildIconFromLabel(params)
                        items[lastDevice][app][b][controlType][bid].encodedIconLabel = encodedImg
                    end
                end
            end
            self.items(items)

            --------------------------------------------------------------------------------
            -- Update Knob Images:
            --------------------------------------------------------------------------------
            if controlType == "knob" then
                for b=1, mod.numberOfBanks do
                    b = tostring(b) .. suffix
                    self:generateKnobImages(app, b, bid)
                end
            end
        elseif callbackType == "resetControl" then
            --------------------------------------------------------------------------------
            -- Reset Control:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]

            local items = self.items()
            local lastDevice = self.lastDevice()

            if items[lastDevice][app] and items[lastDevice][app][bank] and items[lastDevice][app][bank][controlType] and items[lastDevice][app][bank][controlType][bid] then
                items[lastDevice][app][bank][controlType][bid] = nil
            end

            self.items(items)

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            self:updateUI(params)

            self:refreshDevice()
        elseif callbackType == "resetEverything" then
            --------------------------------------------------------------------------------
            -- Reset Everything:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    self.device:reset()
                    mod._manager.refresh()
                    self:refreshDevice()
                end
            end, i18n(self.resetCommandID .. "ResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetApplication" then
            --------------------------------------------------------------------------------
            -- Reset Application:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local items = self.items()
                    local lastDevice = self.lastDevice()
                    local app = self.lastApplication()

                    local defaultLayout = self.device.defaultLayout

                    if not items[lastDevice] then
                        items[lastDevice] = {}
                    end

                    items[lastDevice][app] = defaultLayout and defaultLayout[lastDevice][app] or {}

                    self.items(items)
                    mod._manager.refresh()

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware:
                    --------------------------------------------------------------------------------
                    self:refreshDevice()
                end
            end, i18n(self.resetCommandID .. "ResetApplicationConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetBank" then
            --------------------------------------------------------------------------------
            -- Reset Bank:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local items = self.items()
                    local lastDevice = self.lastDevice()
                    local app = self.lastApplication()
                    local bank = self.lastBank()

                    local defaultLayout = self.device.defaultLayout

                    if items[lastDevice] and items[lastDevice][app] and items[lastDevice][app][bank] then
                        items[lastDevice][app][bank] = defaultLayout and defaultLayout[lastDevice][app] and defaultLayout[lastDevice][app][bank] or {}
                    end
                    self.items(items)
                    mod._manager.refresh()

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware:
                    --------------------------------------------------------------------------------
                    self:refreshDevice()
                end
            end, i18n(self.resetCommandID .. "ResetBankConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "copyUnit" then

            --------------------------------------------------------------------------------
            -- Copy Unit:
            --------------------------------------------------------------------------------
            local numberOfUnits = mod._deviceManager.NUMBER_OF_DEVICES

            local copyToUnit = function(destinationUnit)
                local items = self.items()
                local lastDevice = self.lastDevice()
                local data = items[lastDevice]
                if data then
                    items[destinationUnit] = fnutils.copy(data)
                    self.items(items)
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

            for i=1, numberOfUnits do
                table.insert(menu, {
                    title = tostring(i),
                    fn = function() copyToUnit(tostring(i)) end
                })
            end

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "copyApplication" then
            --------------------------------------------------------------------------------
            -- Copy Application:
            --------------------------------------------------------------------------------
            local copyApplication = function(destinationApp)
                local items = self.items()
                local lastDevice = self.lastDevice()
                local app = self.lastApplication()

                local data = items[lastDevice] and items[lastDevice][app]
                if data then
                    if not items[lastDevice] then
                        items[lastDevice] = {}
                    end
                    --------------------------------------------------------------------------------
                    -- Don't replace the display name:
                    --------------------------------------------------------------------------------
                    local originalDisplayName = items[lastDevice][destinationApp].displayName
                    items[lastDevice][destinationApp] = fnutils.copy(data)
                    items[lastDevice][destinationApp].displayName = originalDisplayName

                    self.items(items)
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
            local items = self.items()
            for _, device in pairs(items) do
                for bundleID, v in pairs(device) do
                    if v.displayName then
                        userApps[bundleID] = v.displayName
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
            local app = params["application"]
            local ignore = params["ignore"]

            local items = self.items()
            local lastDevice = self.lastDevice()

            if not items[lastDevice] then
                items[lastDevice] = {}
            end

            if not items[lastDevice][app] then
                items[lastDevice][app] = {}
            end

            items[lastDevice][app]["ignore"] = ignore

            self.items(items)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()

        elseif callbackType == "changeRepeatPressActionUntilReleased" then
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local repeatPressActionUntilReleased = params["repeatPressActionUntilReleased"]

            self:setItem(app, bank, controlType, bid, "repeatPressActionUntilReleased", repeatPressActionUntilReleased)
        elseif callbackType == "copyBank" then
            --------------------------------------------------------------------------------
            -- Copy Bank:
            --------------------------------------------------------------------------------
            local numberOfBanks = mod.numberOfBanks

            local copyToBank = function(destinationBank)
                local items = self.items()
                local lastDevice = self.lastDevice()

                local app = self.lastApplication()
                local bank = self.lastBank()

                local data = items[lastDevice] and items[lastDevice][app] and items[lastDevice][app][bank]
                if data then
                    items[lastDevice][app][destinationBank] = fnutils.copy(data)
                    self.items(items)
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
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "dropAndDrop" then
            --------------------------------------------------------------------------------
            -- Drag & Drop:
            --------------------------------------------------------------------------------
            local translateID = function(v)
                local controlType
                local bid
                if string.sub(v, 1, 4) == "knob" then
                    controlType = "knob"
                    bid = string.sub(v, 5)
                elseif string.sub(v, 1, 9) == "ledButton" then
                    controlType = "ledButton"
                    bid = string.sub(v, 10)
                elseif string.sub(v, 1, 10) == "sideScreen" then
                    controlType = "sideScreen"
                    bid = string.sub(v, 11)
                elseif string.sub(v, 1, 11) == "touchButton" then
                    controlType = "touchButton"
                    bid = string.sub(v, 12)
                elseif string.sub(v, 1, 11) == "wheelScreen" then
                    controlType = "wheelScreen"
                    bid = string.sub(v, 12)
                end
                return controlType, bid
            end

            local app = params["application"]
            local bank = params["bank"]

            local source = params["source"]
            local destination = params["destination"]

            local sourceControlType, sourceID = translateID(source)
            local destinationControlType, destinationID = translateID(destination)

            --------------------------------------------------------------------------------
            -- You can only drag items of the same control type:
            --------------------------------------------------------------------------------
            if sourceControlType ~= destinationControlType then
                webviewAlert(mod._manager.getWebview(), function() end, i18n("youCannotDragItemsBetweenDifferentControlTypes"), i18n("youCannotDragItemsBetweenDifferentControlTypesDescription"), i18n("ok"), nil , "informational")
                return
            end

            --------------------------------------------------------------------------------
            -- Swap controls:
            --------------------------------------------------------------------------------
            local items = self.items()
            local lastDevice = self.lastDevice()

            if not items[lastDevice] then items[lastDevice] = {} end
            if not items[lastDevice][app] then items[lastDevice][app] = {} end
            if not items[lastDevice][app][bank] then items[lastDevice][app][bank] = {} end
            if not items[lastDevice][app][bank][sourceControlType] then items[lastDevice][app][bank][sourceControlType] = {} end
            if not items[lastDevice][app][bank][sourceControlType][sourceID] then items[lastDevice][app][bank][sourceControlType][sourceID] = {} end

            if not items[lastDevice][app][bank][destinationControlType] then items[lastDevice][app][bank][destinationControlType] = {} end
            if not items[lastDevice][app][bank][destinationControlType][destinationID] then items[lastDevice][app][bank][destinationControlType][destinationID] = {} end

            local a = copy(items[lastDevice][app][bank][destinationControlType][destinationID])
            local b = copy(items[lastDevice][app][bank][sourceControlType][sourceID])

            items[lastDevice][app][bank][sourceControlType][sourceID] = a
            items[lastDevice][app][bank][destinationControlType][destinationID] = b

            self.items(items)

            --------------------------------------------------------------------------------
            -- Generate Knob Images (if required):
            --------------------------------------------------------------------------------
            if sourceControlType == "knob" or destinationControlType == "knob" then
                if sourceID == "1" or sourceID == "2" or sourceID == "3" or destinationID == "1" or destinationID == "2" or destinationID == "3" then
                    self:generateKnobImages(app, bank, "1")
                end
                if sourceID == "4" or sourceID == "5" or sourceID == "6" or destinationID == "4" or destinationID == "5" or destinationID == "6" then
                    self:generateKnobImages(app, bank, "4")
                end
            end

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            self:updateUI()

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "showContextMenu" then
            --------------------------------------------------------------------------------
            -- Show Context Menu:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]

            local items = self.items()
            local lastDevice = self.lastDevice()

            local pasteboard = self.pasteboard()

            local pasteboardContents = pasteboard[controlType]

            local menu = {}

            table.insert(menu, {
                title = i18n("copy"),
                fn = function()
                    --------------------------------------------------------------------------------
                    -- Copy:
                    --------------------------------------------------------------------------------
                    if items[lastDevice] and items[lastDevice][app] and items[lastDevice][app][bank] and items[lastDevice][app][bank][controlType] and items[lastDevice][app][bank][controlType][bid] then
                        pasteboard[controlType] = copy(items[lastDevice][app][bank][controlType][bid])
                        self.pasteboard(pasteboard)
                    end
                end
            })

            table.insert(menu, {
                title = i18n("paste"),
                disabled = not pasteboardContents,
                fn = function()
                    --------------------------------------------------------------------------------
                    -- Paste:
                    --------------------------------------------------------------------------------
                    if not items[lastDevice][app] then items[lastDevice][app] = {} end
                    if not items[lastDevice][app][bank] then items[lastDevice][app][bank] = {} end
                    if not items[lastDevice][app][bank][controlType] then items[lastDevice][app][bank][controlType] = {} end

                    items[lastDevice][app][bank][controlType][bid] = copy(pasteboardContents)

                    self.items(items)

                    self:updateUI()

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware:
                    --------------------------------------------------------------------------------
                    self:refreshDevice()
                end
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.absolutePosition(), true)
        elseif callbackType == "openKeyCreator" then
            --------------------------------------------------------------------------------
            -- Open Key Creator:
            --------------------------------------------------------------------------------
            execute('open "' .. KEY_CREATOR_URL .. '"')
        elseif callbackType == "buyMoreIcons" then
            --------------------------------------------------------------------------------
            -- Buy More Icons:
            --------------------------------------------------------------------------------
            execute('open "' .. BUY_MORE_ICONS_URL .. '"')
        elseif callbackType == "openIconFolder" then
            --------------------------------------------------------------------------------
            -- Open Icon Folder:
            --------------------------------------------------------------------------------
            execute('open "' .. config.basePath .. '/extensions/cp/resources/assets/icons/"')
        elseif callbackType == "editSnippet" then
            --------------------------------------------------------------------------------
            -- Edit Snippet:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local actionType = params["actionType"]

            local items = self.items()
            local lastDevice = self.lastDevice()

            if items[lastDevice] and items[lastDevice][app] and items[lastDevice][app][bank] and items[lastDevice][app][bank][controlType] and items[lastDevice][app][bank][controlType][bid] then
                local snippetAction = items[lastDevice][app][bank][controlType][bid][actionType]
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
        elseif callbackType == "examples" then
            --------------------------------------------------------------------------------
            -- Examples Button:
            --------------------------------------------------------------------------------
            execute('open "' .. SNIPPET_HELP_URL .. '"')
        elseif callbackType == "ledExamples" then
            --------------------------------------------------------------------------------
            -- Examples Button:
            --------------------------------------------------------------------------------
            execute('open "' .. SNIPPET_LED_HELP_URL .. '"')
        elseif callbackType == "updateFontSize" then
            --------------------------------------------------------------------------------
            -- Update Font Size:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "fontSize", value)

            --------------------------------------------------------------------------------
            -- Update encoded icon label:
            --------------------------------------------------------------------------------
            local encodedImg = ""
            if value and trim(value) ~= "" then
                encodedImg = self:buildIconFromLabel(params)
            end

            self:setItem(app, bank, controlType, bid, "encodedIconLabel", encodedImg)

            --------------------------------------------------------------------------------
            -- Process knobs:
            --------------------------------------------------------------------------------
            if controlType == "knob" then
                self:generateKnobImages(app, bank, bid)
            end

            --------------------------------------------------------------------------------
            -- Change the control and update the UI:
            --------------------------------------------------------------------------------
            changeControl(controlType, bid)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        elseif callbackType == "selectFont" then
            --------------------------------------------------------------------------------
            -- Select a font:
            --------------------------------------------------------------------------------
            if not self.fontChooser then

                local completionFn = function(result)
                    if result then
                        local value = result.id

                        local app = params["application"]
                        local bank = params["bank"]
                        local controlType = params["controlType"]
                        local bid = params["id"]

                        self:setItem(app, bank, controlType, bid, "font", value)

                        --------------------------------------------------------------------------------
                        -- Update encoded icon label:
                        --------------------------------------------------------------------------------
                        local encodedImg = ""
                        if value and trim(value) ~= "" then
                            encodedImg = self:buildIconFromLabel(params)
                        end

                        self:setItem(app, bank, controlType, bid, "encodedIconLabel", encodedImg)

                        --------------------------------------------------------------------------------
                        -- Process knobs:
                        --------------------------------------------------------------------------------
                        if controlType == "knob" then
                            self:generateKnobImages(app, bank, bid)
                        end

                        --------------------------------------------------------------------------------
                        -- Change the control and update the UI:
                        --------------------------------------------------------------------------------
                        changeControl(controlType, bid)

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        self:refreshDevice()
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

                self.fontChooser = chooser.new(completionFn)
                    :bgDark(true)
                    :choices(choices)
            end

            self.fontChooser:show()

        elseif callbackType == "updateFontColor" then
            --------------------------------------------------------------------------------
            -- Update Font Color:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "fontColor", value)

            --------------------------------------------------------------------------------
            -- Update encoded icon label:
            --------------------------------------------------------------------------------
            local encodedImg = ""
            if value and trim(value) ~= "" then
                encodedImg = self:buildIconFromLabel(params)
            end

            self:setItem(app, bank, controlType, bid, "encodedIconLabel", encodedImg)

            --------------------------------------------------------------------------------
            -- Process knobs:
            --------------------------------------------------------------------------------
            if controlType == "knob" then
                self:generateKnobImages(app, bank, bid)
            end

            --------------------------------------------------------------------------------
            -- Change the control and update the UI:
            --------------------------------------------------------------------------------
            changeControl(controlType, bid)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self:refreshDevice()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Loupedeck Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "core.loupedeckctandlive.prefs",
    group           = "core",
    dependencies    = {
        ["core.action.manager"]                 = "actionmanager",
        ["core.application.manager"]            = "appmanager",
        ["core.controlsurfaces.manager"]        = "manager",
        ["core.loupedeckctandlive.manager"]     = "deviceManager",
        ["core.preferences.panels.scripting"]   = "scriptingPreferences",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._appmanager             = deps.appmanager

    mod._deviceManager          = deps.deviceManager

    mod._manager                = deps.manager
    mod._webviewLabel           = deps.manager.getLabel()
    mod.numberOfBanks           = deps.manager.NUMBER_OF_BANKS

    mod._actionmanager          = deps.actionmanager

    mod._scriptingPreferences   = deps.scriptingPreferences

    mod._env                    = env

    --------------------------------------------------------------------------------
    -- Setup the seperate panels:
    --------------------------------------------------------------------------------
    mod.panels                              = {}
    mod.panels.CT                           = mod.new(loupedeck.deviceTypes.CT)
    mod.panels.LIVE                         = mod.new(loupedeck.deviceTypes.LIVE)
    mod.panels.LIVE_S                       = mod.new(loupedeck.deviceTypes.LIVE_S)
    mod.panels.RAZER_STREAM_CONTROLLER      = mod.new(loupedeck.deviceTypes.RAZER_STREAM_CONTROLLER)

    return mod
end

return plugin
