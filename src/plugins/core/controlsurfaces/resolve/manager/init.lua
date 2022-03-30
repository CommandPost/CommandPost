--- === plugins.core.controlsurfaces.resolve.manager ===
---
--- Blackmagic DaVinci Resolve Control Surface Support.

local require = require

local log                       = require "hs.logger".new "resolvePanel"

local application               = require "hs.application"
local appWatcher                = require "hs.application.watcher"
local eventtap                  = require "hs.eventtap"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local speededitor               = require "hs.speededitor"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local copy                      = fnutils.copy
local displayNotification       = dialog.displayNotification
local doEvery                   = timer.doEvery
local imageFromPath             = image.imageFromPath
local keyRepeatInterval         = eventtap.keyRepeatInterval
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local spairs                    = tools.spairs
local tableMatch                = tools.tableMatch

local mod = {}

--- plugins.core.resolve.manager.lastApplication <cp.prop: string>
--- Field
--- Last Application used in the Preferences Panel.
mod.lastApplication = config.prop("daVinciResolveControlSurface.preferences.lastApplication", "All Applications")

--- plugins.core.resolve.manager.lastApplication <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastBank = config.prop("daVinciResolveControlSurface.preferences.lastBank", "1")

--- plugins.core.resolve.manager.repeatTimers -> table
--- Variable
--- A table containing `hs.timer` objects.
mod.repeatTimers = {}

--- plugins.core.resolve.prefs.snippetsRefreshFrequency <cp.prop: string>
--- Field
--- How often snippets are refreshed.
mod.snippetsRefreshFrequency = config.prop("daVinciResolveControlSurface.preferences.snippetsRefreshFrequency", "1")

--- plugins.core.resolve.manager.automaticallySwitchApplications <cp.prop: boolean>
--- Field
--- Enable or disable the automatic switching of applications.
mod.automaticallySwitchApplications = config.prop("daVinciResolveControlSurface.automaticallySwitchApplications", false)

--- plugins.core.resolve.manager.lastBundleID <cp.prop: string>
--- Field
--- The last Bundle ID.
mod.lastBundleID = config.prop("daVinciResolveControlSurface.lastBundleID", "All Applications")

-- defaultLayoutPath -> string
-- Variable
-- Default Layout Path
local defaultLayoutPath = config.basePath .. "/plugins/core/controlsurfaces/resolve/default/Default.cpResolve"

--- plugins.core.resolve.manager.defaultLayout -> table
--- Variable
--- Default Layout
mod.defaultLayout = json.read(defaultLayoutPath)

--- plugins.core.resolve.manager.items <cp.prop: table>
--- Field
--- A table containing the control surface layout.
mod.items = json.prop(config.userConfigRootPath, "DaVinci Resolve Control Surface", "Settings.cpResolve", mod.defaultLayout)

--- plugins.core.resolve.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("daVinciResolveControlSurface.activeBanks", {
    ["Speed Editor"] = {},
})

-- plugins.core.resolve.manager.devices -> table
-- Variable
-- Table of Devices.
mod.devices = {
    ["Speed Editor"] = {},
}

-- plugins.core.resolve.manager.deviceOrder -> table
-- Variable
-- Table of Device Orders.
mod.deviceOrder = {
    ["Speed Editor"] = {},
}

-- plugins.core.resolve.manager.defaultSensitivity -> table
-- Variable
-- Table of Default Sensitivity Values.
mod.defaultSensitivity = {
    ["Speed Editor"] = 8000,
}

--- plugins.core.resolve.manager.getDeviceType(object) -> string
--- Function
--- Translates a button layout into a device type string.
---
--- Parameters:
---  * object - A `hs.resolve` object
---
--- Returns:
---  * "Speed Editor"
function mod.getDeviceType()
    --------------------------------------------------------------------------------
    -- Currently there's only one model. This is future proofing for if/when
    -- I eventually add the full-size keyboard or they come out with different
    -- keyboards.
    --------------------------------------------------------------------------------
    return "Speed Editor"
end

