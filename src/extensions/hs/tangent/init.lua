--- === hs.tangent ===
---
--- Tangent Control Surface Extension
---
--- This plugin allows Hammerspoon to communicate with Tangent's range of
--- panels (such as their Element, Virtual Element Apps, Wave, Ripple and any future panels).
---
--- Download the Tangent Developer Support Pack & Tangent Hub Installer for Mac here:
--- http://www.tangentwave.co.uk/developer-support/

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

local log         								= require("hs.logger").new("tangent")
local socket    								= require("hs.socket");
local fs										= require("hs.fs")
local timer										= require("hs.timer")
local utf8         								= require("hs.utf8")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local mod = {}

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

--- hs.tangent.LISTENING_PORT -> number
--- Constant
--- The port that Tangent Hub monitors.
mod.LISTENING_PORT = 64246

--- hs.tangent.LISTENING_IP -> number
--- Constant
--- IP Address that the Tangent Hub is located at.
mod.LISTENING_IP = "127.0.0.1"

--- hs.tangent.INTERVAL -> number
--- Constant
--- How often we check for new socket messages.
mod.INTERVAL = 0.001

--- hs.tangent.HUB_MESSAGE -> table
--- Constant
--- Definitions for IPC Commands from the HUB to Hammerspoon.
mod.HUB_MESSAGE = {
    ["INITIATE_COMMS"]                          = 0x01,
    ["PARAMETER_CHANGE"]                        = 0x02,
    ["PARAMETER_RESET"]                         = 0x03,
    ["PARAMETER_VALUE_REQUEST"]                 = 0x04,
    ["MENU_CHANGE"]                             = 0x05,
    ["MENU_RESET"]                              = 0x06,
    ["MENU_STRING_REQUEST"]                     = 0x07,
    ["ACTION_ON"]                               = 0x08,
    ["MODE_CHANGE"]                             = 0x09,
    ["TRANSPORT"]                               = 0x0A,
    ["ACTION_OFF"]                              = 0x0B,
    ["UNMANAGED_PANEL_CAPABILITIES"]            = 0x30,
    ["UNMANAGED_BUTTON_DOWN"]                   = 0x31,
    ["UNMANAGED_BUTTON_UP"]                     = 0x32,
    ["UNMANAGED_ENCODER_CHANGE"]                = 0x33,
    ["UNMANAGED_DISPLAY_REFRESH"]               = 0x34,
    ["PANEL_CONNECTION_STATE"]                  = 0x35,
}

--- hs.tangent.APP_MESSAGE -> table
--- Constant
--- Definitions for IPC Commands from Hammerspoon to the HUB.
mod.APP_MESSAGE = {
    ["APPLICATION_DEFINITION"]                  = 0x81,
    ["PARAMETER_VALUE"]                         = 0x82,
    ["MENU_STRING"]                             = 0x83,
    ["ALL_CHANGE"]                              = 0x84,
    ["MODE_VALUE"]                              = 0x85,
    ["DISPLAY_TEXT"]                            = 0x86,
    ["UNMANAGED_PANEL_CAPABILITIES_REQUEST"]    = 0xA0,
    ["UNMANAGED_DISPLAY_WRITE"]                 = 0xA1,
    ["RENAME_CONTROL"]                          = 0xA2,
    ["HIGHLIGHT_CONTROL"]                       = 0xA3,
    ["INDICATE_CONTROL"]                        = 0xA4,
    ["REQUEST_PANEL_CONNECTION_STATES"]         = 0xA5,
}

--- hs.tangent.PANEL_TYPE -> table
--- Constant
--- Tangent Panel Types.
mod.PANEL_TYPE = {
    ["CP200-BK"]                                = 0x03,
    ["CP200-K"]                                 = 0x04,
    ["CP200-TS"]                                = 0x05,
    ["CP200-S"]                                 = 0x09,
    ["Wave"]                                    = 0x0A,
    ["Element-Tk"]                              = 0x0C,
    ["Element-Mf"]                              = 0x0D,
    ["Element-Kb"]                              = 0x0E,
    ["Element-Bt"]                              = 0x0F,
    ["Ripple"]                                  = 0x11,
}

--------------------------------------------------------------------------------
--
-- HELPER FUNCTIONS:
--
--------------------------------------------------------------------------------

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
    for i,v in pairs(mod.PANEL_TYPE) do
        if id == v then
            return i
        end
    end
end

