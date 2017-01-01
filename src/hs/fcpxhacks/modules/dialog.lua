--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            D I A L O G B O X     S U P P O R T     L I B R A R Y           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by Chris Hocking (https://latenitefilms.com)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local dialog = {}

local alert										= require("hs.alert")
local console									= require("hs.console")
local fs										= require("hs.fs")
local inspect									= require("hs.inspect")
local osascript									= require("hs.osascript")
local screen									= require("hs.screen")
local settings									= require("hs.settings")
local sharing									= require("hs.sharing")
local inspect									= require("hs.inspect")

local fcp										= require("hs.finalcutpro")

local tools										= require("hs.fcpxhacks.modules.tools")

--------------------------------------------------------------------------------
-- COMMON APPLESCRIPT:
--------------------------------------------------------------------------------
local commonAppleScript = [[
	set yesButton to "]] .. i18n("yes") .. [["
	set noButton to "]] .. i18n("no") .. [["

	set okButton to "]] .. i18n("ok") .. [["
	set cancelButton to "]] .. i18n("cancel") .. [["

	set iconPath to (((POSIX path of ((path to home folder as Unicode text) & ".hammerspoon:hs:fcpxhacks:assets:fcpxhacks.icns")) as Unicode text) as POSIX file)

	set errorMessageStart to "]] .. i18n("commonErrorMessageStart") .. [[\n\n"
	set errorMessageEnd to "\n\n]] .. i18n("commonErrorMessageEnd") .. [["

	set finalCutProBundleID to "]] .. fcp.bundleID() .. [["

	set isFinalCutProFrontmost to true
	tell application "System Events"
		set runningProcesses to processes whose bundle identifier is finalCutProBundleID
		set activeApp to name of first application process whose frontmost is true
	end tell
	if "Final Cut Pro" is not in activeApp then set isFinalCutProFrontmost to false
	if runningProcesses is {} then set isFinalCutProFrontmost to false

]]

--------------------------------------------------------------------------------
-- DISPLAY SMALL NUMBER TEXT BOX MESSAGE:
--------------------------------------------------------------------------------
function dialog.displaySmallNumberTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer)
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["
		set whatErrorMessage to "]] .. whatErrorMessage .. [["
		set defaultAnswer to "]] .. defaultAnswer .. [["

		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				repeat
					try
						set dialogResult to (display dialog whatMessage default answer defaultAnswer buttons {okButton, cancelButton} with icon iconPath)
					on error
						-- Cancel Pressed:
						return false
					end try
					try
						set usersInput to (text returned of dialogResult) as number -- To accept only entries that coerce directly to class integer.
						if usersInput is not equal to missing value then
							if usersInput is not 0 then
								exit repeat
							end if
						end if
					end try
					display dialog whatErrorMessage buttons {okButton} with icon iconPath
				end repeat
				return usersInput
			end tell
		else
			repeat
				try
					tell me to activate
					set dialogResult to (display dialog whatMessage default answer defaultAnswer buttons {okButton, cancelButton} with icon iconPath)
				on error
					-- Cancel Pressed:
					return false
				end try
				try
					set usersInput to (text returned of dialogResult) as number -- To accept only entries that coerce directly to class integer.
					if usersInput is not equal to missing value then
						if usersInput is not 0 then
							exit repeat
						end if
					end if
				end try
				display dialog whatErrorMessage buttons {okButton} with icon iconPath
			end repeat
			return usersInput
		end if
	]]
	local a,result = osascript.applescript(commonAppleScript .. appleScript)
	return result
end

