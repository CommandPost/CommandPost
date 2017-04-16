--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      V O I C E     C O M M A N D S                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.os.voice ===
---
--- Voice Command Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log									= require("hs.logger").new("voice")

local osascript								= require("hs.osascript")
local speech   								= require("hs.speech")

local fcp									= require("cp.finalcutpro")
local dialog 								= require("cp.dialog")
local config								= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY		= 6000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.commandTitles = {}
mod.commandsByTitle = {}

function mod.isEnabled()
	return config.get("enableVoiceCommands", false)
end

function mod.setEnabled(value)
	config.set("enableVoiceCommands", value)
	mod.update()
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

function mod.isAnnouncementsEnabled()
	return config.get("voiceCommandEnableAnnouncements", false)
end

function mod.setAnnouncementsEnabled(value)
	config.set("voiceCommandEnableAnnouncements", value)
end

function mod.toggleAnnouncementsEnabled()
	mod.setAnnouncementsEnabled(not mod.isAnnouncementsEnabled())
end

function mod.isVisualAlertsEnabled()
	return config.get("voiceCommandEnableVisualAlerts", false)
end

function mod.setVisualAlertsEnabled(value)
	config.set("voiceCommandEnableVisualAlerts", value)
end

function mod.toggleVisualAlertsEnabled()
	mod.setVisualAlertsEnabled(not mod.isVisualAlertsEnabled())
end

function mod.openDictationSystemPreferences()
	osascript.applescript([[
		tell application "System Preferences"
			activate
			reveal anchor "Dictation" of pane "com.apple.preference.speech"
		end tell
	]])
end

--------------------------------------------------------------------------------
-- LISTENER CALLBACK:
--------------------------------------------------------------------------------
local function listenerCallback(listenerObj, text)

	local visualAlerts = mod.isVisualAlertsEnabled()
	local announcements = mod.isAnnouncementsEnabled()

	if announcements then
		mod.talker:speak(text)
	end

	if visualAlerts then
		dialog.displayNotification(text)
	end

	mod.activateCommand(text)
end

function mod.activateCommand(title)
	local cmd = mod.commandsByTitle[title]
	if cmd then
		cmd:activated()
	else
		if announcements then
			mod.talker:speak(i18n("unsupportedVoiceCommand"))
		end

		if visualAlerts then
			dialog.displayNotification(i18n("unsupportedVoiceCommand"))
		end

	end
end

--------------------------------------------------------------------------------
-- NEW:
--------------------------------------------------------------------------------
function mod.new()
	if mod.listener == nil then
		mod.listener = speech.listener.new("CommandPost")
		if mod.listener ~= nil then
			mod.listener:foregroundOnly(false)
						   :blocksOtherRecognizers(true)
						   :commands(mod.getCommandTitles())
						   :setCallback(listenerCallback)
		else
			-- Something went wrong:
			return false
		end

		mod.talker = speech.new()
	end
	return true
end

--------------------------------------------------------------------------------
-- START:
--------------------------------------------------------------------------------
function mod.start()
	if mod.listener == nil then
		if not mod.new() then
			return false
		end
	end
	if mod.listener ~= nil then
		mod.listener:start()
		return true
	end
	return false
end

--------------------------------------------------------------------------------
-- STOP:
--------------------------------------------------------------------------------
function mod.stop()
	if mod.listener ~= nil then
		mod.listener:delete()
		mod.listener = nil
		mod.talker = nil
	end
end

--------------------------------------------------------------------------------
-- IS LISTENING:
--------------------------------------------------------------------------------
function mod.isListening()
	return mod.listener ~= nil and mod.listener:isListening()
end

function mod.update()
	if mod.isEnabled() then
		if not mod.isListening() then
			local result = mod.new()
			if result == false then
				dialog.displayErrorMessage(i18n("voiceCommandsError"))
				mod.setEnabled(false)
				return
			end

			if fcp:isFrontmost() then
				mod.start()
			else
				mod.stop()
			end
		end
	else
		if mod.isListening() then
			mod.stop()
		end
	end
end

function mod.pause()
	if mod.isListening() then
		mod.stop()
	end
end

function mod.getCommandTitles()
	return mod.commandTitles
end

function mod.registerCommands(commands)
	local allCmds = commands:getAll()
	for id,cmd in pairs(allCmds) do
		local title = cmd:getTitle()
		if title then
			if mod.commandsByTitle[title] then
				log.w("Multiple commands with the title of '%' registered. Ignoring additional commands.", title)
			else
				mod.commandsByTitle[title] = cmd
				mod.commandTitles[#mod.commandTitles + 1] = title
			end
		end
	end

	table.sort(mod.commandTitles, function(a, b) return a < b end)
end

function mod.init(...)
	for i = 1,select('#', ...) do
		mod.registerCommands(select(i, ...))
	end
	mod.update()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.os.voice",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.menu.tools"]			= "prefs",
		["finalcutpro.commands"]			= "fcpxCmds",
		["core.commands.global"]			= "globalCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	--------------------------------------------------------------------------------
	-- Activation:
	--------------------------------------------------------------------------------
	fcp:watch({
		active		= mod.update,
		inactive	= mod.pause,
	})

	--------------------------------------------------------------------------------
	-- Menu Items:
	--------------------------------------------------------------------------------
	deps.prefs:addMenu(PRIORITY, function() return i18n("voiceCommands") end)
		:addItem(500, function()
			return { title = i18n("enableVoiceCommands"), fn = mod.toggleEnabled, checked = mod.isEnabled() }
		end)
		:addSeparator(600)
		:addItems(1000, function()
			return {
				{ title = i18n("enableAnnouncements"),	fn = mod.toggleAnnouncementsEnabled, checked = mod.isAnnouncementsEnabled(), disabled = not mod.isEnabled() },
				{ title = i18n("enableVisualAlerts"), 	fn = mod.toggleVisualAlertsEnabled, checked = mod.isVisualAlertsEnabled(), disabled = not mod.isEnabled() },
				{ title = "-" },
				{ title = i18n("openDictationPreferences"), fn = mod.openDictationSystemPreferences },
			}
		end)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpToggleVoiceCommands")
		:whenActivated(mod.toggleEnabled)

	return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)
	mod.init(deps.fcpxCmds, deps.globalCmds)
end

return plugin