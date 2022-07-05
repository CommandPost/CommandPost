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
local tableContains             = tools.tableContains
local tableCount                = tools.tableCount
local tableMatch                = tools.tableMatch

local mod = {}

-- Default Values:
local DEFAULT_AUTOMATICALLY_SWITCH_APPLICATIONS         = true
local DEFAULT_DISPLAY_MESSAGE_WHEN_CHANGING_BANKS       = true
local DEFAULT_LAST_BUNDLE_ID                            = "All Applications"
local DEFAULT_BACKLIGHTS_MODE                           = "User Defined"
local DEFAULT_BACKLIGHT_BRIGHTNESS                      = "50"
local DEFAULT_BACKLIGHT_EFFECT_COLOR_A                  = "000000"
local DEFAULT_BACKLIGHT_EFFECT_COLOR_B                  = "000000"
local DEFAULT_BACKLIGHT_EFFECT_SPEED                    = "1"
local DEFAULT_BACKLIGHT_EFFECT_DIRECTION                = "left"

-- razer -> hs.razer object
-- Variable
-- The Razer extension. We only want to load it when Razer support is enabled.
local razer

--- plugins.core.razer.manager.supportedDevices -> table
--- Constant
--- Table supported devices.
mod.supportedDevices = {
    "Razer Nostromo",
    "Razer Orbweaver",
    "Razer Orbweaver Chroma",
    "Razer Tartarus",
    "Razer Tartarus Pro",
    "Razer Tartarus V2",
}

--- plugins.core.razer.manager.bankLabels -> table
--- Constant
--- Table of bank labels, which reflect the LED icons.
mod.bankLabels = {
    ["Razer Nostromo"] = {
        ["1"] = {
            label   = "1 (Off)",
            red     = false,
            green   = false,
            blue    = false
        },
        ["2"] = {
            label   = "2 (Green)",
            red     = false,
            green   = true,
            blue    = false
        },
        ["3"] = {
            label   = "3 (Red)",
            red     = true,
            green   = false,
            blue    = false
        },
        ["4"] = {
            label   = "4 (Blue)",
            red  = false,
            green   = false,
            blue    = true
        },
        ["5"] = {
            label   = "5 (Red/Green)",
            red     = true,
            green   = true,
            blue    = false
        },
        ["6"] = {
            label   = "6 (Red/Blue)",
            red     = true,
            green   = false,
            blue    = true
        },
        ["7"] = {
            label   = "7 (Green/Blue)",
            red     = false,
            green   = true,
            blue    = true
        }
    },
    ["Razer Orbweaver"] = {
        ["1"] = {
            label   = "1 (Off)",
            yellow  = false,
            green   = false,
            blue    = false
        },
        ["2"] = {
            label   = "2 (Yellow)",
            yellow  = true,
            green   = false,
            blue    = false
        },
        ["3"] = {
            label   = "3 (Green)",
            yellow  = false,
            green   = true,
            blue    = false
        },
        ["4"] = {
            label   = "4 (Blue)",
            yellow  = false,
            green   = false,
            blue    = true
        },
        ["5"] = {
            label   = "5 (Yellow/Green)",
            yellow  = true,
            green   = true,
            blue    = false
        },
        ["6"] = {
            label   = "6 (Yellow/Blue)",
            yellow  = true,
            green   = false,
            blue    = true
        },
        ["7"] = {
            label   = "7 (Green/Blue)",
            yellow  = false,
            green   = true,
            blue    = true
        }
    },
    ["Razer Orbweaver Chroma"] = {
        ["1"] = {
            label   = "1 (Off)",
            yellow  = false,
            green   = false,
            blue    = false
        },
        ["2"] = {
            label   = "2 (Yellow)",
            yellow  = true,
            green   = false,
            blue    = false
        },
        ["3"] = {
            label   = "3 (Green)",
            yellow  = false,
            green   = true,
            blue    = false
        },
        ["4"] = {
            label   = "4 (Blue)",
            yellow  = false,
            green   = false,
            blue    = true
        },
        ["5"] = {
            label   = "5 (Yellow/Green)",
            yellow  = true,
            green   = true,
            blue    = false
        },
        ["6"] = {
            label   = "6 (Yellow/Blue)",
            yellow  = true,
            green   = false,
            blue    = true
        },
        ["7"] = {
            label   = "7 (Green/Blue)",
            yellow  = false,
            green   = true,
            blue    = true
        }
    },
    ["Razer Tartarus"] = {
        ["1"] = {
            label   = "1 (Off)",
            yellow  = false,
            green   = false,
            blue    = false
        },
        ["2"] = {
            label   = "2 (Yellow)",
            yellow  = true,
            green   = false,
            blue    = false
        },
        ["3"] = {
            label   = "3 (Green)",
            yellow  = false,
            green   = true,
            blue    = false
        },
        ["4"] = {
            label   = "4 (Blue)",
            yellow  = false,
            green   = false,
            blue    = true
        },
        ["5"] = {
            label   = "5 (Yellow/Green)",
            yellow  = true,
            green   = true,
            blue    = false
        },
        ["6"] = {
            label   = "6 (Yellow/Blue)",
            yellow  = true,
            green   = false,
            blue    = true
        },
        ["7"] = {
            label   = "7 (Green/Blue)",
            yellow  = false,
            green   = true,
            blue    = true
        }
    },
    ["Razer Tartarus Pro"] = {
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
    },
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
    },
}

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
mod.automaticallySwitchApplications = config.prop("razer.automaticallySwitchApplications", {})