--------------------------------------------------------------------------------
-- DISPLAY TEXT BOX MESSAGE:
--------------------------------------------------------------------------------
function dialog.displayTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer)
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["
		set whatErrorMessage to "]] .. whatErrorMessage .. [["
		set defaultAnswer to "]] .. defaultAnswer .. [["

		set allowedLetters to characters of (do shell script "printf \"%c\" {a..z}")
		set allowedNumbers to characters of (do shell script "printf \"%c\" {0..9}")
		set allowedAll to allowedLetters & allowedNumbers & space


		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				repeat
					try
						set response to text returned of (display dialog whatMessage default answer defaultAnswer buttons {okButton, cancelButton} default button 1 with icon iconPath)
					on error
						-- Cancel Pressed:
						return false
					end try
					try
						set invalidCharacters to false
						repeat with aCharacter in response
							if (aCharacter as text) is not in allowedAll then
								set invalidCharacters to true
							end if
						end repeat
						if length of response is 0 then
							set invalidCharacters to true
						end if
						if invalidCharacters is false then
							exit repeat
						end
					end try
					display dialog whatErrorMessage buttons {okButton} with icon iconPath
				end repeat
				return response
			end tell
		else
			repeat
				try
					tell me to activate
					set response to text returned of (display dialog whatMessage default answer defaultAnswer buttons {okButton, cancelButton} default button 1 with icon iconPath)
				on error
					-- Cancel Pressed:
					return false
				end try
				try
					set invalidCharacters to false
					repeat with aCharacter in response
						if (aCharacter as text) is not in allowedAll then
							set invalidCharacters to true
						end if
					end repeat
					if length of response is 0 then
						set invalidCharacters to true
					end if
					if invalidCharacters is false then
						exit repeat
					end
				end try
				display dialog whatErrorMessage buttons {okButton} with icon iconPath
			end repeat
			return response
		end if
	]]
	local a,result = osascript.applescript(commonAppleScript .. appleScript)
	return result
end

--------------------------------------------------------------------------------
-- DISPLAY CHOOSE FOLDER DIALOG:
--------------------------------------------------------------------------------
function dialog.displayChooseFolder(whatMessage)
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["

		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				try
					set whichFolder to POSIX path of (choose folder with prompt whatMessage default location (path to desktop))
					return whichFolder
				on error
					-- Cancel Pressed:
					return false
				end try
			end tell
		else
			tell me to activate
			try
				set whichFolder to POSIX path of (choose folder with prompt whatMessage default location (path to desktop))
				return whichFolder
			on error
				-- Cancel Pressed:
				return false
			end try
		end if
	]]
	local a,result = osascript.applescript(commonAppleScript .. appleScript)
	return result
end

--------------------------------------------------------------------------------
-- DISPLAY ALERT MESSAGE:
--------------------------------------------------------------------------------
function dialog.displayAlertMessage(whatMessage)
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["

		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				display dialog whatMessage buttons {okButton} with icon stop
			end tell
		else
			tell me to activate
			display dialog whatMessage buttons {okButton} with icon stop
		end if
	]]
	local a,result = osascript.applescript(commonAppleScript .. appleScript)
end

--------------------------------------------------------------------------------
-- DISPLAY ERROR MESSAGE:
--------------------------------------------------------------------------------
function dialog.displayErrorMessage(whatError)

	--------------------------------------------------------------------------------
	-- Write error message to console:
	--------------------------------------------------------------------------------
	writeToConsole(whatError)

	--------------------------------------------------------------------------------
	-- Display Dialog Box:
	--------------------------------------------------------------------------------
	local appleScript = [[
		set whatError to "]] .. whatError .. [["

		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				display dialog errorMessageStart & whatError & errorMessageEnd buttons {yesButton, noButton} with icon iconPath
				if the button returned of the result is equal to yesButton then
					return true
				else
					return false
				end if
			end tell
		else
			tell me to activate
			display dialog errorMessageStart & whatError & errorMessageEnd buttons {yesButton, noButton} with icon iconPath
			if the button returned of the result is equal to yesButton then
				return true
			else
				return false
			end if
		end if

	]]
	local a,result = osascript.applescript(commonAppleScript .. appleScript)

	--------------------------------------------------------------------------------
	-- Send bug report:
	--------------------------------------------------------------------------------
	if result then emailBugReport() end

end

