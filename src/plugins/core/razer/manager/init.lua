--- === plugins.core.razer.manager ===
---
--- Razer Manager Plugin.

local require                   = require

local log                       = require "hs.logger".new "razer"

local application               = require "hs.application"
local appWatcher                = require "hs.application.watcher"
local eventtap                  = require "hs.eventtap"
local image                     = require "hs.image"
local sleepWatcher              = require "hs.caffeinate.watcher"
local timer                     = require "hs.timer"
local fnutils                   = require "hs.fnutils"

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local copy                      = fnutils.copy
local displayNotification       = dialog.displayNotification
local doAfter                   = timer.doAfter
local doEvery                   = timer.doEvery
local imageFromPath             = image.imageFromPath
local isColor                   = tools.isColor
local keyRepeatInterval         = eventtap.keyRepeatInterval
local tableCount                = tools.tableCount
local tableMatch                = tools.tableMatch

local mod = {}

-- razer -> hs.razer object
-- Variable
-- The Razer extension. We only want to load it when Razer support is enabled.
local razer

--- plugins.core.razer.manager.supportedDevices -> table
--- Constant
--- Table supported devices.
mod.supportedDevices = {"Razer Tartarus V2"}

-- fileExtension -> string
-- Variable
-- File Extension for Loupedeck CT
local fileExtension = ".cpRazer"

-- defaultFilename -> string
-- Variable
-- Default Filename for Loupedeck CT Settings
local defaultFilename = "Default" .. fileExtension

-- defaultLayoutPath -> string
-- Variable
-- Default Layout Path
local defaultLayoutPath = config.basePath .. "/plugins/core/razer/default/Default.cpRazer"

--- plugins.core.razer.manager.defaultLayout -> table
--- Variable
--- Default Loupedeck CT Layout
mod.defaultLayout = json.read(defaultLayoutPath)

--- plugins.core.razer.manager.items <cp.prop: table>
--- Field
--- Contains all the saved TourBox layouts.
mod.items = json.prop(config.userConfigRootPath, "Razer", defaultFilename, mod.defaultLayout)

--- plugins.core.razer.manager.automaticallySwitchApplications <cp.prop: boolean>
--- Field
--- Enable or disable the automatic switching of applications.
mod.automaticallySwitchApplications = config.prop("razer.automaticallySwitchApplications", {
    ["Razer Tartarus V2"] = true,
})

--- plugins.core.razer.manager.displayMessageWhenChangingBanks <cp.prop: boolean>
--- Field
--- Display message when changing banks?
mod.displayMessageWhenChangingBanks = config.prop("razer.displayMessageWhenChangingBanks", {
    ["Razer Tartarus V2"] = true,
})

--- plugins.core.razer.manager.lastBundleID <cp.prop: table>
--- Field
--- The last used bundle ID.
mod.lastBundleID = config.prop("razer.lastBundleID", {
    ["Razer Tartarus V2"] = "All Applications",
})

--- plugins.core.razer.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("razer.activeBanks", {
    ["Razer Tartarus V2"] = {},
})

--- plugins.core.razer.manager.bankLabels -> table
--- Constant
--- Table of bank labels, which reflect the LED icons.
mod.bankLabels = {
    ["Razer Tartarus V2"] = {
        ["1"] = {
            label   = "1 (Off)",
            orange  = false,
            green   = false,
            blue    = false
        },
        ["2"] = {
            label   = "2 (Orange)",
            orange  = true,
            green   = false,
            blue    = false
        },
        ["3"] = {
            label   = "3 (Green)",
            orange  = false,
            green   = true,
            blue    = false
        },
        ["4"] = {
            label   = "4 (Blue)",
            orange  = false,
            green   = false,
            blue    = true
        },
        ["5"] = {
            label   = "5 (Orange/Green)",
            orange  = true,
            green   = true,
            blue    = false
        },
        ["6"] = {
            label   = "6 (Orange/Blue)",
            orange  = true,
            green   = false,
            blue    = true
        },
        ["7"] = {
            label   = "7 (Green/Blue)",
            orange  = false,
            green   = true,
            blue    = true
        }
    }
}