--- plugins.core.razer.manager.displayMessageWhenChangingBanks <cp.prop: boolean>
--- Field
--- Display message when changing banks?
mod.displayMessageWhenChangingBanks = config.prop("razer.displayMessageWhenChangingBanks", {})

--- plugins.core.razer.manager.lastBundleID <cp.prop: table>
--- Field
--- The last used bundle ID.
mod.lastBundleID = config.prop("razer.lastBundleID", {})

--- plugins.core.razer.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("razer.activeBanks", {})

--- plugins.core.razer.manager.backlightsMode <cp.prop: table>
--- Field
--- The backlights mode for all the Razer devices.
mod.backlightsMode = config.prop("razer.preferences.backlightsMode", {})

--- plugins.core.razer.manager.backlightBrightness <cp.prop: table>
--- Field
--- The backlights brightness for all the Razer devices.
mod.backlightBrightness = config.prop("razer.preferences.backlightBrightness", {})

--- plugins.core.razer.manager.backlightEffectColorA <cp.prop: table>
--- Field
--- The backlight effect primary color.
mod.backlightEffectColorA = config.prop("razer.preferences.backlightEffectColorA", {})

--- plugins.core.razer.manager.backlightEffectColorB <cp.prop: table>
--- Field
--- The backlight effect secondary color.
mod.backlightEffectColorB = config.prop("razer.preferences.backlightEffectColorB", {})

--- plugins.core.razer.manager.backlightEffectDirection <cp.prop: table>
--- Field
--- The backlight effect direction.
mod.backlightEffectDirection = config.prop("razer.preferences.backlightEffectDirection", {})

--- plugins.core.razer.manager.backlightEffectSpeed <cp.prop: table>
--- Field
--- The backlight effect speed.
mod.backlightEffectSpeed = config.prop("razer.preferences.backlightEffectSpeed", {})

--- plugins.core.razer.manager -> table
--- Variable
--- A table of Razer devices.
mod.devices = {}

-- repeatTimers -> table
-- Variable
-- A table containing all the repeat timers
local repeatTimers = {}

-- preventExcessiveThumbTapsTimers -> table
-- Variable
-- A table containing all the "Prevent Excessive Thumb Taps" timers
local preventExcessiveThumbTapsTimers = {}

-- cachedPreventExcessiveThumbTaps -> table
-- Variable
-- A table containing all the "Prevent Excessive Thumb Taps" caches
local cachedPreventExcessiveThumbTaps = {}

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

-- cachedBrightness -> table
-- Variable
-- A table of cached brightness values
local cachedBrightness = {}

-- cachedCustomColors -> table
-- Variable
-- A table of cached custom colors
local cachedCustomColors = {}

