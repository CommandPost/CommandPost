--- === plugins.core.tourbox.manager ===
---
--- Loupedeck CT Manager Plugin.

local require                   = require

local log                       = require "hs.logger".new "tourBox"

local application               = require "hs.application"
local appWatcher                = require "hs.application.watcher"
local bytes                     = require "hs.bytes"
local eventtap                  = require "hs.eventtap"
local host                      = require "hs.host"
local image                     = require "hs.image"
local serial                    = require "hs.serial"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"

local applicationsForBundleID   = application.applicationsForBundleID
local displayNotification       = dialog.displayNotification
local doAfter                   = timer.doAfter
local doEvery                   = timer.doEvery
local hexToBytes                = bytes.hexToBytes
local imageFromPath             = image.imageFromPath
local keyRepeatInterval         = eventtap.keyRepeatInterval
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID

local mod = {}

-- fileExtension -> string
-- Variable
-- File Extension for Loupedeck CT
local fileExtension = ".cpTourBox"

-- defaultFilename -> string
-- Variable
-- Default Filename for Loupedeck CT Settings
local defaultFilename = "Default" .. fileExtension

-- DEVICE_ID -> string
-- Constant
-- The device ID of the TourBox.
local DEVICE_ID = "SLAB_USBtoUART"

-- TOURBOX_CONSOLE_BUNDLE_ID -> string
-- Constant
-- The TourBox Console Bundle ID.
local TOURBOX_CONSOLE_BUNDLE_ID = "com.tourbox.ui.launch"

