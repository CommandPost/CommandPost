--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.tangent.manager ===
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
local log										= require("hs.logger").new("tangentMan")

local dialog									= require("hs.dialog")
local fs										= require("hs.fs")
local inspect									= require("hs.inspect")
local json										= require("hs.json")
local tangent									= require("hs.tangent")
local timer										= require("hs.timer")

local commands									= require("cp.commands")
local config									= require("cp.config")
local fcp										= require("cp.apple.finalcutpro")
local tools										= require("cp.tools")

local moses										= require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local mod = {}

--------------------------------------------------------------------------------
-- MODULE CONSTANTS:
--------------------------------------------------------------------------------

--- plugins.finalcutpro.tangent.manager.MODES() -> none
--- Constant
--- The default Modes for CommandPost in the Tangent Mapper.
mod.MODES = {
	["0x00010001"] = {
		["name"] 	=	"Global",
		["active"]	=	function() return not fcp.isFrontmost() end,
	},
	["0x00010002"] = {
		["name"]	=	"Final Cut Pro",
		["active"]	=	function() return fcp.isFrontmost() end,
	},
}

--- plugins.finalcutpro.tangent.manager.colorInspectorParameter
--- Variable
--- Table containing custom Color Inspector paramaters.
mod.colorInspectorParameter = {
	--------------------------------------------------------------------------------
	-- COLOR INSPECTOR PARAMETERS:
	--
	--  * aspect - "color", "saturation" or "exposure"
	--  * property - "global", "shadows", "midtones", "highlights"
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- COLOR BOARD - COLOR:
	--------------------------------------------------------------------------------
	["0x00030001"] = {
		["name"] = "Color Board - Color - Master - Angle",
		["name9"] = "CB MS ANG",
		["minValue"] = 0,
		["maxValue"] = 359,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getAngle("color", "global") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftAngle("color", "global", value) end,
		["resetValue"] = function()
			fcp:colorBoard():applyAngle("color", "global", 110)
			fcp:colorBoard():applyPercentage("color", "global", 0)
		end,
	},
	["0x00030002"] = {
		["name"] = "Color Board - Color - Master - Percentage",
		["name9"] = "CB MS PER",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("color", "global") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("color", "global", value) end,
		["resetValue"] = function()
			fcp:colorBoard():applyAngle("color", "global", 110)
			fcp:colorBoard():applyPercentage("color", "global", 0)
		end,
	},
	["0x00030003"] = {
		["name"] = "Color Board - Color - Shadows - Angle",
		["name9"] = "CB SD ANG",
		["minValue"] = 0,
		["maxValue"] = 359,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getAngle("color", "shadows") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftAngle("color", "shadows", value) end,
		["resetValue"] = function()
			fcp:colorBoard():applyAngle("color", "shadows", 180)
			fcp:colorBoard():applyPercentage("color", "shadows", 0)
		end,
	},
	["0x00030004"] = {
		["name"] = "Color Board - Color - Shadows - Percentage",
		["name9"] = "CB SD PER",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("color", "shadows") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("color", "shadows", value) end,
		["resetValue"] = function()
			fcp:colorBoard():applyAngle("color", "shadows", 180)
			fcp:colorBoard():applyPercentage("color", "shadows", 0)
		end,
	},
	["0x00030005"] = {
		["name"] = "Color Board - Color - Midtones - Angle",
		["name9"] = "CB MT ANG",
		["minValue"] = 0,
		["maxValue"] = 359,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getAngle("color", "midtones") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftAngle("color", "midtones", value) end,
		["resetValue"] = function()
			fcp:colorBoard():applyAngle("color", "midtones", 215)
			fcp:colorBoard():applyPercentage("color", "midtones", 0)
		end,
	},
	["0x00030006"] = {
		["name"] = "Color Board - Color - Midtones - Percentage",
		["name9"] = "CB HL PER",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("color", "midtones") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("color", "midtones", value) end,
		["resetValue"] = function()
			fcp:colorBoard():applyAngle("color", "midtones", 215)
			fcp:colorBoard():applyPercentage("color", "midtones", 0)
		end,
	},
	["0x00030007"] = {
		["name"] = "Color Board - Color - Highlights - Angle",
		["name9"] = "CB HL ANG",
		["minValue"] = 0,
		["maxValue"] = 359,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getAngle("color", "highlights") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftAngle("color", "highlights", value) end,
		["resetValue"] = function()
			fcp:colorBoard():applyPercentage("color", "highlights", 0)
			fcp:colorBoard():applyAngle("color", "highlights", 250)
		end,
	},
	["0x00030008"] = {
		["name"] = "Color Board - Color - Highlights - Percentage",
		["name9"] = "CB HL PER",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("color", "highlights") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("color", "highlights", value) end,
		["resetValue"] = function()
			fcp:colorBoard():applyPercentage("color", "highlights", 0)
			fcp:colorBoard():applyAngle("color", "highlights", 250)
		end,
	},

	--------------------------------------------------------------------------------
	-- COLOR BOARD - SATURATION:
	--------------------------------------------------------------------------------
	["0x00030009"] = {
		["name"] = "Color Board - Saturation - Master",
		["name9"] = "CB SAT MS",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("saturation", "global") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("saturation", "global", value) end,
		["resetValue"] = function() fcp:colorBoard():applyPercentage("saturation", "global", 0) end,
	},
	["0x00030010"] = {
		["name"] = "Color Board - Saturation - Shadows",
		["name9"] = "CB SAT SD",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("saturation", "shadows") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("saturation", "shadows", value) end,
		["resetValue"] = function() fcp:colorBoard():applyPercentage("saturation", "shadows", 0) end,
	},
	["0x00030011"] = {
		["name"] = "Color Board - Saturation - Midtones",
		["name9"] = "CB SAT MT",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("saturation", "midtones") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("saturation", "midtones", value) end,
		["resetValue"] = function() fcp:colorBoard():applyPercentage("saturation", "midtones", 0) end,
	},
	["0x00030012"] = {
		["name"] = "Color Board - Saturation - Highlights",
		["name9"] = "CB SAT HL",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("saturation", "highlights") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("saturation", "highlights", value) end,
		["resetValue"] = function() fcp:colorBoard():applyPercentage("saturation", "highlights", 0) end,
	},

	--------------------------------------------------------------------------------
	-- COLOR BOARD - EXPOSURE:
	--------------------------------------------------------------------------------
	["0x00030013"] = {
		["name"] = "Color Board - Exposure - Master",
		["name9"] = "CB EXP MS",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("exposure", "global") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("exposure", "global", value) end,
		["resetValue"] = function() fcp:colorBoard():applyPercentage("exposure", "global", 0) end,
	},
	["0x00030014"] = {
		["name"] = "Color Board - Exposure - Shadows",
		["name9"] = "CB EXP SD",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("exposure", "shadows") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("exposure", "shadows", value) end,
		["resetValue"] = function() fcp:colorBoard():applyPercentage("exposure", "shadows", 0) end,
	},
	["0x00030015"] = {
		["name"] = "Color Board - Exposure - Midtones",
		["name9"] = "CB EXP MT",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("exposure", "midtones") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("exposure", "midtones", value) end,
		["resetValue"] = function() fcp:colorBoard():applyPercentage("exposure", "midtones", 0) end,
	},
	["0x00030016"] = {
		["name"] = "Color Board - Exposure - Highlights",
		["name9"] = "CB EXP HL",
		["minValue"] = -100,
		["maxValue"] = 100,
		["stepSize"] = 1,
		["getValue"] = function() return fcp:colorBoard():getPercentage("exposure", "highlights") end,
		["shiftValue"] = function(value) return fcp:colorBoard():show():shiftPercentage("exposure", "highlights", value) end,
		["resetValue"] = function() fcp:colorBoard():applyPercentage("exposure", "highlights", 0) end,
	},
}

