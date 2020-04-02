--- === plugins.core.streamdeck.manager ===
---
--- Elgato Stream Deck Manager Plugin.

local require = require

local log                   = require "hs.logger".new "streamDeck"

local application           = require "hs.application"
local appWatcher            = require "hs.application.watcher"
local canvas                = require "hs.canvas"
local image                 = require "hs.image"
local streamdeck            = require "hs.streamdeck"

local dialog                = require "cp.dialog"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local config                = require "cp.config"
local json                  = require "cp.json"

local displayNotification   = dialog.displayNotification
local imageFromURL          = image.imageFromURL
local spairs                = tools.spairs

local mod = {}

-- defaultLayoutPath -> string
-- Variable
-- Default Layout Path
local defaultLayoutPath = config.basePath .. "/plugins/core/streamdeck/default/Default.cpStreamDeck"

--- plugins.core.streamdeck.manager.defaultLayout -> table
--- Variable
--- Default Stream Deck Layout
mod.defaultLayout = json.read(defaultLayoutPath)

--- plugins.core.streamdeck.manager.numberOfDevices -> number
--- Constant
--- Number of supported devices per Stream Deck model.
mod.numberOfDevices = 9

--- plugins.core.streamdeck.manager.numberOfBanks -> number
--- Variable
--- The number of banks.
mod.numberOfBanks = 9

--- plugins.core.streamdeck.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("streamDeck.activeBanks", {
    ["Mini"] = {},
    ["Original"] = {},
    ["XL"] = {},
})

-- plugins.core.streamdeck.manager.devices -> table
-- Variable
-- Table of Stream Deck Devices.
mod.devices = {
    ["Mini"] = {},
    ["Original"] = {},
    ["XL"] = {},
}

-- plugins.core.streamdeck.manager.deviceOrder -> table
-- Variable
-- Table of Stream Deck Device Orders.
mod.deviceOrder = {
    ["Mini"] = {},
    ["Original"] = {},
    ["XL"] = {},
}

-- plugins.core.streamdeck.manager.numberOfButtons -> table
-- Variable
-- Table of Stream Deck Device Button Count.
mod.numberOfButtons = {
    ["Mini"] = 6,
    ["Original"] = 15,
    ["XL"] = 32,
}

--- plugins.core.streamdeck.manager.items <cp.prop: table>
--- Field
--- Contains all the saved Stream Deck Buttons
mod.items = json.prop(config.userConfigRootPath, "Stream Deck", "Default v2.cpStreamDeck", mod.defaultLayout)

-- imageHolder -> hs.canvas
-- Constant
-- Canvas used to store the blackIcon.
local imageHolder = canvas.new{x = 0, y = 0, h = 100, w = 100}
imageHolder[1] = {
    frame = { h = 100, w = 100, x = 0, y = 0 },
    fillColor = { hex = "#000000" },
    type = "rectangle",
}

-- blackIcon -> hs.image
-- Constant
-- A black icon
local blackIcon = imageHolder:imageFromCanvas()

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
function mod.buttonCallback(object, buttonID, pressed)
    if pressed then
        local serialNumber = object:serialNumber()
        local deviceType = mod.getDeviceType(object)
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

        buttonID = tostring(buttonID)

        if items[deviceType] and items[deviceType][deviceID] and items[deviceType][deviceID][bundleID] and items[deviceType][deviceID][bundleID][bankID] and items[deviceType][deviceID][bundleID][bankID][buttonID] then
            local handlerID = items[deviceType][deviceID][bundleID][bankID][buttonID]["handlerID"]
            local action = items[deviceType][deviceID][bundleID][bankID][buttonID]["action"]
            if handlerID and action then
                local handler = mod._actionmanager.getHandler(handlerID)
                handler:execute(action)
            end
        end
    end
end

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
    for deviceType, devices in pairs(mod.devices) do
        for _, device in pairs(devices) do
            --------------------------------------------------------------------------------
            -- Determine bundleID:
            --------------------------------------------------------------------------------
            local serialNumber = device:serialNumber()

            local buttonCount = mod.numberOfButtons[deviceType]
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
            for buttonID=1, buttonCount do
                local success = false
                local buttonData = bankData and bankData[tostring(buttonID)]
                if buttonData then
                    local label = buttonData["label"]
                    local icon = buttonData["icon"]
                    if icon then
                        --------------------------------------------------------------------------------
                        -- Draw an icon:
                        --------------------------------------------------------------------------------
                        icon = imageFromURL(icon)
                        device:setButtonImage(buttonID, icon)
                        success = true
                    elseif label then
                        --------------------------------------------------------------------------------
                        -- Draw a label:
                        --------------------------------------------------------------------------------
                        local c = canvas.new{x = 0, y = 0, h = 100, w = 100}
                        c[1] = {
                            frame = { h = 100, w = 100, x = 0, y = 0 },
                            fillColor = { hex = "#000000"  },
                            type = "rectangle",
                        }
                        c[2] = {
                            frame = { h = 100, w = 100, x = 0, y = 0 },
                            text = label,
                            textAlignment = "left",
                            textColor = { white = 1.0 },
                            textSize = 20,
                            type = "text",
                        }
                        local textIcon = c:imageFromCanvas()
                        device:setButtonImage(buttonID, textIcon)
                        success = true
                    end
                end
                if not success then
                    --------------------------------------------------------------------------------
                    -- Default to black if no label or icon supplied:
                    --------------------------------------------------------------------------------
                    device:setButtonImage(buttonID, blackIcon)
                end
            end
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
        ["core.action.manager"]             = "actionmanager",
        ["core.commands.global"]            = "global",
    }
}

function plugin.init(deps)
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Setup action:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("cpStreamDeck")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    actionmanager.addHandler("global_streamDeckbanks")
        :onChoices(function(choices)
            for device, _ in pairs(mod.devices) do
                for unit=1, mod.numberOfDevices do

                    local deviceLabel = device
                    if deviceLabel == "Original" then
                        deviceLabel = ""
                    else
                        deviceLabel = deviceLabel .. " "
                    end

                    for bank=1, mod.numberOfBanks do
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
                    if tonumber(currentBank) == mod.numberOfBanks then
                        activeBanks[device][unit][bundleID] = "1"
                    else
                        activeBanks[device][unit][bundleID] = tostring(tonumber(currentBank) + 1)
                    end
                elseif result.action == "previous" then
                    if tonumber(currentBank) == 1 then
                        activeBanks[device][unit][bundleID] = tostring(mod.numberOfBanks)
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

    return mod
end

function plugin.postInit()
    if mod.enabled() then
        mod.start()
    end
end

return plugin
