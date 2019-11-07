--- === plugins.core.streamdeck.manager ===
---
--- Elgato Stream Deck Manager Plugin.

local require = require

local log               = require "hs.logger".new "streamDeck"

local application       = require "hs.application"
local canvas            = require "hs.canvas"
local fnutils           = require "hs.fnutils"
local image             = require "hs.image"
local streamdeck        = require "hs.streamdeck"

local dialog            = require "cp.dialog"
local i18n              = require "cp.i18n"

local config            = require "cp.config"
local json              = require "cp.json"

local copy              = fnutils.copy

local mod = {}

--- plugins.core.streamdeck.manager.DEFAULT_GROUP -> string
--- Constant
--- The default group.
mod.DEFAULT_GROUP = "global"

-- FILE_NAME -> string
-- Constant
-- File name of settings file.
local FILE_NAME = "Default.cpStreamDeck"

-- FOLDER_NAME -> string
-- Constant
-- Folder Name where settings file is contained.
local FOLDER_NAME = "Stream Deck"

-- plugins.core.streamdeck.manager._groupStatus -> table
-- Variable
-- Group Statuses.
mod._groupStatus = {}

-- plugins.core.streamdeck.manager._streamDeck -> table
-- Variable
-- Stream Deck Instances.
mod._streamDeck = {}

-- plugins.core.touchbar.manager._currentSubGroup -> table
-- Variable
-- Current Stream Deck Sub Group Statuses.
mod._currentSubGroup = config.prop("streamDeckCurrentSubGroup", {})

--- plugins.core.streamdeck.manager.maxItems -> number
--- Variable
--- The maximum number of Stream Deck items per group.
mod.maxItems = 15

--- plugins.core.streamdeck.manager.numberOfSubGroups -> number
--- Variable
--- The number of Sub Groups per Stream Deck Group.
mod.numberOfSubGroups = 9

-- plugins.core.streamdeck.manager._items <cp.prop: table>
-- Field
-- Contains all the saved Stream Deck Buttons
mod._items = json.prop(config.userConfigRootPath, FOLDER_NAME, FILE_NAME, {})

--- plugins.core.streamdeck.manager.clear() -> none
--- Function
--- Clears the Stream Deck items.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.clear()
    mod._items({})
    mod.update()
end

--- plugins.core.streamdeck.manager.updateOrder(direction, button, group) -> none
--- Function
--- Shifts a Stream Deck button either up or down.
---
--- Parameters:
---  * direction - Either "up" or "down"
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * None
function mod.updateOrder(direction, button, group)
    local buttons = mod._items()

    local shiftButton
    if direction == "down" then
        shiftButton = tostring(tonumber(button) + 1)
    else
        shiftButton = tostring(tonumber(button) - 1)
    end

    if not buttons[group] then
        buttons[group] = {}
    end
    if not buttons[group][button] then
        buttons[group][button] = {}
    end
    if not buttons[group][shiftButton] then
        buttons[group][shiftButton] = {}
    end

    local original = copy(buttons[group][button])
    local new = copy(buttons[group][shiftButton])

    buttons[group][button] = new
    buttons[group][shiftButton] = original

    mod._items(buttons)
    mod.update()
end

--- plugins.core.streamdeck.manager.updateIcon(button, group, icon) -> none
--- Function
--- Updates a Stream Deck icon.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---  * icon - Icon Data as string
---
--- Returns:
---  * None
function mod.updateIcon(button, group, icon)
    local items = mod._items()

    button = tostring(button)

    if not items[group] then
        items[group] = {}
    end
    if not items[group][button] then
        items[group][button] = {}
    end
    items[group][button]["icon"] = icon

    mod._items(items)
    mod.update()
end

--- plugins.core.streamdeck.manager.setBankLabel(group, label) -> none
--- Function
--- Sets a Stream Deck Bank Label.
---
--- Parameters:
---  * group - Group ID as string
---  * label - Label as string
---
--- Returns:
---  * None
function mod.setBankLabel(group, label)
    local items = mod._items()

    if not items[group] then
        items[group] = {}
    end
    items[group]["bankLabel"] = label

    mod._items(items)
    mod.update()
end

--- plugins.core.streamdeck.manager.getBankLabel(group) -> string
--- Function
--- Returns a specific Stream Deck Bank Label.
---
--- Parameters:
---  * group - Group ID as string
---
--- Returns:
---  * Label as string
function mod.getBankLabel(group)
    local items = mod._items()
    if items[group] and items[group] and items[group]["bankLabel"] then
        return items[group]["bankLabel"]
    else
        return nil
    end
end