--- plugins.finalcutpro.tangent.manager.colorInspectorBindings
--- Variable
--- Table containing custom Color Inspector Bindings.
mod.colorInspectorBindings = [[
				<Binding name="Color Board Master Color">
					<Member id="0x00030001"/>
					<Member id="0x00030002"/>
				</Binding>
				<Binding name="Color Board Shadows Color">
					<Member id="0x00030003"/>
					<Member id="0x00030004"/>
				</Binding>
				<Binding name="Color Board Midtones Color">
					<Member id="0x00030005"/>
					<Member id="0x00030006"/>
				</Binding>
				<Binding name="Color Board Highlights Color">
					<Member id="0x00030007"/>
					<Member id="0x00030008"/>
				</Binding>
]]

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS:
--------------------------------------------------------------------------------

-- loadMapping() -> none
-- Function
-- Loads the Tangent Mapping file from the Application Support folder.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if successful, otherwise `false`
local function loadMapping()
	local mappingFilePath = mod._configPath .. "/mapping.json"
	if not tools.doesFileExist(mappingFilePath) then
		log.ef("Tangent Mapping could not be found.")
		return false
	end
	local file = io.open(mappingFilePath, "r")
	if file then
		local content = file:read("*all")
		file:close()
		if not moses.isEmpty(content) then
			log.df("Loaded Tangent Mappings.")
			mod._mapping = json.decode(content)
			return true
		else
			log.ef("Empty Tangent Mapping: '%s'", mappingFilePath)
			return false
		end
	else
		log.ef("Unable to load Tangent Mapping: '%s'", mappingFilePath)
		return false
	end