--------------------------------------------------------------------------------
-- DISPLAY MESSAGE:
--------------------------------------------------------------------------------
function dialog.displayMessage(whatMessage, optionalButtons)

	if optionalButtons == nil or type(optionalButtons) ~= "table" then
		optionalButtons = {i18n("ok")}
	end

	local buttons = 'buttons {'
	for i=1, #optionalButtons do
		buttons = buttons .. '"' .. optionalButtons[i] .. '"'
		if i ~= #optionalButtons then buttons = buttons .. ", " end
	end
	buttons = buttons .. "}"

	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["
		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				set result to button returned of (display dialog whatMessage ]] .. buttons .. [[ with icon iconPath)
				return result
			end tell
		else
			tell me to activate
			set result to button returned of (display dialog whatMessage ]] .. buttons .. [[ with icon iconPath)
			return result
		end if
	]]
	local a, result = osascript.applescript(commonAppleScript .. appleScript)
	return result

end

--------------------------------------------------------------------------------
-- DISPLAY YES OR NO QUESTION:
--------------------------------------------------------------------------------
function dialog.displayYesNoQuestion(whatMessage) -- returns true or false

	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["
		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				display dialog whatMessage buttons {yesButton, noButton} default button 1 with icon iconPath
				if the button returned of the result is equal to yesButton then
					return true
				else
					return false
				end if
			end tell
		else
			tell me to activate
			display dialog whatMessage buttons {yesButton, noButton} default button 1 with icon iconPath
			if the button returned of the result is equal to yesButton then
				return true
			else
				return false
			end if
		end if
	]]
	local a,result = osascript.applescript(commonAppleScript .. appleScript)
	return result

end

--------------------------------------------------------------------------------
-- DISPLAY CHOOSE FROM LIST:
--------------------------------------------------------------------------------
function dialog.displayChooseFromList(dialogPrompt, listOptions, defaultItems)

	if dialogPrompt == "nil" then dialogPrompt = "Please make your selection:" end
	if dialogPrompt == "" then dialogPrompt = "Please make your selection:" end

	if defaultItems == nil then defaultItems = {} end
	if type(defaultItems) ~= "table" then defaultItems = {} end

	local appleScript = [[
		set dialogPrompt to "]] .. dialogPrompt .. [["
		set listOptions to ]] .. inspect(listOptions) .. [[
		set defaultItems to ]] .. inspect(defaultItems) .. [[

		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				return choose from list listOptions with title "FCPX Hacks" with prompt dialogPrompt default items defaultItems
			end tell
		else
			tell me to activate
			return choose from list listOptions with title "FCPX Hacks" with prompt dialogPrompt default items defaultItems
		end if
	]]
	local a,result = osascript.applescript(commonAppleScript .. appleScript)
	return result

end

--------------------------------------------------------------------------------
-- DISPLAY COLOR PICKER:
--------------------------------------------------------------------------------
function dialog.displayColorPicker(customColor) -- Accepts RGB Table

	local defaultColor = {65535, 65535, 65535}
	if type(customColor) == "table" then
		local validColor = true
		if customColor["red"] == nil then validColor = false end
		if customColor["green"] == nil then validColor = false end
		if customColor["blue"] == nil then validColor = false end
		if validColor then
			defaultColor = { customColor["red"] * 257 * 255, customColor["green"] * 257 * 255, customColor["blue"] * 257 * 255 }
		end
	end

	local appleScript = [[
		set defaultColor to ]] .. inspect(defaultColor) .. [[

		if isFinalCutProFrontmost is true then
			tell application id finalCutProBundleID
				return choose color default color defaultColor
			end tell
		else
			tell me to activate
			return choose color default color defaultColor
		end if
	]]
	local a,result = osascript.applescript(commonAppleScript .. appleScript)
	if type(result) == "table" then
		local red = result[1] / 257 / 255
		local green = result[2] / 257 / 255
		local blue = result[3] / 257 / 255
		if red ~= nil and green ~= nil and blue ~= nil then
			if returnToFinalCutPro then fcp.launch() end
			return {red=red, green=green, blue=blue, alpha=1}
		end
	end
	return nil

end

--------------------------------------------------------------------------------
-- DISPLAY ALERT NOTIFICATION:
--------------------------------------------------------------------------------
function dialog.displayNotification(whatMessage)
	alert.closeAll(0)
	alert.show(whatMessage, { textStyle = { paragraphStyle = { alignment = "center" } } })
end

return dialog