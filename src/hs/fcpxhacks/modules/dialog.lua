--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            D I A L O G B O X     S U P P O R T     L I B R A R Y           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by Chris Hocking (https://github.com/latenitefilms).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local dialog = {}

local fcp										= require("hs.finalcutpro")

local osascript									= require("hs.osascript")
local sharing									= require("hs.sharing")
local console									= require("hs.console")

local commonErrorMessageStart 					= "I'm sorry, but the following error has occurred:\n\n"
local commonErrorMessageEnd 					= "\n\nWould you like to email this bug to Chris so that he can try and come up with a fix?"
local commonErrorMessageAppleScript 			= 'set fcpxIcon to (((POSIX path of ((path to home folder as Unicode text) & ".hammerspoon:hs:fcpxhacks:assets:fcpxhacks.icns")) as Unicode text) as POSIX file)\n\nset commonErrorMessageStart to "' .. commonErrorMessageStart .. '"\nset commonErrorMessageEnd to "' .. commonErrorMessageEnd .. '"\n'

--------------------------------------------------------------------------------
-- DISPLAY SMALL NUMBER TEXT BOX MESSAGE:
--------------------------------------------------------------------------------
function dialog.displaySmallNumberTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer)
	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = 'set whatErrorMessage to "' .. whatErrorMessage .. '"' .. '\n\n'
	local appleScriptC = 'set defaultAnswer to "' .. defaultAnswer .. '"' .. '\n\n'
	local appleScriptD = [[
		repeat
			try
				tell me to activate
				set dialogResult to (display dialog whatMessage default answer defaultAnswer buttons {"OK", "Cancel"} with icon fcpxIcon)
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
			display dialog whatErrorMessage buttons {"OK"} with icon fcpxIcon
		end repeat
		return usersInput
	]]
	a,result = osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB .. appleScriptC .. appleScriptD)
	if returnToFinalCutPro then fcp.launch() end
	return result
end

--------------------------------------------------------------------------------
-- DISPLAY TEXT BOX MESSAGE:
--------------------------------------------------------------------------------
function dialog.displayTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer)
	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = 'set whatErrorMessage to "' .. whatErrorMessage .. '"' .. '\n\n'
	local appleScriptC = 'set defaultAnswer to "' .. defaultAnswer .. '"' .. '\n\n'
	local appleScriptD = [[
		set allowedLetters to characters of (do shell script "printf \"%c\" {a..z}")
		set allowedNumbers to characters of (do shell script "printf \"%c\" {0..9}")
		set allowedAll to allowedLetters & allowedNumbers & space

		repeat
			try
				tell me to activate
				set response to text returned of (display dialog whatMessage default answer defaultAnswer buttons {"OK", "Cancel"} default button 1 with icon fcpxIcon)
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
			display dialog whatErrorMessage buttons {"OK"} with icon fcpxIcon
		end repeat
		return response
	]]
	a,result = osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB .. appleScriptC .. appleScriptD)
	if returnToFinalCutPro then fcp.launch() end
	return result
end

--------------------------------------------------------------------------------
-- DISPLAY CHOOSE FOLDER DIALOG:
--------------------------------------------------------------------------------
function dialog.displayChooseFolder(whatMessage)
	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		try
			set whichFolder to POSIX path of (choose folder with prompt whatMessage default location (path to desktop))
			return whichFolder
		on error
			-- Cancel Pressed:
			return false
		end try
	]]
	a,result = osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
	if returnToFinalCutPro then fcp.launch() end
	return result
end

--------------------------------------------------------------------------------
-- DISPLAY ALERT MESSAGE:
--------------------------------------------------------------------------------
function dialog.displayAlertMessage(whatMessage)
	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"OK"} with icon stop
	]]
	osascript.applescript(appleScriptA .. appleScriptB)
	if returnToFinalCutPro then fcp.launch() end
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
	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatError to "' .. whatError .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog commonErrorMessageStart & whatError & commonErrorMessageEnd buttons {"Yes", "No"} with icon fcpxIcon
		if the button returned of the result is "Yes" then
			return true
		else
			return false
		end if
	]]
	a,result = osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)

	--------------------------------------------------------------------------------
	-- Send bug report:
	--------------------------------------------------------------------------------
	if result then dialog.emailBugReport() end
	if returnToFinalCutPro then fcp.launch() end

end

--------------------------------------------------------------------------------
-- DISPLAY MESSAGE:
--------------------------------------------------------------------------------
function dialog.displayMessage(whatMessage)
	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"OK"} with icon fcpxIcon
	]]
	osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
	if returnToFinalCutPro then fcp.launch() end
end

--------------------------------------------------------------------------------
-- DISPLAY YES OR NO QUESTION:
--------------------------------------------------------------------------------
function dialog.displayYesNoQuestion(whatMessage) -- returns true or false

	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"Yes", "No"} default button 1 with icon fcpxIcon
		if the button returned of the result is "Yes" then
			return true
		else
			return false
		end if
	]]
	a,result = osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
	if returnToFinalCutPro then fcp.launch() end
	return result

end

--------------------------------------------------------------------------------
-- EMAIL BUG REPORT:
--------------------------------------------------------------------------------
function dialog.emailBugReport()
	local mailer = sharing.newShare("com.apple.share.Mail.compose"):subject("[FCPX Hacks " .. fcpxhacks.scriptVersion .. "] Bug Report"):recipients({fcpxhacks.bugReportEmail})
															       :shareItems({"Please enter any notes, comments or suggestions here.\n\n---",console.getConsole(true), screen.mainScreen():snapshot()})
end

return dialog