local mod = {}

-------------------------------------------------------------------------------
-- Requirements
-------------------------------------------------------------------------------
local fs								= require("hs.fs")
local osascript 				= require("hs.osascript")

-------------------------------------------------------------------------------
-- SCRIPT VERSION:
-------------------------------------------------------------------------------
local hacksVersion = "0.70"
-------------------------------------------------------------------------------

mod.version() {
	return hacksVersion;
}

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

return mod