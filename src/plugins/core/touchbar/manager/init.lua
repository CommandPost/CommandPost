--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               T O U C H B A R    M A N A G E R    P L U G I N              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.touchbar.manager ===
---
--- Touch Bar Manager Plugin.
--- This handles both the Virtual Touch Bar and adding items to the physical Touch Bar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("managerTouchBar")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas                                    = require("hs.canvas")
local eventtap                                  = require("hs.eventtap")
local image                                     = require("hs.image")
local inspect                                   = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local commands                                  = require("cp.commands")
local config                                    = require("cp.config")
local prop                                      = require("cp.prop")
local tools                                     = require("cp.tools")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local touchbar                                  = require("hs._asm.undocumented.touchbar")

--------------------------------------------------------------------------------
--
-- THE MODULE - WIDGETS:
--
--------------------------------------------------------------------------------

--- === plugins.core.touchbar.manager.widgets ===
---
--- Touch Bar Widgets Manager

local mod = {}

local widgets = {}
widgets._items = {}

mod.widgets = widgets

--- plugins.core.touchbar.manager.widgets:new(id, params) -> table
--- Method
--- Creates a new Touch Bar Widget.
---
--- Parameters:
--- * `id`      - The unique ID for this widget.
---
--- Returns:
---  * table that has been created
function widgets:new(id, params)

    if widgets._items[id] ~= nil then
        error("Duplicate Widget ID: " .. id)
    end
    local o = {
        _id = id,
        _params = params,
    }
    setmetatable(o, self)
    self.__index = self

    widgets._items[id] = o
    return o

end

--- plugins.core.touchbar.manager.widgets:get(id) -> table
--- Method
--- Gets a Touch Bar widget
---
--- Parameters:
--- * `id`      - The unique ID for the widget you want to return.
---
--- Returns:
---  * table containing the widget
function widgets:get(id)
    return self._items[id]
end

--- plugins.core.touchbar.manager.widgets:getAll() -> table
--- Method
--- Returns all of the created widgets
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function widgets:getAll()
    return self._items
end

--- plugins.core.touchbar.manager.widgets:id() -> string
--- Method
--- Returns the ID of the widget
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the widget as a `string`
function widgets:id()
    return self._id
end

--- plugins.core.touchbar.manager.widgets:params() -> function
--- Method
--- Returns the paramaters of the widget
---
--- Parameters:
--- * None
---
--- Returns:
---  * The paramaters of the widget
function widgets:params()
    return self._params
end

--- plugins.core.touchbar.manager.widgets.allGroups() -> table
--- Function
--- Returns a table containing all of the widget groups.
---
--- Parameters:
--- * None
---
--- Returns:
---  * Table
function widgets.allGroups()
    local result = {}
    local widgets = widgets:getAll()
    for id, widget in pairs(widgets) do
        local params = widget:params()
        if params and params.group then
            if not tools.tableContains(result, params.group) then
                table.insert(result, params.group)
            end
        end
    end
    return result
end

--------------------------------------------------------------------------------
--
-- THE MODULE - PHYSICAL TOUCH BAR:
--
--------------------------------------------------------------------------------

-- Touch Bar Items:
mod._tbItems = {}

-- Touch Bar Item IDs:
mod._tbItemIDs = {}

-- Group Statuses:
mod._groupStatus = {}

-- Current Sub Group Statuses:
mod._currentSubGroup = config.prop("touchBarCurrentSubGroup", {})

--- plugins.core.touchbar.manager.defaultGroup -> string
--- Variable
--- The default group.
mod.defaultGroup = "global"

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
mod._items = config.prop("touchBarButtons", {})

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
    local buttons = mod._items()

    button = tostring(button)

    if not buttons[group] then
        buttons[group] = {}
    end
    if not buttons[group][button] then
        buttons[group][button] = {}
    end
    buttons[group][button]["icon"] = icon

    mod._items(buttons)
    mod.update()
end

