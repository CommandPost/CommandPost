--- === plugins.core.loupedeckctandlive.manager ===
---
--- Manager Plugin for Loupedeck CT, Loupedeck Live, Loupedeck Live-S and Razer Stream Controller.

local require                   = require

local hs                        = _G.hs

local log                       = require "hs.logger".new "ldCT"

local application               = require "hs.application"
local appWatcher                = require "hs.application.watcher"
local canvas                    = require "hs.canvas"
local colorExtension            = require "hs.drawing.color"
local eventtap                  = require "hs.eventtap"
local fnutils                   = require "hs.fnutils"
local fs                        = require "hs.fs"
local image                     = require "hs.image"
local loupedeck                 = require "hs.loupedeck"
local plist                     = require "hs.plist"
local sleepWatcher              = require "hs.caffeinate.watcher"
local timer                     = require "hs.timer"
local usb                       = require "hs.usb"

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local prop                      = require "cp.prop"
local tools                     = require "cp.tools"

local applicationsForBundleID   = application.applicationsForBundleID
local delayed                   = timer.delayed
local displayNotification       = dialog.displayNotification
local doAfter                   = timer.doAfter
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local doEvery                   = timer.doEvery
local ensureDirectoryExists     = tools.ensureDirectoryExists
local execute                   = hs.execute
local imageFromPath             = image.imageFromPath
local imageFromURL              = image.imageFromURL
local isColor                   = tools.isColor
local isImage                   = tools.isImage
local keyRepeatInterval         = eventtap.keyRepeatInterval
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local readString                = plist.readString
local tableCount                = tools.tableCount

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- plugins.core.loupedeckctandlive.manager.previewSelectedApplicationAndBankOnHardware <cp.prop: boolean>
--- Field
--- Should we preview the selected application and bank on hardware?
mod.previewSelectedApplicationAndBankOnHardware = config.prop("loupedeck.preferences.previewSelectedApplicationAndBankOnHardware", false)

--- plugins.core.loupedeckctandlive.manager.lastApplication <cp.prop: boolean>
--- Field
--- The last application
mod.lastApplication = config.prop("loupedeck.preferences.previewSelectedApplicationAndBankOnHardware.lastApplication", "All Applications")

--- plugins.core.loupedeckctandlive.manager.lastBank <cp.prop: boolean>
--- Field
--- The last bank
mod.lastBank = config.prop("loupedeck.preferences.previewSelectedApplicationAndBankOnHardware.lastBank", "1")

--- plugins.core.loupedeckctandlive.manager.NUMBER_OF_DEVICES -> number
--- Constant
--- The number of devices of the same type supported.
mod.NUMBER_OF_DEVICES = 10

-- LD_BUNDLE_ID -> string
-- Constant
-- The official Loupedeck App bundle identifier.
local LD_BUNDLE_ID = "com.loupedeck.Loupedeck2"

-- defaultColor -> string
-- Variable
-- Default panel color (black)
local defaultColor = "000000"

-- doubleTapTimeout -> number
-- Variable
-- Double Tap Timeout.
local doubleTapTimeout = 0.2

-- dragMinimumDiff -> number
-- Variable
-- Drag minimum difference.
local dragMinimumDiff = 3

-- wheelDoubleTapXTolerance -> number
-- Variable
-- Last Wheel Double Tap X Tolerance
local wheelDoubleTapXTolerance = 12

-- wheelDoubleTapYTolerance -> number
-- Variable
-- Last Wheel Double Tap Y Tolerance
local wheelDoubleTapYTolerance = 7

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
        return 60, 90
    elseif controlType == "sideScreen" then
        return 60, 270
    elseif controlType == "wheelScreen" then
        return 240, 240
    end
end