-- lockup -> table
-- Variable
-- A lookup table that translates TourBox messages to control and action type strings.
local lookup = {
	["01"] 		= {controlType = "side", actionType = "pressAction", supportsDoubleClick = true},
	["81"] 		= {controlType = "side", actionType = "releaseAction", supportsDoubleClick = true},
	["21"]      = {controlType = "side", actionType = "doubleClickPressAction"},
	["a1"]      = {controlType = "side", actionType = "doubleClickReleaseAction"},

	["02"] 		= {controlType = "top", actionType = "pressAction", supportsDoubleClick = true},
	["82"] 		= {controlType = "top", actionType = "releaseAction", supportsDoubleClick = true},
	["1f"] 		= {controlType = "top", actionType = "doubleClickPressAction"},
	["9f"] 		= {controlType = "top", actionType = "doubleClickReleaseAction"},
	["20"] 		= {controlType = "top", actionType = "pressSideAction"},
	["a0"] 		= {controlType = "top", actionType = "releaseSideAction"},

	["00"] 		= {controlType = "tall", actionType = "pressAction", supportsDoubleClick = true},
	["80"] 		= {controlType = "tall", actionType = "releaseAction", supportsDoubleClick = true},
	["18"] 		= {controlType = "tall", actionType = "doubleClickPressAction"},
	["98"] 		= {controlType = "tall", actionType = "doubleClickReleaseAction"},
	["1b"] 		= {controlType = "tall", actionType = "pressSideAction"},
	["9b"] 		= {controlType = "tall", actionType = "releaseSideAction"},
	["1a"]      = {controlType = "tall", actionType = "pressShortAction"},
	["9a"]      = {controlType = "tall", actionType = "releaseShortAction"},

	["03"] 		= {controlType = "short", actionType = "pressAction", supportsDoubleClick = true},
	["83"] 		= {controlType = "short", actionType = "releaseAction", supportsDoubleClick = true},
	["1c"] 		= {controlType = "short", actionType = "doubleClickPressAction"},
	["9c"] 		= {controlType = "short", actionType = "doubleClickReleaseAction"},
	["1e"] 		= {controlType = "short", actionType = "pressSideAction"},
	["9e"] 		= {controlType = "short", actionType = "releaseSideAction"},

	["0a"] 		= {controlType = "scroll", actionType = "pressAction", supportsDoubleClick = true},
	["8a"] 		= {controlType = "scroll", actionType = "releaseAction", supportsDoubleClick = true},
	["49c9"] 	= {controlType = "scroll", actionType = "leftAction"},
	["0989"] 	= {controlType = "scroll", actionType = "rightAction"},
	["4ece"]    = {controlType = "scroll", actionType = "leftSideAction"},
	["0e8e"]    = {controlType = "scroll", actionType = "rightSideAction"},
	["4dcd"]    = {controlType = "scroll", actionType = "leftTopAction"},
	["0d8d"]    = {controlType = "scroll", actionType = "rightTopAction"},
	["4bcb"]    = {controlType = "scroll", actionType = "leftTallAction"},
	["0b8b"]    = {controlType = "scroll", actionType = "rightTallAction"},
	["4ccc"]    = {controlType = "scroll", actionType = "leftShortAction"},
	["0c8c"]    = {controlType = "scroll", actionType = "rightShortAction"},
	["66e6"]    = {controlType = "scroll", actionType = "leftUpAction"},
	["26a6"]    = {controlType = "scroll", actionType = "rightUpAction"},
	["68e8"]    = {controlType = "scroll", actionType = "leftLeftAction"},
	["28a8"]    = {controlType = "scroll", actionType = "rightLeftAction"},
	["67e7"]    = {controlType = "scroll", actionType = "leftDownAction"},
	["27a7"]    = {controlType = "scroll", actionType = "rightDownAction"},
	["69e9"]    = {controlType = "scroll", actionType = "leftRightAction"},
	["29a9"]    = {controlType = "scroll", actionType = "rightRightAction"},

	["0484"] 	= {controlType = "knob", actionType = "leftAction"},
	["44c4"] 	= {controlType = "knob", actionType = "rightAction"},
	["48c8"] 	= {controlType = "knob", actionType = "leftSideAction"},
	["0888"] 	= {controlType = "knob", actionType = "rightSideAction"},
	["47c7"] 	= {controlType = "knob", actionType = "leftTopAction"},
	["0787"] 	= {controlType = "knob", actionType = "rightTopAction"},
	["45c5"] 	= {controlType = "knob", actionType = "leftTallAction"},
	["0585"] 	= {controlType = "knob", actionType = "rightTallAction"},
	["46c6"] 	= {controlType = "knob", actionType = "leftShortAction"},
	["0686"] 	= {controlType = "knob", actionType = "rightShortAction"},

	["22"] 		= {controlType = "c1", actionType = "pressAction"},
	["a2"] 		= {controlType = "c1", actionType = "releaseAction"},
	["24"] 		= {controlType = "c1", actionType = "pressTallAction"},
	["a4"] 		= {controlType = "c1", actionType = "releaseTallAction"},

	["23"] 		= {controlType = "c2", actionType = "pressAction"},
	["a3"] 		= {controlType = "c2", actionType = "releaseAction"},

	["4fcf"] 	= {controlType = "dial", actionType = "leftAction"},
	["0f8f"] 	= {controlType = "dial", actionType = "rightAction"},

	["2a"] 		= {controlType = "tour", actionType = "pressAction"},
	["aa"] 		= {controlType = "tour", actionType = "releaseAction"},

	["10"] 		= {controlType = "up", actionType = "pressAction"},
	["90"] 		= {controlType = "up", actionType = "releaseAction"},
	["14"] 		= {controlType = "up", actionType = "pressSideAction"},
	["94"] 		= {controlType = "up", actionType = "releaseSideAction"},
	["2b"] 		= {controlType = "up", actionType = "pressTopAction"},
	["ab"] 		= {controlType = "up", actionType = "releaseTopAction"},

	["11"] 		= {controlType = "down", actionType = "pressAction"},
	["91"] 		= {controlType = "down", actionType = "releaseAction"},
	["15"] 		= {controlType = "down", actionType = "pressSideAction"},
	["95"] 		= {controlType = "down", actionType = "releaseSideAction"},
	["2c"] 		= {controlType = "down", actionType = "pressTopAction"},
	["ac"] 		= {controlType = "down", actionType = "releaseTopAction"},

	["12"] 		= {controlType = "left", actionType = "pressAction"},
	["92"] 		= {controlType = "left", actionType = "releaseAction"},
	["16"] 		= {controlType = "left", actionType = "pressSideAction"},
	["96"] 		= {controlType = "left", actionType = "releaseSideAction"},
	["2d"] 		= {controlType = "left", actionType = "pressTopAction"},
	["ad"] 		= {controlType = "left", actionType = "releaseTopAction"},

	["13"] 		= {controlType = "right", actionType = "pressAction"},
	["93"] 		= {controlType = "right", actionType = "releaseAction"},
	["17"] 		= {controlType = "right", actionType = "pressSideAction"},
	["97"] 		= {controlType = "right", actionType = "releaseSideAction"},
	["2e"] 		= {controlType = "right", actionType = "pressTopAction"},
	["ae"] 		= {controlType = "right", actionType = "releaseTopAction"},
}

-- cachedBundleID -> string
-- Variable
-- The last bundle ID processed.
local cachedBundleID = ""

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

-- doubleClickInProgress -> table
-- Variable
-- A table containing a list of all the active double click's in progress
local doubleClickInProgress = {}

