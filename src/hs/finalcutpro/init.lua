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

local ax 									= require("hs._asm.axuielement")
local plist 								= require("hs.plist")

local application 							= require("hs.application")
local fs 									= require("hs.fs")
local osascript 							= require("hs.osascript")
local timer									= require("hs.timer")

--- doesDirectoryExist() -> boolean
--- Internal Function
--- Returns true if Directory Exists else False
---
--- Parameters:
---  * None
---
--- Returns:
---  * True is Directory Exists otherwise False
---
local function doesDirectoryExist(path)
    local attr = fs.attributes(path)
    return attr and attr.mode == 'directory'
end

--- hs.finalcutpro.selectMenuItem() -> table
--- Function
--- Selects a Final Cut Pro Menu Item
---
--- Parameters:
---  * table - A table of the menu item you'd like to activate, for example: {"View", "Browser", "as List"}
---
--- Returns:
---  * True is successful otherwise Nil
---
function finalcutpro.selectMenuItem(menuItemTable)

	--------------------------------------------------------------------------------
	-- Variables:
	--------------------------------------------------------------------------------
	local whichMenuBar 		= nil
	local whichMenuOne 		= nil
	local whichMenuTwo 		= nil
	local whichMenuThree 	= nil

	--------------------------------------------------------------------------------
	-- Hardcoded Values (for system other than English):
	--------------------------------------------------------------------------------
	if menuItemTable[1] == "Apple" 								then whichMenuOne = 1 		end
	if menuItemTable[1] == "Final Cut Pro" 						then whichMenuOne = 2 		end
		if menuItemTable[2] == "Preferences…" 					then whichMenuTwo = 3 		end
		if menuItemTable[25] == "Reveal in Browser" 			then whichMenuTwo = 23 		end
	if menuItemTable[1] == "File" 								then whichMenuOne = 3 		end
	if menuItemTable[1] == "Edit" 								then whichMenuOne = 4 		end
	if menuItemTable[1] == "Trim" 								then whichMenuOne = 5 		end
	if menuItemTable[1] == "Mark" 								then whichMenuOne = 6 		end
	if menuItemTable[1] == "Clip" 								then whichMenuOne = 7 		end
		if menuItemTable[2] == "Open in Angle Editor"			then whichMenuTwo = 4 		end
	if menuItemTable[1] == "Modify" 							then whichMenuOne = 8 		end
	if menuItemTable[1] == "View" 								then whichMenuOne = 9 		end
		if menuItemTable[2] == "Timeline History Back"			then whichMenuTwo = 16 		end
		if menuItemTable[2] == "Zoom to Fit"					then whichMenuTwo = 22 		end
	if menuItemTable[1] == "Window" 							then whichMenuOne = 10 		end
		if menuItemTable[2] == "Go To" 							then whichMenuTwo = 6 		end
			if menuItemTable[3] == "Timeline"					then whichMenuThree = 7		end
			if menuItemTable[3] == "Color Board"				then whichMenuThree = 9		end
	if menuItemTable[1] == "Help" 								then whichMenuOne = 11 		end

	--------------------------------------------------------------------------------
	-- TO DO: Commenting this stuff out will have definitely broken something:
	--------------------------------------------------------------------------------
	--if menuItemTable[2] == "Browser" 				then whichMenuTwo = 5 		end
	--if menuItemTable[3] == "as List"				then whichMenuThree = 2		end
	--if menuItemTable[3] == "Group Clips By"		then whichMenuThree = 4		end
	--if menuItemTable[4] == "None"					then whichMenuThree = 1		end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx = finalcutpro.application()

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpxElements = ax.applicationElement(fcpx)

	--------------------------------------------------------------------------------
	-- Which AXMenuBar:
	--------------------------------------------------------------------------------
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXMenuBar" then
				whichMenuBar = i
				goto performFinalCutProMenuItemWhichMenuBarExit
			end
	end
	if whichMenuBar == nil then	return nil end
	::performFinalCutProMenuItemWhichMenuBarExit::

	--------------------------------------------------------------------------------
	-- Which Menu One:
	--------------------------------------------------------------------------------
	if whichMenuOne == nil then
		for i=1, fcpxElements[whichMenuBar]:attributeValueCount("AXChildren") do
			if fcpxElements[whichMenuBar]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == menuItemTable[1] then
				whichMenuOne = i
				goto performFinalCutProMenuItemWhichMenuOneExit
			end
		end
		if whichMenuOne == nil then	return nil end
		::performFinalCutProMenuItemWhichMenuOneExit::
	end

	--------------------------------------------------------------------------------
	-- Which Menu Two:
	--------------------------------------------------------------------------------
	if whichMenuTwo == nil then
		for i=1, fcpxElements[whichMenuBar][whichMenuOne][1]:attributeValueCount("AXChildren") do
				if fcpxElements[whichMenuBar][whichMenuOne][1]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == menuItemTable[2] then
					whichMenuTwo = i
					goto performFinalCutProMenuItemWhichMenuTwoExit
				end
		end
		if whichMenuTwo == nil then	return nil end
		::performFinalCutProMenuItemWhichMenuTwoExit::
	end

	--------------------------------------------------------------------------------
	-- Select Menu Item 1:
	--------------------------------------------------------------------------------
	if #menuItemTable == 2 then fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo]:performAction("AXPress") end

	--------------------------------------------------------------------------------
	-- Select Menu Item 2:
	--------------------------------------------------------------------------------
	if #menuItemTable == 3 then

		--------------------------------------------------------------------------------
		-- Which Menu Three:
		--------------------------------------------------------------------------------
		if whichMenuThree == nil then
			for i=1, fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo][1]:attributeValueCount("AXChildren") do
					if fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo][1]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == menuItemTable[3] then
						whichMenuThree = i
						goto performFinalCutProMenuItemWhichMenuThreeExit
					end
			end
			if whichMenuThree == nil then return nil end
			::performFinalCutProMenuItemWhichMenuThreeExit::
		end

		--------------------------------------------------------------------------------
		-- Select Menu Item:
		--------------------------------------------------------------------------------
		fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo][1][whichMenuThree]:performAction("AXPress")

	end

	--------------------------------------------------------------------------------
	-- Select Menu Item 3:
	--------------------------------------------------------------------------------
	if #menuItemTable == 4 then

		--------------------------------------------------------------------------------
		-- Which Menu Three:
		--------------------------------------------------------------------------------
		if whichMenuThree == nil then
			for i=1, fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo][1]:attributeValueCount("AXChildren") do
					if fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo][1]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == menuItemTable[3] then
						whichMenuThree = i
						goto performFinalCutProMenuItemWhichMenuThreeExit
					end
			end
			if whichMenuThree == nil then return nil end
			::performFinalCutProMenuItemWhichMenuThreeExit::
		end

		--------------------------------------------------------------------------------
		-- Which Menu Four:
		--------------------------------------------------------------------------------
		if whichMenuFour == nil then
			for i=1, fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo][1][whichMenuThree][1]:attributeValueCount("AXChildren") do
					if fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo][1][whichMenuThree][1]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == menuItemTable[3] then
						whichMenuFour = i
						goto performFinalCutProMenuItemWhichMenuFourExit
					end
			end
			if whichMenuFour == nil then return nil end
			::performFinalCutProMenuItemWhichMenuFourExit::
		end

		--------------------------------------------------------------------------------
		-- Select Menu Item:
		--------------------------------------------------------------------------------
		fcpxElements[whichMenuBar][whichMenuOne][1][whichMenuTwo][1][whichMenuThree][1][whichMenuFour]:performAction("AXPress")

	end

	return true

