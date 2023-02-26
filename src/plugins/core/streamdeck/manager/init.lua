--- === plugins.core.streamdeck.manager ===
---
--- Elgato Stream Deck Manager Plugin.

local require = require

local log                       = require "hs.logger".new "streamDeck"

local application               = require "hs.application"
local appWatcher                = require "hs.application.watcher"
local canvas                    = require "hs.canvas"
local eventtap                  = require "hs.eventtap"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local streamdeck                = require "hs.streamdeck"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local displayNotification       = dialog.displayNotification
local doesFileExist             = tools.doesFileExist
local doEvery                   = timer.doEvery
local imageFromPath             = image.imageFromPath
local imageFromURL              = image.imageFromURL
local isImage                   = tools.isImage
local keyRepeatInterval         = eventtap.keyRepeatInterval
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local spairs                    = tools.spairs

local mod = {}

--- plugins.core.streamdeck.manager.lastApplication <cp.prop: string>
--- Field
--- Last Application used in the Preferences Panel.
mod.lastApplication = config.prop("streamDeck.preferences.lastApplication", "All Applications")

--- plugins.core.streamdeck.manager.lastApplication <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastBank = config.prop("streamDeck.preferences.lastBank", "1")

--- plugins.core.streamdeck.manager.repeatTimers -> table
--- Variable
--- A table containing `hs.timer` objects.
mod.repeatTimers = {}

--- plugins.core.streamdeck.prefs.previewSelectedApplicationAndBankOnHardware <cp.prop: boolean>
--- Field
--- Should we preview the selected application and bank on hardware?
mod.previewSelectedApplicationAndBankOnHardware = config.prop("streamDeck.preferences.previewSelectedApplicationAndBankOnHardware", false)

--- plugins.core.streamdeck.prefs.snippetsRefreshFrequency <cp.prop: string>
--- Field
--- How often snippets are refreshed.
mod.snippetsRefreshFrequency = config.prop("streamDeck.preferences.snippetsRefreshFrequency", "1")

--- plugins.core.streamdeck.manager.automaticallySwitchApplications <cp.prop: boolean>
--- Field
--- Enable or disable the automatic switching of applications.
mod.automaticallySwitchApplications = config.prop("streamDeck.automaticallySwitchApplications", false)

--- plugins.core.streamdeck.manager.lastBundleID <cp.prop: string>
--- Field
--- The last Bundle ID.
mod.lastBundleID = config.prop("streamDeck.lastBundleID", "All Applications")

-- defaultLayoutPath -> string
-- Variable
-- Default Layout Path
local defaultLayoutPath = config.basePath .. "/plugins/core/streamdeck/default/Default.cpStreamDeck"

--- plugins.core.streamdeck.manager.defaultLayout -> table
--- Variable
--- Default Stream Deck Layout
mod.defaultLayout = json.read(defaultLayoutPath)

--- plugins.core.streamdeck.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("streamDeck.activeBanks", {
    ["Mini"] = {},
    ["Original"] = {},
    ["XL"] = {},
    ["Plus"] = {},
})

-- plugins.core.streamdeck.manager.devices -> table
-- Variable
-- Table of Stream Deck Devices.
mod.devices = {
    ["Mini"] = {},
    ["Original"] = {},
    ["XL"] = {},
    ["Plus"] = {},
}

-- plugins.core.streamdeck.manager.deviceOrder -> table
-- Variable
-- Table of Stream Deck Device Orders.
mod.deviceOrder = {
    ["Mini"] = {},
    ["Original"] = {},
    ["XL"] = {},
    ["Plus"] = {},
}

-- plugins.core.streamdeck.manager.numberOfButtons -> table
-- Variable
-- Table of Stream Deck Device Button Count.
mod.numberOfButtons = {
    ["Mini"] = 6,
    ["Original"] = 15,
    ["XL"] = 32,
    ["Plus"] = 8,
}

-- plugins.core.streamdeck.manager.numberOfEncoders -> table
-- Variable
-- Table of Stream Deck Device Encoder Count.
mod.numberOfEncoders = {
    ["Mini"] = 0,
    ["Original"] = 0,
    ["XL"] = 0,
    ["Plus"] = 4,
}

-- plugins.core.streamdeck.manager.buttonSize -> table
-- Variable
-- Table of Stream Deck Button Sizes.
mod.buttonSize = {
    ["Mini"] = 80,
    ["Original"] = 72,
    ["XL"] = 96,
    ["Plus"] = 120,
}

-- plugins.core.streamdeck.manager.encoderSize -> table
-- Variable
-- Table of Encoder Screen Sizes.
mod.encoderSize = {
    ["Plus"] = {width = 200, height = 100},
}

