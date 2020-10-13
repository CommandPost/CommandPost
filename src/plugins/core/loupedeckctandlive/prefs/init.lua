--- === plugins.core.loupedeckctandlive.prefs ===
---
--- Loupedeck CT & Loupedeck Live Preferences Panels

local require                   = require

local log                       = require "hs.logger".new "prefsLoupedeckCT"

local application               = require "hs.application"
local canvas                    = require "hs.canvas"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local loupedeck                 = require "hs.loupedeck"
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
local getFilenameFromPath       = tools.getFilenameFromPath
local imageFromPath             = image.imageFromPath
local imageFromURL              = image.imageFromURL
local infoForBundlePath         = application.infoForBundlePath
local mergeTable                = tools.mergeTable
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

-- KEY_CREATOR_URL -> string
-- Constant
-- URL to Key Creator Website
local KEY_CREATOR_URL = "https://www.elgato.com/en/gaming/keycreator"

-- BUY_MORE_ICONS_URL -> string
-- Constant
-- URL to SideshowFX Website
local BUY_MORE_ICONS_URL = "http://www.sideshowfx.net/buy"

--- plugins.core.loupedeckctandlive.prefs.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

--- plugins.core.loupedeckctandlive.prefs.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = config.assetsPath .. "/icons/"

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
        o.height            = 1055
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
        o.height            = 1020
    else
        log.ef("Invalid Loupedeck Device Type: %s", deviceType)
        return
    end

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
    o.lastApplication = config.prop(o.id .. ".preferences.lastApplication", "All Applications")

    --- plugins.core.loupedeckctandlive.prefs.lastApplication <cp.prop: string>
    --- Field
    --- Last Bank used in the Preferences Panel.
    o.lastBank = config.prop(o.id .. ".preferences.lastBank", "1")

    --- plugins.core.loupedeckctandlive.prefs.lastSelectedControl <cp.prop: string>
    --- Field
    --- Last Selected Control used in the Preferences Panel.
    o.lastSelectedControl = config.prop(o.id .. ".preferences.lastSelectedControl", "1")

    --- plugins.core.loupedeckctandlive.prefs.lastID <cp.prop: string>
    --- Field
    --- Last Selected Control ID used in the Preferences Panel.
    o.lastID = config.prop(o.id .. ".preferences.lastID", "7")

    --- plugins.core.loupedeckctandlive.prefs.lastControlType <cp.prop: string>
    --- Field
    --- Last Selected Control Type used in the Preferences Panel.
    o.lastControlType = config.prop(o.id .. ".preferences.lastControlType", "ledButton")

    o.loupedeck                           = o.device.device
    o.items                               = o.device.items
    o.enabled                             = o.device.enabled
    o.loadSettingsFromDevice              = o.device.loadSettingsFromDevice
    o.enableFlashDrive                    = o.device.enableFlashDrive
    o.automaticallySwitchApplications     = o.device.automaticallySwitchApplications
    o.screensBacklightLevel               = o.device.screensBacklightLevel

    --------------------------------------------------------------------------------
    -- Watch for Loupedeck CT connections and disconnects:
    --------------------------------------------------------------------------------
    o.device.connected:watch(function(connected)
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
        priority        = o.priority,
        id              = o.id,
        label           = o.label,
        image           = imageFromPath(mod._env:pathToAbsolute("/images/loupedeck.icns")),
        tooltip         = o.label,
        height          = o.height,
    })
        :addHeading(6, o.label)

        :addCheckbox(7.1,
            {
                label       = i18n("enable" .. o.commandID .. "Support"),
                checked     = o.enabled,
                onchange    = function(_, params)
                    o.enabled(params.checked)
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
                                    o.device:refresh()
                                else
                                    manager.injectScript("changeCheckedByID('storeSettingsOnFlashDrive', false);")
                                end
                            end, i18n("areYouSureYouWantToStoreYourSettingsOnThe" .. o.commandID .. "FlashDrive"), i18n("areYouSureYouWantToStoreYourSettingsOnThe" .. o.commandID .. "FlashDriveDescription"), i18n("ok"), i18n("cancel"), "warning")
                        else
                            o.loadSettingsFromDevice(params.checked)
                            mod._manager.refresh()
                            o.device:refresh()
                        end
                    end,
                }
            )
    end

    o.panel
        :addCheckbox(10,
            {
                label       = i18n("automaticallySwitchApplications"),
                checked     = o.automaticallySwitchApplications,
                onchange    = function(_, params)
                    o.automaticallySwitchApplications(params.checked)
                end,
            }
        )


        :addSelect(11,
            {
                label       =   i18n("screensBacklightLevel"),
                value       =   o.screensBacklightLevel,
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
                                    o.loupedeck:updateBacklightLevel(tonumber(params.value))
                                end,
            }
        )


        :addParagraph(12, html.span {class="tip"} (html(i18n("loupedeckAppTip"), false) ) .. "\n\n")

        :addContent(13, function(...) return o:generateContent(...) end, false)

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

        lastApplication             = self.lastApplication(),
        lastBank                    = self.lastBank(),

        lastSelectedControl         = self.lastSelectedControl(),
        lastID                      = self.lastID(),
        lastControlType             = self.lastControlType(),

        insertImage                 = insertImage,

        vibrationIndex              = loupedeck.vibrationIndex,
        wheelSensitivityIndex       = loupedeck.wheelSensitivityIndex,

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

    if type(items[app]) ~= "table" then items[app] = {} end
    if type(items[app][bank]) ~= "table" then items[app][bank] = {} end
    if type(items[app][bank][controlType]) ~= "table" then items[app][bank][controlType] = {} end
    if type(items[app][bank][controlType][id]) ~= "table" then items[app][bank][controlType][id] = {} end

    if type(valueB) ~= "nil" then
        if not items[app][bank][controlType][id][valueA] then items[app][bank][controlType][id][valueA] = {} end
        items[app][bank][controlType][id][valueA] = valueB
    else
        items[app][bank][controlType][id] = valueA
    end

    self.items(items)
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

