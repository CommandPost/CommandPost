--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      L A N G U A G E   P L U G I N                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.language ===
---
--- Language Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log			= require("hs.logger").new("lang")

local fs			= require("hs.fs")
local inspect		= require("hs.inspect")
local timer			= require("hs.timer")

local fcp 			= require("cp.finalcutpro")
local dialog		= require("cp.dialog")
local tools			= require("cp.tools")
local config		= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 6
local LANGUAGE_PATH = config.languagePath

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.installedLanguages = {}

--- plugins.core.language.loadCommandPostLanguages() -> nil
--- Function
--- Loads Command Post Languages
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.loadCommandPostLanguages()
	--log.df("Loading CommandPost Languages")
	for file in fs.dir(LANGUAGE_PATH) do
		if file:sub(-4) == ".lua" then
			local languageFile = io.open(LANGUAGE_PATH .. file, "r")
			if languageFile ~= nil then
				local languageFileData = languageFile:read("*all")
				if string.find(languageFileData, "-- LANGUAGE: ") ~= nil then
					local fileLanguage = string.sub(languageFileData, string.find(languageFileData, "-- LANGUAGE: ") + 13, string.find(languageFileData, "\n") - 1)
					local languageID = string.sub(file, 1, -5)
					mod.installedLanguages[#mod.installedLanguages + 1] = { id = languageID, language = fileLanguage }
				end
				languageFile:close()
			end
		end
	end
	table.sort(mod.installedLanguages, function(a, b) return a.language < b.language end)
end

--- plugins.core.language.getCommandPostLanguages() -> table
--- Function
--- Gets CommandPost Languages in Table
---
--- Parameters:
---  * None
---
--- Returns:
---  * installedLanguages - table of Installed Languages
function mod.getCommandPostLanguages()
	if #mod.installedLanguages == 0 then
		mod.loadCommandPostLanguages()
	end
	return mod.installedLanguages
end

--- plugins.core.language.getCommandPostLanguagesMenu() -> nil
--- Function
--- Gets a table for the Menubar creation of all the supported CommandPost Languages
---
--- Parameters:
---  * None
---
--- Returns:
---  * settingsLanguage - table of Supported Languages for CommandPost's Menubar
local function getCommandPostLanguagesMenu()
	local userLocale = config.get("language", nil)

	if mod._lastUserLocale ~= nil and mod._lastUserLocale == userLocale then
		return mod._lastCPLanguageCache
	else
		--log.df("Not using CommandPost Language Menu Cache")

		if userLocale == nil then userLocale = tools.userLocale() end

		local basicUserLocale = nil
		if string.find(userLocale, "_") ~= nil then
			basicUserLocale = string.sub(userLocale, 1, string.find(userLocale, "_") - 1)
		else
			basicUserLocale = userLocale
		end

		local selectedLanguage = nil
		local settingsLanguage = {}
		local commandPostLanguages = mod.getCommandPostLanguages()
		for i,language in ipairs(commandPostLanguages) do

			local checkedLanguage = (userLocale == language["id"] or basicUserLocale == language["id"])
			if checkedLanguage then
				--log.df("Setting CommandPost Language to: %s", language["id"])
				config.set("language", language["id"])
			end

			settingsLanguage[i] = { title = language["language"], fn = function()
				config.set("language", language["id"])
				i18n.setLocale(language["id"])
			end, checked = checkedLanguage, }

		end

		mod._lastUserLocale = userLocale
		mod._lastCPLanguageCache = settingsLanguage

		return settingsLanguage
	end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.language",
	group			= "core",
	dependencies	= {
		["core.preferences.panels.general"]	= "general",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	-------------------------------------------------------------------------------
	-- Cache Languages on Load:
	-------------------------------------------------------------------------------
	getCommandPostLanguagesMenu()

	--------------------------------------------------------------------------------
	-- Setup General Preferences Panel:
	--------------------------------------------------------------------------------
	deps.general:addHeading(40, function()
			return { title = "<br />Language:" }
		end)

	:addDropdown(41, "", getCommandPostLanguagesMenu)

	return mod
end

return plugin