-- repeatTimers -> table
-- Variable
-- A table containing all the repeat timers
local repeatTimers = {}

-- delayTimers -> table
-- Variable
-- A table containing all the delay timers
local delayTimers = {}

-- ignoreNextReleaseAction -> table
-- Variable
-- A table containing all the release actions to ignore.
local ignoreNextReleaseAction = {}

-- processMessage(message) -> none
-- Function
-- Processes a TourBox message
--
-- Parameters:
--  * message - A table containing the message from the TourBox.
--
-- Returns:
--  * None
local function processMessage(m)
    local items = mod.items()
    local bundleID = cachedBundleID

    --------------------------------------------------------------------------------
    -- Revert to "All Applications" if no settings for frontmost app exist:
    --------------------------------------------------------------------------------
    if not items[bundleID] then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- Ignore if ignored:
    --------------------------------------------------------------------------------
    if items[bundleID] and items[bundleID].ignore then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- If not Automatically Switching Applications:
    --------------------------------------------------------------------------------
    if not mod.automaticallySwitchApplications() then
        bundleID = mod.lastBundleID()
    end

    --------------------------------------------------------------------------------
    -- Get data from settings:
    --------------------------------------------------------------------------------
    local activeBanks = mod.activeBanks()
    local bankID = activeBanks[bundleID] or "1"

    local item = items[bundleID]
    local bank = item and item[bankID]
    local control = bank and bank[m.controlType]
    local action = control and control[m.actionType]

    local controlType = m.controlType
    local actionType = m.actionType
    local supportsDoubleClick = m.supportsDoubleClick

    --------------------------------------------------------------------------------
    -- Release any held down buttons:
    --------------------------------------------------------------------------------
    if actionType:find("elease") then -- This isn't a typo.
        local releaseFn = function()
            local id = controlType .. actionType:gsub("release", "press"):gsub("Release", "Press")
            if repeatTimers[id] then
                repeatTimers[id]:stop()
                repeatTimers[id] = nil
            end
        end
        if supportsDoubleClick then
            --------------------------------------------------------------------------------
            -- This control supports double clicks, so we need to add a delay to check
            -- if it's a single click or a double click:
            --------------------------------------------------------------------------------
            doAfter(0.2, releaseFn)
        else
            --------------------------------------------------------------------------------
            -- This control doesn't support double clicks so trigger it straight away:
            --------------------------------------------------------------------------------
            releaseFn()
        end
    end

    --------------------------------------------------------------------------------
    -- Ignore the release action when Arrow Keys pressed with Side/Top Modifiers:
    --------------------------------------------------------------------------------
    if controlType == "up" or controlType == "down" or controlType == "left" or controlType == "right" then
        if actionType == "releaseAction" and ignoreNextReleaseAction[controlType] then
            ignoreNextReleaseAction[controlType] = false
            return
        end
        if actionType == "releaseTopAction" or actionType == "releaseSideAction" then
            ignoreNextReleaseAction[controlType] = true
        end
    end

    --------------------------------------------------------------------------------
    -- Ignore the release action when Tall button pressed with Short Modifier:
    --------------------------------------------------------------------------------
    if controlType == "tall" then
        if actionType == "releaseAction" and ignoreNextReleaseAction[controlType] then
            ignoreNextReleaseAction[controlType] = false
            return
        end
        if actionType == "releaseShortAction" then
            ignoreNextReleaseAction[controlType] = true
        end

    end

    --log.df("%s - %s", controlType, actionType)

    --------------------------------------------------------------------------------
    -- Trigger actions:
    --------------------------------------------------------------------------------
    if action then
        --------------------------------------------------------------------------------
        -- Function that triggers the
        --------------------------------------------------------------------------------
        local triggerAction = function()
            executeAction(action)
            if action.action and control[actionType .. "Repeat"] then
                local repeatID = controlType .. actionType
                repeatTimers[repeatID] = doEvery(keyRepeatInterval(), function()
                    executeAction(action)
                end)
            end
        end

        --------------------------------------------------------------------------------
        -- A double click should remove any single presses and releases from the queue:
        --------------------------------------------------------------------------------
        if actionType == "doubleClickPressAction" then
            if delayTimers[controlType .. "pressAction"] then
                delayTimers[controlType .. "pressAction"]:stop()
                delayTimers[controlType .. "pressAction"] = nil
            end
            if delayTimers[controlType .. "releaseAction"] then
                delayTimers[controlType .. "releaseAction"]:stop()
                delayTimers[controlType .. "releaseAction"] = nil
            end
        end

        if supportsDoubleClick then
            --------------------------------------------------------------------------------
            -- This control supports double clicks, so we need to add a delay to check
            -- if it's a single click or a double click:
            --------------------------------------------------------------------------------
            local id = controlType .. actionType
            doubleClickInProgress[id] = true
            delayTimers[id] = doAfter(0.2, function()
                if doubleClickInProgress[id] then
                    doubleClickInProgress[id] = false
                    triggerAction()
                end
                delayTimers[id] = nil
            end)
        else
            --------------------------------------------------------------------------------
            -- This control doesn't support double clicks so trigger it straight away:
            --------------------------------------------------------------------------------
            triggerAction()
        end
    end