-- imageHolder -> hs.canvas
-- Constant
-- Canvas used to store the blackIcon.
local imageHolder = canvas.new{x = 0, y = 0, h = 120, w = 120}
imageHolder[1] = {
    frame = { h = 120, w = 120, x = 0, y = 0 },
    fillColor = { hex = "#000000" },
    type = "rectangle",
}

-- blackIcon -> hs.image
-- Constant
-- A black icon
local blackIcon = imageHolder:imageFromCanvas()

--- plugins.core.streamdeck.manager.getSnippetImage(device, buttonData, isEncoder) -> string
--- Function
--- Generates the Preference Panel HTML Content.
---
--- Parameters:
---  * device - The device name as a string.
---  * buttonData - A table of button data.
---  * isEncoder - Are we dealing with an encoder?
---
--- Returns:
---  * An encoded image as a string
function mod.getSnippetImage(device, buttonData, isEncoder)
    --------------------------------------------------------------------------------
    -- Handle Snippets:
    --------------------------------------------------------------------------------

    --log.df("buttonData: %s", hs.inspect(buttonData))

    local height
    local width

    if isEncoder then
        width = mod.encoderSize[device].width
        height = mod.encoderSize[device].height
    else
        width = mod.buttonSize[device]
        height = mod.buttonSize[device]
    end

    local currentEncodedIcon
    local currentSnippet = buttonData and buttonData.snippetAction
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
                if size.w == width and size.h == height then
                    --------------------------------------------------------------------------------
                    -- The generated image is already the correct size:
                    --------------------------------------------------------------------------------
                    currentEncodedIcon = result:encodeAsURLString(true)
                else
                    --------------------------------------------------------------------------------
                    -- The generated image is not 90x90 so process:
                    --------------------------------------------------------------------------------
                    local v = canvas.new{x = 0, y = 0, w = width, h = height }

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

    return currentEncodedIcon
end

--- plugins.core.streamdeck.manager.getDeviceType(object) -> string
--- Function
--- Translates a Stream Deck button layout into a device type string.
---
--- Parameters:
---  * object - A `hs.streamdeck` object
---
--- Returns:
---  * "Mini", "Original" or "XL"
function mod.getDeviceType(object)
    --------------------------------------------------------------------------------
    -- Detect Device Type:
    --------------------------------------------------------------------------------
    local columns, rows = object:buttonLayout()
    if columns == 3 and rows == 2 then
        return "Mini"
    elseif columns == 5 and rows == 3 then
        return "Original"
    elseif columns == 8 and rows == 4 then
        return "XL"
    elseif columns == 4 and rows == 2 then
        return "Plus"
    else
        log.ef("Unknown Stream Deck Model. Columns: %s, Rows: %s", columns, rows)
    end
end

