--- === plugins.core.touchbar.manager ===
---
--- Touch Bar Manager Plugin.

local require           = require

local log               = require "hs.logger".new "tbManager"

local canvas            = require "hs.canvas"
local fnutils           = require "hs.fnutils"
local host              = require "hs.host"
local image             = require "hs.image"
local styledtext        = require "hs.styledtext"

local config            = require "cp.config"
local dialog            = require "cp.dialog"
local i18n              = require "cp.i18n"
local json              = require "cp.json"
local prop              = require "cp.prop"
local tools             = require "cp.tools"

local semver            = require "semver"

local widgets           = require "widgets"

local copy              = fnutils.copy
local imageFromPath     = image.imageFromPath

local mod = {}

--- plugins.core.touchbar.manager.DEFAULT_GROUP -> string
--- Constant
--- The default group.
mod.DEFAULT_GROUP = "global"

--- plugins.core.touchbar.manager.FILE_NAME -> string
--- Constant
--- File name of settings file.
mod.FILE_NAME = "Default.cpTouchBar"

--- plugins.core.touchbar.manager.FOLDER_NAME -> string
--- Constant
--- Folder Name where settings file is contained.
mod.FOLDER_NAME = "Touch Bar"

--- plugins.core.touchbar.manager.widgets -> table
--- Variable
--- Widget Manager
mod.widgets = widgets

-- plugins.core.touchbar.manager._tbItems -> table
-- Variable
-- Touch Bar Items.
mod._tbItems = {}

-- plugins.core.touchbar.manager._tbItemIDs -> table
-- Variable
-- Touch Bar Item IDs.
mod._tbItemIDs = {}

-- plugins.core.touchbar.manager._groupStatus -> table
-- Variable
-- Group Statuses.
mod._groupStatus = {}

-- plugins.core.touchbar.manager._currentSubGroup -> table
-- Variable
-- Current Touch Bar Sub Group Statuses.
mod._currentSubGroup = config.prop("touchBarCurrentSubGroup", {})

--- plugins.core.touchbar.manager.maxItems -> number
--- Variable
--- The maximum number of Touch Bar items per group.
mod.maxItems = 20

--- plugins.core.touchbar.manager.numberOfSubGroups -> number
--- Variable
--- The number of Sub Groups per Touch Bar Group.
mod.numberOfSubGroups = 9

--- plugins.core.touchbar.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Touch Bar Support.
mod.enabled = config.prop("enableTouchBar", false):watch(function(enabled)
    if enabled then
        mod.start()
    else
        mod.stop()
    end
end)

--- plugins.core.touchbar.manager.buttons <cp.prop: table>
--- Field
--- Contains all the saved Touch Bar Buttons
mod._items = json.prop(config.userConfigRootPath, mod.FOLDER_NAME, mod.FILE_NAME, {})

mod.macOSVersionSupported = prop(function()
    return semver(tools.macOSVersion()) >= semver("10.12.1")
end)

--- plugins.core.touchbar.manager.supported <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the Touch Bar is supported on this version of macOS.
mod.supported = mod.macOSVersionSupported:AND(prop(function()
    local touchbar = mod.touchbar()
    return touchbar and touchbar.supported()
end))

--- plugins.core.touchbar.manager.touchbar() -> none
--- Function
--- Returns the `hs._asm.undocumented.touchbar` object if it exists.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `hs._asm.undocumented.touchbar`
function mod.touchbar()
    if not mod._touchbar then
        if mod.macOSVersionSupported() then
            mod._touchbar = require "hs._asm.undocumented.touchbar"
        else
            mod._touchbar = {
                supported = function() return false end,
            }
        end
    end
    return mod._touchbar
end

--- plugins.core.touchbar.manager.clear() -> none
--- Function
--- Clears the Touch Bar items.
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

--- plugins.core.touchbar.manager.updateOrder(direction, button, group) -> none
--- Function
--- Shifts a Touch Bar button either up or down.
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