end

-- tourBoxCallback(obj, messageType, data, messageHexString) -> none
-- Function
-- TourBox Serial Callback
--
-- Parameters:
--  * obj - The hs.serial object
--  * messageType - A string containing the message type
--  * message - The encoded message
--  * messageHexString - The message as a hex string
--
-- Returns:
--  * None
local function tourBoxCallback(obj, messageType, message, messageHexString)
    if messageType == "opened" then
        --------------------------------------------------------------------------------
        -- These are the magic bytes that initialise the TourBox. What they mean, or
        -- what they do, remain a mystery.
        --------------------------------------------------------------------------------
        mod.tourBox:sendData(hexToBytes("5500072cd8001afe"))
        mod.tourBox:sendData(hexToBytes("a5001f2cd80001ffffffffffffffff0001ffffffffffffff0100ff01000000fe"))
    elseif messageType == "error" then
        if not obj:isOpen() then
            --------------------------------------------------------------------------------
            -- This most likely means the resource is busy, so lets retry:
            --------------------------------------------------------------------------------
            mod.connectToTourBox()
        else
            log.ef("Unexpected TourBox Error: %s", message)
        end
    else
        if messageHexString and lookup[messageHexString] then
            processMessage(lookup[messageHexString])
        else
            print(string.format("Unexpected TourBox Message (%s): '%s'", messageType, messageHexString))
        end
    end
end

--- plugins.core.tourbox.manager.connectToTourBox() -> none
--- Function
--- Attempts to establish the TourBox serial connection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.connectToTourBox()
    if not mod.tourBox then
        local tourBox = serial.newFromName(DEVICE_ID)
        if tourBox then
            mod.resetTimers()
            tourBox:baudRate(115200):parity("none"):callback(tourBoxCallback):open()
            mod.tourBox = tourBox
        end
    else
        mod.resetTimers()
        mod.tourBox:open()
    end
end

-- deviceCallback(callbackType, devices) -> none
-- Function
-- The hs.serial device callback.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function deviceCallback(callbackType, devices)
    if callbackType == "connected" then
        for _, deviceName in pairs(devices) do
            if deviceName == DEVICE_ID then
                mod.connectToTourBox()
            end
        end
    end
end

--- plugins.core.tourbox.manager.resetTimers() -> none
--- Function
--- Resets all the various timers and memories.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.resetTimers()
    doubleClickInProgress = {}

    for _, v in pairs(repeatTimers) do
        v:stop()
    end
    repeatTimers = {}

    for _, v in pairs(delayTimers) do
        v:stop()
    end
    delayTimers = {}

    ignoreNextReleaseAction = {}
end

--- plugins.core.tourbox.manager.enabled <cp.prop: boolean>
--- Field
--- Is Loupedeck CT support enabled?
mod.enabled = config.prop("tourbox.enabled", false):watch(function(enabled)
    if enabled then
        mod._appWatcher = appWatcher.new(function(_, event)
            if event == appWatcher.activated then
                local frontmostApplication = application.frontmostApplication()
                cachedBundleID = frontmostApplication:bundleID()
                mod.resetTimers()
            end
        end):start()
        mod.deviceWatcher = serial.deviceCallback(deviceCallback)
        mod.connectToTourBox()

        --------------------------------------------------------------------------------
        -- Check again in 5 seconds, just case TourBox Console took a while to close:
        --------------------------------------------------------------------------------
        doAfter(5, mod.connectToTourBox)
    else
        mod.deviceWatcher = nil
        if mod._appWatcher then
            mod._appWatcher:stop()
            mod._appWatcher = nil
        end
        if mod.tourBox then
            mod.tourBox:close()
            mod.tourBox = nil
        end

        mod.resetTimers()

        collectgarbage()
        collectgarbage()
    end
end)

-- defaultLayoutPath -> string
-- Variable
-- Default Layout Path
local defaultLayoutPath = config.basePath .. "/plugins/core/tourbox/default/Default.cpTourBox"