--- plugins.core.razer.manager.backlightsMode <cp.prop: table>
--- Field
--- The backlights mode for all the Razer devices.
mod.backlightsMode = config.prop("razer.preferences.backlightsMode", {
    ["Razer Tartarus V2"] = "User Defined"
})

--- plugins.core.razer.manager.backlightBrightness <cp.prop: table>
--- Field
--- The backlights brightness for all the Razer devices.
mod.backlightBrightness = config.prop("razer.preferences.backlightBrightness", {
    ["Razer Tartarus V2"] = "100"
})

--- plugins.core.razer.manager.backlightEffectColorA <cp.prop: table>
--- Field
--- The backlight effect primary color.
mod.backlightEffectColorA = config.prop("razer.preferences.backlightEffectColorA", {
    ["Razer Tartarus V2"] = "000000"
})

--- plugins.core.razer.manager.backlightEffectColorB <cp.prop: table>
--- Field
--- The backlight effect secondary color.
mod.backlightEffectColorB = config.prop("razer.preferences.backlightEffectColorB", {
    ["Razer Tartarus V2"] = "000000"
})

--- plugins.core.razer.manager.backlightEffectDirection <cp.prop: table>
--- Field
--- The backlight effect direction.
mod.backlightEffectDirection = config.prop("razer.preferences.backlightEffectDirection", {
    ["Razer Tartarus V2"] = "left"
})

--- plugins.core.razer.manager.backlightEffectSpeed <cp.prop: table>
--- Field
--- The backlight effect speed.
mod.backlightEffectSpeed = config.prop("razer.preferences.backlightEffectSpeed", {
    ["Razer Tartarus V2"] = "1"
})

--- plugins.core.razer.manager -> table
--- Variable
--- A table of Razer devices.
mod.devices = {}

-- repeatTimers -> table
-- Variable
-- A table containing all the repeat timers
local repeatTimers = {}

-- cachedBundleID -> string
-- Variable
-- The last bundle ID processed.
local cachedBundleID = ""

-- cachedLedValues -> table
-- Variable
-- A table of cached LED values
local cachedStatusLights = {}

-- cachedLedMode -> table
-- Variable
-- A table of cached LED values
local cachedLedMode = {}

-- cachedCustomColors -> table
-- Variable
-- A table of cached custom colors
local cachedCustomColors = {}

-- resetStatusLights(device) -> none
-- Function
-- Reset Status Lights
--
-- Parameters:
--  * device - A hs.razer object
--
-- Returns:
--  * None
local function resetStatusLights(device)
    local deviceName = device:name()
    if deviceName == "Razer Tartarus V2" then
        cachedStatusLights[deviceName]["orange"] = false
        cachedStatusLights[deviceName]["green"] = false
        cachedStatusLights[deviceName]["blue"] = false

        device:orangeStatusLight(false)
        device:greenStatusLight(false)
        device:blueStatusLight(false)
    end
end

-- setStatusLights(device, orange, green, blue) -> none
-- Function
-- Sets the Status Lights on a Razer Device.
--
-- Parameters:
--  * device - The Razer device object
--  * orange - Whether or not the orange light is on or off as a boolean
--  * green - Whether or not the green light is on or off as a boolean
--  * blue - Whether or not the blue light is on or off as a boolean
--
-- Returns:
--  * None
local function setStatusLights(device, orange, green, blue)
    local deviceName = device:name()
    if deviceName == "Razer Tartarus V2" then
        if not cachedStatusLights[deviceName]["orange"] == orange then
            device:orangeStatusLight(orange)
        end

        if not cachedStatusLights[deviceName]["green"] == green then
            device:greenStatusLight(green)
        end

        if not cachedStatusLights[deviceName]["blue"] == blue then
            device:blueStatusLight(blue)
        end

        cachedStatusLights[deviceName]["orange"] = orange
        cachedStatusLights[deviceName]["green"] = green
        cachedStatusLights[deviceName]["blue"] = blue
    end