--- plugins.core.streamdeck.manager.updateAction(button, group, action) -> boolean
--- Function
--- Updates a Stream Deck action.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---  * actionTitle - Action Title as string
---  * handlerID - Handler ID as string
---  * action - Action as table
---
--- Returns:
---  * `true` if successfully updated, or `false` if a duplicate entry was found
function mod.updateAction(button, group, actionTitle, handlerID, action)
    local items = mod._items()

    --------------------------------------------------------------------------------
    -- Check to make sure the widget isn't already in use:
    --------------------------------------------------------------------------------
    if handlerID and handlerID:sub(-8) == "_widgets" then
        for _, _group in pairs(items) do
            for _, _button in pairs(_group) do
                if _button.action and _button.action.id and action.id and _button.action.id == action.id then
                    --------------------------------------------------------------------------------
                    -- Duplicate found, so abort:
                    --------------------------------------------------------------------------------
                    return false
                end
            end
        end
    end

    button = tostring(button)
    if not items[group] then
        items[group] = {}
    end
    if not items[group][button] then
        items[group][button] = {}
    end
    items[group][button]["actionTitle"] = actionTitle
    items[group][button]["handlerID"] = handlerID
    items[group][button]["action"] = action

    mod._items(items)
    mod.update()
    return true
end

--- plugins.core.streamdeck.manager.updateLabel(button, group, label) -> none
--- Function
--- Updates a Stream Deck label.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---  * label - Label as string
---
--- Returns:
---  * None
function mod.updateLabel(button, group, label)
    local items = mod._items()

    button = tostring(button)

    if not items[group] then
        items[group] = {}
    end
    if not items[group][button] then
        items[group][button] = {}
    end
    items[group][button]["label"] = label

    mod._items(items)
    mod.update()
end

--- plugins.core.streamdeck.manager.getIcon(button, group) -> string
--- Function
--- Returns a specific Stream Deck Icon.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * Icon data as string
function mod.getIcon(button, group)
    local items = mod._items()
    if items[group] and items[group][button] and items[group][button]["icon"] then
        return items[group][button]["icon"]
    else
        return nil
    end
end

--- plugins.core.streamdeck.manager.getActionTitle(button, group) -> string
--- Function
--- Returns a specific Stream Deck Action Title.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * Action as string
function mod.getActionTitle(button, group)
    local items = mod._items()
    if items[group] and items[group][button] and items[group][button]["actionTitle"] then
        return items[group][button]["actionTitle"]
    else
        return nil
    end
end

--- plugins.core.streamdeck.manager.getActionHandlerID(button, group) -> string
--- Function
--- Returns a specific Stream Deck Action Handler ID.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * Action as string
function mod.getActionHandlerID(button, group)
    local items = mod._items()
    if items[group] and items[group][button] and items[group][button]["handlerID"] then
        return items[group][button]["handlerID"]
    else
        return nil
    end
end

--- plugins.core.streamdeck.manager.getAction(button, group) -> string
--- Function
--- Returns a specific Stream Deck Action.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * Action as string
function mod.getAction(button, group)
    local items = mod._items()
    if items[group] and items[group][button] and items[group][button]["action"] then
        return items[group][button]["action"]
    else
        return nil
    end
end

--- plugins.core.streamdeck.manager.getLabel(button, group) -> string
--- Function
--- Returns a specific Stream Deck Label.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * Label as string
function mod.getLabel(button, group)
    local items = mod._items()
    if items[group] and items[group][button] and items[group][button]["label"] then
        return items[group][button]["label"]
    else
        return nil
    end
end

--- plugins.core.streamdeck.manager.getBankLabel(group) -> string
--- Function
--- Returns a specific Stream Deck Bank Label.
---
--- Parameters:
---  * group - Group ID as string
---
--- Returns:
---  * Label as string
function mod.getBankLabel(group)
    local items = mod._items()
    if items[group] and items[group] and items[group]["bankLabel"] then
        return items[group]["bankLabel"]
    else
        return nil
    end
end

--- plugins.core.streamdeck.manager.activeGroup() -> string
--- Function
--- Returns the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns the active group or `manager.defaultGroup` as a string.
function mod.activeGroup()
    local groupStatus = mod._groupStatus
    for group, status in pairs(groupStatus) do
        if status then
            return group
        end
    end
    return mod.DEFAULT_GROUP
end

--- plugins.core.streamdeck.manager.activeSubGroup() -> string
--- Function
--- Returns the active sub-group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns the active sub group as string
function mod.activeSubGroup()
    local currentSubGroup = mod._currentSubGroup()
    local result = 1
    local activeGroup = mod.activeGroup()
    if currentSubGroup[activeGroup] then
        result = currentSubGroup[activeGroup]
    end
    return tostring(result)
