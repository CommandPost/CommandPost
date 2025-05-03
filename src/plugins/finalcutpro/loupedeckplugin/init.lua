--- === plugins.core.loupedeckplugin.manager ===
---
--- Loupedeck Plugin Actions for Final Cut Pro

local require           = require

local log               = require "hs.logger".new "ldPlugin"

local fnutils           = require "hs.fnutils"
local json              = require "hs.json"
local notify            = require "hs.notify"
local plist             = require "hs.plist"
local timer             = require "hs.timer"

local config            = require "cp.config"
local cpPlugins         = require "cp.plugins"
local deferred          = require "cp.deferred"
local destinations      = require "cp.apple.finalcutpro.export.destinations"
local dialog            = require "cp.dialog"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local just              = require "cp.just"
local notifier          = require "cp.ui.notifier"
local plugins           = require "cp.apple.finalcutpro.plugins"
local tools             = require "cp.tools"

local Do                = require "cp.rx.go.Do"

local copy              = fnutils.copy
local delayed           = timer.delayed
local displayMessage    = dialog.displayMessage
local doUntil           = timer.doUntil
local playErrorSound    = tools.playErrorSound
local tableCount        = tools.tableCount
local wait              = just.wait

local mod = {}

-- DELAY -> number
-- Constant
-- The amount of time to delay UI updates
local DELAY = 0.2

-- DEFER -> number
-- Constant
-- How long we should defer all the update functions.
local DEFER = 0.01

-- COLOR_WHEELS_NORMAL_RANGE -> number
-- Constant
-- What we divide the Loupedeck value by for a normal range.
local COLOR_WHEELS_NORMAL_RANGE = 5000

-- COLOR_WHEELS_FN_RANGE -> number
-- Constant
-- What we divide the Loupedeck value by for a normal range with the Fn key pressed.
local COLOR_WHEELS_FN_RANGE = 1000

-- COLOR_WHEELS_RGB_RANGE -> number
-- Constant
-- What we divide the Loupedeck value by for a normal range.
local COLOR_WHEELS_RGB_RANGE = 1000

-- BRIGHTNESS_RANGE -> number
-- Constant
-- What we divide the Loupedeck value by for a normal range.
local BRIGHTNESS_RANGE = 100

-- SATURATION_RANGE -> number
-- Constant
-- What we divide the Loupedeck value by for a normal range.
local SATURATION_RANGE = 100

