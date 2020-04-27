--- === plugins.core.loupedeckct.manager ===
---
--- Loupedeck CT Manager Plugin.

local require               = require

local hs                    = hs

--local log                   = require "hs.logger".new "ldCT"

local application           = require "hs.application"
local appWatcher            = require "hs.application.watcher"
local ct                    = require "hs.loupedeckct"
local fs                    = require "hs.fs"
local image                 = require "hs.image"
local plist                 = require "hs.plist"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local dialog                = require "cp.dialog"
local i18n                  = require "cp.i18n"
local json                  = require "cp.json"
local just                  = require "cp.just"
local prop                  = require "cp.prop"
local tools                 = require "cp.tools"

local displayNotification   = dialog.displayNotification
local doAfter               = timer.doAfter
local doesDirectoryExist    = tools.doesDirectoryExist
local doesFileExist         = tools.doesFileExist
local ensureDirectoryExists = tools.ensureDirectoryExists
local execute               = hs.execute
local imageFromURL          = image.imageFromURL
local readString            = plist.readString

local mod = {}

-- fileExtension -> string
-- Variable
-- File Extension for Loupedeck CT
local fileExtension = ".cpLoupedeckCT"

-- defaultFilename -> string
-- Variable
-- Default Filename for Loupedeck CT Settings
local defaultFilename = "Default" .. fileExtension

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

-- hasLoaded -> boolean
-- Variable
-- Has the Loupedeck CT loaded?
local hasLoaded = false

-- leftFnPressed -> boolean
-- Variable
-- Is the left Function button pressed?
local leftFnPressed = false

-- rightFnPressed -> boolean
-- Variable
-- Is the right Function button pressed?
local rightFnPressed = false

-- cachedLEDButtonValues -> table
-- Variable
-- Table of cached LED button values.
local cachedLEDButtonValues = {}

-- cachedTouchScreenButtonValues -> table
-- Variable
-- Table of cached Touch Screen button values.
local cachedTouchScreenButtonValues = {}

-- cachedWheelScreen -> string
-- Variable
-- The last wheel screen data sent.
local cachedWheelScreen = ""

-- cachedLeftSideScreen -> string
-- Variable
-- The last screen data sent.
local cachedLeftSideScreen = ""

-- cachedRightSideScreen -> string
-- Variable
-- The last screen data sent.
local cachedRightSideScreen = ""

-- cachedTouchScreenButtonValues -> string
-- Variable
-- The last bundle ID processed.
local cachedBundleID = ""

-- cacheWheelYAxis -> number
-- Variable
-- Wheel Y Axis Cache
local cacheWheelYAxis = nil

-- cacheWheelXAxis -> number
-- Variable
-- Wheel X Axis Cache
local cacheWheelXAxis = nil

-- cacheLeftScreenYAxis -> number
-- Variable
-- Right Screen Y Axis Cache
local cacheLeftScreenYAxis = nil

-- cacheRightScreenYAxis -> number
-- Variable
-- Right Screen Y Axis Cache
local cacheRightScreenYAxis = nil

-- wheelScreenDoubleTapTriggered -> boolean
-- Variable
-- Has the wheel screen been tapped once?
local wheelScreenDoubleTapTriggered = false

-- leftScreenDoubleTapTriggered -> boolean
-- Variable
-- Has the wheel screen been tapped once?
local leftScreenDoubleTapTriggered = false

-- rightScreenDoubleTapTriggered -> boolean
-- Variable
-- Has the wheel screen been tapped once?
local rightScreenDoubleTapTriggered = false

-- tookFingerOffLeftScreen -> boolean
-- Variable
-- Took Finger Off Left Screen?
local tookFingerOffLeftScreen = false

-- tookFingerOffRightScreen -> boolean
-- Variable
-- Took Finger Off Right Screen?
local tookFingerOffRightScreen = false

-- tookFingerOffWheelScreen -> boolean
-- Variable
-- Took Finger Off Wheel Screen?
local tookFingerOffWheelScreen = false

-- lastWheelDoubleTapX -> number
-- Variable
-- Last Wheel Double Tap X Position
local lastWheelDoubleTapX = nil

-- lastWheelDoubleTapY -> number
-- Variable
-- Last Wheel Double Tap Y Position
local lastWheelDoubleTapY = nil

-- wheelDoubleTapXTolerance -> number
-- Variable
-- Last Wheel Double Tap X Tolerance
local wheelDoubleTapXTolerance = 12

