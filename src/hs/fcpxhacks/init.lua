--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  			  ===========================================
--
--  			             F C P X    H A C K S
--
--			      ===========================================
--
--
--  Thrown together by Chris Hocking @ LateNite Films
--  https://latenitefilms.com
--
--  You can download the latest version here:
--  https://latenitefilms.com/blog/final-cut-pro-hacks/
--
--  Please be aware that I'm a filmmaker, not a programmer, so... apologies!
--
--------------------------------------------------------------------------------
--  LICENSE:
--------------------------------------------------------------------------------
--
-- The MIT License (MIT)
--
-- Copyright (c) 2016 Chris Hocking.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
--------------------------------------------------------------------------------
--  FCPX HACKS LOGO DESIGNED BY:
--------------------------------------------------------------------------------
--
--  > Sam Woodhall (https://twitter.com/SWDoctor)
--
--------------------------------------------------------------------------------
--  USING SNIPPETS OF CODE FROM:
--------------------------------------------------------------------------------
--
--  > http://www.hammerspoon.org/go/
--  > https://github.com/asmagill/hs._asm.axuielement
--  > https://github.com/asmagill/hammerspoon_asm/tree/master/touchbar
--  > https://github.com/Hammerspoon/hammerspoon/issues/272
--  > https://github.com/Hammerspoon/hammerspoon/issues/1021#issuecomment-251827969
--  > https://github.com/Hammerspoon/hammerspoon/issues/1027#issuecomment-252024969
--
--------------------------------------------------------------------------------
--  HUGE SPECIAL THANKS TO THESE AMAZING DEVELOPERS FOR ALL THEIR HELP:
--------------------------------------------------------------------------------
--
--  > Aaron Magill 				https://github.com/asmagill
--  > Chris Jones 				https://github.com/cmsj
--  > Bill Cheeseman 			http://pfiddlesoft.com
--  > David Peterson 			https://github.com/randomeizer
--  > Yvan Koenig 				http://macscripter.net/viewtopic.php?id=45148
--  > Tim Webb 					https://twitter.com/_timwebb_
--
--------------------------------------------------------------------------------
--  VERY SPECIAL THANKS TO THESE AWESOME TESTERS & SUPPORTERS:
--------------------------------------------------------------------------------
--
--  > The always incredible Karen Hocking!
--  > Daniel Daperis & David Hocking
--  > Alex Gollner (http://alex4d.com)
--  > Scott Simmons (http://www.scottsimmons.tv)
--  > FCPX Editors InSync Facebook Group
--  > Isaac J. Terronez (https://twitter.com/ijterronez)
--  > Андрей Смирнов, Al Piazza, Shahin Shokoui, Ilyas Akhmedov & Tim Webb
--
--  Latest credits at: https://latenitefilms.com/blog/final-cut-pro-hacks/
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        T H E    M O D U L E                                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mod = {}

-------------------------------------------------------------------------------
-- CONSTANTS:
-------------------------------------------------------------------------------

mod.scriptVersion 		= "0.71"
mod.bugReportEmail		= "chris@latenitefilms.com"
mod.developerURL		= "https://latenitefilms.com/blog/final-cut-pro-hacks/"
mod.updateURL			= "https://latenitefilms.com/blog/final-cut-pro-hacks/#download"
mod.checkUpdateURL		= "https://latenitefilms.com/downloads/fcpx-hammerspoon-version.html"
mod.iconPath			= "~/.hammerspoon/hs/fcpxhacks/assets/fcpxhacks.icns"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    T H E    M A I N    S C R I P T                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- BUILT-IN EXTENSIONS:
--------------------------------------------------------------------------------

local application 				= require("hs.application")
local console 					= require("hs.console")
local drawing					= require("hs.drawing")
local fs						= require("hs.fs")
local inspect					= require("hs.inspect")
local keycodes					= require("hs.keycodes")
local logger					= require("hs.logger")
local settings					= require("hs.settings")
local styledtext				= require("hs.styledtext")
local timer						= require("hs.timer")

--------------------------------------------------------------------------------
-- DEBUG MODE:
--------------------------------------------------------------------------------
if settings.get("fcpxHacks.debugMode") then

	--------------------------------------------------------------------------------
	-- Logger Level (defaults to 'warn' if not specified)
	--------------------------------------------------------------------------------
	logger.defaultLogLevel = 'debug'

	--------------------------------------------------------------------------------
	-- This will test that our global/local values are set up correctly
	-- by forcing a garbage collection.
	--------------------------------------------------------------------------------
	timer.doAfter(5, collectgarbage)

end

--------------------------------------------------------------------------------
-- CUSTOM EXTENSIONS:
--------------------------------------------------------------------------------

local dialog					= require("hs.fcpxhacks.modules.dialog")
local fcp 						= require("hs.finalcutpro")
local tools						= require("hs.fcpxhacks.modules.tools")

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------

local hsBundleID				= hs.processInfo["bundleID"]

--------------------------------------------------------------------------------
-- LOAD SCRIPT:
--------------------------------------------------------------------------------
function mod.init()

	--------------------------------------------------------------------------------
	-- Clear The Console:
	--------------------------------------------------------------------------------
	console.clearConsole()

	--------------------------------------------------------------------------------
	-- Display Welcome Message In The Console:
	--------------------------------------------------------------------------------
	writeToConsole("-----------------------------", true)
	writeToConsole("| FCPX Hacks v" .. mod.scriptVersion .. "          |", true)
	writeToConsole("| Created by LateNite Films |", true)
	writeToConsole("-----------------------------", true)

	--------------------------------------------------------------------------------
	-- Check All The Required Files Exist:
	--------------------------------------------------------------------------------
	local requiredFiles = {
		"hs/fcpxhacks/init.lua",
		"hs/fcpxhacks/assets/fcpxhacks.icns",
		"hs/fcpxhacks/assets/fcpxhacks.png",
		"hs/fcpxhacks/modules/clipboard.lua",
		"hs/fcpxhacks/modules/dialog.lua",
		"hs/fcpxhacks/modules/fcpx10-2-3.lua",
		"hs/fcpxhacks/modules/fcpx10-3.lua",
		"hs/fcpxhacks/modules/protect.lua",
		"hs/fcpxhacks/modules/tools.lua",
		"hs/fcpxhacks/plist/10-2-3/new/NSProCommandGroups.plist",
		"hs/fcpxhacks/plist/10-2-3/new/NSProCommands.plist",
		"hs/fcpxhacks/plist/10-2-3/new/en.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-2-3/new/en.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-2-3/new/en.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-2-3/old/NSProCommandGroups.plist",
		"hs/fcpxhacks/plist/10-2-3/old/NSProCommands.plist",
		"hs/fcpxhacks/plist/10-2-3/old/en.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-2-3/old/en.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-2-3/old/en.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/old/NSProCommandGroups.plist",
		"hs/fcpxhacks/plist/10-3/old/NSProCommands.plist",
		"hs/fcpxhacks/plist/10-3/old/en.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/old/en.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/old/en.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/old/de.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/old/de.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/old/de.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/old/es.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/old/es.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/old/es.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/old/fr.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/old/fr.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/old/fr.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/old/ja.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/old/ja.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/old/ja.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/old/zh_CN.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/old/zh_CN.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/old/zh_CN.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/new/NSProCommandGroups.plist",
		"hs/fcpxhacks/plist/10-3/new/NSProCommands.plist",
		"hs/fcpxhacks/plist/10-3/new/en.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/new/en.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/new/en.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/new/de.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/new/de.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/new/de.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/new/es.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/new/es.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/new/es.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/new/fr.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/new/fr.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/new/fr.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/new/ja.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/new/ja.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/new/ja.lproj/NSProCommandNames.strings",
		"hs/fcpxhacks/plist/10-3/new/zh_CN.lproj/Default.commandset",
		"hs/fcpxhacks/plist/10-3/new/zh_CN.lproj/NSProCommandDescriptions.strings",
		"hs/fcpxhacks/plist/10-3/new/zh_CN.lproj/NSProCommandNames.strings" }
	local checkFailed = false
	for i=1, #requiredFiles do
		if fs.attributes(requiredFiles[i]) == nil then checkFailed = true end
	end
	if checkFailed then
		writeToConsole("[FCPX Hacks] FATAL ERROR: Missing required files.")
		dialog.displayAlertMessage("FCPX Hacks is missing some of its required files.\n\nPlease try re-downloading the latest version from the website, and make sure you follow the installation instructions.\n\nHammerspoon will now quit.")
		application.applicationsForBundleID(hsBundleID)[1]:kill()
	end

	--------------------------------------------------------------------------------
	-- Check Final Cut Pro Version:
	--------------------------------------------------------------------------------
	local fcpVersion = fcp.version()
	local osVersion = tools.macOSVersion()
	local fcpLanguage = fcp.currentLanguage()

	--------------------------------------------------------------------------------
	-- Display Useful Debugging Information in Console:
	--------------------------------------------------------------------------------
	if osVersion ~= nil then 					writeToConsole("macOS Version: " .. tostring(osVersion), true) 								end
	if fcpVersion ~= nil then					writeToConsole("Final Cut Pro Version: " .. tostring(fcpVersion), true)						end
	if fcpLanguage ~= nil then 					writeToConsole("Final Cut Pro Language: " .. tostring(fcpLanguage), true)					end
	if keycodes.currentLayout() ~= nil then 	writeToConsole("Current Keyboard Layout: " .. tostring(keycodes.currentLayout()), true) 	end

	writeToConsole("", true)

	local validFinalCutProVersion = false
	if fcpVersion == "10.2.3" then
		validFinalCutProVersion = true
		require("hs.fcpxhacks.modules.fcpx10-2-3")
	end
	if fcpVersion:sub(1,4) == "10.3" then
		validFinalCutProVersion = true
		require("hs.fcpxhacks.modules.fcpx10-3")
	end
	if not validFinalCutProVersion then
		writeToConsole("[FCPX Hacks] FATAL ERROR: Could not find Final Cut Pro X.")
		dialog.displayAlertMessage("FCPX Hacks couldn't find a compatible version of Final Cut Pro installed on this system.\n\nPlease make sure Final Cut Pro 10.2.3, 10.3 or later is installed in the root of the Applications folder and hasn't been renamed to something other than 'Final Cut Pro'.\n\nHammerspoon will now quit.")
		application.applicationsForBundleID(hsBundleID)[1]:kill()
	end

	return self
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C O M M O N    F U N C T I O N S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- REPLACE THE BUILT-IN PRINT FEATURE:
--------------------------------------------------------------------------------
print = function(value)
	if type(value) == "table" then
		value = inspect(value)
	else
		value = tostring(value)
	end

	--------------------------------------------------------------------------------
	-- Reformat hs.logger values:
	--------------------------------------------------------------------------------
	if string.sub(value, 1, 8) == string.match(value, "%d%d:%d%d:%d%d") then
		value = string.sub(value, 9, string.len(value)) .. " [" .. string.sub(value, 1, 8) .. "]"
		value = string.gsub(value, "     ", " ")
		value =	" > " .. string.gsub(value, "^%s*(.-)%s*$", "%1")
		local consoleStyledText = styledtext.new(value, {
			color = drawing.color.definedCollections.hammerspoon["red"],
			font = { name = "Menlo", size = 12 },
		})
		console.printStyledtext(consoleStyledText)
		return
	end

	if (value:sub(1, 21) ~= "-- Loading extension:") and (value:sub(1, 8) ~= "-- Done.") then
		value = string.gsub(value, "     ", " ")
		value = string.gsub(value, "^%s*(.-)%s*$", "%1")
		local consoleStyledText = styledtext.new(" > " .. value, {
			color = drawing.color.definedCollections.hammerspoon["red"],
			font = { name = "Menlo", size = 12 },
		})
		console.printStyledtext(consoleStyledText)
	end
end

--------------------------------------------------------------------------------
-- WRITE TO CONSOLE:
--------------------------------------------------------------------------------
function writeToConsole(value, overrideLabel)
	if value ~= nil then
		if not overrideLabel then
			value = "> "..value
		end
		local consoleStyledText = styledtext.new(value, {
			color = drawing.color.definedCollections.hammerspoon["blue"],
			font = { name = "Menlo", size = 12 },
		})
		console.printStyledtext(consoleStyledText)
	end
end

--------------------------------------------------------------------------------
-- DEBUG MESSAGE:
--------------------------------------------------------------------------------
function debugMessage(value, value2)
	if value2 ~= nil then
		local consoleStyledText = styledtext.new(" > " .. tostring(value) .. ": " .. tostring(value2), {
			color = drawing.color.definedCollections.hammerspoon["red"],
			font = { name = "Menlo", size = 12 },
		})
		console.printStyledtext(consoleStyledText)
	else
		if value ~= nil then
			if type(value) == "string" then value = string.gsub(value, "\n\n", "\n > ") end
			if settings.get("fcpxHacks.debugMode") then
				local consoleStyledText = styledtext.new(" > " .. value, {
					color = drawing.color.definedCollections.hammerspoon["red"],
					font = { name = "Menlo", size = 12 },
				})
				console.printStyledtext(consoleStyledText)
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                L E T ' S     D O     T H I S     T H I N G !               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ASSIGN OUR MOD TO THE GLOBAL 'FCPXHACKS' OBJECT:
--------------------------------------------------------------------------------
fcpxhacks = mod

--------------------------------------------------------------------------------
-- KICK IT OFF!
--------------------------------------------------------------------------------
return mod.init()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------