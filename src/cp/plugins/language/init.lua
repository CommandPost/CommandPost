--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      L A N G U A G E   P L U G I N                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}
mod.installedLanguages = {}

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log			= require("hs.logger").new("lang")

local fs			= require("hs.fs")
local inspect		= require("hs.inspect")
local timer			= require("hs.timer")

local fcp 			= require("cp.finalcutpro")
local dialog		= require("cp.dialog")
local tools			= require("cp.tools")
local metadata		= require("cp.metadata")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY = 6
local LANGUAGE_PATH = metadata.languagePath

--------------------------------------------------------------------------------
-- LOAD LANGUAGES:
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- GET LANGUAGES:
--------------------------------------------------------------------------------
function mod.getCommandPostLanguages()
	if #mod.installedLanguages == 0 then
		mod.loadCommandPostLanguages()
	end
	return mod.installedLanguages
end

--------------------------------------------------------------------------------
-- CHANGE FINAL CUT PRO LANGUAGE:
--------------------------------------------------------------------------------
function mod.changeFinalCutProLanguage(language)

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartStatus = false
	if fcp:isRunning() then
		if dialog.displayYesNoQuestion(i18n("changeFinalCutProLanguage") .. "\n\n" .. i18n("doYouWantToContinue")) then
			restartStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Update Final Cut Pro's settings::
	--------------------------------------------------------------------------------
	local result = fcp:setPreference("AppleLanguages", {language})
	if not result then
		dialog.displayErrorMessage(i18n("failedToChangeLanguage"))
	end

	--------------------------------------------------------------------------------
	-- Change Language:
	--------------------------------------------------------------------------------
	fcp:getCurrentLanguage(true, language)

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if restartStatus then
		if not fcp:restart() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			dialog.displayErrorMessage(i18n("failedToRestart"))
			return "Failed"
		end
	end

end

--------------------------------------------------------------------------------
-- GET FINAL CUT PRO LANGUAGES MENU:
--------------------------------------------------------------------------------
local function getFinalCutProLanguagesMenu()
	local currentLanguage = fcp:getCurrentLanguage()
	if mod._lastFCPXLanguage ~= nil and mod._lastFCPXLanguage == currentLanguage and mod._lastFCPXLanguageCache ~= nil then
		--log.df("Using FCPX Language Menu Cache")
		return mod._lastFCPXLanguageCache
	else
		--log.df("Not using FCPX Language Menu Cache")
		local result = {
			{ title = i18n("german"),			fn = function() mod.changeFinalCutProLanguage("de") end, 				checked = currentLanguage == "de"},
			{ title = i18n("english"), 			fn = function() mod.changeFinalCutProLanguage("en") end, 				checked = currentLanguage == "en"},
			{ title = i18n("spanish"), 			fn = function() mod.changeFinalCutProLanguage("es") end, 				checked = currentLanguage == "es"},
			{ title = i18n("french"), 			fn = function() mod.changeFinalCutProLanguage("fr") end, 				checked = currentLanguage == "fr"},
			{ title = i18n("japanese"), 		fn = function() mod.changeFinalCutProLanguage("ja") end, 				checked = currentLanguage == "ja"},
			{ title = i18n("chineseChina"),		fn = function() mod.changeFinalCutProLanguage("zh_CN") end, 			checked = currentLanguage == "zh_CN"},
		}
		mod._lastFCPXLanguage = currentLanguage
		mod._lastFCPXLanguageCache = result
		return result
	end
end

--------------------------------------------------------------------------------
-- GET COMMANDPOST LANGUAGES MENU:
--------------------------------------------------------------------------------
local function getCommandPostLanguagesMenu()
	local userLocale = metadata.get("language", nil)

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
				metadata.set("language", language["id"])
			end

			settingsLanguage[i] = { title = language["language"], fn = function()
				metadata.set("language", language["id"])
				i18n.setLocale(language["id"])
			end, checked = checkedLanguage, }

		end

		mod._lastUserLocale = userLocale
		mod._lastCPLanguageCache = settingsLanguage

		return settingsLanguage
	end
end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.top"]	= "top",
	["cp.plugins.menu.preferences"]	= "prefs",
}

function plugin.init(deps)

	-------------------------------------------------------------------------------
	-- Cache Languages on Load:
	-------------------------------------------------------------------------------
	getFinalCutProLanguagesMenu()
	getCommandPostLanguagesMenu()

	-------------------------------------------------------------------------------
	-- New Menu Section:
	-------------------------------------------------------------------------------
	local section = deps.top:addSection(PRIORITY)

	-------------------------------------------------------------------------------
	-- The FCPX Languages Menu:
	-------------------------------------------------------------------------------
	local fcpxLangs = section:addMenu(100, function() return i18n("finalCutProLanguage") end)
	fcpxLangs:addItems(1, getFinalCutProLanguagesMenu)

	-------------------------------------------------------------------------------
	-- The CommandPost Languages Menu:
	-------------------------------------------------------------------------------
	local section = deps.prefs:addSection(PRIORITY)

	local cpLangs = section:addMenu(200, function() return i18n("language") end)
	cpLangs:addItems(1, getCommandPostLanguagesMenu)

	section:addSeparator(9000)

	return mod
end

return plugin