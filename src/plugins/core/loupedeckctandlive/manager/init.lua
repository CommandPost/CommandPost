--- === plugins.core.loupedeckctandlive.manager ===
---
--- Loupedeck CT & Loupedeck Live Manager Plugin.

local require                   = require

local hs                        = hs

local log                       = require "hs.logger".new "ldCT"

local application               = require "hs.application"
local appWatcher                = require "hs.application.watcher"
local eventtap                  = require "hs.eventtap"
local fs                        = require "hs.fs"
local image                     = require "hs.image"
local loupedeck                 = require "hs.loupedeck"
local plist                     = require "hs.plist"
local sleepWatcher              = require "hs.caffeinate.watcher"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local just                      = require "cp.just"
local prop                      = require "cp.prop"
local tools                     = require "cp.tools"

local applicationsForBundleID   = application.applicationsForBundleID
local displayNotification       = dialog.displayNotification
local doAfter                   = timer.doAfter
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local doEvery                   = timer.doEvery
local ensureDirectoryExists     = tools.ensureDirectoryExists
local execute                   = hs.execute
local imageFromPath             = image.imageFromPath
local imageFromURL              = image.imageFromURL
local keyRepeatInterval         = eventtap.keyRepeatInterval
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local readString                = plist.readString

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

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

-- cachedBundleID -> string
-- Variable
-- The last bundle ID processed.
local cachedBundleID = ""

-- wheelDoubleTapXTolerance -> number
-- Variable
-- Last Wheel Double Tap X Tolerance
local wheelDoubleTapXTolerance = 12