end

--- plugins.core.razer.manager.refresh() -> none
--- Function
--- Refreshes the LEDs on a Razer device.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.refresh()
    for _, device in pairs(mod.devices) do
        --------------------------------------------------------------------------------
        -- Get settings from preferences:
        --------------------------------------------------------------------------------
        local deviceName = device:name()
        local backlightsMode = mod.backlightsMode()
        local currentMode = backlightsMode[deviceName]

        local backlightBrightness = mod.backlightBrightness()
        local brightness = backlightBrightness and backlightBrightness[deviceName] and tonumber(backlightBrightness[deviceName])

        local backlightEffectColorA = mod.backlightEffectColorA()
        local backlightEffectColorB = mod.backlightEffectColorB()

        local backlightEffectDirection = mod.backlightEffectDirection()
        local backlightEffectSpeed = mod.backlightEffectSpeed()

        local speed = backlightEffectSpeed and backlightEffectSpeed[deviceName] and tonumber(backlightEffectSpeed[deviceName])
        local direction = backlightEffectDirection and backlightEffectDirection[deviceName]

        local colorA = backlightEffectColorA and backlightEffectColorA[deviceName] and {hex=backlightEffectColorA[deviceName]}
        local colorB = backlightEffectColorB and backlightEffectColorB[deviceName] and {hex=backlightEffectColorB[deviceName]}

        --------------------------------------------------------------------------------
        -- Get Device Name, and data from Layout File:
        --------------------------------------------------------------------------------
        local bundleID = cachedBundleID

        local items = mod.items()
        if not items[deviceName] then
            items[deviceName] = {}
        end
        if not items[deviceName][bundleID] then
            items[deviceName][bundleID] = {}
        end

        --------------------------------------------------------------------------------
        -- Revert to "All Applications" if no settings for frontmost app exist:
        --------------------------------------------------------------------------------
        if not items[deviceName][bundleID] then
            bundleID = "All Applications"
        end

        --------------------------------------------------------------------------------
        -- Ignore if ignored:
        --------------------------------------------------------------------------------
        if items[deviceName][bundleID].ignore then
            bundleID = "All Applications"
        end

        --------------------------------------------------------------------------------
        -- If not Automatically Switching Applications:
        --------------------------------------------------------------------------------
        if not mod.automaticallySwitchApplications()[deviceName] then
            local lastBundleID = mod.lastBundleID()
            bundleID = lastBundleID and lastBundleID[deviceName]
        end

        --------------------------------------------------------------------------------
        -- Get data from settings:
        --------------------------------------------------------------------------------
        local activeBanks = mod.activeBanks()
        local activeBanksForDevice = activeBanks and activeBanks[deviceName]
        local bankID = activeBanksForDevice and activeBanksForDevice[bundleID] or "1"

        local item = items[deviceName] and items[deviceName][bundleID]
        local bank = item and item[bankID]
        local buttons = bank and bank.button
        local scrollWheels = bank and bank.scrollWheel

        --------------------------------------------------------------------------------
        -- Brightness:
        --------------------------------------------------------------------------------
        device:brightness(brightness)

        --------------------------------------------------------------------------------
        -- Update status lights based on current bank:
        --------------------------------------------------------------------------------
        local statusLights = mod.bankLabels[deviceName][bankID]
        setStatusLights(device, statusLights.orange, statusLights.green, statusLights.blue)

        --------------------------------------------------------------------------------
        -- We only update the LEDs if they actually need changing (to avoid messing
        -- up any LED animation cycles):
        --------------------------------------------------------------------------------
        if currentMode == "User Defined" then
            --------------------------------------------------------------------------------
            -- Custom:
            --------------------------------------------------------------------------------
            local customColors = {}

            --------------------------------------------------------------------------------
            -- Process LEDs for the Razer Tartarus V2:
            --------------------------------------------------------------------------------
            if deviceName == "Razer Tartarus V2" then

                --------------------------------------------------------------------------------
                -- Update Scroll Wheel:
                --------------------------------------------------------------------------------
                local scrollWheel = scrollWheels and scrollWheels["1"]
                local led = scrollWheel and scrollWheel.led
                if led then
                    customColors[23] = {hex="#"..led}
                end

                --------------------------------------------------------------------------------
                -- Update Button LEDs:
                --------------------------------------------------------------------------------
                for i=1, 20 do
                    local offset = 0
                    if i > 5 then offset = 1 end
                    if i > 10 then offset = 2 end
                    if i > 15 then offset = 3 end
                    if i > 19 then offset = 4 end

                    local button = buttons and buttons[tostring(i)]

                    --------------------------------------------------------------------------------
                    -- If there's a Snippet to assign the LED color, use that instead:
                    --------------------------------------------------------------------------------
                    local snippetAction = button and button.ledSnippetAction
                    local snippetResult
                    if snippetAction and snippetAction.action then
                        local code = snippetAction.action.code
                        if code then
                            --------------------------------------------------------------------------------
                            -- Use the latest Snippet from the Snippets Preferences if it exists:
                            --------------------------------------------------------------------------------
                            local snippets = mod._scriptingPreferences.snippets()
                            local savedSnippet = snippets[snippetAction.action.id]
                            if savedSnippet and savedSnippet.code then
                                code = savedSnippet.code
                            end

                            local successful, result = pcall(load(code))
                            if type(successful) and isColor(result) then
                                snippetResult = result
                            end
                        end
                    end

                    local buttonLed = snippetResult or (button and button.led)
                    if buttonLed then
                        if isColor(buttonLed) then
                            customColors[i + offset] = buttonLed
                        else
                            customColors[i + offset] = {hex="#"..buttonLed}
                        end
                    end
                end
            end

            if not tableMatch(cachedCustomColors[deviceName], customColors) then
                device:backlightsCustom(customColors)
            end

            --------------------------------------------------------------------------------
            -- Cache the colour matrix, so we don't send it more than once:
            --------------------------------------------------------------------------------
            cachedCustomColors[deviceName] = copy(customColors)
        elseif not (cachedLedMode[deviceName] == currentMode) then
            --------------------------------------------------------------------------------
            -- Kill the custom colours cache:
            --------------------------------------------------------------------------------
            cachedCustomColors[deviceName] = {}

            if currentMode == "Off" then
                --------------------------------------------------------------------------------
                -- Off:
                --------------------------------------------------------------------------------
                device:backlightsOff()
            elseif currentMode == "Wave" then
                --------------------------------------------------------------------------------
                -- Wave:
                --
                --  * speed - A number between 1 (fast) and 255 (slow)
                --  * direction - "left" or "right" as a string
                --------------------------------------------------------------------------------
                device:backlightsWave(speed, direction)
            elseif currentMode == "Spectrum" then
                --------------------------------------------------------------------------------
                -- Spectrum:
                --------------------------------------------------------------------------------
                device:backlightsSpectrum()
            elseif currentMode == "Reactive" then
                --------------------------------------------------------------------------------
                -- Reactive:
                --
                --  * speed - A number between 1 (fast) and 4 (slow)
                --  * color - A `hs.drawing.color` object
                --------------------------------------------------------------------------------
                device:backlightsReactive(speed, colorA)
            elseif currentMode == "Static" then
                --------------------------------------------------------------------------------
                -- Static:
                --
                --  * color - A `hs.drawing.color` object.
                --------------------------------------------------------------------------------
                device:backlightsStatic(colorA)
            elseif currentMode == "Starlight" then
                --------------------------------------------------------------------------------
                -- Starlight:
                --
                --  * speed - A number between 1 (fast) and 3 (slow)
                --  * [color] - An optional `hs.drawing.color` value
                --  * [secondaryColor] - An optional secondary `hs.drawing.color`
                --------------------------------------------------------------------------------
                device:backlightsStarlight(speed, colorA, colorB)
            elseif currentMode == "Breathing" then
                --------------------------------------------------------------------------------
                -- Breathing:
                --
                --  * [color] - An optional `hs.drawing.color` value
                --  * [secondaryColor] - An optional secondary `hs.drawing.color`
                --------------------------------------------------------------------------------
                device:backlightsBreathing(colorA, colorB)
            end
        end

        --------------------------------------------------------------------------------
        -- Cache the current LED mode ID:
        --------------------------------------------------------------------------------
        cachedLedMode[deviceName] = currentMode
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

