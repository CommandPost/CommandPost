--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 M I D I    P R E F E R E N C E S    P A N E L              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.midi ===
---
--- MIDI Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsMIDI")

local application								= require("hs.application")
local canvas									= require("hs.canvas")
local dialog									= require("hs.dialog")
local image										= require("hs.image")
local inspect									= require("hs.inspect")
local midi										= require("hs.midi")
local timer										= require("hs.timer")

local commands									= require("cp.commands")
local config									= require("cp.config")
local fcp										= require("cp.apple.finalcutpro")
local html										= require("cp.web.html")
local plist										= require("cp.plist")
local tools										= require("cp.tools")
local ui										= require("cp.web.ui")

local _											= require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.panels.midi.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Stream Deck Support.
mod.enabled = config.prop("enableMIDI", false)

--- plugins.core.preferences.panels.midi.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("midiPreferencesLastGroup", nil)

-- resetMIDI() -> none
-- Function
-- Prompts to reset shortcuts to default.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetMIDI()
	dialog.webviewAlert(mod._manager.getWebview(), function(result)
		if result == i18n("yes") then
			mod._midi.clear()
			mod._manager.refresh()
		end
	end, i18n("midiResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- renderRows(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderRows(context)
	if not mod._renderRows then
		mod._renderRows, err = mod._env:compileTemplate("html/rows.html")
		if err then
			error(err)
		end
	end
	return mod._renderRows(context)
end

-- renderPanel(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderPanel(context)
	if not mod._renderPanel then
		mod._renderPanel, err = mod._env:compileTemplate("html/panel.html")
		if err then
			error(err)
		end
	end
	return mod._renderPanel(context)
end

-- generateContent() -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML content as string
local function generateContent()

	--------------------------------------------------------------------------------
	-- The Group Select:
	--------------------------------------------------------------------------------
	local groupOptions = {}
	local defaultGroup = nil
	if mod.lastGroup() then defaultGroup = mod.lastGroup() end -- Get last group from preferences.
	for _,id in ipairs(commands.groupIds()) do
		defaultGroup = defaultGroup or id
		groupOptions[#groupOptions+1] = { value = id, label = i18n("shortcut_group_"..id, {default = id})}
	end
	table.sort(groupOptions, function(a, b) return a.label < b.label end)

	local midiGroupSelect = ui.select({
		id			= "midiGroupSelect",
		value		= defaultGroup,
		options		= groupOptions,
		required	= true,
	}) .. ui.javascript([[
		var midiGroupSelect = document.getElementById("midiGroupSelect")
		midiGroupSelect.onchange = function(e) {
			try {
				var result = {
					id: "midiPanelCallback",
					params: {
						type: "updateGroup",
						groupID: this.value,
					},
				}
				webkit.messageHandlers.]] .. mod._manager.getLabel() .. [[.postMessage(result);
			} catch(err) {
				console.log("Error: " + err)
				alert('An error has occurred. Does the controller exist yet?');
			}

			console.log("midiGroupSelect changed");
			var groupControls = document.getElementById("midiGroupControls");
			var value = midiGroupSelect.options[midiGroupSelect.selectedIndex].value;
			var children = groupControls.children;
			for (var i = 0; i < children.length; i++) {
			  var child = children[i];
			  if (child.id == "midiGroup_" + value) {
				  child.classList.add("selected");
			  } else {
				  child.classList.remove("selected");
			  }
			}
		}
	]])


	local context = {
		_						= _,
		midiGroupSelect			= midiGroupSelect,
		groups					= commands.groups(),
		defaultGroup			= defaultGroup,

		groupEditor				= mod.getGroupEditor,

		webviewLabel 			= mod._manager.getLabel(),

		maxItems				= mod._midi.maxItems,
		midi					= mod._midi,
		i18n					= i18n,
	}

	return renderPanel(context)

end

local function setValue(groupID, buttonID, field, value)
	mod._manager.injectScript([[
		document.getElementById("midi]] .. groupID .. [[_button]] .. buttonID .. [[_]] .. field .. [[").value = "]] .. value .. [["
	]])
end

-- midiPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function midiPanelCallback(id, params)
	if params and params["type"] then
		if params["type"] == "updateAction" then

			--------------------------------------------------------------------------------
			-- Setup Activators:
			--------------------------------------------------------------------------------
			if not mod.activator then
				mod.activator = {}
				local handlerIds = mod._actionmanager.handlerIds()
				for _,groupID in ipairs(commands.groupIds()) do

					--------------------------------------------------------------------------------
					-- Create new Activator:
					--------------------------------------------------------------------------------
					mod.activator[groupID] = mod._actionmanager.getActivator("midiPreferences" .. groupID)

					--------------------------------------------------------------------------------
					-- Restrict Allowed Handlers for Activator to current group (and global):
					--------------------------------------------------------------------------------
					local allowedHandlers = {}
					for _,id in pairs(handlerIds) do
						local handlerTable = tools.split(id, "_")
						if handlerTable[1] == groupID or handlerTable[1] == "global" then
							--------------------------------------------------------------------------------
							-- Don't include "widgets" (that are used for the Touch Bar):
							--------------------------------------------------------------------------------
							if handlerTable[2] ~= "widgets" then
								table.insert(allowedHandlers, id)
							end
						end
					end
					mod.activator[groupID]:allowHandlers(table.unpack(allowedHandlers))
					mod.activator[groupID]:preloadChoices()
				end
			end

			--------------------------------------------------------------------------------
			-- Setup Activator Callback:
			--------------------------------------------------------------------------------
			local groupID = params["groupID"]
			mod.activator[groupID]:onActivate(function(handler, action, text)
				local actionTitle = text
				local handlerID = handler:id()
				mod._midi.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action)
				setValue(params["groupID"], params["buttonID"], "action", actionTitle)
			end)

			--------------------------------------------------------------------------------
			-- Show Activator:
			--------------------------------------------------------------------------------
			mod.activator[groupID]:show()
		elseif params["type"] == "clear" then
			--------------------------------------------------------------------------------
			-- Clear:
			--------------------------------------------------------------------------------
			mod._midi.updateAction(params["buttonID"], params["groupID"], nil, nil, nil)

			setValue(params["groupID"], params["buttonID"], "action", i18n("none"))
			setValue(params["groupID"], params["buttonID"], "device", "")
			setValue(params["groupID"], params["buttonID"], "number", i18n("none"))
			setValue(params["groupID"], params["buttonID"], "channel", "")
			setValue(params["groupID"], params["buttonID"], "value", i18n("none"))

		elseif params["type"] == "updateNumber" then
			--------------------------------------------------------------------------------
			-- Update Command Type:
			--------------------------------------------------------------------------------
			mod._midi.setItem("number", params["buttonID"], params["groupID"], params["number"])
		elseif params["type"] == "updateDevice" then
			--------------------------------------------------------------------------------
			-- Update Device:
			--------------------------------------------------------------------------------
			mod._midi.setItem("device", params["buttonID"], params["groupID"], params["device"])
		elseif params["type"] == "updateChannel" then
			--------------------------------------------------------------------------------
			-- Update Channel:
			--------------------------------------------------------------------------------
			mod._midi.setItem("channel", params["buttonID"], params["groupID"], params["channel"])
		elseif params["type"] == "updateValue" then
			--------------------------------------------------------------------------------
			-- Update Device:
			--------------------------------------------------------------------------------
			mod._midi.setItem("value", params["buttonID"], params["groupID"], params["value"])
		elseif params["type"] == "updateGroup" then
			--------------------------------------------------------------------------------
			-- Update Group:
			--------------------------------------------------------------------------------
			mod.lastGroup(params["groupID"])

		elseif params["type"] == "learnButton" then
			--------------------------------------------------------------------------------
			-- Learn Button:
			--------------------------------------------------------------------------------
			dialog.webviewAlert(mod._manager.getWebview(), function(result)
				if result == i18n("yes") then

					--------------------------------------------------------------------------------
					-- Abort after 3 seconds:
					--------------------------------------------------------------------------------
					mod.learningTimer = timer.doAfter(3, function()
						--------------------------------------------------------------------------------
						-- Destroy the MIDI watchers:
						--------------------------------------------------------------------------------
						for _, id in pairs(mod.learningMidiDeviceNames) do
							mod.learningMidiDevices[id] = nil
						end
						mod.learningMidiDevices = nil
						collectgarbage()

						--------------------------------------------------------------------------------
						-- Show failed message:
						--------------------------------------------------------------------------------
						dialog.webviewAlert(mod._manager.getWebview(), function() end, "No MIDI commands were detected.", "Please try again.", "Close")
					end)

					--------------------------------------------------------------------------------
					-- Setup MIDI watchers:
					--------------------------------------------------------------------------------
					mod.learningMidiDeviceNames = midi.devices()
					mod.learningMidiDevices = {}
					for _, deviceName in ipairs(mod.learningMidiDeviceNames) do
						mod.learningMidiDevices[deviceName] = midi.new(deviceName)
						if mod.learningMidiDevices[deviceName] then
							mod.learningMidiDevices[deviceName]:callback(function(object, deviceName, commandType, description, metadata)
								if commandType == "controlChange" or commandType == "noteOff" or commandType == "noteOn" then

									--------------------------------------------------------------------------------
									-- Stop the timer:
									--------------------------------------------------------------------------------
									if mod.learningTimer then
										mod.learningTimer:stop()
										mod.learningTimer = nil
									end

									--------------------------------------------------------------------------------
									-- Update the UI & Save Preferences:
									--------------------------------------------------------------------------------
									setValue(params["groupID"], params["buttonID"], "device", deviceName)
									mod._midi.setItem("device", params["buttonID"], params["groupID"], deviceName)

									setValue(params["groupID"], params["buttonID"], "channel", metadata.channel)
									mod._midi.setItem("channel", params["buttonID"], params["groupID"], metadata.channel)

									if commandType == "noteOff" or commandType == "noteOn" then

										setValue(params["groupID"], params["buttonID"], "number", metadata.note)
										mod._midi.setItem("number", params["buttonID"], params["groupID"], metadata.note)

										setValue(params["groupID"], params["buttonID"], "value", i18n("none"))
										mod._midi.setItem("value", params["buttonID"], params["groupID"], i18n("none"))

									elseif commandType == "controlChange" then

										setValue(params["groupID"], params["buttonID"], "number", metadata.controllerNumber)
										mod._midi.setItem("number", params["buttonID"], params["groupID"], metadata.controllerNumber)

										setValue(params["groupID"], params["buttonID"], "value", metadata.controllerValue)
										mod._midi.setItem("value", params["buttonID"], params["groupID"], metadata.controllerValue)

									end

									--log.df("Device: %s\nCommand: %s\nMetadata: %s", deviceName, commandType, hs.inspect(metadata))

									--------------------------------------------------------------------------------
									-- Destroy the MIDI watchers:
									--------------------------------------------------------------------------------
									for _, id in pairs(mod.learningMidiDeviceNames) do
										mod.learningMidiDevices[id] = nil
									end
									mod._learningMidiDevices = nil
									collectgarbage()

								end
							end)
						end
					end
				end
			end, i18n("learnMIDIMessage"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
		else
			--------------------------------------------------------------------------------
			-- Unknown Callback:
			--------------------------------------------------------------------------------
			log.df("Unknown Callback in Stream Deck Preferences Panel:")
			log.df("id: %s", hs.inspect(id))
			log.df("params: %s", hs.inspect(params))
		end
	end
end

--- plugins.core.preferences.panels.midi.setGroupEditor(groupId, editorFn) -> none
--- Function
--- Sets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---  * editorFn - Editor Function
---
--- Returns:
---  * None
function mod.setGroupEditor(groupId, editorFn)
	if not mod._groupEditors then
		mod._groupEditors = {}
	end
	mod._groupEditors[groupId] = editorFn
end

--- plugins.core.preferences.panels.midi.getGroupEditor(groupId) -> none
--- Function
--- Gets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---
--- Returns:
---  * Group Editor
function mod.getGroupEditor(groupId)
	return mod._groupEditors and mod._groupEditors[groupId]
end

--- plugins.core.preferences.panels.midi.init(deps, env) -> module
--- Function
--- Initialise the Module.
---
--- Parameters:
---  * deps - Dependancies Table
---  * env - Environment Table
---
--- Returns:
---  * The Module
function mod.init(deps, env)

	--------------------------------------------------------------------------------
	-- Inter-plugin Connectivity:
	--------------------------------------------------------------------------------
	mod._midi			= deps.midi
	mod._manager		= deps.manager
	mod._webviewLabel	= deps.manager.getLabel()
	mod._actionmanager	= deps.actionmanager
	mod._env			= env

	--------------------------------------------------------------------------------
	-- Setup Preferences Panel:
	--------------------------------------------------------------------------------
	mod._panel 			=  deps.manager.addPanel({
		priority 		= 2033,
		id				= "midi",
		label			= i18n("midi"),
		image			= image.imageFromPath(tools.iconFallback("/Applications/Utilities/Audio MIDI Setup.app/Contents/Resources/AudioMIDISetup.icns")),
		tooltip			= i18n("midi"),
		height			= 550,
	})
		:addHeading(6, i18n("midiControls"))
		:addCheckbox(7,
			{
				label		= i18n("enableMIDI"),
				checked		= mod.enabled,
				onchange	= function(id, params)
					mod.enabled(params.checked)
				end,
			}
		)
		:addContent(10, generateContent, true)

	mod._panel
		:addButton(20,
			{
				label		= i18n("midiReset"),
				onclick		= resetMIDI,
				class		= "resetShortcuts",
			}
		)
		:addButton(21,
			{
				label		= i18n("refreshMidi"),
				onclick		= mod._manager.refresh,
				class		= "refreshMidi",
			}
		)
		:addButton(22,
			{
				label		= i18n("openAudioMIDISetup"),
				onclick		= function() hs.open("/Applications/Utilities/Audio MIDI Setup.app") end,
				class		= "openAudioMIDISetup",
			}
		)

	--------------------------------------------------------------------------------
	-- Setup Callback Manager:
	--------------------------------------------------------------------------------
	mod._panel:addHandler("onchange", "midiPanelCallback", midiPanelCallback)

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.midi",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]		= "manager",
		["core.midi.manager"]				= "midi",
		["core.action.manager"]				= "actionmanager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(deps, env)
end

return plugin