--- plugins.core.streamdeck.manager.buttonCallback(object, buttonID, pressed) -> none
--- Function
--- Stream Deck Button Callback
---
--- Parameters:
---  * object - The `hs.streamdeck` userdata object
---  * buttonID - A number containing the button that was pressed/released
---  * pressed - A boolean indicating whether the button was pressed (`true`) or released (`false`)
---
--- Returns:
---  * None
function mod.buttonCallback(object, buttonID, pressed, controlType, turningLeft, turningRight, eventType, startX, startY, endX, endY)
    local serialNumber = object:serialNumber()
    local deviceType = mod.getDeviceType(object)
    local deviceID = mod.deviceOrder[deviceType][serialNumber]

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    --------------------------------------------------------------------------------
    -- Get layout from preferences file:
    --------------------------------------------------------------------------------
    local items = mod.items()
    local deviceData = items[deviceType] and items[deviceType][deviceID]

    --------------------------------------------------------------------------------
    -- Revert to "All Applications" if no settings for frontmost app exist:
    --------------------------------------------------------------------------------
    if deviceData and not deviceData[bundleID] then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- Ignore if ignored:
    --------------------------------------------------------------------------------
    local ignoreData = items[deviceType] and items[deviceType]["1"] and items[deviceType]["1"][bundleID]
    if ignoreData and ignoreData.ignore and ignoreData.ignore == true then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- If not Automatically Switching Applications:
    --------------------------------------------------------------------------------
    if not mod.automaticallySwitchApplications() then
        bundleID = mod.lastBundleID()
    end

    --------------------------------------------------------------------------------
    -- Get the active bank ID:
    --------------------------------------------------------------------------------
    local activeBanks = mod.activeBanks()
    local bankID = activeBanks and activeBanks[deviceType] and activeBanks[deviceType][deviceID] and activeBanks[deviceType][deviceID][bundleID] or "1"

    --------------------------------------------------------------------------------
    -- Preview Selected Application & Bank on Hardware:
    --------------------------------------------------------------------------------
    if mod.previewSelectedApplicationAndBankOnHardware() then
        bundleID = mod.lastApplication()
        bankID = mod.lastBank()
    end

    buttonID = tostring(buttonID)

    local theDevice = items[deviceType]
    local theUnit = theDevice and theDevice[deviceID]
    local theApp = theUnit and theUnit[bundleID]
    local theBank = theApp and theApp[bankID]
    local theButton = theBank and theBank[buttonID]

    --log.df("buttonID: %s", buttonID)
    --log.df("theButton: %s", theButton)

    if controlType == "screen" then
        --------------------------------------------------------------------------------
        -- It's a screen event!
        --
        -- "shortPress", "longPress" or "swipe"
        --------------------------------------------------------------------------------
        --log.df("[SCREEN] object: %s, eventType: %s, startX: %s, startY: %s, endX: %s, endY: %s", object, eventType, startX, startY, endX, endY)

        --log.df("buttonID: %s eventType: %s", buttonID, eventType)

        local screenAction
        if eventType == "shortPress" then
            --------------------------------------------------------------------------------
            -- Short Press:
            --------------------------------------------------------------------------------
            screenAction = theButton and theButton.shortPressAction
        elseif eventType == "longPress" then
            --------------------------------------------------------------------------------
            -- Long Press:
            --------------------------------------------------------------------------------
            screenAction = theButton and theButton.longPressAction
        elseif eventType == "swipe" then
            --------------------------------------------------------------------------------
            -- Swipe:
            --------------------------------------------------------------------------------
            if startX > endX then
                --------------------------------------------------------------------------------
                -- Swipe Left:
                --------------------------------------------------------------------------------
                screenAction = theButton and theButton.swipeLeftAction
            else
                --------------------------------------------------------------------------------
                -- Swipe Right:
                --------------------------------------------------------------------------------
                screenAction = theButton and theButton.swipeRightAction
            end
        else
            log.ef("Unknown Event Type: %s", eventType)
        end

        if screenAction then
            local handlerID = screenAction.handlerID
            local action = screenAction.action
            if handlerID and action then
                --------------------------------------------------------------------------------
                -- Trigger the action:
                --------------------------------------------------------------------------------
                local handler = mod._actionmanager.getHandler(handlerID)
                handler:execute(action)
            end
        end

        return
    elseif controlType == "encoder" then
        --------------------------------------------------------------------------------
        -- It's a encoder event!
        --------------------------------------------------------------------------------
        local encoderAction

        if turningLeft then
            encoderAction = theButton and theButton.leftAction
        elseif turningRight then
            encoderAction = theButton and theButton.rightAction
        end

        if encoderAction then
            local handlerID = encoderAction.handlerID
            local action = encoderAction.action
            if handlerID and action then
                --------------------------------------------------------------------------------
                -- Trigger the action:
                --------------------------------------------------------------------------------
                local handler = mod._actionmanager.getHandler(handlerID)
                handler:execute(action)
            end
        end

        --------------------------------------------------------------------------------
        -- If we're turning left or right, we abort:
        --------------------------------------------------------------------------------
        if turningLeft or turningRight then
            return
        end
    end

    if theButton then
        local repeatPressActionUntilReleased = theButton.repeatPressActionUntilReleased
        local repeatID = deviceType .. deviceID .. buttonID

        if pressed then
            local handlerID = theButton.handlerID
            local action = theButton.action
            if handlerID and action then
                --------------------------------------------------------------------------------
                -- Trigger the press action:
                --------------------------------------------------------------------------------
                local handler = mod._actionmanager.getHandler(handlerID)
                handler:execute(action)

                --------------------------------------------------------------------------------
                -- Repeat if necessary:
                --------------------------------------------------------------------------------
                if repeatPressActionUntilReleased then
                    mod.repeatTimers[repeatID] = doEvery(keyRepeatInterval(), function()
                        handler:execute(action)
                    end)
                end

            end
        else
            --------------------------------------------------------------------------------
            -- Stop repeating if necessary:
            --------------------------------------------------------------------------------
            if repeatPressActionUntilReleased then
                if mod.repeatTimers[repeatID] then
                    mod.repeatTimers[repeatID]:stop()
                    mod.repeatTimers[repeatID] = nil
                end
            end

            --------------------------------------------------------------------------------
            -- Trigger the release action:
            --------------------------------------------------------------------------------
            local releaseAction = theButton.releaseAction
            if releaseAction then
                local handlerID = releaseAction.handlerID
                local action = releaseAction.action
                if handlerID and action then
                    local handler = mod._actionmanager.getHandler(handlerID)
                    handler:execute(action)
                end
            end
        end
    end
end

