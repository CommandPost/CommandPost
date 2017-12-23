--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.manager ===
---
--- Tangent Control Surface Manager
---
--- This plugin allows Hammerspoon to communicate with Tangent's range of
--- panels (Element, Virtual Element Apps, Wave, Ripple and any future panels).
---
--- Download the Tangent Developer Support Pack & Tangent Hub Installer for Mac
--- here: http://www.tangentwave.co.uk/developer-support/

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("tangent")

local inspect									= require("hs.inspect")
local socket									= require("hs.socket")
local timer										= require("hs.timer")
local utf8										= require("hs.utf8")

local config									= require("cp.config")
local prop										= require("cp.prop")
local tools										= require("cp.tools")

--
-- We want to see all the logs whilst we're still testing:
--
socket.setLogLevel('verbose')

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local mod = {}

--- plugins.core.tangent.manager.LISTENING_PORT -> number
--- Constant
--- The port that Tangent Hub monitors.
mod.LISTENING_PORT = 64246

--- plugins.core.tangent.manager.LOCALHOST -> number
--- Constant
--- Local Host
mod.LOCALHOST = "127.0.0.1"

--- plugins.core.tangent.manager.INTERVAL -> number
--- Constant
--- How often we check for new socket messages
mod.INTERVAL = 0.001

--- plugins.core.tangent.manager.HUB_MESSAGE -> table
--- Constant
--- Definitions for IPC Commands from the HUB to CommandPost.
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

--- plugins.core.tangent.manager.PANEL_TYPE -> table
--- Constant
--- Tangent Panel Types
mod.PANEL_TYPE = {
	["CP200-BK"]								= 0x03,
	["CP200-K"]									= 0x04,
	["CP200-TS"]								= 0x05,
	["CP200-S"]									= 0x09,
	["Wave"]									= 0x0A,
	["Element-Tk"]								= 0x0C,
	["Element-Mf"]								= 0x0D,
	["Element-Kb"]								= 0x0E,
	["Element-Bt"]								= 0x0F,
	["Ripple"]									= 0x11,
}

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

--- plugins.core.tangent.manager.messageBuffer -> table
--- Variable
--- Incoming Message Buffer
mod.messageBuffer = {}

--- plugins.core.tangent.manager.messageLength -> number
--- Variable
--- Incoming Message Length
mod.messageLength = 0

--- plugins.core.tangent.manager.v -> number
--- Variable
--- Incoming Message Count
mod.messageCount = 0

--- plugins.core.tangent.manager.sendApplicationDefinition() -> none
--- Function
--- Sends the Application Definition Data to the Hub.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.sendApplicationDefinition()

	--------------------------------------------------------------------------------
	-- This has been hardcoded for testing purposes:
	--------------------------------------------------------------------------------
	byteArray = {
		0x00, 0x00, 0x00, 0x7B, 	-- 123 bytes below:
		0x00, 0x00, 0x00, 0x81,		-- ApplicationDefinition (0x81)
		0x00, 0x00, 0x00, 0x0B,		-- The length of appStr: 11
		0x43, 0x6F, 0x6D, 0x6D,		-- Comm
		0x61, 0x6E, 0x64, 0x50,		-- andP
		0x6F, 0x73, 0x74, 			-- ost
		0x00, 0x00, 0x00, 0x60, 	-- The length of sysDirStr: 96
		0x2F, 0x55, 0x73, 0x65,		-- /Use
		0x72, 0x73, 0x2F, 0x63,		-- rs/cn
		0x68, 0x72, 0x69, 0x73,		-- hris
		0x68, 0x6F, 0x63, 0x6B,		-- hock
		0x69, 0x6E, 0x67, 0x2F,		-- ing/
		0x44, 0x6F, 0x77, 0x6E,		-- Down
		0x6C, 0x6F, 0x61, 0x64,		-- load
		0x73, 0x2F, 0x54, 0x44,		-- s/TD
		0x53, 0x50, 0x76, 0x33,		-- SPv3
		0x5F, 0x32, 0x2F, 0x54,		-- _2/T
		0x55, 0x42, 0x45, 0x20,		-- UBE
		0x44, 0x65, 0x76, 0x65,		-- Deve
		0x6C, 0x6F, 0x70, 0x6D,		-- lopm
		0x65, 0x6E, 0x74, 0x20,		-- ent
		0x53, 0x75, 0x70, 0x70,		-- Supp
		0x6F, 0x72, 0x74, 0x20,		-- ort
		0x66, 0x6F, 0x72, 0x20,		-- for
		0x4F, 0x53, 0x58, 0x20,		-- OSX
		0x76, 0x33, 0x2E, 0x32,		-- v3.2
		0x2F, 0x4D, 0x6F, 0x63,		-- /Moc
		0x6B, 0x41, 0x70, 0x70,		-- kApp
		0x6C, 0x69, 0x63, 0x61,		-- lica
		0x74, 0x69, 0x6F, 0x6E,		-- tion
		0x2F, 0x73, 0x79, 0x73,		-- /sys
		0x00, 0x00, 0x00, 0x00,		-- Let's wrap it up.
	}

	byteString = string.char(table.unpack(byteArray))

	mod.socket:write(byteString, function()
		log.df(" * Sent ApplicationDefinition:\n%s", utf8.hexDump(byteString))
	end)

	--
	-- TODO: Annoyingly this causes an error in Tangent Hub:
	-- ProcessRead: WARNING - message data size of 3800597986 is larger than maximum of 1024
	--