--- plugins.core.resolve.manager.buttonCallback(object, buttonID, pressed) -> none
--- Function
--- Control Surface Button Callback
---
--- Parameters:
---  * object - The `hs.resolve` userdata object
---  * buttonID - A number containing the button that was pressed/released
---  * pressed - A boolean indicating whether the button was pressed (`true`) or released (`false`)
---
--- Returns:
---  * None
function mod.buttonCallback(object, buttonID, pressed, jogWheelMode, jogWheelValue)

    --[[
    log.df("buttonID: %s", buttonID)
    log.df("pressed: %s", pressed)
    log.df("jogWheelMode: %s", jogWheelMode)
    log.df("jogWheelValue: %s", jogWheelValue)
    --]]

    local serialNumber = object:serialNumber()
    local deviceType = mod.getDeviceType()
    local deviceID = mod.deviceOrder[deviceType][serialNumber]

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    local activeBanks = mod.activeBanks()
    local bankID = activeBanks and activeBanks[deviceType] and activeBanks[deviceType][deviceID] and activeBanks[deviceType][deviceID][bundleID] or "1"

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

    --[[
    log.df("deviceType: %s", deviceType)
    log.df("deviceID: %s", deviceID)
    log.df("bundleID: %s", bundleID)
    log.df("bankID: %s", bankID)
    log.df("buttonID: %s", buttonID)
    --]]

    --------------------------------------------------------------------------------
    -- Get the data from the layout file:
    --------------------------------------------------------------------------------
    local theDevice = items[deviceType]
    local theUnit = theDevice and theDevice[deviceID]
    local theApp = theUnit and theUnit[bundleID]
    local theBank = theApp and theApp[bankID]
    local theButton = theBank and theBank[buttonID]

    --------------------------------------------------------------------------------
    -- Nothing assigned to that button:
    --------------------------------------------------------------------------------
    if not theButton then
        return
    end

    if jogWheelMode then
        --------------------------------------------------------------------------------
        -- Jog Wheel Turned:
        --------------------------------------------------------------------------------
        local sensitivity = (theButton and theButton.sensitivity) or mod.defaultSensitivity[deviceType]
        if math.abs(jogWheelValue) > tonumber(sensitivity) then
            if jogWheelValue < 0 then
                --------------------------------------------------------------------------------
                -- Turn Left:
                --------------------------------------------------------------------------------
                local turnLeftAction = theButton.turnLeftAction
                if turnLeftAction then
                    local handlerID = turnLeftAction.handlerID
                    local action = turnLeftAction.action
                    if handlerID and action then
                        --------------------------------------------------------------------------------
                        -- Trigger the action:
                        --------------------------------------------------------------------------------
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
            else
                --------------------------------------------------------------------------------
                -- Turn Right:
                --------------------------------------------------------------------------------
                local turnRightAction = theButton.turnRightAction
                if turnRightAction then
                    local handlerID = turnRightAction.handlerID
                    local action = turnRightAction.action
                    if handlerID and action then
                        --------------------------------------------------------------------------------
                        -- Trigger the  action:
                        --------------------------------------------------------------------------------
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
            end
        end
    else
        --------------------------------------------------------------------------------
        -- Button Pressed/Released:
        --------------------------------------------------------------------------------
        local repeatPressActionUntilReleased = theButton.repeatPressActionUntilReleased
        local repeatID = deviceType .. deviceID .. buttonID
        if pressed then
            local pressAction = theButton.pressAction
            if pressAction then
                local handlerID = pressAction.handlerID
                local action = pressAction.action
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

-- ledCache
-- Variable
-- A table of LED statuses
local ledCache = {}

--- plugins.core.resolve.manager.update() -> none
--- Function
--- Updates all the control surface LEDs.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()

    local containsLEDSnippet = false

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
            -- Get bank data:
            --------------------------------------------------------------------------------
            local bankData = deviceData and deviceData[bundleID] and deviceData[bundleID][bankID]

            --------------------------------------------------------------------------------
            -- Update every button:
            --------------------------------------------------------------------------------
            local ledStatus = {}
            for _, ledID in pairs(speededitor.ledNames) do
                local buttonData = bankData and bankData[ledID]
                local snippetAction = buttonData and buttonData.snippetAction
                local snippetActionAction = snippetAction and snippetAction.action
                local code = snippetActionAction and snippetActionAction.code
                if code then
                    containsLEDSnippet = true

                    --------------------------------------------------------------------------------
                    -- Load Snippet from Snippet Preferences if it exists:
                    --------------------------------------------------------------------------------
                    local snippetID = snippetActionAction.id
                    local snippets = mod._scriptingPreferences.snippets()
                    if snippets[snippetID] then
                        code = snippets[snippetID].code
                    end

                    local successful, result = pcall(load(code))
                    if successful and type(result) == "boolean" then
                        ledStatus[ledID] = result
                    end
                else
                    --------------------------------------------------------------------------------
                    -- Either use the "LED Always On" preference, or leave it off:
                    --------------------------------------------------------------------------------
                    local ledAlwaysOn = buttonData and buttonData.ledAlwaysOn
                    ledStatus[ledID] = ledAlwaysOn or false
                end
            end

            --------------------------------------------------------------------------------
            -- Only update the hardware if there's a change:
            --------------------------------------------------------------------------------
            if not tableMatch(ledStatus, ledCache) then
                device:led(ledStatus)
            end
            ledCache = copy(ledStatus)
        end
    end

    --------------------------------------------------------------------------------
    -- Enable or disable the refresh timer:
    --------------------------------------------------------------------------------
    if containsLEDSnippet then
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