-- razerCallback(obj, buttonName, buttonAction) -> none
-- Function
-- Razer Callback.
--
-- Parameters:
--  * `obj` - The serial port object that triggered the callback.
--  * `buttonName` - The name of the button as a string.
--  * `buttonAction` - A string containing "pressed", "released", "up" or "down".
--
-- Returns:
--  * None
local function razerCallback(obj, buttonName, buttonAction)
    --------------------------------------------------------------------------------
    -- Translate Control Type & ID:
    --------------------------------------------------------------------------------
    local controlType
    local controlID
    if buttonName == "Up" or buttonName == "Down" or buttonName == "Left" or buttonName == "Right" then
        controlType = "joystick"
        controlID = "1"
    elseif buttonName == "Scroll Wheel" then
        controlType = "scrollWheel"
        controlID = "1"
    elseif buttonName == "Mode" then
        controlType = "button"
        controlID = "Mode"
    else
        controlType = "button"
        controlID = buttonName
    end

    --------------------------------------------------------------------------------
    -- Translate Action Type:
    --------------------------------------------------------------------------------
    local actionType
    if buttonAction == "pressed" then
        actionType = "press"
    elseif buttonAction == "released" then
        actionType = "release"
    elseif buttonAction == "up" then
        actionType = "scrollUp"
    elseif buttonAction == "down" then
        actionType = "scrollDown"
    end
    if controlType == "joystick" then
        actionType = actionType .. buttonName
    end
    actionType = actionType .. "Action"

    --------------------------------------------------------------------------------
    -- Get Device Name, and data from Layout File:
    --------------------------------------------------------------------------------
    local deviceName = obj:name()
    local bundleID = cachedBundleID

    local items = mod.items()
    if not items[deviceName] then
        items[deviceName] = {}
    end
    if not items[deviceName][bundleID] then
        items[deviceName][bundleID] = {}
    end

    --------------------------------------------------------------------------------
    -- Revert to "All Applications" if no settings for frontmost app exist:
    --------------------------------------------------------------------------------
    if not items[deviceName][bundleID] then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- Ignore if ignored:
    --------------------------------------------------------------------------------
    if items[deviceName][bundleID].ignore then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- If not Automatically Switching Applications:
    --------------------------------------------------------------------------------
    if not mod.automaticallySwitchApplications()[deviceName] then
        local lastBundleID = mod.lastBundleID()
        bundleID = lastBundleID and lastBundleID[deviceName]
    end

    --------------------------------------------------------------------------------
    -- Get data from settings:
    --------------------------------------------------------------------------------
    local activeBanks = mod.activeBanks()
    local activeBanksForDevice = activeBanks and activeBanks[deviceName]
    local bankID = activeBanksForDevice and activeBanksForDevice[bundleID] or "1"

    local item = items[deviceName] and items[deviceName][bundleID]
    local bank = item and item[bankID]
    local theControlType = bank and bank[controlType]
    local theControlID = theControlType and theControlType[controlID]
    local action = theControlID and theControlID[actionType]

    local repeatID = deviceName .. controlType .. controlID .. buttonName

    --------------------------------------------------------------------------------
    -- Release any held down buttons:
    --------------------------------------------------------------------------------
    if actionType:sub(1, 7)  == "release" then
        if repeatTimers[repeatID] then
            repeatTimers[repeatID]:stop()
            repeatTimers[repeatID] = nil
        end
    end

    if action and action.action then
        --------------------------------------------------------------------------------
        -- Trigger action:
        --------------------------------------------------------------------------------
        executeAction(action)

        --------------------------------------------------------------------------------
        -- Add the action to a repeat timer if enabled:
        --------------------------------------------------------------------------------
        if actionType:sub(1,5) == "press" and theControlID[actionType .. "Repeat"] then
            repeatTimers[repeatID] = doEvery(keyRepeatInterval(), function()
                executeAction(action)
            end)
        end
    end
