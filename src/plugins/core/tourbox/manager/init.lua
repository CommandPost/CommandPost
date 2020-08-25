--- === plugins.core.tourbox.manager ===
---
--- Loupedeck CT Manager Plugin.

local require                   = require

local log                       = require "hs.logger".new "tourBox"

local application               = require "hs.application"
local appWatcher                = require "hs.application.watcher"
local timer                     = require "hs.timer"
local serial                    = require "hs.serial"
local bytes                     = require "hs.bytes"

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"

local displayNotification       = dialog.displayNotification
local doAfter                   = timer.doAfter
local hexToBytes                = bytes.hexToBytes

local mod = {}

-- fileExtension -> string
-- Variable
-- File Extension for Loupedeck CT
local fileExtension = ".cpTourBox"

-- defaultFilename -> string
-- Variable
-- Default Filename for Loupedeck CT Settings
local defaultFilename = "Default" .. fileExtension

local DEVICE_ID = "SLAB_USBtoUART"

local lookup = {
	["01"] 		= {controlType = "side", actionType = "pressAction"},
	["81"] 		= {controlType = "side", actionType = "releaseAction"},
	["21"]      = {controlType = "side", actionType = "doubleClickPressAction"},
	["a1"]      = {controlType = "side", actionType = "doubleClickReleaseAction"},

	["0a"] 		= {controlType = "scroll", actionType = "pressAction"},
	["8a"] 		= {controlType = "scroll", actionType = "releaseAction"},
	["0989"] 	= {controlType = "scroll", actionType = "leftAction"},
	["49c9"] 	= {controlType = "scroll", actionType = "rightAction"},

	["02"] 		= {controlType = "top", actionType = "pressAction"},
	["82"] 		= {controlType = "top", actionType = "releaseAction"},
	["1f"] 		= {controlType = "top", actionType = "doubleClickPressAction"},
	["9f"] 		= {controlType = "top", actionType = "doubleClickReleaseAction"},

	["22"] 		= {controlType = "c1", actionType = "pressAction"},
	["a2"] 		= {controlType = "c1", actionType = "releaseAction"},

	["23"] 		= {controlType = "c2", actionType = "pressAction"},
	["a3"] 		= {controlType = "c2", actionType = "releaseAction"},

	["44c4"] 	= {controlType = "knob", actionType = "leftAction"},
	["0484"] 	= {controlType = "knob", actionType = "rightAction"},

	["0f8f"] 	= {controlType = "dial", actionType = "leftAction"},
	["4fcf"] 	= {controlType = "dial", actionType = "rightAction"},

	["2a"] 		= {controlType = "tour", actionType = "pressAction"},
	["aa"] 		= {controlType = "tour", actionType = "releaseAction"},

	["00"] 		= {controlType = "tall", actionType = "pressAction"},
	["80"] 		= {controlType = "tall", actionType = "releaseAction"},
	["18"] 		= {controlType = "tall", actionType = "doubleClickPressAction"},
	["98"] 		= {controlType = "tall", actionType = "doubleClickReleaseAction"},

	["03"] 		= {controlType = "short", actionType = "pressAction"},
	["83"] 		= {controlType = "short", actionType = "releaseAction"},
	["1c"] 		= {controlType = "short", actionType = "doubleClickPressAction"},
	["9c"] 		= {controlType = "short", actionType = "doubleClickReleaseAction"},

	["10"] 		= {controlType = "up", actionType = "pressAction"},
	["90"] 		= {controlType = "up", actionType = "releaseAction"},

	["11"] 		= {controlType = "down", actionType = "pressAction"},
	["91"] 		= {controlType = "down", actionType = "releaseAction"},

	["12"] 		= {controlType = "left", actionType = "pressAction"},
	["92"] 		= {controlType = "left", actionType = "releaseAction"},

	["13"] 		= {controlType = "right", actionType = "pressAction"},
	["93"] 		= {controlType = "right", actionType = "releaseAction"},
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
    local bankID = activeBanks[bundleID] or "1"

    local item = items[bundleID]
    local bank = item and item[bankID]
    local control = bank and bank[m.controlType]
    local action = control and control[m.actionType]

    --[[
    log.df("%s - %s", m.controlType, m.actionType)
    log.df("bundleID: %s", bundleID)
    log.df("action: %s", hs.inspect(action))
    log.df("-----")
    --]]

    if action then
        executeAction(action)
    end

end

local function tourBoxCallback(_, messageType, _, messageHexString)
    if messageType == "opened" then
        mod.tourBox:sendData(hexToBytes("5500072cd8001afe"))
        mod.tourBox:sendData(hexToBytes("a5001f2cd80001ffffffffffffffff0001ffffffffffffff0100ff01000000fe"))
    else
        if messageHexString and lookup[messageHexString] then
            processMessage(lookup[messageHexString])
        else
            log.ef("Unknown TourBox Command > Type: '%s', Hex: '%s'", messageType, messageHexString)
        end
    end

end

local function setupTourbox()
    local tourBox = serial.newFromName(DEVICE_ID)
    if tourBox then
        tourBox:baudRate(115200):parity("none"):callback(tourBoxCallback):open()
        mod.tourBox = tourBox
    end
end

local function deviceCallback(callbackType, devices)
    if callbackType == "connected" then
        for _, deviceName in pairs(devices) do
            if deviceName == DEVICE_ID then
                log.df("TourBox Connected!")
                setupTourbox()
            end
        end
    end
end

--- plugins.core.tourbox.manager.enabled <cp.prop: boolean>
--- Field
--- Is Loupedeck CT support enabled?
mod.enabled = config.prop("tourbox.enabled", false):watch(function(enabled)
    if enabled then
        mod._appWatcher:start()
        mod.deviceWatcher = serial.deviceCallback(deviceCallback)
        setupTourbox()
    else
        mod.deviceWatcher = nil
        if mod._appWatcher then
            mod._appWatcher:stop()
            mod._appWatcher = nil
        end
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

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    --[[
    local global = deps.global
    global
        :add("enableLoupedeckCT")
        :whenActivated(function()
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :titled(i18n("enableLoupedeckCTSupport"))

    global
        :add("disableLoupedeckCT")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :titled(i18n("disableLoupedeckCTSupport"))

    global
        :add("disableLoupedeckCTandLaunchLoupedeckApp")
        :whenActivated(function()
            mod.enabled(false)
            launchOrFocusByBundleID(LD_BUNDLE_ID)
        end)
        :groupedBy("commandPost")
        :titled(i18n("disableLoupedeckCTSupportAndLaunchLoupedeckApp"))

    global
        :add("enableLoupedeckCTandKillLoupedeckApp")
        :whenActivated(function()
            local apps = applicationsForBundleID(LD_BUNDLE_ID)
            if apps then
                for _, app in pairs(apps) do
                    app:kill9()
                end
            end
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :titled(i18n("enableLoupedeckCTSupportQuitLoupedeckApp"))
    --]]

    --------------------------------------------------------------------------------
    -- Watch for application changes:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function(_, event)
        if event == appWatcher.activated then
            local frontmostApplication = application.frontmostApplication()
            cachedBundleID = frontmostApplication:bundleID()
        end
    end)

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
                choices:add(i18n("tourBox") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("loupedeckCTBankDescription"))
                    :params({ id = i })
                    :id(i)
            end

            choices:add(i18n("next") .. " " .. i18n("tourBox") .. " " .. i18n("bank"))
                :subText(i18n("loupedeckCTBankDescription"))
                :params({ id = "next" })
                :id("next")

            choices:add(i18n("previous") .. " " .. i18n("tourBox") .. " " .. i18n("bank"))
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

                mod.refresh()

                items = mod.items() -- Reload items
                local label = items[bundleID] and items[bundleID][newBank] and items[bundleID][newBank]["bankLabel"] or newBank
                displayNotification(i18n("tourBox") .. " " .. i18n("bank") .. ": " .. label)
            end
        end)
        :onActionId(function(action) return "tourBoxBank" .. action.id end)

    return mod
end

return plugin