end

-- processBuffer(data) -> none
-- Function
-- Processes the incoming buffer.
--
-- Parameters:
--  * data - the Data as a table
--
-- Returns:
--  * None
local function processBuffer(data)
	local id = tonumber(data[1]..data[2]..data[3]..data[4], 16)
	if id == mod.HUB_MESSAGE["INITIATE_COMMS"] then
		--------------------------------------------------------------------------------
		-- FORMAT:
		-- 0x01, <protocolRev>, <numPanels>, (<panelType>, <panelID>)...
		--------------------------------------------------------------------------------

		local protocolRev = tonumber(data[5]..data[6]..data[7]..data[8], 16)
		local numberOfPanels = tonumber(data[9]..data[10]..data[11]..data[12], 16)

		if protocolRev and numberOfPanels then
			log.df("IPC_HUB_COMMAND_INITIATE_COMMS:")
			log.df("  hub supports protocol revision %s", protocolRev)
			log.df("  %s panel(s) are listed", numberOfPanels)

			local startNumber = 12
			for i=1, numberOfPanels do
				local currentPanelType = tonumber(data[startNumber + 1]..data[startNumber + 2]..data[startNumber + 3]..data[startNumber + 4], 16)
				local currentPanelID = tonumber(data[startNumber + 5]..data[startNumber + 6]..data[startNumber + 7]..data[startNumber + 8], 16)
				startNumber = startNumber + 8
				log.df("    %s: type: %s with id: %s", i, getPanelType(currentPanelType), currentPanelID)
			end

			--------------------------------------------------------------------------------
			-- Respond with ApplicationDefinition (0x81):
			--------------------------------------------------------------------------------
			mod.sendApplicationDefinition()
		end
	else
		log.df("HUB RESPONSE: %s", inspect(data))
	end
end

--- plugins.core.tangent.manager.init(deps, env) -> none
--- Function
--- Initialises the Tangent Plugin
---
--- Parameters:
---  * deps - Dependencies Table
---  * env - Environment Table
---
--- Returns:
---  * None
function mod.init(deps, env)

	log.df("CONNECTING TO TANGENT HUB...")
	mod.socket = socket.new()
		:setCallback(function(data, tag)
			local hexDump = utf8.hexDump(data)
			local data1 = string.sub(hexDump, 6, 7)
			local data2 = string.sub(hexDump, 9, 10)
			local data3 = string.sub(hexDump, 12, 13)
			local data4 = string.sub(hexDump, 15, 16)

			table.insert(mod.messageBuffer, data1)
			table.insert(mod.messageBuffer, data2)
			table.insert(mod.messageBuffer, data3)
			table.insert(mod.messageBuffer, data4)

			if mod.messageCount ~= 0 and mod.messageCount == mod.messageLength then
				--------------------------------------------------------------------------------
				-- Process Buffer:
				--------------------------------------------------------------------------------
				processBuffer(mod.messageBuffer)

				--------------------------------------------------------------------------------
				-- Reset:
				--------------------------------------------------------------------------------
				mod.messageBuffer = {}
				mod.messageCount = 0
				mod.messageLength = 0
			end
			if data and mod.messageCount == 0 then
				--------------------------------------------------------------------------------
				-- Each message starts with a 32 bit integer value which indicates the number
				-- of bytes that will follow to complete the message:
				--------------------------------------------------------------------------------
				mod.messageLength = tonumber(data1, 16) + tonumber(data2, 16) + tonumber(data3, 16) + tonumber(data4, 16)

				--------------------------------------------------------------------------------
				-- Reset Message Count:
				--------------------------------------------------------------------------------
				mod.messageCount = 0

				--------------------------------------------------------------------------------
				-- Don't add the first 4 bytes to the table,
				-- as we've already used them for `mod.messageLength`:
				--------------------------------------------------------------------------------
				mod.messageBuffer = {}
			end
			mod.messageCount = mod.messageCount + 4
		end)
	:connect(mod.LOCALHOST, mod.LISTENING_PORT, function()
		log.df("CONNECTION TO TANGENT HUB ESTABLISHED.")
		mod._timer = timer.doEvery(mod.INTERVAL, function()
			if mod.socket:connected() then
				mod.socket:read(4)
			else
				log.df("CONNECTION TO TANGENT HUB DISCONNECTED. ABORTING.")
				mod._timer:stop()
			end
		end)
	end)
	return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id			= "core.tangent.manager",
	group		= "core",
	required	= true,
	dependencies	= {
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	if tools.doesFileExist("/Library/Application Support/Tangent/Hub/TangentHub") then
		return mod.init(deps, env)
	else
		log.ef("\nTangent Hub needs to be installed to enable Tangent TUBE/TIPC support in CommandPost.\nPlease download Tangent Hub from: http://www.tangentwave.co.uk/download/tangent-hub-installer-mac/")
	end
end

return plugin