-- setupDefaults() -> none
-- Function
-- Sets up the default values for the various preferences.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function setupDefaults()
    for _, deviceName in pairs(mod.supportedDevices) do
        local automaticallySwitchApplications = mod.automaticallySwitchApplications()
        if type(automaticallySwitchApplications[deviceName]) == "nil" then
            automaticallySwitchApplications[deviceName] = DEFAULT_AUTOMATICALLY_SWITCH_APPLICATIONS
            mod.automaticallySwitchApplications(automaticallySwitchApplications)
        end

        local displayMessageWhenChangingBanks = mod.displayMessageWhenChangingBanks()
        if type(displayMessageWhenChangingBanks[deviceName]) == "nil" then
            displayMessageWhenChangingBanks[deviceName] = DEFAULT_DISPLAY_MESSAGE_WHEN_CHANGING_BANKS
            mod.displayMessageWhenChangingBanks(displayMessageWhenChangingBanks)
        end

        local lastBundleID = mod.lastBundleID()
        if type(lastBundleID[deviceName]) == "nil" then
            lastBundleID[deviceName] = DEFAULT_LAST_BUNDLE_ID
            mod.lastBundleID(lastBundleID)
        end

        local activeBanks = mod.activeBanks()
        if type(activeBanks[deviceName]) == "nil" then
            activeBanks[deviceName] = {}
            mod.activeBanks(activeBanks)
        end

        local backlightsMode = mod.backlightsMode()
        if type(backlightsMode[deviceName]) == "nil" then
            backlightsMode[deviceName] = DEFAULT_BACKLIGHTS_MODE
            mod.backlightsMode(backlightsMode)
        end

        local backlightBrightness = mod.backlightBrightness()
        if type(backlightBrightness[deviceName]) == "nil" then
            backlightBrightness[deviceName] = DEFAULT_BACKLIGHT_BRIGHTNESS
            mod.backlightBrightness(backlightBrightness)
        end

        local backlightEffectColorA = mod.backlightEffectColorA()
        if type(backlightEffectColorA[deviceName]) == "nil" then
            backlightEffectColorA[deviceName] = DEFAULT_BACKLIGHT_EFFECT_COLOR_A
            mod.backlightEffectColorA(backlightEffectColorA)
        end

        local backlightEffectColorB = mod.backlightEffectColorB()
        if type(backlightEffectColorB[deviceName]) == "nil" then
            backlightEffectColorB[deviceName] = DEFAULT_BACKLIGHT_EFFECT_COLOR_B
            mod.backlightEffectColorB(backlightEffectColorB)
        end

        local backlightEffectSpeed = mod.backlightEffectSpeed()
        if type(backlightEffectSpeed[deviceName]) == "nil" then
            backlightEffectSpeed[deviceName] = DEFAULT_BACKLIGHT_EFFECT_SPEED
            mod.backlightEffectSpeed(backlightEffectSpeed)
        end

        local backlightEffectDirection = mod.backlightEffectDirection()
        if type(backlightEffectDirection[deviceName]) == "nil" then
            backlightEffectDirection[deviceName] = DEFAULT_BACKLIGHT_EFFECT_DIRECTION
            mod.backlightEffectDirection(backlightEffectDirection)
        end
    end
end

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
    if deviceName == "Razer Orbweaver" or deviceName == "Razer Tartarus" or deviceName == "Razer Orbweaver Chroma" then
        --------------------------------------------------------------------------------
        -- YELLOW / GREEN / BLUE:
        --------------------------------------------------------------------------------
        cachedStatusLights[deviceName]["yellow"] = false
        cachedStatusLights[deviceName]["green"] = false
        cachedStatusLights[deviceName]["blue"] = false

        device:yellowStatusLight(false)
        device:greenStatusLight(false)
        device:blueStatusLight(false)
    elseif deviceName == "Razer Tartarus Pro" or deviceName == "Razer Tartarus V2" then
        --------------------------------------------------------------------------------
        -- ORANGE / GREEN / BLUE:
        --------------------------------------------------------------------------------
        cachedStatusLights[deviceName]["orange"] = false
        cachedStatusLights[deviceName]["green"] = false
        cachedStatusLights[deviceName]["blue"] = false

        device:orangeStatusLight(false)
        device:greenStatusLight(false)
        device:blueStatusLight(false)
    elseif deviceName == "Razer Nostromo" then
        --------------------------------------------------------------------------------
        -- GREEN / RED / BLUE:
        --------------------------------------------------------------------------------
        cachedStatusLights[deviceName]["green"] = false
        cachedStatusLights[deviceName]["red"] = false
        cachedStatusLights[deviceName]["blue"] = false

        device:greenStatusLight(false)
        device:redStatusLight(false)
        device:blueStatusLight(false)
    end
end