--- plugins.core.touchbar.manager.updateAction(button, group, action) -> none
--- Function
--- Updates a Touch Bar action.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---  * action - Action as string
---
--- Returns:
---  * None
function mod.updateAction(button, group, actionTitle, handlerID, action)

    local buttons = mod._items()

    button = tostring(button)
    if not buttons[group] then
        buttons[group] = {}
    end
    if not buttons[group][button] then
        buttons[group][button] = {}
    end
    buttons[group][button]["actionTitle"] = actionTitle
    buttons[group][button]["handlerID"] = handlerID
    buttons[group][button]["action"] = action

    mod._items(buttons)
    mod.update()

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
    local buttons = mod._items()

    button = tostring(button)

    if not buttons[group] then
        buttons[group] = {}
    end
    if not buttons[group][button] then
        buttons[group][button] = {}
    end
    buttons[group][button]["label"] = label

    mod._items(buttons)
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
                             :callback(function(self)

                                --[[
                                log.df("visible: %s", mod._bar:isVisible())
                                if mod._bar:isVisible() then
                                    mod._bar:minimizeModalBar()
                                else
                                    mod._bar:presentModalBar()
                                    --self:presentModalBar(mod._bar, mod.dismissButton)
                                end
                                --]]

                                mod.incrementActiveSubGroup()
                                mod.update()

                                --self:addToSystemTray(false)
                                --self:addToSystemTray(true)
                             end)
                             :addToSystemTray(true)

                             --[[
                             :visibilityCallback(function(object, visible)
                                log.df("object: %s", object)
                                log.df("visible: %s", visible)
                             end)
                             --]]

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
local function addButton(icon, action, label, id)
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
local function addWidget(icon, action, label, id)
    if action and action.id then
        local widget = widgets:get(action.id)
        if widget then
            local params = widget:params()
            if params and params.item then
                table.insert(mod._tbItemIDs, widget:id())
                table.insert(mod._tbItems, params.item)
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
    return mod.defaultGroup

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

--------------------------------------------------------------------------------
--
-- THE MODULE - VIRTUAL TOUCH BAR:
--
--------------------------------------------------------------------------------

--- === plugins.core.touchbar.manager.virtual ===
---
--- Virtual Touch Bar Manager

mod.virtual = {}

--- plugins.core.touchbar.manager.virtual.LOCATION_DRAGGABLE -> string
--- Constant
--- Location is Draggable.
mod.virtual.LOCATION_DRAGGABLE  = "Draggable"

--- plugins.core.touchbar.manager.virtual.LOCATION_MOUSE -> string
--- Constant
--- Location is Mouse.
mod.virtual.LOCATION_MOUSE      = "Mouse"

--- plugins.core.touchbar.manager.virtual.LOCATION_DEFAULT_VALUE -> string
--- Constant
--- Default location value.
mod.virtual.LOCATION_DEFAULT_VALUE      = mod.virtual.LOCATION_DRAGGABLE

--- plugins.core.touchbar.manager.virtual.lastLocation <cp.prop: point table>
--- Field
--- The last known Virtual Touch Bar Location
mod.virtual.lastLocation = config.prop("lastVirtualTouchBarLocation")

--- plugins.finalcutpro.touchbar.virtual.location <cp.prop: string>
--- Field
--- The Virtual Touch Bar Location Setting
mod.virtual.location = config.prop("displayVirtualTouchBarLocation", mod.virtual.LOCATION_DEFAULT_VALUE):watch(function() mod.virtual.update() end)

--- plugins.core.touchbar.manager.virtual.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.virtual.enabled = config.prop("displayVirtualTouchBar", false):watch(function(enabled)
    --------------------------------------------------------------------------------
    -- Check for compatibility:
    --------------------------------------------------------------------------------
    if enabled and not mod.supported() then
        dialog.displayMessage(i18n("touchBarError"))
        mod.enabled(false)
    end
    if not enabled then
        mod.virtual.stop()
    end
end)