end

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

	if optionalPath == nil then
		activeCommandSetPath = finalcutpro.getActiveCommandSetPath()
	else
		activeCommandSetPath = optionalPath
	end

	if activeCommandSetPath ~= nil then
		if fs.attributes(activeCommandSetPath) ~= nil then
			result = plist.xmlFileToTable(activeCommandSetPath)
			if result == nil then
				result = plist.binaryFileToTable(activeCommandSetPath)
			end
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

--- hs.finalcutpro.version() -> string or nil
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
			timer.usleep(1000000)
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

	-- Which Split Group:
	local whichSplitGroup = nil

	-- Define Final Cut Pro:
	local sw = ax.applicationElement(finalcutpro.application())

	-- Single Screen:
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

	-- Dual Screen:
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

	-- Which Split Group:
	local finalCutProTimelineScrollArea = nil
	local finalCutProTimelineSplitGroup = finalcutpro.getTimelineSplitGroup()

	-- Get last scroll area:
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

	-- Get Timeline Split Group:
	local finalCutProTimelineSplitGroup = finalcutpro.getTimelineSplitGroup()

	-- Which Group:
	for i=1, finalCutProTimelineSplitGroup:attributeValueCount("AXChildren") do
		if finalCutProTimelineSplitGroup[i]:attributeValue("AXRole") == "AXGroup" then
			return finalCutProTimelineSplitGroup[i]
		end
	end

	-- If things get to here it's failed:
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

	-- Define Final Cut Pro:
	sw = ax.applicationElement(finalcutpro.application())

	-- Single Screen:
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

	-- Dual Screen:
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


	-- Define Final Cut Pro:
	sw = ax.applicationElement(finalcutpro.application())

	-- Find Color Button:
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

return finalcutpro