-- setStatusLights(device, orange, green, blue, yellow, red) -> none
-- Function
-- Sets the Status Lights on a Razer Device.
--
-- Parameters:
--  * device - The Razer device object
--  * orange - Whether or not the orange light is on or off as a boolean
--  * green - Whether or not the green light is on or off as a boolean
--  * blue - Whether or not the blue light is on or off as a boolean
--  * yellow - Whether or not the yellow light is on or off as a boolean
--  * red - Whether or not the yellow light is on or off as a boolean
--
-- Returns:
--  * None
local function setStatusLights(device, orange, green, blue, yellow, red)
    local deviceName = device:name()
    if deviceName == "Razer Orbweaver" or deviceName == "Razer Tartarus" or deviceName == "Razer Orbweaver Chroma" then
        --------------------------------------------------------------------------------
        -- YELLOW / GREEN / BLUE:
        --------------------------------------------------------------------------------
        if not cachedStatusLights[deviceName]["yellow"] == yellow then
            device:yellowStatusLight(yellow)
        end

        if not cachedStatusLights[deviceName]["green"] == green then
            device:greenStatusLight(green)
        end

        if not cachedStatusLights[deviceName]["blue"] == blue then
            device:blueStatusLight(blue)
        end

        cachedStatusLights[deviceName]["yellow"] = yellow
        cachedStatusLights[deviceName]["green"] = green
        cachedStatusLights[deviceName]["blue"] = blue
    elseif deviceName == "Razer Tartarus Pro" or deviceName == "Razer Tartarus V2" then
        --------------------------------------------------------------------------------
        -- ORANGE / GREEN / BLUE:
        --------------------------------------------------------------------------------
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
    elseif deviceName == "Razer Nostromo" then
        --------------------------------------------------------------------------------
        -- GREEN / RED / BLUE:
        --------------------------------------------------------------------------------
        if not cachedStatusLights[deviceName]["green"] == green then
            device:greenStatusLight(green)
        end

        if not cachedStatusLights[deviceName]["red"] == red then
            device:redStatusLight(red)
        end

        if not cachedStatusLights[deviceName]["blue"] == blue then
            device:blueStatusLight(blue)
        end

        cachedStatusLights[deviceName]["green"] = green
        cachedStatusLights[deviceName]["red"] = red
        cachedStatusLights[deviceName]["blue"] = blue
    end
end