end

-- deviceCallback(callbackType, devices) -> none
-- Function
-- The Razer device callback.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function deviceCallback(connected, device)
    local deviceName = device:name()
    if connected then
        --------------------------------------------------------------------------------
        -- Razer Connected:
        --------------------------------------------------------------------------------
        log.df("Razer Device Connected: %s", deviceName)
        mod.devices[deviceName] = device
        mod.devices[deviceName]:defaultKeyboardLayout(false)
        mod.devices[deviceName]:callback(razerCallback)

        --------------------------------------------------------------------------------
        -- Reset the caches:
        --------------------------------------------------------------------------------
        cachedStatusLights[deviceName] = {}
        cachedCustomColors[deviceName] = {}

        cachedLedMode[deviceName] = ""

        --------------------------------------------------------------------------------
        -- Reset the status lights:
        --------------------------------------------------------------------------------
        resetStatusLights(device)

        --------------------------------------------------------------------------------
        -- Update the LEDs:
        --------------------------------------------------------------------------------
        mod.refresh()
    else
        --------------------------------------------------------------------------------
        -- Razer Disconnected:
        --------------------------------------------------------------------------------
        log.df("Razer Device Removed: %s", deviceName)

        --------------------------------------------------------------------------------
        -- Restore default keyboard layout:
        --------------------------------------------------------------------------------
        mod.devices[deviceName]:defaultKeyboardLayout(true)

        --------------------------------------------------------------------------------
        -- Turn off the LEDs:
        --------------------------------------------------------------------------------
        mod.devices[deviceName]:backlightsOff()
        setStatusLights(mod.devices[deviceName], false, false, false)

        --------------------------------------------------------------------------------
        -- Destroy the device:
        --------------------------------------------------------------------------------
        mod.devices[deviceName] = nil
        collectgarbage()
        collectgarbage()
    end

    -- Reset timers:
    mod.resetTimers()