--- plugins.core.streamdeck.manager.encoderCallback(object, buttonID, pressed, turningLeft, turningRight) -> none
--- Function
--- Stream Deck Screen Callback
---
--- Parameters:
---  * object - The `hs.streamdeck` userdata object
---  * buttonID - The button ID
---  * pressed - Was the encoder pressed?
---  * turnedLeft - Did the encoder turn left?
---  * turnedRight - Did the encoder turn right?
---
--- Returns:
---  * None
function mod.encoderCallback(object, buttonID, pressed, turningLeft, turningRight)
    mod.buttonCallback(object, "Encoder " .. buttonID, pressed, "encoder", turningLeft, turningRight)
end

--- plugins.core.streamdeck.manager.screenCallback(object, eventType, startX, startY, endX, endY) -> none
--- Function
--- Stream Deck Screen Callback
---
--- Parameters:
---  * object - The `hs.streamdeck` userdata object
---  * eventType - The event type as a string
---  * startX - The X position when first pressed
---  * startY - The Y position when first pressed
---  * endX - The X position when released
---  * endY - The Y position when released
---
--- Returns:
---  * None
function mod.screenCallback(object, eventType, startX, startY, endX, endY)

    --------------------------------------------------------------------------------
    -- Determine the button ID based on the screen position:
    --------------------------------------------------------------------------------
    local buttonID
    if startX <= 200 then
        buttonID = "Screen 1"
    elseif startX <= 400 then
        buttonID = "Screen 2"
    elseif startX <= 600 then
        buttonID = "Screen 3"
    elseif startX <= 800 then
        buttonID = "Screen 4"
    else
        log.df("Unknown Screen Button - startX: %s", startX)
    end

    mod.buttonCallback(object, buttonID, nil, "screen", nil, nil, eventType, startX, startY, endX, endY)
end

--- plugins.core.streamdeck.manager.imageCache() -> none
--- Variable
--- A cache of images used on the Stream Deck.
mod.imageCache = {}