--- plugins.core.touchbar.manager.virtual.isActive <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the plugin is enabled and the TouchBar is supported on this OS.
mod.virtual.isActive = mod.virtual.enabled:AND(mod.supported):watch(function(active)
    if active then
        mod.virtual.show()
    else
        mod.virtual.hide()
    end
end)

--- plugins.core.touchbar.manager.virtual.start() -> none
--- Function
--- Initialises the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.start()
    if mod.supported() and not mod._touchBar then

        --------------------------------------------------------------------------------
        -- Set up Touch Bar:
        --------------------------------------------------------------------------------
        mod._touchBar = touchbar.new()

        if mod._touchBar == nil then
            log.ef("There was an error initialising the Touch Bar.")
            return
        end

        --------------------------------------------------------------------------------
        -- Touch Bar Watcher:
        --------------------------------------------------------------------------------
        mod._touchBar:setCallback(mod.virtual.callback)

        --------------------------------------------------------------------------------
        -- Get last Touch Bar Location from Settings:
        --------------------------------------------------------------------------------
        local lastTouchBarLocation = mod.virtual.lastLocation()
        if lastTouchBarLocation ~= nil then mod._touchBar:topLeft(lastTouchBarLocation) end

        --------------------------------------------------------------------------------
        -- Draggable Touch Bar:
        --------------------------------------------------------------------------------
        local events = eventtap.event.types
        mod.keyboardWatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
            if mod.mouseInsideTouchbar and mod.virtual.location() == mod.virtual.LOCATION_DRAGGABLE then
                if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524576 then
                    mod._touchBar:backgroundColor{ red = 1 }
                                    :movable(true)
                                    :acceptsMouseEvents(false)
                elseif ev:getType() ~= events.leftMouseDown then
                    mod._touchBar:backgroundColor{ white = 0 }
                                  :movable(false)
                                  :acceptsMouseEvents(true)
                    mod.virtual.lastLocation(mod._touchBar:topLeft())
                end
            end
            return false
        end):start()

        mod.virtual.update()

    end
end

--- plugins.core.touchbar.manager.virtual.stop() -> none
--- Function
--- Stops the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.stop()
    if mod._touchBar then
        mod._touchBar:hide()
        mod._touchBar = nil
        collectgarbage() -- See: https://github.com/asmagill/hammerspoon_asm/issues/10#issuecomment-303290853
    end
    if mod.keyboardWatcher then
        mod.keyboardWatcher:stop()
        mod.keyboardWatcher = nil
    end
end

--- plugins.finalcutpro.touchbar.virtual.updateLocation() -> none
--- Function
--- Updates the Location of the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.updateLocation()

    --------------------------------------------------------------------------------
    -- Check that the Touch Bar exists:
    --------------------------------------------------------------------------------
    if not mod._touchBar then return end

    --------------------------------------------------------------------------------
    -- Get Settings:
    --------------------------------------------------------------------------------
    local displayTouchBarLocation = mod.virtual.location()

    --------------------------------------------------=-----------------------------
    -- Put it back to last known position:
    --------------------------------------------------------------------------------
    local lastLocation = mod.virtual.lastLocation()
    if lastLocation and mod._touchBar then
        mod._touchBar:topLeft(lastLocation)
    end

    --------------------------------------------------------------------------------
    -- Trigger Callbacks:
    --------------------------------------------------------------------------------
    local updateLocationCallbacks = mod.virtual.updateLocationCallback:getAll()
    if updateLocationCallbacks and type(updateLocationCallbacks) == "table" then
        for i, v in pairs(updateLocationCallbacks) do
            local fn = v:callbackFn()
            if fn and type(fn) == "function" then
                fn()
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Save last Touch Bar Location to Settings:
    --------------------------------------------------------------------------------
    mod.virtual.lastLocation(mod._touchBar:topLeft())
end

