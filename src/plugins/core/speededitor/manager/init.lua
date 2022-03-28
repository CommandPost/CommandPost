--- === plugins.core.speededitor.manager ===
---
--- Blackmagic Speed Editor Keyboard Support.

local require = require

local log                       = require "hs.logger".new "speedEditor"

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

--- plugins.core.speededitor.manager.lastApplication <cp.prop: string>
--- Field
--- Last Application used in the Preferences Panel.
mod.lastApplication = config.prop("speedEditor.preferences.lastApplication", "All Applications")

--- plugins.core.speededitor.manager.lastApplication <cp.prop: string>
--- Field
--- Last Bank used in the Preferences Panel.
mod.lastBank = config.prop("speedEditor.preferences.lastBank", "1")

--- plugins.core.speededitor.manager.repeatTimers -> table
--- Variable
--- A table containing `hs.timer` objects.
mod.repeatTimers = {}

--- plugins.core.speededitor.prefs.snippetsRefreshFrequency <cp.prop: string>
--- Field
--- How often snippets are refreshed.
mod.snippetsRefreshFrequency = config.prop("speedEditor.preferences.snippetsRefreshFrequency", "1")

--- plugins.core.speededitor.manager.automaticallySwitchApplications <cp.prop: boolean>
--- Field
--- Enable or disable the automatic switching of applications.
mod.automaticallySwitchApplications = config.prop("speedEditor.automaticallySwitchApplications", false)

--- plugins.core.speededitor.manager.lastBundleID <cp.prop: string>
--- Field
--- The last Bundle ID.
mod.lastBundleID = config.prop("speedEditor.lastBundleID", "All Applications")

-- defaultLayoutPath -> string
-- Variable
-- Default Layout Path
local defaultLayoutPath = config.basePath .. "/plugins/core/speededitor/default/Default.cpSpeedEditor"

--- plugins.core.speededitor.manager.defaultLayout -> table
--- Variable
--- Default Speed Editor Layout
mod.defaultLayout = json.read(defaultLayoutPath)

--- plugins.core.speededitor.manager.items <cp.prop: table>
--- Field
--- A table containing the Speed Editor layout.
mod.items = json.prop(config.userConfigRootPath, "Speed Editor", "Settings.cpSpeedEditor", mod.defaultLayout)

--- plugins.core.speededitor.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("speedEditor.activeBanks", {
    ["Speed Editor"] = {},
})

-- plugins.core.speededitor.manager.devices -> table
-- Variable
-- Table of Speed Editor Devices.
mod.devices = {
    ["Speed Editor"] = {},
}

-- plugins.core.speededitor.manager.deviceOrder -> table
-- Variable
-- Table of Speed Editor Device Orders.
mod.deviceOrder = {
    ["Speed Editor"] = {},
}

--- plugins.core.speededitor.manager.getDeviceType(object) -> string
--- Function
--- Translates a Speed Editor button layout into a device type string.
---
--- Parameters:
---  * object - A `hs.speededitor` object
---
--- Returns:
---  * "Speed Editor"
function mod.getDeviceType()
    -- Currently there's only one model.
    return "Speed Editor"
end

--- plugins.core.speededitor.manager.buttonCallback(object, buttonID, pressed) -> none
--- Function
--- Speed Editor Button Callback
---
--- Parameters:
---  * object - The `hs.speededitor` userdata object
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

    local theDevice = items[deviceType]
    local theUnit = theDevice and theDevice[deviceID]
    local theApp = theUnit and theUnit[bundleID]
    local theBank = theApp and theApp[bankID]
    local theButton = theBank and theBank[buttonID]

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

local ledCache = {}

--- plugins.core.speededitor.manager.update() -> none
--- Function
--- Updates the screens of all Speed Editor devices.
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
            -- TODO: move to hs.speededitor
            local ledNames = {"AUDIO ONLY", "CAM1", "CAM2", "CAM3", "CAM4", "CAM5", "CAM6", "CAM7", "CAM8", "CAM9", "CLOSE UP", "CUT", "DIS", "JOG", "LIVE OWR", "SCRL", "SHTL", "SMTH CUT", "SNAP", "TRANS", "VIDEO ONLY"}
            local ledStatus = {}
            for _, ledID in pairs(ledNames) do
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
                        log.df("found a valid snippet!")
                        ledStatus[ledID] = result
                    end
                else
                    ledStatus[ledID] = false
                end
            end
            if not tableMatch(ledStatus, ledCache) then
                log.df("updating leds")
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