end

-- makeStringTangentFriendly(value) -> none
-- Function
-- Removes any illegal characters from the value
--
-- Parameters:
--  * value - The string you want to process
--
-- Returns:
--  * A string that's valid for Tangent's panels
local function makeStringTangentFriendly(value)
	local result = ""
	for i = 1, #value do
		local letter = value:sub(i,i)
		local byte = string.byte(letter)
		if byte >= 32 and byte <= 126 then
			result = result .. letter
		else
			--log.df("Illegal Character: %s", letter)
		end
	end
	if #result == 0 then
		return nil
	else
		--------------------------------------------------------------------------------
		-- Replace Ampersand's as we're building an XML file:
		--------------------------------------------------------------------------------
		result = string.gsub(result, "&", "&amp;")

		--------------------------------------------------------------------------------
		-- Trim Results, just to be safe:
		--------------------------------------------------------------------------------
		return tools.trim(result)
	end
end

-- writeControlsXML() -> none
-- Function
-- Writes the Tangent controls.xml File to the User's Application Support folder.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function writeControlsXML()

	--------------------------------------------------------------------------------
	-- Create folder if it doesn't exist:
	--------------------------------------------------------------------------------
	if not tools.doesDirectoryExist(mod._configPath) then
		log.df("Tangent Settings folder did not exist, so creating one.")
		fs.mkdir(mod._configPath)
	end

	--------------------------------------------------------------------------------
	-- Copy existing XML files from Application Bundle to local Application Support:
	--------------------------------------------------------------------------------
	local output, status = hs.execute([[cp -a "]] .. mod._pluginPath .. [["/. "]] .. mod._configPath .. [[/"]])
	if not status then
		log.ef("Failed to copy XML files.")
	end

	--------------------------------------------------------------------------------
	-- Create "controls.xml" file:
	--------------------------------------------------------------------------------
	local mapping = {}
	local controlsFile = io.open(mod._configPath .. "/controls.xml", "w")
	if controlsFile then

		io.output(controlsFile)

		--------------------------------------------------------------------------------
		-- Set starting values:
		--------------------------------------------------------------------------------
		local currentActionID = 131073 -- Action ID starts at 0x00020001

		local result = ""
		result = result .. [[<?xml version="1.0" encoding="UTF-8" standalone="yes"?>]] .. "\n"
		result = result .. [[<TangentWave fileType="ControlSystem" fileVersion="3.0">]] .. "\n"

		--------------------------------------------------------------------------------
		-- Capabilities:
		--------------------------------------------------------------------------------
		result = result .. [[	<Capabilities>]] .. "\n"
		result = result .. [[		<Jog enabled="true"/>]] .. "\n"
		result = result .. [[		<Shuttle enabled="false"/>]] .. "\n"
		result = result .. [[		<StatusDisplay lineCount="3"/>]] .. "\n"
		result = result .. [[	</Capabilities>]] .. "\n"

		--------------------------------------------------------------------------------
		-- Modes:
		--------------------------------------------------------------------------------
		result = result .. [[	<Modes>]] .. "\n"
		for modeID, metadata in pairs(mod.MODES) do
			result = result .. [[		<Mode id="]] .. modeID .. [[">]] .. "\n"
			result = result .. [[			<Name>]] .. metadata.name .. [[</Name>]] .. "\n"
			result = result .. [[		</Mode>]] .. "\n"
		end
		result = result .. [[	</Modes>]] .. "\n"

		--------------------------------------------------------------------------------
		-- Get & Sort a list of Handler IDs:
		--------------------------------------------------------------------------------
		local colorInspectorID = "fcpx_colorInspector"
		local handlerIds = mod._actionmanager.handlerIds()
		table.insert(handlerIds, colorInspectorID)
		table.sort(handlerIds, function(a, b) return i18n(a .. "_action") < i18n(b .. "_action") end)

		--------------------------------------------------------------------------------
		-- Controls:
		--------------------------------------------------------------------------------
		result = result .. [[	<Controls>]] .. "\n"
		for _, handlerID in pairs(handlerIds) do
			if handlerID == colorInspectorID then
				--------------------------------------------------------------------------------
				-- Custom Color Inspector Parameters:
				--------------------------------------------------------------------------------
				local handlerLabel = i18n(handlerID .. "_action")
				result = result .. [[		<Group name="]] .. handlerLabel .. [[">]] .. "\n"
				table.sort(mod.colorInspectorParameter, function(a, b) return a.name < b.name end)
				for id, metadata in pairs(mod.colorInspectorParameter) do
					local actionID = string.format("%#010x", id)
					result = result .. [[			<Parameter id="]] .. id .. [[">]] .. "\n"
					result = result .. [[				<Name>]] .. metadata.name .. [[</Name>]] .. "\n"
					result = result .. [[				<Name9>]] .. metadata.name9 .. [[</Name9>]] .. "\n"
					result = result .. [[				<MinValue>]] .. metadata.minValue .. [[</MinValue>]] .. "\n"
					result = result .. [[				<MaxValue>]] .. metadata.maxValue .. [[</MaxValue>]] .. "\n"
					result = result .. [[				<StepSize>]] .. metadata.stepSize .. [[</StepSize>]] .. "\n"
					result = result .. [[			</Parameter>]] .. "\n"
					currentActionID = currentActionID + 1
				end
				--------------------------------------------------------------------------------
				-- Add Bindings:
				--------------------------------------------------------------------------------
				result = result .. mod.colorInspectorBindings
				result = result .. [[		</Group>]] .. "\n"
			else
				--------------------------------------------------------------------------------
				-- Action Manager Actions:
				--------------------------------------------------------------------------------
				local handler = mod._actionmanager.getHandler(handlerID)
				if string.sub(handlerID, -7) ~= "widgets" and string.sub(handlerID, -12) ~= "midicontrols" then
					local handlerLabel = i18n(handler:id() .. "_action")
					result = result .. [[		<Group name="]] .. handlerLabel .. [[">]] .. "\n"
					local choices = handler:choices()._choices
					table.sort(choices, function(a, b) return a.text < b.text end)
					for _, choice in pairs(choices) do
						local friendlyName = makeStringTangentFriendly(choice.text)
						if friendlyName and #friendlyName >= 1 then
							local actionID = string.format("%#010x", currentActionID)
							result = result .. [[			<Action id="]] .. actionID .. [[">]] .. "\n"
							result = result .. [[				<Name>]] .. friendlyName .. [[</Name>]] .. "\n"
							result = result .. [[			</Action>]] .. "\n"
							currentActionID = currentActionID + 1
							table.insert(mapping, {
								[actionID] = {
									["handlerID"] = handlerID,
									["action"] = choice.params,
								}
							})
						end
					end
					result = result .. [[		</Group>]] .. "\n"
				end
			end
		end
		result = result .. [[	</Controls>]] .. "\n"
		result = result .. [[</TangentWave>]]

		--------------------------------------------------------------------------------
		-- Write to File & Close:
		--------------------------------------------------------------------------------
		io.write(result)
		io.close(controlsFile)

		--------------------------------------------------------------------------------
		-- Save Mapping File:
		--------------------------------------------------------------------------------
		local mappingFile = io.open(mod._configPath .. "/mapping.json", "w")
		io.output(mappingFile)
		io.write(json.encode(mapping))
		io.close(mappingFile)
		mod._mapping = mapping
	end