-- byteStringToNumber(str, offset, numberOfBytes) -> number
-- Function
-- Translates a Byte String into a Number
--
-- Parameters:
--  * str - The string you want to translate
--  * offset - An offset
--  * numberOfBytes - Number of bytes
--
-- Returns:
--  * A number
local function byteStringToNumber(str, offset, numberOfBytes)
  assert(numberOfBytes >= 1 and numberOfBytes <= 4)
  local x = 0
  for i = 1, numberOfBytes do
    x = x * 0x0100
    x = x + math.fmod(string.byte(str, i + offset - 1) or 0, 0x0100)
  end
  return x
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
    local t = {}
    local char = string.char
    t[1] = char(n >> 24 & 0xFF)
    t[2] = char(n >> 16 & 0xFF)
    t[3] = char(n >> 08 & 0xFF)
    t[4] = char(n >> 00 & 0xFF)
    return table.concat(t)
end

-- buildMessage(msgType, msgParts) -> string
-- Function
-- Builds a message
--
-- Parameters:
--  * msgType - The messages type as defined in `hs.tangent.APP_MESSAGE`.
--  * msgParts - A table containing individual message parts.
--
-- Returns:
--  * A byte string in the form of a string
local function buildMessage(msgType, msgParts)
    local byteString = numberToByteString(msgType)

    for _,partValue in pairs(msgParts) do
        byteString = byteString .. numberToByteString(#partValue)
        byteString = byteString .. partValue
    end

    --log.df("buildMessage constructed: "..utf8.hexDump(byteString))
    return byteString
end

local function sendApplicationDefinition()
	--------------------------------------------------------------------------------
	-- Respond with ApplicationDefinition (0x81):
	--------------------------------------------------------------------------------
	log.df("Responding with ApplicationDefinition (0x81)")
	local byteString = buildMessage(mod.APP_MESSAGE["APPLICATION_DEFINITION"], {mod._applicationName, mod._xmlPath, ""})
	mod._socket:send(numberToByteString(#byteString)..byteString)
end

-- processHubCommand(data) -> none
-- Function
-- Processes a HUB Command.
--
-- Parameters:
--  * data - The raw data from the socket.
--
-- Returns:
--  * None
local function processHubCommand(data)
    local id = byteStringToNumber(data, 1, 4)
    if id == mod.HUB_MESSAGE["INITIATE_COMMS"] then
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
        -- 0x01, <protocolRev>, <numPanels>, (<mod.PANEL_TYPE>, <panelID>)...
        --------------------------------------------------------------------------------
        log.df("InitiateComms (0x01) Triggered:")

        local protocolRev = byteStringToNumber(data, 5, 4)
        local numberOfPanels = byteStringToNumber(data, 9, 4)

        log.df("    Protocol Revision: %s", protocolRev)
        log.df("    Number of Panels: %s", numberOfPanels)

        local startNumber = 13
        for i=1, numberOfPanels do
            local currentPanelType = byteStringToNumber(data, startNumber, 4)
            startNumber = startNumber + 4
            local currentPanelID = byteStringToNumber(data, startNumber, 4)
            startNumber = startNumber + 4
            log.df("    Panel Type: %s (%s)", getPanelType(currentPanelType), currentPanelID)
        end

        --------------------------------------------------------------------------------
        -- Send Application Definition:
        --------------------------------------------------------------------------------
        sendApplicationDefinition()
	elseif id == mod.HUB_MESSAGE["PARAMETER_CHANGE"] then
		--------------------------------------------------------------------------------
		-- ParameterChange (0x02)
		--  * Requests that the application increment a parameter. The application needs
		--    to constrain the value to remain within its maximum and minimum values.
		--  * On receipt the application should respond to the Hub with the new
		--    absolute parameter value using the ParameterValue (0x82) command,
		--    if the value has changed.
		--
		-- 0x02, <paramID>, <increment>
		--------------------------------------------------------------------------------
		local paramID = byteStringToNumber(data, 5, 4)
		local increment = byteStringToNumber(data, 9, 4)
		if paramID and increment then
			mod._callback("PARAMETER_CHANGE", {
				["paramID"] = paramID,
				["increment"] = increment
			})
		else
			log.ef("Error translating PARAMETER_CHANGE.")
		end
	elseif id == mod.HUB_MESSAGE["PARAMETER_RESET"] then
		--------------------------------------------------------------------------------
		-- ParameterReset (0x03)
		--  * Requests that the application changes a parameter to its reset value.
		--  * On receipt the application should respond to the Hub with the new absolute
		--    parameter value using the ParameterValue (0x82) command, if the value
		--    has changed.
		--
		-- 0x03, <paramID>
		--------------------------------------------------------------------------------
		local paramID = byteStringToNumber(data, 5, 4)
		if paramID then
			mod._callback("PARAMETER_RESET", {
				["paramID"] = paramID
			})
		else
			log.ef("Error translating PARAMETER_RESET.")
		end
	elseif id == mod.HUB_MESSAGE["PARAMETER_VALUE_REQUEST"] then
		--------------------------------------------------------------------------------
		-- ParameterValueRequest (0x04)
		--  * Requests that the application sends a ParameterValue (0x82) command
		--    to the Hub.
		--
		-- 0x04, <paramID>
		--------------------------------------------------------------------------------
		local paramID = byteStringToNumber(data, 5, 4)
		if paramID then
			mod._callback("PARAMETER_VALUE_REQUEST", {
				["paramID"] = paramID
			})
		else
			log.ef("Error translating PARAMETER_VALUE_REQUEST.")
		end
	elseif id == mod.HUB_MESSAGE["MENU_CHANGE"] then
		--------------------------------------------------------------------------------
		-- MenuChange (0x05)
		--  * Requests the application change a menu index by +1 or -1.
		--  * We recommend that menus that only have two values (e.g. on/off) should
		--    toggle their state on receipt of either a +1 or -1 increment value.
		--    This will allow a single button to toggle the state of such an item
		--    without the need for separate ‘up’ and ‘down’ buttons.
		--
		-- 0x05, <menuID>, < increment >
		--------------------------------------------------------------------------------
		local menuID = byteStringToNumber(data, 5, 4)
		local increment = byteStringToNumber(data, 9, 4)
		if paramID and increment then
			mod._callback("MENU_CHANGE", {
				["menuID"] = menuID,
				["increment"] = increment
			})
		else
			log.ef("Error translating MENU_CHANGE.")
		end
	elseif id == mod.HUB_MESSAGE["MENU_RESET"] then
		--------------------------------------------------------------------------------
		-- MenuReset (0x06)
		--  * Requests that the application sends a MenuString (0x83) command to the Hub.
		--
		-- 0x06, <menuID>
		--------------------------------------------------------------------------------
		local menuID = byteStringToNumber(data, 5, 4)
		if menuID then
			mod._callback("MENU_RESET", {
				["menuID"] = menuID
			})
		else
			log.ef("Error translating MENU_RESET.")
		end
	elseif id == mod.HUB_MESSAGE["MENU_STRING_REQUEST"] then
		--------------------------------------------------------------------------------
		-- MenuStringRequest (0x07)
		--  * Requests that the application sends a MenuString (0x83) command to the Hub.
		--  * On receipt, the application should respond to the Hub with the new menu
		--    value using the MenuString (0x83) command, if the menu has changed.
		--
		-- 0x07, <menuID>
		--------------------------------------------------------------------------------
		local menuID = byteStringToNumber(data, 5, 4)
		if menuID then
			mod._callback("MENU_STRING_REQUEST", {
				["menuID"] = menuID
			})
		else
			log.ef("Error translating MENU_STRING_REQUEST.")
		end
	elseif id == mod.HUB_MESSAGE["ACTION_ON"] then
		--------------------------------------------------------------------------------
		-- Action On (0x08)
		--  * Requests that the application performs the specified action.
		--
		-- 0x08, <actionID>
		--------------------------------------------------------------------------------
		local actionID = byteStringToNumber(data, 5, 4)
		if actionID then
			mod._callback("ACTION_ON", {
				["actionID"] = actionID
			})
		else
			log.ef("Error translating ACTION_ON.")
		end
	elseif id == mod.HUB_MESSAGE["MODE_CHANGE"] then
		--------------------------------------------------------------------------------
		-- ModeChange (0x09)
		--  * Requests that the application changes to the specified mode.
		--
		-- 0x09, <modeID>
		--------------------------------------------------------------------------------

	elseif id == mod.HUB_MESSAGE["TRANSPORT"] then
		--------------------------------------------------------------------------------
		-- Transport (0x0A)
		--  * Requests the application to move the currently active transport.
		--  * jogValue or shuttleValue will never both be set simultaneously
		--  * One revolution of the control represents 32 counts by default.
		--    The user will be able to adjust the sensitivity of Jog & Shuttle
		--    independently in the TUBE Mapper tool to send more or less than
		--    32 counts per revolution.
		--
		-- 0x0A, <jogValue>, <shuttleValue>
		--------------------------------------------------------------------------------

	elseif id == mod.HUB_MESSAGE["ACTION_OFF"] then
		--------------------------------------------------------------------------------
		-- ActionOff (0x0B)
		--  * Requests that the application cancels the specified action.
		--  * This is typically sent when a button is released.
		--
		-- 0x0B, <actionID>
		--------------------------------------------------------------------------------
		local actionID = byteStringToNumber(data, 5, 4)
		if actionID then
			mod._callback("ACTION_OFF", {
				["actionID"] = actionID
			})
		else
			log.ef("Error translating ACTION_OFF.")
		end
	elseif id == mod.HUB_MESSAGE["UNMANAGED_PANEL_CAPABILITIES"] then
		--------------------------------------------------------------------------------
		-- UnmanagedPanelCapabilities (0x30)
		--  * Only used when working in Unmanaged panel mode.
		--  * Sent in response to a UnmanagedPanelCapabilitiesRequest (0xA0) command.
		--  * The values returned are those given in the table in Section 18.
		--    Panel Data for Unmanaged Mode.
		--
		-- 0x30, <panelID>, <numButtons>, <numEncoders>, <numDisplays>, <numDisplayLines>, <numDisplayChars>
		--------------------------------------------------------------------------------
	elseif id == mod.HUB_MESSAGE["UNMANAGED_BUTTON_DOWN"] then
		--------------------------------------------------------------------------------
		-- UnmanagedButtonDown (0x31)
		--  * Only used when working in Unmanaged panel mode
		--  * Issued when a button has been pressed
		--
		-- 0x31, <panelID>, <buttonID>
		--------------------------------------------------------------------------------
	elseif id == mod.HUB_MESSAGE["UNMANAGED_BUTTON_UP"] then
		--------------------------------------------------------------------------------
		-- UnmanagedButtonUp (0x32)
		--  * Only used when working in Unmanaged panel mode.
		-- 	* Issued when a button has been released
		--
		-- 0x32, <panelID>, <buttonID>
		--------------------------------------------------------------------------------
	elseif id == mod.HUB_MESSAGE["UNMANAGED_ENCODER_CHANGE"] then
		--------------------------------------------------------------------------------
		-- UnmanagedEncoderChange (0x33)
		--  * Only used when working in Unmanaged panel mode.
		--  * Issued when an encoder has been moved.
		--
		-- 0x33, <panelID>, <encoderID>, <increment>
		--------------------------------------------------------------------------------
	elseif id == mod.HUB_MESSAGE["UNMANAGED_DISPLAY_REFRESH"] then
		--------------------------------------------------------------------------------
		-- UnmanagedDisplayRefresh (0x34)
		--  * Only used when working in Unmanaged panel mode
		--	* Issued when a panel has been connected or the focus of the panel has
		--    been returned to your application.
		--  * On receipt your application should send all the current information to
		--    each display on the panel in question.
		--
		-- 0x34, <panelID>
		--------------------------------------------------------------------------------
	elseif id == mod.HUB_MESSAGE["PANEL_CONNECTION_STATE"] then
		--------------------------------------------------------------------------------
		-- PanelConnectionState (0x35)
		--  * Sent in response to a PanelConnectionStatesRequest (0xA5) command to
		--    report the current connected/disconnected status of a configured panel.
		--
		-- 0x35, <panelID>, <state>
		--------------------------------------------------------------------------------
    else
    	--------------------------------------------------------------------------------
    	-- Unknown Message:
    	--------------------------------------------------------------------------------
    	local hexDump = utf8.hexDump(data)
        log.df("Unknown message received from Tangent Hub:\n%s", hexDump)
    end
end

--------------------------------------------------------------------------------
--
-- FUNCTIONS & METHODS:
--
--------------------------------------------------------------------------------

-- hs.tangent.setLogLevel(loglevel) -> none
-- Function
-- Sets the Log Level.
--
-- Parameters:
--  * loglevel - can be 'nothing', 'error', 'warning', 'info', 'debug', or 'verbose'; or a corresponding number between 0 and 5
--
-- Returns:
--  * None
function mod.setLogLevel(loglevel)
	log:setLogLevel(loglevel)
	socket.setLogLevel(loglevel)
end

-- hs.tangent._readBytesRemaining -> number
-- Variable
-- Number of read bytes remaining.
mod._readBytesRemaining = 0

-- hs.tangent._applicationName -> number
-- Variable
-- Application name as specified in `hs.tangent.connect()`
mod._applicationName = nil

-- hs.tangent._readBytesRemaining -> number
-- Variable
-- XML path as specified in `hs.tangent.connect()`
mod._xmlPath = nil

-- hs.tangent.isTangentHubInstalled() -> none
-- Function
-- Checks to see whether or not the Tangent Hub software is installed.
--
-- Parameters:
--  * applicationName - Your application name as a string
--  * xmlPath - Path to the Tangent XML configuration files as a string
--
-- Returns:
--  * `true` on successful connection, `false` on failed connection or `nil` on error.
function mod.isTangentHubInstalled()
	if doesFileExist("/Library/Application Support/Tangent/Hub/TangentHub") then
		return true
	else
		return false
	end
end

-- hs.tangent.callback() -> boolean
-- Function
-- Sets a callback when new messages are received.
--
-- Parameters:
--  * callbackFn - The callback function or `nil` if you want to clear the callback.
--
-- Returns:
--  * `true` if successful otherwise `false`
function mod.callback(callbackFn)
	if type(callbackFn) == "function" then
		mod._callback = callbackFn
		return true
	elseif type(callbackFn) == "nil" then
		log.df("Resetting callback function")
		mod._callback = nil
		return true
	else
		log.ef("Callback recieved an invalid value: %s", type(callbackFn))
		return false
	end
end

-- hs.tangent.disconnect() -> none
-- Function
-- Disconnects from the Tangent Hub.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod.disconnect()
	if mod._socket then
		mod._socket:disconnect()
		mod._socket = nil
	end
end

-- hs.tangent.connect() -> boolean, errorMessage
-- Function
-- Connects to the Tangent Hub.
--
-- Parameters:
--  * applicationName - Your application name as a string
--  * xmlPath - Path to the Tangent XML configuration files as a string
--
-- Returns:
--  * `true` on success, otherwise `nil`
--  * Any error messages as a string
function mod.connect(applicationName, xmlPath)

	--------------------------------------------------------------------------------
	-- Check Paramaters:
	--------------------------------------------------------------------------------
	if not applicationName or type(applicationName) ~= "string" then
		return nil, "applicationName is a required string."
	end
	if xmlPath and type(xmlPath) == "string" then
		local attr = fs.attributes(xmlPath)
    	if not attr or attr.mode ~= 'directory' then
			return nil, "xmlPath must be a valid path."
    	end
	else
		return nil, ("xmlPath is a required string.")
	end

	--------------------------------------------------------------------------------
	-- Save values for later:
	--------------------------------------------------------------------------------
	mod._applicationName = applicationName
	mod._xmlPath = xmlPath

	--------------------------------------------------------------------------------
	-- Connect to HUB:
	--------------------------------------------------------------------------------
	log.df("Connecting to Tangent Hub...")
	mod._socket = socket.new()
		:setCallback(function(data, tag)
			--local hexDump = utf8.hexDump(data)
			--log.df("Received data: "..hexDump)
			if mod._readBytesRemaining == 0 then
				--------------------------------------------------------------------------------
				-- Each message starts with an integer value indicating the number of bytes
				-- to follow. We don't have any bytes left to read of a previous message,
				-- so this must be the first 4 bytes:
				--------------------------------------------------------------------------------
				mod._readBytesRemaining = byteStringToNumber(data, 1, 4)
				--log.df("New command received from hub, of length: "..mod._readBytesRemaining)
				timer.doAfter(mod.INTERVAL, function() mod._socket:read(mod._readBytesRemaining) end)
			else
				--------------------------------------------------------------------------------
				-- We've read the rest of a command:
				--------------------------------------------------------------------------------
				mod._readBytesRemaining = 0
				processHubCommand(data)

				--------------------------------------------------------------------------------
				-- Get set up for the next command:
				--------------------------------------------------------------------------------
				timer.doAfter(mod.INTERVAL, function() mod._socket:read(4) end)
			end
		end)
		:connect(mod.LISTENING_IP, mod.LISTENING_PORT, function()
			log.df("Connection To Tangent Hub successfully established.")
			--------------------------------------------------------------------------------
			-- Read the first 4 bytes, which will trigger the callback:
			--------------------------------------------------------------------------------
			mod._socket:read(4)
		end)

	return mod._socket ~= nil or nil

end

return mod