--- plugins.core.tourbox.manager.defaultLayout -> table
--- Variable
--- Default Loupedeck CT Layout
mod.defaultLayout = json.read(defaultLayoutPath)

--- plugins.core.tourbox.manager.automaticallySwitchApplications <cp.prop: boolean>
--- Field
--- Enable or disable the automatic switching of applications.
mod.automaticallySwitchApplications = config.prop("tourbox.automaticallySwitchApplications", false)

--- plugins.core.tourbox.manager.displayMessageWhenChangingBanks <cp.prop: boolean>
--- Field
--- Display message when changing banks?
mod.displayMessageWhenChangingBanks = config.prop("tourbox.displayMessageWhenChangingBanks", true)

--- plugins.core.tourbox.manager.automaticallySwitchApplications <cp.prop: boolean>
--- Field
--- Enable or disable the automatic switching of applications.
mod.lastBundleID = config.prop("tourbox.lastBundleID", "All Applications")

--- plugins.core.tourbox.manager.items <cp.prop: table>
--- Field
--- Contains all the saved TourBox layouts.
mod.items = json.prop(config.userConfigRootPath, "TourBox", defaultFilename, mod.defaultLayout)

--- plugins.core.tourbox.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("tourbox.activeBanks", {})

--- plugins.core.tourbox.manager.reset()
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

local plugin = {
    id          = "core.tourbox.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.application.manager"]        = "appmanager",
        ["core.controlsurfaces.manager"]    = "csman",
        ["core.commands.global"]            = "global",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- TourBox Icon:
    --------------------------------------------------------------------------------
    local tourBoxIcon = imageFromPath(env:pathToAbsolute("/../prefs/images/TourBox.icns"))

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("enableTourBox")
        :whenActivated(function()
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("enableTourBoxSupport"))

    global
        :add("disableTourBox")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("disableTourBoxSupport"))

    global
        :add("toggleTourBox")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("toggleTourBoxSupport"))

    global
        :add("disableTourBoxAndLaunchTourBoxConsole")
        :whenActivated(function()
            mod.enabled(false)
            launchOrFocusByBundleID(TOURBOX_CONSOLE_BUNDLE_ID)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("disableTourBoxAndLaunchTourBoxConsole"))

    global
        :add("enableTourBoxSupportQuitTourBoxConsole")
        :whenActivated(function()
            local apps = applicationsForBundleID(TOURBOX_CONSOLE_BUNDLE_ID)
            if apps then
                for _, app in pairs(apps) do
                    app:kill9()
                end
            end
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("enableTourBoxSupportQuitTourBoxConsole"))

    --------------------------------------------------------------------------------
    -- Connect to the TourBox:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    local numberOfBanks = deps.csman.NUMBER_OF_BANKS
    actionmanager.addHandler("global_tourbox_banks")
        :onChoices(function(choices)
            for i=1, numberOfBanks do
                choices
                    :add(i18n("tourBox") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("tourBoxBankDescription"))
                    :params({ id = i })
                    :id(i)
                    :image(tourBoxIcon)
            end

            choices
                :add(i18n("next") .. " " .. i18n("tourBox") .. " " .. i18n("bank"))
                :subText(i18n("tourBoxBankDescription"))
                :params({ id = "next" })
                :id("next")
                :image(tourBoxIcon)

            choices:add(i18n("previous") .. " " .. i18n("tourBox") .. " " .. i18n("bank"))
                :subText(i18n("tourBoxBankDescription"))
                :params({ id = "previous" })
                :id("previous")
                :image(tourBoxIcon)

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

                --------------------------------------------------------------------------------
                -- If not Automatically Switching Applications:
                --------------------------------------------------------------------------------
                if not mod.automaticallySwitchApplications() then
                    bundleID = mod.lastBundleID()
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

                --------------------------------------------------------------------------------
                -- Reset any timers:
                --------------------------------------------------------------------------------
                mod.resetTimers()

                --------------------------------------------------------------------------------
                -- Display a notification if enabled:
                --------------------------------------------------------------------------------
                if mod.displayMessageWhenChangingBanks() then
                    local newBank = activeBanks[bundleID]
                    items = mod.items() -- Reload items
                    local label = items[bundleID] and items[bundleID][newBank] and items[bundleID][newBank]["bankLabel"]
                    if label then
                        displayNotification(label)
                    else
                        displayNotification(i18n("tourBox") .. " " .. i18n("bank") .. ": " .. newBank)
                    end
                end
            end
        end)
        :onActionId(function(action) return "tourBoxBank" .. action.id end)

    return mod
end

return plugin