--- plugins.core.touchbar.manager.virtual.show() -> none
--- Function
--- Show the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.show()
    --------------------------------------------------------------------------------
    -- Check if we need to show the Touch Bar:
    --------------------------------------------------------------------------------
    if mod.supported() and mod.virtual.enabled() then
        mod.virtual.start()
        mod.virtual.updateLocation()
        mod._touchBar:show()
    end
end

--- plugins.core.touchbar.manager.virtual.hide() -> none
--- Function
--- Hide the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.hide()
    if mod.supported() and mod.virtual.enabled() and mod._touchBar then
        mod._touchBar:hide()
    end
end

--- plugins.core.touchbar.manager.virtual.callback() -> none
--- Function
--- Callback Function for the Virtual Touch Bar
---
--- Parameters:
---  * obj - the touchbarObject the callback is for
---  * message - the message to the callback, either "didEnter" or "didExit"
---
--- Returns:
---  * None
function mod.virtual.callback(obj, message)
    if message == "didEnter" then
        mod.mouseInsideTouchbar = true
    elseif message == "didExit" then
        mod.mouseInsideTouchbar = false

        --------------------------------------------------------------------------------
        -- Just in case we got here before the eventtap returned the Touch Bar to normal:
        --------------------------------------------------------------------------------
        mod._touchBar:movable(false)
        mod._touchBar:acceptsMouseEvents(true)
        mod.virtual.lastLocation(mod._touchBar:topLeft())
    end
end

--- plugins.core.touchbar.manager.virtual.update() -> none
--- Function
--- Updates the visibility and location of the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.update()
    -- Check if it's active.
    mod.virtual.isActive:update()
end

--------------------------------------------------------------------------------
--
-- UPDATE LOCATION CALLBACK:
--
--------------------------------------------------------------------------------

--- === plugins.core.touchbar.manager.virtual.updateLocationCallback ===
---
--- Virtual Touch Bar Update Location Callback

local updateLocationCallback = {}
updateLocationCallback._items = {}

mod.virtual.updateLocationCallback = updateLocationCallback

--- plugins.core.touchbar.manager.virtual.updateLocationCallback:new(id, callbackFn) -> table
--- Method
--- Creates a new Update Location Callback
---
--- Parameters:
--- * `id`      - The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function updateLocationCallback:new(id, callbackFn)

    if updateLocationCallback._items[id] ~= nil then
        error("Duplicate Update Location Callback: " .. id)
    end
    local o = {
        _id = id,
        _callbackFn = callbackFn,
    }
    setmetatable(o, self)
    self.__index = self

    updateLocationCallback._items[id] = o
    return o

end

--- plugins.core.touchbar.manager.virtual.updateLocationCallback:get(id) -> table
--- Method
--- Gets an Update Location Callback based on an ID.
---
--- Parameters:
--- * `id`      - The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function updateLocationCallback:get(id)
    return self._items[id]
end

--- plugins.core.touchbar.manager.virtual.updateLocationCallback:getAll() -> table
--- Method
--- Returns all of the created Update Location Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function updateLocationCallback:getAll()
    return self._items
end

--- plugins.core.touchbar.manager.virtual.updateLocationCallback:id() -> string
--- Method
--- Returns the ID of the current Update Location Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current File Dropped to Dock Icon Callback as a `string`
function updateLocationCallback:id()
    return self._id
end

--- plugins.core.touchbar.manager.virtual.updateLocationCallback:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current Update Location Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function updateLocationCallback:callbackFn()
    return self._callbackFn
end


--- plugins.core.touchbar.manager.virtual.updateLocationCallback:delete() -> none
--- Method
--- Deletes a Update Location Callback based on an ID.
---
--- Parameters:
--- * None
---
--- Returns:
---  * None
function updateLocationCallback:delete()
    updateLocationCallback._items[self._id] = nil
end

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
function mod.init(deps, env)
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
function plugin.postInit(deps, env)

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
            :onActionId(function() return id end)
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