end

--------------------------------------------------------------------------------
-- MODULE METHODS & FUNCTIONS:
--------------------------------------------------------------------------------

--- plugins.finalcutpro.tangent.manager.active -> boolean
--- Variable
--- Returns `true` if plugin is active, otherwise `false`.
mod.active = false

--- plugins.finalcutpro.tangent.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disables the Tangent Manager.
mod.enabled = config.prop("enableTangent", false)

--- plugins.finalcutpro.tangent.manager.updateMode() -> none
--- Function
--- Updates the Mode on the Tangent Hub
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateMode()
	if mod.active then
		for id,metadata in pairs(mod.MODES) do
			local active = metadata.active()
			if active == true then
				local result, errorMessage = tangent.send("MODE_VALUE", {
					["modeID"] = tonumber(id)
				})
				return
			end
		end
	end
end

--- plugins.finalcutpro.tangent.manager.callback(id, metadata) -> none
--- Function
--- Tangent Manager Callback Function
---
--- Parameters:
---  * id - The ID of the Tangent Message
---  * metadata - A table of metadata
---
--- Returns:
---  * None
function mod.callback(id, metadata)
	if id == "CONNECTED" then
		--------------------------------------------------------------------------------
		-- Connected:
		--------------------------------------------------------------------------------
		log.df("Connection To Tangent Hub successfully established.")
	elseif id == "INITIATE_COMMS" then
		--------------------------------------------------------------------------------
		-- InitiateComms:
		--------------------------------------------------------------------------------
		log.df("InitiateComms Received:")
		log.df("    Protocol Revision: %s", metadata.protocolRev)
        log.df("    Number of Panels: %s", metadata.numberOfPanels)
        for i, v in pairs(metadata.panels) do
			log.df("        Panel Type: %s (%s)", v.panelType, string.format("%#010x", v.panelID))
		end
		--------------------------------------------------------------------------------
		-- Display CommandPost Version on Screen:
		--------------------------------------------------------------------------------
		timer.doAfter(1, function()
			tangent.send("DISPLAY_TEXT", {["stringOne"]="CommandPost " .. config.appVersion,["stringOneDoubleHeight"]=false})
		end)
		--------------------------------------------------------------------------------
		-- Update Mode:
		--------------------------------------------------------------------------------
		mod.updateMode()
	elseif id == "ACTION_ON" then
		--------------------------------------------------------------------------------
		-- Action On:
		--------------------------------------------------------------------------------
		if metadata and metadata.actionID then
			local actionID = string.format("%#010x", metadata.actionID)
			local mapping = nil
			for i, v in pairs(mod._mapping) do
				if v[actionID] then
					mapping = v[actionID]
				end
			end
			if mapping then
				if string.sub(mapping.handlerID, 1, 4) == "fcpx" and fcp.isFrontmost() == false then
					log.df("Final Cut Pro isn't actually frontmost so ignoring.")
					return
				end
				local handler = mod._actionmanager.getHandler(mapping.handlerID)
				handler:execute(mapping.action)
			else
				log.ef("Could not find a Mapping with Action ID: '%s'", actionID)
			end
		end
	elseif id == "PARAMETER_CHANGE" then
		--------------------------------------------------------------------------------
		-- Parameter Change:
		--------------------------------------------------------------------------------
		if metadata and metadata.increment and metadata.paramID then
			if fcp.isFrontmost() == false then
				log.df("Final Cut Pro isn't actually frontmost so ignoring.")
				return
			end

			local paramID = string.format("%#010x", metadata.paramID)
			local increment = metadata.increment
			mod.colorInspectorParameter[paramID].shiftValue(increment + mod._incrementBuffer)

			--------------------------------------------------------------------------------
			-- Send Values back to Tangent Hub:
			--------------------------------------------------------------------------------
			local value = mod.colorInspectorParameter[paramID] and mod.colorInspectorParameter[paramID].getValue()
			if value then
				tangent.send("PARAMETER_VALUE", {
					["paramID"] = paramID,
					["value"] = value,
					["atDefault"] = false,
				})
			end
		end
	elseif id == "PARAMETER_VALUE_REQUEST" then
		--------------------------------------------------------------------------------
		-- Parameter Value Request:
		--------------------------------------------------------------------------------
		local paramID = string.format("%#010x", metadata.paramID)
		local value = mod.colorInspectorParameter[paramID] and mod.colorInspectorParameter[paramID].getValue()
		if value then
			tangent.send("PARAMETER_VALUE", {
				["paramID"] = paramID,
				["value"] = value,
				["atDefault"] = false,
			})
		end
	elseif id == "ACTION_OFF" then
		--------------------------------------------------------------------------------
		-- Action Off:
		--------------------------------------------------------------------------------
		-- A key has been released.
	elseif id == "PARAMETER_RESET" then
		--------------------------------------------------------------------------------
		-- Parameter Reset:
		--------------------------------------------------------------------------------
		local paramID = string.format("%#010x", metadata.paramID)
		log.df("Parameter Reset Request: %s", paramID)
		mod.colorInspectorParameter[paramID].resetValue()
	elseif id == "TRANSPORT" then
		--------------------------------------------------------------------------------
		-- Transport:
		--------------------------------------------------------------------------------
		if fcp.isFrontmost() then
			log.df("jogValue: %s, shuttleValue: %s", metadata.jogValue, metadata.shuttleValue)
			if metadata.jogValue == 1 then
				fcp:menuBar():selectMenu({"Mark", "Next", "Frame"})
			elseif metadata.jogValue == -1 then
				fcp:menuBar():selectMenu({"Mark", "Previous", "Frame"})
			end
		end
	elseif id == "MENU_CHANGE" then
		--------------------------------------------------------------------------------
		-- Menu Change:
		--------------------------------------------------------------------------------
		--
		-- Do nothing.
		--
	elseif id == "MENU_RESET" then
		--------------------------------------------------------------------------------
		-- Menu Reset:
		--------------------------------------------------------------------------------
		--
		-- Do nothing.
		--
	elseif id == "MENU_STRING_REQUEST" then
		--------------------------------------------------------------------------------
		-- Menu String Request:
		--------------------------------------------------------------------------------
		--
		-- Do nothing.
		--
	elseif id == "MODE_CHANGE" then
		--------------------------------------------------------------------------------
		-- Mode Change:
		--------------------------------------------------------------------------------
		--
		-- Do nothing.
		--
	elseif id == "UNMANAGED_PANEL_CAPABILITIES" then
		--------------------------------------------------------------------------------
		-- Unmanaged Panel Capabilities:
		--------------------------------------------------------------------------------
		--
		-- Only used when working in Unmanaged panel mode.
		--
	elseif id == "UNMANAGED_BUTTON_DOWN" then
		--------------------------------------------------------------------------------
		-- Unmanaged Button Down:
		--------------------------------------------------------------------------------
		--
		-- Only used when working in Unmanaged panel mode.
		--
	elseif id == "UNMANAGED_BUTTON_UP" then
		--------------------------------------------------------------------------------
		-- Unmanaged Button Up:
		--------------------------------------------------------------------------------
		--
		-- Only used when working in Unmanaged panel mode.
		--
	elseif id == "UNMANAGED_ENCODER_CHANGE" then
		--------------------------------------------------------------------------------
		-- Unmanaged Encoder Change:
		--------------------------------------------------------------------------------
		--
		-- Only used when working in Unmanaged panel mode.
		--
	elseif id == "UNMANAGED_DISPLAY_REFRESH" then
		--------------------------------------------------------------------------------
		-- Unmanaged Display Refresh:
		--------------------------------------------------------------------------------
		--
		-- Only used when working in Unmanaged panel mode.
		--
	elseif id == "PANEL_CONNECTION_STATE" then
		--------------------------------------------------------------------------------
		-- Panel Connection State:
		--------------------------------------------------------------------------------
		--
		-- Sent in response to a PanelConnectionStatesRequest (0xA5) command to report the
		-- current connected/disconnected status of a configured panel.
		--
	else
		log.df("Unexpected Tangent Message Recieved:\nid: %s, metadata: %s", id, metadata and inspect(metadata))
	end
