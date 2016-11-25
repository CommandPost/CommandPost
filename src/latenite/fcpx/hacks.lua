local mod = {}

-------------------------------------------------------------------------------
-- Requirements
-------------------------------------------------------------------------------
local fs						= require("hs.fs")
local osascript 				= require("hs.osascript")

-------------------------------------------------------------------------------
-- SCRIPT VERSION:
-------------------------------------------------------------------------------
scriptVersion = "0.70"
-------------------------------------------------------------------------------

function mod.version()
	return scriptVersion;
end

--------------------------------------------------------------------------------
-- IS FINAL CUT PRO INSTALLED:
--------------------------------------------------------------------------------
function mod.isFinalCutProInstalled()
	return mod.doesDirectoryExist('/Applications/Final Cut Pro.app')
end

--------------------------------------------------------------------------------
-- RETURNS FCPX VERSION:
--------------------------------------------------------------------------------
function mod.finalCutProVersion()
	if mod.isFinalCutProInstalled() then
		ok,appleScriptFinalCutProVersion = osascript.applescript('return version of application "Final Cut Pro"')
		return appleScriptFinalCutProVersion
	else
		return "Not Installed"
	end
end

--------------------------------------------------------------------------------
-- LAUNCH FINAL CUT PRO:
--------------------------------------------------------------------------------
function mod.launchFinalCutPro()
	hs.application.launchOrFocus("Final Cut Pro")
end

--------------------------------------------------------------------------------
-- IS FINAL CUT PRO FRONTMOST?
--------------------------------------------------------------------------------
function mod.isFinalCutProFrontmost()

	local fcpx = hs.appfinder.appFromName("Final Cut Pro")
	if fcpx == nil then
		return false
	else
		return fcpx:isFrontmost()
	end

end

--------------------------------------------------------------------------------
-- DOES DIRECTORY EXIST:
--------------------------------------------------------------------------------
function mod.doesDirectoryExist(path)
    local attr = fs.attributes(path)
    return attr and attr.mode == 'directory'
end

--------------------------------------------------------------------------------
-- DISPLAY ALERT MESSAGE:
--------------------------------------------------------------------------------
function mod.displayAlertMessage(whatMessage)
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"OK"} with icon stop
	]]
	osascript.applescript(appleScriptA .. appleScriptB)
end

--------------------------------------------------------------------------------
-- INITIALISES THE HACK
--------------------------------------------------------------------------------
function mod.init()
	--------------------------------------------------------------------------------
	-- CLEAR THE CONSOLE:
	--------------------------------------------------------------------------------
	hs.console.clearConsole()

	--------------------------------------------------------------------------------
	-- DISPLAY WELCOME MESSAGE IN THE CONSOLE:
	--------------------------------------------------------------------------------
	print("====================================================")
	print("                  FCPX Hacks v" .. mod.version()     )
	print("====================================================")
	print("    If you have any problems with this script,      ")
	print("  please email a screenshot of your entire screen   ")
	print(" with this console open to: chris@latenitefilms.com ")
	print("====================================================")
	
	local finalCutProVersion = mod.finalCutProVersion()

	local validFinalCutProVersion = false
	if finalCutProVersion == "10.2.3" then
		validFinalCutProVersion = true
		require("hs.fcpx10-2-3")
	end
	if finalCutProVersion == "10.3" then
		validFinalCutProVersion = true
		require("hs.fcpx10-3")
	end
	if not validFinalCutProVersion then
		print("[FCPX Hacks] FATAL ERROR: Could not find '/Applications/Final Cut Pro.app'.")
		mod.displayAlertMessage("We couldn't find a compatible version of Final Cut Pro installed on this system.\n\nPlease make sure Final Cut Pro 10.2.3 or 10.3 is installed in the root of the Applications folder and hasn't been renamed.\n\nHammerspoon will now quit.")
		application.get("Hammerspoon"):kill()
	end
end

return mod