end

--- plugins.core.razer.manager.resetTimers() -> none
--- Function
--- Resets all the various timers and memories.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.resetTimers()
    for _, v in pairs(repeatTimers) do
        v:stop()
    end
    repeatTimers = {}
end

--- plugins.core.razer.manager.enabled <cp.prop: boolean>
--- Field
--- Is Loupedeck CT support enabled?
mod.enabled = config.prop("razer.enabled", false):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Watch for application changes:
        --------------------------------------------------------------------------------
        if mod._appWatcher then
            mod._appWatcher:stop()
            mod._appWatcher = nil
        end
        mod._appWatcher = appWatcher.new(function(_, event)
            if event == appWatcher.activated then
                local frontmostApplication = application.frontmostApplication()
                local frontmostBundleID = frontmostApplication:bundleID()
                if frontmostBundleID then
                    cachedBundleID = frontmostBundleID
                end
                mod.resetTimers()
                mod.refresh()
            end
        end):start()

        --------------------------------------------------------------------------------
        -- Turn off LEDs when sleeping:
        --------------------------------------------------------------------------------
        if mod._sleepWatcher then
            mod._sleepWatcher:stop()
            mod._sleepWatcher = nil
        end
        mod._sleepWatcher = sleepWatcher.new(function(eventType)
            if eventType == sleepWatcher.systemDidWake then
                if mod.enabled() then
                    mod.refresh()
                end
            end
            if eventType == sleepWatcher.systemWillSleep then
                if mod.enabled() then
                    for _, device in pairs(mod.devices) do
                        device:backlightsOff()
                        setStatusLights(device, false, false, false)
                    end
                end
            end
        end):start()

        --------------------------------------------------------------------------------
        -- Pre-populate the frontmost application cache:
        --------------------------------------------------------------------------------
        local frontmostApplication = application.frontmostApplication()
        local frontmostBundleID = frontmostApplication:bundleID()
        if frontmostBundleID then
            cachedBundleID = frontmostBundleID
        end
		if not razer then
    		razer = require("hs.razer")
			razer.init(deviceCallback)
		end
    else
        if mod._appWatcher then
            mod._appWatcher:stop()
            mod._appWatcher = nil
        end

        if mod._sleepWatcher then
            mod._sleepWatcher:stop()
            mod._sleepWatcher = nil
        end

        for i, device in pairs(mod.devices) do
            device:defaultKeyboardLayout(true)
            device:backlightsOff()
            setStatusLights(device, false, false, false)
            mod.devices[i] = nil
        end

        --------------------------------------------------------------------------------
        -- Destroy the Razer object:
        --------------------------------------------------------------------------------
        razer = nil

        --------------------------------------------------------------------------------
        -- Reset Timers:
        --------------------------------------------------------------------------------
        mod.resetTimers()

        --------------------------------------------------------------------------------
        -- Take out the trash (...and hopefully don't crash!)
        --------------------------------------------------------------------------------
        collectgarbage()
        collectgarbage()
    end
end)