--- plugins.core.resolve.manager.discoveryCallback(connected, object) -> none
--- Function
--- Control Surface Discovery Callback
---
--- Parameters:
---  * connected - A boolean, `true` if a device was connected, `false` if a device was disconnected
---  * object - An `hs.speededitor` object, being the device that was connected/disconnected
---
--- Returns:
---  * None
function mod.discoveryCallback(connected, object)
    local serialNumber = object:serialNumber()
    if serialNumber == nil then
        log.ef("Failed to get DaVinci Resolve Control Surface Serial Number. Is DaVinci Resolve running?")
    else
        local deviceType = mod.getDeviceType()
        if connected then
            --log.df("DaVinci Resolve Control Surface Connected: %s - %s", deviceType, serialNumber)
            mod.devices[deviceType][serialNumber] = object:callback(mod.buttonCallback)

            --------------------------------------------------------------------------------
            -- Force the device into SHTL Jog Wheel mode:
            --------------------------------------------------------------------------------
            object:jogMode("SHTL")

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
                --log.df("DaVinci Resolve Control Surface Disconnected: %s - %s", deviceType, serialNumber)
                mod.devices[deviceType][serialNumber] = nil
            else
                log.ef("Disconnected DaVinci Resolve Control Surface wasn't previously registered: %s - %s", deviceType, serialNumber)
            end
        end
    end
end

--- plugins.core.resolve.manager.start() -> boolean
--- Function
--- Starts the DaVinci Resolve Control Surface Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    --------------------------------------------------------------------------------
    -- Setup watch to refresh the control surfaces when apps change focus:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function(_, event)
        if event == appWatcher.activated then
            mod.update()
        end
    end):start()

    --------------------------------------------------------------------------------
    -- Initialise DaVinci Resolve Control Surface support:
    --------------------------------------------------------------------------------
    speededitor.init(mod.discoveryCallback)
end

--- plugins.core.resolve.manager.start() -> boolean
--- Function
--- Stops DaVinci Resolve Control Surface Support.
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
end

--- plugins.core.resolve.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable DaVinci Resolve Control Surface support
mod.enabled = config.prop("enableSpeedEditor", false):watch(function(enabled)
    if enabled then
        mod.start()
    else
        mod.stop()
    end
end)

local plugin = {
    id          = "core.controlsurfaces.resolve.manager",
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

function plugin.init(deps)

    local icon = imageFromPath(config.bundledPluginsPath .. "/core/controlsurfaces/resolve/prefs/images/resolve.icns")

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
        :add("cpResolveControlSurfaceSupport")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :titled(i18n("toggleDaVinciResolveControlSurfaceSupport"))
        :groupedBy("commandPost")
        :image(icon)

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    local numberOfBanks = deps.csman.NUMBER_OF_BANKS
    local numberOfDevices = deps.csman.NUMBER_OF_DEVICES
    actionmanager.addHandler("global_resolvebanks")
        :onChoices(function(choices)
            for device, _ in pairs(mod.devices) do
                for unit=1, numberOfDevices do
                    for bank=1, numberOfBanks do
                        choices:add(device .. " " .. i18n("bank") .. " " .. tostring(bank) .. " (Unit " .. unit .. ")")
                            :subText(i18n("resolveBankDescription"))
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
                        :add(i18n("next") .. " " .. device .. " " .. i18n("bank") .. " (Unit " .. unit .. ")")
                        :subText(i18n("resolveBankDescription"))
                        :params({
                            action = "next",
                            device = device,
                            unit = tostring(unit),
                            id = device .. "_" .. unit .. "_nextBank"
                        })
                        :id(device .. "_" .. unit .. "_nextBank")
                        :image(icon)

                    choices
                        :add(i18n("previous") .. " " .. device .. " " .. i18n("bank") .. " (Unit " .. unit .. ")")
                        :subText(i18n("resolveBankDescription"))
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

                displayNotification("Speed Editor " .. deviceLabel .. "(Unit " .. unit .. ") " .. i18n("bank") .. ": " .. label)
            end
        end)
        :onActionId(function(action) return "resolveBank" .. action.id end)

    --------------------------------------------------------------------------------
    -- Actions to Manually Change Application:
    --------------------------------------------------------------------------------
    local applicationmanager = deps.appmanager
    actionmanager.addHandler("global_resolveapplications", "global")
        :onChoices(function(choices)
            local applications = applicationmanager.getApplications()

            applications["All Applications"] = {
                displayName = "All Applications",
            }

            --------------------------------------------------------------------------------
            -- Add User Added Applications from Preferences:
            --------------------------------------------------------------------------------
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
                    :add(i18n("switchDaVinciResolveControlSurfaceTo") .. " " .. item.displayName)
                    :subText(i18n("resolveAppDescription"))
                    :params({
                        bundleID = bundleID,
                    })
                    :id("global_resolveapplications_switch_" .. bundleID)
                    :image(icon)

                if bundleID ~= "All Applications" then
                    choices
                        :add(i18n("switchDaVinciResolveControlSurfaceTo") .. " " .. item.displayName .. " " .. i18n("andLaunch"))
                        :subText(i18n("resolveAppDescription"))
                        :params({
                            bundleID = bundleID,
                            launch = true,
                        })
                        :id("global_resolveapplications_launch_" .. bundleID)
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
            return "global_resolveapplications_" .. params.bundleID
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
