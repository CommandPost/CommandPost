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
local osascript									= require("hs.osascript")
local settings									= require("hs.settings")
local screen									= require("hs.screen")
local sharing									= require("hs.sharing")

local fcp										= require("hs.finalcutpro")

local i18n										= require("hs.fcpxhacks.modules.i18n")
local tools										= require("hs.fcpxhacks.modules.tools")

--------------------------------------------------------------------------------
-- SETUP I18N LANGUAGES:
--------------------------------------------------------------------------------
local languagePath = "hs/fcpxhacks/languages/"
for file in fs.dir(languagePath) do
	if file:sub(-4) == ".lua" then
		i18n.loadFile(languagePath .. file)
	end
end
local userLocale = nil
if settings.get("fcpxHacks.language") == nil then
	userLocale = tools.userLocale()
else
	userLocale = settings.get("fcpxHacks.language")
end
i18n.setLocale(userLocale)

--------------------------------------------------------------------------------
-- COMMON ERROR MESSAGES:
--------------------------------------------------------------------------------
local commonErrorMessageStart 					= i18n("commonErrorMessageStart") .. "\n\n"
local commonErrorMessageEnd 					= "\n\n" .. i18n("commonErrorMessageEnd")
local commonErrorMessageAppleScript 			= 'set noButton to "' .. i18n("no") .. '"' .. '\n\nset yesButton to "' .. i18n("yes") .. '"' .. '\n\nset okButton to "' .. i18n("ok") .. '"' .. '\n\nset cancelButton to "' .. i18n("cancel") .. '"' .. '\n\nset fcpxIcon to (((POSIX path of ((path to home folder as Unicode text) & ".hammerspoon:hs:fcpxhacks:assets:fcpxhacks.icns")) as Unicode text) as POSIX file)\n\nset commonErrorMessageStart to "' .. commonErrorMessageStart .. '"\nset commonErrorMessageEnd to "' .. commonErrorMessageEnd .. '"\n'

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
				set dialogResult to (display dialog whatMessage default answer defaultAnswer buttons {okButton, cancelButton} with icon fcpxIcon)
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
			display dialog whatErrorMessage buttons {okButton} with icon fcpxIcon
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
				set response to text returned of (display dialog whatMessage default answer defaultAnswer buttons {okButton, cancelButton} default button 1 with icon fcpxIcon)
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
			display dialog whatErrorMessage buttons {okButton} with icon fcpxIcon
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
		display dialog whatMessage buttons {okButton} with icon stop
	]]
	osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
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
		display dialog commonErrorMessageStart & whatError & commonErrorMessageEnd buttons {yesButton, noButton} with icon fcpxIcon
		if the button returned of the result is equal to yesButton then
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

	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		set result to button returned of (display dialog whatMessage ]] .. buttons .. [[ with icon fcpxIcon)
		return result
	]]
	local a, result = osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
	if returnToFinalCutPro then fcp.launch() end

	return result

end

--------------------------------------------------------------------------------
-- DISPLAY YES OR NO QUESTION:
--------------------------------------------------------------------------------
function dialog.displayYesNoQuestion(whatMessage) -- returns true or false

	local returnToFinalCutPro = fcp.frontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {yesButton, noButton} default button 1 with icon fcpxIcon
		if the button returned of the result is equal to yesButton then
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
-- DISPLAY ALERT NOTIFICATION:
--------------------------------------------------------------------------------
function dialog.displayNotification(whatMessage)
	alert.closeAll(0)
	alert.show(whatMessage, { textStyle = { paragraphStyle = { alignment = "center" } } })
end

--------------------------------------------------------------------------------
-- EMAIL BUG REPORT:
--------------------------------------------------------------------------------
function dialog.emailBugReport()
	local mailer = sharing.newShare("com.apple.share.Mail.compose"):subject("[FCPX Hacks " .. fcpxhacks.scriptVersion .. "] Bug Report"):recipients({fcpxhacks.bugReportEmail})
															       :shareItems({"Please enter any notes, comments or suggestions here.\n\n---",console.getConsole(true), screen.mainScreen():snapshot()})
end

return dialog