--- plugins.core.touchbar.manager.updateIcon(button, group, icon) -> none
--- Function
--- Updates a Touch Bar icon.
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

--- plugins.core.touchbar.manager.updateAction(button, group, action) -> boolean
--- Function
--- Updates a Touch Bar action.
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

--- plugins.core.touchbar.manager.updateLabel(button, group, label) -> none
--- Function
--- Updates a Touch Bar label.
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

--- plugins.core.touchbar.manager.updateBankLabel(group, label) -> none
--- Function
--- Updates a Touch Bar Bank Label.
---
--- Parameters:
---  * group - Group ID as string
---  * label - Label as string
---
--- Returns:
---  * None
function mod.updateBankLabel(group, label)
    local items = mod._items()

    if not items[group] then
        items[group] = {}
    end
    items[group]["bankLabel"] = label

    mod._items(items)
    mod.update()
end

--- plugins.core.touchbar.manager.getIcon(button, group) -> string
--- Function
--- Returns a specific Touch Bar Icon.
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

--- plugins.core.touchbar.manager.getActionTitle(button, group) -> string
--- Function
--- Returns a specific Touch Bar Action Title.
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

--- plugins.core.touchbar.manager.getActionHandlerID(button, group) -> string
--- Function
--- Returns a specific Touch Bar Action Handler ID.
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

--- plugins.core.touchbar.manager.getAction(button, group) -> string
--- Function
--- Returns a specific Touch Bar Action.
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

--- plugins.core.touchbar.manager.getLabel(button, group) -> string
--- Function
--- Returns a specific Touch Bar Label.
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

--- plugins.core.touchbar.manager.getBankLabel(group) -> string
--- Function
--- Returns a specific Touch Bar Bank Label.
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

--- plugins.core.touchbar.manager.start() -> none
--- Function
--- Starts the CommandPost Touch Bar module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    local tb = mod.touchbar()
    if tb and not mod._bar then
        mod._bar = tb.bar.new()

        --------------------------------------------------------------------------------
        -- Resize Icon:
        --------------------------------------------------------------------------------
        local icon = canvas.new{x = 0, y = 0, w = 512, h = 512 }
        icon[1] = {
          type="image",
          image = image.imageFromPath(config.bundledPluginsPath .. "/core/touchbar/images/icon.png"),
          frame = { x = "15%", y = "18%", h = "65%", w = "65%" },
        }

        --------------------------------------------------------------------------------
        -- Setup System Icon:
        --------------------------------------------------------------------------------
        mod._sysTrayIcon = mod.touchbar().item.newButton(icon:imageFromCanvas(), "CommandPost")
                             :callback(function()
                                mod.incrementActiveSubGroup()
                                mod.update()
                             end)
                             :addToSystemTray(true)

        --------------------------------------------------------------------------------
        -- Update Touch Bar:
        --------------------------------------------------------------------------------
        mod.update()
    end
end

--- plugins.core.touchbar.manager.stop() -> none
--- Function
--- Stops the CommandPost Touch Bar module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    if mod._bar then
        mod._sysTrayIcon:addToSystemTray(false)
        mod._bar:dismissModalBar()
        mod._bar = nil
        mod._sysTrayIcon = nil
    end
end

--- plugins.core.touchbar.manager.toggle() -> none
--- Function
--- Toggles the CommandPost Touch Bar module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggle()
    if not mod._bar then
        mod.start()
    else
        mod.stop()
    end
end

-- buttonCallback(item) -> none
-- Function
-- Callback that's triggered when you click a Touch Bar button.
--
-- Parameters:
--  * item - The Touch Bar item.
--
-- Returns:
--  * None
local function buttonCallback(item)
    local id = item:identifier()
    local idTable = tools.split(id, "_")
    local group = idTable[1]
    local button = idTable[2]

    local action = mod.getAction(button, group)
    local handlerID = mod.getActionHandlerID(button, group)

    local handler = mod._actionmanager.getHandler(handlerID)
    handler:execute(action)