-- wheelDoubleTapYTolerance -> number
-- Variable
-- Last Wheel Double Tap Y Tolerance
local wheelDoubleTapYTolerance = 7

--- plugins.core.loupedeckct.manager.connected <cp.prop: boolean>
--- Field
--- Is Loupedeck CT connected?
mod.connected = prop.FALSE()

--- plugins.core.loupedeckct.manager.enabled <cp.prop: boolean>
--- Field
--- Is Loupedeck CT support enabled?
mod.enabled = config.prop("loupedeckct.enabled", false):watch(function(enabled)
    if enabled then
        mod._appWatcher:start()
        mod._driveWatcher:start()
        ct.connect(true)
    else
        --------------------------------------------------------------------------------
        -- Stop all watchers:
        --------------------------------------------------------------------------------
        mod._appWatcher:stop()
        mod._driveWatcher:stop()

        --------------------------------------------------------------------------------
        -- Make everything black:
        --------------------------------------------------------------------------------
        for _, screen in pairs(ct.screens) do
                ct.updateScreenColor(screen, {hex="#"..defaultColor})
        end
        for i=7, 26 do
            ct.buttonColor(i, {hex="#" .. defaultColor})
        end
        just.wait(0.01) -- Slight delay so the websocket message has time to send.

        --------------------------------------------------------------------------------
        -- Disconnect from the Loupedeck CT:
        --------------------------------------------------------------------------------
        ct.disconnect()
    end
end)

-- defaultLayoutPath -> string
-- Variable
-- Default Layout Path
local defaultLayoutPath = config.basePath .. "/plugins/core/loupedeckct/default/Default.cpLoupedeckCT"

--- plugins.core.loupedeckct.manager.defaultLayout -> table
--- Variable
--- Default Loupedeck CT Layout
mod.defaultLayout = json.read(defaultLayoutPath)

-- getFlashDrivePath() -> string
-- Function
-- Gets the Loupedeck CT Flash Drive path.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The Loupedeck CT Flash Drive path as a string
local function getFlashDrivePath()
    local storage = execute("system_profiler SPStorageDataType -xml")
    local storagePlist = storage and readString(storage)
    local drives = storagePlist and storagePlist[1] and storagePlist[1]._items
    for _, data in pairs(drives) do
        if data.physical_drive and data.physical_drive.media_name and data.physical_drive.media_name == "LD-CT CT Media" then
            local path = data.mount_point
            return doesDirectoryExist(path) and path
        end
    end
end

--- plugins.core.loupedeckct.manager.enableFlashDrive <cp.prop: boolean>
--- Field
--- Enable or disable the Loupedeck CT Flash Drive.
mod.enableFlashDrive = config.prop("loupedeckct.enableFlashDrive", true):watch(function(enabled)
    ct.updateFlashDrive(enabled)
    if not enabled then
        local path = getFlashDrivePath()
        if path then
            fs.volume.eject(path)
        end
    end
end)

--- plugins.core.loupedeckct.manager.items <cp.prop: table>
--- Field
--- Contains all the saved Loupedeck CT layouts.
mod.items = nil

-- refreshItems() -> none
-- Function
-- Refreshes mod.items to either
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function refreshItems()
    local flashDrivePath = getFlashDrivePath()

    if mod.loadSettingsFromDevice() and flashDrivePath then
        --------------------------------------------------------------------------------
        -- If settings don't already exist on Loupedeck CT, copy them from Mac:
        --------------------------------------------------------------------------------
        local macPreferencesPath = config.userConfigRootPath .. "/Loupedeck CT/" .. defaultFilename
        local flashDrivePreferencesPath = flashDrivePath .. "/CommandPost/" .. defaultFilename
        if not doesFileExist(flashDrivePreferencesPath) then
            if ensureDirectoryExists(flashDrivePath, "CommandPost") then
                local existingSettings = json.read(macPreferencesPath) or mod.defaultLayout
                json.write(flashDrivePreferencesPath, existingSettings)
            end
        end

        --------------------------------------------------------------------------------
        -- Read preferences from Flash Drive:
        --------------------------------------------------------------------------------
        mod.items = json.prop(flashDrivePath, "CommandPost", defaultFilename, mod.defaultLayout, function()
            refreshItems()
        end):watch(function()
            local data = mod.items()
            local path = config.userConfigRootPath .. "/Loupedeck CT/" .. defaultFilename
            json.write(path, data)
        end)
        return
    else
        --------------------------------------------------------------------------------
        -- Read preferences from Mac:
        --------------------------------------------------------------------------------
        mod.items = json.prop(config.userConfigRootPath, "Loupedeck CT", defaultFilename, mod.defaultLayout)
    end