-- wheelDoubleTapYTolerance -> number
-- Variable
-- Last Wheel Double Tap Y Tolerance
local wheelDoubleTapYTolerance = 7

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

    --- plugins.core.loupedeckctandlive.manager.getDevice() -> hs.loupedeck
    --- Function
    --- Gets the Loupedeck device.
    ---
    --- Parameters:
    ---  * None
    ---
    --- Returns:
    ---  * A cached or a new hs.loupedeck object.
    o.getDevice = function()
        if not o.device then
            if deviceType == loupedeck.deviceTypes.CT then
                o.device = loupedeck.new(true, loupedeck.deviceTypes.CT)
            elseif deviceType == loupedeck.deviceTypes.LIVE then
                o.device = loupedeck.new(true, loupedeck.deviceTypes.LIVE)
            end

            -- Setup the callback:
            o.device:callback(function(...)
                o:callback(...)
            end)
        end
        return o.device
    end

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
    else
        log.ef("Invalid Loupedeck Device Type: %s", deviceType)
        return
    end

    --- plugins.core.loupedeckctandlive.manager.defaultFilename -> string
    --- Field
    --- Default filename
    o.defaultFilename = "Default" .. o.fileExtension

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
    o.hasLoaded = false

    --- plugins.core.loupedeckctandlive.manager.leftFnPressed -> boolean
    --- Variable
    --- Is the left Function button pressed?
    o.leftFnPressed = false

    --- plugins.core.loupedeckctandlive.manager.rightFnPressed -> boolean
    --- Variable
    --- Is the right Function button pressed?
    o.rightFnPressed = false

    --- plugins.core.loupedeckctandlive.manager.cachedLEDButtonValues -> table
    --- Variable
    --- Table of cached LED button values.
    o.cachedLEDButtonValues = {}

    --- plugins.core.loupedeckctandlive.manager.cachedTouchScreenButtonValues -> table
    --- Variable
    --- Table of cached Touch Screen button values.
    o.cachedTouchScreenButtonValues = {}

    --- plugins.core.loupedeckctandlive.manager.cachedWheelScreen -> string
    --- Variable
    --- The last wheel screen data sent.
    o.cachedWheelScreen = ""

    --- plugins.core.loupedeckctandlive.manager.cachedLeftSideScreen -> string
    --- Variable
    --- The last screen data sent.
    o.cachedLeftSideScreen = ""

    --- plugins.core.loupedeckctandlive.manager.cachedRightSideScreen -> string
    --- Variable
    --- The last screen data sent.
    o.cachedRightSideScreen = ""

    --- plugins.core.loupedeckctandlive.manager.cacheWheelYAxis -> number
    --- Variable
    --- Wheel Y Axis Cache
    o.cacheWheelYAxis = nil

    --- plugins.core.loupedeckctandlive.manager.cacheWheelXAxis -> number
    --- Variable
    --- Wheel X Axis Cache
    o.cacheWheelXAxis = nil

    --- plugins.core.loupedeckctandlive.manager.cacheLeftScreenYAxis -> number
    --- Variable
    --- Right Screen Y Axis Cache
    o.cacheLeftScreenYAxis = nil

    --- plugins.core.loupedeckctandlive.manager.cacheRightScreenYAxis -> number
    --- Variable
    --- Right Screen Y Axis Cache
    o.cacheRightScreenYAxis = nil

    --- plugins.core.loupedeckctandlive.manager.wheelScreenDoubleTapTriggered -> boolean
    --- Variable
    --- Has the wheel screen been tapped once?
    o.wheelScreenDoubleTapTriggered = false

    --- plugins.core.loupedeckctandlive.manager.leftScreenDoubleTapTriggered -> boolean
    --- Variable
    --- Has the wheel screen been tapped once?
    o.leftScreenDoubleTapTriggered = false

    --- plugins.core.loupedeckctandlive.manager.rightScreenDoubleTapTriggered -> boolean
    --- Variable
    --- Has the wheel screen been tapped once?
    o.rightScreenDoubleTapTriggered = false

    --- plugins.core.loupedeckctandlive.manager.tookFingerOffLeftScreen -> boolean
    --- Variable
    --- Took Finger Off Left Screen?
    o.tookFingerOffLeftScreen = false

    --- plugins.core.loupedeckctandlive.manager.tookFingerOffRightScreen -> boolean
    --- Variable
    --- Took Finger Off Right Screen?
    o.tookFingerOffRightScreen = false

    --- plugins.core.loupedeckctandlive.manager.tookFingerOffWheelScreen -> boolean
    --- Variable
    --- Took Finger Off Wheel Screen?
    o.tookFingerOffWheelScreen = false

    --- plugins.core.loupedeckctandlive.manager.lastWheelDoubleTapX -> number
    --- Variable
    --- Last Wheel Double Tap X Position
    o.lastWheelDoubleTapX = nil

    --- plugins.core.loupedeckctandlive.manager.lastWheelDoubleTapY -> number
    --- Variable
    --- Last Wheel Double Tap Y Position
    o.lastWheelDoubleTapY = nil

    --- plugins.core.loupedeckctandlive.manager.connected <cp.prop: boolean>
    --- Field
    --- Is the Loupedeck connected?
    o.connected = prop.FALSE()

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
        local device = o.getDevice()
        device:updateFlashDrive(enabled)
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

    --- plugins.core.loupedeckctandlive.manager.screensBacklightLevel <cp.prop: number>
    --- Field
    --- Screens Backlight Level
    o.screensBacklightLevel = config.prop(o.id .. ".screensBacklightLevel", "9")

    --- plugins.core.loupedeckctandlive.manager.activeBanks <cp.prop: table>
    --- Field
    --- Table of active banks for each application.
    o.activeBanks = config.prop(o.id .. ".activeBanks", {})

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
    o.automaticallySwitchApplications = config.prop(o.id .. ".automaticallySwitchApplications", false):watch(function() o:refresh() end)

    --- plugins.core.loupedeckctandlive.manager.enabled <cp.prop: boolean>
    --- Field
    --- Is Loupedeck support enabled?
    o.enabled = config.prop(o.id .. ".enabled", false):watch(function(enabled)
        if enabled then
            o.appWatcher:start()
            o.driveWatcher:start()
            o.sleepWatcher:start()

            local device = o.getDevice()
            device:connect()
        else
            --------------------------------------------------------------------------------
            -- Stop all watchers:
            --------------------------------------------------------------------------------
            o.appWatcher:stop()
            o.driveWatcher:stop()
            o.sleepWatcher:stop()

            if o.device then
                --------------------------------------------------------------------------------
                -- Make everything black:
                --------------------------------------------------------------------------------
                for _, screen in pairs(loupedeck.screens) do
                    o.device:updateScreenColor(screen, {hex="#"..defaultColor})
                end
                for i=7, 26 do
                    o.device:buttonColor(i, {hex="#" .. defaultColor})
                end

                --------------------------------------------------------------------------------
                -- After a slight delay so the websocket message has time to send...
                --------------------------------------------------------------------------------
                doAfter(0.01, function()
                    --------------------------------------------------------------------------------
                    -- Disconnect from the Loupedeck:
                    --------------------------------------------------------------------------------
                    o.device:disconnect()

                    --------------------------------------------------------------------------------
                    -- Destroy the device:
                    --------------------------------------------------------------------------------
                    o.device = nil
                end)
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- Watch for sleep events:
    --------------------------------------------------------------------------------
    o.sleepWatcher = sleepWatcher.new(function(eventType)
        if eventType == sleepWatcher.systemDidWake then
            if o.enabled() and o.device then
                o.device:disconnect()
                o.device:connect()
            end
        end
        if eventType == sleepWatcher.systemWillSleep then
            if o.enabled() and o.device then
                --------------------------------------------------------------------------------
                -- Make everything black:
                --------------------------------------------------------------------------------
                for _, screen in pairs(loupedeck.screens) do
                    o.device:updateScreenColor(screen, {hex="#"..defaultColor})
                end
                for i=7, 26 do
                    o.device:buttonColor(i, {hex="#" .. defaultColor})
                end

                --------------------------------------------------------------------------------
                -- After a slight delay so the websocket message has time to send...
                --------------------------------------------------------------------------------
                doAfter(0.01, function()
                    --------------------------------------------------------------------------------
                    -- Disconnect from the Loupedeck:
                    --------------------------------------------------------------------------------
                    o.device:disconnect()
                end)
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- Setup watch to refresh the Loupedeck when apps change focus:
    --------------------------------------------------------------------------------
    o.appWatcher = appWatcher.new(function(_, event)
        if o.hasLoaded and event == appWatcher.activated then
            o:refresh(true)
        end
    end)

    --------------------------------------------------------------------------------
    -- Shutdown Callback (make screen black):
    --------------------------------------------------------------------------------
    config.shutdownCallback:new(o.configFolder, function()
        if o.enabled() then
            local device = o.getDevice()
            for _, screen in pairs(loupedeck.screens) do
                device:updateScreenColor(screen, {hex="#"..defaultColor})
            end
            for i=7, 26 do
                device:buttonColor(i, {hex="#" .. defaultColor})
            end
            just.wait(0.01) -- Slight delay so the websocket message has time to send.
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
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = mod.actionmanager
    local numberOfBanks = mod.csman.NUMBER_OF_BANKS
    actionmanager.addHandler("global_" .. o.id .. "_banks")
        :onChoices(function(choices)
            for i=1, numberOfBanks do
                choices:add(o.configFolder .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n(o.i18nID .. "BankDescription"))
                    :params({ id = i })
                    :id(i)
                    :image(icon)
            end

            choices:add(i18n("next") .. " " .. o.configFolder .. " " .. i18n("bank"))
                :subText(i18n(o.i18nID .. "BankDescription"))
                :params({ id = "next" })
                :id("next")
                :image(icon)

            choices:add(i18n("previous") .. " " .. o.configFolder .. " " .. i18n("bank"))
                :subText(i18n(o.i18nID .. "BankDescription"))
                :params({ id = "previous" })
                :id("previous")
                :image(icon)

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then

                local frontmostApplication = application.frontmostApplication()
                local bundleID = frontmostApplication:bundleID()

                local items = o.items()

                --------------------------------------------------------------------------------
                -- Revert to "All Applications" if no settings for frontmost app exist:
                --------------------------------------------------------------------------------
                if not items[bundleID] then
                    bundleID = "All Applications"
                end

                --------------------------------------------------------------------------------
                -- Ignore if ignored:
                --------------------------------------------------------------------------------
                if items[bundleID].ignore and items[bundleID].ignore == true then
                    bundleID = "All Applications"
                end

                --------------------------------------------------------------------------------
                -- If not Automatically Switching Applications:
                --------------------------------------------------------------------------------
                if not o.automaticallySwitchApplications() then
                    bundleID = o.lastBundleID()
                end

                local activeBanks = o.activeBanks()
                local currentBank = activeBanks[bundleID] and tonumber(activeBanks[bundleID]) or 1

                if type(result.id) == "number" then
                    activeBanks[bundleID] = tostring(result.id)
                else
                    if result.id == "next" then
                        if currentBank == numberOfBanks then
                            activeBanks[bundleID] = "1"
                        else
                            activeBanks[bundleID] = tostring(currentBank + 1)
                        end
                    elseif result.id == "previous" then
                        if currentBank == 1 then
                            activeBanks[bundleID] = tostring(numberOfBanks)
                        else
                            activeBanks[bundleID] = tostring(currentBank - 1)
                        end
                    end
                end

                local newBank = activeBanks[bundleID]

                o.activeBanks(activeBanks)

                o:refresh()

                items = o.items() -- Reload items
                local label = items[bundleID] and items[bundleID][newBank] and items[bundleID][newBank]["bankLabel"] or newBank
                displayNotification(i18n("loupedeckCT") .. " " .. i18n("bank") .. ": " .. label)
            end
        end)
        :onActionId(function(action) return "loupedeckCTBank" .. action.id end)

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
            for bundleID, v in pairs(items) do
                if not applications[bundleID] and v.displayName then
                    applications[bundleID] = {}
                    applications[bundleID].displayName = v.displayName
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
            o:refresh()

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

    setmetatable(o, mod.mt)
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
    for _, data in pairs(drives) do
        if data.physical_drive and data.physical_drive.media_name and data.physical_drive.media_name == self.mediaName then
            local path = data.mount_point
            return doesDirectoryExist(path) and path
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
        -- If settings don't already exist on Loupedeck, copy them from Mac:
        --------------------------------------------------------------------------------
        local macPreferencesPath = config.userConfigRootPath .. "/" .. self.configFolder .. "/" .. self.defaultFilename
        local flashDrivePreferencesPath = flashDrivePath .. "/CommandPost/" .. self.defaultFilename
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
        -- Read preferences from Mac:
        --------------------------------------------------------------------------------
        self.items = json.prop(config.userConfigRootPath, self.configFolder, self.defaultFilename, self.defaultLayout)
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

--- plugins.core.loupedeckctandlive.manager:refresh()
--- Method
--- Refreshes the Loupedeck screens and LED buttons.
---
--- Parameters:
---  * dueToAppChange - A optional boolean to specify whether the refresh is due to
---                     an application focus change.
---
--- Returns:
---  * None
function mod.mt:refresh(dueToAppChange)
    local device = o.getDevice()

    local success
    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    --------------------------------------------------------------------------------
    -- If we're refreshing due to an change in application focus, make sure things
    -- have actually changed:
    --------------------------------------------------------------------------------
    if dueToAppChange and bundleID == cachedBundleID then
        cachedBundleID = bundleID
        return
    else
        cachedBundleID = bundleID
    end

    --------------------------------------------------------------------------------
    -- Stop any stray repeat timers:
    --------------------------------------------------------------------------------
    for _, v in pairs(self.repeatTimers) do
        v:stop()
        v = nil -- luacheck: ignore
    end

    local items = self.items()

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
    local bankID = activeBanks[bundleID] or "1"

    --------------------------------------------------------------------------------
    -- TREAT LEFT & RIGHT FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    if self.leftFnPressed then
        bankID = bankID .. "_LeftFn"
    elseif self.rightFnPressed then
        bankID = bankID .. "_RightFn"
    end

    local item = items[bundleID]
    local bank = item and item[bankID]

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
        local ledColor = ledButton and ledButton[id] and ledButton[id].led or defaultColor
        if self.cachedLEDButtonValues[id] ~= ledColor then
            --------------------------------------------------------------------------------
            -- Only update if the colour has changed to save bandwidth:
            --------------------------------------------------------------------------------
            device:buttonColor(i, {hex="#" .. ledColor})
        end
        self.cachedLEDButtonValues[id] = ledColor
    end

    --------------------------------------------------------------------------------
    -- UPDATE TOUCH SCREEN BUTTON IMAGES:
    --------------------------------------------------------------------------------
    local touchButton = bank and bank.touchButton
    for i=1, 12 do
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
        -- Only update if the screen has changed to save bandwidth:
        --------------------------------------------------------------------------------
        if encodedIcon and self.cachedTouchScreenButtonValues[id] == encodedIcon then
            success = true
        elseif encodedIcon and self.cachedTouchScreenButtonValues[id] ~= encodedIcon then
            self.cachedTouchScreenButtonValues[id] = encodedIcon
            local decodedImage = imageFromURL(encodedIcon)
            if decodedImage then
                device:updateScreenButtonImage(i, decodedImage)
                success = true
            end
        end

        if not success and self.cachedTouchScreenButtonValues[id] ~= defaultColor then
            device:updateScreenButtonColor(i, {hex="#"..defaultColor})
            self.cachedTouchScreenButtonValues[id] = defaultColor
        end
    end

    --------------------------------------------------------------------------------
    -- UPDATE WHEEL SCREEN:
    --------------------------------------------------------------------------------
    success = false
    local thisWheel = bank and bank.wheelScreen and bank.wheelScreen["1"]
    local encodedIcon = thisWheel and thisWheel.encodedIcon
    if encodedIcon and self.cachedWheelScreen == encodedIcon then
        success = true
    elseif encodedIcon and self.cachedWheelScreen ~= encodedIcon then
        self.cachedWheelScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            device:updateScreenImage(loupedeck.screens.wheel, decodedImage)
            success = true
        end
    end
    if not success and self.cachedWheelScreen ~= defaultColor then
        device:updateScreenColor(loupedeck.screens.wheel, {hex="#"..defaultColor})
        self.cachedWheelScreen = defaultColor
    end

    --------------------------------------------------------------------------------
    -- UPDATE LEFT SIDE SCREEN:
    --------------------------------------------------------------------------------
    success = false
    local thisSideScreen = bank and bank.sideScreen and bank.sideScreen["1"]
    if thisSideScreen and thisSideScreen.encodedKnobIcon and thisSideScreen.encodedKnobIcon ~= "" then
        encodedIcon = thisSideScreen.encodedKnobIcon
    else
        encodedIcon = thisSideScreen and thisSideScreen.encodedIcon
    end
    if encodedIcon and self.cachedLeftSideScreen == encodedIcon then
        success = true
    elseif encodedIcon and self.cachedLeftSideScreen ~= encodedIcon then
        self.cachedLeftSideScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            device:updateScreenImage(loupedeck.screens.left, decodedImage)
            success = true
        end
    end
    if not success and self.cachedLeftSideScreen ~= defaultColor then
        device:updateScreenColor(loupedeck.screens.left, {hex="#"..defaultColor})
        self.cachedLeftSideScreen = defaultColor
    end

    --------------------------------------------------------------------------------
    -- UPDATE RIGHT SIDE SCREEN:
    --------------------------------------------------------------------------------
    success = false
    thisSideScreen = bank and bank.sideScreen and bank.sideScreen["2"]
    if thisSideScreen and thisSideScreen.encodedKnobIcon and thisSideScreen.encodedKnobIcon ~= "" then
        encodedIcon = thisSideScreen.encodedKnobIcon
    else
        encodedIcon = thisSideScreen and thisSideScreen.encodedIcon
    end
    if encodedIcon and self.cachedRightSideScreen == encodedIcon then
        success = true
    elseif encodedIcon and self.cachedRightSideScreen ~= encodedIcon then
        self.cachedRightSideScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            device:updateScreenImage(loupedeck.screens.right, decodedImage)
            success = true
        end
    end
    if not success and self.cachedRightSideScreen ~= defaultColor then
        device:updateScreenColor(loupedeck.screens.right, {hex="#"..defaultColor})
        self.cachedRightSideScreen = defaultColor
    end
end

-- executeAction(thisAction) -> boolean
-- Function
-- Executes an action.
--
-- Parameters:
--  * thisAction - The action to execute
--
-- Returns:
--  * `true` if successful otherwise `false`
local function executeAction(thisAction)
    if thisAction then
        local handlerID = thisAction.handlerID
        local action = thisAction.action
        if handlerID and action then
            local handler = mod.actionmanager.getHandler(handlerID)
            if handler then
                doAfter(0, function()
                    handler:execute(action)
                end)
                return true
            end
        end
    end
    return false
end

--- plugins.core.loupedeckctandlive.manager:clearCache() -> none
--- Method
--- Clears the cache.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.mt:clearCache()
    --------------------------------------------------------------------------------
    -- Stop any stray repeat timers:
    --------------------------------------------------------------------------------
    for _, v in pairs(self.repeatTimers) do
        v:stop()
        v = nil -- luacheck: ignore
    end

    self.cacheWheelYAxis = nil
    self.cacheWheelXAxis = nil

    self.cacheRightScreenYAxis = nil
    self.cacheLeftScreenYAxis = nil

    self.leftFnPressed = false
    self.rightFnPressed = false

    self.cachedLEDButtonValues = {}
    self.cachedTouchScreenButtonValues = {}

    self.cachedWheelScreen = ""
    self.cachedLeftSideScreen = ""
    self.cachedRightSideScreen = ""

    self.lastWheelDoubleTapX = nil
    self.lastWheelDoubleTapY = nil

    self.hasLoaded = false
end

--- plugins.core.loupedeckctandlive.manager:callback(data) -> none
--- Method
--- The Loupedeck callback.
---
--- Parameters:
---  * data - The callback data.
---
--- Returns:
---  * None
function mod.mt:callback(data)
    --log.df("ct data: %s", hs.inspect(data))

    --------------------------------------------------------------------------------
    -- REFRESH ON INITIAL LOAD AFTER A SLIGHT DELAY:
    --------------------------------------------------------------------------------
    if data.action == "websocket_open" then
        self.connected(true)
        self:clearCache()
        self:refresh()
        self.hasLoaded = true
        self.enableFlashDrive:update()

        self.device:updateBacklightLevel(tonumber(self.screensBacklightLevel()))
        return
    elseif data.action == "websocket_closed" or data.action == "websocket_fail" then
        --------------------------------------------------------------------------------
        -- If the websocket disconnects or fails, then trash all the caches:
        --------------------------------------------------------------------------------
        self.connected(false)
        self:clearCache()
        return
    end

    local bundleID = cachedBundleID

    local items = self.items()

    --------------------------------------------------------------------------------
    -- Revert to "All Applications" if no settings for frontmost app exist:
    --------------------------------------------------------------------------------
    if not items[bundleID] then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- Ignore if ignored:
    --------------------------------------------------------------------------------
    if items[bundleID].ignore and items[bundleID].ignore == true then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- If not Automatically Switching Applications:
    --------------------------------------------------------------------------------
    if not self.automaticallySwitchApplications() then
        bundleID = self.lastBundleID()
    end

    local activeBanks = self.activeBanks()
    local bankID = activeBanks[bundleID] or "1"

    local buttonID = tostring(data.buttonID)

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
                    self.leftFnPressed = false
                    self:refresh()
                end
            elseif data.buttonID == loupedeck.buttonID.RIGHT_FN then
                local button = item[bankID] and item[bankID]["ledButton"] and item[bankID]["ledButton"]["23"]
                local pressAction = button and button["pressAction"]
                if not pressAction or (pressAction and next(pressAction) == nil) then
                    self.rightFnPressed = false
                    self:refresh()
                end
            end
        elseif data.direction == "down" then
            if data.buttonID == loupedeck.buttonID.LEFT_FN then
                local button = item[bankID] and item[bankID]["ledButton"] and item[bankID]["ledButton"]["20"]
                local pressAction = button and button["pressAction"]
                if not pressAction or (pressAction and next(pressAction) == nil) then
                    functionButtonPressed = true
                    self.leftFnPressed = true
                    self:refresh()
                end
            elseif data.buttonID == loupedeck.buttonID.RIGHT_FN then
                local button = item[bankID] and item[bankID]["ledButton"] and item[bankID]["ledButton"]["23"]
                local pressAction = button and button["pressAction"]
                if not pressAction or (pressAction and next(pressAction) == nil) then
                    functionButtonPressed = true
                    self.rightFnPressed = true
                    self:refresh()
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- HANDLE FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    if not functionButtonPressed then
        if self.leftFnPressed then
            bankID = bankID .. "_LeftFn"
        elseif self.rightFnPressed then
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
            if thisButton and executeAction(thisButton.pressAction) then

                -- Repeat if necessary:
                if thisButton.repeatPressActionUntilReleased then
                    self.repeatTimers[buttonID] = doEvery(keyRepeatInterval(), function()
                        executeAction(thisButton.pressAction)
                    end)
                end

                return
            end

            -- Vibrate if needed:
            if thisButton and thisButton.vibratePress then
                self.device:vibrate(tonumber(thisButton.vibratePress))
            end

            --------------------------------------------------------------------------------
            -- KNOB BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisKnob = bank.knob and bank.knob[buttonID]
            if thisKnob and executeAction(thisKnob.pressAction) then
                return
            end

            -- Vibrate if needed:
            if thisKnob and thisKnob.vibratePress then
                self.device:vibrate(tonumber(thisKnob.vibratePress))
            end
        elseif data.id == loupedeck.event.BUTTON_PRESS and data.direction == "up" then
            --------------------------------------------------------------------------------
            -- LED BUTTON RELEASE:
            --------------------------------------------------------------------------------
            local thisButton = bank.ledButton and bank.ledButton[buttonID]

            -- Stop repeating:
            if thisButton and thisButton.repeatPressActionUntilReleased then
                if self.repeatTimers[buttonID] then
                    self.repeatTimers[buttonID]:stop()
                    self.repeatTimers[buttonID] = nil
                end
            end

            if thisButton and executeAction(thisButton.releaseAction) then
                return
            end

            -- Vibrate if needed:
            if thisButton and thisButton.vibrateRelease then
                self.device:vibrate(tonumber(thisButton.vibrateRelease))
            end

            --------------------------------------------------------------------------------
            -- KNOB BUTTON RELEASE:
            --------------------------------------------------------------------------------
            local thisKnob = bank.knob and bank.knob[buttonID]
            if thisKnob and executeAction(thisKnob.releaseAction) then
                return
            end

            -- Vibrate if needed:
            if thisKnob and thisKnob.vibrateRelease then
                self.device:vibrate(tonumber(thisKnob.vibrateRelease))
            end
        elseif data.id == loupedeck.event.ENCODER_MOVE then
            --------------------------------------------------------------------------------
            -- KNOB TURN:
            --------------------------------------------------------------------------------
            local thisKnob = bank.knob and bank.knob[buttonID]
            if thisKnob and executeAction(thisKnob[data.direction.."Action"]) then
                return
            end

            -- Vibrate if needed:
            if data.direction == "left" and thisKnob and thisKnob.vibrateLeft then
                self.device:vibrate(tonumber(thisKnob.vibrateLeft))
            end
            if data.direction == "right" and thisKnob and thisKnob.vibrateRight then
                self.device:vibrate(tonumber(thisKnob.vibrateRight))
            end

            local thisJogWheel = buttonID == "0" and bank.jogWheel and bank.jogWheel["1"]
            if thisJogWheel and executeAction(thisJogWheel[data.direction.."Action"]) then
                return
            end

            -- Vibrate if needed:
            if data.direction == "left" and thisJogWheel and thisJogWheel.vibrateLeft then
                self.device:vibrate(tonumber(thisJogWheel.vibrateLeft))
            end
            if data.direction == "right" and thisJogWheel and thisJogWheel.vibrateRight then
                self.device:vibrate(tonumber(thisJogWheel.vibrateRight))
            end
        elseif data.id == loupedeck.event.SCREEN_PRESSED then
            --------------------------------------------------------------------------------
            -- TOUCH SCREEN BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisTouchButton = bank.touchButton and bank.touchButton[buttonID]

            -- Vibrate if needed:
            if thisTouchButton and thisTouchButton.vibratePress then
                self.device:vibrate(tonumber(thisTouchButton.vibratePress))
            end

            if thisTouchButton and executeAction(thisTouchButton.pressAction) then

                -- Repeat if necessary:
                if thisTouchButton.repeatPressActionUntilReleased then
                    self.repeatTimers[buttonID] = doEvery(keyRepeatInterval(), function()
                        executeAction(thisTouchButton.pressAction)
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
                    if self.cacheLeftScreenYAxis ~= nil then
                        -- already dragging. Which way?
                        local yDiff = data.y - self.cacheLeftScreenYAxis
                        if yDiff < 0-dragMinimumDiff then
                            executeAction(thisSideScreen.upAction)
                        elseif yDiff > 0+dragMinimumDiff then
                            executeAction(thisSideScreen.downAction)
                        end
                    end
                    self.cacheLeftScreenYAxis = data.y

                    --------------------------------------------------------------------------------
                    -- DOUBLE TAP:
                    --------------------------------------------------------------------------------
                    if data.multitouch == 0 and thisSideScreen.doubleTapAction then
                        if self.leftScreenDoubleTapTriggered and self.tookFingerOffLeftScreen then
                            self.leftScreenDoubleTapTriggered = false
                            self.tookFingerOffLeftScreen = false
                            executeAction(thisSideScreen.doubleTapAction)
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
                        executeAction(thisSideScreen.twoFingerTapAction)
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
                    if self.cacheRightScreenYAxis ~= nil then
                        -- already dragging. Which way?
                        local yDiff = data.y - self.cacheRightScreenYAxis
                        if yDiff < 0-dragMinimumDiff then
                            executeAction(thisSideScreen.upAction)
                        elseif yDiff > 0+dragMinimumDiff then
                            executeAction(thisSideScreen.downAction)
                        end
                    end
                    self.cacheRightScreenYAxis = data.y

                    --------------------------------------------------------------------------------
                    -- DOUBLE TAP:
                    --------------------------------------------------------------------------------
                    if data.multitouch == 0 and thisSideScreen.doubleTapAction then
                        if self.rightScreenDoubleTapTriggered and self.tookFingerOffRightScreen then
                            self.rightScreenDoubleTapTriggered = false
                            self.tookFingerOffRightScreen = false
                            executeAction(thisSideScreen.doubleTapAction)
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
                        executeAction(thisSideScreen.twoFingerTapAction)
                    end
                end
            end
        elseif data.id == loupedeck.event.SCREEN_RELEASED then
            --------------------------------------------------------------------------------
            -- SCREEN RELEASED:
            --------------------------------------------------------------------------------
            self.cacheLeftScreenYAxis = nil
            self.cacheRightScreenYAxis = nil
            self.tookFingerOffLeftScreen = true
            self.tookFingerOffRightScreen = true

            --------------------------------------------------------------------------------
            -- TOUCH SCREEN BUTTON RELEASE:
            --------------------------------------------------------------------------------
            local thisTouchButton = bank.touchButton and bank.touchButton[buttonID]

            -- Stop repeating:
            if thisTouchButton and thisTouchButton.repeatPressActionUntilReleased then
                if self.repeatTimers[buttonID] then
                    self.repeatTimers[buttonID]:stop()
                    self.repeatTimers[buttonID] = nil
                end
            end

            -- Vibrate if needed:
            if thisTouchButton and thisTouchButton.vibrateRelease then
                self.device:vibrate(tonumber(thisTouchButton.vibrateRelease))
            end

            if thisTouchButton and executeAction(thisTouchButton.releaseAction) then
                return
            end
        elseif data.id == loupedeck.event.WHEEL_PRESSED then
            local wheelScreen = bank.wheelScreen and bank.wheelScreen["1"]
            if wheelScreen then
                --------------------------------------------------------------------------------
                -- BUTTON PRESS:
                --------------------------------------------------------------------------------
                if wheelScreen.topLeftAction and buttonID == "1" then
                    executeAction(wheelScreen.topLeftAction)
                end
                if wheelScreen.topMiddleAction and buttonID == "2" then
                    executeAction(wheelScreen.topMiddleAction)
                end
                if wheelScreen.topRightAction and buttonID == "3" then
                    executeAction(wheelScreen.topRightAction)
                end
                if wheelScreen.bottomLeftAction and buttonID == "4" then
                    executeAction(wheelScreen.bottomLeftAction)
                end
                if wheelScreen.bottomMiddleAction and buttonID == "5" then
                    executeAction(wheelScreen.bottomMiddleAction)
                end
                if wheelScreen.bottomRightAction and buttonID == "6" then
                    executeAction(wheelScreen.bottomRightAction)
                end

                --------------------------------------------------------------------------------
                -- DRAG WHEEL:
                --------------------------------------------------------------------------------
                if self.cacheWheelXAxis ~= nil and self.cacheWheelYAxis ~= nil then
                    -- we're already dragging. Which way?
                    local xDiff, yDiff = data.x - self.cacheWheelXAxis, data.y - self.cacheWheelYAxis
                    -- dragging horizontally
                    if xDiff < 0-dragMinimumDiff then
                        executeAction(wheelScreen.leftAction)
                    elseif xDiff > 0+dragMinimumDiff then
                        executeAction(wheelScreen.rightAction)
                    end
                    -- dragging vertically
                    if yDiff < 0-dragMinimumDiff then
                        executeAction(wheelScreen.upAction)
                    elseif yDiff > 0+dragMinimumDiff then
                        executeAction(wheelScreen.downAction)
                    end
                end

                --------------------------------------------------------------------------------
                -- CACHE DATA:
                --------------------------------------------------------------------------------
                self.cacheWheelXAxis = data.x
                self.cacheWheelYAxis = data.y

                --------------------------------------------------------------------------------
                -- DOUBLE TAP:
                --------------------------------------------------------------------------------
                if not data.multitouch and wheelScreen.doubleTapAction then

                    local withinRange = self.lastWheelDoubleTapX and self.lastWheelDoubleTapY and
                                        data.x >= (self.lastWheelDoubleTapX - wheelDoubleTapXTolerance) and data.x <= (self.lastWheelDoubleTapX + wheelDoubleTapXTolerance) and
                                        data.y >= (self.lastWheelDoubleTapY - wheelDoubleTapYTolerance) and data.y <= (self.lastWheelDoubleTapY + wheelDoubleTapYTolerance)

                    if self.wheelScreenDoubleTapTriggered and self.tookFingerOffWheelScreen and withinRange then
                        self.wheelScreenDoubleTapTriggered = false
                        self.tookFingerOffWheelScreen = false
                        self.lastWheelDoubleTapX = nil
                        self.lastWheelDoubleTapY = nil
                        executeAction(wheelScreen.doubleTapAction)
                    else
                        self.wheelScreenDoubleTapTriggered = true
                        self.lastWheelDoubleTapX = nil
                        self.lastWheelDoubleTapY = nil
                        doAfter(doubleTapTimeout, function()
                            self.wheelScreenDoubleTapTriggered = false
                            self.tookFingerOffWheelScreen = false
                            self.lastWheelDoubleTapX = nil
                            self.lastWheelDoubleTapY = nil
                        end)
                    end
                end

                --------------------------------------------------------------------------------
                -- TWO FINGER TAP:
                --------------------------------------------------------------------------------
                if data.multitouch then
                    executeAction(wheelScreen.twoFingerTapAction)
                end
            end
        elseif data.id == loupedeck.event.WHEEL_RELEASED then
            self.cacheWheelYAxis = nil
            self.cacheWheelXAxis = nil

            self.lastWheelDoubleTapX = data.x
            self.lastWheelDoubleTapY = data.y

            self.tookFingerOffWheelScreen = true
        end

    end
end

local plugin = {
    id          = "core.loupedeckctandlive.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.application.manager"]        = "applicationmanager",
        ["core.commands.global"]            = "global",
        ["core.controlsurfaces.manager"]    = "csman",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod.actionmanager       = deps.actionmanager
    mod.applicationmanager  = deps.applicationmanager
    mod.csman               = deps.csman
    mod.global              = deps.global

    mod.env                 = env

    --------------------------------------------------------------------------------
    -- Setup devices:
    --------------------------------------------------------------------------------
    mod.devices         = {}
    mod.devices.CT      = mod.new(loupedeck.deviceTypes.CT):refreshItems()
    mod.devices.LIVE    = mod.new(loupedeck.deviceTypes.LIVE):refreshItems()

    return mod
end

return plugin