end

-- addButton(icon, action, label, id) -> none
-- Function
-- Add's a new button to the Touch Bar item tables.
--
-- Parameters:
--  * icon - Icon data as string
--  * action - Action as string
--  * label - Label as string
--  * id - Unique ID of the button
--
-- Returns:
--  * None
local function addButton(icon, _, label, id)
    if not label then
        label = ""
    end
    if icon then
        icon = image.imageFromURL(icon):setSize({w=36,h=36})
    end
    table.insert(mod._tbItemIDs, id)
    if icon then
        table.insert(mod._tbItems, mod.touchbar().item.newButton(label, icon, id):callback(buttonCallback))
    else
        table.insert(mod._tbItems, mod.touchbar().item.newButton(label, id):callback(buttonCallback))
    end
end

-- addWidget(icon, action, label, id) -> none
-- Function
-- Add's a new widget to the Touch Bar item tables.
--
-- Parameters:
--  * icon - Icon data as string
--  * action - Action as string
--  * label - Label as string
--  * id - Unique ID of the button
--
-- Returns:
--  * None
local function addWidget(_, action, _, id)
    if action and action.id then
        local widget = widgets:get(action.id)
        if widget then
            local params = widget:params()
            if params and params.item then
                table.insert(mod._tbItemIDs, widget:id())
                local item = params.item
                if type(item) == "function" then
                    item = item()
                end
                if item == nil then
                    log.wf("A widget item resolved to `nil`: %s, %s", action.id, id)
                end
                table.insert(mod._tbItems, item)
                mod._tbWidgetID[widget:id()] = id
            end
        end
    end
end

--- plugins.core.touchbar.manager.activeGroup() -> string
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

--- plugins.core.touchbar.manager.activeSubGroup() -> string
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

--- plugins.core.touchbar.manager.gotoSubGroup() -> none
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

--- plugins.core.touchbar.manager.forceGroupChange(combinedGroupAndSubGroupID) -> none
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
                dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("touchBar") .. " " .. i18n("bank") .. ": " .. bankLabel)
            else
                dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("touchBar") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. group) .. " " .. subGroup)
            end
        end
    end
end

--- plugins.core.touchbar.manager.nextSubGroup() -> none
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

--- plugins.core.touchbar.manager.previousSubGroup() -> none
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

--- plugins.core.touchbar.manager.incrementActiveSubGroup() -> none
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

    dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("touchBar") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. activeGroup) .. " " .. result)
end

