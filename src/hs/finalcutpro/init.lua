--- === hs.finalcutpro ===
---
--- Controls for Final Cut Pro
---
--- Thrown together by:
---   Chris Hocking (https://github.com/latenitefilms)
---

local finalcutpro = {}

local finalCutProBundleID 					= "com.apple.FinalCut"
local finalCutProClipboardUTI 				= "com.apple.flexo.proFFPasteboardUTI"
local finalCutProPreferencesPlistPath 		= "~/Library/Preferences/com.apple.FinalCut.plist"
local finalCutProLanguages 					= {"de", "en", "es", "fr", "ja", "zh_CN"}
local finalCutProFlexoLanguages				= {"de", "en", "es_419", "es", "fr", "id", "ja", "ms", "vi", "zh_CN"}

local plist 								= require("hs.plist")
local application 							= require("hs.application")
local osascript 							= require("hs.osascript")
local fs 									= require("hs.fs")
local ax 									= require("hs._asm.axuielement")

--- hs.finalcutpro.flexoLanguages() -> table
--- Function
--- Returns a table of languages Final Cut Pro's Flexo Framework supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
---
function finalcutpro.flexoLanguages()
	return finalCutProFlexoLanguages
end

--- hs.finalcutpro.languages() -> table
--- Function
--- Returns a table of languages Final Cut Pro supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
---
function finalcutpro.languages()
	return finalCutProLanguages
end

--- hs.finalcutpro.clipboardUTI() -> string
--- Function
--- Returns the Final Cut Pro Bundle ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing the Final Cut Pro Bundle ID
---
function finalcutpro.bundleID()
	return finalCutProBundleID
end

--- hs.finalcutpro.clipboardUTI() -> string
--- Function
--- Returns the Final Cut Pro Clipboard UTI
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing the Final Cut Pro Clipboard UTI
---
function finalcutpro.clipboardUTI()
	return finalCutProClipboardUTI
end

--- hs.finalcutpro.getPreferencesAsTable() -> table or nil
--- Function
--- Gets Final Cut Pro's Preferences as a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table with all of Final Cut Pro's preferences, or nil if an error occurred
---
function finalcutpro.getPreferencesAsTable()
	local preferencesTable = plist.binaryFileToTable(finalCutProPreferencesPlistPath) or nil
	return preferencesTable
end

--- hs.finalcutpro.getPreference(preferenceName) -> string or nil
--- Function
--- Get an individual Final Cut Pro preference
---
--- Parameters:
---  * preferenceName - The preference you want to return
---
--- Returns:
---  * A string with the preference value, or nil if an error occurred
---
function finalcutpro.getPreference(value)
	local result = nil
	local preferencesTable = plist.binaryFileToTable(finalCutProPreferencesPlistPath) or nil

	if preferencesTable ~= nil then
		result = preferencesTable[value]
	end

	return result
end

--- hs.finalcutpro.setPreference(key, value) -> boolean
--- Function
--- Sets an individual Final Cut Pro preference
---
--- Parameters:
---  * key - The preference you want to change
---  * value - The value you want to set for that preference
---
--- Returns:
---  * True if executed successfully otherwise False
---
function finalcutpro.setPreference(key, value)

	local executeResult, executeStatus

	if type(value) == "boolean" then
		executeResult, executeStatus = hs.execute("defaults write " .. finalCutProPreferencesPlistPath .. " " .. key .. " -bool " .. tostring(value))
	else
		executeResult, executeStatus = hs.execute("defaults write " .. finalCutProPreferencesPlistPath .. " " .. key .. " -string '" .. value .. "'")
	end

	if executeStatus == nil then
		return false
	else
		return true
	end

end

--- hs.finalcutpro.getActiveCommandSetPath() -> string or nil
--- Function
--- Gets the 'Active Command Set' value from the Final Cut Pro preferences
---
--- Parameters:
---  * None
---
--- Returns:
---  * The 'Active Command Set' value, or nil if an error occurred
---
function finalcutpro.getActiveCommandSetPath()
	local result = finalcutpro.getPreference("Active Command Set") or nil
	return result
end

--- hs.finalcutpro.getActiveCommandSetAsTable([optionalPath]) -> table or nil
--- Function
--- Returns the 'Active Command Set' as a Table
---
--- Parameters:
---  * optionalPath - The optional path of the Command Set
---
--- Returns:
---  * A table of the Active Command Set's contents, or nil if an error occurred
---
function finalcutpro.getActiveCommandSetAsTable(optionalPath)
	local result = nil
	local activeCommandSetPath = nil

	if optionalPath ~= nil then
		activeCommandSetPath = finalcutpro.getActiveCommandSetPath()
	else
		activeCommandSetPath = optionalPath
	end

	if activeCommandSetPath ~= nil then
		if fs.attributes(activeCommandSetPath) ~= nil then
			result = plist.xmlFileToTable(activeCommandSetPath) or nil
		end
	end

	return result
end

--- hs.finalcutpro.installed() -> boolean
--- Function
--- Is Final Cut Pro Installed?
---
--- Parameters:
---  * None
---
--- Returns:
---  * Boolean value
---
function finalcutpro.installed()
	local path = application.pathForBundleID(finalCutProBundleID)
	return doesDirectoryExist(path)
end

--- hs.finalcutpro.installed() -> string or nil
--- Function
--- Version of Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * Version as string or nil if an error occurred
---
function finalcutpro.version()
	local version = nil
	if finalcutpro.installed() then
		ok,version = osascript.applescript('return version of application id "'..finalCutProBundleID..'"')
	end
	return version or nil
end

--- hs.finalcutpro.application() -> hs.application or nil
--- Function
--- Returns the Final Cut Pro application (as hs.application)
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro application (as hs.application) or nil if an error occurred
---
function finalcutpro.application()
	local result = application(finalCutProBundleID) or nil
	return result
end

--- hs.finalcutpro.launch() -> boolean
--- Function
--- Launches Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro was either launched or focused, otherwise false (e.g. if Final Cut Pro doesn't exist)
---
function finalcutpro.launch()
	local result = application.launchOrFocusByBundleID(finalCutProBundleID)
	return result
end

--- hs.finalcutpro.running() -> boolean
--- Function
--- Is Final Cut Pro Running?
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro is running otherwise False
---
function finalcutpro.running()

	local fcpx = finalcutpro.application()
	if fcpx == nil then
		return false
	else
		return fcpx:isRunning()
	end

end

--- hs.finalcutpro.restart() -> boolean
--- Function
--- Restart Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro is running otherwise False if Final Cut Pro is not running, or fails to close or restart
---
function finalcutpro.restart()

	if finalcutpro.application() ~= nil then

		-- Kill Final Cut Pro:
		finalcutpro.application():kill()

		-- Wait until Final Cut Pro is Closed:
		local timeoutCount = 0
		repeat
			timeoutCount = timeoutCount + 1
			if timeoutCount == 10 then
				return false
			end
			sleep(1)
		until not finalcutpro.running()

		-- Launch Final Cut Pro:
		local result = finalcutpro.launch()

		return result

	else
		return false
	end

end

--- hs.finalcutpro.frontmost() -> boolean
--- Function
--- Is Final Cut Pro Frontmost?
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro is Frontmost otherwise false.
---
function finalcutpro.frontmost()

	local fcpx = finalcutpro.application()
	if fcpx == nil then
		return false
	else
		return fcpx:isFrontmost()
	end

end

--- hs.finalcutpro.getTimelineSplitGroup() -> axuielementObject or nil
--- Function
--- Get Timeline Split Group
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Timeline Split Group or nil if failed
---
function finalcutpro.getTimelineSplitGroup()

	--------------------------------------------------------------------------------
	-- Which Split Group:
	--------------------------------------------------------------------------------
	local whichSplitGroup = nil

	--------------------------------------------------------------------------------
	-- Define Final Cut Pro:
	--------------------------------------------------------------------------------
	local sw = ax.applicationElement(finalcutpro.application())

	--------------------------------------------------------------------------------
	-- Single Screen:
	--------------------------------------------------------------------------------
	whichSplitGroup = sw:searchPath({
		{ role = "AXWindow", Title = "Final Cut Pro"},								-- AXWindow "Final Cut Pro" (window 2)
		{ role = "AXSplitGroup", },												 	-- AXSplitGroup (splitter group 1)
		{ role = "AXGroup", },													    -- AXGroup (group 1)
		{ role = "AXSplitGroup", },												    -- AXSplitGroup (splitter group 1)
		{ role = "AXGroup", },												        -- AXGroup (group 2)
		{ role = "AXSplitGroup", },												 	-- AXSplitGroup (splitter group 1)
		{ role = "AXGroup", },														-- AXGroup (group 1)
		{ role = "AXSplitGroup", Identifier = "_NS:237"},							-- AXSplitGroup (splitter group 1)
	}, 1)

	--------------------------------------------------------------------------------
	-- Dual Screen:
	--------------------------------------------------------------------------------
	if whichSplitGroup == nil then

		whichSplitGroup = sw:searchPath({
			{ role = "AXWindow", Title = "Final Cut Pro"},							-- AXWindow "Final Cut Pro" (window 2)
			{ role = "AXSplitGroup", },											 	-- AXSplitGroup (splitter group 1)
			{ role = "AXGroup", },												    -- AXGroup (group 1)
			{ role = "AXSplitGroup", },											    -- AXSplitGroup (splitter group 1)
			{ role = "AXGroup", },											        -- AXGroup (group 2)
			{ role = "AXSplitGroup", Identifier = "_NS:237"},					 	-- AXSplitGroup (splitter group 1)
		}, 1)

	end

	return whichSplitGroup

end

--- hs.finalcutpro.getTimelineScrollArea() -> axuielementObject or nil
--- Function
--- Gets Timeline Scroll Area
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Timeline Scroll Area or nil if failed
---
function finalcutpro.getTimelineScrollArea()

	--------------------------------------------------------------------------------
	-- Which Split Group
	--------------------------------------------------------------------------------
	local finalCutProTimelineScrollArea = nil
	local finalCutProTimelineSplitGroup = finalcutpro.getTimelineSplitGroup()

	--------------------------------------------------------------------------------
	-- Get last scroll area:
	--------------------------------------------------------------------------------
	if finalCutProTimelineSplitGroup ~= nil then

		local whichScrollArea = nil
		for i=1, finalCutProTimelineSplitGroup:attributeValueCount("AXChildren") do
			if finalCutProTimelineSplitGroup:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
				whichScrollArea = i
			end
		end
		if whichScrollArea == nil then
			return nil
		end
		finalCutProTimelineScrollArea = finalCutProTimelineSplitGroup[whichScrollArea]

	end

	return finalCutProTimelineScrollArea

end

--- hs.finalcutpro.getTimelineButtonBar() -> axuielementObject or nil
--- Function
--- Gets Timeline Button Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Timeline Button Bar or nil if failed
---
function finalcutpro.getTimelineButtonBar()

	local finalCutProTimelineSplitGroup = finalcutpro.getTimelineSplitGroup()
	return finalCutProTimelineSplitGroup:attributeValue("AXParent")[2]

end

--- hs.finalcutpro.getEffectsTransitionsBrowserGroup() -> axuielementObject or nil
--- Function
--- Gets Effects/Transitions Browser Group
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Effects/Transitions Browser Group or nil if failed
---
function finalcutpro.getEffectsTransitionsBrowserGroup()

	--------------------------------------------------------------------------------
	-- Get Timeline Split Group:
	--------------------------------------------------------------------------------
	local finalCutProTimelineSplitGroup = finalcutpro.getTimelineSplitGroup()

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	for i=1, finalCutProTimelineSplitGroup:attributeValueCount("AXChildren") do
		if finalCutProTimelineSplitGroup[i]:attributeValue("AXRole") == "AXGroup" then
			return finalCutProTimelineSplitGroup[i]
		end
	end

	--------------------------------------------------------------------------------
	-- If things get to here it's failed:
	--------------------------------------------------------------------------------
	return nil

end

--- hs.finalcutpro.getBrowserSplitGroup() -> axuielementObject or nil
--- Function
--- Gets Browser Split Group
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Browser Split Group or nil if failed
---
function finalcutpro.getBrowserSplitGroup()

	--------------------------------------------------------------------------------
	-- Define Final Cut Pro:
	--------------------------------------------------------------------------------
	sw = ax.applicationElement(finalcutpro.application())

	--------------------------------------------------------------------------------
	-- Single Screen:
	--------------------------------------------------------------------------------
	local browserSplitGroup = sw:searchPath({
		{ role = "AXWindow", Title = "Final Cut Pro"},
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", Identifier = "_NS:344"},
	}, 1)

	--------------------------------------------------------------------------------
	-- Dual Screen:
	--------------------------------------------------------------------------------
	if browserSplitGroup == nil then
		browserSplitGroup = sw:searchPath({
			{ role = "AXWindow", Title = "Events"},
			{ role = "AXSplitGroup", },
			{ role = "AXGroup", },
			{ role = "AXSplitGroup", Identifier = "_NS:344"},
		}, 1)
	end

	return browserSplitGroup

end

--- hs.finalcutpro.getBrowserButtonBar() -> axuielementObject or nil
--- Function
--- Gets Browser Button Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Browser Button Bar or nil if failed
---
function finalcutpro.getBrowserButtonBar()
	local finalCutProBrowserSplitGroup = finalcutpro.getBrowserSplitGroup()
	if finalCutProBrowserSplitGroup ~= nil then
		return finalCutProBrowserSplitGroup:attributeValue("AXParent")
	else
		return nil
	end
end

--- hs.finalcutpro.getColorBoardRadioGroup() -> axuielementObject or nil
--- Function
--- Gets the Color Board Radio Group
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Color Board Radio Group or nil if failed
---
function finalcutpro.getColorBoardRadioGroup()

	--------------------------------------------------------------------------------
	-- Final Cut Pro:
	--------------------------------------------------------------------------------
	sw = ax.applicationElement(finalcutpro.application())

	--------------------------------------------------------------------------------
	-- Find Color Button:
	--------------------------------------------------------------------------------
	local result = sw:searchPath({
		{ role = "AXWindow", Title = "Final Cut Pro"},
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXRadioGroup", Identifier = "_NS:128"},
	}, 1)

	return result

end

-- Internal function: Does directory exist?
local function doesDirectoryExist(path)
    local attr = fs.attributes(path)
    return attr and attr.finalcutproe == 'directory'
end

return finalcutpro