--- plugins.core.razer.manager.refresh(trashCache) -> none
--- Function
--- Refreshes the LEDs on a Razer device.
---
--- Parameters:
---  * trashCache - an optional boolean to trash the LED cache
---
--- Returns:
---  * None
function mod.refresh(trashCache)
    for _, device in pairs(mod.devices) do
        --------------------------------------------------------------------------------
        -- Check if we should trash the cache:
        --------------------------------------------------------------------------------
        local deviceName = device:name()
        if trashCache then
			cachedStatusLights[deviceName]  = {}
			cachedCustomColors[deviceName]  = {}
			cachedLedMode[deviceName]       = ""
			cachedBrightness[deviceName]    = ""
		end

        --------------------------------------------------------------------------------
        -- Get settings from preferences (or defaults):
        --------------------------------------------------------------------------------
        local backlightsMode = mod.backlightsMode()
        local currentMode = backlightsMode[deviceName]

        local backlightBrightness = mod.backlightBrightness()
        local brightness = backlightBrightness and backlightBrightness[deviceName] and tonumber(backlightBrightness[deviceName]) or tonumber(DEFAULT_BACKLIGHT_BRIGHTNESS)

        local backlightEffectColorA = mod.backlightEffectColorA()
        local backlightEffectColorB = mod.backlightEffectColorB()

        local backlightEffectDirection = mod.backlightEffectDirection()
        local backlightEffectSpeed = mod.backlightEffectSpeed()

        local speed = backlightEffectSpeed and backlightEffectSpeed[deviceName] and tonumber(backlightEffectSpeed[deviceName]) or tonumber(DEFAULT_BACKLIGHT_EFFECT_SPEED)
        local direction = backlightEffectDirection and backlightEffectDirection[deviceName]

        local colorA = backlightEffectColorA and backlightEffectColorA[deviceName] and {hex=backlightEffectColorA[deviceName]} or {hex=DEFAULT_BACKLIGHT_EFFECT_COLOR_A}
        local colorB = backlightEffectColorB and backlightEffectColorB[deviceName] and {hex=backlightEffectColorB[deviceName]} or {hex=DEFAULT_BACKLIGHT_EFFECT_COLOR_B}

        --------------------------------------------------------------------------------
        -- Get Device Name, and data from Layout File:
        --------------------------------------------------------------------------------
        local bundleID = cachedBundleID

        local items = mod.items()
        if not items[deviceName] then
            items[deviceName] = {}
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
        if items[deviceName][bundleID] and items[deviceName][bundleID].ignore then
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
        if cachedBrightness[deviceName] ~= brightness then
            device:brightness(brightness)
            cachedBrightness[deviceName] = brightness
        end

        --------------------------------------------------------------------------------
        -- Update status lights based on current bank:
        --------------------------------------------------------------------------------
        local statusLights = mod.bankLabels[deviceName][bankID]
        setStatusLights(device, statusLights.orange, statusLights.green, statusLights.blue, statusLights.yellow, statusLights.red)

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
            -- Process LEDs for all devices that support Custom LED values:
            --------------------------------------------------------------------------------
            if deviceName == "Razer Tartarus V2" or deviceName == "Razer Tartarus Pro" or deviceName == "Razer Orbweaver Chroma" then
                --------------------------------------------------------------------------------
                -- Update Scroll Wheel:
                --------------------------------------------------------------------------------
                local scrollWheelID
                if deviceName == "Razer Tartarus V2" then
                    scrollWheelID = 23
                elseif deviceName == "Razer Tartarus Pro" then
                   scrollWheelID = 20
                end
                local scrollWheel = scrollWheels and scrollWheels["1"]
                local led = scrollWheel and scrollWheel.led
                if led and scrollWheelID then
                    customColors[scrollWheelID] = {hex="#"..led}
                end

                --------------------------------------------------------------------------------
                -- Update Button LEDs:
                --------------------------------------------------------------------------------
                for i=1, 20 do
                    local offset = 0

                    if deviceName == "Razer Tartarus V2" then
                        if i > 5 then offset = 1 end
                        if i > 10 then offset = 2 end
                        if i > 15 then offset = 3 end
                        if i > 19 then offset = 4 end
                    elseif deviceName == "Razer Tartarus Pro" then
                        if i == 20 then offset = 1 end
                    end

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

            if not tableMatch(cachedCustomColors[deviceName], customColors) or trashCache then
                device:backlightsCustom(customColors)
            end

            --------------------------------------------------------------------------------
            -- Cache the colour matrix, so we don't send it more than once:
            --------------------------------------------------------------------------------
            cachedCustomColors[deviceName] = copy(customColors)

        elseif not (cachedLedMode[deviceName] == currentMode) or trashCache then
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

    --------------------------------------------------------------------------------
    -- Revert to "All Applications" if no settings for frontmost app exist:
    --------------------------------------------------------------------------------
    if not items[deviceName][bundleID] then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- Ignore if ignored:
    --------------------------------------------------------------------------------
    if items[deviceName][bundleID] and items[deviceName][bundleID].ignore then
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

    local repeatID
    if controlType and controlID and buttonName then
        repeatID = deviceName .. controlType .. controlID .. buttonName
    end

    --------------------------------------------------------------------------------
    -- Release any held down buttons:
    --------------------------------------------------------------------------------
    if repeatID then
        if actionType:sub(1, 7) == "release" then
            if repeatTimers[repeatID] then
                repeatTimers[repeatID]:stop()
                repeatTimers[repeatID] = nil
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Trigger the action:
    --------------------------------------------------------------------------------
    if action and action.action then
        --------------------------------------------------------------------------------
        -- Check for "Prevent Excessive Thumb Taps" setting:
        --------------------------------------------------------------------------------
        local preventExcessiveThumbTaps = theControlID.preventExcessiveThumbTaps
        if preventExcessiveThumbTaps and preventExcessiveThumbTaps ~= "" then
            if cachedPreventExcessiveThumbTaps[repeatID] then
                return
            else
                cachedPreventExcessiveThumbTaps[repeatID] = true
                preventExcessiveThumbTapsTimers[repeatID] = doAfter(tonumber(preventExcessiveThumbTaps), function()
                    cachedPreventExcessiveThumbTaps[repeatID] = false
                    preventExcessiveThumbTapsTimers[repeatID] = nil
                end)
            end
        end

        --------------------------------------------------------------------------------
        -- Execute action:
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
        cachedBrightness[deviceName] = ""

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
        setStatusLights(mod.devices[deviceName], false, false, false, false, false)

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
                        setStatusLights(device, false, false, false, false, false)
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
            setStatusLights(device, false, false, false, false, false)
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
    -- Setup Defaults:
    --------------------------------------------------------------------------------
    setupDefaults()

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
    mod._scriptingPreferences   = deps.scriptingPreferences

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

    local backlightModes = {
        { value = "Off",              label = i18n("off"),                  supportedDevices = {"Razer Orbweaver Chroma", "Razer Tartarus V2", "Razer Tartarus Pro"}    },
        { value = "User Defined",     label = i18n("userDefined"),          supportedDevices = {"Razer Orbweaver Chroma", "Razer Tartarus V2", "Razer Tartarus Pro"}    },
        { value = "Breathing",        label = i18n("breathing"),            supportedDevices = {"Razer Orbweaver Chroma", "Razer Tartarus V2"}                          },
        { value = "Reactive",         label = i18n("reactive"),             supportedDevices = {"Razer Orbweaver Chroma", "Razer Tartarus V2"}                          },
        { value = "Spectrum",         label = i18n("spectrum"),             supportedDevices = {"Razer Orbweaver Chroma", "Razer Tartarus V2"}                          },
        { value = "Starlight",        label = i18n("starlight"),            supportedDevices = {"Razer Orbweaver Chroma", "Razer Tartarus V2"}                          },
        { value = "Static",           label = i18n("static"),               supportedDevices = {"Razer Orbweaver Chroma", "Razer Tartarus V2", "Razer Tartarus Pro"}    },
        { value = "Wave",             label = i18n("wave"),                 supportedDevices = {"Razer Orbweaver Chroma", "Razer Tartarus V2"}                          },
    }
    for _, deviceName in pairs(mod.supportedDevices) do
        --------------------------------------------------------------------------------
        -- Backlight Modes:
        --------------------------------------------------------------------------------
        for _, v in pairs(backlightModes) do
            if tableContains(v.supportDevices, deviceName) then
                global
                    :add(deviceName .. "Backlight" .. v.value)
                    :whenActivated(function()
                        local backlightsMode = mod.backlightsMode()
                        backlightsMode[deviceName] = v.value
                        mod.backlightsMode(backlightsMode)
                        mod.refresh(true)
                    end)
                    :groupedBy("commandPost")
                    :image(razerIcon)
                    :titled(deviceName .. " " .. i18n("backlightsMode") .. ": " .. v.label)
            end
        end

        --------------------------------------------------------------------------------
        -- Brightness Set:
        --------------------------------------------------------------------------------
        for i=1, 100 do
            global
                :add(deviceName .. "Brightness" .. i)
                :whenActivated(function()
                    local backlightBrightness = mod.backlightBrightness()
                    backlightBrightness[deviceName] = tostring(i)
                    mod.backlightBrightness(backlightBrightness)
                    mod.refresh(true)
                end)
                :groupedBy("commandPost")
                :image(razerIcon)
                :titled(deviceName .. " " .. i18n("backlightBrightness") .. ": " .. i)
        end

        --------------------------------------------------------------------------------
        -- Brightness Increase:
        --------------------------------------------------------------------------------
        global
            :add(deviceName .. "BrightnessIncrease")
            :whenActivated(function()
                local backlightBrightness = mod.backlightBrightness()
                local currentBrightness = tonumber(backlightBrightness[deviceName])
                if currentBrightness < 100 then
                    backlightBrightness[deviceName] = tostring(currentBrightness + 10)
                end
                mod.backlightBrightness(backlightBrightness)
                mod.refresh(true)
            end)
            :groupedBy("commandPost")
            :image(razerIcon)
            :titled(deviceName .. " " .. i18n("backlightBrightness") .. " " .. i18n("increase"))

        --------------------------------------------------------------------------------
        -- Brightness Decrease:
        --------------------------------------------------------------------------------
        global
            :add(deviceName .. "BrightnessDecrease")
            :whenActivated(function()
                local backlightBrightness = mod.backlightBrightness()
                local currentBrightness = tonumber(backlightBrightness[deviceName])
                if currentBrightness > 1 then
                    backlightBrightness[deviceName] = tostring(currentBrightness - 10)
                end
                mod.backlightBrightness(backlightBrightness)
                mod.refresh(true)
            end)
            :groupedBy("commandPost")
            :image(razerIcon)
            :titled(deviceName .. " " .. i18n("backlightBrightness") .. " " .. i18n("decrease"))
    end

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