--- plugins.core.speededitor.manager.discoveryCallback(connected, object) -> none
--- Function
--- Speed Editor Discovery Callback
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
        log.ef("Failed to get Speed Editor's Serial Number. Is DaVinci Resolve running?")
    else
        local deviceType = mod.getDeviceType()
        if connected then
            log.df("Speed Editor Connected: %s - %s", deviceType, serialNumber)
            mod.devices[deviceType][serialNumber] = object:callback(mod.buttonCallback)

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
                log.df("Speed Editor Disconnected: %s - %s", deviceType, serialNumber)
                mod.devices[deviceType][serialNumber] = nil
            else
                log.ef("Disconnected Speed Editor wasn't previously registered: %s - %s", deviceType, serialNumber)
            end
        end
    end
end

--- plugins.core.speededitor.manager.start() -> boolean
--- Function
--- Starts the Speed Editor Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    --------------------------------------------------------------------------------
    -- Setup watch to refresh the Speed Editor's when apps change focus:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function(_, event)
        if event == appWatcher.activated then
            mod.update()
        end
    end):start()

    --------------------------------------------------------------------------------
    -- Initialise Speed Editor support:
    --------------------------------------------------------------------------------
    speededitor.init(mod.discoveryCallback)
end

--- plugins.core.speededitor.manager.start() -> boolean
--- Function
--- Stops the Speed Editor Plugin
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

--- plugins.core.speededitor.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Speed Editor Support.
mod.enabled = config.prop("enableSpeedEditor", false):watch(function(enabled)
    if enabled then
        mod.start()
    else
        mod.stop()
    end
end)

local plugin = {
    id          = "core.speededitor.manager",
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

    local icon = imageFromPath(env:pathToAbsolute("/../prefs/images/speededitor.icns"))

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
        :add("cpSpeedEditor")
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
    actionmanager.addHandler("global_speededitorbanks")
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
                        choices:add("Speed Editor " .. deviceLabel .. i18n("bank") .. " " .. tostring(bank) .. " (Unit " .. unit .. ")")
                            :subText(i18n("speedEditorBankDescription"))
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
                        :add(i18n("next") .. " Speed Editor " .. deviceLabel .. i18n("bank") .. " (Unit " .. unit .. ")")
                        :subText(i18n("speedEditorBankDescription"))
                        :params({
                            action = "next",
                            device = device,
                            unit = tostring(unit),
                            id = device .. "_" .. unit .. "_nextBank"
                        })
                        :id(device .. "_" .. unit .. "_nextBank")
                        :image(icon)

                    choices
                        :add(i18n("previous") .. " Speed Editor " .. deviceLabel .. i18n("bank") .. " (Unit " .. unit .. ")")
                        :subText(i18n("speedEditorBankDescription"))
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
        :onActionId(function(action) return "speedEditorBank" .. action.id end)

    --------------------------------------------------------------------------------
    -- Actions to Manually Change Application:
    --------------------------------------------------------------------------------
    local applicationmanager = deps.appmanager
    actionmanager.addHandler("global_speededitorapplications", "global")
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
                    :add(i18n("switchSpeedEditorTo") .. " " .. item.displayName)
                    :subText("")
                    :params({
                        bundleID = bundleID,
                    })
                    :id("global_speededitorapplications_switch_" .. bundleID)

                if bundleID ~= "All Applications" then
                    choices
                        :add(i18n("switchSpeedEditorTo") .. " " .. item.displayName .. " " .. i18n("andLaunch"))
                        :subText("")
                        :params({
                            bundleID = bundleID,
                            launch = true,
                        })
                        :id("global_speededitorapplications_launch_" .. bundleID)
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
            return "global_speededitorapplications_" .. params.bundleID
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