--- plugins.core.touchbar.manager.update() -> none
--- Function
--- Updates the Touch Bar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if not mod._bar then
        return
    end

    --------------------------------------------------------------------------------
    -- Reset the Touch Bar items:
    --------------------------------------------------------------------------------
    mod._tbItems = {}
    mod._tbItemIDs = {}
    mod._tbWidgetID = {}

    --------------------------------------------------------------------------------
    -- Create new buttons and widgets:
    --------------------------------------------------------------------------------
    local activeGroup = mod.activeGroup()
    local activeSubGroup = mod.activeSubGroup()
    local activeGroupAndSubGroup = activeGroup .. activeSubGroup
    local items = mod._items()
    for groupID, group in pairs(items) do
        if groupID == activeGroupAndSubGroup then
            for buttonID, button in pairs(group) do
                if button["action"] then
                    local action        = button["action"] or nil
                    local label         = button["label"] or nil
                    local icon          = button["icon"] or nil
                    local id            = groupID .. "_" .. buttonID

                    if string.sub(button["handlerID"], -8) == "_widgets" then
                        addWidget(icon, action, label, id)
                    else
                        addButton(icon, action, label, id)
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Put the buttons in the correct order:
    --------------------------------------------------------------------------------
    table.sort(mod._tbItemIDs, function(a,b)
        if mod._tbWidgetID[a] then
            a = mod._tbWidgetID[a]
        end
        if mod._tbWidgetID[b] then
            b = mod._tbWidgetID[b]
        end
        a = tonumber(tools.split(a, "_")[2])
        b = tonumber(tools.split(b, "_")[2])
        return a<b
    end)

    --------------------------------------------------------------------------------
    -- Add Bank Label if exists:
    --------------------------------------------------------------------------------
    if items and items[activeGroupAndSubGroup] and items[activeGroupAndSubGroup]["bankLabel"] then
        local bankLabel = items[activeGroupAndSubGroup]["bankLabel"]
        local id = "bankLabel" .. activeGroupAndSubGroup .. host.uuid() -- I'm not sure why these need to be unique, but it seems to fix crashes.
        local bankLabelCanvas = canvas.new{x = 0, y = 0, h = 30, w = 50}
        bankLabelCanvas[1] = {
            type    = "text",
            text    = styledtext.getStyledTextFromData([[<span style="font-family: -apple-system; font-size: 10px; color: #FFFFFF; vertical-align: middle;">]] .. bankLabel .. [[</span>]]),
            frame   = { x = 0, y = 8, h = "100%", w = "100%" }
        }
        local bankLabelCanvasItem = mod.touchbar().item.newCanvas(bankLabelCanvas, id)
        table.insert(mod._tbItemIDs, 1, id)
        table.insert(mod._tbItems, 1, bankLabelCanvasItem)
    end

    --------------------------------------------------------------------------------
    -- Add buttons to the bar:
    --------------------------------------------------------------------------------
    mod._bar
        :templateItems(mod._tbItems)
        :customizableIdentifiers(mod._tbItemIDs)
        :requiredIdentifiers(mod._tbItemIDs)
        :defaultIdentifiers(mod._tbItemIDs)
        :presentModalBar()
end

--- plugins.core.touchbar.manager.groupStatus(groupID, status) -> none
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

--- plugins.core.touchbar.manager.init(deps) -> self
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The module.
function mod.init(deps)
    mod._actionmanager = deps.actionmanager
    return mod
end

local plugin = {
    id          = "core.touchbar.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.commands.global"]            = "global",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local icon = imageFromPath(env:pathToAbsolute("/../prefs/images/touchbar.icns"))
    local global = deps.global
    global:add("cpTouchBar")
        :whenActivated(mod.toggle)
        :groupedBy("commandPost")
        :image(icon)

    return mod.init(deps, env)
end

function plugin.postInit(deps, env)
    --------------------------------------------------------------------------------
    -- Setup Actions:
    --------------------------------------------------------------------------------
    local icon = imageFromPath(env:pathToAbsolute("/../prefs/images/touchbar.icns"))
    mod._handlers = {}
    local widgetGroups = widgets.allGroups()
    for _, groupID in pairs(widgetGroups) do
        mod._handlers[groupID] = deps.actionmanager.addHandler(groupID .. "_" .. "widgets", groupID)
            :onChoices(function(choices)
                --------------------------------------------------------------------------------
                -- Choices:
                --------------------------------------------------------------------------------
                local allWidgets = widgets:getAll()
                for _, widget in pairs(allWidgets) do

                    local id = widget:id()
                    local params = widget:params()

                    local action = {
                        id      = id,
                    }

                    if params.group == groupID then
                        choices:add(params.text)
                            :subText(i18n("touchBarWidget") .. ": " .. params.subText)
                            :params(action)
                            :id(id)
                            :image(icon)
                    end

                end
                return choices
            end)
            :onExecute(function() end)
            :onActionId(function() return "touchBarWidget" end)
    end

    --------------------------------------------------------------------------------
    -- Setup Physical Touch Bar Buttons:
    --------------------------------------------------------------------------------
    if mod.enabled() then
        mod.start()
        mod.update()
    end
end

return plugin
