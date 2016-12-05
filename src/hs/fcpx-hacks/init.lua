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





-------------------------------------------------------------------------------
-- CONSTANTS:
-------------------------------------------------------------------------------

scriptVersion 				= "0.70"
finalCutProBundleID 		= "com.apple.FinalCut"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   T H E    M A I N    S C R I P T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- INTERNAL EXTENSIONS:
--------------------------------------------------------------------------------

application 				= require("hs.application")
console 					= require("hs.console")
drawing 					= require("hs.drawing")
fs 							= require("hs.fs")
inspect 					= require("hs.inspect")
osascript 					= require("hs.osascript")
styledtext 					= require("hs.styledtext")
keycodes					= require("hs.keycodes")

--------------------------------------------------------------------------------
-- LOAD SCRIPT:
--------------------------------------------------------------------------------
function loadScript()

	--------------------------------------------------------------------------------
	-- CLEAR THE CONSOLE:
	--------------------------------------------------------------------------------
	console.clearConsole()

	--------------------------------------------------------------------------------
	-- DISPLAY WELCOME MESSAGE IN THE CONSOLE:
	--------------------------------------------------------------------------------
	writeToConsole("-----------------------------", true)
	writeToConsole("| FCPX Hacks v" .. scriptVersion .. "          |", true)
	writeToConsole("| Created by LateNite Films |", true)
	writeToConsole("-----------------------------", true)

	--------------------------------------------------------------------------------
	-- CHECK FINAL CUT PRO VERSION:
	--------------------------------------------------------------------------------
	local fcpVersion = finalCutProVersion()
	local osVersion = macOSVersion()

	--------------------------------------------------------------------------------
	-- Display Useful Debugging Information in Console:
	--------------------------------------------------------------------------------
	if osVersion ~= nil then 						writeToConsole("macOS Version: " .. tostring(osVersion)) 								end
	if fcpVersion ~= nil then						writeToConsole("Final Cut Pro Version: " .. tostring(fcpVersion))						end
	if keycodes.currentLayout() ~= nil then 		writeToConsole("Current Keyboard Layout: " .. tostring(keycodes.currentLayout())) 		end

	local validFinalCutProVersion = false
	if fcpVersion == "10.2.3" then
		validFinalCutProVersion = true
		require("hs.fcpx-hacks.fcpx10-2-3")
	end
	if fcpVersion:sub(1,4) == "10.3" then
		validFinalCutProVersion = true
		require("hs.fcpx-hacks.fcpx10-3")
	end
	if not validFinalCutProVersion then
		writeToConsole("[FCPX Hacks] FATAL ERROR: Could not find Final Cut Pro X.")
		displayAlertMessage("We couldn't find a compatible version of Final Cut Pro installed on this system.\n\nPlease make sure Final Cut Pro 10.2.3 or 10.3.1 is installed in the root of the Applications folder and hasn't been renamed to something other than 'Final Cut Pro'.\n\nHammerspoon will now quit.")
		application.get("Hammerspoon"):kill()
	end

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
	if type(value) == "table" then value = inspect(value) end
	if (value:sub(1, 21) ~= "-- Loading extension:") and (value:sub(1, 8) ~= "-- Done.") then
		local consoleStyledText = styledtext.new(value, {
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
		if type(value) == "table" then value = inspect(value) end
		if overrideLabel == nil then value = "> " .. value end
		local consoleStyledText = styledtext.new(value, {
			color = drawing.color.definedCollections.hammerspoon["blue"],
			font = { name = "Menlo", size = 12 },
		})
		console.printStyledtext(consoleStyledText)
	end
end

--------------------------------------------------------------------------------
-- DISPLAY ALERT MESSAGE:
--------------------------------------------------------------------------------
function displayAlertMessage(whatMessage)
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"OK"} with icon stop
	]]
	osascript.applescript(appleScriptA .. appleScriptB)
end

--------------------------------------------------------------------------------
-- IS FINAL CUT PRO INSTALLED:
--------------------------------------------------------------------------------
function isFinalCutProInstalled()
	local path = application.pathForBundleID(finalCutProBundleID)
	return doesDirectoryExist(path)
end

--------------------------------------------------------------------------------
-- RETURNS FCPX VERSION:
--------------------------------------------------------------------------------
function finalCutProVersion()
	local version = nil
	if isFinalCutProInstalled() then
		ok,version = osascript.applescript('return version of application id "'..finalCutProBundleID..'"')
	end
	return version or "Not Installed"
end

-------------------------------------------------------------------------------
-- RETURNS MACOS VERSION:
-------------------------------------------------------------------------------
function macOSVersion()
	local osVersion = hs.host.operatingSystemVersion()
	local osVersionString = (tostring(osVersion["major"]) .. "." .. tostring(osVersion["minor"]) .. "." .. tostring(osVersion["patch"]))
	return osVersionString
end


--------------------------------------------------------------------------------
-- DOES DIRECTORY EXIST:
--------------------------------------------------------------------------------
function doesDirectoryExist(path)
    local attr = fs.attributes(path)
    return attr and attr.mode == 'directory'
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                L E T ' S     D O     T H I S     T H I N G !               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

loadScript()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