--- plugins.core.streamdeck.manager.update() -> none
--- Function
--- Updates the screens of all Stream Deck devices.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()

    local containsIconSnippets = false

    for deviceType, devices in pairs(mod.devices) do
        for _, device in pairs(devices) do
            --------------------------------------------------------------------------------
            -- Determine bundleID:
            --------------------------------------------------------------------------------
            local serialNumber = device:serialNumber()

            local deviceID = mod.deviceOrder[deviceType][serialNumber]

            local frontmostApplication = application.frontmostApplication()
            local bundleID = frontmostApplication:bundleID()

            --------------------------------------------------------------------------------
            -- Get layout from preferences file:
            --------------------------------------------------------------------------------
            local items = mod.items()
            local deviceData = items[deviceType] and items[deviceType][deviceID]

            --------------------------------------------------------------------------------
            -- Revert to "All Applications" if no settings for frontmost app exist:
            --------------------------------------------------------------------------------
            if deviceData and not deviceData[bundleID] then
                bundleID = "All Applications"
            end

            --------------------------------------------------------------------------------
            -- Ignore if ignored:
            --------------------------------------------------------------------------------
            local ignoreData = items[deviceType] and items[deviceType]["1"] and items[deviceType]["1"][bundleID]
            if ignoreData and ignoreData.ignore and ignoreData.ignore == true then
                bundleID = "All Applications"
            end

            --------------------------------------------------------------------------------
            -- If not Automatically Switching Applications:
            --------------------------------------------------------------------------------
            if not mod.automaticallySwitchApplications() then
                bundleID = mod.lastBundleID()
            end

            --------------------------------------------------------------------------------
            -- Determine bankID:
            --------------------------------------------------------------------------------
            local activeBanks = mod.activeBanks()
            local bankID = activeBanks and activeBanks[deviceType] and activeBanks[deviceType][deviceID] and activeBanks[deviceType][deviceID][bundleID] or "1"

            --------------------------------------------------------------------------------
            -- Preview Selected Application & Bank on Hardware:
            --------------------------------------------------------------------------------
            if mod.previewSelectedApplicationAndBankOnHardware() then
                bundleID = mod.lastApplication()
                bankID = mod.lastBank()
            end

            --------------------------------------------------------------------------------
            -- Get bank data:
            --------------------------------------------------------------------------------
            local bankData = deviceData and deviceData[bundleID] and deviceData[bundleID][bankID]

            --------------------------------------------------------------------------------
            -- Update every button:
            --------------------------------------------------------------------------------
            local buttonCount = mod.numberOfButtons[deviceType]
            for buttonID=1, buttonCount do
                local success = false
                local buttonData = bankData and bankData[tostring(buttonID)]

                local imageToUse

                if buttonData then
                    local label                 = buttonData.label
                    local icon                  = buttonData.icon
                    local encodedIconLabel      = buttonData.encodedIconLabel

                    local snippetImage = mod.getSnippetImage(deviceType, buttonData, false)
                    if snippetImage then
                        --------------------------------------------------------------------------------
                        -- Generate an icon from a Snippet:
                        --------------------------------------------------------------------------------
                        local theImage = imageFromURL(snippetImage)
                        if theImage then
                            imageToUse = theImage
                            success = true
                            containsIconSnippets = true
                        end
                    elseif icon then
                        --------------------------------------------------------------------------------
                        -- Draw an icon:
                        --------------------------------------------------------------------------------
                        local theImage = imageFromURL(icon)
                        if theImage then
                            imageToUse = theImage
                            success = true
                        end
                    elseif buttonData.encodedIconLabel then
                        --------------------------------------------------------------------------------
                        -- Draw an image from an icon label:
                        --------------------------------------------------------------------------------
                        local theImage = imageFromURL(encodedIconLabel)
                        if theImage then
                            imageToUse = theImage
                            success = true
                        end
                    elseif label then
                        --------------------------------------------------------------------------------
                        -- Draw a label (only here for legacy reasons):
                        --------------------------------------------------------------------------------
                        local widthAndHeight = mod.buttonSize[device]
                        local c = canvas.new{x = 0, y = 0, h = widthAndHeight, w = widthAndHeight}
                        c[1] = {
                            frame = { h = widthAndHeight, w = widthAndHeight, x = 0, y = 0 },
                            fillColor = { hex = "#000000"  },
                            type = "rectangle",
                        }
                        c[2] = {
                            frame = { h = widthAndHeight, w = widthAndHeight, x = 0, y = 0 },
                            text = label,
                            textAlignment = "left",
                            textColor = { white = 1.0 },
                            textSize = 20,
                            type = "text",
                        }
                        local textIcon = c:imageFromCanvas()

                        imageToUse = textIcon
                        success = true
                    end
                end
                if not success then
                    --------------------------------------------------------------------------------
                    -- Default to black if no label or icon supplied:
                    --------------------------------------------------------------------------------
                    imageToUse = blackIcon
                end

                --------------------------------------------------------------------------------
                -- Only update the image on the hardware if necessary:
                --------------------------------------------------------------------------------
                local cacheID = deviceType .. deviceID .. buttonID
                if imageToUse ~= mod.imageCache[cacheID] then
                    device:setButtonImage(buttonID, imageToUse)
                    mod.imageCache[cacheID] = imageToUse
                end
            end

            --------------------------------------------------------------------------------
            -- Update every encoder screen:
            --------------------------------------------------------------------------------
            local encoderCount = mod.numberOfEncoders[deviceType]
            for buttonID=1, encoderCount do
                local success = false
                local buttonData = bankData and bankData["Screen " .. tostring(buttonID)]

                local imageToUse

                if buttonData then
                    local label                 = buttonData.label
                    local icon                  = buttonData.icon
                    local encodedIconLabel      = buttonData.encodedIconLabel

                    local snippetImage = mod.getSnippetImage(deviceType, buttonData, true)
                    if snippetImage then
                        --------------------------------------------------------------------------------
                        -- Generate an icon from a Snippet:
                        --------------------------------------------------------------------------------
                        local theImage = imageFromURL(snippetImage)
                        if theImage then
                            imageToUse = theImage
                            success = true
                            containsIconSnippets = true
                        end
                    elseif icon then
                        --------------------------------------------------------------------------------
                        -- Draw an icon:
                        --------------------------------------------------------------------------------
                        local theImage = imageFromURL(icon)
                        if theImage then
                            imageToUse = theImage
                            success = true
                        end
                    elseif buttonData.encodedIconLabel then
                        --------------------------------------------------------------------------------
                        -- Draw an image from an icon label:
                        --------------------------------------------------------------------------------
                        local theImage = imageFromURL(encodedIconLabel)
                        if theImage then
                            imageToUse = theImage
                            success = true
                        end
                    elseif label then
                        --------------------------------------------------------------------------------
                        -- Draw a label (only here for legacy reasons):
                        --------------------------------------------------------------------------------
                        local width = mod.encoderSize[device].width
                        local height = mod.encoderSize[device].height

                        local c = canvas.new{x = 0, y = 0, h = height, w = width}
                        c[1] = {
                            frame = { h = height, w = width, x = 0, y = 0 },
                            fillColor = { hex = "#000000"  },
                            type = "rectangle",
                        }
                        c[2] = {
                            frame = { h = height, w = width, x = 0, y = 0 },
                            text = label,
                            textAlignment = "left",
                            textColor = { white = 1.0 },
                            textSize = 20,
                            type = "text",
                        }
                        local textIcon = c:imageFromCanvas()

                        imageToUse = textIcon
                        success = true
                    end
                end
                if not success then
                    --------------------------------------------------------------------------------
                    -- Default to black if no label or icon supplied:
                    --------------------------------------------------------------------------------
                    imageToUse = blackIcon
                end

                --------------------------------------------------------------------------------
                -- Only update the image on the hardware if necessary:
                --------------------------------------------------------------------------------
                local cacheID = deviceType .. deviceID .. "screen" .. buttonID
                if imageToUse ~= mod.imageCache[cacheID] then
                    device:setScreenImage(buttonID, imageToUse)
                    mod.imageCache[cacheID] = imageToUse
                end
            end

        end
    end

    --------------------------------------------------------------------------------
    -- Enable or disable the refresh timer:
    --------------------------------------------------------------------------------
    if containsIconSnippets then
        if not mod.refreshTimer then
            local snippetsRefreshFrequency = tonumber(mod.snippetsRefreshFrequency())
            mod.refreshTimer = timer.new(snippetsRefreshFrequency, function()
                mod.update()
            end)
        end
        mod.refreshTimer:start()
    else
        if mod.refreshTimer then
            mod.refreshTimer:stop()
            mod.refreshTimer = nil
        end
    end