end

--- plugins.finalcutpro.tangent.manager.start() -> boolean
--- Function
--- Starts the Tangent Plugin
---
--- Parameters:
---  * resetControlMap - When `true`, CommandPost will rebuild the Control Map for Tangent Mapper.
---
--- Returns:
---  * `true` if successfully started, otherwise `false`
function mod.start(resetControlMap)
	if tangent.isTangentHubInstalled() then
		--------------------------------------------------------------------------------
		-- Write Controls XML:
		--------------------------------------------------------------------------------
		if resetControlMap then
			writeControlsXML()
		end
		--------------------------------------------------------------------------------
		-- Disable "Final Cut Pro" in Tangent Hub:
		--------------------------------------------------------------------------------
		local hideFilePath = "/Library/Application Support/Tangent/Hub/KeypressApps/hide.txt"
		if tools.doesFileExist(hideFilePath) then
			--------------------------------------------------------------------------------
			-- Read existing Hide file:
			--------------------------------------------------------------------------------
			local file = io.open(hideFilePath, "r")
			local fileContents = file:read("*a")
			file:close()
			if fileContents and string.match(fileContents, "Final Cut Pro") then
				--------------------------------------------------------------------------------
				-- Final Cut Pro is already hidden in the Tangent Hub.
				--------------------------------------------------------------------------------
			else
				--------------------------------------------------------------------------------
				-- Append Existing Hide File:
				--------------------------------------------------------------------------------
				local appendFile = io.open(hideFilePath, "a")
				appendFile:write("\nFinal Cut Pro")
				appendFile:close()
			end
		else
			--------------------------------------------------------------------------------
			-- Create new Hide File:
			--------------------------------------------------------------------------------
			local newFile = io.open(hideFilePath, "w")
			log.df("newFile: %s", newFile)
			newFile:write("Final Cut Pro")
			newFile:close()
		end
		--------------------------------------------------------------------------------
		-- Connect to Tangent Hub:
		--------------------------------------------------------------------------------
		log.df("Connecting to Tangent Hub...")
		local result, errorMessage = tangent.connect("CommandPost", mod._configPath)
		if result then
			tangent.callback(mod.callback)
			mod.active = true
			return true
		else
			log.ef("Failed to start Tangent Support: %s", errorMessage)
			return false
		end
	else
		return false
	end
