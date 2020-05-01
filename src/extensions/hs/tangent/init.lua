--- === hs.tangent ===
---
--- Tangent Control Surface Extension
---
--- **API Version:** TUBE Version 3.8 - TIPC Rev 6 (1st March 2019)
---
--- This plugin allows Hammerspoon to communicate with Tangent's range of panels, such as their Element, Virtual Element Apps, Wave, Ripple and any future panels.
---
--- The Tangent Unified Bridge Engine (TUBE) is made up of two software elements, the Mapper and the Hub. The Hub communicates with your application via the
--- TUBE Inter Process Communications (TIPC). TIPC is a standardised protocol to allow any application that supports it to communicate with any current and
--- future panels produced by Tangent via the TUBE Hub.
---
--- You can download the Tangent Developer Support Pack & Tangent Hub Installer for Mac [here](http://www.tangentwave.co.uk/developer-support/).
---
--- This extension was thrown together by [Chris Hocking](https://github.com/latenitefilms), then dramatically improved by [David Peterson](https://github.com/randomeizer) for [CommandPost](http://commandpost.io).

local log                                       = require("hs.logger").new("tangent")
local inspect                                   = require("hs.inspect")

local fs                                        = require("hs.fs")
local socket                                    = require("hs.socket")
local timer                                     = require("hs.timer")

local unpack, pack, format                      = string.unpack, string.pack, string.format


local mod = {}

--------------------------------------------------------------------------------
-- MODULE CONSTANTS:
--------------------------------------------------------------------------------

--- hs.tangent.fromHub -> table
--- Constant
--- Definitions for IPC Commands from the HUB to Hammerspoon.
---
--- Notes:
---  * `connected`                       - a connection is established with the Hub.
---  * `disconnected`                    - the connection is dropped with the Hub.
---  * `initiateComms`                   - sent when the Hub wants to initiate communications.
---  * `parameterChange`                 - a parameter was incremented.
---  * `parameterReset`                  - a parameter was reset.
---  * `parameterValueRequest`           - the Hub wants the current value of the parameter.
---  * `menuChange`                      - The menu was changed, `+1` or `-1`.
---  * `menuReset`                       - The menu was reset.
---  * `menuStringRequest`               - The application should send a `menuString` with the current value.
---  * `actionOn`                        - An action button was pressed.
---  * `actionOff`                       - An action button was released.
---  * `modeChange`                      - The current mode was changed.
---  * `transport`                       - The transport.
---  * `unmanagedPanelCapabilities`      - Send by the Hub to advertise an unmanaged panel.
---  * `unmanagedButtonDown`             - A button on an unmanaged panel was pressed.
---  * `unmanagedButtonUp`               - A button on an unmanaged panel was released.
---  * `unmanagedEncoderChange`          - An encoder (dial/wheel) on an unmanaged panel changed.
---  * `unmanagedDisplayRefresh`         - Triggered when an unmanaged panel's display needs to update.
---  * `panelConnectionState`            - A panel's connection state changed.
---  * `customParameterChange`           - Increment a parameter as defined by a custom control string.
---  * `customParameterReset`            - Reset the specified custom parameter.
---  * `customParameterValueRequest`     - The Hub wants the current value of the custom parameter.
---  * `customMenuChange`                - The value of the menu has changed on the Hub.
---  * `customMenuReset`                 - The value of the menu should be reset.
---  * `customMenuStringRequest`         - The Hub wants the current value of the menu as a string.
---  * `customActionOn`                  - The custom action has been turned on. Typically a button press.
---  * `customActionOff`                 - The custom action has been turned off. Typically a button release.
mod.fromHub = {
    --------------------------------------------------------------------------------
    -- Custom Notifications:
    --------------------------------------------------------------------------------
    connected                                   = 0xFF01,
    disconnected                                = 0xFF02,

    --------------------------------------------------------------------------------
    -- Official Definitions:
    --------------------------------------------------------------------------------
    initiateComms                               = 0x01,
    parameterChange                             = 0x02,
    parameterReset                              = 0x03,
    parameterValueRequest                       = 0x04,
    menuChange                                  = 0x05,
    menuReset                                   = 0x06,
    menuStringRequest                           = 0x07,
    actionOn                                    = 0x08,
    modeChange                                  = 0x09,
    transport                                   = 0x0A,
    actionOff                                   = 0x0B,
    unmanagedPanelCapabilities                  = 0x30,
    unmanagedButtonDown                         = 0x31,
    unmanagedButtonUp                           = 0x32,
    unmanagedEncoderChange                      = 0x33,
    unmanagedDisplayRefresh                     = 0x34,
    panelConnectionState                        = 0x35,
    customParameterChange                       = 0x36,
    customParameterReset                        = 0x37,
    customParameterValueRequest                 = 0x38,
    customMenuChange                            = 0x39,
    customMenuReset                             = 0x3A,
    customMenuStringRequest                     = 0x3B,
    customActionOn                              = 0x3C,
    customActionOff                             = 0x3D,
}

--- hs.tangent.toHub -> table
--- Constant
--- Definitions for IPC Commands from Hammerspoon to the HUB.
mod.toHub = {
    applicationDefinition                       = 0x81,
    parameterValue                              = 0x82,
    menuString                                  = 0x83,
    allChange                                   = 0x84,
    modeValue                                   = 0x85,
    displayText                                 = 0x86,
    arcDisplayText                              = 0x87,
    unmanagedPanelCapabilitiesRequest           = 0xA0,
    unmanagedDisplayWrite                       = 0xA1,
    renameControl                               = 0xA2,
    highlightControl                            = 0xA3,
    indicateControl                             = 0xA4,
    panelConnectionStatesRequest                = 0xA5,
    customParameterValue                        = 0xA6,
    customMenuString                            = 0xA7,
    renameCustomControl                         = 0xA8,
    highlightCustomControl                      = 0xA9,
    indicateCustomControl                       = 0xAA,
}

mod.reserved = {
--- hs.tangent.reserved.action -> table
--- Constant
--- Definitions for reserved action IDs.
---
--- Notes:
---  * `alt`                     - toggles the 'ALT' function.
---  * `nextKnobBank`            - switches to the next knob bank.
---  * `prevKnobBank`            - switches to the previous knob bank.
---  * `nextButtonBank`          - switches to the next button bank.
---  * `prevBasketBank`          - switches to the previous button bank.
---  * `nextTrackerballBank`     - switches to the next trackerball bank.
---  * `prevTrackerballBank`     - switches to the previous trackerball bank.
---  * `nextMode`                - switches to the next mode.
---  * `prevMode`                - switches to the previous mode.
---  * `goToMode`                - switches to the specified mode, requiring a Argument with the mode ID.
---  * `toggleJogShuttle`        - toggles jog/shuttle mode.
---  * `toggleMouseEmulation`    - toggles mouse emulation.
---  * `fakeKeypress`            - generates a keypress, requiring an Argument with the key code.
---  * `showHUD`                 - shows the HUD on screen.
---  * `goToKnobBank`            - goes to the specific knob bank, requiring an Argument with the bank number.
---  * `goToButtonBank`          - goes to the specific button bank, requiring an Argument with the bank number.
---  * `goToTrackerballBank`     - goes to the specific trackerball bank, requiring an Argument with the bank number.
---  * `customAction`            - a custom action.
    action = {
        _                                       = 0x80000000,
        alt                                     = 0x80000001,
        nextKnobBank                            = 0x80000002,
        prevKnobBank                            = 0x80000003,
        nextButtonBank                          = 0x80000004,
        prevButtonBank                          = 0x80000005,
        nextTrackerballBank                     = 0x80000006,
        prevTrackerballBank                     = 0x80000007,
        nextMode                                = 0x80000009,
        prevMode                                = 0x8000000A,
        goToMode                                = 0x8000000B,
        toggleJogShuttle                        = 0x8000000C,
        toggleMouseEmulation                    = 0x8000000D,
        fakeKeypress                            = 0x8000000E,
        showHUD                                 = 0x8000000F,
        goToKnobBank                            = 0x80000010,
        goToButtonBank                          = 0x80000011,
        goToTrackerballBank                     = 0x80000012,
        customAction                            = 0x80000013,
    },

--- hs.tangent.reserved.parameter -> table
--- Constant
--- A table of reserved parameter IDs.
---
--- Notes:
---  * `transportRing`           - transport ring.
---  * `fakeKeypress`            - sends a fake keypress.
---  * `customParameter`         - a custom parameter.
    parameter = {
        _                                       = 0x81000000,
        transportRing                           = 0x81000001,
        fakeKeypress                            = 0x81000002,
        customParameter                         = 0x81000003,
    },

--- hs.tangent.reserved.menu -> table
--- Constant
--- A table of reserved menu IDs.
---
--- Notes:
---  * `customMenu`              - a custom menu.
    menu = {
        _                                       = 0x82000000,
        customMenu                              = 0x82000001,
    }
}

--- hs.tangent.panelType -> table
--- Constant
--- Tangent Panel Types.
mod.panelType = {
    [0x03]  = "CP200-BK",
    [0x04]  = "CP200-K",
    [0x05]  = "CP200-TS",
    [0x09]  = "CP200-S",
    [0x0A]  = "Wave",
    [0x0C]  = "Element-Tk",
    [0x0D]  = "Element-Mf",
    [0x0E]  = "Element-Kb",
    [0x0F]  = "Element-Bt",
    [0x11]  = "Ripple",
    [0x12]  = "Arc-FCN",
    [0x13]  = "Arc-GRD",
    [0x14]  = "Arc-NAV",
}

-- ERROR_OFFSET -> number
-- Constant
-- Error Offset.
local ERROR_OFFSET = -1

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS:
--------------------------------------------------------------------------------

-- isNumber(value) -> boolean
-- Function
-- Checks to see whether or not `value` is a number.
--
-- Parameters:
--  * value - The value to check.
--
-- Returns:
--  * A boolean.
local function isNumber(value)
    return type(value) == "number"
end

-- isNotTable(value) -> boolean
-- Function
-- Checks to see whether or not `value` is not a table.
--
-- Parameters:
--  * value - The value to check.
--
-- Returns:
--  * A boolean.
local function isNotTable(value)
    return type(value) ~= "table"
end

-- isNotList(value) -> boolean
-- Function
-- Checks to see whether or not `value` is not a list.
--
-- Parameters:
--  * value - The value to check.
--
-- Returns:
--  * A boolean.
local function isNotList(value)
    return isNotTable(value) or #value == 0
end

-- doesDirectoryExist(path) -> string
-- Function
-- Returns whether or not a directory exists.
--
-- Parameters:
--  * path - the path of the directory you want to check as a string.
--
-- Returns:
--  * `true` if the directory exists otherwise `false`
local function doesDirectoryExist(path)
    if path then
        local attr = fs.attributes(path)
        return attr and attr.mode == 'directory'
    else
        return false
    end
end

-- doesFileExist(path) -> boolean
-- Function
-- Returns whether or not a file exists.
--
-- Parameters:
--  * path - Path to the file
--
-- Returns:
--  * `true` if the file exists otherwise `false`
local function doesFileExist(path)
    if path == nil then return nil end
    local attr = fs.attributes(path)
    if type(attr) == "table" then
        return true
    else
        return false
    end
end

-- getPanelType(id) -> string
-- Function
-- Returns the Panel Type based on an ID
--
-- Parameters:
--  * id - ID of the Panel Type you want to return
--
-- Returns:
--  * Panel Type as string
local function getPanelType(id)
    return mod.panelType[id]
end

-- byteStringToNumber(str, offset, numberOfBytes[, signed]) -> number, number
-- Function
-- Translates a Byte String into a Number
--
-- Parameters:
--  * str - The string you want to translate
--  * offset - An offset
--  * numberOfBytes - Number of bytes
--  * signed - `true` if it's a signed integer otherwise `false`. Defaults to `false`.
--
-- Returns:
--  * A number value
--  * The new offset
local function byteStringToNumber(str, offset, numberOfBytes, signed)
    local fmt = (signed and ">i" or ">I") .. tostring(numberOfBytes)
    return unpack(fmt, str, offset)
end

-- byteStringToFloat(str, offset) -> number, number
-- Function
-- Translates a Byte String into a Float Number
--
-- Parameters:
--  * str - The string you want to translate
--  * offset - An offset
--
-- Returns:
--  * A number value
--  * The new offset
local function byteStringToFloat(str, offset)
    return unpack(">f", str, offset)
end

-- byteStringToBoolean(str, offset, numberOfBytes) -> boolean, number
-- Function
-- Translates a Byte String into a Boolean
--
-- Parameters:
--  * str - The string you want to translate
--  * offset - An offset
--  * numberOfBytes - Number of bytes
--
-- Returns:
--  * A boolean value
--  * The new offset
local function byteStringToBoolean(str, offset, numberOfBytes)
  local x = byteStringToNumber(str, offset, numberOfBytes)
  return x == 1 or false, offset + numberOfBytes
end

-- byteStringToString(str, offset, numberOfBytes) -> string, number
-- Function
-- Translates a Byte String into a `string`.
--
-- Parameters:
--  * str - The string you want to translate
--  * offset - An offset
--  * numberOfBytes - Number of bytes
--
-- Returns:
--  * The `string` value
--  * The new offset
local function byteStringToString(str, offset, numberOfBytes)
    return str:sub(offset, offset+numberOfBytes-1), offset+numberOfBytes
end

-- numberToByteString(n) -> string
-- Function
-- Translates a number into a byte string.
--
-- Parameters:
--  * n - The number you want to translate
--
-- Returns:
--  * A string
local function numberToByteString(n)
    if type(n) ~= "number" then
        log.ef("numberToByteString() was fed something other than a number")
        return nil
    end
    return pack(">I4", n)
end

-- floatToByteString(n) -> string
-- Function
-- Translates a float number into a byte string.
--
-- Parameters:
--  * n - The number you want to translate
--
-- Returns:
--  * A string
local function floatToByteString(n)
    if type(n) ~= "number" then
        log.ef("floatToByteString() was fed something other than a number")
        return nil
    end
    return pack(">f", n)
end

-- booleanToByteString(value) -> string
-- Function
-- Translates a boolean into a byte string.
--
-- Parameters:
--  * value - The boolean you want to translate
--
-- Returns:
--  * A string
local function booleanToByteString(value)
    if value == true then
        return numberToByteString(1)
    else
        return numberToByteString(0)
    end
end

-- validCallback() -> boolean
-- Function
-- Checks to see if the callback is valid.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if valid otherwise `false`.
local function validCallback()
    return type(mod._callback) == "function"
end

-- processCommands(commands) -> none
-- Function
-- Triggers the callback using the contents of the buffer.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function processCommands(commands)
    --------------------------------------------------------------------------------
    -- Trigger the callback:
    --------------------------------------------------------------------------------
    if mod._callback then
        local success, result = xpcall(function() mod._callback(commands) end, debug.traceback)
        if not success then
            log.ef("Error in Tangent Callback: %s", result)
        end
    end
end

-- errorResponse(message) -> nil, number
-- Function
-- Writes an error message to the Hammerspoon Console.
--
-- Parameters:
--  * message - The error message.
--
-- Returns:
--  * `nil`
--  * The error offset number.
local function errorResponse(message)
    log.ef(message)
    return nil, ERROR_OFFSET
end

-- receiveHandler -> table
-- Variable
-- Collection of handlers for messages received from the Hub.
local receiveHandler = {
    --------------------------------------------------------------------------------
    -- InitiateComms (0x01)
    --  * Initiates communication between the Hub and the application.
    --  * Communicates the quantity, type and IDs of the panels which are
    --    configured to be connected in the panel-list.xml file. Note that this is
    --    not the same as the panels which are actually connected – just those
    --    which are expected to be connected.
    --  * The length is dictated by the number of panels connected as the details
    --    of each panel occupies 5 bytes.
    --  * On receipt the application should respond with the
    --    ApplicationDefinition (0x81) command.
    --
    -- Format: 0x01, <protocolRev>, <numPanels>, (<mod.panelType>, <panelID>)...
    --
    -- protocolRev: The revision number of the protocol (Unsigned Int)
    -- numPanels: The number of panels connected (Unsigned Int)
    -- panelType: The code for the type of panel connected (Unsigned Int)
    -- panelID: The ID of the panel (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.initiateComms] = function(data, offset)

        local protocolRev, numberOfPanels
        protocolRev, offset = byteStringToNumber(data, offset, 4)
        numberOfPanels, offset = byteStringToNumber(data, offset, 4)

        mod._protocolRev = protocolRev

        --------------------------------------------------------------------------------
        -- Send Application Definition?
        --------------------------------------------------------------------------------
        if mod.automaticallySendApplicationDefinition == true then
            mod.sendApplicationDefinition()
        end

        --------------------------------------------------------------------------------
        -- Trigger callback:
        --------------------------------------------------------------------------------
        if protocolRev and numberOfPanels and validCallback() then
            local panels = {}
            for _ = 1,numberOfPanels do
                local currentPanelID, currentPanelType
                currentPanelType, offset = byteStringToNumber(data, offset, 4)
                currentPanelID, offset = byteStringToNumber(data, offset, 4)
                table.insert(panels, {
                    panelID = currentPanelID,
                    panelType = getPanelType(currentPanelType),
                })
            end

            return {
                protocolRev = protocolRev,
                numberOfPanels = numberOfPanels,
                panels = panels,
            }, offset
        else
            return nil, ERROR_OFFSET
        end
    end,

    --------------------------------------------------------------------------------
    -- ParameterChange (0x02)
    --  * Requests that the application increment a parameter. The application needs
    --    to constrain the value to remain within its maximum and minimum values.
    --  * On receipt the application should respond to the Hub with the new
    --    absolute parameter value using the ParameterValue (0x82) command,
    --    if the value has changed.
    --
    -- Format: 0x02, <paramID>, <increment>
    --
    -- paramID: The ID value of the parameter (Unsigned Int)
    -- increment: The incremental value which should be applied to the parameter (Float)
    --------------------------------------------------------------------------------
    [mod.fromHub.parameterChange] = function(data, offset)
        local paramID, increment
        paramID, offset = byteStringToNumber(data, offset, 4)
        increment, offset = byteStringToFloat(data, offset)
        if paramID and increment and validCallback() then
            return {
                paramID = paramID,
                increment = increment,
            }, offset
        else
            return errorResponse("Error translating parameterChange.")
        end
    end,

    --------------------------------------------------------------------------------
    -- ParameterReset (0x03)
    --  * Requests that the application changes a parameter to its reset value.
    --  * On receipt the application should respond to the Hub with the new absolute
    --    parameter value using the ParameterValue (0x82) command, if the value
    --    has changed.
    --
    -- Format: 0x03, <paramID>
    --
    -- paramID: The ID value of the parameter (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.parameterReset] = function(data, offset)
        local paramID
        paramID, offset = byteStringToNumber(data, offset, 4)
        if paramID then
            return {
                paramID = paramID,
            }, offset
        else
            return errorResponse("Error translating parameterReset.")
        end
    end,

    --------------------------------------------------------------------------------
    -- ParameterValueRequest (0x04)
    --  * Requests that the application sends a ParameterValue (0x82) command
    --    to the Hub.
    --
    -- Format: 0x04, <paramID>
    --
    -- paramID: The ID value of the parameter (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.parameterValueRequest] = function(data, offset)
        local paramID
        paramID, offset = byteStringToNumber(data, offset, 4)
        if paramID then
            return {
                paramID = paramID,
            }, offset
        else
            return errorResponse("Error translating parameterValueRequest.")
        end
    end,

    --------------------------------------------------------------------------------
    -- MenuChange (0x05)
    --  * Requests the application change a menu index by +1 or -1.
    --  * We recommend that menus that only have two values (e.g. on/off) should
    --    toggle their state on receipt of either a +1 or -1 increment value.
    --    This will allow a single button to toggle the state of such an item
    --    without the need for separate ‘up’ and ‘down’ buttons.
    --
    -- Format: 0x05, <menuID>, <increment>
    --
    -- menuID: The ID value of the menu (Unsigned Int)
    -- increment: The incremental amount by which the menu index should be changed which will always be an integer value of +1 or -1 (Signed Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.menuChange] = function(data, offset)
        local menuID, increment
        menuID, offset = byteStringToNumber(data, offset, 4)
        increment, offset = byteStringToNumber(data, offset, 4)
        if menuID and increment then
            return {
                menuID = menuID,
                increment = increment,
            }, offset
        else
            return errorResponse("Error translating menuChange.")
        end
    end,

    --------------------------------------------------------------------------------
    -- MenuReset (0x06)
    --  * Requests that the application sends a MenuString (0x83) command to the Hub.
    --
    -- Format: 0x06, <menuID>
    --
    -- menuID: The ID value of the menu (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.menuReset] = function(data, offset)
        local menuID
        menuID, offset = byteStringToNumber(data, offset, 4)
        if menuID then
            return {
                menuID = menuID,
            }, offset
        else
            return errorResponse("Error translating menuReset.")
        end
    end,

    --------------------------------------------------------------------------------
    -- MenuStringRequest (0x07)
    --  * Requests that the application sends a MenuString (0x83) command to the Hub.
    --  * On receipt, the application should respond to the Hub with the new menu
    --    value using the MenuString (0x83) command, if the menu has changed.
    --
    -- Format: 0x07, <menuID>
    --
    -- menuID: The ID value of the menu (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.menuStringRequest] = function(data, offset)
        local menuID
        menuID, offset = byteStringToNumber(data, offset, 4)
        if menuID then
            return {
                menuID = menuID,
            }, offset
        else
            return errorResponse("Error translating menuStringRequest.")
        end
    end,

    --------------------------------------------------------------------------------
    -- Action On (0x08)
    --  * Requests that the application performs the specified action.
    --
    -- Format: 0x08, <actionID>
    --
    -- actionID: The ID value of the action (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.actionOn] = function(data, offset)
        local actionID
        actionID, offset = byteStringToNumber(data, offset, 4)
        if actionID then
            return {
                actionID = actionID,
            }, offset
        else
            return errorResponse("Error translating actionOn.")
        end
    end,

    --------------------------------------------------------------------------------
    -- ModeChange (0x09)
    --  * Requests that the application changes to the specified mode.
    --
    -- Format: 0x09, <modeID>
    --
    -- modeID: The ID value of the mode (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.modeChange] = function(data, offset)
        local modeID
        modeID, offset = byteStringToNumber(data, offset, 4)
        if modeID then
            return {
                modeID = modeID,
            }, offset
        else
            return errorResponse("Error translating modeChange.")
        end
    end,

    --------------------------------------------------------------------------------
    -- Transport (0x0A)
    --  * Requests the application to move the currently active transport.
    --  * jogValue or shuttleValue will never both be set simultaneously
    --  * One revolution of the control represents 32 counts by default.
    --    The user will be able to adjust the sensitivity of Jog & Shuttle
    --    independently in the TUBE Mapper tool to send more or less than
    --    32 counts per revolution.
    --
    -- Format: 0x0A, <jogValue>, <shuttleValue>
    --
    -- jogValue: The number of jog steps to move the transport (Signed Int)
    -- shuttleValue: An incremental value to add to the shuttle speed (Signed Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.transport] = function(data, offset)
        local jogValue, shuttleValue
        jogValue, offset = byteStringToNumber(data, offset, 4, true)
        shuttleValue, offset = byteStringToNumber(data, offset, 4, true)
        if jogValue and shuttleValue then
            return {
                jogValue = jogValue,
                shuttleValue = shuttleValue,
            }, offset
        else
            return errorResponse("Error translating transport.")
        end
    end,

    --------------------------------------------------------------------------------
    -- ActionOff (0x0B)
    --  * Requests that the application cancels the specified action.
    --  * This is typically sent when a button is released.
    --
    -- Format: 0x0B, <actionID>
    --
    -- actionID: The ID value of the action (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.actionOff] = function(data, offset)
        local actionID
        actionID, offset = byteStringToNumber(data, offset, 4)
        if actionID then
            return {
                actionID = actionID,
            }, offset
        else
            return errorResponse("Error translating actionOff.")
        end
    end,

    --------------------------------------------------------------------------------
    -- UnmanagedPanelCapabilities (0x30)
    --  * Only used when working in Unmanaged panel mode.
    --  * Sent in response to a UnmanagedPanelCapabilitiesRequest (0xA0) command.
    --  * The values returned are those given in the table in Section 18.
    --    Panel Data for Unmanaged Mode.
    --
    -- Format: 0x30, <panelID>, <numButtons>, <numEncoders>, <numDisplays>, <numDisplayLines>, <numDisplayChars>
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command (Unsigned Int)
    -- numButtons: The number of buttons on the panel (Unsigned Int)
    -- numEncoders: The number of encoders on the panel (Unsigned Int)
    -- numDisplays: The number of displays on the panel (Unsigned Int)
    -- numDisplayLines: The number of lines for each display on the panel (Unsigned Int)
    -- numDisplayChars: The number of characters on each line of each display on the panel (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.unmanagedPanelCapabilities] = function(data, offset)
        local panelID, numButtons, numEncoders, numDisplays, numDisplayLines, numDisplayChars
        panelID, offset             = byteStringToNumber(data, offset, 4)
        numButtons, offset          = byteStringToNumber(data, offset, 4)
        numEncoders, offset         = byteStringToNumber(data, offset, 4)
        numDisplays, offset         = byteStringToNumber(data, offset, 4)
        numDisplayLines, offset     = byteStringToNumber(data, offset, 4)
        numDisplayChars, offset     = byteStringToNumber(data, offset, 4)
        if panelID and numButtons and numEncoders and numDisplays and numDisplayLines and numDisplayChars then
            return {
                panelID             = panelID,
                numButtons          = numButtons,
                numEncoders         = numEncoders,
                numDisplays         = numDisplays,
                numDisplayLines     = numDisplayLines,
                numDisplayChars     = numDisplayChars,
            }, offset
        else
            return errorResponse("Error translating unmanagedPanelCapabilities.")
        end
    end,

    --------------------------------------------------------------------------------
    -- UnmanagedButtonDown (0x31)
    --  * Only used when working in Unmanaged panel mode
    --  * Issued when a button has been pressed
    --
    -- Format: 0x31, <panelID>, <buttonID>
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command (Unsigned Int)
    -- buttonID: The hardware ID of the button (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.unmanagedButtonDown] = function(data, offset)
        local panelID, buttonID
        panelID, offset = byteStringToNumber(data, offset, 4)
        buttonID, offset = byteStringToNumber(data, offset, 4)
        if panelID and buttonID then
            return {
                panelID = panelID,
                buttonID = buttonID,
            }, offset
        else
            return errorResponse("Error translating unmanagedButtonDown.")
        end
    end,

    --------------------------------------------------------------------------------
    -- UnmanagedButtonUp (0x32)
    --  * Only used when working in Unmanaged panel mode.
    --  * Issued when a button has been released
    --
    -- Format: 0x32, <panelID>, <buttonID>
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command (Unsigned Int)
    -- buttonID: The hardware ID of the button (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.unmanagedButtonUp] = function(data, offset)
        local panelID, buttonID
        panelID, offset = byteStringToNumber(data, offset, 4)
        buttonID, offset = byteStringToNumber(data, offset, 4)
        if panelID and buttonID then
            return {
                panelID = panelID,
                buttonID = buttonID,
            }, offset
        else
            return errorResponse("Error translating unmanagedButtonUp.")
        end
    end,

    --------------------------------------------------------------------------------
    -- UnmanagedEncoderChange (0x33)
    --  * Only used when working in Unmanaged panel mode.
    --  * Issued when an encoder has been moved.
    --
    -- Format: 0x33, <panelID>, <encoderID>, <increment>
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command (Unsigned Int)
    -- paramID: The hardware ID of the encoder (Unsigned Int)
    -- increment: The incremental value (Float)
    --------------------------------------------------------------------------------
    [mod.fromHub.unmanagedEncoderChange] = function(data, offset)
        local panelID, encoderID, increment
        panelID, offset = byteStringToNumber(data, offset, 4)
        encoderID, offset = byteStringToNumber(data, offset, 4)
        increment, offset = byteStringToFloat(data, offset)
        if panelID and encoderID and increment then
            return {
                panelID = panelID,
                encoderID = encoderID,
                increment = increment,
            }, offset
        else
            return errorResponse("Error translating unmanagedEncoderChange.")
        end
    end,

    --------------------------------------------------------------------------------
    -- UnmanagedDisplayRefresh (0x34)
    --  * Only used when working in Unmanaged panel mode
    --  * Issued when a panel has been connected or the focus of the panel has
    --    been returned to your application.
    --  * On receipt your application should send all the current information to
    --    each display on the panel in question.
    --
    -- Format: 0x34, <panelID>
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command (Unsigned Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.unmanagedDisplayRefresh] = function(data, offset)
        local panelID
        panelID, offset = byteStringToNumber(data, offset, 4)
        if panelID then
            return {
                panelID = panelID,
            }, offset
        else
            return errorResponse("Error translating unmanagedDisplayRefresh.")
        end
    end,

    --------------------------------------------------------------------------------
    -- PanelConnectionState (0x35)
    --  * Sent in response to a PanelConnectionStatesRequest (0xA5) command to
    --    report the current connected/disconnected status of a configured panel.
    --
    -- Format: 0x35, <panelID>, <state>
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command (Unsigned Int)
    -- state: The connected state of the panel: 1 if connected, 0 if disconnected (Bool)
    --------------------------------------------------------------------------------
    [mod.fromHub.panelConnectionState] = function(data, offset)
        local panelID, state
        panelID, offset = byteStringToNumber(data, offset, 4)
        state, offset = byteStringToBoolean(data, offset, 4)
        if panelID and state then
            return {
                panelID = panelID,
                state = state,
            }, offset
        else
            return errorResponse("Error translating panelConnectionState.")
        end
    end,

    --------------------------------------------------------------------------------
    -- CustomParameterChange (0x36)
    --  * Requests that the application increment a parameter as defined by a custom
    --    control string. The application needs to constrain the value to remain
    --    within its maximum and minimum values.
    --  * On receipt the application should respond to the Hub with the new absolute
    --    parameter value using the CustomParameterValue (0xA6) command, if the
    --    value has changed.
    --
    -- Format: 0x36, <controlStrLen>, <controlStr>, <increment>
    --
    -- controlStrLen: The length of controlStr The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    -- increment: The incremental value which should be applied to the parameter (Float)
    --------------------------------------------------------------------------------
    [mod.fromHub.customParameterChange] = function(data, offset)
        local controlStrLen, controlStr, increment
        controlStrLen, offset = byteStringToNumber(data, offset, 4)
        controlStr, offset = byteStringToString(data, offset, controlStrLen)
        increment, offset = byteStringToFloat(data, offset)
        return {
            controlID = controlStr,
            increment = increment
        }, offset
    end,

    --------------------------------------------------------------------------------
    -- CustomParameterReset (0x37)
    --  * Requests that the application changes a parameter as defined by a custom
    --    control string to its reset value.
    --  * On receipt the application should respond to the Hub with the new absolute
    --    parameter value using the CustomParameterValue (0xA6) command, if the
    --    value has changed.
    --
    -- Format: 0x37, <controlStrLen>, <controlStr>
    --
    -- controlStrLen: The length of controlStr The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    --------------------------------------------------------------------------------
    [mod.fromHub.customParameterReset] = function(data, offset)
        local controlStrLen, controlStr
        controlStrLen, offset = byteStringToNumber(data, offset, 4)
        controlStr, offset = byteStringToString(data, offset, controlStrLen)
        return {
            controlID = controlStr,
        }, offset
    end,

    --------------------------------------------------------------------------------
    -- CustomParameterValueRequest (0x38)
    --  * Requests that the application sends a CustomParameterValue (0xA6) command
    --    to the Hub.
    --
    -- Format: 0x38, <controlStrLen>, <controlStr>
    --
    -- controlStrLen: The length of controlStr The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    --------------------------------------------------------------------------------
    [mod.fromHub.customParameterValueRequest] = function(data, offset)
        local controlStrLen, controlStr
        controlStrLen, offset = byteStringToNumber(data, offset, 4)
        controlStr, offset = byteStringToString(data, offset, controlStrLen)
        return {
            controlID = controlStr,
        }, offset
    end,

    --------------------------------------------------------------------------------
    -- CustomMenuChange (0x39)
    --  * Requests the application change a custom menu index by +1 or -1.
    --  * We recommend that menus that only have two values (e.g. on/off) should
    --    toggle their state on receipt of either a +1 or -1 increment value. This
    --    will allow a single button to toggle the state of such an item without the
    --    need for separate ‘up’ and ‘down’ buttons.
    --  * On receipt, the application should respond to the Hub with the new menu
    --    value using the CustomMenuString (0xA7) command, if the menu has changed.
    --
    -- Format: 0x36, <controlStrLen>, <controlStr>, <increment>
    --
    -- controlStrLen: The length of controlStr The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    -- increment: The incremental amount by which the menu index should be changed
    --            which will always be an integer value of +1 or -1. (Signed Int)
    --------------------------------------------------------------------------------
    [mod.fromHub.customMenuChange] = function(data, offset)
        local controlStrLen, controlStr, increment
        controlStrLen, offset = byteStringToNumber(data, offset, 4)
        controlStr, offset = byteStringToString(data, offset, controlStrLen)
        increment, offset = byteStringToNumber(data, offset, 4)
        return {
            controlID = controlStr,
            increment = increment
        }, offset
    end,

    --------------------------------------------------------------------------------
    -- CustomMenuReset (0x3A)
    --  * Requests that the application changes a custom menu to its reset value.
    --  * On receipt the application should respond to the Hub with the new absolute
    --    parameter value using the CustomMenuString (0xA7) command, if the
    --    value has changed.
    --
    -- Format: 0x3A, <controlStrLen>, <controlStr>
    --
    -- controlStrLen: The length of controlStr The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    --------------------------------------------------------------------------------
    [mod.fromHub.customMenuReset] = function(data, offset)
        local controlStrLen, controlStr
        controlStrLen, offset = byteStringToNumber(data, offset, 4)
        controlStr, offset = byteStringToString(data, offset, controlStrLen)
        return {
            controlID = controlStr,
        }, offset
    end,

    --------------------------------------------------------------------------------
    -- CustomMenuStringRequest (0x3B)
    --  * Requests that the application sends a CustomMenuString (0xA7) command
    --    to the Hub.
    --
    -- Format: 0x3B, <controlStrLen>, <controlStr>
    --
    -- controlStrLen: The length of controlStr The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    --------------------------------------------------------------------------------
    [mod.fromHub.customMenuStringRequest] = function(data, offset)
        local controlStrLen, controlStr
        controlStrLen, offset = byteStringToNumber(data, offset, 4)
        controlStr, offset = byteStringToString(data, offset, controlStrLen)
        return {
            controlID = controlStr,
        }, offset
    end,

    --------------------------------------------------------------------------------
    -- CustomActionOn (0x3C)
    --  * Requests that the application performs the specified custom action.
    --
    -- Format: 0x3C, <controlStrLen>, <controlStr>
    --
    -- controlStrLen: The length of controlStr The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    --------------------------------------------------------------------------------
    [mod.fromHub.customActionOn] = function(data, offset)
        local controlStrLen, controlStr
        controlStrLen, offset = byteStringToNumber(data, offset, 4)
        controlStr, offset = byteStringToString(data, offset, controlStrLen)
        return {
            controlID = controlStr,
        }, offset
    end,

    --------------------------------------------------------------------------------
    -- CustomActionOff (0x3D)
    --  * Requests that the application cancels the specified custom action.
    --  * This is typically sent when a button is released.
    --
    -- Format: 0x3D, <controlStrLen>, <controlStr>
    --
    -- controlStrLen: The length of controlStr The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    --------------------------------------------------------------------------------
    [mod.fromHub.customActionOff] = function(data, offset)
        local controlStrLen, controlStr
        controlStrLen, offset = byteStringToNumber(data, offset, 4)
        controlStr, offset = byteStringToString(data, offset, controlStrLen)
        return {
            controlID = controlStr,
        }, offset
    end,
}

-- processHubCommand(data) -> none
-- Function
-- Processes a single HUB Command.
--
-- Parameters:
--  * data - The raw data from the socket.
--
-- Returns:
--  * None
local function processHubCommand(data, offset)
    local id, command

    id, offset = byteStringToNumber(data, offset, 4)
    -- log.df("Processing command %#010x, offset: %d", id, offset)

    local fn = receiveHandler[id]
    if fn then
        local result
        result, offset = fn(data, offset)
        if offset == ERROR_OFFSET then
            command = {
                id = ERROR_OFFSET,
                metadata = {
                    details = format("Error while processing command ID: %#010x", id),
                    data = data,
                    offset = offset,
                }
            }
        else
            command = {
                id = id,
                metadata = result
            }
        end
    else
        command = {
            id = ERROR_OFFSET,
            metadata = {
                details = format("Unrecognised command ID: %#010x", id),
                data = data,
                offset = offset,
            }
        }
    end

    return command, offset
end

-- processDataFromHub(data) -> none
-- Function
-- Separates multiple Hub Commands for processing.
--
-- Parameters:
--  * data - The raw data from the socket.
--
-- Returns:
--  * None
local function processDataFromHub(data)
    if not validCallback() then
        --------------------------------------------------------------------------------
        -- There's no callback setup, so abort:
        --------------------------------------------------------------------------------
        return
    end
    local commands = {}
    local len = string.len(data)
    local offset = 1
    while offset > 0 and offset < len do
        local command
        command, offset = processHubCommand(data, offset)
        if command then
            commands[#commands + 1] = command
        end
    end

    --------------------------------------------------------------------------------
    -- Process the buffer:
    --------------------------------------------------------------------------------
    processCommands(commands)
end

--------------------------------------------------------------------------------
-- PRIVATE VARIABLES:
--------------------------------------------------------------------------------

-- hs.tangent._buffer -> table
-- Variable
-- The commands buffer.
mod._buffer = {}

-- hs.tangent._readBytesRemaining -> number
-- Variable
-- Number of read bytes remaining.
mod._readBytesRemaining = 0

-- hs.tangent._applicationName -> string
-- Variable
-- Application name as specified in `hs.tangent.connect()`
mod._applicationName = nil

-- hs.tangent._systemPath -> string
-- Variable
-- A string containing the absolute path of the directory that contains the Controls and Default Map XML files.
mod._systemPath = nil

-- hs.tangent._userPath -> string
-- Variable
-- A string containing the absolute path of the directory that contains the User’s Default Map XML files.
mod._userPath = nil

-- hs.tangent._protocolRev -> number
-- Variable
-- The most recent protocolRev value returned when an InitiatComms is received.
mod._protocolRev = nil

--------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS & METHODS:
--------------------------------------------------------------------------------

--- hs.tangent.ipAddress -> number
--- Variable
--- IP Address that the Tangent Hub is located at. Defaults to 127.0.0.1.
mod.ipAddress = "127.0.0.1"

--- hs.tangent.port -> number
--- Variable
--- The port that Tangent Hub monitors. Defaults to 64246.
mod.port = 64246

--- hs.tangent.automaticallySendApplicationDefinition -> boolean
--- Variable
--- Automatically send the "Application Definition" response. Defaults to `true`.
mod.automaticallySendApplicationDefinition = true

--- hs.tangent.setLogLevel(loglevel) -> none
--- Function
--- Sets the Log Level.
---
--- Parameters:
---  * loglevel - can be 'nothing', 'error', 'warning', 'info', 'debug', or 'verbose'; or a corresponding number between 0 and 5
---
--- Returns:
---  * None
function mod.setLogLevel(loglevel)
    log:setLogLevel(loglevel)
    socket.setLogLevel(loglevel)
end

--- hs.tangent.isTangentHubInstalled() -> boolean
--- Function
--- Checks to see whether or not the Tangent Hub software is installed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Tangent Hub is installed otherwise `false`.
function mod.isTangentHubInstalled()
    if doesFileExist("/Library/Application Support/Tangent/Hub/TangentHub") then
        return true
    else
        return false
    end
end

--- hs.tangent.callback() -> boolean
--- Function
--- Sets a callback when new messages are received.
---
--- Parameters:
---  * callbackFn - a function to set as the callback for `hs.tangent`. If the value provided is `nil`, any currently existing callback function is removed.
---
--- Returns:
---  * `true` if successful otherwise `false`
---
--- Notes:
---  * Full documentation for the Tangent API can be downloaded [here](http://www.tangentwave.co.uk/download/developer-support-pack/).
---  * The callback function should expect 1 argument and should not return anything.
---  * The 1 argument will be a table, which can contain one or many commands. Each command is it's own table with the following contents:
---    * id - the message ID of the incoming message
---    * metadata - A table of data for the Tangent command (see below).
---  * The metadata table will return the following, depending on the `id` for the callback:
---    * `connected` - Connection to Tangent Hub successfully established.
---    * `disconnected` - The connection to Tangent Hub was dropped.
---    * `initiateComms` - Initiates communication between the Hub and the application.
---      * `protocolRev` - The revision number of the protocol.
---      * `numPanels` - The number of panels connected.
---      * `panels`
---        * `panelID` - The ID of the panel.
---        * `panelType` - The type of panel connected.
---      * `data` - The raw data from the Tangent Hub
---    * `parameterChange` - Requests that the application increment a parameter.
---      * `paramID` - The ID value of the parameter.
---      * `increment` - The incremental value which should be applied to the parameter.
---    * `parameterReset` - Requests that the application changes a parameter to its reset value.
---      * `paramID` - The ID value of the parameter.
---    * `parameterValueRequest` - Requests that the application sends a `ParameterValue (0x82)` command to the Hub.
---      * `paramID` - The ID value of the parameter.
---    * `menuChange` - Requests the application change a menu index by +1 or -1.
---      * `menuID` - The ID value of the menu.
---      * `increment` - The incremental amount by which the menu index should be changed which will always be an integer value of +1 or -1.
---    * `menuReset` - Requests that the application changes a menu to its reset value.
---      * `menuID` - The ID value of the menu.
---    * `menuStringRequest` - Requests that the application sends a `MenuString (0x83)` command to the Hub.
---      * `menuID` - The ID value of the menu.
---    * `actionOn` - Requests that the application performs the specified action.
---      * `actionID` - The ID value of the action.
---    * `modeChange` - Requests that the application changes to the specified mode.
---      * `modeID` - The ID value of the mode.
---    * `transport` - Requests the application to move the currently active transport.
---      * `jogValue` - The number of jog steps to move the transport.
---      * `shuttleValue` - An incremental value to add to the shuttle speed.
---    * `actionOff` - Requests that the application cancels the specified action.
---      * `actionID` - The ID value of the action.
---    * `unmanagedPanelCapabilities` - Only used when working in Unmanaged panel mode. Sent in response to a `UnmanagedPanelCapabilitiesRequest (0xA0)` command.
---      * `panelID` - The ID of the panel as reported in the `InitiateComms` command.
---      * `numButtons` - The number of buttons on the panel.
---      * `numEncoders` - The number of encoders on the panel.
---      * `numDisplays` - The number of displays on the panel.
---      * `numDisplayLines` - The number of lines for each display on the panel.
---      * `numDisplayChars` - The number of characters on each line of each display on the panel.
---    * `unmanagedButtonDown` - Only used when working in Unmanaged panel mode. Issued when a button has been pressed.
---      * `panelID` - The ID of the panel as reported in the `InitiateComms` command.
---      * `buttonID` - The hardware ID of the button
---    * `unmanagedButtonUp` - Only used when working in Unmanaged panel mode. Issued when a button has been released.
---      * `panelID` - The ID of the panel as reported in the `InitiateComms` command.
---      * `buttonID` - The hardware ID of the button.
---    * `unmanagedEncoderChange` - Only used when working in Unmanaged panel mode. Issued when an encoder has been moved.
---      * `panelID` - The ID of the panel as reported in the `InitiateComms` command.
---      * `paramID` - The hardware ID of the encoder.
---      * `increment` - The incremental value.
---    * `unmanagedDisplayRefresh` - Only used when working in Unmanaged panel mode. Issued when a panel has been connected or the focus of the panel has been returned to your application.
---      * `panelID` - The ID of the panel as reported in the `InitiateComms` command.
---    * `panelConnectionState`
---      * `panelID` - The ID of the panel as reported in the `InitiateComms` command.
---      * `state` - The connected state of the panel, `true` if connected, `false` if disconnected.
function mod.callback(callbackFn)
    if type(callbackFn) == "function" then
        mod._callback = callbackFn
        return true
    elseif type(callbackFn) == "nil" then
        mod._callback = nil
        return true
    else
        log.ef("Callback recieved an invalid type: %s", type(callbackFn))
        return false
    end
end

--- hs.tangent.connected() -> boolean
--- Function
--- Checks to see whether or not you're successfully connected to the Tangent Hub.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if connected, otherwise `false`
function mod.connected()
    return mod._socket ~= nil and mod._socket:connected()
end

--- hs.tangent.protocolRev() -> number | nil
--- Function
--- Returns the protocolRev for the connected Tangent Hub, or `nil` if not connected.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if connected, otherwise `false`
function mod.protocolRev()
    return mod.connected() and mod._protocolRev or nil
end

--- hs.tangent.send(byteString) -> boolean, string
--- Function
--- Sends a "bytestring" message to the Tangent Hub. This should be a full
--- encoded string for the command you want to send, withouth the leading 'size' section,
--- which the function will calculate automatically.
---
--- In general, you should use the more specific functions that package the command for you,
--- such as `sendParameterValue(...)`. This function can be used to send a message that
--- this API doesn't yet support.
---
--- Parameters:
---  * byteString   - The string of bytes to send to tangent.
---
--- Returns:
---  * success - `true` if connected, otherwise `false`
---  * errorMessage - An error message if an error occurs, as a string
---
--- Notes:
---  * Full documentation for the Tangent API can be downloaded [here](http://www.tangentwave.co.uk/download/developer-support-pack/).
function mod.send(byteString)
    if mod.connected() then
        if byteString == nil or #byteString == 0 then
            return false, "No byte string provided"
        end

        mod._socket:send(numberToByteString(#byteString)..byteString)
        return true
    end
    return false, "Not connected"
end

--- hs.tangent.sendApplicationDefinition([appName, systemPath, userPath[, task]]) -> boolean, string
--- Function
--- Sends the application details to the Tangent Hub.
--- If no details are provided the ones stored in the module are used.
---
--- Parameters:
---  * appName       - The human-readable name of the application.
---  * systemPath    - A string containing the absolute path of the directory that contains the Controls and Default Map XML files (Path String)
---  * userPath      - A string containing the absolute path of the directory that contains the User’s Default Map XML files (Path String)
---  * task          - An optional string containing the name of the task associated with the application if the `appName` is different to the primary app being managed.
---
--- Returns:
---  * `true` if successful, `false` and an error message if there was a problem.
function mod.sendApplicationDefinition(appName, systemPath, userPath, task)
    appName = appName or mod._applicationName
    systemPath = systemPath or mod._systemPath
    userPath = userPath or mod._userPath
    task = task or mod._task

    if not appName then
        return false, format("Missing or invalid application name: %s", inspect(appName))
    end
    if not systemPath or doesDirectoryExist(systemPath) == false then
        return false, format("Missing or invalid system path: %s", inspect(systemPath))
    end
    if userPath and doesDirectoryExist(userPath) == false then
        return false, format("Missing or invalid userPath: %s", inspect(userPath))
    end

    mod._applicationName = appName
    mod._systemPath = systemPath
    mod._userPath = userPath
    mod._task = task

    --------------------------------------------------------------------------------
    -- Format: 0x81, <appStrLen>, <appStr>, <sysDirStrLen>, <sysDirStr>, <userDirStrLen>, <userDirStr>
    --
    -- appStrLen: The length of appStr (Unsigned Int)
    -- appStr: A string containing the name of the application (Character String)
    -- sysDirStrLen: The length of sysDirStr (Unsigned Int)
    -- sysDirStr: A string containing the absolute path of the directory that contains the Controls and Default Map XML files (Path String)
    -- usrDirStrLen: The length of usrDirStr (Unsigned Int)
    -- usrDirStr: A string containing the absolute path of the directory that contains the User’s Default Map XML files (Path String)
    -- taskStrLen: The length of taskStr (Unsigned Int) (only available from protocolRev 7 onwards)
    -- tastStr: A string containing the name of the task associated with the application. This is used to assist with automatic switching of panels when your application gains mouse focus on the GUI.
    -- This parameter should only be required if the string passed in appStr does not match the Task name that the OS identifies as your application.
    -- Typically, this is only usually required for Plugins which run within a parent Host application. Under these circumstances it is the name of the Host Application’s Task which should be passed.
    -- Any numerical characters included in taskStr will be stripped before matching.
    -- If taskStr is not required then taskStrLen should be set to 0.

    --------------------------------------------------------------------------------
    local byteString =  numberToByteString(mod.toHub.applicationDefinition) ..
                        numberToByteString(#appName) ..
                        appName ..
                        numberToByteString(#systemPath) ..
                        systemPath ..
                        numberToByteString(userPath and #userPath or 0) ..
                        (userPath ~= nil and userPath or "")

    if mod._protocolRev and mod._protocolRev >= 7 then
        if task then
            byteString =    byteString ..
                            numberToByteString(#task) ..
                            task
        else
            byteString =    byteString ..
                            numberToByteString(0)
        end
    end

    return mod.send(byteString)
end

--- hs.tangent.supportsFocusRequest() -> boolean
--- Function
--- Checks if the Tangeng Hub is connected and supports a `sendFocusRequest()` call.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if focus request be requested, otherwise `false`.
function mod.supportsFocusRequest()
    local protocolRev = mod.protocolRev()
    return protocolRev and protocolRev >= 7
end

--- hs.tangent.sendFocusRequest([task]) -> boolean, string
--- Function
--- Sends a request to the Tangent Hub to become the target of the Hub's messages. This is typically used when switching between multiple apps that want the Hub's attention.
---
--- Parameters:
---  * task - An optional string to indicate the name of the app which is 'active'. If not provided, the `task` provided when connecting will be used. Only supported with Tangent Hub on protocolRev 7 or greater.
---
--- Returns:
---  * `true` if successful, `false` and an error message if there was a problem.
function mod.sendFocusRequest(task)
    return mod.sendApplicationDefinition(mod._applicationName, mod._systemPath, mod._userPath, task or mod._task)
end

--- hs.tangent.sendParameterValue(paramID, value[, atDefault]) -> boolean, string
--- Function
--- Updates the Hub with a parameter value.
--- The Hub then updates the displays of any panels which are currently
--- showing the parameter value.
---
--- Parameters:
---  * paramID - The ID value of the parameter (Unsigned Int)
---  * value - The current value of the parameter (Float)
---  * atDefault - if `true` the value represents the default. Defaults to `false`.
---
--- Returns:
---  * `true` if successful, or `false` and an error message if not.
function mod.sendParameterValue(paramID, value, atDefault)
    --------------------------------------------------------------------------------
    -- Format: 0x82, <paramID>, <value>, <atDefault>
    --
    -- paramID: The ID value of the parameter (Unsigned Int)
    -- value: The current value of the parameter (Float)
    -- atDefault: True if the value represents the default. Otherwise false (Bool)
    --------------------------------------------------------------------------------
    if not paramID then
        return false, format("Missing or invalid parameter ID: %s", inspect(paramID))
    end
    if not value or type(value) ~= "number" then
        return false, format("Missing or invalid value: %s", inspect(value))
    end
    atDefault = atDefault == true

    local byteString = numberToByteString(mod.toHub.parameterValue) ..
                    numberToByteString(paramID) ..
                    floatToByteString(value) ..
                    booleanToByteString(atDefault)

    return mod.send(byteString)
end

--- hs.tangent.sendMenuString(menuID, value[, atDefault]) -> boolean, string
--- Function
--- Updates the Hub with a menu value.
--- The Hub then updates the displays of any panels which are currently
--- showing the menu.
--- If a value of `nil` is sent then the Hub will not attempt to display a
--- value for the menu. However the `atDefault` flag will still be recognised.
---
--- Parameters:
---  * menuID - The ID value of the menu (Unsigned Int)
---  * value - The current ‘value’ of the parameter represented as a string
---  * atDefault - if `true` the value represents the default. Otherwise `false`.
---
--- Returns:
---  * `true` if successful, or `false` and an error message if not.
function mod.sendMenuString(menuID, value, atDefault)
    --------------------------------------------------------------------------------
    -- Format: 0x83, <menuID>, <valueStrLen>, <valueStr>, <atDefault>
    --
    -- menuID: The ID value of the menu (Unsigned Int)
    -- valueStrLen: The length of valueStr (Unsigned Int)
    -- valueStr: The current ‘value’ of the parameter represented as a string (Character String)
    -- atDefault: True if the value represents the default. Otherwise false (Bool)
    --------------------------------------------------------------------------------
    if not type(menuID) == "number" then
        return false, format("Missing or invalid menuID: %s", inspect(menuID))
    end
    value = value or ""
    atDefault = atDefault == true

    local byteString = numberToByteString(mod.toHub.menuString) ..
                        numberToByteString(menuID) ..
                        numberToByteString(#value) ..
                        value  ..
                        booleanToByteString(atDefault)

    return mod.send(byteString)
end

--- hs.tangent.sendAllChange() -> boolean, string
--- Function
--- Tells the Hub that a large number of software-controls have changed.
--- The Hub responds by requesting all the current values of
--- software-controls it is currently controlling.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful, or `false` and an error message if not.
function mod.sendAllChange()
    --------------------------------------------------------------------------------
    -- Format: 0x84
    --------------------------------------------------------------------------------
    local byteString = numberToByteString(mod.toHub.allChange)
    return mod.send(byteString)
end

--- hs.tangent.sendModeValue(modeID) -> boolean, string
--- Function
--- Updates the Hub with a mode value.
--- The Hub then changes mode and requests all the current values of
--- software-controls it is controlling.
---
--- Parameters:
---  * modeID - The ID value of the mode (Unsigned Int)
---
--- Returns:
---  * `true` if successful, or `false` and an error message if not.
function mod.sendModeValue(modeID)
    --------------------------------------------------------------------------------
    -- Format: 0x85, <modeID>
    --
    -- modeID: The ID value of the mode (Unsigned Int)
    --------------------------------------------------------------------------------
    if not isNumber(modeID) then
        return false, format("Missing or invalid `modeID`: %s", inspect(modeID))
    end
    local byteString = numberToByteString(mod.toHub.modeValue) ..
                        numberToByteString(modeID)

    return mod.send(byteString)
end

--- hs.tangent.sendDisplayText(messages[, doubleHeight]) -> boolean, string
--- Function
---  * Updates the Hub with a number of character strings that will be displayed
---   on connected panels if there is space.
---  * Strings may either be 32 character, single height or 16 character
---   double-height. They will be displayed in the order received; the first
---   string displayed at the top of the display.
---  * If a string is not defined as double-height then it will occupy the
---   next line.
---  * If a string is defined as double-height then it will occupy the next
---   2 lines.
---  * The maximum number of lines which will be used by the application
---   must be indicated in the Controls XML file.
---  * Text which exceeds 32 (single-height) or 16 (double-height) characters will be truncated.
---
--- Example:
---
--- ```lua
--- hs.tangent.sendDisplayText(
---     { "Single Height", "Double Height" }, {false, true}
--- )
--- ```
---
--- If all text is single-height, the `doubleHeight` table can be omitted.
---
--- Parameters:
---  * messages      - A list of messages to send.
---  * doubleHeight  - An optional list of `boolean`s indicating if the corresponding message is double-height.
---
--- Returns:
---  * `true` if successful, or `false` and an error message if not.
function mod.sendDisplayText(messages, doubleHeight)
    --------------------------------------------------------------------------------
    -- DisplayText (0x86)
    --  * Updates the Hub with a number of character strings that will be displayed
    --    on connected panels if there is space.
    --  * Strings may either be 32 character, single height or 16 character
    --    double-height. They will be displayed in the order received; the first
    --    string displayed at the top of the display.
    --  * If a string is not defined as double-height then it will occupy the
    --    next line.
    --  * If a string is defined as double-height then it will occupy the next
    --    2 lines.
    --  * The maximum number of lines which will be used by the application
    --    must be indicated in the Controls XML file.
    --  * If a stateStrLen value of 0 is passed then the line will not be
    --    overwritten with any information. In this circumstance no data should be
    --    passed for stateStr and doubleHeight. The next byte will be the
    --    stateStrLen for the next string.
    --
    -- Format: 0x86, <numStrings>, (<stateStrLen>, <stateStr>, <doubleHeight>)...
    --
    -- numStrings: The number of strings to follow (Unsigned Int)
    -- stateStrLen: The length of stateStr (Unsigned Int)
    -- stateStr: A line of status text (Character String)
    -- doubleHeight: True if the string is to be printed double height. Otherwise false (Bool)
    --------------------------------------------------------------------------------
    if isNotList(messages) then
        return false, format("The `messages` must be a list of strings: %s", inspect(messages))
    end
    doubleHeight = doubleHeight or {}
    if isNotTable(doubleHeight) then
        return false, format("Invalid `doubleHeight` parameter: %s", inspect(doubleHeight))
    end

    local byteString = numberToByteString(mod.toHub.displayText) ..
                        numberToByteString(#messages)

    for i,value in ipairs(messages) do
        --------------------------------------------------------------------------------
        -- Trim to size:
        --------------------------------------------------------------------------------
        if not type(value) == "string" then
            return false, format("Invalid message #%s: %s", i, inspect(value))
        end
        local isDouble = doubleHeight[i]
        local maxLength = isDouble and 16 or 32
        value = #value > maxLength and value:sub(0, maxLength) or value

        byteString = byteString .. numberToByteString(#value)

        if #value > 0 then
            byteString = byteString .. value .. booleanToByteString(isDouble)
        end
    end

    return mod.send(byteString)
end

--- hs.tangent.sendArcDisplayText(message1[, message2]) -> boolean, string
--- Function
---  * Updates the Arc Hub with one or two character strings that will be displayed
---   on connected panels if there is space.
---  * Messages will be truncated to 19 characters long.
---
--- Example:
---
--- ```lua
--- hs.tangent.sendArcDisplayText("message 1", "message 2")
--- ```
---
--- Parameters:
---  * messages1      - The first message.
---  * message2       - The second message (optional)
---
--- Returns:
---  * `true` if successful, or `false` and an error message if not.
function mod.sendArcDisplayText(message1, message2)
    --------------------------------------------------------------------------------
    -- ArcDisplayText (0x87)
    --  * Updates the Hub with a number of character strings that will be shown on
    --    the rear displays of the Arc panels
    --  * Strings must be a maximum of 19 characters long. They will be shown in the
    --    order received; the first string displayed at the top of the display.
    --  * If a textStrLen value of 0 is passed then the line will not be overwritten
    --    with any information. In this circumstance no data should be passed for
    --    textStr. The next byte will be the textStrLen for the next string.
    --
    -- Format: 0x87, < panelID >, <numStrings>, (<textStrLen>, <textStr>, <reserved>)…
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command. (Unsigned Int)
    -- numStrings: The number of strings to follow. Maximum of 2. (Unsigned Int)
    -- textStrLen: The length of textStr The maximum value allowed is 19 bytes. (Unsigned Int)
    -- textStr: A line of status text Character. (String)
    -- reserved: Reserved for future use. (Unsigned Int)
    --------------------------------------------------------------------------------
    if type(message1) ~= "string" then
        return false, format("`message1` must be a strings: %s", inspect(message1))
    elseif message1:len() > 19 then
        return false, format("`message1` must be at most 19 characters.")
    end

    if message2 and type(message2) ~= "string" then
        return false, format("`message2` must be a strings: %s", inspect(message2))
    elseif message2 and message2:len() > 19 then
        return false, format("`message2` must be at most 19 characters.")
    end

    local byteString = numberToByteString(mod.toHub.arcDisplayText) ..
                        numberToByteString(message2 ~= nil and 2 or 1)

    byteString = byteString .. numberToByteString(message1:len())
    if message1:len() > 0 then
        byteString = byteString .. message1:sub(1, 19) .. numberToByteString(0)
    end

    if message2 then
        byteString = byteString .. numberToByteString(message2:len())
        if message2:len() > 0 then
            byteString = byteString .. message2:sub(1, 19) .. numberToByteString(0)
        end
    end

    return mod.send(byteString)
end

--- hs.tangent.sendUnmanagedPanelCapabilitiesRequest(panelID) -> boolean, string
--- Function
---  * Only used when working in Unmanaged panel mode
---  * Requests the Hub to respond with an UnmanagedPanelCapabilities (0x30) command.
---
--- Parameters:
---  * panelID - The ID of the panel as reported in the InitiateComms command (Unsigned Int)
---
--- Returns:
---  * `true` if successful, or `false` and an error message if not.
function mod.sendUnmanagedPanelCapabilitiesRequest(panelID)
    --------------------------------------------------------------------------------
    -- Format: 0xA0, <panelID>
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command (Unsigned Int)
    --------------------------------------------------------------------------------
    if not isNumber(panelID) then
        return false, format("Missing or invalid panel ID: %s", inspect(panelID))
    end
    local byteString = numberToByteString(mod.toHub.unmanagedPanelCapabilitiesRequest) ..
                        numberToByteString(panelID)

    return mod.send(byteString)
end

--- hs.tangent.sendUnmanagedDisplayWrite(panelID, displayID, lineNum, pos, message) -> boolean, string
--- Function
---  * Only used when working in Unmanaged panel mode.
---  * Updates the Hub with text that will be displayed on a specific panel at
---   the given line and starting position where supported by the panel capabilities.
---  * If the most significant bit of any individual text character in `message`
---   is set it will be displayed as inversed with dark text on a light background.
---
--- Parameters:
---  * panelID       - The ID of the panel as reported in the InitiateComms command (Unsigned Int)
---  * displayID     - The ID of the display to be written to (Unsigned Int)
---  * lineNum       - The line number of the display to be written to with `1` as the top line (Unsigned Int)
---  * pos           - The position on the line to start writing from with `1` as the first column (Unsigned Int)
---  * message       - A line of text (Character String)
---
--- Returns:
---  * `true` if successful, or `false` and an error message if not.
function mod.sendUnmanagedDisplayWrite(panelID, displayID, lineNum, pos, message)
    --------------------------------------------------------------------------------
    -- Format: 0xA1, <panelID>, <displayID>, <lineNum>, <pos>, <dispStrLen>, <dispStr>
    --
    -- panelID: The ID of the panel as reported in the InitiateComms command (Unsigned Int)
    -- displayID: The ID of the display to be written to (Unsigned Int)
    -- lineNum: The line number of the display to be written to with 0 as the top line (Unsigned Int)
    -- pos: The position on the line to start writing from with 0 as the first column (Unsigned Int)
    -- dispStrLen: The length of dispStr (Unsigned Int)
    -- dispStr: A line of text (Character String)
    --------------------------------------------------------------------------------
    if not isNumber(panelID) then
        return false, format("Missing or invalid panelID: %s", inspect(panelID))
    end
    if not isNumber(displayID) then
        return false, format("Missing or invalid displayID: %s", inspect(displayID))
    end
    if not isNumber(lineNum) or lineNum < 1 then
        return false, format("Missing or invalid lineNum: %s", inspect(lineNum))
    end
    if not isNumber(pos) or pos < 1 then
        return false, format("Missing or invalid pos: %s", inspect(pos))
    end
    if not type(message) == "string" then
        return false, format("Missing or invalid message: %s", inspect(message))
    end

    local byteString =  numberToByteString(mod.toHub.unmanagedDisplayWrite) ..
                        numberToByteString(panelID) ..
                        numberToByteString(displayID) ..
                        numberToByteString(lineNum-1) ..
                        numberToByteString(pos-1) ..
                        numberToByteString(#message) ..
                        message

    return mod.send(byteString)
end

--- hs.tangent.sendRenameControl(targetID, newName) -> boolean, string
--- Function
---  * Renames a control dynamically.
---  * The string supplied will replace the normal text which has been
---   derived from the Controls XML file.
---  * To remove any existing replacement name set `newName` to `""`,
---   this will remove any renaming and return the system to the normal
---   display text
---  * When applied to Modes, the string displayed on buttons which mapped to
---   the reserved "Go To Mode" action for this particular mode will also change.
---
--- Parameters:
---  * targetID  - The id of any application defined Parameter, Menu, Action or Mode (Unsigned Int)
---  * newName   - The new name to apply.
---
--- Returns:
---  * `true` if successful, `false` and an error message if not.
function mod.sendRenameControl(targetID, newName)
    --------------------------------------------------------------------------------
    -- Format: 0xA2, <targetID>, <nameStrLen>, <nameStr>
    --
    -- targetID: The id of any application defined Parameter, Menu, Action or Mode (Unsigned Int)
    -- nameStrLen: The length of nameStr (Unsigned Int)
    --------------------------------------------------------------------------------
    if not isNumber(targetID) then
        return false, format("Missing or invalid targetID: %s", inspect(targetID))
    end
    if not type(newName) == "string" then
        return false, format("Missing or invalid name: %s", inspect(newName))
    end

    local byteString =  numberToByteString(mod.toHub.renameControl) ..
                        numberToByteString(targetID) ..
                        numberToByteString(#newName) ..
                        newName

    return mod.send(byteString)
end

--- hs.tangent.sendHighlightControl(targetID, active) -> boolean, string
--- Function
---  * Highlights the control on any panel where this feature is available.
---  * When applied to Modes, buttons which are mapped to the reserved "Go To
---   Mode" action for this particular mode will highlight.
---
--- Parameters:
---  * targetID      - The id of any application defined Parameter, Menu, Action or Mode (Unsigned Int)
---  * active        - If `true`, the control is highlighted, otherwise it is not.
---
--- Returns:
---  * `true` if sent successfully, `false` and an error message if no.
function mod.sendHighlightControl(targetID, active)
    --------------------------------------------------------------------------------
    -- targetID: The id of any application defined Parameter, Menu, Action or Mode (Unsigned Int)
    -- state: The state to set. 1 for highlighted, 0 for clear (Unsigned Int)
    --------------------------------------------------------------------------------
    if not isNumber(targetID) then
        return false, "Missing or invalid paramater: targetID."
    end
    local state = active == true and 1 or 0

    local byteString = numberToByteString(mod.toHub.highlightControl) ..
                        numberToByteString(targetID) ..
                        numberToByteString(state)

    return mod.send(byteString)
end

--- hs.tangent.sendIndicateControl(targetID, indicated) -> boolean, string
--- Function
---  * Sets the Indicator of the control on any panel where this feature is
---   available.
---  * This indicator is driven by the `atDefault` argument for Parameters and
---   Menus. This command therefore only applies to controls mapped to Actions
---   and Modes.
---  * When applied to Modes, buttons which are mapped to the reserved "Go To
---   Mode" action for this particular mode will have their indicator set.
---
--- Parameters:
---  * targetID      - The id of any application defined Parameter, Menu, Action or Mode
---  * active        - If `true`, the control is indicated, otherwise it is not.
---
--- Returns:
---  * `true` if sent successfully, `false` and an error message if no.
function mod.sendIndicateControl(targetID, active)
    --------------------------------------------------------------------------------
    -- Format: 0xA4, <targetID>, <state>
    --
    -- targetID: The id of any application defined Action or Mode (Unsigned Int)
    -- state: The state to set. 1 for indicated, 0 for clear (Unsigned Int)
    --------------------------------------------------------------------------------
    if not isNumber(targetID) then
        return false, "Missing or invalid paramater: targetID."
    end
    local state = active == true and 1 or 0

    local byteString = numberToByteString(mod.toHub.indicateControl) ..
                        numberToByteString(targetID) ..
                        numberToByteString(state)

    return mod.send(byteString)
end

--- hs.tangent.sendPanelConnectionStatesRequest() -> boolean, string
--- Function
---  Requests the Hub to respond with a sequence of PanelConnectionState
--- (0x35) commands to report the connected/disconnected status of each
--- configured panel. A single request may result in multiple state responses.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if sent successfully, `false` and an error message if not.
function mod.sendPanelConnectionStatesRequest()
    --------------------------------------------------------------------------------
    -- Format: 0xA5
    --------------------------------------------------------------------------------
    local byteString = numberToByteString(mod.toHub.panelConnectionStatesRequest)

    return mod.send(byteString)
end

--- hs.tangent.sendCustomParameterValue(controlID, value, atDefault) -> boolean, string
--- Function
--- Updates the Hub with a custom parameter value. The Hub then updates the displays
--- of any panels which are currently showing the parameter value.
---
--- Parameters:
---  * controlID    - the `string` ID value of the control being sent. Maximum length 128 bytes.
---  * value        - floating-point `number` with the current value.
---  * atDefault    - if `true`, the value is the default for this parameter.
---
--- Returns:
---  * `true` if sent successfully, `false` and an error message if not.
function mod.sendCustomParameterValue(controlID, value, atDefault)
    --------------------------------------------------------------------------------
    -- Format: 0xA6, <controlStrLen>, <controlStr>, <value>, <atDefault>
    --
    -- controlStrLen: The length of controlStr.
    --                The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    -- value: The current value of the parameter. (Float)
    -- atDefault: True if the value represents the default. Otherwise false. (Bool)
    --------------------------------------------------------------------------------
    if controlID:len() > 128 then
        error("controlID must be a maximum of 128 bytes, but was " .. tostring(controlID:len()))
    end
    local byteString = numberToByteString(mod.toHub.customParameterValue) ..
                        numberToByteString(#controlID) ..
                        controlID ..
                        floatToByteString(value) ..
                        booleanToByteString(atDefault)

    return mod.send(byteString)
end

--- hs.tangent.sendCustomMenuString(controlID, value, atDefault) -> boolean, string
--- Function
--- Updates the Hub with a custom menu value. The Hub then updates the displays of any panels which are
--- currently showing the menu. If the value is `nil` or an empty string, the Hub will not attempt to
--- display a value for the menu. However the `atDefault` flag will still be recognised.
---
--- Parameters:
---  * controlID    - the `string` ID value of the control being sent. Maximum length 128 bytes.
---  * value        - `string` representing the current value of the parameter. Max 256 bytes.
---  * atDefault    - if `true`, the value is the default for this parameter.
---
--- Returns:
---  * `true` if sent successfully, `false` and an error message if not.
function mod.sendCustomMenuString(controlID, value, atDefault)
    --------------------------------------------------------------------------------
    -- Format: 0xA7, <controlStrLen>, <controlStr>, <valueStrLen>, <valueStr>, <atDefault>
    --
    -- controlStrLen: The length of controlStr.
    --                The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    -- valueStrLen: The length of valueStr The maximum value allowed is 256 bytes. (Unsigned Int)
    -- valueStr: The current ‘value’ of the parameter represented as a string (Character String)
    -- atDefault: True if the value represents the default. Otherwise false. (Bool)
    --------------------------------------------------------------------------------
    if controlID:len() > 128 then
        error("controlID must be a maximum of 128 bytes, but was " .. tostring(controlID:len()))
    end
    value = value:sub(1, 256)
    local byteString = numberToByteString(mod.toHub.customMenuString) ..
                        numberToByteString(#controlID) ..
                        controlID ..
                        numberToByteString(value:len()) ..
                        value ..
                        booleanToByteString(atDefault)

    return mod.send(byteString)
end

--- hs.tangent.sendRenameCustomControl(controlID, name) -> boolean, string
--- Function
--- Renames a custom control dynamically. The string supplied will replace the normal.
--- To remove any existing replacement name set name to `nil`, this will remove
--- any renaming and return the system to the normal display text.
---
--- Parameters:
---  * controlID    - the `string` ID value of the control being sent. Maximum length 128 bytes.
---  * value        - `string` representing the current value of the parameter. Max 256 bytes.
---
--- Returns:
---  * `true` if sent successfully, `false` and an error message if not.
function mod.sendRenameCustomControl(controlID, name)
    --------------------------------------------------------------------------------
    -- Format: 0xA8, <controlStrLen>, <controlStr>, <nameStrLen>, <nameStr>
    --
    -- controlStrLen: The length of controlStr.
    --                The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    -- nameStrLen: The length of nameStr. (Unsigned Int)
    -- nameStr: The new name string. (Character String)
    --------------------------------------------------------------------------------
    if controlID:len() > 128 then
        error("controlID must be a maximum of 128 bytes, but was " .. tostring(controlID:len()))
    end
    name = name or ""
    local byteString = numberToByteString(mod.toHub.renameCustomControl) ..
                        numberToByteString(#controlID) ..
                        controlID ..
                        numberToByteString(name:len()) ..
                        name

    return mod.send(byteString)
end

--- hs.tangent.sendHighlightCustomControl(controlID, highlighted) -> boolean, string
--- Function
--- Highlights the control on any panel where this feature is available.
---
--- Parameters:
---  * controlID    - the `string` ID value of the control being sent. Maximum length 128 bytes.
---  * enabled      - If `true`, the highlight will be enabled (if supported).
---
--- Returns:
---  * `true` if sent successfully, `false` and an error message if not.
function mod.sendHighlightCustomControl(controlID, enabled)
    --------------------------------------------------------------------------------
    -- Format: 0xA9, <controlStrLen>, <controlStr>, <state>
    --
    -- controlStrLen: The length of controlStr.
    --                The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    -- state: The state to set. 1 for highlighted, 0 for clear. (Unsigned Int)
    --------------------------------------------------------------------------------
    if controlID:len() > 128 then
        error("controlID must be a maximum of 128 bytes, but was " .. tostring(controlID:len()))
    end
    local byteString = numberToByteString(mod.toHub.highlightCustomControl) ..
                        numberToByteString(#controlID) ..
                        controlID ..
                        numberToByteString(enabled and 1 or 0)

    return mod.send(byteString)
end

--- hs.tangent.sendIndicateCustomControl(controlID, enabled) -> boolean, string
--- Function
--- Sets the Indicator of the control on any panel where this feature is available.
--- This indicator is driven by the atDefault argument for Parameters and Menus.
--- This command therefore only applies to controls mapped to Actions.
---
--- Parameters:
---  * controlID    - the `string` ID value of the control being sent. Maximum length 128 bytes.
---  * enabled      - If `true`, the indicator will be enabled (if supported).
---
--- Returns:
---  * `true` if sent successfully, `false` and an error message if not.
function mod.sendIndicateCustomControl(controlID, enabled)
    --------------------------------------------------------------------------------
    -- Format: 0xAA, <controlStrLen>, <controlStr>, <state>
    --
    -- controlStrLen: The length of controlStr.
    --                The maximum length allowed is 128 bytes. (Unsigned Int)
    -- controlStr: A string containing the identifier for the custom control mapping. (Character String)
    -- state: The state to set. 1 for highlighted, 0 for clear. (Unsigned Int)
    --------------------------------------------------------------------------------
    if controlID:len() > 128 then
        error("controlID must be a maximum of 128 bytes, but was " .. tostring(controlID:len()))
    end
    local byteString = numberToByteString(mod.toHub.indiateCustomControl) ..
                        numberToByteString(#controlID) ..
                        controlID ..
                        numberToByteString(enabled and 1 or 0)

    return mod.send(byteString)
end

-- notifyDisconnected() -> none
-- Function
-- Triggers the disconnection notification callback and stops the Connection Watcher.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function notifyDisconnected()
    if mod._callback then
        mod._callback({{id=mod.fromHub.disconnected, metadata={
            ipAddress = mod.ipAddress,
            port = mod.port,
        }}})
    end
    if mod._connectionWatcher then mod._connectionWatcher:stop() end
end

-- hs.tangent._connectionWatcher -> timer
-- Variable
-- Tracks the Tangent socket connection.
mod._connectionWatcher = timer.new(1.0, function()
    if not mod.connected() then
        mod._socket = nil
        notifyDisconnected()
    end
end)

--- hs.tangent.disconnect() -> none
--- Function
--- Disconnects from the Tangent Hub.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.disconnect()
    if mod._socket then
        mod._socket:disconnect()
        mod._socket = nil
        notifyDisconnected()
        mod._connectionWatcher:stop()
    end
end

-- MESSAGE_SIZE -> number
-- Constant
-- Message Size.
local MESSAGE_SIZE = 1

-- MESSAGE_BODY -> number
-- Constant
-- Message Body.
local MESSAGE_BODY = 2

-- socketCallback(data, tag) -> none
-- Function
-- Tangent Socket Callback Function.
--
-- Parameters:
--  * data - The data read from the socket as a string
--  * tag - The integer tag associated with the read call, which defaults to -1
--
-- Returns:
--  * None
local function socketCallback(data, tag)
    --log.df("Received data: size=%s; tag=%s", #data, inspect(tag))
    if tag == MESSAGE_SIZE then
        --------------------------------------------------------------------------------
        -- Each message starts with an integer value indicating the number of bytes.
        --------------------------------------------------------------------------------
        local messageSize = byteStringToNumber(data, 1, 4)
        if mod._socket then
            mod._socket:read(messageSize, MESSAGE_BODY)
        else
            log.ef("Tangent: The Socket doesn't exist anymore.")
        end
    elseif tag == MESSAGE_BODY then
        --------------------------------------------------------------------------------
        -- We've read the rest of series of commands:
        --------------------------------------------------------------------------------
        processDataFromHub(data)

        --------------------------------------------------------------------------------
        -- Get set up for the next series of commands:
        --------------------------------------------------------------------------------
        if mod._socket then
            mod._socket:read(4, MESSAGE_SIZE)
        else
            log.ef("Tangent: The Socket doesn't exist anymore.")
        end
    else
        log.ef("Tangent: Unknown Tag or Data from Socket.")
    end
end

--- hs.tangent.connect(applicationName, systemPath[, userPath[, task]]) -> boolean, errorMessage
--- Function
--- Connects to the Tangent Hub.
---
--- Parameters:
---  * applicationName - Your application name as a string
---  * systemPath - A string containing the absolute path of the directory that contains the Controls and Default Map XML files.
---  * userPath - An optional string containing the absolute path of the directory that contains the User’s Default Map XML files.
---  * task - An optional string containing the name of the task associated with the application.
---         This is used to assist with automatic switching of panels when your application gains mouse focus on the GUI.
---         This parameter should only be required if the string passed in appStr does not match the Task name that the OS
---         identifies as your application. Typically, this is only usually required for Plugins which run within a parent
---         Host application. Under these circumstances it is the name of the Host Application’s Task which should be passed.
---
--- Returns:
---  * success - `true` on success, otherwise `nil`
---  * errorMessage - The error messages as a string or `nil` if `success` is `true`.
function mod.connect(applicationName, systemPath, userPath, task)

    --------------------------------------------------------------------------------
    -- Check Paramaters:
    --------------------------------------------------------------------------------
    if not applicationName or type(applicationName) ~= "string" then
        return nil, "applicationName is a required string."
    end
    if systemPath and type(systemPath) == "string" then
        local attr = fs.attributes(systemPath)
        if not attr or attr.mode ~= 'directory' then
            return nil, "systemPath must be a valid path."
        end
    else
        return nil, "systemPath is a required string."
    end
    if userPath and type(userPath) == "string" then
        local attr = fs.attributes(userPath)
        if not attr or attr.mode ~= 'directory' then
            return nil, "userPath must be a valid path."
        end
    end

    --------------------------------------------------------------------------------
    -- Save values for later:
    --------------------------------------------------------------------------------
    mod._applicationName = applicationName
    mod._systemPath = systemPath
    mod._userPath = userPath
    mod._task = task

    --------------------------------------------------------------------------------
    -- Connect to Tangent Hub:
    --------------------------------------------------------------------------------
    mod._socket = socket.new()
    if mod._socket then
        mod._socket:setCallback(socketCallback)
        :connect(mod.ipAddress, mod.port, function()
            --------------------------------------------------------------------------------
            -- Trigger Callback when connected:
            --------------------------------------------------------------------------------
            if mod._callback then
                mod._callback({{id=mod.fromHub.connected, metadata={
                    ipAddress = mod.ipAddress,
                    port = mod.port,
                }}})
            end

            --------------------------------------------------------------------------------
            -- Watch for disconnections:
            --------------------------------------------------------------------------------
            mod._connectionWatcher:start()

            --------------------------------------------------------------------------------
            -- Read the first 4 bytes, which will trigger the callback:
            --------------------------------------------------------------------------------
            mod._socket:read(4, MESSAGE_SIZE)
        end)
    end
    return mod._socket ~= nil or nil

end

return mod