end

--- plugins.core.streamdeck.manager.gotoSubGroup() -> none
--- Function
--- Loads a specific sub-group.
---
--- Parameters:
---  * id - The ID of the sub-group.
---
--- Returns:
---  * None
function mod.gotoSubGroup(id)
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    currentSubGroup[activeGroup] = id
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.streamdeck.manager.forceGroupChange(combinedGroupAndSubGroupID) -> none
--- Function
--- Loads a specific sub-group.
---
--- Parameters:
---  * combinedGroupAndSubGroupID - The group and subgroup as a single string.
---
--- Returns:
---  * None
function mod.forceGroupChange(combinedGroupAndSubGroupID, notify)
    if combinedGroupAndSubGroupID then
        local group = string.sub(combinedGroupAndSubGroupID, 1, -2)
        local subGroup = string.sub(combinedGroupAndSubGroupID, -1)
        if group and subGroup then
            local currentSubGroup = mod._currentSubGroup()
            currentSubGroup[group] = tonumber(subGroup)
            mod._currentSubGroup(currentSubGroup)
        end
        if notify then
            local bankLabel = mod.getBankLabel(combinedGroupAndSubGroupID)
            if bankLabel then
                dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("streamDeck") .. " " .. i18n("bank") .. ": " .. bankLabel)
            else
                dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("streamDeck") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. group) .. " " .. subGroup)
            end
        end
    end
end

--- plugins.core.streamdeck.manager.nextSubGroup() -> none
--- Function
--- Goes to the next sub-group for the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.nextSubGroup()
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    local currentSubGroupValue = currentSubGroup[activeGroup] or 1
    if currentSubGroupValue < mod.numberOfSubGroups then
        currentSubGroup[activeGroup] = currentSubGroupValue + 1
    else
        currentSubGroup[activeGroup] = 1
    end
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.streamdeck.manager.previousSubGroup() -> none
--- Function
--- Goes to the previous sub-group for the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.previousSubGroup()
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    local currentSubGroupValue = currentSubGroup[activeGroup] or 1
    if currentSubGroupValue == 1 then
        currentSubGroup[activeGroup] = mod.numberOfSubGroups
    else
        currentSubGroup[activeGroup] = currentSubGroupValue - 1
    end
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.streamdeck.manager.incrementActiveSubGroup() -> none
--- Function
--- Increments the active sub-group
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.incrementActiveSubGroup()
    local currentSubGroup = mod._currentSubGroup()

    local items = mod._items()
    local activeGroup = mod.activeGroup()
    local result = 0
    local startingGroup = 1
    if currentSubGroup[activeGroup] then
        startingGroup = currentSubGroup[activeGroup]
    end
    for i=startingGroup + 1, mod.numberOfSubGroups do
        if items[activeGroup .. tostring(i)] then
            result  = i
            break
        end
    end
    if result == 0 then
        local foundResult = false
        for i=1, mod.numberOfSubGroups do
            if items[activeGroup .. tostring(i)] then
                result  = i
                foundResult = true
                break
            end
        end
        if not foundResult then
            result = 1
        end
    end
    currentSubGroup[activeGroup] = result

    -- Save to Preferences:
    mod._currentSubGroup(currentSubGroup)

    dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("streamDeck") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. activeGroup) .. " " .. result)
end


--- plugins.core.streamdeck.manager.groupStatus(groupID, status) -> none
--- Function
--- Updates a group's visibility status.
---
--- Parameters:
---  * groupID - the group you want to update as a string.
---  * status - the status of the group as a boolean.
---
--- Returns:
---  * None
function mod.groupStatus(groupID, status)
    mod._groupStatus[groupID] = status
    mod.update()
end

-- convertButtonID(buttonID) -> number
-- Function
-- Converts the button ID to reflect Stream Deck numbering.
--
-- Parameters:
--  * buttonID
--
-- Returns:
--  * A number
local function convertButtonID(buttonID)
    --------------------------------------------------------------------------------
    -- TODO: Fix lazy programming (sorry David)
    --------------------------------------------------------------------------------
    buttonID = tonumber(buttonID)
    if buttonID == 1 then
        return 5
    elseif buttonID == 2 then
        return 4
    elseif buttonID == 3 then
        return 3
    elseif buttonID == 4 then
        return 2
    elseif buttonID == 5 then
        return 1
    elseif buttonID == 6 then
        return 10
    elseif buttonID == 7 then
        return 9
    elseif buttonID == 8 then
        return 8
    elseif buttonID == 9 then
        return 7
    elseif buttonID == 10 then
        return 6
    elseif buttonID == 11 then
        return 15
    elseif buttonID == 12 then
        return 14
    elseif buttonID == 13 then
        return 13
    elseif buttonID == 14 then
        return 12
    elseif buttonID == 15 then
        return 11
    else
        return nil
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
function mod.buttonCallback(_, buttonID, pressed)
    local activeGroup = mod.activeGroup()
    local activeSubGroup = mod.activeSubGroup()
    local activeGroupAndSubGroup = activeGroup .. activeSubGroup
    if pressed then
        local handlerID = mod.getActionHandlerID(tostring(convertButtonID(buttonID)), activeGroupAndSubGroup)
        local action = mod.getAction(tostring(convertButtonID(buttonID)), activeGroupAndSubGroup)
        if handlerID and action then
            local handler = mod._actionmanager.getHandler(handlerID)
            handler:execute(action)
        end
    end