end

--- plugins.finalcutpro.tangent.manager.stop() -> boolean
--- Function
--- Stops the Tangent Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
	tangent.disconnect()
	mod.active = false
	log.df("Disconnected from Tangent Hub.")
end

--- plugins.finalcutpro.tangent.manager.init(deps, env) -> none
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
	if mod.enabled() then
		if tools.doesFileExist(mod._configPath .. "/controls.xml") == false or tools.doesFileExist(mod._configPath .. "/mapping.json") == false then
			log.df("Tangent Control and/or Mapping File doesn't exist, so disabling Tangent Support.")
			mod.enabled(false)
		else
			loadMapping()
			mod.start()
		end
	end
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
		["core.preferences.panels.tangent"]				= "prefs",
		["core.preferences.manager"]					= "prefsManager",
		["core.action.manager"]							= "actionmanager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	--------------------------------------------------------------------------------
	-- Action Manager:
	--------------------------------------------------------------------------------
	mod._actionmanager = deps.actionmanager

	--------------------------------------------------------------------------------
	-- Get XML Path:
	--------------------------------------------------------------------------------
	mod._pluginPath = env:pathToAbsolute("/defaultmap")
	mod._configPath = config.userConfigRootPath .. "/Tangent Settings"

	--------------------------------------------------------------------------------
	-- Final Cut Pro Watchers:
	--------------------------------------------------------------------------------
	fcp:watch({
		active		= mod.updateMode,
		inactive	= mod.updateMode,
		show		= mod.updateMode,
		hide		= mod.updateMode,
	})

	--------------------------------------------------------------------------------
	-- Setup Preferences Panel:
	--------------------------------------------------------------------------------
	if deps.prefs then
		deps.prefs
			:addContent(1, [[
				<style>
					.tangentButtonOne {
						float:left;
						width: 141px;
					}
					.tangentButtonTwo {
						float:left;
						margin-left: 5px;
						width: 141px;
					}
					.tangentButtonThree {
						clear:both;
						float:left;
						margin-top: 5px;
						width: 141px;
					}
					.tangentButtonFour {
						float:left;
						margin-top: 5px;
						margin-left: 5px;
						width: 141px;
					}
				</style>
			]], true)
			:addHeading(2, "Tangent Panel Support")
			:addParagraph(3,
			[[CommandPost offers native support of the entire range of Tangent's panels, including the <strong>Element</strong>, <strong>Wave</strong>, <strong>Ripple</strong>, the <strong>Element-Vs iPad app</strong>, and any future panels.<br />
			<br />
			All actions within CommandPost can be assigned to any Tangent panel button/wheel using <strong>Tangent's Mapper</strong> application. This allows you to create your own layouts and modes.<br />
			<br />
			If you add a new effect or plugin in Final Cut Pro, you can use the <strong>Rebuild Control Map</strong> button below to make these new items appear in <strong>Tangent Mapper</strong>.<br />
			<br />]], true)
			:addCheckbox(4,
				{
					label = "Enable Tangent Panel Support",
					onchange = function(_, params)
						if params.checked then
							if not tangent.isTangentHubInstalled() then
								dialog.webviewAlert(deps.prefsManager.getWebview(), function()
									mod.enabled(false)
									deps.prefsManager.injectScript([[
										document.getElementById("enableTangentSupport").checked = false;
									]])
								end, "Tangent Panel Support", [[You must install the Tangent Mapper & Hub to enable Tangent Panel support.]], i18n("ok"))
							else
								dialog.webviewAlert(deps.prefsManager.getWebview(), function()
									mod.enabled(true)
									mod.start(true)
								end, "Enabling Tangent Panel Support", "Just a heads up, it can take a few minutes to re-build the Control Map once you click OK.", i18n("ok"))
							end
						else
							mod.enabled(false)
							mod.stop()
						end
					end,
					checked = mod.enabled,
					id = "enableTangentSupport",
				}
			)
			:addParagraph(5, "<br />", true)
			:addButton(6,
				{
					label = "Open Tangent Mapper",
					onclick = function(_, params)
						os.execute('open "/Applications/Tangent/Tangent Mapper.app"')
					end,
					class = "tangentButtonOne",
				}
			)
			:addButton(7,
				{
					label = "Rebuild Control Map",
					onclick = function(_, params)
						dialog.webviewAlert(deps.prefsManager.getWebview(), function()
							if mod.enabled() then
								mod.stop()
								mod.start(true)
							else
								writeControlsXML()
							end
						end, "Rebuild Control Map", "Just a heads up, it can take a few minutes to re-build the Control Map once you click OK.", i18n("ok"))
					end,
					class = "tangentButtonTwo",
				}
			)
			:addButton(8,
				{
					label = "Download Tangent Hub",
					onclick = function(_, params)
						os.execute('open "http://www.tangentwave.co.uk/download/tangent-hub-installer-mac/"')
					end,
					class = "tangentButtonThree",
				}
			)
			:addButton(9,
				{
					label = "Visit Tangent Website",
					onclick = function(_, params)
						os.execute('open "http://www.tangentwave.co.uk/"')
					end,
					class = "tangentButtonFour",
				}
			)

	end

	--------------------------------------------------------------------------------
	-- Return Module:
	--------------------------------------------------------------------------------
	return mod
end

function plugin.postInit(deps, env)
	mod.init()
end

return plugin