--- plugins.core.loupedeckctandlive.prefs:generateKnobImages(app, bank, id) -> none
--- Method
--- Generates a combined image for all the knobs.
---
--- Parameters:
---  * app - The application bundle ID
---  * bank - The bank as a string
---  * id - The ID
---
--- Returns:
---  * None
function mod.mt:generateKnobImages(app, bank, bid)
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

    local items = self.items()

    local selectedApp = items[app]

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
    local colorValue = selectedID and selectedID.led or "FFFFFF"
    local encodedIcon = selectedID and selectedID.encodedIcon or ""
    local iconLabel = selectedID and selectedID.iconLabel or ""

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
        if self.id == "loupedeckct" then
            local wheelScreen = selectedBank and selectedBank.wheelScreen and selectedBank.wheelScreen["1"]
            if wheelScreen and wheelScreen.encodedIcon and wheelScreen.encodedIcon ~= "" then
                updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. wheelScreen.encodedIcon .. [[")]] .. "\n"
            else
                updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. insertImage("images/wheelScreen1.png") .. [[")]] .. "\n"
            end
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
        if self.id == "loupedeckct" then
            updateIconsScript = updateIconsScript .. [[changeImage("wheelScreen1", "]] .. insertImage("images/wheelScreen1.png") .. [[")]] .. "\n"
        end
    end

    --------------------------------------------------------------------------------
    -- Update UI on whether connected or not:
    --------------------------------------------------------------------------------
    local loadSettingsFromDevice = self.device.loadSettingsFromDevice()
    local connected = self.device.connected()
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
        changeValueByID('vibratePress', ']] .. vibratePressValue .. [[');
        changeValueByID('vibrateRelease', ']] .. vibrateReleaseValue .. [[');
        changeValueByID('vibrateLeft', ']] .. vibrateLeftValue .. [[');
        changeValueByID('vibrateRight', ']] .. vibrateRightValue .. [[');
        changeValueByID('wheelSensitivity', ']] .. wheelSensitivityValue .. [[');
        changeValueByID('iconLabel', `]] .. iconLabel .. [[`);
        changeCheckedByID('ignore', ]] .. tostring(ignoreValue) .. [[);
        changeCheckedByID('repeatPressActionUntilReleased', ]] .. tostring(repeatPressActionUntilReleasedValue) .. [[);
        changeColor(']] .. colorValue .. [[');
        setIcon("]] .. encodedIcon .. [[");
    ]] .. updateIconsScript .. "\n" .. connectedScript .. "\n" .. "updateIgnoreVisibility();")
end

--- plugins.core.loupedeckctandlive.prefs:panelCallback() -> none
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
        if callbackType == "updateAction" then
            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            local activatorID = params["application"]
            if not self.activator or self.activator and not self.activator[activatorID] then
                self.activator = {}
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
                local items = self.items()
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
                    self.activator[groupID] = mod._actionmanager.getActivator("loupedeckCTPreferences" .. groupID)

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
                    self.activator[groupID]:allowHandlers(unpack(allowedHandlers))

                    --------------------------------------------------------------------------------
                    -- Gather Toolbar Icons for Search Console:
                    --------------------------------------------------------------------------------
                    local defaultSearchConsoleToolbar = mod._appmanager.defaultSearchConsoleToolbar()
                    local appSearchConsoleToolbar = mod._appmanager.getSearchConsoleToolbar(groupID) or {}
                    local searchConsoleToolbar = mergeTable(defaultSearchConsoleToolbar, appSearchConsoleToolbar)
                    self.activator[groupID]:toolbarIcons(searchConsoleToolbar)
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

                self:setItem(app, bank, controlType, bid, buttonType, result)

                --------------------------------------------------------------------------------
                -- Update the webview:
                --------------------------------------------------------------------------------
                if params["buttonType"] == "pressAction" then
                    injectScript("changeValueByID('press_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "releaseAction" then
                    injectScript("changeValueByID('release_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "leftAction" then
                    injectScript("changeValueByID('left_action', `" .. escapeTilda(actionTitle) .. "`);")
                    injectScript("changeValueByID('left_touch_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "rightAction" then
                    injectScript("changeValueByID('right_action', `" .. escapeTilda(actionTitle) .. "`);")
                    injectScript("changeValueByID('right_touch_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "upAction" then
                    injectScript("changeValueByID('up_touch_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "downAction" then
                    injectScript("changeValueByID('down_touch_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "doubleTapAction" then
                    injectScript("changeValueByID('double_tap_touch_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "twoFingerTapAction" then
                    injectScript("changeValueByID('two_finger_touch_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "topLeftAction" then
                    injectScript("changeValueByID('top_left_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "bottomLeftAction" then
                    injectScript("changeValueByID('bottom_left_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "topMiddleAction" then
                    injectScript("changeValueByID('top_middle_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "bottomMiddleAction" then
                    injectScript("changeValueByID('bottom_middle_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "topRightAction" then
                    injectScript("changeValueByID('top_right_action', `" .. escapeTilda(actionTitle) .. "`);")
                elseif params["buttonType"] == "bottomRightAction" then
                    injectScript("changeValueByID('bottom_right_action', `" .. escapeTilda(actionTitle) .. "`);")
                end
            end)

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
            -- Update the UI:
            --------------------------------------------------------------------------------
            self:updateUI(params)
        elseif callbackType == "updateApplicationAndBank" then
            local app = params["application"]
            local bank = params["bank"]

            if app == "Add Application" then
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
                self.device:refresh()
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
            self.device:refresh()
        elseif callbackType == "updateBankLabel" then
            --------------------------------------------------------------------------------
            -- Update Bank Label:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]

            local items = self.items()

            if not items[app] then items[app] = {} end
            if not items[app][bank] then items[app][bank] = {} end
            items[app][bank]["bankLabel"] = params["bankLabel"]

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
            self.device:refresh()
        elseif callbackType == "iconClicked" then
            --------------------------------------------------------------------------------
            -- Icon Clicked:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(self.lastIconPath()) then
                self.lastIconPath(self.defaultIconPath())
            end

            local result = dialog.chooseFileOrFolder(i18n("pleaseSelectAnIcon"), self.lastIconPath(), true, false, false, mod.supportedExtensions, true)
            local failed = false
            if result and result["1"] then
                local path = result["1"]

                --------------------------------------------------------------------------------
                -- Save path for next time:
                --------------------------------------------------------------------------------
                self.lastIconPath(removeFilenameFromPath(path))

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

                        self:setItem(app, bank, controlType, bid, "encodedIcon", newEncodedIcon)

                        local changeImageScript = [[changeImage("]] .. controlType .. bid .. [[", "]] .. newEncodedIcon .. [[")]]

                        --------------------------------------------------------------------------------
                        -- Process knobs:
                        --------------------------------------------------------------------------------
                        if controlType == "knob" then

                            self:generateKnobImages(app, bank, bid)

                            --------------------------------------------------------------------------------
                            -- Update preferences UI:
                            --------------------------------------------------------------------------------
                            local items = self.items()

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
                        local iconHistory = self.iconHistory()

                        while (#(iconHistory) >= 5) do
                            table.remove(iconHistory,1)
                        end

                        local filename = getFilenameFromPath(path, true)

                        table.insert(iconHistory, {filename, newEncodedIcon})

                        self.iconHistory(iconHistory)

                        --------------------------------------------------------------------------------
                        -- Refresh the hardware:
                        --------------------------------------------------------------------------------
                        self.device:refresh()
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

            self:setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self.device:refresh()
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

            self:setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self.device:refresh()
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

            self:setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self.device:refresh()
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
            self:setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self.device:refresh()
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
            self:setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

            --------------------------------------------------------------------------------
            -- Generate Knob Images:
            --------------------------------------------------------------------------------
            self:generateKnobImages(app, bank, bid)

            --------------------------------------------------------------------------------
            -- Update Preferences Screen:
            --------------------------------------------------------------------------------
            local items = self.items()
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
            self.device:refresh()
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

                                self:setItem(app, bank, controlType, bid, "encodedIcon", fixedEncodedIcon)

                                local changeImageScript = [[changeImage("]] .. controlType .. bid .. [[", "]] .. fixedEncodedIcon .. [[")]]

                                --------------------------------------------------------------------------------
                                -- Process knobs:
                                --------------------------------------------------------------------------------
                                if controlType == "knob" then

                                    self:generateKnobImages(app, bank, bid)

                                    --------------------------------------------------------------------------------
                                    -- Update preferences UI:
                                    --------------------------------------------------------------------------------
                                    local items = self.items()

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

                                self.device:refresh()
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

            self:setItem(app, bank, controlType, bid, "encodedIcon", "")

            local items = self.items()
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

                self:generateKnobImages(app, bank, bid)

                --------------------------------------------------------------------------------
                -- Update preferences UI:
                --------------------------------------------------------------------------------
                items = self.items() -- Refresh items

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
            self.device:refresh()
        elseif callbackType == "updateIconLabel" then
            --------------------------------------------------------------------------------
            -- Write to file:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]
            local value = params["value"]

            self:setItem(app, bank, controlType, bid, "iconLabel", value)

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

            self:setItem(app, bank, controlType, bid, "encodedIconLabel", encodedImg)

            local items = self.items()

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
                self:generateKnobImages(app, bank, bid)

                --------------------------------------------------------------------------------
                -- Refresh Items:
                --------------------------------------------------------------------------------
                items = self.items()
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

            self.device:refresh()
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
                        if action == "replace" then
                            self.items(data)
                        elseif action == "merge" then
                            local original = self.items()
                            local combined = mergeTable(original, data)
                            self.items(combined)
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
                local items = self.items()
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
            local items = self.items()

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
                for b=1, mod.numberOfBanks do
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

                    --------------------------------------------------------------------------------
                    -- Generate an Encoded Icon Label if needed:
                    --------------------------------------------------------------------------------
                    local value = items[app][b][controlType][bid].iconLabel
                    if value then
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
                        local encodedImg = img:encodeAsURLString(true)

                        items[app][b][controlType][bid].encodedIconLabel = encodedImg
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

            if items[app] and items[app][bank] and items[app][bank][controlType] and items[app][bank][controlType][bid] then
                items[app][bank][controlType][bid] = nil
            end

            self.items(items)

            --------------------------------------------------------------------------------
            -- Update the UI:
            --------------------------------------------------------------------------------
            self:updateUI(params)

            self.device:refresh()
        elseif callbackType == "resetEverything" then
            --------------------------------------------------------------------------------
            -- Reset Everything:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    self.device:reset()
                    mod._manager.refresh()
                    self.device:refresh()
                end
            end, i18n("loupedeckCTResetAllConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetApplication" then
            --------------------------------------------------------------------------------
            -- Reset Application:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local items = self.items()
                    local app = self.lastApplication()

                    local defaultLayout = self.device.defaultLayout
                    items[app] = defaultLayout and defaultLayout[app] or {}

                    self.items(items)
                    mod._manager.refresh()

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware:
                    --------------------------------------------------------------------------------
                    self.device:refresh()
                end
            end, i18n("loupedeckCTResetApplicationConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "resetBank" then
            --------------------------------------------------------------------------------
            -- Reset Bank:
            --------------------------------------------------------------------------------
            webviewAlert(mod._manager.getWebview(), function(result)
                if result == i18n("yes") then
                    local items = self.items()
                    local app = self.lastApplication()
                    local bank = self.lastBank()

                    local defaultLayout = self.device.defaultLayout

                    if items[app] and items[app][bank] then
                        items[app][bank] = defaultLayout and defaultLayout[app] and defaultLayout[app][bank] or {}
                    end
                    self.items(items)
                    mod._manager.refresh()

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware:
                    --------------------------------------------------------------------------------
                    self.device:refresh()
                end
            end, i18n("loupedeckCTResetBankConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
        elseif callbackType == "copyApplication" then
            --------------------------------------------------------------------------------
            -- Copy Application:
            --------------------------------------------------------------------------------
            local copyApplication = function(destinationApp)
                local items = self.items()
                local app = self.lastApplication()

                local data = items[app]
                if data then
                    items[destinationApp] = fnutils.copy(data)
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

            local items = self.items()

            if not items[app] then items[app] = {} end
            items[app]["ignore"] = ignore

            self.items(items)

            --------------------------------------------------------------------------------
            -- Refresh the hardware:
            --------------------------------------------------------------------------------
            self.device:refresh()

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
                local app = self.lastApplication()
                local bank = self.lastBank()

                local data = items[app] and items[app][bank]
                if data then
                    items[app][destinationBank] = fnutils.copy(data)
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
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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

            if not items[app] then items[app] = {} end
            if not items[app][bank] then items[app][bank] = {} end
            if not items[app][bank][sourceControlType] then items[app][bank][sourceControlType] = {} end
            if not items[app][bank][sourceControlType][sourceID] then items[app][bank][sourceControlType][sourceID] = {} end

            if not items[app][bank][destinationControlType] then items[app][bank][destinationControlType] = {} end
            if not items[app][bank][destinationControlType][destinationID] then items[app][bank][destinationControlType][destinationID] = {} end

            local a = copy(items[app][bank][destinationControlType][destinationID])
            local b = copy(items[app][bank][sourceControlType][sourceID])

            items[app][bank][sourceControlType][sourceID] = a
            items[app][bank][destinationControlType][destinationID] = b

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
            self.device:refresh()
        elseif callbackType == "showContextMenu" then
            --------------------------------------------------------------------------------
            -- Show Context Menu:
            --------------------------------------------------------------------------------
            local app = params["application"]
            local bank = params["bank"]
            local controlType = params["controlType"]
            local bid = params["id"]

            local items = self.items()
            local pasteboard = self.pasteboard()

            local pasteboardContents = pasteboard[controlType]

            local menu = {}

            table.insert(menu, {
                title = i18n("copy"),
                fn = function()
                    --------------------------------------------------------------------------------
                    -- Copy:
                    --------------------------------------------------------------------------------
                    if items[app] and items[app][bank] and items[app][bank][controlType] and items[app][bank][controlType][bid] then
                        pasteboard[controlType] = copy(items[app][bank][controlType][bid])
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
                    if not items[app] then items[app] = {} end
                    if not items[app][bank] then items[app][bank] = {} end
                    if not items[app][bank][controlType] then items[app][bank][controlType] = {} end

                    items[app][bank][controlType][bid] = copy(pasteboardContents)

                    self.items(items)

                    self:updateUI()

                    --------------------------------------------------------------------------------
                    -- Refresh the hardware:
                    --------------------------------------------------------------------------------
                    self.device:refresh()
                end
            })

            local popup = menubar.new()
            popup:setMenu(menu):removeFromMenuBar()
            popup:popupMenu(mouse.getAbsolutePosition(), true)
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
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._appmanager     = deps.appmanager

    mod._deviceManager  = deps.deviceManager

    mod._manager        = deps.manager
    mod._webviewLabel   = deps.manager.getLabel()
    mod.numberOfBanks   = deps.manager.NUMBER_OF_BANKS

    mod._actionmanager  = deps.actionmanager

    mod._env            = env

    --------------------------------------------------------------------------------
    -- Setup the seperate panels:
    --------------------------------------------------------------------------------
    mod.panels          = {}
    mod.panels.CT       = mod.new(loupedeck.deviceTypes.CT)
    mod.panels.LIVE     = mod.new(loupedeck.deviceTypes.LIVE)

    return mod
end

return plugin