end

--- plugins.core.loupedeckct.manager.loadSettingsFromDevice <cp.prop: boolean>
--- Field
--- Load settings from device.
mod.loadSettingsFromDevice = config.prop("loupedeckct.loadSettingsFromDevice", false):watch(function(enabled)
    if enabled then
        local existingSettings = json.read(config.userConfigRootPath .. "/Loupedeck CT/" .. defaultFilename)
        local path = config.userConfigRootPath .. "/Loupedeck CT/Backup " .. os.date("%Y%m%d %H%M") .. fileExtension
        json.write(path, existingSettings)
    end
    refreshItems()
end)

--- plugins.core.loupedeckct.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("loupedeckct.activeBanks", {})

--- plugins.core.loupedeckct.manager.reset()
--- Function
--- Resets the config back to the default layout.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.reset()
    mod.items(mod.defaultLayout)
end

--- plugins.core.loupedeckct.manager.refresh()
--- Function
--- Refreshes the Loupedeck CT screens and LED buttons.
---
--- Parameters:
---  * dueToAppChange - A optional boolean to specify whether the refresh is due to
---                     an application focus change.
---
--- Returns:
---  * None
function mod.refresh(dueToAppChange)
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

    local items = mod.items()

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

    local activeBanks = mod.activeBanks()
    local bankID = activeBanks[bundleID] or "1"

    --------------------------------------------------------------------------------
    -- TREAT LEFT & RIGHT FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    if leftFnPressed then
        bankID = bankID .. "_LeftFn"
    elseif rightFnPressed then
        bankID = bankID .. "_RightFn"
    end

    local item = items[bundleID]
    local bank = item and item[bankID]

    --------------------------------------------------------------------------------
    -- UPDATE LED BUTTON COLOURS:
    --------------------------------------------------------------------------------
    local ledButton = bank and bank.ledButton
    for i=7, 26 do
        local id = tostring(i)
        local ledColor = ledButton and ledButton[id] and ledButton[id].led or defaultColor
        if cachedLEDButtonValues[id] ~= ledColor then
            --------------------------------------------------------------------------------
            -- Only update if the colour has changed to save bandwidth:
            --------------------------------------------------------------------------------
            ct.buttonColor(i, {hex="#" .. ledColor})
        end
        cachedLEDButtonValues[id] = ledColor
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
        if encodedIcon and cachedTouchScreenButtonValues[id] == encodedIcon then
            success = true
        elseif encodedIcon and cachedTouchScreenButtonValues[id] ~= encodedIcon then
            cachedTouchScreenButtonValues[id] = encodedIcon
            local decodedImage = imageFromURL(encodedIcon)
            if decodedImage then
                ct.updateScreenButtonImage(i, decodedImage)
                success = true
            end
        end

        if not success and cachedTouchScreenButtonValues[id] ~= defaultColor then
            ct.updateScreenButtonColor(i, {hex="#"..defaultColor})
            cachedTouchScreenButtonValues[id] = defaultColor
        end
    end

    --------------------------------------------------------------------------------
    -- UPDATE WHEEL SCREEN:
    --------------------------------------------------------------------------------
    success = false
    local thisWheel = bank and bank.wheelScreen and bank.wheelScreen["1"]
    local encodedIcon = thisWheel and thisWheel.encodedIcon
    if encodedIcon and cachedWheelScreen == encodedIcon then
        success = true
    elseif encodedIcon and cachedWheelScreen ~= encodedIcon then
        cachedWheelScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            ct.updateScreenImage(ct.screens.wheel, decodedImage)
            success = true
        end
    end
    if not success and cachedWheelScreen ~= defaultColor then
        ct.updateScreenColor(ct.screens.wheel, {hex="#"..defaultColor})
        cachedWheelScreen = defaultColor
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
    if encodedIcon and cachedLeftSideScreen == encodedIcon then
        success = true
    elseif encodedIcon and cachedLeftSideScreen ~= encodedIcon then
        cachedLeftSideScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            ct.updateScreenImage(ct.screens.left, decodedImage)
            success = true
        end
    end
    if not success and cachedLeftSideScreen ~= defaultColor then
        ct.updateScreenColor(ct.screens.left, {hex="#"..defaultColor})
        cachedLeftSideScreen = defaultColor
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
    if encodedIcon and cachedRightSideScreen == encodedIcon then
        success = true
    elseif encodedIcon and cachedRightSideScreen ~= encodedIcon then
        cachedRightSideScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            ct.updateScreenImage(ct.screens.right, decodedImage)
            success = true
        end
    end
    if not success and cachedRightSideScreen ~= defaultColor then
        ct.updateScreenColor(ct.screens.right, {hex="#"..defaultColor})
        cachedRightSideScreen = defaultColor
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
            local handler = mod._actionmanager.getHandler(handlerID)
            handler:execute(action)
            return true
        end

    end
    return false