end

--- plugins.core.streamdeck.manager.discoveryCallback(connected, object) -> none
--- Function
--- Stream Deck Discovery Callback
---
--- Parameters:
---  * connected - A boolean, `true` if a device was connected, `false` if a device was disconnected
---  * object - An `hs.streamdeck` object, being the device that was connected/disconnected
---
--- Returns:
---  * None
function mod.discoveryCallback(connected, object)
    local serialNumber = object:serialNumber()
    if serialNumber == nil then
        log.ef("Failed to get Stream Deck's Serial Number. This normally means the Stream Deck App is running.")
    else
        local deviceType = mod.getDeviceType(object)
        if connected then
            --log.df("Stream Deck Connected: %s - %s", deviceType, serialNumber)
            mod.devices[deviceType][serialNumber] = object:buttonCallback(mod.buttonCallback)

            --------------------------------------------------------------------------------
            -- If it's a Stream Deck Plus we need to add an encoder and screen callback:
            --------------------------------------------------------------------------------
            if deviceType == "Plus" then
                object:screenCallback(mod.screenCallback)
                object:encoderCallback(mod.encoderCallback)
            end

            --------------------------------------------------------------------------------
            -- Sort the devices alphabetically based on serial number:
            --------------------------------------------------------------------------------
            local count = 1
            for sn, _ in spairs(mod.devices[deviceType], function(_,a,b) return a < b end) do
                mod.deviceOrder[deviceType][sn] = tostring(count)
                count = count + 1
            end

            mod.update()
        else
            if mod.devices and mod.devices[deviceType][serialNumber] then
                --log.df("Stream Deck Disconnected: %s - %s", deviceType, serialNumber)
                mod.devices[deviceType][serialNumber] = nil
            else
                log.ef("Disconnected Stream Deck wasn't previously registered: %s - %s", deviceType, serialNumber)
            end
        end
    end
end

--- plugins.core.streamdeck.manager.start() -> boolean
--- Function
--- Starts the Stream Deck Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    --------------------------------------------------------------------------------
    -- Setup watch to refresh the Stream Deck's when apps change focus:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function(_, event)
        if event == appWatcher.activated then
            mod.update()
        end
    end):start()

    --------------------------------------------------------------------------------
    -- Initialise Stream Deck support:
    --------------------------------------------------------------------------------
    streamdeck.init(mod.discoveryCallback)
end

--- plugins.core.streamdeck.manager.start() -> boolean
--- Function
--- Stops the Stream Deck Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    --------------------------------------------------------------------------------
    -- Stop any stray repeat timers:
    --------------------------------------------------------------------------------
    for id, _ in ipairs(mod.repeatTimers) do
        mod.repeatTimer[id]:stop()
        mod.repeatTimer[id] = nil
    end
    mod.repeatTimers = {}

    --------------------------------------------------------------------------------
    -- Black out all the buttons and screens:
    --------------------------------------------------------------------------------
    for deviceType, devices in pairs(mod.devices) do
        for _, device in pairs(devices) do
            local buttonCount = mod.numberOfButtons[deviceType]
            for buttonID=1, buttonCount do
                device:setButtonImage(buttonID, blackIcon)
            end

            local encoderCount = mod.numberOfEncoders[deviceType]
            for encoderID=1, encoderCount do
                device:setScreenImage(encoderID, blackIcon)
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Kill any devices:
    --------------------------------------------------------------------------------
    for deviceType, devices in pairs(mod.devices) do
        for serialNumber, _ in pairs(devices) do
            mod.devices[deviceType][serialNumber] = nil
        end
    end

    --------------------------------------------------------------------------------
    -- Kill the app watcher:
    --------------------------------------------------------------------------------
    if mod._appWatcher then
        mod._appWatcher:stop()
        mod._appWatcher = nil
    end

    --------------------------------------------------------------------------------
    -- Empty the cache:
    --------------------------------------------------------------------------------
    mod.imageCache = {}