--- plugins.core.loupedeckctandlive.manager.new() -> Loupedeck
--- Constructor
--- Creates a new Loupedeck object.
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
    setmetatable(o, mod.mt)

    --- plugins.core.loupedeckctandlive.manager.getScreenSizeFromControlType() -> number, number
    --- Function
    --- Converts a controlType to a width and height.
    ---
    --- Parameters:
    ---  * controlType - A string defining the control type.
    ---
    --- Returns:
    ---  * width as a number
    ---  * height as a number
    o.getScreenSizeFromControlType = getScreenSizeFromControlType

    --- plugins.core.loupedeckctandlive.manager.deviceCount -> number
    --- Variable
    --- How many devices are connected?
    o.deviceCount = 0

    --- plugins.core.loupedeckctandlive.manager.getDevices() -> table
    --- Function
    --- Gets a table of Loupedeck devices.
    ---
    --- Parameters:
    ---  * None
    ---
    --- Returns:
    ---  * A table of cached or a new hs.loupedeck objects.
    o.getDevices = function()
        return o.devices or {}
    end

    --- plugins.core.loupedeckctandlive.manager.setupDevicesCount -> number
    --- Variable
    --- A counter for how many times the `setupDevices` function has run.
    o.setupDevicesCount = 0

    --- plugins.core.loupedeckctandlive.manager.setupDevices() -> none
    --- Function
    --- Sets up connected Loupedeck devices.
    ---
    --- Parameters:
    ---  * None
    ---
    --- Returns:
    ---  * None
    o.setupDevices = function()
        --log.df("Setting up " .. deviceType .. " Devices...")

        local devices = loupedeck.findDevices(deviceType)
        local currentDeviceCount = tableCount(devices)

        --log.df("Current Device Count: %s", currentDeviceCount)
        --log.df("Past Device Count: %s", o.deviceCount)

        if currentDeviceCount ~= o.deviceCount and currentDeviceCount > 0 then
            --------------------------------------------------------------------------------
            -- Destroy any devices:
            --------------------------------------------------------------------------------
            --log.df("Destorying any existing devices...")
            local existingDevices = o.getDevices()
            for _, device in pairs(existingDevices) do
                device:disconnect()
            end

            if not o.devices then
                o.devices = {}
            end

            --------------------------------------------------------------------------------
            -- Create new devices:
            --------------------------------------------------------------------------------
            for i=1, currentDeviceCount do
                --log.df("Creating a new " .. deviceType .. " (" .. i .. ")")
                o.devices[i] = loupedeck.new(deviceType, i)
                o.devices[i]:callback(function(...)
                    o:callback(...)
                end)
                o.devices[i]:connect()
            end

            --------------------------------------------------------------------------------
            -- Update the device count:
            --------------------------------------------------------------------------------
            o.deviceCount = currentDeviceCount

            o.setupDevicesCount = 0
        else
            if o.setupDevicesCount == 10 then
                o.setupDevicesCount = 0
            else
                mod.setupRetry = doAfter(1, function()
                    o.setupDevicesCount = o.setupDevicesCount + 1
                    o.setupDevices()
                    mod.setupRetry = nil
                end)
            end
        end
    end

    --- plugins.core.loupedeckctandlive.manager.usbWatcher -> hs.usb.watcher
    --- Variable
    --- USB device watcher.
    o.usbWatcher = usb.watcher.new(function(data)
        if data.productName == deviceType then
            if data.eventType == "added" then
                --log.df(deviceType .. " connected.")
                o.setupDevices()
            elseif data.eventType == "removed" then
                --log.df(deviceType .. " removed from system.")
                o.setupDevices()
            end
        end
    end)

    if deviceType == loupedeck.deviceTypes.CT then
        --------------------------------------------------------------------------------
        -- Loupedeck CT:
        --------------------------------------------------------------------------------
        o.fileExtension     = ".cpLoupedeckCT"
        o.id                = "loupedeckct"
        o.mediaName         = "LD-CT CT Media"
        o.configFolder      = "Loupedeck CT"
        o.commandID         = "LoupedeckCT"
        o.i18nID            = "loupedeckCT"
    elseif deviceType == loupedeck.deviceTypes.LIVE then
        --------------------------------------------------------------------------------
        -- Loupedeck Live:
        --------------------------------------------------------------------------------
        o.fileExtension     = ".cpLoupedeckLive"
        o.id                = "loupedecklive"
        o.configFolder      = "Loupedeck Live"
        o.commandID         = "LoupedeckLive"
        o.i18nID            = "loupedeckLive"
    elseif deviceType == loupedeck.deviceTypes.LIVE_S then
        --------------------------------------------------------------------------------
        -- Loupedeck Live-S:
        --------------------------------------------------------------------------------
        o.fileExtension     = ".cpLoupedeckLiveS"
        o.id                = "loupedecklives"
        o.configFolder      = "Loupedeck Live-S"
        o.commandID         = "LoupedeckLiveS"
        o.i18nID            = "loupedeckLiveS"
    elseif deviceType == loupedeck.deviceTypes.RAZER_STREAM_CONTROLLER then
        --------------------------------------------------------------------------------
        -- Razer Stream Controller:
        --------------------------------------------------------------------------------
        o.fileExtension     = ".cpRazerStreamController"
        o.id                = "razerstreamcontroller"
        o.configFolder      = "Razer Stream Controller"
        o.commandID         = "RazerStreamController"
        o.i18nID            = "razerStreamController"
    else
        log.ef("Invalid Loupedeck Device Type: %s", deviceType)
        return
    end

    --- plugins.core.loupedeckctandlive.manager.defaultFilename -> string
    --- Field
    --- Default filename
    o.defaultFilename = "Multiple Units" .. o.fileExtension

    --- plugins.core.loupedeckctandlive.manager.repeatTimers -> table
    --- Variable
    --- A table containing `hs.timer` objects.
    o.repeatTimers = {}

    --- plugins.core.loupedeckctandlive.manager.items <cp.prop: table>
    --- Field
    --- Contains all the saved Loupedeck layouts.
    o.items = nil

    --- plugins.core.loupedeckctandlive.manager.hasLoaded -> boolean
    --- Variable
    --- Has the Loupedeck loaded?
    o.hasLoaded = {}

    --- plugins.core.loupedeckctandlive.manager.leftFnPressed -> boolean
    --- Variable
    --- Is the left Function button pressed?
    o.leftFnPressed = {}

    --- plugins.core.loupedeckctandlive.manager.rightFnPressed -> boolean
    --- Variable
    --- Is the right Function button pressed?
    o.rightFnPressed = {}

    --- plugins.core.loupedeckctandlive.manager.cachedLEDButtonValues -> table
    --- Variable
    --- Table of cached LED button values.
    o.cachedLEDButtonValues = {}

    --- plugins.core.loupedeckctandlive.manager.cachedTouchScreenButtonValues -> table
    --- Variable
    --- Table of cached Touch Screen button values.
    o.cachedTouchScreenButtonValues = {}

    --- plugins.core.loupedeckctandlive.manager.cachedKnobValues -> table
    --- Variable
    --- Table of cached Knob values.
    o.cachedKnobValues = {}

    --- plugins.core.loupedeckctandlive.manager.cachedWheelScreen -> table
    --- Variable
    --- The last wheel screen data sent per device.
    o.cachedWheelScreen = {}

    --- plugins.core.loupedeckctandlive.manager.cachedLeftSideScreen -> table
    --- Variable
    --- The last screen data sent per device.
    o.cachedLeftSideScreen = {}

    --- plugins.core.loupedeckctandlive.manager.cachedRightSideScreen -> table
    --- Variable
    --- The last screen data sent.
    o.cachedRightSideScreen = {}

    --- plugins.core.loupedeckctandlive.manager.cacheWheelYAxis -> number
    --- Variable
    --- Wheel Y Axis Cache
    o.cacheWheelYAxis = {}

    --- plugins.core.loupedeckctandlive.manager.cacheWheelXAxis -> number
    --- Variable
    --- Wheel X Axis Cache
    o.cacheWheelXAxis = {}

    --- plugins.core.loupedeckctandlive.manager.cacheLeftScreenYAxis -> number
    --- Variable
    --- Right Screen Y Axis Cache
    o.cacheLeftScreenYAxis = {}

    --- plugins.core.loupedeckctandlive.manager.cacheRightScreenYAxis -> number
    --- Variable
    --- Right Screen Y Axis Cache
    o.cacheRightScreenYAxis = {}

    --- plugins.core.loupedeckctandlive.manager.wheelScreenDoubleTapTriggered -> boolean
    --- Variable
    --- Has the wheel screen been tapped once?
    o.wheelScreenDoubleTapTriggered = {}

    --- plugins.core.loupedeckctandlive.manager.leftScreenDoubleTapTriggered -> boolean
    --- Variable
    --- Has the wheel screen been tapped once?
    o.leftScreenDoubleTapTriggered = {}

    --- plugins.core.loupedeckctandlive.manager.rightScreenDoubleTapTriggered -> boolean
    --- Variable
    --- Has the wheel screen been tapped once?
    o.rightScreenDoubleTapTriggered = {}

    --- plugins.core.loupedeckctandlive.manager.tookFingerOffLeftScreen -> boolean
    --- Variable
    --- Took Finger Off Left Screen?
    o.tookFingerOffLeftScreen = {}

    --- plugins.core.loupedeckctandlive.manager.tookFingerOffRightScreen -> boolean
    --- Variable
    --- Took Finger Off Right Screen?
    o.tookFingerOffRightScreen = {}

    --- plugins.core.loupedeckctandlive.manager.tookFingerOffWheelScreen -> boolean
    --- Variable
    --- Took Finger Off Wheel Screen?
    o.tookFingerOffWheelScreen = {}

    --- plugins.core.loupedeckctandlive.manager.lastWheelDoubleTapX -> number
    --- Variable
    --- Last Wheel Double Tap X Position
    o.lastWheelDoubleTapX = {}

    --- plugins.core.loupedeckctandlive.manager.lastWheelDoubleTapY -> number
    --- Variable
    --- Last Wheel Double Tap Y Position
    o.lastWheelDoubleTapY = {}

    --- plugins.core.loupedeckctandlive.manager.connected -> table
    --- Variable
    --- Is the Loupedeck connected?
    o.connected = {}

    --- plugins.core.loupedeckctandlive.manager.refreshTimer -> table
    --- Variable
    --- Refresh Timers
    o.refreshTimer = {}

    --- plugins.core.loupedeckctandlive.manager.cachedBundleID -> table
    --- Variable
    --- Cached Bundle IDs
    o.cachedBundleID = {}

    --- plugins.core.loupedeckctandlive.manager.activeBanks <cp.prop: table>
    --- Field
    --- Table of active banks for each application.
    o.activeBanks = config.prop(o.id .. ".activeBanks", {})

    --------------------------------------------------------------------------------
    -- Setup the defaults for each device:
    --------------------------------------------------------------------------------
    for deviceNumber=1, mod.NUMBER_OF_DEVICES do
        o.hasLoaded[deviceNumber]                       = false
        o.leftFnPressed[deviceNumber]                   = false
        o.rightFnPressed[deviceNumber]                  = false
        o.wheelScreenDoubleTapTriggered[deviceNumber]   = false
        o.leftScreenDoubleTapTriggered[deviceNumber]    = false
        o.rightScreenDoubleTapTriggered[deviceNumber]   = false
        o.tookFingerOffLeftScreen[deviceNumber]         = false
        o.tookFingerOffRightScreen[deviceNumber]        = false
        o.tookFingerOffWheelScreen[deviceNumber]        = false

        o.cacheWheelYAxis[deviceNumber]                 = 0
        o.cacheWheelXAxis[deviceNumber]                 = 0
        o.cacheLeftScreenYAxis[deviceNumber]            = 0
        o.cacheRightScreenYAxis[deviceNumber]           = 0

        o.connected[deviceNumber]                       = prop.FALSE()

        o.cachedBundleID[deviceNumber]                  = ""

        o.repeatTimers[deviceNumber]                    = {}
    end

    -- defaultLayoutPath -> string
    -- Variable
    -- Default Layout Path
    o.defaultLayoutPath = config.basePath .. "/plugins/core/" .. o.id .. "/default/Default.cp" .. o.commandID

    --- plugins.core.loupedeckctandlive.manager.defaultLayout -> table
    --- Variable
    --- Default Loupedeck Layout
    o.defaultLayout = json.read(o.defaultLayoutPath)

    --- plugins.core.loupedeckctandlive.manager.driveWatcher -> watcher
    --- Field
    --- Watches for drive volume events.
    o.driveWatcher = fs.volume.new(function()
        o:refreshItems()
    end)

    --- plugins.core.loupedeckctandlive.manager.enableFlashDrive <cp.prop: boolean>
    --- Field
    --- Enable or disable the Loupedeck Flash Drive.
    o.enableFlashDrive = config.prop(o.id .. ".enableFlashDrive", false):watch(function(enabled)
        local devices = o.getDevices()
        for _, device in pairs(devices) do
            device:updateFlashDrive(enabled)
        end

        if not enabled then
            local path = o:getFlashDrivePath()
            if path then
                fs.volume.eject(path)
            end
        end
    end)

    --- plugins.core.loupedeckctandlive.manager.lastBundleID <cp.prop: string>
    --- Field
    --- The last Bundle ID.
    o.lastBundleID = config.prop(o.id .. ".lastBundleID", "All Applications")

    --- plugins.core.loupedeckctandlive.manager.screensBacklightLevel <cp.prop: string>
    --- Field
    --- Screens Backlight Level
    o.screensBacklightLevel = config.prop(o.id .. ".screensBacklightLevel", "9")

    --- plugins.core.loupedeckctandlive.manager.screensBacklightLevel <cp.prop: number>
    --- Field
    --- LED Backlight Level
    o.ledBacklightLevel = config.prop(o.id .. ".ledBacklightLevel", 10)

    --- plugins.core.loupedeckctandlive.manager.loadSettingsFromDevice <cp.prop: boolean>
    --- Field
    --- Load settings from device.
    o.loadSettingsFromDevice = config.prop(o.id .. ".loadSettingsFromDevice", false):watch(function(enabled)
        if enabled then
            local existingSettings = json.read(config.userConfigRootPath .. "/" .. o.configFolder .. "/" .. o.defaultFilename)
            local path = config.userConfigRootPath .. "/" .. o.configFolder .. "/Backup " .. os.date("%Y%m%d %H%M") .. o.fileExtension
            json.write(path, existingSettings)
        end
        o:refreshItems()
    end)

    --- plugins.core.loupedeckctandlive.manager.automaticallySwitchApplications <cp.prop: boolean>
    --- Field
    --- Enable or disable the automatic switching of applications.
    o.automaticallySwitchApplications = config.prop(o.id .. ".automaticallySwitchApplications", false):watch(function()
        local devices = o.getDevices()
        for deviceNumber, _ in pairs(devices) do
            o:refresh(deviceNumber)
        end
    end)

    --- plugins.core.loupedeckctandlive.prefs.snippetsRefreshFrequency <cp.prop: string>
    --- Field
    --- How often snippets are refreshed.
    o.snippetsRefreshFrequency = config.prop(o.id .. ".preferences.snippetsRefreshFrequency", "1")

    --- plugins.core.loupedeckctandlive.manager.enabled <cp.prop: boolean>
    --- Field
    --- Is Loupedeck support enabled?
    o.enabled = config.prop(o.id .. ".enabled", false):watch(function(enabled)
        if enabled then
            if mod.loupedeckPlugin.enabled() then
                log.df("Can't use CommandPost's Loupedeck Intergration if the Loupedeck Plugin is enabled")
                o.enabled(false)
            else
                o.appWatcher:start()
                o.driveWatcher:start()
                o.sleepWatcher:start()
                o.usbWatcher:start()

                o.setupDevices()
            end
        else
            --------------------------------------------------------------------------------
            -- Stop all watchers:
            --------------------------------------------------------------------------------
            o.appWatcher:stop()
            o.driveWatcher:stop()
            o.sleepWatcher:stop()
            o.usbWatcher:stop()

            --------------------------------------------------------------------------------
            -- Destroy the refresh timers:
            --------------------------------------------------------------------------------
            if o.refreshTimer then
                for _, v in pairs(o.refreshTimer) do
                    v:stop()
                end
            end

            --------------------------------------------------------------------------------
            -- Destroy any devices:
            --------------------------------------------------------------------------------
            local devices = o.getDevices()
            for _, device in pairs(devices) do
                device:disconnect()
            end

            --------------------------------------------------------------------------------
            -- Destroy the devices table:
            --------------------------------------------------------------------------------
            o.devices = nil

            o.deviceCount = 0
        end
    end)

    --------------------------------------------------------------------------------
    -- Watch for sleep events:
    --------------------------------------------------------------------------------
    o.sleepWatcher = sleepWatcher.new(function(eventType)
        if eventType == sleepWatcher.systemDidWake then
            if o.enabled() then
                --------------------------------------------------------------------------------
                -- Let's collect garbage first to give ourselves a clean slate.
                --------------------------------------------------------------------------------
                collectgarbage()
                collectgarbage()

                o.appWatcher:start()
                o.driveWatcher:start()
                o.usbWatcher:start()

                o.setupDevices()

                local devices = o.getDevices()
                if mod.numberOfDevicesBeforeSleep ~= tableCount(devices) then
                    --------------------------------------------------------------------------------
                    -- It looks like the older "virtual ethernet port" firmware takes up to
                    -- 3 seconds to "wake up" after the system wakes from sleep.
                    --------------------------------------------------------------------------------
                    mod.sleepRetry = doAfter(3, function()
                        o.setupDevices()
                        mod.sleepRetry = nil
                    end)
                end

                --local devices = o.getDevices()
                --log.df("Number of Loupedeck's Detected After Sleep: %s", tableCount(devices))
            end
        end
        if eventType == sleepWatcher.systemWillSleep then
            if o.enabled() then
                --------------------------------------------------------------------------------
                -- Stop all other watchers:
                --------------------------------------------------------------------------------
                o.appWatcher:stop()
                o.driveWatcher:stop()
                o.usbWatcher:stop()

                --------------------------------------------------------------------------------
                -- Destroy the refresh timers:
                --------------------------------------------------------------------------------
                if o.refreshTimer then
                    for _, v in pairs(o.refreshTimer) do
                        v:stop()
                    end
                end

                --------------------------------------------------------------------------------
                -- Destroy any devices:
                --------------------------------------------------------------------------------
                local devices = o.getDevices()
                mod.numberOfDevicesBeforeSleep = tableCount(devices)
                --log.df("Number of Loupedeck's Detected Before Sleep: %s", tableCount(devices))
                for _, device in pairs(devices) do
                    device:disconnect()
                end

                --------------------------------------------------------------------------------
                -- Destroy the devices table:
                --------------------------------------------------------------------------------
                o.devices = nil
                o.deviceCount = 0
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- Setup watch to refresh the Loupedeck when apps change focus:
    --------------------------------------------------------------------------------
    o.appWatcher = appWatcher.new(function(_, event)
        local devices = o.getDevices()
        for deviceNumber, _ in pairs(devices) do
            if o.hasLoaded[deviceNumber] and event == appWatcher.activated then
                o:refresh(deviceNumber, true)
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- Shutdown Callback (make screen black):
    --------------------------------------------------------------------------------
    config.shutdownCallback:new(o.configFolder, function()
        if o.enabled() then
            local devices = o.getDevices()
            for _, device in pairs(devices) do
                device:disconnect()
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- Setup Loupedeck Commands:
    --------------------------------------------------------------------------------
    local icon = imageFromPath(mod.env:pathToAbsolute("/../prefs/images/loupedeck.icns"))
    local global = mod.global
    global
        :add("enable" .. o.commandID)
        :whenActivated(function()
            o.enabled(true)
        end)
        :groupedBy("commandPost")
        :titled(i18n("enableLoupedeckCTSupport"))
        :image(icon)

    global
        :add("disable" .. o.commandID)
        :whenActivated(function()
            o.enabled(false)
        end)
        :groupedBy("commandPost")
        :titled(i18n("disableLoupedeckCTSupport"))
        :image(icon)

    global
        :add("disable" .. o.commandID .. "andLaunchLoupedeckApp")
        :whenActivated(function()
            o.enabled(false)
            launchOrFocusByBundleID(LD_BUNDLE_ID)
        end)
        :groupedBy("commandPost")
        :titled(i18n("disable" .. o.commandID .. "SupportAndLaunchLoupedeckApp"))
        :image(icon)

    global
        :add("enable" .. o.commandID .. "andKillLoupedeckApp")
        :whenActivated(function()
            local apps = applicationsForBundleID(LD_BUNDLE_ID)
            if apps then
                for _, app in pairs(apps) do
                    app:kill9()
                end
            end
            o.enabled(true)
        end)
        :groupedBy("commandPost")
        :titled(i18n("enable" .. o.commandID .. "SupportQuitLoupedeckApp"))
        :image(icon)

    --------------------------------------------------------------------------------
    -- Actions to Change Screens Backlight Level:
    --------------------------------------------------------------------------------
    for deviceNumber=1, mod.NUMBER_OF_DEVICES do
        --------------------------------------------------------------------------------
        -- Individual Screen Brightness - 1 to 10:
        --------------------------------------------------------------------------------
        for i=1, 10 do
            global
                :add("backlight_" .. o.commandID .. "_" .. deviceNumber .. "_" .. i)
                :whenActivated(function()
                    o.screensBacklightLevel(tostring(i))
                    o:updateBacklightLevel(deviceNumber, i)
                end)
                :groupedBy("commandPost")
                :titled(string.format("%s (%s %s) - %s %s", i18n(o.i18nID), i18n("unit"), deviceNumber, i18n("screensBacklightLevel"), i))
                :image(icon)
        end

        --------------------------------------------------------------------------------
        -- Increase Screen Brightness:
        --------------------------------------------------------------------------------
        global
            :add("backlight_" .. o.commandID .. "_" .. deviceNumber .. "_increase")
            :whenActivated(function()
                local currentBacklightLevel = tonumber(o.screensBacklightLevel())
                if currentBacklightLevel < 10 then
                    currentBacklightLevel = currentBacklightLevel + 1
                    o.screensBacklightLevel(tostring(currentBacklightLevel))
                    o:updateBacklightLevel(deviceNumber, currentBacklightLevel)
                end
            end)
            :groupedBy("commandPost")
            :titled(string.format("%s (%s %s) - %s %s", i18n(o.i18nID), i18n("unit"), deviceNumber, i18n("increase"), i18n("screensBacklightLevel")))
            :image(icon)

        --------------------------------------------------------------------------------
        -- Decrease Screen Brightness:
        --------------------------------------------------------------------------------
        global
            :add("backlight_" .. o.commandID .. "_" .. deviceNumber .. "_decrease")
            :whenActivated(function()
                local currentBacklightLevel = tonumber(o.screensBacklightLevel())
                if currentBacklightLevel > 1 then
                    currentBacklightLevel = currentBacklightLevel - 1
                    o.screensBacklightLevel(tostring(currentBacklightLevel))
                    o:updateBacklightLevel(deviceNumber, currentBacklightLevel)
                end
            end)
            :groupedBy("commandPost")
            :titled(string.format("%s (%s %s) - %s %s", i18n(o.i18nID), i18n("unit"), deviceNumber, i18n("decrease"), i18n("screensBacklightLevel")))
            :image(icon)

        --------------------------------------------------------------------------------
        -- Individual LED Brightness - 1 to 10:
        --------------------------------------------------------------------------------
        for i=1, 10 do
            global
                :add("ledBrightness_" .. o.commandID .. "_" .. deviceNumber .. "_" .. i)
                :whenActivated(function()
                    o.ledBacklightLevel(i)
                    o:refresh(deviceNumber)
                end)
                :groupedBy("commandPost")
                :titled(string.format("%s (%s %s) - %s %s", i18n(o.i18nID), i18n("unit"), deviceNumber, i18n("ledBrightness"), i))
                :image(icon)
        end

        --------------------------------------------------------------------------------
        -- Increase LED Brightness:
        --------------------------------------------------------------------------------
        global
            :add("ledBrightness_" .. o.commandID .. "_" .. deviceNumber .. "_increase")
            :whenActivated(function()
                local currentBacklightLevel = o.ledBacklightLevel()
                if currentBacklightLevel < 10 then
                    currentBacklightLevel = currentBacklightLevel + 1
                    o.ledBacklightLevel(currentBacklightLevel)
                    o:refresh(deviceNumber)
                end
            end)
            :groupedBy("commandPost")
            :titled(string.format("%s (%s %s) - %s %s", i18n(o.i18nID), i18n("unit"), deviceNumber, i18n("increase"), i18n("ledBrightness")))
            :image(icon)

        --------------------------------------------------------------------------------
        -- Decrease LED Brightness:
        --------------------------------------------------------------------------------
        global
            :add("ledBrightness_" .. o.commandID .. "_" .. deviceNumber .. "_decrease")
            :whenActivated(function()
                local currentBacklightLevel = o.ledBacklightLevel()
                if currentBacklightLevel > 1 then
                    currentBacklightLevel = currentBacklightLevel - 1
                    o.ledBacklightLevel(currentBacklightLevel)
                    o:refresh(deviceNumber)
                end
            end)
            :groupedBy("commandPost")
            :titled(string.format("%s (%s %s) - %s %s", i18n(o.i18nID), i18n("unit"), deviceNumber, i18n("decrease"), i18n("ledBrightness")))
            :image(icon)
    end

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = mod.actionmanager
    local numberOfBanks = mod.csman.NUMBER_OF_BANKS
    actionmanager.addHandler("global_" .. o.id .. "_banks")
        :onChoices(function(choices)

            for currentDevice=1, mod.NUMBER_OF_DEVICES do
                local deviceNumber = tostring(currentDevice)
                local deviceID = "  - Unit " .. tostring(deviceNumber)

                for i=1, numberOfBanks do
                    choices:add(o.configFolder .. " " .. i18n("bank") .. " " .. tostring(i) .. deviceID)
                        :subText(i18n(o.i18nID .. "BankDescription"))
                        :params({
                            id = i,
                            deviceNumber = tostring(deviceNumber)
                        })
                        :id(i)
                        :image(icon)
                end

                choices:add(i18n("next") .. " " .. o.configFolder .. " " .. i18n("bank") .. deviceID)
                    :subText(i18n(o.i18nID .. "BankDescription"))
                    :params({
                        id = "next",
                        deviceNumber = tostring(deviceNumber)
                    })
                    :id("next")
                    :image(icon)

                choices:add(i18n("previous") .. " " .. o.configFolder .. " " .. i18n("bank") .. deviceID)
                    :subText(i18n(o.i18nID .. "BankDescription"))
                    :params({
                        id = "previous",
                        deviceNumber = tostring(deviceNumber)
                    })
                    :id("previous")
                    :image(icon)
            end

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then

                local frontmostApplication = application.frontmostApplication()
                local bundleID = frontmostApplication:bundleID()

                local deviceNumber = (result.deviceNumber and tostring(result.deviceNumber)) or "1" -- Default to 1 for legacy reasons.
                local items = o.items()

                if not items[deviceNumber] then
                    items[deviceNumber] = {}
                end

                --------------------------------------------------------------------------------
                -- Revert to "All Applications" if no settings for frontmost app exist:
                --------------------------------------------------------------------------------
                if not items[deviceNumber][bundleID] then
                    bundleID = "All Applications"
                end

                --------------------------------------------------------------------------------
                -- Ignore if ignored:
                --------------------------------------------------------------------------------
                if items[deviceNumber][bundleID].ignore and items[deviceNumber][bundleID].ignore == true then
                    bundleID = "All Applications"
                end

                --------------------------------------------------------------------------------
                -- If not Automatically Switching Applications:
                --------------------------------------------------------------------------------
                if not o.automaticallySwitchApplications() then
                    bundleID = o.lastBundleID()
                end

                local activeBanks = o.activeBanks()
                if not activeBanks[deviceNumber] then
                    activeBanks[deviceNumber] = {}
                end

                local currentBank = (activeBanks[deviceNumber] and activeBanks[deviceNumber][bundleID] and tonumber(activeBanks[deviceNumber][bundleID])) or 1

                if type(result.id) == "number" then
                    activeBanks[deviceNumber][bundleID] = tostring(result.id)
                else
                    if result.id == "next" then
                        if currentBank == numberOfBanks then
                            activeBanks[deviceNumber][bundleID] = "1"
                        else
                            activeBanks[deviceNumber][bundleID] = tostring(currentBank + 1)
                        end
                    elseif result.id == "previous" then
                        if currentBank == 1 then
                            activeBanks[deviceNumber][bundleID] = tostring(numberOfBanks)
                        else
                            activeBanks[deviceNumber][bundleID] = tostring(currentBank - 1)
                        end
                    end
                end

                local newBank = activeBanks[deviceNumber][bundleID]

                o.activeBanks(activeBanks)

                local refreshID = tonumber(deviceNumber)
                o:refresh(refreshID)

                items = o.items() -- Reload items
                local label = items[deviceNumber] and items[deviceNumber][bundleID] and items[deviceNumber][bundleID][newBank] and items[deviceNumber][bundleID][newBank]["bankLabel"] or newBank
                displayNotification(i18n(o.i18nID) .. " " .. i18n("bank") .. ": " .. label)
            end
        end)
        :onActionId(function(action) return o.id .. "Bank" .. action.id end)

    --------------------------------------------------------------------------------
    -- Actions to Manually Change Application:
    --------------------------------------------------------------------------------
    local applicationmanager = mod.applicationmanager
    actionmanager.addHandler("global_" .. o.id .. "applications", "global")
        :onChoices(function(choices)
            local applications = applicationmanager.getApplications()

            applications["All Applications"] = {
                displayName = "All Applications",
            }

            -- Add User Added Applications from Loupedeck Preferences:
            local items = o.items()

            for _, unitObj in pairs(items) do
                for bundleID, v in pairs(unitObj) do
                    if not applications[bundleID] and v.displayName then
                        applications[bundleID] = {
                            displayName = v.displayName
                        }
                    end
                end
            end

            for bundleID, item in pairs(applications) do
                choices
                    :add(i18n("switch" .. o.commandID .. "To") .. " " .. item.displayName)
                    :subText("")
                    :params({
                        bundleID = bundleID,
                    })
                    :id("global_" .. o.id .. "applications_switch_" .. bundleID)

                if bundleID ~= "All Applications" then
                    choices
                        :add(i18n("switch" .. o.commandID .. "To") .. " " .. item.displayName .. " " .. i18n("andLaunch"))
                        :subText("")
                        :params({
                            bundleID = bundleID,
                            launch = true,
                        })
                        :id("global_" .. o.id .. "applications_launch_" .. bundleID)
                end
            end
        end)
        :onExecute(function(action)
            local bundleID = action.bundleID
            o.lastBundleID(bundleID)

            --------------------------------------------------------------------------------
            -- Refresh all devices:
            --------------------------------------------------------------------------------
            for deviceNumber=1, mod.NUMBER_OF_DEVICES do
                o:refresh(deviceNumber)
            end

            if action.launch then
                launchOrFocusByBundleID(bundleID)
            end
        end)
        :onActionId(function(params)
            return "global_" .. o.id .. "applications_" .. params.bundleID
        end)
        :cached(false)

    --------------------------------------------------------------------------------
    -- Connect to the Loupedeck:
    --------------------------------------------------------------------------------
    o.enabled:update()
    return o
end

--- plugins.core.loupedeckctandlive.manager:getFlashDrivePath() -> string
--- Method
--- Gets the Loupedeck Flash Drive path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Loupedeck Flash Drive path as a string
function mod.mt:getFlashDrivePath()
    local storage = execute("system_profiler SPStorageDataType -xml")
    local storagePlist = storage and readString(storage)
    local drives = storagePlist and storagePlist[1] and storagePlist[1]._items
    if drives then
        for _, data in pairs(drives) do
            if data.physical_drive and data.physical_drive.media_name and data.physical_drive.media_name == self.mediaName then
                local path = data.mount_point
                return doesDirectoryExist(path) and path
            end
        end
    end
end
--- plugins.core.loupedeckctandlive.manager:refreshItems() -> self
--- Method
--- Refreshes the items to either either local drive or the Loupedeck Flash Drive.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function mod.mt:refreshItems()
    local flashDrivePath = self:getFlashDrivePath()
    if self.loadSettingsFromDevice() and flashDrivePath then
        --------------------------------------------------------------------------------
        -- Define Paths:
        --------------------------------------------------------------------------------
        local macPreferencesPath = config.userConfigRootPath .. "/" .. self.configFolder .. "/" .. self.defaultFilename
        local flashDrivePreferencesPath = flashDrivePath .. "/CommandPost/" .. self.defaultFilename
        local legacyFlashDrivePreferencesPath = flashDrivePath .. "/CommandPost/Default" .. self.fileExtension

        --------------------------------------------------------------------------------
        -- If legacy preferences exists, but new ones don't:
        --------------------------------------------------------------------------------
        if not doesFileExist(flashDrivePreferencesPath) and doesFileExist(legacyFlashDrivePreferencesPath) then
            local legacyPreferences = json.read(legacyFlashDrivePreferencesPath)
            if legacyPreferences then
                local newData = {}
                newData["1"] = fnutils.copy(legacyPreferences)
                json.write(flashDrivePreferencesPath, newData)
                log.df("Converted Loupedeck Preferences from single unit to multi-unit format on Flash Drive.")
            end
        end

        --------------------------------------------------------------------------------
        -- If settings don't already exist on Loupedeck, copy them from Mac:
        --------------------------------------------------------------------------------
        if not doesFileExist(flashDrivePreferencesPath) then
            if ensureDirectoryExists(flashDrivePath, "CommandPost") then
                local existingSettings = json.read(macPreferencesPath) or self.defaultLayout
                json.write(flashDrivePreferencesPath, existingSettings)
            end
        end

        --------------------------------------------------------------------------------
        -- Read preferences from Flash Drive:
        --------------------------------------------------------------------------------
        self.items = json.prop(flashDrivePath, "CommandPost", self.defaultFilename, self.defaultLayout, function()
            self:refreshItems()
        end):watch(function()
            local data = self.items()
            local path = config.userConfigRootPath .. "/" .. self.configFolder .. "/" .. self.defaultFilename
            json.write(path, data)
        end)
    else
        --------------------------------------------------------------------------------
        -- Check if we need to migrate the layout:
        --------------------------------------------------------------------------------
        local newLayoutExists = doesFileExist(config.userConfigRootPath .. "/" .. self.configFolder .. "/" .. self.defaultFilename)

        --------------------------------------------------------------------------------
        -- Read preferences from Mac:
        --------------------------------------------------------------------------------
        self.items = json.prop(config.userConfigRootPath, self.configFolder, self.defaultFilename, self.defaultLayout)

        --------------------------------------------------------------------------------
        -- Migrate to new format:
        --------------------------------------------------------------------------------
        if not newLayoutExists then
            local updatedPreferencesToV2 = config.prop(self.id  .. ".updatedPreferencesToV2", false)
            local legacyPath = config.userConfigRootPath .. "/" .. self.configFolder .. "/Default" .. self.fileExtension
            if doesFileExist(legacyPath) and not updatedPreferencesToV2() then
                local legacyPreferences = json.read(legacyPath)
                if legacyPreferences then

                    local newData = {}

                    newData["1"] = fnutils.copy(legacyPreferences)

                    updatedPreferencesToV2(true)

                    self.items(newData)
                    log.df("Converted Loupedeck Preferences from single unit to multi-unit format.")
                end
            end
        end

    end
    return self
end

--- plugins.core.loupedeckctandlive.manager:reset()
--- Method
--- Resets the config back to the default layout.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.mt:reset()
    self.items(self.defaultLayout)
end

--- plugins.core.loupedeckctandlive.manager:refresh(dueToAppChange, deviceNumber)
--- Method
--- Refreshes the Loupedeck screens and LED buttons.
---
--- Parameters:
---  * dueToAppChange - A optional boolean to specify whether the refresh is due to
---                     an application focus change.
---  * deviceNumber - The device number.
---
--- Returns:
---  * None
function mod.mt:refresh(deviceNumber, dueToAppChange)
    local devices = self.getDevices()
    local device = devices and devices[deviceNumber]

    if type(deviceNumber) ~= "number" then
        log.ef("The Loupedeck device number supplied to the refresh function is invalid: '%s' (%s)", deviceNumber, type(deviceNumber))
        return
    end

    if not device then
        --log.ef("There is no Loupedeck device for unit '%s', which is causing screen refresh to fail.", deviceNumber)
        return
    end

    if not self.items then
        log.ef("The Loupedeck control surfaces layout preferences could not be loaded. This shouldn't be possible.")
        return
    end

    local deviceType = device and device.deviceType

    local success
    local frontmostApplication = application.frontmostApplication()

    --------------------------------------------------------------------------------
    -- It's unlikely, but possible that the frontmostApplication is nil:
    --------------------------------------------------------------------------------
    local bundleID = frontmostApplication and frontmostApplication:bundleID() or "All Applications"

    local containsIconSnippets = false

    --------------------------------------------------------------------------------
    -- If we're refreshing due to an change in application focus, make sure things
    -- have actually changed:
    --------------------------------------------------------------------------------
    if dueToAppChange and bundleID == self.cachedBundleID[deviceNumber] then
        --------------------------------------------------------------------------------
        -- Update Cache, then move onto the next device...
        --------------------------------------------------------------------------------
        self.cachedBundleID[deviceNumber] = bundleID
    else
        --------------------------------------------------------------------------------
        -- Update cache, then update current device:
        --------------------------------------------------------------------------------
        self.cachedBundleID[deviceNumber] = bundleID

        --------------------------------------------------------------------------------
        -- Stop any stray repeat timers:
        --------------------------------------------------------------------------------
        for i, devTimers in ipairs(self.repeatTimers) do
            for j, buttonTimer in ipairs(devTimers) do
                buttonTimer:stop()
                devTimers[j] = nil
            end
            self.repeatTimers[i] = {}
        end

        local items = self.items()
        items = items and items[tostring(deviceNumber)] or {}

        --------------------------------------------------------------------------------
        -- Revert to "All Applications" if no settings for frontmost app exist:
        --------------------------------------------------------------------------------
        if not items[bundleID] then
            bundleID = "All Applications"
        end

        --------------------------------------------------------------------------------
        -- Ignore if ignored:
        --------------------------------------------------------------------------------
        if items[bundleID] and items[bundleID].ignore and items[bundleID].ignore == true then
            bundleID = "All Applications"
        end

        --------------------------------------------------------------------------------
        -- If not Automatically Switching Applications:
        --------------------------------------------------------------------------------
        if not self.automaticallySwitchApplications() then
            bundleID = self.lastBundleID()
        end

        --------------------------------------------------------------------------------
        -- Determine active bank, or default to Bank 1:
        --------------------------------------------------------------------------------
        local activeBanks = self.activeBanks()
        local deviceNumberAsString = tostring(deviceNumber)
        local bankID = (activeBanks[deviceNumberAsString] and activeBanks[deviceNumberAsString][bundleID] and tostring(activeBanks[deviceNumberAsString][bundleID])) or "1"

        --------------------------------------------------------------------------------
        -- TREAT LEFT & RIGHT FUNCTION KEYS AS MODIFIERS:
        --------------------------------------------------------------------------------
        if self.leftFnPressed[deviceNumber] then
            bankID = bankID .. "_LeftFn"
        elseif self.rightFnPressed[deviceNumber] then
            bankID = bankID .. "_RightFn"
        end

        --------------------------------------------------------------------------------
        -- Preview Selected Application & Bank on Hardware:
        --------------------------------------------------------------------------------
        if mod.previewSelectedApplicationAndBankOnHardware() then
            bundleID = mod.lastApplication()
            bankID = mod.lastBank()
        end

        local item = items[bundleID]
        local bank = item and item[bankID]

        --log.df("Updating %s - Unit %s for %s - bank %s", self.configFolder, deviceNumber, bundleID, bankID)

        --------------------------------------------------------------------------------
        -- UPDATE WHEEL SENSITIVITY:
        --------------------------------------------------------------------------------
        local jogWheel = bank and bank.jogWheel and bank.jogWheel["1"]
        local wheelSensitivity = jogWheel and jogWheel.wheelSensitivity and tonumber(jogWheel.wheelSensitivity) or loupedeck.defaultWheelSensitivityIndex
        device:updateWheelSensitivity(wheelSensitivity)

        --------------------------------------------------------------------------------
        -- UPDATE LED BUTTON COLOURS:
        --------------------------------------------------------------------------------
        local ledButton = bank and bank.ledButton
        for i=7, 26 do
            local id = tostring(i)

            --------------------------------------------------------------------------------
            -- If there's a Snippet to assign the LED color, use that instead:
            --------------------------------------------------------------------------------
            local currentLEDButton = ledButton and ledButton[id]
            local snippetAction = currentLEDButton and currentLEDButton.ledSnippetAction
            local snippetResult
            if snippetAction and snippetAction.action then
                local code = snippetAction.action.code
                if code then
                    --------------------------------------------------------------------------------
                    -- Use the latest Snippet from the Snippets Preferences if it exists:
                    --------------------------------------------------------------------------------
                    local snippets = mod.scriptingPreferences.snippets()
                    local savedSnippet = snippets[snippetAction.action.id]
                    if savedSnippet and savedSnippet.code then
                        code = savedSnippet.code
                    end

                    local successful, result = pcall(load(code))
                    if type(successful) and isColor(result) then
                        snippetResult = result
                        containsIconSnippets = true
                    end
                end
            end

            local ledColor = snippetResult or (ledButton and ledButton[id] and ledButton[id].led) or defaultColor

            --------------------------------------------------------------------------------
            -- Set the LED brightness by adjusting the HSB values:
            --------------------------------------------------------------------------------
            local newLEDColor

            if isColor(ledColor) then
                newLEDColor = ledColor
            else
                newLEDColor = {hex="#" .. ledColor}
            end

            local hsbLEDColor = colorExtension.asHSB(newLEDColor)

            hsbLEDColor.brightness = hsbLEDColor.brightness * (self.ledBacklightLevel() / 10)

            if not self.cachedLEDButtonValues[deviceNumber] then
                self.cachedLEDButtonValues[deviceNumber] = {}
            end

            local cacheID = tostring(hsbLEDColor.hue) .. tostring(hsbLEDColor.saturation) .. tostring(hsbLEDColor.brightness) .. tostring(hsbLEDColor.alpha)
            if self.cachedLEDButtonValues[deviceNumber][id] ~= cacheID then
                --------------------------------------------------------------------------------
                -- Only update if the colour has changed to save bandwidth:
                --------------------------------------------------------------------------------
                device:buttonColor(i, hsbLEDColor)
                self.cachedLEDButtonValues[deviceNumber][id] = cacheID
            end
        end

        --------------------------------------------------------------------------------
        -- UPDATE TOUCH SCREEN BUTTON IMAGES:
        --------------------------------------------------------------------------------
        local touchButton = bank and bank.touchButton

        local numberOfTouchButtons = 12
        if deviceType == "Loupedeck Live-S" then
            numberOfTouchButtons = 15
        end

        for i=1, numberOfTouchButtons do
            local id = tostring(i)
            success = false
            local thisButton = touchButton and touchButton[id]
            local encodedIcon = thisButton and thisButton.encodedIcon

            --------------------------------------------------------------------------------
            -- If there's no encodedIcon, then try encodedIconLabel:
            --------------------------------------------------------------------------------
            if not encodedIcon or (encodedIcon and encodedIcon == "") then
                encodedIcon = thisButton and thisButton.encodedIconLabel
            end

            --------------------------------------------------------------------------------
            -- If there's a Snippet to generate the icon, use that instead:
            --------------------------------------------------------------------------------
            local snippetAction = thisButton and thisButton.snippetAction
            if snippetAction and snippetAction.action then
                local code = snippetAction.action.code
                if code then
                    --------------------------------------------------------------------------------
                    -- Use the latest Snippet from the Snippets Preferences if it exists:
                    --------------------------------------------------------------------------------
                    local snippets = mod.scriptingPreferences.snippets()
                    local savedSnippet = snippets[snippetAction.action.id]
                    if savedSnippet and savedSnippet.code then
                        code = savedSnippet.code
                    end

                    local successful, result = pcall(load(code))
                    if successful and isImage(result) then
                        local size = result:size()
                        if size.w == 90 and size.h == 90 then
                            --------------------------------------------------------------------------------
                            -- The generated image is already 90x90 so proceed:
                            --------------------------------------------------------------------------------
                            encodedIcon = result:encodeAsURLString(true)
                            containsIconSnippets = true
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
                            -- Icon - Scaled as per preferences:
                            --------------------------------------------------------------------------------
                            v[2] = {
                              type="image",
                              image = result,
                              frame = { x = 0, y = 0, h = "100%", w = "100%" },
                            }

                            local fixedImage = v:imageFromCanvas()

                            encodedIcon = fixedImage:encodeAsURLString(true)
                            containsIconSnippets = true
                        end
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Only update if the screen has changed to save bandwidth:
            --------------------------------------------------------------------------------
            if not self.cachedTouchScreenButtonValues[deviceNumber] then
                self.cachedTouchScreenButtonValues[deviceNumber] = {}
            end

            if encodedIcon and self.cachedTouchScreenButtonValues[deviceNumber][id] == encodedIcon then
                success = true
            elseif encodedIcon and self.cachedTouchScreenButtonValues[deviceNumber][id] ~= encodedIcon then
                self.cachedTouchScreenButtonValues[deviceNumber][id] = encodedIcon
                local decodedImage = imageFromURL(encodedIcon)
                if decodedImage then
                    device:updateScreenButtonImage(i, decodedImage)
                    success = true
                end
            end

            if not success and self.cachedTouchScreenButtonValues[deviceNumber][id] ~= defaultColor then
                device:updateScreenButtonColor(i, {hex="#"..defaultColor})
                self.cachedTouchScreenButtonValues[deviceNumber][id] = defaultColor
            end
        end

        --------------------------------------------------------------------------------
        -- UPDATE WHEEL SCREEN (ONLY ON THE LOUPEDECK CT):
        --------------------------------------------------------------------------------
        if deviceType == "Loupedeck CT" then
            success = false
            local thisWheel = bank and bank.wheelScreen and bank.wheelScreen["1"]
            local encodedIcon = thisWheel and thisWheel.encodedIcon

            --------------------------------------------------------------------------------
            -- If there's a Snippet to generate the icon, use that instead:
            --------------------------------------------------------------------------------
            local snippetAction = thisWheel and thisWheel.snippetAction
            if snippetAction and snippetAction.action then
                local code = snippetAction.action.code
                if code then
                    --------------------------------------------------------------------------------
                    -- Use the latest Snippet from the Snippets Preferences if it exists:
                    --------------------------------------------------------------------------------
                    local snippets = mod.scriptingPreferences.snippets()
                    local savedSnippet = snippets[snippetAction.action.id]
                    if savedSnippet and savedSnippet.code then
                        code = savedSnippet.code
                    end

                    local successful, result = pcall(load(code))
                    if successful and isImage(result) then
                        local size = result:size()
                        if size.w == 240 and size.h == 240 then
                            --------------------------------------------------------------------------------
                            -- The generated image is already 240x240 so proceed:
                            --------------------------------------------------------------------------------
                            encodedIcon = result:encodeAsURLString(true)
                            containsIconSnippets = true
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
                            -- Icon - scaled to fit:
                            --------------------------------------------------------------------------------
                            v[2] = {
                              type="image",
                              image = result,
                              frame = { x = 0, y = 0, h = "100%", w = "100%" },
                            }

                            local fixedImage = v:imageFromCanvas()

                            encodedIcon = fixedImage:encodeAsURLString(true)
                            containsIconSnippets = true
                        end
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Only update if the screen has changed to save bandwidth:
            --------------------------------------------------------------------------------
            if not self.cachedWheelScreen[deviceNumber] then
                self.cachedWheelScreen[deviceNumber] = {}
            end
            if encodedIcon and self.cachedWheelScreen[deviceNumber] == encodedIcon then
                success = true
            elseif encodedIcon and self.cachedWheelScreen[deviceNumber] ~= encodedIcon then
                self.cachedWheelScreen[deviceNumber] = encodedIcon
                local decodedImage = imageFromURL(encodedIcon)
                if decodedImage then
                    device:updateScreenImage(loupedeck.screens.wheel, decodedImage)
                    success = true
                end
            end
            if not success and self.cachedWheelScreen[deviceNumber] ~= defaultColor then
                device:updateScreenColor(loupedeck.screens.wheel, {hex="#"..defaultColor})
                self.cachedWheelScreen[deviceNumber] = defaultColor
            end
        end

        --------------------------------------------------------------------------------
        -- UPDATE KNOB IMAGES:
        --------------------------------------------------------------------------------
        local knob = bank and bank.knob
        local hasLeftKnob = false
        local hasRightKnob = false
        for i=1, 6 do
            local id = tostring(i)
            success = false
            local thisKnob = knob and knob[id]
            encodedIcon = thisKnob and thisKnob.encodedIcon

            --------------------------------------------------------------------------------
            -- If there's no encodedIcon, then try encodedIconLabel:
            --------------------------------------------------------------------------------
            if not encodedIcon or (encodedIcon and encodedIcon == "") then
                encodedIcon = thisKnob and thisKnob.encodedIconLabel
            end

            --------------------------------------------------------------------------------
            -- If there's a Snippet to generate the icon, use that instead:
            --------------------------------------------------------------------------------
            snippetAction = thisKnob and thisKnob.snippetAction
            if snippetAction and snippetAction.action then
                local code = snippetAction.action.code
                if code then
                    --------------------------------------------------------------------------------
                    -- Use the latest Snippet from the Snippets Preferences if it exists:
                    --------------------------------------------------------------------------------
                    local snippets = mod.scriptingPreferences.snippets()
                    local savedSnippet = snippets[snippetAction.action.id]
                    if savedSnippet and savedSnippet.code then
                        code = savedSnippet.code
                    end

                    local successful, result = pcall(load(code))
                    if successful and isImage(result) then
                        local size = result:size()
                        if size.w == 60 and size.h == 90 then
                            --------------------------------------------------------------------------------
                            -- The generated image is already 60x90 so proceed:
                            --------------------------------------------------------------------------------
                            encodedIcon = result:encodeAsURLString(true)
                            containsIconSnippets = true
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
                            -- Icon - Scaled as per preferences:
                            --------------------------------------------------------------------------------
                            v[2] = {
                              type="image",
                              image = result,
                              frame = { x = 0, y = 0, h = "100%", w = "100%" },
                            }

                            local fixedImage = v:imageFromCanvas()

                            encodedIcon = fixedImage:encodeAsURLString(true)
                            containsIconSnippets = true
                        end
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Only update if the screen has changed to save bandwidth:
            --------------------------------------------------------------------------------
            if not self.cachedKnobValues[deviceNumber] then
                self.cachedKnobValues[deviceNumber] = {}
            end

            if encodedIcon and self.cachedKnobValues[deviceNumber][id] == encodedIcon then
                success = true
            elseif encodedIcon and self.cachedKnobValues[deviceNumber][id] ~= encodedIcon then
                self.cachedKnobValues[deviceNumber][id] = encodedIcon
                local decodedImage = imageFromURL(encodedIcon)
                local size = decodedImage and decodedImage:size()
                if size and (size.w ~= 60 or size.h ~= 90) then
                    --------------------------------------------------------------------------------
                    -- The Knob Icon isn't 60x90 pixels, so it must be a legacy icon that needs
                    -- to be scaled:
                    --------------------------------------------------------------------------------
                    local v = canvas.new{x = 0, y = 0, w = 60, h = 90 }

                    v[1] = {
                        frame = { h = "100%", w = "100%", x = 0, y = 0 },
                        fillColor = { alpha = 1, hex = "#000000" },
                        type = "rectangle",
                    }

                    v[1] = {
                      type = "image",
                      image = decodedImage:croppedCopy({ x = 15, y = 0, h = 90, w = 60 }),
                      frame = { x = 0, y = 0, h = 90, w = 60 },
                    }

                    local fixedImage = v:imageFromCanvas()

                    --------------------------------------------------------------------------------
                    -- NOTE: We do this encode/decode dance because otherwise something
                    --       screws up with the scale. Hopefully this will eventually be
                    --       addressed with Hammerspoon Issue #2807.
                    --------------------------------------------------------------------------------
                    local encoded = fixedImage:encodeAsURLString(true)
                    decodedImage = imageFromURL(encoded)

                end
                if decodedImage then
                    device:updateKnobImage(i, decodedImage)
                    success = true
                end
            end
            if not success and self.cachedKnobValues[deviceNumber][id] ~= defaultColor then
                device:updateScreenKnobColor(i, {hex="#"..defaultColor})
                self.cachedKnobValues[deviceNumber][id] = defaultColor
            end
            if success then
                if i > 3 then
                    hasRightKnob = true
                else
                    hasLeftKnob = true
                end
            end
        end

        --------------------------------------------------------------------------------
        -- If no individual knob icons, use the left/right screen icons instead:
        --------------------------------------------------------------------------------
        if not self.cachedLeftSideScreen[deviceNumber] then
            self.cachedLeftSideScreen[deviceNumber] = {}
        end
        if not hasLeftKnob then
            success = false
            local thisSideScreen = bank and bank.sideScreen and bank.sideScreen["1"]
            encodedIcon = thisSideScreen and thisSideScreen.encodedIcon
            if encodedIcon and self.cachedLeftSideScreen[deviceNumber] == encodedIcon then
                success = true
            elseif encodedIcon and self.cachedLeftSideScreen[deviceNumber] ~= encodedIcon then
                self.cachedLeftSideScreen[deviceNumber] = encodedIcon
                local decodedImage = imageFromURL(encodedIcon)
                if decodedImage then
                    device:updateScreenImage(loupedeck.screens.left, decodedImage)
                    success = true
                end
            end
            if not success and self.cachedLeftSideScreen[deviceNumber] ~= defaultColor then
                device:updateScreenColor(loupedeck.screens.left, {hex="#"..defaultColor})
                self.cachedLeftSideScreen[deviceNumber] = defaultColor
            end
        else
            self.cachedLeftSideScreen[deviceNumber] = nil
        end


        if not self.cachedRightSideScreen[deviceNumber] then
            self.cachedRightSideScreen[deviceNumber] = {}
        end
        if not hasRightKnob then
            success = false
            local thisSideScreen = bank and bank.sideScreen and bank.sideScreen["2"]
            encodedIcon = thisSideScreen and thisSideScreen.encodedIcon
            if encodedIcon and self.cachedRightSideScreen[deviceNumber] == encodedIcon then
                success = true
            elseif encodedIcon and self.cachedRightSideScreen[deviceNumber] ~= encodedIcon then
                self.cachedRightSideScreen[deviceNumber] = encodedIcon
                local decodedImage = imageFromURL(encodedIcon)
                if decodedImage then
                    device:updateScreenImage(loupedeck.screens.right, decodedImage)
                    success = true
                end
            end
            if not success and self.cachedRightSideScreen[deviceNumber] ~= defaultColor then
                device:updateScreenColor(loupedeck.screens.right, {hex="#"..defaultColor})
                self.cachedRightSideScreen[deviceNumber] = defaultColor
            end
        else
            self.cachedRightSideScreen[deviceNumber] = nil
        end

        --------------------------------------------------------------------------------
        -- Enable or disable the refresh timer:
        --------------------------------------------------------------------------------
        if containsIconSnippets then
            if not self.refreshTimer[deviceNumber] then
                local snippetsRefreshFrequency = tonumber(self.snippetsRefreshFrequency())
                self.refreshTimer[deviceNumber] = timer.new(snippetsRefreshFrequency, function()
                    self:refresh(deviceNumber)
                end)
            end
            self.refreshTimer[deviceNumber]:start()
        else
            if self.refreshTimer[deviceNumber] then
                self.refreshTimer[deviceNumber]:stop()
            end
        end
    end
end

--- plugins.core.loupedeckctandlive.manager:executeAction(thisAction, deviceNumber) -> boolean
--- Function
--- Executes an action.
---
--- Parameters:
---  * thisAction - The action to execute
---  * deviceNumber - The device number
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.mt:executeAction(thisAction, deviceNumber)
    if not self._delayedTimer then
        self._delayedTimer = delayed.new(0.1, function()
            self:refresh(deviceNumber)
        end)
    end
    if thisAction then
        local handlerID = thisAction.handlerID
        local action = thisAction.action
        if handlerID and action then
            local handler = mod.actionmanager.getHandler(handlerID)
            if handler then
                doAfter(0, function()
                    handler:execute(action)
                    self._delayedTimer:start()
                end)
                return true
            end
        end
    end
    return false
end

--- plugins.core.loupedeckctandlive.manager:clearCache(deviceNumber) -> none
--- Method
--- Clears the cache.
---
--- Parameters:
---  * deviceNumber - The device number.
---
--- Returns:
---  * None
function mod.mt:clearCache(deviceNumber)
    --------------------------------------------------------------------------------
    -- Stop any stray repeat timers:
    --------------------------------------------------------------------------------
    for i, devTimers in ipairs(self.repeatTimers) do
        for j, buttonTimer in ipairs(devTimers) do
            buttonTimer:stop()
            devTimers[j] = nil
        end
        self.repeatTimers[i] = {}
    end

    self.cacheWheelYAxis[deviceNumber] = 0
    self.cacheWheelXAxis[deviceNumber] = 0

    self.cacheRightScreenYAxis[deviceNumber] = 0
    self.cacheLeftScreenYAxis[deviceNumber] = 0

    self.leftFnPressed[deviceNumber] = false
    self.rightFnPressed[deviceNumber] = false

    self.cachedLEDButtonValues[deviceNumber] = {}
    self.cachedTouchScreenButtonValues[deviceNumber] = {}
    self.cachedKnobValues[deviceNumber] = {}

    self.cachedWheelScreen[deviceNumber] = {}
    self.cachedLeftSideScreen[deviceNumber] = {}
    self.cachedRightSideScreen[deviceNumber] = {}

    self.lastWheelDoubleTapX[deviceNumber] = {}
    self.lastWheelDoubleTapY[deviceNumber] = {}

    self.hasLoaded[deviceNumber] = false
end

--- plugins.core.loupedeckctandlive.manager:updateBacklightLevel(deviceNumber, value) -> none
--- Method
--- Update the backlight level for a Loupedeck device.
---
--- Parameters:
---  * deviceNumber - The device number.
---  * value - The backlight level
---
--- Returns:
---  * None
function mod.mt:updateBacklightLevel(deviceNumber, value)
    local device = self.devices and self.devices[deviceNumber]
    if device then
        device:updateBacklightLevel(value)
    end
end

--- plugins.core.loupedeckctandlive.manager:callback(data, deviceNumber) -> none
--- Method
--- The Loupedeck callback.
---
--- Parameters:
---  * data - The callback data.
---  * deviceNumber - The device number.
---
--- Returns:
---  * None
function mod.mt:callback(data, deviceNumber)
    --[[
    log.df("--------------------------------------------------------------------------------")
    log.df("deviceNumber: %s", deviceNumber)
    log.df("data: %s", hs.inspect(data))
    log.df("--------------------------------------------------------------------------------")
    --]]

    local device = self.devices and self.devices[deviceNumber]

    --------------------------------------------------------------------------------
    -- REFRESH ON INITIAL LOAD AFTER A SLIGHT DELAY:
    --------------------------------------------------------------------------------
    if data.action == "websocket_opening" then
        --log.df("Loupedeck websocket opening for %s (Unit %s)...", self.configFolder, deviceNumber)
        return
    elseif data.action == "websocket_closing" then
        --log.df("Loupedeck websocket closing for %s (Unit %s)...", self.configFolder, deviceNumber)
        return
    elseif data.action == "websocket_opened" then
        self.connected[deviceNumber](true)
        self:clearCache(deviceNumber)
        self:refresh(deviceNumber)
        self.hasLoaded[deviceNumber] = true
        self.enableFlashDrive:update()

        if device then
            device:updateBacklightLevel(tonumber(self.screensBacklightLevel()))
        end

        return
    elseif data.action == "websocket_closed" then
        --------------------------------------------------------------------------------
        -- If the websocket disconnects, then trash all the caches:
        --------------------------------------------------------------------------------
        self.connected[deviceNumber](false)
        self:clearCache(deviceNumber)
        return
    elseif data.action == "websocket_error"  then
        --------------------------------------------------------------------------------
        -- If the websocket fails, then trash all the caches:
        --------------------------------------------------------------------------------
        log.ef("The websocket connection for %s (Unit %s) failed.", self.configFolder, deviceNumber)
        self.connected[deviceNumber](false)
        self:clearCache(deviceNumber)
        return
    end

    local bundleID = self.cachedBundleID[deviceNumber]

    local items = self.items()
    items = items and items[tostring(deviceNumber)] or {}

    --------------------------------------------------------------------------------
    -- Revert to "All Applications" if no settings for frontmost app exist:
    --------------------------------------------------------------------------------
    if not items[bundleID] then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- Ignore if ignored:
    --------------------------------------------------------------------------------
    if items[bundleID] and items[bundleID].ignore and items[bundleID].ignore == true then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- If not Automatically Switching Applications:
    --------------------------------------------------------------------------------
    if not self.automaticallySwitchApplications() then
        bundleID = self.lastBundleID()
    end

    local activeBanks = self.activeBanks()
    local deviceNumberAsString = tostring(deviceNumber)
    local bankID = (activeBanks[deviceNumberAsString] and activeBanks[deviceNumberAsString][bundleID] and tostring(activeBanks[deviceNumberAsString][bundleID])) or "1"

    local buttonID = tostring(data.buttonID)

    --------------------------------------------------------------------------------
    -- Preview Selected Application & Bank on Hardware:
    --------------------------------------------------------------------------------
    if mod.previewSelectedApplicationAndBankOnHardware() then
        bundleID = mod.lastApplication()
        bankID = mod.lastBank()
    end

    local item = items[bundleID]

    --------------------------------------------------------------------------------
    -- TREAT LEFT & RIGHT FUNCTION KEYS AS MODIFIERS AS LONG AS A PRESS ACTION
    -- ISN'T ASSIGNED TO THEM (IN WHICH CASE THEY BECOME NORMAL BUTTONS):
    --------------------------------------------------------------------------------
    local functionButtonPressed = false
    if data.id == loupedeck.event.BUTTON_PRESS then
        if data.direction == "up" then
            if data.buttonID == loupedeck.buttonID.LEFT_FN then
                local button = item[bankID] and item[bankID]["ledButton"] and item[bankID]["ledButton"]["20"]
                local pressAction = button and button["pressAction"]
                if not pressAction or (pressAction and next(pressAction) == nil) then
                    self.leftFnPressed[deviceNumber] = false
                    self:refresh(deviceNumber)
                end
            elseif data.buttonID == loupedeck.buttonID.RIGHT_FN then
                local button = item[bankID] and item[bankID]["ledButton"] and item[bankID]["ledButton"]["23"]
                local pressAction = button and button["pressAction"]
                if not pressAction or (pressAction and next(pressAction) == nil) then
                    self.rightFnPressed[deviceNumber] = false
                    self:refresh(deviceNumber)
                end
            end
        elseif data.direction == "down" then
            if data.buttonID == loupedeck.buttonID.LEFT_FN then
                local button = item[bankID] and item[bankID]["ledButton"] and item[bankID]["ledButton"]["20"]
                local pressAction = button and button["pressAction"]
                if not pressAction or (pressAction and next(pressAction) == nil) then
                    functionButtonPressed = true
                    self.leftFnPressed[deviceNumber] = true
                    self:refresh(deviceNumber)
                end
            elseif data.buttonID == loupedeck.buttonID.RIGHT_FN then
                local button = item[bankID] and item[bankID]["ledButton"] and item[bankID]["ledButton"]["23"]
                local pressAction = button and button["pressAction"]
                if not pressAction or (pressAction and next(pressAction) == nil) then
                    functionButtonPressed = true
                    self.rightFnPressed[deviceNumber] = true
                    self:refresh(deviceNumber)
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- HANDLE FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    if not functionButtonPressed then
        if self.leftFnPressed[deviceNumber] then
            bankID = bankID .. "_LeftFn"
        elseif self.rightFnPressed[deviceNumber] then
            bankID = bankID .. "_RightFn"
        end
    end

    local bank = item and item[bankID]

    if bank then
        if data.id == loupedeck.event.BUTTON_PRESS and data.direction == "down" then
            --------------------------------------------------------------------------------
            -- LED BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisButton = bank.ledButton and bank.ledButton[buttonID]

            --------------------------------------------------------------------------------
            -- Vibrate if needed:
            --------------------------------------------------------------------------------
            if thisButton and thisButton.vibratePress and thisButton.vibratePress ~= "" and device then
                device:vibrate(tonumber(thisButton.vibratePress))
            end

            --------------------------------------------------------------------------------
            -- Trigger Action:
            --------------------------------------------------------------------------------
            if thisButton and self:executeAction(thisButton.pressAction, deviceNumber) then
                --------------------------------------------------------------------------------
                -- Repeat if necessary:
                --------------------------------------------------------------------------------
                if thisButton.repeatPressActionUntilReleased then
                    self.repeatTimers[deviceNumber][buttonID] = doEvery(keyRepeatInterval(), function()
                        self:executeAction(thisButton.pressAction, deviceNumber)
                    end)
                end

                return
            end

            --------------------------------------------------------------------------------
            -- KNOB BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisKnob = bank.knob and bank.knob[buttonID]

            --------------------------------------------------------------------------------
            -- Vibrate if needed:
            --------------------------------------------------------------------------------
            if thisKnob and thisKnob.vibratePress and thisKnob.vibratePress ~= "" and device then
                device:vibrate(tonumber(thisKnob.vibratePress))
            end

            --------------------------------------------------------------------------------
            -- Trigger Action:
            --------------------------------------------------------------------------------
            if thisKnob and self:executeAction(thisKnob.pressAction, deviceNumber) then
                return
            end

        elseif data.id == loupedeck.event.BUTTON_PRESS and data.direction == "up" then
            --------------------------------------------------------------------------------
            -- LED BUTTON RELEASE:
            --------------------------------------------------------------------------------
            local thisButton = bank.ledButton and bank.ledButton[buttonID]

            --------------------------------------------------------------------------------
            -- Vibrate if needed:
            --------------------------------------------------------------------------------
            if thisButton and thisButton.vibrateRelease and thisButton.vibrateRelease ~= "" and device then
                device:vibrate(tonumber(thisButton.vibrateRelease))
            end

            --------------------------------------------------------------------------------
            -- Stop repeating:
            --------------------------------------------------------------------------------
            if thisButton and thisButton.repeatPressActionUntilReleased then
                if self.repeatTimers[deviceNumber][buttonID] then
                    self.repeatTimers[deviceNumber][buttonID]:stop()
                    self.repeatTimers[deviceNumber][buttonID] = nil
                end
            end

            --------------------------------------------------------------------------------
            -- Trigger Action:
            --------------------------------------------------------------------------------
            if thisButton and self:executeAction(thisButton.releaseAction, deviceNumber) then
                return
            end

            --------------------------------------------------------------------------------
            -- KNOB BUTTON RELEASE:
            --------------------------------------------------------------------------------
            local thisKnob = bank.knob and bank.knob[buttonID]

            --------------------------------------------------------------------------------
            -- Vibrate if needed:
            --------------------------------------------------------------------------------
            if thisKnob and thisKnob.vibrateRelease and thisKnob.vibrateRelease ~= "" and device then
                device:vibrate(tonumber(thisKnob.vibrateRelease))
            end

            --------------------------------------------------------------------------------
            -- Trigger Action:
            --------------------------------------------------------------------------------
            if thisKnob and self:executeAction(thisKnob.releaseAction, deviceNumber) then
                return
            end
        elseif data.id == loupedeck.event.ENCODER_MOVE then
            --------------------------------------------------------------------------------
            -- KNOB TURN:
            --------------------------------------------------------------------------------
            local thisKnob = bank.knob and bank.knob[buttonID]

            --------------------------------------------------------------------------------
            -- Vibrate if needed:
            --------------------------------------------------------------------------------
            if data.direction == "left" and thisKnob and thisKnob.vibrateLeft and thisKnob.vibrateLeft ~= "" and device then
                device:vibrate(tonumber(thisKnob.vibrateLeft))
            end
            if data.direction == "right" and thisKnob and thisKnob.vibrateRight and thisKnob.vibrateRight ~= "" and device then
                device:vibrate(tonumber(thisKnob.vibrateRight))
            end

            --------------------------------------------------------------------------------
            -- Trigger Action:
            --------------------------------------------------------------------------------
            if thisKnob and self:executeAction(thisKnob[data.direction.."Action"], deviceNumber) then
                return
            end

            --------------------------------------------------------------------------------
            -- JOG WHEEL TURN:
            --------------------------------------------------------------------------------
            local thisJogWheel = buttonID == "0" and bank.jogWheel and bank.jogWheel["1"]

            --------------------------------------------------------------------------------
            -- Vibrate if needed:
            --------------------------------------------------------------------------------
            if data.direction == "left" and thisJogWheel and thisJogWheel.vibrateLeft and thisJogWheel.vibrateLeft ~= "" and device then
                device:vibrate(tonumber(thisJogWheel.vibrateLeft))
            end
            if data.direction == "right" and thisJogWheel and thisJogWheel.vibrateRight and thisJogWheel.vibrateRight ~= "" and device then
                device:vibrate(tonumber(thisJogWheel.vibrateRight))
            end

            --------------------------------------------------------------------------------
            -- Trigger Action:
            --------------------------------------------------------------------------------
            if thisJogWheel and self:executeAction(thisJogWheel[data.direction.."Action"], deviceNumber) then
                return
            end
        elseif data.id == loupedeck.event.SCREEN_PRESSED then
            --------------------------------------------------------------------------------
            -- TOUCH SCREEN BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisTouchButton = bank.touchButton and bank.touchButton[buttonID]

            --------------------------------------------------------------------------------
            -- Vibrate if needed:
            --------------------------------------------------------------------------------
            if thisTouchButton and thisTouchButton.vibratePress and thisTouchButton.vibratePress ~= "" and device then
                device:vibrate(tonumber(thisTouchButton.vibratePress))
            end

            --------------------------------------------------------------------------------
            -- Trigger Action:
            --------------------------------------------------------------------------------
            if thisTouchButton and self:executeAction(thisTouchButton.pressAction, deviceNumber) then
                --------------------------------------------------------------------------------
                -- Repeat if necessary:
                --------------------------------------------------------------------------------
                if thisTouchButton.repeatPressActionUntilReleased then
                    self.repeatTimers[deviceNumber][buttonID] = doEvery(keyRepeatInterval(), function()
                        self:executeAction(thisTouchButton.pressAction, deviceNumber)
                    end)
                end
                return
            end

            --------------------------------------------------------------------------------
            -- LEFT TOUCH SCREEN:
            --------------------------------------------------------------------------------
            if data.screenID == loupedeck.screens.left.id then
                local thisSideScreen = bank.sideScreen and bank.sideScreen["1"]
                if thisSideScreen then
                    --------------------------------------------------------------------------------
                    -- SLIDE UP/DOWN:
                    --------------------------------------------------------------------------------
                    if self.cacheLeftScreenYAxis[deviceNumber] ~= nil then
                        -- already dragging. Which way?
                        local yDiff = data.y - self.cacheLeftScreenYAxis[deviceNumber]
                        if yDiff < 0-dragMinimumDiff then
                            self:executeAction(thisSideScreen.upAction, deviceNumber)
                        elseif yDiff > 0+dragMinimumDiff then
                            self:executeAction(thisSideScreen.downAction, deviceNumber)
                        end
                    end
                    self.cacheLeftScreenYAxis[deviceNumber] = data.y

                    --------------------------------------------------------------------------------
                    -- DOUBLE TAP:
                    --------------------------------------------------------------------------------
                    if data.multitouch == 0 and thisSideScreen.doubleTapAction then
                        if self.leftScreenDoubleTapTriggered and self.tookFingerOffLeftScreen then
                            self.leftScreenDoubleTapTriggered = false
                            self.tookFingerOffLeftScreen = false
                            self:executeAction(thisSideScreen.doubleTapAction, deviceNumber)
                        else
                            self.leftScreenDoubleTapTriggered = true
                            doAfter(doubleTapTimeout, function()
                                self.leftScreenDoubleTapTriggered = false
                                self.tookFingerOffLeftScreen = false
                            end)
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- TWO FINGER TAP:
                    --------------------------------------------------------------------------------
                    if data.multitouch == 1 then
                        self:executeAction(thisSideScreen.twoFingerTapAction, deviceNumber)
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- RIGHT TOUCH SCREEN:
            --------------------------------------------------------------------------------
            if data.screenID == loupedeck.screens.right.id then
                --------------------------------------------------------------------------------
                -- SLIDE UP/DOWN:
                --------------------------------------------------------------------------------
                local thisSideScreen = bank.sideScreen and bank.sideScreen["2"]
                if thisSideScreen then
                    if self.cacheRightScreenYAxis[deviceNumber] ~= nil then
                        -- already dragging. Which way?
                        local yDiff = data.y - self.cacheRightScreenYAxis[deviceNumber]
                        if yDiff < 0-dragMinimumDiff then
                            self:executeAction(thisSideScreen.upAction, deviceNumber)
                        elseif yDiff > 0+dragMinimumDiff then
                            self:executeAction(thisSideScreen.downAction, deviceNumber)
                        end
                    end
                    self.cacheRightScreenYAxis[deviceNumber] = data.y

                    --------------------------------------------------------------------------------
                    -- DOUBLE TAP:
                    --------------------------------------------------------------------------------
                    if data.multitouch == 0 and thisSideScreen.doubleTapAction then
                        if self.rightScreenDoubleTapTriggered and self.tookFingerOffRightScreen then
                            self.rightScreenDoubleTapTriggered = false
                            self.tookFingerOffRightScreen = false
                            self:executeAction(thisSideScreen.doubleTapAction, deviceNumber)
                        else
                            self.rightScreenDoubleTapTriggered = true
                            doAfter(doubleTapTimeout, function()
                                self.rightScreenDoubleTapTriggered = false
                                self.tookFingerOffRightScreen = false
                            end)
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- TWO FINGER TAP:
                    --------------------------------------------------------------------------------
                    if data.multitouch == 1 then
                        self:executeAction(thisSideScreen.twoFingerTapAction, deviceNumber)
                    end
                end
            end
        elseif data.id == loupedeck.event.SCREEN_RELEASED then
            --------------------------------------------------------------------------------
            -- SCREEN RELEASED:
            --------------------------------------------------------------------------------
            self.cacheLeftScreenYAxis[deviceNumber] = nil
            self.cacheRightScreenYAxis[deviceNumber] = nil
            self.tookFingerOffLeftScreen = true
            self.tookFingerOffRightScreen = true

            --------------------------------------------------------------------------------
            -- TOUCH SCREEN BUTTON RELEASE:
            --------------------------------------------------------------------------------
            local thisTouchButton = bank.touchButton and bank.touchButton[buttonID]

            --------------------------------------------------------------------------------
            -- Stop repeating:
            --------------------------------------------------------------------------------
            if thisTouchButton and thisTouchButton.repeatPressActionUntilReleased then
                if self.repeatTimers[deviceNumber][buttonID] then
                    self.repeatTimers[deviceNumber][buttonID]:stop()
                    self.repeatTimers[deviceNumber][buttonID] = nil
                end
            end

            --------------------------------------------------------------------------------
            -- Vibrate if needed:
            --------------------------------------------------------------------------------
            if thisTouchButton and thisTouchButton.vibrateRelease and thisTouchButton.vibrateRelease ~= "" and device then
                device:vibrate(tonumber(thisTouchButton.vibrateRelease))
            end

            if thisTouchButton and self:executeAction(thisTouchButton.releaseAction, deviceNumber) then
                return
            end
        elseif data.id == loupedeck.event.WHEEL_PRESSED then
            local wheelScreen = bank.wheelScreen and bank.wheelScreen["1"]
            if wheelScreen then
                --------------------------------------------------------------------------------
                -- BUTTON PRESS:
                --------------------------------------------------------------------------------
                if wheelScreen.topLeftAction and buttonID == "1" then
                    self:executeAction(wheelScreen.topLeftAction, deviceNumber)
                end
                if wheelScreen.topMiddleAction and buttonID == "2" then
                    self:executeAction(wheelScreen.topMiddleAction, deviceNumber)
                end
                if wheelScreen.topRightAction and buttonID == "3" then
                    self:executeAction(wheelScreen.topRightAction, deviceNumber)
                end
                if wheelScreen.bottomLeftAction and buttonID == "4" then
                    self:executeAction(wheelScreen.bottomLeftAction, deviceNumber)
                end
                if wheelScreen.bottomMiddleAction and buttonID == "5" then
                    self:executeAction(wheelScreen.bottomMiddleAction, deviceNumber)
                end
                if wheelScreen.bottomRightAction and buttonID == "6" then
                    self:executeAction(wheelScreen.bottomRightAction, deviceNumber)
                end

                --------------------------------------------------------------------------------
                -- DRAG WHEEL:
                --------------------------------------------------------------------------------
                --if not self.cacheWheelXAxis[deviceNumber] then

                if self.cacheWheelXAxis[deviceNumber] ~= nil and self.cacheWheelYAxis[deviceNumber] ~= nil then
                    -- we're already dragging. Which way?
                    local xDiff, yDiff = data.x - self.cacheWheelXAxis[deviceNumber], data.y - self.cacheWheelYAxis[deviceNumber]
                    -- dragging horizontally
                    if xDiff < 0-dragMinimumDiff then
                        self:executeAction(wheelScreen.leftAction, deviceNumber)
                    elseif xDiff > 0+dragMinimumDiff then
                        self:executeAction(wheelScreen.rightAction, deviceNumber)
                    end
                    -- dragging vertically
                    if yDiff < 0-dragMinimumDiff then
                        self:executeAction(wheelScreen.upAction, deviceNumber)
                    elseif yDiff > 0+dragMinimumDiff then
                        self:executeAction(wheelScreen.downAction, deviceNumber)
                    end
                end

                --------------------------------------------------------------------------------
                -- CACHE DATA:
                --------------------------------------------------------------------------------
                self.cacheWheelXAxis[deviceNumber] = data.x
                self.cacheWheelYAxis[deviceNumber] = data.y

                --------------------------------------------------------------------------------
                -- DOUBLE TAP:
                --------------------------------------------------------------------------------
                if not data.multitouch and wheelScreen.doubleTapAction then

                    local withinRange = self.lastWheelDoubleTapX[deviceNumber] and self.lastWheelDoubleTapY[deviceNumber] and
                                        data.x >= (self.lastWheelDoubleTapX[deviceNumber] - wheelDoubleTapXTolerance) and data.x <= (self.lastWheelDoubleTapX[deviceNumber] + wheelDoubleTapXTolerance) and
                                        data.y >= (self.lastWheelDoubleTapY[deviceNumber] - wheelDoubleTapYTolerance) and data.y <= (self.lastWheelDoubleTapY[deviceNumber] + wheelDoubleTapYTolerance)

                    if self.wheelScreenDoubleTapTriggered[deviceNumber] and self.tookFingerOffWheelScreen[deviceNumber] and withinRange then
                        self.wheelScreenDoubleTapTriggered[deviceNumber] = false
                        self.tookFingerOffWheelScreen[deviceNumber] = false
                        self.lastWheelDoubleTapX[deviceNumber] = nil
                        self.lastWheelDoubleTapY[deviceNumber] = nil
                        self:executeAction(wheelScreen.doubleTapAction, deviceNumber)
                    else
                        self.wheelScreenDoubleTapTriggered[deviceNumber] = true
                        self.lastWheelDoubleTapX[deviceNumber] = nil
                        self.lastWheelDoubleTapY[deviceNumber] = nil
                        doAfter(doubleTapTimeout, function()
                            self.wheelScreenDoubleTapTriggered[deviceNumber] = false
                            self.tookFingerOffWheelScreen[deviceNumber] = false
                            self.lastWheelDoubleTapX[deviceNumber] = nil
                            self.lastWheelDoubleTapY[deviceNumber] = nil
                        end)
                    end
                end

                --------------------------------------------------------------------------------
                -- TWO FINGER TAP:
                --------------------------------------------------------------------------------
                if data.multitouch then
                    self:executeAction(wheelScreen.twoFingerTapAction, deviceNumber)
                end
            end
        elseif data.id == loupedeck.event.WHEEL_RELEASED then
            self.cacheWheelYAxis[deviceNumber] = nil
            self.cacheWheelXAxis[deviceNumber] = nil

            self.lastWheelDoubleTapX[deviceNumber] = data.x
            self.lastWheelDoubleTapY[deviceNumber] = data.y

            self.tookFingerOffWheelScreen[deviceNumber] = true
        end
    end
end

local plugin = {
    id          = "core.loupedeckctandlive.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]                 = "actionmanager",
        ["core.application.manager"]            = "applicationmanager",
        ["core.commands.global"]                = "global",
        ["core.controlsurfaces.manager"]        = "csman",
        ["core.preferences.panels.scripting"]   = "scriptingPreferences",
        ["core.loupedeckplugin.manager"]        = "loupedeckPlugin",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod.actionmanager           = deps.actionmanager
    mod.applicationmanager      = deps.applicationmanager
    mod.csman                   = deps.csman
    mod.global                  = deps.global
    mod.scriptingPreferences    = deps.scriptingPreferences
    mod.loupedeckPlugin         = deps.loupedeckPlugin

    mod.env                     = env

    --------------------------------------------------------------------------------
    -- Setup devices:
    --------------------------------------------------------------------------------
    mod.devices                             = {}
    mod.devices.CT                          = mod.new(loupedeck.deviceTypes.CT):refreshItems()
    mod.devices.LIVE                        = mod.new(loupedeck.deviceTypes.LIVE):refreshItems()
    mod.devices.LIVE_S                      = mod.new(loupedeck.deviceTypes.LIVE_S):refreshItems()
    mod.devices.RAZER_STREAM_CONTROLLER     = mod.new(loupedeck.deviceTypes.RAZER_STREAM_CONTROLLER):refreshItems()

    return mod
end

return plugin
