--- === plugins.core.touchbar.manager ===
---
--- Touch Bar Manager Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("tbManager")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas                                    = require("hs.canvas")
local fnutils                                   = require("hs.fnutils")
local image                                     = require("hs.image")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local json                                      = require("cp.json")
local prop                                      = require("cp.prop")
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local touchbar                                  = require("hs._asm.undocumented.touchbar")

--------------------------------------------------------------------------------
-- Local Extensions:
--------------------------------------------------------------------------------
local widgets                                   = require("widgets")
local copy                                      = fnutils.copy

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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

--- plugins.core.touchbar.manager.closeBox -> boolean
--- Variable
--- An optional boolean, specifying whether or not the system
--- escape (or its current replacement) button should be replaced by a button
--- to remove the modal bar from the touch bar display when pressed.
mod.dismissButton = true

--- plugins.core.touchbar.manager.maxItems -> number
--- Variable
--- The maximum number of Touch Bar items per group.
mod.maxItems = 20

--- plugins.core.touchbar.manager.numberOfSubGroups -> number
--- Variable
--- The number of Sub Groups per Touch Bar Group.
mod.numberOfSubGroups = 5

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

--- plugins.core.touchbar.manager.supported <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the Touch Bar is supported on this version of macOS.
mod.supported = prop(function() return touchbar.supported() end)

--- plugins.core.touchbar.manager.touchBar() -> none
--- Function
--- Returns the `hs._asm.undocumented.touchbar` object if it exists.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `hs._asm.undocumented.touchbar`
function mod.touchBar()
    return mod._touchBar or nil
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
    local buttons = copy(mod._items())

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
    local items = copy(mod._items())

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
    local items = copy(mod._items())

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
--- Updates a Touch Bar action.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---  * label - Label as string
---
--- Returns:
---  * None
function mod.updateLabel(button, group, label)
    local items = copy(mod._items())

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

    if not mod._bar then
        mod._bar = touchbar.bar.new()

        --------------------------------------------------------------------------------
        -- Resize Icon:
        --------------------------------------------------------------------------------
        local icon = canvas.new{x = 0, y = 0, w = 512, h = 512 }
        icon[1] = {
          type="image",
          image = image.imageFromName(image.systemImageNames.ApplicationIcon),
          frame = { x = "10%", y = "10%", h = "80%", w = "80%" },
        }

        --------------------------------------------------------------------------------
        -- Setup System Icon:
        --------------------------------------------------------------------------------
        mod._sysTrayIcon = touchbar.item.newButton(icon:imageFromCanvas(), "CommandPost")
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
        table.insert(mod._tbItems, touchbar.item.newButton(label, icon, id):callback(buttonCallback))
    else
        table.insert(mod._tbItems, touchbar.item.newButton(label, id):callback(buttonCallback))
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
    local items = mod._items()
    for groupID, group in pairs(items) do
        if groupID == mod.activeGroup() .. mod.activeSubGroup() then
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

function mod.init(deps)
    mod._actionmanager = deps.actionmanager
    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id          = "core.touchbar.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.commands.global"]            = "global",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("cpTouchBar")
        :whenActivated(mod.toggle)
        :groupedBy("commandPost")

    return mod.init(deps, env)
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)

    --------------------------------------------------------------------------------
    -- Migrate Legacy Property List Touch Bar Buttons to JSON:
    --------------------------------------------------------------------------------
    local legacyControls = config.get("touchBarButtons", nil)
    if legacyControls then
        mod._items(fnutils.copy(legacyControls))
        config.set("touchBarButtons", nil)
        log.df("Migrated Touch Bar Buttons from Plist to JSON.")
    end

    --------------------------------------------------------------------------------
    -- Setup Actions:
    --------------------------------------------------------------------------------
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
