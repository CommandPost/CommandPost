-- Imports
local fcp									= require("hs.finalcutpro")
local settings								= require("hs.settings")
local dialog 								= require("hs.fcpxhacks.modules.dialog")
local osascript								= require("hs.osascript")
local speech   								= require("hs.speech")
local metadata								= require("hs.fcpxhacks.metadata")

local log									= require("hs.logger").new("voice")

-- Constants
local PRIORITY		= 6000

-- The Module
local mod = {}

mod.commandTitles = {}
mod.commandsByTitle = {}

function mod.isEnabled()
	return settings.get(metadata.settingsPrefix .. ".enableVoiceCommands") or false
end

function mod.setEnabled(value)
	settings.set(metadata.settingsPrefix .. ".enableVoiceCommands", value)
	mod.update()
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

function mod.isAnnouncementsEnabled()
	return settings.get(metadata.settingsPrefix .. ".voiceCommandEnableAnnouncements") or false
end

function mod.setAnnouncementsEnabled(value)
	settings.set(metadata.settingsPrefix .. ".voiceCommandEnableAnnouncements", value)
end

function mod.toggleAnnouncementsEnabled()
	mod.setAnnouncementsEnabled(not mod.isAnnouncementsEnabled())
end

function mod.isVisualAlertsEnabled()
	return settings.get(metadata.settingsPrefix .. ".voiceCommandEnableVisualAlerts") or false
end

function mod.setVisualAlertsEnabled(value)
	settings.set(metadata.settingsPrefix .. ".voiceCommandEnableVisualAlerts", value)
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


-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.tools.options"]	= "options",
	["hs.fcpxhacks.plugins.menu.preferences"]	= "prefs",
	["hs.fcpxhacks.plugins.commands.fcpx"]		= "fcpxCmds",
	["hs.fcpxhacks.plugins.commands.global"]	= "globalCmds",
}

function plugin.init(deps)
	-- Activation
	fcp:watch({
		active		= mod.update,
		inactive	= mod.pause,
	})

	-- Menu Items
	deps.options:addSection(PRIORITY)
		:addSeparator(1000)
		:addItem(2000, function()
			return { title = i18n("enableVoiceCommands"), fn = mod.toggleEnabled, checked = mod.isEnabled() }
		end)
		:addSeparator(3000)

	deps.prefs:addMenu(PRIORITY, function() return i18n("voiceCommandOptions") end)
		:addItems(1000, function()
			return {
				{ title = i18n("enableAnnouncements"),	fn = mod.toggleAnnouncementsEnabled, checked = mod.isAnnouncementsEnabled() },
				{ title = i18n("enableVisualAlerts"), 	fn = mod.toggleVisualAlertsEnabled, checked = mod.isVisualAlertsEnabled() },
				{ title = "-" },
				{ title = i18n("openDictationPreferences"), fn = mod.openDictationSystemPreferences },
			}
		end)

	-- Commands
	deps.fcpxCmds:add("FCPXHackToggleVoiceCommands")
		:whenActivated(mod.toggleEnabled)

	return mod
end

function plugin.postInit(deps)
	mod.init(deps.fcpxCmds, deps.globalCmds)
end

return plugin