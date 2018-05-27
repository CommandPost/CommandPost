--- === plugins.core.streamdeck.manager ===
---
--- Elgato Stream Deck Manager Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("streamDeck")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local application                               = require("hs.application")
local canvas                                    = require("hs.canvas")
local image                                     = require("hs.image")
local streamdeck                                = require("hs.streamdeck")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local json                                      = require("cp.json")
local prop                                      = require("cp.prop")
local tools                                     = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.streamdeck.manager.DEFAULT_GROUP -> string
--- Constant
--- The default group.
mod.DEFAULT_GROUP = "global"

--- plugins.core.streamdeck.manager.FILE_NAME -> string
--- Constant
--- File name of settings file.
mod.FILE_NAME = "Stream Deck.json"

--- plugins.core.streamdeck.manager.FOLDER_NAME -> string
--- Constant
--- Folder Name where settings file is contained.
mod.FOLDER_NAME = "Stream Deck"

-- plugins.core.streamdeck.manager._groupStatus -> table
-- Variable
-- Group Statuses.
mod._groupStatus = {}

-- plugins.core.streamdeck.manager._streamDeck -> table
-- Variable
-- Stream Deck Instances.
mod._streamDeck = {}

--- plugins.core.streamdeck.manager.maxItems -> number
--- Variable
--- The maximum number of Touch Bar items per group.
mod.maxItems = 15

--- plugins.core.streamdeck.manager.buttons <cp.prop: table>
--- Field
--- Contains all the saved Touch Bar Buttons
mod._items = json.prop(config.userConfigRootPath, mod.FOLDER_NAME, mod.FILE_NAME, {})

--- plugins.core.streamdeck.manager.clear() -> none
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

--- plugins.core.streamdeck.manager.updateIcon(button, group, icon) -> none
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

--- plugins.core.streamdeck.manager.updateAction(button, group, action) -> none
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

    --------------------------------------------------------------------------------
    -- Process Stylised Text:
    --------------------------------------------------------------------------------
    if actionTitle and type(actionTitle) == "userdata" then
        actionTitle = actionTitle:convert("text")
    end

    buttons[group][button]["actionTitle"] = actionTitle
    buttons[group][button]["handlerID"] = handlerID
    buttons[group][button]["action"] = action

    mod._items(buttons)
    mod.update()

end

--- plugins.core.streamdeck.manager.updateLabel(button, group, label) -> none
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

--- plugins.core.streamdeck.manager.getIcon(button, group) -> string
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

--- plugins.core.streamdeck.manager.getActionTitle(button, group) -> string
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

--- plugins.core.streamdeck.manager.getActionHandlerID(button, group) -> string
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

--- plugins.core.streamdeck.manager.getAction(button, group) -> string
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

--- plugins.core.streamdeck.manager.getLabel(button, group) -> string
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

--- plugins.core.streamdeck.manager.activeGroup() -> none
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
    if pressed then
        local handlerID = mod.getActionHandlerID(tostring(convertButtonID(buttonID)), mod.activeGroup())
        local action = mod.getAction(tostring(convertButtonID(buttonID)), mod.activeGroup())
        if handlerID and action then
            local handler = mod._actionmanager.getHandler(handlerID)
            handler:execute(action)
        end
    end
end

--- plugins.core.streamdeck.manager.update() -> none
--- Function
--- Updates the Touch Bar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()

    if not mod._streamDeck then
        --log.df("Update called, but no Stream Deck available.")
        return
    end

    --log.df("Updating Stream Deck...")

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

    for groupID, group in pairs(items) do
        if groupID == mod.activeGroup() then
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
            local streamDeck = object
            streamDeck:buttonCallback(mod.buttonCallback)
            mod._streamDeck[serialNumber] = streamDeck
            mod.update()
        else
            if mod._streamDeck[serialNumber] then
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
        log.df("Starting Stream Deck Support...")
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
    log.df("Stopping Stream Deck Support...")
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
--- Enable or disable Touch Bar Support.
mod.enabled = config.prop("enableStreamDesk", false):watch(function(enabled)
    if enabled then
        mod.start()
    else
        mod.stop()
    end
end)

--- plugins.core.streamdeck.manager.init(deps, env) -> none
--- Function
--- Initialises the Stream Deck Plugin
---
--- Parameters:
---  * deps - Dependencies Table
---  * env - Environment Table
---
--- Returns:
---  * None
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
    id          = "core.streamdeck.manager",
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
    global:add("cpStreamDeck")
        :whenActivated(mod.toggle)
        :groupedBy("commandPost")

    --------------------------------------------------------------------------------
    -- Initialise Module:
    --------------------------------------------------------------------------------
    return mod.init(deps, env)
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    if mod.enabled() then
        mod.start()
    end
end

return plugin
