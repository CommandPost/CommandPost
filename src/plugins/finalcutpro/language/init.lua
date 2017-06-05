--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       F I N A L    C U T    P R O    L A N G U A G E    P L U G I N        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.language ===
---
--- Final Cut Pro Language Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log			= require("hs.logger").new("lang")

local fs			= require("hs.fs")
local inspect		= require("hs.inspect")
local timer			= require("hs.timer")

local dialog		= require("cp.dialog")
local fcp 			= require("cp.apple.finalcutpro")
local config		= require("cp.config")
local tools			= require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 		= 6

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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
	fcp:setCurrentLanguage(language)

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
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.language",
	group = "finalcutpro",
	dependencies = {
		["core.menu.top"]			= "top",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	-------------------------------------------------------------------------------
	-- Cache Languages on Load:
	-------------------------------------------------------------------------------
	getFinalCutProLanguagesMenu()

	-------------------------------------------------------------------------------
	-- New Menu Section:
	-------------------------------------------------------------------------------
	local section = deps.top:addSection(PRIORITY)

	-------------------------------------------------------------------------------
	-- The FCPX Languages Menu:
	-------------------------------------------------------------------------------
	local fcpxLangs = section:addMenu(100, function()
		if fcp:isInstalled() then
			return i18n("finalCutProLanguage")
		end
	end)
	fcpxLangs:addItems(1, getFinalCutProLanguagesMenu)

	return mod
end

return plugin