-- makeContrastWheelHandler() -> function
-- Function
-- Creates a 'handler' for contrast wheel control.
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeContrastWheelHandler()
    local colorWheelContrastValue = 0
    local colorWheels = fcp.inspector.color.colorWheels

    local updateUI = deferred.new(DEFER):action(function()
        if colorWheels:isShowing() then
            colorWheels.shadows.brightness:shiftValue(colorWheelContrastValue*-1)
            colorWheels.highlights.brightness:shiftValue(colorWheelContrastValue)
            colorWheelContrastValue = 0
        else
            colorWheels:show()
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                colorWheelContrastValue = colorWheelContrastValue + (actionValue/COLOR_WHEELS_NORMAL_RANGE)
                updateUI()
            end
        elseif data.actionType == "press" then
            colorWheels.shadows.brightness:value(0)
            colorWheels.highlights.brightness:value(0)
        end
    end
end

-- makeWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeWheelHandler(wheelFinderFn, vertical)
    local wheelRight = 0
    local wheelUp = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(DEFER):action(function()
        if wheel:isShowing() then
            local current = wheel:colorOrientation()
            current.right = current.right + wheelRight
            current.up = current.up + wheelUp
            wheel:colorOrientation(current)
            wheelRight = 0
            wheelUp = 0
        else
            wheel:show()
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                if vertical then
                    wheelUp = wheelUp + (actionValue/COLOR_WHEELS_NORMAL_RANGE)
                else
                    wheelRight = wheelRight + (actionValue/COLOR_WHEELS_NORMAL_RANGE)
                end
                updateUI()
            end
        elseif data.actionType == "press" then
            wheel:colorOrientation({right=0, up=0})
        end
    end
end

-- makeRGBWheelHandler(wheelFinderFn, whichColor) -> function
-- Function
-- Creates a 'handler' for RGB Wheel Controls.
--
-- Parameters:
--  * wheelFinderFn - a function which returns the wheel object.
--  * whichColor - "red", "green" or "blue"
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeRGBWheelHandler(wheelFinderFn, whichColor)

    local wheel = wheelFinderFn()

    local colorWheelRedValue = 0
    local colorWheelGreenValue = 0
    local colorWheelBlueValue = 0

    local updateUI = deferred.new(DEFER):action(function()
        if not wheel:isShowing() then
            wheel:show()
        else
            local currentValue = wheel:colorValue()

            currentValue.red = currentValue.red + colorWheelRedValue
            currentValue.green = currentValue.green + colorWheelGreenValue
            currentValue.blue = currentValue.blue + colorWheelBlueValue

            wheel:colorValue(currentValue)

            colorWheelRedValue = 0
            colorWheelGreenValue = 0
            colorWheelBlueValue = 0
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                if whichColor == "red" then
                    colorWheelRedValue = colorWheelRedValue + (actionValue/COLOR_WHEELS_RGB_RANGE)
                elseif whichColor == "green" then
                    colorWheelGreenValue = colorWheelGreenValue + (actionValue/COLOR_WHEELS_RGB_RANGE)
                elseif whichColor == "blue" then
                    colorWheelBlueValue = colorWheelBlueValue + (actionValue/COLOR_WHEELS_RGB_RANGE)
                end

                updateUI()
            end
        elseif data.actionType == "press" then
            wheel:show()
            local currentValue = wheel:colorValue()

            if whichColor == "red" then
                currentValue.red = 0
            elseif whichColor == "green" then
                currentValue.green = 0
            elseif whichColor == "blue" then
                currentValue.blue = 0
            end

            wheel:colorValue(currentValue)
        end
    end

end

-- makeResetColorWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for resetting a Color Wheel.
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to reset.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeResetColorWheelHandler(wheelFinderFn)
    return function()
        local wheel = wheelFinderFn()
        wheel:show()
        wheel:colorOrientation({right=0, up=0})
    end
end

-- makeFunctionHandler(fn) -> function
-- Function
-- Creates a 'handler' for triggering a function.
--
-- Parameters:
--  * fn - the function you want to trigger.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeFunctionHandler(fn)
    return function()
        fn()
    end
end

-- makeResetColorWheelSatAndBrightnessHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for resetting a Color Wheel, Saturation & Brightness.
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to reset.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeResetColorWheelSatAndBrightnessHandler(wheelFinderFn)
    return function()
        local wheel = wheelFinderFn()
        wheel:show()
        wheel:colorOrientation({right=0, up=0})
        wheel:brightnessValue(0)
        wheel:saturationValue(1)
    end
end

-- makeShortcutHandler(finderFn) -> function
-- Function
-- Creates a 'handler' for triggering a Final Cut Pro Command Editor shortcut.
--
-- Parameters:
--  * finderFn - a function that will return the shortcut identifier.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeShortcutHandler(finderFn)
    return function()
        local shortcut = finderFn()
        fcp:doShortcut(shortcut):Now()
    end
end

-- makeMenuItemHandler(finderFn) -> function
-- Function
-- Creates a 'handler' for triggering a Final Cut Pro Menu Item.
--
-- Parameters:
--  * finderFn - a function that will return the Menu Item identifier.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeMenuItemHandler(finderFn)
    return function()
        local menuTable = finderFn()
        fcp:doSelectMenu(menuTable, {locale="en"}):Now()
    end
end

-- makeTimelineZoomHandler() -> function
-- Function
-- Creates a 'handler' for Timeline Zoom.
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeTimelineZoomHandler()
    local zoomShift = 0

    local appearance = fcp.timeline.toolbar.appearance

    local appearancePopUpCloser = delayed.new(1, function()
        appearance:hide()
    end)

    local updateUI = deferred.new(DEFER):action(function()
        if appearance:isShowing() then
            appearance.zoomAmount:shiftValue(zoomShift)
            zoomShift = 0
            appearancePopUpCloser:start()
        else
            appearance:show()
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                zoomShift = zoomShift - (actionValue/10)
            end
            updateUI()
        elseif data.actionType == "press" then
            zoomShift = 0
            fcp:application():selectMenuItem({"View", "Zoom to Fit"})
        end
    end
end

-- makeTimelineClipHeightHandler() -> function
-- Function
-- Creates a 'handler' Timeline Clip Height.
--
-- Parameters:
--  * None
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeTimelineClipHeightHandler()
    local clipHeightShift = 0

    local appearance = fcp.timeline.toolbar.appearance

    local appearancePopUpCloser = delayed.new(1, function()
        appearance:hide()
    end)

    local updateUI = deferred.new(DEFER):action(function()
        if appearance:isShowing() then
            appearance.clipHeight:shiftValue(clipHeightShift)
            clipHeightShift = 0
            appearancePopUpCloser:start()
        else
            appearance:show()
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                clipHeightShift = clipHeightShift - actionValue
                updateUI()
            end
        end
    end
end

-- makeSaturationHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeSaturationHandler(wheelFinderFn)
    local absolute
    local saturationShift = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(DEFER):action(function()
        if wheel:isShowing() then
            if absolute then
                wheel:saturationValue(absolute)
                absolute = nil
            else
                local current = wheel:saturationValue()
                wheel:saturationValue(current + saturationShift)
                saturationShift = 0
            end
        else
            wheel:show()
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                saturationShift = saturationShift + (actionValue/SATURATION_RANGE)
                updateUI()
            end
        elseif data.actionType == "press" then
            absolute = 1
            updateUI()
        end
    end
end

-- makeBrightnessHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeBrightnessHandler(wheelFinderFn)
    local absolute
    local brightnessShift = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(DEFER):action(function()
        if wheel:isShowing() then
            if absolute then
                wheel:brightnessValue(absolute)
                absolute = nil
            else
                local current = wheel:brightnessValue()
                wheel:brightnessValue(current + brightnessShift)
                brightnessShift = 0
            end
        else
            wheel:show()
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                brightnessShift = brightnessShift + (actionValue/BRIGHTNESS_RANGE)
                updateUI()
            end
        elseif data.actionType == "press" then
            absolute = 0
            updateUI()
        end
    end
end

-- makeColourBoardHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for color board controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * boardFinderFn - a function that will return the color board puck to apply the value to.
--  * angle - a boolean which specifies whether or not it's an angle value.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeColourBoardHandler(boardFinderFn, angle)
    local colorBoardShift = 0
    local board = boardFinderFn()

    local updateUI = deferred.new(DEFER):action(function()
        if board:isShowing() then
            if angle then
                local current = board:angle()
                board:angle(current + colorBoardShift)
                colorBoardShift = 0
            else
                local current = board:percent()
                board:percent(current + colorBoardShift)
                colorBoardShift = 0
            end
        else
            board:show()
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                colorBoardShift = colorBoardShift + actionValue
                updateUI()
            end
        elseif data.actionType == "press" then
            board:show():reset()
        end
    end
end

-- makeSliderHandler(finderFn) -> function
-- Function
-- Creates a 'handler' for slider controls, applying them to the slider returned by the `finderFn`
--
-- Parameters:
--  * finderFn - a function that will return the slider to apply the value to.
--  * actionName - The action name used by Loupedeck Plugin
--  * resetValue - The reset value (i.e. when a knob is pressed)
--  * range - An optional range to divide the Loupedeck value by
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeSliderHandler(finderFn, actionName, resetValue, range)
    local absolute
    local shift = 0
    local slider = finderFn()

    range = range or 1

    local updateUI = deferred.new(DEFER):action(function()
        if slider:isShowing() then
            if absolute then
                slider:value(absolute)
                absolute = nil
            else
                local current = slider:value()
                slider:value(current + shift)
                shift = 0
            end
        else
            slider:show()
        end

        --------------------------------------------------------------------------------
        -- Tell Loupedeck App to update the hardware display:
        --------------------------------------------------------------------------------
        local message = {
            ["MessageType"] = "UpdateDisplay",
            ["ActionName"] = actionName,
            ["ActionValue"] = tostring(slider:value()) or "",
        }
        local encodedMessage = json.encode(message, true)
        mod.manager.sendMessage(encodedMessage)
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                shift = shift + (actionValue/range)
                updateUI()
            end
        elseif data.actionType == "press" then
            absolute = resetValue
            updateUI()
        else
            log.ef("Unexpected actionType in Loupedeck Plugin's makeSliderHandler: %s", data and inspect(data))
        end
    end
end

-- plugins.core.loupedeckplugin.manager._buildCommandSet(languageCode) -> none
-- Function
-- A private function which outputs the command set code into the Debug Console.
-- This should only really ever be used by CommandPost Developers.
--
-- Parameters:
--  * languageCode - A valid FCPX language code (de, en, es, fr, ja, ko, zh_CN)
--
-- Returns:
--  * None
--
-- Notes:
--  * Usage: `cp.plugins("finalcutpro.loupedeckplugin")._buildCommandSet("en")`
function mod._buildCommandSet(languageCode)

    if not languageCode then
        languageCode = "en"
    end

    local commandNamesPath = "/Applications/Final Cut Pro.app/Contents/Resources/" .. languageCode .. ".lproj/NSProCommandNames.strings"
    local commandNames = plist.read(commandNamesPath)

    local commandDescriptionsPath = "/Applications/Final Cut Pro.app/Contents/Resources/" .. languageCode .. ".lproj/NSProCommandDescriptions.strings"
    local commandDescriptions = plist.read(commandDescriptionsPath)

    local commandGroupsPath = "/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist"
    local commandGroups = plist.read(commandGroupsPath)

    local codeForCommandPost = ""

    local commandsJSON = ""
    local groupJSON = ""
    local displayNamesJSON = ""

    local groupNameLookup = {}

    local groupIDPrefix = "FCPCommandSet."

    local groups = {}

    for id, commandName in pairs(commandNames) do
        local description = commandDescriptions[id]
        if description then
            local group = "General"
            for currentGroup, v in pairs(commandGroups) do
                groups[currentGroup] = currentGroup
                for _, commandID in pairs(v.commands) do
                    if commandID == id then
                        group = currentGroup
                        break
                    end
                end
            end

            groupNameLookup["Command Set Shortcuts." .. group .. "." .. commandName] = group
            codeForCommandPost = codeForCommandPost .. [[registerAction("Command Set Shortcuts.]] .. group .. [[.]] .. commandName .. [[", makeShortcutHandler(function() return "]] .. id .. [[" end))]] .. "\n"
            commandsJSON = commandsJSON .. [["Command Set Shortcuts.]] .. group .. [[.]] .. commandName .. [[": "]] .. groupIDPrefix .. group .. [[",]] .. "\n"
            displayNamesJSON = displayNamesJSON .. [["Command Set Shortcuts.]] .. group .. [[.]] .. commandName .. [[": "]] .. commandName .. [[",]] .. "\n"
        end
    end

    for _, groupName in pairs(groups) do
        local translatedGroupName = commandNames[groupName]
        groupJSON = groupJSON .. [["]] .. groupIDPrefix .. groupName .. [[": "FCP: Commands - ]] .. translatedGroupName .. [[",]] .. "\n"
    end

    --------------------------------------------------------------------------------
    -- Write the output to the Debug Console:
    --------------------------------------------------------------------------------
    hs.console.clearConsole()
    log.df("codeForCommandPost:\n%s", codeForCommandPost)
    log.df("")
    log.df("JSON data for commands.json:\n%s", commandsJSON)
    log.df("")
    log.df("JSON data for displaynames-en.json:\n%s", displayNamesJSON)
    log.df("")
    log.df("JSON data for groupnames-en.json:\n%s", groupJSON)

end

-- menuItems -> table
-- Variable
-- A table of menu items.
local menuItems = {}

-- _processMenuItems(items, path)
-- Function
-- A private function which processes menu items.
-- This should only really ever be used by CommandPost Developers.
--
-- Parameters:
--  * items - A table of menu items
--  * path - A table containing the current menu item path.
--
-- Returns:
--  * None
local function _processMenuItems(items, path)
    path = path or {}
    for _,v in pairs(items) do
        if type(v) == "table" then
            local role = v.AXRole
            local children = v.AXChildren
            local title = v.AXTitle
            if children then
                local newPath = copy(path)
                table.insert(newPath, title)
                _processMenuItems(children[1], newPath)
            else
                if title and title ~= "" then
                    table.insert(menuItems, {
                        title = title,
                        path = copy(path),
                    })
                end
            end
        end
    end
end

-- plugins.core.loupedeckplugin.manager._buildMenuItems() -> none
-- Function
-- A private function which outputs the menu items code into the Debug Console.
-- This should only really ever be used by CommandPost Developers.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
--
-- Notes:
--  * Example Usage: `cp.plugins("finalcutpro.loupedeckplugin")._buildMenuItems()`
function mod._buildMenuItems()
    menuItems = {}

    local items = fcp:application():getMenuItems()

    for _, v in pairs(items) do
        local title = v.AXTitle
        local children = v.AXChildren
        if children then
            _processMenuItems(children[1], {title})
        end
    end

    local codeForCommandPost = ""
    local displayNamesJSON = ""
    local commandsJSON = ""

    local rootMenus = {}

    local menubarPrefix = "FCPMenu."

    for _, v in pairs(menuItems) do

        local group = table.concat(v.path, ".")
        local commandName = v.title
        local id = table.concat(v.path, "|||") .. "|||" .. commandName
        local info = table.concat(v.path, " > ") .. " > " .. commandName

        rootMenus[v.path[1]] = v.path[1]

        codeForCommandPost = codeForCommandPost .. [[registerAction("Menu Items.]] .. group .. [[.]] .. commandName .. [[", makeMenuItemHandler(function() return "]] .. id .. [[" end))]] .. "\n"

        local actionID = "Menu Items." .. group .. "." .. commandName
        local firstSeperator = info:find(" > ")
        local infoWithoutMainMenu = info:sub(firstSeperator + 3)

        commandsJSON = commandsJSON .. [[  "]] .. actionID .. [[": "]] .. menubarPrefix .. v.path[1] .. [[",]] .. "\n"
        displayNamesJSON = displayNamesJSON .. [[  "]] .. actionID .. [[": "]] .. infoWithoutMainMenu .. [[",]] .. "\n"
    end

    local groupJSON = ""
    for _, groupName in pairs(rootMenus) do
        groupJSON = groupJSON .. [[  "]] .. menubarPrefix .. groupName .. [[": "]] .. groupName .. [[",]] ..  "\n"
    end

    --------------------------------------------------------------------------------
    -- Write the output to the Debug Console:
    --------------------------------------------------------------------------------
    hs.console.clearConsole()
    log.df("codeForCommandPost:\n%s", codeForCommandPost)
    log.df("")
    log.df("JSON data for commands.json:\n%s", commandsJSON)
    log.df("")
    log.df("JSON data for displaynames-en.json:\n%s", displayNamesJSON)
    log.df("")
    log.df("JSON data for groupnames-en.json:\n%s", groupJSON)
end

-- makeLoupedeckColorWheelHandler(wheelFinderFn, vertical) -> function
-- Function
-- Creates a 'handler' for Color Wheels.slider controls, applying them to the slider returned by the `finderFn`
--
-- Parameters:
--  * wheelFinderFn - a function that will return the Color Wheel to apply the value to.
--
-- Returns:
--  * a function that will receive the Loupedeck WebSocket metadata table and process it.
local function makeLoupedeckColorWheelHandler(wheelFinderFn)

    local deltaX = 0
    local deltaY = 0

    local brightnessShift = 0
    local saturationShift = 0

    local wheel = wheelFinderFn()

    local updateUI = deferred.new(DEFER):action(function()
        if wheel:isShowing() then
            --------------------------------------------------------------------------------
            -- Color Wheel:
            --------------------------------------------------------------------------------
            local current = wheel:colorOrientation()
            current.right = current.right + deltaX
            current.up = current.up + deltaY
            wheel:colorOrientation(current)
            deltaX = 0
            deltaY = 0

            --------------------------------------------------------------------------------
            -- Saturation:
            --------------------------------------------------------------------------------
            local currentSaturation = wheel:saturationValue()
            wheel:saturationValue(currentSaturation + saturationShift)
            saturationShift = 0

            --------------------------------------------------------------------------------
            -- Brightness:
            --------------------------------------------------------------------------------
            local currentBrightness = wheel:brightnessValue()
            wheel:brightnessValue(currentBrightness + brightnessShift)
            brightnessShift = 0
        else
            wheel:show()
        end
    end)

    return function(data)
        if data.actionType == "move" then
            --------------------------------------------------------------------------------
            -- The Touch Wheel has "moved":
            --------------------------------------------------------------------------------
            local range = COLOR_WHEELS_NORMAL_RANGE
            if data.functionPressed then
                range = COLOR_WHEELS_FN_RANGE
            end
            deltaX = deltaX + ((data.deltaX)/range)
            deltaY = deltaY + ((data.deltaY*-1)/range)
            updateUI()
        elseif data.actionType == "doubleTap" then
            --------------------------------------------------------------------------------
            -- Double Tap to Reset:
            --------------------------------------------------------------------------------
            if data.functionPressed then
                wheel:saturationValue(1)
                wheel:brightnessValue(0)
            else
                wheel:colorOrientation({right=0, up=0})
            end
        elseif data.actionType == "wheel" then
            --------------------------------------------------------------------------------
            -- Turn the Wheel:
            --------------------------------------------------------------------------------
            if data.functionPressed then
                --------------------------------------------------------------------------------
                -- Saturation:
                --------------------------------------------------------------------------------
                saturationShift = saturationShift + (data.actionValue/SATURATION_RANGE)
            else
                --------------------------------------------------------------------------------
                -- Brightness:
                --------------------------------------------------------------------------------
                brightnessShift = brightnessShift + (data.actionValue/BRIGHTNESS_RANGE)
            end
            updateUI()
        else
            log.df("[Loupedeck Plugin] Unexpected data: %s", hs.inspect(data))
        end
    end

end

-- requestCommands(data) -> none
-- Function
-- Triggered when the Loupedeck Service requests a JSON of commands
--
-- Parameters:
--  * data - The data from the Loupedeck
--
-- Returns:
--  * None
local function requestCommands(data)
    for pluginType,_ in pairs(plugins.types) do
        --------------------------------------------------------------------------------
        -- Get a list of plugins:
        --------------------------------------------------------------------------------
        local pluginIDs = {}
        local list = fcp:plugins():ofType(pluginType)
        if list then
            for _,plugin in ipairs(list) do
                if plugin.name then
                    local category = plugin.category or "none"
                    local theme = plugin.theme or "none"
                    local name = plugin.name
                    local id = name .. "." .. category .. "." .. theme

                    --------------------------------------------------------------------------------
                    -- Save the ID and Plugin Name to send back to Loupedeck:
                    --------------------------------------------------------------------------------
                    pluginIDs[id] = name

                    --------------------------------------------------------------------------------
                    -- Save a lookup table for execution:
                    --------------------------------------------------------------------------------
                    mod.fcpPluginsLookup[id] = copy(plugin)
                    mod.fcpPluginsTypeLookup[id] = pluginType
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Send a WebSocket Message back to Loupedeck:
        --------------------------------------------------------------------------------
        local message = {
            ["MessageType"] = "UpdateCommands",
            ["ActionName"] = "FCPPlugin." .. pluginType,
            ["ActionValue"] = json.encode(pluginIDs),
        }
        local encodedMessage = json.encode(message, true)
        mod.manager.sendMessage(encodedMessage)
    end
end

-- requestShareDestinations(data) -> none
-- Function
-- Triggered when the Loupedeck Service requests a JSON of commands
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function requestShareDestinations()
    local destinationIDs = {}
    local shares = destinations.names()
    for _, title in pairs(shares) do
        destinationIDs[title] = title
    end

    --------------------------------------------------------------------------------
    -- Send a WebSocket Message back to Loupedeck:
    --------------------------------------------------------------------------------
    if tableCount(destinationIDs) > 0 then
        local message = {
            ["MessageType"]     = "UpdateCommands",
            ["ActionName"]      = "FCP.Share Destinations",
            ["ActionValue"]     = json.encode(destinationIDs),
        }
        local encodedMessage = json.encode(message, true)
        mod.manager.sendMessage(encodedMessage)
    end
end

--- plugins.core.loupedeckplugin.manager.requestKeywordShortcuts(data) -> none
--- Function
--- Triggered when the Loupedeck Service requests a JSON of commands
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.requestKeywordShortcuts()

    local keywordShortcuts = {}

    local keywords = fcp.preferences.FFKeywordGroups

    for i=1, 9 do
        local keyword = keywords and keywords[i] and keywords[i][1] or i18n("unassigned")
        keywordShortcuts[i .. ": Keyword Shortcut"] = keyword
    end

    --------------------------------------------------------------------------------
    -- Send a WebSocket Message back to Loupedeck:
    --------------------------------------------------------------------------------
    local message = {
        ["MessageType"]     = "UpdateCommands",
        ["ActionName"]      = "FCP.Keyword Shortcuts",
        ["ActionValue"]     = json.encode(keywordShortcuts),
    }
    local encodedMessage = json.encode(message, true)
    mod.manager.sendMessage(encodedMessage)

    --------------------------------------------------------------------------------
    -- Watch for future changes:
    --------------------------------------------------------------------------------
    if not mod.keywordsWatcher then
        mod.keywordsWatcher = fcp.preferences:prop("FFKeywordGroups", nil, false):watch(function()
            mod.requestKeywordShortcuts()
        end)
    end
end

-- applyKeywordShortcut(data) -> none
-- Function
-- Triggered when the Loupedeck Service wants to apply a Keyword Shortcut.
--
-- Parameters:
--  * data - The data from the Loupedeck
--
-- Returns:
--  * None
local function applyKeywordShortcut(data)
    local actionValue = data.actionValue
    if actionValue then
        local keywordID = actionValue:sub(1,1)
        fcp:doShortcut("AddKeywordGroup" .. keywordID):Now()
    end
end

-- applyShareDestination(data) -> none
-- Function
-- Triggered when the Loupedeck Service wants to apply a share destination.
--
-- Parameters:
--  * data - The data from the Loupedeck
--
-- Returns:
--  * None
local function applyShareDestination(data)
    local actionValue = data.actionValue
    if actionValue then

        local function isDefaultItem(element)
            return element and element:attributeValue("AXMenuItemCmdChar") ~= nil
        end

        local defaultFormat = fcp.strings:find("FFShareDefaultApplicationFormat")

        defaultFormat = defaultFormat:gsub("([()])", "%%%1"):gsub("%%@", "(.+)") .. "…"

        local dest = actionValue

        --------------------------------------------------------------------------------
        -- This function will match based on the destination title, minus
        -- "(default)" and "…" if present.
        --------------------------------------------------------------------------------
        local destinationSelect = function(menuItem)
            local title = menuItem:attributeValue("AXTitle")
            if title == nil then
                return false
            elseif isDefaultItem(menuItem) then
                title = title:match(defaultFormat)
            else
                local destinationFormat = "(.+)…"
                title = title:match(destinationFormat)
            end
            return type(dest) == "function" and dest(title) or title == tostring(dest)
        end
        local menuItem = fcp.menu:findMenuUI({"File", "Share", destinationSelect})
        if menuItem then
            fcp:selectMenu({"File", "Share", destinationSelect}, {locale="en", ["pressAll"] = true}):Now()
        else
            playErrorSound()
        end
    end
end

-- requestWorkflowExtensions(data) -> none
-- Function
-- Triggered when the Loupedeck Service requests a JSON of commands
--
-- Parameters:
--  * data - The data from the Loupedeck
--
-- Returns:
--  * None
local function requestWorkflowExtensions(data)
    local workflowExtensionIDs = {}
    local workflowExtensions = fcp.workflowExtensionNames()
    for _, title in pairs(workflowExtensions) do
        --------------------------------------------------------------------------------
        -- We don't want the CommandPost Workflow Extension visible:
        --------------------------------------------------------------------------------
        if title ~= "CommandPost" then
            workflowExtensionIDs[title] = title
        end
    end

    --------------------------------------------------------------------------------
    -- Send a WebSocket Message back to Loupedeck:
    --------------------------------------------------------------------------------
    if tableCount(workflowExtensionIDs) > 0 then
        local message = {
            ["MessageType"]     = "UpdateCommands",
            ["ActionName"]      = "FCP.Workflow Extensions",
            ["ActionValue"]     = json.encode(workflowExtensionIDs),
        }
        local encodedMessage = json.encode(message, true)
        mod.manager.sendMessage(encodedMessage)
    end
end

-- applyWorkflowExtension(data) -> none
-- Function
-- Triggered when the Loupedeck Service wants to apply a share destination.
--
-- Parameters:
--  * data - The data from the Loupedeck
--
-- Returns:
--  * None
local function applyWorkflowExtension(data)
    local actionValue = data.actionValue
    if actionValue then
        fcp:doSelectMenu({"Window", "Extensions", actionValue}, {locale="en"}):Now()
    end
end

-- applyCommand(data) -> none
-- Function
-- Triggered when the Loupedeck Service asks to apply a specific command.
--
-- Parameters:
--  * data - The data from the Loupedeck
--
-- Returns:
--  * None
local function applyCommand(data)
    --log.df("ApplyWebSocketCommand: %s", data)
    local id = data.actionValue
    local actionData = mod.fcpPluginsLookup[id]
    local pluginType = mod.fcpPluginsTypeLookup[id]
    if actionData and pluginType then
        mod.fcpPlugins[pluginType].apply(actionData)
    end
end

-- makePlayheadHandler(actionName, playRate) -> function
-- Function
-- Make a Playhead Handler
--
-- Parameters:
--  * actionName - The action name as a string.
--  * playRate - The play rate as a number.
--
-- Returns:
--  * A handler function
local function makePlayheadHandler(actionName, playRate)
    return function(data)
        --------------------------------------------------------------------------------
        -- Process the data:
        --------------------------------------------------------------------------------
        if data.actionType == "turn" then
            if data.actionValue > 0 then
                mod._workflowExtension.incrementPlayhead(data.actionValue * playRate)
            else
                mod._workflowExtension.decrementPlayhead(math.abs(data.actionValue * playRate))
            end
        elseif data.actionType == "press" then
            fcp:doShortcut("JumpToStart"):Now()
        end

        --------------------------------------------------------------------------------
        -- Tell Loupedeck App to update the hardware display:
        --------------------------------------------------------------------------------
        local timecode = fcp.viewer.timecode()
        if timecode then

            --------------------------------------------------------------------------------
            -- Trim the timecode value to make it easier to read:
            --------------------------------------------------------------------------------
            if timecode:sub(1,6) == "00:00:" then
                timecode = timecode:sub(7)
            elseif timecode:sub(1,3) == "00:" then
                timecode = timecode:sub(4)
            end
            if timecode:sub(1,1) == "0" then
                timecode = timecode:sub(2)
            end

            local message = {
                ["MessageType"] = "UpdateDisplay",
                ["ActionName"] = actionName,
                ["ActionValue"] = timecode,
            }
            local encodedMessage = json.encode(message, true)
            mod.manager.sendMessage(encodedMessage)
        end
    end
end

-- makePopupSliderParameterHandler(actionName, param, options, resetIndex) -> function
-- Function
-- Makes a handler for popups
--
-- Parameters:
--  * actionName - The action name
--  * param - The parameter
--  * options - A table of the available options
--  * resetIndex - Which item should be selected when resetting?
--
-- Returns:
--  * A handler function
local function makePopupSliderParameterHandler(actionName, param, options, resetIndex)

    param = param()

    local popupSliderCache = nil

    local maxValue = tableCount(options)

    local loopupID = function(name)
        for i, v in pairs(options) do
            if v.flexoID then
                if name == fcp:string(v.flexoID) then
                    return i
                end
            end
        end
    end

    local updateDisplay = function()
        local displayValue
        if popupSliderCache then
            if options[popupSliderCache].i18n ~= nil then
                local v = options[popupSliderCache].i18n
                displayValue = i18n(v, {default= i18n(v, {default=v})})
            end
        else
            local i = loopupID(param:value())
            local v = options[i] and options[i].i18n
            displayValue = i18n(v, {default=i18n(v, {default=v})})
        end

        --------------------------------------------------------------------------------
        -- Tell Loupedeck App to update the hardware display:
        --------------------------------------------------------------------------------
        local timecode = fcp.viewer.timecode()
        if timecode then
            local message = {
                ["MessageType"] = "UpdateDisplay",
                ["ActionName"] = actionName,
                ["ActionValue"] = displayValue,
            }
            local encodedMessage = json.encode(message, true)
            mod.manager.sendMessage(encodedMessage)
        end
    end

    local updateUI = delayed.new(DELAY, function()
        Do(param:doSelectItem(popupSliderCache))
            :Then(function()
                popupSliderCache = nil
                updateDisplay()
            end)
            :Label("plugins.finalcutpro.tangent.common.makePopupSliderParameterHandler.updateUI")
            :Now()
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                --------------------------------------------------------------------------------
                -- Show and ignore input if not already showing:
                --------------------------------------------------------------------------------
                local parent = param:parent()
                if parent and not parent:isShowing() then
                    parent:doShow():Now()
                    return
                end

                if actionValue > 0 then
                    --------------------------------------------------------------------------------
                    -- Next:
                    --------------------------------------------------------------------------------
                    local currentValue = param:value()
                    local currentValueID = popupSliderCache or (currentValue and loopupID(currentValue))
                    if type(currentValueID) ~= "number" then
                        return
                    end
                    local newID = currentValueID and currentValueID + 1
                    if newID > maxValue then newID = 1 end

                    --------------------------------------------------------------------------------
                    -- TODO: This is a horrible temporary workaround for menu non-enabled items.
                    -- It should probably be some kind of loop.
                    --------------------------------------------------------------------------------
                    if options[newID] and options[newID].flexoID == nil then
                        newID = newID + 1
                    end
                    if options[newID] and options[newID].flexoID == nil then
                        newID = newID + 1
                    end
                    if newID > maxValue then newID = 1 end
                    --------------------------------------------------------------------------------

                    popupSliderCache = newID
                    updateUI:start()

                    updateDisplay()
                else
                    --------------------------------------------------------------------------------
                    -- Previous:
                    --------------------------------------------------------------------------------
                    local currentValue = param:value()
                    local currentValueID = popupSliderCache or (currentValue and loopupID(currentValue))
                    if type(currentValueID) ~= "number" then
                        return
                    end
                    local newID = currentValueID and currentValueID - 1
                    if newID == 0 then newID = maxValue - 1 end

                    --------------------------------------------------------------------------------
                    -- TODO: This is a horrible temporary workaround for menu non-enabled items.
                    -- It should probably be some kind of loop.
                    --------------------------------------------------------------------------------
                    if options[newID] and options[newID].flexoID == nil then
                        newID = newID - 1
                    end
                    if options[newID] and options[newID].flexoID == nil then
                        newID = newID - 1
                    end
                    if newID <= 0 then newID = maxValue - 1 end
                    --------------------------------------------------------------------------------

                    popupSliderCache = newID
                    updateUI:start()

                    updateDisplay()
                end
            end
        elseif data.actionType == "press" then
            Do(function() popupSliderCache = resetIndex end)
                :Then(param:parent():doShow())
                :Then(param:doSelectValue(fcp:string(options[resetIndex].flexoID)))
                :Then(function()
                    popupSliderCache = nil
                    updateDisplay()
                end)
                :Label("plugins.finalcutpro.loupedeckplugin.makePopupSliderParameterHandler.reset")
                :Now()
        end
    end
end

-- makeViewerColorChannelsHandler(actionName) -> function
-- Function
-- Makes a handler the Viewer Color Channels.
--
-- Parameters:
--  * actionName - The action name
--
-- Returns:
--  * A handler function
local function makeViewerColorChannelsHandler(actionName)
    local selectedChannel = 1

    --------------------------------------------------------------------------------
    -- NOTE: These are definitely not the write i18n codes, however they'll do
    --       as placeholders for now. The actual string values are stored in:
    --
    --       /Applications/Final Cut Pro.app/Contents/Resources/en.lproj/PEPlayerContainerModule.nib
    --
    --------------------------------------------------------------------------------
    local viewerChannels = {
        [1] = "FFAllEffectTypeLabel",               -- All
        [2] = "FFShareAlpha",                       -- Alpha
        [3] = "VideoWaveformModeRedChannel",        -- Red
        [4] = "VideoWaveformModeGreenChannel",      -- Green
        [5] = "VideoWaveformModeBlueChannel"        -- Blue
    }

    local updateDisplay = function()
        local currentChannelID = viewerChannels[selectedChannel]
        local currentChannelName = fcp:string(currentChannelID)

        --------------------------------------------------------------------------------
        -- Tell Loupedeck App to update the hardware display:
        --------------------------------------------------------------------------------
        local timecode = fcp.viewer.timecode()
        if timecode then
            local message = {
                ["MessageType"] = "UpdateDisplay",
                ["ActionName"] = actionName,
                ["ActionValue"] = currentChannelName,
            }
            local encodedMessage = json.encode(message, true)
            mod.manager.sendMessage(encodedMessage)
        end
    end

    local updateUI = delayed.new(DELAY, function()
        local currentChannelID = viewerChannels[selectedChannel]
        local currentChannelName = fcp:string(currentChannelID)
        fcp:doSelectMenu({"View", "Show in Viewer", "Color Channels", currentChannelName}, {locale="en"}):Now()
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue

            if actionValue > 0 then
                selectedChannel = selectedChannel + 1
                if selectedChannel > 5 then selectedChannel = 1 end
            else
                selectedChannel = selectedChannel - 1
                if selectedChannel < 1 then selectedChannel = 5 end
            end

            updateDisplay()
            updateUI:start()
        elseif data.actionType == "press" then
            fcp:doSelectMenu({"View", "Show in Viewer", "Color Channels", "All"}, {locale="en"}):Now()
        end
    end
end

-- makeNextPreviousMenuItemHandler(itemName) -> function
-- Function
-- Makes a handler for Next/Previous Menu Items.
--
-- Parameters:
--  * itemName - The menu item name
--
-- Returns:
--  * A handler function
local function makeNextPreviousMenuItemHandler(itemName)
    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                if actionValue > 0 then
                    fcp:doSelectMenu({"Mark", "Next", itemName}, {locale="en"}):Now()
                else
                    fcp:doSelectMenu({"Mark", "Previous", itemName}, {locale="en"}):Now()
                end
            end
        end
    end
end

-- makeNudgeMarkerHandler() -> function
-- Function
-- Makes a handler for Nudge Marker Left/Right.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A handler function
local function makeNudgeMarkerHandler()
    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                if actionValue < 0 then
                    fcp:doSelectMenu({"Mark", "Markers", "Nudge Marker Left"}, {locale="en"}):Now()
                else
                    fcp:doSelectMenu({"Mark", "Markers", "Nudge Marker Right"}, {locale="en"}):Now()
                end
            end
        end
    end
end

-- makeNudgeHandler() -> function
-- Function
-- Makes a handler for Nudge Marker Left/Right.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A handler function
local function makeNudgeHandler()
    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                if actionValue < 0 then
                    fcp:doSelectMenu({"Trim", "Nudge Left"}, {locale="en"}):Now()
                else
                    fcp:doSelectMenu({"Trim", "Nudge Right"}, {locale="en"}):Now()
                end
            end
        end
    end
end

-- makeSlideHandler() -> function
-- Function
-- Makes a handler for Sliding Left/Right.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A handler function
local function makeSlideHandler()

    local currentTool

    local updateUI = delayed.new(DELAY, function()
        local CommandSetID = currentTool and currentTool.CommandSetID
        if CommandSetID then
            fcp:doShortcut(CommandSetID):Now()
            currentTool = nil
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                if not currentTool then
                    currentTool = fcp.timeline.toolbar.tool:value()
                end
                if actionValue < 0 then
                    if fcp.timeline.toolbar.tool:isTrim() then
                        fcp:doShortcut("SelectClipAtPlayhead")
                            :Then(fcp:doShortcut("NudgeLeft"))
                            :Now()
                    else
                        fcp:doShortcut("SelectClipAtPlayhead")
                            :Then(fcp:doShortcut("SelectToolTrim"))
                            :Then(fcp:doShortcut("NudgeLeft"))
                            :Now()
                    end
                else
                    if fcp.timeline.toolbar.tool:isTrim() then
                        fcp:doShortcut("SelectClipAtPlayhead")
                            :Then(fcp:doShortcut("NudgeRight"))
                            :Now()
                    else
                        fcp:doShortcut("SelectClipAtPlayhead")
                            :Then(fcp:doShortcut("SelectToolTrim"))
                            :Then(fcp:doShortcut("NudgeRight"))
                            :Now()
                    end
                end
                updateUI:start()
            end
        end
    end
end

-- makeRollHandler() -> function
-- Function
-- Makes a handler for Rolling a Clip.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A handler function
local function makeRollHandler()

    local currentTool

    local updateUI = delayed.new(DELAY, function()
        local CommandSetID = currentTool and currentTool.CommandSetID
        if CommandSetID then
            fcp:doShortcut(CommandSetID):Now()
            currentTool = nil
        end
    end)

    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                if not currentTool then
                    currentTool = fcp.timeline.toolbar.tool:value()
                end
                if actionValue < 0 then
                    if fcp.timeline.toolbar.tool:isTrim() then
                        fcp:doShortcut("SelectLeftRightEdge")
                            :Then(fcp:doShortcut("NudgeLeft"))
                            :Now()
                    else
                        fcp:doShortcut("SelectToolTrim")
                            :Then(fcp:doShortcut("SelectLeftRightEdge"))
                            :Then(fcp:doShortcut("NudgeLeft"))
                            :Now()
                    end
                else
                    if fcp.timeline.toolbar.tool:isTrim() then
                        fcp:doShortcut("SelectLeftRightEdge")
                            :Then(fcp:doShortcut("NudgeRight"))
                            :Now()
                    else
                        fcp:doShortcut("SelectToolTrim")
                            :Then(fcp:doShortcut("SelectLeftRightEdge"))
                            :Then(fcp:doShortcut("NudgeRight"))
                            :Now()
                    end
                end
                updateUI:start()
            end
        end
    end
end

-- makeShortcutAdjustment() -> function
-- Function
-- Makes a handler for Nudge Marker Left/Right.
--
-- Parameters:
--  * upShortcut - A shortcut identifier when turning up
--  * downShortcut - A shortcut identifier when turning down
--
-- Returns:
--  * A handler function
local function makeShortcutAdjustment(upShortcut, downShortcut, pressShortcut)
    return function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue then
                if actionValue > 0 then
                    fcp:doShortcut(upShortcut):Now()
                else
                    fcp:doShortcut(downShortcut):Now()
                end
            end
        elseif data.actionType == "press" then
            fcp:doShortcut(pressShortcut):Now()
        end
    end
end

-- makeShuttleHandler() -> function
-- Function
-- Makes a handler for the Shutter Touch Wheel control.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A handler function
local function makeShuttleHandler()

    local shuttleCount = 0

    local shuttleRange = 5
    local shuttleValue = 0
    local lastShortcut = ""

    local updateUI = delayed.new(DELAY, function()
        shuttleCount = 0
    end)

    return function(data)
        if data.actionType == "wheel" then
            if data.functionPressed then
                local range = 1
                if shuttleCount > 50 then
                    range = 5
                elseif shuttleCount > 100 then
                    range = 10
                elseif shuttleCount > 150 then
                    range = 20
                elseif shuttleCount > 200 then
                    range = 25
                end
                if data.actionValue > 0 then
                    mod._workflowExtension.incrementPlayhead(data.actionValue * range)
                else
                    mod._workflowExtension.decrementPlayhead(math.abs(data.actionValue * range))
                end
                shuttleCount = shuttleCount + 1
                updateUI:start()
            else
                if data.actionValue > 0 then
                    shuttleValue = shuttleValue + 1
                else
                    shuttleValue = shuttleValue - 1
                end

                local whichShortcut

                if shuttleValue > 0 then
                    if shuttleValue < (shuttleRange * 1) then
                        whichShortcut = "PlayRate1X"
                    elseif shuttleValue < (shuttleRange * 2) then
                        whichShortcut = "PlayRate2X"
                    elseif shuttleValue < (shuttleRange * 3) then
                        whichShortcut = "PlayRate4X"
                    elseif shuttleValue < (shuttleRange * 4) then
                        whichShortcut = "PlayRate8X"
                    elseif shuttleValue < (shuttleRange * 5) then
                        whichShortcut = "PlayRate16X"
                    elseif shuttleValue < (shuttleRange * 6) then
                        whichShortcut = "PlayRate32X"
                    end
                else
                    if shuttleValue > ((shuttleRange * 1)*-1) then
                        whichShortcut = "PlayRateMinus1X"
                    elseif shuttleValue > ((shuttleRange * 2)*-1) then
                        whichShortcut = "PlayRateMinus2X"
                    elseif shuttleValue > ((shuttleRange * 3)*-1) then
                        whichShortcut = "PlayRateMinus4X"
                    elseif shuttleValue > ((shuttleRange * 4)*-1) then
                        whichShortcut = "PlayRateMinus8X"
                    elseif shuttleValue > ((shuttleRange * 5)*-1) then
                        whichShortcut = "PlayRateMinus16X"
                    elseif shuttleValue > ((shuttleRange * 6)*-1) then
                        whichShortcut = "PlayRateMinus32X"
                    end
                end

                if whichShortcut then
                    if lastShortcut ~= whichShortcut then
                        fcp:doShortcut(whichShortcut):Now()
                    end
                    lastShortcut = whichShortcut
                end
            end
        elseif data.actionType == "doubleTap" then
            fcp:doShortcut("JumpToStart"):Now()
        elseif data.actionType == "tap" then
            fcp:doSelectMenu({"View", "Playback", "Play"}, {locale="en"}):Now()
            shuttleValue = 0
            lastShortcut = ""
        end
    end
end

-- plugins.core.loupedeckplugin.manager._registerActions(manager) -> none
-- Function
-- A private function to register actions.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._registerActions()
    --------------------------------------------------------------------------------
    -- Only run once:
    --------------------------------------------------------------------------------
    if mod._registerActionsRun then return end
    mod._registerActionsRun = true

    --------------------------------------------------------------------------------
    -- Setup Dependancies:
    --------------------------------------------------------------------------------
    local registerAction = mod.manager.registerAction

    --------------------------------------------------------------------------------
    -- Share Destinations:
    --------------------------------------------------------------------------------
    registerAction("RequestKeywordShortcuts", mod.requestKeywordShortcuts)
    registerAction("FCP.Keyword Shortcuts", applyKeywordShortcut)

    --------------------------------------------------------------------------------
    -- CommandPost Actions:
    --------------------------------------------------------------------------------
    registerAction("FCP.Automation.Timeline Batch Export", function()
        local plugin = cpPlugins("finalcutpro.export.batch")
        if plugin then
            plugin.batchExport()
        end
    end)
    registerAction("FCP.Automation.Export Timeline Index as CSV", function()
        local plugin = cpPlugins("finalcutpro.timeline.csv")
        if plugin then
            plugin.saveTimelineIndexToCSV()
        end
    end)
    registerAction("FCP.Automation.Export Browser as CSV", function()
        local plugin = cpPlugins("finalcutpro.browser.csv")
        if plugin then
            plugin.saveBrowserContentsToCSV()
        end
    end)
    registerAction("FCP.Automation.Scrolling Timeline", function()
        local plugin = cpPlugins("finalcutpro.timeline.playhead")
        if plugin then
            plugin.scrollingTimeline:toggle()
        end
    end)

    --------------------------------------------------------------------------------
    -- Shuttle Touch Wheel:
    --------------------------------------------------------------------------------
    registerAction("FCP Shuttle", makeShuttleHandler())

    --------------------------------------------------------------------------------
    -- Show Horizon:
    --------------------------------------------------------------------------------
    registerAction("FCP.Viewer.Show Horizon", function()
        fcp.viewer.infoBar.viewMenu:doSelectValue(fcp:string("CPShowHorizon")):Now()
    end)

    --------------------------------------------------------------------------------
    -- Share Destinations:
    --------------------------------------------------------------------------------
    registerAction("RequestShareDestinations", requestShareDestinations)
    registerAction("FCP.Share Destinations", applyShareDestination)

    --------------------------------------------------------------------------------
    -- Workflow Extensions:
    --------------------------------------------------------------------------------
    registerAction("RequestWorkflowExtensions", requestWorkflowExtensions)
    registerAction("FCP.Workflow Extensions", applyWorkflowExtension)

    --------------------------------------------------------------------------------
    -- Mark > Previous/Next > Frame/Edit/Marker/Keyframe
    --------------------------------------------------------------------------------
    registerAction("Timeline.Frame", makeNextPreviousMenuItemHandler("Frame"))
    registerAction("Timeline.Edit", makeNextPreviousMenuItemHandler("Edit"))
    registerAction("Timeline.Marker", makeNextPreviousMenuItemHandler("Marker"))
    registerAction("Timeline.Keyframe", makeNextPreviousMenuItemHandler("Keyframe"))

    --------------------------------------------------------------------------------
    -- Nudge Marker:
    --------------------------------------------------------------------------------
    registerAction("Timeline.Nudge Marker", makeNudgeMarkerHandler())

    --------------------------------------------------------------------------------
    -- Nudge (Trim):
    --------------------------------------------------------------------------------
    registerAction("Timeline.Trim - Nudge", makeNudgeHandler())

    --------------------------------------------------------------------------------
    -- Slide:
    --------------------------------------------------------------------------------
    registerAction("Timeline.Slide", makeSlideHandler())

    --------------------------------------------------------------------------------
    -- Roll:
    --------------------------------------------------------------------------------
    registerAction("Timeline.Roll", makeRollHandler())

    --------------------------------------------------------------------------------
    -- Shortcut-based Adjustments:
    --------------------------------------------------------------------------------
    registerAction("Multicam.Bank",                     makeShortcutAdjustment("SelectNextAngleBank", "SelectPreviousAngleBank"))
    registerAction("Multicam.Bank",                     makeShortcutAdjustment("SelectNextAngleBank", "SelectPreviousAngleBank"))

    registerAction("Cinematic.Focus Point",             makeShortcutAdjustment("NextDecisionCinematicEditor", "PreviousDecisionCinematicEditor"))

    registerAction("Timeline.Nudge Vertically",         makeShortcutAdjustment("NudgeUp", "NudgeDown"))
    registerAction("Timeline.Field",                    makeShortcutAdjustment("JumpToNextField", "JumpToPreviousField"))
    registerAction("Timeline.Subframe",                 makeShortcutAdjustment("JumpToNextSubframe", "JumpToPreviousSubframe"))
    registerAction("Timeline.Clip",                     makeShortcutAdjustment("NextClip", "PreviousClip"))
    registerAction("Timeline.Select Edge",              makeShortcutAdjustment("SelectRightEdge", "SelectLeftEdge"))
    registerAction("Timeline.Select Video Edge",        makeShortcutAdjustment("SelectRightEdgeVideo", "SelectLeftEdgeVideo"))
    registerAction("Timeline.Select Audio Edge",        makeShortcutAdjustment("SelectRightEdgeAudio", "SelectLeftEdgeAudio"))
    registerAction("Timeline.Waveform Size",            makeShortcutAdjustment("ClipAppearanceAudioBigger", "ClipAppearanceAudioSmaller", "ClipAppearance5050"))
    registerAction("Timeline.Move 10 Frames",           makeShortcutAdjustment("JumpForward10Frames", "JumpBackward10Frames"))
    registerAction("Timeline.History",                  makeShortcutAdjustment("SelectNextTimelineItem", "SelectPreviousTimelineItem"))

    registerAction("360 Viewer.Pan",                    makeShortcutAdjustment("PanLeft", "PanRight"))
    registerAction("360 Viewer.Tilt",                   makeShortcutAdjustment("TiltUp", "TiltDown"))

    --------------------------------------------------------------------------------
    -- Effects, Transitions, Generators & Titles:
    --------------------------------------------------------------------------------
    registerAction("RequestCommands", requestCommands)
    for pluginType,_ in pairs(plugins.types) do
        registerAction("FCPPlugin." .. pluginType, applyCommand)
    end

    --------------------------------------------------------------------------------
    -- Move Playhead using Workflow Extension:
    --------------------------------------------------------------------------------
    registerAction("Timeline.Playhead", makePlayheadHandler("Timeline.Playhead", 1))
    local playRates = {2, 4, 8, 12, 16, 20}
    for _, playRate in pairs(playRates) do
        registerAction("Timeline.PlayheadX" .. playRate, makePlayheadHandler("Timeline.PlayheadX" .. playRate, playRate))
    end

    --------------------------------------------------------------------------------
    -- Viewer Channels:
    --------------------------------------------------------------------------------
    registerAction("Viewer.Color Channels", makeViewerColorChannelsHandler("Viewer.Color Channels"))

    --------------------------------------------------------------------------------
    -- Full Screen Toggle:
    --------------------------------------------------------------------------------
    local lastPlayheadPosition
    registerAction("FCP.Automation.Toggle Fullscreen", function()
        if fcp.fullScreenPlayer:isShowing() then
            fcp:keyStroke({}, "escape")
        else
            --------------------------------------------------------------------------------
            -- Abort if the Workflow Extension is not running, or we don't know the
            -- last playhead position:
            --------------------------------------------------------------------------------
            mod._workflowExtension.ping()
            if not mod._workflowExtension.connected or not mod._workflowExtension.lastPlayheadPosition then
                notify.new(nil, {
                    title = i18n("workFlowExtensionNotRunning"),
                    subTitle = "",
                    informativeText = i18n("featureRequiresWorkflowExtension"),
                    withdrawAfter = 5,
                    alwaysPresent = true,
                }):send()
                return
            end

            --log.df("lastPlayheadPosition: %s", lastPlayheadPosition)
            fcp:doSelectMenu({"View", "Playback", "Play Full Screen"}, {locale="en"}):Then(function()
                if doUntil(function()
                    return fcp.fullScreenPlayer:isShowing()
                end, 5, 0.1) then
                    fcp:keyStroke({}, "space")
                    if lastPlayheadPosition then
                        --log.df("moving to: %s", lastPlayheadPosition)
                        mod._workflowExtension.movePlayheadToSeconds(lastPlayheadPosition)
                        mod._workflowExtension.movePlayheadToSeconds(lastPlayheadPosition)
                    end
                    return
                end
            end):Now()
        end
    end)

    --------------------------------------------------------------------------------
    -- Trim Clip:
    --------------------------------------------------------------------------------
    registerAction("FCP.Automation.Trim Left Edge", function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue < 0 then
                fcp:doSelectMenu({"Trim", "Nudge Left"}, {locale="en"}):Now()
            else
                fcp:doSelectMenu({"Trim", "Nudge Right"}, {locale="en"}):Now()
            end
        elseif data.actionType == "press" then
            fcp:doShortcut("SelectLeftEdge"):Now()
        end
    end)
    registerAction("FCP.Automation.Trim Right Edge", function(data)
        if data.actionType == "turn" then
            local actionValue = data.actionValue
            if actionValue < 0 then
                fcp:doSelectMenu({"Trim", "Nudge Left"}, {locale="en"}):Now()
            else
                fcp:doSelectMenu({"Trim", "Nudge Right"}, {locale="en"}):Now()
            end
        elseif data.actionType == "press" then
            fcp:doShortcut("SelectRightEdge"):Now()
        end
    end)

    --------------------------------------------------------------------------------
    -- Timeline:
    --------------------------------------------------------------------------------
    registerAction("Timeline.Zoom", makeTimelineZoomHandler("Timeline.Zoom"))
    registerAction("Timeline.Clip Height", makeTimelineClipHeightHandler())

    --------------------------------------------------------------------------------
    -- Colour Wheel Controls for Touch Wheel:
    --------------------------------------------------------------------------------
    do
        local colourWheels = {
            { control = fcp.inspector.color.colorWheels.master,       id = "Global" },
            { control = fcp.inspector.color.colorWheels.shadows,      id = "Shadows" },
            { control = fcp.inspector.color.colorWheels.midtones,     id = "Midtones" },
            { control = fcp.inspector.color.colorWheels.highlights,   id = "Highlights" },
        }
        for _, v in pairs(colourWheels) do
            registerAction("FCP " .. v.id, makeLoupedeckColorWheelHandler(function() return v.control end))
        end
    end

    --------------------------------------------------------------------------------
    -- Colour Wheel Controls for Knobs:
    --------------------------------------------------------------------------------
    do
        local colourWheels = {
            { control = fcp.inspector.color.colorWheels.master,       id = "Master" },
            { control = fcp.inspector.color.colorWheels.shadows,      id = "Shadows" },
            { control = fcp.inspector.color.colorWheels.midtones,     id = "Midtones" },
            { control = fcp.inspector.color.colorWheels.highlights,   id = "Highlights" },
        }
        for _, v in pairs(colourWheels) do
            registerAction("Color Wheels." .. v.id .. ".Vertical", makeWheelHandler(function() return v.control end, true))
            registerAction("Color Wheels." .. v.id .. ".Horizontal", makeWheelHandler(function() return v.control end, false))

            registerAction("Color Wheels." .. v.id .. ".Saturation", makeSaturationHandler(function() return v.control end))
            registerAction("Color Wheels." .. v.id .. ".Brightness", makeBrightnessHandler(function() return v.control end))

            registerAction("Color Wheels." .. v.id .. ".Reset", makeResetColorWheelHandler(function() return v.control end))
            registerAction("Color Wheels." .. v.id .. ".Reset All", makeResetColorWheelSatAndBrightnessHandler(function() return v.control end))

            registerAction("Color Wheels." .. v.id .. ".Red", makeRGBWheelHandler(function() return v.control end, "red"))
            registerAction("Color Wheels." .. v.id .. ".Green", makeRGBWheelHandler(function() return v.control end, "green"))
            registerAction("Color Wheels." .. v.id .. ".Blue", makeRGBWheelHandler(function() return v.control end, "blue"))
        end

        registerAction("Color Wheels.Temperature", makeSliderHandler(function() return fcp.inspector.color.colorWheels.temperatureSlider end, "Color Wheels.Temperature", 5000))
        registerAction("Color Wheels.Tint", makeSliderHandler(function() return fcp.inspector.color.colorWheels.tintSlider end, "Color Wheels.Tint", 0))
        registerAction("Color Wheels.Hue", makeSliderHandler(function() return fcp.inspector.color.colorWheels.hueTextField end, "Color Wheels.Hue", 0))
        registerAction("Color Wheels.Mix", makeSliderHandler(function() return fcp.inspector.color.colorWheels.mixSlider end, "Color Wheels.Mix", 1, 100))
        registerAction("Color Wheels.Contrast", makeContrastWheelHandler())
    end

    --------------------------------------------------------------------------------
    -- Color Board Controls:
    --------------------------------------------------------------------------------
    do
        local colourBoards = {
            { control = fcp.inspector.color.colorBoard.color.master,            id = "Color Master (Angle)",            angle = true },
            { control = fcp.inspector.color.colorBoard.color.shadows,           id = "Color Shadows (Angle)",           angle = true },
            { control = fcp.inspector.color.colorBoard.color.midtones,          id = "Color Midtones (Angle)",          angle = true },
            { control = fcp.inspector.color.colorBoard.color.highlights,        id = "Color Highlights (Angle)",        angle = true },

            { control = fcp.inspector.color.colorBoard.color.master,            id = "Color Master (Percentage)" },
            { control = fcp.inspector.color.colorBoard.color.shadows,           id = "Color Shadows (Percentage)" },
            { control = fcp.inspector.color.colorBoard.color.midtones,          id = "Color Midtones (Percentage)" },
            { control = fcp.inspector.color.colorBoard.color.highlights,        id = "Color Highlights (Percentage)" },

            { control = fcp.inspector.color.colorBoard.saturation.master,       id = "Saturation Master" },
            { control = fcp.inspector.color.colorBoard.saturation.shadows,      id = "Saturation Shadows" },
            { control = fcp.inspector.color.colorBoard.saturation.midtones,     id = "Saturation Midtones" },
            { control = fcp.inspector.color.colorBoard.saturation.highlights,   id = "Saturation Highlights" },

            { control = fcp.inspector.color.colorBoard.exposure.master,         id = "Exposure Master" },
            { control = fcp.inspector.color.colorBoard.exposure.shadows,        id = "Exposure Shadows" },
            { control = fcp.inspector.color.colorBoard.exposure.midtones,       id = "Exposure Midtones" },
            { control = fcp.inspector.color.colorBoard.exposure.highlights,     id = "Exposure Highlights" },
        }
        for _, v in pairs(colourBoards) do
            registerAction("Color Board." .. v.id, makeColourBoardHandler(function() return v.control end, v.angle))
        end
    end

    --------------------------------------------------------------------------------
    -- Video Inspector:
    --------------------------------------------------------------------------------
    do
        registerAction("Video Inspector.Compositing.Opacity",       makeSliderHandler(function() return fcp.inspector.video.compositing():opacity() end,    "Video Inspector.Compositing.Opacity",      100))

        registerAction("Video Inspector.Transform.Position X",      makeSliderHandler(function() return fcp.inspector.video.transform():position().x end,   "Video Inspector.Transform.Position X",     0))
        registerAction("Video Inspector.Transform.Position Y",      makeSliderHandler(function() return fcp.inspector.video.transform():position().y end,   "Video Inspector.Transform.Position Y",     0))

        registerAction("Video Inspector.Transform.Rotation",        makeSliderHandler(function() return fcp.inspector.video.transform():rotation() end,     "Video Inspector.Transform.Rotation",       0))

        registerAction("Video Inspector.Transform.Scale (All)",     makeSliderHandler(function() return fcp.inspector.video.transform():scaleAll() end,     "Video Inspector.Transform.Scale (All)",    100))

        registerAction("Video Inspector.Transform.Scale X",         makeSliderHandler(function() return fcp.inspector.video.transform():scaleX() end,       "Video Inspector.Transform.Scale X",        100))
        registerAction("Video Inspector.Transform.Scale Y",         makeSliderHandler(function() return fcp.inspector.video.transform():scaleY() end,       "Video Inspector.Transform.Scale Y",        100))

        registerAction("Video Inspector.Transform.Anchor X",        makeSliderHandler(function() return fcp.inspector.video.transform():anchor().x end,     "Video Inspector.Transform.Anchor X",       0))
        registerAction("Video Inspector.Transform.Anchor Y",        makeSliderHandler(function() return fcp.inspector.video.transform():anchor().y end,     "Video Inspector.Transform.Anchor Y",       0))

        registerAction("Video Inspector.Crop.Crop Left",            makeSliderHandler(function() return fcp.inspector.video.crop():left() end,              "Video Inspector.Crop.Crop Left",           0))
        registerAction("Video Inspector.Crop.Crop Right",           makeSliderHandler(function() return fcp.inspector.video.crop():right() end,             "Video Inspector.Crop.Crop Right",          0))
        registerAction("Video Inspector.Crop.Crop Top",             makeSliderHandler(function() return fcp.inspector.video.crop():top() end,               "Video Inspector.Crop.Crop Top",            0))
        registerAction("Video Inspector.Crop.Crop Bottom",          makeSliderHandler(function() return fcp.inspector.video.crop():bottom() end,            "Video Inspector.Crop.Crop Bottom",         0))
    end

    --------------------------------------------------------------------------------
    -- Video Inspector - Blend Modes - Buttons:
    --------------------------------------------------------------------------------
    do
        local blendModes = fcp.inspector.video.BLEND_MODES
        for _, v in pairs(blendModes) do
            if v.flexoID then
                registerAction("Video Inspector.Compositing.Blend Mode." .. fcp:string(v.flexoID, "en"), makeFunctionHandler(function() fcp.inspector.video:compositing():blendMode():doSelectValue(fcp:string(v.flexoID)):Now() end))
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Video Inspector - Blend Modes - Knobs:
    --------------------------------------------------------------------------------
    registerAction("Video Inspector.Compositing.Blend Modes", makePopupSliderParameterHandler("Video Inspector.Compositing.Blend Modes", function() return fcp.inspector.video:compositing():blendMode().value end, blendModes, 1))

    --------------------------------------------------------------------------------
    -- Distort:
    --------------------------------------------------------------------------------
    do
        registerAction("Video Inspector.Distort.Bottom Left X",         makeSliderHandler(function() return fcp.inspector.video.distort():bottomLeft().x end,     "Video Inspector.Distort.Bottom Left X",      0))
        registerAction("Video Inspector.Distort.Bottom Left Y",         makeSliderHandler(function() return fcp.inspector.video.distort():bottomLeft().y end,     "Video Inspector.Distort.Bottom Left Y",      0))

        registerAction("Video Inspector.Distort.Bottom Right X",        makeSliderHandler(function() return fcp.inspector.video.distort():bottomRight().x end,    "Video Inspector.Distort.Bottom Right X",     0))
        registerAction("Video Inspector.Distort.Bottom Right Y",        makeSliderHandler(function() return fcp.inspector.video.distort():bottomRight().y end,    "Video Inspector.Distort.Bottom Right Y",     0))

        registerAction("Video Inspector.Distort.Top Right X",           makeSliderHandler(function() return fcp.inspector.video.distort():topRight().x end,       "Video Inspector.Distort.Top Right X",        0))
        registerAction("Video Inspector.Distort.Top Right Y",           makeSliderHandler(function() return fcp.inspector.video.distort():topRight().y end,       "Video Inspector.Distort.Top Right Y",        0))

        registerAction("Video Inspector.Distort.Top Left X",            makeSliderHandler(function() return fcp.inspector.video.distort():topLeft().x end,        "Video Inspector.Distort.Top Left X",         0))
        registerAction("Video Inspector.Distort.Top Left Y",            makeSliderHandler(function() return fcp.inspector.video.distort():topLeft().y end,        "Video Inspector.Distort.Top Left Y",         0))
    end

    --------------------------------------------------------------------------------
    -- Audio Controls:
    --------------------------------------------------------------------------------
    do
        registerAction("Audio Inspector.Volume", makeSliderHandler(function() return fcp.inspector.audio:volume() end, "Audio Inspector.Volume", 0, 10))
    end

    --------------------------------------------------------------------------------
    -- Menu Items:
    --------------------------------------------------------------------------------
    do
        local mainMenuName = fcp:mainMenuName()
        registerAction("Menu Items.Final Cut Pro.About Final Cut Pro", makeMenuItemHandler(function() return {mainMenuName, "About Final Cut Pro"} end))
        registerAction("Menu Items.Final Cut Pro.Preferences…", makeMenuItemHandler(function() return {mainMenuName, "Preferences…"} end))
        registerAction("Menu Items.Final Cut Pro.Commands.Customize…", makeMenuItemHandler(function() return {mainMenuName, "Commands", "Customize…"} end))
        registerAction("Menu Items.Final Cut Pro.Commands.Import…", makeMenuItemHandler(function() return {mainMenuName, "Commands", "Import…"} end))
        registerAction("Menu Items.Final Cut Pro.Commands.Export…", makeMenuItemHandler(function() return {mainMenuName, "Commands", "Export…"} end))
        registerAction("Menu Items.Final Cut Pro.Commands.Default", makeMenuItemHandler(function() return {mainMenuName, "Commands", "Default"} end))
        registerAction("Menu Items.Final Cut Pro.Download Additional Content…", makeMenuItemHandler(function() return {mainMenuName, "Download Additional Content…"} end))
        registerAction("Menu Items.Final Cut Pro.Provide Final Cut Pro Feedback…", makeMenuItemHandler(function() return {mainMenuName, "Provide Final Cut Pro Feedback…"} end))
        registerAction("Menu Items.Final Cut Pro.Hide Final Cut Pro", makeMenuItemHandler(function() return {mainMenuName, "Hide Final Cut Pro"} end))
        registerAction("Menu Items.Final Cut Pro.Hide Others", makeMenuItemHandler(function() return {mainMenuName, "Hide Others"} end))
        registerAction("Menu Items.Final Cut Pro.Show All", makeMenuItemHandler(function() return {mainMenuName, "Show All"} end))
        registerAction("Menu Items.Final Cut Pro.Quit Final Cut Pro", makeMenuItemHandler(function() return {mainMenuName, "Quit Final Cut Pro"} end))
        registerAction("Menu Items.Final Cut Pro.Quit and Keep Windows", makeMenuItemHandler(function() return {mainMenuName, "Quit and Keep Windows"} end))
        registerAction("Menu Items.File.New.Project…", makeMenuItemHandler(function() return {"File", "New", "Project…"} end))
        registerAction("Menu Items.File.New.Event…", makeMenuItemHandler(function() return {"File", "New", "Event…"} end))
        registerAction("Menu Items.File.New.Library…", makeMenuItemHandler(function() return {"File", "New", "Library…"} end))
        registerAction("Menu Items.File.New.Folder", makeMenuItemHandler(function() return {"File", "New", "Folder"} end))
        registerAction("Menu Items.File.New.Keyword Collection", makeMenuItemHandler(function() return {"File", "New", "Keyword Collection"} end))
        registerAction("Menu Items.File.New.Library Smart Collection", makeMenuItemHandler(function() return {"File", "New", "Library Smart Collection"} end))
        registerAction("Menu Items.File.New.Compound Clip…", makeMenuItemHandler(function() return {"File", "New", "Compound Clip…"} end))
        registerAction("Menu Items.File.New.Multicam Clip…", makeMenuItemHandler(function() return {"File", "New", "Multicam Clip…"} end))
        registerAction("Menu Items.File.Open Library.Other…", makeMenuItemHandler(function() return {"File", "Open Library", "Other…"} end))
        registerAction("Menu Items.File.Open Library.From Backup…", makeMenuItemHandler(function() return {"File", "Open Library", "From Backup…"} end))
        registerAction("Menu Items.File.Open Library.Clear Recents", makeMenuItemHandler(function() return {"File", "Open Library", "Clear Recents"} end))
        registerAction("Menu Items.File.Close Library", makeMenuItemHandler(function() return {"File", "Close Library"} end))
        registerAction("Menu Items.File.Library Properties", makeMenuItemHandler(function() return {"File", "Library Properties"} end))
        registerAction("Menu Items.File.Import.Media…", makeMenuItemHandler(function() return {"File", "Import", "Media…"} end))
        registerAction("Menu Items.File.Import.Reimport from Camera/Archive...", makeMenuItemHandler(function() return {"File", "Import", "Reimport from Camera/Archive..."} end))
        registerAction("Menu Items.File.Import.Redownload Remote Media...", makeMenuItemHandler(function() return {"File", "Import", "Redownload Remote Media..."} end))
        registerAction("Menu Items.File.Import.iMovie iOS Projects...", makeMenuItemHandler(function() return {"File", "Import", "iMovie iOS Projects..."} end))
        registerAction("Menu Items.File.Import.XML...", makeMenuItemHandler(function() return {"File", "Import", "XML..."} end))
        registerAction("Menu Items.File.Import.Captions…", makeMenuItemHandler(function() return {"File", "Import", "Captions…"} end))
        registerAction("Menu Items.File.Transcode Media…", makeMenuItemHandler(function() return {"File", "Transcode Media…"} end))
        registerAction("Menu Items.File.Relink Files.Original Media…", makeMenuItemHandler(function() return {"File", "Relink Files", "Original Media…"} end))
        registerAction("Menu Items.File.Relink Files.Proxy Media…", makeMenuItemHandler(function() return {"File", "Relink Files", "Proxy Media…"} end))
        registerAction("Menu Items.File.Export XML…", makeMenuItemHandler(function() return {"File", "Export XML…"} end))
        registerAction("Menu Items.File.Export Captions...", makeMenuItemHandler(function() return {"File", "Export Captions..."} end))
        registerAction("Menu Items.File.Share.Master File…", makeMenuItemHandler(function() return {"File", "Share", "Master File…"} end))
        registerAction("Menu Items.File.Share.AIFF…", makeMenuItemHandler(function() return {"File", "Share", "AIFF…"} end))
        registerAction("Menu Items.File.Share.DVD…", makeMenuItemHandler(function() return {"File", "Share", "DVD…"} end))
        registerAction("Menu Items.File.Share.Save Current Frame…", makeMenuItemHandler(function() return {"File", "Share", "Save Current Frame…"} end))
        registerAction("Menu Items.File.Share.Apple Devices 720p…", makeMenuItemHandler(function() return {"File", "Share", "Apple Devices 720p…"} end))
        registerAction("Menu Items.File.Share.Apple Devices 1080p…", makeMenuItemHandler(function() return {"File", "Share", "Apple Devices 1080p…"} end))
        registerAction("Menu Items.File.Share.Apple Devices 4K…", makeMenuItemHandler(function() return {"File", "Share", "Apple Devices 4K…"} end))
        registerAction("Menu Items.File.Share.MP3…", makeMenuItemHandler(function() return {"File", "Share", "MP3…"} end))
        registerAction("Menu Items.File.Share.Export Image Sequence…", makeMenuItemHandler(function() return {"File", "Share", "Export Image Sequence…"} end))
        registerAction("Menu Items.File.Share.Vimeo (advanced)…", makeMenuItemHandler(function() return {"File", "Share", "Vimeo (advanced)…"} end))
        registerAction("Menu Items.File.Share.Xsend Motion…", makeMenuItemHandler(function() return {"File", "Share", "Xsend Motion…"} end))
        registerAction("Menu Items.File.Share.Add Destination…", makeMenuItemHandler(function() return {"File", "Share", "Add Destination…"} end))
        registerAction("Menu Items.File.Send to Compressor.New Batch", makeMenuItemHandler(function() return {"File", "Send to Compressor", "New Batch"} end))
        registerAction("Menu Items.File.Send to Compressor.iTunes Store Package", makeMenuItemHandler(function() return {"File", "Send to Compressor", "iTunes Store Package"} end))
        registerAction("Menu Items.File.Send to Compressor.IMF Package", makeMenuItemHandler(function() return {"File", "Send to Compressor", "IMF Package"} end))
        registerAction("Menu Items.File.Save Video Effects Preset…", makeMenuItemHandler(function() return {"File", "Save Video Effects Preset…"} end))
        registerAction("Menu Items.File.Save Audio Effects Preset…", makeMenuItemHandler(function() return {"File", "Save Audio Effects Preset…"} end))
        registerAction("Menu Items.File.Copy to Library.New Library…", makeMenuItemHandler(function() return {"File", "Copy to Library", "New Library…"} end))
        registerAction("Menu Items.File.Move to Library.New Library…", makeMenuItemHandler(function() return {"File", "Move to Library", "New Library…"} end))
        registerAction("Menu Items.File.Consolidate Library Media…", makeMenuItemHandler(function() return {"File", "Consolidate Library Media…"} end))
        registerAction("Menu Items.File.Consolidate Motion Content...", makeMenuItemHandler(function() return {"File", "Consolidate Motion Content..."} end))
        registerAction("Menu Items.File.Delete Generated Clip Files…", makeMenuItemHandler(function() return {"File", "Delete Generated Clip Files…"} end))
        registerAction("Menu Items.File.Merge Events", makeMenuItemHandler(function() return {"File", "Merge Events"} end))
        registerAction("Menu Items.File.Close Other Timelines", makeMenuItemHandler(function() return {"File", "Close Other Timelines"} end))
        registerAction("Menu Items.File.Reveal in Browser", makeMenuItemHandler(function() return {"File", "Reveal in Browser"} end))
        registerAction("Menu Items.File.Reveal Project in Browser", makeMenuItemHandler(function() return {"File", "Reveal Project in Browser"} end))
        registerAction("Menu Items.File.Reveal in Finder", makeMenuItemHandler(function() return {"File", "Reveal in Finder"} end))
        registerAction("Menu Items.File.Reveal Proxy Media in Finder", makeMenuItemHandler(function() return {"File", "Reveal Proxy Media in Finder"} end))
        registerAction("Menu Items.File.Move to Trash", makeMenuItemHandler(function() return {"File", "Move to Trash"} end))
        registerAction("Menu Items.Edit.Undo", makeMenuItemHandler(function() return {"Edit", "Undo"} end))
        registerAction("Menu Items.Edit.Redo", makeMenuItemHandler(function() return {"Edit", "Redo"} end))
        registerAction("Menu Items.Edit.Cut", makeMenuItemHandler(function() return {"Edit", "Cut"} end))
        registerAction("Menu Items.Edit.Copy", makeMenuItemHandler(function() return {"Edit", "Copy"} end))
        registerAction("Menu Items.Edit.Copy Timecode", makeMenuItemHandler(function() return {"Edit", "Copy Timecode"} end))
        registerAction("Menu Items.Edit.Paste", makeMenuItemHandler(function() return {"Edit", "Paste"} end))
        registerAction("Menu Items.Edit.Paste as Connected Clip", makeMenuItemHandler(function() return {"Edit", "Paste as Connected Clip"} end))
        registerAction("Menu Items.Edit.Delete", makeMenuItemHandler(function() return {"Edit", "Delete"} end))
        registerAction("Menu Items.Edit.Replace with Gap", makeMenuItemHandler(function() return {"Edit", "Replace with Gap"} end))
        registerAction("Menu Items.Edit.Select All", makeMenuItemHandler(function() return {"Edit", "Select All"} end))
        registerAction("Menu Items.Edit.Select Clip", makeMenuItemHandler(function() return {"Edit", "Select Clip"} end))
        registerAction("Menu Items.Edit.Deselect All", makeMenuItemHandler(function() return {"Edit", "Deselect All"} end))
        registerAction("Menu Items.Edit.Select.Select Next", makeMenuItemHandler(function() return {"Edit", "Select", "Select Next"} end))
        registerAction("Menu Items.Edit.Select.Select Previous", makeMenuItemHandler(function() return {"Edit", "Select", "Select Previous"} end))
        registerAction("Menu Items.Edit.Select.Select Above", makeMenuItemHandler(function() return {"Edit", "Select", "Select Above"} end))
        registerAction("Menu Items.Edit.Select.Select Below", makeMenuItemHandler(function() return {"Edit", "Select", "Select Below"} end))
        registerAction("Menu Items.Edit.Paste Effects", makeMenuItemHandler(function() return {"Edit", "Paste Effects"} end))
        registerAction("Menu Items.Edit.Paste Attributes…", makeMenuItemHandler(function() return {"Edit", "Paste Attributes…"} end))
        registerAction("Menu Items.Edit.Remove Effects", makeMenuItemHandler(function() return {"Edit", "Remove Effects"} end))
        registerAction("Menu Items.Edit.Remove Attributes…", makeMenuItemHandler(function() return {"Edit", "Remove Attributes…"} end))
        registerAction("Menu Items.Edit.Duplicate Project", makeMenuItemHandler(function() return {"Edit", "Duplicate Project"} end))
        registerAction("Menu Items.Edit.Duplicate Project As…", makeMenuItemHandler(function() return {"Edit", "Duplicate Project As…"} end))
        registerAction("Menu Items.Edit.Snapshot Project", makeMenuItemHandler(function() return {"Edit", "Snapshot Project"} end))
        registerAction("Menu Items.Edit.Keyframes.Cut", makeMenuItemHandler(function() return {"Edit", "Keyframes", "Cut"} end))
        registerAction("Menu Items.Edit.Keyframes.Copy", makeMenuItemHandler(function() return {"Edit", "Keyframes", "Copy"} end))
        registerAction("Menu Items.Edit.Keyframes.Paste", makeMenuItemHandler(function() return {"Edit", "Keyframes", "Paste"} end))
        registerAction("Menu Items.Edit.Keyframes.Delete", makeMenuItemHandler(function() return {"Edit", "Keyframes", "Delete"} end))
        registerAction("Menu Items.Edit.Connect to Primary Storyline", makeMenuItemHandler(function() return {"Edit", "Connect to Primary Storyline"} end))
        registerAction("Menu Items.Edit.Insert", makeMenuItemHandler(function() return {"Edit", "Insert"} end))
        registerAction("Menu Items.Edit.Append to Storyline", makeMenuItemHandler(function() return {"Edit", "Append to Storyline"} end))
        registerAction("Menu Items.Edit.Overwrite", makeMenuItemHandler(function() return {"Edit", "Overwrite"} end))
        registerAction("Menu Items.Edit.Source Media.All", makeMenuItemHandler(function() return {"Edit", "Source Media", "All"} end))
        registerAction("Menu Items.Edit.Source Media.Video Only", makeMenuItemHandler(function() return {"Edit", "Source Media", "Video Only"} end))
        registerAction("Menu Items.Edit.Source Media.Audio Only", makeMenuItemHandler(function() return {"Edit", "Source Media", "Audio Only"} end))
        registerAction("Menu Items.Edit.Overwrite to Primary Storyline", makeMenuItemHandler(function() return {"Edit", "Overwrite to Primary Storyline"} end))
        registerAction("Menu Items.Edit.Lift from Storyline", makeMenuItemHandler(function() return {"Edit", "Lift from Storyline"} end))
        registerAction("Menu Items.Edit.Add Cross Dissolve", makeMenuItemHandler(function() return {"Edit", "Add Cross Dissolve"} end))
        registerAction("Menu Items.Edit.Add Color Board", makeMenuItemHandler(function() return {"Edit", "Add Color Board"} end))
        registerAction("Menu Items.Edit.Add Channel EQ", makeMenuItemHandler(function() return {"Edit", "Add Channel EQ"} end))
        registerAction("Menu Items.Edit.Connect Title.Basic Title", makeMenuItemHandler(function() return {"Edit", "Connect Title", "Basic Title"} end))
        registerAction("Menu Items.Edit.Connect Title.Basic Lower Third", makeMenuItemHandler(function() return {"Edit", "Connect Title", "Basic Lower Third"} end))
        registerAction("Menu Items.Edit.Insert Generator.Placeholder", makeMenuItemHandler(function() return {"Edit", "Insert Generator", "Placeholder"} end))
        registerAction("Menu Items.Edit.Insert Generator.Gap", makeMenuItemHandler(function() return {"Edit", "Insert Generator", "Gap"} end))
        registerAction("Menu Items.Edit.Connect Freeze Frame", makeMenuItemHandler(function() return {"Edit", "Connect Freeze Frame"} end))
        registerAction("Menu Items.Edit.Captions.Add Caption", makeMenuItemHandler(function() return {"Edit", "Captions", "Add Caption"} end))
        registerAction("Menu Items.Edit.Captions.Edit Caption", makeMenuItemHandler(function() return {"Edit", "Captions", "Edit Caption"} end))
        registerAction("Menu Items.Edit.Captions.Split Captions", makeMenuItemHandler(function() return {"Edit", "Captions", "Split Captions"} end))
        registerAction("Menu Items.Edit.Captions.Resolve Overlaps", makeMenuItemHandler(function() return {"Edit", "Captions", "Resolve Overlaps"} end))
        registerAction("Menu Items.Edit.Captions.Extract Captions", makeMenuItemHandler(function() return {"Edit", "Captions", "Extract Captions"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Afrikaans", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Afrikaans"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Arabic", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Arabic"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Bangla", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Bangla"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Bulgarian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Bulgarian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Catalan", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Catalan"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Chinese (Cantonese)", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Chinese (Cantonese)"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Chinese (Simplified)", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Chinese (Simplified)"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Chinese (Traditional)", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Chinese (Traditional)"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Croatian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Croatian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Czech", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Czech"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Danish", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Danish"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Dutch", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Dutch"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.English.All", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "English", "All"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.English.Australia", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "English", "Australia"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.English.Canada", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "English", "Canada"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.English.United Kingdom", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "English", "United Kingdom"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.English.United States", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "English", "United States"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Estonian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Estonian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Finnish", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Finnish"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.French.Belgium", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "French", "Belgium"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.French.Canada", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "French", "Canada"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.French.France", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "French", "France"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.French.Switzerland", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "French", "Switzerland"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.German.All", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "German", "All"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.German.Austria", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "German", "Austria"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.German.Germany", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "German", "Germany"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.German.Switzerland", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "German", "Switzerland"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Greek.All", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Greek", "All"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Greek.Cyprus", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Greek", "Cyprus"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Hebrew", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Hebrew"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Hindi", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Hindi"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Hungarian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Hungarian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Icelandic", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Icelandic"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Indonesian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Indonesian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Italian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Italian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Japanese", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Japanese"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Kannada", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Kannada"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Kazakh", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Kazakh"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Korean", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Korean"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Lao", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Lao"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Latvian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Latvian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Lithuanian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Lithuanian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Luxembourgish", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Luxembourgish"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Malay", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Malay"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Malayalam", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Malayalam"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Maltese", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Maltese"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Marathi", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Marathi"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Norwegian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Norwegian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Polish", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Polish"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Portuguese.Brazil", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Portuguese", "Brazil"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Portuguese.Portugal", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Portuguese", "Portugal"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Punjabi", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Punjabi"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Romanian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Romanian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Russian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Russian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Scottish Gaelic", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Scottish Gaelic"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Slovak", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Slovak"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Slovenian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Slovenian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Spanish.Latin America", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Spanish", "Latin America"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Spanish.Mexico", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Spanish", "Mexico"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Spanish.Spain", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Spanish", "Spain"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Swedish", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Swedish"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Tagalog", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Tagalog"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Tamil", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Tamil"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Telugu", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Telugu"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Thai", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Thai"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Turkish", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Turkish"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Ukrainian", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Ukrainian"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Urdu", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Urdu"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Vietnamese", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Vietnamese"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Welsh", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Welsh"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Language.Zulu", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Language", "Zulu"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Format.iTT", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Format", "iTT"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Format.CEA-608", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Format", "CEA-608"} end))
        registerAction("Menu Items.Edit.Captions.Duplicate Captions to New Format.SRT", makeMenuItemHandler(function() return {"Edit", "Captions", "Duplicate Captions to New Format", "SRT"} end))
        registerAction("Menu Items.Edit.Find…", makeMenuItemHandler(function() return {"Edit", "Find…"} end))
        registerAction("Menu Items.Edit.Find and Replace Title Text...", makeMenuItemHandler(function() return {"Edit", "Find and Replace Title Text..."} end))
        registerAction("Menu Items.Edit.Start Dictation…", makeMenuItemHandler(function() return {"Edit", "Start Dictation…"} end))
        registerAction("Menu Items.Edit.Emoji & Symbols", makeMenuItemHandler(function() return {"Edit", "Emoji & Symbols"} end))
        registerAction("Menu Items.Trim.Blade", makeMenuItemHandler(function() return {"Trim", "Blade"} end))
        registerAction("Menu Items.Trim.Blade All", makeMenuItemHandler(function() return {"Trim", "Blade All"} end))
        registerAction("Menu Items.Trim.Join Clips", makeMenuItemHandler(function() return {"Trim", "Join Clips"} end))
        registerAction("Menu Items.Trim.Trim Start", makeMenuItemHandler(function() return {"Trim", "Trim Start"} end))
        registerAction("Menu Items.Trim.Trim End", makeMenuItemHandler(function() return {"Trim", "Trim End"} end))
        registerAction("Menu Items.Trim.Trim to Selection", makeMenuItemHandler(function() return {"Trim", "Trim to Selection"} end))
        registerAction("Menu Items.Trim.Extend Edit", makeMenuItemHandler(function() return {"Trim", "Extend Edit"} end))
        registerAction("Menu Items.Trim.Align Audio to Video", makeMenuItemHandler(function() return {"Trim", "Align Audio to Video"} end))
        registerAction("Menu Items.Trim.Nudge Left", makeMenuItemHandler(function() return {"Trim", "Nudge Left"} end))
        registerAction("Menu Items.Trim.Nudge Right", makeMenuItemHandler(function() return {"Trim", "Nudge Right"} end))
        registerAction("Menu Items.Mark.Set Range Start", makeMenuItemHandler(function() return {"Mark", "Set Range Start"} end))
        registerAction("Menu Items.Mark.Set Range End", makeMenuItemHandler(function() return {"Mark", "Set Range End"} end))
        registerAction("Menu Items.Mark.Set Clip Range", makeMenuItemHandler(function() return {"Mark", "Set Clip Range"} end))
        registerAction("Menu Items.Mark.Clear Selected Ranges", makeMenuItemHandler(function() return {"Mark", "Clear Selected Ranges"} end))
        registerAction("Menu Items.Mark.Favorite", makeMenuItemHandler(function() return {"Mark", "Favorite"} end))
        registerAction("Menu Items.Mark.Delete", makeMenuItemHandler(function() return {"Mark", "Delete"} end))
        registerAction("Menu Items.Mark.Unrate", makeMenuItemHandler(function() return {"Mark", "Unrate"} end))
        registerAction("Menu Items.Mark.Show Keyword Editor", makeMenuItemHandler(function() return {"Mark", "Show Keyword Editor"} end))
        registerAction("Menu Items.Mark.Remove All Keywords", makeMenuItemHandler(function() return {"Mark", "Remove All Keywords"} end))
        registerAction("Menu Items.Mark.Remove All Analysis Keywords", makeMenuItemHandler(function() return {"Mark", "Remove All Analysis Keywords"} end))
        registerAction("Menu Items.Mark.Markers.Add Marker", makeMenuItemHandler(function() return {"Mark", "Markers", "Add Marker"} end))
        registerAction("Menu Items.Mark.Markers.Add Marker and Modify", makeMenuItemHandler(function() return {"Mark", "Markers", "Add Marker and Modify"} end))
        registerAction("Menu Items.Mark.Markers.Modify Marker", makeMenuItemHandler(function() return {"Mark", "Markers", "Modify Marker"} end))
        registerAction("Menu Items.Mark.Markers.Nudge Marker Left", makeMenuItemHandler(function() return {"Mark", "Markers", "Nudge Marker Left"} end))
        registerAction("Menu Items.Mark.Markers.Nudge Marker Right", makeMenuItemHandler(function() return {"Mark", "Markers", "Nudge Marker Right"} end))
        registerAction("Menu Items.Mark.Markers.Delete Marker", makeMenuItemHandler(function() return {"Mark", "Markers", "Delete Marker"} end))
        registerAction("Menu Items.Mark.Markers.Delete Markers in Selection", makeMenuItemHandler(function() return {"Mark", "Markers", "Delete Markers in Selection"} end))
        registerAction("Menu Items.Mark.Go to.Range Start", makeMenuItemHandler(function() return {"Mark", "Go to", "Range Start"} end))
        registerAction("Menu Items.Mark.Go to.Range End", makeMenuItemHandler(function() return {"Mark", "Go to", "Range End"} end))
        registerAction("Menu Items.Mark.Go to.Beginning", makeMenuItemHandler(function() return {"Mark", "Go to", "Beginning"} end))
        registerAction("Menu Items.Mark.Go to.End", makeMenuItemHandler(function() return {"Mark", "Go to", "End"} end))
        registerAction("Menu Items.Mark.Previous.Frame", makeMenuItemHandler(function() return {"Mark", "Previous", "Frame"} end))
        registerAction("Menu Items.Mark.Previous.Edit", makeMenuItemHandler(function() return {"Mark", "Previous", "Edit"} end))
        registerAction("Menu Items.Mark.Previous.Marker", makeMenuItemHandler(function() return {"Mark", "Previous", "Marker"} end))
        registerAction("Menu Items.Mark.Previous.Keyframe", makeMenuItemHandler(function() return {"Mark", "Previous", "Keyframe"} end))
        registerAction("Menu Items.Mark.Next.Frame", makeMenuItemHandler(function() return {"Mark", "Next", "Frame"} end))
        registerAction("Menu Items.Mark.Next.Edit", makeMenuItemHandler(function() return {"Mark", "Next", "Edit"} end))
        registerAction("Menu Items.Mark.Next.Marker", makeMenuItemHandler(function() return {"Mark", "Next", "Marker"} end))
        registerAction("Menu Items.Mark.Next.Keyframe", makeMenuItemHandler(function() return {"Mark", "Next", "Keyframe"} end))
        registerAction("Menu Items.Clip.Create Storyline", makeMenuItemHandler(function() return {"Clip", "Create Storyline"} end))
        registerAction("Menu Items.Clip.Synchronize Clips…", makeMenuItemHandler(function() return {"Clip", "Synchronize Clips…"} end))
        registerAction("Menu Items.Clip.Reference New Parent Clip", makeMenuItemHandler(function() return {"Clip", "Reference New Parent Clip"} end))
        registerAction("Menu Items.Clip.Open Clip", makeMenuItemHandler(function() return {"Clip", "Open Clip"} end))
        registerAction("Menu Items.Clip.Audition.Open", makeMenuItemHandler(function() return {"Clip", "Audition", "Open"} end))
        registerAction("Menu Items.Clip.Audition.Preview", makeMenuItemHandler(function() return {"Clip", "Audition", "Preview"} end))
        registerAction("Menu Items.Clip.Audition.Create", makeMenuItemHandler(function() return {"Clip", "Audition", "Create"} end))
        registerAction("Menu Items.Clip.Audition.Duplicate as Audition", makeMenuItemHandler(function() return {"Clip", "Audition", "Duplicate as Audition"} end))
        registerAction("Menu Items.Clip.Audition.Duplicate from Original", makeMenuItemHandler(function() return {"Clip", "Audition", "Duplicate from Original"} end))
        registerAction("Menu Items.Clip.Audition.Next Pick", makeMenuItemHandler(function() return {"Clip", "Audition", "Next Pick"} end))
        registerAction("Menu Items.Clip.Audition.Previous Pick", makeMenuItemHandler(function() return {"Clip", "Audition", "Previous Pick"} end))
        registerAction("Menu Items.Clip.Audition.Finalize Audition", makeMenuItemHandler(function() return {"Clip", "Audition", "Finalize Audition"} end))
        registerAction("Menu Items.Clip.Audition.Replace and add to Audition", makeMenuItemHandler(function() return {"Clip", "Audition", "Replace and add to Audition"} end))
        registerAction("Menu Items.Clip.Audition.Add to Audition", makeMenuItemHandler(function() return {"Clip", "Audition", "Add to Audition"} end))
        registerAction("Menu Items.Clip.Show Video Animation", makeMenuItemHandler(function() return {"Clip", "Show Video Animation"} end))
        registerAction("Menu Items.Clip.Show Audio Animation", makeMenuItemHandler(function() return {"Clip", "Show Audio Animation"} end))
        registerAction("Menu Items.Clip.Solo Animation", makeMenuItemHandler(function() return {"Clip", "Solo Animation"} end))
        registerAction("Menu Items.Clip.Expand Audio", makeMenuItemHandler(function() return {"Clip", "Expand Audio"} end))
        registerAction("Menu Items.Clip.Expand Audio Components", makeMenuItemHandler(function() return {"Clip", "Expand Audio Components"} end))
        registerAction("Menu Items.Clip.Detach Audio", makeMenuItemHandler(function() return {"Clip", "Detach Audio"} end))
        registerAction("Menu Items.Clip.Break Apart Clip Items", makeMenuItemHandler(function() return {"Clip", "Break Apart Clip Items"} end))
        registerAction("Menu Items.Clip.Enable", makeMenuItemHandler(function() return {"Clip", "Enable"} end))
        registerAction("Menu Items.Clip.Solo", makeMenuItemHandler(function() return {"Clip", "Solo"} end))
        registerAction("Menu Items.Clip.Add to Soloed Clips", makeMenuItemHandler(function() return {"Clip", "Add to Soloed Clips"} end))
        registerAction("Menu Items.Modify.Analyze and Fix…", makeMenuItemHandler(function() return {"Modify", "Analyze and Fix…"} end))
        registerAction("Menu Items.Modify.Adjust Content Created Date and Time…", makeMenuItemHandler(function() return {"Modify", "Adjust Content Created Date and Time…"} end))
        registerAction("Menu Items.Modify.Apply Custom Name.Clip Date/Time", makeMenuItemHandler(function() return {"Modify", "Apply Custom Name", "Clip Date/Time"} end))
        registerAction("Menu Items.Modify.Apply Custom Name.Custom Name with Counter", makeMenuItemHandler(function() return {"Modify", "Apply Custom Name", "Custom Name with Counter"} end))
        registerAction("Menu Items.Modify.Apply Custom Name.Original Name from Camera", makeMenuItemHandler(function() return {"Modify", "Apply Custom Name", "Original Name from Camera"} end))
        registerAction("Menu Items.Modify.Apply Custom Name.Scene/Shot/Take/Angle", makeMenuItemHandler(function() return {"Modify", "Apply Custom Name", "Scene/Shot/Take/Angle"} end))
        registerAction("Menu Items.Modify.Apply Custom Name.Edit…", makeMenuItemHandler(function() return {"Modify", "Apply Custom Name", "Edit…"} end))
        registerAction("Menu Items.Modify.Apply Custom Name.New…", makeMenuItemHandler(function() return {"Modify", "Apply Custom Name", "New…"} end))
        registerAction("Menu Items.Modify.Assign Audio Roles.Edit Roles…", makeMenuItemHandler(function() return {"Modify", "Assign Audio Roles", "Edit Roles…"} end))
        registerAction("Menu Items.Modify.Assign Video Roles.Edit Roles…", makeMenuItemHandler(function() return {"Modify", "Assign Video Roles", "Edit Roles…"} end))
        registerAction("Menu Items.Modify.Assign Caption Roles.Edit Roles…", makeMenuItemHandler(function() return {"Modify", "Assign Caption Roles", "Edit Roles…"} end))
        registerAction("Menu Items.Modify.Edit Roles…", makeMenuItemHandler(function() return {"Modify", "Edit Roles…"} end))
        registerAction("Menu Items.Modify.Balance Color", makeMenuItemHandler(function() return {"Modify", "Balance Color"} end))
        registerAction("Menu Items.Modify.Match Color…", makeMenuItemHandler(function() return {"Modify", "Match Color…"} end))
        registerAction("Menu Items.Modify.Smart Conform", makeMenuItemHandler(function() return {"Modify", "Smart Conform"} end))
        registerAction("Menu Items.Modify.Auto Enhance Audio", makeMenuItemHandler(function() return {"Modify", "Auto Enhance Audio"} end))
        registerAction("Menu Items.Modify.Match Audio…", makeMenuItemHandler(function() return {"Modify", "Match Audio…"} end))
        registerAction("Menu Items.Modify.Adjust Volume.Up (+1 dB)", makeMenuItemHandler(function() return {"Modify", "Adjust Volume", "Up (+1 dB)"} end))
        registerAction("Menu Items.Modify.Adjust Volume.Down (-1 dB)", makeMenuItemHandler(function() return {"Modify", "Adjust Volume", "Down (-1 dB)"} end))
        registerAction("Menu Items.Modify.Adjust Volume.Silence (-∞)", makeMenuItemHandler(function() return {"Modify", "Adjust Volume", "Silence (-∞)"} end))
        registerAction("Menu Items.Modify.Adjust Volume.Reset (0dB)", makeMenuItemHandler(function() return {"Modify", "Adjust Volume", "Reset (0dB)"} end))
        registerAction("Menu Items.Modify.Adjust Volume.Absolute…", makeMenuItemHandler(function() return {"Modify", "Adjust Volume", "Absolute…"} end))
        registerAction("Menu Items.Modify.Adjust Volume.Relative…", makeMenuItemHandler(function() return {"Modify", "Adjust Volume", "Relative…"} end))
        registerAction("Menu Items.Modify.Adjust Audio Fades.Crossfade", makeMenuItemHandler(function() return {"Modify", "Adjust Audio Fades", "Crossfade"} end))
        registerAction("Menu Items.Modify.Adjust Audio Fades.Apply Fades", makeMenuItemHandler(function() return {"Modify", "Adjust Audio Fades", "Apply Fades"} end))
        registerAction("Menu Items.Modify.Adjust Audio Fades.Remove Fades", makeMenuItemHandler(function() return {"Modify", "Adjust Audio Fades", "Remove Fades"} end))
        registerAction("Menu Items.Modify.Adjust Audio Fades.Fade In", makeMenuItemHandler(function() return {"Modify", "Adjust Audio Fades", "Fade In"} end))
        registerAction("Menu Items.Modify.Adjust Audio Fades.Fade Out", makeMenuItemHandler(function() return {"Modify", "Adjust Audio Fades", "Fade Out"} end))
        registerAction("Menu Items.Modify.Add Keyframe to Selected Effect in Animation Editor", makeMenuItemHandler(function() return {"Modify", "Add Keyframe to Selected Effect in Animation Editor"} end))
        registerAction("Menu Items.Modify.Change Duration…", makeMenuItemHandler(function() return {"Modify", "Change Duration…"} end))
        registerAction("Menu Items.Modify.Retime.Slow.50%", makeMenuItemHandler(function() return {"Modify", "Retime", "Slow", "50%"} end))
        registerAction("Menu Items.Modify.Retime.Slow.25%", makeMenuItemHandler(function() return {"Modify", "Retime", "Slow", "25%"} end))
        registerAction("Menu Items.Modify.Retime.Slow.10%", makeMenuItemHandler(function() return {"Modify", "Retime", "Slow", "10%"} end))
        registerAction("Menu Items.Modify.Retime.Fast.2x", makeMenuItemHandler(function() return {"Modify", "Retime", "Fast", "2x"} end))
        registerAction("Menu Items.Modify.Retime.Fast.4x", makeMenuItemHandler(function() return {"Modify", "Retime", "Fast", "4x"} end))
        registerAction("Menu Items.Modify.Retime.Fast.8x", makeMenuItemHandler(function() return {"Modify", "Retime", "Fast", "8x"} end))
        registerAction("Menu Items.Modify.Retime.Fast.20x", makeMenuItemHandler(function() return {"Modify", "Retime", "Fast", "20x"} end))
        registerAction("Menu Items.Modify.Retime.Normal (100%)", makeMenuItemHandler(function() return {"Modify", "Retime", "Normal (100%)"} end))
        registerAction("Menu Items.Modify.Retime.Hold", makeMenuItemHandler(function() return {"Modify", "Retime", "Hold"} end))
        registerAction("Menu Items.Modify.Retime.Blade Speed", makeMenuItemHandler(function() return {"Modify", "Retime", "Blade Speed"} end))
        registerAction("Menu Items.Modify.Retime.Custom Speed...", makeMenuItemHandler(function() return {"Modify", "Retime", "Custom Speed..."} end))
        registerAction("Menu Items.Modify.Retime.Reverse Clip", makeMenuItemHandler(function() return {"Modify", "Retime", "Reverse Clip"} end))
        registerAction("Menu Items.Modify.Retime.Reset Speed ", makeMenuItemHandler(function() return {"Modify", "Retime", "Reset Speed "} end))
        registerAction("Menu Items.Modify.Retime.Automatic Speed", makeMenuItemHandler(function() return {"Modify", "Retime", "Automatic Speed"} end))
        registerAction("Menu Items.Modify.Retime.Speed Ramp.to 0%", makeMenuItemHandler(function() return {"Modify", "Retime", "Speed Ramp", "to 0%"} end))
        registerAction("Menu Items.Modify.Retime.Speed Ramp.from 0%", makeMenuItemHandler(function() return {"Modify", "Retime", "Speed Ramp", "from 0%"} end))
        registerAction("Menu Items.Modify.Retime.Instant Replay.100%", makeMenuItemHandler(function() return {"Modify", "Retime", "Instant Replay", "100%"} end))
        registerAction("Menu Items.Modify.Retime.Instant Replay.50%", makeMenuItemHandler(function() return {"Modify", "Retime", "Instant Replay", "50%"} end))
        registerAction("Menu Items.Modify.Retime.Instant Replay.25%", makeMenuItemHandler(function() return {"Modify", "Retime", "Instant Replay", "25%"} end))
        registerAction("Menu Items.Modify.Retime.Instant Replay.10%", makeMenuItemHandler(function() return {"Modify", "Retime", "Instant Replay", "10%"} end))
        registerAction("Menu Items.Modify.Retime.Rewind.1x", makeMenuItemHandler(function() return {"Modify", "Retime", "Rewind", "1x"} end))
        registerAction("Menu Items.Modify.Retime.Rewind.2x", makeMenuItemHandler(function() return {"Modify", "Retime", "Rewind", "2x"} end))
        registerAction("Menu Items.Modify.Retime.Rewind.4x", makeMenuItemHandler(function() return {"Modify", "Retime", "Rewind", "4x"} end))
        registerAction("Menu Items.Modify.Retime.Jump Cut at Markers.3 frames", makeMenuItemHandler(function() return {"Modify", "Retime", "Jump Cut at Markers", "3 frames"} end))
        registerAction("Menu Items.Modify.Retime.Jump Cut at Markers.5 frames", makeMenuItemHandler(function() return {"Modify", "Retime", "Jump Cut at Markers", "5 frames"} end))
        registerAction("Menu Items.Modify.Retime.Jump Cut at Markers.10 frames", makeMenuItemHandler(function() return {"Modify", "Retime", "Jump Cut at Markers", "10 frames"} end))
        registerAction("Menu Items.Modify.Retime.Jump Cut at Markers.20 frames", makeMenuItemHandler(function() return {"Modify", "Retime", "Jump Cut at Markers", "20 frames"} end))
        registerAction("Menu Items.Modify.Retime.Jump Cut at Markers.30 frames", makeMenuItemHandler(function() return {"Modify", "Retime", "Jump Cut at Markers", "30 frames"} end))
        registerAction("Menu Items.Modify.Retime.Video Quality.Normal", makeMenuItemHandler(function() return {"Modify", "Retime", "Video Quality", "Normal"} end))
        registerAction("Menu Items.Modify.Retime.Video Quality.Frame Blending", makeMenuItemHandler(function() return {"Modify", "Retime", "Video Quality", "Frame Blending"} end))
        registerAction("Menu Items.Modify.Retime.Video Quality.Optical Flow", makeMenuItemHandler(function() return {"Modify", "Retime", "Video Quality", "Optical Flow"} end))
        registerAction("Menu Items.Modify.Retime.Preserve Pitch", makeMenuItemHandler(function() return {"Modify", "Retime", "Preserve Pitch"} end))
        registerAction("Menu Items.Modify.Retime.Speed Transitions", makeMenuItemHandler(function() return {"Modify", "Retime", "Speed Transitions"} end))
        registerAction("Menu Items.Modify.Retime.Show Retime Editor", makeMenuItemHandler(function() return {"Modify", "Retime", "Show Retime Editor"} end))
        registerAction("Menu Items.Modify.Render All", makeMenuItemHandler(function() return {"Modify", "Render All"} end))
        registerAction("Menu Items.Modify.Render Selection", makeMenuItemHandler(function() return {"Modify", "Render Selection"} end))
        registerAction("Menu Items.View.Playback.Play", makeMenuItemHandler(function() return {"View", "Playback", "Play"} end))
        registerAction("Menu Items.View.Playback.Play Selection", makeMenuItemHandler(function() return {"View", "Playback", "Play Selection"} end))
        registerAction("Menu Items.View.Playback.Play Around", makeMenuItemHandler(function() return {"View", "Playback", "Play Around"} end))
        registerAction("Menu Items.View.Playback.Play from Beginning", makeMenuItemHandler(function() return {"View", "Playback", "Play from Beginning"} end))
        registerAction("Menu Items.View.Playback.Play to End", makeMenuItemHandler(function() return {"View", "Playback", "Play to End"} end))
        registerAction("Menu Items.View.Playback.Play Full Screen", makeMenuItemHandler(function() return {"View", "Playback", "Play Full Screen"} end))
        registerAction("Menu Items.View.Playback.Loop Playback", makeMenuItemHandler(function() return {"View", "Playback", "Loop Playback"} end))
        registerAction("Menu Items.View.Sort Library Events By.Date", makeMenuItemHandler(function() return {"View", "Sort Library Events By", "Date"} end))
        registerAction("Menu Items.View.Sort Library Events By.Name", makeMenuItemHandler(function() return {"View", "Sort Library Events By", "Name"} end))
        registerAction("Menu Items.View.Sort Library Events By.Ascending", makeMenuItemHandler(function() return {"View", "Sort Library Events By", "Ascending"} end))
        registerAction("Menu Items.View.Sort Library Events By.Descending", makeMenuItemHandler(function() return {"View", "Sort Library Events By", "Descending"} end))
        registerAction("Menu Items.View.Browser.Toggle Filmstrip/List View", makeMenuItemHandler(function() return {"View", "Browser", "Toggle Filmstrip/List View"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.None", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "None"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Content Created", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Content Created"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Date Imported", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Date Imported"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Reel", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Reel"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Scene", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Scene"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Duration", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Duration"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.File Type", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "File Type"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Roles", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Roles"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Camera Name", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Camera Name"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Camera Angle", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Camera Angle"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Ascending", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Ascending"} end))
        registerAction("Menu Items.View.Browser.Group Clips By.Descending", makeMenuItemHandler(function() return {"View", "Browser", "Group Clips By", "Descending"} end))
        registerAction("Menu Items.View.Browser.Sort By.Content Created", makeMenuItemHandler(function() return {"View", "Browser", "Sort By", "Content Created"} end))
        registerAction("Menu Items.View.Browser.Sort By.Name", makeMenuItemHandler(function() return {"View", "Browser", "Sort By", "Name"} end))
        registerAction("Menu Items.View.Browser.Sort By.Take", makeMenuItemHandler(function() return {"View", "Browser", "Sort By", "Take"} end))
        registerAction("Menu Items.View.Browser.Sort By.Duration", makeMenuItemHandler(function() return {"View", "Browser", "Sort By", "Duration"} end))
        registerAction("Menu Items.View.Browser.Sort By.Ascending", makeMenuItemHandler(function() return {"View", "Browser", "Sort By", "Ascending"} end))
        registerAction("Menu Items.View.Browser.Sort By.Descending", makeMenuItemHandler(function() return {"View", "Browser", "Sort By", "Descending"} end))
        registerAction("Menu Items.View.Browser.Clip Name Size.Small", makeMenuItemHandler(function() return {"View", "Browser", "Clip Name Size", "Small"} end))
        registerAction("Menu Items.View.Browser.Clip Name Size.Medium", makeMenuItemHandler(function() return {"View", "Browser", "Clip Name Size", "Medium"} end))
        registerAction("Menu Items.View.Browser.Clip Name Size.Large", makeMenuItemHandler(function() return {"View", "Browser", "Clip Name Size", "Large"} end))
        registerAction("Menu Items.View.Browser.Clip Names", makeMenuItemHandler(function() return {"View", "Browser", "Clip Names"} end))
        registerAction("Menu Items.View.Browser.Waveforms", makeMenuItemHandler(function() return {"View", "Browser", "Waveforms"} end))
        registerAction("Menu Items.View.Browser.Marked Ranges", makeMenuItemHandler(function() return {"View", "Browser", "Marked Ranges"} end))
        registerAction("Menu Items.View.Browser.Used Media Ranges", makeMenuItemHandler(function() return {"View", "Browser", "Used Media Ranges"} end))
        registerAction("Menu Items.View.Browser.Skimmer Info", makeMenuItemHandler(function() return {"View", "Browser", "Skimmer Info"} end))
        registerAction("Menu Items.View.Browser.Continuous Playback", makeMenuItemHandler(function() return {"View", "Browser", "Continuous Playback"} end))
        registerAction("Menu Items.View.Show in Viewer.Angles", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Angles"} end))
        registerAction("Menu Items.View.Show in Viewer.360°", makeMenuItemHandler(function() return {"View", "Show in Viewer", "360°"} end))
        registerAction("Menu Items.View.Show in Viewer.Video Scopes", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Video Scopes"} end))
        registerAction("Menu Items.View.Show in Viewer.Both Fields", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Both Fields"} end))
        registerAction("Menu Items.View.Show in Viewer.Title/Action Safe Zones", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Title/Action Safe Zones"} end))
        registerAction("Menu Items.View.Show in Viewer.Show Custom Overlay", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Show Custom Overlay"} end))
        registerAction("Menu Items.View.Show in Viewer.Choose Custom Overlay.Add Custom Overlay…", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Choose Custom Overlay", "Add Custom Overlay…"} end))
        registerAction("Menu Items.View.Show in Viewer.Color Channels.All", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Color Channels", "All"} end))
        registerAction("Menu Items.View.Show in Viewer.Color Channels.Alpha", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Color Channels", "Alpha"} end))
        registerAction("Menu Items.View.Show in Viewer.Color Channels.Red", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Color Channels", "Red"} end))
        registerAction("Menu Items.View.Show in Viewer.Color Channels.Green", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Color Channels", "Green"} end))
        registerAction("Menu Items.View.Show in Viewer.Color Channels.Blue", makeMenuItemHandler(function() return {"View", "Show in Viewer", "Color Channels", "Blue"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Angles", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Angles"} end))
        registerAction("Menu Items.View.Show in Event Viewer.360°", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "360°"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Video Scopes", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Video Scopes"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Both Fields", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Both Fields"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Title/Action Safe Zones", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Title/Action Safe Zones"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Show Custom Overlay", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Show Custom Overlay"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Choose Custom Overlay", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Choose Custom Overlay"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Color Channels.All", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Color Channels", "All"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Color Channels.Alpha", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Color Channels", "Alpha"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Color Channels.Red", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Color Channels", "Red"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Color Channels.Green", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Color Channels", "Green"} end))
        registerAction("Menu Items.View.Show in Event Viewer.Color Channels.Blue", makeMenuItemHandler(function() return {"View", "Show in Event Viewer", "Color Channels", "Blue"} end))
        registerAction("Menu Items.View.Toggle Inspector Height", makeMenuItemHandler(function() return {"View", "Toggle Inspector Height"} end))
        registerAction("Menu Items.View.Timeline Index.Clips", makeMenuItemHandler(function() return {"View", "Timeline Index", "Clips"} end))
        registerAction("Menu Items.View.Timeline Index.Tags", makeMenuItemHandler(function() return {"View", "Timeline Index", "Tags"} end))
        registerAction("Menu Items.View.Timeline Index.Roles", makeMenuItemHandler(function() return {"View", "Timeline Index", "Roles"} end))
        registerAction("Menu Items.View.Timeline Index.Captions", makeMenuItemHandler(function() return {"View", "Timeline Index", "Captions"} end))
        registerAction("Menu Items.View.Show Audio Lanes", makeMenuItemHandler(function() return {"View", "Show Audio Lanes"} end))
        registerAction("Menu Items.View.Collapse Subroles", makeMenuItemHandler(function() return {"View", "Collapse Subroles"} end))
        registerAction("Menu Items.View.Timeline History Back", makeMenuItemHandler(function() return {"View", "Timeline History Back"} end))
        registerAction("Menu Items.View.Timeline History Forward", makeMenuItemHandler(function() return {"View", "Timeline History Forward"} end))
        registerAction("Menu Items.View.Show Precision Editor", makeMenuItemHandler(function() return {"View", "Show Precision Editor"} end))
        registerAction("Menu Items.View.Zoom In", makeMenuItemHandler(function() return {"View", "Zoom In"} end))
        registerAction("Menu Items.View.Zoom Out", makeMenuItemHandler(function() return {"View", "Zoom Out"} end))
        registerAction("Menu Items.View.Zoom to Fit", makeMenuItemHandler(function() return {"View", "Zoom to Fit"} end))
        registerAction("Menu Items.View.Zoom to Samples", makeMenuItemHandler(function() return {"View", "Zoom to Samples"} end))
        registerAction("Menu Items.View.Skimming", makeMenuItemHandler(function() return {"View", "Skimming"} end))
        registerAction("Menu Items.View.Clip Skimming", makeMenuItemHandler(function() return {"View", "Clip Skimming"} end))
        registerAction("Menu Items.View.Audio Skimming", makeMenuItemHandler(function() return {"View", "Audio Skimming"} end))
        registerAction("Menu Items.View.Snapping", makeMenuItemHandler(function() return {"View", "Snapping"} end))
        registerAction("Menu Items.View.Enter Full Screen", makeMenuItemHandler(function() return {"View", "Enter Full Screen"} end))
        registerAction("Menu Items.Window.Minimize", makeMenuItemHandler(function() return {"Window", "Minimize"} end))
        registerAction("Menu Items.Window.Zoom", makeMenuItemHandler(function() return {"Window", "Zoom"} end))
        registerAction("Menu Items.Window.Go To.Libraries", makeMenuItemHandler(function() return {"Window", "Go To", "Libraries"} end))
        registerAction("Menu Items.Window.Go To.Photos and Audio", makeMenuItemHandler(function() return {"Window", "Go To", "Photos and Audio"} end))
        registerAction("Menu Items.Window.Go To.Titles and Generators", makeMenuItemHandler(function() return {"Window", "Go To", "Titles and Generators"} end))
        registerAction("Menu Items.Window.Go To.Viewer", makeMenuItemHandler(function() return {"Window", "Go To", "Viewer"} end))
        registerAction("Menu Items.Window.Go To.Event Viewer", makeMenuItemHandler(function() return {"Window", "Go To", "Event Viewer"} end))
        registerAction("Menu Items.Window.Go To.Comparison Viewer", makeMenuItemHandler(function() return {"Window", "Go To", "Comparison Viewer"} end))
        registerAction("Menu Items.Window.Go To.Timeline", makeMenuItemHandler(function() return {"Window", "Go To", "Timeline"} end))
        registerAction("Menu Items.Window.Go To.Inspector", makeMenuItemHandler(function() return {"Window", "Go To", "Inspector"} end))
        registerAction("Menu Items.Window.Go To.Color Inspector", makeMenuItemHandler(function() return {"Window", "Go To", "Color Inspector"} end))
        registerAction("Menu Items.Window.Go To.Next Tab", makeMenuItemHandler(function() return {"Window", "Go To", "Next Tab"} end))
        registerAction("Menu Items.Window.Go To.Previous Tab", makeMenuItemHandler(function() return {"Window", "Go To", "Previous Tab"} end))
        registerAction("Menu Items.Window.Show in Workspace.Sidebar", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Sidebar"} end))
        registerAction("Menu Items.Window.Show in Workspace.Browser", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Browser"} end))
        registerAction("Menu Items.Window.Show in Workspace.Event Viewer", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Event Viewer"} end))
        registerAction("Menu Items.Window.Show in Workspace.Comparison Viewer", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Comparison Viewer"} end))
        registerAction("Menu Items.Window.Show in Workspace.Inspector", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Inspector"} end))
        registerAction("Menu Items.Window.Show in Workspace.Timeline", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Timeline"} end))
        registerAction("Menu Items.Window.Show in Workspace.Timeline Index", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Timeline Index"} end))
        registerAction("Menu Items.Window.Show in Workspace.Audio Meters", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Audio Meters"} end))
        registerAction("Menu Items.Window.Show in Workspace.Effects", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Effects"} end))
        registerAction("Menu Items.Window.Show in Workspace.Transitions", makeMenuItemHandler(function() return {"Window", "Show in Workspace", "Transitions"} end))
        registerAction("Menu Items.Window.Show in Secondary Display.Browser", makeMenuItemHandler(function() return {"Window", "Show in Secondary Display", "Browser"} end))
        registerAction("Menu Items.Window.Show in Secondary Display.Viewers", makeMenuItemHandler(function() return {"Window", "Show in Secondary Display", "Viewers"} end))
        registerAction("Menu Items.Window.Show in Secondary Display.Timeline", makeMenuItemHandler(function() return {"Window", "Show in Secondary Display", "Timeline"} end))
        registerAction("Menu Items.Window.Workspaces.Default", makeMenuItemHandler(function() return {"Window", "Workspaces", "Default"} end))
        registerAction("Menu Items.Window.Workspaces.Organize", makeMenuItemHandler(function() return {"Window", "Workspaces", "Organize"} end))
        registerAction("Menu Items.Window.Workspaces.Color & Effects", makeMenuItemHandler(function() return {"Window", "Workspaces", "Color & Effects"} end))
        registerAction("Menu Items.Window.Workspaces.Dual Displays", makeMenuItemHandler(function() return {"Window", "Workspaces", "Dual Displays"} end))
        registerAction("Menu Items.Window.Workspaces.Save Workspace as…", makeMenuItemHandler(function() return {"Window", "Workspaces", "Save Workspace as…"} end))
        registerAction("Menu Items.Window.Workspaces.Update Workspace", makeMenuItemHandler(function() return {"Window", "Workspaces", "Update Workspace"} end))
        registerAction("Menu Items.Window.Workspaces.Open Workspace Folder in Finder", makeMenuItemHandler(function() return {"Window", "Workspaces", "Open Workspace Folder in Finder"} end))
        registerAction("Menu Items.Window.Extensions.Frame.io", makeMenuItemHandler(function() return {"Window", "Extensions", "Frame.io"} end))
        registerAction("Menu Items.Window.Extensions.Getting Started for Final Cut Pro 10.4", makeMenuItemHandler(function() return {"Window", "Extensions", "Getting Started for Final Cut Pro 10.4"} end))
        registerAction("Menu Items.Window.Extensions.KeyFlow Pro 2 Extension", makeMenuItemHandler(function() return {"Window", "Extensions", "KeyFlow Pro 2 Extension"} end))
        registerAction("Menu Items.Window.Extensions.Scribeomatic", makeMenuItemHandler(function() return {"Window", "Extensions", "Scribeomatic"} end))
        registerAction("Menu Items.Window.Extensions.ShareBrowser", makeMenuItemHandler(function() return {"Window", "Extensions", "ShareBrowser"} end))
        registerAction("Menu Items.Window.Extensions.Shutterstock", makeMenuItemHandler(function() return {"Window", "Extensions", "Shutterstock"} end))
        registerAction("Menu Items.Window.Extensions.Simon Says Transcription", makeMenuItemHandler(function() return {"Window", "Extensions", "Simon Says Transcription"} end))
        registerAction("Menu Items.Window.Record Voiceover", makeMenuItemHandler(function() return {"Window", "Record Voiceover"} end))
        registerAction("Menu Items.Window.Background Tasks", makeMenuItemHandler(function() return {"Window", "Background Tasks"} end))
        registerAction("Menu Items.Window.Project Properties", makeMenuItemHandler(function() return {"Window", "Project Properties"} end))
        registerAction("Menu Items.Window.Project Timecode", makeMenuItemHandler(function() return {"Window", "Project Timecode"} end))
        registerAction("Menu Items.Window.Source Timecode", makeMenuItemHandler(function() return {"Window", "Source Timecode"} end))
        registerAction("Menu Items.Window.A/V Output", makeMenuItemHandler(function() return {"Window", "A/V Output"} end))
        registerAction("Menu Items.Window.Output to VR Headset", makeMenuItemHandler(function() return {"Window", "Output to VR Headset"} end))
        registerAction("Menu Items.Window.Bring All to Front", makeMenuItemHandler(function() return {"Window", "Bring All to Front"} end))
        registerAction("Menu Items.Window.Final Cut Pro", makeMenuItemHandler(function() return {"Window", mainMenuName} end))
        registerAction("Menu Items.Help.Final Cut Pro X Help", makeMenuItemHandler(function() return {"Help", "Final Cut Pro X Help"} end))
        registerAction("Menu Items.Help.What's New in Final Cut Pro X", makeMenuItemHandler(function() return {"Help", "What's New in Final Cut Pro X"} end))
        registerAction("Menu Items.Help.Keyboard Shortcuts", makeMenuItemHandler(function() return {"Help", "Keyboard Shortcuts"} end))
        registerAction("Menu Items.Help.Logic Effects Reference", makeMenuItemHandler(function() return {"Help", "Logic Effects Reference"} end))
        registerAction("Menu Items.Help.Supported Cameras", makeMenuItemHandler(function() return {"Help", "Supported Cameras"} end))
        registerAction("Menu Items.Help.Apps for Final Cut Pro X", makeMenuItemHandler(function() return {"Help", "Apps for Final Cut Pro X"} end))
        registerAction("Menu Items.Help.Service and Support", makeMenuItemHandler(function() return {"Help", "Service and Support"} end))
        registerAction("Menu Items.Help.Gather App Diagnostics", makeMenuItemHandler(function() return {"Help", "Gather App Diagnostics"} end))
    end

    --------------------------------------------------------------------------------
    -- Command Set Shortcuts:
    --------------------------------------------------------------------------------
    do
        registerAction("Command Set Shortcuts.Playback/Navigation.Next Marker", makeShortcutHandler(function() return "NextMarker" end))
        registerAction("Command Set Shortcuts.General.Send iTMS Package to Compressor", makeShortcutHandler(function() return "SendITMSPackageToCompressor" end))
        registerAction("Command Set Shortcuts.General.Start/Stop Voiceover Recording", makeShortcutHandler(function() return "ToggleVoiceOverRecording" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 7", makeShortcutHandler(function() return "AddKeywordGroup7" end))
        registerAction("Command Set Shortcuts.Editing.Deselect All", makeShortcutHandler(function() return "DeselectAll" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Timeline Index", makeShortcutHandler(function() return "ToggleDataList" end))
        registerAction("Command Set Shortcuts.Effects.Apply Color Correction from Two Clips Back", makeShortcutHandler(function() return "SetCorrectionFromEdit-Back-2" end))
        registerAction("Command Set Shortcuts.View.Increase Clip Height", makeShortcutHandler(function() return "IncreaseThumbnailSize" end))
        registerAction("Command Set Shortcuts.Effects.Save Frame", makeShortcutHandler(function() return "AddCompareFrame" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Next Clip", makeShortcutHandler(function() return "NextClip" end))
        registerAction("Command Set Shortcuts.Editing.Select Left and Right Video Edit Edges", makeShortcutHandler(function() return "SelectLeftRightEdgeVideo" end))
        registerAction("Command Set Shortcuts.Editing.Overwrite", makeShortcutHandler(function() return "OverwriteWithSelectedMedia" end))
        registerAction("Command Set Shortcuts.Editing.Select Previous Audio Angle", makeShortcutHandler(function() return "SelectPreviousAudioAngle" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Increase Field of View", makeShortcutHandler(function() return "IncreaseFOV" end))
        registerAction("Command Set Shortcuts.Editing.Overwrite to Primary Storyline", makeShortcutHandler(function() return "CollapseToSpine" end))
        registerAction("Command Set Shortcuts.Tools.Distort Tool", makeShortcutHandler(function() return "SelectDistortTool" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Forward", makeShortcutHandler(function() return "JogForward" end))
        registerAction("Command Set Shortcuts.Marking.Reject", makeShortcutHandler(function() return "Reject" end))
        registerAction("Command Set Shortcuts.Editing.Connect Video only to Primary Storyline - Backtimed", makeShortcutHandler(function() return "AnchorWithSelectedMediaVideoBacktimed" end))
        registerAction("Command Set Shortcuts.Effects.Toggle Effects on/off", makeShortcutHandler(function() return "ToggleSelectedEffectsOff" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 15", makeShortcutHandler(function() return "SwitchAngle15" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 2", makeShortcutHandler(function() return "PlayRate2X" end))
        registerAction("Command Set Shortcuts.Editing.Audition: Duplicate as Audition", makeShortcutHandler(function() return "NewVariantFromCurrentInSelection" end))
        registerAction("Command Set Shortcuts.General.Show/Hide Custom Overlay", makeShortcutHandler(function() return "SetDisplayCustomOverlay" end))
        registerAction("Command Set Shortcuts.Marking.Add Chapter Marker", makeShortcutHandler(function() return "AddChapterMarker" end))
        registerAction("Command Set Shortcuts.Effects.Toggle Color Mask Type", makeShortcutHandler(function() return "ToggleColorMaskModel" end))
        registerAction("Command Set Shortcuts.Marking.Delete Marker", makeShortcutHandler(function() return "DeleteMarker" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 7", makeShortcutHandler(function() return "SwitchAngle07" end))
        registerAction("Command Set Shortcuts.Editing.Select Right Audio Edge", makeShortcutHandler(function() return "SelectRightEdgeAudio" end))
        registerAction("Command Set Shortcuts.Editing.Cut", makeShortcutHandler(function() return "Cut" end))
        registerAction("Command Set Shortcuts.Editing.Solo", makeShortcutHandler(function() return "Solo" end))
        registerAction("Command Set Shortcuts.General.Import Media", makeShortcutHandler(function() return "Import" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Output to VR Headset", makeShortcutHandler(function() return "ToggleHMD" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 1", makeShortcutHandler(function() return "PlayRate1X" end))
        registerAction("Command Set Shortcuts.Editing.Copy", makeShortcutHandler(function() return "Copy" end))
        registerAction("Command Set Shortcuts.Editing.Extend Edit", makeShortcutHandler(function() return "ExtendEdit" end))
        registerAction("Command Set Shortcuts.Editing.Audition: Add to Audition", makeShortcutHandler(function() return "AddToAudition" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 3", makeShortcutHandler(function() return "AddKeywordGroup3" end))
        registerAction("Command Set Shortcuts.Windows.Project Timecode", makeShortcutHandler(function() return "GoToProjectTimecodeView" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Edit", makeShortcutHandler(function() return "NextEdit" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Speed Ramp from Zero", makeShortcutHandler(function() return "RetimeSpeedRampFromZero" end))
        registerAction("Command Set Shortcuts.General.Blade Speed", makeShortcutHandler(function() return "RetimeBladeSpeed" end))
        registerAction("Command Set Shortcuts.Marking.Delete Markers In Selection", makeShortcutHandler(function() return "DeleteMarkersInSelection" end))
        registerAction("Command Set Shortcuts.Windows.Revert to Original Layout", makeShortcutHandler(function() return "ResetWindowLayout" end))
        registerAction("Command Set Shortcuts.View.Clip Appearance: Filmstrips Only", makeShortcutHandler(function() return "ClipAppearanceVideoOnly" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Reset Current Effect Pane", makeShortcutHandler(function() return "ColorBoard-ResetPucksOnCurrentBoard" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Up Many", makeShortcutHandler(function() return "NudgeUpMany" end))
        registerAction("Command Set Shortcuts.Editing.Source Media: Audio & Video", makeShortcutHandler(function() return "AVEditModeBoth" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 9", makeShortcutHandler(function() return "CutSwitchAngle09" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 4", makeShortcutHandler(function() return "CutSwitchAngle04" end))
        registerAction("Command Set Shortcuts.General.Toggle Audio Fade In", makeShortcutHandler(function() return "ToggleFadeInAudio" end))
        registerAction("Command Set Shortcuts.View.Clip Appearance: Waveforms and Filmstrips", makeShortcutHandler(function() return "ClipAppearance5050" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Exit Full Screen", makeShortcutHandler(function() return "ExitFullScreen" end))
        registerAction("Command Set Shortcuts.Editing.Select Below", makeShortcutHandler(function() return "SelectLowerItem" end))
        registerAction("Command Set Shortcuts.Editing.Finalize Audition", makeShortcutHandler(function() return "FinalizePick" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Down Many", makeShortcutHandler(function() return "NudgeDownMany" end))
        registerAction("Command Set Shortcuts.General.Sort By Name", makeShortcutHandler(function() return "SortByName" end))
        registerAction("Command Set Shortcuts.Windows.Show Vectorscope", makeShortcutHandler(function() return "ToggleVectorscope" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Selection", makeShortcutHandler(function() return "PlaySelected" end))
        registerAction("Command Set Shortcuts.General.Paste Keyframes", makeShortcutHandler(function() return "PasteKeyframes" end))
        registerAction("Command Set Shortcuts.General.Export Captions…", makeShortcutHandler(function() return "ExportCaptions" end))
        registerAction("Command Set Shortcuts.Effects.Apply Color Correction from Previous Clip", makeShortcutHandler(function() return "SetCorrectionFromEdit-Back-1" end))
        registerAction("Command Set Shortcuts.Editing.Insert Audio only", makeShortcutHandler(function() return "InsertMediaAudio" end))
        registerAction("Command Set Shortcuts.General.Copy Keyframes", makeShortcutHandler(function() return "CopyKeyframes" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Right Many", makeShortcutHandler(function() return "NudgeRightMany" end))
        registerAction("Command Set Shortcuts.Editing.Align Audio to Video", makeShortcutHandler(function() return "AlignAudioToVideo" end))
        registerAction("Command Set Shortcuts.Editing.Insert Gap", makeShortcutHandler(function() return "InsertGap" end))
        registerAction("Command Set Shortcuts.View.Toggle Inspector Height", makeShortcutHandler(function() return "ToggleFullheightInspector" end))
        registerAction("Command Set Shortcuts.Editing.New Multicam Clip…", makeShortcutHandler(function() return "CreateMultiAngleClip" end))
        registerAction("Command Set Shortcuts.Editing.Sync Angle to Monitoring Angle", makeShortcutHandler(function() return "AudioFineSyncMultiAngleAngle" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Nudge Control Down", makeShortcutHandler(function() return "ColorBoard-NudgePuckDown" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Negative Timecode Entry", makeShortcutHandler(function() return "ShowTimecodeEntryMinusDelta" end))
        registerAction("Command Set Shortcuts.Windows.View Tags in Timeline Index", makeShortcutHandler(function() return "SwitchToTagsTabInTimelineIndex" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Left Eye Only", makeShortcutHandler(function() return "360LeftEyeOnly" end))
        registerAction("Command Set Shortcuts.Editing.New Compound Clip…", makeShortcutHandler(function() return "CreateCompoundClip" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 4", makeShortcutHandler(function() return "PlayRate4X" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Difference", makeShortcutHandler(function() return "360Difference" end))
        registerAction("Command Set Shortcuts.Editing.Overwrite Video only - Backtimed", makeShortcutHandler(function() return "OverwriteWithSelectedMediaVideoBacktimed" end))
        registerAction("Command Set Shortcuts.Effects.Color Board: Switch to the Color Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToColorTab" end))
        registerAction("Command Set Shortcuts.View.Clip Appearance: Waveforms Only", makeShortcutHandler(function() return "ClipAppearanceAudioOnly" end))
        registerAction("Command Set Shortcuts.Effects.Retime Video Quality: Optical Flow", makeShortcutHandler(function() return "RetimeVideoQualityOpticalFlow" end))
        registerAction("Command Set Shortcuts.General.Nudge Marker Right", makeShortcutHandler(function() return "NudgeMarkerRight" end))
        registerAction("Command Set Shortcuts.View.Clip Appearance: Decrease Waveform Size", makeShortcutHandler(function() return "ClipAppearanceAudioSmaller" end))
        registerAction("Command Set Shortcuts.Marking.New Keyword Collection", makeShortcutHandler(function() return "NewKeyword" end))
        registerAction("Command Set Shortcuts.Editing.Append to Storyline", makeShortcutHandler(function() return "AppendWithSelectedMedia" end))
        registerAction("Command Set Shortcuts.General.Save Audio Effect Preset", makeShortcutHandler(function() return "SaveAudioEffectPreset" end))
        registerAction("Command Set Shortcuts.Editing.Next Pick", makeShortcutHandler(function() return "SelectNextVariant" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Bank", makeShortcutHandler(function() return "SelectNextAngleBank" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Previous Clip", makeShortcutHandler(function() return "PreviousClip" end))
        registerAction("Command Set Shortcuts.Editing.Delete Selection Only", makeShortcutHandler(function() return "DeleteSelectionOnly" end))
        registerAction("Command Set Shortcuts.Editing.Select Next Audio Angle", makeShortcutHandler(function() return "SelectNextAudioAngle" end))
        registerAction("Command Set Shortcuts.Editing.Replace From End", makeShortcutHandler(function() return "ReplaceWithSelectedMediaFromEnd" end))
        registerAction("Command Set Shortcuts.Organization.Reveal Project in Browser", makeShortcutHandler(function() return "RevealProjectInEventsBrowser" end))
        registerAction("Command Set Shortcuts.General.Show/Hide Video Scopes in the Event Viewer", makeShortcutHandler(function() return "ToggleVideoScopesEventViewer" end))
        registerAction("Command Set Shortcuts.Effects.Add Color Mask", makeShortcutHandler(function() return "AddColorMask" end))
        registerAction("Command Set Shortcuts.Editing.Source Media: Video Only", makeShortcutHandler(function() return "AVEditModeVideo" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Copy Timecode", makeShortcutHandler(function() return "CopyTimecode" end))
        registerAction("Command Set Shortcuts.Editing.Replace", makeShortcutHandler(function() return "ReplaceWithSelectedMediaWhole" end))
        registerAction("Command Set Shortcuts.Marking.Clear Range Start", makeShortcutHandler(function() return "ClearSelectionStart" end))
        registerAction("Command Set Shortcuts.Marking.Range Selection Tool", makeShortcutHandler(function() return "SelectToolRangeSelection" end))
        registerAction("Command Set Shortcuts.Effects.Add Default Transition", makeShortcutHandler(function() return "AddTransition" end))
        registerAction("Command Set Shortcuts.Editing.Paste as Connected", makeShortcutHandler(function() return "PasteAsConnected" end))
        registerAction("Command Set Shortcuts.General.New Project", makeShortcutHandler(function() return "NewProject" end))
        registerAction("Command Set Shortcuts.General.Sort By Date", makeShortcutHandler(function() return "SortByDate" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Roll Counterclockwise", makeShortcutHandler(function() return "RollCounterclockwise" end))
        registerAction("Command Set Shortcuts.Editing.Expand/Collapse Audio Components", makeShortcutHandler(function() return "ToggleAudioComponents" end))
        registerAction("Command Set Shortcuts.Windows.View Captions in Timeline Index", makeShortcutHandler(function() return "SwitchToCaptionsTabInTimelineIndex" end))
        registerAction("Command Set Shortcuts.Share.Export Using Default Share Destination…", makeShortcutHandler(function() return "ShareDefaultDestination" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Nudge Control Right", makeShortcutHandler(function() return "ColorBoard-NudgePuckRight" end))
        registerAction("Command Set Shortcuts.Organization.New Event…", makeShortcutHandler(function() return "NewEvent" end))
        registerAction("Command Set Shortcuts.Editing.Delete", makeShortcutHandler(function() return "Delete" end))
        registerAction("Command Set Shortcuts.Effects.Remove Effects", makeShortcutHandler(function() return "RemoveEffects" end))
        registerAction("Command Set Shortcuts.Editing.Connect Audio only to Primary Storyline", makeShortcutHandler(function() return "AnchorWithSelectedMediaAudio" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Fast 4x", makeShortcutHandler(function() return "RetimeFast4x" end))
        registerAction("Command Set Shortcuts.General.Render Selection", makeShortcutHandler(function() return "RenderSelection" end))
        registerAction("Command Set Shortcuts.General.Delete Keyframes", makeShortcutHandler(function() return "DeleteKeyframes" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 9", makeShortcutHandler(function() return "SwitchAngle09" end))
        registerAction("Command Set Shortcuts.View.Zoom to Samples", makeShortcutHandler(function() return "ZoomToSubframes" end))
        registerAction("Command Set Shortcuts.View.View All Color Channels", makeShortcutHandler(function() return "ShowColorChannelsAll" end))
        registerAction("Command Set Shortcuts.Windows.Organize", makeShortcutHandler(function() return "OrganizeLayout" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 13", makeShortcutHandler(function() return "SwitchAngle13" end))
        registerAction("Command Set Shortcuts.Effects.Connect Default Title", makeShortcutHandler(function() return "AddBasicTitle" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 12", makeShortcutHandler(function() return "SwitchAngle12" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 1", makeShortcutHandler(function() return "AddKeywordGroup1" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Reverse Clip", makeShortcutHandler(function() return "RetimeReverseClip" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 4", makeShortcutHandler(function() return "SwitchAngle04" end))
        registerAction("Command Set Shortcuts.Marking.Show/Hide Marked Ranges", makeShortcutHandler(function() return "ShowMarkedRanges" end))
        registerAction("Command Set Shortcuts.General.Hide Rejected", makeShortcutHandler(function() return "HideRejected" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Copy Playhead Timecode", makeShortcutHandler(function() return "CopyPlayheadTimecode" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Video Scopes", makeShortcutHandler(function() return "ToggleVideoScopes" end))
        registerAction("Command Set Shortcuts.Editing.Extend Selection Down", makeShortcutHandler(function() return "ExtendDown" end))
        registerAction("Command Set Shortcuts.Application.Minimize", makeShortcutHandler(function() return "Minimize" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Reset", makeShortcutHandler(function() return "RetimeReset" end))
        registerAction("Command Set Shortcuts.Tools.Select Tool", makeShortcutHandler(function() return "SelectToolArrowOrRangeSelection" end))
        registerAction("Command Set Shortcuts.View.Zoom Out", makeShortcutHandler(function() return "ZoomOut" end))
        registerAction("Command Set Shortcuts.Effects.Enable/Disable Balance Color", makeShortcutHandler(function() return "ToggleColorBalance" end))
        registerAction("Command Set Shortcuts.General.Connect with Selected Media Video Backtimed", makeShortcutHandler(function() return "ConnectWithSelectedMediaVideoBacktimed" end))
        registerAction("Command Set Shortcuts.General.Hide Keyword Editor", makeShortcutHandler(function() return "HideKeywordEditor" end))
        registerAction("Command Set Shortcuts.View.View Red Color Channel", makeShortcutHandler(function() return "ShowColorChannelsRed" end))
        registerAction("Command Set Shortcuts.Effects.Color Board: Switch to the Saturation Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToSaturationTab" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 6", makeShortcutHandler(function() return "AddKeywordGroup6" end))
        registerAction("Command Set Shortcuts.Tools.Blade Tool", makeShortcutHandler(function() return "SelectToolBlade" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Cut/Switch Multicam Audio and Video", makeShortcutHandler(function() return "MultiAngleEditStyleAudioVideo" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Timeline", makeShortcutHandler(function() return "ToggleTimeline" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Events on Second Display", makeShortcutHandler(function() return "ToggleFullScreenEvents" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Select Previous Effect", makeShortcutHandler(function() return "ColorBoard-PreviousColorEffect" end))
        registerAction("Command Set Shortcuts.Editing.Resolve Overlaps", makeShortcutHandler(function() return "ResolveCaptionOverlaps" end))
        registerAction("Command Set Shortcuts.Effects.Toggle View Mask On/Off", makeShortcutHandler(function() return "ToggleEffectViewMask" end))
        registerAction("Command Set Shortcuts.General.Edit Next Marker", makeShortcutHandler(function() return "EditNextMarker" end))
        registerAction("Command Set Shortcuts.View.Show One Frame per Filmstrip", makeShortcutHandler(function() return "ShowOneFramePerFilmstrip" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Event Viewer", makeShortcutHandler(function() return "ToggleEventViewer" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Decrease Field of View", makeShortcutHandler(function() return "DecreaseFOV" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 7", makeShortcutHandler(function() return "CutSwitchAngle07" end))
        registerAction("Command Set Shortcuts.Editing.Paste Insert at Playhead", makeShortcutHandler(function() return "Paste" end))
        registerAction("Command Set Shortcuts.Editing.Open Audition", makeShortcutHandler(function() return "ToggleStackHUD" end))
        registerAction("Command Set Shortcuts.Effects.Toggle Color Correction Effects on/off", makeShortcutHandler(function() return "ColorBoard-ToggleAllCorrection" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 2", makeShortcutHandler(function() return "SwitchAngle02" end))
        registerAction("Command Set Shortcuts.Editing.Select Left Audio Edge", makeShortcutHandler(function() return "SelectLeftEdgeAudio" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Keyword Editor", makeShortcutHandler(function() return "ToggleKeywordEditor" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 4", makeShortcutHandler(function() return "AddKeywordGroup4" end))
        registerAction("Command Set Shortcuts.Effects.Retime Video Quality: Frame Blending", makeShortcutHandler(function() return "RetimeVideoQualityFrameBlending" end))
        registerAction("Command Set Shortcuts.View.Toggle Filmstrip/List View", makeShortcutHandler(function() return "ToggleEventsAsFilmstripAndList" end))
        registerAction("Command Set Shortcuts.Windows.Go To Titles and Generators", makeShortcutHandler(function() return "ToggleEventContentBrowser" end))
        registerAction("Command Set Shortcuts.View.View Blue Color Channel", makeShortcutHandler(function() return "ShowColorChannelsBlue" end))
        registerAction("Command Set Shortcuts.Marking.Edit Caption", makeShortcutHandler(function() return "EditCaption" end))
        registerAction("Command Set Shortcuts.Editing.Blade", makeShortcutHandler(function() return "BladeAtPlayhead" end))
        registerAction("Command Set Shortcuts.General.Connect with Selected Media Audio Backtimed", makeShortcutHandler(function() return "ConnectWithSelectedMediaAudioBacktimed" end))
        registerAction("Command Set Shortcuts.Editing.Create Storyline", makeShortcutHandler(function() return "CreateConnectedStoryline" end))
        registerAction("Command Set Shortcuts.General.Sort Ascending", makeShortcutHandler(function() return "SortAscending" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Rewind 2x", makeShortcutHandler(function() return "RetimeRewind2x" end))
        registerAction("Command Set Shortcuts.General.Add Custom Name…", makeShortcutHandler(function() return "AddNewNamePreset" end))
        registerAction("Command Set Shortcuts.General.Favorites", makeShortcutHandler(function() return "ShowFavorites" end))
        registerAction("Command Set Shortcuts.General.Connect with Selected Media Video", makeShortcutHandler(function() return "ConnectWithSelectedMediaVideo" end))
        registerAction("Command Set Shortcuts.General.Connect with Selected Media Audio", makeShortcutHandler(function() return "ConnectWithSelectedMediaAudio" end))
        registerAction("Command Set Shortcuts.Editing.Connect Video only to Primary Storyline", makeShortcutHandler(function() return "AnchorWithSelectedMediaVideo" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Slow 50%", makeShortcutHandler(function() return "RetimeSlow50" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 6", makeShortcutHandler(function() return "CutSwitchAngle06" end))
        registerAction("Command Set Shortcuts.General.Play From Beginning", makeShortcutHandler(function() return "PlayFromStart" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Effects Browser", makeShortcutHandler(function() return "ToggleMediaEffectsBrowser" end))
        registerAction("Command Set Shortcuts.Marking.Extract Captions", makeShortcutHandler(function() return "ExtractCaptionsFromClip" end))
        registerAction("Command Set Shortcuts.Marking.Set Range Start", makeShortcutHandler(function() return "SetSelectionStart" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 2", makeShortcutHandler(function() return "AddKeywordGroup2" end))
        registerAction("Command Set Shortcuts.View.Zoom to Fit", makeShortcutHandler(function() return "ZoomToFit" end))
        registerAction("Command Set Shortcuts.General.Import iMovie iOS Projects", makeShortcutHandler(function() return "ImportiOSProjects" end))
        registerAction("Command Set Shortcuts.General.All Clips", makeShortcutHandler(function() return "AllClips" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Pan Left", makeShortcutHandler(function() return "PanLeft" end))
        registerAction("Command Set Shortcuts.Marking.Roles: Apply Dialogue Role", makeShortcutHandler(function() return "SetRoleDialogue" end))
        registerAction("Command Set Shortcuts.General.Reimport from Camera/Archive…", makeShortcutHandler(function() return "ReImportFilesFromCamera" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Frame", makeShortcutHandler(function() return "JumpToNextFrame" end))
        registerAction("Command Set Shortcuts.Marking.Add Marker and Modify", makeShortcutHandler(function() return "AddAndEditMarker" end))
        registerAction("Command Set Shortcuts.Marking.Add Marker", makeShortcutHandler(function() return "AddMarker" end))
        registerAction("Command Set Shortcuts.Editing.Select Left and Right Edit Edges", makeShortcutHandler(function() return "SelectLeftRightEdge" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 9", makeShortcutHandler(function() return "AddKeywordGroup9" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Pan Right", makeShortcutHandler(function() return "PanRight" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Field", makeShortcutHandler(function() return "JumpToNextField" end))
        registerAction("Command Set Shortcuts.Editing.Add to Soloed Clips", makeShortcutHandler(function() return "AddToSoloed" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Reset Field of View", makeShortcutHandler(function() return "ResetFieldOfView" end))
        registerAction("Command Set Shortcuts.General.Previous Keyframe", makeShortcutHandler(function() return "PreviousKeyframe" end))
        registerAction("Command Set Shortcuts.Editing.Trim to Selection", makeShortcutHandler(function() return "TrimSelection" end))
        registerAction("Command Set Shortcuts.General.Detach Audio", makeShortcutHandler(function() return "DetachAudio" end))
        registerAction("Command Set Shortcuts.View.Zoom In", makeShortcutHandler(function() return "ZoomIn" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 15", makeShortcutHandler(function() return "CutSwitchAngle15" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Reset Angle", makeShortcutHandler(function() return "ResetPointOfView" end))
        registerAction("Command Set Shortcuts.View.Show More Filmstrip Frames", makeShortcutHandler(function() return "ShowMoreFilmstripFrames" end))
        registerAction("Command Set Shortcuts.Organization.Edit Smart Collection", makeShortcutHandler(function() return "EditSmartCollection" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go Forward 10 Frames", makeShortcutHandler(function() return "JumpForward10Frames" end))
        registerAction("Command Set Shortcuts.Editing.Show/Hide Precision Editor", makeShortcutHandler(function() return "TogglePrecisionEditor" end))
        registerAction("Command Set Shortcuts.Editing.Overwrite - Backtimed", makeShortcutHandler(function() return "OverwriteWithSelectedMediaBacktimed" end))
        registerAction("Command Set Shortcuts.Editing.Previous Pick", makeShortcutHandler(function() return "SelectPreviousVariant" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -1", makeShortcutHandler(function() return "PlayRateMinus1X" end))
        registerAction("Command Set Shortcuts.General.Clear Selected Ranges", makeShortcutHandler(function() return "ClearSelection" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Speed Ramp to Zero", makeShortcutHandler(function() return "RetimeSpeedRampToZero" end))
        registerAction("Command Set Shortcuts.Editing.Select Above", makeShortcutHandler(function() return "SelectUpperItem" end))
        registerAction("Command Set Shortcuts.Editing.Audition: Replace and Add to Audition", makeShortcutHandler(function() return "ReplaceAndAddToAudition" end))
        registerAction("Command Set Shortcuts.Editing.Snapping", makeShortcutHandler(function() return "ToggleSnapping" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Reset All Controls", makeShortcutHandler(function() return "ColorBoard-ResetAllPucks" end))
        registerAction("Command Set Shortcuts.Application.Hide Other Applications", makeShortcutHandler(function() return "HideOtherApplications" end))
        registerAction("Command Set Shortcuts.General.Show/Hide All Image Content", makeShortcutHandler(function() return "ToggleTransformOverscan" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Positive Timecode Entry", makeShortcutHandler(function() return "ShowTimecodeEntryPlusDelta" end))
        registerAction("Command Set Shortcuts.General.Snapshot Project", makeShortcutHandler(function() return "SnapshotProject" end))
        registerAction("Command Set Shortcuts.General.Rejected", makeShortcutHandler(function() return "ShowRejected" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 6", makeShortcutHandler(function() return "SwitchAngle06" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play From Beginning of Clip", makeShortcutHandler(function() return "PlayFromBeginningOfClip" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Bank", makeShortcutHandler(function() return "SelectPreviousAngleBank" end))
        registerAction("Command Set Shortcuts.Editing.Insert Default Generator", makeShortcutHandler(function() return "InsertPlaceholder" end))
        registerAction("Command Set Shortcuts.Tools.Zoom Tool", makeShortcutHandler(function() return "SelectToolZoom" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Audio Subframe Right Many", makeShortcutHandler(function() return "NudgeRightAudioMany" end))
        registerAction("Command Set Shortcuts.Editing.Overwrite Video only", makeShortcutHandler(function() return "OverwriteWithSelectedMediaVideo" end))
        registerAction("Command Set Shortcuts.Marking.New Smart Collection", makeShortcutHandler(function() return "NewSmartCollection" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Up", makeShortcutHandler(function() return "Up" end))
        registerAction("Command Set Shortcuts.Application.Undo Changes", makeShortcutHandler(function() return "UndoChanges" end))
        registerAction("Command Set Shortcuts.Marking.Roles: Apply Effects Role", makeShortcutHandler(function() return "SetRoleEffects" end))
        registerAction("Command Set Shortcuts.General.Save Color Effect Preset", makeShortcutHandler(function() return "SaveColorEffectPreset" end))
        registerAction("Command Set Shortcuts.General.Show Both Fields", makeShortcutHandler(function() return "ShowBothFields" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go Back 10 Frames", makeShortcutHandler(function() return "JumpBackward10Frames" end))
        registerAction("Command Set Shortcuts.Editing.Extend Selection to Previous Clip", makeShortcutHandler(function() return "ExtendPreviousItem" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Audio Subframe Left", makeShortcutHandler(function() return "NudgeLeftAudio" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Anaglyph Color", makeShortcutHandler(function() return "360AnaglyphColor" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 8", makeShortcutHandler(function() return "PlayRate8X" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Around", makeShortcutHandler(function() return "PlayAroundCurrentFrame" end))
        registerAction("Command Set Shortcuts.Editing.Open Clip", makeShortcutHandler(function() return "OpenInTimeline" end))
        registerAction("Command Set Shortcuts.General.Show/Hide Angles in the Event Viewer", makeShortcutHandler(function() return "ShowMultiangleEventViewer" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 16", makeShortcutHandler(function() return "CutSwitchAngle16" end))
        registerAction("Command Set Shortcuts.Effects.Add Shape Mask", makeShortcutHandler(function() return "AddShapeMask" end))
        registerAction("Command Set Shortcuts.Editing.Reset Volume (0db)", makeShortcutHandler(function() return "VolumeZero" end))
        registerAction("Command Set Shortcuts.Effects.Show/Hide Comparison Viewer", makeShortcutHandler(function() return "ToggleCompareViewer" end))
        registerAction("Command Set Shortcuts.Effects.Add Color Board Effect", makeShortcutHandler(function() return "AddColorBoardEffect" end))
        registerAction("Command Set Shortcuts.Editing.Join Clips or Captions", makeShortcutHandler(function() return "JoinSelection" end))
        registerAction("Command Set Shortcuts.Application.Hide Application", makeShortcutHandler(function() return "HideApplication" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 10", makeShortcutHandler(function() return "CutSwitchAngle10" end))
        registerAction("Command Set Shortcuts.Effects.Switch Focus between Comparison Viewer and Main Viewer", makeShortcutHandler(function() return "ToggleCompareViewerFocus" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -16", makeShortcutHandler(function() return "PlayRateMinus16X" end))
        registerAction("Command Set Shortcuts.Application.Preferences", makeShortcutHandler(function() return "ShowPreferences" end))
        registerAction("Command Set Shortcuts.Windows.Go to Color Inspector", makeShortcutHandler(function() return "GoToColorBoard" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide 360° Viewer", makeShortcutHandler(function() return "Toggle360Viewer" end))
        registerAction("Command Set Shortcuts.General.Sync To Monitoring Angle…", makeShortcutHandler(function() return "ToggleSyncTo" end))
        registerAction("Command Set Shortcuts.General.Library Properties", makeShortcutHandler(function() return "LibraryProperties" end))
        registerAction("Command Set Shortcuts.General.Reveal Proxy Media in Finder", makeShortcutHandler(function() return "RevealProxyInFinder" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Left Many", makeShortcutHandler(function() return "NudgeLeftMany" end))
        registerAction("Command Set Shortcuts.Marking.Add Caption", makeShortcutHandler(function() return "AddAndEditCaption" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Timeline History Forward", makeShortcutHandler(function() return "SelectNextTimelineItem" end))
        registerAction("Command Set Shortcuts.General.Add Keyframe to Selected Effect in Animation Editor", makeShortcutHandler(function() return "AddKeyframe" end))
        registerAction("Command Set Shortcuts.General.Close Other Timelines", makeShortcutHandler(function() return "CloseOthers" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Go to the Next Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToNextTab" end))
        registerAction("Command Set Shortcuts.Editing.Audition: Duplicate from Original", makeShortcutHandler(function() return "DuplicateFromOriginal" end))
        registerAction("Command Set Shortcuts.Marking.Roles: Apply Music Role", makeShortcutHandler(function() return "SetRoleMusic" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Select Next Control", makeShortcutHandler(function() return "ColorBoard-SelectNextPuck" end))
        registerAction("Command Set Shortcuts.Editing.Extend Selection Up", makeShortcutHandler(function() return "ExtendUp" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Audition: Preview", makeShortcutHandler(function() return "AuditionSelected" end))
        registerAction("Command Set Shortcuts.General.Transcode Media…", makeShortcutHandler(function() return "TranscodeMedia" end))
        registerAction("Command Set Shortcuts.General.Relink Proxy Files…", makeShortcutHandler(function() return "RelinkProxyFiles" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Sidebar", makeShortcutHandler(function() return "ToggleEventsLibrary" end))
        registerAction("Command Set Shortcuts.Editing.Replace From Start", makeShortcutHandler(function() return "ReplaceWithSelectedMediaFromStart" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 16", makeShortcutHandler(function() return "PlayRate16X" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Roll Clockwise", makeShortcutHandler(function() return "RollClockwise" end))
        registerAction("Command Set Shortcuts.Editing.Insert", makeShortcutHandler(function() return "InsertMedia" end))
        registerAction("Command Set Shortcuts.General.Export Final Cut Pro X XML", makeShortcutHandler(function() return "ExportXML" end))
        registerAction("Command Set Shortcuts.General.Auto Enhance Audio", makeShortcutHandler(function() return "EnhanceAudio" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Browser", makeShortcutHandler(function() return "ToggleOrganizer" end))
        registerAction("Command Set Shortcuts.Tools.Hand Tool", makeShortcutHandler(function() return "SelectToolHand" end))
        registerAction("Command Set Shortcuts.Editing.Overwrite Audio only", makeShortcutHandler(function() return "OverwriteWithSelectedMediaAudio" end))
        registerAction("Command Set Shortcuts.Editing.Sync Selection to Monitoring Angle", makeShortcutHandler(function() return "AudioSyncMultiAngleItems" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 8", makeShortcutHandler(function() return "CutSwitchAngle08" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Viewer on Second Display", makeShortcutHandler(function() return "ToggleFullScreenViewer" end))
        registerAction("Command Set Shortcuts.Organization.Analyze and Fix…", makeShortcutHandler(function() return "AnalyzeAndFix" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Beginning", makeShortcutHandler(function() return "JumpToStart" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -32", makeShortcutHandler(function() return "PlayRateMinus32X" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Tilt Up", makeShortcutHandler(function() return "TiltUp" end))
        registerAction("Command Set Shortcuts.Marking.Select Clip Range", makeShortcutHandler(function() return "SelectClip" end))
        registerAction("Command Set Shortcuts.Editing.Append Audio only to Storyline", makeShortcutHandler(function() return "AppendWithSelectedMediaAudio" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Field", makeShortcutHandler(function() return "JumpToPreviousField" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Rewind 4x", makeShortcutHandler(function() return "RetimeRewind4x" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Select Next Effect", makeShortcutHandler(function() return "ColorBoard-NextColorEffect" end))
        registerAction("Command Set Shortcuts.General.Show/Hide 360° Viewer in the Event Viewer", makeShortcutHandler(function() return "Toggle360EventViewer" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 8", makeShortcutHandler(function() return "AddKeywordGroup8" end))
        registerAction("Command Set Shortcuts.General.Consolidate Library/Project/Event/Clip Media", makeShortcutHandler(function() return "ConsolidateFiles" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Down", makeShortcutHandler(function() return "NudgeDown" end))
        registerAction("Command Set Shortcuts.General.Go to End", makeShortcutHandler(function() return "JumpToEnd" end))
        registerAction("Command Set Shortcuts.Editing.Select Next Angle", makeShortcutHandler(function() return "SelectNextAngle" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Audio Meters", makeShortcutHandler(function() return "ToggleAudioMeter" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Reset Selected Control", makeShortcutHandler(function() return "ColorBoard-ResetSelectedPuck" end))
        registerAction("Command Set Shortcuts.Effects.Add Color Curves Effect", makeShortcutHandler(function() return "AddColorCurvesEffect" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Fast 8x", makeShortcutHandler(function() return "RetimeFast8x" end))
        registerAction("Command Set Shortcuts.General.Next Keyframe", makeShortcutHandler(function() return "NextKeyframe" end))
        registerAction("Command Set Shortcuts.Editing.Reference New Parent Clip", makeShortcutHandler(function() return "MakeIndependent" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Paste Timecode", makeShortcutHandler(function() return "PasteTimecode" end))
        registerAction("Command Set Shortcuts.Effects.Add Default Audio Effect", makeShortcutHandler(function() return "AddDefaultAudioEffect" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 13", makeShortcutHandler(function() return "CutSwitchAngle13" end))
        registerAction("Command Set Shortcuts.General.Find and Replace Title Text", makeShortcutHandler(function() return "FindAndReplaceTitleText" end))
        registerAction("Command Set Shortcuts.Windows.Previous Inspector Tab", makeShortcutHandler(function() return "SelectPreviousTab" end))
        registerAction("Command Set Shortcuts.General.Show/Hide Audio Lanes", makeShortcutHandler(function() return "AllAudioLanes" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 1", makeShortcutHandler(function() return "CutSwitchAngle01" end))
        registerAction("Command Set Shortcuts.General.Pick the next object in the Audition", makeShortcutHandler(function() return "SelectNextPick" end))
        registerAction("Command Set Shortcuts.Effects.Smart Conform", makeShortcutHandler(function() return "AutoReframe" end))
        registerAction("Command Set Shortcuts.General.Show Unused Media Only", makeShortcutHandler(function() return "FilterUnusedMedia" end))
        registerAction("Command Set Shortcuts.General.Sort Descending", makeShortcutHandler(function() return "SortDescending" end))
        registerAction("Command Set Shortcuts.Effects.Solo Animation", makeShortcutHandler(function() return "CollapseAnimations" end))
        registerAction("Command Set Shortcuts.Editing.Select Next Video Angle", makeShortcutHandler(function() return "SelectNextVideoAngle" end))
        registerAction("Command Set Shortcuts.General.Save Video Effect Preset", makeShortcutHandler(function() return "SaveVideoEffectPreset" end))
        registerAction("Command Set Shortcuts.General.Paste as Connected", makeShortcutHandler(function() return "PasteConnected" end))
        registerAction("Command Set Shortcuts.General.Close Project", makeShortcutHandler(function() return "CloseProject" end))
        registerAction("Command Set Shortcuts.General.Better Playback Quality", makeShortcutHandler(function() return "PlaybackBetterQuality" end))
        registerAction("Command Set Shortcuts.General.Remove Analysis Keywords", makeShortcutHandler(function() return "RemoveAllAnalysisKeywordsFromSelection" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 32", makeShortcutHandler(function() return "PlayRate32X" end))
        registerAction("Command Set Shortcuts.Editing.Override Connections", makeShortcutHandler(function() return "ToggleOverrideConnections" end))
        registerAction("Command Set Shortcuts.Editing.Append Video only to Storyline", makeShortcutHandler(function() return "AppendWithSelectedMediaVideo" end))
        registerAction("Command Set Shortcuts.General.Color Correction: Switch Between Inside/Outside Masks", makeShortcutHandler(function() return "ColorBoard-ToggleInsideColorMask" end))
        registerAction("Command Set Shortcuts.Effects.Add Default Video Effect", makeShortcutHandler(function() return "AddDefaultVideoEffect" end))
        registerAction("Command Set Shortcuts.Editing.Blade All", makeShortcutHandler(function() return "BladeAll" end))
        registerAction("Command Set Shortcuts.Editing.Overwrite Audio only - Backtimed", makeShortcutHandler(function() return "OverwriteWithSelectedMediaAudioBacktimed" end))
        registerAction("Command Set Shortcuts.General.Apply Audio Fades", makeShortcutHandler(function() return "ApplyAudioFades" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Inspector", makeShortcutHandler(function() return "ToggleInspector" end))
        registerAction("Command Set Shortcuts.General.Crossfade", makeShortcutHandler(function() return "ApplyAudioCrossFadesToAlignedClips" end))
        registerAction("Command Set Shortcuts.Editing.Select Right Edge", makeShortcutHandler(function() return "SelectRightEdge" end))
        registerAction("Command Set Shortcuts.General.Close Library", makeShortcutHandler(function() return "CloseLibrary" end))
        registerAction("Command Set Shortcuts.General.Better Playback Performance", makeShortcutHandler(function() return "PlaybackBetterPerformance" end))
        registerAction("Command Set Shortcuts.Editing.Select Left Video Edge", makeShortcutHandler(function() return "SelectLeftEdgeVideo" end))
        registerAction("Command Set Shortcuts.General.Go to Comparison Viewer", makeShortcutHandler(function() return "GoToCompareViewer" end))
        registerAction("Command Set Shortcuts.Effects.Apply Color Correction from Three Clips Back", makeShortcutHandler(function() return "SetCorrectionFromEdit-Back-3" end))
        registerAction("Command Set Shortcuts.Effects.Match Color…", makeShortcutHandler(function() return "ToggleMatchColor" end))
        registerAction("Command Set Shortcuts.Tools.Trim Tool", makeShortcutHandler(function() return "SelectToolTrim" end))
        registerAction("Command Set Shortcuts.General.Go to Event Viewer", makeShortcutHandler(function() return "GoToEventViewer" end))
        registerAction("Command Set Shortcuts.Organization.New Folder", makeShortcutHandler(function() return "NewFolder" end))
        registerAction("Command Set Shortcuts.Windows.Background Tasks", makeShortcutHandler(function() return "GoToBackgroundTasks" end))
        registerAction("Command Set Shortcuts.Editing.Select Previous Angle", makeShortcutHandler(function() return "SelectPreviousAngle" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Mirror VR Headset", makeShortcutHandler(function() return "ToggleMirrorHMD" end))
        registerAction("Command Set Shortcuts.General.Remove Audio Fades", makeShortcutHandler(function() return "RemoveAudioFades" end))
        registerAction("Command Set Shortcuts.General.Open Library", makeShortcutHandler(function() return "OpenLibrary" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Nudge Control Left", makeShortcutHandler(function() return "ColorBoard-NudgePuckLeft" end))
        registerAction("Command Set Shortcuts.General.Edit Previous Marker", makeShortcutHandler(function() return "EditPreviousMarker" end))
        registerAction("Command Set Shortcuts.Application.Redo Changes", makeShortcutHandler(function() return "RedoChanges" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Audio Subframe Right", makeShortcutHandler(function() return "NudgeRightAudio" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Anaglyph Monochrome", makeShortcutHandler(function() return "360AnaglyphMono" end))
        registerAction("Command Set Shortcuts.General.Toggle Audio Fade Out", makeShortcutHandler(function() return "ToggleFadeOutAudio" end))
        registerAction("Command Set Shortcuts.Editing.Raise Volume 1 dB", makeShortcutHandler(function() return "VolumeUp" end))
        registerAction("Command Set Shortcuts.Windows.Go To Photos and Audio", makeShortcutHandler(function() return "ToggleEventMediaBrowser" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Edit", makeShortcutHandler(function() return "PreviousEdit" end))
        registerAction("Command Set Shortcuts.General.Custom Speed…", makeShortcutHandler(function() return "RetimeCustomSpeed" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Cut/Switch Multicam Audio Only", makeShortcutHandler(function() return "MultiAngleEditStyleAudio" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Slow 10%", makeShortcutHandler(function() return "RetimeSlow10" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Anaglyph Outline", makeShortcutHandler(function() return "360AnaglyphOutline" end))
        registerAction("Command Set Shortcuts.Editing.Split Captions", makeShortcutHandler(function() return "SplitCaptions" end))
        registerAction("Command Set Shortcuts.General.Render All", makeShortcutHandler(function() return "RenderAll" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Angles", makeShortcutHandler(function() return "ShowMultiangleViewer" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Loop Playback", makeShortcutHandler(function() return "LoopPlayback" end))
        registerAction("Command Set Shortcuts.Editing.Trim To Playhead", makeShortcutHandler(function() return "TrimToPlayhead" end))
        registerAction("Command Set Shortcuts.Editing.Trim Start", makeShortcutHandler(function() return "TrimStart" end))
        registerAction("Command Set Shortcuts.View.View Clip Names", makeShortcutHandler(function() return "ToggleShowTimelineItemTitles" end))
        registerAction("Command Set Shortcuts.Organization.Merge Events", makeShortcutHandler(function() return "MergeEvents" end))
        registerAction("Command Set Shortcuts.Effects.Paste Effects", makeShortcutHandler(function() return "PasteAllAttributes" end))
        registerAction("Command Set Shortcuts.Tools.Crop Tool", makeShortcutHandler(function() return "SelectCropTool" end))
        registerAction("Command Set Shortcuts.General.No Ratings or Keywords", makeShortcutHandler(function() return "NoRatingsOrKeywords" end))
        registerAction("Command Set Shortcuts.View.Show Fewer Filmstrip Frames", makeShortcutHandler(function() return "ShowFewerFilmstripFrames" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 3", makeShortcutHandler(function() return "CutSwitchAngle03" end))
        registerAction("Command Set Shortcuts.Windows.Source Timecode", makeShortcutHandler(function() return "GoToTimecodeView" end))
        registerAction("Command Set Shortcuts.Marking.Roles: Apply Titles Role", makeShortcutHandler(function() return "SetRoleTitles" end))
        registerAction("Command Set Shortcuts.Marking.Set Additional Range Start", makeShortcutHandler(function() return "AddNewSelectionStart" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 14", makeShortcutHandler(function() return "SwitchAngle14" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Create Normal Speed Segment", makeShortcutHandler(function() return "RetimeCreateSegment" end))
        registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 5", makeShortcutHandler(function() return "AddKeywordGroup5" end))
        registerAction("Command Set Shortcuts.General.Cut Keyframes", makeShortcutHandler(function() return "CutKeyframes" end))
        registerAction("Command Set Shortcuts.Effects.Paste Attributes…", makeShortcutHandler(function() return "PasteSomeAttributes" end))
        registerAction("Command Set Shortcuts.Windows.Record Voiceover", makeShortcutHandler(function() return "GoToVoiceoverRecordView" end))
        registerAction("Command Set Shortcuts.View.Clip Appearance: Clip Labels Only", makeShortcutHandler(function() return "ClipAppearanceTitleOnly" end))
        registerAction("Command Set Shortcuts.General.Connect with Selected Media Backtimed", makeShortcutHandler(function() return "ConnectWithSelectedMediaBacktimed" end))
        registerAction("Command Set Shortcuts.Editing.Select Left Edge", makeShortcutHandler(function() return "SelectLeftEdge" end))
        registerAction("Command Set Shortcuts.General.Import Captions…", makeShortcutHandler(function() return "ImportCaptions" end))
        registerAction("Command Set Shortcuts.Application.Quit", makeShortcutHandler(function() return "Quit" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 11", makeShortcutHandler(function() return "CutSwitchAngle11" end))
        registerAction("Command Set Shortcuts.Marking.Favorite", makeShortcutHandler(function() return "Favorite" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Stop", makeShortcutHandler(function() return "Stop" end))
        registerAction("Command Set Shortcuts.Marking.Clear Range End", makeShortcutHandler(function() return "ClearSelectionEnd" end))
        registerAction("Command Set Shortcuts.Organization.Reveal In Browser", makeShortcutHandler(function() return "RevealInEventsBrowser" end))
        registerAction("Command Set Shortcuts.Editing.Create Audition", makeShortcutHandler(function() return "CollapseSelectionIntoVariant" end))
        registerAction("Command Set Shortcuts.Tools.Position Tool", makeShortcutHandler(function() return "SelectToolPlacement" end))
        registerAction("Command Set Shortcuts.View.View Alpha Color Channel", makeShortcutHandler(function() return "ShowColorChannelsAlpha" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Slow 25%", makeShortcutHandler(function() return "RetimeSlow25" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 14", makeShortcutHandler(function() return "CutSwitchAngle14" end))
        registerAction("Command Set Shortcuts.General.Delete Generated Library/Event/Project/Clip Files", makeShortcutHandler(function() return "PurgeRenderFiles" end))
        registerAction("Command Set Shortcuts.General.Replace At Playhead", makeShortcutHandler(function() return "ReplaceWithSelectedMediaAtPlayhead" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Subframe", makeShortcutHandler(function() return "JumpToNextSubframe" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Cut/Switch Multicam Video Only", makeShortcutHandler(function() return "MultiAngleEditStyleVideo" end))
        registerAction("Command Set Shortcuts.General.Adjust Volume Absolute…", makeShortcutHandler(function() return "AdjustVolumeAbsolute" end))
        registerAction("Command Set Shortcuts.Marking.Set Range End", makeShortcutHandler(function() return "SetSelectionEnd" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 11", makeShortcutHandler(function() return "SwitchAngle11" end))
        registerAction("Command Set Shortcuts.Editing.Move Playhead Position", makeShortcutHandler(function() return "ShowTimecodeEntryPlayhead" end))
        registerAction("Command Set Shortcuts.Windows.Go to Viewer", makeShortcutHandler(function() return "GoToViewer" end))
        registerAction("Command Set Shortcuts.Editing.Select All", makeShortcutHandler(function() return "SelectAll" end))
        registerAction("Command Set Shortcuts.View.Decrease Clip Height", makeShortcutHandler(function() return "DecreaseThumbnailSize" end))
        registerAction("Command Set Shortcuts.Effects.Remove Attributes…", makeShortcutHandler(function() return "RemoveAttributes" end))
        registerAction("Command Set Shortcuts.Effects.Copy Effects", makeShortcutHandler(function() return "CopyAttributes" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Previous Marker", makeShortcutHandler(function() return "PreviousMarker" end))
        registerAction("Command Set Shortcuts.General.Update Projects and Events…", makeShortcutHandler(function() return "UpdateProjectsAndEvents" end))
        registerAction("Command Set Shortcuts.General.Pick the previous object in the Audition", makeShortcutHandler(function() return "SelectPreviousPick" end))
        registerAction("Command Set Shortcuts.General.Toggle A/V Output on/off", makeShortcutHandler(function() return "ToggleVideoOut" end))
        registerAction("Command Set Shortcuts.Windows.Default", makeShortcutHandler(function() return "DefaultLayout" end))
        registerAction("Command Set Shortcuts.Windows.Dual Displays", makeShortcutHandler(function() return "DualDisplaysLayout" end))
        registerAction("Command Set Shortcuts.Windows.Go to Timeline", makeShortcutHandler(function() return "GoToTimeline" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 1", makeShortcutHandler(function() return "SwitchAngle01" end))
        registerAction("Command Set Shortcuts.Windows.Show Title/Action Safe Zones", makeShortcutHandler(function() return "SetDisplayBroadcastSafe" end))
        registerAction("Command Set Shortcuts.Editing.Change Duration", makeShortcutHandler(function() return "ShowTimecodeEntryDuration" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Timeline on Second Display", makeShortcutHandler(function() return "ToggleFullScreenTimeline" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Up", makeShortcutHandler(function() return "NudgeUp" end))
        registerAction("Command Set Shortcuts.General.Move to Trash", makeShortcutHandler(function() return "MoveToTrash" end))
        registerAction("Command Set Shortcuts.Effects.Retime Video Quality: Normal", makeShortcutHandler(function() return "RetimeVideoQualityNormal" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Rewind", makeShortcutHandler(function() return "RetimeRewind1x" end))
        registerAction("Command Set Shortcuts.General.Reveal in Finder", makeShortcutHandler(function() return "RevealInFinder" end))
        registerAction("Command Set Shortcuts.General.Clip Skimming", makeShortcutHandler(function() return "ToggleItemSkimming" end))
        registerAction("Command Set Shortcuts.Effects.Automatic Speed", makeShortcutHandler(function() return "RetimeConformSpeed" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 3", makeShortcutHandler(function() return "SwitchAngle03" end))
        registerAction("Command Set Shortcuts.Windows.Color & Effects", makeShortcutHandler(function() return "ColorEffectsLayout" end))
        registerAction("Command Set Shortcuts.General.Edit Custom Names…", makeShortcutHandler(function() return "EditNamePreset" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Reverse", makeShortcutHandler(function() return "PlayReverse" end))
        registerAction("Command Set Shortcuts.Marking.Add ToDo Marker", makeShortcutHandler(function() return "AddToDoMarker" end))
        registerAction("Command Set Shortcuts.General.New Library…", makeShortcutHandler(function() return "NewLibrary" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 2", makeShortcutHandler(function() return "CutSwitchAngle02" end))
        registerAction("Command Set Shortcuts.Marking.Unrate", makeShortcutHandler(function() return "Unfavorite" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 12", makeShortcutHandler(function() return "CutSwitchAngle12" end))
        registerAction("Command Set Shortcuts.Editing.Lower Volume 1 dB", makeShortcutHandler(function() return "VolumeDown" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Instant Replay", makeShortcutHandler(function() return "RetimeInstantReplay" end))
        registerAction("Command Set Shortcuts.Editing.Select Left and Right Audio Edit Edges", makeShortcutHandler(function() return "SelectLeftRightEdgeAudio" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Reverse", makeShortcutHandler(function() return "JogBackward" end))
        registerAction("Command Set Shortcuts.General.Relink Files…", makeShortcutHandler(function() return "RelinkFiles" end))
        registerAction("Command Set Shortcuts.General.Connect with Selected Media", makeShortcutHandler(function() return "ConnectWithSelectedMedia" end))
        registerAction("Command Set Shortcuts.Editing.Break Apart Clip Items", makeShortcutHandler(function() return "BreakApartClipItems" end))
        registerAction("Command Set Shortcuts.Editing.Select Previous Video Angle", makeShortcutHandler(function() return "SelectPreviousVideoAngle" end))
        registerAction("Command Set Shortcuts.General.Adjust Content Created Date and Time…", makeShortcutHandler(function() return "ModifyContentCreationDate" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -2", makeShortcutHandler(function() return "PlayRateMinus2X" end))
        registerAction("Command Set Shortcuts.Editing.Duplicate", makeShortcutHandler(function() return "Duplicate" end))
        registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 5", makeShortcutHandler(function() return "CutSwitchAngle05" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Full Screen", makeShortcutHandler(function() return "PlayFullscreen" end))
        registerAction("Command Set Shortcuts.Editing.Trim End", makeShortcutHandler(function() return "TrimEnd" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Left", makeShortcutHandler(function() return "NudgeLeft" end))
        registerAction("Command Set Shortcuts.Marking.Go to Keyword Editor", makeShortcutHandler(function() return "OrderFrontKeywordEditor" end))
        registerAction("Command Set Shortcuts.Effects.Add Color Hue/Saturation Effect", makeShortcutHandler(function() return "AddHueSaturationEffect" end))
        registerAction("Command Set Shortcuts.Effects.Show/Hide Frame Browser", makeShortcutHandler(function() return "ToggleCompareFrameHUD" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Go to the Previous Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToPreviousTab" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 5", makeShortcutHandler(function() return "SwitchAngle05" end))
        registerAction("Command Set Shortcuts.Windows.Go to Library Browser", makeShortcutHandler(function() return "ToggleEventLibraryBrowser" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Set Monitoring Angle", makeShortcutHandler(function() return "MultiAngleVideoSetUsingSkimmedObject" end))
        registerAction("Command Set Shortcuts.Editing.Extend Selection to Next Clip", makeShortcutHandler(function() return "ExtendNextItem" end))
        registerAction("Command Set Shortcuts.View.Show/Hide Skimmer Info", makeShortcutHandler(function() return "ShowSkimmerInfo" end))
        registerAction("Command Set Shortcuts.General.Import Final Cut Pro X XML", makeShortcutHandler(function() return "ImportXML" end))
        registerAction("Command Set Shortcuts.Tools.Transform Tool", makeShortcutHandler(function() return "SelectTransformTool" end))
        registerAction("Command Set Shortcuts.General.Duplicate Project As…", makeShortcutHandler(function() return "DuplicateProjectAs" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Hold", makeShortcutHandler(function() return "RetimeHold" end))
        registerAction("Command Set Shortcuts.Marking.Set Additional Range End", makeShortcutHandler(function() return "AddNewSelectionEnd" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Nudge Control Up", makeShortcutHandler(function() return "ColorBoard-NudgePuckUp" end))
        registerAction("Command Set Shortcuts.Windows.Show/Hide Transitions Browser", makeShortcutHandler(function() return "ToggleMediaTransitionsBrowser" end))
        registerAction("Command Set Shortcuts.General.Adjust Volume Relative…", makeShortcutHandler(function() return "AdjustVolumeRelative" end))
        registerAction("Command Set Shortcuts.Windows.View Roles in Timeline Index", makeShortcutHandler(function() return "SwitchToRolesTabInTimelineIndex" end))
        registerAction("Command Set Shortcuts.General.Show Both Fields in the Event Viewer", makeShortcutHandler(function() return "ShowBothFieldsEventViewer" end))
        registerAction("Command Set Shortcuts.Editing.Expand Audio/Video", makeShortcutHandler(function() return "ShowAVSplit" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Frame", makeShortcutHandler(function() return "JumpToPreviousFrame" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Audio Skimming", makeShortcutHandler(function() return "ToggleAudioScrubbing" end))
        registerAction("Command Set Shortcuts.Editing.Replace with Gap", makeShortcutHandler(function() return "ReplaceWithGap" end))
        registerAction("Command Set Shortcuts.Windows.View Clips in Timeline Index", makeShortcutHandler(function() return "SwitchToClipsTabInTimelineIndex" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 8", makeShortcutHandler(function() return "SwitchAngle08" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Superimpose", makeShortcutHandler(function() return "360Superimpose" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play to End", makeShortcutHandler(function() return "PlayToOut" end))
        registerAction("Command Set Shortcuts.Editing.Source Media: Audio Only", makeShortcutHandler(function() return "AVEditModeAudio" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Right Eye Only", makeShortcutHandler(function() return "360RightEyeOnly" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Down", makeShortcutHandler(function() return "Down" end))
        registerAction("Command Set Shortcuts.Editing.Select Next Clip", makeShortcutHandler(function() return "SelectNextItem" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Subframe", makeShortcutHandler(function() return "JumpToPreviousSubframe" end))
        registerAction("Command Set Shortcuts.Organization.Synchronize Clips…", makeShortcutHandler(function() return "SynchronizeClips" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 10", makeShortcutHandler(function() return "SwitchAngle10" end))
        registerAction("Command Set Shortcuts.Effects.Color Board: Switch to the Exposure Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToExposureTab" end))
        registerAction("Command Set Shortcuts.General.Find", makeShortcutHandler(function() return "Find" end))
        registerAction("Command Set Shortcuts.Editing.Select Clip", makeShortcutHandler(function() return "SelectClipAtPlayhead" end))
        registerAction("Command Set Shortcuts.Editing.Select Previous Clip", makeShortcutHandler(function() return "SelectPreviousItem" end))
        registerAction("Command Set Shortcuts.Editing.Connect to Primary Storyline - Backtimed", makeShortcutHandler(function() return "AnchorWithSelectedMediaBacktimed" end))
        registerAction("Command Set Shortcuts.View.Clip Appearance: Large Waveforms", makeShortcutHandler(function() return "ClipAppearanceAudioMostly" end))
        registerAction("Command Set Shortcuts.Editing.Connect to Primary Storyline", makeShortcutHandler(function() return "AnchorWithSelectedMedia" end))
        registerAction("Command Set Shortcuts.Editing.Insert Video only", makeShortcutHandler(function() return "InsertMediaVideo" end))
        registerAction("Command Set Shortcuts.Organization.Continuous Playback", makeShortcutHandler(function() return "ToggleOrganizerPlaythrough" end))
        registerAction("Command Set Shortcuts.Effects.Connect Default Lower Third", makeShortcutHandler(function() return "AddBasicLowerThird" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -8", makeShortcutHandler(function() return "PlayRateMinus8X" end))
        registerAction("Command Set Shortcuts.Effects.Retime Editor", makeShortcutHandler(function() return "ShowRetimeEditor" end))
        registerAction("Command Set Shortcuts.Editing.Insert/Connect Freeze Frame", makeShortcutHandler(function() return "FreezeFrame" end))
        registerAction("Command Set Shortcuts.Editing.Set Volume to Silence (-∞)", makeShortcutHandler(function() return "VolumeMinusInfinity" end))
        registerAction("Command Set Shortcuts.General.Close Window", makeShortcutHandler(function() return "CloseWindow" end))
        registerAction("Command Set Shortcuts.General.Skimming", makeShortcutHandler(function() return "ToggleSkimming" end))
        registerAction("Command Set Shortcuts.Effects.Color Correction: Select Previous Control", makeShortcutHandler(function() return "ColorBoard-SelectPreviousPuck" end))
        registerAction("Command Set Shortcuts.General.Modify Marker", makeShortcutHandler(function() return "EditMarker" end))
        registerAction("Command Set Shortcuts.General.Project Properties", makeShortcutHandler(function() return "ProjectInfo" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Range End", makeShortcutHandler(function() return "GotoOut" end))
        registerAction("Command Set Shortcuts.General.Nudge Marker Left", makeShortcutHandler(function() return "NudgeMarkerLeft" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -4", makeShortcutHandler(function() return "PlayRateMinus4X" end))
        registerAction("Command Set Shortcuts.Marking.Roles: Apply Video Role", makeShortcutHandler(function() return "SetRoleVideo" end))
        registerAction("Command Set Shortcuts.Windows.Show Video Waveform", makeShortcutHandler(function() return "ToggleWaveform" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Audio Subframe Left Many", makeShortcutHandler(function() return "NudgeLeftAudioMany" end))
        registerAction("Command Set Shortcuts.Windows.Next Inspector Tab", makeShortcutHandler(function() return "SelectNextTab" end))
        registerAction("Command Set Shortcuts.Editing.Enable/Disable Clip", makeShortcutHandler(function() return "EnableOrDisableEdit" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play/Pause", makeShortcutHandler(function() return "PlayPause" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Play from Playhead", makeShortcutHandler(function() return "PlayFromAlternatePlayhead" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Monitor Audio", makeShortcutHandler(function() return "MultiAngleAddAudioUsingSkimmedObject" end))
        registerAction("Command Set Shortcuts.Windows.Go to Inspector", makeShortcutHandler(function() return "GoToInspector" end))
        registerAction("Command Set Shortcuts.Editing.Nudge Right", makeShortcutHandler(function() return "NudgeRight" end))
        registerAction("Command Set Shortcuts.Editing.Connect Audio only to Primary Storyline - Backtimed", makeShortcutHandler(function() return "AnchorWithSelectedMediaAudioBacktimed" end))
        registerAction("Command Set Shortcuts.View.Clip Appearance: Increase Waveform Size", makeShortcutHandler(function() return "ClipAppearanceAudioBigger" end))
        registerAction("Command Set Shortcuts.View.View Green Color Channel", makeShortcutHandler(function() return "ShowColorChannelsGreen" end))
        registerAction("Command Set Shortcuts.View.Show/Hide Video Animation", makeShortcutHandler(function() return "ShowCurveEditor" end))
        registerAction("Command Set Shortcuts.Share.Send to Compressor", makeShortcutHandler(function() return "SendToCompressor" end))
        registerAction("Command Set Shortcuts.Effects.Retime: Fast 2x", makeShortcutHandler(function() return "RetimeFast2x" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Timeline History Back", makeShortcutHandler(function() return "SelectPreviousTimelineItem" end))
        registerAction("Command Set Shortcuts.Windows.Show Histogram", makeShortcutHandler(function() return "ToggleHistogram" end))
        registerAction("Command Set Shortcuts.Editing.Select Right Video Edge", makeShortcutHandler(function() return "SelectRightEdgeVideo" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Go to Range Start", makeShortcutHandler(function() return "GotoIn" end))
        registerAction("Command Set Shortcuts.Application.Keyboard Customization", makeShortcutHandler(function() return "KeyboardCustomization" end))
        registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 16", makeShortcutHandler(function() return "SwitchAngle16" end))
        registerAction("Command Set Shortcuts.Playback/Navigation.Tilt Down", makeShortcutHandler(function() return "TiltDown" end))
        registerAction("Command Set Shortcuts.Marking.Remove All Keywords From Selection", makeShortcutHandler(function() return "RemoveAllKeywordsFromSelection" end))
        registerAction("Command Set Shortcuts.View.Clip Appearance: Large Filmstrips", makeShortcutHandler(function() return "ClipAppearanceVideoMostly" end))
        registerAction("Command Set Shortcuts.View.Show/Hide Audio Animation", makeShortcutHandler(function() return "ShowAudioCurveEditor" end))
        registerAction("Command Set Shortcuts.Marking.Edit Roles…", makeShortcutHandler(function() return "EditRoles" end))
        registerAction("Command Set Shortcuts.Editing.Toggle Storyline Mode", makeShortcutHandler(function() return "ToggleAnchoredSpinesMode" end))
        registerAction("Command Set Shortcuts.Effects.Match Audio…", makeShortcutHandler(function() return "MatchAudio" end))
        registerAction("Command Set Shortcuts.Editing.Lift from Storyline", makeShortcutHandler(function() return "LiftFromSpine" end))
        registerAction("Command Set Shortcuts.General.Send IMF Package to Compressor", makeShortcutHandler(function() return "SendIMFPackageToCompressor" end))
        registerAction("Command Set Shortcuts.Effects.Add Color Wheels Effect", makeShortcutHandler(function() return "AddColorWheelsEffect" end))
    end

end

local plugin = {
    id          = "finalcutpro.loupedeckplugin",
    group       = "finalcutpro",
    required    = true,
    dependencies    = {
        ["core.loupedeckplugin.manager"]                = "manager",
        ["finalcutpro.timeline.generators"]             = "generators",
        ["finalcutpro.timeline.titles"]                 = "titles",
        ["finalcutpro.timeline.transitions"]            = "transitions",
        ["finalcutpro.timeline.audioeffects"]           = "audioeffects",
        ["finalcutpro.timeline.videoeffects"]           = "videoeffects",
        ["finalcutpro.workflowextension"]               = "workflowExtension",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Manage Dependencies:
    --------------------------------------------------------------------------------
    mod.manager             = deps.manager
    mod._generators         = deps.generators
    mod._titles             = deps.titles
    mod._transitions        = deps.transitions
    mod._audioeffects       = deps.audioeffects
    mod._videoeffects       = deps.videoeffects
    mod._workflowExtension  = deps.workflowExtension

    --------------------------------------------------------------------------------
    -- Setup Final Cut Pro Plugins:
    --------------------------------------------------------------------------------
    mod.fcpPluginsLookup = {}
    mod.fcpPluginsTypeLookup = {}

    mod.fcpPlugins = {
        [plugins.types.generator]       = mod._generators,
        [plugins.types.title]           = mod._titles,
        [plugins.types.transition]      = mod._transitions,
        [plugins.types.audioEffect]     = mod._audioeffects,
        [plugins.types.videoEffect]     = mod._videoeffects,
    }

    --------------------------------------------------------------------------------
    -- Add actions:
    --------------------------------------------------------------------------------
    mod.manager.enabled:watch(function(enabled)
        if enabled then
            mod._registerActions()
        end
    end)

    return mod
end

return plugin