end

-- clearCache() -> none
-- Function
-- Clears the cache.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function clearCache()
    cacheWheelYAxis = nil
    cacheWheelXAxis = nil

    cacheRightScreenYAxis = nil
    cacheLeftScreenYAxis = nil

    leftFnPressed = false
    rightFnPressed = false

    cachedLEDButtonValues = {}
    cachedTouchScreenButtonValues = {}

    cachedWheelScreen = ""
    cachedLeftSideScreen = ""
    cachedRightSideScreen = ""

    lastWheelDoubleTapX = nil
    lastWheelDoubleTapY = nil

    hasLoaded = false
end

-- callback(data) -> none
-- Function
-- The Loupedeck CT callback.
--
-- Parameters:
--  * data - The callback data.
--
-- Returns:
--  * None
local function callback(data)
    --log.df("ct data: %s", hs.inspect(data))

    --------------------------------------------------------------------------------
    -- REFRESH ON INITIAL LOAD AFTER A SLIGHT DELAY:
    --------------------------------------------------------------------------------
    if data.action == "websocket_open" then
        mod.connected(true)
        clearCache()
        mod.refresh()
        hasLoaded = true
        mod.enableFlashDrive:update()
        return
    elseif data.action == "websocket_closed" or data.action == "websocket_fail" then
        --------------------------------------------------------------------------------
        -- If the websocket disconnects or fails, then trash all the caches:
        --------------------------------------------------------------------------------
        mod.connected(false)
        clearCache()
        return
    end

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    local items = mod.items()

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

    local activeBanks = mod.activeBanks()
    local bankID = activeBanks[bundleID] or "1"

    local buttonID = tostring(data.buttonID)

    --------------------------------------------------------------------------------
    -- TREAT LEFT & RIGHT FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    local functionButtonPressed = false
    if data.id == ct.event.BUTTON_PRESS then
        if data.direction == "up" then
            if data.buttonID == ct.buttonID.LEFT_FN then
                leftFnPressed = false
                mod.refresh()
            elseif data.buttonID == ct.buttonID.RIGHT_FN then
                rightFnPressed = false
                mod.refresh()
            end
        elseif data.direction == "down" then
            if data.buttonID == ct.buttonID.LEFT_FN then
                functionButtonPressed = true
                leftFnPressed = true
                mod.refresh()
            elseif data.buttonID == ct.buttonID.RIGHT_FN then
                functionButtonPressed = true
                rightFnPressed = true
                mod.refresh()
            end
        end
    end

    --------------------------------------------------------------------------------
    -- HANDLE FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    if not functionButtonPressed then
        if leftFnPressed then
            bankID = bankID .. "_LeftFn"
        elseif rightFnPressed then
            bankID = bankID .. "_RightFn"
        end
    end

    local item = items[bundleID]
    local bank = item and item[bankID]

    if bank then
        if data.id == ct.event.BUTTON_PRESS and data.direction == "down" then
            --------------------------------------------------------------------------------
            -- LED BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisButton = bank.ledButton and bank.ledButton[buttonID]
            if thisButton and executeAction(thisButton.pressAction) then
                return
            end

            --------------------------------------------------------------------------------
            -- KNOB BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisKnob = bank.knob and bank.knob[buttonID]
            if thisKnob and executeAction(thisKnob.pressAction) then
                return
            end
        elseif data.id == ct.event.ENCODER_MOVE then
            local thisKnob = bank.knob and bank.knob[buttonID]
            if thisKnob and executeAction(thisKnob[data.direction.."Action"]) then
                return
            end

            local thisJogWheel = buttonID == "0" and bank.jogWheel and bank.jogWheel["1"]
            if thisJogWheel and executeAction(thisJogWheel[data.direction.."Action"]) then
                return
            end
        elseif data.id == ct.event.SCREEN_PRESSED then
            --------------------------------------------------------------------------------
            -- TOUCH SCREEN BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisTouchButton = bank.touchButton and bank.touchButton[buttonID]

            -- Vibrate if needed:
            if thisTouchButton and thisTouchButton.vibrate then
                ct.vibrate(tonumber(thisTouchButton.vibrate))
            end

            if thisTouchButton and executeAction(thisTouchButton.pressAction) then
                return
            end

            --------------------------------------------------------------------------------
            -- LEFT TOUCH SCREEN:
            --------------------------------------------------------------------------------
            if data.screenID == ct.screens.left.id then
                local thisSideScreen = bank.sideScreen and bank.sideScreen["1"]
                if thisSideScreen then
                    --------------------------------------------------------------------------------
                    -- SLIDE UP/DOWN:
                    --------------------------------------------------------------------------------
                    if cacheLeftScreenYAxis ~= nil then
                        -- already dragging. Which way?
                        local yDiff = data.y - cacheLeftScreenYAxis
                        if yDiff < 0-dragMinimumDiff then
                            executeAction(thisSideScreen.upAction)
                        elseif yDiff > 0+dragMinimumDiff then
                            executeAction(thisSideScreen.downAction)
                        end
                    end
                    cacheLeftScreenYAxis = data.y

                    --------------------------------------------------------------------------------
                    -- DOUBLE TAP:
                    --------------------------------------------------------------------------------
                    if data.multitouch == 0 and thisSideScreen.doubleTapAction then
                        if leftScreenDoubleTapTriggered and tookFingerOffLeftScreen then
                            leftScreenDoubleTapTriggered = false
                            tookFingerOffLeftScreen = false
                            executeAction(thisSideScreen.doubleTapAction)
                        else
                            leftScreenDoubleTapTriggered = true
                            doAfter(doubleTapTimeout, function()
                                leftScreenDoubleTapTriggered = false
                                tookFingerOffLeftScreen = false
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
            if data.screenID == ct.screens.right.id then
                --------------------------------------------------------------------------------
                -- SLIDE UP/DOWN:
                --------------------------------------------------------------------------------
                local thisSideScreen = bank.sideScreen and bank.sideScreen["2"]
                if thisSideScreen then
                    if cacheRightScreenYAxis ~= nil then
                        -- already dragging. Which way?
                        local yDiff = data.y - cacheRightScreenYAxis
                        if yDiff < 0-dragMinimumDiff then
                            executeAction(thisSideScreen.upAction)
                        elseif yDiff > 0+dragMinimumDiff then
                            executeAction(thisSideScreen.downAction)
                        end
                    end
                    cacheRightScreenYAxis = data.y

                    --------------------------------------------------------------------------------
                    -- DOUBLE TAP:
                    --------------------------------------------------------------------------------
                    if data.multitouch == 0 and thisSideScreen.doubleTapAction then
                        if rightScreenDoubleTapTriggered and tookFingerOffRightScreen then
                            rightScreenDoubleTapTriggered = false
                            tookFingerOffRightScreen = false
                            executeAction(thisSideScreen.doubleTapAction)
                        else
                            rightScreenDoubleTapTriggered = true
                            doAfter(doubleTapTimeout, function()
                                rightScreenDoubleTapTriggered = false
                                tookFingerOffRightScreen = false
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
        elseif data.id == ct.event.SCREEN_RELEASED then
            cacheLeftScreenYAxis = nil
            cacheRightScreenYAxis = nil
            tookFingerOffLeftScreen = true
            tookFingerOffRightScreen = true
        elseif data.id == ct.event.WHEEL_PRESSED then
            local wheelScreen = bank.wheelScreen and bank.wheelScreen["1"]
            if wheelScreen then
                --------------------------------------------------------------------------------
                -- DRAG WHEEL:
                --------------------------------------------------------------------------------
                if cacheWheelXAxis ~= nil and cacheWheelYAxis ~= nil then
                    -- we're already dragging. Which way?
                    local xDiff, yDiff = data.x - cacheWheelXAxis, data.y - cacheWheelYAxis
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
                cacheWheelXAxis = data.x
                cacheWheelYAxis = data.y

                --------------------------------------------------------------------------------
                -- DOUBLE TAP:
                --------------------------------------------------------------------------------
                if not data.multitouch and wheelScreen.doubleTapAction then

                    local withinRange = lastWheelDoubleTapX and lastWheelDoubleTapY and
                                        data.x >= (lastWheelDoubleTapX - wheelDoubleTapXTolerance) and data.x <= (lastWheelDoubleTapX + wheelDoubleTapXTolerance) and
                                        data.y >= (lastWheelDoubleTapY - wheelDoubleTapYTolerance) and data.y <= (lastWheelDoubleTapY + wheelDoubleTapYTolerance)

                    if wheelScreenDoubleTapTriggered and tookFingerOffWheelScreen and withinRange then
                        wheelScreenDoubleTapTriggered = false
                        tookFingerOffWheelScreen = false
                        lastWheelDoubleTapX = nil
                        lastWheelDoubleTapY = nil
                        executeAction(wheelScreen.doubleTapAction)
                    else
                        wheelScreenDoubleTapTriggered = true
                        lastWheelDoubleTapX = nil
                        lastWheelDoubleTapY = nil
                        doAfter(doubleTapTimeout, function()
                            wheelScreenDoubleTapTriggered = false
                            tookFingerOffWheelScreen = false
                            lastWheelDoubleTapX = nil
                            lastWheelDoubleTapY = nil
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
        elseif data.id == ct.event.WHEEL_RELEASED then
            cacheWheelYAxis = nil
            cacheWheelXAxis = nil

            lastWheelDoubleTapX = data.x
            lastWheelDoubleTapY = data.y

            tookFingerOffWheelScreen = true
        end

    end
end

local plugin = {
    id          = "core.loupedeckct.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.application.manager"]        = "appmanager",
        ["core.controlsurfaces.manager"]    = "csman",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Refresh mod.items:
    --------------------------------------------------------------------------------
    refreshItems()

    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Setup the Loupedeck CT callback:
    --------------------------------------------------------------------------------
    ct.callback(callback)

    --------------------------------------------------------------------------------
    -- Setup watch to refresh the Loupedeck CT when apps change focus:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function(_, event)
        if hasLoaded and event == appWatcher.activated then
            mod.refresh(true)
        end
    end)

    --------------------------------------------------------------------------------
    -- Watch for drive changes:
    --------------------------------------------------------------------------------
    mod._driveWatcher = fs.volume.new(function()
        refreshItems()
    end)

    --------------------------------------------------------------------------------
    -- Connect to the Loupedeck CT:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    local numberOfBanks = deps.csman.NUMBER_OF_BANKS
    actionmanager.addHandler("global_loupedeckct_banks")
        :onChoices(function(choices)
            for i=1, numberOfBanks do
                choices:add(i18n("loupedeckCT") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("loupedeckCTBankDescription"))
                    :params({ id = i })
                    :id(i)
            end

            choices:add(i18n("next") .. " " .. i18n("loupedeckCT") .. " " .. i18n("bank"))
                :subText(i18n("loupedeckCTBankDescription"))
                :params({ id = "next" })
                :id("next")

            choices:add(i18n("previous") .. " " .. i18n("loupedeckCT") .. " " .. i18n("bank"))
                :subText(i18n("loupedeckCTBankDescription"))
                :params({ id = "previous" })
                :id("previous")

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then

                local frontmostApplication = application.frontmostApplication()
                local bundleID = frontmostApplication:bundleID()

                local items = mod.items()

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

                local activeBanks = mod.activeBanks()
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

                mod.activeBanks(activeBanks)

                mod.refresh()

                items = mod.items() -- Reload items
                local label = items[bundleID] and items[bundleID][newBank] and items[bundleID][newBank]["bankLabel"] or newBank
                displayNotification(i18n("loupedeckCT") .. " " .. i18n("bank") .. ": " .. label)
            end
        end)
        :onActionId(function(action) return "loupedeckCTBank" .. action.id end)

    --------------------------------------------------------------------------------
    -- Shutdown Callback (make screen black):
    --------------------------------------------------------------------------------
    config.shutdownCallback:new("loupedeckCT", function()
        if mod.enabled() then
            for _, screen in pairs(ct.screens) do
                ct.updateScreenColor(screen, {hex="#"..defaultColor})
            end
            for i=7, 26 do
                ct.buttonColor(i, {hex="#" .. defaultColor})
            end
            just.wait(0.01) -- Slight delay so the websocket message has time to send.
        end
    end)

    return mod
end

return plugin