--- plugins.core.razer.manager.reset()
--- Function
--- Resets the config back to the default layout.
---
--- Parameters:
---  * completelyEmpty - A boolean
---
--- Returns:
---  * None
function mod.reset(completelyEmpty)
    if completelyEmpty then
        mod.items({})
    else
        mod.items(mod.defaultLayout)
    end
end

local plugin = {
    id          = "core.razer.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]                 = "actionmanager",
        ["core.application.manager"]            = "appmanager",
        ["core.controlsurfaces.manager"]        = "csman",
        ["core.commands.global"]                = "global",
        ["core.preferences.panels.scripting"]   = "scriptingPreferences",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Turn off LEDs and restore default keyboard layout on shutdown:
    --------------------------------------------------------------------------------
    config.shutdownCallback:new("razer", function()
        for _, device in pairs(mod.devices) do
            device:defaultKeyboardLayout(true)
            device:backlightsOff()
        end
    end)

    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager          = deps.actionmanager
    mod._scriptingPreferences    = deps.scriptingPreferences

    --------------------------------------------------------------------------------
    -- Razer Icon:
    --------------------------------------------------------------------------------
    local razerIcon = imageFromPath(env:pathToAbsolute("/../prefs/images/razerIcon.png"))

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("enableRazer")
        :whenActivated(function()
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :image(razerIcon)
        :titled(i18n("enableRazerSupport"))

    global
        :add("disableRazer")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :image(razerIcon)
        :titled(i18n("disableRazerSupport"))

    global
        :add("toggleRazer")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")
        :image(razerIcon)
        :titled(i18n("toggleRazerSupport"))

    --------------------------------------------------------------------------------
    -- Connect to the Razer:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    for _, deviceName in pairs(mod.supportedDevices) do
        local numberOfBanks = tableCount(mod.bankLabels[deviceName])
        local deviceID = deviceName:lower():gsub("%s+", "")

        actionmanager.addHandler("global_" .. deviceID .. "_banks")
            :onChoices(function(choices)
                for i=1, numberOfBanks do
                    choices
                        :add(deviceName .. " " .. i18n("bank") .. " " .. tostring(i))
                        :subText(i18n("razerBankDescription"))
                        :params({ id = i, deviceName = deviceName })
                        :id(i)
                        :image(razerIcon)
                end

                choices
                    :add(i18n("next") .. " " .. deviceName .. " " .. i18n("bank"))
                    :subText(i18n("razerBankDescription"))
                    :params({ id = "next", deviceName = deviceName })
                    :id("next")
                    :image(razerIcon)

                choices:add(i18n("previous") .. " " .. deviceName .. " " .. i18n("bank"))
                    :subText(i18n("razerBankDescription"))
                    :params({ id = "previous", deviceName = deviceName })
                    :id("previous")
                    :image(razerIcon)

                return choices
            end)
            :onExecute(function(result)
                if result and result.id then

                    local frontmostApplication = application.frontmostApplication()
                    local bundleID = frontmostApplication:bundleID()

                    local items = mod.items()
                    items = items and items[deviceName]

                    --------------------------------------------------------------------------------
                    -- Revert to "All Applications" if no settings for frontmost app exist:
                    --------------------------------------------------------------------------------
                    if not items[bundleID] then
                        bundleID = "All Applications"
                    end

                    if not items[bundleID] then
                        items[bundleID] = {}
                    end

                    --------------------------------------------------------------------------------
                    -- Ignore if ignored:
                    --------------------------------------------------------------------------------
                    if items[bundleID].ignore then
                        bundleID = "All Applications"
                    end

                    --------------------------------------------------------------------------------
                    -- If not Automatically Switching Applications:
                    --------------------------------------------------------------------------------
                    if not mod.automaticallySwitchApplications()[deviceName] then
                        local lastBundleID = mod.lastBundleID()
                        bundleID = lastBundleID and lastBundleID[deviceName]
                    end

                    local activeBanks = mod.activeBanks()
                    local activeBanksForDevice = activeBanks and activeBanks[deviceName]
                    local currentBank = activeBanksForDevice and activeBanksForDevice[bundleID] and tonumber(activeBanksForDevice[bundleID]) or 1

                    if not activeBanks[deviceName] then activeBanks[deviceName] = {} end

                    if type(result.id) == "number" then
                        activeBanks[deviceName][bundleID] = tostring(result.id)
                    else
                        if result.id == "next" then
                            if currentBank == numberOfBanks then
                                activeBanks[deviceName][bundleID] = "1"
                            else
                                activeBanks[deviceName][bundleID] = tostring(currentBank + 1)
                            end
                        elseif result.id == "previous" then
                            if currentBank == 1 then
                                activeBanks[deviceName][bundleID] = tostring(numberOfBanks)
                            else
                                activeBanks[deviceName][bundleID] = tostring(currentBank - 1)
                            end
                        end
                    end

                    mod.activeBanks(activeBanks)

                    --------------------------------------------------------------------------------
                    -- Reset any timers:
                    --------------------------------------------------------------------------------
                    mod.resetTimers()

                    --------------------------------------------------------------------------------
                    -- Refresh the LEDs:
                    --------------------------------------------------------------------------------
                    mod.refresh()

                    --------------------------------------------------------------------------------
                    -- Display a notification if enabled:
                    --------------------------------------------------------------------------------
                    if mod.displayMessageWhenChangingBanks()[deviceName] then
                        local newBank = activeBanks[deviceName][bundleID]
                        local i = mod.items() -- Reload items
                        local label = i and i[deviceName] and i[deviceName][bundleID] and i[deviceName][bundleID][newBank] and i[deviceName][bundleID][newBank]["bankLabel"]
                        if label then
                            displayNotification(label)
                        else
                            displayNotification(deviceName .. " " .. i18n("bank") .. ": " .. newBank)
                        end
                    end
                end
            end)
            :onActionId(function(action) return "razerBank" .. action.id end)
    end

    return mod
end

return plugin
