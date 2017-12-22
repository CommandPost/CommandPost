--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.manager ===
---
--- Tangent Control Surface Manager

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("tangent")

local inspect									= require("hs.inspect")
local socket									= require("hs.socket")
local utf8										= require("hs.utf8")

local config									= require("cp.config")
local prop										= require("cp.prop")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local mod = {}

--------------------------------------------------------------------------------
-- DEFINITIONS FOR IPC COMMANDS FROM THE HUB TO APPLICATIONS:
--------------------------------------------------------------------------------
mod.IPC_HUB_COMMAND_INITIATE_COMMS                          = 0x01
mod.IPC_HUB_COMMAND_PARAMETER_CHANGE                        = 0x02
mod.IPC_HUB_COMMAND_PARAMETER_RESET                         = 0x03
mod.IPC_HUB_COMMAND_PARAMETER_VALUE_REQUEST                 = 0x04
mod.IPC_HUB_COMMAND_MENU_CHANGE                             = 0x05
mod.IPC_HUB_COMMAND_MENU_RESET                              = 0x06
mod.IPC_HUB_COMMAND_MENU_STRING_REQUEST                     = 0x07
mod.IPC_HUB_COMMAND_ACTION_ON                               = 0x08
mod.IPC_HUB_COMMAND_MODE_CHANGE                             = 0x09
mod.IPC_HUB_COMMAND_TRANSPORT                               = 0x0A
mod.IPC_HUB_COMMAND_ACTION_OFF                              = 0x0B
mod.IPC_HUB_COMMAND_UNMANAGED_PANEL_CAPABILITIES            = 0x30
mod.IPC_HUB_COMMAND_UNMANAGED_BUTTON_DOWN                   = 0x31
mod.IPC_HUB_COMMAND_UNMANAGED_BUTTON_UP                     = 0x32
mod.IPC_HUB_COMMAND_UNMANAGED_ENCODER_CHANGE                = 0x33
mod.IPC_HUB_COMMAND_UNMANAGED_DISPLAY_REFRESH               = 0x34
mod.IPC_HUB_COMMAND_PANEL_CONNECTION_STATE                  = 0x35

--------------------------------------------------------------------------------
-- DEFINITIONS FOR IPC COMMANDS FROM APPLICATIONS TO THE HUB:
--------------------------------------------------------------------------------
mod.IPC_APP_COMMAND_APPLICATION_DEFINITION                  = 0x81
mod.IPC_APP_COMMAND_PARAMETER_VALUE                         = 0x82
mod.IPC_APP_COMMAND_MENU_STRING                             = 0x83
mod.IPC_APP_COMMAND_ALL_CHANGE                              = 0x84
mod.IPC_APP_COMMAND_MODE_VALUE                              = 0x85
mod.IPC_APP_COMMAND_DISPLAY_TEXT                            = 0x86
mod.IPC_APP_COMMAND_UNMANAGED_PANEL_CAPABILITIES_REQUEST    = 0xA0
mod.IPC_APP_COMMAND_UNMANAGED_DISPLAY_WRITE                 = 0xA1
mod.IPC_APP_COMMAND_RENAME_CONTROL                          = 0xA2
mod.IPC_APP_COMMAND_HIGHLIGHT_CONTROL                       = 0xA3
mod.IPC_APP_COMMAND_INDICATE_CONTROL                        = 0xA4
mod.IPC_APP_COMMAND_REQUEST_PANEL_CONNECTION_STATES         = 0xA5

mod.listeningPort = 64246

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

	log.df("LOADING TANGENT PLUGIN MANAGER:")

	byteArray = { 0x00, 0x00, 0x00, 0x81, 0x00, 0x00, 0x00, 0x0B, 0x43, 0x6F, 0x6D, 0x6D, 0x61, 0x6E, 0x64, 0x50, 0x6F, 0x73, 0x74, 0x00, 0x00, 0x00, 0x60, 0x2F, 0x55, 0x73, 0x65, 0x72, 0x73, 0x2F, 0x63, 0x68, 0x72, 0x69, 0x73, 0x68, 0x6F, 0x63, 0x6B, 0x69, 0x6E, 0x67, 0x2F, 0x44, 0x6F, 0x77, 0x6E, 0x6C, 0x6F, 0x61, 0x64, 0x73, 0x2F, 0x54, 0x44, 0x53, 0x50, 0x76, 0x33, 0x5F, 0x32, 0x2F, 0x54, 0x55, 0x42, 0x45, 0x20, 0x44, 0x65, 0x76, 0x65, 0x6C, 0x6F, 0x70, 0x6D, 0x65, 0x6E, 0x74, 0x20, 0x53, 0x75, 0x70, 0x70, 0x6F, 0x72, 0x74, 0x20, 0x66, 0x6F, 0x72, 0x20, 0x4F, 0x53, 0x58, 0x20, 0x76, 0x33, 0x2E, 0x32, 0x2F, 0x4D, 0x6F, 0x63, 0x6B, 0x41, 0x70, 0x70, 0x6C, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x2F, 0x73, 0x79, 0x73, 0x00, 0x00, 0x00, 0x00 }
	byteString = string.char(table.unpack(byteArray))

	--log.df("byteString: %s", utf8.hexDump(byteString))

	local message = byteString

	mod.socket = socket.new()
		:setCallback(function(data, tag)
			log.df("TAG: %s", tag)
			log.df("DATA RECEIVED: '%s'", data)
			log.df("DATA RECEIVED HEXDUMP: %s", utf8.hexDump(data))
		end)
		:connect("127.0.0.1", mod.listeningPort, function()
			log.df("CONNECTION TO TANGENT HUB ESTABLISHED.")
			local info = mod.socket:info()
			--log.df("%s", hs.inspect(info))
		end)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		:read(4)
		--:send(message)

	--tangent = mod.socket

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
	return mod.init(deps, env)
end

return plugin