--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     M I D I    M A N A G E R    P L U G I N                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.midi.manager ===
---
--- MIDI Manager Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("midi")

local application								= require("hs.application")
local canvas 									= require("hs.canvas")
local drawing									= require("hs.drawing")
local eventtap									= require("hs.eventtap")
local image										= require("hs.image")
local inspect									= require("hs.inspect")
local midi										= require("hs.midi")
local styledtext								= require("hs.styledtext")

local config									= require("cp.config")
local prop										= require("cp.prop")
local tools										= require("cp.tools")
local commands									= require("cp.commands")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local mod = {}

-- MIDI Devices:
mod._midiDevices = {}

-- MIDI Device Names
mod._deviceNames = {}

-- Group Statuses:
mod._groupStatus = {}

--- plugins.core.midi.manager.maxItems -> number
--- Variable
--- The maximum number of Touch Bar items per group.
mod.maxItems = 100

--- plugins.core.midi.manager.buttons <cp.prop: table>
--- Field
--- Contains all the saved Touch Bar Buttons
mod._items = config.prop("midiControls", {})

--- plugins.core.midi.manager.defaultGroup -> string
--- Variable
--- The default group.
mod.defaultGroup = "global"

--- plugins.core.midi.manager.clear() -> none
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

--- plugins.core.midi.manager.updateAction(button, group, action) -> none
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

--- plugins.core.midi.manager.setItem(item, button, group, value) -> none
--- Function
--- Stores a MIDI value in Preferences.
---
--- Parameters:
---  * item - The item you want to set.
---  * button - Button ID as string
---  * group - Group ID as string
---  * value - The value of the item you want to set.
---
--- Returns:
---  * None
function mod.setItem(item, button, group, value)
	local buttons = mod._items()

	button = tostring(button)

	if not buttons[group] then
		buttons[group] = {}
	end
	if not buttons[group][button] then
		buttons[group][button] = {}
	end
	buttons[group][button][item] = value

	mod._items(buttons)
	mod.update()
end

--- plugins.core.midi.manager.getIcon(button, group) -> string
--- Function
--- Returns a specific Touch Bar Icon.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * Icon data as string
function mod.getItem(item, button, group)
	local items = mod._items()
	if items[group] and items[group][button] and items[group][button][item] then
		return items[group][button][item]
	else
		return nil
	end
end

--- plugins.core.midi.manager.activeGroup() -> none
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

--- plugins.core.midi.manager.groupStatus(groupID, status) -> none
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

--- plugins.core.midi.manager.midiCallback(object, deviceName, commandType, description, metadata) -> none
--- Function
--- MIDI Callback
---
--- Parameters:
---  * object - The `hs.midi` userdata object
---  * deviceName - Device name as string
---  * commandType - Command Type as string
---  * description - Description as string
---  * metadata - A table containing metadata for the MIDI command
---
--- Returns:
---  * None
function mod.midiCallback(object, deviceName, commandType, description, metadata)

	--[[
	print("deviceName: " .. deviceName)
	print("commandType: " .. commandType)
	print("metadata: " .. hs.inspect(metadata))
	print("------------")
	--]]

	local activeGroup = mod.activeGroup()
	local items = mod._items()

	if items[activeGroup] then
		for _, item in pairs(items[activeGroup]) do
			if deviceName == item.device and item.channel == metadata.channel then
				if commandType == "noteOff" or commandType == "noteOn" then
					if tostring(item.number) == tostring(metadata.note) then
						if item.handlerID and item.action then
							local handler = mod._actionmanager.getHandler(item.handlerID)
							handler:execute(item.action)
						end
						return
					end
				elseif commandType == "controlChange" then
					if tostring(item.number) == tostring(metadata.controllerNumber) and tostring(item.value) == tostring(metadata.controllerValue) then
						if item.handlerID and item.action then
							local handler = mod._actionmanager.getHandler(item.handlerID)
							handler:execute(item.action)
						end
						return
					end
				end
			end
		end
	end

end

--- plugins.core.midi.manager.start() -> boolean
--- Function
--- Starts the MIDI Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()

	log.df("Starting MIDI Watchers")

	if not mod._midiDevices then
		mod._midiDevices = {}
	end
	for _, deviceName in ipairs(mod._deviceNames) do
		if not mod._midiDevices[deviceName] then
			mod._midiDevices[deviceName] = midi.new(deviceName)
			if mod._midiDevices[deviceName] then
				mod._midiDevices[deviceName]:callback(mod.midiCallback)
			end
		end
	end

end

--- plugins.core.midi.manager.start() -> boolean
--- Function
--- Stops the MIDI Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()

	log.df("Stopping MIDI Watchers")

	for _, id in pairs(mod._midiDevices) do
		mod._midiDevices[id] = nil
	end
	mod._midiDevices = nil
	collectgarbage()

end

--- plugins.core.midi.manager.update() -> none
--- Function
--- Updates the MIDI Watchers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
	mod.start()
end

--- plugins.core.midi.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable MIDI Support.
mod.enabled = config.prop("enableMIDI", false):watch(function(enabled)
	if enabled then
		mod.start()
	else
		mod.stop()
	end
end)

--- plugins.core.midi.manager.init(deps, env) -> none
--- Function
--- Initialises the MIDI Plugin
---
--- Parameters:
---  * deps - Dependencies Table
---  * env - Environment Table
---
--- Returns:
---  * None
function mod.init(deps, env)
	mod._actionmanager = deps.actionmanager
	return mod
end

function mod.devices()
	return mod._deviceNames
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id			= "core.midi.manager",
	group		= "core",
	required	= true,
	dependencies	= {
		["core.action.manager"]				= "actionmanager",
		["core.commands.global"] 			= "global",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	--------------------------------------------------------------------------------
	-- Get list of MIDI devices:
	--------------------------------------------------------------------------------
	mod._deviceNames = midi.devices() or {}

	--------------------------------------------------------------------------------
	-- Setup MIDI Device Callback:
	--------------------------------------------------------------------------------
	midi.deviceCallback(function(devices)
		log.df("MIDI Devices Updated")
		mod._deviceNames = devices or {}
	end)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	local global = deps.global
	global:add("cpMIDI")
		:whenActivated(mod.toggle)
		:groupedBy("commandPost")

	return mod.init(deps, env)
end

function plugin.postInit(deps, env)

	if mod.enabled() then
		mod.start()
	end

end

return plugin