end

--- plugins.core.streamdeck.manager.update() -> none
--- Function
--- Updates the Stream Deck.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()

    if not mod._streamDeck then
        log.df("Update called, but no Stream Deck available.")
        return
    end

    --------------------------------------------------------------------------------
    -- Reset Stream Deck:
    --------------------------------------------------------------------------------
    for _, streamDeck in pairs(mod._streamDeck) do
        streamDeck:reset()
    end

    --------------------------------------------------------------------------------
    -- Create new buttons and widgets:
    --------------------------------------------------------------------------------
    local items = mod._items()

    local activeGroup = mod.activeGroup()
    local activeSubGroup = mod.activeSubGroup()
    local activeGroupAndSubGroup = activeGroup .. activeSubGroup

    for groupID, group in pairs(items) do
        if groupID == activeGroupAndSubGroup then
            for buttonID, button in pairs(group) do
                if button["action"] then
                    local label         = button["label"] or nil
                    local icon          = button["icon"] or nil
                    for _, streamDeck in pairs(mod._streamDeck) do
                        if icon then
                            icon = image.imageFromURL(icon) --:setSize({w=36,h=36})
                            streamDeck:setButtonImage(convertButtonID(buttonID), icon)
                        elseif label then
                            local imageHolder = canvas.new{x = 0, y = 0, h = 100, w = 100}
                            imageHolder[1] = {
                                frame = { h = 100, w = 100, x = 0, y = 0 },
                                fillColor = { alpha = 0.5, green = 1.0  },
                                type = "rectangle",
                            }
                            imageHolder[2] = {
                                frame = { h = 100, w = 100, x = 0, y = 40 },
                                text = label,
                                textAlignment = "center",
                                textColor = { white = 1.0 },
                                textSize = 20,
                                type = "text",
                            }
                            local textIcon = imageHolder:imageFromCanvas()
                            streamDeck:setButtonImage(convertButtonID(buttonID), textIcon)
                        end
                    end
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
        if connected then
            mod._streamDeck[serialNumber] = object:buttonCallback(mod.buttonCallback)
            mod.update()
        else
            if mod._streamDeck and mod._streamDeck[serialNumber] then
                --log.df("Disconnected Stream Deck: %s", serialNumber)
                mod._streamDeck[serialNumber] = nil
            else
                log.ef("Disconnected Stream Deck wasn't previously registered.")
            end
        end
    end
end

--- plugins.core.streamdeck.manager.appWatcherCallback(name, event, app) -> none
--- Function
--- Stream Deck App Watcher Callback
---
--- Parameters:
---  * name - A string containing the name of the application
---  * event - An event type
---  * app - An `hs.application` object representing the application, or `nil` if the application couldn't be found
---
--- Returns:
---  * None
function mod.appWatcherCallback(_, _, app)
    if app and app:bundleID() == "com.elgato.StreamDeck" then
        log.ef("Stream Deck App is running. This must be closed to activate Stream Deck support in CommandPost.")
        mod.enabled(false)
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
    if #application.applicationsForBundleID("com.elgato.StreamDeck") == 0 then
        mod._streamDeck = {}
        mod._appWatcher = application.watcher.new(mod.appWatcherCallback):start()
        streamdeck.init(mod.discoveryCallback)
        return true
    else
        log.ef("Stream Deck App is already running. This must be closed to activate Stream Deck support in CommandPost.")
        mod.enabled(false)
        return false
    end
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
    if mod._streamDeck then
        for i, _ in pairs(mod._streamDeck) do
            mod._streamDeck[i] = nil
        end
        mod._streamDeck = nil
    end
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
    local global = deps.global
    global:add("cpStreamDeck")
        :whenActivated(mod.toggle)
        :groupedBy("commandPost")

    mod._actionmanager = deps.actionmanager
    return mod
end

function plugin.postInit()
    if mod.enabled() then
        mod.start()
    end
end

return plugin
