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
--  Please be aware that I'm a filmmaker, not a coder, so... apologies!
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
--  > https://github.com/Hammerspoon/hammerspoon/issues/272
--  > https://github.com/Hammerspoon/hammerspoon/issues/1021#issuecomment-251827969
--  > https://github.com/Hammerspoon/hammerspoon/issues/1027#issuecomment-252024969
--
--------------------------------------------------------------------------------
--  HUGE SPECIAL THANKS TO THESE AMAZING DEVELOPERS FOR ALL THEIR HELP:
--------------------------------------------------------------------------------
--
--  > Aaron Magill (https://github.com/asmagill)
--  > Chris Jones (https://github.com/cmsj)
--  > Bill Cheeseman (http://pfiddlesoft.com)
--  > Yvan Koenig (http://macscripter.net/viewtopic.php?id=45148)
--  > Tim Webb (https://twitter.com/_timwebb_)
--
--------------------------------------------------------------------------------
--  VERY SPECIAL THANKS TO THESE AWESOME TESTERS & SUPPORTERS:
--------------------------------------------------------------------------------
--
--  > The always incredible Karen Hocking!
--  > Daniel Daperis & David Hocking
--  > Андрей Смирнов
--  > FCPX Editors InSync Facebook Group
--  > Alex Gollner (http://alex4d.com)
--  > Scott Simmons (http://www.scottsimmons.tv)
--  > Isaac J. Terronez (https://twitter.com/ijterronez)
--  > Shahin Shokoui, Ilyas Akhmedov & Tim Webb
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





-------------------------------------------------------------------------------
-- SCRIPT VERSION:
-------------------------------------------------------------------------------
scriptVersion = "0.65"
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   T H E    M A I N    S C R I P T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CLEAR THE CONSOLE:
--------------------------------------------------------------------------------
hs.console.clearConsole()

--------------------------------------------------------------------------------
-- DISPLAY WELCOME MESSAGE IN THE CONSOLE:
--------------------------------------------------------------------------------
print("====================================================")
print("                  FCPX Hacks v" .. scriptVersion     )
print("====================================================")
print("    If you have any problems with this script,      ")
print("  please email a screenshot of your entire screen   ")
print(" with this console open to: chris@latenitefilms.com ")
print("====================================================")

--------------------------------------------------------------------------------
-- LOAD EXTENSIONS:
--------------------------------------------------------------------------------

-- BUILT-IN:

	osascript 					= require("hs.osascript")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   T H E    M A I N    S C R I P T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function loadScript()

	finalCutProVersion = finalCutProVersion()

	if finalCutProVersion == nil then
		displayAlertMessage("We couldn't find a compatible version of Final Cut Pro installed on this system.\n\nPlease make sure it's installed in the Applications folder and hasn't been renamed.")
	end
	if finalCutProVersion == "10.2.3" then
		require("hs.fcpx10-2-3")
	end
	if finalCutProVersion == "10.3" then
		require("hs.fcpx10-3")
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
-- DISPLAY ALERT MESSAGE:
--------------------------------------------------------------------------------
function displayAlertMessage(whatMessage)
	local returnToFinalCutPro = isFinalCutProFrontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"OK"} with icon stop
	]]
	hs.osascript.applescript(appleScriptA .. appleScriptB)
	if returnToFinalCutPro then launchFinalCutPro() end
end

--------------------------------------------------------------------------------
-- IS FINAL CUT PRO INSTALLED:
--------------------------------------------------------------------------------
function isFinalCutProInstalled()
	return doesDirectoryExist('/Applications/Final Cut Pro.app')
end

--------------------------------------------------------------------------------
-- RETURNS FCPX VERSION:
--------------------------------------------------------------------------------
function finalCutProVersion()
	if isFinalCutProInstalled() then
		ok,appleScriptFinalCutProVersion = hs.osascript.applescript('return version of application "Final Cut Pro"')
		return appleScriptFinalCutProVersion
	else
		return "Not Installed"
	end
end

--------------------------------------------------------------------------------
-- DOES DIRECTORY EXIST:
--------------------------------------------------------------------------------
function doesDirectoryExist(path)
    local attr = hs.fs.attributes(path)
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