end

--- plugins.core.streamdeck.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Stream Deck Support.
mod.enabled = config.prop("enableStreamDesk", false):watch(function(enabled)
    if enabled then
        mod.start()
    else
        mod.stop()
    end
end)

local plugin = {
    id          = "core.streamdeck.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]                 = "actionmanager",
        ["core.commands.global"]                = "global",
        ["core.application.manager"]            = "appmanager",
        ["core.controlsurfaces.manager"]        = "csman",
        ["core.preferences.panels.scripting"]   = "scriptingPreferences",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Migrate old preferences to newer format if 'Settings.cpStreamDeck' doesn't
    -- already exist, and if we haven't already upgraded previously:
    --------------------------------------------------------------------------------
    local newLayoutExists = doesFileExist(config.userConfigRootPath .. "/Stream Deck/Settings.cpStreamDeck")
    mod.items = json.prop(config.userConfigRootPath, "Stream Deck", "Settings.cpStreamDeck", mod.defaultLayout)
    if not newLayoutExists then
        local updatedPreferencesToV2 = config.prop("streamdeck.updatedPreferencesToV2", false)
        local legacyPath = config.userConfigRootPath .. "/Stream Deck/Default.cpStreamDeck"
        if doesFileExist(legacyPath) and not updatedPreferencesToV2() then
            local legacyPreferences = json.read(legacyPath)
            local newData = {}
            if legacyPreferences then
                for groupID, data in pairs(legacyPreferences) do
                    local bundleID
                    local bankID
                    if string.sub(groupID, 1, 4) == "fcpx" then
                        bundleID = "com.apple.FinalCut"
                        bankID = string.sub(groupID, 5)
                    end
                    if string.sub(groupID, 1, 6) == "global" then
                        bundleID = "All Applications"
                        bankID = string.sub(groupID, 7)
                    end

                    if not newData["Original"] then newData["Original"] = {} end
                    if not newData["Original"]["1"] then newData["Original"]["1"] = {} end
                    if not newData["Original"]["1"][bundleID] then newData["Original"]["1"][bundleID] = {} end
                    newData["Original"]["1"][bundleID][bankID] = fnutils.copy(data)
                end
                updatedPreferencesToV2(true)
                mod.items(newData)
                log.df("Converted Stream Deck Preferences from Default.cpStreamDeck to Settings.cpStreamDeck.")
            end
        end
    end

    local icon = imageFromPath(env:pathToAbsolute("/../prefs/images/streamdeck.icns"))

    --------------------------------------------------------------------------------
    -- Shared dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager          = deps.actionmanager
    mod._scriptingPreferences   = deps.scriptingPreferences

    --------------------------------------------------------------------------------
    -- Setup action:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("cpStreamDeck")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")
        :image(icon)

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    local numberOfBanks = deps.csman.NUMBER_OF_BANKS
    local numberOfDevices = deps.csman.NUMBER_OF_DEVICES
    actionmanager.addHandler("global_streamDeckbanks")
        :onChoices(function(choices)
            for device, _ in pairs(mod.devices) do
                for unit=1, numberOfDevices do

                    local deviceLabel = device
                    if deviceLabel == "Original" then
                        deviceLabel = ""
                    else
                        deviceLabel = deviceLabel .. " "
                    end

                    for bank=1, numberOfBanks do
                        choices:add("Stream Deck " .. deviceLabel .. i18n("bank") .. " " .. tostring(bank) .. " (Unit " .. unit .. ")")
                            :subText(i18n("streamDeckBankDescription"))
                            :params({
                                action = "bank",
                                device = device,
                                unit = tostring(unit),
                                bank = bank,
                                id = device .. "_" .. unit .. "_" .. tostring(bank),
                            })
                            :id(device .. "_" .. unit .. "_" .. tostring(bank))
                            :image(icon)
                    end

                    choices
                        :add(i18n("next") .. " Stream Deck " .. deviceLabel .. i18n("bank") .. " (Unit " .. unit .. ")")
                        :subText(i18n("streamDeckBankDescription"))
                        :params({
                            action = "next",
                            device = device,
                            unit = tostring(unit),
                            id = device .. "_" .. unit .. "_nextBank"
                        })
                        :id(device .. "_" .. unit .. "_nextBank")
                        :image(icon)

                    choices
                        :add(i18n("previous") .. " Stream Deck " .. deviceLabel .. i18n("bank") .. " (Unit " .. unit .. ")")
                        :subText(i18n("streamDeckBankDescription"))
                        :params({
                            action = "previous",
                            device = device,
                            unit = tostring(unit),
                            id = device .. "_" .. unit .. "_previousBank",
                        })
                        :id(device .. "_" .. unit .. "_previousBank")
                        :image(icon)
                end
            end
            return choices
        end)
        :onExecute(function(result)
            if result then
                local device = result.device
                local unit = result.unit

                local frontmostApplication = application.frontmostApplication()
                local bundleID = frontmostApplication:bundleID()

                local items = mod.items()

                local unitData = items[device] and items[device]["1"] -- The ignore preference is stored on unit 1.

                --------------------------------------------------------------------------------
                -- Revert to "All Applications" if no settings for frontmost app exist:
                --------------------------------------------------------------------------------
                if unitData and not unitData[bundleID] then
                    bundleID = "All Applications"
                end

                --------------------------------------------------------------------------------
                -- Ignore if ignored:
                --------------------------------------------------------------------------------
                local ignoreData = items[device] and items[device]["1"] and items[device]["1"][bundleID]
                if ignoreData and ignoreData.ignore and ignoreData.ignore == true then
                    bundleID = "All Applications"
                end

                local activeBanks = mod.activeBanks()

                if not activeBanks[device] then activeBanks[device] = {} end
                if not activeBanks[device][unit] then activeBanks[device][unit] = {} end

                local currentBank = activeBanks and activeBanks[device] and activeBanks[device][unit] and activeBanks[device][unit][bundleID] or "1"

                if result.action == "bank" then
                    activeBanks[device][unit][bundleID] = tostring(result.bank)
                elseif result.action == "next" then
                    if tonumber(currentBank) == numberOfBanks then
                        activeBanks[device][unit][bundleID] = "1"
                    else
                        activeBanks[device][unit][bundleID] = tostring(tonumber(currentBank) + 1)
                    end
                elseif result.action == "previous" then
                    if tonumber(currentBank) == 1 then
                        activeBanks[device][unit][bundleID] = tostring(numberOfBanks)
                    else
                        activeBanks[device][unit][bundleID] = tostring(tonumber(currentBank) - 1)
                    end
                end

                local newBank = activeBanks[device][unit][bundleID]

                mod.activeBanks(activeBanks)

                mod.update()

                items = mod.items() -- Reload items
                local label = items[bundleID] and items[bundleID][newBank] and items[bundleID][newBank]["bankLabel"] or newBank

                local deviceLabel = device
                if deviceLabel == "Original" then
                    deviceLabel = ""
                else
                    deviceLabel = deviceLabel .. " "
                end

                displayNotification("Stream Deck " .. deviceLabel .. "(Unit " .. unit .. ") " .. i18n("bank") .. ": " .. label)
            end
        end)
        :onActionId(function(action) return "streamDeckBank" .. action.id end)

    --------------------------------------------------------------------------------
    -- Actions to Manually Change Application:
    --------------------------------------------------------------------------------
    local applicationmanager = deps.appmanager
    actionmanager.addHandler("global_streamdeckapplications", "global")
        :onChoices(function(choices)
            local applications = applicationmanager.getApplications()

            applications["All Applications"] = {
                displayName = "All Applications",
            }

            -- Add User Added Applications from Loupedeck Preferences:
            local items = mod.items()

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
                    :add(i18n("switchStreamDeckTo") .. " " .. item.displayName)
                    :subText(i18n("streamDeckAppDescription"))
                    :params({
                        bundleID = bundleID,
                    })
                    :id("global_streamdeckapplications_switch_" .. bundleID)
                    :image(icon)

                if bundleID ~= "All Applications" then
                    choices
                        :add(i18n("switchStreamDeckTo") .. " " .. item.displayName .. " " .. i18n("andLaunch"))
                        :subText(i18n("streamDeckAppDescription"))
                        :params({
                            bundleID = bundleID,
                            launch = true,
                        })
                        :id("global_streamdeckapplications_launch_" .. bundleID)
                        :image(icon)
                end
            end
        end)
        :onExecute(function(action)
            local bundleID = action.bundleID
            mod.lastBundleID(bundleID)

            --------------------------------------------------------------------------------
            -- Refresh all devices:
            --------------------------------------------------------------------------------
            mod.update()

            if action.launch then
                launchOrFocusByBundleID(bundleID)
            end
        end)
        :onActionId(function(params)
            return "global_streamdeckapplications_" .. params.bundleID
        end)
        :cached(false)

    return mod
end

function plugin.postInit()
    if mod.enabled() then
        mod.start()
    end
end

return plugin
